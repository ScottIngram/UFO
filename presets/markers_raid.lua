-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Zebug.TRACE)

local id = Preset.ids.MARKERS_RAID

local function makeMacroName(key)
    return RaidMarkerTexture[RaidMarker[key]] .. " " .. Ufo.L10N[RaidMarker[key]]
end

local getButtons = function()
    local me = Preset.defs[id]
    local btns = me.protoBtns
    for i, btn in ipairs(btns) do
        local key = btns[i].key
        local rmId = RaidMarker[key]
        btn.name      = btn.name or (RaidMarkerTexture[RaidMarker[rmId]] .. " " .. Ufo.L10N[RaidMarker[rmId]])
        btn.macroText = "/tm [@mouseover,exists][@target,exists][@player] " .. btn.id
        btn.type      = "macroText"
    end
    me.btns = btns
    me.protoBtns = nil
    return btns
end

Preset.defs[id] = {
    ["name"] = L10N.MARKERS_RAID,
    ["desc"] = L10N.MARKERS_RAID_DESC,
    ["icon"] = 413589,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mrpopularity.blp",
    ["id"] = id,
    ["btns"] = getButtons,
    ["protoBtns"] = {
        {
            ["id"] = 1,
            ["key"] = RaidMarker.STAR,
            ["icon"] = 413589,
            ["atlas"] = "GM-raidMarker8",
        },
        {
            ["id"] = 2,
            ["key"] = RaidMarker.CIRCLE,
            ["icon"] = 237281,
            ["atlas"] = "GM-raidMarker7",
        },
        {
            ["id"] = 3,
            ["key"] = RaidMarker.DIAMOND,
            ["icon"] = 7549139,
            ["atlas"] = "GM-raidMarker6",
        },
        {
            ["id"] = 4,
            ["key"] = RaidMarker.TRIANGLE,
            ["icon"] = 466280,
            ["atlas"] = "GM-raidMarker5",
        },
        {
            ["id"] = 5,
            ["key"] = RaidMarker.MOON,
            ["icon"] = 1392543,
            ["atlas"] = "GM-raidMarker4",
        },
        {
            ["id"] = 6,
            ["key"] = RaidMarker.SQUARE,
            ["icon"] = 135724,
            ["atlas"] = "GM-raidMarker3",
        },
        {
            ["id"] = 7,
            ["key"] = RaidMarker.CROSS,
            ["icon"] = 878249,
            ["atlas"] = "GM-raidMarker2",
        },
        {
            ["id"] = 8,
            ["key"] = RaidMarker.SKULL,
            ["icon"] = 237272,
            ["atlas"] = "GM-raidMarker1",
        },
        {
            ["id"] = 0,
            ["name"] = 	L10N.REMOVE_TARGETS_MARK,
            ["icon"] = 135768,
            ["atlas"] = "GM-raidMarker-reset",
        },
    },
}
