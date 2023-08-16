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

---@type GermCommander
local GermCommander -- initialized below

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
            order = 5,
            type = 'description',
            fontSize = "small",
            name = "(Shortcut: Right-click the [UFO] button to open this config menu.)\n\n",
        },
        doCloseOnClick = {
            order = 10,
            name = "Auto-Close UFO",
            desc = "Closes the UFO after clicking any of its buttons",
            width = "full",
            type = "toggle",
            set = function(optionsMenu, val)
                opts.doCloseOnClick = val
                GermCommander:updateAll()
            end,
            get = function()
                return opts.doCloseOnClick
            end,
        },
        configHeader = {
            order = 20,
            name = "PlaceHolder Macros VS Edit Mode Config",
            type = 'header',
        },
        helpTextForPlaceHolders = {
            order = 40,
            type = 'description',
            name = [=[
Each UFO placed onto an action bar has a special macro (named "]=].. Ufo.PLACEHOLDER_MACRO_NAME ..[=[") to hold its place as a button and ensure the UI renders it.

You may disable placeholder macros, but, doing so will require extra UI configuration on your part: You must set the "Always Show Buttons" config option for action bars in Bliz UI "Edit Mode" (in Bartender4 the same option is called "Button Grid").
]=]
        },
        usePlaceHolders = {
            order = 41,
            name = "Choose your workaround:",
            desc = "Because UFOs aren't spells or items, when they are placed into an action bar slot, the UI thinks that slot is empty and doesn't render the slot by default.",
            width = "full",
            type = "select",
            style = "radio",
            values = {
                [true]  = "Placeholder Macros",
                [false] = "Extra UI Configuration" ,
            },
            sorting = {true,false},
            set = function(optionsMenu, val)
                opts.usePlaceHolders = val
                zebug.info:name("opt:usePlaceHolders()"):print("new val",val)
                if val then
                    GermCommander:ensureAllGermsHavePlaceholders()
                else
                    DeleteMacro(Ufo.PLACEHOLDER_MACRO_NAME)
                end
            end,
            get = function()
                return opts.usePlaceHolders
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
    GermCommander = Ufo.GermCommander

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
