---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

-------------------------------------------------------------------------------
-- MouseRatType
-- the kinds of stuff WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRatType - the types used by the Bliz API's
MouseRatType = {
    SPELL   = "spell",
    MOUNT   = "mount",
    ITEM    = "item",
    TOY     = "toy",
    PET     = "battlepet",
    MACRO   = "macro",
    PSPELL  = "petaction",
    FLYOUT  = "flyout",
    BROKENP = "brokenPetCommand", -- an imaginary type used to accomodate the various kinds of petaction that the WoW APIs do not handle correctly
    BRUNDLEFLY = "companion",-- MOUNT variant, an abnormal result containing a useless ID which isn't accepted by any API. is returned by PickupSpell(spellIdOfSomeMount)
    SUMMON_RANDOM_FAVORITE_MOUNT = "summonmount",
}

-------------------------------------------------------------------------------
-- MouseRatRegistry
-- records & wrangles MouseRat subclasses (and instantiates them?)
-------------------------------------------------------------------------------
---@class MouseRatRegistry : UfoMixIn
---@field ufoType string
---@field kids table<MouseRatType,MouseRat>
MouseRatRegistry = {
    ufoType = "MouseRatRegistry",
    kids = {},
}

UfoMixIn:mixInto(MouseRatRegistry)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@param kid MouseRat a "subclass" that implements the MouseRat missing methods required for SPELL, ITEM, etc.
function MouseRatRegistry:register(kid)
    self.kids[kid.type] = kid
end

function MouseRatRegistry:init()
    self:validateKids()
end

function MouseRatRegistry:validateKids()
    MouseRatRegistry:forEachKid(function(kid)
        for i, methodName in ipairs(MouseRatContractMethods) do
            zebug.warn:print("methodName",methodName, "exists",isFunction( kid[methodName] ))
        end
    end)
end

function MouseRatRegistry:getClass(type)
    local subClass = self.kids[type]
    -- assert(subClass, "Oops, no MouseRat for " .. (type or "nil"))
    return subClass
end

-------------------------------------------------------------------------------
-- Utility Methods
-------------------------------------------------------------------------------

function MouseRatRegistry:forEachKid(func)
    if isEmptyTable(self.kids) then
        error("MouseRatRegistry FAILED - no MouseRat children exist?")
    end

    for type, kid in pairs(self.kids) do
        zebug.warn:print("type",type, "kid", kid)
        func(kid)
    end
end

