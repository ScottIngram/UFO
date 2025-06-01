---@type Ufo
local ADDON_NAME, Ufo = ...

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo.CONST object
-- Now, FOO = "bar" is equivilent to Ufo.FOO = "bar" - Even though they all look like globals, they are not.

IS_OPTIONAL = true
AUTO_ATTACK_SPELL_ID = 6603
MAX_FLYOUT_SIZE = 35
NON_SPEC_SLOT = 5
SPELLFLYOUT_DEFAULT_SPACING = 4
SPELLFLYOUT_INITIAL_SPACING = 7
SPELLFLYOUT_FINAL_SPACING = 4
STRATA_DEFAULT = "MEDIUM"
STRATA_LEVEL_DEFAULT = 75 -- must be higher than the MainMenuBar's level which would otherwise hide the UFO
DELIMITER = "\a"
EMPTY_ELEMENT = "\t" -- strjoin skips "" as if they were nil, but "" isn't treated as nil. omfg Lua, get it together.
CONSUMABLE = "Consumable"
DEFAULT_ICON = "INV_Misc_QuestionMark"
DEFAULT_ICON_FULL = "INTERFACE\\ICONS\\INV_Misc_QuestionMark"
DEFAULT_ICON_FULL_CAPS = "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK"
PROXY_MACRO_NAME = "ZUFO-PROXY"
PLACEHOLDER_MACRO_NAME = "ZUFO"
START = "Start"
END = "End"
PLACEHOLDER_MACRO_TEXT = [=[Placeholder for a UFO.

Without this macro, you must set "Always Show Buttons" in Edit Mode (or "Button Grid" in Bartender4). Why? A UFO isn't a real button so the UI thinks its action bar slot is empty & will hide it.

If you stop using UFO, delete this macro to remove it from your action bars.
]=]



