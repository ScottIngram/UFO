-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.RIDE

Preset.defs[id] = {
    ["name"] = "Ride",
    ["icon"] = 236552,
    ["Ace3icon"] = "Interface/ICONS/achievement_halloween_witch_01.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
