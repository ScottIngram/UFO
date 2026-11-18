-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.NOMZ

Preset.defs[id] = {
    ["name"] = L10N.cfg.NOM_NOM,
    ["desc"] = L10N.cfg.THINGS_THAT_RESTORE_HEALTH_OR_MANA,
    ["icon"] =  isForever() and 2203786 or 6866615,
    ["Ace3icon"] = isForever() and  "Interface/ICONS/Inv_misc_popcorntoy.blp" or "Interface/ICONS/inv_1117_ability_recuperate.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 1231411,
            --["name"] = "Recuperate",
        },

        -- == CONJURED WATER == --
        { ["type"] = "item", ["itemId"] = 5350, },
        { ["type"] = "item", ["itemId"] = 2288, },
        { ["type"] = "item", ["itemId"] = 2136, },
        { ["type"] = "item", ["itemId"] = 3772, },
        { ["type"] = "item", ["itemId"] = 8077, },
        { ["type"] = "item", ["itemId"] = 8078, },
        { ["type"] = "item", ["itemId"] = 8079, },

        -- == CONJURED FOOD == --
        { ["type"] = "item", ["itemId"] = 5349, },
        { ["type"] = "item", ["itemId"] = 1113, },
        { ["type"] = "item", ["itemId"] = 1114, },
        { ["type"] = "item", ["itemId"] = 1487, },
        { ["type"] = "item", ["itemId"] = 8075, },
        { ["type"] = "item", ["itemId"] = 8076, },
        { ["type"] = "item", ["itemId"] = 22895, },

        -- -- CONJURE WATER -- --
        { ["type"] = "spell", ["spellId"] = 5504, },
        { ["type"] = "spell", ["spellId"] = 5505, },
        { ["type"] = "spell", ["spellId"] = 5506, },
        { ["type"] = "spell", ["spellId"] = 6127, },
        { ["type"] = "spell", ["spellId"] = 10138, },
        { ["type"] = "spell", ["spellId"] = 10139, },
        { ["type"] = "spell", ["spellId"] = 10140, },
        { ["type"] = "spell", ["spellId"] = 468766, },

        -- -- CONJURE FOOD -- --
        { ["type"] = "spell", ["spellId"] = 587, },
        { ["type"] = "spell", ["spellId"] = 597, },
        { ["type"] = "spell", ["spellId"] = 990, },
        { ["type"] = "spell", ["spellId"] = 6129, },
        { ["type"] = "spell", ["spellId"] = 10144, },
        { ["type"] = "spell", ["spellId"] = 10145, },
        { ["type"] = "spell", ["spellId"] = 28612, },

        -- retail stuff
        {
            ["type"] = "item",
            --["name"] = "Conjured Mana Bun",
            ["itemId"] = 113509,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 190336,
            --["name"] = "Conjure Refreshment",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 20577,
            --["name"] = "Cannibalize",
        },
        {
            ["type"] = "item",
            --["name"] = "Weavercloth Bandage",
            ["itemId"] = 224441,
        },
        {
            ["type"] = "item",
            --["name"] = "Everlasting Nosh",
            ["itemId"] = 250316,
        },
        {
            ["type"] = "toy",
            --["name"] = "Dragon Tea Set",
            ["itemId"] = 199649,
        },
        {
            ["type"] = "toy",
            --["name"] = "Sinvyr Tea Set",
            ["itemId"] = 183900,
        },
        {
            ["type"] = "toy",
            --["name"] = "Whale Bone Tea Set",
            ["itemId"] = 199650,
        },
    },
}
