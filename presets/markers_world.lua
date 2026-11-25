-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MARKERS_WORLD

local errMsgMacro = [=[
/stopmacro [group]
/stopmacro [combat]
/run RaidWarningUtil.AddMessage("]=] .. L10N.MARKERS_WORLD_WARNING .. [=[", WARNING_FONT_COLOR, 5)
]=]

local function makeMacroText(n)
    return "/wm [@mouseover,noexists] " .. n .. "; [@cursor] " .. n .. EOL .. errMsgMacro
end

-- Blizz, why why WHY are you so consistently inconsistent?
-- NONE of the world markers share their numeric ID with their equivalent raid markers

local getButtons = function()
    local raidMarkers = Preset.defs[Preset.ids.MARKERS_RAID]
    local btns = deepcopy(raidMarkers.btns)
    btns[1].macroText = makeMacroText(5) -- Star
    btns[2].macroText = makeMacroText(6) -- Circle
    btns[3].macroText = makeMacroText(3) -- Diamond
    btns[4].macroText = makeMacroText(2) -- Triangle
    btns[5].macroText = makeMacroText(7) -- Moon
    btns[6].macroText = makeMacroText(1) -- Square
    btns[7].macroText = makeMacroText(4) -- Cross
    btns[8].macroText = makeMacroText(8) -- Skull
    btns[9].name = L10N.CLEAR_ALL_WORLD_MARKERS
    btns[9].macroText = "/cwm all" -- Clear All
    for i = 1, 8 do
        btns[i].name = btns[i].name .. " " .. L10N.WORLD_MARKER
    end
    return btns
end

Preset.defs[id] = {
    ["name"] = L10N.MARKERS_WORLD,
    ["desc"] = L10N.MARKERS_WORLD_DESC,
    ["icon"] = 413590,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mrpopularity_rank2.blp",
    ["id"] = id,
    ["btns"] = getButtons,
}
