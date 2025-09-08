-- simplify tracking what's on the action bars
-- BlizActionBarButtonHelper - helper methods for easy access to bliz action bar buttons and their fields
-- BlizActionBarButton - a wrapper for the actual bliz action bar buttons Frame objects PLUS all of the above

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@alias LITERAL_BABB  ActionBarActionButtonMixin | Button_Mixin | ActionButtonTemplate | SecureActionButtonTemplate | Frame

---@class BlizActionBarButtonHelper : UfoMixIn
---@field ufoType string The classname

---@type BlizActionBarButtonHelper
BlizActionBarButtonHelper = {
    ufoType = "BLIZACTIONBARBUTTONHELPER"
}
local BabbClass = BlizActionBarButtonHelper

---@class BlizActionBarButton : UfoMixIn
---@field ufoType string The classname
---@field germ Germ the germ using me as its parent
---@field btnSlotIndex number the index of the button among all 100+ buttons
---@field barNum number which action bar
---@field btnNum number the index of the button among the 12 on the same bar
---@field actionBarDef table meta data about the button's action bar
---@field barName string one of Bliz's many names for the bar
---@field barYafName string yet another of Bliz's many fucking names for the bar
---@field btnName string one of Bliz's many names for the button
---@field btnYafName string yet another of Bliz's many fucking names for the button
---@field visibleIf string conditions used by RegisterStateDriver(self, "visibility")

---@type BlizActionBarButton | LITERAL_BABB
BlizActionBarButton = {
    ufoType = "BlizActionBarButton"
}
UfoMixIn:mixInto(BlizActionBarButton)

local BabbInstance = BlizActionBarButton

----------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

---@class BLIZ_BAR_METADATA
---@field name string is how it's identified by /fstack and thus the name of its _G global variable and its buttons
---@field yafName string yet another fucking name is how it's identified by the key bindings API
---@field visibleIf string used by Bliz's visibility driver to decide when to show/hide
BLIZ_BAR_METADATA = {
    [1]  = {name="Action",              visibleIf="bar:1,nobonusbar:1,nobonusbar:2,nobonusbar:3,nobonusbar:4"}, -- primary "ActionBar" - page #1 - no stance/shapeshift --- ff: actionBarPage = 1
    [2]  = {name="Action",              visibleIf="bar:2"}, -- primary "ActionBar" - page #2 (regardless of stance/shapeshift) --- ff: actionBarPage = 2
    [3]  = {name="MultiBarRight",       yafName="MultiActionBar3"}, -- config UI -> Action Bars -> checkbox #4
    [4]  = {name="MultiBarLeft",        yafName="MultiActionBar4"}, -- config UI -> Action Bars -> checkbox #5
    [5]  = {name="MultiBarBottomRight", yafName="MultiActionBar2"}, -- config UI -> Action Bars -> checkbox #3
    [6]  = {name="MultiBarBottomLeft",  yafName="MultiActionBar1"}, -- config UI -> Action Bars -> checkbox #2
    [7]  = {name="Action",              visibleIf="bar:1,bonusbar:1"}, -- primary "ActionBar" - page #1 - bonusbar 1 - druid CAT
    [8]  = {name="Action",              visibleIf="bar:1,bonusbar:2"}, -- primary "ActionBar" - page #1 - bonusbar 2 - unknown?
    [9]  = {name="Action",              visibleIf="bar:1,bonusbar:3"}, -- primary "ActionBar" - page #1 - bonusbar 3 - druid BEAR
    [10] = {name="Action",              visibleIf="bar:1,bonusbar:4"}, -- primary "ActionBar" - page #1 - bonusbar 4 - druid MOONKIN
    [11] = {name="Action",              visibleIf="bar:1,bonusbar:5"}, -- primary "ActionBar" - page #1 - bonusbar 5 - dragon riding
    [12] = {name="Action",              visibleIf="bar:1,bonusbar:6"--[[just a guess]]}, -- unknown?
    [13] = {name="MultiBar5",           yafName="MultiActionBar5"}, -- config UI -> Action Bars -> checkbox #6
    [14] = {name="MultiBar6",           yafName="MultiActionBar6"}, -- config UI -> Action Bars -> checkbox #7
    [15] = {name="MultiBar7",           yafName="MultiActionBar7"}, -- config UI -> Action Bars -> checkbox #8
    [16] = {name="WhoKnows",            }, -- another vehicle ?
    [18] = {name="OverrideActionBar",   }, -- vehicle
    [19] = {name="ExtraAction",         }, -- center screen popup spell
}

-------------------------------------------------------------------------------
--  Data
-------------------------------------------------------------------------------

local babBtns = {}

-------------------------------------------------------------------------------
--  BlizActionBarButtonHelper Methods
-------------------------------------------------------------------------------
----- TODO: rework this class with a cache<btnSlotIndex, a-btn>

-- gets the UI frame object for the button / empty slot sitting in btnSlotIndex on the Bliz action bars.
-- such a button could be EMPTY or contain a spell, a macro, a potion, etc.
---@return BlizActionBarButton
function BlizActionBarButtonHelper:get(btnSlotIndex, event)
    if btnSlotIndex == 0 then return end -- during UI reloads, sometimes Bliz's shitty API reports that we're using the non-existent btnSlotIndex #0.  Fuck you Bliz.
    assert(btnSlotIndex, "invalid nil value for btnSlotIndex")

    if babBtns[btnSlotIndex] then
        return babBtns[btnSlotIndex]
    end

    local barNum, barName, btnNum, btnName, actionBarDef, literalBlizBtn = getBarAndBtnEtc(btnSlotIndex, event)
    zebug.trace:print("getBarAndBtnEtc UT - btnName",btnName, "literalBlizBtn", literalBlizBtn)
    --print("literalBlizBtn.GetName", literalBlizBtn.GetName)
    --print("literalBlizBtn:GetName()", literalBlizBtn:GetName())

    if barNum == 0 then return end -- during UI reloads, sometimes Bliz's shitty API reports that we're using the non-existent action bar #0.  Fuck you Bliz.
    --zebug.error:event(event):mark(Mark.FIRE):print("wtf-2 btnSlotIndex",btnSlotIndex, "barNum",barNum, "actionBarDef", actionBarDef)

    --metatable FAILED: got error "error calling FOO on bad self"
    --local instance = deepcopy(BlizActionBarButton, {})
    --setmetatable(instance, { __index = literalBlizBtn }) -- any access to methods or variables that don't exist in BlizActionBarButton will look for those same things on literalBlizBtn

    -- So instead, wollop the Bliz button Frame object and bolt all of BlizActionBarButton's fields/methods into it.
    -- TAINT concerns.  Be careful to not touch any fields read by Bliz code.

    ---@type BlizActionBarButton | LITERAL_BABB
    local self = deepcopy(BlizActionBarButton, literalBlizBtn)

--[[
    print("babb self A", self)
    print("babb literalBlizBtn.GetName", literalBlizBtn.GetName)
    print("babb self.GetName", self.GetName)
    print("babb literalBlizBtn:GetName()", literalBlizBtn:GetName())
    print("babb self:GetName()", self:GetName())
]]

    -- go the extra mile and collect a bunch of "missing from the box" data that Bliz doesn't make easy to find out.

    local barYafName = actionBarDef.yafName
    local btnYafName = barYafName and (barYafName .. "Button" .. btnNum) or nil

    self.btnSlotIndex = btnSlotIndex
    self.barNum       = barNum
    self.btnNum       = btnNum
    self.actionBarDef = actionBarDef
    self.barName      = barName
    self.btnName      = btnName
    self.barYafName   = barYafName
    self.btnYafName   = btnYafName
    self.visibleIf    = actionBarDef.visibleIf

    --print("babb instance B", instance)
    local mt = getmetatable(self)
    --zebug.info:event(event):print("BABB", "self",self, "mt",mt, "self.toString", self.toString, "mt.__tostring",mt and mt.__tostring, "self:toString()", self:toString())
    self:installMyToString()

    babBtns[btnSlotIndex] = self
    return self
end

---@return number barNum
---@return string barName
---@return number btnNum
---@return string btnName
---@return table meta data about the action bar
function getBarAndBtnEtc(btnSlotIndex, event)
    assert(btnSlotIndex, "btnSlotIndex is nil.  Try again, plz!")

    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    if barNum == 0 then return end -- during UI reloads, sometimes Bliz's shitty API reports that we're using the non-existent action bar #0.  Fuck you Bliz.

    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum.." resulting from event: ".. tostring(event)) -- in case Blizzard adds more bars, complain here clearly.

    -- zebug.error:event(event):mark(Mark.FIRE):print("wtf-1 btnSlotIndex",btnSlotIndex, "actionBarDef", actionBarDef)
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local barName = actionBarDef.name
    local btnName = barName .. "Button" .. btnNum
    local literalBlizBtn = _G[btnName]
    zebug.trace:print("getBarAndBtnEtc IN - btnName",btnName, "literalBlizBtn", literalBlizBtn)

    return barNum, barName, btnNum, btnName, actionBarDef, literalBlizBtn
end

---@return LITERAL_BABB
function BabbClass:getLiteralBlizBtn(btnSlotIndex)
    local _, _, _, _, _, btn = getBarAndBtnEtc(btnSlotIndex)
    return btn
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return boolean true if the btn has nothing on it
function BabbClass:isEmpty(btnSlotIndex)
    assert(btnSlotIndex, "btnSlotIndex arg is missing.  oops!")
    assert(btnSlotIndex > 0, "btnSlotIndex arg is invalid.  Must be above 0.")
    local btn = self:getLiteralBlizBtn(btnSlotIndex)
    return not (btn and btn.HasAction and btn:HasAction())
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return ButtonType
function BabbClass:getTypeAndId(btnSlotIndex)
    assert(btnSlotIndex, "btnSlotIndex arg is missing.  oops!")
    assert(btnSlotIndex > 0, "btnSlotIndex arg is invalid.  Must be above 0.")
    return GetActionInfo(btnSlotIndex)
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return boolean true if the btn contains a UfoProxy
function BabbClass:isUfoProxy(btnSlotIndex)
    local btn = self:getLiteralBlizBtn(btnSlotIndex)
    return UfoProxy:isOnBtn(btn)
end

function BabbClass:isUfoPlaceholder(btnSlotIndex, event)
    local btn = self:getLiteralBlizBtn(btnSlotIndex)
    return Placeholder:isOn(btn, event)
end

-------------------------------------------------------------------------------
--  BlizActionBarButton Methods
-------------------------------------------------------------------------------

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return boolean true if the btn has nothing on it
function BabbInstance:isEmpty()
    return BabbClass:isEmpty(self.btnSlotIndex)
end

--[[
function BabbInstance:getParent()
    if ThirdPartyAddonSupport.isAnyActionBarAddonActive then
        return ThirdPartyAddonSupport:getBtnParentAsProvidedByAddon(self.btnSlotIndex, self.barNum, self.btnNum)
    else
        return self:GetParent() -- call Bliz's
    end
end
]]

function BabbInstance:getLiteralBlizBtn()
    return BabbClass:getLiteralBlizBtn(self.btnSlotIndex)
end

---@return ButtonType
function BabbInstance:getTypeAndId()
    return BabbClass:getTypeAndId(self.btnSlotIndex)
end

function BabbInstance:getBtnSlotIndex()
    return self.btnSlotIndex
end

function BabbInstance:isUfoProxy()
    return UfoProxy:isOnBtn(self)
end

function BabbInstance:isUfoPlaceholder(event)
    return Placeholder:isOn(self, event)
end

function BabbInstance:getFlyoutIdFromUfoProxy()
    return UfoProxy:getFlyoutId()
end

-------------------------------------------------------------------------------
-- Debugger tools
-------------------------------------------------------------------------------

function BabbInstance:printDebugDetails(event, okToGo)
    okToGo = self:notInfiniteLoop(okToGo)
    if not okToGo then return end

    local parent, parentName = self:getParentAndName()
    zebug.warn:event(event):name("details"):owner(self):print("IsShown",self:IsShown(), "IsVisible",self:IsVisible(), "parent", parentName, "germ",self.germ, self:getTypeAndId())
    self.germ:printDebugDetails(event, okToGo)
end

-------------------------------------------------------------------------------
-- toString MAGIC!
-------------------------------------------------------------------------------

function BabbInstance:toString()
    if self == BlizActionBarButton then
        return "nil"
    else
        if self:isEmpty() then
            return string.format("<A-BTN: s%d EMPTY>", nilStr(self.btnSlotIndex))
        else
            local name
            local blizType, blizId = self:getTypeAndId()
            if blizType == ButtonType.MACRO then
                if blizId == UfoProxy:getMacroId() then
                    name = "UfoProxy: ".. (UfoProxy:getFlyoutName() or "UnKnOwN")
                elseif Placeholder:isOn(self, "BlizActionBarButton:toString()") then
                    name = "Placeholder"
                end
            end

            if not name then
                name = self:getNameForBlizThingy(blizType, blizId)
                --print("BlizActionBarButton:toString... d.aId",d.aId, "d.aType",d.aType, "name",name)
            end

            local icon = DEFAULT_ICON_FULL
            if blizId and blizType then
                local btnDef = ButtonDef:new(blizId, blizType)
                icon = btnDef:getIcon()
            end

            if name then
                return string.format("<A-BTN: |T%d:0|t s%d %s: %s>", icon, nilStr(self.btnSlotIndex), nilStr(blizType), name)
            end

            return string.format("<A-BTN: |T%d:0|t s%d, %s:%s>", icon, nilStr(self.btnSlotIndex), nilStr(blizType), nilStr(blizId))
        end
    end
end
