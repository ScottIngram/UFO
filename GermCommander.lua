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
-- Constants
-------------------------------------------------------------------------------

BLIZ_BAR_METADATA = {
    [1]  = {name="Action",              visibleIf="bar:1,nobonusbar:1,nobonusbar:2,nobonusbar:3,nobonusbar:4"}, -- primary "ActionBar" - page #1 - no stance/shapeshift --- ff: actionBarPage = 1
    [2]  = {name="Action",              visibleIf="bar:2"}, -- primary "ActionBar" - page #2 (regardless of stance/shapeshift) --- ff: actionBarPage = 2
    [3]  = {name="MultiBarRight",       }, -- config UI -> Action Bars -> checkbox #4
    [4]  = {name="MultiBarLeft",        }, -- config UI -> Action Bars -> checkbox #5
    [5]  = {name="MultiBarBottomRight", }, -- config UI -> Action Bars -> checkbox #3
    [6]  = {name="MultiBarBottomLeft",  }, -- config UI -> Action Bars -> checkbox #2
    [7]  = {name="Action",              visibleIf="bar:1,bonusbar:1"}, -- primary "ActionBar" - page #1 - bonusbar 1 - druid CAT
    [8]  = {name="Action",              visibleIf="bar:1,bonusbar:2"}, -- primary "ActionBar" - page #1 - bonusbar 2 - unknown?
    [9]  = {name="Action",              visibleIf="bar:1,bonusbar:3"}, -- primary "ActionBar" - page #1 - bonusbar 3 - druid BEAR
    [10] = {name="Action",              visibleIf="bar:1,bonusbar:4"}, -- primary "ActionBar" - page #1 - bonusbar 4 - druid MOONKIN
    [11] = {name="Action",              visibleIf="bar:1,bonusbar:5"}, -- primary "ActionBar" - page #1 - bonusbar 5 - dragon riding
    [12] = {name="Action",              visibleIf="bar:1,bonusbar:6"--[[just a guess]]}, -- unknown?
    [13] = {name="MultiBar5"}, -- config UI -> Action Bars -> checkbox #6
    [14] = {name="MultiBar6"}, -- config UI -> Action Bars -> checkbox #7
    [15] = {name="MultiBar7"}, -- config UI -> Action Bars -> checkbox #8
}

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
                -- create a new germ
                local bbInfo = self:extractBarBtnInfo(btnSlotIndex)
                local parent = self:getActionBarBtn(bbInfo)
                germ = Germ.new(flyoutId, btnSlotIndex, parent)
                self:saveGerm(germ)
            end
            germ:update(flyoutId)
            if Config.opts.usePlaceHolders then
                if not self:hasPlaceholder(btnSlotIndex) then
                    self:putPlaceholder(btnSlotIndex)
                end
            end
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

function GermCommander:getActionBarBtn(bbInfo)
    local actionBarBtn
    if ThirdPartyAddonSupport.isAnyActionBarAddonActive then
        actionBarBtn = ThirdPartyAddonSupport:getParent(bbInfo)
    end
    if not actionBarBtn then
        actionBarBtn = _G[bbInfo.actionBarBtnName] -- default to the standard Bliz object
    end
    actionBarBtn.visibleIf = bbInfo.visibleIf
    return actionBarBtn
end

function GermCommander:extractBarBtnInfo(btnSlotIndex)
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.
    local actionBarName    = actionBarDef.name
    local actionBarBtnName = actionBarName .. "Button" .. btnNum

    return {
        btnSlotIndex     = btnSlotIndex,
        barNum           = barNum,
        btnNum           = btnNum,
        actionBarDef     = actionBarDef,
        actionBarName    = actionBarName,
        actionBarBtnName = actionBarBtnName,
        visibleIf        = actionBarDef.visibleIf,
    }
end

function GermCommander:createPlaceholder()
    Ufo.thatWasMe = true
    local exists = GetMacroInfo(PLACEHOLDER_MACRO_NAME)
    if not exists then
        local icon = C_AddOns.GetAddOnMetadata(ADDON_NAME, "IconTexture")
        zebug.info:print("name",PLACEHOLDER_MACRO_NAME, "icon",icon, "PLACEHOLDER_MACRO_TEXT", PLACEHOLDER_MACRO_TEXT)
        CreateMacro(PLACEHOLDER_MACRO_NAME, icon, PLACEHOLDER_MACRO_TEXT)
    end
end

function GermCommander:pickupPlaceHolder()
    self:createPlaceholder()
    PickupMacro(PLACEHOLDER_MACRO_NAME)
end

function GermCommander:newGermProxy(flyoutId, icon)
    self:deleteProxy()
    return self:createProxy(flyoutId, icon)
end

function GermCommander:deleteProxy()
    Ufo.thatWasMe = true
    DeleteMacro(PROXY_MACRO_NAME)
    -- workaround Bliz bug - make sure the macro frame accurately reflects that the macro has been deleted
    if MacroFrame:IsShown() then
        MacroFrame:Update()
    end
end

function doKillProxy()
    local proxyExists = GetMacroInfo(PROXY_MACRO_NAME)
    local isDraggingProxy = GermCommander:isDraggingProxy()
    local doKillProxy = proxyExists and not isDraggingProxy
    zebug.trace:print("proxyExists",proxyExists, "isDraggingProxy",isDraggingProxy, "doKillProxy", doKillProxy)
    return doKillProxy
end

function GermCommander:delayedAsynchronousConditionalDeleteProxy()
    zebug.trace:print("checking proxy...")
    if doKillProxy() then
        zebug.trace:print("deleting proxy in 1 second...")
        C_Timer.After(1,
            -- START callback
            function()
                zebug.trace:print("double checking proxy...")
                if doKillProxy() then
                    zebug.trace:print("DIE PROXY !!!")
                    self:deleteProxy()
                end
            end
        ) -- END callback
    end
end

function GermCommander:createProxy(flyoutId, icon)
    Ufo.thatWasMe = true
    local macroText = flyoutId
    return CreateMacro(PROXY_MACRO_NAME, icon or DEFAULT_ICON, macroText)
end

-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- Check if this event was caused by dragging a flyout out of the Catalog and dropping it onto an actionbar.
-- The targeted slot could: be empty; already have a different germ (or the same one); anything else.
function GermCommander:handleActionBarSlotChanged(btnSlotIndex)
    if Ufo.droppedUfoOntoActionBar then
        -- we triggered this event ourselves elsewhere and don't need to do anything more
        Ufo.droppedUfoOntoActionBar = false
        return
    end

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
        GermCommander:dropUfoOntoActionBar(btnSlotIndex, droppedFlyoutId)
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

function GermCommander:dropUfoOntoActionBar(btnSlotIndex, flyoutId)
    self:savePlacement(btnSlotIndex, flyoutId)
    self:deleteProxy()
    if Config.opts.usePlaceHolders then
        self:putPlaceholder(btnSlotIndex)
    end
end

function GermCommander:putPlaceholder(btnSlotIndex)
    Ufo.droppedUfoOntoActionBar = true
    self:pickupPlaceHolder()
    zebug.trace:print("btnSlotIndex",btnSlotIndex)
    PlaceAction(btnSlotIndex)
end

function GermCommander:clearUfoPlaceholderFromActionBar(btnSlotIndex)
    if Config.opts.usePlaceHolders then
        -- pickup whatever it is onto the mouse cursor.
        -- assume it's a UFO placeholder.  assume the cursor will be cleared later
        PickupAction(btnSlotIndex)
    end
end

function GermCommander:hasPlaceholder(btnSlotIndex)
    local type, id = GetActionInfo(btnSlotIndex)
    zebug.trace:print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

function GermCommander:ensureAllGermsHavePlaceholders()
    self:createPlaceholder()
    self:updateAll()
end

function GermCommander:nukePlaceholder()
    while GetMacroInfo(PLACEHOLDER_MACRO_NAME) do
        DeleteMacro(PLACEHOLDER_MACRO_NAME)
    end
end

