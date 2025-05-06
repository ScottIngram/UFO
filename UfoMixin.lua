-- UfoMixIn
-- "base class" with fields and methods to be used in other UFO classes

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Zebug.TRACE)

---@alias UfoType string

------@class UfoMixIn
---@field UfoType string The classname
UfoMixIn = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@param class UfoMixIn
function UfoMixIn:mixInto(class)
    assert (class.ufoType, 'UfoMixIn: the provided class definition is missing its "ufoType" field.')
    assert (not class.isA, 'UfoMixIn: the provided class already has self:isA()')
    deepcopy(self, class)
end

---@param other any the object being evaluate for its UfoType. if any
---@param test table optional - only needed if using the class to compare two other objects to one another
---@return UfoType nil if not a UfoType (and also the test arg is not the same UfoType)
function UfoMixIn:isA(other, test)
    if type(other) ~= "table" then return false end

    if self == UfoMixIn then
        if test then
            if type(test) ~= "table" then return nil end
            return (other.ufoType == test.ufoType) and other.ufoType
        else
            return other.ufoType
        end
    else
        return (other.ufoType == self.ufoType) and other.ufoType
    end

    return nil
end

function UfoMixIn:installMyToString()
    assert(self ~= UfoMixIn, "yeah, no.  fixToString() only works on instances, not the UfoMixIn class itself.")
    assert(self.toString, "can't find self:toString() method.")

    local mt = getmetatable(self)
    if not mt then
        mt = {}
        setmetatable(self, mt)
    end
    mt.__tostring = function()
        return self.toString(self)
    end
end

---@param funcName string name of the method to be overridden
---@param newFunc function reference to the replacement
---@return function the original method so it can be invoked by the new one
function UfoMixIn:override(funcName, newFunc)
    return override(self, funcName, newFunc)
end
