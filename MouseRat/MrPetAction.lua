---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrPetAction : MouseRat
local MrPetAction = {
    mrType     = MouseRatType.PETACTION,
    primaryKey = "petSpellId",
    getName_helper = C_Spell.GetSpellInfo,
    getIcon_helper = C_Spell.GetSpellTexture,
    setToolTip_helper = GameTooltip.SetSpellByID,
    pickupToCursor_helper = _G.PickupPetSpell,
    --isUsable_helper = C_SpellBook.IsSpellInSpellBook, -- replaced by isUsable() defined below
}

MouseRat:mixInto(MrPetAction)

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
        --error("How did we reach here?")
    end
    self:setId(spellId)
end

function MrPetAction:isUsable()
    return C_SpellBook.IsSpellInSpellBook(self:getId(), Enum.SpellBookSpellBank.Pet, true)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrPetAction)
