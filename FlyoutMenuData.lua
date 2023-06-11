-- FlyoutMenuData
-- unique flyout definitions shown in the config panel
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- TODO: invert the FlyoutMenu data structure
-- TODO: * implement as array of self-contained button objects rather than each button spread across multiple parallel arrays
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(DEBUG_OUTPUT.WARN)

---@class FlyoutMenuData -- IntelliJ-EmmyLua annotation
local FlyoutMenuData = {}
Ufo.FlyoutMenuData = FlyoutMenuData

--[[
--TODO: implement as OO

Ufo.FlyoutMenuData = {}
Ufo.Wormhole(Ufo.FlyoutMenuData, Ufo) -- now it's FlyoutMenuData inheriting from Ufo

local flyoutsConfigurator = Ufo.getFlyoutMenusConfigurator()
local flyoutConfig = flyoutsConfigurator:get(flyoutId) -- also :new() :add(flyout); :delete(flyoutId);
local flyoutBtns = flyoutConfig:getButtons()
local flyoutBtn1 = flyoutConfig:getButton(1)
flyoutConfig:addButton(myNewBtn) -- or smarter DWIM behavior that takes a macro or pet or mount etc.  Or the AceBtn ? no.
]]

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- "spell" can mean also item, mount, macro, etc.
STRUCT_FLYOUT_DEF = { spells={}, actionTypes={}, mounts={}, spellNames={}, macroOwners={}, pets={} }

NEW_STRUCT_FLYOUT_DEF = { id=false, name="", icon="", btns={} }
NEW_STRUCT_FLYOUT_BTN_DEF = { type="", spellId="", mountId="", spellName="", macroOwner="", pet="", }

-------------------------------------------------------------------------------
-- Flyout Menu Functions - SavedVariables, config CRUD
-------------------------------------------------------------------------------

function updateVersionId()
    UFO_SV_FLYOUTS.v = VERSION
    UFO_SV_FLYOUTS.V_MAJOR = V_MAJOR
    UFO_SV_FLYOUTS.V_MINOR = V_MINOR
    UFO_SV_FLYOUTS.V_PATCH = V_PATCH
end

-- compares the config's stored version to input parameters
function isConfigOlderThan(major, minor, patch, ufo)
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

function getFlyoutsConfig()
    return UFO_SV_ACCOUNT and UFO_SV_ACCOUNT.flyouts
end

function getFlyoutConfig(flyoutId)
    assert(flyoutId and type(flyoutId)=="number", "Bad flyoutId arg.")
    local config = getFlyoutsConfig()
    assert(config, "Flyouts config structure is abnormal.")
    local flyoutConfig = config[flyoutId]
    --[[DEBUG]] debug.trace:print(flyoutConfig, "No config found for #"..flyoutId)
    return flyoutConfig
end

local function getNewFlyoutDef()
    return deepcopy(STRUCT_FLYOUT_DEF)
end

function addFlyout()
    local newFlyoutDef = getNewFlyoutDef()
    local flyoutsConfig = getFlyoutsConfig()
    table.insert(flyoutsConfig, newFlyoutDef)
    return newFlyoutDef
end

function deleteFlyout(flyoutId)
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    table.remove(getFlyoutsConfig(), flyoutId)
    -- shift references -- TODO: stop this.  Indices are not a precious resource.  And, this will get really complicated for mixing global & toon
    local placementsForEachSpec = getGermPlacementsConfig()
    --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()","flyoutId",flyoutId)
    --[[DEBUG]] debug.trace:dump(placementsForEachSpec)
    for spec, placementsForSpec in pairs(placementsForEachSpec) do
        --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()", "flyId", flyId, "flyoutId",flyoutId, "spec", spec)
        for btnSlotIndex, flyId in pairs(placementsForSpec) do
            --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()", "flyId", flyId, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex)
            if flyId == flyoutId then
                placementsForSpec[btnSlotIndex] = nil
            elseif flyId > flyoutId then
                placementsForSpec[btnSlotIndex] = flyId - 1
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Flyout Button Functions
-------------------------------------------------------------------------------

function removeSpell(flyoutId, spellPos)
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    if type(spellPos) == "string" then spellPos = tonumber(spellPos) end
    local flyoutConf = getFlyoutConfig(flyoutId)
    table.remove(flyoutConf.spells, spellPos)
    table.remove(flyoutConf.actionTypes, spellPos)
    table.remove(flyoutConf.mounts, spellPos)
    table.remove(flyoutConf.spellNames, spellPos)
    table.remove(flyoutConf.macroOwners, spellPos)
    table.remove(flyoutConf.pets, spellPos)
end
