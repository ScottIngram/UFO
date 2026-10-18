-- Presets
-- pre-defined, pre-populated UFOs available via the config UI
-- TODO - dynamically, automatically maintain these as new toys/items/spells appear in future patches

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@class Presets -- IntelliJ-EmmyLua annotation
---@field defs table
---@field ids table
Preset = {
    defs = {}, -- defined inside other lua files for each type
    ids = {
        HEARTHSTONE = "HEARTHSTONE",
        MAGE_TELEPORT = "MAGE_TELEPORT",
        MAGE_PORTAL = "MAGE_PORTAL",
        INVTORY_MGMNT = "INVTORY_MGMNT",
        TRADE_SKILLS = "TRADE_SKILLS",
        BUFF = "BUFF",
        RIDE = "RIDE",
        HEAL = "HEAL",
        CURE = "CURE",
        DELVE = "DELVE",
        PARACHUTE = "PARACHUTE",
        VISION = "VISION",

        -- remember to add new entries to index.xml
        -- remember to also add them below :-/
    },
}

Preset.Order = {
    Preset.ids.HEARTHSTONE,
    Preset.ids.MAGE_TELEPORT,
    Preset.ids.MAGE_PORTAL,
    Preset.ids.INVTORY_MGMNT,
    Preset.ids.TRADE_SKILLS,
    Preset.ids.BUFF,
    Preset.ids.RIDE,
    Preset.ids.HEAL,
    Preset.ids.CURE,
    Preset.ids.DELVE,
    Preset.ids.PARACHUTE,
    Preset.ids.VISION,
}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

local isValidated

function validate()
    if isValidated then return true end

    local missingIds = { }
    local missingDefs = {}

    for k,_ in pairs(Preset.ids) do
        missingIds[k] = true
        if not Preset.defs[k] then
            missingDefs[k] = true
        end
    end

    for i, v in ipairs(Preset.Order) do
        missingIds[v] = nil
    end

    if isTableNotEmpty(missingIds) then
        zebug.error:dumpy("Preset.Order is missing members of Preset.Ids", missingIds)
        error("Preset.Order is missing members of Preset.Ids")
    end

    if isTableNotEmpty(missingDefs) then
        zebug.error:dumpy("Preset.Defs is missing some defs", missingDefs)
        error("Preset.Defs is missing some defs.  Scott, remember to update index.xml")
    end

    isValidated = true
    return isValidated
end

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@param callback fun(id:number)
function Preset:forEach(callback)
    validate() -- ensure Order contains all Ids
    for i, id in ipairs(Preset.Order) do
        callback(id)
    end
end

function Preset:install(id)
    local preset = Preset.defs[id]
    -- check if it already exists in catalog, if so, warn & abort.
    local all = FlyoutDefsDb:getAll()
    local ufo = all[id]
    if ufo then
        local array = DB:getOrderedFlyoutIds()
        local where = findElement(array, id)
        -- TODO: popup dialogue
        msgUser("The", preset.name, "UFO already exists in your catalog at position",where,"named", ufo.name, "-- Delete it if you want to create it anew.")
        return
    end

    preset = deepcopy(preset)
    zebug.warn:dumpy("Preset", preset)
    local flyoutDef = FlyoutDefsDb:appendNewOne(preset)
    zebug.warn:dumpy("flyoutDef", flyoutDef)

    -- TODO: if locale is not en_US, replace all of the names

    Catalog:update("PRESET-INSTALL")
end
