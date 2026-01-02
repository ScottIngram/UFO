-- DB
-- access to Bliz's persisted data facility

-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them here
-- there is no call to Wormhole() so we're in the global namespace, NOT in the Ufo !
-------------------------------------------------------------------------------

---@class DB
local DB = {}

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.DB = DB

local L10N = Ufo.L10N

---@alias SpecId number
---@alias FlyoutId string
---@alias Placements table<BtnSlotIndex,FlyoutId>
---@alias PlacementsForAllSpecs table<SpecId,Placements>

-------------------------------------------------------------------------------
-- Flyouts
-------------------------------------------------------------------------------

function DB:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { flyouts={}, n=0, orderedFlyoutIds={} }
    end
end

-- the set of flyouts is shared between all toons on the account
function DB:getFlyoutDefs()
    return UFO_SV_ACCOUNT.flyouts
end

function DB:getOrderedFlyoutIds()
    return UFO_SV_ACCOUNT.orderedFlyoutIds
end

function DB:nextN()
    UFO_SV_ACCOUNT.n = (UFO_SV_ACCOUNT.n or 0) + 1
    return UFO_SV_ACCOUNT.n
end

-------------------------------------------------------------------------------
-- Placements
-------------------------------------------------------------------------------

function DB:initializePlacements()
    if not UFO_SV_TOON then
        UFO_SV_TOON = { placementsForAllSpecs = {} }
    end
end

-- the placement of flyouts on the action bars is stored separately for each toon
---@return PlacementsForAllSpecs
function DB:getAllSpecsPlacementsConfig()
    ---@type PlacementsForAllSpecs
    return UFO_SV_TOON.placementsForAllSpecs
end

function DB:snapshotSave()
    local placements = Ufo.Spec:getCurrentSpecPlacementConfig()
    if Ufo.isEmpty(placements) then
        Ufo.zebug.error:print("Current config is empty.  ABORT snapshot")
        return
    end

    UFO_SV_ACCOUNT.placementsDefaultSnapshot = placements
    Ufo.msgUser(Ufo.L10N.SAVED_SNAPSHOT)
end

function DB:snapshotLoad()
    local placements = UFO_SV_ACCOUNT.placementsDefaultSnapshot
    if Ufo.isEmpty(placements) then
        Ufo.zebug.error:print("Snapshot is empty.  ABORT load snapshot")
        return
    end

    Ufo.Spec:replaceCurrentSpecPlacementConfig(placements)
    Ufo.GermCommander:initializeAllSlots("Load_Snapshot")
    Ufo.msgUser(Ufo.L10N.LOADED_SNAPSHOT)
end

function DB:isThereUhSnapshot()
    local placements = UFO_SV_ACCOUNT.placementsDefaultSnapshot
    return not Ufo.isEmpty(placements)
end

function DB:isNoSnapshot()
    return not DB:isThereUhSnapshot()
end



function DB:canHazPet(arg)
    local specId = GetSpecialization()
    if UFO_SV_TOON.canHazPet == nil then
        UFO_SV_TOON.canHazPet = {}
    end

    if arg ~= nil then
        UFO_SV_TOON.canHazPet[specId] = arg and true or false
    end
    return UFO_SV_TOON.canHazPet[specId] or false
end


-------------------------------------------------------------------------------
-- Config Opts
-------------------------------------------------------------------------------

function DB:initializeOptsMemory()
    if not UFO_SV_ACCOUNT.opts then
        UFO_SV_ACCOUNT.opts = Ufo.Config:getOptionDefaults()
    end

    ---@type Config
    local Config = Ufo.Config
    Config.opts = UFO_SV_ACCOUNT.opts
    Config.optDefaults = Config:getOptionDefaults()

    -- new opt introduced by UFO v10.1.7.a
    if not Config.opts.clickers then
        Config.opts.clickers = Config.optDefaults.clickers
    end

    -- new opt introduced by UFO 11.2.0
    if not Config.opts.bonusModifierKeys then
        Config.opts.bonusModifierKeys = {}
    end
end
