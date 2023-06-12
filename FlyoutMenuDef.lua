-- FlyoutMenuDef
-- a flyout menu definition
-- data for a single flyout object, its spells/pets/macros/items/etc.  and methods for manipulating that data
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

---@class FlyoutMenuDef -- IntelliJ-EmmyLua annotation
---@field spells table
---@field spellNames table
---@field actionTypes table
---@field mounts table
---@field pets table
---@field macroOwners table
local FlyoutMenuDef = {}
Ufo.FlyoutMenuDef = FlyoutMenuDef

-- FUTURE structure
---@field name string
---@field icon string
---@field btns table

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- "spell" can mean also item, mount, macro, etc.
STRUCT_FLYOUT_DEF = { spells={}, actionTypes={}, mounts={}, spellNames={}, macroOwners={}, pets={} }

NEW_STRUCT_FLYOUT_DEF = { name="", icon="", btns={} }
NEW_STRUCT_FLYOUT_BTN_DEF = { type="", blizType="", spells="", mounts="", spellName="", macroOwner="", pet="", }


-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@returns FlyoutMenuDef
function FlyoutMenuDef:new()
    local newInstance = deepcopy(STRUCT_FLYOUT_DEF)
    setmetatable(newInstance, { __index = FlyoutMenuDef })
    return newInstance
end

function FlyoutMenuDef:oneOfUs(flyoutConfig)
    setmetatable(flyoutConfig, { __index = FlyoutMenuDef })
    return flyoutConfig
end

function FlyoutMenuDef:removeSpell(spellPos)
    if type(spellPos) == "string" then spellPos = tonumber(spellPos) end
    table.remove(self.spells, spellPos)
    table.remove(self.actionTypes, spellPos)
    table.remove(self.mounts, spellPos)
    table.remove(self.spellNames, spellPos)
    table.remove(self.macroOwners, spellPos)
    table.remove(self.pets, spellPos)
end
