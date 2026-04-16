---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrOutfit : MouseRat
local MrOutfit = {
    type       = MouseRatType.OUTFIT,
    primaryKey = "outfitIndex",
    helpers = {
        pickupToCursor = C_TransmogOutfitInfo.PickupOutfit,
    },
}

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

function MrOutfit:doInit()
    local id = self:getId()
    assert(id, "no ID has been consumed yet")
    self:consumeGetCursorInfo(self.type, id)
    return true
end

function MrOutfit:isUsable()
    if true then return true end
    local n = C_Item.GetItemCount(self:getId())
    return n > 0
end

function MrOutfit:getName()
    return self.name or (self:doInit() and self.name)
end

function MrOutfit:getIcon()
    return self.icon or (self:doInit() and self.icon)
end

-- will the real itemId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param outfitIndex number the 2nd arg from GetCursorInfo
function MrOutfit:consumeGetCursorInfo(type, outfitIndex)
    self:setId(outfitIndex)
    local o = C_TransmogOutfitInfo.GetOutfitInfo(outfitIndex)
    self.name = o.name
    self.owner = getIdForCurrentToon()
    self:setPvar("icon",o.icon)
end

function MrOutfit:setToolTip()
    local name = self:getName()
    local text = "Outfit ".. (self:getId()) .." " .. (name or "UnKnOwN")
    if not self:isUsable() then
        text = "Toon " .. text .. " for " .. self.owner
    end
    return _G.GameTooltip:SetText(text)
end

-- expresses the MrOutfit in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute (according to Bliz's fucking insane rules) related to the above "type" attribute
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrOutfit:asSecureClickHandlerAttributes()
    -- because using items by name implies rank 1 and never rank 2 or 3 we must use by the item's ID
    return ButtonType.ITEM, ButtonType.ITEM, "item:".. self.itemId -- but not just itemId, it must be item:itemId - I hate you Bliz
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrOutfit)
