-- Config
-- user defined options and saved vars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new()

---@type MouseClick
MouseClick = Ufo.MouseClick

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean placate Bliz security rules of "don't SetAnchor() during combat"
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
---@field clickers table germ behavior for various mouse clicks
Options = { }

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
---@field optDefaults Options
Config = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@return Options
function Config:getOptionDefaults()
    return {
        supportCombat   = true,
        doCloseOnClick  = true,
        usePlaceHolders = true,
        clickers = {
            flyouts = {
                default = {
                    [MouseClick.ANY]    = GermClickBehavior.OPEN,
                    [MouseClick.LEFT]   = GermClickBehavior.OPEN,
                    [MouseClick.RIGHT]  = GermClickBehavior.FIRST_BTN,
                    [MouseClick.MIDDLE] = GermClickBehavior.RANDOM_BTN,
                    [MouseClick.FOUR]   = GermClickBehavior.CYCLE_ALL_BTNS,
                    [MouseClick.FIVE]   = GermClickBehavior.OPEN, -- REVERSE_CYCLE_ALL_BTNS,
                }
            }
        },
    }
end

-------------------------------------------------------------------------------
-- Configuration Options Menu UI
-------------------------------------------------------------------------------

function getOptTitle() return Ufo.myTitle  end

local optionsMenu

local function initializeOptionsMenu()
    if optionsMenu then
        return optionsMenu
    end

    local opts = Config.opts

    optionsMenu = {
        name = getOptTitle,
        type = "group",
        args = {

            -------------------------------------------------------------------------------
            -- General Options
            -------------------------------------------------------------------------------

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


            -------------------------------------------------------------------------------
            -- Place Holder options
            -------------------------------------------------------------------------------

            placeHoldersHeader = {
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


            -------------------------------------------------------------------------------
            -- Mouse Click opts
            -------------------------------------------------------------------------------

            mouseClickGroupHeader = {
                order = 100,
                name = "Mouse Buttons",
                type = 'header',
            },
            mouseClickGroupHelp = {
                order = 110,
                type = 'description',
                name = [=[

You can choose a different action for each mouse button when it clicks on a UFO.

]=]
            },
            mouseClickGroup = {
                order = 120,
                name = "Mouse Buttons",
                type = "group",
                inline = true, -- set this to false to enable multiple configs, one per flyout.
                args = {
                    leftBtn   = includeMouseButtonOpts(MouseClick.LEFT),
                    middleBtn = includeMouseButtonOpts(MouseClick.MIDDLE),
                    rightBtn  = includeMouseButtonOpts(MouseClick.RIGHT),
                    fourBtn   = includeMouseButtonOpts(MouseClick.FOUR),
                    fiveBtn   = includeMouseButtonOpts(MouseClick.FIVE),
                },
            },
        },
    }

    return optionsMenu
end

-------------------------------------------------------------------------------
-- Mouse Button opt maker
-------------------------------------------------------------------------------

local mouseButtonOptsOrder = 0
local mouseButtonName = {
    [MouseClick.ANY]    = "All Buttons",
    [MouseClick.LEFT]   = "Left",
    [MouseClick.RIGHT]  = "Right",
    [MouseClick.MIDDLE] = "Middle",
    [MouseClick.FOUR]   = "Fourth",
    [MouseClick.FIVE]   = "Fifth",
}

---@param click MouseClick
function includeMouseButtonOpts(mouseClick)
    local opts = Config.opts
    mouseButtonOptsOrder = mouseButtonOptsOrder + 1
    return {
        order = mouseButtonOptsOrder,
        name = mouseButtonName[mouseClick],
        desc = "Assign an action to the ".. zebug.warn:colorize(mouseButtonName[mouseClick]) .." mouse button",
        width = "double",
        type = "select",
        style = "dropdown",
        values = {
            [GermClickBehavior.OPEN]           = zebug.info:colorize("Open") .." the flyout",
            [GermClickBehavior.FIRST_BTN]      = "Trigger the ".. zebug.info:colorize("first") .." button of the flyout",
            [GermClickBehavior.RANDOM_BTN]     = "Trigger a ".. zebug.info:colorize("random") .." button of the flyout",
            [GermClickBehavior.CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle") .." through each button of the flyout",
            --[GermClickBehavior.REVERSE_CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle backwards") .." through each button of the flyout",
        },
        sorting = {
            --"default", -- will be useful if I implement each FlyoutId having its own config
            GermClickBehavior.OPEN,
            GermClickBehavior.FIRST_BTN,
            GermClickBehavior.RANDOM_BTN,
            GermClickBehavior.CYCLE_ALL_BTNS,
            --GermClickBehavior.REVERSE_CYCLE_ALL_BTNS,
        },
        ---@param behavior GermClickBehavior
        set = function(zelf, behavior)
            Config:setClickBehavior(nil, mouseClick, behavior)
            zebug.info:name("opt:MouseButtonOpts()"):print("mouseClick",mouseClick, "new val", behavior)
            GermCommander:updateClickHandlerForAllGerms(mouseClick)
        end,
        ---@return GermClickBehavior
        get = function()
            local val = Config:getClickBehavior(nil, mouseClick)
            zebug.info:name("opt:MouseButtonOpts()"):print("mouseClick",mouseClick, "current val", val)
            return val
        end,
    }
end

---@param flyoutId string
---@param mouseClick MouseClick
---@return GermClickBehavior
function Config:getClickBehavior(flyoutId, mouseClick)
    local clickOpts = Config.opts.clickers.flyouts[flyoutId] or Config.opts.clickers.flyouts.default
    return clickOpts[mouseClick]
end

function Config:setClickBehavior(flyoutId, mouseClick, behavior)
    if not flyoutId then
        flyoutId = "default"
    end

    local clickOpts = Config.opts.clickers.flyouts[flyoutId]
    if not clickOpts then
        clickOpts = {}
        Config.opts.clickers.flyouts[flyoutId] = clickOpts
    end

    if behavior == "default" then
        behavior = nil
    end

    clickOpts[mouseClick] = behavior
end

function Config:initializeOptionsMenu()
    initializeOptionsMenu()
    --local db = LibStub("AceDB-3.0"):New(ADDON_NAME, defaults)
    --options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, optionsMenu)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, Ufo.myTitle)
end
