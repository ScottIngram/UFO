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

    -- subclasses are considered "custom" when their mrType is a MouseRatType but is NOT a standard BlizCursorType
    local isCustom = not BLIZ_CURSOR_TYPE_BY_NAME[kid.mrType]
    local isMrUnsupported = (kid.mrType == MouseRatType.UNSUPPORTED)
    if isCustom and not isMrUnsupported then
        -- custom types must provide the "cursorType" field and it must specify a standard BlizCursorType
        assert(kid.cursorType, "bad config: The custom MouseRat for "..kid.mrType.." has not specified a 'cursorType' field")
        assert(BLIZ_CURSOR_TYPE_BY_NAME[kid.cursorType], "bad config: The custom cursorType for "..kid.mrType.." is not a standard BlizCursorType")

        -- custom types are expected handle specific instances of BlizCursorType
        self:addMouseRatForCustomizedCursorType(kid)
    else
        -- standard types are not expected to provide "cursorType" field
        if kid.cursorType then
            -- but if they do, it can't be different from their "mrType"
            assert(kid.mrType == kid.cursorType, "bad config: The MouseRat for the standard '"..kid.mrType.."' has also specified cursorType of '"..kid.cursorType.."'")
        else
            -- TODO: do I actually need to do this?
            --kid.cursorType = kid.mrType
        end
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
        if (kid[CGCI] == nil) or (kid[CGCI] == MouseRat.consumeGetCursorInfo) then
            zebug.warn:owner(kid):print("the method",CGCI, "is mandatory and MUST be implemented by the subclass")
        end

        if kid == MrEmpty or kid == MrUnsupported then return end

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
                zebug.warn:owner(kid):print("mrType",kid.mrType, methodName,kid[methodName], "apiName", helpers.helperApi,kid[helpers.helperApi], "valid",valid)
            end
        end
    end)

    if not invalids then
        -- prolly need to either accumulate all errs, or, just fail immediately above
        -- error("blah blah")
    end

end

---@param type MouseRatType
---@return MouseRat
function MouseRatRegistry:getSubClass(type)
    assert(type, "bad arg: 'type' is nil")

    local subClass = self.kids[type]
    if not subClass then
        subClass =  self.kids[MouseRatType.UNSUPPORTED]
    end

    -- TODO: consider self.customizedCursorTypes[type] - the  subClass needs to know if it qualifies to become a "customized" MouseRat... maybe add logic to MouseRat:oneOfUs() ?

    return subClass
end

-- customizedCursorTypes
---@param mr MouseRat
function MouseRatRegistry:addMouseRatForCustomizedCursorType(kid)
    -- custom types must provide the "cursorType" field and it must specify a standard BlizCursorType
    assert(kid.cursorType, "bad config: The custom MouseRat for "..kid.mrType.." has not specified a 'cursorType' field")
    assert(BLIZ_CURSOR_TYPE_BY_NAME[kid.cursorType], "bad config: The custom cursorType for "..kid.mrType.." is not a standard BlizCursorType")
    assert(kid.disambiguator, "bad config: The custom MouseRat for "..kid.mrType.." has not specified a 'disambiguator' method")

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
        zebug.warn:print("mrType", mrType, "kid", kid)
        func(kid)
    end
end

