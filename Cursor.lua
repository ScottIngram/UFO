-- Cursor Helper

-- TODO - subscribe to CURSOR_CHANGED which erases a cached cursor.  the Cursor:get() caches itself for reuse

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(zVol or Zebug.INFO)

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
local secretCachedCursor

-------------------------------------------------------------------------------
-- Listeners
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:CURSOR_CHANGED(isCursorEmpty, me, eventCounter)
    eventCounter = eventCounter or "NO-EVENT-COUNTER"
    --if not Ufo.hasShitCalmedTheFuckDown then return end

    local event = Event:new(self, Cursor:nameMakerForCursorChanged(isCursorEmpty), eventCounter, ZEBUG_LEVEL_FOR_CURSOR_CHANGED)
    zebug.info:name("handler"):owner(secretCachedCursor):runEvent(event, function()
        local type, id = GetCursorInfo()
        zebug.info:event(event):name("handler"):print("erasing cachedCursor")
        secretCachedCursor = cachedCursor
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
        local b = ButtonDef:getFromCursor("rando")
        self.name = b and b:getName()
    end

    cachedCursor = self
    self.whenWasCached = time()
    return self
end

local maxAge = 0 -- seconds.  disabled this entirely because the user can click really fast

-- bypass the cache - should only need to be used by other subscribers of CURSOR_CHANGED due to race condition
function Cursor:getFresh(event)
    if cachedCursor then
        local age = time() - cachedCursor.whenWasCached
        zebug.trace:event(event):print("age", age)
        if age >= maxAge then
            zebug.trace:event(event):print("clearing cache because it's too old!")
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

function amEmpty()
    return Cursor:isEmpty() and "already empty... supposedly" or ""
end

function Cursor:clear(event)
    zebug.info:owner(amEmpty):event(event):print("clearing cursor and cache")
    ClearCursor()
    cachedCursor = nil
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function Cursor:dropOntoActionBar(btnSlotIndex, event)
    self = self:asInstance()
    zebug.info:event(event):owner(self):print("dropping onto btnSlotIndex",btnSlotIndex)
    PlaceAction(btnSlotIndex)
    self:populateIfInstance() -- I am now something different so find out what I am
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
---@return Cursor, Cursor - (1) what's on the cursor now, (2) what was on the cursor before, if anything
function Cursor:pickupFromActionBar(btnSlotIndex, event)
    self = self:asInstance()
    local wasCursorEmpty = self:isEmpty()

    zebug.info:event(event):owner(self):print("pickup from btnSlotIndex",btnSlotIndex)
    PickupAction(btnSlotIndex)
    return self:populateIfInstance()
end

---@param macroNameOrId string|number duh
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function Cursor:pickupMacro(macroNameOrId, event)
    -- -d-o-n-'-t- DO (see below) pickup the same macro if it's already on the cursor
    -- because Bliz will spam extraneous and/or misleading CURSOR_CHANGED events which fuck up any subscribers who need accurate info.
    -- For example, doing so will trigger a CURSOR_CHANGED event at which time the Bliz cursor API will report that it is empty.
    -- Ok, fine, but then there is no subsequent event to indicate that the macro ever made it onto the cursor.
    -- So, the Bliz API fucking lies to you and says "yep, the cursor is empty and stayed that way."  Fuck you Bliz.
    local isAlreadyOnCursor
    local type, id = GetCursorInfo()
    if type == ButtonType.MACRO then
        if isNumber(macroNameOrId) then
            isAlreadyOnCursor = macroNameOrId == id
        else
            local id2 = getMacroIndexByNameOrNil(macroNameOrId)
            isAlreadyOnCursor = id2 == id
        end
    end

    if isAlreadyOnCursor then
        -- if I EditMacro(.., newIcon) a macro that is currently being dragged around by the cursor it won't display the changed icon.
        -- The cursor will display the old version of the macro UNLESS I explicitly pick it up again.
        -- WORSE YET, if I DON'T first ClearCursor() before PickupMacro() again, then,
        -- the fucking BLIZ event dispatcher issues a single CURSOR_CHANGED event during which PickupMacro() thinks the cursor is EMPTY.
        -- There is never CURSOR_CHANGED event to indicate it carries the new version of the macro.  Shit kicking mutherfucking Bliz API.
        zebug.info:mCross():mMoon():event(event):owner(self):print("macro",id, "is already on the cursor.  NOP... errr, I mean, I must clear it first to avoid Bliz Bullshit")
        ClearCursor()
        --return -- nope, keep going and do the PickupMacro()
    end

    --zebug.info:event(event):owner(self):print("BEFORE PickupMacro()... macroNameOrId",macroNameOrId,  "GetCursorInfo->",GetCursorInfo())
    PickupMacro(macroNameOrId)
    --zebug.info:event(event):owner(self):print("AFTER PickupMacro()... macroNameOrId",macroNameOrId,  "GetCursorInfo->",GetCursorInfo())

    return self:populateIfInstance()
    -- TODO ---@return Cursor, Cursor : (1) what's on the cursor now; (2) what was on the cursor before, if anything
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

function Cursor:nameMakerForCursorChanged(isCursorEmpty)
    return sprintf("CURSOR_CHANGED_{%s}", isCursorEmpty and " " or "#")
end

function Cursor:toString()
    if self == Cursor then
        return self:asInstance():toString()-- "CuRsOr"
    else
        if self:isEmpty() then
            return "<Cursor: EMPTY>"
        else
            local name = self.name
            if self.type == ButtonType.MACRO then
                if name == PROXY_MACRO_NAME then
                    name = UfoProxy:toString()
                    -- name = "UfoProxy: ".. (UfoProxy:getFlyoutName() or "UnKnOwN")
                elseif name == PLACEHOLDER_MACRO_NAME then
                    name = Placeholder:toString()
                end
            end
            return string.format("<Cursor: %s:%s %s>", s(self.type), s(self.id), s(name))
        end
    end
end
