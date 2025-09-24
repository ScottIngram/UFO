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
---@field doCloseOnClick boolean close the flyout after the user clicks one of its buttons
---@field usePlaceHolders boolean eliminate the need for "Always Show Buttons" in Bliz UI "Edit Mode" config option for action bars
---@field clickers table germ behavior for various mouse clicks
---@field keybindBehavior GermClickBehavior when a keybind is activated, it will perform this action
---@field doKeybindTheButtonsOnTheFlyout boolean when a UFO is open, are its buttons bound to number keys?
---@field muteLogin boolean don't print out status messages on log in
---@field showLabels boolean display a UFO's name on the action bar button
---@field primaryButtonIs PrimaryButtonIs which button is considered "primary"
Options = { }

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
---@field optDefaults Options
Config = { }

-------------------------------------------------------------------------------
-- Enums
-------------------------------------------------------------------------------

---@class PrimaryButtonIs
PrimaryButtonIs = {
    FIRST  = "FIRST",
    RECENT = "RECENT",
}

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@return Options
function Config:getOptionDefaults()
    ---@type Options
    local defaults = {
        doCloseOnClick  = true,
        usePlaceHolders = true,
        muteLogin       = false,
        showLabels       = false,
        hideCooldownsWhen = 99999,
        keybindBehavior = GermClickBehavior.OPEN,
        doKeybindTheButtonsOnTheFlyout = true,
        primaryButtonIs = PrimaryButtonIs.FIRST,
        clickers = {
            flyouts = {
                default = {
                    [MouseClick.ANY]    = GermClickBehavior.OPEN,
                    [MouseClick.LEFT]   = GermClickBehavior.OPEN,
                    [MouseClick.RIGHT]  = GermClickBehavior.PRIME_BTN,
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
                order = 100,
                type = 'description',
                fontSize = "small",
                name = [=[
(Shortcut: Right-click the [UFO] button to open this config menu.)

]=] .. Ufo.myTitle .. [=[ lets you create custom flyout menus which you can place on your action bars and include any arbitrary buttons of your choosing (spells, macros, items, pets, mounts, etc.) all with standard drag and drop.

]=]
            },
            doCloseOnClick = {
                order = 110,
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
                order = 120,
                name = "Mute Login Messages",
                desc = "Don't print out Addon info during login.",
                width = "medium",
                type = "toggle",
                set = function(optionsMenu, val)
                    opts.muteLogin = val
                end,
                get = function()
                    return Config:get("muteLogin")
                end,
            },
            showLabels = {
                order = 120,
                name = "Show Labels",
                desc = "Add a label to the action bar button displaying the UFO's name.",
                width = "medium",
                type = "toggle",
                set = function(optionsMenu, val)
                    opts.showLabels = val
                    GermCommander:applyConfigForLabels("config_labels")
                end,
                get = function()
                    return Config:get("showLabels")
                end,
            },



            -------------------------------------------------------------------------------
            -- Define Primary
            -------------------------------------------------------------------------------

            divHeader = {
                order = 200,
                name = "",
                type = 'header',
            },

            primaryButtonIsGroup = {
                order = 210,
                name = 'The "Primary Button"',
                type = "group",
                inline = true,
                args = {
                    helpPrim = {
                        order = 210,
                        type = 'description',
                        name = [=[
One button on the UFO is "Primary," is shown on the actionbar, and can be clicked without necessarily opening the UFO.  By default, the first button on the UFO is its primary.  Alternatively, whenever you use a button it would become the new primary.

]=]
                    },

                    primaryButtonIsMenu = {
                        order = 220,
                        name = 'The "Primary" Button is...',
                        desc = 'Which button of the flyout should be considered its "Primary" button?',
                        width = "double",
                        type = "select",
                        style = "dropdown",
                        values = {
                            [PrimaryButtonIs.FIRST]  = "First Button, Always",
                            [PrimaryButtonIs.RECENT] = "Most Recently Used",
                        },
                        sorting = {PrimaryButtonIs.FIRST, PrimaryButtonIs.RECENT},
                        set = function(optionsMenu, val)
                            opts.primaryButtonIs = val
                            zebug.info:name("opt:primaryButtonIs()"):print("new val",val)
                            GermCommander:applyConfigForPrimaryButtonIs("config_delta_prime")
                        end,
                        get = function()
                            return Config:get("primaryButtonIs")
                        end,
                    },
                },
            },




            -------------------------------------------------------------------------------
            -- Mouse Click opts
            -------------------------------------------------------------------------------

            mouseClickGroup = {
                order = 320,
                name = "Mouse Buttons",
                type = "group",
                inline = true, -- set this to false to enable multiple configs, one per flyout.
                args = {
                    mouseClickGroupHelp = {
                        order = 1,
                        type = 'description',
                        name = [=[
You can choose a different action for each mouse button when it clicks on a UFO.

]=]
                    },

                    leftBtn   = includeMouseButtonOpts(MouseClick.LEFT),
                    middleBtn = includeMouseButtonOpts(MouseClick.MIDDLE),
                    rightBtn  = includeMouseButtonOpts(MouseClick.RIGHT),
                    fourBtn   = includeMouseButtonOpts(MouseClick.FOUR),
                    fiveBtn   = includeMouseButtonOpts(MouseClick.FIVE),

                    excluderHelpText = {
                        order = 100,
                        type = 'description',
                        fontSize = "small",
                        name = [[

Tip: In the catalog, open a UFO and right click a button to exclude it from the "random" and "cycle" actions.
]],
                    },
                },
            },



            -------------------------------------------------------------------------------
            -- Keybinds
            -------------------------------------------------------------------------------

            keybindGroup = {
                order = 400,
                name = "Keybinding Behavior",
                type = "group",
                inline = true, -- set this to false to enable multiple configs, one per flyout.
                args = {
                    mkeybindHelp = {
                        order = 10,
                        type = 'description',
                        name = [=[
UFOs on the action bars support keybindings.  Buttons on UFOs can be configured to also have keybindings.
]=]
                    },

                    keybindBehavior = {
                        order = 20,
                        name = "Actionbar Keybinding",
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
                        order = 30,
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
                            GermCommander:applyConfigForBindTheButtons("Config-doKeybindTheButtonsOnTheFlyout")
                        end,
                        get = function()
                            return Config:get("doKeybindTheButtonsOnTheFlyout")
                        end,
                    },
                },
            },



            -------------------------------------------------------------------------------
            -- Place Holder options
            -------------------------------------------------------------------------------

            placeHoldersHeader = {
                order = 500,
                name = "PlaceHolder Macros VS Edit Mode Config",
                type = 'header',
            },
            helpTextForPlaceHolders = {
                order = 510,
                type = 'description',
                name = [=[
Each UFO placed onto an action bar has a special macro (named "]=].. Ufo.PLACEHOLDER_MACRO_NAME ..[=[") to hold its place as a button and ensure the UI renders it.

You may disable placeholder macros, but, doing so will require extra UI configuration on your part: You must set the "Always Show Buttons" config option for action bars in Bliz UI "Edit Mode" (in Bartender4 the same option is called "Button Grid").
]=]
            },
            usePlaceHolders = {
                order = 520,
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
                        GermCommander:ensureAllGermsHavePlaceholders("config_delta_ph")
                    else
                        Config:deletePlaceholder()
                    end
                end,
                get = function()
                    return opts.usePlaceHolders
                end,
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
    mouseButtonOptsOrder = mouseButtonOptsOrder + 10
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
            GermCommander:updateClickerForAllActiveGerms(mouseClick, Event:new("Config", "bind-a-mouse-button"))
        end,
        ---@return GermClickBehavior
        get = function()
            local val = Config:getGermClickBehavior(nil, mouseClick)
            zebug.info:name("opt:MouseButtonOpts()"):print("mouseClick",mouseClick, "current val", val)
            return val
        end,
    }
end

local INCLUDE_GERM_CLICK_BEHAVIORS

function includeGermClickBehaviors()
    if not INCLUDE_GERM_CLICK_BEHAVIORS then
        INCLUDE_GERM_CLICK_BEHAVIORS = {
            [GermClickBehavior.OPEN]           = zebug.info:colorize("Open") .." the flyout",
            [GermClickBehavior.PRIME_BTN]      = "Trigger the ".. zebug.info:colorize("primary") .." button of the flyout",
            [GermClickBehavior.RANDOM_BTN]     = "Trigger a ".. zebug.info:colorize("random") .." button of the flyout",
            [GermClickBehavior.CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle") .." through each button of the flyout",
            --[GermClickBehavior.REVERSE_CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle backwards") .." through each button of the flyout",
        }
    end

    return INCLUDE_GERM_CLICK_BEHAVIORS
end

function includeGermClickBehaviorSorting()
    local sorting = {
        --"default", -- will be useful if I implement each FlyoutId having its own config
        GermClickBehavior.OPEN,
        GermClickBehavior.PRIME_BTN,
        GermClickBehavior.RANDOM_BTN,
        GermClickBehavior.CYCLE_ALL_BTNS,
        --GermClickBehavior.REVERSE_CYCLE_ALL_BTNS,
    }
    return sorting
end

---@param flyoutId number aspirational param for when I allow users to give each UFO its own configs
---@param mouseClick MouseClick
---@return GermClickBehavior
function Config:getGermClickBehavior(flyoutId, mouseClick)
    local clickOpts = Config.opts.clickers.flyouts[flyoutId] or Config.opts.clickers.flyouts.default
    return clickOpts[mouseClick]
end

local isUsingRecent -- cleared during setClickBehavior() and recalculated by isAnyClickerUsingRecent()

function Config:setClickBehavior(flyoutId, mouseClick, behavior)
    isUsingRecent = nil

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

function Config:isPrimeDefinedAsRecent()
    return Config:get("primaryButtonIs") == PrimaryButtonIs.RECENT
end

function Config:isPrimeDefinedAsFirst()
    return Config:get("primaryButtonIs") == PrimaryButtonIs.FIRST
end

function Config:isAnyClickerUsingRecent(flyoutId)
    local prime_is_defined_as_recent = Config:get("primaryButtonIs") == PrimaryButtonIs.RECENT
    if not prime_is_defined_as_recent then
        return false
    end

    if isUsingRecent == nil then
        local clickOpts = Config.opts.clickers.flyouts[flyoutId] or Config.opts.clickers.flyouts.default
        for k, v in pairs(MouseClick) do
            if clickOpts[v] == GermClickBehavior.PRIME_BTN then isUsingRecent = true end
        end
    end
    return isUsingRecent
end

function Config:getPrimeClickers(flyoutId)
    local primeClickers
    local clickOpts = Config.opts.clickers.flyouts[flyoutId] or Config.opts.clickers.flyouts.default
    for k, v in pairs(MouseClick) do
        if clickOpts[v] == GermClickBehavior.PRIME_BTN then
            if primeClickers == nil then
                primeClickers = {}
            end
            primeClickers[#primeClickers +1] = v
            zebug.info:print("isUsingRecent v",v)
        end
    end
    return primeClickers
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

Config.deletePlaceholder = Pacifier:wrap(Config.deletePlaceholder, L10N.DELETE_PLACEHOLDERS)
