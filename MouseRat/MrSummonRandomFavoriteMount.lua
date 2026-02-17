--MrSummonRandomFavoriteMount

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrSummonRandomFavoriteMount : MouseRat
local MrSummonRandomFavoriteMount = {
    mrType     = MouseRatType.SUMMON_RANDOM_FAVORITE_MOUNT,
    cursorType = MouseRatType.MOUNT,
    primaryKey = "id",
    apiForIcon = function() return 413588 end,
    apiForPickup = function() C_MountJournal.Pickup(0) end,
}

MouseRat:mixInto(MrSummonRandomFavoriteMount)

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe the SRFM
---@param type MouseRatType must be MouseRatType.MOUNT
---@param maybeMountId any do not care
---@param maybeMountIndex any must be 0
function MrSummonRandomFavoriteMount:disambiguator(type, maybeMountId, maybeMountIndex)
    zebug.warn:print("type", type, "maybeMountId",maybeMountId, "maybeMountIndex",maybeMountIndex)
    if not type == MouseRatType.MOUNT then return false end
    return maybeMountIndex == 0
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

---@return number texture ID
function MrSummonRandomFavoriteMount:getIcon()
    return 413588
end

---@return string
function MrSummonRandomFavoriteMount:getName()
    return _G.MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT -- L10N global defined by Bliz
end

function MrSummonRandomFavoriteMount:isUsable()
    return true
end

function MrSummonRandomFavoriteMount:setToolTip()
    _G.GameTooltip:SetText(self:getName())
end

-- will the real mountId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param mountId number the 2nd arg from GetCursorInfo
---@param mountIndex number the 3rd arg from GetCursorInfo
function MrSummonRandomFavoriteMount:consumeGetCursorInfo(type, mountId, mountIndex)
    assert(mountIndex == 0, "Um... wut?  mountIndex must be 0 for MrSummonRandomFavoriteMount")
    self:setId(self.mrType)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrSummonRandomFavoriteMount)
