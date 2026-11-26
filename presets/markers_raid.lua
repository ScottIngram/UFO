-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Zebug.TRACE)

local id = Preset.ids.MARKERS_RAID

local getButtons = function()
end

local function makeMacroName(key)
    return RaidMarkerTexture[RaidMarker[key]] .. " " .. Ufo.L10N[RaidMarker[key]]
end

local function makeMacroText(n)
    local t = "/tm [@mouseover,exists][@target,exists][@player] " .. n
    return t
end


-- [@mouseover,exists] mouseover; [@target,exists] target; player

Preset.defs[id] = {
    ["name"] = L10N.MARKERS_RAID,
    ["desc"] = L10N.MARKERS_RAID_DESC,
    ["icon"] = 413589,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mrpopularity.blp",
    ["id"] = id,
    ["btns"] = {
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.STAR),
            ["icon"] = 413589,
            ["atlas"] = "GM-raidMarker8",
            ["macroText"] = makeMacroText(1), -- Yellow Star
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.CIRCLE),
            ["icon"] = 237281,
            ["atlas"] = "GM-raidMarker7",
            ["macroText"] = makeMacroText(2), -- Orange Circle
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.DIAMOND),
            ["icon"] = 7549139,
            ["atlas"] = "GM-raidMarker6",
            ["macroText"] = makeMacroText(3), -- Purple Diamond
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.TRIANGLE),
            ["icon"] = 466280,
            ["atlas"] = "GM-raidMarker5",
            ["macroText"] = makeMacroText(4), -- Green Triangle
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.MOON),
            ["icon"] = 1392543,
            ["atlas"] = "GM-raidMarker4",
            ["macroText"] = makeMacroText(5), -- Pale Blue Moon
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.SQUARE),
            ["icon"] = 135724,
            ["atlas"] = "GM-raidMarker3",
            ["macroText"] = makeMacroText(6), -- Blue Square
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.CROSS),
            ["icon"] = 878249,
            ["atlas"] = "GM-raidMarker2",
            ["macroText"] = makeMacroText(7), -- Red Cross
        },
        {
            ["type"] = "macroText",
            ["name"] = makeMacroName(RaidMarker.SKULL),
            ["icon"] = 237272, -- 236366, --
            ["atlas"] = "GM-raidMarker1",
            ["macroText"] = makeMacroText(8), -- White Skull
        },
        {
            ["id"] = 0,
            ["name"] = 	L10N.REMOVE_TARGETS_MARK,
            ["icon"] = 135768,
            ["atlas"] = "GM-raidMarker-reset",
            ["macroText"] = makeMacroText(0), -- Clears the marker
        },
    },
}
