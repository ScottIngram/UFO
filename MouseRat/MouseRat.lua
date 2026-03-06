---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(--[[Z_VOLUME_GLOBAL_OVERRIDE or]] Zebug.TRACE)

-- The Bliz Enum.UICursorType lists all possible values given to the CURSOR_CHANGED event handler.
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

-------------------------------------------------------------------------------
-- MouseRatType
-- the kinds of stuff WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRatType - the type values actually used by the Bliz API's.
MouseRatType = {
    ITEM    = BlizCursorType[Enum.UICursorType.Item],   -- "item",
    FLYOUT  = BlizCursorType[Enum.UICursorType.Flyout], -- "flyout",
    MACRO   = BlizCursorType[Enum.UICursorType.Macro],  -- "macro",
    MOUNT   = BlizCursorType[Enum.UICursorType.Mount],  -- "mount",
    PET     = BlizCursorType[Enum.UICursorType.BattlePet],   -- "battlepet",
    PETACTION = BlizCursorType[Enum.UICursorType.PetAction], -- "petaction",
    SPELL   = BlizCursorType[Enum.UICursorType.Spell], -- "spell"
    TOY     = BlizCursorType[Enum.UICursorType.Toy],   -- "toy", --  cursorType="item" .. sub-type of: ITEM
    UNSUPPORTED = "unsupported", -- nobody's got time for that

    -- ------------------------
    -- not in Enum.UICursorType
    -- ------------------------

    -- MOUNT variant, an abnormal result containing a useless ID
    -- which isn't accepted by any API. It is returned by PickupSpell(spellIdOfSomeMount)
    COMPANION = "companion",  -- sideways brundlefly of: MOUNT

    -- an imaginary type that will never be returned by _G.GetCursorInfo()
    -- it is used here to accommodate the various kinds of PSPELL / petaction
    -- that the WoW APIs do not handle correctly.  What?!  No way!
    -- the PSPELL handler has special logic to morph into this type as needed
    BROKEN_PET_ACTION = "brokenPetCommand", -- cursorType="petaction" .. sub-type of: PETACTION

    -- duh
    SUMMON_RANDOM_FAVORITE_MOUNT = "summonmount", -- cursorType="mount" .. sub-type of: MOUNT

    -- custom UFO types
    UFO_BUTTON = "ufobutton",
    UFO_FLYOUT = "ufoflyout",
}

MOUSE_RAT_TYPE_FOR_CURSOR_NAME = tInvert(MouseRatType)

-------------------------------------------------------------------------------
-- FOR ACTION BARS
-- MouseRatTypeForActionBarButton
-- the kinds of stuff WoW lets you put on the action bars and thus the mouse
-------------------------------------------------------------------------------
---@class MouseRatTypeForActionBarButton
MouseRatTypeForActionBarButton = {

    -- ------------------------------------------------------------------
    -- same string used by both _G.GetCursorInfo() and _G.GetActionInfo()
    -- ------------------------------------------------------------------

    ITEM      = BlizCursorType[Enum.UICursorType.Item],   -- "item",
    FLYOUT    = BlizCursorType[Enum.UICursorType.Flyout], -- "flyout",
    MACRO     = BlizCursorType[Enum.UICursorType.Macro],  -- "macro",
    PETACTION = BlizCursorType[Enum.UICursorType.PetAction], -- "petaction", actionBarButtonType = "spell" .. subType: pet
    SPELL     = BlizCursorType[Enum.UICursorType.Spell], -- "spell"
    TOY       = BlizCursorType[Enum.UICursorType.Toy],   -- "toy", actionBarButtonType = "item"

    -- ----------------------------------------------------------
    -- used by _G.GetActionInfo() but is not in Enum.UICursorType
    -- ----------------------------------------------------------

    MOUNT   = "summonmount", -- not BlizCursorType[Enum.UICursorType.Mount], -- actionBarButtonType = "summonmount"
    PET     = "summonpet", -- not  BlizCursorType[Enum.UICursorType.BattlePet], -- actionBarButtonType = "summonpet"

    -- ------------------------------------------------------------------------------------
    -- custom button types - these are neither used by Bliz but is not in Enum.UICursorType
    -- ------------------------------------------------------------------------------------

    BROKEN_PET_ACTION = "brokenPetCommand",-- actionBarButtonType = "spell" .. subType: pet  <--- ID is always 0
    SUMMON_RANDOM_FAVORITE_MOUNT = "summon_r_f_mount", -- actionBarButtonType = "summonmount" .. subType: nil .. id=268435455
    UNSUPPORTED = "unsupported", -- nobody's got time for that
}

MOUSE_RAT_ACTION_BAR_BUTTON_TYPE_FOR_BUTTON_NAME = tInvert(MouseRatTypeForActionBarButton)


-- map from button -> mouse
ACTION_B_MAPPED_TO_MOUSE = {
    [MouseRatTypeForActionBarButton.MOUNT] = MouseRatType.MOUNT,
    [MouseRatTypeForActionBarButton.PET]   = MouseRatType.PET,
}
-- map from mouse -> button
MOUSE_MAPPED_TO_ACTION_B = tInvert(ACTION_B_MAPPED_TO_MOUSE)

-------------------------------------------------------------------------------
-- MouseRat
-- anything WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRat : UfoMixIn
---@field ufoType string The classname
---@field isInstance boolean used to decide what data & methods can be expected
---@field type MouseRatType
---@field cursorType MouseRatType -- only required if different from type
---@field abbType MouseRatTypeForActionBarButton -- only required if different from type
---@field helpers table<string,function|string|number> typically Bliz APIs to find icons, names, or to set cursor or tooltip
---@field disambiguator function required only if a custom type and a standard MouseRatType share a cursorType
---@field primaryKey string "spellId", "mountId", etc.
---@field setPvar function stores data on self but hides it from SavedVariables
---@field consumeGetCursorInfo function transforms the wtf _G.GetCursorInfo() results into plain and simple type and id
MouseRat = {
    ufoType = "MouseRat",
    zebug = zebug,
}

UfoMixIn:mixInto(MouseRat)

---@class MouseRatMethodsContract
MouseRatMethodsContract = {
    -- the following methods are expected to be implemented by all subclasses of MouseRat.
    -- In the absence of such a method implementation in the subclass, then, it can define a "helper".
    -- These helpers can contain either a hardcoded value (e.g. an ID, a name, etc)
    -- or a function (usually an explicit ref to a Bliz API func.) which will return such a value.
    -- The helper will used by the MouseRat default implementation
    primaryKey = "primaryKey",
    getIcon    = "getIcon",
    isUsable   = "isUsable",
    getName    = "getName",
    setToolTip = "setToolTip",
    pickupToCursor = "pickupToCursor",
}

local mName = MouseRatMethodsContract

-------------------------------------------------------------------------------
-- private functions
-------------------------------------------------------------------------------

-- coerce a table into becoming an instance of a MouseRat subclass. Polymorphism, baby!
---@param target table either an empty {} or a pre-populated chunk of MouseRat-like data (probably from SavedVariables)
---@param subClass MouseRat
---@return MouseRat the target arg but now with metatable goodness
local function coerce(target, subClass)
    assert(target, "the 'target' arg can't be nil")
    if target.isInstance then
        -- it's already "one of us" so nothing needs to be done.
        return target
    end

    assert(subClass, "the 'subClass' arg can't be nil")
    zebug.trace:event("event"):owner(subClass):print("type",subClass.type)

    local privateData = { isInstance = true } -- storage but it's NOT persisted to SavedVariables
    function privateData:setPvar(key, val) privateData[key] = val end -- provide a way to set hidden data

    -- create an inheritance tree using setmetatable()
    -- From the top down, the tree is: MouseRat:adopt()-> subClass / privateData / target
    setmetatable(privateData, { __index = subClass    }) -- subClass is now PD's parent
    setmetatable(target,      { __index = privateData }) -- PD is now target's parent

    target:installMyToString() -- assumes we are a descendant of UfoMixin
    target:setPvar("isInitialized",true)

    return target
end

---@param methodName MouseRatMethodsContract
local function assertIsValidMethodName(methodName)
    if not (mName)[methodName] then
        error("methodName value '"..methodName.."' is not a recognized MouseRatMethodsContract method name", 1)
    end
end

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

---@param obj any|MouseRat
---@return boolean
function MouseRat:isSupported(obj)
    return obj ~= nil
            and isTable(obj)
            and obj.ufoType == MouseRat.ufoType -- TODO: this will break if I decide to give subClasses their own distinct ufoType
            and obj.type ~= MrUnsupported.type
    -- TODO: support checking plain type values
    -- or (not isString(mr))
    -- or MouseRatRegistry:findSubClassForThisUnreliableData(mr)
end

-- establish OO inheritance from the MouseRat parent to the kid subclass (eg MrSpell)
-- this only needs to be done once for each subclass
---@param kid MouseRat a subclass
function MouseRat:adopt(kid)
    if kid.ufoType ~= MouseRat.ufoType then
        zebug.trace:event("event"):print("adopt YES - none kid.ufoType",kid.ufoType)
        setmetatable(kid, { __index = MouseRat }) -- MouseRat is now the kid's parent
        kid:installMyToString()
    else
        zebug.trace:event("event"):print("adopt NOT - already got kid.ufoType",kid.ufoType)
    end
end

---@param target table a pre-populated chunk of MouseRat-like data (probably from SavedVariables)
---@return MouseRat
function MouseRat:oneOfUs(target)
    assert(target, "the 'target' can't be nil")
    assert(isTable(target), "the 'target' arg must be a table")
    assert(target.type, "the 'target' table must first contain valid data before being converted into One of Us.")

    local subClass = MouseRatRegistry:getSubClassForTrustedType(target.type)
    if not subClass then
        subClass = MrUnsupported
    end

    local instance = coerce(target, subClass)
    zebug.info:event("event"):owner(target):print("welcome to the club!")
    return instance
end

-- scrutinize the fucked up shit from GetCursorInfo.
---@param type MouseRatType the 1st value returned by _G.GetCursorInfo()
---@param c2 number|string|nil (optional) the 2nd value from _G.GetCursorInfo()
---@param c3 number|string|nil (optional) the 3rd value from _G.GetCursorInfo()
---@param c4 number|string|nil (optional) the 4th value from _G.GetCursorInfo()
---@return MouseRat
function MouseRat:newFromGetCursorIdiot(type, c2, c3, c4)
    assert(type, "the type arg can't be nil")

    zebug.warn:event("event"):owner(self):print("type",type, "c2",c2, "c3",c3, "c4",c4)

    -- scrutinize the fucked up shit from GetCursorInfo.
    local subClass = MouseRatRegistry:findSubClassForThisUnreliableData(type, c2, c3, c4)
    if not subClass then
        subClass = MrUnsupported
    end

    -- TODO: handle
--[[
    -- currently, this exists only to support the fucked up "companion" type
    if subClass.transformAndAbort then
        local mr = subClass:transformAndAbort(type, c2, c3, c4)
        if mr then return mr end
    end
]]

    local instance = coerce({}, subClass)
    instance:consumeGetCursorInfo(type, c2, c3, c4)

    -- even though type is already in subClass, that data will be hidden from SavedVariables. rectify.
    instance.type = subClass.type

    zebug.info:event("event"):owner(instance):print("")
    return instance
end

function MouseRat:getFromCursor(event)
    local type, c2, c3, c4 = GetCursorInfo()

    if not type then
        Ufo.pickedUpBtn = nil
        zebug.warn:event(event):owner(self):print("Empty cursor is empty")
        return nil
    end

    return self:newFromGetCursorIdiot(type, c2, c3, c4)
end

---@param btnSlotIndex number the bliz identifier for an action bar button.
function MouseRat:getFromActionBarSlot(btnSlotIndex)
    local type, id, subType = _G.GetActionInfo(btnSlotIndex)
    --[[DEBUG]]zebug.warn:event("event"):print("btnSlotIndex",btnSlotIndex, "---> type",type, "id",id, "subType",subType)
    if not type then return nil end

    local subClass = MouseRatRegistry:findSubClassForThisUnreliableData(type, id, subType)
    if not subClass then
        subClass = MrUnsupported
    end

    --[[
    -- TODO: handle
    -- currently, this exists only to support the fucked up "companion" type
    if subClass.transformAndAbort then
        local mr = subClass:transformAndAbort(type, c2, c3, c4)
        if mr then return mr end
    end
    ]]

    local instance = coerce({}, subClass)
    instance:consumeGetCursorInfo(type, id, subType)

    -- even though type is already in subClass, that data will be hidden from SavedVariables. rectify.
    instance.type = subClass.type

    --[[DEBUG]]zebug.info:event("event"):owner(instance):print("")
    return instance
end

-------------------------------------------------------------------------------
-- INSTANCE Methods - utilities - not intended for use outside of this library
-------------------------------------------------------------------------------

local apiSelf = { [mName.setToolTip] = _G.GameTooltip }

---@param methodName MouseRatMethodsContract
---@return any whatever the helper produced (a name, an icon, true for success, etc)
function MouseRat:helpMe(methodName)
    assert(self.isInstance, "instance method called from a class context")
    assert(methodName, "methodName arg is nil")
    assertIsValidMethodName(methodName)
    local helper = self.helpers[methodName]
    if helper == nil then error(methodName..":The MouseRat subclass must either implement this method or provide its helper.") end
    if isFunction(helper) then
        if apiSelf[methodName] then
            return helper(apiSelf[methodName], self:getIdUsedByBlizApis())
        else
            return helper(self:getIdUsedByBlizApis())
        end
    else
        return helper
    end
end

-- at the moment, this exists solely for MOUNT because all of its APIs are actually Spell APIs
-- Bliz APIs are all over the goddamn place and follow no consistency whatsofuckingever.
---@return number|string a unique identifier for this thing as expected by bliz APIs
function MouseRat:getIdUsedByBlizApis()
    assert(self.isInstance, "instance method called from a class context")
    return self[self.keyForApis or self.primaryKey]
end

---@return number|string the unique identifier for this thing, its primaryKey
function MouseRat:getId()
    assert(self.isInstance, "instance method called from a class context")
    return self[self.primaryKey]
end

function MouseRat:setId(id)
    assert(self.isInstance, "instance method called from a class context")
    self[self.primaryKey or "id"] = id
end

---@return boolean true if the WoW client will allow this toon to put this thing onto the cursor
function MouseRat:canThisToonPickup()
    -- difference between isUsable() and canThisToonPickup?
    local canPickup = self:isUsable() or MouseRatType.ITEM == self.type
    return canPickup
end

function MouseRat:getMostRecentlyPickedUpMr()
    return MouseRat.pickedUpMouseRat or Ufo.pickedUpBtn
end

-------------------------------------------------------------------------------
-- CONTRACT INSTANCE Methods - provide mandatory behaviors of the MouseRat library
-- Below are default implementations for subclasses.
-- These lean into params set inside the subclasses that understand
-- the specific APIs required for their MouseRatType.
-- Subclasses can override these default implementations with custom ones.
-------------------------------------------------------------------------------

-- subclasses can override this method and decide how to interpret GetCursorBullshit() for particularly shitty data
---@param ... any - the verbatim results from _G.GetCursorInfo()
function MouseRat:consumeGetCursorInfo(type, prollyId, maybeSubType, whoEvenFuckingKnows)
    if type ~= self.type then
        error(type..",the provided type, doesn't match the expected one:"..self.type)
    end
    self:setId(prollyId)
    self:setPvar("subType", maybeSubType)
    self:setPvar("extraId", whoEvenFuckingKnows)
end

-- because Bliz loves inconsistency more than life itself,
-- the results from _G.GetCursorInfo() are given in an unpredictable order.
-- here, we fix that bullshit
---@param type MouseRatType the 1st value returned by GCI seems to reliably always be type
---@param id number|string  the 2nd value from GCI - uSuAlLy the ID
---@param subType number|string|nil (optional) the 3rd value from GCI - sometimes describes a variation for the type, sometimes an index in some catalog
---@param subId number|string|nil (optional) the 4th value from GCI - sometimes is a derived ID
function MouseRat:fixGetCursorInfo(type, id, subType, subId)
    -- default implementation simply returns them in the same order provided which for some types is actually correctly
    return type, id, subType, subId
end

---@return string
function MouseRat:getName()
    assert(self.isInstance, "instance method called from a class context")
    if self.name then
        return self.name
    end

    local blizNameApiResults = self:helpMe(mName.getName)

    -- Bliz APIs are all over the goddamn place and follow no consistency whatsofuckingever.
    if isTable(blizNameApiResults) then
        self.name = blizNameApiResults.name
    elseif isString(blizNameApiResults) then
        self.name = blizNameApiResults
    else
        self.name = toStr(blizNameApiResults)
    end

    self.name = stripEol(self.name) or "uNkNoWn?"
    return self.name
end

---@return number texture ID
function MouseRat:getIcon()
    assert(self.isInstance, "instance method called from a class context")
    return self:helpMe(mName.getIcon)
end

---@return boolean true if the spell is known / the class can operate the item or toy / the faction can ride the mount / etc
function MouseRat:isUsable()
    assert(self.isInstance, "instance method called from a class context")
    return self:helpMe(mName.isUsable) or false
end

function MouseRat:setToolTip()
    assert(self.isInstance, "instance method called from a class context")
    return self:helpMe(mName.setToolTip)
end

function MouseRat:pickupToCursor()
    assert(self.isInstance, "instance method called from a class context")

    --MouseRat.pickedUpMouseRat = self -- TODO: fully switch over from ButtonDef to MouseRat
    Ufo.pickedUpBtn = self

    local event = "event"
    zebug.warn:event(event):owner(self):print("pick me up!")

    local isOk, err
    if self:canThisToonPickup() then
        isOk, err = pcall(function() self:helpMe(mName.pickupToCursor) end)
    else
        -- TODO - implement MrUfoButtton / Flyout, ie, replace UfoProxy with MouseRats
        local cursor = UfoProxy:pickupButtonDefOntoCursor(self, "event")
        isOk = cursor and true or false
        err = isOk and "A-OK" or "couldn't transform myself into a UfoProxy"
    end

    if isOk then
        zebug.trace:event(event):owner(self):print("picked up A-OK!")
    else
        zebug.warn:event(event):owner(self):print("pickupToCursor failed! ERROR is",err)
    end

    return isOk
end

-- expresses the MouseRat in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
-- the following is a generic handler that is good enough for some simpler MouseRatTypes.
-- TODO auto handle sub-types: Macro -> UfoFlyout, Spell -> ProfessionShitShow
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute related to the above "type" attribute (according to Bliz's convoluted rules)
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MouseRat:asSecureClickHandlerAttributes()
    assert(self.isInstance, "instance method called from a class context")
    --zebug.info:event("event"):owner(self):print("default asSecureClickHandlerAttributes")
    return self.type, self.type, self:getName()
end

-------------------------------------------------------------------------------
-- UFO Mixin Instance Methods
-------------------------------------------------------------------------------

function MouseRat:toString(arg)
    --assert(self.isInstance, "instance method called from a class context")
    if not self.type then
        return "<MouseRat zombie>"
    elseif not self.isInstance then
        return string.format('<MouseRat CLASS: "%s">', nilStr(self.type))
    elseif not self.isInitialized then
        return string.format('<MouseRat PROTO: "%s">', nilStr(self.type))
    else
        local icon = self:getIcon()
        if icon then
            icon =  string.format(' |T%d:0|t ', icon)
        end
        return string.format('<MouseRat:%s%s%s:%s>',
                MarkTexture[ self:isUsable() and Mark.CHECK or Mark.NO ],
                icon or '',
                toStr(self.type),
                toStr(self:getName() or self:getId())
        )
    end
end

-------------------------------------------------------------------------------
-- BRIDGE to satisfy ButtonDef "interface"
-------------------------------------------------------------------------------

MouseRat.getIdForBlizApi = MouseRat.getIdUsedByBlizApis
