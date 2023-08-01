local ADDON_NAME, Ufo = ...

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo.CONST object
-- Now, FOO = "bar" is equivilent to Ufo.FOO = "bar" - Even though they all look like globals, they are not.

V_MAJOR = 10
V_MINOR = 1
V_PATCH = 0
V_UFO = "alpha"
VERSION = table.concat({V_MAJOR, V_MINOR, V_PATCH, V_UFO}, ".")

X = nil
MAX_FLYOUT_SIZE = 30
NON_SPEC_SLOT = 5
SPELLFLYOUT_DEFAULT_SPACING = 4
SPELLFLYOUT_INITIAL_SPACING = 7
SPELLFLYOUT_FINAL_SPACING = 4
STRATA_DEFAULT = "MEDIUM"
PROXY_MACRO_NAME = "ZZZZZZZZZZ_ufo_proxy" -- make sure this name is last alphabetically to mniimize its impact on the array index reordering
MAX_GLOBAL_MACRO_ID = 120
DELIMITER = "\a"
EMPTY_ELEMENT = "\t" -- strjoin skips "" as if they were nil, but "" isn't treated as nil. omfg Lua, get it together.
CONSUMABLE = "Consumable"
DEFAULT_ICON = "INV_Misc_QuestionMark"
