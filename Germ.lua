-- Germ
-- a button on the actionbars that opens & closes an instance of a flyout menu
-- a.k.a launchpad, egg, exploder, torpedo, detonator, originator, impetus, genesis, bigBang, singularity...

local ADDON_NAME, Ufo = ...
local debug = Ufo.DEBUG.newDebugger(Ufo.DEBUG.TRACE)
local L10N = Ufo.L10N
local handlers = {}

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local snippet_Germ_Click = [=[
	local DELIMITER = "]=]..DELIMITER..[=["
	local EMPTY_ELEMENT = "]=]..EMPTY_ELEMENT..[=["
	local ref = self:GetFrameRef("UIUFO_FlyoutMenu")
	local direction = self:GetAttribute("flyoutDirection")
	local prevButton = nil;

	if ref:IsShown() and ref:GetParent() == self then
		ref:Hide()
	else
		ref:SetParent(self)
		ref:ClearAllPoints()
		if direction == "UP" then
			ref:SetPoint("BOTTOM", self, "TOP", 0, 0)
		elseif direction == "DOWN" then
			ref:SetPoint("TOP", self, "BOTTOM", 0, 0)
		elseif direction == "LEFT" then
			ref:SetPoint("RIGHT", self, "LEFT", 0, 0)
		elseif direction == "RIGHT" then
			ref:SetPoint("LEFT", self, "RIGHT", 0, 0)
		end

		local spellNameList = table.new(strsplit(DELIMITER, self:GetAttribute("spellnamelist")or""))
		local typeList = table.new(strsplit(DELIMITER, self:GetAttribute("typelist")or""))
		local pets = table.new(strsplit(DELIMITER, self:GetAttribute("petlist")or""))
		local buttonList = table.new(ref:GetChildren())
		table.remove(buttonList, 1)
		for i, buttonRef in ipairs(buttonList) do
			if typeList[i] then
				buttonRef:ClearAllPoints()
				if direction == "UP" then
					if prevButton then
						buttonRef:SetPoint("BOTTOM", prevButton, "TOP", 0, ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
					else
						buttonRef:SetPoint("BOTTOM", "$parent", 0, ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
					end
				elseif direction == "DOWN" then
					if prevButton then
						buttonRef:SetPoint("TOP", prevButton, "BOTTOM", 0, -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[)
					else
						buttonRef:SetPoint("TOP", "$parent", 0, -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[)
					end
				elseif direction == "LEFT" then
					if prevButton then
						buttonRef:SetPoint("RIGHT", prevButton, "LEFT", -]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
					else
						buttonRef:SetPoint("RIGHT", "$parent", -]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
					end
				elseif direction == "RIGHT" then
					if prevButton then
						buttonRef:SetPoint("LEFT", prevButton, "RIGHT", ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[, 0)
					else
						buttonRef:SetPoint("LEFT", "$parent", ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[, 0)
					end
				end

				local type = typeList[i]
				local thisId = ((typeList[i] == "battlepet") and pets[i]) or spellNameList[i]

				-- It appears that SecureActionButtonTemplate
				-- provides no support for summoning battlepets
				-- because summoning a battlepet is not a protected action.
				-- But, here we are, in FloFlyout's SecureActionButtonTemplate code,
				-- so, fake it with an adhoc macro!
				if (type == "battlepet") then
					-- here I was fumbling around guessing at a solution:
					-- buttonRef:SetAttribute("pet", thisId)
					-- buttonRef:SetAttribute("companion", thisId)
					-- buttonRef:SetAttribute("CompanionPet", thisId)

					-- summon the pet via a macro
					local petMacro = "/run C_PetJournal.SummonPetByGUID(\"" .. thisId .. "\")"
					buttonRef:SetAttribute("type", "macro")
					buttonRef:SetAttribute("macrotext", petMacro)
				else
					buttonRef:SetAttribute("type", type)
					buttonRef:SetAttribute(type, thisId)

				end

				buttonRef:Show()

				prevButton = buttonRef
			else
				buttonRef:Hide()
			end
		end
		local numButtons = table.maxn(typeList)
		if direction == "UP" or direction == "DOWN" then
			ref:SetWidth(prevButton:GetWidth())
			ref:SetHeight((prevButton:GetHeight()+]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[) * numButtons - ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[ + ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[ + ]=]..SPELLFLYOUT_FINAL_SPACING..[=[)
		else
			ref:SetHeight(prevButton:GetHeight())
			ref:SetWidth((prevButton:GetWidth()+]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[) * numButtons - ]=]..SPELLFLYOUT_DEFAULT_SPACING..[=[ + ]=]..SPELLFLYOUT_INITIAL_SPACING..[=[ + ]=]..SPELLFLYOUT_FINAL_SPACING..[=[)
		end
		ref:Show()
		--ref:RegisterAutoHide(1)
		--ref:AddToAutoHide(self)
	end
]=]

function createGerm(btnSlotIndex, flyoutId, direction, actionButton, visibleIf, typeActionButton)
    local flyoutConf = getFlyoutConfig(flyoutId)
    if not flyoutId then return end -- because one toon can delete a flyout while other toons still have it on their bars
    local name = "UIUfo_FlyoutGerm" .. btnSlotIndex
    local germ = getGerm(name) or CreateFrame("CheckButton", name, actionButton, "ActionButtonTemplate, SecureHandlerClickTemplate")
    setGerm(name, germ)
    germ.flyoutId = flyoutId
    germ.actionId = btnSlotIndex -- TODO: rename actionId -> btnSlotIndex

    if actionButton then
        if actionButton:GetSize() and actionButton:IsRectValid() then
            germ:SetAllPoints(actionButton)
        else
            local spacerName = "UIUfo_ActionBarButtonSpacer"..tostring(actionButton.index)
            local children = {actionButton:GetParent():GetChildren()}
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
    germ:SetFrameRef("UIUFO_FlyoutMenu", UIUFO_FlyoutMenu)

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
        if isThingyUsable(spellID, flyoutConf.actionTypes[i], flyoutConf.mountIndex[i], flyoutConf.macroOwners[i], flyoutConf.pets[i]) then
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

    -- TODO: find a way to eliminate the need for OnUpdate
    germ:SetScript("OnUpdate", handlers.OnUpdate)
    germ:SetScript("OnEnter", handlers.OnEnter)
    germ:SetScript("OnLeave", handlers.OnLeave)

    germ:SetScript("OnReceiveDrag", handlers.OnReceiveDrag)
    germ:SetScript("OnMouseUp", handlers.OnReceiveDrag) -- Hmmm... needed?
    germ:SetScript("OnDragStart", handlers.OnDragStart)

    germ:SetScript("PreClick", handlers.OnPreClick)
    germ:SetAttribute("_onclick", snippet_Germ_Click)
    germ:RegisterForClicks("AnyUp")
    germ:RegisterForDrag("LeftButton")

    -- TODO: calculate the icon on the fly - consider if a toon knows the spell before choosing its icon
    local icon = _G[germ:GetName().."Icon"]
    if flyoutConf.icon then
        if type(flyoutConf.icon) == "number" then
            icon:SetTexture(flyoutConf.icon)
        else
            icon:SetTexture("INTERFACE\\ICONS\\"..flyoutConf.icon)
        end
    elseif actionTypes[1] then
        local texture = getTexture(actionTypes[1], spells[1], pets[1])
        icon:SetTexture(texture)
    end

    if visibleIf then
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. visibleIf
        RegisterStateDriver(germ, "visibility", "["..stateCondition.."] show; hide")
    else
        germ:Show()
    end
end

-------------------------------------------------------------------------------
-- Handlers
-------------------------------------------------------------------------------

function handlers.OnReceiveDrag(germ)
    if InCombatLockdown() then
        return
    end

    local cursor = GetCursorInfo()
    if cursor then
        PlaceAction(germ.actionId)
    end
end

function handlers.OnDragStart(germ)
    if not InCombatLockdown() and (LOCK_ACTIONBAR ~= "1" or IsShiftKeyDown()) then
        pickupFlyout(germ.flyoutId)
        forgetPlacement(germ.actionId)
        applyAllGerms()
    end
end

function updateGerm(germ)
    -- print("========== Germ_UpdateFlyout()") this is being called continuously while a flyout exists on any bar
    -- Update border and determine arrow position
    local arrowDistance;
    -- Update border
    local isMouseOverButton =  GetMouseFocus() == germ;
    local isFlyoutShown = UIUFO_FlyoutMenu and UIUFO_FlyoutMenu:IsShown() and UIUFO_FlyoutMenu:GetParent() == germ;
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

function handlers.OnEnter(germ)
    updateGerm(germ)
end

function handlers.OnLeave(germ)
    updateGerm(germ)
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
    updateGerm(germ)
end

function handlers.OnPreClick(germ, whichMouseButton, down)
    germ:SetChecked(not germ:GetChecked())
    local direction = germ:GetAttribute("flyoutDirection");

    local spellList = fknSplit(germ:GetAttribute("spelllist"))
    --print("~~~~~~ /spellList/ =",self:GetAttribute("spellList"))
    --print("~~~~~~ spellList -->")
    --DevTools_Dump(spellList)

    local typeList = fknSplit(germ:GetAttribute("typelist"))
    --print("~~~~~~ /typeList/ =",self:GetAttribute("typelist"))
    --print("~~~~~~ typeList -->")
    --DevTools_Dump(typeList)

    local pets     = fknSplit(germ:GetAttribute("petlist"))
    --print("~~~~~~ /pets/ =",self:GetAttribute("petlist"))
    --print("~~~~~~ pets -->")
    --DevTools_Dump(pets)

    local buttonFrames = { UIUFO_FlyoutMenu:GetChildren() }
    table.remove(buttonFrames, 1)
    for i, buttonFrame in ipairs(buttonFrames) do
        local type = typeList[i]
        if not isEmpty(type) then
            local spellId = spellList[i]
            local pet = pets[i]
            --print("Germ_PreClick(): i =",i, "| spellID =",spellId,  "| type =",type, "| pet =", pet)

            buttonFrame.spellID = spellId
            buttonFrame.actionType = type
            buttonFrame.battlepet = pet

            local icon = getTexture(type, spellId, pet)
            _G[buttonFrame:GetName().."Icon"]:SetTexture(icon)

            if not isEmpty(spellId) then
                SpellFlyoutButton_UpdateCooldown(buttonFrame)
                SpellFlyoutButton_UpdateState(buttonFrame)
                SpellFlyoutButton_UpdateUsable(buttonFrame)
                SpellFlyoutButton_UpdateCount(buttonFrame)
            end
        end
    end
    UIUFO_FlyoutMenu.Background.End:ClearAllPoints()
    UIUFO_FlyoutMenu.Background.Start:ClearAllPoints()
    local distance = 3
    if (direction == "UP") then
        UIUFO_FlyoutMenu.Background.End:SetPoint("TOP", 0, SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.End, 0);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.VerticalMiddle, 0);
        UIUFO_FlyoutMenu.Background.Start:SetPoint("TOP", UIUFO_FlyoutMenu.Background.VerticalMiddle, "BOTTOM");
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.Start, 0);
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:Hide();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:Show();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:ClearAllPoints();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:SetPoint("TOP", UIUFO_FlyoutMenu.Background.End, "BOTTOM");
        UIUFO_FlyoutMenu.Background.VerticalMiddle:SetPoint("BOTTOM", 0, distance);
    elseif (direction == "DOWN") then
        UIUFO_FlyoutMenu.Background.End:SetPoint("BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.End, 180);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.VerticalMiddle, 180);
        UIUFO_FlyoutMenu.Background.Start:SetPoint("BOTTOM", UIUFO_FlyoutMenu.Background.VerticalMiddle, "TOP");
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.Start, 180);
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:Hide();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:Show();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:ClearAllPoints();
        UIUFO_FlyoutMenu.Background.VerticalMiddle:SetPoint("BOTTOM", UIUFO_FlyoutMenu.Background.End, "TOP");
        UIUFO_FlyoutMenu.Background.VerticalMiddle:SetPoint("TOP", 0, -distance);
    elseif (direction == "LEFT") then
        UIUFO_FlyoutMenu.Background.End:SetPoint("LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.End, 270);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.HorizontalMiddle, 180);
        UIUFO_FlyoutMenu.Background.Start:SetPoint("LEFT", UIUFO_FlyoutMenu.Background.HorizontalMiddle, "RIGHT");
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.Start, 270);
        UIUFO_FlyoutMenu.Background.VerticalMiddle:Hide();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:Show();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:ClearAllPoints();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:SetPoint("LEFT", UIUFO_FlyoutMenu.Background.End, "RIGHT");
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:SetPoint("RIGHT", -distance, 0);
    elseif (direction == "RIGHT") then
        UIUFO_FlyoutMenu.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.End, 90);
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.HorizontalMiddle, 0);
        UIUFO_FlyoutMenu.Background.Start:SetPoint("RIGHT", UIUFO_FlyoutMenu.Background.HorizontalMiddle, "LEFT");
        SetClampedTextureRotation(UIUFO_FlyoutMenu.Background.Start, 90);
        UIUFO_FlyoutMenu.Background.VerticalMiddle:Hide();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:Show();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:ClearAllPoints();
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:SetPoint("RIGHT", UIUFO_FlyoutMenu.Background.End, "LEFT");
        UIUFO_FlyoutMenu.Background.HorizontalMiddle:SetPoint("LEFT", distance, 0);
    end
    UIUFO_FlyoutMenu:SetBorderColor(0.7, 0.7, 0.7)
    UIUFO_FlyoutMenu:SetBorderSize(47);
end
