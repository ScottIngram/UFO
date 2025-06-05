-- Placeholder class
-- a special macro that holds onto the action bar button slot for the Germ

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(zVol or Zebug.TRACE)

---@class Placeholder
Placeholder = {
    ufoType = "Placeholder",
}
UfoMixIn:mixInto(Placeholder)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Placeholder:createIfNotExists(event)
    local exists = GetMacroInfo(PLACEHOLDER_MACRO_NAME)
    if not exists then
        local icon = Ufo.iconTexture
        zebug.info:event(event):print("name",PLACEHOLDER_MACRO_NAME, "icon",icon, "PLACEHOLDER_MACRO_TEXT", PLACEHOLDER_MACRO_TEXT)
        Ufo.thatWasMeThatDidThatMacro = event
        CreateMacro(PLACEHOLDER_MACRO_NAME, icon, PLACEHOLDER_MACRO_TEXT)
    else
        zebug.info:event(event):print("placeholder exists",PLACEHOLDER_MACRO_NAME)
    end
end

function Placeholder:pickup(event)
    self:createIfNotExists(event)
    Ufo.myPlaceholderSoDoNotDelete = event
    zebug.info:event(event):owner(self):print("grabbers")
    Cursor:pickupMacro(PLACEHOLDER_MACRO_NAME, event)
end

---@param btnSlotIndex number
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
---@return ButtonDef whatever was on btnSlotIndex before it got clobbered by the Placeholder
function Placeholder:put(btnSlotIndex, event)
    if not Config.opts.usePlaceHolders then return end

    local theBtnAlready = BlizActionBarButtonHelper:get(btnSlotIndex, event)
    if self:isOn(theBtnAlready, event) then return end

    Ufo.droppedPlaceholderOntoActionBar = event or true

    -- preserve the current contents of the cursor
    local thingWasOnCursor = ButtonDef:getFromCursor(event)

    -- clobber anything on the cursor and replace it with the placeholder
    self:pickup(event)
    zebug.trace:event(event):print("btnSlotIndex",btnSlotIndex)
    Cursor:dropOntoActionBar(btnSlotIndex, event)

    -- yes? we're synchronous, yes?
    -- Ufo.droppedPlaceholderOntoActionBar = nil

    local nowCursor = ButtonDef:getFromCursor(event)
    -- restore anything that had originally been on the cursor
    if thingWasOnCursor then
        zebug.info:event(event):print("restoring original cursor to", thingWasOnCursor, "which replaces nowCursor",nowCursor)
        thingWasOnCursor:pickupToCursor(event)
        nowCursor = thingWasOnCursor
    else
        zebug.info:event(event):mark(Mark.FIRE):print("NOTHING was originally on the cursor to", thingWasOnCursor, "and it's currently nowCursor",nowCursor)
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

    local type, id = btn:getTypeAndId()
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
        --local type, id = GetCursorInfo()
        --zebug.info:event(event):owner(cursor):print("ignoring because I only care about Placeholders. type",type, "id",id)
        Ufo.myPlaceholderSoDoNotDelete = false
    end
end

function Placeholder:getId()
    return getMacroIndexByNameOrNil(PLACEHOLDER_MACRO_NAME)
end

function Placeholder:toString()
    return string.format("<Placeholder: macroId=%d>", self:getId())
end
