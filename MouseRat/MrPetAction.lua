---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrPetAction : MouseRat
local MrPetAction = {
    type       = MouseRatType.PETACTION,
    primaryKey = "petSpellId",
    helpers = {
        getName = C_Spell.GetSpellInfo,
        getIcon = C_Spell.GetSpellTexture,
        setToolTip = _G.GameTooltip.SetSpellByID,
        pickupToCursor = _G.PickupPetSpell,
        --isUsable = C_SpellBook.IsSpellInSpellBook, -- replaced by isUsable() defined below
    }
}

------------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrPetAction
------------------------------------------------------------------------------------

-- will the real spellId please stand up!
---@param _ any do not care
---@param spellId number the 2nd arg from GetCursorInfo - Spell ID of the pet action on the cursor, or unknown 0-4 number if the spell is a shared pet control spell (Follow, Stay, Assist, Defensive, etc...)..
function MrPetAction:consumeGetCursorInfo(_, spellId, _, _)
    if spellId < 10 then
        -- the Bliz API is shite.  This isn't a petaction.  None of the APIs understand it.  Fuck you bliz.
        -- the MrBrokenPetAction should have intercepted this.  In absence of a bug in my code,  we should never reach here.
        error("How did we reach here?")
    end
    self:setId(spellId)
end

function MrPetAction:isUsable()
    return C_SpellBook.IsSpellInSpellBook(self:getId(), Enum.SpellBookSpellBank.Pet, true)
end

-- expresses the MouseRat in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
-- the following is a generic handler that is good enough for some simpler MouseRatTypes.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute related to the above "type" attribute (according to Bliz's convoluted rules)
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrPetAction:asSecureClickHandlerAttributes()
    assert(self.isInstance, "instance method called from a class context")
    --zebug.info:event("event"):owner(self):print("default asSecureClickHandlerAttributes")
    return MouseRatType.SPELL, MouseRatType.SPELL, self:getId()
end


-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrPetAction)
