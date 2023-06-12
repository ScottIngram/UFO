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

local debug = Debug:new(DEBUG_OUTPUT.WARN)

---@class FlyoutMenuDef -- IntelliJ-EmmyLua annotation
---@field name string
---@field icon string
---@field btns
local FlyoutMenuDef = {}
Ufo.FlyoutMenuDef = FlyoutMenuDef

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
    return deepcopy(STRUCT_FLYOUT_DEF)
end
