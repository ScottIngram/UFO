-- GermCommander
-- collects and manages instances of the Germ class which sit on the action bars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

---@type Debug -- IntelliJ-EmmyLua annotation
local debugTrace, debugInfo, debugWarn, debugError = Debug:new(Debug.INFO)

---@type Germ -- IntelliJ-EmmyLua annotation
local Germ = Ufo.Germ

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local germs = {} -- copies of flyouts that sit on the action bars
local previousSpec
local currentSpec

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

local function getGerm(btnSlotIndex)
    return germs[btnSlotIndex]
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
local function rememberGerm(germ)
    local btnSlotIndex = germ:GetBtnSlotIndex()
    germs[btnSlotIndex] = germ
end

local function bindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
    -- examine the action/bonus/multi bar
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME .." config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.
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
        rememberGerm(germ)
    end
    debugInfo:out("*",3,"bindFlyoutToActionBarSlot()","germ...",germ)
    germ:Refresh(flyoutId, btnSlotIndex, direction, visibleIf)
end

local function clearGerms()
    for name, germ in pairs(germs) do
        germ:Hide()
        UnregisterStateDriver(germ, "visibility")
    end
end

function updateAllGerms()
    if InCombatLockdown() then
        return
    end
    clearGerms()
    local placements = getConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        bindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
    end
end

local function newGermProxy(flyoutId, texture)
    DeleteMacro(PROXY_MACRO_NAME)
    return CreateMacro(PROXY_MACRO_NAME, texture, flyoutId, nil, nil)
end

local function isGermProxy(type, macroId)
    local flyoutId
    if type == "macro" then
        local name, texture, body = GetMacroInfo(macroId)
        if name == PROXY_MACRO_NAME then
            flyoutId = body
        end
    end
    return flyoutId
end

local function getFlyoutIdForSlot(btnSlotIndex)
    return getConfigForCurrentSpec()[btnSlotIndex]
end

-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- Check if this event was caused by dragging a flyout out of the Catalog and dropping it onto an actionbar.
-- The targeted slot could: be empty; already have a different germ (or the same one); anything else.
function handleActionBarSlotChanged(btnSlotIndex)
    local configChanged
    local existingFlyoutId = getFlyoutIdForSlot(btnSlotIndex)

    local type, macroId = GetActionInfo(btnSlotIndex)
    if not type then
        return
    end

    local flyoutId = isGermProxy(type, macroId)
    if flyoutId then
        savePlacement(btnSlotIndex, flyoutId)
        DeleteMacro(PROXY_MACRO_NAME)
        configChanged = true
    end

    -- after dropping the flyout on the cursor, pickup the one we just replaced
    if existingFlyoutId then
        pickupFlyout(existingFlyoutId)
        if not configChanged then
            forgetPlacement(btnSlotIndex)
            configChanged = true
        end
    end

    if configChanged then
        updateAllGerms()
    end
end

function savePlacement(btnSlotIndex, flyoutId)
    if type(btnSlotIndex) == "string" then btnSlotIndex = tonumber(btnSlotIndex) end
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    getConfigForCurrentSpec()[btnSlotIndex] = flyoutId
end

function forgetPlacement(btnSlotIndex)
    if type(btnSlotIndex) == "string" then btnSlotIndex = tonumber(btnSlotIndex) end
    getConfigForCurrentSpec()[btnSlotIndex] = nil
end

-- when the user picks up a flyout from the catalog (or a germ from the actionbars?)
-- we need a draggable UI element, so create a dummy macro with the same icon as the flyout
function pickupFlyout(flyoutId)
    if InCombatLockdown() then
        return;
    end

    local flyoutConf = getFlyoutConfig(flyoutId)
    local texture = flyoutConf.icon

    if not texture and flyoutConf.actionTypes[1] then
        texture = getTexture(flyoutConf.actionTypes[1], flyoutConf.spells[1], flyoutConf.pets[1])
    end
    if not texture then
        texture = "INV_Misc_QuestionMark"
    end

    local proxy = newGermProxy(flyoutId, texture)
    PickupMacro(proxy)
end

local function getSpecId()
    return GetSpecialization() or NON_SPEC_SLOT
end

-- keep track of spec changes so getConfigForSpec() can initialize a brand new config based on the old one
function recordCurrentSpec()
    local newSpec = getSpecId()
    --[[DEBUG]] debugTrace:out("+",5,"recordCurrentSpec()", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
    if currentSpec ~= newSpec then
        previousSpec = currentSpec
        currentSpec = newSpec
        --[[DEBUG]] debugTrace:out("+",5,"REASSIGNED->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        return true
    else
        --[[DEBUG]] debugTrace:out("+",5,"unchanged ->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        return false
    end
end

-- I originally created this method to handle the PLAYER_SPECIALIZATION_CHANGED event
-- but, in consitent bliz inconsistency, it's unreliable whether that event
-- will shoot off before, during, or after the ACTIONBAR_SLOT_CHANGED event which also will trigger updateAllGerms()
-- so, I had to move recordCurrentSpec() directly into getConfigForCurrentSpec() and am leaving this here as a monument.
function changePlacementsBecauseSpecChanged()
    -- recordCurrentSpec() -- nope, nevermind.  moved below
    updateAllGerms()
end

function getConfigForCurrentSpec()
    recordCurrentSpec() --
    local specId = getSpecId()
    return getConfigForSpec(specId)
end

function getConfigForSpec(specId)
    -- the placement of flyouts on the action bars changes from spec to spec
    local placementsForAllSpecs = getGermPlacementsConfig()
    assert(placementsForAllSpecs,"Oops!  placements config is nil")

    -- is this a never-before-encountered spec? - if so, initialze its config
    --[[DEBUG]] debugTrace:out("+",5,"getConfigForSpec().....", "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "placementsForAllSpecs[specId]",placementsForAllSpecs[specId])
    if not placementsForAllSpecs[specId] then -- TODO: identify empty OR nil
        local initialConfig
        if not previousSpec or specId == previousSpec then
            --[[DEBUG]] debugTrace:out("+",7,"getConfigForSpec() blanking", "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec)
            initialConfig = {}
        else
            -- initialize the new config based on the old one
            --[[DEBUG]] debugTrace:out("+",7,"getConfigForSpec() COPYING", "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec)
            initialConfig = deepcopy(getConfigForSpec(previousSpec))
            --[[DEBUG]] debugTrace:dump(initialConfig)
        end
        placementsForAllSpecs[specId] = initialConfig
    end
    return placementsForAllSpecs[specId]
end

-- the placement of flyouts on the action bars is stored separately for each toon
function getGermPlacementsConfig()
    return UFO_SV_TOON and UFO_SV_TOON.placementsForAllSpecs
end
