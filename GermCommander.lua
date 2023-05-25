-- GermCommander
-- collects and manages instances of the Germ class which sit on the action bars

local ADDON_NAME, Ufo = ...
local debug = Ufo.DEBUG.newDebugger(Ufo.DEBUG.TRACE)
local L10N = Ufo.L10N
local GermCommander = Ufo

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

GermCommander.germs = {} -- copies of flyouts that sit on the action bars

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function GermCommander:ApplyConfig()
    if InCombatLockdown() then
        return
    end
    self:ClearGerms()
    local placements = self:GetSpecificConditionalFlyoutPlacements()
    for btnSlotIndex, flyoutId in pairs(placements) do
        self:BindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
    end
end


function isGermProxy(type, macroId)
    local flyoutId
    if type == "macro" then
        local name, texture, body = GetMacroInfo(macroId)
        if name == PROXY_MACRO_NAME then
            flyoutId = body
        end
    end
    return flyoutId
end

-- Check if this event was caused by dragging a flyout out of the Catalog and dropping it onto an actionbar.
-- The targeted slot could: be empty; already have a different germ (or the same one); anything else.
function handleActionBarSlotChanged(actionBarSlotId)
    local configChanged
    local existingFlyoutId = GermCommander:GetSpecificConditionalFlyoutPlacements()[actionBarSlotId]

    local type, macroId = GetActionInfo(actionBarSlotId)
    if not type then
        return
    end

    local flyoutId = isGermProxy(type, macroId)
    if flyoutId then
        GermCommander:SavePlacement(actionBarSlotId, flyoutId)
        DeleteMacro(PROXY_MACRO_NAME)
        configChanged = true
    end

    -- after dropping the flyout on the cursor, pickup the one we just replaced
    if existingFlyoutId then
        GermCommander:PickupFlyout(existingFlyoutId)
        if not configChanged then
            GermCommander:ForgetPlacement(actionBarSlotId)
            configChanged = true
        end
    end

    if configChanged then
        GermCommander:ApplyConfig()
    end
end


function GermCommander:ApplyOperationToAllGermInstancesUnlessInCombat(callback)
    if InCombatLockdown() then return end
    self:ApplyOperationToAllGermInstances(callback)
end

function GermCommander:BindFlyoutToActionBarSlot(flyoutId, btnSlotIndex)
    -- examine the action/bonus/multi bar
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local blizBarDef = BLIZ_BAR_METADATA[barNum]
    assert(blizBarDef, "No ".. ADDON_NAME .." config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.
    local blizBarName = blizBarDef.name
    local visibleIf = blizBarDef.visibleIf
    local typeActionButton = blizBarDef.classicType -- for WoW classic

    -- examine the button
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local btnName = blizBarName .. "Button" .. btnNum
    local btnObj = _G[btnName] -- grab the button object from Blizzard's GLOBAL dumping ground

    -- ask the bar instance what direction to fly
    local barObj = btnObj and btnObj.bar
    local direction = barObj and barObj:GetSpellFlyoutDirection() or "UP" -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs

    --local foo = btnObj and "FOUND" or "NiL"
    --print ("###--->>> ffUniqueId =", ffUniqueId, "barNum =",barNum, "slotId = ", btnSlotIndex, "btnObj =",foo, "blizBarName = ",blizBarName,  "btnName =",btnName,  "btnNum =",btnNum, "direction =",direction, "visibleIf =", visibleIf)

    Ufo:CreateGerm(btnSlotIndex, flyoutId, direction, btnObj, visibleIf, typeActionButton)
end

function GermCommander:ClearGerms()
    for name, germ in pairs(germs) do
        germ:Hide()
        UnregisterStateDriver(germ, "visibility")
    end
end

-------------------------------------------------------------------------------
-- Placement Functions
-------------------------------------------------------------------------------
-- assigned action bar button slots
-- TODO: move into FlyoutConfigData
local DEFAULT_PLACEMENTS_CONFIG = {
    -- each class spec has its own set of placements
    [1] = {
        -- config format:
        -- [action bar slot] = flyout Id
        -- each button on the bliz action bars has a slot ID which is which we place a flyout ID (see above)
        -- [13] = 1, -- button #13 holds flyout #1
        -- [49] = 3, -- button #49 holds flyout #3
        -- [125] = 2, -- button #125 holds flyout #2
    },
    [2] = {
    },
    [3] = {
    },
    [4] = {
    },
    -- spec-agnostic slot
    [5] = {
    },
}

function GermCommander:InitializePlacementConfigIfEmpty(mayUseLegacyData)
    if self:GetFlyoutPlacementsForToon() then
        return
    end

    local placementsForAllSpecs
    local legacyData = mayUseLegacyData and UFO_SV_PLACEMENT and UFO_SV_PLACEMENT.actions
    if legacyData then
        placementsForAllSpecs = deepcopy(legacyData)
        fixLegacyActionsNils(placementsForAllSpecs)
        UFO_SV_PLACEMENT.actions_note = "the actions field is old and no longer used by the current version of this addon"
    else
        placementsForAllSpecs = deepcopy(DEFAULT_PLACEMENTS_CONFIG)
    end

    self:PutFlyoutPlacementsForToon(placementsForAllSpecs)
end

function fixLegacyActionsNils(actions)
    for i=3,5 do
        if actions[i] == nil then
            actions[i] = {}
        end
    end
end

function GermCommander:SavePlacement(slotId, flyoutId)
    if type(slotId) == "string" then slotId = tonumber(slotId) end
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    self:GetSpecificConditionalFlyoutPlacements()[slotId] = flyoutId
end

function GermCommander:ForgetPlacement(slotId)
    if type(slotId) == "string" then slotId = tonumber(slotId) end
    self:GetSpecificConditionalFlyoutPlacements()[slotId] = nil
end

-- when the user picks up a flyout, we need a draggable UI element, so create a dummy macro with the same icon as the flyout
function GermCommander:PickupFlyout(flyoutId)
    if InCombatLockdown() then
        return;
    end

    local flyoutConf = self:GetFlyoutConfig(flyoutId)
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

function newGermProxy(flyoutId, texture)
    DeleteMacro(PROXY_MACRO_NAME)
    return CreateMacro(PROXY_MACRO_NAME, texture, flyoutId, nil, nil)
end

function GermCommander:GetSpecificConditionalFlyoutPlacement(actionBarSlotId)
    local placements = self:GetSpecificConditionalFlyoutPlacements()
    return placements[actionBarSlotId]
end

function GermCommander:GetSpecificConditionalFlyoutPlacements()
    local placements = self:GetFlyoutPlacementsForToon()
    local spec = self:GetSpecSlotId()
    return placements and placements[spec]
end

-- the placement of flyouts on the action bars is stored separately for each toon
function GermCommander:PutFlyoutPlacementsForToon(flyoutPlacements)
    if not UFO_SV_PLACEMENT then
        UFO_SV_PLACEMENT = {}
    end

    UFO_SV_PLACEMENT.flyoutPlacements = flyoutPlacements

    --if not Db.profile.placementsPerToonAndSpec then
    --	Db.profile.placementsPerToonAndSpec = {}
    --end

    --local playerId = getIdForCurrentToon()
    --Db.profile.placementsPerToonAndSpec[playerId] = flyoutPlacements
end

function GermCommander:GetFlyoutPlacementsForToon()
    return UFO_SV_PLACEMENT and UFO_SV_PLACEMENT.flyoutPlacements
    --local playerId = getIdForCurrentToon()
    --local ppts = Db.profile.placementsPerToonAndSpec
    --return ppts and ppts[playerId]
end
