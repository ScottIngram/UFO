-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.CURE
Preset.defs[id] = {
    ["name"] = L10N.cfg.CURE,
    ["desc"] = L10N.cfg.IF_YOU_RE_POISONED,
    ["icon"] = 648207,
    ["Ace3icon"] = "Interface/ICONS/petbattle_health.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 20707,
            --["name"] = "Soulstone",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 7744,
            --["name"] = "Will of the Forsaken",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 527,
            --["name"] = "Purify",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 32375,
            --["name"] = "Mass Dispel",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 213634,
            --["name"] = "Purify Disease",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 374251,
            --["name"] = "Cauterizing Flame",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 365585,
            --["name"] = "Expunge",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2782,
            --["name"] = "Remove Corruption",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 475,
            --["name"] = "Remove Curse",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 115450,
            --["name"] = "Detox",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 361227,
            --["name"] = "Return",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 212051,
            --["name"] = "Reawaken",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 4987,
            --["name"] = "Cleanse",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 51886,
            --["name"] = "Cleanse Spirit",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 77130,
            --["name"] = "Purify Spirit",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 88423,
            --["name"] = "Nature's Cure",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2008,
            --["name"] = "Ancestral Spirit",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 212048,
            --["name"] = "Ancestral Vision",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 8143,
            --["name"] = "Tremor Totem",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2006,
            --["name"] = "Resurrection",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 212036,
            --["name"] = "Mass Resurrection",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 50769,
            --["name"] = "Revive",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 20484,
            --["name"] = "Rebirth",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 61999,
            --["name"] = "Raise Ally",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 218164,
            --["name"] = "Detox",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 115178,
            --["name"] = "Resuscitate",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 213644,
            --["name"] = "Cleanse Toxins",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 7328,
            --["name"] = "Redemption",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 391054,
            --["name"] = "Intercession",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 212040,
            --["name"] = "Revitalize",
        },
        {
            ["type"] = "item",
            --["name"] = "Crown Co. \"Kure-Everything\" Tonic",
            ["itemId"] = 143542,
        },
    },
}
