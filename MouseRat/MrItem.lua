---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrItem : MouseRat
local MrItem = {
    mrType     = MouseRatType.ITEM,
    primaryKey = "itemId",
    getName_helper = C_Item.GetItemInfo,
    getIcon_helper = C_Item.GetItemIconByID,
    setToolTip_helper = GameTooltip.SetItemByID,
    pickupToCursor_helper = C_Item.PickupItem,
    --isUsable_helper = C_PlayerInfo.CanUseItem, -- replaced by isUsable() defined below
}

MouseRat:mixInto(MrItem)

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

function MrItem:isUsable()
    local n = C_Item.GetItemCount(self:getId())
    return n > 0
end

-- will the real itemId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param itemId number the 2nd arg from GetCursorInfo
function MrItem:consumeGetCursorInfo(type, itemId)
    self:setId(itemId)

    -- TODO: implement MrToy
    --local isToy = PlayerHasToy(itemId) or false -- btnDef:readToolTipForToyType()
    --local itemID, toyName, icon, isFavorite, hasFanfare = C_ToyBox.GetToyInfo(itemId)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrItem)
