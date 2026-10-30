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
        NOMZ = "NOMZ",
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
    Preset.ids.NOMZ,
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

function Preset:getDef(id)
    local preset = Preset.defs[id]
    if isFunction(preset) then
        return preset()
    else
        return preset
    end
end

---@param callback fun(id:number)
function Preset:forEach(callback)
    validate() -- ensure Order contains all Ids
    for i, id in ipairs(Preset.Order) do
        callback(id)
    end
end

function Preset:install(id)
    local preset = self:getDef(id)

    -- check if it already exists in catalog, if so, warn & abort.
    local all = FlyoutDefsDb:getAll()
    local ufo = all[id]
    if ufo then
        local array = DB:getOrderedFlyoutIds()
        local where = findElement(array, id)
        -- TODO: popup dialogue
        local msg = sprintf(L10N.cfg.PRESET_UFO_ALREADY_EXISTS, preset.name, where, ufo.name)
        msgUser(msg)
        UfoProxy:pickupUfoOntoCursor(id, "PRESET-ALREADY-EXISTS")
        return
    end

    preset = deepcopy(preset)
    --zebug.warn:dumpy("Preset", preset)
    if isFunction(preset.btns) then
        preset.btns = preset.btns()
    end
    local flyoutDef = FlyoutDefsDb:appendNewOne(preset)
    --zebug.warn:dumpy("flyoutDef", flyoutDef)

    -- TODO: if locale is not en_US, replace all of the names

    Catalog:update("PRESET-INSTALL")
    UfoProxy:pickupUfoOntoCursor(flyoutDef.id, "PRESET-INSTALL")

end

---@return table<number,number> array of spellIds
function Preset:getSpellsFromFlyout(...)
    local spells = {}
    local alreadySeen = {}

    for i = 1, select("#", ...) do
        local flyoutId = select(i, ...)
        local name, description, numSlots, isKnown = _G.GetFlyoutInfo(flyoutId)
        zebug.trace:print("Flyout name",name, "numSlots",numSlots)

        for i = 1, numSlots do
            local spellId, overrideSpellId, isKnown, name, slotSpecId = GetFlyoutSlotInfo(flyoutId, i)
            zebug.trace:print("Flyout name",name, "#",i, "name",name, "isKnown",isKnown, "alreadySeen", alreadySeen[spellId])
            if alreadySeen[spellId] then
                --msgUser("already included ", name)
                zebug.info:mCircle():print("skipping redundant name",name, "spellId",spellId)
            else
                msgUser(L10N.cfg.ADDING, name)
                spells[#spells+1] = {
                    type = ButtonType.SPELL,
                    name = name,
                    spellId = spellId,
                    overrideSpellId = overrideSpellId,
                }
                alreadySeen[spellId] = true
            end
        end
    end

    return spells
end
