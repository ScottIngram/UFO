-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.INVTORY_MGMNT
Preset.defs[id] = {
    ["name"] = "Invtory Mgmnt",
    ["icon"] = 413587,
    ["Ace3icon"] = "Interface/ICONS/achievement_guildperk_mobilebanking.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
