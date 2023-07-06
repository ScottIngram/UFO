-- Catalog
-- The catalog UI collecting the existing flyout menus letting the user create, edit, and delete them.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class Catalog -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local Catalog = {
    ufoType = "Catalog",
}
Ufo.Catalog = Catalog

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

STRIPE_COLOR = {r=0.9, g=0.9, b=1}
DEFAULT_COLOR = NORMAL_FONT_COLOR -- Bliz global
GREEN = GREEN_FONT_COLOR -- Bliz global

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- Executed on load, calls general set-up functions
function Catalog:definePopupDialogWindow()
    StaticPopupDialogs["UFO_CONFIRM_DELETE"] = {
        text = L10N.CONFIRM_DELETE,
        button1 = YES,
        button2 = NO,
        OnAccept = function (dialog) FlyoutDefsDb:delete(dialog.flyoutId); Catalog:update(); GermCommander:updateAll(); end,
        OnCancel = function (dialog) end,
        hideOnEscape = 1,
        timeout = 0,
        exclusive = 1,
        whileDead = 1,
    }
end

function Catalog:hookFrame(frame)
    -- CollectionsJournal
    -- MacroFrame
    if frame then
        frame:HookScript("OnShow", Catalog.createToggleButton)
    end
end

local toggleBtns = {}

function Catalog:createToggleButton(blizFrame)
    local blizFrameName = blizFrame:GetName()
    local btnName = "UIUFO_BtnToToggleCatalog_On".. blizFrameName
    local btnFrame = _G[btnName]
    if btnFrame then
        -- we've already made it
        return
    end
    local xBtnName = blizFrameName .."CloseButton"
    local xBtnFrame = _G[xBtnName]
    zebug.trace:print("parentName", blizFrameName, "xBtnName", xBtnName, "btnName",btnName)

    btnFrame = CreateFrame("Button", btnName, blizFrame, "UIPanelButtonTemplate")
    btnFrame:SetSize(80,22)
    btnFrame:SetPoint("RIGHT", xBtnName, "LEFT", 2, 1)
    btnFrame:SetFrameStrata(xBtnFrame:GetFrameStrata())
    btnFrame:SetFrameLevel(xBtnFrame:GetFrameLevel()+1 )
    btnFrame.Text:SetText("UFO")
    btnFrame:SetScript("OnClick", function(zelf) Catalog:toggle(zelf) end)
    btnFrame:Show()

    toggleBtns[blizFrame] = btnFrame
end

function Catalog:toggle(clickedBtn, forceOpen)
    local catalogFrame = UIUFO_Catalog
    local blizFrame = clickedBtn:GetParent()
    local blizFrameName = blizFrame:GetName()
    local oldBlizFrame = catalogFrame:GetParent()
    local isCatalogOpen = catalogFrame:IsShown()
    local willMoveCatalog = blizFrame ~= oldBlizFrame
    local willCloseCatalog = (isCatalogOpen and not willMoveCatalog)
    if forceOpen then
        willCloseCatalog = false
    end

    zebug.trace:print("parentName", blizFrameName, "oldParent name", oldBlizFrame:GetName(), "isCatalogOpen",isCatalogOpen, "willMoveCatalog", willMoveCatalog, "willCloseCatalog", willCloseCatalog )

    local xOffSet = 0
    if blizFrame == SpellBookFrame then
        -- accommodate those tabs down the side...
        -- because they aren't already included in the width?!?!  Facepalm.
        xOffSet = 35
    end

    if willCloseCatalog then
        SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth())
        catalogFrame:Hide()
    end

    if (willMoveCatalog and isCatalogOpen) or willCloseCatalog then
        SetUIPanelAttribute(oldBlizFrame, "width", oldBlizFrame:GetWidth())
    end

    if willMoveCatalog then
        SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth() +150)
        catalogFrame:SetParent(blizFrame)
        catalogFrame:SetPoint("TOPLEFT", blizFrameName, "TOPRIGHT", xOffSet, -15)
        catalogFrame:SetPoint("BOTTOMLEFT", blizFrameName, "BOTTOMRIGHT", xOffSet, -5)
    end

    if not willCloseCatalog then
        SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth() +150)
        catalogFrame:Show()
    end

    -- tell the UI to update window positions
    UpdateUIPanelPositions(blizFrame)
    if willMoveCatalog then
        UpdateUIPanelPositions(oldBlizFrame)
    end
end

function Catalog:update()
    local flyoutsCount = FlyoutDefsDb:howMany()
    local theAddButton = flyoutsCount + 1
    local scrollPane = UIUFO_CatalogScrollPane
    HybridScrollFrame_Update(scrollPane, theAddButton * EQUIPMENTSET_BUTTON_HEIGHT + 20, scrollPane:GetHeight())
    local scrollOffset = HybridScrollFrame_GetOffset(scrollPane) -- how many buttons have scrolled up out of sight
    local visibleBtnFrames = scrollPane.buttons -- how many buttons are actually onscreen (or almost onscreen)
    local selectedIdx = scrollPane.selectedIdx

    zebug.trace:out(25,"[]", "flyoutsCount",flyoutsCount)

    ---@type FlyoutMenu
    local flyoutMenu = UIUFO_FlyoutMenuForCatalog
    flyoutMenu:Hide()

    for i = 1, #visibleBtnFrames do
        ---@type number
        local flyoutIndex = i+scrollOffset
        local btnFrame = visibleBtnFrames[i]
        if flyoutIndex <= theAddButton then
            btnFrame:Show()
            btnFrame:Enable()

            zebug:line(30,"i",i, "flyoutIndex",flyoutIndex)

            if flyoutIndex < theAddButton then
                -- Normal flyout button
                local flyoutDef = FlyoutDefsDb:getByIndex(flyoutIndex)
                ---@type string
                local flyoutId = flyoutDef.id
                zebug:print("i",i, "flyoutIndex",flyoutIndex, "flyoutId",flyoutId)

                btnFrame.name = flyoutIndex
                btnFrame.label = flyoutIndex
                btnFrame.flyoutId = flyoutId
                btnFrame.text:SetText(flyoutIndex);
                btnFrame.text:SetTextColor(DEFAULT_COLOR.r, DEFAULT_COLOR.g, DEFAULT_COLOR.b);

                zebug:print("flyoutIndex",flyoutIndex, "btnFrame.flyoutId",btnFrame.flyoutId, "flyoutDef",flyoutDef)
                local icon = flyoutDef:getIcon()

                if icon then
                    if(type(icon) == "number") then
                        btnFrame.icon:SetTexture(icon);
                    else
                        btnFrame.icon:SetTexture("INTERFACE\\ICONS\\".. icon);
                    end
                else
                    btnFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                if selectedIdx and (flyoutIndex == selectedIdx) then
                    btnFrame.SelectedBar:Show()
                    btnFrame.Arrow:Show()
                    flyoutMenu.parent = btnFrame
                    flyoutMenu:updateForCatalog(flyoutId)
                    flyoutMenu:Show()
                else
                    btnFrame.SelectedBar:Hide()
                    btnFrame.Arrow:Hide()
                end

                btnFrame.icon:SetSize(36, 36)
                btnFrame.icon:SetPoint("LEFT", 4, 0)
            else
                -- This is the Add New button
                btnFrame.name = nil
                btnFrame.label = nil
                btnFrame.text:SetText(L10N.NEW_FLYOUT)
                btnFrame.text:SetTextColor(GREEN.r, GREEN.g, GREEN.b)
                btnFrame.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus")
                btnFrame.icon:SetSize(30, 30)
                btnFrame.icon:SetPoint("LEFT", 7, 0)
                btnFrame.SelectedBar:Hide()
                btnFrame.Arrow:Hide()
            end

            if (flyoutIndex) == 1 then
                btnFrame.BgTop:Show()
                btnFrame.BgMiddle:SetPoint("TOP", btnFrame.BgTop, "BOTTOM")
            else
                btnFrame.BgTop:Hide()
                btnFrame.BgMiddle:SetPoint("TOP")
            end

            if (flyoutIndex) == theAddButton then
                btnFrame.BgBottom:Show()
                btnFrame.BgMiddle:SetPoint("BOTTOM", btnFrame.BgBottom, "TOP")
            else
                btnFrame.BgBottom:Hide()
                btnFrame.BgMiddle:SetPoint("BOTTOM")
            end

            if (flyoutIndex)%2 == 0 then
                btnFrame.Stripe:SetTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b)
                btnFrame.Stripe:SetAlpha(0.1)
                btnFrame.Stripe:Show()
            else
                btnFrame.Stripe:Hide()
            end
        else
            btnFrame:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting Catalog XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_CatalogScrollPane_OnLoad(scrollPane)
    HybridScrollFrame_OnLoad(scrollPane)
    scrollPane.update = Catalog.update
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogFlyoutOptionsMouseOver")
end

function GLOBAL_UIUFO_CatalogScrollPane_OnShow(scrollPane)
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogFlyoutOptionsMouseOver")
    Catalog:update()
end

function GLOBAL_UIUFO_CatalogScrollPane_OnHide(scrollPane)
    UIUFO_DetailerPopup:Hide()
    UIUFO_FlyoutMenuForCatalog:Hide()
end

function GLOBAL_UIUFO_BlizCompartment_OnClick(addonName, whichMouseButton)
    zebug.trace:print("addonName",addonName, "whichMouseButton", whichMouseButton, "SpellBookFrame",SpellBookFrame)

    local anyOpenBlizFrame
    for blizFrame, _ in pairs(toggleBtns) do
        if blizFrame:IsShown() then
            if not anyOpenBlizFrame then
                anyOpenBlizFrame = blizFrame
            end
        end
    end

    if not anyOpenBlizFrame then
        ToggleSpellBook("spell")
        anyOpenBlizFrame = SpellBookFrame
    end

    zebug.trace:dump(toggleBtns)
    local toggleBtn = toggleBtns[anyOpenBlizFrame]
    Catalog:toggle(toggleBtn, true)
end

function GLOBAL_Any_BtnToToggleCatalog_OnClick(anyBtnToToggleCatalog)
    Catalog:toggle(anyBtnToToggleCatalog)
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

function GLOBAL_UIUFO_CatalogFlyoutOptionsDetailerBtn_OnClick(editBtn, whichMouseButton, down)
    local scrollPane = UIUFO_CatalogScrollPane
    local popup = UIUFO_DetailerPopup
    if editBtn.name and editBtn.name ~= "" then
        if scrollPane.selectedIdx == editBtn.name then
            scrollPane.selectedIdx = nil
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)		-- inappropriately named, but a good sound.
            scrollPane.selectedIdx = editBtn.name
        end
        Catalog:update()
        popup:Hide()
    else
        -- This is the "New" button
        popup:Show()
        scrollPane.selectedIdx = nil
        Catalog:update()
    end
end

function UFO_CatalogScrollPane_DoUpdate(scrollPane)
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

function GLOBAL_UIUFO_CatalogFlyoutOptionsMouseOverDeleteButton_OnClick(deleteBtnFrame)
    local parent = deleteBtnFrame:GetParent()
    local popupLabel = parent.label
    local dialog = StaticPopup_Show("UFO_CONFIRM_DELETE", popupLabel);
    if dialog then
        local flyoutId = parent.flyoutId
        dialog.flyoutId = flyoutId
    else
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
    end
end

function GLOBAL_UIUFO_CatalogFlyoutOptionsMouseOverEditButton_OnClick(editBtnFrame)
    local parent = editBtnFrame:GetParent()
    local popup = UIUFO_DetailerPopup
    GLOBAL_UIUFO_CatalogFlyoutOptionsDetailerBtn_OnClick(parent);
    popup:Show();
    popup.isEdit = true;
    popup.flyoutId = parent.flyoutId;
    local itemTexture = parent.icon:GetTexture()
    itemTexture = string.upper(string.sub(itemTexture, string.len("INTERFACE\\ICONS\\") + 1));
    GLOBAL_UIUFO_RecalculateDetailerPopup(itemTexture);
end
