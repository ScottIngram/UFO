---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrUnsupported : MouseRat
MrUnsupported = {
    mrType     = MouseRatType.UNSUPPORTED,
    primaryKey = "id",
    apiForName = nil,
    apiForIcon = nil,
    apiForUsable = MouseRat.nop,
    apiForPickup = ClearCursor,
    apiForToolTip = GameTooltip.SetSpellByID,
}

MouseRatRegistry:register(MrUnsupported)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

---@param type BlizCursorType will the real spellId please stand up!
function MrUnsupported:consumeGetCursorInfo(type, ...)
    self.type = type
    self.name = strjoinnilsafe(", ", type, ...)
    self.cursorInfo = {...} -- in case we want to know later
end
