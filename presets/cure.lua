-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.CURE
Preset.defs[id] = {
    ["name"] = "Cure",
    ["icon"] = 648207,
    ["Ace3icon"] = "Interface/ICONS/petbattle_health.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
