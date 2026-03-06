---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrItem : MouseRat
local MrItem = {
    type       = MouseRatType.ITEM,
    primaryKey = "itemId",
    helpers = {
        getName = C_Item.GetItemInfo,
        getIcon = C_Item.GetItemIconByID,
        setToolTip = _G.GameTooltip.SetItemByID,
        pickupToCursor = C_Item.PickupItem,
        --isUsable = C_PlayerInfo.CanUseItem, -- overreaching. replaced by isUsable() defined below
    },
}

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

function MrItem:isUsable()
    local n = C_Item.GetItemCount(self:getId())
    return n > 0
end

-- expresses the MrItem in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute (according to Bliz's fucking insane rules) related to the above "type" attribute
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrItem:asSecureClickHandlerAttributes()
    -- because using items by name implies rank 1 and never rank 2 or 3 we must use by the item's ID
    return ButtonType.ITEM, ButtonType.ITEM, "item:".. self.itemId -- but not just itemId, it must be item:itemId - I hate you Bliz
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrItem)
