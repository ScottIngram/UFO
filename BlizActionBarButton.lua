-- BlizActionBarButton
-- simplifies tracking what's on the action bars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@alias BABB_INHERITANCE UfoMixIn | ActionBarActionButtonMixin | Button_Mixin | ActionButtonTemplate | SecureActionButtonTemplate | Frame
---@alias BABB_TYPE BlizActionBarButton | BABB_INHERITANCE

---@class BlizActionBarButton : UfoMixIn
---@field btnDesc AbbInfo meta data about the button
---@field ufoType string The classname
BlizActionBarButton = {
    ufoType = "BlizActionBarButton"
}
UfoMixIn:mixInto(BlizActionBarButton)

---@class AbbInfo describes various aspects of a button on the Bliz action bars
---@field btnSlotIndex number the index of the button among all 100+ buttons
---@field barNum number which action bar
---@field btnNum number the index of the button among the 12 on the same bar
---@field actionBarDef table meta data about the button's action bar
---@field barName string one of Bliz's many names for the bar
---@field barYafName string yet another of Bliz's many fucking names for the bar
---@field btnName string one of Bliz's many names for the button
---@field btnYafName string yet another of Bliz's many fucking names for the button
---@field visibleIf string conditions used by RegisterStateDriver(self, "visibility")
---@field aType string type of the spell/macro/etc that's on the button, if any
---@field aId string id of the spell/macro/etc that's on the button, if any

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

---@field name string is how it's identified by /fstack and thus the name of its _G global variable and its buttons
---@field yafName string yet another fucking name is how it's identified by the key bindings API
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
    [18] = {name="OverrideActionBar",   }, -- vehicle
    [19] = {name="ExtraAction",         }, -- center screen popup spell

}

-------------------------------------------------------------------------------
--  Methods
-------------------------------------------------------------------------------

-- gets the UI frame object for the button / empty slot sitting in btnSlotIndex on the Bliz action bars.
-- such a button could be EMPTY or contain a spell, a macro, a potion, etc.
---@return BlizActionBarButton, AbbInfo
function BlizActionBarButton:new(btnSlotIndex, event)
    assert(btnSlotIndex, "invalid nil value for btnSlotIndex")
    local barNum, barName, btnNum, btnName, actionBarDef, btn = getBarNumAndBtnNum(btnSlotIndex)

    -- during UI reloads, sometimes Bliz's shitty API reports that we're using the non-existent action bar #0.  Fuck you Bliz.
    if barNum == 0 then return end

    local barYafName = actionBarDef.yafName
    local btnYafName = barYafName and (barYafName .. "Button" .. btnNum) or nil
    local actionType, actionId = GetActionInfo(btnSlotIndex)

    ---@type AbbInfo
    local btnDesc = {
        btnSlotIndex = btnSlotIndex,
        barNum       = barNum,
        btnNum       = btnNum,
        actionBarDef = actionBarDef,
        barName      = barName,
        barYafName   = actionBarDef.yafName,
        btnName      = btnName,
        btnYafName   = btnYafName,
        visibleIf    = actionBarDef.visibleIf,
        aType        = actionType,
        aId          = actionId,
    }

    ---@type BlizActionBarButton
    local protoSelf = btn -- default to the standard Bliz object

    if ThirdPartyAddonSupport.isAnyActionBarAddonActive then
        protoSelf = ThirdPartyAddonSupport:getParent(btnDesc)
    end

    -- TAINT RISK - be careful to not affect any fields or methods used by Bliz

    protoSelf.btnDesc = btnDesc

    local mt = getmetatable(protoSelf)
    if not mt then
        mt = {}
        setmetatable(protoSelf, mt)
    end
    mt.__tostring = function()
        return BlizActionBarButton.toString(protoSelf)
    end

    ---@type BlizActionBarButton
    local self = deepcopy(BlizActionBarButton, protoSelf)

    return self, btnDesc
end

BlizActionBarButton.get = BlizActionBarButton.new

---@return number barNum
---@return string barName
---@return number btnNum
---@return string btnName
---@return table meta data about the action bar
---@return BABB_INHERITANCE the actual UI Frame object
function getBarNumAndBtnNum(btnSlotIndex)
    -- TODO: memoize
    assert(btnSlotIndex, "btnSlotIndex is nil.  Try again, plz!")
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)

    -- during UI reloads, sometimes Bliz's shitty API reports that we're using the non-existent action bar #0.  Fuck you Bliz.
    if barNum == 0 then return end

    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum.." resulting from event: ".. tostring(event)) -- in case Blizzard adds more bars, complain here clearly.

    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local barName = actionBarDef.name
    local btnName = barName .. "Button" .. btnNum
    local btn = _G[btnName]

    return barNum, barName, btnNum, btnName, actionBarDef, btn
end

---@return BABB_INHERITANCE
function BlizActionBarButton:getLiteralBlizBtn(btnSlotIndex)
    local _, _, _, _, _, btn = getBarNumAndBtnNum(btnSlotIndex)
    return btn
end

---@return boolean true if Not An Instance
function BlizActionBarButton:amTheClass()
    return self == BlizActionBarButton
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return boolean true if the btn has nothing on it
function BlizActionBarButton:isEmpty(btnSlotIndex)
    ---@type BABB_TYPE
    local self = self

    if self:amTheClass() then
        self = self:getLiteralBlizBtn(btnSlotIndex)
    end

    return not (self and self.HasAction and self:HasAction())
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return ButtonType
function BlizActionBarButton:getType(btnSlotIndex)
    if self:amTheClass() then
        local actionType, actionId = GetActionInfo(btnSlotIndex)
        return actionType
    else
        return self.btnDesc.aType
    end
end

function BlizActionBarButton:getId()
    ---@type BABB_TYPE
    local self = self
    return self.btnDesc.aId
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return number the id of the spell/macro/etc
function BlizActionBarButton:getId(btnSlotIndex)
    if self:amTheClass() then
        local actionType, actionId = GetActionInfo(btnSlotIndex)
        return actionId
    else
        return self.btnDesc.aId
    end
end

function BlizActionBarButton:getBtnSlotIndex()
    ---@type BABB_TYPE
    local self = self
    return self.btnDesc.btnSlotIndex
end

function BlizActionBarButton:isUfoProxy()
    return UfoProxy:isOnBtn(self)
end

---@param btnSlotIndex number|nil required only during a class invocation and not via an instance which would already know its btnSlotIndex
---@return boolean true if the btn contains a UfoProxy
function BlizActionBarButton:isUfoProxy(btnSlotIndex)
    if self:amTheClass() then
        return UfoProxy:isOnBtnSlot(btnSlotIndex)
    end

    return UfoProxy:isOnBtn(self)
end




-- unused?
function BlizActionBarButton:isUfoPlaceholder(event)
    return Placeholder:isOn(self, event)
end

function BlizActionBarButton:getFlyoutIdFromUfoProxy()
    return UfoProxy:getFlyoutId()
end

local s = function(v) return v or "nil"  end

function BlizActionBarButton:toString()
    if self == BlizActionBarButton then
        return "nil"
    else
        local d = self.btnDesc
        if self:isEmpty() then
            return string.format("<A-BTN: s%d EMPTY>", s(d.btnSlotIndex))
        else
            local name
            if d.aType == ButtonType.MACRO then
                if d.aId == UfoProxy:getMacroId() then
                    name = "UfoProxy: ".. (UfoProxy:getFlyoutName() or "UnKnOwN")
                elseif Placeholder:isOn(self, "BlizActionBarButton:toString()") then
                    name = "Placeholder"
                end
            end

            if not name then
                name = self:getNameForBlizThingy(d.aId, d.aType)
                --print("BlizActionBarButton:toString... d.aId",d.aId, "d.aType",d.aType, "name",name)
            end

            if name then
                return string.format("<A-BTN: s%d %s: %s>", s(d.btnSlotIndex), s(d.aType), name)
            end

            return string.format("<A-BTN: s%d, %s:%s>", s(d.btnSlotIndex), s(d.aType), s(d.aId))
        end
    end
end
