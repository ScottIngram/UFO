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
    local privateData = {
        alreadyCoercedMyButtons = false,
    }
    function privateData:_setUsableFlyoutDef(usableFlyoutDef) privateData.usableFlyoutDef = usableFlyoutDef end
    function privateData:_setCachedStrLists(strLists) privateData.cachedStrLists = strLists end
    function privateData:_setCachedLists(lists) privateData.cachedLists = lists end
    function privateData:setAlreadyCoercedMyButtons() privateData.alreadyCoercedMyButtons = true end

    -- tie the privateData table to the FlyoutDef class definition
    setmetatable(privateData, { __index = FlyoutDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateData })
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

-- because privateData:_setCachedLists() is not visible to my IDE's autocomplete
-- defining this redundant declaration here
function FlyoutDef:setCachedLists(lists)
    zebug.trace:print("self.name",self.name, "lists",lists)
    self:_setCachedLists(lists)
    self:_setCachedStrLists(nil) -- always clear the stringy copy when the base changes
    self:_setUsableFlyoutDef(nil) -- always clear the filtered copy when the base changes
end

function FlyoutDef:newId()
    return Config:nextN() ..":".. getIdForCurrentToon() ..":".. (time()-1687736964)
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
        self:setCachedLists(nil)
    end
end

---@param killTester function
function FlyoutDef:batchDeleteBtns(killTester)
    local btns = self:getAllButtonDefs()
    local modified = deleteFromArray(btns, killTester)
    if modified then
        self:setCachedLists(nil)
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
    self:setCachedLists(nil)
end

---@param i number
---@param buttonDef ButtonDef
function FlyoutDef:replaceButton(i, buttonDef)
    self.btns[tonumber(i)] = buttonDef
    self:setCachedLists(nil)
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

    if self.usableFlyoutDef then
        zebug.trace:print("returning chached usableFlyoutDef")
        return self.usableFlyoutDef
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
    self:_setUsableFlyoutDef(usableFlyoutDef)
    return usableFlyoutDef
end

function table.inserty(t, val)
    table.insert(t, val or EMPTY_ELEMENT)
end

---@return table
function FlyoutDef:asLists()
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

function FlyoutDef:asStrLists()
    local cache = self.cachedStrLists
    if cache then return cache end

    local asLists = self:asLists()

    local asStrLists = {
        spellIds  = fknJoin(asLists.spellIds),
        names     = fknJoin(asLists.names),
        blizTypes = fknJoin(asLists.blizTypes),
        petGuids  = fknJoin(asLists.petGuids),
    }

    zebug.trace:print("UFO_NAMES",      asStrLists.names)
    zebug.trace:print("UFO_BLIZ_TYPES", asStrLists.blizTypes)
    zebug.trace:print("UFO_PETS",       asStrLists.petGuids)

    self.cachedStrLists = asStrLists
    return asStrLists
end
