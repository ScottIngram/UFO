-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MAGE_PORTAL
Preset.defs[id] = {
    ["name"] = "Mage Portals",
    ["icon"] = 237508,
    ["Ace3icon"] = "Interface/ICONS/spell_arcane_portaldalaran.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 1259194,
            ["name"] = "Portal: Silvermoon City",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 11417,
            ["name"] = "Portal: Orgrimmar",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 11418,
            ["name"] = "Portal: Undercity",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 11420,
            ["name"] = "Portal: Thunder Bluff",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 32267,
            ["name"] = "Portal: Silvermoon",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 446534,
            ["name"] = "Portal: Dornogal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 49361,
            ["name"] = "Portal: Stonard",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 35717,
            ["name"] = "Portal: Shattrath",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 88346,
            ["name"] = "Portal: Tol Barad",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 132626,
            ["name"] = "Portal: Vale of Eternal Blossoms",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 176244,
            ["name"] = "Portal: Warspear",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 281402,
            ["name"] = "Portal: Dazar'alor",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 344597,
            ["name"] = "Portal: Oribos",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 53142,
            ["name"] = "Portal: Dalaran - Northrend",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 224871,
            ["name"] = "Portal: Dalaran - Broken Isles",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 395289,
            ["name"] = "Portal: Valdrakken",
        },
    },
}
