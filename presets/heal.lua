-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.HEAL
Preset.defs[id] = {
    ["name"] = L10N.cfg.HEAL,
    ["desc"] = L10N.cfg.HEALTH_POTIONS_HEALTHSTONES_ETC,
    ["icon"] = 648632,
    ["Ace3icon"] = "Interface/ICONS/achievement_guild_doctorisin.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "item",
            --["name"] = "Healthstone",
            ["itemId"] = 5512,
        },
        {
            ["type"] = "item",
            --["name"] = "Demonic Healthstone",
            ["itemId"] = 224464,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 6201,
            --["name"] = "Create Healthstone",
        },
        {
            ["type"] = "item",
            --["name"] = "Potent Healing Potion",
            ["itemId"] = 258138,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 22842,
            --["name"] = "Frenzied Regeneration",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 6789,
            --["name"] = "Mortal Coil",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 416250,
            --["name"] = "Gift of the Naaru",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 29893,
            --["name"] = "Create Soulwell",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 8004,
            --["name"] = "Healing Surge",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 19236,
            --["name"] = "Desperate Prayer",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 19750,
            --["name"] = "Flash of Light",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 85673,
            --["name"] = "Word of Glory",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 633,
            --["name"] = "Lay on Hands",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 116670,
            --["name"] = "Vivify",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 108238,
            --["name"] = "Renewal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 109304,
            --["name"] = "Exhilaration",
        },
        {
            ["type"] = "item",
            --["name"] = "Silvermoon Health Potion",
            ["itemId"] = 241305,
        },
    },
}
