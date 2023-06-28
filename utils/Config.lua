-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local zebug = Ufo.Zebug:new()

---@class Config -- IntelliJ-EmmyLua annotation
local Config = {}
Ufo.Config = Config

-------------------------------------------------------------------------------
-- Flyouts
-------------------------------------------------------------------------------

function Config:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { flyouts={}, n=0 }
    end
end

function Config:nuke_a1()
    UFO_SV_ACCOUNT.flyouts = {}
end

function Config:nuke_a2()
    UFO_SV_ACCOUNT.n = 0
    UFO_SV_ACCOUNT.flyouts_a2 = {}
    UFO_SV_ACCOUNT.orderedFlyoutIds = {}
    UFO_SV_TOON.placementsForAllSpecs_a2 = {}
    UFO_SV_ACCOUNT.xedni = nil
    UFO_SV_ACCOUNT.flyoutXedni = nil
    UFO_SV_ACCOUNT.flyoutIdList = nil
    UFO_SV_ACCOUNT.OLD_flyouts = nil
end

-- the set of flyouts is shared between all toons on the account
function Config:getFlyoutDefs()
    return UFO_SV_ACCOUNT.flyouts
end

-- caches the computationally generated lookup index
function Config:getOrderedFlyoutIds()
    return UFO_SV_ACCOUNT.orderedFlyoutIds
end

function Config:nextN()
    UFO_SV_ACCOUNT.n = (UFO_SV_ACCOUNT.n or 0) + 1
    return UFO_SV_ACCOUNT.n
end

-------------------------------------------------------------------------------
-- Placements
-------------------------------------------------------------------------------

function Config:initializePlacements()
    if not UFO_SV_TOON then
        UFO_SV_TOON = { placementsForAllSpecs_a2 = {} }
    end
    -- TMP
    if not UFO_SV_TOON.placementsForAllSpecs_a2 then
        UFO_SV_TOON.placementsForAllSpecs_a2 = {}
    end

end

-- the placement of flyouts on the action bars is stored separately for each toon
function Config:getAllSpecsPlacementsConfig()
    return UFO_SV_TOON.placementsForAllSpecs_a2
end

-------------------------------------------------------------------------------
-- Versioning
-- In case I ever make changes to the data structure that breaks backwards compatibility,
-- putting version info in the config will let me detect old configs and convert them to the new format.
-------------------------------------------------------------------------------

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
