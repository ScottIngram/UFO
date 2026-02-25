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

-------------------------------------------------------------------------------
-- MouseRatType
-- the kinds of stuff WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRatType - the type values actually used by the Bliz API's.
MouseRatType = {
    UNSUPPORTED = "unsupported", -- nobody's got time for that
    SPELL   = BlizCursorType[Enum.UICursorType.Spell], -- "spell"
    MOUNT   = BlizCursorType[Enum.UICursorType.Mount], -- "mount",
    ITEM    = BlizCursorType[Enum.UICursorType.Item], -- "item",
    TOY     = BlizCursorType[Enum.UICursorType.Toy], -- "toy",
    PET     = BlizCursorType[Enum.UICursorType.BattlePet], -- "battlepet",
    MACRO   = BlizCursorType[Enum.UICursorType.Macro], -- "macro",
    FLYOUT  = BlizCursorType[Enum.UICursorType.Flyout], -- "flyout",
    PETACTION = BlizCursorType[Enum.UICursorType.PetAction], -- "petaction",

    -- ------------------------
    -- not in Enum.UICursorType
    -- ------------------------

    -- MOUNT variant, an abnormal result containing a useless ID
    -- which isn't accepted by any API. It is returned by PickupSpell(spellIdOfSomeMount)
    COMPANION = "companion",

    -- an imaginary type that will never be returned by _G.GetCursorInfo()
    -- it is used here to accommodate the various kinds of PSPELL / petaction
    -- that the WoW APIs do not handle correctly.  What?!  No way!
    -- the PSPELL handler has special logic to morph into this type as needed
    BROKEN_PET_ACTION = "brokenPetCommand",

    -- duh
    SUMMON_RANDOM_FAVORITE_MOUNT = "summonmount",

    -- custom UFO types
    UFO_BUTTON = "ufobutton",
    UFO_FLYOUT = "ufoflyout",
}

-------------------------------------------------------------------------------
-- MouseRat
-- anything WoW lets you put on the mouse and thus the action bars
-------------------------------------------------------------------------------
---@class MouseRat : UfoMixIn
---@field ufoType string The classname
---@field isInstance boolean used to decide what data & methods can be expected
---@field type MouseRatType
---@field cursorType MouseRatType -- only required if different from type
---@field helpers table<string,function|string|number> typically Bliz APIs to find icons, names, or to set cursor or tooltip
---@field disambiguator function required only if a custom type and a standard MouseRatType share a cursorType
---@field primaryKey string "spellId", "mountId", etc.
---@field setPvar function stores data on self but hides it from SavedVariables
---@field consumeGetCursorInfo function transforms the wtf _G.GetCursorInfo() results into plain and simple type and id
MouseRat = {
    ufoType = "MouseRat",
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

-- is the type from _G.GetCursorInfo() a big fat fucking lie?
-- analyze the API's data and decide if one of MouseRat's "customized" sub-subClass is a better fit for this type.
---@return MouseRat|nil a different MouseRat subclass from what the "type" suggests, or nil if none exists
local function morph(type, c2, c3, c4)
    local customMouseRatsForThisType = MouseRatRegistry.customizedCursorTypes[type]
    if not customMouseRatsForThisType then return end

    --zebug.warn:event("event"):owner(subClass):dumpKeys(customMouseRatsForThisType)
    ---@param customSubMr MouseRat
    for i, customSubMr in ipairs(customMouseRatsForThisType) do
        local isQualified = customSubMr:disambiguator(type, c2, c3, c4)
        zebug.warn:event("event"):print("disambiguator! is this type", type," actually", customSubMr.type, "?",isQualified)
        if isQualified then
            -- first one wins!  assume only one custom class will qualify
            -- replace the previous subClass with the custom one we found
            return customSubMr
        end
    end

    return nil
end

-- coerce a table into becoming an instance of a MouseRat subclass. Polymorphism, baby!
---@param target table|nil (optional) either a pre-populated btn probably from SavedVariables or an empty {}
---@param type MouseRatType|nil (optional) the 1st value returned by _G.GetCursorInfo()
---@param c2 number|string|nil (optional) the 2nd value from _G.GetCursorInfo()
---@param c3 number|string|nil (optional) the 3rd value from _G.GetCursorInfo()
---@param c4 number|string|nil (optional) the 4th value from _G.GetCursorInfo()
---@return MouseRat the target arg but now with metatable goodness
local function coerce(target, type, c2, c3, c4)
    if target.isInstance then
        -- it's already "one of us" so nothing needs to be done.
        return target
    end

    type = target.type or type
    assert(type, "a type must be provided")

    local subClass = MouseRatRegistry:getSubClass(type) or MrUnsupported -- TODO: consider merging MouseRatRegistry and MouseRat
    zebug.trace:event("event"):owner(subClass):print("type",type, "c2",c2, "c3",c3, "c4",c4)

    -- scrutinize the fucked up shit from GetCursorInfo.
    -- assume anything from SavedVariables has already been analyzed and sanitized.
    local untrustworthyBlizBullshit = (c2 or c3 or c4)
    if untrustworthyBlizBullshit then

        -- currently, this exists only to support the fucked up "companion" type
        if subClass.transformAndAbort then
            local mr = subClass:transformAndAbort(type, c2, c3, c4)
            if mr then return mr end
        end

        -- does the subClass qualify to become a "customized" sub-subClass
        local butterFly = morph(type, c2, c3, c4)
        if butterFly then
            subClass = butterFly
        end

        -- even though type is already in subClass,
        -- that data will be hidden from SavedVariables. rectify.
        target.type = subClass.type
    end

    local privateData = { isInstance = true } -- storage but it's NOT persisted to SavedVariables

    -- create an inheritance tree using setmetatable()
    -- From the top down, the tree is: MouseRat:adopt()-> subClass / privateData / target
    setmetatable(privateData, { __index = subClass    }) -- subClass is now PD's parent
    setmetatable(target,      { __index = privateData }) -- PD is now target's parent

    -- provide an accessor to the private data
    function privateData:setPvar(key, val) privateData[key] = val end

    target:installMyToString()
    target:setPvar("isInitialized",true)

    return target
end

---@param methodName MouseRatMethodsContract
function isValidMethodName(methodName)
    return mName[methodName] or false
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

-- establish OO inheritance from the MouseRat parent to the kid subclass (eg MrSpell)
-- this only needs to be done once for each subclass
---@param kid MouseRat a subclass
function MouseRat:adopt(kid)
    if kid.ufoType ~= MouseRat.ufoType then
        zebug.warn:event("event"):print("adopt YES - none kid.ufoType",kid.ufoType)
        setmetatable(kid, { __index = MouseRat }) -- MouseRat is now the kid's parent
        kid:installMyToString()
    else
        zebug.trace:event("event"):print("adopt NOT - already got kid.ufoType",kid.ufoType)
    end
end

---@return MouseRat
function MouseRat:oneOfUs(target)
    assert(target, "the 'target' can't be nil")
    assert(isTable(target), "the 'target' arg must be a table")
    assert(target.type, "the 'target' table must first contain valid data before being converted into One of Us.")
    local instance = coerce(target)
    zebug.info:event("event"):owner(target):print("welcome to the club!")
    return instance
end

---@param type MouseRatType the 1st value returned by _G.GetCursorInfo()
---@param c2 number|string|nil (optional) the 2nd value from _G.GetCursorInfo()
---@param c3 number|string|nil (optional) the 3rd value from _G.GetCursorInfo()
---@param c4 number|string|nil (optional) the 4th value from _G.GetCursorInfo()
---@return MouseRat
function MouseRat:new(type, c2, c3, c4)
    assert(type, "the type arg can't be nil")

    zebug.warn:event("event"):owner(self):print("type",type, "c2",c2, "c3",c3, "c4",c4)
    local instance = coerce({}, type, c2, c3, c4)
    instance:consumeGetCursorInfo(type, c2, c3, c4)
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

    return self:new(type, c2, c3, c4)
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

-- this method is mandatory and MUST be implemented by the subclass
-- the Bliz API GetCursorInfo() is a great example of why I fucking hate the Bliz APIs
---@field ... varargs - the verbatim results from _G.GetCursorInfo()
function MouseRat:consumeGetCursorInfo(...)
    error("this method is mandatory and MUST be implemented by the subclass")
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

    --MouseRat.pickedUpMouseRat = self
    Ufo.pickedUpBtn = self

    local event = "event"
    zebug.warn:event(event):owner(self):print("pick me up!")

    local cursor, isOk, err
    if self:canThisToonPickup() then
        isOk, err = pcall(function() self:helpMe(mName.pickupToCursor) end)
    else
        zebug.error:event("event"):owner(self):print("haven't implemented this yet :-(")
        return false
--[[
        -- TODO - leverage proxy
        cursor = UfoProxy:pickupButtonDefOntoCursor(self, "event")
        isOk = cursor and true or false
        err = isOk and "A-OK" or "couldn't transform myself into a UfoProxy"
]]
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
