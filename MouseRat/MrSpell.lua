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
-- Class Methods
-------------------------------------------------------------------------------

-- not currently used. is a proof of concept
-- correct the fucked up shit from GetCursorInfo.
---@param gc0_type MouseRatType|nil the 1st value returned by _G.GetCursorInfo()
---@param gc1_spellIndex number|string|nil (optional) the 2nd value from _G.GetCursorInfo()
---@param gc2_bookType number|string|nil (optional) the 3rd value from _G.GetCursorInfo()
---@param gc3_spellId number|string|nil (optional) the 4th value from _G.GetCursorInfo()
---@param gc4_baseSpellId number|string|nil (optional) the 5th value from _G.GetCursorInfo()
---@return MouseRatType parrot the type param
---@return number id - in this case the spellId
---@return string subType - in this case the bookType
---@return number index - in this case the spellIndex
---@return number altId - in this case the baseSpellId
---@return table all of the above in a sanely homogenous consistent predictable naming scheme.  Take note, Bliz.
function MrSpell:fixGetCursorIdiot(gc0_type, gc1_spellIndex, gc2_bookType, gc3_spellId, gc4_baseSpellId)
    if self.type ~= gc0_type then return nil end
    return gc0_type, gc3_spellId, gc2_bookType, gc1_spellIndex, gc4_baseSpellId, {
        type = gc0_type,
        id = gc3_spellId,
        subType = gc2_bookType,
        index = gc1_spellIndex,
        altId = gc4_baseSpellId,
    }
end

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

---@return boolean true if the args from GetCursorIdiot match mine
function MrSpell:isThisCursorDataMine(type, _, _, spellId)
    return (self.type == type) and (self:getId() == spellId)
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
