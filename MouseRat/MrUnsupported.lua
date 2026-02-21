---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrUnsupported : MouseRat
MrUnsupported = {
    type       = MouseRatType.UNSUPPORTED,
    primaryKey = "id",
    getName_helper = nil,
    getIcon_helper = nil,
    isUsable_helper = MouseRat.nop,
    setToolTip_helper = GameTooltip.SetSpellByID,
    pickupToCursor_helper = ClearCursor,
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
