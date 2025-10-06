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
---@field enableBonusModifierKeys boolean Incorporate shift, control, etc when using keybindings
---@field doNotOverwriteExistingKeybindings boolean when enableBonusModifierKeys are enabled, do not create new key bindings that clobber pre-existing ones
---@field bonusModifierKeys table<ModifierKey,GermClickBehavior> maps shift/ctrl/etc to OPEN/PRIME/etc
---@field muteLogin boolean don't print out status messages on log in
---@field showLabels boolean display a UFO's name on the action bar button
---@field primaryButtonIs PrimaryButtonIs which button is considered "primary"
---@field version number identifies the config data's format. determines when the config is (in)compatible with the addon code's version
Options = { }

---@class Config -- IntelliJ-EmmyLua annotation
---@field opts Options
---@field optDefaults Options
Config = { }

-------------------------------------------------------------------------------
-- Enums
-------------------------------------------------------------------------------

---@class Option
Option = {

}

---@class PrimaryButtonIs
PrimaryButtonIs = {
    FIRST  = "FIRST",
    RECENT = "RECENT",
}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local KEY_MOD_NA = "KEY_MOD_NA"

-------------------------------------------------------------------------------
-- Data
-------------------------------
local keymodOptsOrder = 0

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
        enableBonusModifierKeys = false,
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
                    [MouseClick.FIVE]   = nil, -- REVERSE_CYCLE_ALL_BTNS,
                }
            }
        },
        bonusModifierKeys = {
            [ModifierKey.SHIFT] = nil,
            [ModifierKey.ALT]   = nil,
            [ModifierKey.CTRL]  = nil,
            [ModifierKey.META]  = nil,
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

                    hotkeyWhenOpen = {
                        order = 20,
                        name = "Hot Key the Buttons on a UFO",
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

                    keybindBehavior = {
                        order = 30,
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
                                GermCommander:applyConfigForMainKeybind("Config-Main-Keybind")
                            end
                        end,
                        get = function()
                            return opts.keybindBehavior or Config.optDefaults.keybindBehavior
                        end,
                    },


                    -------------------------------------------------------------------------------
                    -- Keymods
                    -------------------------------------------------------------------------------

                    enableBonusModifierKeys = {
                        order = 500,
                        name = "Enable Modifier Keys for Keybinds",
                        desc = "Incorporate shift, control, etc when using keybindings.",
                        width = "double",
                        type = "toggle",
                        set = function(optionsMenu, val)
                            opts.enableBonusModifierKeys = val
                            GermCommander:applyConfigForBonusModifierKeys(Event:new("Config", "mod-ALL-the-mod-keys"))
                        end,
                        get = function()
                            return Config:get("enableBonusModifierKeys")
                        end,
                    },
                    keymodGroup = {
                        order = 510,
                        name = "Modifier Keys for Keybindings",
                        type = "group",
                        inline = true, -- set this to false to enable multiple configs, one per flyout.
                        hidden = function() return not Config:get("enableBonusModifierKeys")  end,
                        args = {
                            keymodHelp = {
                                order = 10,
                                type = 'description',
                                name = [=[
In addition to using the keybindings configured in the standard WoW menus, UFO can bind extra key + modifier combinations.  For example, if you have a UFO bound to the Z key, then you can add shift-Z or control-Z here.
]=]
                            },

                            shiftKey = includeKeyModOpts(ModifierKey.SHIFT),
                            ctrlKey  = includeKeyModOpts(ModifierKey.CTRL),
                            altKey   = includeKeyModOpts(ModifierKey.ALT),
                            cmdtKey  = includeKeyModOpts(ModifierKey.META),

                            keymodOverwriteHelp = {
                                order = keymodOptsOrder + 10,
                                type = 'description',
                                name = [=[

(Note: modifiers are additive.  So, if a UFO's main keybind is CMD-X then its extra bindings will always include "CMD-X" plus the modifiers.  Expect CMD-SHIFT-X (not SHIFT-X) and CMD-ALT-X (not ALT-X)

In the above example, there is a UFO on the Z key.  What if there is also an action bound to Shift-Z (for example) already.  How do you want UFO how to handle such a conflict?
]=]
                            },

                            doNotOverwriteExistingKeybindings = {
                                order = keymodOptsOrder + 20,
                                name = "Do Not Overwrite Existing Keybindings",
                                desc = "Leave existing keybindings intact rather than overwrite them with new ones specific to a UFO",
                                width = "double",
                                type = "toggle",
                                set = function(optionsMenu, val)
                                    opts.doNotOverwriteExistingKeybindings = val
                                    GermCommander:applyConfigForBonusModifierKeys(Event:new("Config", "config-key-mods-clobber"))
                                end,
                                get = function()
                                    return Config:get("doNotOverwriteExistingKeybindings")
                                end,
                            },
                        },


                    },
                },
            },






            -------------------------------------------------------------------------------
            -- Place Holder options
            -------------------------------------------------------------------------------

            placeHoldersHeader = {
                order = 600,
                name = "PlaceHolder Macros VS Edit Mode Config",
                type = 'header',
            },
            helpTextForPlaceHolders = {
                order = 610,
                type = 'description',
                name = [=[
Each UFO placed onto an action bar has a special macro (named "]=].. Ufo.PLACEHOLDER_MACRO_NAME ..[=[") to hold its place as a button and ensure the UI renders it.

You may disable placeholder macros, but, doing so will require extra UI configuration on your part: You must set the "Always Show Buttons" config option for action bars in Bliz UI "Edit Mode" (in Bartender4 the same option is called "Button Grid").
]=]
            },
            usePlaceHolders = {
                order = 620,
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
    [MouseClick.RESERVED_FOR_KEYBIND]    = "Keybind",
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
        values = includeGermClickBehaviors("include empty"),
        sorting = includeGermClickBehaviorSorting("include empty"),
        ---@param behavior GermClickBehavior
        set = function(zelf, behavior)
            if behavior == KEY_MOD_NA then
                behavior = nil
            end
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

---@param click ModifierKey
function includeKeyModOpts(modifierKey, mk2)
    local opts = Config.opts
    keymodOptsOrder = keymodOptsOrder + 10
    return {
        order = keymodOptsOrder,
        name = L10N[modifierKey] or "NiL",
        desc = "Assign an action to the keybind + ".. zebug.warn:colorize(L10N[modifierKey] or "NiL") .." modifier",
        width = "double",
        type = "select",
        style = "dropdown",
        values = includeGermClickBehaviors("include empty"),
        sorting = includeGermClickBehaviorSorting("do it dummy"),
        ---@param behavior GermClickBehavior
        set = function(zelf, behavior)
            zebug.info:name("opt:KeyModOpts()"):print("modifierKey",modifierKey, "new val", behavior)
            if behavior == KEY_MOD_NA then
                behavior = nil
            end
            Config.opts.bonusModifierKeys[modifierKey] = behavior
            GermCommander:applyConfigForBonusModifierKeys(modifierKey, behavior, Event:new("Config", "mod-the-mod-keys"))
        end,
        ---@return GermClickBehavior
        get = function()
            return Config.opts.bonusModifierKeys[modifierKey]
        end,
    }
end

local INCLUDE_GERM_CLICK_BEHAVIORS
local INCLUDE_GERM_CLICK_BEHAVIORS_PLUS_NA

function includeGermClickBehaviors(includeNa)
    if not INCLUDE_GERM_CLICK_BEHAVIORS then
        INCLUDE_GERM_CLICK_BEHAVIORS = {
            [GermClickBehavior.OPEN]           = zebug.info:colorize("Open") .." the flyout",
            [GermClickBehavior.PRIME_BTN]      = "Trigger the ".. zebug.info:colorize("primary") .." button of the flyout",
            [GermClickBehavior.RANDOM_BTN]     = "Trigger a ".. zebug.info:colorize("random") .." button of the flyout",
            [GermClickBehavior.CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle") .." through each button of the flyout",
            --[GermClickBehavior.REVERSE_CYCLE_ALL_BTNS] = zebug.info:colorize("Cycle backwards") .." through each button of the flyout",
        }
        INCLUDE_GERM_CLICK_BEHAVIORS_PLUS_NA = deepcopy(INCLUDE_GERM_CLICK_BEHAVIORS)
        INCLUDE_GERM_CLICK_BEHAVIORS_PLUS_NA[KEY_MOD_NA] = ""-- "Do not include in binding"
    end

    if includeNa then
        return INCLUDE_GERM_CLICK_BEHAVIORS_PLUS_NA
    else
        return INCLUDE_GERM_CLICK_BEHAVIORS
    end
end

function includeGermClickBehaviorSorting(includeNa)
    if includeNa then
        return  {
            KEY_MOD_NA,
            GermClickBehavior.OPEN,
            GermClickBehavior.PRIME_BTN,
            GermClickBehavior.RANDOM_BTN,
            GermClickBehavior.CYCLE_ALL_BTNS,
        }
    else
        return  {
            --"default", -- will be useful if I implement each FlyoutId having its own config
            -- KEY_MOD_NA,
            GermClickBehavior.OPEN,
            GermClickBehavior.PRIME_BTN,
            GermClickBehavior.RANDOM_BTN,
            GermClickBehavior.CYCLE_ALL_BTNS,
            --GermClickBehavior.REVERSE_CYCLE_ALL_BTNS,
        }
    end
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

---@param modifierKey ModifierKey
---@return GermClickBehavior
function Config:getKeyModBehavior(modifierKey)
    return Config.modifierKey[modifierKey]
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

-------------------------------------------------------------------------------
-- Versioning and Migration
-------------------------------------------------------------------------------

local migrationFuncs = {}

function Config:getRequiredVersion()
    local vString = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-Config-Version") or 0
    return tonumber(vString)
end

function Config:getCurrentVersion()
    if not self.opts.version then
        self.opts.version = 1
    end
    return self.opts.version
end

function Config:migrateToCurrentVersion()
    local v = self:getCurrentVersion()
    local required = self:getRequiredVersion()

    if v == required then
        return
    elseif v > required then
        -- um, hello time traveler
        return
    else
        -- v < required
        -- fix incompatible data, etc.

        for i = v, required do
            local migrate = migrationFuncs[i]
            if migrate then
                msgUserOrNot("Migrating config from version",self.opts.version, "to",i)
                migrate()
                self.opts.version = i
            end
        end

        self.opts.version = required
    end
end

migrationFuncs[2] = function()
    local clickers = Config.opts.clickers.flyouts.default

    ---@param behavior GermClickBehavior
    ---@param clicker MouseClick
    for clicker, behavior in pairs(clickers) do
        if behavior == "FIRST_BTN" then
            msgUserOrNot("Fixing clicker",clicker, "from",clickers[clicker], "to", GermClickBehavior.PRIME_BTN)
            clickers[clicker] = GermClickBehavior.PRIME_BTN
        end
    end
end
