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
---@field primeBtnIndex number Identifies which button on the flyout is currently the PRIME_BTN
---@field flyoutMenu FM_TYPE The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
---@field clickScriptUpdaters table secure scriptlets that must be run during any update()
---@field bbInfo table definition of the actionbar/button where the Germ lives
---@field visibleIf string for RegisterStateDriver -- uses macro-conditionals to control visibility automatically
---@field visibilityDriver string primarily for debugging
---@field myName string duh
---@field mainKeyBindingsKeyNames table<string,boolean> the names of the keys bound to this Germ's action bar button
---@field label string human friendly identifier

---@type Germ | GERM_INHERITANCE
Germ = {
    ufoType = "Germ",
    --clickScriptUpdaters = {},
    clickers = {},
    mainKeyBindingsKeyNames = {},
    primeBtnIndex = 1,
}
UfoMixIn:mixInto(Germ)
GLOBAL_Germ = Germ

---@class GermClickBehavior
GermClickBehavior = {
    OPEN = "OPEN",
    PRIME_BTN = "PRIME_BTN",
    RANDOM_BTN = "RANDOM_BTN",
    CYCLE_ALL_BTNS = "CYCLE_ALL_BTNS",
    --REVERSE_CYCLE_ALL_BTNS = "REVERSE_CYCLE_ALL_BTNS",
}

---@type table<GermClickBehavior, MouseClick>
RESERVED_CLICKER_BEHAVES_AS = {
    [GermClickBehavior.OPEN]           = MouseClick.SEVEN,
    [GermClickBehavior.PRIME_BTN]      = MouseClick.EIGHT,
    [GermClickBehavior.RANDOM_BTN]     = MouseClick.NINE,
    [GermClickBehavior.CYCLE_ALL_BTNS] = MouseClick.TEN,
}

---@type Germ|GERM_INHERITANCE
local GermClickBehaviorAssignmentFunction = { }

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@type GERM_TYPE for the benefit of my IDE's autocomplete
local ScriptHandlers = {}
local SEC_ENV_SCRIPT_FOR_ON_CLICK

---@type table<string,Germ> all keybindings currently in use by any Germs
local mainKeyBindingsForAllGerms = {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
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
    self.isNew = true -- a flag to silence messages during 1st time creation

    -- one-time only initialization --
    self.myName       = myName -- who
    self.btnSlotIndex = btnSlotIndex -- where
    self.flyoutId     = flyoutId -- what

    -- manipulate methods
    self:installMyToString() -- do this as soon as possible for the sake of debugging output
    -- self.originalHide = self:override("Hide", self.hide)

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
    self:initLabelString()
    self:applyConfigForShowLabel(event)
    self:doIcon(event)
    self:setVisibilityDriver(parentBlizActionBarBtn.visibleIf) -- do I even need this? when the parent Hides so will the Germ automatically

    -- secure tainty stuff
    self:copyDoCloseOnClickConfigValToAttribute()
    self:doMyKeybindings(event) -- bind me to my action bar slot's keybindings (if any)

    -- Initialize the Primary Button option
    local isPrimeDefinedAsRecent = Config:isPrimeDefinedAsRecent()
    self:SetAttribute("IS_PRIME_RECENT", isPrimeDefinedAsRecent)

    -- Blizz things
    ButtonStateBehaviorMixin.OnLoad(self)
    self:UpdateArrowShown()
    self:UpdateArrowPosition()
    self:UpdateArrowRotation()

    self.isNew = false

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
    self:applyConfigForShowLabel(event)
    self:updateClickerForBtn1(event)
    self:closeFlyout() -- in case the buttons' number/ordering changes
    self.flyoutMenu:applyConfigForGerm(self, event)
end

function Germ:applyConfigForShowLabel(event)
    local txt = Config:get("showLabels") and self:getLabel() or ""
    self.Name:SetText(txt)
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

Germ.initLabelString = Germ.getLabel

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
    return usableFlyout:getIcon(self.primeBtnIndex) or flyoutDef.fallbackIcon or DEFAULT_ICON
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

    -- TODO - fix bug: actionbar #1 buttons vanish

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
function Germ:hide(event)
    --VisibleRegion:Hide(self) -- L-O-FUCKING-L this threw  "attempt to index global 'VisibleRegion' (a nil value)" was called from SecureStateDriver.lua:103
    zebug.info:event(event or "Blizz-Call"):owner(self):print("hiding.")
    -- evidently, self:Hide() is called several times per second during state driver of visibility state==hide
    local hide = self.originalHide or self.Hide
    hide(self)
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
    -- seems like if the new flyoutId is the same as a the old one, then, I could skip a lot (all?) of this...
    -- but I vaguely remember that I tried that and something went wrong... but I can't remember why.
    self.flyoutId = flyoutId
    self:initLabelString()
    zebug.info:event(event):owner(self):print("EnAbLe GeRm :-)")

    self:closeFlyout()
    self:doIcon(event)
    self.flyoutMenu:applyConfigForGerm(self, event)
    self:registerForBlizUiActions(event)
    self:clearKeybinding()
    self:doMyKeybindings(event)
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
        if cursorBeforeItDrops:isUfoProxyForFlyout() then
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
    local btn = self:getPrimeBtn()
    if btn and btn.hasDef and btn:hasDef() then
        btn:setTooltip()
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
    return self:getUsableFlyoutDef():getButtonDef(n)
end

-- required by Button_Mixin
function Germ:getDef()
    return self:getBtnDef(self.primeBtnIndex or 1)
end

---@return BOFM_TYPE
function Germ:getPrimeBtn()
    return self.flyoutMenu:getBtn(self.primeBtnIndex or 1)
end

function Germ:invalidateFlyoutCache()
    self:getFlyoutDef():invalidateCache()
end

function Germ:refreshFlyoutDefAndApply(event)
    zebug.info:event(event):owner(self):print("re-configuring...") -- name("refreshFlyoutDefAndApply"):
    self:getFlyoutDef():invalidateCacheOfUsableFlyoutDefOnly(event)
    self:applyConfigFromFlyoutDef(event) -- exclude clickers?
end

-------------------------------------------------------------------------------
-- Key Bindings & UI actions Registerings
-------------------------------------------------------------------------------

function Germ:doneSaid(key)
    local result
    if not self.DONE_SAID then
        self.DONE_SAID = { }
    end

    result = self.DONE_SAID[key]
    self.DONE_SAID[key] = true
    return result
end

function Germ:fullModifiedKeyName(key, ...)
    if select("#", ...) == 0 then return key end -- nothing in "..." means no modifiers means no work to do.
    local fullKey = strjoin("-", ...) .. "-" .. strupper(key)
    return fullKey
end

function Germ:bindKeyNameTo(keyName, mouseClick)
    return self:addModifiersToKeyNameAndBind(keyName, mouseClick) -- no args for any modifiers (shift/alt/etc)
end

---@param unmodifiedKeyName string
---@param mouseClick MouseClick
---@vararg ModifierKey list of 0 or more
---@return string original name plus modifiers (if any) IF it was successfully bound or is a Germ binding still in use
function Germ:addModifiersToKeyNameAndBind(unmodifiedKeyName, mouseClick, --[[modifiers]] ...)
    local keyName = strupper(unmodifiedKeyName)
    local isMainBinding

    local modCount = select("#", ...)
    if modCount == 0 then
        -- if we didn't pass in any modifiers, then this is the Germ's base binding
        isMainBinding = true
        self.mainKeyBindingsKeyNames[keyName] = true
    else
        -- filter out any modifiers that are already present in the in base binding to avoid something like SHIFT-SHIFT-Z
        local filteredModifiers
        for i = 1, modCount do
            local modifier = strupper( select(i, ...) )
            local hasAlready = string.find(keyName, modifier)
            if not hasAlready then
                zebug.trace:owner(self):print("KEY",keyName, "ok to add modifier",modifier)
                if not filteredModifiers then filteredModifiers = {} end
                filteredModifiers[#filteredModifiers+1] = modifier
            else
                zebug.trace:owner(self):print("KEY",keyName, "already includes modifier",modifier)
            end
        end

        if not filteredModifiers then
            zebug.info:owner(self):print("KEY",keyName, "ABORT - all desired modifiers already in base binding", ...)
            return
        end

        local keyNamePlusModifiers = strjoin("-", unpack(filteredModifiers) ) .. "-" .. keyName -- TODO: does the order matter? Is ALT-SHIFT-Z as good as SHIFT-ALT-Z
        keyName = keyNamePlusModifiers
    end

    local isAlreadyProcessedAndBoundToMe = tableContainsVal(self.keybinds, keyName)
    if isAlreadyProcessedAndBoundToMe then
        zebug.info:owner(self):print("KEY",keyName, "SKIP: already bound! self.keybinds contains this key.")
        -- returning the name to signal the caller that this one is still in use so don't remove it
        return keyName
    end

    if isMainBinding then
        self:claimMainKeyBinding(keyName)
    else
        -- decide if we can steal a key that is already bound
        local isOkForExtra = true
        local otherGerm = self:isAlreadyMainKeyBindingOfSomeOtherGerm(keyName)
        if otherGerm then
            -- never steal a "main binding" from another germ
            zebug.info:owner(self):print("KEY",keyName, "Will not add extra binding for this key because existing UFO", otherGerm, "is already bound to it.")
            if not self.isNew then
                msgUser(self:forUser(), "with keybinding", unmodifiedKeyName, "will not bind", keyName, "because that one is already bound to", otherGerm:forUser())
            end
            isOkForExtra = false
            return
        end

        local action
        local targetBtn
        local isNoClobber = Config:get("doNotOverwriteExistingKeybindings")
        if isNoClobber then

            -- check for an existing key binding
            action = GetBindingAction(keyName, true) -- returns empty string instead of nil - FU Bliz
            action = exists(action) and action or nil -- ensure a meaningful value and not Bliz BS

            if action then
                -- but, is it an action bar button?
                targetBtn = BlizActionBarButtonHelper:getViaKeyBinding(action)
                if targetBtn then
                    zebug.info:owner(self):print("KEY", keyName, "existingBinding", action, "btn", targetBtn)

                    -- is that button EMPTY?
                    isOkForExtra = targetBtn:isEmpty()
                    if not isOkForExtra then
                        zebug.info:owner(self):print("KEY", keyName, "Will not add extra binding for this key because it conflicts with", targetBtn)
                        --if not self:doneSaid(keyName) then
                        if not self.isNew then
                            msgUser(self:forUser(), "with keybinding", unmodifiedKeyName, "will not bind", keyName, "because that one is already bound to", targetBtn:forUser())
                        end
                        --end
                        return
                    end
                else
                    -- there is an action but it's not a button, eg FORWARD or TOGGLERUN.  Don't touch it!
                    isOkForExtra = false
                end
            end
        end

        zebug.info:owner(self):print("KEY", keyName, "existingBinding", action, "btn", targetBtn, "isOkForExtra",isOkForExtra)

        if not isOkForExtra then
            return
        end
    end

    local myGlobalVarName = self:GetName()
    SetOverrideBindingClick(self, true, keyName, myGlobalVarName, mouseClick)

    -- debugging err check - remove when done
    local newBinding = GetBindingAction(keyName, true)
    zebug.info:owner(self):print("KEY", keyName, "BOUND! newBinding", newBinding)

    return keyName
end

---@return Germ the germ that is already bound to this keyName
function Germ:isAlreadyMainKeyBindingOfSomeOtherGerm(keyName)
    ---@type Germ
    local someGerm = mainKeyBindingsForAllGerms[keyName]
    if someGerm then
        -- is that Germ me?
        return (someGerm ~= self) and someGerm
    end
    return nil -- no Germ claims this binding
end

function Germ:isMyBoundKey(isMyBoundKey)
    for keyName, foo in pairs(self.mainKeyBindingsKeyNames) do
        if keyName == isMyBoundKey then return true end
    end
end

function Germ:claimMainKeyBinding(keyName)
    ---@type Germ
    self.mainKeyBindingsKeyNames[keyName] = true
    mainKeyBindingsForAllGerms[keyName] = self
end

function Germ:doMyKeybindings(event)
    if isInCombatLockdown("Keybind") then return end

    local parent = self:getParent()
    local btnName = parent.btnYafName or parent.btnName
    local ucBtnName = string.upper(btnName)
    local myGlobalVarName = self:GetName()
    local keybindingsAssignedToMyActionBarButton
    if GetBindingKey(ucBtnName) then
        keybindingsAssignedToMyActionBarButton = { GetBindingKey(ucBtnName) }
    end

    -- add new keybinds
    local newKeyBindings = {}
    if keybindingsAssignedToMyActionBarButton then
        for i, keyName in ipairs(keybindingsAssignedToMyActionBarButton) do

            -- handle the MAIN keybinding(s)
            table.insert(newKeyBindings, keyName)
            local isAdded = self:bindKeyNameTo(keyName, MouseClick.RESERVED_FOR_KEYBIND)
            if isAdded then
                zebug.info:event(event):owner(self):print("bound keyName", keyName)

                local keybind1 = keybindingsAssignedToMyActionBarButton[1]
                self:setHotKeyOverlay(keybind1)
                if not isNumber(keybind1) then
                    -- store it for use inside the secure code
                    -- so we can make the first button's keybind be the same as the UFO's
                    self:setSecEnvAttribute("UFO_KEYBIND_1", keybind1)
                end
            else
                zebug.info:event(event):owner(self):print("NOT binding keyName", keyName, "because it's already bound.")
            end

            -- handle the MODIFIED (shift/alt/etc) keybinding(s)
            if Config:get("enableBonusModifierKeys") then
                local bonusModifierKeys = Config:get("bonusModifierKeys")

                ---@param modifierKey ModifierKey
                ---@param behavior GermClickBehavior
                for modifierKey, behavior in pairs(bonusModifierKeys) do

                    local clicker = RESERVED_CLICKER_BEHAVES_AS[behavior]



                    -- DONE? - I must differentiate between KB I create VS those in the Bliz Opt

                    zebug.info:event(event):owner(self):print("CONFIG OPTS LOOP - binding - keyName", keyName, "modifierKey",modifierKey, "behavior",behavior)
                    local modName = self:addModifiersToKeyNameAndBind(keyName, clicker, modifierKey)

                    if modName then
                        table.insert(newKeyBindings, modName)
                    else
                        zebug.info:event(event):owner(self):print("NOT binding BonusModifier for Key", keyName, "plus",modifierKey)
                    end
                end
            else
                zebug.info:event(event):owner(self):print("CONFIG OPTS - nope!  No bonusModifierKeys for you!")
            end

        end
    else
        self:setHotKeyOverlay(nil)
        self:clearKeybinding()
    end

    -- remove deleted keybinds
    if (self.keybinds) then
        for i, keyName in ipairs(self.keybinds) do
            if not tableContainsVal(newKeyBindings, keyName) then
                zebug.trace:event(event):owner(self):print("myGlobalVarName", myGlobalVarName, "UN-binding keyName",keyName)
                SetOverrideBinding(self, true, keyName, nil)
            else
                zebug.trace:event(event):owner(self):print("myGlobalVarName", myGlobalVarName, "NOT UN-binding keyName",keyName, "because it's still bound.")
            end
        end
    end

    self.keybinds = newKeyBindings
end

Germ.doMyKeybindings = Pacifier:wrap(Germ.doMyKeybindings, L10N.CHANGE_KEYBINDING)

function Germ:clearKeybinding()
    if not (self.keybinds) then return end

    exeOnceNotInCombat("Keybind removal "..self:getName(), function()
        -- FUNC START
        ClearOverrideBindings(self)
        self.keybinds = nil
        for keyName, foo in pairs(self.mainKeyBindingsKeyNames) do
            mainKeyBindingsForAllGerms[keyName] = nil
        end
        self.mainKeyBindingsKeyNames = { }
        self:setHotKeyOverlay(nil)
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

        if cursor:isUfoProxyForFlyout() then
            -- soup to nuts. do everything without relying on the ACTIONBAR_SLOT_CHANGED handler
            -- don't let the UfoProxy hit the actionbar.
            zebug.info:event(event):owner(self):print("cursor is a proxy",cursor)
            local flyoutIdNew = UfoProxy:getFlyoutId()
            self:changeFlyoutIdAndEnable(flyoutIdNew, event)
            Placeholder:put(self.btnSlotIndex, event) -- will discard the UfoProxy in favor of a Placeholder
            GermCommander:savePlacement(self.btnSlotIndex, flyoutIdNew, event)
        elseif cursor:isUfoProxyForButton() then
            -- The user has dropped the fake button proxy onto the action bar.
            ButtonOnFlyoutMenu:abortIfUnusable(Ufo.pickedUpBtn)

            -- ignore it
            Ufo.germLock = nil
            return
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
            zebug.info:owner(self):event(event):name("ScriptHandlers:ON_MOUSE_DOWN"):print("not dragging, so, exiting. proxy",UfoProxy)
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
    if _G.LOCK_ACTIONBAR then return end
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

---@class SecEnvConst
---@field OPENER_NAME string key for the sec-env attribute that will hold the OPENER_SCRIPT
---@field OPENER_SCRIPT string code. will be initialized on-demand
---@field ON_CLICK_PICK_BTN_NAME_PREFIX string code key for the sec-env attribute that will hold the
---@field ON_CLICK_PICK_BTN_SCRIPT string code. will be initialized on-demand
local SecEnvConst = {
    OPENER_NAME = "SEC_ENV_OPENER_NAME",
    ON_CLICK_PICK_BTN_NAME_PREFIX = "SEC_ENV_ON_CLICK_PICK_BTN_NAME_PREFIX_",
}

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

    -- these mouse clicks are unconditionally reserved & hardcoded for special key bindings
    for behavior, click in pairs(RESERVED_CLICKER_BEHAVES_AS) do
        self:assignTheMouseClicker(click, behavior, event)
    end

    self:applyConfigForMainKeybind(event)
end

-- sets secure environment scripts to handle mouse clicks (left button, right button, etc)
---@param mouseClick MouseClick
---@param behaviorName GermClickBehavior
function Germ:assignTheMouseClicker(mouseClick, behaviorName, event)
    if not behaviorName then
        GermClickBehaviorAssignmentFunction.NONE(self, mouseClick, event)
        return
    end

    if not GermClickBehavior[behaviorName] then
        error("Invalid 'behaviorName' arg: " .. (behaviorName or "NiL")) -- type checking in Lua!
    end

    local behave = GermClickBehaviorAssignmentFunction[behaviorName]
    if not behave then
        error(behave, "there is no method defined for GermClickBehavior of ".. behaviorName)
    end

    zebug.info:owner(self):event(event):print("mouseClick",mouseClick, "behaviorName", behaviorName, "handler", behave)
    behave(self, mouseClick, event)

    -- tell the ButtonOnFlyoutMenu that this mouseClick is PRIME_BTN
    local isPrime = behaviorName == GermClickBehavior.PRIME_BTN
    local n = MouseClickAsSecEnvN[mouseClick]
    self:SetAttribute("IS_A_PRIME_BTN_"..n, isPrime) -- assume earlier code blocked exe during combat
end

-- the secEnv handler for "click the first button of the flyout" is special.
-- it won't automatically accommodate changes to the flyout buttons and must be re-applied for any changes to flyoutDef
-- TODO: consider folding it into the ON_CLICK script along with the RANDOM_BTN and CYCLE_ALL_BTNS
function Germ:updateClickerForBtn1(event)
    -- loop over all mouse buttons
    for _, mouseClick in ipairs(MOUSE_BUTTONS) do
        local behaviorName = Config:getGermClickBehavior(self.flyoutId, mouseClick)
        if behaviorName == GermClickBehavior.PRIME_BTN then
            self:assignTheMouseClicker(mouseClick, behaviorName, event)
        end
    end
end

function Germ:applyConfigForMainKeybind(event)
    local keybindBehavior = Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior
    self:assignTheMouseClicker(MouseClick.RESERVED_FOR_KEYBIND, keybindBehavior, event)
end

function Germ:removeSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, nil)
end

---@param mouseClick MouseClick
---@param clickBehavior GermClickBehavior
function Germ:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, clickBehavior)
    local name = SecEnvConst.ON_CLICK_PICK_BTN_NAME_PREFIX .. mouseClick
    self:setSecEnvAttribute(name, clickBehavior)
end

function Germ:setRecentIcon(icon)
    if not self:isActive() then return end
    if not Config:isAnyClickerUsingRecent(self.flyoutId) then return end
    -- icon = icon or self.promoter:GetAttribute("UFO_ICON")
    zebug.info:owner(self):print("sneaky! icon", icon)
    self:setIcon(icon,"promoter")
end

---@param btn ButtonOnFlyoutMenu
function Germ:promoteButtonToPrime(btn)
    if not self:isActive() then return end

    local n = btn:getId()
    self.primeBtnIndex = n or 1
    self:setIcon(btn.iconTexture, "promoter")
end


-------------------------------------------------------------------------------
--
-- SecEnv - GermClickBehaviorAssignmentFunction
-- deal with OPEN / PRIME_BTN / RANDOM_BTN / CYCLE_ALL_BTNS
--
-------------------------------------------------------------------------------

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:NONE(mouseClick, event)
    self:removeSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick)
    self:removeSecEnvMouseClickBehaviorVia_Attribute(mouseClick)
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:OPEN(mouseClick, event)
    self:removeSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick)
    zebug.info:event(event):owner(self):name("HandlerMakers:OpenFlyout"):print("mouseClick",mouseClick)
    self:assignSecEnvMouseClickBehaviorVia_Attribute(mouseClick, SecEnvConst.OPENER_NAME)
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:PRIME_BTN(mouseClick, event)
    self:removeSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick)
    self:assignSecEnvMouseClickBehaviorVia_AttributeFromBtnDef(mouseClick, event) -- assign attributes, eg: "type1" -> "macro" -> "macro1" -> macroId
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:RANDOM_BTN(mouseClick, event)
    self:removeSecEnvMouseClickBehaviorVia_Attribute(mouseClick)
    self:assignSecEnvMouseClickBehaviorVia_ON_CLICK(mouseClick, GermClickBehavior.RANDOM_BTN)
end

---@param mouseClick MouseClick
function GermClickBehaviorAssignmentFunction:CYCLE_ALL_BTNS(mouseClick, event)
    self:removeSecEnvMouseClickBehaviorVia_Attribute(mouseClick)
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
    self:setSecEnvAttribute("_".. SecEnvConst.OPENER_NAME, self:getSecEnvScriptFor_Opener())
end

function Germ:installSecEnvScriptFor_ON_CLICK()
    assert(not self.onClickScriptInitialized, "Wut?  The ON_CLICK_SCRIPT is already installed.  Why you call again?")
    self.isOnClickScriptInitialized = true
    self:WrapScript(self, Script.ON_CLICK, self:getSecEnvScriptFor_ON_CLICK() )
end

function Germ:getSecEnvScriptFor_Opener()
    if not SecEnvConst.OPENER_SCRIPT then
        local DIRECTION_AS_ANCHOR = serializeAsAssignments("DIRECTION_AS_ANCHOR", DirectionAsAnchor)
        local ANCHOR_OPPOSITE = serializeAsAssignments("ANCHOR_OPPOSITE", AnchorOpposite)

        SecEnvConst.OPENER_SCRIPT =
[=[
--local doDebug = true

    local mouseClick = button
    local isClicked = down
    local dir = germ:GetAttribute( "]=].. SecEnvAttribute.flyoutDirection ..[=[" )
    local isVert = dir == "UP" or dir == "DOWN"
    local isOpen = flyoutMenu:IsShown()
    local initialSpacing = ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[
    local defaultSpacing = ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[
    local finalSpacing   = ]=].. SPELLFLYOUT_FINAL_SPACING ..[=[
    ]=].. DIRECTION_AS_ANCHOR ..[=[
    ]=].. ANCHOR_OPPOSITE ..[=[

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "OPENER_SCRIPT <START> germ =", germ, "flyoutMenu =",flyoutMenu, "mouseClick",mouseClick, "isClicked",isClicked, "dir",dir, "isOpen",isOpen)
    --[[DEBUG]] end

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

    -- attach the flyout to the germ

    flyoutMenu:ClearAllPoints()
    flyoutMenu:SetParent(germ)  -- holdover from single FM
    local anchorOnGerm = DIRECTION_AS_ANCHOR[dir]
    local ptOnMe   = ANCHOR_OPPOSITE[anchorOnGerm]
    flyoutMenu:SetPoint(ptOnMe, germ, anchorOnGerm, 0, 0)

    -- arrange all the buttons onto the flyout

    -- get the buttons, filtering out trash
    local btns = table.new(flyoutMenu:GetChildren())
    while btns[1] and btns[1]:GetID() < 1 do
        --print("discarding", btns[1]:GetObjectType())
        table.remove(btns, 1) -- this is the non-button UI element "Background" from ui.xml
    end

    -- count the buttons being used on the flyout
    local numButtons = 0
    for i, btn in ipairs(btns) do
        local isInUse = btn:GetAttribute("UFO_NAME")
        if isInUse then
            numButtons = numButtons + 1
        end
    end

-- calculate if the flyout is too long, then how many rows & columns
local configMaxLen = 20
local vertLineWrapDir = "RIGHT"
local horizLineWrapDir = "UP"
local linesCountMax = math.ceil(numButtons / configMaxLen, 1)
local maxBtnsPerLine = math.ceil(numButtons / linesCountMax)
--[[DEBUG]] -- print("configMaxLen",configMaxLen, "numButtons =",numButtons, "maxBtnsPerLine",maxBtnsPerLine, "linesCountMax",linesCountMax)
if linesCountMax > configMaxLen then
    linesCountMax = math.floor( math.sqrt(numButtons) )
	    --[[DEBUG]] if doDebug then
        --[[DEBUG]] print("TOO WIDE! sqrt =",linesCountMax)
        --[[DEBUG]] end
end

    local x,y,linesCount,btnCountForThisLine = 1,1,1,0
    local lineGirth, lineOff
	local anyBumper = nil
	local firstBumperOfPreviousLine = nil
	local anchorBuddy = flyoutMenu
    for i, btn in ipairs(btns) do
        local wrapper = btn.bumper
        local bumper = btn.bumper
        --[[DEBUG]] --print("wrapper =",wrapper)


    local muhKids = table.new(btn:GetChildren())
    for i, frame in ipairs(muhKids) do
        --[[DEBUG]] -- print("i =",i, "name", frame:GetName(), frame:GetID())
        if frame:GetID() == 99 then
            bumper = frame
        end
    end

        local isInUse = btn:GetAttribute("UFO_NAME")

	    --[[DEBUG]] if doDebug then
        --[[DEBUG]] print("i:",i, "btn:",btn:GetName(), "isInUse",isInUse)
        --[[DEBUG]] end

        if isInUse then

            --[[DEBUG]] if doDebug then
            --[[DEBUG]] print("SNIPPET... i:",i, "bumper:",bumper:GetName())
            --[[DEBUG]] end
            bumper:ClearAllPoints()

            local xLineBump = 0
            local yLineBump = 0
            btnCountForThisLine = btnCountForThisLine + 1

--local doDebug = true

local isFirstBtnOfLine
if btnCountForThisLine > maxBtnsPerLine then
    isFirstBtnOfLine = true
    anchorBuddy = firstBumperOfPreviousLine or flyoutMenu
    linesCount = linesCount + 1
    local btnSize = isVert and bumper:GetHeight() or bumper:GetWidth()
    lineGirth = (btnSize + defaultSpacing)
    lineOff = lineGirth * (linesCount-1)
    xLineBump = 0 -- isVert and lineOff or 0
    yLineBump = 0 -- not isVert and lineOff or 0
    --[[DEBUG]] if doDebug then
    --[[DEBUG]] print("=== BREAK === maxBtnsPerLine",maxBtnsPerLine, "linesCount",linesCount, "btnCountForThisLine",btnCountForThisLine, "btnSize",btnSize, "lineGirth",lineGirth)
    --[[DEBUG]] end
    btnCountForThisLine = 0
end

            local isFirstBtn     = anchorBuddy == flyoutMenu
            local spacing        = isFirstBtn and initialSpacing or defaultSpacing
            local anchorForDir   = DIRECTION_AS_ANCHOR[dir]
            local anchorOpposite = ANCHOR_OPPOSITE[anchorForDir]
            local ptOnMe     = anchorOpposite
            local ptOnAnchorBuddy = isFirstBtn and anchorOpposite or anchorForDir

            if isFirstBtn then
                -- anchor a corner of the btn to the same corner of the flyout
                -- the anchor is the opposite corner from the flyout's grow direction and wrap dir
                -- eg, flies up and grows right, then anchor corner is bottom-left
                local anchPrefix, tmp, anchPost
                if isVert then
                    anchPrefix = anchorOpposite
                    tmp = DIRECTION_AS_ANCHOR[vertLineWrapDir]
                    anchPost = ANCHOR_OPPOSITE[tmp]
                else
                    tmp = DIRECTION_AS_ANCHOR[horizLineWrapDir]
                    anchPrefix = ANCHOR_OPPOSITE[tmp]
                    anchPost = anchorOpposite
                end
                ptOnAnchorBuddy = anchPrefix..anchPost
                ptOnMe = ptOnAnchorBuddy
            elseif isFirstBtnOfLine then
                if isVert then
                    ptOnAnchorBuddy = DIRECTION_AS_ANCHOR[vertLineWrapDir]
                    ptOnMe = ANCHOR_OPPOSITE[ptOnAnchorBuddy]
                else
                    ptOnAnchorBuddy = DIRECTION_AS_ANCHOR[horizLineWrapDir]
                    ptOnMe = ANCHOR_OPPOSITE[ptOnAnchorBuddy]
                end
            end

            local wW = bumper:GetWidth()
            local wH = bumper:GetHeight()
            local aW = btn:GetWidth()
            local aH = btn:GetHeight()

            --[[DEBUG]] if doDebug then
            --[[DEBUG]] print("ptOnMe",ptOnMe, "ptOnAnchorBuddy",ptOnAnchorBuddy, "anchorBuddy", anchorBuddy:GetName(), "wW",math.floor(wW), "wH",math.floor(wH),  "aW",math.floor(aW), "aH",math.floor(aH))
            --[[DEBUG]] end

            bumper:SetPoint(ptOnMe, anchorBuddy, ptOnAnchorBuddy, 0, 0)
            anchorBuddy:Show()

            --
            -- keybind each button to 1-9 and 0
            --

            local doKeybindTheButtonsOnTheFlyout = germ:GetAttribute("doKeybindTheButtonsOnTheFlyout")
            if doKeybindTheButtonsOnTheFlyout then
                if i < 11 then
                    -- TODO: make first keybind same as the UFO's
                    local numberKey = (i == 10) and "0" or tostring(i)
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

            if btnCountForThisLine == 1 then
                firstBumperOfPreviousLine = bumper
            end

            anyBumper = bumper
            anchorBuddy = bumper
            btn:Show()
        else
            btn:Hide()
        end
    end

    local btnW = anyBumper and anyBumper:GetWidth() or 10
    local btnH = anyBumper and anyBumper:GetHeight() or 10
    local btnsPerLine = (numButtons == 0) and 2 or maxBtnsPerLine

    if isVert then
        flyoutMenu:SetWidth(btnW * linesCount)
        flyoutMenu:SetHeight(btnH * btnsPerLine)
    else
        flyoutMenu:SetWidth(btnW * btnsPerLine)
        flyoutMenu:SetHeight(btnH * linesCount)
    end

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "SHOWING flyout")
    --[[DEBUG]] end
    flyoutMenu:Show()
]=]
    end

    return SecEnvConst.OPENER_SCRIPT
end

function Germ:getSecEnvScriptFor_ON_CLICK()
    if not SecEnvConst.ON_CLICK_PICK_BTN_SCRIPT then
        local MAP_MOUSE_CLICK_AS_A_TYPE = serializeAsAssignments("MAP_MOUSE_CLICK_AS_A_TYPE", MouseClickAsSecEnvId)
        local MAP_MOUSE_CLICK_AS_NUMBER = serializeAsAssignments("MAP_MOUSE_CLICK_AS_NUMBER", MouseClickAsSecEnvN)

        SecEnvConst.ON_CLICK_PICK_BTN_SCRIPT =
[=[
        -- CONSTANTS
        local CYCLE_ALL_BTNS  = "]=].. GermClickBehavior.CYCLE_ALL_BTNS ..[=["
        local RANDOM_BTN      = "]=].. GermClickBehavior.RANDOM_BTN ..[=["
        local ON_CLICK_PREFIX = "]=].. SecEnvConst.ON_CLICK_PICK_BTN_NAME_PREFIX ..[=["
        ]=].. MAP_MOUSE_CLICK_AS_A_TYPE ..[=[
        ]=].. MAP_MOUSE_CLICK_AS_NUMBER ..[=[

        -- INCOMING PARAMS - rename/remap Blizard's idiotic variables and SHITTY identifiers
        local isClicked          = down -- true/false
        local mouseClick         = button -- "LeftButton" etc
        local secEnvMouseClickId = MAP_MOUSE_CLICK_AS_A_TYPE[mouseClick] -- turn "LeftButton" into "type1" etc
        local mouseBtnNumber     = MAP_MOUSE_CLICK_AS_NUMBER[mouseClick] -- turn "LeftButton" into "1" etc

        -- logic figuring out what's going to happen
        local behaviorKey    = ON_CLICK_PREFIX .. mouseClick
        local behavior       = self:GetAttribute(behaviorKey)
        local doCycle        = (behavior == CYCLE_ALL_BTNS)
        local doRandomizer   = (behavior == RANDOM_BTN)
        local onlyInitialize = (mouseClick == nil)

        --[[DEBUG]] if doDebug and isClicked then
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() mouseClick",mouseClick, "isClicked",isClicked, "onlyInitialize",onlyInitialize)
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() behaviorKey",behaviorKey, "behavior",behavior, "doCycle",doCycle, "doRandomizer",doRandomizer)
        --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() secEnvMouseClickId",secEnvMouseClickId, "mouseBtnNumber",mouseBtnNumber)
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
        local SEC_ENV_ACTION_TYPE   = btn:GetAttribute("SEC_ENV_ACTION_TYPE") -- set inside assignSecEnvAttributeForMouseClick()
        local SEC_ENV_ACTION_TYPE_D = btn:GetAttribute("SEC_ENV_ACTION_TYPE_DUMBER") -- set inside assignSecEnvAttributeForMouseClick()
        local SEC_ENV_ACTION_ARG    = btn:GetAttribute("SEC_ENV_ACTION_ARG") -- set inside assignSecEnvAttributeForMouseClick()
        local SEC_ENV_ACTION_TYPE_ADJUSTED = SEC_ENV_ACTION_TYPE .. mouseBtnNumber -- convert "macro" into "marco1" etc
        local SEC_ENV_ACTION_TYPE_DUMBER_AND_ADJUSTED = SEC_ENV_ACTION_TYPE_D .. mouseBtnNumber -- convert "macrotext" into "macrotext1" etc

        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "type",type, "SEC_ENV_TYPE_DUMB_ADJ",SEC_ENV_ACTION_TYPE_DUMBER_AND_ADJUSTED, "SEC_ENV_ACTION_ARG",SEC_ENV_ACTION_ARG)
        --[[DEBUG]] end

        -- copy the btn's behavior onto myself
        self:SetAttribute(secEnvMouseClickId, type)
        self:SetAttribute(SEC_ENV_ACTION_TYPE_DUMBER_AND_ADJUSTED, SEC_ENV_ACTION_ARG)

        if SEC_ENV_ACTION_TYPE ~= SEC_ENV_ACTION_TYPE_D then
            self:SetAttribute(SEC_ENV_ACTION_TYPE_ADJUSTED, nil) -- handle case of macro, macrotext, "/petattack" which would leave macro -> stale data
        end
]=]
    end
    return SecEnvConst.ON_CLICK_PICK_BTN_SCRIPT
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
    zebug.warn:event(event):owner(self):print("isActive",self:isActive(), "IsShown",self:IsShown(), "IsVisible",self:IsVisible(), "parent", parentName, "flyoutMenu",self.flyoutMenu, "visibilityDriver",self.visibilityDriver)

    local t = self:GetAttribute("type") or "NIL"
    local t1 = self:GetAttribute("type1") or "NIL"
    local t2 = self:GetAttribute("type2") or "NIL"
    local t3 = self:GetAttribute("type3") or "NIL"
    local t6 = self:GetAttribute("type6") or "NIL"

    local v  = self:GetAttribute(t) or "nIl"
    local v1 = self:GetAttribute(t1.."1") or "nIl"
    local v2 = self:GetAttribute(t2.."2") or "nIl"
    local v3 = self:GetAttribute(t3.."3") or "nIl"
    local v6 = self:GetAttribute(t6.."6") or "nIl"

    local d  = self:GetAttribute("SEC_ENV_ACTION_TYPE_DUMBER") or "nIl"
    local d0 = self:GetAttribute(d) or "nIl"
    local d1 = self:GetAttribute(d.."1") or "nIl"
    local d2 = self:GetAttribute(d.."2") or "nIl"
    local d3 = self:GetAttribute(d.."3") or "nIl"
    local d6 = self:GetAttribute(d.."6") or "nIl"
    zebug.warn:event(event):owner(self):print("t=atr['typeX'] and atr[tX] - t",t, "v",v,  "d",d, "d0",d0, "t1",t1, "v1",v1, "d1",d1,   "t2",t2, "v2",v2, "d2",d2, "t3",t3, "v3",v3,"d3",d3, "t6",t6, "v6",v6, "d6",d6)

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
    local result
    if not self.flyoutId then
        result = self.isUserFacing and "<UFO: EMPTY>" or "<Germ: EMPTY>"
    else
        local icon = self:getIcon()
        local label = self.isUserFacing and self.label or self:getLabel() or shortName(self.label or self:getLabel() )
        result = self.isUserFacing
                and string.format("<UFO: |T%d:0|t %s>", icon, label or "UnKnOwN")
                or string.format("<Germ: |T%d:0|t %s>", icon, label or "UnKnOwN")
    end

    self.isUserFacing = false
    return result
end

function Germ:forUser()
    -- set Flag For User Facing Messaging
    self.isUserFacing = true
    return self
end
