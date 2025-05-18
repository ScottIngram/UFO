-- Placeholder class
-- a special macro that holds onto the action bar button slot for the Germ

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.ERROR)

---@class Placeholder
Placeholder = {
    ufoType = "Placeholder",
}

local width = 20

-------------------------------------------------------------------------------
-- Listeners
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:CURSOR_CHANGED(isDefault, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
--print("..................... zebug:getNoiseLevel()",zebug:getLowestAllowedSpeakingVolume(), "zebug.NONE",zebug.NONE)
    zebug.trace:print("11111111 *****************************************************************")
    local event = Event:new(self, me, eventCounter, zebug.TRACE) -- zebug:getNoiseLevel()
    zebug.trace:mMoon():name(me):runEvent(event, function()
        zebug.trace:print("2 *****************************************************************")
        zebug.trace:event(event):print("3 *****************************************************************")
        zebug.info:print("4 *****************************************************************")
        zebug.info:event(event):print("5 *****************************************************************")
        zebug.warn:print("6 *****************************************************************")
        zebug.warn:event(event):print("7 *****************************************************************")
        Placeholder:doNotLetUserDragMe(event)
    end)
end

BlizGlobalEventsListener:register(Placeholder, EventHandlers)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Placeholder:create(event)
    local exists = GetMacroInfo(PLACEHOLDER_MACRO_NAME)
    if not exists then
        local icon = Ufo.iconTexture
        zebug.info:event(event):print("name",PLACEHOLDER_MACRO_NAME, "icon",icon, "PLACEHOLDER_MACRO_TEXT", PLACEHOLDER_MACRO_TEXT)
        Ufo.thatWasMeThatDidThatMacro = event
        CreateMacro(PLACEHOLDER_MACRO_NAME, icon, PLACEHOLDER_MACRO_TEXT)
    end
end

function Placeholder:pickup(event)
    self:create(event)
    Ufo.myPlaceholderSoDoNotDelete = event
    Cursor:pickupMacro(PLACEHOLDER_MACRO_NAME, event)
end

---@param btnSlotIndex number
---@param event Event
---@return ButtonDef whatever was on btnSlotIndex before it got clobbered by the Placeholder
function Placeholder:put(btnSlotIndex, event)
    if not Config.opts.usePlaceHolders then return end

    local theBtnAlready = BlizActionBarButton:get(btnSlotIndex, event)
    if self:isOn(theBtnAlready, event) then return end

    Ufo.droppedPlaceholderOntoActionBar = event or true

    -- preserve the current contents of the cursor
    local crsDef = ButtonDef:getFromCursor()

    -- clobber anything on the cursor and replace it with the placeholder
    self:pickup(event)
    zebug.trace:event(event):print("btnSlotIndex",btnSlotIndex)
    Cursor:dropOntoActionBar(btnSlotIndex, event)

    -- yes? we're synchronous, yes?
    -- Ufo.droppedPlaceholderOntoActionBar = nil

    local nowCursor = ButtonDef:getFromCursor()
    -- restore anything that had originally been on the cursor
    if crsDef then
        zebug.info:event(event):print("restoring original cursor to",crsDef, "which replaces nowCursor",nowCursor)
        crsDef:pickupToCursor(event)
        nowCursor = crsDef
        --GermCommander:updateAll(eventId.."+putPlaceholder()") -- draw the dropped UFO -- TODO: update ONLY the one specific germ.
    else
        zebug.info:event(event):print("nothing was originally on the cursor to",crsDef, "but it's currently nowCursor",nowCursor)
    end

    return nowCursor
end

function Placeholder:clear(btnSlotIndex, event)
    --if not Config.opts.usePlaceHolders then return end
    if not Placeholder:isOnBtnSlot(btnSlotIndex, event) then return end
    Cursor:pickupFromActionBar(btnSlotIndex, event)
    Cursor:clear(event)
end

function Placeholder:isOnBtnSlot(btnSlotIndex, event)
    local type, id = GetActionInfo(btnSlotIndex)
    zebug.trace:event(event):print("btnSlotIndex",btnSlotIndex, "type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:event(event):print("btnSlotIndex",btnSlotIndex, "name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

---@param btn BlizActionBarButton
function Placeholder:isOn(btn, event)
    if not btn then return end

    local type, id = btn:getType(), btn:getId()
    zebug.trace:event(event):--[[owner(btn):]]print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:event(event):--[[owner(btn):]]print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

function Placeholder:nuke()
    while GetMacroInfo(PLACEHOLDER_MACRO_NAME) do
        DeleteMacro(PLACEHOLDER_MACRO_NAME)
    end
end

function Placeholder:doNotLetUserDragMe(event)
    local cursor = Cursor:get()
    if cursor:isUfoPlaceholder() then
        if Ufo.myPlaceholderSoDoNotDelete then
            zebug.info:event(event):owner(cursor):print("keeping (this one time) at request of Ufo.myPlaceholderSoDoNotDelete",Ufo.myPlaceholderSoDoNotDelete)
            Ufo.myPlaceholderSoDoNotDelete = false
        else
            zebug.info:event(event):owner(cursor):print("clearing in absence of Ufo.myPlaceholderSoDoNotDelete")
            cursor:clear(event)
        end
    else
        zebug.info:event(event):owner(cursor):print("ignoring because I only care about Placeholders")
        Ufo.myPlaceholderSoDoNotDelete = false
    end
end
