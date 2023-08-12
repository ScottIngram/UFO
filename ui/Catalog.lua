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

local flyoutIndexOnTheMouse
local btnUnderTheMouse
local btnOnTheMouse

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local STRIPE_COLOR = {r=0.9, g=0.9, b=1}
local DEFAULT_COLOR = NORMAL_FONT_COLOR -- Bliz global
local GREEN = GREEN_FONT_COLOR -- Bliz global
local BLUE = BRIGHTBLUE_FONT_COLOR -- Bliz global
local ADD_BUTTON_NAME = "ADD_BUTTON_NAME"
local LANDING_BUTTON_NAME = "LANDING_BUTTON_NAME"

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
        catalogFrame:Hide()
        SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth() +150)
        catalogFrame:SetParent(blizFrame)
        catalogFrame:ClearAllPoints() -- required to avoid error: Action[SetPoint] failed because[SetPoint would result in anchor family connection]
        catalogFrame:SetPoint("TOPLEFT", blizFrame, "TOPRIGHT", xOffSet, -15)
        catalogFrame:SetPoint("BOTTOMLEFT", blizFrame, "BOTTOMRIGHT", xOffSet, -5)
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
    local scrollPane = UIUFO_CatalogScrollPane
    local flyoutsCount = FlyoutDefsDb:howMany()
    local theAddButton = flyoutsCount + 1
    HybridScrollFrame_Update(scrollPane, theAddButton * EQUIPMENTSET_BUTTON_HEIGHT + 20, scrollPane:GetHeight())
    local scrollOffset = HybridScrollFrame_GetOffset(scrollPane) -- how many buttons have scrolled up out of sight
    local visibleBtnFrames = scrollPane.buttons -- how many buttons are actually onscreen (or almost onscreen)
    local selectedIdx = scrollPane.selectedIdx

    local flyoutIdOnTheMouse = GermCommander:getFlyoutIdFromCursor()
    local isDragging = flyoutIdOnTheMouse and btnUnderTheMouse
    local hoverIndex = isDragging and tonumber(btnUnderTheMouse.flyoutIndex) -- this can be nil if hovering over the Add+ button

    zebug.trace:print("flyoutsCount",flyoutsCount, "flyoutIdOnTheMouse", flyoutIdOnTheMouse, "newMouseOver", btnUnderTheMouse and btnUnderTheMouse.flyoutIndex, "isDragging",isDragging )

    ---@type FlyoutMenu
    local flyoutMenu = UIUFO_FlyoutMenuForCatalog
    flyoutMenu:Hide()

    for i = 1, #visibleBtnFrames do
        ---@type number
        local row = i+scrollOffset
        local btnFrame = visibleBtnFrames[i]
        zebug.trace:print("i",i, "row", row)
        if row > theAddButton then
            btnFrame:Hide()
        else
            btnFrame:Show()
            btnFrame:Enable()

            if row == theAddButton then
                -- insert the PLUS button at the bottom
                btnFrame.name = ADD_BUTTON_NAME
                btnFrame.label = nil
                btnFrame.text:SetText(L10N.NEW_FLYOUT)
                btnFrame.text:SetTextColor(GREEN.r, GREEN.g, GREEN.b)
                btnFrame.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus")
                btnFrame.icon:SetSize(30, 30)
                btnFrame.icon:SetPoint("LEFT", 7, 0)
                btnFrame.SelectedBar:Hide()
                btnFrame.Arrow:Hide()
            elseif row == hoverIndex then
                -- insert a LANDING TARGET for the user to drop the flyout they're dragging
                btnFrame.name = LANDING_BUTTON_NAME
                btnFrame.label = nil
                btnFrame.text:SetText(row)
                btnFrame.text:SetTextColor(BLUE.r, BLUE.g, BLUE.b)
                btnFrame.icon:SetTexture("Interface\\Buttons\\ButtonHilight-SquareQuickslot")
                btnFrame.icon:SetSize(36, 36)
                btnFrame.icon:SetPoint("LEFT", 4, 0)
                btnFrame.SelectedBar:Hide()
                btnFrame.Arrow:Hide()
            else
                -- if the user is moving a flyout to a new position in the catalog
                -- then offset the other flyouts to make room for it
                local flyoutIndex = row -- default to the actual row
                if hoverIndex then
                    zebug.trace:print("row",row, "hoverIndex",hoverIndex, "flyoutIndexOnTheMouse",flyoutIndexOnTheMouse)
                    if row > hoverIndex and row <= flyoutIndexOnTheMouse then
                        flyoutIndex = row - 1
                    elseif row >= flyoutIndexOnTheMouse and row < hoverIndex then
                        flyoutIndex = row + 1
                    end
                end

                local flyoutDef = FlyoutDefsDb:getByIndex(flyoutIndex)
                local flyoutId = flyoutDef.id
                local icon = flyoutDef:getIcon()

                zebug.trace:print("i",i, "flyoutIndex", row, "flyoutId",flyoutId)

                btnFrame.name = flyoutDef.name
                btnFrame.label = flyoutDef.name or row
                btnFrame.flyoutIndex = row
                btnFrame.flyoutId = flyoutId
                btnFrame.text:SetText(btnFrame.label);
                btnFrame.text:SetTextColor(DEFAULT_COLOR.r, DEFAULT_COLOR.g, DEFAULT_COLOR.b);

                zebug.trace:print("flyoutIndex", row, "btnFrame.flyoutId",btnFrame.flyoutId)

                if icon then
                    if(type(icon) == "number") then
                        btnFrame.icon:SetTexture(icon);
                    else
                        btnFrame.icon:SetTexture("INTERFACE\\ICONS\\".. icon);
                    end
                else
                    btnFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                -- Highlight the selected Flyout
                if selectedIdx and (row == selectedIdx) then
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
            end

            if (row) == 1 then
                btnFrame.BgTop:Show()
                btnFrame.BgMiddle:SetPoint("TOP", btnFrame.BgTop, "BOTTOM")
            else
                btnFrame.BgTop:Hide()
                btnFrame.BgMiddle:SetPoint("TOP")
            end

            if (row) == theAddButton then
                btnFrame.BgBottom:Show()
                btnFrame.BgMiddle:SetPoint("BOTTOM", btnFrame.BgBottom, "TOP")
            else
                btnFrame.BgBottom:Hide()
                btnFrame.BgMiddle:SetPoint("BOTTOM")
            end

            if (row)%2 == 0 then
                btnFrame.Stripe:SetTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b)
                btnFrame.Stripe:SetAlpha(0.1)
                btnFrame.Stripe:Show()
            else
                btnFrame.Stripe:Hide()
            end
        end
    end
end

function Catalog:clearProxyOnCursorChange()
    local flyoutId = GermCommander:getFlyoutIdFromCursor()
    if not flyoutId then
        if btnOnTheMouse then
            btnOnTheMouse = nil
            zebug.info:print("weeeee!")
            GermCommander:deleteProxy()
            self:update()
        end
    end
end

function Catalog:clearProxyAndCursor()
    GermCommander:deleteProxy()
    ClearCursor()
end

function Catalog:open()
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

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting Catalog XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_CatalogEntry_OnLeave(btnInCatalog)
    zebug.info:print("leaving button", btnInCatalog.flyoutIndex)
    btnUnderTheMouse = nil
    Catalog:update()
end

function GLOBAL_UIUFO_CatalogEntry_OnEnter(btnInCatalog)
    local flyoutId = GermCommander:getFlyoutIdFromCursor()

    if flyoutId then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        zebug.info:print("entering button with drag", btnInCatalog.flyoutIndex, "flyoutId", flyoutId)
    end
    btnUnderTheMouse = btnInCatalog
    Catalog:update()
end

function GLOBAL_UIUFO_CatalogEntry_OnDragStart(btnInCatalog)
    local flyoutId = btnInCatalog.flyoutId
    flyoutIndexOnTheMouse = btnInCatalog.flyoutIndex
    if exists(flyoutId) then
        FlyoutMenu:pickup(flyoutId)
    end
    local scrollPane = btnInCatalog:GetParent():GetParent()
    scrollPane.selectedIdx = nil
    btnUnderTheMouse = btnInCatalog
    btnOnTheMouse = btnInCatalog
    btnInCatalog.EditButton:Hide()
    btnInCatalog.DeleteButton:Hide()
    Catalog:update()
end

function GLOBAL_UIUFO_CatalogScrollPane_OnLoad(scrollPane)
    HybridScrollFrame_OnLoad(scrollPane)
    scrollPane.update = Catalog.update
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogEntry")
end

function GLOBAL_UIUFO_CatalogScrollPane_OnShow(scrollPane)
    HybridScrollFrame_CreateButtons(scrollPane, "UIUFO_CatalogEntry")
    Catalog:update()
end

function GLOBAL_UIUFO_CatalogScrollPane_OnHide(scrollPane)
    UIUFO_IconPicker:Hide()
    UIUFO_FlyoutMenuForCatalog:Hide()
end

function GLOBAL_UIUFO_BlizCompartment_OnClick(addonName, whichMouseButton)
    zebug.trace:print("addonName",addonName, "whichMouseButton", whichMouseButton, "SpellBookFrame",SpellBookFrame)
    Catalog:open()
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

function GLOBAL_UIUFO_CatalogEntryButton_OnClick(btnInCatalog, whichMouseButton, down)
    zebug.info:name("GLOBAL_UIUFO_CatalogEntryButton_OnClick"):print("btnInCatalog.flyoutIndex",btnInCatalog.flyoutIndex,"btnInCatalog.name",btnInCatalog.name)
    local scrollPane = UIUFO_CatalogScrollPane
    local popup = UIUFO_IconPicker

    if btnInCatalog.name == ADD_BUTTON_NAME then
        popup:Show()
        scrollPane.selectedIdx = nil
        Catalog:update()
    elseif btnInCatalog.name == LANDING_BUTTON_NAME then
        local flyoutIdOnTheMouse = GermCommander:getFlyoutIdFromCursor()
        local isDragging = flyoutIdOnTheMouse and btnUnderTheMouse
        zebug.info:name("GLOBAL_UIUFO_CatalogEntryButton_OnClick"):print("flyoutIdOnTheMouse",flyoutIdOnTheMouse, "isDragging",isDragging)
        FlyoutDefsDb:move(flyoutIdOnTheMouse, btnInCatalog.flyoutIndex)
        btnUnderTheMouse = nil
        flyoutIndexOnTheMouse = nil
        btnOnTheMouse = nil
        Catalog:clearProxyAndCursor()
        Catalog:update()
        PlaySound(1202) -- PutDownCloth_Leather01
    else
        if scrollPane.selectedIdx == btnInCatalog.flyoutIndex then
            scrollPane.selectedIdx = nil
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)		-- inappropriately named, but a good sound.
            scrollPane.selectedIdx = btnInCatalog.flyoutIndex
        end
        Catalog:update()
        popup:Hide()
    end
end

function UFO_CatalogScrollPane_DoUpdate(scrollPane)
    for i = 1, #scrollPane.buttons do
        local button = scrollPane.buttons[i]
        if button:IsMouseOver() then
            if button.name == ADD_BUTTON_NAME then
                button.DeleteButton:Hide()
                button.EditButton:Hide()
            else
                button.DeleteButton:Show()
                button.EditButton:Show()
            end
            button.HighlightBar:Show()
        else
            button.DeleteButton:Hide()
            button.EditButton:Hide()
            button.HighlightBar:Hide()
        end
    end
end

function GLOBAL_UIUFO_CatalogEntryButtonsMouseOver_OnShow(btn)
    zebug.info:name("GLOBAL_UIUFO_CatalogEntryButtonsMouseOver_OnShow"):print("btn",btn:GetName())
    if GermCommander:isDraggingProxy() then
        btn:Hide()
    else
        Catalog:update()
    end
end

function GLOBAL_UIUFO_CatalogEntryDeleteButton_OnClick(deleteBtnFrame)
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

function GLOBAL_UIUFO_CatalogEntryEditButton_OnClick(editBtnFrame)
    local btnInCatalog = editBtnFrame:GetParent()
    local iconPicker = UIUFO_IconPicker
    --GLOBAL_UIUFO_CatalogEntryButton_OnClick(btnInCatalog);
    UIUFO_FlyoutMenuForCatalog:Hide()
    iconPicker:Show();
    iconPicker.isEdit = true;
    iconPicker.flyoutId = btnInCatalog.flyoutId;
    local flyoutDef = FlyoutDefsDb:get(btnInCatalog.flyoutId)
    local icon = flyoutDef.icon

    local itemTexture = btnInCatalog.icon:GetTexture()
    --itemTexture = string.upper(string.sub(itemTexture, string.len("INTERFACE\\ICONS\\") + 1));

    --zebug.warn:line(70,"UIUFO_IconPicker")
    --zebug.error:dumpKeys(UIUFO_IconPicker)
    --zebug.warn:line(70,"IconPickerMixin")
    --zebug.warn:dumpKeys(IconPickerMixin)
    --zebug.warn:line(70,"UIUFO_IconPicker.IconSelector")
    --zebug.error:dumpKeys(UIUFO_IconPicker.IconSelector)

    IconPicker:open(btnInCatalog.name, icon)
end
