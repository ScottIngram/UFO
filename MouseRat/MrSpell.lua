---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrSpell : MouseRat
local MrSpell = {
    mrType     = MouseRatType.SPELL,
    primaryKey = "spellId",
    apiForName = C_Spell.GetSpellInfo,
    apiForIcon = C_Spell.GetSpellTexture,
    apiForUsable = C_SpellBook.IsSpellInSpellBook,
    apiForPickup = C_Spell.PickupSpell,
    apiForToolTip = GameTooltip.SetSpellByID,
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
