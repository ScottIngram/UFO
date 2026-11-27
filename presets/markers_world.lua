-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MARKERS_WORLD

local function makeMacroText(n)
    -- this especially convoluted conditional is to restrict the mouseover to only enemies.
    -- without it, the button on the flyout itself qualifies as a mouseover target ffs.
    -- additional note,  Bliz's undocumented BS works in my favor for once:
    -- the /stopmacro lines seem to short-circuit execution of my WrapScript("PostClick") handler
    -- which closes the flyout.  Thus, the flyout remains open and the player can quickly select multiple markers!
    -- In case this causes some other bug, I could try rolling the /stopmacro logic into the /run itself thusly:
    -- /run if not IsInGroup() and not UnitAffectingCombat("player") then RaidWarningUtil.AddMessage("foobar", WARNING_FONT_COLOR, 5) end
    -- except I MUST keep the /stopmacro [combat]... so, yeah.  nevermind.  Rock hard catch 22!
    local x = [=[
/wm [@mouseover,noexists][@mouseover,exists,noharm] ]=] .. n .. "; [@cursor] " .. n .. [=[

/stopmacro [group]
/stopmacro [combat]
/run RaidWarningUtil.AddMessage("]=] .. L10N.MARKERS_WORLD_WARNING .. [=[", WARNING_FONT_COLOR, 5)
]=]
    return x
    --return "/wm [@mouseover,noexists] " .. n .. "; [@cursor] " .. n .. EOL .. errMsgMacro
end

-- Blizz, why why WHY are you so consistently inconsistent?
-- NONE of the world markers share their numeric ID with their equivalent raid markers

local getButtons = function()
    -- copy the buttons from the raid markers preset
    local raidMarkers = Preset.defs[Preset.ids.MARKERS_RAID]
    local btns = raidMarkers.btns
    -- which may actually be a function,
    -- or, if the user has triggered that preset in this session, would have been converted into an array.
    -- so we have to support both possibilities
    if isFunction(btns) then
        btns = btns()
    end
    btns = deepcopy((isFunction(btns) and btns()) or btns)

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
    ["icon"] = 4644002,
    ["Ace3icon"] = "Interface/ICONS/Inv_10_jewelcrafting3_rainbowprism_color2.blp",
    ["id"] = id,
    ["btns"] = getButtons,
}
