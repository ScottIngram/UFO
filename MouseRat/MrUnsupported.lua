---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrUnsupported : MouseRat
MrUnsupported = {
    type       = MouseRatType.UNSUPPORTED,
    primaryKey = "id",
    getIcon_helper = 134400, -- the question mark
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
    self.name = strjoinnilsafe(",", ...)
    self.cursorInfo = {...} -- in case we want to know later
end
