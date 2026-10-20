-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.VISION
Preset.defs[id] = {
    ["name"] = "Vision",
    ["desc"] = "Spells and toys that grant you sight at a distance or enhanced vision.",
    ["icon"] = 1100023,
    ["Ace3icon"] = "Interface/ICONS/inv_darkmoon_eye.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "spell",
            ["spellId"] = 126,
            ["name"] = "Eye of Kilrogg",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 5502,
            ["name"] = "Sense Undead",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 2096,
            ["name"] = "Mind Vision",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 6196,
            ["name"] = "Far Sight",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 6197,
            ["name"] = "Eagle Eye",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 321297,
            ["name"] = "Eyes of the Beast",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 188501,
            ["name"] = "Spectral Sight",
        },
        {
            ["type"] = "toy",
            ["name"] = "Farwater Conch",
            ["itemId"] = 86581,
        },
        {
            ["type"] = "toy",
            ["name"] = "Legion Communication Orb",
            ["itemId"] = 153194,
        },
        {
            ["type"] = "item",
            ["name"] = "Scrying Roguestone",
            ["itemId"] = 83795,
        },
        {
            ["type"] = "toy",
            ["name"] = "All-Seer's Eye",
            ["itemId"] = 153204,
        },
        {
            ["type"] = "toy",
            ["name"] = "S.F.E. Interceptor",
            ["itemId"] = 153253,
        },
        {
            ["type"] = "toy",
            ["name"] = "Crashin' Thrashin' Racer Controller",
            ["itemId"] = 37710,
        },
        {
            ["type"] = "toy",
            ["name"] = "Blue Crashin' Thrashin' Racer Controller",
            ["itemId"] = 54343,
        },
        {
            ["type"] = "toy",
            ["name"] = "Micro-Artillery Controller",
            ["itemId"] = 153126,
        },
        {
            ["type"] = "toy",
            ["name"] = "MiniZep Controller",
            ["itemId"] = 46709,
        },
        {
            ["type"] = "toy",
            ["name"] = "Crashin' Thrashin' Flyer Controller",
            ["itemId"] = 104318,
        },
        {
            ["type"] = "toy",
            ["name"] = "Wheeled Floaty Boaty Controller",
            ["itemId"] = 200878,
        },
        {
            ["type"] = "toy",
            ["name"] = "Crashin' Thrashin' Flamer Controller",
            ["itemId"] = 108632,
        },
        {
            ["type"] = "toy",
            ["name"] = "Crashin' Thrashin' Juggernaught",
            ["itemId"] = 172222,
        },
        {
            ["type"] = "toy",
            ["name"] = "Rockin' Rollin' Racer Customizer 19.9.3",
            ["itemId"] = 187422,
        },
        {
            ["type"] = "toy",
            ["name"] = "Foxicopter Controller",
            ["itemId"] = 88802,
        },
        {
            ["type"] = "toy",
            ["name"] = "Gastropod Shell",
            ["itemId"] = 98136,
        },
    },
}
