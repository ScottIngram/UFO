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
function DB:getAllSpecsPlacementsConfig()
    return UFO_SV_TOON.placementsForAllSpecs
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
end
