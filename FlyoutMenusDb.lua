-- FlyoutMenusDb
-- unique flyout definitions shown in the config panel
-- TODO: invert the FlyoutMenu data structure
-- TODO: * implement as array of self-contained button objects rather than each button spread across multiple parallel arrays
-- is currently a collection if parallel lists, each containing one param for each button in the menu
-- instead, should be one collection/list of button objects, each containing all params for each button.  ENCAPSULATION FTW!

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(Debug.OUTPUT.WARN)

---@class FlyoutMenusDb -- IntelliJ-EmmyLua annotation
local FlyoutMenusDb = {}
Ufo.FlyoutMenusDb = FlyoutMenusDb

--[[
--TODO: implement as OO

Ufo.FlyoutMenusDb = {}
Ufo.Wormhole(Ufo.FlyoutMenusDb, Ufo) -- now it's FlyoutMenusDb inheriting from Ufo

local flyoutConfig = FlyoutMenusDb:get(flyoutId) -- also :new() :add(flyout); :delete(flyoutId);
local flyoutBtns = flyoutConfig:getButtons()
local flyoutBtn1 = flyoutConfig:getButton(1)
flyoutConfig:addButton(myNewBtn) -- or smarter DWIM behavior that takes a macro or pet or mount etc.  Or the AceBtn ? no.
]]

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@return FlyoutMenuDef
function FlyoutMenusDb:appendNewOne()
    local newFlyoutDef = FlyoutMenuDef:new()
    local flyoutsConfig = self:getAll()
    table.insert(flyoutsConfig, newFlyoutDef)
    return newFlyoutDef
end

function FlyoutMenusDb:howMany()
    local flyouts = self:getAll()
    return #flyouts
end

function FlyoutMenusDb:getAll()
    return UFO_SV_ACCOUNT and UFO_SV_ACCOUNT.flyouts
end

---@return FlyoutMenuDef
function FlyoutMenusDb:get(flyoutId)
    assert(flyoutId and type(flyoutId)=="number", "Bad flyoutId arg.")
    local config = self:getAll()
    assert(config, "Flyouts config structure is abnormal.")
    local flyoutConfig = config[flyoutId]
    --[[DEBUG]] debug.trace:print(flyoutConfig, "No config found for #"..flyoutId)
    local flyoutDef = FlyoutMenuDef:oneOfUs(flyoutConfig)
    return flyoutDef
end

function FlyoutMenusDb:delete(flyoutId)
    if type(flyoutId) == "string" then flyoutId = tonumber(flyoutId) end
    table.remove(self:getAll(), flyoutId)
    -- shift references -- TODO: stop this.  Indices are not a precious resource.  And, this will get really complicated for mixing global & toon
    local placementsForEachSpec = getGermPlacementsConfig()
    --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()","flyoutId",flyoutId)
    --[[DEBUG]] debug.trace:dump(placementsForEachSpec)
    for spec, placementsForSpec in pairs(placementsForEachSpec) do
        --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()", "flyId", flyId, "flyoutId",flyoutId, "spec", spec)
        for btnSlotIndex, flyId in pairs(placementsForSpec) do
            --[[DEBUG]] debug.trace:out(X,X,"deleteFlyout()", "flyId", flyId, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex)
            if flyId == flyoutId then
                placementsForSpec[btnSlotIndex] = nil
            elseif flyId > flyoutId then
                placementsForSpec[btnSlotIndex] = flyId - 1
            end
        end
    end
end
