---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrOutfit : MouseRat
local MrOutfit = {
    type       = MouseRatType.OUTFIT,
    primaryKey = "outfitId",
    helpers = {
        pickupToCursor = C_TransmogOutfitInfo.PickupOutfit,
    },
}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- Because the /outfit macro only uses transmogINDEX
-- and NONE of the APIs will tell you the transmogINDEX
-- I get to iterate through ALL of the outfits and FUCKING COUNT THEM.
-- TODO: cache this and clear if some event exists to tell me the use changes the outfit list
function getIndexForId_AndFuckYouBliz(outfitId)
    local outfits = C_TransmogOutfitInfo.GetOutfitsInfo()
    for i, outfitData in ipairs(outfits) do
        if outfitData.outfitID == outfitId then
            zebug.info:print("matched outfitId", outfitId, "to index",i)
            zebug.info:dumpy("outfitData", outfitData)
            return i
        end
    end
    return nil
end

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
---@param outfitId number the 2nd arg from GetCursorInfo
function MrOutfit:consumeGetCursorInfo(type, outfitId)
    self:setId(outfitId)
    local o = C_TransmogOutfitInfo.GetOutfitInfo(outfitId)
    self.name = o.name
    self.owner = getIdForCurrentToon()
    self:setPvar("icon",o.icon)

    local i = getIndexForId_AndFuckYouBliz(self.outfitId)
    self:setPvar("outfitIndex",i)
    if not self.outfitIndex then
        error("The Bliz APIs failed to provide UFO with the index for outfit with ID:".. self.outfitId .. " name:" .. self.name)
    end
    self:setPvar("isInit",true)
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
    if not self.isInit then
        self:doInit()
    end

    return ButtonType.MACRO, "macrotext", sprintf("/outfit %d", self.outfitIndex)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrOutfit)
