-- Specialization Helper

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.WARN)

---@class SpecializationHelper -- IntelliJ-EmmyLua annotation
Spec = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local previousSpec
local currentSpec

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Spec:getSpecId()
    return GetSpecialization() or NON_SPEC_SLOT
end

-- keep track of spec changes so getConfigForSpec() can initialize a brand new config based on the old one
function Spec:recordCurrentSpec()
    local hasChanged
    local newSpec = self:getSpecId()
    zebug.trace:print("recordCurrentSpec()", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
    if currentSpec ~= newSpec then
        local debugLabel = currentSpec and "REASSIGNED" or "Initialized"
        previousSpec = currentSpec
        currentSpec = newSpec
        zebug.trace:print(debugLabel, "->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        hasChanged = true
    else
        zebug.trace:print("unchanged ->", "newSpec",newSpec, "currentSpec",currentSpec, "previousSpec",previousSpec)
        hasChanged = false
    end
    return hasChanged
end

function Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    return Spec:getPlacementConfigForCurrentSpec()[btnSlotIndex]
end

function Spec:getPlacementConfigForCurrentSpec()
    self:recordCurrentSpec()
    local specId = self:getSpecId()
    return self:getConfigForSpec(specId)
end

function Spec:getConfigForSpec(specId)
    -- the placement of flyouts on the action bars changes from spec to spec
    local placementsForAllSpecs = DB:getAllSpecsPlacementsConfig()
    assert(placementsForAllSpecs, ADDON_NAME..": Oops!  placements config is nil")

    local result = placementsForAllSpecs[specId]
    -- is this a never-before-encountered spec? - if so, initialze its config
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 1",result)
    if not result then -- TODO: identify empty OR nil
        if not previousSpec or specId == previousSpec then
            zebug:print("blanking specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec)
            result = {}
        else
            -- initialize the new config based on the old one
            result = deepcopy(self:getConfigForSpec(previousSpec))
            zebug:line(7, "COPYING specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "initialConfig", "result 1b",result)
        end
        placementsForAllSpecs[specId] = result
    end
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 2",result)
    --debug:dump(result)
    return result
end
