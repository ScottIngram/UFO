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
local zebug = Zebug:new()

---@class Germ -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field flyoutId number Identifies which flyout is currently copied into this germ
---@field flyoutMenu FlyoutMenu The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
---@field clickScriptUpdaters table secure scriptlets that must be run during any update()
---@field bbInfo table definition of the actionbar/button where the Germ lives

---@type Germ|ButtonMixin
Germ = {
    ufoType = "Germ",
    clickScriptUpdaters = {},
    clickers = {},
}
ButtonMixin:inject(Germ)
ActionBarButtonMixin:inject(Germ)

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

local handlers = {}
local HANDLER_MAKERS_MAP

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
local CLICK_ID_MARKER = "-- CLICK_ID_MARKER:"
local LEN_CLICK_ID_MARKER = string.len(CLICK_ID_MARKER)

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
	local germ = self
	local mouseClick = button
	local isClicked = down
	local direction = germ:GetAttribute("flyoutDirection")
    local doCloseFlyout = flyoutMenu:GetAttribute("doCloseFlyout")
    local isOpen = flyoutMenu:IsShown()

	if doCloseFlyout and isOpen then
		flyoutMenu:Hide()
		flyoutMenu:SetAttribute("doCloseFlyout", false)
		keybindKeeper:ClearBindings()
		return
    end

    keybindKeeper:SetBindingClick(true, "Escape", germ, mouseClick)

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
    if uiButtons[1]:GetObjectType() ~= "CheckButton" then
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
            local flyoutButtonsWillBind = germ:GetAttribute("flyoutButtonsWillBind")
            if flyoutButtonsWillBind then
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

    flyoutMenu:Show()
    flyoutMenu:SetAttribute("doCloseFlyout", true)

    --flyoutMenu:RegisterAutoHide(1) -- nah.  Let's match the behavior of the mage teleports. They don't auto hide.
    --flyoutMenu:AddToAutoHide(germ)
]=]

    return OPENER_CLICKER_SCRIPTLET
end

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ:new(flyoutId, btnSlotIndex)
    local bbInfo = self:extractBarBtnInfo(btnSlotIndex)
    local parentActionBarBtn = self:getActionBarBtn(bbInfo)

    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentActionBarBtn:GetName()
    self.myName = myName -- TODO: figure out why leaving this line out breaks self:GetName() in FlyoutMenu.new even though self == Germ

    local protoGerm = CreateFrame(FrameType.CHECK_BUTTON, self.myName, parentActionBarBtn, "SecureActionButtonTemplate, ActionButtonTemplate")

    -- copy Germ's methods, functions, etc to the UI btn
    -- I can't use the setmetatable() trick here because the Bliz frame already has a metatable... TODO: can I metatable a metatable?
    ---@type Germ
    local self = deepcopy(Germ, protoGerm)

    self.myName = myName
    _G[myName] = self -- so that keybindings can reference it

    -- initialize my fields
    self.btnSlotIndex = btnSlotIndex
    self.action       = btnSlotIndex -- used deep inside the Bliz APIs
    self.flyoutId     = flyoutId
    self.visibleIf    = parentActionBarBtn.visibleIf
    self.myLabel      = self:getFlyoutDef().name
    self.bbInfo       = bbInfo

    -- UI positioning
    self:ClearAllPoints()
    self:SetAllPoints(parentActionBarBtn)
    self:SetFrameStrata(STRATA_DEFAULT)
    self:SetFrameLevel(STRATA_LEVEL_DEFAULT)
    self:SetToplevel(true)
    self:setVisibilityDriver()

    -- UI reactions
    self:SetScript(Script.ON_UPDATE,       handlers.OnUpdate)
    self:SetScript(Script.ON_ENTER,        handlers.OnEnter)
    self:SetScript(Script.ON_LEAVE,        handlers.OnLeave)
    self:SetScript(Script.ON_RECEIVE_DRAG, handlers.OnReceiveDrag)
    self:SetScript(Script.ON_MOUSE_UP,     handlers.OnMouseUp) -- is this short-circuiting my attempts to get the buttons to work on mouse up?
    self:SetScript(Script.ON_DRAG_START,   handlers.OnPickupAndDrag) -- this is required to get OnDrag to work
    --self:SetScript(Script.ON_HIDE, function(self) print('***GERM*** Script.ON_HIDE for',self:GetName()); end) -- This is NEVER invoked.  Thanks for silent fail, Bliz.

    -- FlyoutMenu
    self:initFlyoutMenu()
    self.flyoutMenu:installHandlerForCloseOnClick()
    self:SetAttribute("flyoutDirection", self:getDirection())
    self:SetAttribute("FLYOUT_MENU_NAME", self.flyoutMenu:GetName())

    -- Click behavior
    --self:RegisterForClicks("AnyUp") -- this does nothing
    --self:RegisterForClicks("AnyDown") -- this works but clobbers OnDragStart
    self:RegisterForClicks("AnyDown", "AnyUp") -- this also works and also clobbers OnDragStart
    self:setAllClickHandlers()
    self:SetAttribute("flyoutButtonsWillBind", Config:get("flyoutButtonsWillBind"))

    -- Drag and Drop behavior
    self:RegisterForDrag("LeftButton")
    --SecureHandlerWrapScript(self, "OnDragStart", self, "return "..QUOTE.."message"..QUOTE , "print(123456789)") -- this does nothing.  TODO: understand why

    return self
end

function Germ:setAllClickHandlers()
    -- I could have done this in a loop, but, this is FAR clearer and easier to understand
    local flyoutId = self.flyoutId
    self:setMouseClickHandler(MouseClick.LEFT,   Config:getClickBehavior(flyoutId, MouseClick.LEFT))
    self:setMouseClickHandler(MouseClick.MIDDLE, Config:getClickBehavior(flyoutId, MouseClick.MIDDLE))
    self:setMouseClickHandler(MouseClick.RIGHT,  Config:getClickBehavior(flyoutId, MouseClick.RIGHT))
    self:setMouseClickHandler(MouseClick.FOUR,   Config:getClickBehavior(flyoutId, MouseClick.FOUR))
    self:setMouseClickHandler(MouseClick.FIVE,   Config:getClickBehavior(flyoutId, MouseClick.FIVE))
    self:setMouseClickHandler(MouseClick.SIX,    Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior)
end

function Germ:initFlyoutMenu()
    if Config.opts.supportCombat then
        self.flyoutMenu = FlyoutMenu.new(self)
        self.flyoutMenu:updateForGerm(self)
    else
        self.flyoutMenu = UIUFO_FlyoutMenuForGerm
    end
    self.flyoutMenu.isForGerm = true
end

function Germ:setVisibilityDriver()
    if self.visibleIf then
        -- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. self.visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")
    else
        self:Show()
    end
end

function Germ:myHide()
    self:Hide()
    UnregisterStateDriver(self, "visibility")
end

function Germ:getDirection()
    -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs
    -- ask the bar instance what direction to fly
    local parent = self:GetParent()
    return parent.bar:GetSpellFlyoutDirection()
end

function Germ:updateAllBtnCooldownsEtc()
    --zebug.trace:print(self:getFlyoutId())
    self.flyoutMenu:updateAllBtnCooldownsEtc()
end

function Germ:updateAllBtnHotKeyLabels()
    self.flyoutMenu:updateForGerm(self)
end

function Germ:getBtnSlotIndex()
    return self.btnSlotIndex
end

---@return string
function Germ:getFlyoutId()
    return self.flyoutId
end

function Germ:update(flyoutId)
    self.flyoutId = flyoutId
    self.myLabel = self:getFlyoutDef().name

    local btnSlotIndex = self.btnSlotIndex
    zebug.trace:line(30, "germ",self.myLabel, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex, "self.name", self:GetName(), "parent", self:GetParent():GetName())

    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    if not flyoutDef then
        -- because one toon can delete a flyout while other toons still have it on their bars
        local msg = "Flyout".. flyoutId .."no longer exists.  Removing it from your action bars."
        msgUser(msg)
        GermCommander:deletePlacement(btnSlotIndex)
        return
    end

    -- discard any buttons that the toon can't ever use
    local usableFlyout = flyoutDef:filterOutUnusable()

    -- set the Germ's icon so that it reflects only USABLE buttons
    local icon = usableFlyout:getIcon() or flyoutDef.fallbackIcon or DEFAULT_ICON
    self:setIcon(icon)

    self.flyoutMenu:updateForGerm(self)

    self:setVisibilityDriver() -- TODO: remove after we stop sledge hammering all the germs every time

    ---------------------
    -- SECURE TEMPLATE --
    ---------------------

    self:SetAttribute("UFO_NAME",  self.myLabel)

    -- some clickers need to be re-initialized whenever the flyout's buttons change
    self:reInitializeMySecureClickers()

    -- all FIRST_BTN handlers must be re-initialized after flyoutDef changes
    ---@param mouseClick MouseClick
    ---@param behavior GermClickBehavior
    for mouseClick, behavior in pairs(self.clickers) do
        if behavior == GermClickBehavior.FIRST_BTN then
            local installTheBehavior = getHandlerMaker(behavior)
            installTheBehavior(self, mouseClick)
        end
    end

    self:SetAttribute("doCloseOnClick", Config.opts.doCloseOnClick)
end

function Germ:reInitializeMySecureClickers()
    for secureMouseClickId, updaterScriptlet in pairs(self.clickScriptUpdaters) do
        zebug.trace:print("germ",self.myLabel, "i",secureMouseClickId, "updaterScriptlet",updaterScriptlet)
        SecureHandlerExecute(self, updaterScriptlet)
    end
end

function Germ:handleGermUpdateEvent()
    self:updateCooldownsAndCountsAndStatesEtc()

    -- Update border and determine arrow position
    local arrowDistance;

    -- support v10 and v11 until launch
    local isMouseOverButton
    if self.IsMouseMotionFocus then -- v11
        isMouseOverButton = self:IsMouseMotionFocus()
    elseif GetMouseFocus then -- v10
        isMouseOverButton = GetMouseFocus() == self
    end

    local isFlyoutShown = self.flyoutMenu:IsShown()
    if isFlyoutShown or isMouseOverButton then
        self.FlyoutBorderShadow:Show();
        arrowDistance = 5;
    else
        self.FlyoutBorderShadow:Hide();
        arrowDistance = 2;
    end

    -- Update arrow
    local isButtonDown = self:GetButtonState() == "PUSHED"
    local flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowNormal

    if isButtonDown then
        flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowPushed;

        self.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
        self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
    elseif isMouseOverButton then
        flyoutArrowTexture = self.FlyoutArrowContainer.FlyoutArrowHighlight;

        self.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
        self.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
    else
        self.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
        self.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
    end

    self.FlyoutArrowContainer:Show();
    flyoutArrowTexture:Show();
    flyoutArrowTexture:ClearAllPoints();

    local direction = self:GetAttribute("flyoutDirection");
    if (direction == "LEFT") then
        flyoutArrowTexture:SetPoint(Anchor.LEFT, self, Anchor.LEFT, -arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 270);
    elseif (direction == "RIGHT") then
        flyoutArrowTexture:SetPoint(Anchor.RIGHT, self, Anchor.RIGHT, arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 90);
    elseif (direction == "DOWN") then
        flyoutArrowTexture:SetPoint(Anchor.BOTTOM, self, Anchor.BOTTOM, 0, -arrowDistance);
        SetClampedTextureRotation(flyoutArrowTexture, 180);
    else
        flyoutArrowTexture:SetPoint(Anchor.TOP, self, Anchor.TOP, 0, arrowDistance);
        SetClampedTextureRotation(flyoutArrowTexture, 0);
    end
end

function Germ:setToolTip()
    local btn1 = self.flyoutMenu:getBtn1()
    if btn1 and btn1:hasDef() then
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

-- required by ButtonMixin
function Germ:getDef()
    -- treat the first button in the flyout as the "definition" for the Germ
    return self:getBtnDef(1)
end

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
                zebug.trace:print("germ",germName, "binding keyName",keyName)
                SetOverrideBindingClick(self, true, keyName, germName, MouseClick.SIX)
            else
                zebug.trace:print("germ",germName, "NOT binding keyName",keyName, "because it's already bound.")
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
                zebug.trace:print("germ",germName, "UN-binding keyName",keyName)
                SetOverrideBinding(self, true, keyName, nil)
            else
                zebug.trace:print("germ",germName, "NOT UN-binding keyName",keyName, "because it's still bound.")
            end
        end
    end

    self.keybinds = keybinds
end

function Germ:clearKeybinding()
    if isInCombatLockdown("Keybind removal") then return end
    if not (self.keybinds) then return end

    ClearOverrideBindings(self)
    self:setHotKeyOverlay(nil)
    self.keybinds = nil
end

-------------------------------------------------------------------------------
-- Handlers
--
-- Note: ACTIONBAR_SLOT_CHANGED will happen as a result of
-- some of the actions below which will in turn trigger other handlers elsewhere
-------------------------------------------------------------------------------

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnMouseUp(germ)
    zebug.trace:name("OnMouseUp"):print("name",germ:GetName())
    local isDragging = GetCursorInfo()
    if isDragging then
        handlers.OnReceiveDrag(germ)
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnReceiveDrag(germ)
    zebug.trace:name("OnReceiveDrag"):print("name",germ:GetName())
    if isInCombatLockdown("Drag and drop") then return end

    local cursor = GetCursorInfo()
    if cursor then
        PlaceAction(germ:getBtnSlotIndex())
        GermCommander:updateAll() -- draw the dropped UFO -- TODO: update ONLY the one specific germ
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnPickupAndDrag(germ)
    if (LOCK_ACTIONBAR ~= "1" or IsShiftKeyDown()) then
        if isInCombatLockdown("Drag and drop") then return end
        zebug.info:name("OnPickupAndDrag"):print("name",germ:GetName())

        local btnSlotIndex = germ:getBtnSlotIndex()
        GermCommander:deletePlacement(btnSlotIndex)

        local type, macroId = GetCursorInfo()
        if type then
            local btnSlotIndex = germ:getBtnSlotIndex()
            local droppedFlyoutId = GermCommander:getFlyoutIdFromGermProxy(type, macroId)
            zebug.info:print("droppedFlyoutId",droppedFlyoutId, "btnSlotIndex",btnSlotIndex)
            if droppedFlyoutId then
                -- the user is dragging a UFO
                GermCommander:dropUfoOntoActionBar(btnSlotIndex, droppedFlyoutId)
            else
                -- the user is just dragging a normal Bliz spell/item/etc.
                PlaceAction(btnSlotIndex)
            end
        else
            GermCommander:clearUfoPlaceholderFromActionBar(btnSlotIndex)
        end

        FlyoutMenu:pickup(germ.flyoutId)
        GermCommander:updateAll()
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnEnter(germ)
    germ:setToolTip()
    germ:handleGermUpdateEvent()
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnLeave(germ)
    GameTooltip:Hide()
    germ:handleGermUpdateEvent()
end

-- throttle OnUpdate because it fires as often as FPS and is very resource intensive
-- TODO: abstract this into its own class/function
local ON_UPDATE_TIMER_FREQUENCY = 1.5
local onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY

---@param germ Germ
function handlers.OnUpdate(germ, elapsed)
    onUpdateTimer = onUpdateTimer + elapsed
    if onUpdateTimer < ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    onUpdateTimer = 0
    germ:handleGermUpdateEvent()
    germ:updateAllBtnCooldownsEtc() -- nah, let the flyout do this.
end

---@param germ Germ
function handlers.OnPreClick(germ, mouseClick, down)
    germ:SetChecked(germ:GetChecked())
    onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY

    local flyoutMenu = germ.flyoutMenu
    if not flyoutMenu.isSharedByAllGerms then return end

    --if isInCombatLockdown("Open/Close") then return end

    local isShown = flyoutMenu:IsShown()
    local doCloseFlyout

    local otherGerm = flyoutMenu:GetParent()
    local isFromSameGerm = otherGerm == germ
    zebug.trace:print("germ",germ:GetName(), "otherGerm", otherGerm:GetName(), "isFromSameGerm", isFromSameGerm, "isShown",isShown)

    if isFromSameGerm then
        doCloseFlyout = isShown
    else
        doCloseFlyout = false
    end

    germ.flyoutMenu:updateForGerm(germ)
    flyoutMenu:SetAttribute("doCloseFlyout", doCloseFlyout)
    zebug.trace:print("doCloseFlyout",doCloseFlyout)
end

local oldGerm

-- this is needed for the edge case of clicking on a different germ while the current one is still open
-- in which case there is no OnShow event which is where the below usually happens
---@param self Germ
---@param mouseClick MouseClick
function handlers.OnPostClick(self, mouseClick, down)
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

---@type Germ|ButtonMixin
local HandlerMaker = { }

---@param mouseClick MouseClick
function Germ:setMouseClickHandler(mouseClick, behavior)
    self:removeOldHandler(mouseClick)
    local installTheBehavior = getHandlerMaker(behavior)
    zebug.info:print("mouseClick",mouseClick, "opt", behavior, "handler", installTheBehavior)
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

---@param mouseClick MouseClick
function HandlerMaker:OpenFlyout(mouseClick)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:name("HandlerMakers:OpenFlyout"):print("self",self, "mouseClick",mouseClick, "secureMouseClickId", secureMouseClickId)
    local scriptName = "OPENER_SCRIPT_FOR_" .. secureMouseClickId
    zebug.info:name("HandlerMakers:OpenFlyout"):print("germ",self.myLabel, "secureMouseClickId",secureMouseClickId, "scriptName",scriptName)
    self:SetAttribute(secureMouseClickId,scriptName)
    self:SetAttribute("_"..scriptName, getOpenerClickerScriptlet())
end

---@param mouseClick MouseClick
function HandlerMaker:ActivateBtn1(mouseClick)
    local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
    zebug.info:print("secureMouseClickId",secureMouseClickId)
    self:updateSecureClicker(mouseClick)
    local btn1 = self:getBtnDef(1)
    if not btn1 then return end
    local btn1Type = btn1:getTypeForBlizApi()
    local btn1Name = btn1.name
    local type, key, val = btn1:asSecureClickHandlerAttributes()
    local keyAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
    zebug.info:name("HandlerMakers:ActivateBtn1"):print("germ",self.myLabel, "btn1Name",btn1Name, "btn1Type",btn1Type, "secureMouseClickId", secureMouseClickId, "type", type, "key",key, "ADJ key", keyAdjustedToMatchMouseClick, "val", val)
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

    zebug.info:print("germ",self.myLabel, "secureMouseClickId",secureMouseClickId, "mouseBtnNumber",mouseBtnNumber)
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
    zebug.trace:print("old",old)
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
        zebug.info:print("germ", self.myLabel, "click",mouseClick, "old",old, "script owner", scriptsClick, "iAmOwner", isForThisClick)
        if not isForThisClick then
            rescue( header, preBody, postBody, scriptsClick )
        end
    end

    -- try to put that shit back
    for i, params in ipairs(lostBoys) do
        local success = pcall(function()
            SecureHandlerWrapScript(params[1], "OnClick", params[1], params[2], params[3])
        end )
        zebug.info:print("germ", self.myLabel, "click",mouseClick, "RESTORING handler for", params[4], "success?", success)
    end
end

