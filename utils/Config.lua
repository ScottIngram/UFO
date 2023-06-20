-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local debug = Ufo.Debug:new()

---@class Config -- IntelliJ-EmmyLua annotation
local Config = {}
Ufo.Config = Config

function Config:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { neoFlyouts = {} }
    end
end

function Config:tmpNeoNuke()
    UFO_SV_ACCOUNT.neoFlyouts = {}
end

-- the set of flyouts is shared between all toons on the account
function Config:getFlyoutsConfig()
    return UFO_SV_ACCOUNT.neoFlyouts
end

function Config:initializePlacements()
    if not UFO_SV_TOON then
        UFO_SV_TOON = { placementsForAllSpecs = {} }
    end
end

-- the placement of flyouts on the action bars is stored separately for each toon
function Config:getAllSpecsPlacementsConfig()
    return UFO_SV_TOON.placementsForAllSpecs
end

function Config:updateVersionId()
    UFO_SV_FLYOUTS.v = VERSION
    UFO_SV_FLYOUTS.V_MAJOR = V_MAJOR
    UFO_SV_FLYOUTS.V_MINOR = V_MINOR
    UFO_SV_FLYOUTS.V_PATCH = V_PATCH
end

-- compares the config's stored version to input parameters
function Config:isConfigOlderThan(major, minor, patch, ufo)
    local configMajor = UFO_SV_FLYOUTS.V_MAJOR
    local configMinor = UFO_SV_FLYOUTS.V_MINOR
    local configPatch = UFO_SV_FLYOUTS.V_PATCH
    local configUfo   = UFO_SV_FLYOUTS.V_UFO

    if not (configMajor and configMinor and configPatch) then
        return true
    elseif configMajor < major then
        return true
    elseif configMinor < minor then
        return true
    elseif configPatch < patch then
        return true
    elseif configUfo < ufo then
        return true
    else
        return false
    end
end
