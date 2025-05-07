-- Placeholder class
-- a special macro that holds onto the action bar button slot for the Germ

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.TRACE)

---@class Placeholder
Placeholder = {}

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Placeholder:create()
    Ufo.thatWasMeThatDidThatMacro = true
    local exists = GetMacroInfo(PLACEHOLDER_MACRO_NAME)
    if not exists then
        local icon = Ufo.iconTexture
        zebug.info:print("name",PLACEHOLDER_MACRO_NAME, "icon",icon, "PLACEHOLDER_MACRO_TEXT", PLACEHOLDER_MACRO_TEXT)
        CreateMacro(PLACEHOLDER_MACRO_NAME, icon, PLACEHOLDER_MACRO_TEXT)
    end
end

function Placeholder:pickup(eventId)
    self:create()
    Ufo.myPlaceholderSoDoNotDelete = true
    Cursor:pickupMacro(PLACEHOLDER_MACRO_NAME, eventId)
end

function Placeholder:put(btnSlotIndex, eventId)
    if not Config.opts.usePlaceHolders then return end

    Ufo.droppedPlaceholderOntoActionBar = eventId or true

    -- preserve the current contents of the cursor
    local crsDef = ButtonDef:getFromCursor()

    -- clobber anything on the cursor and replace it with the placeholder
    self:pickup(eventId)
    zebug.trace:label(eventId):print("btnSlotIndex",btnSlotIndex)
    Cursor:dropOntoActionBar(btnSlotIndex, eventId)

    -- yes? we're synchronous, yes?
    -- Ufo.droppedPlaceholderOntoActionBar = nil

    -- restore anything that had originally been on the cursor
    if crsDef then
        zebug.info:label(self):print("triggering updateAll()  eventId",eventId)
        crsDef:pickupToCursor()
        --GermCommander:updateAll(eventId.."+putPlaceholder()") -- draw the dropped UFO -- TODO: update ONLY the one specific germ
    end
end

function Placeholder:clear(btnSlotIndex, eventId)
    --if not Config.opts.usePlaceHolders then return end
    if not Placeholder:exists(btnSlotIndex) then return end
    Cursor:pickupFromActionBar(btnSlotIndex, eventId)
    Cursor:clear()
end

function Placeholder:exists(btnSlotIndex)
    local type, id = GetActionInfo(btnSlotIndex)
    zebug.trace:print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

---@param btn BlizActionBarButton
function Placeholder:isOn(btn)
    if not btn then return end

    local type, id = btn:getType(), btn:getId()
    zebug.trace:print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

function Placeholder:nuke()
    while GetMacroInfo(PLACEHOLDER_MACRO_NAME) do
        DeleteMacro(PLACEHOLDER_MACRO_NAME)
    end
end
