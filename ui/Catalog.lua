-- Catalog
-- The catalog UI collecting the existing flyout menus letting the user create, edit, and delete them.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = MouseRat.zebug
local Bliz = _G

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
        button1 = Bliz.YES,
        button2 = Bliz.NO,
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

    btnFrame = Bliz.CreateFrame(FrameType.BUTTON, btnName, parentFrame, "UIPanelButtonTemplate")
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
function Catalog:clickUfoButton(mouseClick, force)
    zebug.info:print("ufoBtn", self.GetName and self:GetName(), "mouseClick",mouseClick, "force", force)

    if mouseClick == MouseClick.LEFT then
        if force then
            Catalog:open()
        else
            Catalog:toggle(self)
        end
    else
        Config:toggle()
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
    if blizFrame == Bliz.SpellBookFrame then
        -- accommodate those tabs down the side...
        -- because they aren't already included in the width?!?!  Facepalm.
        xOffSet = 35
    end

    if willCloseCatalog then
        Bliz.SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth())
        catalogFrame:Hide()
    end

    if (willMoveCatalog and isCatalogOpen) or willCloseCatalog then
        Bliz.SetUIPanelAttribute(oldBlizFrame, "width", oldBlizFrame:GetWidth())
    end

    if willMoveCatalog then
        catalogFrame:Hide()
        Bliz.SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth() +150)
        catalogFrame:SetParent(blizFrame)
        catalogFrame:ClearAllPoints() -- required to avoid error: Action[SetPoint] failed because[SetPoint would result in anchor family connection]
        catalogFrame:SetPoint(Anchor.TOPLEFT, blizFrame, Anchor.TOPRIGHT, xOffSet, -15)
        catalogFrame:SetPoint(Anchor.BOTTOMLEFT, blizFrame, Anchor.BOTTOMRIGHT, xOffSet, -5)
    end

    if not willCloseCatalog then
        Bliz.SetUIPanelAttribute(blizFrame, "width", blizFrame:GetWidth() +150)
        catalogFrame:Show()
    end

    -- tell the UI to update window positions
    Bliz.UpdateUIPanelPositions(blizFrame)
    if willMoveCatalog then
        Bliz.UpdateUIPanelPositions(oldBlizFrame)
    end
end

local NO_EVENT = Event:new(Catalog, "Misc Update")

function Catalog:update(event)
    event = event or NO_EVENT
    local scrollPane = UFO_CatalogScrollPane
    local flyoutsCount = FlyoutDefsDb:howMany()
    local theAddButton = flyoutsCount + 1
    Bliz.HybridScrollFrame_Update(scrollPane, theAddButton * Bliz.EQUIPMENTSET_BUTTON_HEIGHT + 20, scrollPane:GetHeight())
    local scrollOffset = Bliz.HybridScrollFrame_GetOffset(scrollPane) -- how many buttons have scrolled up out of sight
    local visibleBtnFrames = scrollPane.buttons -- how many buttons are actually onscreen (or almost onscreen)
    local selectedIdx = scrollPane.selectedIdx

    --local flyoutIdOnTheMouse = GermCommander:getFlyoutIdFromCursor()
    local flyoutDefOnTheMouse = MrUfo:isOnCursor()
    local isDragging = flyoutDefOnTheMouse and btnUnderTheMouse
    local hoverIndex = isDragging and tonumber(btnUnderTheMouse.flyoutIndex) -- this can be nil if hovering over the Add+ button

    zebug.info:event(event):print("flyoutsCount",flyoutsCount, "on the mouse", flyoutDefOnTheMouse, "newMouseOver", btnUnderTheMouse and btnUnderTheMouse.flyoutIndex, "isDragging",isDragging )

    ---@type FlyoutMenu
    local flyoutMenu = UFO_FlyoutMenuForCatalog
    flyoutMenu:Hide()
    flyoutMenu:SetParent(UFO_Catalog) -- seemingly, I can't attach it to the btnFrame becoz then it's invisible despite visible==true
    flyoutMenu:SetFrameStrata(FrameStrata.HIGH) -- altho set in the XML, this value gets clobbered somehow somewhere.

    for i = 1, #visibleBtnFrames do
        ---@type number
        local row = i+scrollOffset
        local btnFrame = visibleBtnFrames[i]
        zebug.trace:mark(Mark.HEALER):event(event):print("i",i, "row", row)
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

                zebug.trace:event(event):owner(flyoutDef):print("flyoutIndex", row, "btnFrame.flyoutId",btnFrame.flyoutId)

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
                        flyoutMenu:redrawIfConfigChanged(event)
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
    MrUfo:clearCursor()
    MrUfo:deleteMacroVessel()
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
        Bliz.PlayerSpellsUtil.ToggleSpellBookFrame()
        anyOpenBlizFrame = Bliz.SpellBookFrame or Bliz.PlayerSpellsFrame
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

    if Bliz.GetCVar("UberTooltips") == "1" then
        Bliz.GameTooltip_SetDefaultAnchor(GameTooltip, btnInCatalog)
    else
        Bliz.GameTooltip:SetOwner(btnInCatalog, TooltipAnchor.LEFT)
    end

    Bliz.GameTooltip:SetText(label)
end

function Catalog:addNewFlyout(name, icon)
    local flyoutDef = FlyoutDefsDb:appendNewOne()
    flyoutDef.name = name
    flyoutDef.icon = icon
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting Catalog XML Callbacks
-------------------------------------------------------------------------------

Catalog.ScrollPane = {}
_G.UFO_CatalogScrollPaneMixin = Catalog.ScrollPane

function Catalog.ScrollPane:OnLoad()
    local catalog = self:GetParent()
    self.scrollBar.doNotHide  = 1;
    self:SetFrameLevel(catalog.inset:GetFrameLevel()+1);
    Bliz.HybridScrollFrame_OnLoad(self)
    self.update = function()
        Catalog:update("Bliz_CatalogScrollPane_OnLoad_Callback")
    end
    Bliz.HybridScrollFrame_CreateButtons(self, "UFO_CatalogEntry")
end

function Catalog.ScrollPane:OnShow()
    local volumeCutoff = Ufo:getEventVolume("CatalogScrollPane:OnShow")
    zebug.info:name("handler"):newEvent("CatalogScrollPane", "OnShow", nil, volumeCutoff):run(function(event)
        Bliz.HybridScrollFrame_CreateButtons(self, "UFO_CatalogEntry")
        Catalog:update(event)
    end)
end

function Catalog.ScrollPane:OnHide()
    IconPicker:Hide()
end

-------------------------------------------------------------------------------
-- CatalogEntry class
-------------------------------------------------------------------------------

Catalog.Entry = {}
_G.UFO_MIXIN_FOR_CatalogEntry = Catalog.Entry -- export to global name space via ExportToGlobal.lua

function Catalog.Entry:OnLoad()
    local event = Event:new(self, "CatalogEntry_OnLoad")
    zebug.info:event(event):owner(self):print("load catalog entry", self:GetName())
    self:RegisterForDrag("LeftButton");
    Bliz.SetClampedTextureRotation(self.BgBottom, 180);
    Bliz.SetClampedTextureRotation(self.Arrow, 90);

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

function Catalog.Entry:initFlyoutMenu(event)
    self.flyoutMenu = UFO_FlyoutMenuForCatalog
    self.flyoutMenu:SetParent(self)
    --self.flyoutMenu:applyConfigForGerm(self, event)
    --self:SetPopup(self.flyoutMenu) -- put my FO where Bliz expects it
    self.flyoutMenu.isForGerm = false
    self.flyoutMenu.isForCatalog = true
    return self.flyoutMenu
end

function Catalog.Entry:getDirection()
    return "RIGHT"
end

function Catalog.Entry:initConfigOptsForEventHandlers()
    Config:includeOptsForEventHandlers("CatalogEntry:OnLeave")
    Config:includeOptsForEventHandlers("CatalogEntry:OnEnter")
    Config:includeOptsForEventHandlers("CatalogEntry:OnDragStart")
    Config:includeOptsForEventHandlers("CatalogEntry:OnClick")
    Config:includeOptsForEventHandlers("CatalogEntryButtons:OnShow")
    Config:includeOptsForEventHandlers("CatalogScrollPane:OnShow")
end

function Catalog.Entry:OnLeave()
    if (self.deleteButton:IsMouseOver() or self.editButton:IsMouseOver()) then
        return
    end

    local volumeCutoff = Ufo:getEventVolume("CatalogEntry:OnLeave")
    zebug.info:mark(Mark.TANK):owner(self):name("handler"):newEvent(self, "OnLeave", nil, volumeCutoff):run(function(event)
        self.deleteButton:Hide()
        self.editButton:Hide()
        self.HighlightBar:Hide()
        zebug.error:mark(Mark.INFO):event(event):owner(self):name("handler"):print("name",self:GetName(), "IsMouseOver",self:IsMouseOver())
        Bliz.GameTooltip_Hide()
        btnUnderTheMouse = nil
        Catalog:update(event)
        GermCommander:forEachGermWithFlyoutId(self.flyoutId, Germ.glowStop)
    end)
end

function Catalog.Entry:OnEnter()
    local volumeCutoff = Ufo:getEventVolume("CatalogEntry:OnEnter")
    zebug.info:mark(Mark.TANK):name("handler"):newEvent(self, "OnEnter", nil, volumeCutoff):run(function(event)
        if self.name == ADD_BUTTON_NAME then
            self.deleteButton:Hide()
            self.editButton:Hide()
        else
            self.deleteButton:Show()
            self.editButton:Show()
        end
        self.HighlightBar:Show()

        local flyoutDef = MrUfo:getFromCursor()

        if flyoutDef then
            Bliz.PlaySound(Bliz.SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            zebug.info:event(event):print("entering button with drag", self.flyoutIndex, "flyoutId", flyoutDef)
        end

        Catalog:setToolTip(self)
        btnUnderTheMouse = self
        Catalog:update(event)
        GermCommander:forEachGermWithFlyoutId(self.flyoutId, Germ.glowStart)
    end)
end

function Catalog.Entry:OnDragStart()
    local volumeCutoff = Ufo:getEventVolume("CatalogEntry:OnDragStart")
    zebug.info:newEvent(self, "OnDragStart", nil, volumeCutoff):mark(Mark.DPS):name("handler"):run(function(event)
        local flyoutId = self.flyoutId
        flyoutIndexOnTheMouse = self.flyoutIndex
        if exists(flyoutId) then
            MrUfo:pickupFlyoutId(flyoutId)
        end
        local scrollPane = self:GetParent():GetParent()
        scrollPane.selectedIdx = nil
        btnUnderTheMouse = self
        btnOnTheMouse = self
        self.editButton:Hide()
        self.deleteButton:Hide()
        Catalog:update(event)
    end)
end

function Catalog.Entry:OnClick(mouseClick, down)
    local volumeCutoff = Ufo:getEventVolume("CatalogEntry:OnClick")
    zebug.info:mark(Mark.SWORD):name("handler"):newEvent(self, "OnClick", nil, volumeCutoff):run(function(event)
        zebug.info:event(event):name("CatalogEntry:OnClick"):print("btnInCatalog.flyoutIndex", self.flyoutIndex,"btnInCatalog.name", self.name)
        local scrollPane = UFO_CatalogScrollPane

        if ADD_BUTTON_NAME == self.name then
            Catalog:selectRow(nil, event)
            IconPicker:open()
        elseif LANDING_BUTTON_NAME == self.name then
            local flyoutDefOnTheCursor = MrUfo:getFromCursor()
            local isDragging = flyoutDefOnTheCursor and btnUnderTheMouse
            zebug.info:event(event):name("GLOBAL_UFO_CatalogEntryButton_OnClick"):print("on cursor", flyoutDefOnTheCursor, "isDragging",isDragging)
            FlyoutDefsDb:move(flyoutDefOnTheCursor.id, self.flyoutIndex)
            btnUnderTheMouse = nil
            flyoutIndexOnTheMouse = nil
            btnOnTheMouse = nil
            Catalog:clearProxyAndCursor("CatalogEntryButton_OnClick()")
            Catalog:update(event)
            Bliz.PlaySound(1202) -- PutDownCloth_Leather01
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
            Catalog:selectRow(row, event)
        end
    end)
end

-------------------------------------------------------------------------------
-- CatalogEntry class
-------------------------------------------------------------------------------

Catalog.Entry.Buttons = {}
_G.UFO_MIXIN_FOR_CatalogEntryButtons = Catalog.Entry.Buttons -- export to global name space via ExportToGlobal.lua

function Catalog.Entry.Buttons:OnShow()
    local volumeCutoff = Ufo:getEventVolume("CatalogEntryButtons:OnShow")
    zebug.info:mark(Mark.TANK):name("handler"):newEvent("CatalogEntryEdDelBtns", "OnShow", nil, volumeCutoff):run(function(event)
        if MrUfo:getFromCursor() then
            self:Hide()
        else
            Catalog:update(event)
        end
    end)
end

function Catalog.Entry.Buttons:OnClickDelete()
    local btnInCatalog = self:GetParent()
    local popupLabel = btnInCatalog.label
    local dialog = Bliz.StaticPopup_Show("UFO_CONFIRM_DELETE", popupLabel);
    if dialog then
        local flyoutId = btnInCatalog.flyoutId
        dialog.flyoutId = flyoutId
    else
        Bliz.UIErrorsFrame:AddMessage(Bliz.ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
    end
end

function Catalog.Entry.Buttons:OnClickEdit()
    local btnInCatalog = self:GetParent()
    IconPicker:open(btnInCatalog)
    Catalog:selectRow(btnInCatalog.flyoutIndex, "CatalogEntryEditButton_OnClick")

    -- example code for getting the displayed icon as set by the 1st button on the flyout
    --local itemTexture = btnInCatalog.icon:GetTexture()
    --itemTexture = string.upper(string.sub(itemTexture, string.len("INTERFACE\\ICONS\\") + 1));
end

-------------------------------------------------------------------------------
-- Bliz addon compartment menu
-------------------------------------------------------------------------------

---@param mouseClick MouseClick
function GLOBAL_UFO_BlizCompartment_OnClick(addonName, mouseClick)
    Catalog:clickUfoButton(mouseClick, true)
end

local muhToolTip
function GLOBAL_UFO_BlizCompartment_OnEnter(addonName, menuButtonFrame)
    zebug.trace:print("addonName",addonName, "menuButtonFrame", menuButtonFrame:GetName())
    Bliz.GameTooltip:SetOwner(menuButtonFrame, TooltipAnchor.LEFT);
    if not muhToolTip then
        muhToolTip = sprintf(
                "%s \r\r %s - %s \r %s - %s",
                ADDON_NAME,
                zebug.trace:colorize(L10N.LEFT_CLICK), zebug.info:colorize(L10N.OPEN_CATALOG),
                zebug.trace:colorize(L10N.RIGHT_CLICK), zebug.info:colorize(L10N.OPEN_CONFIG)
        )
    end
    Bliz.GameTooltip:SetText(muhToolTip);
end

function GLOBAL_UFO_BlizCompartment_OnLeave(addonName, menuButtonFrame)
    zebug.trace:print("addonName",addonName, "menuButtonFrame", menuButtonFrame:GetName())
    GameTooltip_Hide();
end
