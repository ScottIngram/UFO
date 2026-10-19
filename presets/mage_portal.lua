-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MAGE_PORTAL
local HORDE = 11
local ALLIANCE = 12

local getButtons = function()
    local result = Preset:getSpellsFromFlyout(HORDE, ALLIANCE)
    --zebug.warn:dumpy("result", result)
    return result
end

Preset.defs[id] = {
    ["name"] = "Mage Portals",
    --["icon"] = 237508,
    ["Ace3icon"] = "Interface/ICONS/spell_arcane_portaldalaran.blp",
    ["id"] = id,
    ["btns"] = getButtons,
}
