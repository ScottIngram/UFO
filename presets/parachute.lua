-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.PARACHUTE
Preset.defs[id] = {
    ["name"] = L10N.cfg.PARACHUTE,
    ["desc"] = L10N.cfg.IF_YOU_RE_FALLIN,
    --["icon"] = 644385,
    ["Ace3icon"] = "Interface/ICONS/archaeology_5_0_umbrellaofchiji.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 1706,
            --["name"] = "Levitate",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 130,
            --["name"] = "Slow Fall",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 164862,
            --["name"] = "Flap",
        },
        {
            ["type"] = "toy",
            --["name"] = "Delicate Crimson Parasol",
            ["itemId"] = 212524,
        },
        {
            ["type"] = "toy",
            --["name"] = "Stylish Black Parasol",
            ["itemId"] = 182694,
        },
        {
            ["type"] = "toy",
            --["name"] = "Weathered Purple Parasol",
            ["itemId"] = 182695,
        },
        {
            ["type"] = "toy",
            --["name"] = "The Countess's Parasol",
            ["itemId"] = 182696,
        },
        {
            ["type"] = "toy",
            --["name"] = "Delicate Jade Parasol",
            ["itemId"] = 212523,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 125883,
            --["name"] = "Zen Flight",
        },
        {
            ["type"] = "item",
            --["name"] = "Goblin Glider Kit",
            ["itemId"] = 109076,
        },
        {
            ["type"] = "toy",
            --["name"] = "Shroom Jumper's Parachute",
            ["itemId"] = 258963,
        },
    },
}
