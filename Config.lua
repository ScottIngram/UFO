-- Config
-- user defined options and saved vars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@type MouseClick
MouseClick = Ufo.MouseClick

---@class Options -- IntelliJ-EmmyLua annotation
---@field supportCombat boolean placate Bliz security rules of "don't SetAnchor() during combat"
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
---@field clickers table germ behavior for various mouse clicks
---@field keybindBehavior GermClickBehavior when a keybind is activated, it will perform this action
---@field doKeybindTheButtonsOnTheFlyout boolean when a UFO is open, are its buttons bound to number keys?
---@field muteLogin boolean don't print out status messages on log in
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
    ---@type Options
    local defaults = {
        supportCombat   = true,
        doCloseOnClick  = true,
        usePlaceHolders = true,
        muteLogin       = false,
        hideCooldownsWhen = 99999,
        keybindBehavior = GermClickBehavior.OPEN,
        doKeybindTheButtonsOnTheFlyout = true,
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
    return defaults
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
                width = "medium",
                type = "toggle",
                set = function(optionsMenu, val)
                    opts.doCloseOnClick = val
                    GermCommander:forEachGerm(Germ.copyDoCloseOnClickConfigValToAttribute, "user-config-changed-doCloseOnClick") -- TODO: target just the clickers
                end,
                get = function()
                    return opts.doCloseOnClick
                end,
            },
            doMute = {
                order = 12,
                name = "Mute Login Messages",
                desc = "Don't print out Addon info during login.",
                width = "medium",
                type = "toggle",
                set = function(optionsMenu, val)
                    opts.muteLogin = val
                end,
                get = function()
                    return opts.muteLogin
                end,
            },
--[[
            hideCooldownsWhen = {
                hidden = true, -- this is too nitty gritty
                order = 20,
                name = "Hide Long Cooldowns",
                desc = "When configured with a '?' icon, a UFO on the action bar displays its first button including its cooldown.  This option will hide the cooldown if it's longer than X seconds.",
                width = "double",
                type = "range",
                min = 1,
                max = 99999,
                softMax = 9999,
                step = 1,
                set = function(optionsMenu, val)
                    opts.hideCooldownsWhen = val
                    GermCommander:throttledUpdateAllSlots("user-config-hideCooldownsWhen") -- change to updateAllGerms
                end,
                get = function()
                    return opts.hideCooldownsWhen or 1
                end,
            },
]]

            -------------------------------------------------------------------------------
            -- Keybinds
            -------------------------------------------------------------------------------

            keybindBehavior = {
                order = 25,
                name = "Keybind's Action",
                desc = "A UFO on an actionbar button will respond to any keybinding you've given that button.  Choose what the keybind does:",
                width = "double",
                type = "select",
                style = "dropdown",
                values = includeGermClickBehaviors(),
                sorting = includeGermClickBehaviorSorting(),
                set = function(_, behavior)
                    local isDiff = opts.keybindBehavior ~= behavior
                    opts.keybindBehavior = behavior
                    if isDiff then
                        GermCommander:updateAllKeybindBehavior("Config-ObeyBtnSlotKeybind")
                    end
                end,
                get = function()
                    return opts.keybindBehavior or Config.optDefaults.keybindBehavior
                end,
            },
            hotkeyWhenOpen = {
                order = 26,
                name = "Hot Key the Buttons",
                desc = "While open, assign keys 1 through 9 and 0 to the first 10 buttons on the UFO.",
                width = "double",
                type = "select",
                style = "dropdown",
                values = {
                    [true] = "Bind each button to a number (Escape to close).",
                    [false] = "An open UFO won't intercept key presses.",
                },
                set = function(_, doKeybindTheButtonsOnTheFlyout)
                    opts.doKeybindTheButtonsOnTheFlyout = doKeybindTheButtonsOnTheFlyout
                    GermCommander:updateAllActiveGermsWithConfigToBindTheButtons("Config-doKeybindTheButtonsOnTheFlyout")
                end,
                get = function()
                    return Config:get("doKeybindTheButtonsOnTheFlyout")
                end,
            },

            excluderHelpText = {
                order = 28,
                type = 'description',
                fontSize = "small",
                name = [[

Tip: In the catalog, open a UFO and right click a button to exclude it from the "random" and "cycle" actions.
]],
            },

            -------------------------------------------------------------------------------
            -- Place Holder options
            -------------------------------------------------------------------------------

            placeHoldersHeader = {
                order = 30,
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
                        GermCommander:ensureAllGermsHavePlaceholders("config_delta")
                    else
                        Config:deletePlaceholder()
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
    [MouseClick.SIX]    = "Keybind",
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
        values = includeGermClickBehaviors(),
        sorting = includeGermClickBehaviorSorting(),
        ---@param behavior GermClickBehavior
        set = function(zelf, behavior)
            Config:setClickBehavior(nil, mouseClick, behavior)
            zebug.info:name("opt:MouseButtonOpts()"):print("mouseClick",mouseClick, "new val", behavior)
            GermCommander:updateClickHandlerForAllActiveGerms(mouseClick, Event:new("Config", "bind-a-mouse-button"))
        end,
        ---@return GermClickBehavior
        get = function()
            local val = Config:getClickBehavior(nil, mouseClick)
            zebug.info:name("opt:MouseButtonOpts()"):print("mouseClick",mouseClick, "current val", val)
            return val
        end,
    }
end

function includeGermClickBehaviors()
    local values = {
        [GermClickBehavior.OPEN]           = zebug.info:colorize("Open") .." the flyout",
        [GermClickBehavior.FIRST_BTN]      = "Trigger the ".. zebug.info:colorize("first") .." button of the flyout",
        [GermClickBehavior.RANDOM_BTN]     = "Trigger a ".. zebug.info:colorize("random") .." button of the flyout",
        [GermClickBehavior.CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle") .." through each button of the flyout",
        --[GermClickBehavior.REVERSE_CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle backwards") .." through each button of the flyout",
    }
    return values
end

function includeGermClickBehaviorSorting()
    local sorting = {
        --"default", -- will be useful if I implement each FlyoutId having its own config
        GermClickBehavior.OPEN,
        GermClickBehavior.FIRST_BTN,
        GermClickBehavior.RANDOM_BTN,
        GermClickBehavior.CYCLE_ALL_BTNS,
        --GermClickBehavior.REVERSE_CYCLE_ALL_BTNS,
    }
    return sorting
end

---@param flyoutId number aspirational param for when I allow users to give each UFO its own configs
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

function Config:get(key)
    if Config.opts[key] == nil then
        return Config.optDefaults[key]
    else
        return Config.opts[key]
    end

end

function Config:deletePlaceholder()
    Ufo.deletedPlaceholder = "Config: DELETE PLACEHOLDER"
    zebug.info:name("opt:usePlaceHolders()"):print("DELETE ",PLACEHOLDER_MACRO_NAME,"START")

    DeleteMacro(Ufo.PLACEHOLDER_MACRO_NAME) -- here

    -- they claim lua is single threaded.  lets see i WoW's engine is synchronous
    zebug.info:name("opt:usePlaceHolders()"):print("DELETE ",PLACEHOLDER_MACRO_NAME, "DONE")
    Ufo.deletedPlaceholder = nil
end

Config.deletePlaceholder = Pacifier:pacify(Config, "deletePlaceholder", "delete placeholders.")
