-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

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
---@field typeForBliz ButtonType
---@field key string
local BlizApiFieldDef = {
    [ButtonType.SPELL] = { typeForBliz = ButtonType.SPELL, },
    [ButtonType.MOUNT] = { typeForBliz = ButtonType.SPELL, },
    [ButtonType.ITEM ] = { typeForBliz = ButtonType.ITEM,  },
    [ButtonType.TOY  ] = { typeForBliz = ButtonType.ITEM,  },
    [ButtonType.PET  ] = { typeForBliz = ButtonType.PET, key = "petGuid" },
    [ButtonType.MACRO] = { typeForBliz = ButtonType.MACRO, },
    [ButtonType.SNAFU] = { typeForBliz = ButtonType.SPELL, key = "mountId" },
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
    debug.trace:out("'",3,"FlyoutMenuDef:oneOfUs()", "self",self)
    if self.ufoType == ButtonDef.ufoType then
        -- it's already "one of us" so nothing needs to be done.
        return self
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateData = { }
    function privateData:setIdForBlizApi(id) privateData.idForBlizApis = id end

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
---@return number
function ButtonDef:getIdForBlizApi()
    if self.idForBlizApis then
        return self.idForBlizApis
    end
    if not self.type then
        -- if there is no type, there can't be a typeForBliz
        return
    end

    local blizDef     = BlizApiFieldDef[self.type]
    local typeForBliz = blizDef.typeForBliz
    local idKey       = blizDef.key or (typeForBliz.."Id") -- spellId or itemId or petGuid or etcId
    local happyBlizId = self[idKey]
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
    local t = self.type
    local id = self:getIdForBlizApi()
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

function ButtonDef:getName()
    if self.name then
        return self.name
    end

    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.SPELL or t == ButtonType.MOUNT then
        self.name =  GetSpellInfo(id)
    elseif t == ButtonType.ITEM then
        self.name =  GetItemInfo(id)
    elseif t == ButtonType.TOY then
        self.name =  GetItemInfo(id)
    elseif t == ButtonType.MACRO then
        self.name =  GetMacroInfo(id)
    elseif t == ButtonType.PET then
        self.name =  getPetNameAndIcon(id)
    else
        debug:print("ButtonDef:getName() Unknown type:",t)
    end

    return self.name
end

function ButtonDef:getToolTipSetter()
    local type = self.type
    local id = self:getIdForBlizApi()

    local tooltipSetter
    if type == ButtonType.SPELL or type == ButtonType.MOUNT then
        tooltipSetter = GameTooltip.SetSpellByID
    elseif type == ButtonType.ITEM or type == ButtonType.TOY then
        tooltipSetter = GameTooltip.SetItemByID
    elseif type == ButtonType.PET then
        tooltipSetter = GameTooltip.SetCompanionPet
    elseif type == ButtonType.MACRO then
        tooltipSetter = function(zelf, macroId)
            local name, _, _ = GetMacroInfo(macroId)
            if not macroId then macroId = "NiL" end
            debug.info:out(X,X,"ButtonType:getToolTipSetter() ButtonType.MACRO !", "macroId",macroId)
            return zelf:SetText("Macro: ".. macroId .." " .. (name or "UNKNOWN"))
        end
    end

    if tooltipSetter and id then
        return function()
            return tooltipSetter(GameTooltip, id)
        end
    end

    return nil
end

-- TODO: distinguish between toys and items
---@return ButtonDef
function ButtonDef:getFromCursor()
    ---@type ButtonDef
    local btnDef = ButtonDef:new()
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;
    debug.trace:out(">",5,"getFromCursor()", "type",type, "c1",c1, "c2",c2, "c3",c3)

    btnDef.type = type
    if type == ButtonType.SPELL then
        btnDef.spellId = c3
    elseif type == ButtonType.SNAFU then
        -- this is an abnormal result containing a useless ID which isn't accepted by any API.  Not helpful.
        -- It's caused when the mouse pointer is loaded via Bliz's API PickupSpell(withTheSpellIdOfSomeMount)
        -- This is a workaround to Bliz's API and retrieves a usable ID from my secret stash created when the user grabbed the mount.
        if Ufo.pickedUpMount then
            btnDef.type = ButtonType.MOUNT
            btnDef.spellId = Ufo.pickedUpMount.spellId
            btnDef.mountId = Ufo.pickedUpMount.mountId
        else
            debug.warn:print("Sorry, the Blizzard API provided bad data for this mount.")
        end
    elseif type == ButtonType.MOUNT then
        local name, spellId = C_MountJournal.GetMountInfoByID(c1)
        btnDef.spellId = spellId
        btnDef.mountId = c1
    elseif type == ButtonType.ITEM then
        local ttType = parseToolTipForType(c2)
        if ttType == ButtonType.TOY then
            btnDef.type = ButtonType.TOY
        end
        btnDef.itemId = c1
    elseif type == ButtonType.MACRO then
        btnDef.macroId = c1
        if not isMacroGlobal(c1) then
            btnDef.macroOwner = getIdForCurrentToon()
        end
    elseif type == ButtonType.PET then
        btnDef.petGuid = c1
    else
        btnDef.kind = type or "UnKnOwN"
    end

    if type then
        -- discovering the name requires knowing its type
        btnDef:getName()
    end

    return btnDef
end

function ButtonDef:pickupToCursor()
    local type = self.type

    debug.trace:out("<",5,"ButtonOnFlyoutMenu:pickup", "actionType", self.type, "name", self.name, "spellId", self.spellId, "itemId", self.itemId, "mountId", self.mountId)

    if type == ButtonType.MOUNT then
        -- set a global variable because the Bliz API is broken
        Ufo.pickedUpMount = {
            mountId = self.mountId,
            spellId = self.spellId
        }
        PickupSpell(self.spellId)
    elseif type == ButtonType.SPELL then
        PickupSpell(self.spellId)
    elseif type == ButtonType.ITEM or type == ButtonType.TOY then
        PickupItem(self.itemId)
    elseif type == ButtonType.MACRO then
        PickupMacro(self.macroId)
    elseif type == ButtonType.PET then
        C_PetJournal.PickupPet(self.petGuid)
    end
    -- TODO: bug - address TOY
end
