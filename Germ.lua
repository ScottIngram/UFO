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
local zebug = Zebug:new(Zebug.TRACE)

---@alias GERM_INHERITANCE UfoMixIn | Button_Mixin | ActionButtonTemplate | SecureActionButtonTemplate | Button | Frame | ScriptObject
---@alias GERM_TYPE Germ | GERM_INHERITANCE

---@class Germ : GERM_TYPE
---@field ufoType string The classname
---@field flyoutId number Identifies which flyout is currently copied into this germ
---@field flyoutMenu FM_TYPE The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
---@field clickScriptUpdaters table secure scriptlets that must be run during any update()
---@field bbInfo table definition of the actionbar/button where the Germ lives
---@field myName string duh
---@field label string human friendly identifier

---@type GERM_TYPE | Germ
Germ = {
    ufoType = "Germ",
    clickScriptUpdaters = {},
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

local ScriptHandlers = {}
local HANDLER_MAKERS_MAP

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
local CLICK_ID_MARKER = "-- CLICK_ID_MARKER:"
local LEN_CLICK_ID_MARKER = string.len(CLICK_ID_MARKER)

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ:new(flyoutId, btnSlotIndex, eventId)
    local parentActionBarBtn, bbInfo = BlizActionBarButton:new(btnSlotIndex, "Germ:New() for btnSlotIndex"..btnSlotIndex)
    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentActionBarBtn:GetName()

    ---@type GERM_TYPE | Germ
    local self = CreateFrame(
            FrameType.CHECK_BUTTON,
            myName,
            parentActionBarBtn,
            "GermTemplate"
    )

    _G[myName] = self -- so that keybindings can reference it

    -- initialize my fields

    -- one-time only initialization --
    self.myName       = myName
    self.btnSlotIndex = btnSlotIndex
    self.bbInfo       = bbInfo

    -- any-time set whenever the config changes --
    self.flyoutId     = flyoutId
    self.label        = self:getFlyoutDef().name -- TODO remove?

    -- install event handlers
    --self:SetScript(Script.ON_UPDATE,       handlers.OnUpdate)
-- TEMP    self:SetScript(Script.ON_UPDATE,       Throttler:new(handlers.OnUpdate, 1, self.label ):asFunc() )
    self:SetScript(Script.ON_ENTER,        ScriptHandlers.OnEnter)
    self:SetScript(Script.ON_LEAVE,        ScriptHandlers.OnLeave)
    self:SetScript(Script.ON_RECEIVE_DRAG, ScriptHandlers.OnReceiveDrag)
    self:SetScript(Script.ON_MOUSE_DOWN,   ScriptHandlers.OnMouseDown)
    self:SetScript(Script.ON_MOUSE_UP,     ScriptHandlers.OnMouseUp) -- is this short-circuiting my attempts to get the buttons to work on mouse up?
    self:SetScript(Script.ON_DRAG_START,   ScriptHandlers.OnPickupAndDrag) -- this is required to get OnDrag to work
    self:HookScript(Script.ON_HIDE, function(self) zebug.info:owner(self):event("Script.ON_HIDE"):print('byeeeee'); end) -- This fires IF the germ is on a dynamic action bar that switches (stance / druid form / etc. or on clearAndDisable()

    self:registerForBlizUiActions()
    --self:RegisterForClicks("AnyDown", "AnyUp") -- this also works and also clobbers OnDragStart
    --self:RegisterForDrag("LeftButton")
--
    -- manipulate methods
    self:installMyToString()
    self.originalHide = self:override("Hide", self.hide)
    self.clearAndDisable = Pacifier:pacify(self, "clearAndDisable")

    -- UI positioning
    self:ClearAllPoints()
    self:SetAllPoints(parentActionBarBtn)

    self:setVisibilityDriver(parentActionBarBtn.btnDesc.visibleIf)

    -- FlyoutMenu
    self:initFlyoutMenu(eventId)
    self:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId() -- depends on initFlyoutMenu() above

    return self
end

local s = function(v) return v or "nil"  end

function Germ:toString()
    if not self.flyoutId then
        return "<Germ: EMPTY>"
    else
        return string.format("<Germ: name=%s, label=%s>", s(self:getName()), self:getLabel())
    end
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

function Germ:getBtnSlotIndex()
    return self.btnSlotIndex
end

---@return string
function Germ:getFlyoutId()
    return self.flyoutId
end

function Germ:isActive()
    return self.flyoutId and true or false
end

---@return string
function Germ:getFlyoutName()
    return self:getFlyoutDef():getName()
end

function Germ:initFlyoutMenu(eventId)
    if Config.opts.supportCombat then
        self.flyoutMenu = FlyoutMenu:new(self)
        zebug.info:event(eventId):line("20","initFlyoutMenu",self.flyoutMenu)
        self.flyoutMenu:updateForGerm(self, eventId)
        self:SetPopup(self.flyoutMenu) -- put my FO where Bliz expects it

        -- now in the XML
        --self.flyoutMenu:SetFrameStrata(STRATA_DEFAULT)
        --self.flyoutMenu:SetFrameLevel(STRATA_LEVEL_DEFAULT)
        --self.flyoutMenu:SetToplevel(true)

    else
        self.flyoutMenu = UFO_FlyoutMenuForGerm
    end
    self.flyoutMenu.isForGerm = true
end

-- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
function Germ:setVisibilityDriver(visibleIf)
    self.visibleIf = visibleIf
    zebug.error:print("visibleIf",visibleIf)
    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")
    else
        UnregisterStateDriver(self, "visibility")
    end
end

function Germ:closeFlyout()
    -- TAINT / not secure ?
    self.flyoutMenu:Hide()
end

-- will replace Germ:Hide() via Germ:new()
-- TODO is this serving the same purpose as clearAndDisable ?
function Germ:hide()
    --zebug.error:dumpy(self:getLabel(), debugstack())
    --VisibleRegion:Hide(self) -- L-O-FUCKING-L this threw  "attempt to index global 'VisibleRegion' (a nil value)" was called from SecureStateDriver.lua:103
    zebug.error:owner(self):print("hiding.  self",self, "parent", self:GetParent())
    UnregisterStateDriver(self, "visibility")
    self:originalHide()
end

function Germ:clearAndDisable(event)
    zebug.info:event(event):owner(self):print("DISABLE GERM :-(")
    self:closeFlyout()
    self:hide()
    self:clearKeybinding()
    self:setVisibilityDriver(nil) -- must be restored if Germ comes back -- TODO: move into registerForBlizUiActions() ?
    self.flyoutId = nil
    self.label = nil
    self.isConfigChanged = true

    self:unregisterForBlizUiActions()
    self:Disable() -- replaces all (well, most) of the above?
    self:SetEnabled(false) -- equiv?
end

function Germ:changeFlyoutIdAndEnable(flyoutId, event)
    if flyoutId == self.flyoutId then
        zebug.trace:event(event):print("Um, that's the same flyoutId as before",flyoutId)
        return
    end

    self.flyoutId = flyoutId
    zebug.info:event(event):owner(self):print("EnAbLe GeRm :-)")

    self.isConfigChanged = true
    self:closeFlyout()
    self.flyoutId = flyoutId
    self.flyoutMenu:updateForGerm(self, event)
    self:registerForBlizUiActions()
    self:Show()
    self:update(flyoutId, event) -- handles icon change and um...

    -- change any/everything
    -- go analyze the update() etc in Germ *AND* GermCommander

    -- the btn1 may need to change
    -- the clickers
    -- the flyout
    -- the flyoutDef

    self.isConfigChanged = false

    self:Enable()
    --self:SetEnabled(true) -- equiv?
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
        zebug.warn:event(event):owner(self):print("cursorBeforeItDrops", cursorBeforeItDrops)
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
    --GermCommander:updateAll(eventId)
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

function Germ:getDirection()
    -- Germ == ActionButton
    --return self.bar:GetSpellFlyoutDirection()

    -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs
    -- ask the bar instance what direction to fly
    -- removed for Germ == ActionButton
    local parent = self:GetParent()
    return parent.bar:GetSpellFlyoutDirection()
end

function Germ:updateAllBtnCooldownsEtc()
    --zebug.trace:print(self:getFlyoutId())
    self.flyoutMenu:updateAllBtnCooldownsEtc()
end

function Germ:updateAllBtnHotKeyLabels()
    zebug.info:line("20","updateForGerm from Germ:updateAllBtnHotKeyLabels")
    self.flyoutMenu:updateForGerm(self)
end

local maxUpdateFrequency = 0.5

-- TODO: rename and refactor - split into init and update - leverage setFlyoutId() - update new() so it does everything required
function Germ:update(flyoutId, event)
    self.flyoutId = flyoutId
    self:getLabel() -- update the stashed self.myLabel - TODO: eliminate cheese!

    -- limit frequency of updates
    -- but don't make each germ compete with the others.  give each a unique ID
    if not self.throttledUpdate then
        local func = function(event)
            zebug.info:name("throttled _secretUpdate"):event(event):owner(self):line("20","updateForGerm from Germ:updateAllBtnHotKeyLabels")
            return self:_secretUpdate(event)
        end
        -- every instance of Germ gets its own copy of throttledUpdate.
        -- thus, EACH instance can execute its own update without competing with the other instances
        self.throttledUpdate = Throttler:new(func, maxUpdateFrequency, self:getLabel().." secretUpdate()", true )
    end

    self.throttledUpdate:exe(event)
end

-- TODO v11.1 - figure out what all actually needs to be updated under which circumstances
function Germ:_secretUpdate(event, amDelayed)
    if not self:isActive() then
        zebug.error:name("_secretUpdate"):owner(self):line(50, "I am limited.  Because I have  nodes.")
        return
    end

    ---@type GERM_TYPE
    local self = self
    local flyoutId = self.flyoutId
    if not flyoutId then
        -- I've been deactivated / disabled
        zebug.error:line(70,"proof of bug - removed when fixed")
    end

    local btnSlotIndex = self.btnSlotIndex
    zebug.trace:name("_secretUpdate"):event(event):owner(self):line(30, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex, "self.name", self:GetName(), "parent", self:GetParent():GetName(), "amDelayed",amDelayed)

    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    if not flyoutDef then
        -- because one toon can delete a flyout while other toons still have it on their bars
        local msg = "Flyout".. flyoutId .."no longer exists.  Removing it from your action bars."
        msgUser(msg)
        GermCommander:forgetPlacement(btnSlotIndex, event)
        return
    end

    -- discard any buttons that the toon can't ever use
    local usableFlyout = flyoutDef:filterOutUnusable()

    -- set the Germ's icon so that it reflects only USABLE buttons
    local icon = usableFlyout:getIcon() or flyoutDef.fallbackIcon or DEFAULT_ICON
    self:setIcon(icon, event)

    -- inside ActionBarActionButtonMixin:Update() it sets self:Name based on a call to [Global]GetActionText(actionBarSlot)
    -- which will always be the UFO Macro's name, "ZUFO" so nope.
    self.Name:SetText(self.label)

    self:UpdateArrowTexture()
    self:UpdateArrowRotation()
    self:UpdateArrowPosition()
    self:UpdateBorderShadow()
    self:updateCooldownsAndCountsAndStatesEtc() -- TODO: v11.1 verify this is working properly.  do I need to do more? -- What happens if I remove this?

    ---------------------
    -- SECURE TEMPLATE --
    ---------------------

    -- TODO v11.1 - wrap in exeNotInCombat() ?

    local qId = "GERM:_secretUpdate() : ".. self:getName()
    exeOnceNotInCombat(qId, function()

        zebug.trace:name(qId):event(event):owner(self):line("20", "inner circle!")
        self.flyoutMenu:updateForGerm(self, event)

        -- removed this because I think it's good enough to do it only in new()
        --self:setVisibilityDriver() -- TODO: remove after we stop sledge hammering all the germs every time

        self:SetAttribute("UFO_NAME",  self.label)
        self:SetAttribute("doCloseOnClick", Config.opts.doCloseOnClick)

        local lastClickerUpdate = self.clickersLastUpdate or 0

        if self:getFlyoutDef():isModNewerThan(lastClickerUpdate) then
            zebug.trace:name(qId):event(event):owner(self):print("NO CHANGES! lastClickerUpdate",lastClickerUpdate)
            --return
        end

        zebug.trace:name(qId):event(event):owner(self):print("changed! lastClickerUpdate",lastClickerUpdate)
        self.clickersLastUpdate = time()

        -- some clickers need to be re-initialized whenever the flyout's buttons change
        self:reInitializeMySecureClickers()

        -- TODO - MOVE INTO ger:changeFLyoutId() !!!
        -- all FIRST_BTN handlers must be re-initialized after flyoutDef changes because the first button of the flyout might be different than before
        ---@param mouseClick MouseClick
        ---@param behavior GermClickBehavior
        for mouseClick, behavior in pairs(self.clickers) do
            if behavior == GermClickBehavior.FIRST_BTN then
                local installTheBehavior = getHandlerMaker(behavior, event)
                installTheBehavior(self, mouseClick)
            end
        end

    end)
end

function Germ:reInitializeMySecureClickers()
    for secureMouseClickId, updaterScriptlet in pairs(self.clickScriptUpdaters) do
        --zebug.trace:print("germ",self.label, "i",secureMouseClickId, "updaterScriptlet",updaterScriptlet)
        SecureHandlerExecute(self, updaterScriptlet)
    end
end

-- created for Germ == ActionButton
--[[
function Germ:fixMyActionAttribute()
    if not self.actionValueSetterSecureScriptlette then
        -- note: this will "hardcode" the btnSlotIndex which will become a problem if I ever decide to recylce Germs and move them
        self.actionValueSetterSecureScriptlette = "self:SetAttribute('action'," ..tostring(self.btnSlotIndex).. ")"
    end

    -- I can execute SecureHandlerExecute even when in combat, yes?
    -- No? "Insecure code can’t use SecureHandler Execute during combat"
    exeOnceNotInCombat("fix self.action ".. self:getName(), function()
        SecureHandlerExecute(self, self.actionValueSetterSecureScriptlette)
    end)
end
]]

-- why isn't this just part of self:update()
-- called by the Germ's OnUpdate handler
function Germ:handleGermUpdateEvent(eventId)
    ---@type GERM_TYPE
    local self = self
    self:update(self.flyoutId, eventId)
end

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

-------------------------------------------------------------------------------
-- Key Bindings & UI actions Registerings
-------------------------------------------------------------------------------

-- called by GermCommander:updateAllKeybinds()... which is currently unused???
-- called by GermCommander:updateBtnSlot()
function Germ:doKeybinding()
    if isInCombatLockdown("Keybind") then return end

    local bb = self.bbInfo
    local btnName = bb.btnYafName or bb.btnName
    local ucBtnName = string.upper(btnName)
    local germName = self:GetName()
    local keybinds
    if GetBindingKey(ucBtnName) then
        keybinds = { GetBindingKey(ucBtnName) }
    end

    -- add new keybinds
    if keybinds then
        for i, keyName in ipairs(keybinds) do
            if not tableContainsVal(self.keybinds, keyName) then
                zebug.trace:owner(self):print("germ",germName, "binding keyName",keyName)
                SetOverrideBindingClick(self, true, keyName, germName, MouseClick.SIX)
            else
                zebug.trace:owner(self):print("germ",germName, "NOT binding keyName",keyName, "because it's already bound.")
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
                zebug.trace:owner(self):print("germ",germName, "UN-binding keyName",keyName)
                SetOverrideBinding(self, true, keyName, nil)
            else
                zebug.trace:owner(self):print("germ",germName, "NOT UN-binding keyName",keyName, "because it's still bound.")
            end
        end
    end

    self.keybinds = keybinds
end

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

function Germ:registerForBlizUiActions()
    if self.eventsRegistered then return end

    self:EnableMouseMotion(true)
    self:RegisterForDrag(MouseClick.LEFT)
    self:RegisterForClicks("AnyDown", "AnyUp")

    -- TODO - refactor GermCommander so we do these here in Germ
    -- leverage BlizGlobalEventsListener
    --self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    --self:RegisterEvent("SPELL_UPDATE_USABLE")
    --self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    --self:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    --self:RegisterEvent("BAG_UPDATE") -- ?
    --self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    --self:RegisterEvent("UPDATE_BINDINGS")
    --self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") -- usableFlyout may change

    self.eventsRegistered = true
end

-- and here
function Germ:unregisterForBlizUiActions()
    if not self.eventsRegistered then return end

    self:EnableMouseMotion(false)
    self:RegisterForDrag("Button6Down")
    self:RegisterForClicks("Button6Down")
    --self:UnregisterAllEvents()

    self.eventsRegistered = false
end

function Germ:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId()
    -- TODO v11.1 - wrap in exeNotInCombat() ? in case "/reload" during combat
    -- set attributes used inside the secure scriptlettes
    self:SetAttribute("flyoutDirection", self:getDirection())
    self:SetAttribute("FLYOUT_MENU_NAME", self.flyoutMenu:GetName())
    self:SetAttribute("doKeybindTheButtonsOnTheFlyout", Config:get("doKeybindTheButtonsOnTheFlyout"))

    local flyoutId = self.flyoutId
    self:setMouseClickHandler(MouseClick.LEFT,   Config:getClickBehavior(flyoutId, MouseClick.LEFT))
    self:setMouseClickHandler(MouseClick.MIDDLE, Config:getClickBehavior(flyoutId, MouseClick.MIDDLE))
    self:setMouseClickHandler(MouseClick.RIGHT,  Config:getClickBehavior(flyoutId, MouseClick.RIGHT))
    self:setMouseClickHandler(MouseClick.FOUR,   Config:getClickBehavior(flyoutId, MouseClick.FOUR))
    self:setMouseClickHandler(MouseClick.FIVE,   Config:getClickBehavior(flyoutId, MouseClick.FIVE))
    self:setMouseClickHandler(MouseClick.SIX,    Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior)
end

-------------------------------------------------------------------------------
-- Handlers
--
-- Note: ACTIONBAR_SLOT_CHANGED will happen as a result of
-- some of the actions below which will in turn trigger other handlers elsewhere
-------------------------------------------------------------------------------

local hWidth = 50
local counter = { } -- eventId
function Germ:nextEventCount(eventName)
    if not counter[eventName] then
        counter[eventName] = 1
    else
        counter[eventName] = counter[eventName] + 1
    end

    return (self:getLabel() or "UnKnOwN gErM") .. eventName .. counter[eventName]
end

---@param self GERM_TYPE
function ScriptHandlers.OnMouseDown(self)
    local cursor = Cursor:get()
    if cursor then
        -- just abort because this is actually a DRAG event.  do NOT treat it like a click.
        -- Hmmm... the btn1 attribute clicker fires anyway.
        return
    end

    local event = Event:new(self, "OnMouseDown")
    zebug.info:mDiamond():owner(self):runEvent(event, function()
        self:OnMouseDown()
    end)
end

---@param self GERM_TYPE
function ScriptHandlers.OnMouseUp(self)
    if isInCombatLockdown("Drag and drop") then return end
    local event = Event:new(self, "ScriptHandlers.OnMouseUp")
    zebug.info:mCross():owner(self):event(event):runEvent(event, function()
        self:OnMouseUp()
        local isDragging = GetCursorInfo()
        if isDragging then
            self:handleReceiveDrag(event)
        else
            zebug.info:owner(self):event(event):name("ScriptHandlers.OnMouseUp"):print("not dragging, so, exiting.")
        end
    end)
end

function Germ:handleReceiveDrag(event)
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
            UfoProxy:pickupUfoOntoCursor(flyoutIdOld, event)
        else
            cursor:clear(event) -- will discard the UfoProxy if it's still there
        end

        Ufo.germLock = nil
    end
end

-- A germ on the action bar was just hit by something dropping off the user's cursor
-- The something is either a std Bliz thingy,
-- or, a UFO (which itself is represented by the "proxy" macro)
---@param self GERM_TYPE
function ScriptHandlers.OnReceiveDrag(self)
    if isInCombatLockdown("Drag and drop") then return end

    local event = Event:new(self, "OnReceiveDrag")
    zebug.info:mCircle():owner(self):runEvent(event, function()
        self:handleReceiveDrag(event)
    end)
end

---@param germ GERM_TYPE
function ScriptHandlers.OnPickupAndDrag(germ)
    if LOCK_ACTIONBAR then return end
    if not IsShiftKeyDown() then return end
    if isInCombatLockdown("Drag and drop") then return end

    local event = Event:new(self, "OnPickupAndDrag")
    zebug.info:mCircle():owner(self):runEvent(event, function()
        germ:pickupFromSlotAndClear(event)
    end)
end

---@param self GERM_TYPE
function ScriptHandlers.OnEnter(self)
    local event = Event:new(self, "OnEnter")
    zebug.info:mDiamond():owner(self):runEvent(event, function()
        self:setToolTip()
        --self:handleGermUpdateEvent(event)
    end)
end

---@param self GERM_TYPE
function ScriptHandlers.OnLeave(self)
    local event = Event:new(self, "OnLeave")
    zebug.info:mCross():owner(self):runEvent(event, function()
        GameTooltip:Hide()
        --self:handleGermUpdateEvent(event)
    end)
end

-- throttle OnUpdate because it fires as often as FPS and is very resource intensive
-- TODO: abstract this into its own class/function - throttle
local ON_UPDATE_TIMER_FREQUENCY = 10
local onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY

---@param self GERM_TYPE
function ScriptHandlers.OnUpdate(self, elapsed)
    -- do NOT run this without first wrapping it in Throttler !!!

    local event = Event:new(self, "OnUpdate")
    zebug.info:mSkull():owner(self):runEvent(event, function()
        self:handleGermUpdateEvent(event)
        self:updateAllBtnCooldownsEtc() -- nah, let the flyout do this. -- or the buttons themselves.  and have them sub/unsub based on vis
    end)
end

---@param self GERM_TYPE
function ScriptHandlers.OLD_OnUpdate(self, elapsed)
    onUpdateTimer = onUpdateTimer + elapsed
    if onUpdateTimer < ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    onUpdateTimer = 0

    local eventId = self:nextEventCount("/OnUpdate_")
    zebug.trace:owner(self):name(eventId):out(hWidth, ".",":START: poopy :START:")

    self:handleGermUpdateEvent(eventId)
    self:updateAllBtnCooldownsEtc() -- nah, let the flyout do this. -- or the buttons themselves.  and have them sub/unsub based on vis
    zebug.trace:owner(self):name(eventId):out(hWidth, ".",":END:")
end

---@param self GERM_TYPE
--[[
function ScriptHandlers.OnPreClick(self, mouseClick, down)
    -- am I not being called?  maybe the mixin is over riding me
    zebug.error:print("am I not being called?","weeee!")
    self:SetChecked(self:GetChecked())
    onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY

    local flyoutMenu = self.flyoutMenu
    if not flyoutMenu.isSharedByAllGerms then return end

    --if isInCombatLockdown("Open/Close") then return end

    local isShown = flyoutMenu:IsShown()
    local doCloseFlyout

    local otherGerm = flyoutMenu:GetParent()
    local isFromSameGerm = otherGerm == self
    zebug.trace:print("germ", self:GetName(), "otherGerm", otherGerm:GetName(), "isFromSameGerm", isFromSameGerm, "isShown",isShown)

    if isFromSameGerm then
        doCloseFlyout = isShown
    else
        doCloseFlyout = false
    end

    zebug.info:line("20","updateForGerm from Germ : handlers.OnPreClick")
    self.flyoutMenu:updateForGerm(self)
    flyoutMenu:SetAttribute("doCloseFlyout", doCloseFlyout)
    zebug.trace:print("doCloseFlyout",doCloseFlyout)
    zebug.trace:name(eventId):out(hWidth, "=",":END:")
end
]]

local oldGerm

-- this is needed for the edge case of clicking on a different germ while the current one is still open
-- in which case there is no OnShow event which is where the below usually happens
---@param self GERM_TYPE
---@param mouseClick MouseClick
function ScriptHandlers.OnPostClick(self, mouseClick, down)
    if oldGerm and oldGerm ~= self then
        self:updateAllBtnCooldownsEtc()
    end
    oldGerm = self
end

-------------------------------------------------------------------------------
-- Mouse Click Handling
--
-- SECURE TEMPLATE / RESTRICTED ENVIRONMENT
--
-- a bunch of code to make calls to SetAttribute("type",action) etc
-- to enable the Germ's button to do things in response to mouse clicks
-------------------------------------------------------------------------------

---@type Germ|Button_Mixin
local HandlerMaker = { }

---@param mouseClick MouseClick
function Germ:setMouseClickHandler(mouseClick, behavior)
    self:removeOldHandler(mouseClick)
    local installTheBehavior = getHandlerMaker(behavior)
    zebug.info:owner(self):print("mouseClick",mouseClick, "opt", behavior, "handler", installTheBehavior)
    installTheBehavior(self, mouseClick)
    self.clickers[mouseClick] = behavior
    SecureHandlerExecute(self, searchForFlyoutMenuScriptlet()) -- initialize the scriptlet's "global" vars
end

---@param behavior GermClickBehavior
---@return fun(zelf: Germ, mouseClick: MouseClick): nil
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
function HandlerMaker:OpenFlyout(mouseClick)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:owner(self):name("HandlerMakers:OpenFlyout"):print("self",self, "mouseClick",mouseClick, "secureMouseClickId", secureMouseClickId)
    local scriptName = "OPENER_SCRIPT_FOR_" .. secureMouseClickId
    zebug.info:owner(self):name("HandlerMakers:OpenFlyout"):print("germ",self.label, "secureMouseClickId",secureMouseClickId, "scriptName",scriptName)
    -- TODO v11.1 - wrap in exeNotInCombat() ?
    self:SetAttribute(secureMouseClickId,scriptName)
    self:SetAttribute("_"..scriptName, getOpenerClickerScriptlet()) -- OPENER
end

---@param mouseClick MouseClick
function HandlerMaker:ActivateBtn1(mouseClick)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:owner(self):print("secureMouseClickId",secureMouseClickId)
    self:updateSecureClicker(mouseClick)
    local btn1 = self:getBtnDef(1)
    if not btn1 then return end
    local btn1Type = btn1:getTypeForBlizApi()
    local btn1Name = btn1.name
    local type, key, val = btn1:asSecureClickHandlerAttributes()
    local keyAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
    zebug.info:owner(self):name("HandlerMakers:ActivateBtn1"):print("germ",self.label, "btn1Name",btn1Name, "btn1Type",btn1Type, "secureMouseClickId", secureMouseClickId, "type", type, "key",key, "ADJ key", keyAdjustedToMatchMouseClick, "val", val)
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
    	    -- good to go... this is being called by Germ:update() in order to initialize the click SetAttribute()s
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
            --print("clearing kid cache.  kidsCachedWhen:",kidsCachedWhen, " flyoutLastModified:",flyoutLastModified)
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
    self.clickScriptUpdaters[secureMouseClickId] = scriptToSetNextRandomBtn

    -- install the script which will install the buttons which will perform the action
    SecureHandlerWrapScript(self, "OnClick", self, scriptToSetNextRandomBtn)

    -- initialize the scriptlet's "global" vars
    SecureHandlerExecute(self, searchForFlyoutMenuScriptlet())
end

-- Fuck you yet again, Bliz, for only providing a way to remove some unknown, generally arbitrary handler but not a specific handler.
-- So now, I cry, and loop through ALL of the SecureHandlerUnwrapScript(self, "OnClick") until I find the one,
-- then restore the others that were needlessly stripped while groping the Frame in a blind, hamfisted search.

function Germ:removeOldHandler(mouseClick)
    local old = self.clickers[mouseClick]
    zebug.trace:owner(self):print("old",old)
    if not old then return end

    local needsRemoval = (old == (GermClickBehavior.RANDOM_BTN) or (old == GermClickBehavior.CYCLE_ALL_BTNS))
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
        zebug.info:owner(self):print("germ", self.label, "click",mouseClick, "old",old, "script owner", scriptsClick, "iAmOwner", isForThisClick)
        if not isForThisClick then
            rescue( header, preBody, postBody, scriptsClick )
        end
    end

    -- try to put that shit back
    for i, params in ipairs(lostBoys) do
        local success = pcall(function()
            SecureHandlerWrapScript(params[1], "OnClick", params[1], params[2], params[3])
        end )
        zebug.info:owner(self):print("germ", self.label, "click",mouseClick, "RESTORING handler for", params[4], "success?", success)
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
    local doCloseFlyout = flyoutMenu:GetAttribute("doCloseFlyout")
    local isOpen = flyoutMenu:IsShown()

	if doCloseFlyout and isOpen then
--print("OPENER_CLICKER_SCRIPTLET ... closing and exiting")
		flyoutMenu:Hide()
		flyoutMenu:SetAttribute("doCloseFlyout", false)
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
--print("OPENER_CLICKER_SCRIPTLET ... SetAttribute() doCloseFlyout = true")
    flyoutMenu:SetAttribute("doCloseFlyout", true)

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












--[[function Germ:BROKEN_new(flyoutId, btnSlotIndex, eventId)
    local parentActionBarBtn, bbInfo = BlizActionBarButton:getButton(btnSlotIndex)

    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentActionBarBtn:GetName()

    ---@type GERM_TYPE | Germ
    local self = CreateFrame(
            FrameType.CHECK_BUTTON,
            myName,
            parentActionBarBtn, -- can I make the action bar instead to satisfy SecureButtonTemplate code?
    -- including FlyoutButtonTemplate last will position the arrows but also nukes my left/right/middle click handlers
    --"SecureActionButtonTemplate, ActionButtonTemplate, ActionBarButtonCodeTemplate, FlyoutButtonTemplate"
    --"SecureActionButtonTemplate, ActionButtonTemplate, ActionBarButtonCodeTemplate"
            "GermTemplate"
    )

    _G[myName] = self -- so that keybindings can reference it

    -- one-time only initialization --

    -- initialize my fields
    self.myName       = myName
    self.btnSlotIndex = btnSlotIndex
    self.flyoutId     = flyoutId
    self.label        = self:getFlyoutDef().name
    self.bbInfo       = bbInfo

    -- install event handlers
    --self:SetScript(Script.ON_UPDATE,       handlers.OnUpdate)
    --self:SetScript(Script.ON_UPDATE,       Throttler:new(handlers.OnUpdate, 1, self.label ):asFunc() )
    self:SetScript(Script.ON_ENTER,        handlers.OnEnter)
    self:SetScript(Script.ON_LEAVE,        handlers.OnLeave)
    self:SetScript(Script.ON_RECEIVE_DRAG, handlers.OnReceiveDrag)
    self:SetScript(Script.ON_MOUSE_DOWN,   handlers.OnMouseDown)
    self:SetScript(Script.ON_MOUSE_UP,     handlers.OnMouseUp) -- is this short-circuiting my attempts to get the buttons to work on mouse up?
    self:SetScript(Script.ON_DRAG_START,   handlers.OnPickupAndDrag) -- this is required to get OnDrag to work
    self:HookScript(Script.ON_HIDE, function(self) print('***GERM*** Script.ON_HIDE for',self:GetName(),self); end)

    self:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId()

    -- manipulate methods
    self:installMyToString()
    self.originalHide = self:override("Hide", self.hide)
    self.clear = Pacifier:pacify(self, "clear")

    -- UI positioning - anchor me to the action bar button
    self:ClearAllPoints()
    self:SetAllPoints(parentActionBarBtn)
    --self:SetFrameStrata(STRATA_DEFAULT)
    --self:SetFrameLevel(STRATA_LEVEL_DEFAULT)
    --self:SetToplevel(true)

    -- Behavior
    self:setVisibilityDriver(parentActionBarBtn.btnDesc.visibleIf) -- VOLATIle
    self:registerEventListeners()

    -- FlyoutMenu
    self:initFlyoutMenu(eventId)
    self.flyoutMenu:installHandlerForCloseOnClick()
    -- TODO v11.1 - wrap in exeNotInCombat() ? in case "/reload" during combat
    self:SetAttribute("flyoutDirection", self:getDirection())
    self:SetAttribute("FLYOUT_MENU_NAME", self.flyoutMenu:GetName())
    self:SetAttribute("doKeybindTheButtonsOnTheFlyout", Config:get("doKeybindTheButtonsOnTheFlyout"))

    return self
end
]]




