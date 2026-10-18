-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.BUFF
Preset.defs[id] = {
    ["name"] = "Buffs",
    ["icon"] = 135869,
    ["Ace3icon"] = "Interface/ICONS/spell_holy_arcaneintellect.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
