-- FlyoutMenu
-- methods and functions for flyout creation, behavior, etc

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
---@type Debug -- IntelliJ-EmmyLua annotation
local debugTrace, debugInfo, debugWarn, debugError = Debug:new(Debug.INFO)

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutMenu XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_FlyoutMenu_OnLoad(...)
    SpellFlyout_OnLoad(...) -- call Blizzard handler
end

function GLOBAL_UIUFO_FlyoutMenu_OnShow(self)
    SpellFlyout_OnShow(self) -- call Blizzard handler
    self:RegisterEvent("BAG_UPDATE_COOLDOWN"); -- to support items
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- to support items

    updateAllButtonStatusesFor(self, function(button)
        debugInfo:out("/",40)
        Ufo_UpdateCooldown(button)
        SpellFlyoutButton_UpdateState(button)
        SpellFlyoutButton_UpdateUsable(button)
        SpellFlyoutButton_UpdateCount(button)
    end)

end

function SpellFlyoutButton_UpdateCount (self)
    local text = _G[self:GetName().."Count"];
    if ( IsConsumableSpell(self.spellID)) then
        local count = GetSpellCount(self.spellID);
        if ( count > (self.maxDisplayCount or 9999 ) ) then
            text:SetText("*");
        else
            text:SetText(count);
        end
    else
        text:SetText("");
    end
end


function GLOBAL_UIUFO_FlyoutMenu_OnHide(self)
    SpellFlyout_OnHide(self) -- call Blizzard handler
    if (self.eventsRegistered == true) then
        self:UnregisterEvent("BAG_UPDATE_COOLDOWN"); -- to support items
        self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- to support items
    end
end

local function getButtonFor(parent, i)
    return _G[ parent:GetName().."Button"..i ]
end

local callCount2
function GLOBAL_UIUFO_ButtonOnFlyoutMenuTemplate_OnEvent(button, event, ...)
    debugInfo:out("O",3,"GLOBAL_UIUFO_ButtonOnFlyoutMenuTemplate_OnEvent", "event",event, "callCount2",callCount2)
    callCount2 = callCount2 + 1
    if (event == "SPELL_UPDATE_COOLDOWN") or (event == "ACTIONBAR_UPDATE_COOLDOWN") or (event == "BAG_UPDATE_COOLDOWN") then
            debugInfo:print("EVENT O:", event)
            Ufo_UpdateCooldown(button)
    elseif event == "CURRENT_SPELL_CAST_CHANGED" then
            SpellFlyoutButton_UpdateState(button)
    elseif event == "SPELL_UPDATE_USABLE" then
            SpellFlyoutButton_UpdateUsable(button)
    elseif event == "BAG_UPDATE" then
            SpellFlyoutButton_UpdateCount(button)
            SpellFlyoutButton_UpdateUsable(button)
    elseif event == "SPELL_FLYOUT_UPDATE" then
            Ufo_UpdateCooldown(button)
            SpellFlyoutButton_UpdateState(button)
            SpellFlyoutButton_UpdateUsable(button)
            SpellFlyoutButton_UpdateCount(button)
    end
end

function updateAllButtonStatusesFor(flyoutMenu, handler)
    local i = 1
    local button = getButtonFor(flyoutMenu, i)
    while (button and button:IsShown()) do
        if exists(button.spellID or button.action) then
            handler(button)
        end
        i = i+1
        button = getButtonFor(flyoutMenu, i)
    end
end

-- THIS FUNCTION MAY HAVE NO EFFECT
local callCount = 0
function GLOBAL_UIUFO_FlyoutMenu_OnEvent(flyoutMenu, event, ...)
    --if true then return end
    debugInfo:out("-",3,"GLOBAL_UIUFO_FlyoutMenu_OnEvent", "event",event, "callCount",callCount)
    callCount = callCount + 1
    if (event == "SPELL_UPDATE_COOLDOWN") or (event == "ACTIONBAR_UPDATE_COOLDOWN") or (event == "BAG_UPDATE_COOLDOWN") then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            debugInfo:out("=",40)
            --debugInfo:dumpKeys(button)
            --debugInfo:out("=",40)
            Ufo_UpdateCooldown(button)
        end)
    elseif event == "CURRENT_SPELL_CAST_CHANGED" then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            SpellFlyoutButton_UpdateState(button)
        end)
    elseif event == "SPELL_UPDATE_USABLE" then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            SpellFlyoutButton_UpdateUsable(button)
        end)
    elseif event == "BAG_UPDATE" then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            SpellFlyoutButton_UpdateCount(button)
            SpellFlyoutButton_UpdateUsable(button)
        end)
    elseif event == "SPELL_FLYOUT_UPDATE" then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            Ufo_UpdateCooldown(button)
            SpellFlyoutButton_UpdateState(button)
            SpellFlyoutButton_UpdateUsable(button)
            SpellFlyoutButton_UpdateCount(button)
        end)
    end
end

function Ufo_UpdateCooldown(btn)
    -- copied from Bliz's ActionButton_UpdateCooldown and updated to understand items (TODO: maybe macros?)
    local locStart, locDuration;
    local start, duration, enable, charges, maxCharges, chargeStart, chargeDuration;
    local modRate = 1.0;
    local chargeModRate = 1.0;
    local actionType, actionID = nil;
    if (btn.action) then
        actionType, actionID = GetActionInfo(btn.action);
    end
    local auraData = nil;
    local passiveCooldownSpellID = nil;
    local onEquipPassiveSpellID = nil;

    if(actionID) then
        onEquipPassiveSpellID = C_ActionBar.GetItemActionOnEquipSpellID(btn.action or btn.itemID);
    end

    debugInfo:out("X",3,"Ufo_UpdateCooldown 1", "self.action", btn.action, "actionType",actionType,  "actionID",actionID,  "self.booger", btn.booger, "onEquipPassiveSpellID",onEquipPassiveSpellID )

    if (onEquipPassiveSpellID) then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(onEquipPassiveSpellID);
    elseif ((actionType and actionType == "spell") and actionID ) then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(actionID);
    elseif(btn.spellID) then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(btn.spellID);
    end

    if(passiveCooldownSpellID and passiveCooldownSpellID ~= 0) then
        auraData = C_UnitAuras.GetPlayerAuraBySpellID(passiveCooldownSpellID);
    end

    if(auraData) then
        local currentTime = GetTime();
        local timeUntilExpire = auraData.expirationTime - currentTime;
        local howMuchTimeHasPassed = auraData.duration - timeUntilExpire;

        locStart =  currentTime - howMuchTimeHasPassed;
        locDuration = auraData.expirationTime - currentTime;
        start = currentTime - howMuchTimeHasPassed;
        duration =  auraData.duration
        modRate = auraData.timeMod;
        charges = auraData.charges;
        maxCharges = auraData.maxCharges;
        chargeStart = currentTime * 0.001;
        chargeDuration = duration * 0.001;
        chargeModRate = modRate;
        enable = 1;
    elseif (btn.itemID) then -- added for UFO
        locStart, locDuration = GetSpellLossOfControlCooldown(btn.itemID);
        start, duration, enable = GetItemCooldown(btn.itemID);
        local includeBank = false
        local includeCharges = true
        local count = GetItemCount(btn.itemID, includeBank, includeCharges)
        -- charges, maxCharges, chargeStart, chargeDuration = count, count, 1, 1
        charges = count
        debugInfo:out("X",5,"Ufo_UpdateCooldown 2 ITEM","actionType",actionType, "start",start, "duration",duration, "enable",enable )
    elseif (btn.spellID) then
        locStart, locDuration = GetSpellLossOfControlCooldown(btn.spellID);
        start, duration, enable, modRate = GetSpellCooldown(btn.spellID);
        charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetSpellCharges(btn.spellID);
        debugInfo:out("X",5,"Ufo_UpdateCooldown 2 SPELL","actionType",actionType, "start",start, "duration",duration, "enable",enable )
    else
        locStart, locDuration = GetActionLossOfControlCooldown(btn.action);
        start, duration, enable, modRate = GetActionCooldown(btn.action);
        charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(btn.action);
        debugInfo:out("X",5,"Ufo_UpdateCooldown 2 FALLTHRU","actionType",actionType, "start",start, "duration",duration, "enable",enable )
    end

    if ( (locStart + locDuration) > (start + duration) ) then
        debugInfo:out("X",5,"Ufo_UpdateCooldown 3 LOC")
        if ( btn.cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL ) then
            btn.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge-LoC");
            btn.cooldown:SetSwipeColor(0.17, 0, 0);
            btn.cooldown:SetHideCountdownNumbers(true);
            btn.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL;
        end

        CooldownFrame_Set(btn.cooldown, locStart, locDuration, true, true, modRate);
        ClearChargeCooldown(btn);
    else
        debugInfo:out("X",5,"Ufo_UpdateCooldown 3","self.cooldown.currentCooldownType", btn.cooldown.currentCooldownType)
        if ( btn.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL ) then
            btn.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
            btn.cooldown:SetSwipeColor(0, 0, 0);
            btn.cooldown:SetHideCountdownNumbers(false);
            btn.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
        end

        if( locStart > 0 ) then
            btn.cooldown:SetScript("OnCooldownDone", ActionButtonCooldown_OnCooldownDone);
        end

        if ( charges and maxCharges and maxCharges > 1 and charges < maxCharges ) then
            StartChargeCooldown(btn, chargeStart, chargeDuration, chargeModRate);
        else
            ClearChargeCooldown(btn);
        end

        CooldownFrame_Set(btn.cooldown, start, duration, enable, false, modRate);
    end
end


function updateFlyoutMenuForCatalog(flyoutMenu, flyoutId)
    local direction = "RIGHT"
    local parent = flyoutMenu.parent

    flyoutMenu.idFlyout = flyoutId

    -- Update all spell buttons for this flyout
    local prevButton = nil;
    local numButtons = 0;
    local flyoutConfig = getFlyoutConfig(flyoutId)
    local spells = flyoutConfig and flyoutConfig.spells
    local actionTypes = flyoutConfig and flyoutConfig.actionTypes
    local mountIndexes = flyoutConfig and flyoutConfig.mountIndex
    local pets = flyoutConfig and flyoutConfig.pets

    for i=1, math.min(#actionTypes+1, MAX_FLYOUT_SIZE) do
        local spellId    = spells[i]
        local actionType = actionTypes[i]
        local mountIndex = mountIndexes[i]
        local pet        = pets[i]
        local button = _G["UIUFO_FlyoutMenuForCatalogButton"..numButtons+1]

        button:ClearAllPoints()
        if direction == "UP" then
            if prevButton then
                button:SetPoint("BOTTOM", prevButton, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
            else
                button:SetPoint("BOTTOM", 0, SPELLFLYOUT_INITIAL_SPACING)
            end
        elseif direction == "DOWN" then
            if prevButton then
                button:SetPoint("TOP", prevButton, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
            else
                button:SetPoint("TOP", 0, -SPELLFLYOUT_INITIAL_SPACING)
            end
        elseif direction == "LEFT" then
            if prevButton then
                button:SetPoint("RIGHT", prevButton, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
            else
                button:SetPoint("RIGHT", -SPELLFLYOUT_INITIAL_SPACING, 0)
            end
        elseif direction == "RIGHT" then
            if prevButton then
                button:SetPoint("LEFT", prevButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
            else
                button:SetPoint("LEFT", SPELLFLYOUT_INITIAL_SPACING, 0)
            end
        end

        button:Show()

        if actionType then
            button.spellID = spellId -- this is read by Bliz code in SpellFlyout.lua which expects only numbers
            button.actionType = actionType
            button.mountIndex = mountIndex
            button.battlepet  = pet
            local texture = getTexture(actionType, spellId, pet)
            _G[button:GetName().."Icon"]:SetTexture(texture)
            if spellId then
                SpellFlyoutButton_UpdateCooldown(button)
                SpellFlyoutButton_UpdateState(button)
                SpellFlyoutButton_UpdateUsable(button)
                SpellFlyoutButton_UpdateCount(button)
            end
        else
            _G[button:GetName().."Icon"]:SetTexture(nil)
            button.spellID = nil
            button.actionType = nil
            button.mountIndex = nil
        end

        prevButton = button
        numButtons = numButtons+1
    end

    -- Hide unused buttons
    local unusedButtonIndex = numButtons+1
    while _G["UIUFO_FlyoutMenuForCatalogButton"..unusedButtonIndex] do
        _G["UIUFO_FlyoutMenuForCatalogButton"..unusedButtonIndex]:Hide()
        unusedButtonIndex = unusedButtonIndex+1
    end

    if numButtons == 0 then
        flyoutMenu:Hide()
        return
    end

    -- Show the flyout
    flyoutMenu:SetFrameStrata("DIALOG")
    flyoutMenu:ClearAllPoints()

    local distance = 3

    flyoutMenu.Background.End:ClearAllPoints()
    flyoutMenu.Background.Start:ClearAllPoints()
    if (direction == "UP") then
        flyoutMenu:SetPoint("BOTTOM", parent, "TOP");
        flyoutMenu.Background.End:SetPoint("TOP", 0, SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(flyoutMenu.Background.End, 0);
        SetClampedTextureRotation(flyoutMenu.Background.VerticalMiddle, 0);
        flyoutMenu.Background.Start:SetPoint("TOP", flyoutMenu.Background.VerticalMiddle, "BOTTOM");
        SetClampedTextureRotation(flyoutMenu.Background.Start, 0);
        flyoutMenu.Background.HorizontalMiddle:Hide();
        flyoutMenu.Background.VerticalMiddle:Show();
        flyoutMenu.Background.VerticalMiddle:ClearAllPoints();
        flyoutMenu.Background.VerticalMiddle:SetPoint("TOP", flyoutMenu.Background.End, "BOTTOM");
        flyoutMenu.Background.VerticalMiddle:SetPoint("BOTTOM", 0, distance);
    elseif (direction == "DOWN") then
        flyoutMenu:SetPoint("TOP", parent, "BOTTOM");
        flyoutMenu.Background.End:SetPoint("BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(flyoutMenu.Background.End, 180);
        SetClampedTextureRotation(flyoutMenu.Background.VerticalMiddle, 180);
        flyoutMenu.Background.Start:SetPoint("BOTTOM", flyoutMenu.Background.VerticalMiddle, "TOP");
        SetClampedTextureRotation(flyoutMenu.Background.Start, 180);
        flyoutMenu.Background.HorizontalMiddle:Hide();
        flyoutMenu.Background.VerticalMiddle:Show();
        flyoutMenu.Background.VerticalMiddle:ClearAllPoints();
        flyoutMenu.Background.VerticalMiddle:SetPoint("BOTTOM", flyoutMenu.Background.End, "TOP");
        flyoutMenu.Background.VerticalMiddle:SetPoint("TOP", 0, -distance);
    elseif (direction == "LEFT") then
        flyoutMenu:SetPoint("RIGHT", parent, "LEFT");
        flyoutMenu.Background.End:SetPoint("LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(flyoutMenu.Background.End, 270);
        SetClampedTextureRotation(flyoutMenu.Background.HorizontalMiddle, 180);
        flyoutMenu.Background.Start:SetPoint("LEFT", flyoutMenu.Background.HorizontalMiddle, "RIGHT");
        SetClampedTextureRotation(flyoutMenu.Background.Start, 270);
        flyoutMenu.Background.VerticalMiddle:Hide();
        flyoutMenu.Background.HorizontalMiddle:Show();
        flyoutMenu.Background.HorizontalMiddle:ClearAllPoints();
        flyoutMenu.Background.HorizontalMiddle:SetPoint("LEFT", flyoutMenu.Background.End, "RIGHT");
        flyoutMenu.Background.HorizontalMiddle:SetPoint("RIGHT", -distance, 0);
    elseif (direction == "RIGHT") then
        flyoutMenu:SetPoint("LEFT", parent, "RIGHT");
        flyoutMenu.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(flyoutMenu.Background.End, 90);
        SetClampedTextureRotation(flyoutMenu.Background.HorizontalMiddle, 0);
        flyoutMenu.Background.Start:SetPoint("RIGHT", flyoutMenu.Background.HorizontalMiddle, "LEFT");
        SetClampedTextureRotation(flyoutMenu.Background.Start, 90);
        flyoutMenu.Background.VerticalMiddle:Hide();
        flyoutMenu.Background.HorizontalMiddle:Show();
        flyoutMenu.Background.HorizontalMiddle:ClearAllPoints();
        flyoutMenu.Background.HorizontalMiddle:SetPoint("RIGHT", flyoutMenu.Background.End, "LEFT");
        flyoutMenu.Background.HorizontalMiddle:SetPoint("LEFT", distance, 0);
    end

    if direction == "UP" or direction == "DOWN" then
        flyoutMenu:SetWidth(prevButton:GetWidth())
        flyoutMenu:SetHeight((prevButton:GetHeight()+SPELLFLYOUT_DEFAULT_SPACING) * numButtons - SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)
    else
        flyoutMenu:SetHeight(prevButton:GetHeight())
        flyoutMenu:SetWidth((prevButton:GetWidth()+SPELLFLYOUT_DEFAULT_SPACING) * numButtons - SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)
    end

    flyoutMenu.direction = direction;
    flyoutMenu:SetBorderColor(0.7, 0.7, 0.7);
    flyoutMenu:SetBorderSize(47);
end

function initializeOnClickHandlersForFlyouts()
    for i, button in ipairs({UIUFO_FlyoutMenu:GetChildren()}) do
        if button:GetObjectType() == "CheckButton" then
            SecureHandlerWrapScript(button, "OnClick", button, "self:GetParent():Hide()")
        end
    end

    UIUFO_FlyoutMenuForCatalog.IsConfig = true
end
