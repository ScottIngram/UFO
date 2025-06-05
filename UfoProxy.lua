-- UfoProxy
-- manages the special macro that acts as a UFO on the mouse pointer

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(zVol or Zebug.INFO)

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

    zebug.trace:name("handler"):newEvent(self, me, eventCounter):run(function(event)
        zebug.trace:event(event):name("handler"):print("syncMyId")
        UfoProxy:syncMyId()
    end)
end

function EventHandlers:CURSOR_CHANGED(isDefault, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end

    zebug.trace:name("handler"):newEvent(self, me, eventCounter, ZEBUG_LEVEL_FOR_CURSOR_CHANGED):run(function(event)
        local cursor = Cursor:getFresh(event)
        zebug.trace:event(event):owner(cursor):print("maybe erasing UfoProxy macro")
        UfoProxy:delayedAsyncDeleteProxyIfNotOnCursor(event)
    end)
end

BlizGlobalEventsListener:register(UfoProxy, EventHandlers)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function getMacroIndexByNameOrNil(name)
    local proxyMacroId = GetMacroIndexByName(name) -- omfg, BLiz.  Returns 0 not nil if the macro does not exist. JFC
    local proxyExists = proxyMacroId and proxyMacroId > 0
    return proxyExists and proxyMacroId or nil
end

function UfoProxy:syncMyId()
    self.macroId = getMacroIndexByNameOrNil(self.name)
    return self.macroId
end

function UfoProxy:getMacroId()
    if not self.macroId then
        self:syncMyId()
    end
    return self.macroId
end

---@param thing UfoMixIn
---@return boolean true if there is a UfoProxy on the thing
function UfoProxy:isOn(thing)
    if not thing then
        return false
    elseif thing:isA(BlizActionBarButton) then
        return self:isOnBtn(thing)
    elseif thing:isA(ButtonDef) then
        return self:isOnBtnDef(thing)
    elseif thing:isA(Cursor) then
        return self:isOnCursor(thing)
    else
        -- maybe it's a Blizzard ActionBarActionButtonMixin
        return self:isOnBtn(thing)
    end

    return false -- give up
end

function UfoProxy:isOnBtnSlot(btnSlotIndex)
    local btn = BlizActionBarButton:getLiteralBlizBtn(btnSlotIndex)
    return self:isOnBtn(btn)
end

---@param btn number | BlizActionBarButton | ActionBarActionButtonMixin | LITERAL_BABB
---@return boolean true if there is a UfoProxy on the thing
function UfoProxy:isOnBtn(btn)
    assert(btn, "btn is nil.  So, no, it's not a UfoProxy")

    local btnSlotIndex
    if isNumber(btn) then
        btnSlotIndex = btn
    else
        if UfoMixIn:isA(btn, BlizActionBarButton) then
            btnSlotIndex = btn:getBtnSlotIndex()
        else
            btnSlotIndex = btn.action
        end
    end

    assert(btnSlotIndex, "can't figure out what the btn is so I can't ask it if it's holding UfoProxy.")

    local type, id = GetActionInfo(btnSlotIndex)

    return self:is(type, id)
end

---@param type ButtonType
---@param id number
---@return boolean true if the type and ID match those of the UfoProxy
function UfoProxy:is(type, id)
    assert(type, "invalid nil type")
    assert(id, "invalid nil id")
    return (type == ButtonType.MACRO) and (id == self:getMacroId())
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
    return getMacroIndexByNameOrNil(PROXY_MACRO_NAME)
end

function UfoProxy:getFlyoutId()
    local _, _, body = GetMacroInfo(PROXY_MACRO_NAME)
    if body then
        self.flyoutId = body
    end
    return self.flyoutId
end

function UfoProxy:put(btnSlotIndex, event)
    if self:isOnBtnSlot(btnSlotIndex) then return end

end

---@param flyoutId number
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
---@return Cursor
function UfoProxy:pickupUfoOntoCursor(flyoutId, event)
    if isInCombatLockdown("Drag and drop") then return end
    self.flyoutId = flyoutId

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local icon = flyoutConf:getIcon() or DEFAULT_ICON
    local macroText = flyoutId

    -- set a semaphore so other code can decide to respond to the resulting UPDATE_MACROS event
    Ufo.thatWasMeThatDidThatMacro = Event:new(self, "UfoProxy:pickupUfoOntoCursor()")

    local proxyMacroId = getMacroIndexByNameOrNil(PROXY_MACRO_NAME)

    if proxyMacroId then
        zebug.info:event(event):owner(self):print("Editing existing proxy macro. proxyMacroId",proxyMacroId, "icon",icon, "macroText",macroText)
        EditMacro(proxyMacroId, PROXY_MACRO_NAME, icon, macroText)
    else
        zebug.info:event(event):owner(self):print("Creating the proxy macro.", "icon",icon, "macroText",macroText)
        proxyMacroId = CreateMacro(PROXY_MACRO_NAME, icon , macroText)
        zebug.info:event(event):owner(self):print("CreatED the proxy macro. macroText",macroText,  "icon",icon, "proxyMacroId",proxyMacroId)
    end

    return Cursor:pickupMacro(proxyMacroId, event)
end

function UfoProxy:deleteProxyMacro(event)
    Ufo.thatWasMeThatDidThatMacro = Event:new(self, "deleteProxyMacro()") -- event or "deleteProxyMacro()"
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

function UfoProxy:delayedAsyncDeleteProxyIfNotOnCursor(event, timeToGo)
    if not timeToGo then
        C_Timer.After(1, function()
            self:delayedAsyncDeleteProxyIfNotOnCursor(event, true)
        end)
    else
        local cursor = Cursor:get()
        if self:exists() then
            if self:isOnCursor() then
                zebug.info:event(event):owner(cursor):print("It's on the cursor.  Exit and defer to the next CURSOR_CHANGED.")
            else
                zebug.info:event(event):owner(cursor):print("Not on cursor!  Safe to kill!  DIE PROXY !!!")
                self:deleteProxyMacro(event)
            end
        end
    end
end

function UfoProxy:toString()
    local name = self:getFlyoutName() or "nope"
    return string.format("<UfoProxy: %s>", name)
end

UfoMixIn.installMyToString(UfoProxy)
