-- FlyoutMenuConfig
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- TODO: invert the FlyoutMenu data structure
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

local ADDON_NAME, Ufo = ...
local debug = Ufo.DEBUG.newDebugger(Ufo.DEBUG.TRACE)
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

--[[
--TODO: implement as OO

Ufo.FlyoutMenuConfig = {}
Ufo.Wormhole(Ufo.FlyoutMenuConfig, Ufo) -- now it's FlyoutMenuConfig inheriting from Ufo

local flyoutsConfigurator = Ufo.getFlyoutMenusConfigurator()
local flyoutConfig = flyoutsConfigurator:get(flyoutId) -- also :new() :add(flyout); :delete(flyoutId);
local flyoutBtns = flyoutConfig:getButtons()
local flyoutBtn1 = flyoutConfig:getButton(1)
flyoutConfig:addButton(myNewBtn) -- or smarter DWIM behavior that takes a macro or pet or mount etc.  Or the AceBtn ? no.
]]

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- unique flyout definitions shown in the config panel
-- TODO: eliminate inner "flyout"
-- TODO: * implement as array of self-contained button objects rather than each button spread across multiple parallel arrays

local DEFAULT_UFO_SV_FLYOUT_DEF = {
    flyouts = {
        --[[ Sample config : each flyout can have a list of actions and an icon
        [1] = {
            actionTypes = {
                [1] = "spell",
                [2] = "item",
                [3] = "macro",
                [4] = "battlepet"
            },
            spells = {
                [1] = 8024, -- Flametongue
                [2] = 8033, -- Frostbite
                [3] = 8232, -- Windfury
                [4] = 8017, -- RockBite
                [5] = 51730, -- earthliving
            },
            icon = ""
        },
        [2] = { ... etc ... }, etc...
        ]]
    },
}

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

function initializeFlyoutConfigIfEmpty(mayUseLegacyData)
    debug.info:out("*",3,"InitializeFlyoutConfigIfEmpty()")
    if getFlyoutsConfigs() then
        return
    end

    local flyouts

    -- support older versions of the addon
    local legacyData = mayUseLegacyData and UFO_SV_PLACEMENT and UFO_SV_PLACEMENT.flyouts
    if legacyData then
        flyouts = deepcopy(legacyData)
        fixLegacyFlyoutsNils(flyouts)
        UFO_SV_PLACEMENT.flyouts_note = "the flyouts field is old and no longer used by the current version of this addon"
    else
        flyouts = deepcopy(DEFAULT_UFO_SV_FLYOUT_DEF)
    end

    putFlyoutConfig(flyouts)
end


-- the flyout definitions are stored account-wide and thus shared between all toons
function putFlyoutConfig(flyouts)
    if not UFO_SV_FLYOUTS then
        UFO_SV_FLYOUTS = {}
    end
    UFO_SV_FLYOUTS.flyouts = flyouts
end

function getFlyoutsConfigs()
    return UFO_SV_FLYOUTS and UFO_SV_FLYOUTS.flyouts
    --return Db.profile.flyouts
end

local doneChecked = {}

-- get and validate the requested flyout config
function getFlyoutConfig(flyoutId)
    local config = getFlyoutsConfigs()
    local flyoutConfig = config and (config[flyoutId])

    -- check that the data structure is complete
    -- because old versions of the addon may have saved less data than now needed
    -- but check each specific flyoutId only once
    if doneChecked[flyoutId] then return flyoutConfig end
    doneChecked[flyoutId] = true
    if not flyoutConfig then return nil end

    -- init any missing parts
    for k,_ in pairs(STRUCT_FLYOUT_DEF) do
        if not flyoutConfig[k] then

            flyoutConfig[k] = {}
        end
    end

    return flyoutConfig
end

function fixLegacyFlyoutsNils(flyouts)
    for _, flyout in ipairs(flyouts) do
        if flyout.actionTypes == nil then
            flyout.actionTypes = {}
            for i, _ in ipairs(flyout.spells) do
                flyout.actionTypes[i] = "spell"
            end
        end
        if flyout.mountIndex == nil then
            flyout.mountIndex = {}
        end
        if flyout.spellNames == nil then
            flyout.spellNames = {}
        end
    end
end


-- "spell" can mean also item, mount, macro, etc.
STRUCT_FLYOUT_DEF = { spells={}, actionTypes={}, mountIndex={}, spellNames={}, macroOwners={}, pets={} }
NEW_STRUCT_FLYOUT_DEF = { id=false, name="", icon="", btns={} }
NEW_STRUCT_FLYOUT_BTN_DEF = { type="", spellId="", mountIndex="", spellName="", macroOwner="", pet="", }


function getNewFlyoutDef()
    return deepcopy(STRUCT_FLYOUT_DEF)
end

function addFlyout()
    local newFlyoutDef = getNewFlyoutDef()
    local flyoutsConfig = getFlyoutsConfigs()
    table.insert(flyoutsConfig, newFlyoutDef)
    return newFlyoutDef
end

function removeFlyout(flyoutId)
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    table.remove(getFlyoutsConfigs(), flyoutId)
    -- shift references -- TODO: stop this.  Indices are not a precious resource.  And, this will get really complicated for mixing global & toon
    local placementsForEachSpec = getFlyoutPlacementsForToon()
    for i = 1, #placementsForEachSpec do
        local placements = placementsForEachSpec[i]
        for slotId, fId in pairs(placements) do
            if fId == flyoutId then
                placements[slotId] = nil
            elseif fId > flyoutId then
                placements[slotId] = fId - 1
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
    table.remove(flyoutConf.mountIndex, spellPos)
    table.remove(flyoutConf.spellNames, spellPos)
    table.remove(flyoutConf.macroOwners, spellPos)
    table.remove(flyoutConf.pets, spellPos)
end
