-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MAGE_TELEPORT
Preset.defs[id] = {
    ["name"] = "Mage Teleport",
    ["icon"] = 237509,
    ["Ace3icon"] = "Interface/ICONS/spell_arcane_teleportdalaran.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 1259190,
            ["name"] = "Teleport: Silvermoon City",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 3567,
            ["name"] = "Teleport: Orgrimmar",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 3566,
            ["name"] = "Teleport: Thunder Bluff",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 3563,
            ["name"] = "Teleport: Undercity",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 446540,
            ["name"] = "Teleport: Dornogal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 32272,
            ["name"] = "Teleport: Silvermoon",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 49358,
            ["name"] = "Teleport: Stonard",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 35715,
            ["name"] = "Teleport: Shattrath",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 88344,
            ["name"] = "Teleport: Tol Barad",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 132627,
            ["name"] = "Teleport: Vale of Eternal Blossoms",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 176242,
            ["name"] = "Teleport: Warspear",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 193759,
            ["name"] = "Teleport: Hall of the Guardian",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 344587,
            ["name"] = "Teleport: Oribos",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 281404,
            ["name"] = "Teleport: Dazar'alor",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 53140,
            ["name"] = "Teleport: Dalaran - Northrend",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 224869,
            ["name"] = "Teleport: Dalaran - Broken Isles",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 395277,
            ["name"] = "Teleport: Valdrakken",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 111771,
            ["name"] = "Demonic Gateway",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 48020,
            ["name"] = "Demonic Circle: Teleport",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 48018,
            ["name"] = "Demonic Circle",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 698,
            ["name"] = "Ritual of Summoning",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 101643,
            ["name"] = "Transcendence",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 119996,
            ["name"] = "Transcendence: Transfer",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 393764,
            ["name"] = "Path of Proven Worth",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 410078,
            ["name"] = "Path of the Earth-Warder",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 393766,
            ["name"] = "Path of the Grand Magistrix",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 424153,
            ["name"] = "Path of Ancient Horrors",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 424163,
            ["name"] = "Path of the Nightmare Lord",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1239155,
            ["name"] = "Path of the All-Devouring",
        },
    },
}
