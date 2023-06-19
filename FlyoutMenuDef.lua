-- FlyoutMenuDef
-- a flyout menu definition
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- TODO: invert the FlyoutMenu data structure
-- TODO: * implement as array of self-contained button objects rather than each button spread across multiple parallel arrays
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

---@class FlyoutMenuDef -- IntelliJ-EmmyLua annotation
---@field name string
---@field icon string
---@field btns table
local FlyoutMenuDef = {
    ufoType = "FlyoutMenuDef",
}
Ufo.FlyoutMenuDef = FlyoutMenuDef

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a FlyoutMenuDef instance
---@return FlyoutMenuDef
function FlyoutMenuDef:oneOfUs(self)
    debug.trace:out("+",3,"FlyoutMenuDef:oneOfUs()", "self",self)
    if self.ufoType == FlyoutMenuDef.ufoType then
        return self
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateData = {
        alreadyCoercedMyButtons = false,
    }
    function privateData:_setCachedLists(lists) privateData.cachedLists = lists end
    function privateData:setAlreadyCoercedMyButtons() privateData.alreadyCoercedMyButtons = true end

    -- tie the privateData table to the FlyoutMenuDef class definition
    setmetatable(privateData, { __index = FlyoutMenuDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateData })
    return self
end

local flyoutIndex = 1

---@return FlyoutMenuDef
function FlyoutMenuDef:new()
    local self = { btns = {} } -- I tried putting self.btns = {} into oneOfUs() but then they failed to persist out to SAVED_VARIABLES :-/
    self.name = flyoutIndex
    flyoutIndex = flyoutIndex + 1
    return FlyoutMenuDef:oneOfUs(self)
end

-- because privateData:_setCachedLists() is not visible to my IDE's autocomplete
-- defining this redundant declaration here
function FlyoutMenuDef:setCachedLists(lists)
    debug.info:out("~",3, "FlyoutMenuDef.cacheLists()", "self.name",self.name, "lists",lists)
    self:_setCachedLists(lists)
end

function FlyoutMenuDef:howManyButtons()
    return #self.btns
end

function FlyoutMenuDef:forEachBtn(callback)
    assert(self.btns, "This instance of FlyoutMenuDef has no 'btns' field to coerce.")

    for i, buttonDef in ipairs(self.btns) do
        debug.info:out(".",3,"FlyoutMenusDb:forEachBtn()", "i",i, "buttonDef", buttonDef)
        callback(buttonDef, buttonDef) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
    end
end

function FlyoutMenuDef:getAllButtonDefs()
    debug.info:out("C",3,"FlyoutMenuDef:getAllButtonDefs()...")
    if not self.alreadyCoercedMyButtons then
        self:forEachBtn(ButtonDef.oneOfUs)
        self:setAlreadyCoercedMyButtons()
    end
    return self.btns
end

---@return ButtonDef
function FlyoutMenuDef:getButtonDef(i)
    return self:getAllButtonDefs()[tonumber(i)]
end

---@param buttonDef ButtonDef
function FlyoutMenuDef:addButton(buttonDef)
    table.insert(self.btns, buttonDef)
    self:setCachedLists(nil)
end

---@param i number
---@param buttonDef ButtonDef
function FlyoutMenuDef:replaceButton(i, buttonDef)
    self.btns[tonumber(i)] = buttonDef
    self:setCachedLists(nil)
end

function FlyoutMenuDef:removeButton(i)
    self.btns[tonumber(i)] = nil
end

function FlyoutMenuDef:getIcon()
    if self.icon then return self.icon end
    ---@type ButtonDef
    local btn1 = self:getButtonDef(1)
    if btn1 then
        local isMe = isClass(self, FlyoutMenuDef)
        debug.trace:out("#",5,"FlyoutMenuDef:getIcon()","btn1",btn1, "isMe",isMe, "btn1.ufoType",btn1.ufoType, "btn1.getIcon",btn1.getIcon)
        return btn1:getIcon()
    end
    return nil
end

---@return FlyoutMenuDef
function FlyoutMenuDef:filterOutUnusable()
    ---@type FlyoutMenuDef
    local usableFlyoutMenuDef = FlyoutMenuDef:new()
    ---@param btn ButtonDef
    for i, btn in ipairs(self.btns) do
        if btn:isUsable() then
            usableFlyoutMenuDef:addButton(btn)
        end
    end
    return usableFlyoutMenuDef
end

function table.inserty(t, val)
    table.insert(t, val or EMPTY_ELEMENT)
end

---@return table
function FlyoutMenuDef:asLists()
    local cache = self.cachedLists
    local isSame = cache == self
    debug.info:out("~",3, "FlyoutMenuDef:asLists()", "cache 0",cache, "isSame",isSame, "self:howManyButtons()",self:howManyButtons())
    debug.info:dump(cache)
    if cache then return cache end
    local lists = {
        blizTypes = {},
        types = {},
        names = {},
        spellIds = {},
        petGuids = {},
        macroIds = {},
    }
    ---@param btn ButtonDef
    for i, btn in ipairs(self.btns) do
        local blizApiFieldDef = btn:getBlizApiFieldDef()
        local typeForApi = blizApiFieldDef.typeForBliz

        lists.blizTypes[i] = typeForApi
        lists.types    [i] = btn.type
        lists.names    [i] = btn.name
        lists.spellIds [i] = btn.spellId
        lists.petGuids [i] = btn.petGuid
        lists.macroIds [i] = btn.macroId
    end
    debug.info:out("~",3, "FlyoutMenuDef:asLists()", "cache 1",lists)
    debug.info:dump(lists)
    self:setCachedLists(lists)
    return lists
end
