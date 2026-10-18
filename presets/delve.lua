-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.DELVE
Preset.defs[id] = {
    ["name"] = "Delves",
    ["icon"] = 81064187,
    ["Ace3icon"] = "Interface/ICONS/icon_treasuremap.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
