-- Catalog
-- The catalog UI collecting the existing flyout menus letting the user create, edit, and delete them.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

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
        text = L10N.CONFIRM_DELETE,
        button1 = YES,
        button2 = NO,
        OnAccept = function (dialog) FlyoutMenusDb:delete(dialog.flyoutId); updateCatalog(); GermCommander:updateAll(); end,
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
    debug.trace:out(X,X,"Catalog:createToggleButton() HEAD", "parentName", blizFrameName, "xBtnName", xBtnName, "btnName",btnName)

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

    debug.trace:out(X,X,"Catalog:open()", "parentName", blizFrameName, "oldParent name", oldBlizFrame:GetName(), "isCatalogOpen",isCatalogOpen, "willMoveCatalog", willMoveCatalog, "willCloseCatalog", willCloseCatalog )

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

function updateCatalog()
    local flyoutsCount = FlyoutMenusDb:howMany()
    local numRows = flyoutsCount + 1
    HybridScrollFrame_Update(UIUFO_CatalogScrollPane, numRows * EQUIPMENTSET_BUTTON_HEIGHT + 20, UIUFO_CatalogScrollPane:GetHeight())

    local scrollOffset = HybridScrollFrame_GetOffset(UIUFO_CatalogScrollPane)
    local buttons = UIUFO_CatalogScrollPane.buttons
    local selectedIdx = UIUFO_CatalogScrollPane.selectedIdx

    ---@type FlyoutMenu
    local flyoutMenu = UIUFO_FlyoutMenuForCatalog
    flyoutMenu:Hide()

    for i = 1, #buttons do
        local pos = i+scrollOffset
        if pos <= numRows then
            local button = buttons[i]
            buttons[i]:Show()
            button:Enable()

            if pos < numRows then
                -- Normal flyout button
                button.name = pos
                button.flyoutId = pos
                button.text:SetText(pos);
                button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);

                debug:out("U",3,"updateCatalog()", "pos",pos)
                local flyoutMenuDef = FlyoutMenusDb:get(pos)
                debug:out("U",3,"updateCatalog()", "pos",pos, "flyoutMenuDef", flyoutMenuDef)
                local icon = flyoutMenuDef:getIcon()

                if icon then
                    if(type(icon) == "number") then
                        button.icon:SetTexture(icon);
                    else
                        button.icon:SetTexture("INTERFACE\\ICONS\\".. icon);
                    end
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                if selectedIdx and (pos == selectedIdx) then
                    button.SelectedBar:Show()
                    button.Arrow:Show()
                    flyoutMenu.parent = button
                    flyoutMenu:updateForCatalog(pos)
                    flyoutMenu:Show()
                else
                    button.SelectedBar:Hide()
                    button.Arrow:Hide()
                end

                button.icon:SetSize(36, 36)
                button.icon:SetPoint("LEFT", 4, 0)
            else
                -- This is the Add New button
                button.name = nil
                button.text:SetText(L10N.NEW_FLYOUT)
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

            if (pos) == numRows then
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

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting Catalog XML Callbacks
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
    local catalogFrame = UIUFO_Catalog
    debug.trace:out("~",3,"UIUFO_BlizCompartment_OnClick","addonName",addonName, "whichMouseButton", whichMouseButton, "SpellBookFrame",SpellBookFrame)

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

    debug.trace:dump(toggleBtns)
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
