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

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@type GERM_TYPE for the benefit of my IDE's autocomplete
local ScriptHandlers = {}
local HANDLER_MAKERS_MAP

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
local CLICK_ID_MARKER = "-- CLICK_ID_MARKER:"
local LEN_CLICK_ID_MARKER = string.len(CLICK_ID_MARKER)
local MAX_FREQ_UPDATE = 0.25 -- secs

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ:new(flyoutId, btnSlotIndex, event)
    local parentActionBarBtn = BlizActionBarButtonHelper:get(btnSlotIndex, "Germ:New() for btnSlotIndex"..btnSlotIndex)
    --print("Germ parentActionBarBtn",parentActionBarBtn, "parentActionBarBtn.GetName", parentActionBarBtn.GetName)
    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentActionBarBtn:GetName()

    ---@type GERM_TYPE | Germ
    local self = CreateFrame(
            FrameType.CHECK_BUTTON,
            myName,
            parentActionBarBtn,
            "GermTemplate"
    )

    _G[myName] = self -- so that keybindings can reference it

    -- one-time only initialization --
    self.myName       = myName -- who
    self.btnSlotIndex = btnSlotIndex -- where
    self.flyoutId     = flyoutId -- what

    -- manipulate methods
    self:installMyToString() -- do this as soon as possible for the sake of debugging output
    self.originalHide = self:override("Hide", self.hide)

    -- install event handlers
    self:HookScript(Script.ON_HIDE,        function(self) zebug.info:owner(self):event("Script.ON_HIDE"):print('byeeeee'); end) -- This fires IF the germ is on a dynamic action bar that switches (stance / druid form / etc. or on clearAndDisable() or on a spec change which throws away placeholders
    --self:SetScript(Script.ON_UPDATE,       Throttler:throttleAndNoQueue(MAX_FREQ_UPDATE, self, ScriptHandlers.ON_UPDATE)) -- moved into Ufo.lua and replaced with SPELL_UPDATE_COOLDOWN
    self:SetScript(Script.ON_ENTER,        ScriptHandlers.ON_ENTER)
    self:SetScript(Script.ON_LEAVE,        ScriptHandlers.ON_LEAVE)
    self:SetScript(Script.ON_RECEIVE_DRAG, ScriptHandlers.ON_RECEIVE_DRAG)
    self:SetScript(Script.ON_MOUSE_DOWN,   ScriptHandlers.ON_MOUSE_DOWN)
    self:SetScript(Script.ON_MOUSE_UP,     ScriptHandlers.ON_MOUSE_UP) -- is this short-circuiting my attempts to get the buttons to work on mouse up?
    self:SetScript(Script.ON_DRAG_START,   ScriptHandlers.ON_DRAG_START) -- this is required to get OnDrag to work
    --self:SetScript(Script.ON_EVENT,        ScriptHandlers.ON_EVENT) -- also do a RegisterEvent -- MOVED INTO Ufo.lua

    self:registerForBlizUiActions(event)

    -- FlyoutMenu
    self:initFlyoutMenu(event)
    self:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId(event) -- depends on initFlyoutMenu() above

    -- UI positioning & appearance
    self:ClearAllPoints()
    self:SetAllPoints(parentActionBarBtn)
    self:initLabel()
    self:doIcon(event)
    self.Name:SetText(self.label)
    self:setVisibilityDriver(parentActionBarBtn.visibleIf)

    -- secure tainty stuff
    self:safeSetAttribute("UFO_NAME", self.label)
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
    self:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId(event)
    self:closeFlyout() -- in case the buttons' number/ordering changes
    self.flyoutMenu:applyConfigForGerm(self, event)
    --self:doUpdate(self.flyoutId, event)
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

function Germ:hasItemsAndIsActive()
    return self:isActive() and self:getFlyoutDef():hasItem()
end

function Germ:hasMacrosAndIsActive()
    return self:isActive() and self:getFlyoutDef():hasIMacro()
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
    if Config.opts.supportCombat then
        self.flyoutMenu = FlyoutMenu:new(self)
        zebug.info:event(event):line("20","initFlyoutMenu",self.flyoutMenu)
        self.flyoutMenu:applyConfigForGerm(self, event)
        self:SetPopup(self.flyoutMenu) -- put my FO where Bliz expects it
    else
        self.flyoutMenu = UFO_FlyoutMenuForGerm
    end
    self.flyoutMenu.isForGerm = true
end

-- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
function Germ:setVisibilityDriver(visibleIf)
    self.visibleIf = visibleIf
    zebug.trace:print("visibleIf",visibleIf)
    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")
    else
        UnregisterStateDriver(self, "visibility")
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

Germ.clearAndDisable = Pacifier:pacify(Germ, "clearAndDisable")


function Germ:changeFlyoutIdAndEnable(flyoutId, event)
    if flyoutId == self.flyoutId then
        zebug.trace:event(event):owner(self):print("Um, that's the same flyoutId as before",flyoutId)
        return
    end

    self.flyoutId = flyoutId
    zebug.info:event(event):owner(self):print("EnAbLe GeRm :-)")

    self:closeFlyout()
    self:doIcon(event)
    self.flyoutMenu:applyConfigForGerm(self, event)
    self:registerForBlizUiActions(event)
    self:doMyKeybinding()
    self:Show()
    self:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId(event) -- depends on initFlyoutMenu() above
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

--[[
---@type function
Germ.clear = Pacifier:pacify(function(self)
    self:closeFlyout()
    self:hide()
end)

function Germ:clear()
    if not self.pacifierForClear then
        self.pacifierForClear = Pacifier:new(self:getLabel() .. " : clear()")
    end

    self.pacifierForClear:exe(function()
        self:closeFlyout()
        self:hide()
    end)
end
]]

---@return BlizActionBarButton
function Germ:getParent()
    return self:GetParent()
end

function Germ:getDirection()
    -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs
    -- ask the bar instance what direction to fly
    -- removed for Germ == ActionButton
    local parent = self:GetParent()
    return parent.bar:GetSpellFlyoutDirection()
end

function Germ:updateAllBtnHotKeyLabels(event)
    self.flyoutMenu:applyConfigForGerm(self, event)
end

function Germ:copyDoCloseOnClickConfigValToAttribute()
    -- haven't figured out why it doesn't work on the germ but does on the flyout
    --zebug.trace:mCross():owner(self):print("self.flyoutMenu",self.flyoutMenu, "setting new value from Config.opts.doCloseOnClick", Config.opts.doCloseOnClick)
    self:SetAttribute("doCloseOnClick", Config.opts.doCloseOnClick)
    return self.flyoutMenu and self.flyoutMenu:SetAttribute("doCloseOnClick", Config.opts.doCloseOnClick)
end

Germ.copyDoCloseOnClickConfigValToAttribute = Pacifier:pacify(Germ, "copyDoCloseOnClickConfigValToAttribute", L10N.RECONFIGURE_UFO)

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
--[[
    if self:getLabel() == "Nom Nom" then
        print("SPEAK label =====>",self:getLabel())
        event.mySpeakingVolume = 20
    else
        print("MUTE label =====>",self:getLabel())
        event.mySpeakingVolume = -10
    end
]]

    --self:zz(event):print("B4 UsableFlyoutDef", self:getUsableFlyoutDef())
    zebug.info:event(event):owner(self):print("I am a germ?",self, "my label is",  self:getLabel())
    --zebug.info:event(event):owner(self):dumpy("-B4- UsableFlyoutDef",  self:getUsableFlyoutDef())
    self:getFlyoutDef():invalidateCache(event)
    --self:zz(event):print("AF UsableFlyoutDef", self:getUsableFlyoutDef())
    --zebug.info:event(event):owner(self):dumpy("-AF- UsableFlyoutDef",  self:getUsableFlyoutDef())
    self:applyConfigFromFlyoutDef(event)
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
            self:SetAttribute("UFO_KEYBIND_1", keybind1)
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

Germ.doMyKeybinding = Pacifier:pacify(Germ, "doMyKeybinding", L10N.CHANGE_KEYBINDING)

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
        self:RegisterForClicks("AnyDown", "AnyUp")
    else
        self:RegisterForClicks()
    end
end

-- and here
function Germ:unregisterForBlizUiActions()
    if not self.isEventStuffRegistered then return end

    self:EnableMouseMotion(false)
    self:RegisterForDrag("Button6Down")
    self:RegisterForClicks("Button6Down")
    --self:UnregisterEvent("CURSOR_CHANGED")

    --self:UnregisterAllEvents()

    self.isEventStuffRegistered = false
end

function Germ:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId(event)
    -- TODO v11.1 - wrap in exeNotInCombat() ? in case "/reload" during combat
    -- set attributes used inside the secure scriptlettes
    self:SetAttribute("flyoutDirection", self:getDirection())
    self:SetAttribute("FLYOUT_MENU_NAME", self.flyoutMenu:GetName())
    self:SetAttribute("doKeybindTheButtonsOnTheFlyout", Config:get("doKeybindTheButtonsOnTheFlyout"))

    local flyoutId = self.flyoutId
    self:setMouseClickHandler(MouseClick.LEFT,   Config:getClickBehavior(flyoutId, MouseClick.LEFT), event)
    self:setMouseClickHandler(MouseClick.MIDDLE, Config:getClickBehavior(flyoutId, MouseClick.MIDDLE), event)
    self:setMouseClickHandler(MouseClick.RIGHT,  Config:getClickBehavior(flyoutId, MouseClick.RIGHT), event)
    self:setMouseClickHandler(MouseClick.FOUR,   Config:getClickBehavior(flyoutId, MouseClick.FOUR), event)
    self:setMouseClickHandler(MouseClick.FIVE,   Config:getClickBehavior(flyoutId, MouseClick.FIVE), event)
    self:setMouseClickHandler(MouseClick.SIX,    Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior, event)
end

Germ.setAllSecureClickScriptlettesBasedOnCurrentFlyoutId = Pacifier:pacify(Germ, "setAllSecureClickScriptlettesBasedOnCurrentFlyoutId", L10N.RECONFIGURE_BUTTON)

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

---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function Germ:renderIfSlow(event)
    if MAX_FREQ_UPDATE > 0.1 then
        self:render(event)
    end
end

-------------------------------------------------------------------------------
-- Handlers
-------------------------------------------------------------------------------

-- no longer used - now render() is triggered in Ufo.lua by SPELL_UPDATE_COOLDOWN etc
function ScriptHandlers:ON_UPDATE(elapsed)
    if self:isInactive() then return end
    -- do NOT run ON_UPDATE without first wrapping it in Throttler !!!
    zebug.trace:owner(self):newEvent(self, "ON_UPDATE"):runTerse(function(event)
        self:render(event)
    end)
end

-- if there is something (let's call it "foo") on the mouse pointer, then we need to disable clicks.
-- otherwise, when the "user drags foo, releases mouse button in mid-air. foo remains on mouse pointer. user moves over a UFO.  user clicks."
-- will fail to drop foo onto bars (foo just vanishes with only a cursor_change event) nor will it pick up the UFO
---@param me string event name, literal string "CURSOR_CHANGED"
---@param isCursorEmpty boolean true if nothing is on the mouse pointer
function ScriptHandlers:ON_EVENT(eventName, isCursorEmpty --[[, newCursorType, oldCursorType, oldCursorVirtualID]])
--[[
    zebug.info:mStar():newEvent(self, Cursor:nameMakerForCursorChanged(isCursorEmpty)):run(function(event)
        self:maybeRegisterForClicksDependingOnCursorIsEmpty(event)
    end)
]]
end

function ScriptHandlers:ON_MOUSE_DOWN(mouseClick)
    local cursor = Cursor:get()
    zebug.info:mDiamond():owner(self):newEvent(self, "ScriptHandlers.ON_MOUSE_DOWN"):run(function(event)
        self:OnMouseDown() -- Call Bliz super()

        if cursor then
            -- self:handleReceiveDrag(event)
        else
            zebug.info:owner(self):event(event):name("ScriptHandlers:ON_MOUSE_DOWN"):print("not dragging, so, exiting. proxy",UfoProxy, "mySlotBtn",mySlotBtn)
        end
        --self:doUpdateIfSlow(event)
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
        --self:doUpdateIfSlow(event)
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
        --self:doUpdateIfSlow(event)
    end)
end

function ScriptHandlers:ON_LEAVE()
    self:OnLeave() -- Call Bliz super()
    GameTooltip:Hide()
    --self:doUpdateIfSlow("on-leave")
end

-------------------------------------------------------------------------------
-- Mouse Click Handling
--
-- SECURE TEMPLATE / RESTRICTED ENVIRONMENT
--
-- a bunch of code to make calls to SetAttribute("type",action) etc
-- to enable the Germ's button to do things in response to mouse clicks
-------------------------------------------------------------------------------

---@type Germ|GERM_INHERITANCE
local HandlerMaker = { }

---@param mouseClick MouseClick
function Germ:setMouseClickHandler(mouseClick, behavior, event)
    self:removeOldHandler(mouseClick, event)
    local installTheBehavior = getHandlerMaker(behavior)
    zebug.info:owner(self):event(event):print("mouseClick",mouseClick, "opt", behavior, "handler", installTheBehavior)
    installTheBehavior(self, mouseClick, event)
    self.clickers[mouseClick] = behavior
    SecureHandlerExecute(self, searchForFlyoutMenuScriptlet()) -- initialize the scriptlet's "global" vars
end

---@param behavior GermClickBehavior
---@return fun(zelf: Germ, mouseClick: MouseClick, event: Event): nil
function getHandlerMaker(behavior)
    assert(behavior, "usage: getHandlerMaker(behavior)")
    if not HANDLER_MAKERS_MAP then
        HANDLER_MAKERS_MAP = {
            [GermClickBehavior.OPEN]           = HandlerMaker.OpenFlyout,
            [GermClickBehavior.FIRST_BTN]      = HandlerMaker.ActivateBtn1,
            [GermClickBehavior.RANDOM_BTN]     = HandlerMaker.ActivateRandomBtn,
            [GermClickBehavior.CYCLE_ALL_BTNS] = HandlerMaker.CycleThroughAllBtns,
            --[GermClickBehavior.REVERSE_CYCLE_ALL_BTNS] = HandlerMaker.ReverseCycleThroughAllBtns,
        }
    end
    local result = HANDLER_MAKERS_MAP[behavior]
    assert(result, "Unknown GermClickBehavior: ".. behavior)
    return result
end

-- open / show
---@param mouseClick MouseClick
function HandlerMaker:OpenFlyout(mouseClick, event)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:event(event):owner(self):name("HandlerMakers:OpenFlyout"):print("mouseClick",mouseClick, "secureMouseClickId", secureMouseClickId)
    local scriptName = "OPENER_SCRIPT_FOR_" .. secureMouseClickId
    zebug.info:event(event):owner(self):name("HandlerMakers:OpenFlyout"):print("germ",self.label, "secureMouseClickId",secureMouseClickId, "scriptName",scriptName)
    -- TODO v11.1 - wrap in exeNotInCombat() ?
    self:SetAttribute(secureMouseClickId,scriptName)
    self:SetAttribute("_"..scriptName, getOpenerClickerScriptlet()) -- OPENER
end

---@param mouseClick MouseClick
function HandlerMaker:ActivateBtn1(mouseClick, event)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:event(event):owner(self):print("secureMouseClickId",secureMouseClickId)
    self:updateSecureClicker(mouseClick, event)
    local btn1 = self:getBtnDef(1)
    if not btn1 then return end
    local btn1Type = btn1:getTypeForBlizApi()
    local btn1Name = btn1.name
    local type, key, val = btn1:asSecureClickHandlerAttributes(event)
    local keyAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
    zebug.info:event(event):owner(self):name("HandlerMakers:ActivateBtn1"):print("germ",self.label, "btn1Name",btn1Name, "btn1Type",btn1Type, "secureMouseClickId", secureMouseClickId, "type", type, "key",key, "ADJ key", keyAdjustedToMatchMouseClick, "val", val)
    -- TODO v11.1 - wrap in exeNotInCombat() ?
    self:SetAttribute(secureMouseClickId, type)
    self:SetAttribute(keyAdjustedToMatchMouseClick, val)
end

---@param mouseClick MouseClick
function HandlerMaker:ActivateRandomBtn(mouseClick)
    self:installHandlerForDynamicButtonPickerClicker(mouseClick, "local x = n>0 and random(1,n) or 1")
end

-- TODO: can I make CYCLE_POSITION a global var instead of a SetAttribute() ?
-- yes, but, it still won't be shared between mouse buttons

---@param mouseClick MouseClick
function HandlerMaker:CycleThroughAllBtns(mouseClick)
    local xGetterScriptlet = [=[
        local x = self:GetAttribute("CYCLE_POSITION") or 0
        x = x + 1
        if x > n then x = 1 end
        self:SetAttribute("CYCLE_POSITION", x)
        --print("CycleThroughAllBtns", self:GetName(), isClicked, n, x)
]=]
    -- "self" is actually a Germ and not HandlerMaker
    self:installHandlerForDynamicButtonPickerClicker(mouseClick, xGetterScriptlet)
end

---@param mouseClick MouseClick
function HandlerMaker:ReverseCycleThroughAllBtns(mouseClick)
    -- not supported at the moment
end

---@param mouseClick MouseClick
function Germ:installHandlerForDynamicButtonPickerClicker(mouseClick, xGetterScriptlet)
    -- Sets two handlers (or rather, the first handler creates the second.)
    -- 1) a SecureHandlerWrapScript script that picks a [random|sequential] button and...
    -- 2) that script creates another handler via SetAttribute(mouseButton -> action) that will actually perform the action determined in step #1

    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    local mouseBtnNumber = self:getMouseBtnNumber(secureMouseClickId) or ""
    local scriptToSetNextRandomBtn = CLICK_ID_MARKER .. mouseClick .. ";\n" ..
    [=[
    	local germ = self
    	local mouseClick = button
    	local isClicked = down
    	local onlyInitialize = mouseClick == nil

        local iAmFor = "]=].. mouseClick ..[=["

    	if onlyInitialize then
    	    -- good to go... this is being called by Germ:update() Or germ:new()? or germ:movedToNewSlot()? in order to initialize the click SetAttribute()s
        elseif not isClicked then
            -- abort... only execute once per mouseclick, not on both UP and DOWN
            return
        elseif iAmFor ~= mouseClick then
            -- abort... only execute if the clicked mouse button matches the one this script was specifically created
            return
    	end

    	local myName = self:GetAttribute("UFO_NAME")
        local secureMouseClickId = "]=].. secureMouseClickId .. [=["

        --print("PickerClicker(): germ =",myName, "(1) flyoutMenuKids =", flyoutMenuKids)

        -- keep a cache of work done to reduce workload
        -- but invalidate this cache when the user changes the flyout def
        local kidsCachedWhen     = germ:GetAttribute("UFO_KIDS_CACHED_WHEN")
        local flyoutLastModified = self:GetAttribute("UFO_FLYOUT_MOD_TIME")
        if (not kidsCachedWhen) or (kidsCachedWhen < flyoutLastModified) then
            flyoutMenuKids = nil
            print("clearing kid cache.  kidsCachedWhen:",kidsCachedWhen, " flyoutLastModified:",flyoutLastModified)
        else
            print("using kid cache.  kidsCachedWhen:",kidsCachedWhen, " flyoutLastModified:",flyoutLastModified)
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

        --print("PickerClicker(): germ =",myName, "(2) flyoutMenuKids =", flyoutMenuKids)

    	]=] .. xGetterScriptlet .. [=[

        local btn    = buttonsOnFlyoutMenu[x] -- computed by xGetterScriptlet
        if not btn then return end

        local type   = btn:GetAttribute("type")
        local adjKey = btn:GetAttribute("UFO_KEY") .. ]=] .. mouseBtnNumber .. [=[
        local val    = btn:GetAttribute("UFO_VAL")

        --print("PickerClicker(): germ =", myName, "(3) copy btn to clicker... btn#",x, secureMouseClickId, "-->", type, "... adjKey =", adjKey, "-->",val) -- this shows that it is firing for both mouse UP and DOWN

        -- copy the btn's behavior onto myself
        self:SetAttribute(secureMouseClickId, type)
        self:SetAttribute(adjKey, val)
    ]=]

    zebug.info:owner(self):print("germ",self.label, "secureMouseClickId",secureMouseClickId, "mouseBtnNumber",mouseBtnNumber)
--    self.clickScriptUpdaters[secureMouseClickId] = scriptToSetNextRandomBtn -- this doesn't seem to actually be required

    -- install the script which will install the buttons which will perform the action
    SecureHandlerWrapScript(self, "OnClick", self, scriptToSetNextRandomBtn)

    -- initialize the scriptlet's "global" vars
    SecureHandlerExecute(self, searchForFlyoutMenuScriptlet())
end

-- Fuck you yet again, Bliz, for only providing a way to remove some unknown, generally arbitrary handler but not a specific handler.
-- So now, I cry, and loop through ALL of the SecureHandlerUnwrapScript(self, "OnClick") until I find the one,
-- then restore the others that were needlessly stripped while groping the Frame in a blind, hamfisted search.

function Germ:removeOldHandler(mouseClick, event)
    local old = self.clickers[mouseClick]
    zebug.trace:event(event):owner(self):print("old",old)
    if not old then return end

    local needsRemoval = (old == (GermClickBehavior.RANDOM_BTN) or (old == GermClickBehavior.CYCLE_ALL_BTNS))
    zebug.trace:event(event):owner(self):print("old",old, "needsRemoval",needsRemoval)
    if not needsRemoval then return end

    local i = 0
    local lostBoys = {}
    local rescue = function(header, preBody, postBody, scriptsClick)
        -- Oopsy daisy!  Blizzy Wizzy tricked me into removing the wrong one!  Remember it so we can put it back.
        i = i + 1
        lostBoys[i] = { header, preBody, postBody, scriptsClick }
    end

    local header = self
    local isForThisClick = false
    while header and not isForThisClick do -- assume we will only ever install ONE handler per mouse button
        local header, preBody, postBody = SecureHandlerUnwrapScript(self, "OnClick")
        if not header then
            break
        end

        if header ~= self then
            rescue(header, preBody, postBody, "unknown")
            break
        end

        -- pull the ID marker out of the script body and see if it's the one we're supposed to remove
        local start = LEN_CLICK_ID_MARKER +1
        local stop  = LEN_CLICK_ID_MARKER + string.len(mouseClick)
        local scriptsClick = string.sub(postBody or "", start, stop)
        isForThisClick = (scriptsClick == mouseClick)
        zebug.info:event(event):owner(self):print("germ", self.label, "click",mouseClick, "old",old, "script owner", scriptsClick, "iAmOwner", isForThisClick)
        if not isForThisClick then
            rescue( header, preBody, postBody, scriptsClick )
        end
    end

    -- try to put that shit back
    for i, params in ipairs(lostBoys) do
        local success = pcall(function()
            SecureHandlerWrapScript(params[1], "OnClick", params[1], params[2], params[3])
        end )
        zebug.info:event(event):owner(self):print("germ", self.label, "click",mouseClick, "RESTORING handler for", params[4], "success?", success)
    end
end

-- self.OnEvent = ActionBarActionButtonMixin.OnEvent
--[[
function Germ:OnEvent(event, ...)
    zebug.error:print("wee?",event)
    ActionBarActionButtonMixin:OnEvent(event, ...)
end
]]

function searchForFlyoutMenuScriptlet()
    return [=[
	germ = self
    local FLYOUT_MENU_NAME = self:GetAttribute("FLYOUT_MENU_NAME")

    -- use a global var to cache the flyout menu
    if not flyoutMenu then
        -- search the kids for the flyout menu
        local kids = table.new(germ:GetChildren())
        for i, kid in ipairs(kids) do
            local kidName = kid:GetName()
            if kidName == FLYOUT_MENU_NAME then
                flyoutMenu = kid
                keybindKeeper = flyoutMenu -- not really needed. I added this while debugging a taint problem
                break
            end
        end
    end
    ]=]
end

local OPENER_CLICKER_SCRIPTLET

function getOpenerClickerScriptlet()
    if OPENER_CLICKER_SCRIPTLET then
        return OPENER_CLICKER_SCRIPTLET
    end

    OPENER_CLICKER_SCRIPTLET = [=[
--print("OPENER_CLICKER_SCRIPTLET <START>")
	local germ = self
	local mouseClick = button
	local isClicked = down
	local direction = germ:GetAttribute("flyoutDirection")
    local isOpen = flyoutMenu:IsShown()

	if isOpen then
		flyoutMenu:Hide()
		keybindKeeper:ClearBindings()
		return
    end

--print("OPENER_CLICKER_SCRIPTLET ... 1")
    keybindKeeper:SetBindingClick(true, "Escape", germ, mouseClick)

-- TODO: move this into FlyoutMenu:updateForGerm()

--print("OPENER_CLICKER_SCRIPTLET ... 2")
    flyoutMenu:SetParent(germ)  -- holdover from single FM
--print("OPENER_CLICKER_SCRIPTLET ... 3")
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

--print("OPENER_CLICKER_SCRIPTLET ... 4")
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
                    keybindKeeper:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
                    if numberKey == "1" then
                        -- make the UFO's first button's keybind be the same as the UFO itself
                        local germKey = self:GetAttribute("UFO_KEYBIND_1")
                        if germKey then
                            keybindKeeper:SetBindingClick(true, germKey, btn, "]=].. MouseClick.LEFT ..[=[")
                        end
                    end
                end
            end

            prevBtn = btn
--print("OPENER_CLICKER_SCRIPTLET ... showing button")
            btn:Show()
        else
            btn:Hide()
        end
    end

--print("OPENER_CLICKER_SCRIPTLET ... 5")
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

--print("OPENER_CLICKER_SCRIPTLET ... SHOWING flyout")
    flyoutMenu:Show()

    --flyoutMenu:RegisterAutoHide(1) -- nah.  Let's match the behavior of the mage teleports. They don't auto hide.
    --flyoutMenu:AddToAutoHide(germ)
]=]

    return OPENER_CLICKER_SCRIPTLET
end


-------------------------------------------------------------------------------
-- OVERRIDES for methods defined in ActionBarActionButtonMixin
-- Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButton.lua
-- because Germ isn't on an action bar and thus:
-- * calling GetActionInfo(self.action) knows nothing of UFOs
-- *
-- maybe I need to re-implement all of ActionBarActionButtonMixin ?
-- ActionBarActionButtonMixin:Update() calls -> ActionBarActionEventsFrame:RegisterFrame(self)
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
    FlyoutButtonMixin.OnButtonStateChanged(self) -- "FlyoutButtonMixin" meaning "a button that opens a flyout" not "a button on a flyout"
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


