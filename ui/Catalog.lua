-- Catalog
-- The catalog UI collecting the existing flyout menus letting the user create, edit, and delete them.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

---@class Catalog : UfoMixIn
---@field ufoType string The classname
Catalog = {
    ufoType = "Catalog",
}
UfoMixIn:mixInto(Catalog)

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
        -- OnAccept = function (dialog) IconPicker:Hide(); FlyoutDefsDb:delete(dialog.flyoutId); Catalog:update("Catalog:acceptIcon"); GermCommander:updateAll(); end,
        OnAccept = function (dialog)
            IconPicker:Hide()
            GermCommander:nukeGermsThatHaveFlyoutIdOf(dialog.flyoutId, "Catalog: DELETE UFO")
            FlyoutDefsDb:delete(dialog.flyoutId)
            Catalog:update("Catalog:acceptIcon")
        end,
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

function Catalog:createToggleButtonIfWeCan(maybeFrame)
    if not maybeFrame then return end
    self:createToggleButton(maybeFrame)
end

function Catalog:createToggleButton(parentFrame, xBtnOverride)
    assert(parentFrame, "can't find parent frame")
    local parentFrameName = parentFrame:GetName()
    local btnName = "UFO_BtnToToggleCatalog_On".. parentFrameName
    ---@type Button
    local btnFrame = _G[btnName]
    if btnFrame then
        -- we've already made it
        return
    end
    local xBtnName = parentFrameName .."CloseButton"
    local xBtnFrame = parentFrame.MaximizeMinimizeButton or _G[xBtnName]
    zebug.trace:print("parentName", parentFrameName, "xBtnName", xBtnName, "btnName",btnName, "blizFrame.MaximizeMinimizeButton", parentFrame.MaximizeMinimizeButton)

    btnFrame = CreateFrame(FrameType.BUTTON, btnName, parentFrame, "UIPanelButtonTemplate")
    btnFrame:SetSize(80,22)
    btnFrame:SetPoint(Anchor.RIGHT, xBtnOverride or xBtnFrame, Anchor.LEFT, 2, 1)
    btnFrame:SetFrameStrata(xBtnFrame:GetFrameStrata())
    btnFrame:SetFrameLevel(xBtnFrame:GetFrameLevel()+10 )
    btnFrame.Text:SetText("UFO")
    btnFrame:RegisterForClicks("AnyUp")
    btnFrame:SetScript(Script.ON_CLICK, Catalog.clickUfoButton)
    btnFrame:SetScript(Script.ON_ENTER, Catalog.ON_ENTER)
    btnFrame:SetScript(Script.ON_LEAVE, Catalog.ON_LEAVE)
    btnFrame:Show()

    toggleBtns[parentFrame] = btnFrame
end

function Catalog:ON_LEAVE()
    self:OnLeave() -- Call Bliz super()
    GameTooltip:Hide()
end

function Catalog:ON_ENTER()
    self:OnEnter() -- Call Bliz super()
    GLOBAL_UFO_BlizCompartment_OnEnter(ADDON_NAME, self)
end

---@param mouseClick MouseClick
function Catalog:clickUfoButton(mouseClick, isDown)
    zebug.info:print("ufoBtn", self:GetName(), "mouseClick",mouseClick, "isDown",isDown)

    if mouseClick == MouseClick.LEFT then
        Catalog:toggle(self)
    else
        Settings.OpenToCategory(Ufo.myTitle)
    end
end

function Catalog:toggle(clickedBtn, forceOpen)
    if isInCombatLockdown("Configuration") then return end
    local catalogFrame = UFO_Catalog
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
        catalogFrame:SetPoint(Anchor.TOPLEFT, blizFrame, Anchor.TOPRIGHT, xOffSet, -15)
        catalogFrame:SetPoint(Anchor.BOTTOMLEFT, blizFrame, Anchor.BOTTOMRIGHT, xOffSet, -5)
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

local NO_EVENT = Event:new(Catalog, "Misc Update")

function Catalog:update(event)
    event = event or NO_EVENT
    local scrollPane = UFO_CatalogScrollPane
    local flyoutsCount = FlyoutDefsDb:howMany()
    local theAddButton = flyoutsCount + 1
    HybridScrollFrame_Update(scrollPane, theAddButton * EQUIPMENTSET_BUTTON_HEIGHT + 20, scrollPane:GetHeight())
    local scrollOffset = HybridScrollFrame_GetOffset(scrollPane) -- how many buttons have scrolled up out of sight
    local visibleBtnFrames = scrollPane.buttons -- how many buttons are actually onscreen (or almost onscreen)
    local selectedIdx = scrollPane.selectedIdx

    --local flyoutIdOnTheMouse = GermCommander:getFlyoutIdFromCursor()
    local flyoutDefOnTheMouse = UfoProxy:isFlyoutOnCursor()
    local isDragging = flyoutDefOnTheMouse and btnUnderTheMouse
    local hoverIndex = isDragging and tonumber(btnUnderTheMouse.flyoutIndex) -- this can be nil if hovering over the Add+ button

    zebug.trace:event(event):print("flyoutsCount",flyoutsCount, "on the mouse", flyoutDefOnTheMouse, "newMouseOver", btnUnderTheMouse and btnUnderTheMouse.flyoutIndex, "isDragging",isDragging )

    ---@type FlyoutMenu
    local flyoutMenu = UFO_FlyoutMenuForCatalog
    flyoutMenu:Hide()
    flyoutMenu:SetParent(UFO_Catalog) -- seemingly, I can't attach it to the btnFrame becoz then it's invisible despite visible==true
    flyoutMenu:SetFrameStrata(FrameStrata.HIGH) -- altho set in the XML, this value gets clobbered somehow somewhere.

    for i = 1, #visibleBtnFrames do
        ---@type number
        local row = i+scrollOffset
        local btnFrame = visibleBtnFrames[i]
        zebug.trace:event(event):print("i",i, "row", row)
        if row > theAddButton then
            btnFrame:Hide()
        else
            btnFrame:Show()
            btnFrame:Enable()

            if row == theAddButton then
                -- insert the PLUS button at the bottom
                btnFrame.name = ADD_BUTTON_NAME
                btnFrame.label = nil
                btnFrame.flyoutIndex = row
                btnFrame.flyoutId = nil
                btnFrame.text:SetText(L10N.NEW_FLYOUT)
                btnFrame.text:SetTextColor(GREEN.r, GREEN.g, GREEN.b)
                btnFrame.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus")
                btnFrame.icon:SetSize(30, 30)
                btnFrame.icon:SetPoint(Anchor.LEFT, 7, 0)
                btnFrame.SelectedBar:Hide()
                btnFrame.Arrow:Hide()
            elseif row == hoverIndex then
                -- insert a LANDING TARGET for the user to drop the flyout they're dragging
                btnFrame.name = LANDING_BUTTON_NAME
                btnFrame.label = nil
                btnFrame.flyoutIndex = row
                btnFrame.flyoutId = nil
                btnFrame.text:SetText(row)
                btnFrame.text:SetTextColor(BLUE.r, BLUE.g, BLUE.b)
                btnFrame.icon:SetTexture("Interface\\Buttons\\ButtonHilight-SquareQuickslot")
                btnFrame.icon:SetSize(36, 36)
                btnFrame.icon:SetPoint(Anchor.LEFT, 4, 0)
                btnFrame.SelectedBar:Hide()
                btnFrame.Arrow:Hide()
            else
                -- if the user is moving a flyout to a new position in the catalog
                -- then offset the other flyouts to make room for it
                local flyoutIndex = row -- default to the actual row
                if hoverIndex and hoverIndex ~= theAddButton and flyoutIndexOnTheMouse then
                    zebug.trace:event(event):print("row",row, "hoverIndex",hoverIndex, "flyoutIndexOnTheMouse",flyoutIndexOnTheMouse)
                    if row > hoverIndex and row <= flyoutIndexOnTheMouse then
                        flyoutIndex = row - 1
                    elseif row >= flyoutIndexOnTheMouse and row < hoverIndex then
                        flyoutIndex = row + 1
                    end
                end

                local flyoutDef = FlyoutDefsDb:getByIndex(flyoutIndex)
                local flyoutId = flyoutDef.id
                local icon = flyoutDef:getIcon()

                zebug.trace:event(event):owner(flyoutDef):print("i",i, "flyoutIndex", row, "icon",icon)

                btnFrame.name = flyoutDef.name
                btnFrame.label = flyoutDef.name or row
                btnFrame.flyoutIndex = row
                btnFrame.flyoutId = flyoutId
                btnFrame.text:SetText(btnFrame.label);
                btnFrame.text:SetTextColor(DEFAULT_COLOR.r, DEFAULT_COLOR.g, DEFAULT_COLOR.b);

                zebug.trace:event(event):print("flyoutIndex", row, "btnFrame.flyoutId",btnFrame.flyoutId)

                if icon then
                    if(type(icon) == "number") then
                        btnFrame.icon:SetTexture(icon);
                    else
                        btnFrame.icon:SetTexture(icon)
                    end
                else
                    btnFrame.icon:SetTexture(DEFAULT_ICON_FULL)
                end

                -- Highlight the selected Flyout
                if selectedIdx and (row == selectedIdx) then
                    btnFrame.SelectedBar:Show()
                    --flyoutMenu.parent = btnFrame
                    if self.renderedFlyoutId ~= flyoutId then
                        flyoutMenu:attach(btnFrame)
                        flyoutMenu:applyConfigForCatalog(flyoutId, event)
                        self.renderedFlyoutId = flyoutId
                    else
                        flyoutMenu:attach(btnFrame)
                    end
                    if IconPicker:IsShown() then
                        flyoutMenu:Hide()
                        btnFrame.Arrow:Hide()
                    else
                        flyoutMenu:Show()
                        --btnFrame.Arrow:Show() -- meh, who needs the arrow.  just easts up space
                    end
                else
                    btnFrame.SelectedBar:Hide()
                    btnFrame.Arrow:Hide()
                end

                btnFrame.icon:SetSize(36, 36)
                btnFrame.icon:SetPoint(Anchor.LEFT, 4, 0)
            end

            if (row) == 1 then
                btnFrame.BgTop:Show()
                btnFrame.BgMiddle:SetPoint(Anchor.TOP, btnFrame.BgTop, Anchor.BOTTOM)
            else
                btnFrame.BgTop:Hide()
                btnFrame.BgMiddle:SetPoint(Anchor.TOP)
            end

            if (row) == theAddButton then
                btnFrame.BgBottom:Show()
                btnFrame.BgMiddle:SetPoint(Anchor.BOTTOM, btnFrame.BgBottom, Anchor.TOP)
            else
                btnFrame.BgBottom:Hide()
                btnFrame.BgMiddle:SetPoint(Anchor.BOTTOM)
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

function Catalog:clearProxyAndCursor(event)
    Cursor:clear(event)
    UfoProxy:deleteProxyMacro(event)
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
        if PlayerSpellsUtil and PlayerSpellsUtil.ToggleSpellBookFrame then -- v11
            PlayerSpellsUtil.ToggleSpellBookFrame()
        else --v10
            ToggleSpellBook("spell")
        end
        anyOpenBlizFrame = SpellBookFrame or PlayerSpellsFrame
    end

    zebug.trace:dump(toggleBtns)
    local toggleBtn = toggleBtns[anyOpenBlizFrame]
    Catalog:toggle(toggleBtn, true)
end

function Catalog:selectRow(row, event)
    zebug.info:event(event):print("row", row)
    if row ~= UFO_CatalogScrollPane.selectedIdx then
        UFO_CatalogScrollPane.selectedIdx = row
        Catalog:update(event)
    end
end

function Catalog:setToolTip(btnInCatalog)
    local flyoutId = btnInCatalog.flyoutId
    if not flyoutId then return end

    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    local label = flyoutDef.name or flyoutDef.id

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, btnInCatalog)
    else
        GameTooltip:SetOwner(btnInCatalog, TooltipAnchor.LEFT)
    end

    GameTooltip:SetText(label)
end

function Catalog:addNewFlyout(name, icon)
    local flyoutDef = FlyoutDefsDb:appendNewOne()
    flyoutDef.name = name
    flyoutDef.icon = icon
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting Catalog XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UFO_CatalogScrollPane_OnLoad(scrollPane)
    HybridScrollFrame_OnLoad(scrollPane)
    scrollPane.update = function()
        Catalog:update("Bliz_CatalogScrollPane_OnUpdate")
    end
    HybridScrollFrame_CreateButtons(scrollPane, "UFO_CatalogEntry")
end

function GLOBAL_UFO_CatalogScrollPane_OnShow(scrollPane)
    HybridScrollFrame_CreateButtons(scrollPane, "UFO_CatalogEntry")
    Catalog:update("CatalogScrollPane_OnShow")
end

function GLOBAL_UFO_CatalogScrollPane_OnHide(scrollPane)
    IconPicker:Hide()
    -- UFO_FlyoutMenuForCatalog:Hide()
end

---@param mouseClick MouseClick
function GLOBAL_UFO_BlizCompartment_OnClick(addonName, mouseClick)
    zebug.trace:print("addonName",addonName, "mouseClick", mouseClick, "SpellBookFrame",SpellBookFrame)

    if mouseClick == MouseClick.LEFT then
        Catalog:open()
    else
        Settings.OpenToCategory(Ufo.myTitle)
    end
end

local muhToolTip
function GLOBAL_UFO_BlizCompartment_OnEnter(addonName, menuButtonFrame)
    zebug.trace:print("addonName",addonName, "menuButtonFrame", menuButtonFrame:GetName())
    GameTooltip:SetOwner(menuButtonFrame, TooltipAnchor.LEFT);
    if not muhToolTip then
        muhToolTip = sprintf(
                "%s \r\r %s - %s \r %s - %s",
                ADDON_NAME,
                zebug.trace:colorize(L10N.LEFT_CLICK), zebug.info:colorize(L10N.OPEN_CATALOG),
                zebug.trace:colorize(L10N.RIGHT_CLICK), zebug.info:colorize(L10N.OPEN_CONFIG)
        )
    end
    GameTooltip:SetText(muhToolTip);
end

function GLOBAL_UFO_BlizCompartment_OnLeave(addonName, menuButtonFrame)
    zebug.trace:print("addonName",addonName, "menuButtonFrame", menuButtonFrame:GetName())
    GameTooltip_Hide();
end


-- throttle OnUpdate because it fires as often as FPS and is very resource intensive
local C_UI_ON_UPDATE_TIMER_FREQUENCY = 0.25
local onUpdateTimerForConfigUi = 0

function GLOBAL_UFO_CatalogScrollPane_OnUpdate(scrollPane, elapsed)
    onUpdateTimerForConfigUi = onUpdateTimerForConfigUi + elapsed
    if onUpdateTimerForConfigUi < C_UI_ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    --print("GLOBAL_UFO_CatalogScrollPane_OnUpdate() UFO_CatalogScrollPane_onUpdateTimer =", onUpdateTimerForConfigUi)
    onUpdateTimerForConfigUi = 0
    UFO_CatalogScrollPane_DoUpdate(scrollPane)
end

function UFO_CatalogScrollPane_DoUpdate(scrollPane)
    for i = 1, #scrollPane.buttons do
        local button = scrollPane.buttons[i]
        if button:IsMouseOver() then
            if button.name == ADD_BUTTON_NAME then
                button.deleteButton:Hide()
                button.editButton:Hide()
            else
                button.deleteButton:Show()
                button.editButton:Show()
            end
            button.HighlightBar:Show()
        else
            button.deleteButton:Hide()
            button.editButton:Hide()
            button.HighlightBar:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- CatalogEntry class
-------------------------------------------------------------------------------

---@class CatalogEntry : UfoMixIn
---@field ufoType string The classname
CatalogEntry = {
    ufoType = "CatalogEntry",
}
UfoMixIn:mixInto(CatalogEntry)

GLOBAL_UFO_MIXIN_FOR_CatalogEntry = CatalogEntry -- export to global name space via ExportToGlobal.lua

function CatalogEntry:OnLoad()
    local event = Event:new(self, "CatalogEntry_OnLoad")
    zebug.error:event(event):owner(self):print("load catalog entry", self:GetName())
    self:RegisterForDrag("LeftButton");
    SetClampedTextureRotation(self.BgBottom, 180);
    SetClampedTextureRotation(self.Arrow, 90);

    self.flyoutMenu = self:initFlyoutMenu(event)

    --- SEC ENV BULLSHIT

if true then return end -- temp disable

    -- Secure Shenanigans required before initFlyoutMenu() -- here
    SecureHandler_OnLoad(self) -- install self:SetFrameRef()
    self:assignSecEnvMouseClickBehaviorVia_Attribute(MouseClick.ANY, SecEnv.FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME)

    -- FlyoutMenu
    self:initializeSecEnv(event)       -- depends on initFlyoutMenu() above
    self:assignAllMouseClickers(event) -- depends on initializeSecureClickers() above

end

function CatalogEntry:initFlyoutMenu(event)
    self.flyoutMenu = UFO_FlyoutMenuForCatalog
    self.flyoutMenu:SetParent(self)
    --self.flyoutMenu:applyConfigForGerm(self, event)
    --self:SetPopup(self.flyoutMenu) -- put my FO where Bliz expects it
    self.flyoutMenu.isForGerm = false
    self.flyoutMenu.isForCatalog = true
    return self.flyoutMenu
end

function CatalogEntry:getDirection()
    return "RIGHT"
end


function CatalogEntry:OnLeave()
    local event = Event:new(self, "CatalogEntry_OnLeave")
    zebug.info:print("leaving button", self.flyoutIndex)
    GameTooltip_Hide()
    btnUnderTheMouse = nil
    Catalog:update(event)
    GermCommander:forEachGermWithFlyoutId(self.flyoutId, Germ.glowStop)
end

-- TODO - handle the hover glow here and not in the update() routine
function CatalogEntry:OnEnter()
    local event = Event:new(self, "CatalogEntry_OnEnter")
    local flyoutDef = UfoProxy:isFlyoutOnCursor()

    if flyoutDef then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        zebug.info:event(event):print("entering button with drag", self.flyoutIndex, "flyoutId", flyoutDef)
    end

    Catalog:setToolTip(self)
    btnUnderTheMouse = self
    Catalog:update(event)
    GermCommander:forEachGermWithFlyoutId(self.flyoutId, Germ.glowStart)
end

function CatalogEntry:OnDragStart()
    local eventCapture
    local flyoutId = self.flyoutId
    flyoutIndexOnTheMouse = self.flyoutIndex
    if exists(flyoutId) then
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        zebug.info:mSquare():owner(flyoutDef):newEvent("CatalogEntry", "OnDragStart"):run(function(event)
            eventCapture = event
            UfoProxy:pickupUfoOntoCursor(flyoutId, event)
        end)
    end
    local scrollPane = self:GetParent():GetParent()
    scrollPane.selectedIdx = nil
    btnUnderTheMouse = self
    btnOnTheMouse = self
    self.editButton:Hide()
    self.deleteButton:Hide()
    Catalog:update(eventCapture or "CatalogEntry:OnDragStart")
end

function CatalogEntry:OnClick(mouseClick, down)
    local event = Event:new(self,"CatalogEntryButton_OnClick")
    zebug.error:event(event):name("CatalogEntry:OnClick"):print("btnInCatalog.flyoutIndex", self.flyoutIndex,"btnInCatalog.name", self.name)
    local scrollPane = UFO_CatalogScrollPane

    if ADD_BUTTON_NAME == self.name then
        Catalog:selectRow(nil, event)
        IconPicker:open()
    elseif LANDING_BUTTON_NAME == self.name then
        local flyoutDefOnTheCursor = UfoProxy:isFlyoutOnCursor()
        local isDragging = flyoutDefOnTheCursor and btnUnderTheMouse
        zebug.info:event(event):name("GLOBAL_UFO_CatalogEntryButton_OnClick"):print("on cursor", flyoutDefOnTheCursor, "isDragging",isDragging)
        FlyoutDefsDb:move(flyoutDefOnTheCursor.id, self.flyoutIndex)
        btnUnderTheMouse = nil
        flyoutIndexOnTheMouse = nil
        btnOnTheMouse = nil
        Catalog:clearProxyAndCursor("CatalogEntryButton_OnClick()")
        Catalog:update(event)
        PlaySound(1202) -- PutDownCloth_Leather01
    else
        -- A regular UFO.  Open/close it.
        local row
        local isSelected = scrollPane.selectedIdx == self.flyoutIndex
        if isSelected then
            -- if the icon picker is open, do not unselect the row.
            if IconPicker:IsShown() then
                row = self.flyoutIndex
            else
                -- unselect the row
                row = nil
            end
        else
            -- select the row
            row = self.flyoutIndex
        end
        if row then
            self.flyoutMenu:SetFrameRef("catalogEntry", self)
        end
        IconPicker:close()
        Catalog:selectRow(row, "CatalogEntry:OnClick")
    end
end

function GLOBAL_UFO_CatalogEntryButtonsMouseOver_OnShow(btn)
    zebug.info:newEvent(btn,"CatalogEntryButtonsMouseOver_OnShow"):name("CatalogEntryButtonsMouseOver_OnShow"):print("btn",btn:GetName())
    if UfoProxy:isFlyoutOnCursor() then
        btn:Hide()
    else
        Catalog:update("catalog-on-btn-mouse-over")
    end
end

function GLOBAL_UFO_CatalogEntryDeleteButton_OnClick(deleteBtnFrame)
    local btnInCatalog = deleteBtnFrame:GetParent()
    local popupLabel = btnInCatalog.label
    local dialog = StaticPopup_Show("UFO_CONFIRM_DELETE", popupLabel);
    if dialog then
        local flyoutId = btnInCatalog.flyoutId
        dialog.flyoutId = flyoutId
    else
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
    end
end

function GLOBAL_UFO_CatalogEntryEditButton_OnClick(editBtn)
    local btnInCatalog = editBtn:GetParent()
    IconPicker:open(btnInCatalog)
    Catalog:selectRow(btnInCatalog.flyoutIndex, "CatalogEntryEditButton_OnClick")

    -- example code for getting the displayed icon as set by the 1st button on the flyout
    --local itemTexture = btnInCatalog.icon:GetTexture()
    --itemTexture = string.upper(string.sub(itemTexture, string.len("INTERFACE\\ICONS\\") + 1));
end
