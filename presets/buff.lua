-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.BUFF
Preset.defs[id] = {
    ["name"] = L10N.cfg.BUFFS,
    ["desc"] = L10N.cfg.SPELLS_FROM_VARIOUS_CLASSES,
    --["icon"] = 135869,
    ["Ace3icon"] = "Interface/ICONS/spell_holy_arcaneintellect.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 21562,
            --["name"] = "Power Word: Fortitude",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1459,
            --["name"] = "Arcane Intellect",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 192106,
            --["name"] = "Lightning Shield",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 52127,
            --["name"] = "Water Shield",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 318038,
            --["name"] = "Flametongue Weapon",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 462854,
            --["name"] = "Skyfury",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 462757,
            --["name"] = "Thunderstrike Ward",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 1126,
            --["name"] = "Mark of the Wild",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 364342,
            --["name"] = "Blessing of the Bronze",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 6673,
            --["name"] = "Battle Shout",
        },
        {
            ["type"] = "item",
            --["name"] = "Eternal Augment Rune",
            ["itemId"] = 190384,
        },
        {
            ["type"] = "item",
            --["name"] = "Repurposed Fel Focuser",
            ["itemId"] = 147707,
        },
        {
            ["type"] = "item",
            --["name"] = "Oralius' Whispering Crystal",
            ["itemId"] = 118922,
        },
        {
            ["type"] = "item",
            --["name"] = "Thalassian Phoenix Oil",
            ["itemId"] = 243733,
        },
        {
            ["type"] = "item",
            --["name"] = "Thalassian Phoenix Oil",
            ["itemId"] = 243734,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of the Blood Knights",
            ["itemId"] = 241325,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of the Blood Knights",
            ["itemId"] = 241324,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of Tempered Swiftness",
            ["itemId"] = 212274,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of Tempered Swiftness",
            ["itemId"] = 212273,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of Tempered Mastery",
            ["itemId"] = 212280,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of Tempered Mastery",
            ["itemId"] = 212278,
        },
        {
            ["type"] = "item",
            --["name"] = "Flask of Tempered Mastery",
            ["itemId"] = 212279,
        },
        {
            ["type"] = "item",
            --["name"] = "Hearty Impossibly Royal Roast",
            ["itemId"] = 268679,
        },
        {
            ["type"] = "item",
            --["name"] = "Impossibly Royal Roast",
            ["itemId"] = 255847,
        },
        {
            ["type"] = "item",
            --["name"] = "Fel-Kissed Filet",
            ["itemId"] = 242286,
        },
        {
            ["type"] = "item",
            --["name"] = "Hearty Mana-Infused Stew",
            ["itemId"] = 242770,
        },
        {
            ["type"] = "item",
            --["name"] = "Hearthflame Supper",
            ["itemId"] = 242295,
        },
        {
            ["type"] = "item",
            --["name"] = "Hearty Hearthflame Supper",
            ["itemId"] = 242767,
        },
        {
            ["type"] = "item",
            --["name"] = "Harandar Celebration",
            ["itemId"] = 255846,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 315584,
            --["name"] = "Instant Poison",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 3408,
            --["name"] = "Crippling Poison",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 381637,
            --["name"] = "Atrophic Poison",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 8679,
            --["name"] = "Wound Poison",
        },
    },
}
