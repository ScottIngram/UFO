-- FlyoutDef
-- a flyout menu definition
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@class FlyoutDef : UfoMixIn
---@field id string A unique, immutable, permanent identifier.  This is not it's index in any array.
---@field name string
---@field icon string user chosen icon
---@field fallbackIcon string in absence of the icon field, this is used when the Bliz UI fails to load all the necessary icons on login (usually pets and toys)
---@field btns table
---@field lastMod number timestamp of the last significant modification
FlyoutDef = {
    ufoType = "FlyoutDef",
}
UfoMixIn:mixInto(FlyoutDef)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a FlyoutDef instance
---@return FlyoutDef
---@param self FlyoutDef
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
    function privateCache:setAlreadyCoercedMyButtons() privateCache.alreadyCoercedMyButtons = true end
    function privateCache:cacheUsableFlyoutDef(usableFlyoutDef) privateCache.cachedUsableFlyoutDef = usableFlyoutDef end
    function privateCache:cacheHasItem(hasIt) privateCache._hasItem = hasIt end
    function privateCache:cacheHasMacro(hasIt) privateCache._hasMacro = hasIt end
    function privateCache:cacheHasSpell(hasIt) privateCache._hasSpell = hasIt end

    -- tie the privateData table to the FlyoutDef class definition
    setmetatable(privateCache, { __index = FlyoutDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateCache })

    self:installMyToString()

    -- on any modification always update the lastMod
    -- well, this causes the initial load to silently fail and UFO does nothing until a reload
    -- maybe because no defs get loaded SAVED_VARIABLES ?

    self:setModStamp()

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

function FlyoutDef:toString()
    if self == Cursor then
        return "nil"
    else
        local icon = self:getIcon() or self.fallbackIcon or DEFAULT_ICON
        return string.format("<FlyDef: |T%d:0|t %s size=%d>", icon, nilStr(self.name), nilStr(self.btns and #(self.btns) or 0))
    end
end

---@return string
function FlyoutDef:getName()
    return self.name
end

function FlyoutDef:setModStamp()
    self.lastMod = time()
end

function FlyoutDef:getModStamp()
    return self.lastMod
end

-- UNUSED :-(
---@param time number a time ( as returned by a call to the time() function )
---@return boolean true if self has been modified more recently than the given time
function FlyoutDef:isModNewerThan(time)
    return (time or 0) >= self:getModStamp()
end

function FlyoutDef:invalidateCache()
    self:setModStamp()
    self:cacheUsableFlyoutDef(nil)
    self:cacheHasItem(nil)
    self:cacheHasMacro(nil)
    self:cacheHasSpell(nil)
end

function FlyoutDef:invalidateCacheOfUsableFlyoutDefOnly()
    self:cacheUsableFlyoutDef(nil)
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
    zebug.trace:owner(self):print("i", i, "self.btns",self.btns)
    assert(self.btns, "This instance of FlyoutDef has no 'btns' field.")

    self:ensureCoerced()
    local invalidateCaches = false
    ---@param buttonDef ButtonDef
    for j, buttonDef in ipairs(self.btns) do -- this must remain self.btns and NOT self:getAllButtonDefs() - otherwise infinite loop
        zebug.trace:owner(self):print("i", i, "btn #", j, "buttonDef.name", buttonDef.name)
        local killCache = callback(buttonDef, buttonDef, j, self) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
        if killCache then
            zebug.trace:owner(self):print(i, "btn #", j, "buttonDef.name", buttonDef.name, "sent signal to INVALIDATE Caches")
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
    zebug.trace:owner(self):print("self.alreadyCoercedMyButtons",self.alreadyCoercedMyButtons)
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

---@param i number
---@param buttonDef ButtonDef
function FlyoutDef:insertButton(index, buttonDef)
    index = tonumber(index)
    local n = index
    local existingBtnDef = buttonDef
    for i = index, #self.btns do
        existingBtnDef = self.btns[i]
        self.btns[i] = buttonDef
        buttonDef = existingBtnDef
        n = i+1
    end

    --if n <= MAX_FLYOUT_SIZE then
    -- eh, let the btns's exist virtually even if there aren't enough UI btns to display them all
        self.btns[n] = existingBtnDef
    --end

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
    self:invalidateCache()
end

function FlyoutDef:getIcon()
    if self.icon then return self.icon end
    local btn1 = self:getButtonDef(1)
    if btn1 then
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
    if self.cachedUsableFlyoutDef then
        zebug.trace:owner(self):print("returning cached usableFlyoutDef")
        return self.cachedUsableFlyoutDef
    end

    zebug.trace:owner(self):print("filtering...")

    local usableFlyoutDef = FlyoutDef:new()
    ---@param btn ButtonDef
    for i, btn in ipairs(self:getAllButtonDefs()) do
        if btn:isUsable() then
            zebug.trace:owner(self):print("can use", btn:getName())
            usableFlyoutDef:addButton(btn)
        else
            zebug.info:owner(self):print("CANNOT use", btn:getName())
        end
    end
    usableFlyoutDef.name = self.name
    usableFlyoutDef.icon = self.icon
    usableFlyoutDef.fallbackIcon = self.fallbackIcon
    usableFlyoutDef.setAlreadyCoercedMyButtons() -- because the source btns have already been coerced
    self:cacheUsableFlyoutDef(usableFlyoutDef)
    return usableFlyoutDef
end

function FlyoutDef:hasItem(event)
    return self:hasFoo("_hasItem", self.cacheHasItem, ButtonType.ITEM, event)
end

function FlyoutDef:hasMacro(event)
    return self:hasFoo("_hasMacro", self.cacheHasMacro, ButtonType.MACRO, event)
end

function FlyoutDef:hasSpell(event)
    return self:hasFoo("_hasSpell", self.cacheHasSpell, ButtonType.SPELL, event)
end

function FlyoutDef:hasFoo(key, cacher, type, event)
    zebug.trace:mark(Mark.FIRE):event(event):owner(self):print("key",key, "exists", self[key], "type",  type)

    if self[key] == nil then
        cacher(self, false)
        zebug.info:mark(Mark.INFO):event(event):owner(self):print("indexing for", key)
        ---@param btnDef ButtonDef
        self:forEachBtn(function(btnDef)
            if btnDef.type == type then
                cacher(self, true)
                zebug.info:event(event):owner(self):print(key, self[key], "btn",  btnDef.name)
            else
                zebug.trace:event(event):owner(self):print("the",btnDef.name, "is not a",key )
            end
        end)
    else
        zebug.trace:event(event):owner(self):print("using cached",key, "with a val of", self[key])
    end

    return self[key]
end
