-- Cursor Helper

-- TODO - subscribe to CURSOR_CHANGED which erases a cached cursor.  the Cursor:get() caches itself for reuse

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.ERROR)

---@class Cursor : UfoMixIn
---@field type string
---@field id any
---@field index number
---@field itemLink string
---@field bookType any
---@field overriddenSpellId number
---@field amount number
---@field whenWasCached number
---@field ufoType string The classname
Cursor = {
    ufoType = "Cursor"
}
UfoMixIn:mixInto(Cursor)

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local cachedCursor

-------------------------------------------------------------------------------
-- Listeners
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:CURSOR_CHANGED(isDefault, me, eventCounter)
    eventCounter = eventCounter or "NO-EVENT-COUNTER"
    --if not Ufo.hasShitCalmedTheFuckDown then return end

    local event = Event:new(self, me, eventCounter)
    zebug.trace:name(me):runEvent(event, function()
        zebug.info:event(event):name(me):print("erasing cachedCursor")
        cachedCursor = nil
    end)
end

BlizGlobalEventsListener:register(Cursor, EventHandlers)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@return Cursor
function Cursor:get()
    self = self:asInstance(true)
    local type, a, b, c, d = GetCursorInfo()
    if type == ButtonType.ITEM then
        self.id = a
        self.itemLink = b
    elseif type == ButtonType.SPELL then
        self.id = c
		self.index = a
		self.bookType = b
		self.overriddenSpellId = d
    elseif type == ButtonType.PSPELL then
        self.id = a
		self.index = b
    elseif type == ButtonType.MACRO then
        self.id = a
    elseif type == "money" then
        self.amount = a
    elseif type == ButtonType.MOUNT then
        self.id = a
		self.index = b
    elseif type == "merchant" then
        self.id = a
    elseif type == ButtonType.PET then
        self.id = a
    end

    self.type = type

    if type then
        -- this is kind of expensive... maybe reconsider
        local b = ButtonDef:getFromCursor()
        self.name = b and b:getName()
    end

    cachedCursor = self
    self.whenWasCached = time()
    return self
end

local maxAge = 2 -- seconds
-- bypass the cache - should only need to be used by other subscribers of CURSOR_CHANGED due to race condition
function Cursor:getFresh(event)
    if cachedCursor then
        local age = time() - cachedCursor.whenWasCached
        zebug.trace:event(event):print("age", age)
        if age > maxAge then
            zebug.trace:print("clearing cache because it's too old!")
            cachedCursor = nil
        else
            zebug.trace:event(event):print("not clearing cache. cache is young!")
        end
    else
        zebug.trace:event(event):print("no cache to clear")
    end

    return self:get()
end

function Cursor:asInstance(skipPop)
    if self ~= Cursor then
        return self
    end

    if cachedCursor then
        return cachedCursor
    end

    self = deepcopy(self, {})
    self:installMyToString()
    if not skipPop then
        self = self:get()
    end

    return self
end

function Cursor:populateIfInstance()
    if self.ufoType == "Cursor" and self ~= Cursor then
        self:get()
    end
    return self -- support cmd chaining
end

function Cursor:isEmpty()
    return not self:isNotEmpty()
end

function Cursor:isNotEmpty()
    local type
    if self == Cursor then
        type = GetCursorInfo()
    else
        type = self.type
    end
    return (type or false) and true
end

function Cursor:clear(event)
    zebug.trace:event(event):print("clearing cursor and cache")
    ClearCursor()
    cachedCursor = nil
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param event string UFO custom unique ID for the event that triggered this action - good for debugging
function Cursor:dropOntoActionBar(btnSlotIndex, event)
    self = self:asInstance()
    zebug.warn:event(event):owner(self):print("dropping onto btnSlotIndex",btnSlotIndex)
    PlaceAction(btnSlotIndex)
    self:populateIfInstance()
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param event Event UFO custom unique ID for the event that triggered this action - good for debugging
---@return Cursor if invoked via an instance it will get populated with the button data
function Cursor:pickupFromActionBar(btnSlotIndex, event)
    self = self:asInstance()
    zebug.warn:event(event):owner(self):print("pickup from btnSlotIndex",btnSlotIndex)
    PickupAction(btnSlotIndex)
    return self:populateIfInstance()
end

---@param macroNameOrId any the bliz identifier for an action bar button.
---@param event string UFO custom unique ID for the event that triggered this action - good for debugging
function Cursor:pickupMacro(macroNameOrId, event)
    zebug.warn:event(event):print("macroNameOrId",macroNameOrId)
    PickupMacro(macroNameOrId)
    self:populateIfInstance()
end

function Cursor:isUfoPlaceholder()
    self = self:asInstance()
    if self.type == ButtonType.MACRO then
        local name = GetMacroInfo(self.id)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

---@return FlyoutDef
function Cursor:isUfoProxy()
    self = self:asInstance()
    zebug.trace:print("type", self.type, "id", self.id)
    return UfoProxy:isOnCursor(self)
--[[
    if self.type == ButtonType.MACRO then
        local name, texture, body = GetMacroInfo(self.id)
        zebug.trace:print("name",name)
        return (name == PROXY_MACRO_NAME) and body
    end
    return nil
]]
end

local s = function(v) return v or "nil"  end

function Cursor:toString()
    if self == Cursor then
        return "CuRsOr"
    else
        if self:isEmpty() then
            return "<Cursor: EMPTY>"
        else
            local name = self.name
            if self.id == ButtonType.MACRO then
                if name == UfoProxy:getMacroId() then
                    name = "UfoProxy: ".. (UfoProxy:getFlyoutName() or "UnKnOwN")
                elseif Placeholder:isOn(self, "BlizActionBarButton:toString()") then
                    name = "Placeholder"
                end
            end
            return string.format("<Cursor: type=%s, id=%s, name=%s>", s(self.type), s(self.id), s(name))
        end
    end
end
