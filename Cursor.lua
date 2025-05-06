-- Cursor Helper

-- TODO - subscribe to CURSOR_CHANGED which erases a cached cursor.  the Cursor:get() caches itself for reuse

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.TRACE)

---@class Cursor : UfoMixIn
---@field type string
---@field id any
---@field index number
---@field itemLink string
---@field bookType any
---@field overriddenSpellId number
---@field amount number
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

    local eventId = makeEventId("CURSOR_CACHE_CONTROLLER", eventCounter)
    cachedCursor = nil
    zebug.info:name(eventId):out(20, "Ç","START! ", cursor, "!START!", Ufo.manifestedPlaceholder, Ufo.droppedPlaceholderOntoActionBar)
    zebug.info:name(eventId):print("manifestedPlaceholder", Ufo.manifestedPlaceholder, "droppedPlaceholderOntoActionBar",Ufo.droppedPlaceholderOntoActionBar, "myPlaceholderSoDoNotDelete", Ufo.myPlaceholderSoDoNotDelete)
    zebug.info:name(eventId):out(20, "Ç","END!")
end

BlizGlobalEventsListener:register(Cursor, EventHandlers)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@return Cursor
function Cursor:get()
    if cachedCursor then
        return cachedCursor
    end

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
    return self
end

function Cursor:asInstance(skipPop)
    if self == Cursor then
        self = deepcopy(self, {})
        self:installMyToString()
        if not skipPop then
            self:get()
        end
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

function Cursor:clear()
    ClearCursor()
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param eventId string UFO custom unique ID for the event that triggered this action - good for debugging
function Cursor:dropOntoActionBar(btnSlotIndex, eventId)
    zebug.warn:label(eventId):print("btnSlotIndex",btnSlotIndex)
    PlaceAction(btnSlotIndex)
    self:populateIfInstance()
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param eventId string UFO custom unique ID for the event that triggered this action - good for debugging
---@return Cursor if invoked via an instance it will get populated with the button data
function Cursor:pickupFromActionBar(btnSlotIndex, eventId)
    zebug.warn:label(eventId):print("btnSlotIndex",btnSlotIndex)
    Ufo.changedCursor = "Cursor:pickupFromActionBar("..btnSlotIndex..") for eventId " .. (eventId or "UnKnOwN") -- not used yet
    PickupAction(btnSlotIndex)
    return self:populateIfInstance()
end

---@param macroNameOrId any the bliz identifier for an action bar button.
---@param eventId string UFO custom unique ID for the event that triggered this action - good for debugging
function Cursor:pickupMacro(macroNameOrId, eventId)
    zebug.warn:label(eventId):print("macroNameOrId",macroNameOrId)
    Ufo.changedCursor = "Cursor:pickupMacro(".. macroNameOrId ..") for eventId " .. (eventId or "UnKnOwN") -- not used yet
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
        return "nil"
    else
        if self:isEmpty() then
            return "<Cursor: EMPTY>"
        else
            return string.format("<Cursor: type=%s, id=%s, name=%s>", s(self.type), s(self.id), s(self.name))
        end
    end
end

-- TODO move into utilities
--[[
function mixInToString(self)
    local mt = getmetatable(self)
    if not mt then
        mt = {}
        setmetatable(self, mt)
    end
    mt.__tostring = self.toString
end
]]

