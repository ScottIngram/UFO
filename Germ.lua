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

local debug = Debug:new(DEBUG_OUTPUT.WARN)

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

    local spellNameList = table.new(strsplit(DELIMITER, germ:GetAttribute("spellnamelist")or""))
    local typeList      = table.new(strsplit(DELIMITER, germ:GetAttribute("typelist")or""))
    local pets          = table.new(strsplit(DELIMITER, germ:GetAttribute("petlist")or""))
    local uiButtons     = table.new(flyoutMenu:GetChildren())
    table.remove(uiButtons, 1)
    for i, btn in ipairs(uiButtons) do
        if typeList[i] then
            btn:ClearAllPoints()
            if direction == "UP" then
                if prevBtn then
                    btn:SetPoint("BOTTOM", prevBtn, "TOP", 0, ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
                else
                    btn:SetPoint("BOTTOM", "$parent", 0, ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
                end
            elseif direction == "DOWN" then
                if prevBtn then
                    btn:SetPoint("TOP", prevBtn, "BOTTOM", 0, -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
                else
                    btn:SetPoint("TOP", "$parent", 0, -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
                end
            elseif direction == "LEFT" then
                if prevBtn then
                    btn:SetPoint("RIGHT", prevBtn, "LEFT", -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
                else
                    btn:SetPoint("RIGHT", "$parent", -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
                end
            elseif direction == "RIGHT" then
                if prevBtn then
                    btn:SetPoint("LEFT", prevBtn, "RIGHT", ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
                else
                    btn:SetPoint("LEFT", "$parent", ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
                end
            end

            local type = typeList[i]
            local thisId = ((typeList[i] == "battlepet") and pets[i]) or spellNameList[i]

            -- It appears that SecureActionButtonTemplate
            -- provides no support for summoning battlepets
            -- because summoning a battlepet is not a protected action.
            -- So, fake it with an adhoc macro!
            if (type == "battlepet") then
                -- here I was fumbling around guessing at a solution:
                -- btn:SetAttribute("pet", thisId)
                -- btn:SetAttribute("companion", thisId)
                -- btn:SetAttribute("CompanionPet", thisId)

                -- summon the pet via a macro
                local petMacro = "/run C_PetJournal.SummonPetByGUID(\"" .. thisId .. "\")"
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", petMacro)
            else
                btn:SetAttribute("type", type)
                btn:SetAttribute(type, thisId)

            end

            btn:Show()

            prevBtn = btn

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
    --flyoutMenu:RegisterAutoHide(1)
    --flyoutMenu:AddToAutoHide(germ)
]=]

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function Germ.new(flyoutId, actionBarBtn)
    assertIsFunctionOf(flyoutId,Germ)
    local flyoutConf = FlyoutMenus:get(flyoutId)
    if not flyoutConf then return end -- because one toon can delete a flyout while other toons still have it on their bars
    local name = GERM_UI_NAME_PREFIX .. actionBarBtn:GetName()
    ---@type Germ
    local protoGerm = CreateFrame("CheckButton", name, actionBarBtn, "ActionButtonTemplate, SecureHandlerClickTemplate")
    deepcopy(Germ, protoGerm) -- copy Germ's methods, functions, etc to the UI btn
    protoGerm.flyoutId = flyoutId
    protoGerm.flyoutMenu = UIUFO_FlyoutMenuForGerm -- the one UI object is reused by every germ
    return protoGerm
end

function Germ:setIconTexture(texture)
    if texture and type(texture) ~= "number" then
        texture = ("INTERFACE\\ICONS\\"..texture)
    end

    _G[ self:GetName().."Icon" ]:SetTexture(texture)
end

function Germ:GetBtnSlotIndex()
    local whateverIsActionBarBtnParent = self:GetParent()
    assert(whateverIsActionBarBtnParent, "Um, this germ has no parent?!")
    return whateverIsActionBarBtnParent.action
end

function Germ:Refresh(flyoutId, btnSlotIndex, direction, visibleIf)
    assertIsMethodOf(self, Germ)
    local germ = self

    germ.flyoutId = flyoutId
    local flyoutConf = FlyoutMenus:get(germ.flyoutId)
    if not flyoutConf then return end -- because one toon can delete a flyout while other toons still have it on their bars

    germ.action = btnSlotIndex -- used deep inside the Bliz APIs

    local actionBarBtn = germ:GetParent()
    if actionBarBtn then
        if actionBarBtn:GetSize() and actionBarBtn:IsRectValid() then
            germ:SetAllPoints(actionBarBtn)
        else
            local spacerName = "UIUfo_ActionBarButtonSpacer"..tostring(actionBarBtn.index)
            local children = { actionBarBtn:GetParent():GetChildren()}
            for _, child in ipairs(children) do
                if child:GetName() == spacerName then
                    germ:SetAllPoints(child)
                    break;
                end
            end
        end
    end

    germ:SetFrameStrata(STRATA_DEFAULT)
    germ:SetFrameLevel(100)
    germ:SetToplevel(true)

    germ:SetAttribute("flyoutDirection", direction)
    germ:SetFrameRef("UIUFO_FlyoutMenuForGerm", UIUFO_FlyoutMenuForGerm)

    for i, actionType in ipairs(flyoutConf.actionTypes) do
        if flyoutConf.spellNames[i] == nil then
            flyoutConf.spellNames[i] = getThingyNameById(flyoutConf.actionTypes[i], flyoutConf.spells[i] or flyoutConf.pets[i])
        end
    end

    local spells = {}
    local spellNames = {}
    local actionTypes = {}
    local pets = {}

    -- filter out unsuable spell/item/etc - use the "actionType" field because it never has missing elements, unlike spells and pets
    local n = 1
    for i, actionType in ipairs(flyoutConf.actionTypes) do
        local spellID = flyoutConf.spells[i]
        if isThingyUsable(spellID, flyoutConf.actionTypes[i], flyoutConf.mounts[i], flyoutConf.macroOwners[i], flyoutConf.pets[i]) then
            -- table.insert won't preserve correct indicies of arrays with nil elements, so do this[instead]
            spells[n]      = flyoutConf.spells[i]
            spellNames[n]  = flyoutConf.spellNames[i]
            actionTypes[n] = flyoutConf.actionTypes[i]
            pets[n]        = flyoutConf.pets[i]
            n = n + 1
        end
    end

    -- attach string representations of the "arrays" to the germ because Blizzard "secure" templates don't let us attach the actual array
    germ:SetAttribute("spelllist", fknJoin(spells))
    germ:SetAttribute("spellnamelist", fknJoin(spellNames))
    germ:SetAttribute("typelist", fknJoin(actionTypes))
    germ:SetAttribute("petlist", fknJoin(pets))

    --[[
        germ:SetAttribute("spelllist", strjoin(",", unpack(flyoutConf.spells)))
        local spellnameList = flyoutConf.spellNames
        for i, spellID in ipairs(flyoutConf.spells) do
            if spellnameList[i] == nil then
                spellnameList[i] = getItemOrSpellNameById(flyoutConf.actionTypes[i], spellID)
            end
        end
        germ:SetAttribute("spellnamelist", strjoin(",", unpack(flyoutConf.spellNames)))
        germ:SetAttribute("typelist", strjoin(",", unpack(flyoutConf.actionTypes)))
    ]]

    -- TODO: these only need to be set when the germ is first created.
    -- TODO: find a way to eliminate the need for OnUpdate
    germ:SetScript("OnUpdate", handlers.OnUpdate)
    germ:SetScript("OnEnter", handlers.OnEnter)
    germ:SetScript("OnLeave", handlers.OnLeave)
    germ:SetScript("OnReceiveDrag", handlers.OnReceiveDrag)
    germ:SetScript("OnMouseUp", handlers.OnMouseUp)
    germ:SetScript("OnDragStart", handlers.PickupAndDrag)
    germ:SetScript("PreClick", handlers.OnPreClick)
    germ:SetScript("PostClick", handlers.OnPostClick)
    germ:SetAttribute("_onclick", snippet_Germ_Click)
    germ:RegisterForClicks("AnyUp")
    germ:RegisterForDrag("LeftButton")

    local texture = flyoutConf.icon or actionTypes[1] and getTexture(actionTypes[1], spells[1], pets[1])
    germ:setIconTexture(texture)

    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        RegisterStateDriver(germ, "visibility", "["..stateCondition.."] show; hide")
    else
        germ:Show()
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
    if InCombatLockdown() then
        return
    end

    local cursor = GetCursorInfo()
    if cursor then
        PlaceAction(germ:GetBtnSlotIndex())
    end
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function handlers.PickupAndDrag(germ)
    if not InCombatLockdown() and (LOCK_ACTIONBAR ~= "1" or IsShiftKeyDown()) then
        debug.trace:out("^",5,"OnDragStart()","name",germ:GetName())
        pickupFlyout(germ.flyoutId)
        forgetPlacement(germ:GetBtnSlotIndex())
        updateAllGerms()
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
    germ.flyoutMenu:updateFlyoutMenuForGerm(germ, whichMouseButton, down)
end

-- this is needed for the edge case of clicking on a different germ while the current one is still open
-- in which case there is no OnShow event which is where the below usually happens
function handlers.OnPostClick(germ, whichMouseButton, down)
    ---@type FlyoutMenu
    local flyoutMenu = germ.flyoutMenu
    ---@param btn ButtonOnFlyoutMenu
    flyoutMenu:forEachButton(function(btn)
        debug.trace:out("~",40, "btn updatery from Germ:OnPostClick()")
        btn:updateCooldownsAndCountsAndStatesEtc()
    end)
end
