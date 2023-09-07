-- FlyoutDef
-- a flyout menu definition
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class FlyoutDef -- IntelliJ-EmmyLua annotation
---@field id string A unique, immutable, permanent identifier.  This is not it's index in any array.
---@field name string
---@field icon string user chosen icon
---@field fallbackIcon string in absence of the icon field, this is used when the Bliz UI fails to load all the necessary icons on login (usually pets and toys)
---@field btns table
local FlyoutDef = {
    ufoType = "FlyoutDef",
}
Ufo.FlyoutDef = FlyoutDef

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a FlyoutDef instance
---@return FlyoutDef
function FlyoutDef:oneOfUs(self)
    zebug.trace:setMethodName("oneOfUs"):print("self",self)
    if self.ufoType == FlyoutDef.ufoType then
        return self
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateCache = {
        alreadyCoercedMyButtons = false,
    }
    function privateCache:_cacheUsableFlyoutDef(usableFlyoutDef) privateCache.cachedUsableFlyoutDef = usableFlyoutDef end
    function privateCache:setAlreadyCoercedMyButtons() privateCache.alreadyCoercedMyButtons = true end

    -- tie the privateData table to the FlyoutDef class definition
    setmetatable(privateCache, { __index = FlyoutDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateCache })
    return self
end

local flyoutIndex = 1

---@return FlyoutDef
function FlyoutDef:new()
    local self = { btns = {} } -- I tried putting self.btns = {} into oneOfUs() but then they failed to persist out to SAVED_VARIABLES :-/
    self.name = flyoutIndex
    flyoutIndex = flyoutIndex + 1
    return FlyoutDef:oneOfUs(self)
end

function FlyoutDef:invalidateCache()
    self:_cacheUsableFlyoutDef(nil) -- always clear the filtered copy when the base changes
end

function FlyoutDef:newId()
    return DB:nextN() ..":".. getIdForCurrentToon() ..":".. (time()-1687736964)
end

function FlyoutDef:howManyButtons()
    return #self.btns
end

---@param callback function if the function returns true, then, that means it did something that requires the caches to be nuked
function FlyoutDef:forEachBtn(callback)
    local i = Xedni:getFlyoutDef(self.id)
    zebug.trace:out(20, "-", "i", i, "id",self.id, "self.btns",self.btns)
    assert(self.btns, "This instance of FlyoutDef has no 'btns' field.")

    self:ensureCoerced()
    local invalidateCaches = false
    ---@param buttonDef ButtonDef
    for j, buttonDef in ipairs(self.btns) do -- this must remain self.btns and NOT self:getAllButtonDefs() - otherwise infinite loop
        zebug.trace:out(15,"-", "i", i, "btn #", j, "buttonDef.name", buttonDef.name)
        local killCache = callback(buttonDef, buttonDef, j, self) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
        if killCache then
            zebug.trace:out(10,"-", "i", i, "btn #", j, "buttonDef.name", buttonDef.name, "sent signal to INVALIDATE Caches")
            buttonDef:invalidateCache()
            invalidateCaches = true
        end
    end
    if invalidateCaches then
        self:invalidateCache()
    end
end

---@param killTester function
function FlyoutDef:batchDeleteBtns(killTester)
    local btns = self:getAllButtonDefs()
    local modified = deleteFromArray(btns, killTester)
    if modified then
        self:invalidateCache()
    end
end

function FlyoutDef:getAllButtonDefs()
    zebug.trace:print("self.alreadyCoercedMyButtons",self.alreadyCoercedMyButtons)
    self:ensureCoerced()
    return self.btns
end

function FlyoutDef:ensureCoerced()
    if not self.alreadyCoercedMyButtons then
        for i, buttonDef in ipairs(self.btns) do
            ButtonDef:oneOfUs(buttonDef)
        end
        self:setAlreadyCoercedMyButtons()
    end
end

---@return ButtonDef
function FlyoutDef:getButtonDef(i)
    return self:getAllButtonDefs()[tonumber(i)]
end

---@param buttonDef ButtonDef
function FlyoutDef:addButton(buttonDef)
    table.insert(self.btns, buttonDef)
    self:invalidateCache()
end

---@param i number
---@param buttonDef ButtonDef
function FlyoutDef:replaceButton(i, buttonDef)
    self.btns[tonumber(i)] = buttonDef
    self:invalidateCache()
end

-- removes a button an moves the rest down a notch
function FlyoutDef:removeButton(removeAtIndex)
    local howManyButtons = self:howManyButtons()
    self:forEachBtn(function(buttonDef, buttonDef, i)
        if i >= removeAtIndex and i <= howManyButtons then
            local nextBtnDef = self:getButtonDef(i + 1) -- lua is OK with index out of range
            self:replaceButton(i, nextBtnDef)
        end
    end)
end

function FlyoutDef:getIcon()
    if self.icon then return self.icon end
    local btn1 = self:getButtonDef(1)
    if btn1 then
        local isMe = isClass(self, FlyoutDef)
        zebug.trace:print("btn1",btn1, "isMe",isMe, "btn1.ufoType",btn1.ufoType, "btn1.getIcon",btn1.getIcon)
        local icon = btn1:getIcon()
        if icon then
            -- compensate for the Bliz UI bug where not all icons have been loaded at the moment of login
            self.fallbackIcon = icon
        end
        return icon
    end
    return nil
end

---@return FlyoutDef
function FlyoutDef:filterOutUnusable()
    zebug:print("self.name", self.name)

    if self.cachedUsableFlyoutDef then
        zebug.trace:print("returning cached usableFlyoutDef")
        return self.cachedUsableFlyoutDef
    end

    local usableFlyoutDef = FlyoutDef:new()
    ---@param btn ButtonDef
    for i, btn in ipairs(self:getAllButtonDefs()) do
        if btn:isUsable() then
            zebug.trace:print("can use", btn:getName())
            usableFlyoutDef:addButton(btn)
        else
            zebug:print("CANNOT use", btn:getName())
        end
    end
    usableFlyoutDef.name = self.name
    usableFlyoutDef.icon = self.icon
    usableFlyoutDef.fallbackIcon = self.fallbackIcon
    usableFlyoutDef.setAlreadyCoercedMyButtons() -- because the source btns have already been coerced
    self:_cacheUsableFlyoutDef(usableFlyoutDef)
    return usableFlyoutDef
end

function table.inserty(t, val)
    table.insert(t, val or EMPTY_ELEMENT)
end
