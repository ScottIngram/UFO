---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrPet : MouseRat
local MrPet = {
    mrType     = MouseRatType.PET,
    primaryKey = "petGuid",
    --apiForName = getPetNameAndIcon, -- replaced by getName() defined below
    --apiForIcon = getPetNameAndIcon, -- replaced by getIcon() defined below
    apiForPickup = C_PetJournal.PickupPet,
    apiForToolTip = GameTooltip.SetCompanionPet,
    --apiForUsable = ???, -- replaced by isUsable() defined below
}

MouseRat:mixInto(MrPet)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

function MrPet:isUsable()
    return true
end

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
