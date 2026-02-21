---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrSpell : MouseRat
local MrSpell = {
    type       = MouseRatType.SPELL,
    primaryKey = "spellId",
    getName_helper = C_Spell.GetSpellInfo,
    getIcon_helper = C_Spell.GetSpellTexture,
    isUsable_helper = C_SpellBook.IsSpellInSpellBook,
    setToolTip_helper = GameTooltip.SetSpellByID,
    pickupToCursor_helper = C_Spell.PickupSpell,
}

MouseRat:mixInto(MrSpell)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

-- will the real spellId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param _ any don't care
---@param spellId number the 4th arg from GetCursorInfo
function MrSpell:consumeGetCursorInfo(type, _, _, spellId)
    self:setId(spellId)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrSpell)
