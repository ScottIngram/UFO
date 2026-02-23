---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrMount : MouseRat
local MrMount = {
    type       = MouseRatType.MOUNT,
    primaryKey = "mountId",
    keyForApis = "spellId",
    --getName_helper = C_MountJournal.GetMountInfoByID, -- self.name is populated via consumeGetCursorInfo() below
    getIcon_helper = C_Spell.GetSpellTexture, -- C_MountJournal.GetMountInfoByID(mountID) result[3]
    setToolTip_helper = GameTooltip.SetSpellByID,
    pickupToCursor_helper = C_Spell.PickupSpell,
    --isUsable_helper = C_MountJournal.GetMountUsabilityByID, -- replaced by isUsable() defined below
}

MouseRat:mixInto(MrMount)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

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
    if type ~= self.type then return end -- compensate for MrCompanion

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

-- expresses the MrMount in a way that can be executed in WoW's "secure environment" hellscape / action bar button to mount the mount.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string hardcoded value that will be assigned to the SecureActionButton's attribute indicated (according to Bliz's fucking insane rules) by the above "type" attribute
---@return string text of a dynamically generated macro that will summon the goddamn pet
function MrMount:asSecureClickHandlerAttributes()
    -- yep, spell.
    return ButtonType.SPELL, ButtonType.SPELL, self:getName()
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrMount)
