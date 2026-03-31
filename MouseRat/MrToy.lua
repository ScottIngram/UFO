---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-- all toys are items, but not all items are toys

---@class MrToy : MouseRat
local MrToy = {
    type       = MouseRatType.TOY,
    cursorType = MouseRatType.ITEM, -- _G.GetCursorInfo() reports "item" for toys
    abbType    = MouseRatTypeForActionBarButton.ITEM,
    primaryKey = "itemId",
    helpers = {
        getName = C_Item.GetItemInfo,
        getIcon = C_Item.GetItemIconByID,
        isUsable = _G.PlayerHasToy, -- TODO: solve faction specific bug via isUsable()
        setToolTip = _G.GameTooltip.SetToyByItemID,
        pickupToCursor = C_Item.PickupItem, -- C_ToyBox.PickupToyBoxItem ?
    },
}

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a Toy
---@param type MouseRatType must be MouseRatType.SPELL
---@param maybeItemId any could be an itemId
function MrToy:disambiguator(type, maybeItemId)
    zebug.warn:print("type", type, "maybeItemId",maybeItemId)
    if self.cursorType ~= type then return nil end
    --zebug.warn:print("C_Item.GetItemInfo ->", C_Item.GetItemInfo(maybeItemId)) -- this seems to always provide accurate info. but no indicator of being a toy.
    return PlayerHasToy(maybeItemId)
end

-- examines the results of _G.GetActionInfo() and
-- decides if those results describe a MouseRatType.TOY
---@param abbType MouseRatTypeForActionBarButton must match the configured abbType
---@param id any 2nd return val from _G.GetActionInfo()
---@param subType 3rd return val from _G.GetActionInfo()
function MrToy:disamButtonGator(abbType, id, subType)
    --assert(abbType == self.abbType, "the provided abbType doesn't match the expected value of MouseRatTypeForActionBarButton.ITEM")
    if abbType ~= self.abbType then return false end

    zebug.warn:print("abbType", abbType, "id", id, "subType", subType)
    return PlayerHasToy(id)
end


-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

function MrToy:isUsable_TODO()
    -- TODO: solve faction specific bug
    return PlayerHasToy(self:getId()) -- and C_ToyBox.IsToyUsable(id) -- nope, IsToyUsable is unreliable and overreaching
end

---@return boolean true if the args from GetCursorIdiot match mine
function MrToy:isThisMyCursorData(type, itemId)
    return self:disambiguator(type, itemId) and (self:getId() == itemId)
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
