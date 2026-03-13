---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrPet : MouseRat
local MrPet = {
    type       = MouseRatType.PET,
    primaryKey = "petGuid",
    helpers = {
        isUsable = true,
        setToolTip = _G.GameTooltip.SetCompanionPet,
        pickupToCursor = C_PetJournal.PickupPet,
        --getName = getPetNameAndIcon, -- replaced by getName() defined below
        --getIcon = getPetNameAndIcon, -- replaced by getIcon() defined below
    },
}

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

function MrPet:getPetNameAndIcon()
    local _, _, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(self:getId())
    self.name = name
    self:setPvar("icon",icon) --pVars are hidden from SavedVariables
    return name, icon
end

function MrPet:getName()
    return self.name or self:getPetNameAndIcon()
end

function MrPet:getIcon()
    return self.icon or select(2, self:getPetNameAndIcon())
end

-- expresses the MrPet in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string hardcoded value that will be assigned to the SecureActionButton's attribute indicated (according to Bliz's fucking insane rules) by the above "type" attribute
---@return string text of a dynamically generated macro that will summon the goddamn pet
function MrPet:asSecureClickHandlerAttributes()
    -- TODO: fix bug where this fails in combat - perhaps control:CallMethod(keyName, ...) ?
    local petMacro = "/run C_PetJournal.SummonPetByGUID(" .. QUOTE .. self.petGuid .. QUOTE ..")"
    return ButtonType.MACRO, "macrotext", petMacro
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrPet)
