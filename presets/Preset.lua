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

local RETAIL_ORDER = {
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

local FOREVER_ORDER = {
    Preset.ids.HEARTHSTONE,
    Preset.ids.TRADE_SKILLS,
    Preset.ids.BUFF,
    Preset.ids.RIDE,
    Preset.ids.HEAL,
    Preset.ids.CURE,
    Preset.ids.PARACHUTE,
    Preset.ids.VISION,
}

Preset.Order = isForever() and FOREVER_ORDER or RETAIL_ORDER

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

    if (not isForever()) and isTableNotEmpty(missingIds) then
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

    preset = deepcopy(preset)
    if isFunction(preset.btns) then
        preset.btns = preset.btns()
        if not preset.btns then
            return
        end
    end

    local flyoutDef = FlyoutDef:oneOfUs(preset)
    Preset:discardIfForWrongGameVersion(flyoutDef)

    -- check if it already exists in catalog
    local all = FlyoutDefsDb:getAll()
    ---@type FlyoutDef
    local theUfo = all[id]
    if theUfo then
        local allUfoIds = DB:getOrderedFlyoutIds()
        local where = findElement(allUfoIds, id)

        Preset:stripRedundantButtons(flyoutDef, theUfo)

        if flyoutDef:howManyButtons() == 0 then
            -- all the preset buttons are already on the existing UFO
            local msg = sprintf(L10N.cfg.PRESET_UFO_ALREADY_EXISTS_DELETE, flyoutDef.name, where, theUfo.name)
            msgUser(msg)
            zebug.trace:owner(self):dumpy("EMPTY!", flyoutDef)
        else
            -- some of the preset buttons are missing from the existing UFO
            local msg = sprintf(L10N.cfg.PRESET_UFO_ALREADY_EXISTS_MERGE, flyoutDef.name, where, theUfo.name)
            msgUser(msg)
            zebug.trace:owner(self):dumpy("remaining", flyoutDef)
            -- merge the missing buttons into the existing UFO
            ---@param btnDef ButtonDef
            flyoutDef:forEachBtn(function(btnDef)
                msgUser(L10N.cfg.ADDING, btnDef:getName())
                theUfo:addButton(btnDef)
            end)
        end

    else
        newDef = FlyoutDefsDb:appendNewOne(flyoutDef)
    end

    --zebug.warn:dumpy("flyoutDef", flyoutDef)

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

        zebug.info:print("Flyout name",name, "description",description, "numSlots",numSlots)

        for i = 1, numSlots do
            local spellId, overrideSpellId, isKnown, name, slotSpecId = GetFlyoutSlotInfo(flyoutId, i)
            zebug.trace:print("Flyout name",name, "#",i, "name",name, "isKnown",isKnown, "alreadySeen", alreadySeen[spellId])
            if alreadySeen[spellId] then
                --msgUser("already included ", name)
                zebug.info:mCircle():print("skipping redundant name",name, "spellId",spellId)
            else
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

-- use the the Bliz APIs to pre-load  all the names and icons for every button and discard those invalid for this version of WoW
---@param flyoutDef FlyoutDef
function Preset:discardIfForWrongGameVersion(flyoutDef)
    assert(UfoMixIn:isA(flyoutDef, FlyoutDef), "usage: Preset:cleanse(flyoutDef)")

    ---@param btnDef ButtonDef
    flyoutDef:batchDeleteBtns(function(btnDef)
        if btnDef:getIcon() == nil then
            return true
        else
            local name = btnDef:getName()
            if (name == nil) or (name == "UnKnOwN!") then
                return true
            end
        end
        zebug.info:owner(btnDef):print("adding!")
    end)

    return flyoutDef
end

---@param presetFlyoutDef FlyoutDef
---@param oldFlyoutDef FlyoutDef
function Preset:stripRedundantButtons(presetFlyoutDef, oldFlyoutDef)
    assert(UfoMixIn:isA(presetFlyoutDef, FlyoutDef), "usage: Preset:disjoint(presetFlyoutDef, oldFlyoutDef)")

    -- if the old, existing UFO already contains a button on the new preset, then delete it from the preset.
    ---@param newBtnDef ButtonDef
    presetFlyoutDef:batchDeleteBtns(function(newBtnDef)
        if oldFlyoutDef:hasBtn(newBtnDef) then
            zebug.info:owner(presetFlyoutDef):print("discarding",newBtnDef:toString())
            return true
        end
        zebug.info:owner(presetFlyoutDef):print("preserving",newBtnDef:toString())
    end)

    return presetFlyoutDef
end

