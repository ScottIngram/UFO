---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(--[[Z_VOLUME_GLOBAL_OVERRIDE or]] Zebug.TRACE)

-------------------------------------------------------------------------------
-- MouseRatRegistry
-- records & wrangles MouseRat subclasses (and instantiates them?)
-------------------------------------------------------------------------------
---@class MouseRatRegistry : UfoMixIn
---@field ufoType string
---@field kids table<MouseRatType,MouseRat>
---@field customizedCursorTypes table<MouseRatType,table<>>
MouseRatRegistry = {
    ufoType = "MouseRatRegistry",
    kids = {},
    customizedCursorTypes = {},
}

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@param kid MouseRat a "subclass" that implements the MouseRat missing methods required for SPELL, ITEM, etc.
function MouseRatRegistry:register(kid)
    assert(kid, "bad arg: 'kid' is nil")
    assert(kid.type, "the registered kid has no defined 'type'")

    if self.kids[kid.type] then
        error("This MouseRat has already been registered: " .. kid.type)
    end

    -- subclasses are considered "custom" when their type is different from their cursorType (if specified)
    local isCustom = kid.cursorType and (kid.cursorType ~= kid.type)
    if isCustom then
        self:addMouseRatForCustomizedCursorType(kid)
    end

    MouseRat:adopt(kid) -- activate OO inheritance

    self.kids[kid.type] = kid
end

function MouseRatRegistry:init()
    self:validateKids()
end

local CGCI = "consumeGetCursorInfo"

function MouseRatRegistry:validateKids()
    local invalids
    MouseRatRegistry:forEachKid(function(kid)
        local isExempt = (kid == MrUnsupported) or (kid.become ~= nil) -- any subclass that simply becomes a different one is exempt from providing the full contract

        if ((kid[CGCI] == nil) or (kid[CGCI] == MouseRat.consumeGetCursorInfo)) and not isExempt then
            zebug.warn:owner(kid):print("the method",CGCI, "is mandatory and MUST be implemented by the subclass")
        end

        for i, methodName in ipairs(MouseRatMethodsContract) do
            local valid
            local method = kid[methodName]
            local helper = kid.helpers and kid.helpers[methodName]
            local isTheHelperThere = (helper ~= nil) -- allow false but not nil
            local isMethodDefaultBaseImpl = (method == MouseRat[methodName])
            local isDefaultGoodEnoughByItself = (methodName == "getName")

            -- validate that the required methods are implemented by the subclass, or if not, then their helpers have.
            if isMethodDefaultBaseImpl then
                if isDefaultGoodEnoughByItself then
                    valid = true
                else
                    if isTheHelperThere then
                        valid = true
                    else
                        valid = false
                    end
                end
            else
                valid = true
            end

            -- go above and beyond mere validation.
            -- enable subclasses to specify helpers as static values which we will wrap inside a function
            if valid then
                if not kid.helpers then
                    kid.helpers = {}
                end

                if isTheHelperThere then
                    if not isFunction(helper) then
                        --print("WRAPPING",kid.type, "helper", helperName, helper)
                        -- the helper "method" is actually just a string, number, etc.  So convert it into a function.
                        kid.helpers[methodName] = function() return helper end -- this snapshots the current value.  bug?
                    end
                else
                    -- failsafe
                    kid.helpers[methodName] = function() zebug.error:owner(kid):print(methodName,"is missing.  Defaulting to nil") return nil end
                end
            else
                zebug.error:owner(kid):print("type",kid.type, "must implement a method",methodName, "or define a helper method/field", methodName)
                if not invalids then invalids = {} end
                invalids[#invalids+1] = kid.type
            end
        end
    end)

    if invalids then
        -- prolly need to either accumulate all errs, or, just fail immediately above
        -- error("blah blah")
    end

end

---@param type MouseRatType
---@return MouseRat|nil will be nil if the given type has no registered subclass
function MouseRatRegistry:getSubClass(type)
    assert(type, "bad arg: 'type' is nil")
    local subClass = self.kids[type]
    return subClass
end

---@param mr MouseRat
function MouseRatRegistry:addMouseRatForCustomizedCursorType(kid)
    -- custom types must provide the "cursorType" field and it must specify a standard BlizCursorType
    assert(kid.cursorType, "bad config: The custom MouseRat for "..kid.type.." has not specified a 'cursorType' field")
    assert(BLIZ_CURSOR_TYPE_BY_NAME[kid.cursorType], "bad config: The custom '"..kid.type.."' -> '"..kid.cursorType.."' cursorType is not a standard BlizCursorType")
    assert(kid.disambiguator, "bad config: The custom MouseRat for "..kid.type.." -> "..kid.cursorType.." has not specified a 'disambiguator' method")

    local cct = self.customizedCursorTypes[kid.cursorType]
    if not cct then
        cct = {}
        self.customizedCursorTypes[kid.cursorType] = cct
    end

    table.insert(cct, kid)
end

-------------------------------------------------------------------------------
-- Utility Methods
-------------------------------------------------------------------------------

function MouseRatRegistry:forEachKid(func)
    if isEmptyTable(self.kids) then
        error("MouseRatRegistry FAILED - no MouseRat children exist?")
    end

    for type, kid in pairs(self.kids) do
        --zebug.warn:print("type", type, "kid", kid)
        func(kid)
    end
end

