-- Germ
-- is a button on the actionbars that opens & closes a copy of a flyout menu from the catalog.
-- One flyout menu can be duplicated across numerous actionbar buttons, each being a seperate germ.

-- is a standard bliz CheckButton frame but with extra attributes attached.
-- Once created it always exists at its original actionbar slot, but, may be assigned a different flyout menu or none at all.
-- a.k.a launchpad, egg, exploder, torpedo, detonator, originator, impetus, genesis, bigBang, singularity...

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@class Germ -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field flyoutId number Identifies which flyout is currently copied into this germ
---@field flyoutMenu FlyoutMenu The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
local Germ = {
    ufoType = "Germ",
}
Ufo.Germ = Germ

-------------------------------------------------------------------------------
-- Mixing the Mixins
-------------------------------------------------------------------------------

-- this syntax is clunky but my IDE understands this better than ButttonMixin:inject()
Germ.updateCooldownsAndCountsAndStatesEtc = ButttonMixin.updateCooldownsAndCountsAndStatesEtc
Germ.updateUsable   = ButttonMixin.updateUsable
Germ.updateCooldown = ButttonMixin.updateCooldown
Germ.updateCount    = ButttonMixin.updateCount
Germ.getIconFrame   = ButttonMixin.getIconFrame
Germ.setIcon        = ButttonMixin.setIcon
Germ.maxVisibleCooldownDuration = 60

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local handlers = {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"

function getClickerCode()
    return [=[
	local germ = self
	local whichMouseButton = button

	local DELIMITER = "]=]..DELIMITER..[=["
	local EMPTY_ELEMENT = "]=]..EMPTY_ELEMENT..[=["
	local flyoutMenu = germ:GetFrameRef("flyoutMenu")
	local direction = germ:GetAttribute("flyoutDirection")
	local prevBtn = nil;

    -- search the kids for the flyout menu
    local flyoutMenu
    local kids = table.new(germ:GetChildren())
    for i, kid in ipairs(kids) do
        local kidName = kid:GetName()
        print(i,kidName)
        if kidName then
            local wantedSuffix = "]=].. FlyoutMenu.nameSuffix ..[=["
            local n = string.len(wantedSuffix)
            local kidSuffix = string.sub(kidName, 0-n) -- last n letters

            if kidSuffix == wantedSuffix then
                flyoutMenu = kid
                break
            end
        end
    end
    print(flyoutMenu)

    local doCloseFlyout = flyoutMenu:GetAttribute("doCloseFlyout")
	if doCloseFlyout then
		flyoutMenu:Hide()
		flyoutMenu:SetAttribute("doCloseFlyout", false)
		return
    end

    flyoutMenu:SetParent(germ)
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

    local nameList  = table.new(strsplit(DELIMITER, germ:GetAttribute("UFO_NAMES") or ""))
    local typeList  = table.new(strsplit(DELIMITER, germ:GetAttribute("UFO_BLIZ_TYPES") or ""))
    local pets      = table.new(strsplit(DELIMITER, germ:GetAttribute("UFO_PETS")  or ""))

    local uiButtons = table.new(flyoutMenu:GetChildren())
    if uiButtons[1]:GetObjectType() ~= "CheckButton" then
        table.remove(uiButtons, 1) -- this is the non-button UI element "Background" from ui.xml
    end

    for i, btn in ipairs(uiButtons) do
        if typeList[i] then
            --print("SNIPPET... i:",i, "btn:",btn:GetName())
            btn:ClearAllPoints()

            local parent = prevBtn or "$parent"
            if prevBtn then
                if direction == "UP" then
                    btn:SetPoint("BOTTOM", parent, "TOP", 0, ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
                elseif direction == "DOWN" then
                    btn:SetPoint("TOP", parent, "BOTTOM", 0, -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
                elseif direction == "LEFT" then
                    btn:SetPoint("RIGHT", parent, "LEFT", -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
                elseif direction == "RIGHT" then
                    btn:SetPoint("LEFT", parent, "RIGHT", ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
                end
            else
                if direction == "UP" then
                    btn:SetPoint("BOTTOM", parent, 0, ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
                elseif direction == "DOWN" then
                    btn:SetPoint("TOP", parent, 0, -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
                elseif direction == "LEFT" then
                    btn:SetPoint("RIGHT", parent, -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
                elseif direction == "RIGHT" then
                    btn:SetPoint("LEFT", parent, ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
                end
            end

            local type = typeList[i]

            -- It appears that SecureActionButtonTemplate
            -- provides no support for summoning battlepets
            -- because summoning a battlepet is not a protected action.
            -- So, fake it with an adhoc macro!
            if (type == "battlepet") then
                -- summon the pet via a macro
                local petMacro = "/run C_PetJournal.SummonPetByGUID(\"" .. pets[i] .. "\")"
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", petMacro)
            else
                --btn:SetAttribute("downbutton", "MiddleButton")
                btn:SetAttribute("type", type)
                btn:SetAttribute(type, nameList[i]) -- huh, I woulda thought spellId or itemId etc
            end

            prevBtn = btn
            btn:Show()
        else
            btn:Hide()
        end
    end

    local numButtons = table.maxn(typeList)
    if direction == "UP" or direction == "DOWN" then
        flyoutMenu:SetWidth(prevBtn:GetWidth())
        flyoutMenu:SetHeight((prevBtn:GetHeight()+]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[) * numButtons - ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[ + ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[ + ]=]..SPELLFLYOUT_FINAL_SPACING..[=[)
    else
        flyoutMenu:SetHeight(prevBtn:GetHeight())
        flyoutMenu:SetWidth((prevBtn:GetWidth()+]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[) * numButtons - ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[ + ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[ + ]=]..SPELLFLYOUT_FINAL_SPACING..[=[)
    end
        flyoutMenu:Show()
        flyoutMenu:SetAttribute("doCloseFlyout", true)

    --flyoutMenu:RegisterAutoHide(1) -- nah.  Let's match the behavior of the mage teleports. They don't auto hide.
    --flyoutMenu:AddToAutoHide(germ)
]=]
end

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ.new(flyoutId, btnSlotIndex, parentActionBarBtn)
    assertIsFunctionOf(flyoutId,Germ)
    local myName = GERM_UI_NAME_PREFIX .. "On_" .. parentActionBarBtn:GetName()

    local protoGerm = CreateFrame("CheckButton", myName, parentActionBarBtn, "SecureHandlerClickTemplate, ActionButtonTemplate") -- SecureActionButtonTemplate or SecureHandlerClickTemplate
    --local protoGerm = CreateFrame("CheckButton", myName, parentActionBarBtn, "ActionButtonTemplate, SecureHandlerClickTemplate")

    -- copy Germ's methods, functions, etc to the UI btn
    -- I can't use the setmetatable() trick here because the Bliz frame already has a metatable... TODO: can I metatable a metatable?
    ---@type Germ
    local self = deepcopy(Germ, protoGerm)

    -- initialize my fields, handlers, etc.
    self.btnSlotIndex = btnSlotIndex
    self.action       = btnSlotIndex -- used deep inside the Bliz APIs
    self.flyoutId     = flyoutId
    self.visibleIf    = parentActionBarBtn.visibleIf -- I set this inside GermCommander:getActionBarBtn()

    -- FlyoutMenu
    self:initFlyoutMenu()
    self.flyoutMenu:initializeCloseOnClick()

    -- anti-taint / protected environment / secure BS
    self:SetAttribute("flyoutDirection", self:getDirection())
    --self:SetFrameRef("flyoutMenu", self.flyoutMenu)

--[[
    local btn1 = self.flyoutMenu:getButtonFrame(1)
    zebug.error:print("btn1", btn1)
    self:SetFrameRef("btn1", btn1)
    self:WrapScript(self, "OnClick", [=[

local btn1 = self
local whichMouseButton = button
local btn1b = self:GetFrameRef("btn1")
print("WrapScript OnClick whichMouseButton",whichMouseButton, "btn1",btn1, "btn1.Click", btn1 and btn1.Click, "btn1b",btn1b, "btn1b.Click",btn1b and btn1b.Click)

if whichMouseButton == "RightButton" then
    --btn1:Click()
    print("this is where I would do a Click()")
end
]=])

]]

    self:setHandlers()
    self:setVisibility()

    return self
end

function Germ:initFlyoutMenu()
    if Config.opts.supportCombat then
        self.flyoutMenu = FlyoutMenu.new(self)
    else
        self.flyoutMenu = UIUFO_FlyoutMenuForGerm
    end
    self.flyoutMenu.isForGerm = true
end

function Germ:setVisibility()
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

function Germ:setHandlers()
    local actionBarBtn = self:GetParent()
    if actionBarBtn then
        if actionBarBtn:GetSize() and actionBarBtn:IsRectValid() then
            self:SetAllPoints(actionBarBtn)
        else
            local spacerName = "UIUfo_ActionBarButtonSpacer"..tostring(actionBarBtn.index)
            local children = { actionBarBtn:GetParent():GetChildren()}
            for _, child in ipairs(children) do
                if child:GetName() == spacerName then
                    self:SetAllPoints(child)
                    break;
                end
            end
        end
    else
        zebug.trace:print("How is there no actionBarBtn?", "btnSlotIndex", self.btnSlotIndex)
    end

    self:SetFrameStrata(STRATA_DEFAULT)
    self:SetFrameLevel(100)
    self:SetToplevel(true)

    -- handlers
    self:SetScript("OnUpdate",      handlers.OnUpdate)
    self:SetScript("OnEnter",       handlers.OnEnter)
    self:SetScript("OnLeave",       handlers.OnLeave)
    self:SetScript("OnReceiveDrag", handlers.OnReceiveDrag)
    self:SetScript("OnMouseUp",     handlers.OnMouseUp)
    self:SetScript("OnDragStart",   handlers.OnPickupAndDrag)
    self:SetScript("PreClick",      handlers.OnPreClick)
    self:SetScript("PostClick",     handlers.OnPostClick)
    self:SetAttribute("_onclick",   getClickerCode())
    self:RegisterForClicks("AnyUp")
    self:RegisterForDrag("LeftButton")
end

function Germ:getBtnSlotIndex()
    return self.btnSlotIndex
end

---@return string
function Germ:getFlyoutId()
    return self.flyoutId
end

function Germ:update(flyoutId)
    assertIsMethodOf(self, Germ)
    self.flyoutId = flyoutId
    local btnSlotIndex = self.btnSlotIndex
    zebug.trace:line(30, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex, "self.name", self:GetName(), "parent", self:GetParent():GetName())

    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    if not flyoutDef then
        -- because one toon can delete a flyout while other toons still have it on their bars
        local msg = "Flyout".. flyoutId .."no longer exists.  Removing it from your action bars."
        zebug.warn:print(msg)
        GermCommander:deletePlacement(btnSlotIndex)
        return
    end

    -- discard any buttons that the toon can't ever use
    local usableFlyout = flyoutDef:filterOutUnusable()

    -- set the Germ's icon so that it reflects only USABLE buttons
    local icon = usableFlyout:getIcon() or flyoutDef.fallbackIcon or DEFAULT_ICON
    self:setIcon(icon)

    self.flyoutMenu:updateForGerm(self)

    -- attach string representations of the buttons
    -- because Blizzard "secure" templates don't let us attach the actual array
    local asStrLists = usableFlyout:asStrLists()
    self:SetAttribute("UFO_SPELL_IDS",  asStrLists.spellIds)
    self:SetAttribute("UFO_NAMES",      asStrLists.names)
    self:SetAttribute("UFO_BLIZ_TYPES", asStrLists.blizTypes)
    self:SetAttribute("UFO_PETS",       asStrLists.petGuids)
    self:SetAttribute("doCloseOnClick", Config.opts.doCloseOnClick)

    self:setVisibility() -- TODO: remove after we stop sledge hammering all the germs every time
end

function Germ:handleGermUpdateEvent()
    self:updateCooldownsAndCountsAndStatesEtc()

    -- Update border and determine arrow position
    local arrowDistance;
    local isMouseOverButton = GetMouseFocus() == self;
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
        flyoutArrowTexture:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 270);
    elseif (direction == "RIGHT") then
        flyoutArrowTexture:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 90);
    elseif (direction == "DOWN") then
        flyoutArrowTexture:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance);
        SetClampedTextureRotation(flyoutArrowTexture, 180);
    else
        flyoutArrowTexture:SetPoint("TOP", self, "TOP", 0, arrowDistance);
        SetClampedTextureRotation(flyoutArrowTexture, 0);
    end
end

function Germ:setToolTip()
    local flyoutDef = FlyoutDefsDb:get(self.flyoutId)
    local label = flyoutDef.name or flyoutDef.id

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
    else
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    end

    GameTooltip:SetText(label)
end

-- required by ButttonMixin
function Germ:getDef()
    -- treat the first button in the flyout as the "definition" for the Germ
    local flyoutDef = FlyoutDefsDb:get(self.flyoutId)
    local usableFlyout = flyoutDef:filterOutUnusable()
    return usableFlyout:getButtonDef(1)
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
function handlers.OnPreClick(germ, whichMouseButton, down)
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
function handlers.OnPostClick(self, whichMouseButton, down)
    if oldGerm and oldGerm ~= self then
        self:updateAllBtnCooldownsEtc()
    end
    oldGerm = self

    if false and whichMouseButton == MOUSE_BUTTON_RIGHT then
        local btn1 = self.flyoutMenu:getButtonFrame(1)
        local btn1 = self:getDef()
        if btn1 then
            btn1:click(self)
            --print("suck")
            --self:Execute("print( \"Fun!\"  )") -- succeeds
            --germ:Execute("C_MountJournal.SummonByID(1591)") -- fails
        end
    end
end
