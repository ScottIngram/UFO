-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local zebug = Ufo.Zebug:new()

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
local Options = {
    supportCombat   = true,
    doCloseOnClick  = true,
    usePlaceHolders = true,
}

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
local Config = {
    opts = Options
}
Ufo.Config = Config

local opts = Config.opts

-------------------------------------------------------------------------------
-- Flyouts
-------------------------------------------------------------------------------

function Config:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { flyouts={}, n=0, orderedFlyoutIds={} }
    end
end

-- the set of flyouts is shared between all toons on the account
function Config:getFlyoutDefs()
    return UFO_SV_ACCOUNT.flyouts
end

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
        UFO_SV_TOON = { placementsForAllSpecs = {} }
    end
end

-- the placement of flyouts on the action bars is stored separately for each toon
function Config:getAllSpecsPlacementsConfig()
    return UFO_SV_TOON.placementsForAllSpecs
end

-------------------------------------------------------------------------------
-- Configuration Menu UI
-------------------------------------------------------------------------------

function Config:getOpts()
    self.initializeOptsMemory()
    return Config.opts
end

function Config:initializeOptsMemory()
    if not UFO_SV_ACCOUNT.opts then
        UFO_SV_ACCOUNT.opts = Options
    end
end

local optionsMenu = {

}

function Config:initializeOptionsMenu()
    --local db = LibStub("AceDB-3.0"):New("ImmersiveFade", defaults)
    --options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsMenu, { "ifade", "immersivefade" })
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, Ufo.myName)
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
