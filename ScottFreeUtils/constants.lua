local ADDON_NAME, ADDON_SYMBOL_TABLE = ...

ADDON_SYMBOL_TABLE.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo

---@class MouseClick
MouseClick = {
    ANY    = "any",
    LEFT   = "LeftButton",
    RIGHT  = "RightButton",
    MIDDLE = "MiddleButton",
    FOUR   = "Button4",
    FIVE   = "Button5",
    SIX    = "Button6", -- there is no "Button6" in the API docs, so,  I've reserved this for use by my keybind code
}

QUOTE = "\""
EOL = "\n"
MAX_GLOBAL_MACRO_ID = 120
DEFAULT_ICON = "INV_Misc_QuestionMark"
DEFAULT_ICON_FULL = "INTERFACE\\ICONS\\INV_Misc_QuestionMark"
DEFAULT_ICON_FULL_CAPS = "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK"
