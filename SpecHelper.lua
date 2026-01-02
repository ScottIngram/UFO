-- Specialization Helper

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.WARN)

---@class SpecializationHelper -- IntelliJ-EmmyLua annotation
Spec = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local previousSpec
local currentSpec
local appliedSpec

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function Spec:initialize()
    return self:getSpecId()
end

function Spec:getSpecId()
    local newSpec = GetSpecialization() or NON_SPEC_SLOT

    if currentSpec then
        if currentSpec ~= newSpec then
            previousSpec = currentSpec
        end
    end

    currentSpec = newSpec

    if not appliedSpec then
        appliedSpec = currentSpec
    end

    return currentSpec
end

function Spec:hasCurrentSpecBeenApplied()
    assert(appliedSpec, "There is no recorded appliedSpec.  Before calling Spec:hasBeenApplied() please invoke Spec:initialize() prior to any spec changes")
    return self:getSpecId() == appliedSpec
end

function Spec:flagCurrentSpecAsHasBeenApplied()
    appliedSpec = self:getSpecId()
end

---@return Placements
function Spec:getAppliedSpec()
    return appliedSpec
end

---@return Placements
function Spec:getPreviousSpec()
    return previousSpec
end

function Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    return Spec:getCurrentSpecPlacementConfig()[btnSlotIndex]
end

---@return Placements
function Spec:getPreviousSpecPlacementConfig()
    self:getSpecId()
    return self:getPlacementConfig(previousSpec)
end

---@return Placements
function Spec:getCurrentSpecPlacementConfig()
    local specId = self:getSpecId()
    return self:getPlacementConfig(specId)
end

function Spec:replaceCurrentSpecPlacementConfig(newConfig)
    local specId = self:getSpecId()
    local placementsForAllSpecs = DB:getAllSpecsPlacementsConfig()
    placementsForAllSpecs[specId] = newConfig
end

---@return Placements
function Spec:getPlacementConfig(specId)
    if specId == nil then
        zebug.trace:print("exiting due to NIL specId arg... currentSpec",currentSpec, "previousSpec",previousSpec)
        return
    end

    -- the placement of flyouts on the action bars changes from spec to spec
    local placementsForAllSpecs = DB:getAllSpecsPlacementsConfig()
    assert(placementsForAllSpecs, ADDON_NAME..": Oops!  placements config is nil")

    local placementsForTheSpec = placementsForAllSpecs[specId]
    -- is this a never-before-encountered spec? - if so, initialze its config
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 1", placementsForTheSpec)
    if not placementsForTheSpec then -- TODO: identify empty OR nil
        if not previousSpec or specId == previousSpec then
            zebug.info:print("initializing spec. specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec)
            placementsForTheSpec = {}
        else
            -- initialize the new config based on the old one
            placementsForTheSpec = deepcopy(self:getPlacementConfig(previousSpec))
            zebug.info:line(7, "COPYING specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "initialConfig", "result 1b", placementsForTheSpec)
        end
        placementsForAllSpecs[specId] = placementsForTheSpec
    end
    zebug.trace:line(5, "specId",specId, "currentSpec",currentSpec, "previousSpec",previousSpec, "result 2", placementsForTheSpec)
    --debug:dump(result)
    return placementsForTheSpec
end
