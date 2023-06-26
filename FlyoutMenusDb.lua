-- FlyoutMenusDb
-- unique flyout definitions shown in the config panel
-- TODO: stop reclaiming flyout indices when one is deleted - let the index be its unique, permanent ID. - OR...
-- yes, put a unique ID inside the flyoutMenuDef that is NOT its index in the array.  Then, *maintain* an index of the ids

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

---@class FlyoutMenusDb -- IntelliJ-EmmyLua annotation
local FlyoutMenusDb = {
    isInitialized = false
}
Ufo.FlyoutMenusDb = FlyoutMenusDb

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function FlyoutMenusDb:howMany()
    local flyouts = self:getAll()
    return #flyouts
end

function FlyoutMenusDb:forEachFlyoutConfig(callback)
    local allFlyouts = Config:getFlyoutsConfig()
    for i, flyoutConfig in ipairs(allFlyouts) do
        debug.info:out(".",3,"FlyoutMenusDb:forEachFlyoutConfig()", "i",i, "flyoutConfig",flyoutConfig)
        callback(flyoutConfig,flyoutConfig) -- support both functions and methods (which expects 1st arg as self and 2nd arg as the actual arg)
    end
end

function FlyoutMenusDb:getAll()
    debug.info:out("A",3,"FlyoutMenusDb:getAll()...")
    local allFlyouts = Config:getFlyoutsConfig()
    debug.info:out("A",3,"FlyoutMenusDb:getAll()", "allFlyouts", allFlyouts)
    if not self.isInitialized then
        FlyoutMenusDb:forEachFlyoutConfig(FlyoutMenuDef.oneOfUs)
        self.isInitialized = true
    end
    return allFlyouts
end

---@return FlyoutMenuDef
function FlyoutMenusDb:get(flyoutId)
    flyoutId = tonumber(flyoutId)
    assert(flyoutId, ADDON_NAME..": The flyoutId arg is empty.")
    local config = self:getAll()
    assert(config, ADDON_NAME..": Flyouts config structure is abnormal.")
    local flyoutConfig = config[flyoutId]
    debug.trace:out("B",3,"FlyoutMenusDb:get()", "flyoutConfig",flyoutConfig)

    if not flyoutConfig then
        debug.warn:print(flyoutConfig, "No config found for #"..flyoutId)
        return nil
    end

    return flyoutConfig
end

---@return FlyoutMenuDef
function FlyoutMenusDb:appendNewOne()
    local newFlyoutDef = FlyoutMenuDef:new()
    local flyoutsConfig = self:getAll()
    table.insert(flyoutsConfig, newFlyoutDef)
    return newFlyoutDef
end

---@param flyoutMenuDef FlyoutMenuDef -- IntelliJ-EmmyLua annotation
function FlyoutMenusDb:add(flyoutMenuDef)
    table.insert(self:getAll(), flyoutMenuDef)
end

function FlyoutMenusDb:delete(flyoutId)
    local debug = debug.trace:setHeader("#","FlyoutMenusDb:delete")
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    table.remove(self:getAll(), flyoutId)
    -- shift references -- TODO: stop this.  Indices are not a precious resource.  And, this will get really complicated for mixing global & toon
    local placementsForEachSpec = GermCommander:getAllSpecsPlacementsConfig()
    --debug:line(5, "flyoutId",flyoutId)
    --debug:dump(placementsForEachSpec)
    for spec, placementsForSpec in pairs(placementsForEachSpec) do
        debug:line(5, "flyoutId",flyoutId, "spec",spec)
        for btnSlotIndex, flyId in pairs(placementsForSpec) do
            debug:line(5, "flyId",flyId, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex)
            if flyId == flyoutId then
                placementsForSpec[btnSlotIndex] = nil
            elseif flyId > flyoutId then
                placementsForSpec[btnSlotIndex] = flyId - 1
            end
        end
    end
end

-- TODO: use this one instead?
-- converts the previous config format into the new one
---@param flyoutId number -- IntelliJ-EmmyLua annotation
function FlyoutMenusDb:NEW_delete(flyoutId)
    -- leave an empty placeholder
    -- so the array stays an array of contiguous indices
    -- and every flyout always keeps its original ID
    self:getAll()[tonumber(flyoutId)] = false
end

-- TODO: delete after dev is done
function FlyoutMenusDb:convertOldToNew()
    debug.trace:out("+",40,"FlyoutMenusDb:convertOldToNew()")
    local old = UFO_SV_ACCOUNT.OLD_flyouts
    Config:tmpNeoNuke()

    for i, oldFlyout in ipairs(old) do
        local neoFlyout = FlyoutMenuDef:new()
        neoFlyout.icon = oldFlyout.icon
        FlyoutMenusDb:add(neoFlyout)

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
