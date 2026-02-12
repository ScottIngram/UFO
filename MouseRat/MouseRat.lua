---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- MouseRat
-- anything WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRat : UfoMixIn
---@field type MouseRatType
---@field primaryKeyName string "spellId", "mountId", etc.
MouseRat = {
    ufoType = "MouseRat",
}

UfoMixIn:mixInto(MouseRat)

MouseRatContractMethods = {
    -- these are expected to be implemented by subclasses of BtnDef
    -- I prolly need to rethink these now that I'm going with a service provider approach
    --"getId",
    "isUsable",
    "getIcon",
    "getName",
    "getToolTipSetter",
    "getFromCursor",
    --"pickupToCursor",
    "asSecureClickHandlerAttributes",
}

-------------------------------------------------------------------------------
-- CLASS Methods - operate on the singleton MouseRatSub
-------------------------------------------------------------------------------

function MouseRat:init()
    self:installMyToString()
end

function MouseRat:toString()
    if not self.type then
        return "<MouseRat: EMPTY>"
    elseif not self:getId() then
        return string.format("<MouseRat: %s:???>", nilStr(self.type))
    elseif not self:getName() then
        return string.format("<MouseRat: %s:%s>", nilStr(self.type), nilStr(self:getId()))
    else
        return string.format("<MouseRat: %s:%s>", nilStr(self.type), nilStr(self:getName()))
    end
end

-------------------------------------------------------------------------------
-- MouseRatSub
-- anything WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRatSub
---@field type MouseRatType
-- the following are expected to be implemented by the subclasses
---@field primaryKeyName string "spellId", "mountId", etc.
---@field pickerUpper function will place it onto the mouse pointer / cursor
---@field cursorConverter function transforms the wtf _G.GetCursorInfo() results into plain and simple type and id
MouseRatSub = { }

-------------------------------------------------------------------------------
-- CLASS Methods - operate on the singleton MouseRatSub
-------------------------------------------------------------------------------

-- instances from:
---- saved_variables - will have well defined type & id
---- cursor - will have ambiguous ID but well defined type
---- also BlizActionBarButton - as a means to learn its icon
--

---@return ButtonDef
---@param id number|string|nil (optional) a value possibly returned by some Bliz API
---@param type string|nil (optional) a value possibly returned by some Bliz API
function MouseRatSub:new(id, type)
    ---@type MouseRatSub
    local self = {}
    return self
end


-------------------------------------------------------------------------------
-- INSTANCE Methods - Default implementations for subclasses
-------------------------------------------------------------------------------

function MouseRatSub:getId()
    return self[self.primaryKeyName]
end
