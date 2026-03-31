---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- MrUfo - bridge between FlyoutDef and MouseRat
-------------------------------------------------------------------------------

---@alias MR_UFO_INHERITANCE FlyoutDef | MrDreadlord
---@alias MR_UFO_TYPE MrUfo | MR_UFO_INHERITANCE

---@class MrUfo : MrDreadlord -- also a FlyoutDef
MrUfo = {
    -- values not defined here will be inherited from MrDreadlord
    type       = "ufo",
    parentType = MouseRatType.DREADLORD, -- MouseRatRegistry:register() will create the OO inheritance
    primaryKey = "macroId",
    macroVesselName = "Z-UFO",
    passSelfForHelper = {
        pickupToCursor = true,
        getName=true,
    },
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
    zebug.warn:mCircle():name("disambiguator"):event():owner(self):print("primaryKey",self.primaryKey, "getId", self:getId() ) -- getId here is a static/class method
    return MrDreadlord.isThisMySpawn(self, type, c2, c3, c4)
end

---@return boolean true if the args from GetCursorIdiot match mine
function MrUfo:isThisMyCursorData(type, macroId)
    return self:disambiguator(type, macroId)
end

---@return MrUfo returns nil if it's a MouseRat but not specifically a MrUfo
function MrUfo:getFromCursor()
    local mr = MouseRat:getFromCursor()
    zebug.info:mCross():event():owner(self):print("got once", mr)
    if mr then
        local chk = mr and MouseRat:getFromCursor()
        zebug.info:mCross():event():owner(self):print("double checking the cache worked... got twice...  mr", mr, "chk",chk, "mr==chk", mr == chk)
    end
    return mr and mr:isType(self.type) and mr or nil
end

function MrUfo:isOnCursor()
    zebug.info:event():owner(self):print("am I on the cursor?")
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

function MrUfo:deleteMacroVessel()
    MrDreadlord.deleteMacroVessel(self) -- the dot syntax lets me pass MY self in to be used as ITS self
    self.flyoutId = nil -- not sure if this is going to work?
end

-- TODO: bug? what if the macro is gone?
function MrUfo:getSeedData()
    local flyoutId = self:getMacroText()
    zebug.info:event():print("flyoutId",flyoutId)
    assert(flyoutId, "the UFO macro is empty")
    return FlyoutDefsDb:get(flyoutId)
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrUfo
-------------------------------------------------------------------------------

function MrUfo:serialize(x)
    self:assertIsInstance()
    return self:getFlyoutId() -- inherited from FlyoutDef
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrUfo)
