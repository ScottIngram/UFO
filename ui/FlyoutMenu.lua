-- FlyoutMenu
-- methods and functions for flyout creation, behavior, etc

local ADDON_NAME, Ufo = ...
local debug = Ufo.DEBUG.newDebugger(Ufo.DEBUG.TRACE)
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutMenu XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_FlyoutMenu_OnLoad(...)
    SpellFlyout_OnLoad(...) -- call Blizzard handler
end

function GLOBAL_UIUFO_FlyoutMenu_OnShow(...)
    SpellFlyout_OnShow(...) -- call Blizzard handler
end

function GLOBAL_UIUFO_FlyoutMenu_OnHide(...)
    SpellFlyout_OnHide(...) -- call Blizzard handler
end

local function getButtonFor(parent, i)
    return _G[ parent:GetName().."Button"..i ]
end

local function updateAllButtonStatusesFor(flyoutMenu, handler)
    local i = 1
    local button = getButtonFor(flyoutMenu, i)
    while (button and button:IsShown() and not exists(button.spellID)) do
        handler(button)
        i = i+1
        button = getButtonFor(flyoutMenu, i)
    end
end

function GLOBAL_UIUFO_FlyoutMenu_OnEvent(flyoutMenu, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        updateAllButtonStatusesFor(flyoutMenu, function(button)
            SpellFlyoutButton_UpdateCooldown(button)
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
            SpellFlyoutButton_UpdateCooldown(button)
            SpellFlyoutButton_UpdateState(button)
            SpellFlyoutButton_UpdateUsable(button)
            SpellFlyoutButton_UpdateCount(button)
        end)
    end
end

function updateFlyoutMenuForCatalog(flyoutMenu, flyoutId)
    local direction = "RIGHT"
    local parent = flyoutMenu.parent

    flyoutMenu.idFlyout = flyoutId

    -- Update all spell buttons for this flyout
    local prevButton = nil;
    local numButtons = 0;
    local flyoutConfig = Ufo:GetFlyoutConfig(flyoutId)
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
