--MrSummonRandomFavoriteMount

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrSummonRandomFavoriteMount : MouseRat
local MrSummonRandomFavoriteMount = {
    type       = MouseRatType.SUMMON_RANDOM_FAVORITE_MOUNT,
    cursorType = MouseRatType.MOUNT,
    abbType = MouseRatTypeForActionBarButton.MOUNT,
    primaryKey = "id",
    helpers = {
        getName = _G.MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT,
        getIcon = 413588,
        isUsable = true,
        pickupToCursor = function() C_MountJournal.Pickup(0) end,
    },
}

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe the SRFM
---@param type MouseRatType must be MouseRatType.MOUNT
---@param maybeMountId any do not care
---@param maybeMountIndex any must be 0
function MrSummonRandomFavoriteMount:disambiguator(type, maybeMountId, maybeMountIndex)
    zebug.info:print("type", type, "maybeMountId",maybeMountId, "maybeMountIndex",maybeMountIndex)
    if type ~= MouseRatType.MOUNT then return false end
    return maybeMountIndex == 0
end

-- == ActionBars methods

-- examines the results of _G.GetActionInfo() and
-- decides if those results describe a MouseRatTypeForActionBarButton.SUMMON_RANDOM_FAVORITE_MOUNT
---@param btnType MouseRatTypeForActionBarButton must be MouseRatTypeForActionBarButton.MOUNT
---@param id any 2nd return val from _G.GetActionInfo()
---@param subType 3rd return val from _G.GetActionInfo()
function MrSummonRandomFavoriteMount:disamButtonGator(btnType, id, subType)
    if btnType ~= self.abbType then return false end

    zebug.warn:print("btnType", btnType, "id", id, "subType", subType)
    return (subType == "pet")
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

function MrSummonRandomFavoriteMount:setToolTip()
    _G.GameTooltip:SetText(self:getName())
end

-- will the real mountId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param mountId number the 2nd arg from GetCursorInfo
---@param mountIndex number the 3rd arg from GetCursorInfo
function MrSummonRandomFavoriteMount:consumeGetCursorInfo(type, mountId, mountIndex)
    assert(mountIndex == 0, "Um... wut?  mountIndex must be 0 for MrSummonRandomFavoriteMount")
    self:setId(self.type)
end

-- expresses the MrSummonRandomFavoriteMount in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute (according to Bliz's fucking insane rules) related to the above "type" attribute
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrSummonRandomFavoriteMount:asSecureClickHandlerAttributes()
    return ButtonType.MACRO, "macrotext", "/run C_AddOns.LoadAddOn('Blizzard_Collections'); C_MountJournal.SummonByID(0)"
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrSummonRandomFavoriteMount)
