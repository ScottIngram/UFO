-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.DELVE
Preset.defs[id] = {
    ["name"] = "Delves",
    ["desc"] = "Stuff only useful inside or getting into delves: Delve-O-Bot, L00T RAID-R, That-THING-to-Summon the Nemis-S.",
    --["icon"] = 1064187,
    ["Ace3icon"] = "Interface/ICONS/icon_treasuremap.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "toy",
            ["name"] = "Delve-O-Bot 7001",
            ["itemId"] = 230850,
        },
        {
            ["type"] = "toy",
            ["name"] = "Kinduru's Spiriting Quill",
            ["itemId"] = 286643,
        },
        {
            ["type"] = "toy",
            ["name"] = "Midnight Delver's Flare Gun",
            ["itemId"] = 264414,
        },
        {
            ["type"] = "toy",
            ["name"] = "Delver's Mana-Bound Ethergate",
            ["itemId"] = 243056,
        },
        {
            ["type"] = "item",
            ["name"] = "L00T RAID-R Mini",
            ["itemId"] = 244193,
        },
        {
            ["type"] = "item",
            ["name"] = "Scalebound Herald's Flute",
            ["itemId"] = 275910,
        },
        {
            ["type"] = "item",
            ["name"] = "Beacon of Hope",
            ["itemId"] = 253342,
        },
        {
            ["type"] = "item",
            ["name"] = "Shrieking Quartz",
            ["itemId"] = 248017,
        },
    },

}
