-- UfoProxy
-- manages the special macro that acts as a UFO on the mouse pointer

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Zebug.INFO)

---@class UfoProxy : UfoMixIn
---@field macroId number
---@field name string
---@field flyoutId number
---@field ufoType string
UfoProxy = {
    name = PROXY_MACRO_NAME,
    ufoType = "UfoProxy",
}
UfoMixIn:mixInto(UfoProxy)

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local width = 35

-------------------------------------------------------------------------------
-- Listeners
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:UPDATE_MACROS(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    
    local eventId = makeEventId("UfoProxy:UPDATE_MACROS", eventCounter)
    zebug.trace:name(eventId):out(width, "m", "!START --------------- !START!")
    UfoProxy:syncMyId(eventId)
    zebug.trace:name(eventId):out(width, "m", "!END --------------- END!")
end

function EventHandlers:CURSOR_CHANGED(isDefault, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    
    local eventId = makeEventId(me, eventCounter)
    local cursor = Cursor:getFresh()
    zebug.info:name(eventId):out(width, "c","START! ", cursor, "!START!", Ufo.manifestedPlaceholder, Ufo.droppedPlaceholderOntoActionBar)
    zebug.info:name(eventId):print("manifestedPlaceholder", Ufo.manifestedPlaceholder, "droppedPlaceholderOntoActionBar",Ufo.droppedPlaceholderOntoActionBar, "myPlaceholderSoDoNotDelete", Ufo.myPlaceholderSoDoNotDelete)
    UfoProxy:deleteProxyOnCursorChange(eventId)
    zebug.info:name(eventId):out(width, "c","END!")
end

BlizGlobalEventsListener:register(UfoProxy, EventHandlers)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function UfoProxy:syncMyId()
    self.macroId = GetMacroIndexByName(self.name)
    return self.macroId
end

function UfoProxy:getMacroId()
    if not self.macroId then
        self:syncMyId()
    end
    return self.macroId
end

---@param obj UfoMixIn
function UfoProxy:isOn(obj)
    if not UfoMixIn:isA(obj) then
        return false -- I only know how to detect my proxy on one of my objects
    end

    if obj:isA(BlizActionBarButton) then
        return self:isOnBtn(obj)
    elseif obj:isA(ButtonDef) then
        return self:isOnBtnDef(obj)
    elseif obj:isA(Cursor) then
        return self:isOnCursor(obj)
    end
end

function UfoProxy:isOnBtnSlot(btnSlotIndex, eventId)
    local aBtn = BlizActionBarButton:get(btnSlotIndex, eventId)
    if aBtn:isUfoProxy() then

    end
end

---@param btn BlizActionBarButton
function UfoProxy:isOnBtn(btn)
    assert(btn, "btn is nil.  So, no, it's not a UfoProxy")
    assert(UfoMixIn:isA(btn), "btn isn't from a UfoMixIn so I can't check if it contains a UfoProxy.")
    return (btn:getType() == ButtonType.MACRO) and (btn:getId() == UfoProxy:getMacroId())
end

---@param btnDef ButtonDef
function UfoProxy:isOnBtnDef(btnDef)
    assert(btnDef, "btnDef is nil.  So, no, it's not a UfoProxy")
    assert(UfoMixIn:isA(btnDef, ButtonDef), "obj isn't a ButtonDef so I can't check if it contains a UfoProxy.")
    return (btnDef.type == ButtonType.MACRO) and (btnDef.macroId == UfoProxy:getMacroId())
end

---@param cursor Cursor
---@return FlyoutDef
function UfoProxy:isOnCursor(cursor)
    if not cursor then
        cursor = Cursor:get()
    end
    return (cursor.type == ButtonType.MACRO) and (cursor.id == self:getMacroId()) and self:getFlyoutDef()
end

---@return string
function UfoProxy:getFlyoutName()
    return FlyoutDefsDb:getName(self:getFlyoutId())
end

---@return FlyoutDef
function UfoProxy:getFlyoutDef()
    return FlyoutDefsDb:trustedGet(self:getFlyoutId())
end

function UfoProxy:exists()
    return GetMacroInfo(PROXY_MACRO_NAME)
end

function UfoProxy:getFlyoutId()
    local _, _, body = GetMacroInfo(PROXY_MACRO_NAME)
    if body then
        self.flyoutId = body
    end
    return self.flyoutId
end

function UfoProxy:pickupUfoOntoCursor(flyoutId, eventId)
    if isInCombatLockdown("Drag and drop") then return end
    self.flyoutId = flyoutId

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local icon = flyoutConf:getIcon()
    self:deleteProxyMacro(eventId)
    local macroText = flyoutId
    Ufo.thatWasMeThatDidThatMacro = eventId or "pickupUfoCursor()"
    local proxy =  CreateMacro(PROXY_MACRO_NAME, icon or DEFAULT_ICON, macroText)
    Cursor:pickupMacro(proxy, eventId)
end

function UfoProxy:deleteProxyMacro(eventId)
    Ufo.thatWasMeThatDidThatMacro = eventId or "deleteProxyMacro()"
    DeleteMacro(PROXY_MACRO_NAME)
    -- workaround Bliz bug - make sure the macro frame accurately reflects that the macro has been deleted
    if MacroFrame:IsShown() then
        MacroFrame:Update()
    end
    self.flyoutId = nil
end

-- handle the unique situation of
-- the user chucked (right-clicked) the cursor without dropping it onto an action bar.
-- Because CURSOR_CHANGED events may fire before or after ACTIONBAR_SLOT_CHANGED,
-- we have no reliable way to know if the UfoProxy landed on an action bar or vanished into thin air.
-- So, delay execution to give GermCommander a chance to analyze the action bar changes before
-- we delete the proxy which would remove it from the bar.

function UfoProxy:deleteProxyOnCursorChange(eventId, timeToGo)
    zebug.info:label(eventId):print("Is UfoProxy on the cursor", Cursor:get())
    if not timeToGo then
        C_Timer.After(1, function()
            self:deleteProxyOnCursorChange(eventId, true)
        end)
    else
        if self:exists() then
            if self:isOnCursor() then
                zebug.info:label(eventId):print("It's on the cursor.  Exit and defer to the next CURSOR_CHANGED.")
            else
                zebug.info:label(eventId):print("Not on cursor!  Safe to kill!  DIE PROXY !!!")
                self:deleteProxyMacro(eventId)
            end
        end
    end
end

-- handle the unique situation of
-- the user chucked (right-clicked) the cursor without dropping it onto an action bar.
-- but because we can't know for sure if it was or wasn't, wait a moment to get GermCommander a chance to analyze the action bar changes
function UfoProxy:NEW_delayedAsyncDeleteProxy(eventId)
    local name = "delayedAsyncDeleteProxy"
    zebug.info:name(name):label(eventId):print("Is UfoProxy on the cursor", Cursor:get())
    if self:exists() then
        if self:isOnCursor() then
            C_Timer.After(1, function()
                self:NEW_delayedAsyncDeleteProxy(eventId)
            end)
        else
            -- delay just a moment so that other code listening to this same event can read the UfoProxy before it vanishes...
            -- actually, maybe that code should nuke the UfoProxy?
            -- ok, but, Ufo.lua still needs to nuke it on startup just in case it's leftover from a previous session
            -- SO, do I need to wrap this in a C_timer ???? or throw it away entirely?
            zebug.info:name(name):label(eventId):print("Not on cursor!  Safe to kill!  DIE PROXY !!!")
            self:deleteProxyMacro(eventId)
        end
    end
end

function UfoProxy:OLD_delayedAsyncDeleteProxy(eventId)
    local name = "delayedAsyncDeleteProxy"
    local proxyExists = GetMacroInfo(PROXY_MACRO_NAME)
    --zebug.trace:print("checking proxy...")
    if proxyExists then
        --zebug.trace:name(name):label(eventId):print("deleting proxy in 1 second...")
        C_Timer.After(1,
        -- START callback
                function()
                    local c = Cursor:get()
                    zebug.info:name(name):label(eventId):print("double checking proxy... cursor", c)
                    local isDraggingProxy = self:isOnCursor()
                    if isDraggingProxy then
                        UfoProxy:OLD_delayedAsyncDeleteProxy(eventId)
                    else
                        zebug.info:name(name):label(eventId):print("DIE PROXY !!!")
                        UfoProxy:deleteProxyMacro(eventId)
                    end
                end
        ) -- END callback
    end
end
