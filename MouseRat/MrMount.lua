---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrMount : MouseRat
local MrMount = {
    mrType     = MouseRatType.MOUNT,
    primaryKey = "mountId",
    iconKey    = "spellId",
    -- many APIs in C_Spell also accept mountId
    apiForName = C_MountJournal.GetMountInfoByID,
    apiForIcon = C_Spell.GetSpellTexture, -- C_MountJournal.GetMountInfoByID(mountID) result[3]
    apiForPickup = C_Spell.PickupSpell,
    apiForToolTip = GameTooltip.SetSpellByID,
    --apiForUsable = C_MountJournal.GetMountUsabilityByID, -- replaced by isUsable() defined below
}

MouseRat:mixInto(MrMount)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

-- I wrote extra code into MouseRat:getIcon() to support the optional "iconKey" field.
-- Otherwise, I could have simply done the following.
---@return number texture ID
function MrMount:getIcon_EXAMPLE()
    local _, _, icon = C_MountJournal.GetMountInfoByID(self:getId())
    return icon
end

function MrMount:isUsable()
    -- local isUsable, err = C_MountJournal.GetMountUsabilityByID(mountId, false --[[checkIndoors]])
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hiddenFromChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(self:getId())
    return not hiddenFromChar
end

-- will the real mountId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param mountId number the 2nd arg from GetCursorInfo
---@param mountIndex number the 3rd arg from GetCursorInfo
---@param _ any don't care
function MrMount:consumeGetCursorInfo(type, mountId, mountIndex, _)
    if type ~= self.mrType then return end -- compensate for MrCompanion

    if mountIndex == 0 then
        -- the Bliz API is shite.  This isn't a mount.  It's actually the "summon random favorite mount" button
        -- compensate by defaulting to some other arbitrary actual mount and hope MrSummonRandomFavoriteMount kicks in.
        mountId = 1587
    end

    self:setId(mountId)
    local name, spellId = C_MountJournal.GetMountInfoByID(mountId)
    self.name = name
    self.spellId = spellId -- store for use by getIcon() (and others?)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrMount)
