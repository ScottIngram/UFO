local ADDON_NAME, Ufo = ...

---@class L10N -- IntelliJ-EmmyLua annotation
---@field CONFIRM_DELETE
---@field NEW_FLYOUT
---@field TOY
---@field CAN_NOT_MOVE
---@field BARTENDER_BAR_DISABLED
---@field DOMINOS_BAR_DISABLED
---@field DETECTED
---@field LOADED
Ufo.L10N = {
    cfg = {},
}

Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
-- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

CONFIRM_DELETE = "Are you sure you want to delete the flyout set %s?"
NEW_FLYOUT = "New\nFlyout"
TOY = TOY -- Bliz provides this as a global
CAN_NOT_MOVE = "cannot be used, moved, or removed by this toon."
BARTENDER_BAR_DISABLED = "A UFO is on a disabled Bartender4 bar.  Re-enable the bar and reload the UI to activate the UFO."
DOMINOS_BAR_DISABLED = "A UFO is on a disabled Dominos bar.  Re-enable the bar and reload the UI to activate the UFO."
DETECTED = "detected"
LOADED = "loaded"
LEFT_CLICK = "Left-click"
RIGHT_CLICK = "Right-click"
MIDDLE_CLICK = "Middle-click"
OPEN_CATALOG = "open catalog"
OPEN_CONFIG = "open config"

SLASH_CMD_HELP = "help"
SLASH_CMD_CONFIG = "config"
SLASH_DESC_CONFIG = "open the options configuration panel."
SLASH_CMD_OPEN = "open"
SLASH_DESC_OPEN = "open the catalog of flyout menus."
SLASH_UNKNOWN_COMMAND = "unknown command"

-- Professions / Trade Skills
-- These MUST match what Bliz uses in its UI
JEWELCRAFTING = "Jewelcrafting"
BLACKSMITHING = "Blacksmithing"
LEATHERWORKING = "Leatherworking"
ENGINEERING = "Engineering"

WAITING_UNTIL_COMBAT_ENDS = "Waiting until combat ends to "
COMBAT_HAS_ENDED_SO_NOW_WE_CAN = "Combat has ended so now we can "
RECONFIGURE_AUTO_CLOSE = "reconfigure auto-close."
CHANGE_KEYBINDING = "change keybinding."
RECONFIGURE_BUTTON = "reconfigure button."
CHANGE_KEYBIND_ACTION = "change keybind action."
RECONFIGURE_FLYOUT_BUTTON_KEYBINDING = "reconfigure flyout button keybinding."
SWITCH_TO_PLACEHOLDERS = "switch to placeholders."
DELETE_PLACEHOLDERS = "delete placeholders."
CHANGE_MOUSE_BUTTON_BEHAVIOR = "change mouse button behavior"
UNKNOWN = "uNkNoWn"
CANNOT_BE_USED_BY_THIS_TOON = "cannot be used by this toon."
THIS_TOON_HAS_NONE = "This toon has none."
NOT_MACRO_OWNER = "It can only be used by"
UNSUPPORTED_TYPE = "Sorry, unsupported type"
UFO_ICON_PROMOTE = "update the UFO icon to reflect the most recently used member."

-------------------------------------------------------------------------------
-- Configuration Screen
-------------------------------------------------------------------------------

Ufo.Wormhole(cfg)

SHIFT_INIT_CAP = "Shift"
SHIFT_ALL_CAPS = "SHIFT"
CTRL_INIT_CAP = "Control"
CTRL_ALL_CAPS = "CONTROL"

if IsMacClient() then
    META_INIT_CAP = "Command"
    META_ALL_CAPS = "COMMAND"
    ALT_INIT_CAP = "Option"
    ALT_ALL_CAPS = "OPTION"
else
    META_INIT_CAP = "Meta"
    META_ALL_CAPS = "META"
    ALT_INIT_CAP = "Alt"
    ALT_ALL_CAPS = "ALT"
end

SHORTCUT = "(Shortcut: Right-click the [UFO] button to open this config menu.)"
UFO_LETS_YOU = "lets you create custom flyout menus which you can place on your action bars and include any arbitrary buttons of your choosing (spells, macros, items, pets, mounts, etc.) all with standard drag and drop."
AUTO_CLOSE_UFO = "Auto-Close UFO"
CLOSES_THE_UFO = "Closes the UFO after clicking any of its buttons"
MUTE_LOGIN_MESSAGES = "Mute Login Messages"
DONT_PRINT = "Don't print out Addon info during login."
SHOW_LABELS = "Show Labels"
ADD_A_LABEL = "Add a label to the action bar button displaying the UFO's name"
THE_PRIMARY_BUTTON = 'The "Primary Button"'
ONE_BUTTON_ON_THE_UFO_IS_PRIMARY = [=[One button on the UFO is "Primary," is shown on the actionbar, and can be clicked without necessarily opening the UFO.  By default, the first button on the UFO is its primary.  Alternatively, whenever you use a button it would become the new primary.]=]
THE_PRIMARY_BUTTON_IS = 'The "Primary" Button is...'
THE_PRIMARY_BUTTON_IS_THE = 'The "Primary" Button is the:'
WHICH_BUTTON_OF_THE_FLYOUT = 'Which button of the flyout should be considered its "Primary" button?'
FIRST_BUTTON_ALWAYS = "First Button, Always"
FIRST_BUTTON = "First Button"
MOST_RECENTLY_USED = "Most Recently Used"
MOUSE_BUTTONS = "Mouse Buttons"
YOU_CAN_CHOOSE_A_DIFFERENT = "You can choose a different action for each mouse button when it clicks on a UFO."
TIP_IN_THE_CATALOG = [=[Tip: In the catalog, open a UFO and right click a button to exclude it from the "random" and "cycle" actions. ]=]
KEYBINDING_BEHAVIOR = "Keybinding Behavior"
UFOS_ON_THE_ACTION_BARS = [=[ UFOs on the action bars support keybindings.  Buttons on UFOs can be configured to also have keybindings. ]=]
HOT_KEY_THE_BUTTONS_ON_A_UFO = "Hot Key the Buttons on a UFO"
WHILE_OPEN_ASSIGN_KEYS = "While open, assign keys 1 through 9 and 0 to the first 10 buttons on the UFO."
BIND_EACH_BUTTON = "Bind each button to a number (Escape to close)."
AN_OPEN_UFO_WONT = "An open UFO won't intercept key presses."
ACTIONBAR_KEYBINDING = "Actionbar Keybinding"
A_UFO_ON_AN_ACTIONBAR_BUTTON_WILL_RESPOND = "A UFO on an actionbar button will respond to any keybinding you've given that button.  Choose what the keybind does:"
ENABLE_MODIFIER_KEYS_FOR_KEYBINDS = "Enable Modifier Keys for Keybinds"
INCORPORATE_SHIFT_ETC = "Incorporate shift, control, etc when using keybindings."
IN_ADDITION_TO_USING_THE_KEYBINDINGS = "In addition to using the keybindings configured in the standard WoW menus, UFO can bind extra key + modifier combinations.  For example, if you have a UFO bound to the Z key, then you can add shift-Z or control-Z here."
MODIFIERS_ARE_ADDITIVE_IN_THE_ABOVE_EXAMPLE = [=[

(Note: modifiers are additive.  So, if a UFO's main keybind is CTRL-X then its extra bindings will always include "CTRL-X" plus the modifiers.  Expect CTRL-SHIFT-X (not SHIFT-X) and CTRL-]=]..ALT_ALL_CAPS..[=[-X (not ]=]..ALT_ALL_CAPS..[=[-X)

In the above example, there is a UFO on the Z key.  What if there is also an action bound to SHIFT-Z (for example) already.  How do you want UFO how to handle such a conflict?

]=]

DO_NOT_OVERWRITE_EXISTING_KEYBINDINGS = "Do Not Overwrite Existing Keybindings"
LEAVE_EXISTING_KEYBINDINGS = "Leave existing keybindings intact rather than overwrite them with new ones specific to a UFO"
PLACEHOLDER_MACROS_VS_EDIT_MODE_CONFIG = "PlaceHolder Macros VS Edit Mode Config"
EACH_UFO_PLACED = [=[
Each UFO placed onto an action bar has a special macro (named "]=].. Ufo.PLACEHOLDER_MACRO_NAME ..[=[") to hold its place as a button and ensure the UI renders it.

You may disable placeholder macros, but, doing so will require extra UI configuration on your part: You must set the "Always Show Buttons" config option for action bars in Bliz UI "Edit Mode" (in Bartender4 the same option is called "Button Grid").
]=]

CHOOSE_YOUR_WORKAROUND = "Choose your workaround"
BECAUSE_UFOS_ARENT_SPELLS = "Because UFOs aren't spells or items, when they are placed into an action bar slot, the UI thinks that slot is empty and doesn't render the slot by default."
PLACEHOLDER_MACROS = "Placeholder Macros"
EXTRA_UI_CONFIGURATION = "Extra UI Configuration"
ALL_BUTTONS = "All Buttons"
LEFT = "Left"
RIGHT = "Right"
MIDDLE = "Middle"
FOURTH = "Fourth"
FIFTH = "Fifth"
KEYBIND = "Keybind"
ASSIGN_AN_ACTION_TO_THE = "Assign an action to the"
MOUSE_BUTTON = "mouse button"
ASSIGN_AN_ACTION_TO_THE_KEYBIND = "Assign an action to the keybind +"
MODIFIER = "modifier"
OPEN = "Open"
THE_FLYOUT = "the flyout"
PRIMARY = "primary"
BUTTON_OF_THE_FLYOUT = "button of the flyout"
TRIGGER_THE = "Trigger the"
TRIGGER_A = "Trigger a"
RANDOM = "random"
CYCLE = "Cycle"
THROUGH_EACH_BUTTON_OF_THE_FLYOUT = "through each button of the flyout"
CYCLE_BACKWARDS = "Cycle backwards"
MIGRATING_CONFIG_FROM_VERSION = "Migrating config from version"
TO = "to"
FIXING_CLICKER = "Fixing clicker"
FROM = "from"
FIXING_KEYBINDBEHAVIOR_FROM = "Fixing keybindBehavior from"
