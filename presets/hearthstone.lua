-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.HEARTHSTONE
Preset.defs[id] = {
    ["name"] = "HearthStones",
    ["desc"] = "A selection of toys, spells, and items that send you home.",
    ["icon"] = 413582,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_hastyhearth.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "toy",
            ["name"] = "Corewarden's Hearthstone",
            ["itemId"] = 265100,
        },
        {
            ["name"] = "Redeployment Module",
            ["type"] = "toy",
            ["itemId"] = 235016,
        },
        {
            ["type"] = "toy",
            ["name"] = "Lightcalled Hearthstone",
            ["itemId"] = 257736,
        },
        {
            ["type"] = "toy",
            ["name"] = "Enlightened Hearthstone",
            ["itemId"] = 190196,
        },
        {
            ["type"] = "toy",
            ["name"] = "Ethereal Portal",
            ["itemId"] = 54452,
        },
        {
            ["type"] = "toy",
            ["name"] = "Broker Translocation Matrix",
            ["itemId"] = 190237,
        },
        {
            ["type"] = "toy",
            ["name"] = "Preyseeker's Hearthstone",
            ["itemId"] = 263933,
        },
        {
            ["type"] = "toy",
            ["name"] = "Peddlefeet's Lovely Hearthstone",
            ["itemId"] = 165670,
        },
        {
            ["type"] = "toy",
            ["name"] = "Stone of the Hearth",
            ["itemId"] = 212337,
        },
        {
            ["type"] = "toy",
            ["name"] = "Eternal Traveler's Hearthstone",
            ["itemId"] = 172179,
        },
        {
            ["type"] = "toy",
            ["name"] = "P.O.S.T. Master's Express Hearthstone",
            ["itemId"] = 245970,
        },
        {
            ["type"] = "toy",
            ["name"] = "Headless Horseman's Hearthstone",
            ["itemId"] = 163045,
        },
        {
            ["name"] = "Greatfather Winter's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 162973,
        },
        {
            ["type"] = "toy",
            ["name"] = "Fire Eater's Hearthstone",
            ["itemId"] = 166746,
        },
        {
            ["type"] = "toy",
            ["name"] = "Venthyr Sinstone",
            ["itemId"] = 183716,
        },
        {
            ["type"] = "toy",
            ["name"] = "Timewalker's Hearthstone",
            ["itemId"] = 193588,
        },
        {
            ["name"] = "Deepdweller's Earthen Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 208704,
        },
        {
            ["name"] = "Explosive Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 236687,
        },
        {
            ["name"] = "Hearthstone of the Flame",
            ["type"] = "toy",
            ["itemId"] = 209035,
        },
        {
            ["name"] = "Notorious Thread's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 228940,
        },
        {
            ["name"] = "Necrolord Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 182773,
        },
        {
            ["name"] = "Kyrian Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 184353,
        },
        {
            ["name"] = "Lunar Elder's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 165669,
        },
        {
            ["type"] = "toy",
            ["name"] = "Night Fae Hearthstone",
            ["itemId"] = 180290,
        },
        {
            ["type"] = "toy",
            ["name"] = "Dominated Hearthstone",
            ["itemId"] = 188952,
        },
        {
            ["name"] = "Ohn'ir Windsage's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 200630,
        },
        {
            ["name"] = "Noble Gardener's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 165802,
        },
        {
            ["name"] = "Brewfest Reveler's Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 166747,
        },
        {
            ["name"] = "Tome of Town Portal",
            ["type"] = "toy",
            ["itemId"] = 142542,
        },
        {
            ["name"] = "The Innkeeper's Daughter",
            ["type"] = "toy",
            ["itemId"] = 64488,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 556,
            ["name"] = "Astral Recall",
        },
        {
            ["name"] = "Direbrew's Remote",
            ["type"] = "item",
            ["itemId"] = 37863,
            ["noRnd"] = true,
        },
        {
            ["name"] = "Delver's Mana-Bound Ethergate",
            ["type"] = "toy",
            ["itemId"] = 243056,
            ["noRnd"] = true,
        },
        {
            ["name"] = "Argent Crusader's Tabard",
            ["type"] = "item",
            ["itemId"] = 46874,
            ["noRnd"] = true,
        },
        {
            ["type"] = "toy",
            ["name"] = "Lightveil Recall Beacon",
            ["itemId"] = 276371,
            ["noRnd"] = true,
        },
        {
            ["type"] = "toy",
            ["name"] = "Unstable Portal Emitter",
            ["itemId"] = 153004,
            ["noRnd"] = true,
        },
        {
            ["type"] = "toy",
            ["name"] = "Nature's Beacon",
            ["itemId"] = 136849,
            ["noRnd"] = true,
        },
        {
            ["name"] = "Dreamwalk",
            ["type"] = "spell",
            ["spellId"] = 193753,
            ["noRnd"] = true,
        },
        {
            ["name"] = "Personal Key to the Arcantina",
            ["type"] = "toy",
            ["itemId"] = 253629,
            ["noRnd"] = true,
        },
        {
            ["spellId"] = 50977,
            ["type"] = "spell",
            ["name"] = "Death Gate",
            ["noRnd"] = true,
        },
        {
            ["name"] = "Garrison Hearthstone",
            ["type"] = "toy",
            ["itemId"] = 110560,
            ["noRnd"] = true,
        },
        {
            ["type"] = "toy",
            ["name"] = "Dalaran Hearthstone",
            ["itemId"] = 140192,
            ["noRnd"] = true,
        },
    },
}
