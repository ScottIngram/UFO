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
    ["icon"] = 6866615,
    ["Ace3icon"] = "Interface/ICONS/inv_1117_ability_recuperate.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 1231411,
            --["name"] = "Recuperate",
        },
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
