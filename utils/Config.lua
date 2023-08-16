-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...

---@type Zebuggers
local zebug = Ufo.Zebug:new()

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean placate Bliz security rules of "don't SetAnchor() during combat"
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
local Options = {
    supportCombat   = true,
    doCloseOnClick  = true,
    usePlaceHolders = true,
}

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
local Config = {}
Ufo.Config = Config

local opts

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
-- Config Opts
-------------------------------------------------------------------------------

function Config:initializeOptsMemory()
    print("Config:initializeOptsMemory")
    if not UFO_SV_ACCOUNT.opts then
        UFO_SV_ACCOUNT.opts = Options
    end
    Config.opts = UFO_SV_ACCOUNT.opts
    opts = Config.opts
end

-------------------------------------------------------------------------------
-- Configuration Options Menu UI
-------------------------------------------------------------------------------

function getOptTitle() return Ufo.myTitle  end

local optionsMenu = {
    name = getOptTitle,
    type = "group",
    args = {
        helpText = {
            order = 10,
            type = 'description',
            name = [=[
UFO lets you create custom actionbar flyout menus similar to the built-in ones for mage portals, warlock demons, dragonriding abilities, etc.  But with UFO, you can include anything you want:

* Spells
* Items
* Mounts
* Pets
* Macros
* Trade skill Windows

UFO adds a flyout catalog UI onto the side of various panels (Spellbook, Macros, Collections) to let you create and organize multiple flyouts.  These can be shared between all characters on your account.

From there, you can drag your flyouts onto your action bars.  Each toon keeps their own distinct record of which flyouts are on which bars.  Furthermore, placements are stored per spec and automatically change when you change your spec.

]=]
        },
        url = {
            order = 11,
            name = "Full documentation can be found on Curseforge",
            type = "input",
            width = "double",
            get = function() return "https://curseforge.com/wow/addons/ufo/"  end
        },
        configHeader = {
            order = 20,
            name = "Configuration",
            type = 'header',
        },
        helpTextForPlaceHolders = {
            order = 40,
            type = 'description',
            name = [=[
Because UFOs aren't real buttons, when they are placed on an action bar the UI thinks it's empty and typically leaves it hidden.

To solve this, two workarounds exist: Extra UI configuration OR Placeholder macros.

Extra UI configuration: You must set the \"Always Show Buttons\" config option for action bars in Bliz UI \"Edit Mode\" (or \"Button Grid\" in Bartender4).

Placeholder macros: UFO will
Without this macro, you must set "Always Show Buttons" in Edit Mode (or "Button Grid" in Bartender4). Why? A UFO isn't a real button so the UI thinks its action bar slot is empty & will hide it.
If you stop using UFO, delete this macro to remove it from your action bars.
  ]=]
        },
        usePlaceHolders = {
            order = 41,
            name = "Choose your workaround:",
            desc = "Because UFOs aren't real buttons, when they are placed on Bliz Action bars, the UI thinks those buttons are empty.  Choose your workaround:",
            width = "full",
            type = "select",
            style = "radio",
            values = {
                [false] = "Extra UI configuration" ,
                [true]  = "Placeholder macros",
            },
            set = function(optionsMenu, val)
                opts.usePlaceHolders = val
            end,
            get = function()
                return opts.usePlaceHolders
            end,
        },
        doCloseOnClick = {
            order = 50,
            name = "Auto-Close Flyout",
            desc = "Close the flyout after clicking any of its buttons",
            width = "full",
            type = "toggle",
            set = function(optionsMenu, val)
                opts.doCloseOnClick = val
            end,
            get = function()
                return opts.doCloseOnClick
            end,
        },
        supportCombat = {
            hidden = true,
            name = "Support Combat",
            desc = "Placate Bliz security rules of during combat at the cost of less efficient memory usage.",
            width = "full",
            type = "toggle",
            set = function(info, val)
                opts.supportCombat = val
            end,
            get = function()
                return opts.supportCombat
            end
        },
    },
}

function Config:initializeOptionsMenu()
    --local db = LibStub("AceDB-3.0"):New(ADDON_NAME, defaults)
    --options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsMenu)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, Ufo.myTitle)
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
