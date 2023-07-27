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
-- Data
-------------------------------------------------------------------------------

local handlers = {}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local GERM_UI_NAME_PREFIX = "UfoGerm"
local snippet_Germ_Click = [=[
	local DELIMITER = "]=]..DELIMITER..[=["
	local EMPTY_ELEMENT = "]=]..EMPTY_ELEMENT..[=["
	local germ = self
	local flyoutMenu = germ:GetFrameRef("UIUFO_FlyoutMenuForGerm")
	local direction = germ:GetAttribute("flyoutDirection")
	local prevBtn = nil;

	if flyoutMenu:IsShown() and flyoutMenu:GetParent() == germ then
		flyoutMenu:Hide()
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
    table.remove(uiButtons, 1) -- this is the non-button UI element "Background" from ui.xml
    for i, btn in ipairs(uiButtons) do
        if typeList[i] then
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
    --flyoutMenu:RegisterAutoHide(1) -- nah.  Let's match the behavior of the mage teleports. They don't auto hide.
    --flyoutMenu:AddToAutoHide(germ)
]=]

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ.new(flyoutId, btnSlotIndex)
    assertIsFunctionOf(flyoutId,Germ)

    -- which action/bonus/multi bar are we on?
    local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
    local actionBarDef = BLIZ_BAR_METADATA[barNum]
    assert(actionBarDef, "No ".. ADDON_NAME ..": config defined for button bar #"..barNum) -- in case Blizzard adds more bars, complain here clearly.

    -- which of the bar's many buttons are we tied to?
    local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
    if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
    local actionBarName    = actionBarDef.name
    local actionBarBtnName = actionBarName .. "Button" .. btnNum
    local actionBarBtn     = _G[actionBarBtnName] -- grab the button object from Blizzard's GLOBAL dumping ground
    local myName           = GERM_UI_NAME_PREFIX .. actionBarBtn:GetName()

    ---@type Germ
    local protoGerm = CreateFrame("CheckButton", myName, actionBarBtn, "ActionButtonTemplate, SecureHandlerClickTemplate")

    -- copy Germ's methods, functions, etc to the UI btn
    -- I can't use the setmetatable() trick here because the Bliz frame already has a metatable... TODO: can I metatable a metatable?
    local self = deepcopy(Germ, protoGerm)

    -- initialize my fields, handlers, etc.
    self.btnSlotIndex = btnSlotIndex
    self.action       = btnSlotIndex -- used deep inside the Bliz APIs
    self.flyoutId     = flyoutId
    self.flyoutMenu   = UIUFO_FlyoutMenuForGerm -- the one UI object is reused by every germ
    self:setHandlers()

    if actionBarDef.visibleIf then
        -- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
        self.visibleIf = actionBarDef.visibleIf
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. self.visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")
    end

    return self
end

function Germ:getDirection()
    -- TODO: fix bug where edit-mode -> change direction doesn't automatically update existing germs
    -- ask the bar instance what direction to fly
    local myActionBarBtnParent = self:GetParent()
    local barObj = myActionBarBtnParent.bar
    local direction = barObj:GetSpellFlyoutDirection()
    return direction or "UP"
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

    self:SetAttribute("flyoutDirection", self:getDirection())
    self:SetFrameRef("UIUFO_FlyoutMenuForGerm", UIUFO_FlyoutMenuForGerm)

    self:SetScript("OnUpdate",      handlers.OnUpdate)
    self:SetScript("OnEnter",       handlers.OnEnter)
    self:SetScript("OnLeave",       handlers.OnLeave)
    self:SetScript("OnReceiveDrag", handlers.OnReceiveDrag)
    self:SetScript("OnMouseUp",     handlers.OnMouseUp)
    self:SetScript("OnDragStart",   handlers.OnPickupAndDrag)
    self:SetScript("PreClick",      handlers.OnPreClick)
    self:SetScript("PostClick",     handlers.OnPostClick)
    self:SetAttribute("_onclick",   snippet_Germ_Click)
    self:RegisterForClicks("AnyUp")
    self:RegisterForDrag("LeftButton")
end

function Germ:setIcon(icon)
    if icon and type(icon) ~= "number" then
        icon = ("INTERFACE\\ICONS\\".. icon)
    end

    _G[ self:GetName().."Icon" ]:SetTexture(icon)
end

function Germ:getBtnSlotIndex()
    local myActionBarBtnParent = self:GetParent()
    assert(myActionBarBtnParent, ADDON_NAME..": Um, this germ has no parent?!")
    return myActionBarBtnParent.action
end

---@return string
function Germ:getFlyoutId()
    return self.flyoutId
end

---@param flyoutId string
function Germ:setFlyoutId(flyoutId)
    self.flyoutId = flyoutId
end

function Germ:update()
    assertIsMethodOf(self, Germ)
    local flyoutId = self.flyoutId
    local btnSlotIndex = self.btnSlotIndex
    zebug.trace:line(30, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex)

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
    local icon = usableFlyout:getIcon()
    self:setIcon(icon)

    -- attach string representations of the buttons
    -- because Blizzard "secure" templates don't let us attach the actual array
    local asStrLists = usableFlyout:asStrLists()

    self:SetAttribute("UFO_SPELL_IDS",  asStrLists.spellIds)
    self:SetAttribute("UFO_NAMES",      asStrLists.names)
    self:SetAttribute("UFO_BLIZ_TYPES", asStrLists.blizTypes)
    self:SetAttribute("UFO_PETS",       asStrLists.petGuids)

    if not self.visibleIf then
        self:Show()
    end
end

function Germ:handleGermUpdateEvent()
    -- Update border and determine arrow position
    local arrowDistance;
    -- Update border
    local isMouseOverButton = GetMouseFocus() == self;
    local isFlyoutShown = UIUFO_FlyoutMenuForGerm and UIUFO_FlyoutMenuForGerm:IsShown() and UIUFO_FlyoutMenuForGerm:GetParent() == self;
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

-------------------------------------------------------------------------------
-- Handlers
--
-- Note: ACTIONBAR_SLOT_CHANGED will happen as a result of
-- some of the actions below which will in turn trigger other handlers elsewhere
-------------------------------------------------------------------------------

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnMouseUp(germ)
    zebug.trace:name("OnMouseUp"):print("name",germ:GetName())
    handlers.OnReceiveDrag(germ)
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
        zebug.trace:name("OnPickupAndDrag"):print("name",germ:GetName())

        GermCommander:deletePlacement(germ:getBtnSlotIndex())

        local type, macroId = GetCursorInfo()
        if type then
            local btnSlotIndex = germ:getBtnSlotIndex()
            local droppedFlyoutId = GermCommander:getFlyoutIdFromGermProxy(type, macroId)
            zebug.trace:print("droppedFlyoutId",droppedFlyoutId, "btnSlotIndex",btnSlotIndex)
            if droppedFlyoutId then
                -- the user is dragging a UFO
                GermCommander:savePlacement(btnSlotIndex, droppedFlyoutId)
                GermCommander:deleteProxy()
            else
                -- the user is just dragging a normal Bliz spell/item/etc.
                PlaceAction(btnSlotIndex)
            end
        end

        FlyoutMenu:pickup(germ.flyoutId)
        GermCommander:updateAll()
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnEnter(germ)
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
    germ.flyoutMenu:updateForGerm(germ, whichMouseButton, down)
    local UFO_NAMES = germ:GetAttribute("UFO_NAMES")
    local UFO_BLIZ_TYPES = germ:GetAttribute("UFO_BLIZ_TYPES")
    local UFO_PETS  = germ:GetAttribute("UFO_PETS")
    zebug.trace:name("OnPickupAndDrag"):line(30,"flyoutId",germ:getFlyoutId())
    zebug.trace:name("OnPickupAndDrag"):print("flyoutId",germ:getFlyoutId(), "UFO_NAMES",UFO_NAMES)
    zebug.trace:name("OnPickupAndDrag"):print("flyoutId",germ:getFlyoutId(), "UFO_BLIZ_TYPES",UFO_BLIZ_TYPES)
    zebug.trace:name("OnPickupAndDrag"):print("flyoutId",germ:getFlyoutId(), "UFO_PETS",UFO_PETS)
    onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY
end

local oldGerm

-- this is needed for the edge case of clicking on a different germ while the current one is still open
-- in which case there is no OnShow event which is where the below usually happens
---@param germ Germ
function handlers.OnPostClick(germ, whichMouseButton, down)
    zebug.trace:name("OnPostClick"):print("flyoutId",germ:getFlyoutId())
    if oldGerm and oldGerm ~= germ then
        germ:updateAllBtnCooldownsEtc()
    end
    oldGerm = germ
end
