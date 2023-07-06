-- FlyoutDefsDb
-- unique flyout definitions shown in the config panel
-- TODO: stop reclaiming flyout indices when one is deleted - let the index be its unique, permanent ID. - OR...
-- yes, put a unique ID inside the flyoutDef that is NOT its index in the array.  Then, *maintain* an index of the ids

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.OUTPUT.WARN)

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

-------------------------------------------------------------------------------
-- FlyoutDefsDb Methods
-------------------------------------------------------------------------------

function FlyoutDefsDb:howMany()
    local list = Config:getOrderedFlyoutIds()
    return #list
end

function FlyoutDefsDb:forEachFlyoutConfig(callback)
    zebug.trace:out(25,"~")
    for flyoutId, flyoutDef in pairs(Config:getFlyoutDefs()) do
        zebug.trace:out(20,"~", "flyoutId",flyoutId, "--> flyoutDef", flyoutDef)
        callback(flyoutDef, flyoutDef) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
    end
end

function FlyoutDefsDb:getAll()
    zebug.trace:out(30,"=")
    local allFlyouts = Config:getFlyoutDefs()
    zebug.trace:out(10,"=", "allFlyouts", allFlyouts, "self.isInitialized", self.isInitialized)
    if not self.isInitialized then
        FlyoutDefsDb:forEachFlyoutConfig(FlyoutDef.oneOfUs)
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
    zebug.info:print("flyoutIndex",flyoutIndex)
    if type(flyoutIndex) ~= "number" then
        local isNumber
        local ok = pcall(function() isNumber = tonumber(flyoutIndex) end)
        if not isNumber then
            error("Arg 'flyoutIndex' must be numeric, not: " .. (flyoutIndex or "nil"), 2)
        end
    end

    local flyoutId = Config:getOrderedFlyoutIds()[flyoutIndex]
    zebug.info:print("flyoutIndex",flyoutIndex, "--> flyoutId",flyoutId)
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

---@return table
function Xedni:get()
    if not Xedni.lookup then
        Xedni.lookup = {}
        local ids = UFO_SV_ACCOUNT.orderedFlyoutIds
        zebug.info:dumpy("orderedFlyoutIds",ids)
        for i, id in ipairs(ids) do
            zebug.trace:print("i",i, "id",id)
            Xedni.lookup[id] = i
        end
    end
    return Xedni.lookup
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

-------------------------------------------------------------------------------
-- Version migration: FloFlyout -> UFO alpha1
-------------------------------------------------------------------------------

-- TODO: delete after dev is done
function FlyoutDefsDb:convertFloFlyoutToUfoAlpha1()
    zebug.trace:line(40)
    local old = UFO_SV_ACCOUNT.OLD_flyouts
    Config:nuke_a1()

    for i, oldFlyout in ipairs(old) do
        local neoFlyout = FlyoutDef:new()
        neoFlyout.icon = oldFlyout.icon
        FlyoutDefsDb:add(neoFlyout)

        for j, type in ipairs(oldFlyout.actionTypes) do
            local mount = oldFlyout.mounts[j]
            if mount then
                local _, _, _, _, _, _, _, _, _, _, _, mountID = C_MountJournal.GetDisplayedMountInfo(mount)
                mount = mountID or mount
            end

            local btn = ButtonDef:new()
            local isMount = oldFlyout.mounts[j] and true
            btn.type       = isMount and ButtonType.MOUNT or type
            btn.name       = oldFlyout.spellNames[j]
            btn.spellId    = (type == ButtonType.SPELL) and oldFlyout.spells[j] or nil
            btn.itemId     = (type == ButtonType.ITEM) and oldFlyout.spells[j] or nil
            btn.mountId    = mount
            btn.petGuid    = oldFlyout.pets[j]
            btn.macroId    = (type == ButtonType.MACRO) and oldFlyout.spells[j] or nil
            btn.macroOwner = oldFlyout.macroOwners[j]

            neoFlyout:addButton(btn)
        end
    end
end

-------------------------------------------------------------------------------
-- Version migration: UFO alpha1 -> UFO alpha2
-------------------------------------------------------------------------------

local max = 99999

-- TODO: delete after dev is done
function FlyoutDefsDb:convertfoAlpha1ToUfoAlpha2()
    zebug.trace:line(40)
    Config:nuke_a2()

    local a1 = UFO_SV_ACCOUNT.flyouts
    local a2 = UFO_SV_ACCOUNT.flyouts_a2
    local i2 = UFO_SV_ACCOUNT.orderedFlyoutIds
    --local x2 = UFO_SV_ACCOUNT.xedni
    local p1 = UFO_SV_TOON.placementsForAllSpecs
    local p2 = UFO_SV_TOON.placementsForAllSpecs_a2

    -- make a copy of the existing flyouts.  add the new ID into each.
    for i, a1_flyoutDef in ipairs(a1) do
        if i > max then break end
        local a2_flyoutDef = deepcopy(a1_flyoutDef)
        local id = FlyoutDef:newId()
        a2_flyoutDef.id = id
        a2[id] = a2_flyoutDef
        i2[i] = id
        --x2[id] = i
    end

    -- now fix the placements, translating each flyoutIndex into the new flyoutId
    for specId, pDef in pairs(p1) do
        p2[specId] = {}
        for slotId, flyoutIndex in pairs(pDef) do
            local flyoutId = i2[flyoutIndex]
            p2[specId][slotId] = flyoutId
        end
    end

    self.isInitialized = false -- the flag to trigger OO coercion in getAll()
end

function FlyoutDefsDb:convertfoAlpha1PlacementsToUfoAlpha2()
    local p1 = UFO_SV_TOON.placementsForAllSpecs
    local p2 = UFO_SV_TOON.placementsForAllSpecs_a2
    local i2 = UFO_SV_ACCOUNT.orderedFlyoutIds

    -- now fix the placements, translating each flyoutIndex into the new flyoutId
    for specId, pDef in pairs(p1) do
        p2[specId] = {}
        for slotId, flyoutIndex in pairs(pDef) do
            local flyoutId = i2[flyoutIndex]
            zebug.error:print("flyoutIndex",flyoutIndex, "flyoutId",flyoutId)
            p2[specId][slotId] = flyoutId
        end
    end
end
