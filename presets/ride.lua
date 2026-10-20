-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.RIDE

Preset.defs[id] = {
    ["name"] = "Ride",
    ["icon"] = 413588,
    ["desc"] = "Mounts and mount accessories -- the Summon Random Favorite Mount button, Path of Frost, Tuskarr Dinghy, etc.",
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mountup.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["noRnd"] = true,
            ["type"] = "item",
            ["name"] = "Magic Broom",
            ["itemId"] = 37011,
        },
        {
            ["mountId"] = 268435455,
            ["type"] = "summonmount",
            ["name"] = "Summon Random Favorite Mount",
            ["id"] = "summonmount",
            ["noRnd"] = true,
        },
        {
            ["name"] = "Zen Flight",
            ["type"] = "spell",
            ["noRnd"] = true,
            ["spellId"] = 125883,
        },
        {
            ["name"] = "Water Walking",
            ["type"] = "spell",
            ["noRnd"] = true,
            ["spellId"] = 546,
        },
        {
            ["name"] = "Path of Frost",
            ["type"] = "spell",
            ["noRnd"] = true,
            ["spellId"] = 3714,
        },
        {
            ["name"] = "Tuskarr Dinghy",
            ["type"] = "toy",
            ["noRnd"] = true,
            ["itemId"] = 198428,
        },
        {
            ["noRnd"] = true,
            ["type"] = "toy",
            ["name"] = "Vial of Endless Draconic Scales",
            ["itemId"] = 212518,
        },
        {
            ["mountId"] = 2806,
            ["type"] = "mount",
            ["name"] = "Spawn of Vyranoth",
            ["spellId"] = 1264184,
        },
        {
            ["mountId"] = 2941,
            ["type"] = "mount",
            ["name"] = "Flame-Painted Sun Roc",
            ["spellId"] = 1283910,
        },
        {
            ["mountId"] = 2984,
            ["type"] = "mount",
            ["name"] = "Rabbit'ath",
            ["spellId"] = 1293456,
        },
        {
            ["mountId"] = 2567,
            ["type"] = "mount",
            ["name"] = "Voidwing Dragonhawk",
            ["spellId"] = 1234303,
        },
        {
            ["mountId"] = 2568,
            ["type"] = "mount",
            ["name"] = "Lightwing Dragonhawk",
            ["spellId"] = 1234305,
        },
        {
            ["mountId"] = 978,
            ["type"] = "mount",
            ["spellId"] = 253639,
            ["name"] = "Violet Spellwing",
        },
        {
            ["mountId"] = 971,
            ["type"] = "mount",
            ["spellId"] = 253088,
            ["name"] = "Antoran Charhound",
        },
        {
            ["mountId"] = 2770,
            ["type"] = "mount",
            ["name"] = "Preyseeker's Wrath",
            ["spellId"] = 1261337,
        },

        {
            ["mountId"] = 1799,
            ["type"] = "mount",
            ["name"] = "Eve's Ghastly Rider",
            ["spellId"] = 419345,
        },
        {
            ["mountId"] = 1446,
            ["type"] = "mount",
            ["name"] = "Tazavesh Gearglider",
            ["spellId"] = 346554,
        },
        {
            ["mountId"] = 1397,
            ["type"] = "mount",
            ["name"] = "Wildseed Cradle",
            ["spellId"] = 334352,
        },
        {
            ["mountId"] = 2293,
            ["type"] = "mount",
            ["spellId"] = 466027,
            ["name"] = "Darkfuse Spy-Eye",
        },
        {
            ["mountId"] = 2840,
            ["type"] = "mount",
            ["spellId"] = 1268924,
            ["name"] = "Silvermoon's Arcane Defender",
        },
        {
            ["mountId"] = 382,
            ["type"] = "mount",
            ["spellId"] = 75973,
            ["name"] = "X-53 Touring Rocket",
        },
        {
            ["mountId"] = 962,
            ["type"] = "mount",
            ["name"] = "Darkmoon Dirigible",
            ["spellId"] = 247448,
        },
        {
            ["mountId"] = 2623,
            ["type"] = "mount",
            ["name"] = "The Headless Horseman's Ghoulish Charger",
            ["spellId"] = 1245198,
        },
        {
            ["mountId"] = 1517,
            ["type"] = "mount",
            ["spellId"] = 358072,
            ["name"] = "Bound Blizzard",
        },
        {
            ["mountId"] = 183,
            ["type"] = "mount",
            ["spellId"] = 40192,
            ["name"] = "Ashes of Al'ar",
        },
        {
            ["mountId"] = 417,
            ["type"] = "mount",
            ["name"] = "Corrupted Fire Hawk",
            ["spellId"] = 97560,
        },
        {
            ["mountId"] = 2261,
            ["type"] = "mount",
            ["spellId"] = 463133,
            ["name"] = "Coldflame Tempest",
        },
        {
            ["mountId"] = 2324,
            ["type"] = "mount",
            ["spellId"] = 471696,
            ["name"] = "Hooktalon",
        },
        {
            ["mountId"] = 2189,
            ["type"] = "mount",
            ["name"] = "Underlight Corrupted Behemoth",
            ["spellId"] = 448851,
        },
        {
            ["mountId"] = 1315,
            ["type"] = "mount",
            ["spellId"] = 315987,
            ["name"] = "Mail Muncher",
        },
        {
            ["mountId"] = 1310,
            ["type"] = "mount",
            ["spellId"] = 332882,
            ["name"] = "Horrid Dredwing",
        },
        {
            ["mountId"] = 779,
            ["type"] = "mount",
            ["name"] = "Spirit of Eche'ro",
            ["spellId"] = 196681,
        },
        {
            ["mountId"] = 1744,
            ["type"] = "mount",
            ["spellId"] = 412088,
            ["name"] = "Grotto Netherwing Drake",
        },
        {
            ["mountId"] = 2502,
            ["type"] = "mount",
            ["spellId"] = 1218317,
            ["name"] = "Void-Crystal Panther",
        },
        {
            ["mountId"] = 1783,
            ["type"] = "mount",
            ["spellId"] = 414334,
            ["name"] = "Scourgebound Vanquisher",
        },
        {
            ["mountId"] = 2518,
            ["type"] = "mount",
            ["spellId"] = 1226144,
            ["name"] = "Chrono Corsair",
        },
        {
            ["mountId"] = 1556,
            ["type"] = "mount",
            ["spellId"] = 359843,
            ["name"] = "Tangled Dreamweaver",
        },
        {
            ["mountId"] = 1346,
            ["type"] = "mount",
            ["spellId"] = 326390,
            ["name"] = "Steamscale Incinerator",
        },
        {
            ["mountId"] = 1414,
            ["type"] = "mount",
            ["name"] = "Sinrunner Blanchy",
            ["spellId"] = 339588,
        },
        {
            ["mountId"] = 532,
            ["type"] = "mount",
            ["spellId"] = 136505,
            ["name"] = "Ghastly Charger",
        },
    },
}
