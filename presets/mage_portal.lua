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
    return result
end

Preset.defs[id] = {
    ["name"] = L10N.cfg.MAGE_PORTALS,
    ["desc"] = L10N.cfg.A_COPY_OF_THE_BUILT_IN_MAGE_PORTALS,
    --["icon"] = 237508,
    ["Ace3icon"] = "Interface/ICONS/spell_arcane_portaldalaran.blp",
    ["id"] = id,
    ["btns"] = getButtons,
}
