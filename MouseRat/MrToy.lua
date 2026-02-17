---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-- all toys are items, but not all items are toys

---@class MrToy : MouseRat
local MrToy = {
    mrType     = MouseRatType.TOY,
    cursorType = MouseRatType.ITEM, -- _G.GetCursorInfo() reports "item" for toys
    primaryKey = "itemId",
    apiForName = C_Item.GetItemInfo,
    apiForIcon = C_Item.GetItemIconByID,
    apiForPickup = C_Item.PickupItem, -- C_ToyBox.PickupToyBoxItem ?
    apiForToolTip = GameTooltip.SetToyByItemID,
    apiForUsable = _G.PlayerHasToy, -- TODO: solve faction specific bug via isUsable()
}

MouseRat:mixInto(MrToy)

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a Toy
---@param type MouseRatType must be MouseRatType.SPELL
---@param maybeItemId any could be an itemId
function MrToy:disambiguator(type, maybeItemId)
    --zebug.warn:print("type", type, "maybeItemId",maybeItemId)
    if not type == MouseRatType.SPELL then return false end
    return PlayerHasToy(maybeItemId)
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

function MrToy:isUsable_TODO()
    -- TODO: solve faction specific bug
    return PlayerHasToy(self:getId()) -- and C_ToyBox.IsToyUsable(id) -- nope, IsToyUsable is unreliable and overreaching
end

-- will the real itemId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param itemId number the 2nd arg from GetCursorInfo
function MrToy:consumeGetCursorInfo(type, itemId)
    self:setId(itemId)
    local id, name, icon, isFavorite, hasFanfare = C_ToyBox.GetToyInfo(itemId)
    self.name = name
    self:setPvar("icon",icon)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrToy)
