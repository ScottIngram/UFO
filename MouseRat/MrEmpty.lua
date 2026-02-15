---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrEmpty : MouseRat
MrEmpty = {
    mrType         = MouseRatType.EMPTY,
    primaryKey = nil,
    apiForPickup    = ClearCursor,
    consumeGetCursorInfo= function(type, _, _, _) return nil  end,
}

MouseRatRegistry:register(MrEmpty)
