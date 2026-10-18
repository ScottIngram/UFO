-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.HEAL
Preset.defs[id] = {
    ["name"] = "Heal",
    ["icon"] = 648632,
    ["Ace3icon"] = "Interface/ICONS/achievement_guild_doctorisin.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
