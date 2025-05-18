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
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum.." resulting from event: ".. tostring(event)) -- in case Blizzard adds more bars, complain here clearly.
    local barName    = actionBarDef.name
    local btnName    = barName .. "Button" .. btnNum
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
    local actionBarBtnFrame  = _G[btnDesc.btnName] -- default to the standard Bliz object

    if ThirdPartyAddonSupport.isAnyActionBarAddonActive then
        actionBarBtnFrame = ThirdPartyAddonSupport:getParent(btnDesc)
    end

    -- TAINT RISK - be careful to not affect any fields or methods used by Bliz

    actionBarBtnFrame.btnDesc = btnDesc

    local mt = getmetatable(actionBarBtnFrame)
    if not mt then
        mt = {}
        setmetatable(actionBarBtnFrame, mt)
    end
    mt.__tostring = function()
        return BlizActionBarButton.toString(actionBarBtnFrame)
    end
    deepcopy(BlizActionBarButton, actionBarBtnFrame)

    return actionBarBtnFrame, btnDesc
end

BlizActionBarButton.get = BlizActionBarButton.new

function BlizActionBarButton:isEmpty()
    ---@type BABB_TYPE
    local self = self
    return not self:HasAction() -- (self:HasAction() or self:HasPopup())
end

function BlizActionBarButton:getType()
    ---@type BABB_TYPE
    local self = self
    return self.btnDesc.aType
end

function BlizActionBarButton:getId()
    ---@type BABB_TYPE
    local self = self
    return self.btnDesc.aId
end

function BlizActionBarButton:getBtnSlotIndex()
    ---@type BABB_TYPE
    local self = self
    return self.btnDesc.btnSlotIndex
end

function BlizActionBarButton:isUfoProxy()
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
            return string.format("<A-BTN: slot=%d EMPTY>", s(d.btnSlotIndex))
        else
            local id = d.aId
            if d.aType == ButtonType.MACRO then
                if id == UfoProxy:getMacroId() then
                    id = "UfoProxy: ".. (UfoProxy:getFlyoutName() or "UnKnOwN")
                elseif Placeholder:isOn(self, "BlizActionBarButton:toString()") then
                    id = "Placeholder"
                end
            end
            return string.format("<A-BTN: slot=%d, type=%s, id=%s>", s(d.btnSlotIndex), s(d.aType), s(id))
        end
    end
end
