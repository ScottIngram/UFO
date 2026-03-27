---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- MrUfo - bridge between FlyoutDef and MouseRat
-------------------------------------------------------------------------------

---@alias MR_UFO_INHERITANCE FlyoutDef | MrDreadlord

---@class MrUfo : MrDreadlord
MrUfo = {
    -- values not defined here will be inherited from MrDreadlord
    type       = "ufo",
    parentType = MouseRatType.DREADLORD, -- MouseRatRegistry:register() will create the OO inheritance
    primaryKey = "id",
    macroVesselName = "Z-UFO",
    passSelfForHelper = { pickupToCursor = true }
}

local cache = {}
local currentUfo -- if there is a currentMouseRat, it needs to automatically be a MrUfo obj when its data matches

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrUfo
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a Ufo-Flyout
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param macroId number the 2nd arg from GetCursorInfo
function MrUfo:disambiguator(type, c2, c3, c4)
    -- all MrUfos are actually MrDreadlords
    if not MrDreadlord.isThisMySpawn(self, type, c2, c3, c4) then return false end

    local mrDl = MrDreadlord.getCurrent(self)
    if not mrDl then return false end

    local flyoutId
    return true
end

---@return boolean true if the args from GetCursorIdiot match mine
function MrUfo:isThisCursorDataMine(type, macroId)
    return self:disambiguator(type, macroId)
end

---@return MrUfo returns nil if it's a MouseRat but not specifically a MrUfo
function MrUfo:getFromCursor()
    local mr = MouseRat:getFromCursor()
            local chk = mr and mr:getFromCursor()
            zebug.info:event():owner(self):print("double checking the cache worked... mr", mr, "chk",chk, "mr==chk", mr == chk)
    return mr and mr:isType(self.type) and mr or nil
end

function MrUfo:isOnCursor()
    return self:getFromCursor() or false
end

function MrUfo:isEqual(other)
    local baseChecksOk = MouseRat:isEqual(other)
    return baseChecksOk and (other.flyoutId == self.flyoutId)
end

-- the inherited versions should correctly differentiate between DLs and UFOs now that each have unique macros
--[[
function MrUfo:_isThisActionBarSlotDataMyClass(...)
    local isMe = MrDreadlord._isThisActionBarSlotDataMyClass(self, ...)
    if not isMe then return false end

    -- further differentiate from a Dreadlord
    -- USE DISTINCT MACROS for Ufo VS Dreadlord
    local cached = MouseRat:getCurrentCursorCache()
    if not currentUfo then return false end
    return isMe
end

function MrUfo:_isThisActionBarSlotDataMyInstance(abbType, id, subType)
    self:assertIsInstance()
    -- TODO further differentiate based on flyoutId somehow?
    -- Won't be an issue until I allow multiple MrUfos for different flyoutIds to exist simultaneously
    return self:_isThisActionBarSlotDataMyClass(...)
end
]]

---@param flyoutId string
---@return MrUfo|FlyoutDef
function MrUfo:pickupFlyoutId(flyoutId)
    assert(flyoutId, "the flyoutId can't be nil.")

    local zelf
    if cache[flyoutId] then
        zelf = cache[flyoutId]
        zebug.info:event():owner(self):print("got from cache",zelf)
    else
        local flyoutConf = FlyoutDefsDb:get(flyoutId)
        zelf = self:new(flyoutConf) -- this will be a dreadlord
        zebug.info:event():owner(self):print("created new()",zelf)
    end

    zelf:pickupToCursor()
    cache[flyoutId] = zelf
    currentUfo = zelf
    return zelf
end

function MrUfo:deleteProxyMacro()
    MrDreadlord.deleteProxyMacro(self) -- the dot syntax lets me pass MY self in to be used as ITS self
    self.flyoutId = nil -- not sure if this is going to work?
end

function MrUfo:getId()
    if self.isInstance then
        return self:getFlyoutId()
    else
        return MrDreadlord.getId(self)
    end
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrUfo
-------------------------------------------------------------------------------

function MrUfo:serialize()
    self:assertIsInstance()
    return self:getId()
end

--MrUfo.serialize = MrUfo.getFlyoutId

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrUfo)
