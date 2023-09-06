-- Config
-- user defined options and saved vars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@type MouseClick
MouseClick = Ufo.MouseClick

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean placate Bliz security rules of "don't SetAnchor() during combat"
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
Options = { }

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
---@field optDefaults Options
Config = { }

local opts

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@return Options
function Config:getOptionDefaults()
    return {
        supportCombat   = true,
        doCloseOnClick  = true,
        usePlaceHolders = true,
        [MouseClick.ANY]    = GermClickBehavior.OPEN,
        [MouseClick.LEFT]   = GermClickBehavior.OPEN,
        [MouseClick.RIGHT]  = GermClickBehavior.FIRST_BTN,
        [MouseClick.MIDDLE] = GermClickBehavior.RANDOM_BTN,
        [MouseClick.FOUR]   = GermClickBehavior.CYCLE_ALL_BTNS,
        [MouseClick.FIVE]   = GermClickBehavior.REVERSE_CYCLE_ALL_BTNS,
    }

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
    opts = Config.opts
    --local db = LibStub("AceDB-3.0"):New(ADDON_NAME, defaults)
    --options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsMenu)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, Ufo.myTitle)
end
