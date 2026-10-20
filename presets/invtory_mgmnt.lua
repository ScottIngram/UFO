-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.INVTORY_MGMNT
Preset.defs[id] = {
    ["name"] = "Invtory Mgmnt",
    ["desc"] = "Access your vendor mount, mail, bank, transmogger, etc.",
    ["icon"] = 413587,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mobilebanking.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["mountId"] = 1563,
            ["type"] = "mount",
            ["spellId"] = 122708,
            ["name"] = "Grand Expedition Yak",
        },
        {
            ["mountId"] = 280,
            ["type"] = "mount",
            ["name"] = "Traveler's Tundra Mammoth",
            ["spellId"] = 61425,
        },
        {
            ["mountId"] = 284,
            ["type"] = "mount",
            ["spellId"] = 61447,
            ["name"] = "Traveler's Tundra Mammoth",
        },
        {
            ["type"] = "toy",
            ["name"] = "Ethereal Transmogrifier",
            ["itemId"] = 206268,
        },
        {
            ["type"] = "spell",
            ["spellId"] = 460905,
            ["name"] = "Warband Bank Distance Inhibitor",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 69046,
            ["name"] = "Pack Hobgoblin",
        },
        {
            ["type"] = "toy",
            ["name"] = "Interdimensional Parcel Signal",
            ["itemId"] = 264695,
        },
        {
            ["type"] = "toy",
            ["name"] = "Katy's Stampwhistle",
            ["itemId"] = 156833,
        },
        {
            ["type"] = "toy",
            ["name"] = "Ohuna Perch",
            ["itemId"] = 194885,
        },
        {
            ["type"] = "toy",
            ["name"] = "Radiant Lynx Whistle",
            ["itemId"] = 239693,
        },
        {
            ["petGuid"] = "BattlePet-0-000014F4B9FB",
            ["type"] = "battlepet",
            ["name"] = "Argent Gruntling",
        },
        {
            ["type"] = "spell",
            ["spellId"] = 83958,
            ["name"] = "Mobile Banking",
        },
    },
}
