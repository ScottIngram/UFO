---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- COMPANION is a MOUNT variant, an abnormal result containing a useless ID
-- which isn't accepted by any API. is returned by PickupSpell(spellIdOfSomeMount)
-- I found a reference in SecureHandlers.lua
-- elseif kind == 'companion' then
-- PickupCompanion(target, detail)
-------------------------------------------------------------------------------

---@class MrCompanion : MouseRat
local MrCompanion = {
    type           = MouseRatType.COMPANION,
    become         = MouseRatType.MOUNT,
    primaryKey     = "id",
    helpers = {
        getName = "MyStErY",
        getIcon = DEFAULT_ICON,
        isUsable = false,
    },
}

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a MrCompanion
---@param type MouseRatType must be MouseRatType.SPELL
---@param maybeItemId any could be an itemId
function MrCompanion:transformAndAbort(type, mysteryId, companionType, c4)
    --zebug.warn:print("type", type, "mysteryId",mysteryId, "companionType",companionType, "c4",c4)

    if MouseRatType.MOUNT ~= self.become then
        error("was expecting the companion to be a mount but got ".. (companionType or "nil"))
    end

    -- none of the APIs know wtf to do with the mysteryId
    -- PickupCompanion("MOUNT", mysteryId)
    -- zebug.warn:print("GetCompanionInfo()", GetCompanionInfo(companionType, mysteryId))
    -- zebug.warn:print("GetDisplayedMountInfo()", C_MountJournal.GetDisplayedMountInfo(mysteryId))

    -- so, cross fingers and become whatever was last picked up
    local cachedMr = self:getRecentCursorCache()
    local cachedMrType = cachedMr and cachedMr.type
    --zebug.warn:owner(grabbedBtn):dumpy("called getMostRecentlyPickedUpMr()", grabbedBtn)
    if cachedMrType == self.become then
        zebug.warn:owner(cachedMr):print("returning getMostRecentlyPickedUpMr()", cachedMr)
        return cachedMr
    else
        zebug.warn:owner(cachedMr):print("contents of cursor cache was unsuitable.  type", cachedMrType)
    end
    return nil
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

function MrCompanion:getId()
    return "NaN"
end

function MrCompanion:setToolTip()
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrCompanion)
