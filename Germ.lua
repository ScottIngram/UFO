-- Germ
-- is a button on the actionbars that opens & closes a copy of a flyout menu from the catalog.
-- One flyout menu can be duplicated across numerous actionbar buttons, each being a seperate germ.

-- is a standard bliz CheckButton frame but with extra attributes attached.
-- Once created it always exists at its original actionbar slot, but, may be assigned a different flyout menu or none at all.
-- a.k.a launchpad, egg, exploder, torpedo, detonator, originator, impetus, genesis, bigBang, singularity...

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@alias GERM_INHERITANCE UfoMixIn | Button_Mixin | ActionButtonTemplate | SecureActionButtonTemplate | Button | Frame | ScriptObject
---@alias GERM_TYPE Germ | GERM_INHERITANCE

---@class Germ : UfoMixin
---@field ufoType string The classname
---@field flyoutId number Identifies which flyout is currently copied into this germ
---@field flyoutMenu FM_TYPE The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
---@field clickScriptUpdaters table secure scriptlets that must be run during any update()
---@field bbInfo table definition of the actionbar/button where the Germ lives
---@field visibleIf string for RegisterStateDriver -- uses macro-conditionals to control visibility automatically
---@field visibilityDriver string primarily for debugging
---@field myName string duh
---@field label string human friendly identifier

---@type Germ | GERM_INHERITANCE
Germ = {
    ufoType = "Germ",
    --clickScriptUpdaters = {},
    clickers = {},
}
UfoMixIn:mixInto(Germ)
GLOBAL_Germ = Germ

---@class GermClickBehavior
GermClickBehavior = {
    OPEN = "OPEN",
    FIRST_BTN = "FIRST_BTN",
    RANDOM_BTN = "RANDOM_BTN",
    CYCLE_ALL_BTNS = "CYCLE_ALL_BTNS",
    --REVERSE_CYCLE_ALL_BTNS = "REVERSE_CYCLE_ALL_BTNS",
}

---@type Germ|GERM_INHERITANCE
local GermClickBehaviorAssignmentFunction = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@type GERM_TYPE for the benefit of my IDE's autocomplete
local ScriptHandlers = {}
local HANDLER_MAKERS_MAP
local SEC_ENV_SCRIPT_FOR_OPENER
local SEC_ENV_SCRIPT_FOR_ON_CLICK

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
local KEY_PREFIX_FOR_ON_CLICK = "BEHAVIOR_FOR_MOUSE_CLICK_"
local SEC_ENV_SCRIPT_NAME_FOR_OPEN = "SEC_ENV_SCRIPT_NAME_FOR_OPEN"
local MOUSE_BUTTONS = {
    MouseClick.LEFT,
    MouseClick.MIDDLE,
    MouseClick.RIGHT,
    MouseClick.FOUR,
    MouseClick.FIVE,
}

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ:new(flyoutId, btnSlotIndex, event)
    local parentBlizActionBarBtn = BlizActionBarButtonHelper:get(btnSlotIndex, "Germ:New() for btnSlotIndex"..btnSlotIndex)
    local parentBtn3rdParty      = ThirdPartyAddonSupport:getBtnParentAsProvidedByAddon(parentBlizActionBarBtn)
    local parentBtn              = parentBtn3rdParty or parentBlizActionBarBtn

    --print("Germ parentActionBarBtn",parentActionBarBtn, "parentActionBarBtn.GetName", parentActionBarBtn.GetName)
    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentBtn:GetName()

    ---@type GERM_TYPE | Germ
    local self = CreateFrame(
            FrameType.CHECK_BUTTON,
            myName,
            parentBtn,
            "GermTemplate"
    )

    _G[myName] = self -- so that keybindings can reference it
    parentBtn.germ = self

    -- one-time only initialization --
    self.myName       = myName -- who
    self.btnSlotIndex = btnSlotIndex -- where
    self.flyoutId     = flyoutId -- what

    -- manipulate methods
    self:installMyToString() -- do this as soon as possible for the sake of debugging output
    self.originalHide = self:override("Hide", self.hide)

    -- install event handlers
    self:HookScript(Script.ON_HIDE,        function(self) zebug.info:owner(self):event("Script.ON_HIDE"):print('byeeeee'); end) -- This fires IF the germ is on a dynamic action bar that switches (stance / druid form / etc. or on clearAndDisable() or on a spec change which throws away placeholders
    self:SetScript(Script.ON_ENTER,        ScriptHandlers.ON_ENTER)
    self:SetScript(Script.ON_LEAVE,        ScriptHandlers.ON_LEAVE)
    self:SetScript(Script.ON_RECEIVE_DRAG, ScriptHandlers.ON_RECEIVE_DRAG)
    self:SetScript(Script.ON_MOUSE_DOWN,   ScriptHandlers.ON_MOUSE_DOWN)
    self:SetScript(Script.ON_MOUSE_UP,     ScriptHandlers.ON_MOUSE_UP) -- is this short-circuiting my attempts to get the buttons to work on mouse up?
    self:SetScript(Script.ON_DRAG_START,   ScriptHandlers.ON_DRAG_START) -- this is required to get OnDrag to work
    self:registerForBlizUiActions(event)

    -- Secure Shenanigans required before initFlyoutMenu()
    SecureHandler_OnLoad(self) -- install self:SetFrameRef()

    -- FlyoutMenu
    self.flyoutMenu = self:initFlyoutMenu(event)
    self:initializeSecEnv(event)       -- depends on initFlyoutMenu() above
    self:assignAllMouseClickers(event) -- depends on initializeSecureClickers() above

    -- UI positioning & appearance
    self:ClearAllPoints()
    self:SetAllPoints(parentBtn)
    self:initLabel()
    self:doIcon(event)
    self.Name:SetText(self.label)
    self:setVisibilityDriver(parentBlizActionBarBtn.visibleIf) -- do I even need this? when the parent Hides so will the Germ automatically

    -- secure tainty stuff
    self:copyDoCloseOnClickConfigValToAttribute()
    self:doMyKeybinding() -- bind me to my action bar slot's keybindings (if any)

    -- Blizz things
    ButtonStateBehaviorMixin.OnLoad(self)
    self:UpdateArrowShown()
    self:UpdateArrowPosition()
    self:UpdateArrowRotation()

    return self
end

function Germ:render(event)
    if self:isInactive(event) then return end
    self:safelySetSecEnvAttribute(SecEnvAttribute.flyoutDirection, self:getDirection(event))
    self:UpdateArrowRotation() -- VOLATILE if action bar changes direction... and changes when open/closed
    self:renderCooldownsAndCountsAndStatesEtc(event) -- TODO: v11.1 verify this is working properly.  do I need to do more? -- What happens if I remove this?
    self.flyoutMenu:renderAllBtnCooldownsEtc(event)
end

function Germ:notifyOfChangeToFlyoutDef(event)
    self:closeFlyout() -- in case the number of buttons changed?
    self:applyConfigFromFlyoutDef(event)
end

function Germ:applyConfigFromFlyoutDef(event)
    self:doIcon(event)
    self.Name:SetText(self:getLabel())
    self:updateClickerForBtn1(event)
    self:closeFlyout() -- in case the buttons' number/ordering changes
    self.flyoutMenu:applyConfigForGerm(self, event)
end

function Germ:getName()
    return self:GetName()
end

function Germ:copyToCursor(eventId)
    self:copyFlyoutToCursor(self.flyoutId, eventId)
end

function Germ:getLabel()
    self.label = self.flyoutId and self:getFlyoutDef().name
    return self.label
end

Germ.initLabel = Germ.getLabel

function Germ:getBtnSlotIndex()
    return self.btnSlotIndex
end

---@return string
function Germ:getFlyoutId()
    return self.flyoutId
end

function Germ:isActive(event)
    --zebug.trace:event(event or "UnKnOwN"):owner(self):print("am I active?", self.flyoutId and true or false)
    return self.flyoutId and true or false
end

function Germ:isInactive(event)
    return not (self.flyoutId and true or false)
end

function Germ:isActiveAndHasFoo(funcName, event)
    if not self:isActive() then return false end
    local flyoutDef = self:getFlyoutDef()
    local func = flyoutDef[funcName]
    local hasIt = func(flyoutDef, event)
    zebug.info:event(event):owner(self):print(funcName,hasIt)
    return hasIt
end

function Germ:hasItemsAndIsActive(event)
    return self:isActiveAndHasFoo("hasItem", event)
end

function Germ:hasMacrosAndIsActive(event)
    return self:isActiveAndHasFoo("hasMacro", event)
end

function Germ:hasSpellsAndIsActive(event)
    return self:isActiveAndHasFoo("hasSpell", event)
end

function Germ:hasFlyoutId(flyoutId)
    return self:getFlyoutId() == flyoutId
end

---@return string
function Germ:getFlyoutName()
    return self:getFlyoutDef():getName()
end

function Germ:getIcon()
    if not self.flyoutId then return DEFAULT_ICON end
    local flyoutDef = FlyoutDefsDb:get(self.flyoutId)
    local usableFlyout = flyoutDef:filterOutUnusable()
    return usableFlyout:getIcon() or flyoutDef.fallbackIcon or DEFAULT_ICON
end

function Germ:doIcon(event)
    local icon = self:getIcon()
    self:setIcon(icon, event)
end

function Germ:glowStart()
    SharedActionButton_RefreshSpellHighlight(self, true)
end

function Germ:glowStop()
    SharedActionButton_RefreshSpellHighlight(self, false)
end

function Germ:initFlyoutMenu(event)
    self.flyoutMenu = FlyoutMenu:new(self)
    zebug.info:event(event):owner(self):line("20","initFlyoutMenu",self.flyoutMenu)
    self.flyoutMenu:applyConfigForGerm(self, event)
    self:SetPopup(self.flyoutMenu) -- put my FO where Bliz expects it
    self.flyoutMenu.isForGerm = true
    return self.flyoutMenu
end

-- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
function Germ:setVisibilityDriver(visibleIf)
    self.visibleIf = visibleIf
    zebug.trace:owner(self):print("visibleIf",visibleIf)
    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        self.visibilityDriver = "["..stateCondition.."] show; hide"
        RegisterStateDriver(self, "visibility", self.visibilityDriver)
    else
        UnregisterStateDriver(self, "visibility")
        self.visibilityDriver = nil -- just for debugging
    end
end

function Germ:closeFlyout()
    self.flyoutMenu:close()
end

-- will replace Germ:Hide() via Germ:new()
-- TODO is this serving the same purpose as clearAndDisable ?
function Germ:hide(event)
    --VisibleRegion:Hide(self) -- L-O-FUCKING-L this threw  "attempt to index global 'VisibleRegion' (a nil value)" was called from SecureStateDriver.lua:103
    zebug.info:event(event or "Blizz-Call"):owner(self):print("hiding.")
    UnregisterStateDriver(self, "visibility")
    self:originalHide()
end

function Germ:clearAndDisable(event)
    zebug.info:event(event):owner(self):print("DISABLE GERM :-(")
    self:closeFlyout()
    self:hide(event)
    self:clearKeybinding()
    self:setVisibilityDriver(nil) -- must be restored if Germ comes back -- TODO: move into registerForBlizUiActions() ?
    self:unregisterForBlizUiActions()
    self:Disable() -- replaces all (well, most) of the above?
    self.flyoutId = nil
    self.label = nil
end

Germ.clearAndDisable = Pacifier:wrap(Germ.clearAndDisable)

function Germ:changeFlyoutIdAndEnable(flyoutId, event)
    self.flyoutId = flyoutId
    zebug.info:event(event):owner(self):print("EnAbLe GeRm :-)")

    self:closeFlyout()
    self:doIcon(event)
    self.flyoutMenu:applyConfigForGerm(self, event)
    self:registerForBlizUiActions(event)
    self:doMyKeybinding()
    self:Show()
    self:updateClickerForBtn1(event)
    self:Enable()
end

function Germ:pickupFromSlotAndClear(event)
    if isInCombatLockdown("Drag and drop") then return end

    -- grab needed info before it gets cleared
    local btnSlotIndex = self:getBtnSlotIndex()
    local pickingUpThisFlyoutId = self.flyoutId

    -- erase Ufo From the slot
    GermCommander:eraseUfoFrom(btnSlotIndex, self, event)

    -- the ON_DRAG_START event apparently precedes the cursor change
    -- so, handle whatever is currently on the cursor, if anything.
    local cursorBeforeItDrops = Cursor:get()
    if cursorBeforeItDrops then
        zebug.info:event(event):owner(self):print("cursorBeforeItDrops", cursorBeforeItDrops)
        local foo = cursorBeforeItDrops:isUfoProxy()
        if cursorBeforeItDrops:isUfoProxy() then
            -- the user is dragging a UFO
            local droppingThisFlyoutId = UfoProxy:getFlyoutId()
            GermCommander:dropDraggedUfoFromCursorOntoActionBar(btnSlotIndex, droppingThisFlyoutId, event)
        else
            -- the user is just dragging a normal Bliz spell/item/etc.
            -- Cursor:dropOntoActionBar(btnSlotIndex, eventId) -- this is already happening without me needing to do anything, yes?
        end
    end

    UfoProxy:pickupUfoOntoCursor(pickingUpThisFlyoutId, event)
end

---@return BlizActionBarButton
function Germ:getParent()
    return self:GetParent()
end

function Germ:getDirection(event)
    -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs
    local parent = self:getParent()
    -- check if my ThirdPartyAddonSupport has provided a method
    if parent.GetSpellFlyoutDirection then
        return parent:GetSpellFlyoutDirection(event)
    end
    -- use the std Bliz method
    return parent.bar:GetSpellFlyoutDirection(event)
end

function Germ:updateAllBtnHotKeyLabels(event)
    self.flyoutMenu:applyConfigForGerm(self, event)
end

function Germ:copyDoCloseOnClickConfigValToAttribute()
    -- haven't figured out why it doesn't work on the germ but does on the flyout
    --zebug.trace:mCross():owner(self):print("self.flyoutMenu",self.flyoutMenu, "setting new value from Config.opts.doCloseOnClick", Config.opts.doCloseOnClick)
    self:setSecEnvAttribute("doCloseOnClick", Config.opts.doCloseOnClick)
    return self.flyoutMenu and self.flyoutMenu:setSecEnvAttribute("doCloseOnClick", Config.opts.doCloseOnClick)
end

Germ.copyDoCloseOnClickConfigValToAttribute = Pacifier:wrap(Germ.copyDoCloseOnClickConfigValToAttribute, L10N.RECONFIGURE_AUTO_CLOSE)

function Germ:setToolTip()
    local btn1 = self.flyoutMenu:getBtn1()
    if btn1 and btn1.hasDef and btn1:hasDef() then
        btn1:setTooltip()
        return
    end

    local flyoutDef = FlyoutDefsDb:get(self.flyoutId)
    local label = flyoutDef.name or flyoutDef.id

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
    else
        GameTooltip:SetOwner(self, TooltipAnchor.LEFT)
    end

    GameTooltip:SetText(label)
end

---@return FlyoutDef
function Germ:getFlyoutDef()
    return FlyoutDefsDb:get(self.flyoutId)
end

function Germ:getUsableFlyoutDef()
    return self:getFlyoutDef():filterOutUnusable()
end

function Germ:getBtnDef(n)
    -- treat the first button in the flyout as the "definition" for the Germ
    return self:getUsableFlyoutDef():getButtonDef(n)
end

-- required by Button_Mixin
function Germ:getDef()
    -- treat the first button in the flyout as the "definition" for the Germ
    return self:getBtnDef(1)
end

function Germ:invalidateFlyoutCache()
    self:getFlyoutDef():invalidateCache()
end

function Germ:refreshFlyoutDefAndApply(event)
    zebug.info:event(event):owner(self):name("refreshFlyoutDefAndApply"):print("re-configuring...")
    self:getFlyoutDef():invalidateCacheOfUsableFlyoutDefOnly(event)
    self:applyConfigFromFlyoutDef(event) -- exclude clickers?
end

-------------------------------------------------------------------------------
-- Key Bindings & UI actions Registerings
-------------------------------------------------------------------------------

function Germ:doMyKeybinding()
    if isInCombatLockdown("Keybind") then return end

    local parent = self:getParent()
    local btnName = parent.btnYafName or parent.btnName
    local ucBtnName = string.upper(btnName)
    local myGlobalVarName = self:GetName()
    local keybinds
    if GetBindingKey(ucBtnName) then
        keybinds = { GetBindingKey(ucBtnName) }
    end

    -- add new keybinds
    if keybinds then
        for i, keyName in ipairs(keybinds) do
            if not tableContainsVal(self.keybinds, keyName) then
                zebug.trace:owner(self):print("myGlobalVarName", myGlobalVarName, "binding keyName",keyName)
                SetOverrideBindingClick(self, true, keyName, myGlobalVarName, MouseClick.SIX)
            else
                zebug.trace:owner(self):print("myGlobalVarName", myGlobalVarName, "NOT binding keyName",keyName, "because it's already bound.")
            end
        end
        local keybind1 = keybinds[1]
        self:setHotKeyOverlay(keybind1)
        if not isNumber(keybind1) then
            -- store it for use inside the secure code
            -- so we can make the first button's keybind be the same as the UFO's
            self:setSecEnvAttribute("UFO_KEYBIND_1", keybind1)
        end
    else
        self:setHotKeyOverlay(nil)
    end

    -- remove deleted keybinds
    if (self.keybinds) then
        for i, keyName in ipairs(self.keybinds) do
            if not tableContainsVal(keybinds, keyName) then
                zebug.trace:owner(self):print("myGlobalVarName", myGlobalVarName, "UN-binding keyName",keyName)
                SetOverrideBinding(self, true, keyName, nil)
            else
                zebug.trace:owner(self):print("myGlobalVarName", myGlobalVarName, "NOT UN-binding keyName",keyName, "because it's still bound.")
            end
        end
    end

    self.keybinds = keybinds
end

Germ.doMyKeybinding = Pacifier:wrap(Germ.doMyKeybinding, L10N.CHANGE_KEYBINDING)

function Germ:clearKeybinding()
    if not (self.keybinds) then return end

    exeOnceNotInCombat("Keybind removal "..self:getName(), function()
        -- FUNC START
        ClearOverrideBindings(self)
        self:setHotKeyOverlay(nil)
        self.keybinds = nil
        -- FUNC END
    end)

end

function Germ:registerForBlizUiActions(event)
    self:maybeRegisterForClicksDependingOnCursorIsEmpty(event) -- this must be done regardless of isEventStuffRegistered

    if self.isEventStuffRegistered then return end

    self:EnableMouseMotion(true)
    self:RegisterForDrag(MouseClick.LEFT)
    --self:RegisterEvent("CURSOR_CHANGED") -- now handled by Ufo.lua

    self.isEventStuffRegistered = true
end

function Germ:maybeRegisterForClicksDependingOnCursorIsEmpty(event)
    local type, id = GetCursorInfo()
    local enable = not type
    local wut = enable and "cursor is empty so clicks are Enabled" or "cursor is occupied so clicks are IGNORED"
    --zebug.info:mStar():mMoon():mCross():event(event):owner(self):print("enable",enable, "GetCursorInfo->",GetCursorInfo, "GetCursorInfo->type",type, "GetCursorInfo->id",id,  "Cursor:getFresh()",Cursor:getFresh(event), wut)
    zebug.trace:event(event):owner(self):print(wut)
    if enable then
        self:RegisterForClicks("AnyDown", "AnyUp") -- protected.  Pacify.
    else
        self:RegisterForClicks()
    end
end

Germ.maybeRegisterForClicksDependingOnCursorIsEmpty = Pacifier:wrap(Germ.maybeRegisterForClicksDependingOnCursorIsEmpty)

-- and here
function Germ:unregisterForBlizUiActions()
    if not self.isEventStuffRegistered then return end

    self:EnableMouseMotion(false)
    self:RegisterForDrag("Button6Down")
    self:RegisterForClicks("Button6Down")

    self.isEventStuffRegistered = false
end

function Germ:handleReceiveDrag(event)
    if isInCombatLockdown("Drag and drop") then return end
    local cursor = Cursor:get()
    if cursor then
        Ufo.germLock = event

        local flyoutIdOld = self.flyoutId

        if cursor:isUfoProxy() then
            -- soup to nuts. do everything without relying on the ACTIONBAR_SLOT_CHANGED handler
            -- don't let the UfoProxy hit the actionbar.
            zebug.info:event(event):owner(self):print("cursor is a proxy",cursor)
            local flyoutIdNew = UfoProxy:getFlyoutId()
            self:changeFlyoutIdAndEnable(flyoutIdNew, event)
            Placeholder:put(self.btnSlotIndex, event) -- will discard the UfoProxy in favor of a Placeholder
            GermCommander:savePlacement(self.btnSlotIndex, flyoutIdNew, event)
        else
            zebug.info:event(event):owner(self):print("just got hit by rando",cursor)
            self:clearAndDisable(event)
            GermCommander:forgetPlacement(self.btnSlotIndex, event)
            cursor:dropOntoActionBar(self.btnSlotIndex, event)
        end

        if flyoutIdOld then
            zebug.info:mMoon():event(event):owner(self):print("--------- PRE  UfoProxy:PICKUP", GetCursorInfo(), Cursor:get())
            UfoProxy:pickupUfoOntoCursor(flyoutIdOld, event)
            zebug.info:mMoon():event(event):owner(self):print("--------- POST UfoProxy:PICKUP", GetCursorInfo(), Cursor:get())
        else
            cursor:clear(event) -- will discard the UfoProxy if it's still there
        end

        Ufo.germLock = nil
    end
end

-------------------------------------------------------------------------------
-- Handlers
-------------------------------------------------------------------------------

function ScriptHandlers:ON_MOUSE_DOWN(mouseClick)
    local cursor = Cursor:get()
    zebug.info:mDiamond():owner(self):newEvent(self, "ScriptHandlers.ON_MOUSE_DOWN"):run(function(event)
        self:OnMouseDown() -- Call Bliz super()

        if cursor then
            -- self:handleReceiveDrag(event)
        else
            zebug.info:owner(self):event(event):name("ScriptHandlers:ON_MOUSE_DOWN"):print("not dragging, so, exiting. proxy",UfoProxy, "mySlotBtn",mySlotBtn)
        end
    end, cursor)
end

function ScriptHandlers:ON_MOUSE_UP()
    zebug.info:mCross():owner(self):newEvent(self, "ScriptHandlers.ON_MOUSE_UP"):run(function(event)
        self:OnMouseUp() -- Call Bliz super()

        local isDragging = GetCursorInfo()
        local mySlotBtn = BlizActionBarButtonHelper:get(self.btnSlotIndex, event)
        if isDragging then
            self:handleReceiveDrag(event)
        else
            zebug.info:owner(self):event(event):name("ScriptHandlers:ON_MOUSE_UP"):print("not dragging, so, exiting. proxy",UfoProxy, "mySlotBtn",mySlotBtn)
        end
    end)
end

-- A germ on the action bar was just hit by something dropping off the user's cursor
-- The something is either a std Bliz thingy,
-- or, a UFO (which itself is represented by the "proxy" macro)
---@param self GERM_TYPE
function ScriptHandlers:ON_RECEIVE_DRAG()
    if isInCombatLockdown("Drag and drop") then return end
    zebug.info:mCircle():owner(self):newEvent(self, "ON_RECEIVE_DRAG"):run(function(event)
        self:handleReceiveDrag(event)
    end)
end

function ScriptHandlers:ON_DRAG_START()
    if LOCK_ACTIONBAR then return end
    if not IsShiftKeyDown() then return end
    if isInCombatLockdown("Drag and drop") then return end
    self:OnDragStart() -- Call Bliz super()

    zebug.info:mCircle():owner(self):newEvent(self, "ON_DRAG_START"):run(function(event)
        self:pickupFromSlotAndClear(event)
    end)
end

function ScriptHandlers:ON_ENTER()
    if self:isInactive() then return end
    self:OnEnter() -- Call Bliz super()

    zebug.info:mDiamond():owner(self):newEvent(self, "ON_ENTER"):run(function(event)
        self:setToolTip()
    end)
end

function ScriptHandlers:ON_LEAVE()
    self:OnLeave() -- Call Bliz super()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
--
-- SecEnv Mouse Click Handling
--
-- a bunch of code to make calls to SetAttribute("type",action) or ON_CLICK etc
-- to enable the Germ's button to do things in response to mouse clicks
-------------------------------------------------------------------------------

function Germ:initializeSecEnv(event)
    assert(self.flyoutMenu, "do initFlyoutMenu() first")

    -- set attributes used inside the secure scripts
    self:setSecEnvAttribute("DO_DEBUG", not zebug.info:isMute() )
    self:setSecEnvAttribute("UFO_NAME", self:getLabel())
    self:setSecEnvAttribute(SecEnvAttribute.flyoutDirection, self:getDirection(event))
    self:setSecEnvAttribute("doKeybindTheButtonsOnTheFlyout", Config:get("doKeybindTheButtonsOnTheFlyout"))
    self:SetFrameRef("flyoutMenu", self.flyoutMenu)

    -- set global variables inside the restricted environment of the germ
    self:Execute([=[
        germ       = self
        flyoutMenu = germ:GetFrameRef("flyoutMenu")
        myName     = self:GetAttribute("UFO_NAME")
        doDebug    = self:GetAttribute("DO_DEBUG") or false
    ]=])

    self:installSecEnvScriptFor_Opener()
    self:installSecEnvScriptFor_ON_CLICK()
end

function Germ:assignAllMouseClickers(event)
    -- loop over all mouse buttons: LEFT, MIDDLE, etc.
    for _, mouseClick in ipairs(MOUSE_BUTTONS) do
        -- assign each one a behavior: OPEN, RANDOM_BTN, etc.
        local behaviorName = Config:getGermClickBehavior(self.flyoutId, mouseClick)
        self:assignTheMouseClicker(mouseClick, behaviorName, event)
    end

    self:updateClickerForKeybind(event)
end

-- sets secure environment scripts to handle mouse clicks (left button, right button, etc)
---@param mouseClick MouseClick
---@param behaviorName GermClickBehavior
function Germ:assignTheMouseClicker(mouseClick, behaviorName, event)
    if not GermClickBehavior[behaviorName] then
        error("Invalid 'behaviorName' arg: " .. behaviorName) -- type checking in Lua!
    end

    local behave = GermClickBehaviorAssignmentFunction[behaviorName]
    if not behave then
        error(behave, "there is no method defined for GermClickBehavior of ".. behaviorName)
    end

    zebug.info:owner(self):event(event):print("mouseClick",mouseClick, "behaviorName", behaviorName, "handler", behave)
    behave(self, mouseClick, event)
end

-- the secEnv handler for "click the first button of the flyout" is special.
-- it won't automatically accommodate changes to the flyout buttons and must be re-applied for any changes to flyoutDef
-- TODO: consider folding it into the ON_CLICK script along with the RANDOM_BTN and CYCLE_ALL_BTNS
function Germ:updateClickerForBtn1(event)
    -- loop over all mouse buttons
    for _, mouseClick in ipairs(MOUSE_BUTTONS) do
        local behaviorName = Config:getGermClickBehavior(self.flyoutId, mouseClick)
        if behaviorName == GermClickBehavior.FIRST_BTN then
            self:assignTheMouseClicker(mouseClick, behaviorName, event)
        end
    end
end

function Germ:updateClickerForKeybind(event)
    local keybindBehavior = Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior
    self:assignTheMouseClicker(MouseClick.SIX, keybindBehavior, event)
end

---@param mouseClick MouseClick
---@param clickBehavior GermClickBehavior
function Germ:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, clickBehavior)
    local name = KEY_PREFIX_FOR_ON_CLICK .. mouseClick
    self:setSecEnvAttribute(name, clickBehavior)
end

-------------------------------------------------------------------------------
--
-- SecEnv - GermClickBehaviorAssignmentFunction
-- deal with OPEN / FIRST_BTN / RANDOM_BTN / CYCLE_ALL_BTNS
--
-------------------------------------------------------------------------------

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:OPEN(mouseClick, event)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, nil)
    zebug.info:event(event):owner(self):name("HandlerMakers:OpenFlyout"):print("mouseClick",mouseClick)
    self:assignSecEnvMouseClickBehaviorViaAttribute(mouseClick, SEC_ENV_SCRIPT_NAME_FOR_OPEN)
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:FIRST_BTN(mouseClick, event)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, nil)
    self:assignSecEnvMouseClickBehaviorViaAttributeFromBtnDef(mouseClick, event) -- assign attributes, eg: "type1" -> "macro" -> "macro1" -> macroId
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:RANDOM_BTN(mouseClick, event)
    self:assignSecEnvMouseClickBehaviorViaAttribute(mouseClick, nil)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, GermClickBehavior.RANDOM_BTN)
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:CYCLE_ALL_BTNS(mouseClick, event)
    self:assignSecEnvMouseClickBehaviorViaAttribute(mouseClick, nil)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, GermClickBehavior.CYCLE_ALL_BTNS)
end

-------------------------------------------------------------------------------
--
-- SecEnv Scripts
--
-------------------------------------------------------------------------------

function Germ:installSecEnvScriptFor_Opener()
    assert(not self.isOpenerScriptInitialized, "Wut?  The OPENER script is already installed.  Why you call again?")
    self.isOpenerScriptInitialized = true
    self:setSecEnvAttribute("_".. SEC_ENV_SCRIPT_NAME_FOR_OPEN, self:getSecEnvScriptForOpener())
end

function Germ:installSecEnvScriptFor_ON_CLICK()
    assert(not self.onClickScriptInitialized, "Wut?  The ON_CLICK_SCRIPT is already installed.  Why you call again?")
    self.isOnClickScriptInitialized = true
    self:WrapScript(self, Script.ON_CLICK, self:getSecEnvScriptFor_ON_CLICK() )
end

function Germ:getSecEnvScriptForOpener()
    if not SEC_ENV_SCRIPT_FOR_OPENER then
        SEC_ENV_SCRIPT_FOR_OPENER =
[=[
    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "SEC_ENV_SCRIPT_FOR_OPENER <START> germ =", germ, "flyoutMenu =",flyoutMenu)
    --[[DEBUG]] end

    local mouseClick = button
    local isClicked = down
    local direction = germ:GetAttribute( "]=].. SecEnvAttribute.flyoutDirection ..[=[" )
    local isOpen = flyoutMenu:IsShown()

	if isOpen then
	    --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "closing")
        --[[DEBUG]] end
		flyoutMenu:Hide()
		flyoutMenu:ClearBindings()
		return
    end

    flyoutMenu:SetBindingClick(true, "Escape", germ, mouseClick)

-- TODO: move this into FlyoutMenu:updateForGerm()

    flyoutMenu:SetParent(germ)  -- holdover from single FM
    flyoutMenu:ClearAllPoints()
    if direction == "UP" then
        flyoutMenu:SetPoint("BOTTOM", germ, "TOP", 0, 0)
    elseif direction == "DOWN" then
        flyoutMenu:SetPoint("TOP", germ, "BOTTOM", 0, 0)
    elseif direction == "LEFT" then
        flyoutMenu:SetPoint("RIGHT", germ, "LEFT", 0, 0)
    elseif direction == "RIGHT" then
        flyoutMenu:SetPoint("LEFT", germ, "RIGHT", 0, 0)
    end

    local uiButtons = table.new(flyoutMenu:GetChildren())
    while uiButtons[1] and uiButtons[1]:GetObjectType() ~= "CheckButton" do
    --if uiButtons[1]:GetObjectType() ~= "CheckButton" then
        table.remove(uiButtons, 1) -- this is the non-button UI element "Background" from ui.xml
    end

	local prevBtn = nil;
    local numButtons = 0
    for i, btn in ipairs(uiButtons) do
        local isInUse = btn:GetAttribute("UFO_NAME")
        --print(i, numButtons, isInUse)
        if isInUse then
            numButtons = numButtons + 1

            --print("SNIPPET... i:",i, "btn:",btn:GetName())
            btn:ClearAllPoints()

            local parent = prevBtn or "$parent"
            if prevBtn then
                if direction == "UP" then
                    btn:SetPoint("BOTTOM", parent, "TOP", 0, ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[)
                elseif direction == "DOWN" then
                    btn:SetPoint("TOP", parent, "BOTTOM", 0, -]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[)
                elseif direction == "LEFT" then
                    btn:SetPoint("RIGHT", parent, "LEFT", -]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[, 0)
                elseif direction == "RIGHT" then
                    btn:SetPoint("LEFT", parent, "RIGHT", ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[, 0)
                end
            else
                if direction == "UP" then
                    btn:SetPoint("BOTTOM", parent, 0, ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[)
                elseif direction == "DOWN" then
                    btn:SetPoint("TOP", parent, 0, -]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[)
                elseif direction == "LEFT" then
                    btn:SetPoint("RIGHT", parent, -]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[, 0)
                elseif direction == "RIGHT" then
                    btn:SetPoint("LEFT", parent, ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[, 0)
                end
            end

            -- keybind each button to 1-9 and 0
            local doKeybindTheButtonsOnTheFlyout = germ:GetAttribute("doKeybindTheButtonsOnTheFlyout")
            if doKeybindTheButtonsOnTheFlyout then
                if numButtons < 11 then
                    -- TODO: make first keybind same as the UFO's
                    local numberKey = (numButtons == 10) and "0" or tostring(numButtons)
                    flyoutMenu:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
                    if numberKey == "1" then
                        -- make the UFO's first button's keybind be the same as the UFO itself
                        local germKey = self:GetAttribute("UFO_KEYBIND_1")
                        if germKey then
                            flyoutMenu:SetBindingClick(true, germKey, btn, "]=].. MouseClick.LEFT ..[=[")
                        end
                    end
                end
            end

            prevBtn = btn
            btn:Show()
        else
            btn:Hide()
        end
    end

    local w = prevBtn and prevBtn:GetWidth() or 10
    local h = prevBtn and prevBtn:GetHeight() or 10
    local minN = (numButtons == 0) and 1 or numButtons

    if direction == "UP" or direction == "DOWN" then
        flyoutMenu:SetWidth(w)
        flyoutMenu:SetHeight((h + ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[) * minN - ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[ + ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[ + ]=].. SPELLFLYOUT_FINAL_SPACING ..[=[)
    else
        flyoutMenu:SetHeight(h)
        flyoutMenu:SetWidth((w + ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[) * minN - ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[ + ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[ + ]=].. SPELLFLYOUT_FINAL_SPACING ..[=[)
    end

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "SHOWING flyout")
    --[[DEBUG]] end
    flyoutMenu:Show()
]=]
    end

    return SEC_ENV_SCRIPT_FOR_OPENER
end

function Germ:getSecEnvScriptFor_ON_CLICK()
    if not SEC_ENV_SCRIPT_FOR_ON_CLICK then
        local MAP_MOUSE_CLICK_AS_A_TYPE = serializeAsAssignments("MAP_MOUSE_CLICK_AS_A_TYPE", MouseClickAsSecEnvId)
        local MAP_MOUSE_CLICK_AS_NUMBER = serializeAsAssignments("MAP_MOUSE_CLICK_AS_NUMBER", MouseClickAsSecEnvN)

        SEC_ENV_SCRIPT_FOR_ON_CLICK =
[=[
        -- CONSTANTS
        local CYCLE_ALL_BTNS  = "]=].. GermClickBehavior.CYCLE_ALL_BTNS ..[=["
        local RANDOM_BTN      = "]=].. GermClickBehavior.RANDOM_BTN ..[=["
        local KEY_PREFIX_BMC  = "]=].. KEY_PREFIX_FOR_ON_CLICK ..[=["
        ]=].. MAP_MOUSE_CLICK_AS_A_TYPE ..[=[
        ]=].. MAP_MOUSE_CLICK_AS_NUMBER ..[=[

        -- INCOMING PARAMS - rename/remap Blizard's idiotic variables and SHITTY identifiers
        local isClicked          = down -- true/false
        local mouseClick         = button -- "LeftButton" etc
        local secureMouseClickId = MAP_MOUSE_CLICK_AS_A_TYPE[mouseClick] -- turn "LeftButton" into "type1" etc
        local mouseBtnNumber     = MAP_MOUSE_CLICK_AS_NUMBER[mouseClick] -- turn "LeftButton" into "1" etc

        -- logic figuring out what's going to happen
        local behaviorKey    = KEY_PREFIX_BMC .. mouseClick
        local behavior       = self:GetAttribute(behaviorKey)
        local doCycle        = (behavior == CYCLE_ALL_BTNS)
        local doRandomizer   = (behavior == RANDOM_BTN)
        local onlyInitialize = (mouseClick == nil)

        --[[DEBUG]] if doDebug and isClicked then
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() mouseClick",mouseClick, "isClicked",isClicked, "onlyInitialize",onlyInitialize)
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() behaviorKey",behaviorKey, "behavior",behavior, "doCycle",doCycle, "doRandomizer",doRandomizer)
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() secureMouseClickId",secureMouseClickId, "mouseBtnNumber",mouseBtnNumber)
        --[[DEBUG]] end

        if onlyInitialize then
            -- good to go - this is being called by Germ:update() Or germ:new()? or germ:movedToNewSlot()? in order to initialize the click SetAttribute()s
        elseif not isClicked then
            -- ABORT - only execute once per mouseclick, not on both UP and DOWN
            return
        elseif not behavior then
            --[[DEBUG]] if doDebug then
            --[[DEBUG]]   print("INFO", myName, "ON_CLICK() has no behavior for", mouseClick)
            --[[DEBUG]] end
            return
        elseif not (doCycle or doRandomizer) then
            print("<UFO> ERROR", myName, "has been assigned an unknown clicker behavior:", behavior)
            return
        end

        --print("PickerClicker(): germ =",myName, "(1) flyoutMenuKids =", flyoutMenuKids)

        -- keep a cache of work done to reduce workload
        -- but invalidate this cache when the user changes the flyout def
        local kidsCachedWhen     = germ:GetAttribute("UFO_KIDS_CACHED_WHEN")
        local flyoutLastModified = self:GetAttribute("UFO_FLYOUT_MOD_TIME")
        if (not kidsCachedWhen) or (kidsCachedWhen < flyoutLastModified) then
            flyoutMenuKids = nil
            --[[DEBUG]] if doDebug then
            --[[DEBUG]]     local cacheAge = flyoutLastModified - (kidsCachedWhen or 0)
            --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() clearing kid cache.  kidsCachedWhen:",kidsCachedWhen, " flyoutLastModified:",flyoutLastModified, "cacheAge",cacheAge)
            --[[DEBUG]] end
        else
            --[[DEBUG]] if doDebug then
            --[[DEBUG]]     local cacheAge = kidsCachedWhen - flyoutLastModified
            --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() using kid cache.  kidsCachedWhen:",kidsCachedWhen, " flyoutLastModified:",flyoutLastModified, "cacheAge",cacheAge)
            --[[DEBUG]] end
        end

        if not flyoutMenuKids then
            flyoutMenuKids = table.new(flyoutMenu:GetChildren())
            buttonsOnFlyoutMenu = table.new()
            n = 0
            for i, btn in ipairs(flyoutMenuKids) do
                local noRnd = btn:GetAttribute("UFO_NO_RND")
                local btnName = btn:GetAttribute("UFO_NAME")
                --print ("RANDOMIZER: i",i, "name",btnName, "noRnd",noRnd)
                if btnName and not noRnd then
                    n = n + 1
                    buttonsOnFlyoutMenu[n] = btn
                    --print("flyoutMenuKids:", n, btnName, buttonsOnFlyoutMenu[n])
                end
            end
        end

        germ:SetAttribute("UFO_KIDS_CACHED_WHEN", flyoutLastModified) -- Bliz doesn't provide time inside secure protected BS

        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() flyoutMenuKids =", flyoutMenuKids)
        --[[DEBUG]] end

        if doRandomizer then
            x = n>0 and random(1,n) or 1
            --[[DEBUG]] if doDebug then
            --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() RandomBtn", "n",n, "x",x)
            --[[DEBUG]] end
        elseif doCycle then
            x = self:GetAttribute("CYCLE_POSITION") or 0
            x = x + 1
            if x > n then x = 1 end
            self:SetAttribute("CYCLE_POSITION", x)
            --[[DEBUG]] if doDebug then
            --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() CycleThroughAllBtns", "n",n, "x",x)
            --[[DEBUG]] end
        end

        -- having calculated which button is being triggered, now
        -- GRAB THE BUTTON FROM THE FLYOUT
        -- COPY ITS BEHAVIOR ONTO MYSELF

        local btn    = buttonsOnFlyoutMenu[x]
        if not btn then return end
        local type   = btn:GetAttribute("type")
        local key    = btn:GetAttribute("UFO_KEY") -- set inside assignSecEnvAttributeForMouseClick()
        local val    = btn:GetAttribute("UFO_VAL") -- set inside assignSecEnvAttributeForMouseClick()
        local adjKey = key .. mouseBtnNumber -- convert "macro" into "marco1" etc

        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName)
        --[[DEBUG]] end

        --print("PickerClicker(): germ =", myName, "(3) copy btn to clicker... btn#",x, secureMouseClickId, "-->", type, "... adjKey =", adjKey, "-->",val) -- this shows that it is firing for both mouse UP and DOWN

        -- copy the btn's behavior onto myself
        self:SetAttribute(secureMouseClickId, type)
        self:SetAttribute(adjKey, val)
]=]
    end
    return SEC_ENV_SCRIPT_FOR_ON_CLICK
end

-------------------------------------------------------------------------------
-- OVERRIDES of
-- ActionBarActionButtonMixin methods
-- Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButton.lua
-- because Germ isn't on an action bar and thus:
-- calling GetActionInfo(self.action) knows nothing of UFOs
-------------------------------------------------------------------------------

Germ.GetPopupDirection = Germ.getDirection

-------------------------------------------------------------------------------
-- OVERRIDES of
-- FlyoutButtonMixin methods
-- acquired via ActionButtonTemplate -> FlyoutButtonTemplate
-- see Interface/AddOns/Blizzard_Flyout/Flyout.lua
-------------------------------------------------------------------------------

function Germ:IsPopupOpen()
    return self.flyoutMenu and self.flyoutMenu:IsShown()
end

function Germ:ClearPopup()
    -- NOP
    -- unlike the Bliz built-in flyouts, rather than reusing a single flyout object that is passed around from one action bar button to another
    -- each UFO keeps its own flyout object.  Thus, detaching it is a bad idea.
end

-------------------------------------------------------------------------------
-- OVERRIDES of
-- SmallActionButtonMixin methods
-- acquired via SmallActionButtonTemplate
-- See Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButton.lua
-------------------------------------------------------------------------------

function Germ:UpdateButtonArt()
    --BaseActionButtonMixin.UpdateButtonArt(self); -- this was the default self:UpdateButtonArt(). removing it has no effect.
end

-------------------------------------------------------------------------------
-- OVERRIDES of
-- ButtonStateBehaviorMixin methods
-------------------------------------------------------------------------------

function Germ:OnButtonStateChanged()
    -- defined in ButtonStateBehaviorMixin:OnButtonStateChanged() as "Derive and configure your button to the correct state."
    zebug.trace:owner(self):print("calling parent in FlyoutButtonMixin")
    FlyoutButtonMixin.OnButtonStateChanged(self) -- "FlyoutButtonMixin" meaning "a button that opens a flyout" not "a button on a flyout" - English is ambiguous and developers are dumb
end

-------------------------------------------------------------------------------
-- Debugger tools
-------------------------------------------------------------------------------

function Germ:printDebugDetails(event, okToGo)
    okToGo = self:notInfiniteLoop(okToGo)
    if not okToGo then return end

    local parent, parentName = self:getParentAndName()
    zebug.warn:event(event):name("details"):owner(self):print("isActive",self:isActive(), "IsShown",self:IsShown(), "IsVisible",self:IsVisible(), "parent", parentName, "flyoutMenu",self.flyoutMenu, "visibilityDriver",self.visibilityDriver)

    local t1 = self:GetAttribute("type1") or "NIL"
    local t2 = self:GetAttribute("type2") or "NIL"
    local t3 = self:GetAttribute("type3") or "NIL"
    local v1 = self:GetAttribute(t1.."1") or "nIl"
    local v2 = self:GetAttribute(t2.."2") or "nIl"
    local v3 = self:GetAttribute(t3.."3") or "nIl"
    zebug.warn:event(event):name("details"):owner(self):print("t1",t1, "v1",v1, "t2",t2, "v2",v2, "t3",t3, "v3",v3)

    if self.flyoutMenu then self.flyoutMenu:printDebugDetails(event, okToGo) end

    ---@type BlizActionBarButton
    if parent and parent.printDebugDetails then parent:printDebugDetails(event, okToGo) end
end

-------------------------------------------------------------------------------
-- Awesome toString() magic
-------------------------------------------------------------------------------

local shorties = {}

local function shortName(s)
    if not s then return end
    if not shorties[s] then
        shorties[s] = string.sub(s,1,10)
    end
    return shorties[s]
end

function Germ:toString()
    if not self.flyoutId then
        return "<Germ: EMPTY>"
    else
        local icon = self:getIcon()
        return string.format("<Germ: |T%d:0|t %s>", icon, shortName(self.label or self:getLabel() ) or "UnKnOwN")
    end
end


