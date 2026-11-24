-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Zebug.TRACE)

local id = Preset.ids.MARKERS_RAID

-- experimental code to dynamically ask the raid frame for its marker buttons
local getButtons = function()
    local btns = {}
    zebug.info:event("gen markers"):dumpy("CompactRaidFrameManagerDisplayFrameRaidMarkers",Bliz.CompactRaidFrameManagerDisplayFrameRaidMarkers)
    local n, name, frame = 0, "raidMarker", nil
    repeat
        n = n + 1
        local kidName = name .. n
        frame = Bliz.CompactRaidFrameManagerDisplayFrameRaidMarkers[kidName]

        zebug.info:event("gen markers"):dumpy(kidName,frame)
    until frame == nil
    return btns
end

Preset.defs[id] = {
    ["name"] = L10N.MARKERS_RAID,
    ["desc"] = L10N.MARKERS_RAID_DESC,
    ["icon"] = 413589,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mrpopularity.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.STAR] .. " Star",
            ["icon"] = 413589,
            ["atlas"] = "GM-raidMarker8",
            ["macroText"] = "/tm 1", -- Yellow Star
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.CIRCLE] .. " Circle",
            ["icon"] = 237281,
            ["atlas"] = "GM-raidMarker7",
            ["macroText"] = "/tm 2", -- Orange Circle
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.DIAMOND] .. " Diamond",
            ["icon"] = 7549139,
            ["atlas"] = "GM-raidMarker6",
            ["macroText"] = "/tm 3", -- Purple Diamond
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.TRIANGLE] .. " Triangle",
            ["icon"] = 466280,
            ["atlas"] = "GM-raidMarker5",
            ["macroText"] = "/tm 4", -- Green Triangle
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.MOON] .. " Moon",
            ["icon"] = 1392543,
            ["atlas"] = "GM-raidMarker4",
            ["macroText"] = "/tm 5", -- Pale Blue Moon
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.SQUARE] .. " Square",
            ["icon"] = 135724,
            ["atlas"] = "GM-raidMarker3",
            ["macroText"] = "/tm 6", -- Blue Square
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.CROSS] .. " Cross",
            ["icon"] = 878249,
            ["atlas"] = "GM-raidMarker2",
            ["macroText"] = "/tm 7", -- Red Cross
        },
        {
            ["type"] = "macroText",
            ["name"] = RaidMarkerTexture[RaidMarker.SKULL] .. " Skull",
            ["icon"] = 237272, -- 236366, --
            ["atlas"] = "GM-raidMarker1",
            ["macroText"] = "/tm 8", -- White Skull
        },
        {
            ["type"] = "macroText",
            ["name"] = "Remove Target's Mark",
            ["icon"] = 135768,
            ["atlas"] = "GM-raidMarker-reset",
            ["macroText"] = "/tm 0", -- Clears the marker
        },
    },
}
