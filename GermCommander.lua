-- GermCommander
-- collects and manages instances of the Germ class which sit on the action bars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class GermCommander -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local GermCommander = { }
Ufo.GermCommander = GermCommander

---@type Germ -- IntelliJ-EmmyLua annotation
local Germ = Ufo.Germ

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local germs = {} -- copies of flyouts that sit on the action bars
local previousSpec
local currentSpec

-------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------

local function hideAllGerms()
    for name, germ in pairs(germs) do
        germ:myHide()
    end
end

local function doesFlyoutExist(flyoutId)
    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    return flyoutConf and true or false
end

local function getFlyoutIdForSlot(btnSlotIndex)
    return GermCommander:getPlacementConfigForCurrentSpec()[btnSlotIndex]
end

local function getSpecId()
    return GetSpecialization() or NON_SPEC_SLOT
end

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function GermCommander:updateAll()
    zebug.trace:line(40)
    if isInCombatLockdown("Reconfiguring") then return end

    hideAllGerms() -- this is only required because we sledge hammer all the germs every time.

    local placements = self:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        local isThere = doesFlyoutExist(flyoutId)
        zebug.trace:line(5, "btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId, "isThere", isThere)
        if isThere then
            local germ = self:recallGerm(btnSlotIndex)
            if not germ then
                germ = Germ.new(flyoutId, btnSlotIndex)
                self:saveGerm(germ)
            end
            germ:update(flyoutId)
        else
            -- because one toon can delete a flyout while other toons still have it on their bars
            zebug.warn:print("flyoutId",flyoutId, "no longer exists. Deleting it from action bar slot",btnSlotIndex)
            GermCommander:deletePlacement(btnSlotIndex)
        end
    end
end

---@return Germ
function GermCommander:recallGerm(btnSlotIndex)
    return germs[btnSlotIndex]
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function GermCommander:saveGerm(germ)
    local btnSlotIndex = germ:getBtnSlotIndex()
    germs[btnSlotIndex] = germ
end

function GermCommander:newGermProxy(flyoutId, icon)
    self:deleteProxy()
    return self:createProxy(flyoutId, icon)
end

function GermCommander:deleteProxy()
    Ufo.thatWasMe = true
    DeleteMacro(PROXY_MACRO_NAME)
end

local toonSpecific = false

function GermCommander:createProxy(flyoutId, icon)
    Ufo.thatWasMe = true
    local macroText = flyoutId
    return CreateMacro(PROXY_MACRO_NAME, icon or DEFAULT_ICON, macroText, toonSpecific)
end

-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- Check if this event was caused by dragging a flyout out of the Catalog and dropping it onto an actionbar.
-- The targeted slot could: be empty; already have a different germ (or the same one); anything else.
function GermCommander:handleActionBarSlotChanged(btnSlotIndex)
    local configChanged
    local existingFlyoutId = getFlyoutIdForSlot(btnSlotIndex)

    local type, macroId = GetActionInfo(btnSlotIndex)
    if not type then
        return
    end

    local droppedFlyoutId = self:getFlyoutIdFromGermProxy(type, macroId)

    if droppedFlyoutId or existingFlyoutId then
        zebug.info:print("btnSlotIndex",btnSlotIndex, "existingFlyoutId",existingFlyoutId, "type",type, "macroId",macroId, "droppedFlyoutId",droppedFlyoutId)
    end

    if droppedFlyoutId then
        self:savePlacement(btnSlotIndex, droppedFlyoutId)
        self:deleteProxy()
        configChanged = true
    end

    -- after dropping the flyout on the cursor, pickup the one we just replaced
    if existingFlyoutId then
        FlyoutMenu:pickup(existingFlyoutId)
        if not configChanged then
            GermCommander:deletePlacement(btnSlotIndex)
            --configChanged = true
        end
    end

    if configChanged then
        self:updateAll()
    end
end

function GermCommander:isDraggingProxy()
    return self:getFlyoutIdFromCursor() and true or false
end

function GermCommander:getFlyoutIdFromCursor()
    local type, macroId = GetCursorInfo()
    zebug.trace:print("type",type,"macroId",macroId, "isMacro",type == "macro")
    return GermCommander:getFlyoutIdFromGermProxy(type, macroId)
end

-- TODO: extract the owner
function GermCommander:getFlyoutIdFromGermProxy(type, macroId)
    local flyoutId
    if type == "macro" then
        local name, texture, body = GetMacroInfo(macroId)
        if name == PROXY_MACRO_NAME then
            flyoutId = body
        end
    end
    return flyoutId
end

function GermCommander:savePlacement(btnSlotIndex, flyoutId)
    btnSlotIndex = tonumber(btnSlotIndex)
    flyoutId = FlyoutDefsDb:validateFlyoutId(flyoutId)
    zebug.info:print("btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId)
    self:getPlacementConfigForCurrentSpec()[btnSlotIndex] = flyoutId
end

function GermCommander:deletePlacement(btnSlotIndex)
    btnSlotIndex = tonumber(btnSlotIndex)
    local placements = self:getPlacementConfigForCurrentSpec()
    local flyoutId = placements[btnSlotIndex]
    zebug.info:print("GermCommander:deletePlacement() DELETING PLACEMENT", "btnSlotIndex",btnSlotIndex, "flyoutId", flyoutId)
    zebug.trace:dumpy("BEFORE placements", placements)
    -- the germ UI Frame stays in place but is now empty
    placements[btnSlotIndex] = nil
end

function GermCommander:nukeFlyout(flyoutId)
    flyoutId = FlyoutDefsDb:validateFlyoutId(flyoutId)
    for i, allSpecsConfig in ipairs(self:getAllSpecsPlacementsConfig()) do
        for i, specConfig in ipairs(allSpecsConfig) do
            for btnSlotIndex, flyoutId2 in pairs(specConfig) do
                if flyoutId == flyoutId2 then
                    specConfig[btnSlotIndex] = nil
                end
            end
        end
    end
end

-- keep track of spec changes so getConfigForSpec() can initialize a brand new config based on the old one
function GermCommander:recordCurrentSpec()
    local hasChanged
    local newSpec = getSpecId()
    zebug.trace:print("recordCurrentSpec()", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
    if currentSpec ~= newSpec then
        previousSpec = currentSpec
        currentSpec = newSpec
        zebug.trace:print("REASSIGNED->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        hasChanged = true
    else
        zebug.trace:print("unchanged ->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        hasChanged = false
    end
    return hasChanged
end

-- I originally created this method to handle the PLAYER_SPECIALIZATION_CHANGED event
-- but, in consitent bliz inconsistency, it's unreliable whether that event
-- will shoot off before, during, or after the ACTIONBAR_SLOT_CHANGED event which also will trigger updateAllGerms()
-- so, I had to move recordCurrentSpec() directly into getConfigForCurrentSpec() and am leaving this here as a monument.
function GermCommander:changePlacementsBecauseSpecChanged()
    -- recordCurrentSpec() -- nope, nevermind.  moved below
    self:updateAll()
end

function GermCommander:getPlacementConfigForCurrentSpec()
    self:recordCurrentSpec()
    local specId = getSpecId()
    return self:getConfigForSpec(specId)
end

function GermCommander:getConfigForSpec(specId)
    -- the placement of flyouts on the action bars changes from spec to spec
    local placementsForAllSpecs = GermCommander:getAllSpecsPlacementsConfig()
    assert(placementsForAllSpecs, ADDON_NAME..": Oops!  placements config is nil")

    local result = placementsForAllSpecs[specId]
    -- is this a never-before-encountered spec? - if so, initialze its config
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 1",result)
    if not result then -- TODO: identify empty OR nil
        if not previousSpec or specId == previousSpec then
            zebug:print("blanking specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec)
            result = {}
        else
            -- initialize the new config based on the old one
            result = deepcopy(self:getConfigForSpec(previousSpec))
            zebug:line(7, "COPYING specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "initialConfig", "result 1b",result)
        end
        placementsForAllSpecs[specId] = result
    end
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 2",result)
    --debug:dump(result)
    return result
end

-- the placement of flyouts on the action bars is stored separately for each toon
function GermCommander:getAllSpecsPlacementsConfig()
    local foo = Config:getAllSpecsPlacementsConfig()
    return foo
end
