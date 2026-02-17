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

UfoMixIn:mixInto(MouseRatRegistry)

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@param kid MouseRat a "subclass" that implements the MouseRat missing methods required for SPELL, ITEM, etc.
function MouseRatRegistry:register(kid)
    assert(kid, "bad arg: 'kid' is nil")
    --zebug.warn:dumpy("kid", kid)
    assert(kid.mrType, "the registered kid has no defined 'mrType'")

    if self.kids[kid.mrType] then
        error("This MouseRat has already been registered: " .. kid.mrType)
    end

    -- subclasses are considered "custom" when their mrType is different from their cursorType (if specified)
    local isCustom = kid.cursorType and (kid.cursorType ~= kid.mrType)
    if isCustom then
        self:addMouseRatForCustomizedCursorType(kid)
    end

    if not kid.ufoType then
        -- if this field is missing, then, the kid expects us to mix in the MouseRat baseclass
        MouseRat:mixInto(kid)
        zebug.warn:event("event"):owner(kid):print("mixed it all in to",kid)
    else
        zebug.warn:event("event"):owner(kid):print("mixed it NOTHING coz it alread had ufoType",kid.ufoType)
    end

    self.kids[kid.mrType] = kid
end

function MouseRatRegistry:init()
    self:validateKids()
end

local CGCI = "consumeGetCursorInfo"

function MouseRatRegistry:validateKids()
    local invalids
    MouseRatRegistry:forEachKid(function(kid)
        if kid == MrEmpty or kid == MrUnsupported then return end

        if (kid[CGCI] == nil) or (kid[CGCI] == MouseRat.consumeGetCursorInfo) then
            zebug.warn:owner(kid):print("the method",CGCI, "is mandatory and MUST be implemented by the subclass")
        end

        for methodName, helpers in pairs(MouseRatSubClassContract) do
            local valid
            local method = kid[methodName]
            local isImplemented = method and (method ~= MouseRat[methodName])
            if isImplemented then
                valid = true
            else
                local apiName = helpers.helperApi
                local api = kid[apiName]
                if (isFunction(api)) then
                    valid = true
                else
                    if kid[helpers.helperField] then
                        valid = true
                    end
                end
            end

            --zebug.warn:owner(kid):print("mrType",kid.mrType, methodName,kid[methodName], "apiName", helpers.helperApi,kid[helpers.helperApi], "valid",valid)

            if not valid then
                zebug.error:owner(kid):print("mrType",kid.mrType, "must implement a method",methodName, "or define a field",helpers.helperApi or helpers.helperField)

                -- prolly need to either accumulate all errs, or, just fail immediately above
                if not invalids then invalids = {} end
                invalids[#invalids] = kid.mrType
            else
                zebug.warn:owner(kid):print("mrType",kid.mrType, methodName,exists(kid[methodName])and"ok", helpers.helperApi,exists(kid[helpers.helperApi])and"ok", "valid",valid)
            end
        end
    end)

    if not invalids then
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
    assert(kid.cursorType, "bad config: The custom MouseRat for "..kid.mrType.." has not specified a 'cursorType' field")
    assert(BLIZ_CURSOR_TYPE_BY_NAME[kid.cursorType], "bad config: The custom '"..kid.mrType.."' -> '"..kid.cursorType.."' cursorType is not a standard BlizCursorType")
    assert(kid.disambiguator, "bad config: The custom MouseRat for "..kid.mrType.." -> "..kid.cursorType.." has not specified a 'disambiguator' method")

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

    for mrType, kid in pairs(self.kids) do
        --zebug.warn:print("mrType", mrType, "kid", kid)
        func(kid)
    end
end

