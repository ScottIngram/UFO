-- ActionBarButtonMixin

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@class ActionBarButtonMixin -- IntelliJ-EmmyLua annotation
ActionBarButtonMixin = { }

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
}


-------------------------------------------------------------------------------
--  Methods
-------------------------------------------------------------------------------

function ActionBarButtonMixin:inject(other)
    for name, func in pairs(self) do
        other[name] = func
    end
end

function ActionBarButtonMixin:getActionBarBtn(bbInfo)
    local actionBarBtn
    if ThirdPartyAddonSupport.isAnyActionBarAddonActive then
        actionBarBtn = ThirdPartyAddonSupport:getParent(bbInfo)
    end
    if not actionBarBtn then
        actionBarBtn = _G[bbInfo.btnName] -- default to the standard Bliz object
    end
    actionBarBtn.visibleIf = bbInfo.visibleIf
    return actionBarBtn
end

function ActionBarButtonMixin:extractBarBtnInfo(btnSlotIndex)
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.
    local barName    = actionBarDef.name
    local btnName    = barName .. "Button" .. btnNum
    local barYafName = actionBarDef.yafName
    local btnYafName = barYafName and (barYafName .. "Button" .. btnNum) or nil

    return {
        btnSlotIndex = btnSlotIndex,
        barNum       = barNum,
        btnNum       = btnNum,
        actionBarDef = actionBarDef,
        barName      = barName,
        barYafName   = actionBarDef.yafName,
        btnName      = btnName,
        btnYafName   = btnYafName,
        visibleIf    = actionBarDef.visibleIf,
    }
end

