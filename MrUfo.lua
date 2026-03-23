---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- MrUfo - bridge between FlyoutDef and MouseRat
-------------------------------------------------------------------------------

---@class MrUfo : MrDreadlord
MrUfo = {
    type       = "ufo",
    cursorType = MouseRatType.MACRO,
    parentType = MouseRatType.DREADLORD, -- MouseRatRegistry:register() will create the OO inheritance
    primaryKey = "id",
    passSelfForHelper = { pickupToCursor = true }
}

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrUfo
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a Ufo-Flyout
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param macroId number the 2nd arg from GetCursorInfo
function MrUfo:disambiguator(type, c2, c3, c4)
    -- all MrUfos are actually MrDreadlords
    if not MrDreadlord:isThisMySpawn(type, c2, c3, c4) then return false end

    local mrDl = MrDreadlord:getCurrent()
    if not mrDl then return false end

    local flyoutId
    return true
end

---@return boolean true if the args from GetCursorIdiot match mine
function MrUfo:isThisCursorDataMine(type, macroId)
    return self:disambiguator(type, macroId)
end

local cache = {}
local currentUfo

---@param flyoutId string
function MrUfo:pickupFlyoutId(flyoutId)
    if cache[flyoutId] then return cache[flyoutId] end

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local self = self:new(flyoutConf) -- this will be a dreadlord
    self:pickupToCursor()
    cache[flyoutId] = self
    currentUfo = self
    return self
end

-- TODO? called automatically by MouseRatRegistry:register()
function MrUfo:init()
    self:assertIsInstance()
end

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrUfo
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrUfo)
