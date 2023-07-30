-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

-------------------------------------------------------------------------------
-- ButtonType
-- identifies a button as a Spell, Item, Pet, etc.
-- and provides methods for unified, consistent behavior in the face of Bliz's inconsistent API
-- For now, this class is tightly coupled with the ButtonDef class -- most methods here require its arg to be a ButtonDef
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- BlizApiFieldDef
-- maps my types into Bliz types.
-------------------------------------------------------------------------------
---@class BlizApiFieldDef -- IntelliJ-EmmyLua annotation
---@field pickerUpper function the Bliz API that can load the mouse pointer
---@field typeForBliz ButtonType
---@field key string which field should be used as the ID
local BlizApiFieldDef = {
    [ButtonType.SPELL] = { pickerUpper = PickupSpell, typeForBliz = ButtonType.SPELL, },
    [ButtonType.MOUNT] = { pickerUpper = PickupSpell, typeForBliz = ButtonType.SPELL, },
    [ButtonType.ITEM ] = { pickerUpper = PickupItem,  typeForBliz = ButtonType.ITEM,  },
    [ButtonType.TOY  ] = { pickerUpper = PickupItem,  typeForBliz = ButtonType.ITEM,  },
    [ButtonType.MACRO] = { pickerUpper = PickupMacro, typeForBliz = ButtonType.MACRO --[[, key = "name"]] },
    [ButtonType.SNAFU] = { pickerUpper = nil,         typeForBliz = ButtonType.SPELL, key = "mountId" },
    [ButtonType.PET  ] = { pickerUpper = C_PetJournal.PickupPet, typeForBliz = ButtonType.PET, key = "petGuid" },
}
Ufo.BlizApiFieldDef = BlizApiFieldDef

-------------------------------------------------------------------------------
-- ButtonDef
-- data for a single button, its spell/pet/macro/item/etc.  and methods for manipulating that data
-------------------------------------------------------------------------------
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
    zebug.trace:print("self",self)
    if self.ufoType == ButtonDef.ufoType then
        -- it's already "one of us" so nothing needs to be done.
        return
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateData = { }
    function privateData:setIdForBlizApi(id) privateData.idForBlizApis = id end

    -- tie the privateData table to the ButtonDef class definition
    setmetatable(privateData, { __index = ButtonDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateData })
end

---@return ButtonDef
function ButtonDef:new()
    local self = {}
    ButtonDef:oneOfUs(self)
    return self
end

function ButtonDef:invalidateCache()
    zebug.trace:line(75)
    self.name = nil
    self:setIdForBlizApi(nil)
end

function ButtonDef:whatsMyBlizApiIdField()
    assert(self.type, "can't discern ID key without a type.")
    local blizDef = BlizApiFieldDef[self.type]
    local type    = blizDef.typeForBliz
    local idKey   = blizDef.key or (type .."Id") -- spellId or itemId or petGuid or etcId
    return idKey
end

function ButtonDef:redefine(id, name)
    self:invalidateCache()
    local idKey = self:whatsMyBlizApiIdField()
    self[idKey] = id
    self.name   = name
end

-- A few different types of buttons share Bliz APIs.
-- For example, you get a mount's icon by calling GetSpellTexture(mountId)
-- This method remaps the various ID fields to match what Bliz API expects
---@return number
function ButtonDef:getIdForBlizApi()
    if self.idForBlizApis then
        return self.idForBlizApis
    end

    local idKey = self:whatsMyBlizApiIdField()
    local happyBlizId = self[idKey]
    zebug.trace:print("self.type",self.type, "idKey",idKey, "happyBlizId",happyBlizId)
    self:setIdForBlizApi(happyBlizId) -- cache the result to save processing cycles on repeated calls
    return happyBlizId
end

function ButtonDef:getTypeForBlizApi()
    local blizApiFieldDef = BlizApiFieldDef[self.type]
    return blizApiFieldDef.typeForBliz
end

-- TODO: fix bug - lack of rage / runic power / etc produces a false false response
function ButtonDef:isUsable()
    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.MOUNT or t == ButtonType.PET or t == ButtonType.TOY then
        -- TODO: figure out how to find a mount
        return true -- GetMountInfoByID(mountId)
    elseif t == ButtonType.SPELL then
        return IsSpellKnown(id)
    elseif t == ButtonType.ITEM then
        local n = GetItemCount(id)
        local m = PlayerHasToy(id)
        return m or n > 0
    elseif t == ButtonType.MACRO then
        zebug.info:print("macroId",self.macroId, "isMacroGlobal",isMacroGlobal(self.macroId), "owner",self.macroOwner, "me",getIdForCurrentToon())
        return isMacroGlobal(self.macroId) or getIdForCurrentToon() == self.macroOwner
    end
end

function ButtonDef:getIcon()
    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.SPELL or t == ButtonType.MOUNT then
        return GetSpellTexture(id)
    elseif t == ButtonType.ITEM or t == ButtonType.TOY then
        return GetItemIcon(id)
    elseif t == ButtonType.MACRO then
        if self:isUsable() then
            local _, texture, _ = GetMacroInfo(id)
            return texture
        else
            return "Interface\\Icons\\" .. DEFAULT_ICON
        end
    elseif t == ButtonType.PET then
        local _, icon = getPetNameAndIcon(id)
        return icon
    end
end

function ButtonDef:getName()
    if self.name then
        return self.name
    end

    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.SPELL or t == ButtonType.MOUNT then
        self.name =  GetSpellInfo(id)
    elseif t == ButtonType.ITEM or t == ButtonType.TOY then
        self.name =  GetItemInfo(id)
    elseif t == ButtonType.TOY then
        self.name =  GetItemInfo(id)
    elseif t == ButtonType.MACRO then
        self.name =  GetMacroInfo(self.macroId)
    elseif t == ButtonType.PET then
        self.name =  getPetNameAndIcon(id)
    else
        zebug.warn:print("Unknown type:",t)
    end

    return self.name
end

function trim1(s)
    if not s then return nil end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function ButtonDef:getToolTipSetter()
    local type = self.type
    local id = self:getIdForBlizApi()
    zebug.info:line(20,"id",id)

    local tooltipSetter
    if type == ButtonType.SPELL or type == ButtonType.MOUNT then
        tooltipSetter = GameTooltip.SetSpellByID
    elseif type == ButtonType.ITEM or type == ButtonType.TOY then
        tooltipSetter = GameTooltip.SetItemByID
    elseif type == ButtonType.PET then
        tooltipSetter = GameTooltip.SetCompanionPet
    elseif type == ButtonType.MACRO then
        -- START FUNC
        tooltipSetter = function(zelf, Cache1macroId)
            local upToDateId = self:getIdForBlizApi()
            local macroId = self.macroId
            local i_name, _, i_body = GetMacroInfo(macroId)
            local n_name, _, n_body = GetMacroInfo(self.name)
            if not macroId then macroId = "NiL" end
            zebug.info:print("MACRO! macroId",macroId, "cached1",Cache1macroId,"cahced2",upToDateId, "btnDef name",self.name, "i_name",i_name, "n_name",n_name, "i_body", trim1(i_body), "n_body",trim1(n_body))
            zebug.trace:dumpy("self",self)
            local text
            if self:isUsable() then
                text = "Macro: ".. macroId .." " .. (i_name or "UNKNOWN")
            else
                text = "Toon Macro for " .. self.macroOwner
            end
            return zelf:SetText(text)
        end
        -- END FUNC
    end

    if tooltipSetter and id then
        return function()
            -- because Bliz doesn't understand the concept of immutable IDs
            -- and Bliz allows macro IDs to shift will-fucking-nilly
            -- we must always refresh the ID
            local upToDateId = self:getIdForBlizApi()
            return tooltipSetter(GameTooltip, upToDateId)
        end
    end

    return nil
end

local ttData

function ButtonDef:registerToolTipRecorder()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip == GameTooltip then
            ttData = data
        end
    end)
end

function ButtonDef:readToolTipForToyType()
    ttData = nil -- will be re-populated by the registerToolTipRecorder() event handler above

    -- trigger the tooltip
    local tooltipSetter = self:getToolTipSetter()
    local foo = tooltipSetter and tooltipSetter()
    if not ttData then
        return false
    end

    -- scan the text in the tooltip
    for i, ttLine in ipairs(ttData.lines) do
        zebug.trace:print("ttLine.leftText",ttLine.leftText)
        if ttLine.leftText == L10N.TOY then
            zebug.trace:out(")",30,"TOY !!!")
            return true
        end
    end

    return false
end

---@return ButtonDef
function ButtonDef:getFromCursor()
    ---@type ButtonDef
    local btnDef = ButtonDef:new()
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;
    zebug.trace:print("type",type, "c1",c1, "c2",c2, "c3",c3)

    btnDef.type = type
    if type == ButtonType.SPELL then
        btnDef.spellId = c3
    elseif type == ButtonType.SNAFU then
        -- this is an abnormal result containing a useless ID which isn't accepted by any API.  Not helpful.
        -- It's caused when the mouse pointer is loaded via Bliz's API PickupSpell(withTheSpellIdOfSomeMount)
        -- This is a workaround to Bliz's API and retrieves a usable ID from my secret stash created when the user grabbed the mount.
        if Ufo.pickedUpBtn then
            btnDef = Ufo.pickedUpBtn
        else
            zebug.warn:print("Sorry, the Blizzard API provided bad data for this mount.")
        end
    elseif type == ButtonType.MOUNT then
        local name, spellId = C_MountJournal.GetMountInfoByID(c1)
        btnDef.spellId = spellId
        btnDef.mountId = c1
    elseif type == ButtonType.ITEM then
        btnDef.itemId = c1
        local isToy = btnDef:readToolTipForToyType()
        if isToy then
            btnDef.type = ButtonType.TOY
        end
    elseif type == ButtonType.MACRO then
        btnDef.macroId = c1
        if not isMacroGlobal(c1) then
            btnDef.macroOwner = (Ufo.pickedUpBtn and Ufo.pickedUpBtn.macroOwner) or getIdForCurrentToon()
        end
    elseif type == ButtonType.PET then
        btnDef.petGuid = c1
    else
        Ufo.unknownType = type or "UnKnOwN"
        type = nil
        btnDef = nil
    end

    if type then
        -- discovering the name requires knowing its type
        btnDef:getName()
    end

    Ufo.pickedUpBtn = nil

    return btnDef
end

function ButtonDef:pickupToCursor()
    local type = self.type
    local id = self:getIdForBlizApi()
    local pickup = BlizApiFieldDef[type].pickerUpper
    Ufo.pickedUpBtn = self

    zebug.trace:print("actionType", self.type, "name", self.name, "spellId", self.spellId, "itemId", self.itemId, "mountId", self.mountId)

    pickup(id)
end
