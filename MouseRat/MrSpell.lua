---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrSpell : MouseRat
local MrSpell = {
    type       = MouseRatType.SPELL,
    primaryKey = "spellId",
    helpers = {
        getName = C_Spell.GetSpellInfo,
        getIcon = C_Spell.GetSpellTexture,
        isUsable = C_SpellBook.IsSpellInSpellBook,
        setToolTip = _G.GameTooltip.SetSpellByID,
        pickupToCursor = C_Spell.PickupSpell,
    },
}

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

-- expresses the MrSpell in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string hardcoded value that will be assigned to the SecureActionButton's attribute indicated (according to Bliz's fucking insane rules) by the above "type" attribute
---@return string text of a dynamically generated macro that will summon the goddamn pet
function MrSpell:asSecureClickHandlerAttributes()
    -- PROFESSIONS - TODO? split into a sub-type ?
    local professionSnafuId = ProfessionShitShow:get(self.name)
    --zebug.error:event():owner(self):print("name",self.name, "id",self.spellId, "professionSnafuId", professionSnafuId)
    if professionSnafuId then
        local profMacro = sprintf("/run C_TradeSkillUI.OpenTradeSkill(%d)", professionSnafuId)
        zebug.trace:event():owner(self):print("name",self.name, "professionSnafuId", professionSnafuId, "profMacro",profMacro)
        return ButtonType.MACRO, "macrotext", profMacro
    else
        return MouseRat.asSecureClickHandlerAttributes(self)
    end
end


-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrSpell)
