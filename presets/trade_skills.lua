-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.TRADE_SKILLS
Preset.defs[id] = {
    ["name"] = "Trade Skills",
    --["icon"] = 4620681,
    ["Ace3icon"] = "Interface/ICONS/ui_profession_tailoring.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 195126,
            ["name"] = "Tailoring",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1223014,
            ["name"] = "Overload Infused Herb",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1225392,
            ["name"] = "Overload Infused Deposit",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 13262,
            ["name"] = "Disenchant",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195096,
            ["name"] = "Enchanting",
        },
        {
            ["type"] = "item",
            ["name"] = "Empowered Mulch",
            ["itemId"] = 238389,
        },
        {
            ["type"] = "item",
            ["name"] = "Imbued Mulch",
            ["itemId"] = 238388,
        },
        {
            ["type"] = "item",
            ["name"] = "Magical Mulch",
            ["itemId"] = 238387,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195095,
            ["name"] = "Alchemy",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 440977,
            ["name"] = "Sharpen Your Knife",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1226037,
            ["name"] = "Carve Meat",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195115,
            ["name"] = "Inscription",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 193290,
            ["name"] = "Herbalism Journal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195128,
            ["name"] = "Cooking",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195116,
            ["name"] = "Jewelcrafting",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2018,
            ["name"] = "Blacksmithing",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 259930,
            ["name"] = "Forge of Light",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 158739,
            ["name"] = "Engineering",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2656,
            ["name"] = "Mining Journal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 53428,
            ["name"] = "Runeforging",
        },
        {
            ["type"] = "item",
            ["name"] = "Lightbloom Diffuser",
            ["itemId"] = 238657,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 195119,
            ["name"] = "Leatherworking",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 194174,
            ["name"] = "Skinning Journal",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 271990,
            ["name"] = "Fishing Journal",
        },
        {
            ["type"] = "toy",
            ["name"] = "Chef's Hat",
            ["itemId"] = 134020,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 818,
            ["name"] = "Cooking Fire",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 45360,
            ["name"] = "Inscription",
        },
        {
            ["type"] = "item",
            ["name"] = "Haranir Phial of Finesse",
            ["itemId"] = 241310,
        },
        {
            ["type"] = "item",
            ["name"] = "Haranir Phial of Finesse",
            ["itemId"] = 241311,
        },
        {
            ["type"] = "item",
            ["name"] = "Haranir Phial of Perception",
            ["itemId"] = 241317,
        },
        {
            ["type"] = "item",
            ["name"] = "Ironclaw Razorstone",
            ["itemId"] = 222507,
        },
        {
            ["type"] = "item",
            ["name"] = "Ironclaw Razorstone",
            ["itemId"] = 222506,
        },
        {
            ["type"] = "item",
            ["name"] = "Ironclaw Razorstone",
            ["itemId"] = 222505,
        },
        {
            ["type"] = "item",
            ["name"] = "Darkmoon Firewater",
            ["itemId"] = 124671,
        },
    },
}
