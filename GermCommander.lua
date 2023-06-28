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

local function getGerm(btnSlotIndex)
    return germs[btnSlotIndex]
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
local function rememberGerm(germ)
    local btnSlotIndex = germ:getBtnSlotIndex()
    germs[btnSlotIndex] = germ
end

-- TODO: refactor -  actionBarBtn to the Germ
local function bindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
    -- examine the action/bonus/multi bar
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.
    local actionBarName = actionBarDef.name
    local visibleIf = actionBarDef.visibleIf

    -- examine the button
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local actionBarBtnName = actionBarName .. "Button" .. btnNum
    local actionBarBtn = _G[actionBarBtnName] -- grab the button object from Blizzard's GLOBAL dumping ground

    -- ask the bar instance what direction to fly
    local barObj = actionBarBtn and actionBarBtn.bar
    local direction = barObj and barObj:GetSpellFlyoutDirection() or "UP" -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs

    --local foo = btnObj and "FOUND" or "NiL"
    --print ("###--->>> ffUniqueId =", ffUniqueId, "barNum =",barNum, "btnSlotIndex = ", btnSlotIndex, "btnObj =",foo, "blizBarName = ",blizBarName,  "btnName =",btnName,  "btnNum =",btnNum, "direction =",direction, "visibleIf =", visibleIf)

    ---@type Germ
    local germ = getGerm(btnSlotIndex)
    if not germ then
        germ = Germ.new(flyoutId, actionBarBtn)
        if not germ then
            -- a different toon could have deleted it and that's ok.
            return
        end
        rememberGerm(germ)
    end
    zebug.trace:print("bindFlyoutToActionBarSlot()","germ...",germ)
    germ:redefine(flyoutId, btnSlotIndex, direction, visibleIf)
end

local function clearGerms()
    for name, germ in pairs(germs) do
        germ:Hide()
        UnregisterStateDriver(germ, "visibility")
    end
end

local function doesFlyoutExist(flyoutId)
    local flyoutConf = FlyoutMenusDb:get(flyoutId)
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
    zebug:line(20)
    if isInCombatLockdown("Reconfiguring") then return end

    clearGerms()
    local placements = self:getPlacementConfigForCurrentSpec()
    --debug:line(5, "getPlacementConfigForCurrentSpec",placements, " --->")
    --debug:dump(placements)
    for btnSlotIndex, flyoutId in pairs(placements) do
        local isThere = doesFlyoutExist(flyoutId)
        zebug:line(5, "flyoutId",flyoutId, "isThere", isThere)
        if isThere then
            bindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
        else
            -- because one toon can delete a flyout while other toons still have it on their bars
            zebug:line(5, "flyoutId",flyoutId, "doesFlyoutExists()","NOPE!!! DELETING!")
            GermCommander:deletePlacement(btnSlotIndex)
            zebug:line(5, "flyoutId",flyoutId, "doesFlyoutExists()","NOPE!!! DELETED!!!")
        end
    end
end

function GermCommander:newGermProxy(flyoutId, icon)
    DeleteMacro(PROXY_MACRO_NAME)
    local macroText = flyoutId
    return CreateMacro(PROXY_MACRO_NAME, icon or DEFAULT_ICON, macroText, nil, nil)
end

-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- Check if this event was caused by dragging a flyout out of the Catalog and dropping it onto an actionbar.
-- The targeted slot could: be empty; already have a different germ (or the same one); anything else.
function GermCommander:handleActionBarSlotChanged(btnSlotIndex)
    local configChanged
    local existingFlyoutId = getFlyoutIdForSlot(btnSlotIndex)

    local type, macroId = GetActionInfo(btnSlotIndex)
    zebug.trace:print("existingFlyoutId",existingFlyoutId, "type",type, "macroId",macroId)
    if not type then
        return
    end

    local droppedFlyoutId = self:getFlyoutIdFromGermProxy(type, macroId)
    if droppedFlyoutId then
        self:savePlacement(btnSlotIndex, droppedFlyoutId)
        DeleteMacro(PROXY_MACRO_NAME)
        configChanged = true
    end

    -- after dropping the flyout on the cursor, pickup the one we just replaced
    if existingFlyoutId then
        FlyoutMenu:pickup(existingFlyoutId)
        if not configChanged then
            GermCommander:deletePlacement(btnSlotIndex)
            configChanged = true
        end
    end

    if configChanged then
        self:updateAll()
    end
end

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
    flyoutId = FlyoutMenusDb:validateFlyoutId(flyoutId)
    zebug.info:print("btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId)
    self:getPlacementConfigForCurrentSpec()[btnSlotIndex] = flyoutId
end

function GermCommander:deletePlacement(btnSlotIndex)
    btnSlotIndex = tonumber(btnSlotIndex)
    local placementConfigForCurrentSpec = self:getPlacementConfigForCurrentSpec()
    local flyoutId = self:getPlacementConfigForCurrentSpec()[btnSlotIndex]
    zebug.info:print("GermCommander:deletePlacement() DELETING PLACEMENT", "btnSlotIndex",btnSlotIndex, "flyoutId", flyoutId, "placementConfigForCurrentSpec -->")
    zebug.trace:dumpy("placementConfigForCurrentSpec", placementConfigForCurrentSpec)
    -- the germ UI Frame stays in place but is now empty
    placementConfigForCurrentSpec[btnSlotIndex] = nil
end

function GermCommander:nukeFlyout(flyoutId)
    flyoutId = FlyoutMenusDb:validateFlyoutId(flyoutId)
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
    zebug:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 1",result)
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
    zebug:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 2",result)
    --debug:dump(result)
    return result
end

-- the placement of flyouts on the action bars is stored separately for each toon
function GermCommander:getAllSpecsPlacementsConfig()
    local foo = Config:getAllSpecsPlacementsConfig()
    return foo
end
