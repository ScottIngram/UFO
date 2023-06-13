-- ButtonDef
-- data for a single button, its spell/pet/macro/item/etc.  and methods for manipulating that data
-- CURRENTLY UNUSED - work in progress / proof of concept

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(Debug.OUTPUT.WARN)

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
    spell = { invocationType = "spell",     invocationField = "name", },
    mount = { invocationType = "spell",     invocationField = "name", },
    item  = { invocationType = "item",      invocationField = "name", },
    toy   = { invocationType = "item",      invocationField = "name", },
    pet   = { invocationType = "battlepet", invocationField = "petGuid", },
    macro = { invocationType = "macro",     invocationField = "name", },
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
    type = false,
    name = false,
    spellId = false,
    itemId = false,
    mountId = false,
    petGuid = false,
    macroId = false,
    macroOwner = false,
}


-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

---@return ButtonDef
function ButtonDef:new()
    local self = deepcopy(NEW_STRUCT_FLYOUT_BTN_DEF)
    setmetatable(self, { __index = ButtonDef })
    return self
end

---@return ButtonDef
function ButtonDef:create(table)
    local self = deepcopy(NEW_STRUCT_FLYOUT_BTN_DEF)
    setmetatable(self, { __index = ButtonDef })
    return self
end
