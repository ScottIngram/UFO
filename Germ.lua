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

local debug = Debug:new()

---@class Germ -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field flyoutId number Identifies which flyout is currently copied into this germ
---@field flyoutMenu table The UI object serving as the onscreen flyoutMenu (there's only one and it's reused by all germs)
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
    --flyoutMenu:RegisterAutoHide(1) -- TODO: add this back in?
    --flyoutMenu:AddToAutoHide(germ) -- ditto?
]=]

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ.new(flyoutId, actionBarBtn)
    assertIsFunctionOf(flyoutId,Germ)
    local flyoutConf = FlyoutMenusDb:get(flyoutId)
    if not flyoutConf then return end -- because one toon can delete a flyout while other toons still have it on their bars
    local name = GERM_UI_NAME_PREFIX .. actionBarBtn:GetName()
    ---@type Germ
    local protoGerm = CreateFrame("CheckButton", name, actionBarBtn, "ActionButtonTemplate, SecureHandlerClickTemplate")
    -- copy Germ's methods, functions, etc to the UI btn
    -- I can't use the setmetatable() trick here because the Bliz frame already has a metatable... TODO: can I metatable a metatable?
    local self = deepcopy(Germ, protoGerm)
    self.flyoutId = flyoutId
    self.flyoutMenu = UIUFO_FlyoutMenuForGerm -- the one UI object is reused by every germ
    --self:setHandlers()
    return self
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
        debug.trace:out("-",3,"Germ:setHandlers()... How is there no actionBarBtn?", "btnSlotIndex", self.btnSlotIndex)
    end

    self:SetFrameStrata(STRATA_DEFAULT)
    self:SetFrameLevel(100)
    self:SetToplevel(true)

    self:SetAttribute("flyoutDirection", self.direction)
    self:SetFrameRef("UIUFO_FlyoutMenuForGerm", UIUFO_FlyoutMenuForGerm)

    -- TODO: these only need to be set when the germ is first created.
    -- TODO: find a way to eliminate the need for OnUpdate
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

function Germ:getFlyoutId()
    return self.flyoutId
end

function Germ:setFlyoutId(flyoutId)
    self.flyoutId = tonumber(flyoutId)
end

function Germ:redefine(flyoutId, btnSlotIndex, direction, visibleIf)
    assertIsMethodOf(self, Germ)
    local debug = debug.trace:setHeader("%","Germ:redefine()")
    debug:line(3, "flyoutId",flyoutId, "btnSlotIndex",btnSlotIndex, "direction",direction)

    local flyoutDef = FlyoutMenusDb:get(flyoutId)
    if not flyoutDef then
        -- because one toon can delete a flyout while other toons still have it on their bars
        local msg = "Flyout".. flyoutId .."no longer exists.  Removing it from your action bars."
        debug.warn:print(msg)
        debug.warn:alert(msg)
        GermCommander:deletePlacement(btnSlotIndex)
        return
    end

    self.direction    = direction
    self.btnSlotIndex = btnSlotIndex
    self.action       = btnSlotIndex -- used deep inside the Bliz APIs
    self:setFlyoutId(flyoutId)

    local icon = flyoutDef:getIcon()
    self:setIcon(icon)

    -- discard any buttons that the toon can't ever use
    local usableFlyout = flyoutDef:filterOutUnusable()

    -- attach string representations of the buttons
    -- because Blizzard "secure" templates don't let us attach the actual array
    local asLists = usableFlyout:asLists()
    self:SetAttribute("UFO_SPELL_IDS", fknJoin(asLists.spellIds))
    self:SetAttribute("UFO_NAMES", fknJoin(asLists.names))
    self:SetAttribute("UFO_BLIZ_TYPES", fknJoin(asLists.blizTypes))
    self:SetAttribute("UFO_PETS", fknJoin(asLists.petGuids))

    local UFO_NAMES = self:GetAttribute("UFO_NAMES")
    local UFO_BLIZ_TYPES = self:GetAttribute("UFO_BLIZ_TYPES")
    local UFO_PETS  = self:GetAttribute("UFO_PETS")
    debug:line(3, "UFO_NAMES",UFO_NAMES)
    debug:line(3, "UFO_BLIZ_TYPES",UFO_BLIZ_TYPES)
    debug:line(3, "UFO_PETS",UFO_PETS)

    self:setHandlers() -- TODO: move this into self:new() and rework bindFlyoutToActionBarSlot() so it give more info to :new()

    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")
    else
        self:Show()
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
local function handleGermUpdateEvent(germ)
    -- TODO: throttle this?
    -- print("========== Germ_UpdateFlyout()") this is being called continuously while a flyout exists on any bar
    -- Update border and determine arrow position
    local arrowDistance;
    -- Update border
    local isMouseOverButton =  GetMouseFocus() == germ;
    local isFlyoutShown = UIUFO_FlyoutMenuForGerm and UIUFO_FlyoutMenuForGerm:IsShown() and UIUFO_FlyoutMenuForGerm:GetParent() == germ;
    if isFlyoutShown or isMouseOverButton then
        germ.FlyoutBorderShadow:Show();
        arrowDistance = 5;
    else
        germ.FlyoutBorderShadow:Hide();
        arrowDistance = 2;
    end

    -- Update arrow
    local isButtonDown = germ:GetButtonState() == "PUSHED"
    local flyoutArrowTexture = germ.FlyoutArrowContainer.FlyoutArrowNormal

    if isButtonDown then
        flyoutArrowTexture = germ.FlyoutArrowContainer.FlyoutArrowPushed;

        germ.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
        germ.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
    elseif isMouseOverButton then
        flyoutArrowTexture = germ.FlyoutArrowContainer.FlyoutArrowHighlight;

        germ.FlyoutArrowContainer.FlyoutArrowNormal:Hide();
        germ.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
    else
        germ.FlyoutArrowContainer.FlyoutArrowHighlight:Hide();
        germ.FlyoutArrowContainer.FlyoutArrowPushed:Hide();
    end

    germ.FlyoutArrowContainer:Show();
    flyoutArrowTexture:Show();
    flyoutArrowTexture:ClearAllPoints();

    local direction = germ:GetAttribute("flyoutDirection");
    if (direction == "LEFT") then
        flyoutArrowTexture:SetPoint("LEFT", germ, "LEFT", -arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 270);
    elseif (direction == "RIGHT") then
        flyoutArrowTexture:SetPoint("RIGHT", germ, "RIGHT", arrowDistance, 0);
        SetClampedTextureRotation(flyoutArrowTexture, 90);
    elseif (direction == "DOWN") then
        flyoutArrowTexture:SetPoint("BOTTOM", germ, "BOTTOM", 0, -arrowDistance);
        SetClampedTextureRotation(flyoutArrowTexture, 180);
    else
        flyoutArrowTexture:SetPoint("TOP", germ, "TOP", 0, arrowDistance);
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
    debug.trace:out("^",5,"OnMouseUp()","name",germ:GetName())
    handlers.OnReceiveDrag(germ)
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnReceiveDrag(germ)
    debug.trace:out("^",5,"OnReceiveDrag()","name",germ:GetName())
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
        debug.trace:out("^",5,"OnDragStart()","name",germ:GetName())
        FlyoutMenu:pickup(germ.flyoutId)
        GermCommander:deletePlacement(germ:getBtnSlotIndex())
        GermCommander:updateAll()
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnEnter(germ)
    handleGermUpdateEvent(germ)
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.OnLeave(germ)
    handleGermUpdateEvent(germ)
end

-- throttle OnUpdate because it fires as often as FPS and is very resource intensive
local ON_UPDATE_TIMER_FREQUENCY = 1.5
local onUpdateTimer = 0

function handlers.OnUpdate(germ, elapsed)
    onUpdateTimer = onUpdateTimer + elapsed
    if onUpdateTimer < ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    onUpdateTimer = 0
    handleGermUpdateEvent(germ)
end

---@param germ Germ
function handlers.OnPreClick(germ, whichMouseButton, down)
    germ.flyoutMenu:updateForGerm(germ, whichMouseButton, down)

    local UFO_NAMES = germ:GetAttribute("UFO_NAMES")
    local UFO_BLIZ_TYPES = germ:GetAttribute("UFO_BLIZ_TYPES")
    local UFO_PETS  = germ:GetAttribute("UFO_PETS")
    debug.trace:out("~",3, "OnPreClick()", "UFO_NAMES",UFO_NAMES, "UFO_BLIZ_TYPES",UFO_BLIZ_TYPES, "UFO_PETS",UFO_PETS)
end

-- this is needed for the edge case of clicking on a different germ while the current one is still open
-- in which case there is no OnShow event which is where the below usually happens
function handlers.OnPostClick(germ, whichMouseButton, down)
    ---@type FlyoutMenu
    local flyoutMenu = germ.flyoutMenu
    ---@param btn ButtonOnFlyoutMenu
    flyoutMenu:forEachButton(function(btn)
        --debug.trace:out("~",40, "btn updatery from Germ:OnPostClick()")
        btn:updateCooldownsAndCountsAndStatesEtc()
    end)
end
