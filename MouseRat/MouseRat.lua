---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(--[[Z_VOLUME_GLOBAL_OVERRIDE or]] Zebug.TRACE)

-- The Bliz Enum.UICursorType lists all possible values given to the CURSOR_CHANGED even handler.
-- It's only slightly related to the values returned by the Bliz API _G.GetCursorInfo()
-- Let's create a mapping from the Enum to their corresponding "type" result from GetCursorInfo()
-- see also https://github.com/Ketho/vscode-wow-api/blob/master/Annotations/Core/Data/Enum.lua
-- see also https://warcraft.wiki.gg/wiki/API_GetCursorInfo
---@class BlizCursorType
BlizCursorType = {
    -- btw, "Default" equals 0 so the following produces a table with keys, not and an array indices.
    [Enum.UICursorType.Default]      = "empty", -- aka empty. will never actually be returned as a type from GetCursorInfo but instead will be the isDefault = true
    [Enum.UICursorType.Item]         = "item", -- verified
    [Enum.UICursorType.Money]        = "money",
    [Enum.UICursorType.Spell]        = "spell", -- verified
    [Enum.UICursorType.PetAction]    = "petaction", -- verified
    [Enum.UICursorType.Merchant]     = "merchant", -- verified
    [Enum.UICursorType.ActionBar]    = "actionbar",
    [Enum.UICursorType.Macro]        = "macro", -- verified
    [Enum.UICursorType.AmmoObsolete] = "ammoobsolete",
    [Enum.UICursorType.Pet]          = "pet",
    [Enum.UICursorType.GuildBank]    = "guildbank",
    [Enum.UICursorType.GuildBankMoney] = "guildbankmoney",
    [Enum.UICursorType.EquipmentSet]   = "equipmentset", -- verified args: setName
    [Enum.UICursorType.Currency]       = "currency",
    [Enum.UICursorType.Flyout]         = "flyout", -- verified
    [Enum.UICursorType.VoidItem]       = "voiditem",
    [Enum.UICursorType.BattlePet]      = "battlepet", -- verified
    [Enum.UICursorType.Mount]          = "mount", -- verified
    [Enum.UICursorType.Toy]            = "toy", -- verified
    [Enum.UICursorType.Outfit]         = "outfit", -- verified
    [Enum.UICursorType.ConduitCollectionItem]  = "conduitcollectionitem",
    [Enum.UICursorType.PerksProgramVendorItem] = "perksprogramvendoritem",
}

BLIZ_CURSOR_TYPE_BY_NAME = tInvert(BlizCursorType)
--zebug.error:dumpy("BLIZ_CURSOR_TYPE_BY_NAME",BLIZ_CURSOR_TYPE_BY_NAME)

-------------------------------------------------------------------------------
-- MouseRatType
-- the kinds of stuff WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRatType - the type values actually used by the Bliz API's.
MouseRatType = {
    --UNSUPPORTED = BlizCursorType[Enum.UICursorType.AmmoObsolete], -- nobody's got time for that
    UNSUPPORTED = "unsupported", -- nobody's got time for that
    EMPTY   = BlizCursorType[Enum.UICursorType.Default], -- "default" - when nothing is on the cursor
    SPELL   = BlizCursorType[Enum.UICursorType.Spell], -- "spell"
    MOUNT   = BlizCursorType[Enum.UICursorType.Mount], -- "mount",
    ITEM    = BlizCursorType[Enum.UICursorType.Item], -- "item",
    TOY     = BlizCursorType[Enum.UICursorType.Toy], -- "toy",
    PET     = BlizCursorType[Enum.UICursorType.BattlePet], -- "battlepet",
    MACRO   = BlizCursorType[Enum.UICursorType.Macro], -- "macro",
    PSPELL  = BlizCursorType[Enum.UICursorType.PetAction], -- "petaction",
    FLYOUT  = BlizCursorType[Enum.UICursorType.Flyout], -- "flyout",

    -- ------------------------
    -- not in Enum.UICursorType
    -- ------------------------


    -- an imaginary type that will never be returned by _G.GetCursorInfo()
    -- it is used here to accommodate the various kinds of PSPELL / petaction
    -- that the WoW APIs do not handle correctly.  What?!  No way!
    -- the PSPELL handler has special logic to morph into this type as needed
    BROKENP = "brokenPetCommand",

    -- MOUNT variant, an abnormal result containing a useless ID
    -- which isn't accepted by any API. is returned by PickupSpell(spellIdOfSomeMount)
    -- I found a reference in SecureHandlers.lua
    -- elseif kind == 'companion' then
    -- PickupCompanion(target, detail)
    BRUNDLEFLY = "companion",

    -- duh
    SUMMON_RANDOM_FAVORITE_MOUNT = "summonmount",

    -- custom UFO types
    UFO_BUTTON = "macro",
    UFO_FLYOUT = "macro",
}

-------------------------------------------------------------------------------
-- MouseRat
-- anything WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRat : UfoMixIn
---@field ufoType string The classname
---@field isInstance boolean used to decide what data & methods can be expected
---@field mrType MouseRatType
---@field cursorType MouseRatType -- only required if different from mrType
---@field disambiguator function required only if a custom mrType and a standard MouseRatType share a cursorType
---@field primaryKey string "spellId", "mountId", etc.
---@field apiForPickup function will place it onto the mouse pointer / cursor
---@field consumeGetCursorInfo function transforms the wtf _G.GetCursorInfo() results into plain and simple type and id
MouseRat = {
    ufoType = "MouseRat",
}

UfoMixIn:mixInto(MouseRat)

MouseRatContractMethods = {
    -- these are expected to be implemented by subclasses of BtnDef
    -- I prolly need to rethink these now that I'm going with a service provider approach
    "getName", -- or apiForName or nil - optional
    "getIcon", -- or apiForIcon - MANDATORY
    "isUsable", -- or apiForUsable - MANDATORY
    "pickupToCursor", -- or apiForPickup - MANDATORY
    "getToolTipSetter", -- apiForToolTip - MANDATORY
    "asSecureClickHandlerAttributes", -- optional
}

MouseRatSubClassContract = {
    -- the following methods (or their corresponding helper) are expected to be implemented by subclasses of MouseRat
    -- a "helper field" is a function that provides some return data, usually an explicit ref to a Bliz API func
    getId          = { helperField = "primaryKey" },
    getIcon        = { helperApi   = "apiForIcon" },
    isUsable       = { helperApi   = "apiForUsable" },
    setToolTip     = { helperApi   = "apiForToolTip" },
    pickupToCursor = { helperApi   = "apiForPickup" },

    -- these are optional but available if you need them
    -- getName = { helperApi =  "apiForName" },
    -- asSecureClickHandlerAttributes = { no helpers recognized },
}

-------------------------------------------------------------------------------
-- CLASS Methods - operate on the singleton MouseRat
--
-- SUPPORT instantiating from data found in:
-- * saved_variables - will have well defined type & id
-- * cursor - will have ambiguous ID but well defined type
-- * also BlizActionBarButton - as a means to learn its icon
-------------------------------------------------------------------------------

function MouseRat:init()
    self:installMyToString()
end

function MouseRat:mixInto(kid)
    Mixin(kid, self) -- shallow copy
end

-- coerce a table into becoming an instance of a MouseRat subclass.
-- Polymorphism, baby!
---@param target table either a btn from SAVED_VARS that needs to be vivified, or, a junk from GetCursorInfo()
---@param type MouseRatType|nil (optional) if
---@return MouseRat
function MouseRat:oneOfUs(target, type)
    assert(target, "the 'target' arg must be a table")
    if target.mrType then
        -- it's already "one of us" so nothing needs to be done.
        return target
    end

    local type = target.type or type
    assert(type, "a type must be provided")
    local subClass = MouseRatRegistry:getSubClass(type) -- is it bad OOD for MouseRat to call MouseRatRegistry?
    --zebug.warn:event("event"):owner(subClass):print("yay")

    -- TODO: consider MouseRatRegistry.customizedCursorTypes[type] - the  subClass needs to know if it qualifies to become a "customized" MouseRat

    -- create a table to store stuff that we do NOT want persisted out to SavedVariables
    local private = { isInstance = true }
    function private:setPvar(key, val) private[key] = val end
    -- grant the "private" table access to the fields and methods of the MouseRat subClass
    setmetatable(private, { __index = subClass })
    -- grant the target instance access to the "private" table
    setmetatable(target, { __index = private })

    target:installMyToString()

    --zebug.warn:event("event"):owner(target):print("<-- target -->",target)
    --print("oneOfUs -> target.getName", target.getName)
    return target
end

---@param type MouseRatType
---@param c1 number|string|nil (optional) a value potentially returned by _G.GetCursorInfo()
---@param c2 number|string|nil (optional) a value potentially returned by _G.GetCursorInfo()
---@param c3 number|string|nil (optional) a value potentially returned by _G.GetCursorInfo()
---@return MouseRat
function MouseRat:new(type, c1, c2, c3)
    if not type then
        assert(MouseRatType.EMPTY, "MouseRatType.EMPTY is missing / has not been registered")
        return MouseRatType.EMPTY
    end

    local instance = self:oneOfUs({}, type)
    instance:consumeGetCursorInfo(type, c1, c2, c3)
    return instance
end

function MouseRat:getFromCursor(event)
    local type, c1, c2, c3 = GetCursorInfo()
--[[
    if not type then
        assert(MouseRatType.EMPTY, "MouseRatType.EMPTY is missing / has not been registered")
        return self:new(MouseRatType.EMPTY)
    end
]]
    return self:new(type, c1, c2, c3)
end

function MouseRat:nop()
    -- used by subclasses for params that do nothing
    return nil
end

-------------------------------------------------------------------------------
-- INSTANCE Methods - Default implementations for subclasses.
-- These lean into params set inside the subclasses that understand
-- the specific APIs required for their MouseRatType.
-------------------------------------------------------------------------------

function MouseRat:getId(altKey)
    assert(self.isInstance, "instance method called from a class context")
    return self[altKey or self.primaryKey]
end

function MouseRat:setId(id)
    assert(self.isInstance, "instance method called from a class context")
    self[self.primaryKey or "id"] = id
end

-- this method is mandatory and MUST be implemented by the subclass
-- the Bliz API GetCursorInfo() is a great example of why I fucking hate the Bliz APIs
---@field ... varargs - the verbatim results from _G.GetCursorInfo()
function MouseRat:consumeGetCursorInfo(...)
    -- error("this method is mandatory and MUST be implemented by the subclass")
end

---@return string
function MouseRat:getName()
    assert(self.isInstance, "instance method called from a class context")
    if self.name then
        return self.name
    end

    local api = self.apiForName
    --assert(api, "The MouseRat subclass must either implement this method or provide the field 'apiForName'")
    if not api then
        zebug.warn:event("event"):owner("self"):print("the subclass does not define the field 'apiForName' so the name defaults to 'nil'")
        return nil
    end

    -- Bliz APIs are all over the goddamn place and follow no consistency whatsofuckingever.
    local foo = api(self:getId())
    --zebug.warn:event("event"):owner("self"):print("mrType", self.mrType, "id",self:getId() )
    --zebug.warn:event("event"):owner("self"):dumpy("MouseRat:getName api()",foo)
    if isTable(foo) then
        self.name = foo.name
    elseif isString(foo) then
        self.name = foo
    end

    self.name = stripEol(self.name) or "WoW API DuzntKnow"
    zebug.warn:owner("self"):print("name",self.name)
    return self.name
end

---@return number texture ID
function MouseRat:getIcon()
    assert(self.isInstance, "instance method called from a class context")
    if not self.apiForIcon then return nil end
    zebug.warn:owner("self"):print("iconKey",self[self.iconKey], "primaryKey",self.primaryKey)
    return self.apiForIcon(self:getId(self.iconKey))
end

---@return boolean true if the spell is known / the class can operate the item or toy / the faction can ride the mount / etc
function MouseRat:isUsable()
    assert(self.isInstance, "instance method called from a class context")
    assert(self.apiForUsable, "The MouseRat subclass must either implement this method or provide the field 'apiForUsable'")
    return self.apiForUsable(self:getId()) or false
end

function MouseRat:setToolTip()
    assert(self.isInstance, "instance method called from a class context")
    self.apiForToolTip(_G.GameTooltip, self:getId())
end

---@return boolean true if the WoW client will allow this toon to put this thing onto the cursor
function MouseRat:canThisToonPickup()
    -- difference between isUsable() and canThisToonPickup?
    local canPickup = self:isUsable() or MouseRatType.ITEM == self.type
    return canPickup
end

function MouseRat:pickupToCursor()
    assert(self.isInstance, "instance method called from a class context")
    assert(self.apiForPickup, "The MouseRat subclass must either implement this method or provide the field 'apiForPickup'")

    Ufo.pickedUpMouseRat = self

    local event = "event"
    zebug.warn:event(event):owner(self):print("pick me up!")

    local cursor, isOk, err
    if self:canThisToonPickup() then
        isOk, err = pcall(function() self.apiForPickup(self:getId()) end)
    else
        zebug.error:event("event"):owner(self):print("haven't implemented this yet :-(")
        if true then return true end
--[[
        cursor = UfoProxy:pickupButtonDefOntoCursor(self, "event")
        isOk = cursor and true or false
        err = isOk and "A-OK" or "couldn't transform myself into a UfoProxy"
]]
    end

    if isOk then
        zebug.info:event(event):owner(self):print("grabbed id", self:getId())
    else
        zebug.info:event(event):owner(self):print("pickupToCursor failed! ERROR is",err)
    end

    return isOk
end

-- generic handler that is good enough for some simpler MouseRatTypes
-- TODO auto handle sub-types: Macro -> UfoFlyout, Spell -> ProfessionShitShow
---@return MouseRatType type
---@return MouseRatType redundant
---@return string name
function MouseRat:asSecureClickHandlerAttributes()
    assert(self.isInstance, "instance method called from a class context")
    zebug.info:event("event"):owner(self):print("blizType", self.mrType)
    return self.mrType, self.mrType, self:getName()
end

-------------------------------------------------------------------------------
-- UFO Mixin Instance Methods
-------------------------------------------------------------------------------

function MouseRat:toString(arg)
    --assert(self.isInstance, "instance method called from a class context")
    if not self.mrType then
        return "<MouseRat: EMPTY>"
    elseif not self.isInstance then
        local mrType = self.mrType-- (self.mrType == MouseRatType.UNSUPPORTED) and '"UNSUPPORTED"' or self.mrType
        return string.format('<MouseRat base class: "%s">', nilStr(mrType))
--[[
I've implemented these methods in the base class, thus, they always exist
    elseif not self:getId() then
        return string.format("<MouseRat: %s:???>", nilStr(self.mrType))
    elseif not (self.getName and self:getName()) then
        return string.format("<MouseRat: %s:ID%s>", nilStr(self.mrType), nilStr(self:getId()))
]]
    else
        local icon = self:getIcon()
        if icon then
            icon =  string.format(' |T%d:0|t ', icon)
        end
        return string.format('<MouseRat:%s%s:%s - %s>',
                icon or '',
                toStr(self.mrType),
                toStr(self:getName() or self:getId()),
                self:isUsable() and "CAN use" or "NO can use"
        )
    end
end


