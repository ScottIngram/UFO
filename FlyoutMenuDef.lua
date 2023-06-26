-- FlyoutMenuDef
-- a flyout menu definition
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.OUTPUT.ALL)

---@class FlyoutMenuDef -- IntelliJ-EmmyLua annotation
---@field id string A unique, immutable, permanent identifier.  This is not it's index in any array.
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
    zebug.trace:setMethodName("oneOfUs"):print("self",self)
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
    zebug.trace:print("self.name",self.name, "lists",lists)
    self:_setCachedLists(lists)
end

function FlyoutMenuDef:newId()
    return Config:nextN() ..":".. getIdForCurrentToon() ..":".. (time()-1687736964)
end

function FlyoutMenuDef:howManyButtons()
    return #self.btns
end

function FlyoutMenuDef:forEachBtn(callback)
    zebug.trace:out(20, "-", "self.btns",self.btns)
    assert(self.btns, "This instance of FlyoutMenuDef has no 'btns' field to coerce.")

    for i, buttonDef in ipairs(self.btns) do -- this must remain self.btns and NOT self:getAllButtonDefs() - otherwise infinite loop
        zebug.trace:out(15,"-", "i",i, "buttonDef", buttonDef)
        callback(buttonDef, buttonDef, i) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
    end
end

function FlyoutMenuDef:getAllButtonDefs()
    zebug.trace:print("self.alreadyCoercedMyButtons",self.alreadyCoercedMyButtons)
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

-- removes a button an moves the rest down a notch
function FlyoutMenuDef:removeButton(removeAtIndex)
    local howManyButtons = self:howManyButtons()
    self:forEachBtn(function(buttonDef, buttonDef, i)
        if i >= removeAtIndex and i <= howManyButtons then
            local nextBtnDef = self:getButtonDef(i + 1) -- lua is OK with index out of range
            self:replaceButton(i, nextBtnDef)
        end
    end)
end

function FlyoutMenuDef:getIcon()
    if self.icon then return self.icon end
    local btn1 = self:getButtonDef(1)
    if btn1 then
        local isMe = isClass(self, FlyoutMenuDef)
        zebug.trace:print("btn1",btn1, "isMe",isMe, "btn1.ufoType",btn1.ufoType, "btn1.getIcon",btn1.getIcon)
        return btn1:getIcon()
    end
    return nil
end

---@return FlyoutMenuDef
function FlyoutMenuDef:filterOutUnusable()
    zebug:print("self.name", self.name)

    local usableFlyoutMenuDef = FlyoutMenuDef:new()
    ---@param btn ButtonDef
    for i, btn in ipairs(self:getAllButtonDefs()) do
        if btn:isUsable() then
            zebug.trace:print("can use", btn:getName())
            usableFlyoutMenuDef:addButton(btn)
        else
            zebug:print("CANNOT use", btn:getName())
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
    zebug.trace:print("cache",cache, "isSame",isSame, "self:howManyButtons()",self:howManyButtons())
    zebug.trace:dumpy("cache",cache)
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
    for i, btn in ipairs(self:getAllButtonDefs()) do
        lists.blizTypes[i] = btn:getTypeForBlizApi()
        lists.types    [i] = btn.type
        lists.names    [i] = btn.name
        lists.spellIds [i] = btn.spellId
        lists.petGuids [i] = btn.petGuid
        lists.macroIds [i] = btn.macroId
    end
    zebug.trace:dumpy("lists",lists)
    self:setCachedLists(lists)
    return lists
end
