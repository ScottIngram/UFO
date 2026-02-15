---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrFlyout : MouseRat
local MrFlyout = {
    mrType         = MouseRatType.FLYOUT,
    primaryKey = "spellId",
    apiForPickup    = C_Spell.PickupSpell,
}

MouseRatRegistry:register(MrFlyout)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

---@param spellId number will the real spellId please stand up!
---@return boolean true if the args contain the necessary data
function MrFlyout:consumeGetCursorInfo(_, _, _, spellId)
    -- do I want to validate spellId as a number ?
    if not spellId then return false end
    self:setId(spellId)
    return true
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrFlyout)
