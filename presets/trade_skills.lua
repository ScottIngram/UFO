-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

local id = Preset.ids.TRADE_SKILLS
Preset.defs[id] = {
    ["name"] = "Trade Skills",
    ["icon"] = 84620681,
    ["Ace3icon"] = "Interface/ICONS/ui_profession_tailoring.blp",
    ["id"] = id,
    ["btns"] = {
    }
}
