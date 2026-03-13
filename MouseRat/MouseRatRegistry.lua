---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = MouseRat.zebug -- Zebug:new(--[[Z_VOLUME_GLOBAL_OVERRIDE or]] Zebug.TRACE)

-------------------------------------------------------------------------------
-- MouseRatRegistry
-- records & wrangles MouseRat subclasses (and instantiates them?)
-------------------------------------------------------------------------------
---@class MouseRatRegistry : UfoMixIn
---@field ufoType string
---@field kids table<MouseRatType,MouseRat>
---@field customizedCursorTypes table<MouseRatType,table<>>
---@field customizedAbbTypes table<MouseRatTypeForActionBarButton,table<>>
MouseRatRegistry = {
    ufoType = "MouseRatRegistry",
    kids = {},
    customizedCursorTypes = {},
    customizedAbbTypes = {},
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
    local isCustomCursor = kid.cursorType and (kid.cursorType ~= kid.type)
    if isCustomCursor then
        self:addMouseRatForCustomizedCursorType(kid)
    end
    local isCustomAbb = kid.abbType and (kid.abbType ~= kid.type)
    if isCustomAbb then
        self:addMouseRatForCustomizedAbb(kid)
    end

    MouseRat:adopt(kid) -- activate OO inheritance

    self.kids[kid.type] = kid
end

function MouseRatRegistry:init()
    MouseRatRegistry:forEachKid(MouseRatRegistry.validateKid)
end

---@param kid MouseRat
function MouseRatRegistry:validateKid(kid)
    --local invalids
    for i, methodName in ipairs(MouseRatMethodsContract) do
        local valid
        local method = kid[methodName]
        local helper = kid.helpers and kid.helpers[methodName]
        local isTheHelperThere = (helper ~= nil) -- allow false but not nil
        local isMethodDefaultBaseImpl = (method == MouseRat[methodName])
        local isDefaultGoodEnoughByItself = (methodName == MouseRatMethodsContract.getName) or (methodName == MouseRatMethodsContract.canThisToonPickup)

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
                kid.helpers[methodName] = function() zebug.error:owner(kid):print(methodName,"method & helper are both missing.  Defaulting val to nil") return nil end
            end
        else
            --zebug.error:owner(kid):print("type",kid.type, "must implement a method",methodName, "or define a helper method/field", methodName)
            --if not invalids then invalids = {} end
            --invalids[#invalids+1] = kid.type
        end
    end
    --return invalids
end

---@param confirmedType MouseRatType determined to be the actual type and not an ambiguous value returned from a Bliz API
---@return MouseRat|nil will be nil if the given type has not been registered
function MouseRatRegistry:getSubClassForTrustedType(confirmedType)
    assert(confirmedType, "bad arg: 'type' is nil")
    local subClass = self.kids[confirmedType]
    return subClass
end

-- is the type from _G.GetCursorInfo() a big fat fucking lie?
-- analyze the API's data and decide if one of MouseRat's "customized" sub-subClass is a better fit for this type.
---@param type MouseRatType|nil (optional) the 1st value returned by _G.GetCursorInfo()
---@param c2 number|string|nil (optional) the 2nd value from _G.GetCursorInfo()
---@param c3 number|string|nil (optional) the 3rd value from _G.GetCursorInfo()
---@param c4 number|string|nil (optional) the 4th value from _G.GetCursorInfo()
---@return MouseRat|nil the expected MouseRat, or a different MouseRat subclass from what the "type" suggests, or nil if none exists
function MouseRatRegistry:findSubClassForThisUnreliableData(type, c2, c3, c4)

    local subClass = self.kids[type]
    if not subClass then return nil end

    local subSubClasses = MouseRatRegistry.customizedCursorTypes[type]
    if not subSubClasses then return subClass end

    --zebug.warn:event():owner(subClass):dumpKeys(customMouseRatsForThisType)
    ---@param subSubMr MouseRat
    for i, subSubMr in ipairs(subSubClasses) do
        local isQualified = subSubMr:disambiguator(type, c2, c3, c4)
        zebug.warn:event():print("disambiguator! is this type", type," actually", subSubMr.type, "?",isQualified)
        if isQualified then
            -- first one wins!  assume only one custom class will qualify
            -- replace the previous subClass with the custom one we found
            zebug.warn:event():print("BLIZ API LIED.  the type wasn't really", type, "IT WAS ACTUALLY", subSubMr.type)
            subClass = subSubMr
            break
        end
    end

    return subClass
end

---@param kid MouseRat
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

---@param kid MouseRat
function MouseRatRegistry:addMouseRatForCustomizedAbb(kid)
    local regKey = "customizedAbbTypes"
    local configKey = "abbType"
    -- custom types must provide the "cursorType" field and it must specify a standard BlizCursorType
    assert(kid[configKey], "bad config: The custom MouseRat for "..kid.type.." has not specified a '..key..' field")
    assert(MOUSE_RAT_ACTION_BAR_BUTTON_TYPE_FOR_BUTTON_NAME[kid[configKey]], "bad config: The custom '"..kid.type.."' -> '"..kid[configKey].."' ".. configKey .." is not standard")
    assert(kid.disamButtonGator, "bad config: The custom MouseRat for "..kid.type.." -> "..kid[configKey].." has not specified a 'disamButtonGator' method")

    if not self[regKey][kid[configKey]] then
        self[regKey][kid[configKey]] = {}
    end

    table.insert(self[regKey][kid[configKey]], kid)
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

