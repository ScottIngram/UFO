---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrPet : MouseRat
local MrPet = {
    type       = MouseRatType.PET,
    primaryKey = "petGuid",
    isUsable_helper = true,
    setToolTip_helper = GameTooltip.SetCompanionPet,
    pickupToCursor_helper = C_PetJournal.PickupPet,
    --getName_helper = getPetNameAndIcon, -- replaced by getName() defined below
    --getIcon_helper = getPetNameAndIcon, -- replaced by getIcon() defined below
}

MouseRat:mixInto(MrPet)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

-- will the real petGuid please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param petGuid number the 2nd arg from GetCursorInfo
function MrPet:consumeGetCursorInfo(type, petGuid)
    self:setId(petGuid)
end

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


-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrPet)
