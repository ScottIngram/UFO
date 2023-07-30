-- FlyoutDefsDb
-- unique flyout definitions shown in the config panel

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

-------------------------------------------------------------------------------
-- Class: FlyoutDefsDb
-------------------------------------------------------------------------------

---@class FlyoutDefsDb -- IntelliJ-EmmyLua annotation
local FlyoutDefsDb = {
    isInitialized = false
}
Ufo.FlyoutDefsDb = FlyoutDefsDb

-------------------------------------------------------------------------------
-- Class: Xedni
-------------------------------------------------------------------------------

---@class Xedni -- IntelliJ-EmmyLua annotation
local Xedni = { }
Ufo.Xedni = Xedni

-------------------------------------------------------------------------------
-- FlyoutDefsDb Methods
-------------------------------------------------------------------------------

function FlyoutDefsDb:howMany()
    local list = Config:getOrderedFlyoutIds()
    return list and #list or 0
end

function FlyoutDefsDb:forEachFlyoutDef(callback)
    zebug.trace:out(25,"~")
    for i, flyoutId in ipairs(Config:getOrderedFlyoutIds()) do
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        zebug.trace:out(20,"~", "flyoutId",flyoutId, "--> flyoutDef", flyoutDef)
        callback(flyoutDef, flyoutDef) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
    end
end

function FlyoutDefsDb:getAll()
    zebug.trace:out(30,"=")
    local allFlyouts = Config:getFlyoutDefs()
    zebug.trace:out(10,"=", "allFlyouts", allFlyouts, "self.isInitialized", self.isInitialized, "self.infiniteLoopStopper",self.infiniteLoopStopper)
    if not self.isInitialized and not self.infiniteLoopStopper then
        self.infiniteLoopStopper = true
        FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.oneOfUs)
        self.infiniteLoopStopper = false
        self.isInitialized = true
    end
    return allFlyouts
end

local msgBeString = "Arg 'flyoutId' must be a string, not: "
local frameStackSkip = 2 -- despite the implications of a numeric value, Lua doesn't recognize anything other than 1 or 2. ¯\_(ツ)_/¯

---@param flyoutId string
---@return string
function FlyoutDefsDb:validateFlyoutId(flyoutId)
    if type(flyoutId) ~= "string" then
        error(msgBeString .. (flyoutId or "nil"), frameStackSkip)
    end
    if isEmpty(flyoutId) then
        error("The flyoutId arg is empty." .. (flyoutId or "nil"), frameStackSkip)
    end
    return flyoutId
end

---@param flyoutId string
---@return string
function FlyoutDefsDb:reValidateFlyoutId(flyoutId)
    local isNumber
    local ok = pcall(function() isNumber = tonumber(flyoutId) end)
    if isNumber then
        error(msgBeString .. (flyoutId or "nil"), frameStackSkip)
    end
    return flyoutId
end

---@return FlyoutDef
---@param flyoutId string
function FlyoutDefsDb:get(flyoutId)
    zebug.trace:line(40)
    flyoutId = self:validateFlyoutId(flyoutId)

    ---@type FlyoutDef
    local flyoutDef = self:getAll()[flyoutId]
    zebug.trace:print("flyoutId",flyoutId, "flyoutDef", flyoutDef)

    if not flyoutDef then
        -- double check that the incoming arg wasn't a number hiding in a string variable
        flyoutId = self:reValidateFlyoutId(flyoutId)

        -- Ok, the arg was ok, but, the flyout just isn't there.
        -- Merely report it: don't throw it as an error.
        -- Why?  Because a different toon could have deleted it and that's ok.
        zebug.warn:print("FYI, No config found for #",flyoutId) -- TODO - only report the first occurrence of any specific flyoutId
        return nil
    end
    zebug.trace:print("flyoutConfig", flyoutDef, "flyoutDef.name",flyoutDef.name, "flyoutDef.id",flyoutDef.id )

    return flyoutDef
end

---@param flyoutIndex number
function FlyoutDefsDb:getByIndex(flyoutIndex)
    zebug.trace:print("flyoutIndex",flyoutIndex)
    if type(flyoutIndex) ~= "number" then
        local isNumber
        local ok = pcall(function() isNumber = tonumber(flyoutIndex) end)
        if not isNumber then
            error("Arg 'flyoutIndex' must be numeric, not: " .. (flyoutIndex or "nil"), 2)
        end
    end

    local flyoutId = Config:getOrderedFlyoutIds()[flyoutIndex]
    zebug.trace:print("flyoutIndex",flyoutIndex, "--> flyoutId",flyoutId)
    return self:get(flyoutId)
end

---@return FlyoutDef
function FlyoutDefsDb:appendNewOne()
    local newDef = FlyoutDef:new()
    newDef.id = newDef:newId() -- unlike germs, new flyouts in the catalog are given an ID because they are persisted to SAVED_VARs
    self:add(newDef)
    return newDef
end

---@param flyoutDef FlyoutDef -- IntelliJ-EmmyLua annotation
function FlyoutDefsDb:add(flyoutDef)
    local flyoutId = flyoutDef.id
    self:getAll()[flyoutId] = flyoutDef

    -- keep the index and the reverse index in sync
    local list = Config:getOrderedFlyoutIds()
    local i = #list + 1
    list[i] = flyoutId
    Xedni:get()[flyoutDef.id] = i
end

-- erases the flyout def
-- compresses the index
-- updates the index's reverse index (Xedni)
---@param flyoutId string Unique, immutable ID.  This is not it's index in any array.
function FlyoutDefsDb:delete(flyoutId)
    flyoutId = self:validateFlyoutId(flyoutId)
    local flyoutDefs = self:getAll()
    local xedni = Xedni:get()
    local flyoutIndex = xedni[flyoutId] -- grab it before we erase it

    -- remove it from the flyoutDefs and reverseIndex hash tables
    zebug.trace:dumpy("flyoutDefs B4 delete", flyoutDefs)
    flyoutDefs[flyoutId] = nil
    zebug.trace:dumpy("flyoutDefs AFTER delete", flyoutDefs)

    -- remove it from some arbitrary point in the orderedFlyoutIds "array"
    -- luckily, we have a reverse index array (Xedni) to find its index :-)
    zebug.info:print("flyoutId",flyoutId, "removing at flyoutIndex", flyoutIndex)
    local flyoutList = Config:getOrderedFlyoutIds()
    zebug.info:dumpy("list B4 delete", flyoutList)
    local mort = table.remove(flyoutList, flyoutIndex)
    zebug.info:dumpy("list AFTER delete", flyoutList)
    zebug.info:print("killed ->",mort)

    Xedni:moveOrRemove(flyoutId)

    -- remove it from every placement
    local placementsForEachSpec = GermCommander:getAllSpecsPlacementsConfig()
    for spec, placementsForSpec in pairs(placementsForEachSpec) do
        zebug.trace:line(5, "flyoutId",flyoutId, "spec",spec)
        for btnSlotIndex, flyId in pairs(placementsForSpec) do
            zebug.trace:line(5, "flyId",flyId, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex)
            if flyId == flyoutId then
                placementsForSpec[btnSlotIndex] = nil
            end
        end
    end
end

function FlyoutDefsDb:move(flyoutId, destinationIndex)
    local xedni = Xedni:get()
    local flyoutIndex = xedni[flyoutId]
    local flyoutList = Config:getOrderedFlyoutIds()
    local moved = moveElementInArray(flyoutList, flyoutIndex, destinationIndex)
    if moved then
        Xedni:nuke() -- TODO: do something more elegant than erasing the old one
    end
end

function Xedni:nuke()
    Xedni.lookup = nil
end

---@return table
function Xedni:get()
    if not Xedni.lookup then
        Xedni.lookup = {}
        local ids = UFO_SV_ACCOUNT.orderedFlyoutIds
        zebug.trace:dumpy("orderedFlyoutIds",ids)
        for i, id in ipairs(ids) do
            zebug.trace:print("i",i, "id",id)
            Xedni.lookup[id] = i
        end
    end
    return Xedni.lookup
end

function Xedni:getFlyoutDef(flyoutId)
    return self:get()[flyoutId]
end

-- corrects the Xedni after a change in the flyout ordering.
-- call this only after the other maps have been changed
---@param instigatingFlyoutId string
function Xedni:moveOrRemove(instigatingFlyoutId)
    local indicesMap = Xedni.lookup
    local instigatingIndex = indicesMap[instigatingFlyoutId]

    zebug.info:dumpy("Xedni B4 alteration", indicesMap)

    -- remove the entry
    indicesMap[instigatingFlyoutId] = nil

    -- If a flyout is added/deleted from anywhere but the end,
    -- then some/all of the reverse index is now off by 1.
    local orderedIds = Config:getOrderedFlyoutIds()
    local size = #orderedIds

    -- go through the remaining entries and lookup their new index
    local start = instigatingIndex -- if start > size then the instigating action was deleting the last entry
    for i=start, size do
        local flyoutId = orderedIds[i]
        zebug.info:print("flyoutId", instigatingFlyoutId, "index", instigatingIndex, "start",start, "resetting flyoutId",flyoutId, "to i",i)
        indicesMap[flyoutId] = i
    end

    zebug.info:dumpy("Xedni AFTER alteration", indicesMap)
end
