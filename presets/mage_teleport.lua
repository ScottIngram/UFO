-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.MAGE_TELEPORT
local HORDE = 1
local ALLIANCE = 8

local getButtons = function()
    local result = Preset:getSpellsFromFlyout(HORDE, ALLIANCE)
    return result
end

Preset.defs[id] = {
    ["name"] = L10N.cfg.MAGE_TELEPORT,
    ["desc"] = L10N.cfg.A_COPY_OF_THE_BUILT_IN_MAGE_TELEPORT,
    --["icon"] = 237509,
    ["Ace3icon"] = "Interface/ICONS/spell_arcane_teleportdalaran.blp",
    ["id"] = id,
    ["btns"] = getButtons,
}
