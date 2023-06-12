-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...

---@class Config -- IntelliJ-EmmyLua annotation
local Config = {}
Ufo.Config = Config

function Config:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { flyouts = {} }
    end
end

function Config:initializePlacements()
    if not UFO_SV_TOON then
        UFO_SV_TOON = { placementsForAllSpecs = {} }
    end
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
