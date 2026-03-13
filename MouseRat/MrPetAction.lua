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

function MrPetAction:isUsable()
    -- because pets are sometimes not yet summoned when combat is already underway (eg while mounted)
    -- a positive result may come too late for the UI to react before combat lockdown happens, thus,
    -- cache any positive result to ensure it's available even when the pet is momentarily AWOL
    if not self.wasEverUsable then
        self.wasEverUsable = C_SpellBook.IsSpellInSpellBook(self:getId(), Enum.SpellBookSpellBank.Pet, true)
                or IsSpellKnownOrOverridesKnown(self:getId(), true)
    end
    return self.wasEverUsable
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
