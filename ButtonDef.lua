-- ButtonDef
-- data for a single button, its spell/pet/macro/item/etc.  and methods for manipulating that data

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(DEBUG_OUTPUT.WARN)

--[[
            -- from Germ.lua
            -- fields recognized by Bliz internal UI code
            buttonFrame.spellID = spellId
            buttonFrame.itemID = itemId
            buttonFrame.actionID = spellId
            buttonFrame.actionType = type
            buttonFrame.battlepet = pet
--]]

---@class ButtonType -- IntelliJ-EmmyLua annotation
local ButtonType = {
    spell = "spell",
    item = "spell",
    mount = "spell",
    pet = "battlepet",
    macro = "spell",

}
Ufo.ButtonType = ButtonType

---@class ButtonDef -- IntelliJ-EmmyLua annotation
---@field type ButtonType
---@field name string
---@field spellId number
---@field itemId number
---@field mountId number
---@field petGuid string
---@field macroId number
---@field macroOwner string
local ButtonDef = {}
Ufo.ButtonDef = ButtonDef

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

NEW_STRUCT_FLYOUT_BTN_DEF = {
    type="",
    name="",
    spellId="",
    itemId="",
    mountId="",
    petGuid="",
    macroId="",
    macroOwner="",
}


-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@returns FlyoutMenuDef
function FlyoutMenuDef:new()
    return deepcopy(STRUCT_FLYOUT_DEF)
end
