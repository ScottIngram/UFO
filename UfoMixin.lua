-- UfoMixIn
-- "base class" with fields and methods to be used in other UFO classes

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
zVol = Zebug.ERROR
local zebug = Zebug:new(zVol or Zebug.TRACE)

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
    --assert(self ~= UfoMixIn, "yeah, no.  fixToString() only works on instances, not the UfoMixIn class itself.")
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

function UfoMixIn:newEvent(...)
    return Event:new(self, ...)
end

---@param id number
---@param type string
---@return string the name of the spell/mount/toy/etc
function UfoMixIn:getNameForBlizThingy(id, type)
    local name
    if type == ButtonType.SPELL or type == ButtonType.MOUNT or type == ButtonType.PSPELL then
        local foo = C_Spell.GetSpellInfo(id)
        name = foo and foo.name
    elseif type == ButtonType.ITEM or type == ButtonType.TOY then
        name =  C_Item.GetItemInfo(id)
    elseif type == ButtonType.TOY then
        name =  C_Item.GetItemInfo(id)
    elseif type == ButtonType.MACRO then
        name =  GetMacroInfo(id)
        name = name or "BlizBullshit"
    elseif type == ButtonType.PET then
        name =  getPetNameAndIcon(id) -- from UFO's BtnDef.lua
    elseif type == ButtonType.BROKENP or type == ButtonType.PSPELL then
        name = "Some Pet Command" -- BrokenPetCommand[self.brokenPetCommandId].name -- from UFO's PetShitShow.lua
    else
        zebug.warn:print("Unknown type:", type)
    end

    return name
end
