-- UfoMixIn
-- "base class" with fields and methods to be used in other UFO classes

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.TRACE)

---@alias UfoType string

---@class UfoMixIn
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

local seen = {}

function UfoMixIn:installMyToString()
    assert(self ~= UfoMixIn, "yeah, no.  I think you accidentally called UfoMixIn:installMyToString(otherObj).  Change the ':' to a '.'")
    assert(self.toString, "can't find self:toString() method.")

    local originalMt = getmetatable(self)
    local newMt

    if originalMt then
        if seen[originalMt] then
            zebug.trace:mStar():print("REPEATED mt found on ufoType",self.ufoType, --[["self:toString()",self:toString(),]] "originalMt.ufoType",originalMt.ufoType, "__tostring", originalMt.__tostring)
            zebug.trace:mStar():dumpKeys(originalMt)
        end
        seen[originalMt] = true

        if originalMt.__tostring then
            zebug.info:mark(Mark.FIRE):print("ruhroh - __tostring already EXISTS from", originalMt.ufoType, "self.ufoType",self.ufoType, self)
        end

        -- create a distinctly new but "identical" metatable so it can hold the toString
        -- this would/will be a problem if the metatable has anything more than __index
        newMt = { __index = originalMt.__index }
    else
        zebug.trace:print("no mt on self",self , "ufoType",self.ufoType )
        newMt = {}
    end

    newMt.ufoType = self.ufoType
    newMt.__tostring = self.toString
    setmetatable(self, newMt)
    zebug.trace:print("installMyToString",self , "ufoType",self.ufoType )
end

---@param funcName string name of the method to be overridden
---@param newFunc function reference to the replacement
---@return function the original method so it can be invoked by the new one
function UfoMixIn:override(funcName, newFunc)
    return override(self, funcName, newFunc)
end

---@param type string
---@param id number
---@return string the name of the spell/mount/toy/etc
function UfoMixIn:getNameForBlizThingy(type, id)
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
        zebug.warn:print("Unknown type", type)
    end

    return name
end

function UfoMixIn:setSecEnvAttribute(key, value)
    self:SetAttribute(key, value)
end

UfoMixIn.safelySetSecEnvAttribute = Pacifier:wrap(UfoMixIn.setSecEnvAttribute) -- allow only out of combat

function UfoMixIn:assignSecEnvMouseClickBehaviorViaAttribute(mouseClick, value)
    self:setSecEnvAttribute(MouseClickAsSecEnvId[mouseClick], value)
end

---@param loopGuard table|nil tracks each object to have participated in the loop, or nil if nothing
---@return table|nil the tracking table, or, nil when it sees the current object has already participated and thus we're in an infiinite loop
function UfoMixIn:notInfiniteLoop(loopGuard)
    if not loopGuard then
        loopGuard = {  }
    else
        if loopGuard[self] then return nil end -- ABORT !!!
    end
    loopGuard[self] = true
    return loopGuard
end

function UfoMixIn:getParentAndName()
    local p = self:GetParent()
    return p, p and p.GetName and p:GetName()
end

