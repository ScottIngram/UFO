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
Ufo.L10N = {}

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
COMBAT_HAS_ENDED_SO_WE_CAN_NOW = "Combat has ended so we can now "
RECONFIGURE_UFO = "reconfigure UFO."
CHANGE_KEYBINDING = "change keybinding."
RECONFIGURE_BUTTON = "reconfigure button."
CHANGE_KEYBIND_ACTION = "change keybind action."
RECONFIGURE_FLYOUT_BUTTON_KEYBINDING = "reconfigure flyout button keybinding."
