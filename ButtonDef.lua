-- ButtonDef
-- data for a single button, its spell/pet/macro/item/etc.  and methods for manipulating that data
-- CURRENTLY UNUSED - work in progress / proof of concept

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

---@class ButtonType -- IntelliJ-EmmyLua annotation
local ButtonType = {
    SPELL = "spell",
    MOUNT = "mount",
    ITEM  = "item",
    TOY   = "toy",
    PET   = "battlepet",
    MACRO = "macro",
    SNAFU = "companion",
}
Ufo.ButtonType = ButtonType

local ID = "Id"

---@class BlizApiFieldDef -- IntelliJ-EmmyLua annotation
---@field typeForBliz ButtonType
---@field idFieldName string
local BlizApiFieldDef = {
    [ButtonType.SPELL] = { typeForBliz = ButtonType.SPELL, },
    [ButtonType.MOUNT] = { typeForBliz = ButtonType.SPELL, },
    [ButtonType.ITEM ] = { typeForBliz = ButtonType.ITEM,  },
    [ButtonType.TOY  ] = { typeForBliz = ButtonType.ITEM,  },
    [ButtonType.PET  ] = { typeForBliz = ButtonType.PET, idFieldName = "petGuid" },
    [ButtonType.MACRO] = { typeForBliz = ButtonType.MACRO, },
}
Ufo.BlizApiFieldDef = BlizApiFieldDef

---@class ButtonDef -- IntelliJ-EmmyLua annotation
---@field type ButtonType
---@field name string
---@field spellId number
---@field itemId number
---@field mountId number
---@field petGuid string
---@field macroId number
---@field macroOwner string
local ButtonDef = {
    ufoType = "ButtonDef"
}
Ufo.ButtonDef = ButtonDef

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a ButtonDef instance
---@return ButtonDef
function ButtonDef:oneOfUs(self)
    --[[DEBUG]] debug.trace:out("'",3,"FlyoutMenuDef:oneOfUs()", "self",self)
    if self.ufoType == ButtonDef.ufoType then
        return self
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateData = { }
    function privateData:setIdForBlizApis(id) privateData.idForBlizApis = id end

    -- tie the privateData table to the ButtonDef class definition
    setmetatable(privateData, { __index = ButtonDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateData })
    return self
end

---@return ButtonDef
function ButtonDef:new()
    return ButtonDef:oneOfUs({})
end

-- A few different types of buttons share Bliz APIs.
-- For example, you get a mount's icon by calling GetSpellTexture(mountId)
-- This method remaps the various ID fields to match what Bliz API expects
function ButtonDef:remapIdToBlizApiExpectations()
    --debug.trace:out("$",20,"ButtonDef:getProperId()", "self.type",self.type)
    if self.idForBlizApis then
        --debug.trace:out("$",20,"ButtonDef:getProperId()", "self.type",self.type, "RETURNING CACHE :-) self.idForBlizApis", self.idForBlizApis)
        return self.idForBlizApis
    end
    local blizApiFieldDef = self:getBlizApiFieldDef()
    local typeForBliz     = blizApiFieldDef.typeForBliz
    local idFieldName     = blizApiFieldDef.idFieldName or typeForBliz .. "Id" -- spellId or itemId or petGuid or etcId
    local happyBlizId     = self[idFieldName]
    self:setIdForBlizApis(happyBlizId)
    --debug.trace:out("$",3,"ButtonDef:getProperId()", "self.type",self.type, "blizApiFieldDef", blizApiFieldDef, "idFieldName", idFieldName, "idFieldName",idFieldName, "happyBlizId",happyBlizId)
    return happyBlizId
end

-- TODO: fix bug - lack of rage / runic power / etc produces a false false response
function ButtonDef:isUsable()
    local t = self.type
    local id = self:remapIdToBlizApiExpectations()
    if t == ButtonType.MOUNT or t == ButtonType.PET then
        -- TODO: figure out how to find a mount
        return true -- GetMountInfoByID(mountId)
    elseif t == ButtonType.SPELL then
        return IsSpellKnown(id)
    elseif t == ButtonType.ITEM then
        local n = GetItemCount(id)
        local m = PlayerHasToy(id)
        return m or n > 0
    elseif t == ButtonType.MACRO then
        return isMacroGlobal(id) or getIdForCurrentToon() == self.macroOwner
    end
end

function ButtonDef:getIcon()
    local id = self:remapIdToBlizApiExpectations()
    local t = self.type
    if t == ButtonType.SPELL or t == ButtonType.MOUNT then
        return GetSpellTexture(id)
    elseif t == ButtonType.ITEM then
        return GetItemIcon(id)
    elseif t == ButtonType.MACRO then
        local _, texture, _ = GetMacroInfo(id)
        return texture
    elseif t == ButtonType.PET then
        local _, icon = getPetNameAndIcon(id)
        return icon
    end
end

---@return BlizApiFieldDef
function ButtonDef:getBlizApiFieldDef()
    -- maps my types into Bliz types.
    -- for example, converts MOUNT into SPELL because Bliz APIs summon mounts by casting them as spells
    return BlizApiFieldDef[self.type]
end

function ButtonDef:getName()
    if not self.name then
        self:populateName()
    end
    return self.name
end

function ButtonDef:populateName()
    local id = self:remapIdToBlizApiExpectations()
    local t = self.type
    if t == ButtonType.SPELL or t == ButtonType.MOUNT then
        self.name = GetSpellInfo(id)
    elseif t == ButtonType.ITEM then
        self.name = GetItemInfo(id)
    elseif t == ButtonType.TOY then
        self.name = GetItemInfo(id)
    elseif t == ButtonType.MACRO then
        self.name = GetMacroInfo(id)
    elseif t == ButtonType.PET then
        self.name = getPetNameAndIcon(id)
    else
        debug.error:print("ButtonDef:getName() Unknown type:",t)
    end
end
