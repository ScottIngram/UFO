-- Catalog
-- The catalog UI collecting the existing flyout menus letting the user create, edit, and delete them.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(DEBUG_OUTPUT.WARN)

---@class Catalog -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local Catalog = {
    ufoType = "Catalog",
}
Ufo.Catalog = Catalog

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- Executed on load, calls general set-up functions
function Catalog:definePopupDialogWindow()
    StaticPopupDialogs["UFO_CONFIRM_DELETE"] = {
        text = L10N["CONFIRM_DELETE"],
        button1 = YES,
        button2 = NO,
        OnAccept = function (dialog) deleteFlyout(dialog.flyoutId); updateCatalog(); updateAllGerms(); end,
        OnCancel = function (dialog) end,
        hideOnEscape = 1,
        timeout = 0,
        exclusive = 1,
        whileDead = 1,
    }
end

-------------------------------------------------------------------------------
-- CATALOG Functions Supporting Catalog UI
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_CatalogScrollPane_OnLoad(scrollPane)
    HybridScrollFrame_OnLoad(scrollPane)
    scrollPane.update = updateCatalog
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogFlyoutOptionsMouseOver")
end

function GLOBAL_UIUFO_CatalogScrollPane_OnShow(scrollPane)
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogFlyoutOptionsMouseOver")
    updateCatalog()
end

function GLOBAL_UIUFO_CatalogScrollPane_OnHide(scrollPane)
    UIUFO_DetailerPopup:Hide()
    UIUFO_FlyoutMenuForCatalog:Hide()
end

function GLOBAL_UIUFO_BlizCompartment_OnClick(addonName, whichMouseButton)
    debug.trace:out("~",3,"UIUFO_BlizCompartment_OnClick","addonName",addonName, "whichMouseButton", whichMouseButton)
    if not SpellBookFrame:IsShown() then
        ToggleSpellBook("spell")
        --SpellBookFrame:Show()
    end
    GLOBAL_UIUFO_OpenCatalogBtn_OnClick()
end

function GLOBAL_UIUFO_OpenCatalogBtn_OnClick(prollyUIUFO_OpenCatalogBtn)
    if UIUFO_Catalog:IsShown() then
        -- Hide FlyoutConfig panel and collapse its space
        UIUFO_Catalog:Hide()
        SetUIPanelAttribute(SpellBookFrame, "width", GetUIPanelWidth(SpellBookFrame) - 150)
        UpdateUIPanelPositions(SpellBookFrame)
    else
        -- Show FlyoutConfig panel and make room for it
        UIUFO_Catalog:Show()
        SetUIPanelAttribute(SpellBookFrame, "width", GetUIPanelWidth(SpellBookFrame) + 150)
        UpdateUIPanelPositions(SpellBookFrame)
    end

end

-- throttle OnUpdate because it fires as often as FPS and is very resource intensive
local C_UI_ON_UPDATE_TIMER_FREQUENCY = 0.25
local onUpdateTimerForConfigUi = 0

function GLOBAL_UIUFO_CatalogScrollPane_OnUpdate(scrollPane, elapsed)
    onUpdateTimerForConfigUi = onUpdateTimerForConfigUi + elapsed
    if onUpdateTimerForConfigUi < C_UI_ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    --print("GLOBAL_UIUFO_CatalogScrollPane_OnUpdate() UFO_CatalogScrollPane_onUpdateTimer =", onUpdateTimerForConfigUi)
    onUpdateTimerForConfigUi = 0
    UFO_CatalogScrollPane_DoUpdate(scrollPane)
end

function GLOBAL_UIUFO_CatalogFlyoutOptionsDetailerBtn_OnClick(scrollPane, whichMouseButton, down)
    if scrollPane.name and scrollPane.name ~= "" then
        if UIUFO_CatalogScrollPane.selectedIdx == scrollPane.name then
            UIUFO_CatalogScrollPane.selectedIdx = nil
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)		-- inappropriately named, but a good sound.
            UIUFO_CatalogScrollPane.selectedIdx = scrollPane.name
        end
        updateCatalog()
        UIUFO_DetailerPopup:Hide()
    else
        -- This is the "New" button
        UIUFO_DetailerPopup:Show()
        UIUFO_CatalogScrollPane.selectedIdx = nil
        updateCatalog()
    end
end

-------------------------------------------------------------------------------
-- CATALOG Functions Supporting Catalog UI
-------------------------------------------------------------------------------

function UFO_CatalogScrollPane_DoUpdate(scrollPane)--
    for i = 1, #scrollPane.buttons do
        local button = scrollPane.buttons[i]
        if button:IsMouseOver() then
            if button.name then
                button.DeleteButton:Show()
                button.EditButton:Show()
            else
                button.DeleteButton:Hide()
                button.EditButton:Hide()
            end
            button.HighlightBar:Show()
        else
            button.DeleteButton:Hide()
            button.EditButton:Hide()
            button.HighlightBar:Hide()
        end
    end
end

function updateCatalog()
    local flyouts = getFlyoutsConfig()
    local flyoutsCount = #flyouts + 1
    HybridScrollFrame_Update(UIUFO_CatalogScrollPane, flyoutsCount * EQUIPMENTSET_BUTTON_HEIGHT + 20, UIUFO_CatalogScrollPane:GetHeight()) -- TODO: is this the source of the too-tall bug

    local scrollOffset = HybridScrollFrame_GetOffset(UIUFO_CatalogScrollPane)
    local buttons = UIUFO_CatalogScrollPane.buttons
    local selectedIdx = UIUFO_CatalogScrollPane.selectedIdx
    UIUFO_FlyoutMenuForCatalog:Hide()
    local texture, button, flyout
    for i = 1, #buttons do
        local pos = i+scrollOffset
        if pos <= flyoutsCount then
            button = buttons[i]
            buttons[i]:Show()
            button:Enable()

            if pos < flyoutsCount then
                -- Normal flyout button
                button.name = pos
                button.text:SetText(button.name);
                button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
                flyout = getFlyoutConfig(pos)
                texture = flyout.icon

                if not texture and flyout.actionTypes[1] then
                    texture = getTexture(flyout.actionTypes[1], flyout.spells[1], flyout.pets[1])
                end
                if texture then
                    if(type(texture) == "number") then
                        button.icon:SetTexture(texture);
                    else
                        button.icon:SetTexture("INTERFACE\\ICONS\\"..texture);
                    end
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                if selectedIdx and (pos == selectedIdx) then
                    button.SelectedBar:Show()
                    button.Arrow:Show()
                    UIUFO_FlyoutMenuForCatalog.parent = button
                    UIUFO_FlyoutMenuForCatalog:updateFlyoutMenuForCatalog(pos)
                    UIUFO_FlyoutMenuForCatalog:Show()
                else
                    button.SelectedBar:Hide()
                    button.Arrow:Hide()
                end

                button.icon:SetSize(36, 36)
                button.icon:SetPoint("LEFT", 4, 0)
            else
                -- This is the Add New button
                button.name = nil
                button.text:SetText(L10N["NEW_FLYOUT"])
                button.text:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
                button.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus")
                button.icon:SetSize(30, 30)
                button.icon:SetPoint("LEFT", 7, 0)
                button.SelectedBar:Hide()
                button.Arrow:Hide()
            end

            if (pos) == 1 then
                buttons[i].BgTop:Show()
                buttons[i].BgMiddle:SetPoint("TOP", buttons[i].BgTop, "BOTTOM")
            else
                buttons[i].BgTop:Hide()
                buttons[i].BgMiddle:SetPoint("TOP")
            end

            if (pos) == flyoutsCount then
                buttons[i].BgBottom:Show()
                buttons[i].BgMiddle:SetPoint("BOTTOM", buttons[i].BgBottom, "TOP")
            else
                buttons[i].BgBottom:Hide()
                buttons[i].BgMiddle:SetPoint("BOTTOM")
            end

            if (pos)%2 == 0 then
                buttons[i].Stripe:SetTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b)
                buttons[i].Stripe:SetAlpha(0.1)
                buttons[i].Stripe:Show()
            else
                buttons[i].Stripe:Hide()
            end
        else
            buttons[i]:Hide()
        end
    end

end
