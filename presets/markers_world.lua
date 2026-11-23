-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MARKERS_WORLD

-- Blizz, why why WHY are you so consistently inconsistent?
-- NONE of the world markers share their numeric ID with their equivalent raid markers

local getButtons = function()
    local raidMarkers = Preset.defs[Preset.ids.MARKERS_RAID]
    local btns = deepcopy(raidMarkers.btns)
    zebug.error:dumpy("getButtons", btns)
    btns[1].macroText = "/wm [@cursor] 5" -- Star
    btns[2].macroText = "/wm [@cursor] 6" -- Circle
    btns[3].macroText = "/wm [@cursor] 3" -- Diamond
    btns[4].macroText = "/wm [@cursor] 2" -- Triangle
    btns[5].macroText = "/wm [@cursor] 7" -- Moon
    btns[6].macroText = "/wm [@cursor] 1" -- Square
    btns[7].macroText = "/wm [@cursor] 4" -- Cross
    btns[8].macroText = "/wm [@cursor] 8" -- Skull
    btns[9].name = "Clear All World Markers"
    btns[9].macroText = "/cwm all" -- Clear All
    for i = 1, 8 do
        btns[i].name = btns[i].name .. " World Marker"
    end
    return btns
end

Preset.defs[id] = {
    ["name"] = L10N.cfg.MARKERS_WORLD,
    ["desc"] = L10N.cfg.MARKERS_WORLD_DESC,
    ["icon"] = 413590,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mrpopularity_rank2.blp",
    ["id"] = id,
    ["btns"] = getButtons,
    ["btns_OLD"] = {
        {
            ["type"] = "macroText",
            ["name"] = "Star",
            ["icon"] = 413589,
            ["atlas"] = "GM-raidMarker8",
            ["macroText"] = "/wm [@cursor] 5", -- Yellow Star
        },
        {
            ["type"] = "macroText",
            ["name"] = "Circle",
            ["icon"] = 237281,
            ["atlas"] = "GM-raidMarker7",
            ["macroText"] = "/wm [@cursor] 6", -- Orange Circle
        },
        {
            ["type"] = "macroText",
            ["name"] = "Diamond",
            ["icon"] = 7549139,
            ["atlas"] = "GM-raidMarker6",
            ["macroText"] = "/wm [@cursor] 3", -- Purple Diamond
        },
        {
            ["type"] = "macroText",
            ["name"] = "Triangle",
            ["icon"] = 466280,
            ["atlas"] = "GM-raidMarker5",
            ["macroText"] = "/wm [@cursor] 2", -- Green Triangle
        },
        {
            ["type"] = "macroText",
            ["name"] = "Moon",
            ["icon"] = 1392543,
            ["atlas"] = "GM-raidMarker4",
            ["macroText"] = "/wm [@cursor] 7", -- Pale Blue Moon
        },
        {
            ["type"] = "macroText",
            ["name"] = "Square",
            ["icon"] = 135724,
            ["atlas"] = "GM-raidMarker2",
            ["macroText"] = "/wm [@cursor] 1", -- Blue Square
        },
        {
            ["type"] = "macroText",
            ["name"] = "Cross",
            ["icon"] = 878249,
            ["atlas"] = "GM-raidMarker2",
            ["macroText"] = "/wm [@cursor] 4", -- Red Cross
        },
        {
            ["type"] = "macroText",
            ["name"] = "Skull",
            ["icon"] = 237272, -- 236366, --
            ["atlas"] = "GM-raidMarker1",
            ["macroText"] = "/wm [@cursor] 8", -- White Skull
        },
        {
            ["type"] = "macroText",
            ["name"] = "Clear All",
            ["icon"] = 135768,
            ["atlas"] = "GM-raidMarker-reset",
            ["macroText"] = "/cwm all", -- Clears the marker
        },
    },
}
