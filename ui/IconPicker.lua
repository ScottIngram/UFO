-- IconPicker
-- methods and functions for the icon picker popup in the Catalog

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class IconPicker -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local IconPicker = {
    ufoType = "IconPicker",
    macroMax = 999,
}
Ufo.IconPicker = IconPicker

-- export to the global namespace (via ExportToGlobal) so it's available to ui.xml
GLOBAL_IconPicker = IconPicker

--UfoIconPickerMixin

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function IconPicker:open(name, icon)
    self.iconX = icon
    zebug.error:name("SetSelection"):print("Yeehaw!")
    --UIUFO_IconPicker.IconSelector:selectedCallback(1,icon)

    if not icon then
        icon = DEFAULT_ICON_FULL
    end

    local i = UIUFO_IconPicker:GetIndexOfIcon(icon)
    local foo = UIUFO_IconPicker.IconSelector:GetSetupCallback()
    local bar = nil -- UIUFO_IconPicker.IconSelector:GetSelection()
    local moo = UIUFO_IconPicker.IconSelector.selectedCallback
    local cow = UIUFO_IconPicker.BorderBox.IconSelectorEditBox
    zebug.error:name("open"):print("GetIndexOfIcon",i,"foo",foo, "bar",bar, "moo",moo, "UfoIconPickerMixin",UfoIconPickerMixin, "UIUFO_IconPicker",UIUFO_IconPicker)
    --zebug.warn:line(70,"BorderBox.IconSelectorEditBox")
    --zebug.warn:dumpKeys(cow)
    --zebug.warn:line(70,"UfoIconPickerMixin")
    --zebug.warn:dumpy("UfoIconPickerMixin", UfoIconPickerMixin)
    --zebug.warn:line(70,"UIUFO_IconPicker")
    --zebug.warn:dumpy("UIUFO_IconPicker", UIUFO_IconPicker)

    --UIUFO_IconPicker.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);
    UIUFO_IconPicker.IconSelector:SetSelectedIndex(i)
    moo(i,icon)
    UIUFO_IconPicker.BorderBox.IconSelectorEditBox:SetText(name);
    --zebug.error:print("GetIndexOfIcon",i,"foo",foo, "bar",bar, "moo",moo)
end

function IconPicker:OnShow()
    self:SetSelectedIconText( "Booyah boyeeeee!")
    zebug.error:name("OnShow"):print("weee!")
    --zebug.error:name("OnShow"):line(70,"IconPicker")
    --zebug.error:name("OnShow"):dumpKeys(self)
    MacroPopupFrameMixin.OnShow(self)
    --IconSelectorPopupFrameTemplateMixin.OnShow(self);
end

function IconPicker:OnHide()
    zebug.error:name("OnHide"):print("WoOoOo!")
    --IconSelectorPopupFrameTemplateMixin:OnHide(self)
    --MacroPopupFrameMixin.OnHide(self)
end

function IconPicker:Update()
    zebug.error:name("Update"):print("Awoooga!!!")
    MacroPopupFrameMixin.Update(self)
end

function IconPicker:CancelButton_OnClick()
    zebug.error:name("CancelButton_OnClick"):print("12345 !!!")
    self:Hide();

    --local macroFrame = self:GetMacroFrame();
    --zebug.error:name("CancelButton_OnClick"):dumpKeys(macroFrame)

    --IconSelectorPopupFrameTemplateMixin.CancelButton_OnClick(self);
    --self:GetMacroFrame():UpdateButtons();
end

function IconPicker:OkayButton_OnClick()
    local pickerFrame = UIUFO_IconPicker
    local txt = pickerFrame.BorderBox.IconSelectorEditBox:GetText();
    local iconIndex = pickerFrame.IconSelector:GetSelectedIndex()
    local icon = iconIndex and pickerFrame:GetIconByIndex(iconIndex)
    if icon == DEFAULT_ICON_FULL or icon == DEFAULT_ICON_FULL_CAPS then
        icon = nil
    end

    local flyoutId = pickerFrame.flyoutId
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    flyoutDef.name = txt
    flyoutDef.icon = icon

    zebug.error:print("XXoXoXoXoX!!! txt",  txt, "iconIndex", iconIndex, "icon", icon, "flyoutId",flyoutId, "flyoutDef",flyoutDef)
    self:Hide();
    Catalog:update()
    --MacroPopupFrameMixin:OkayButton_OnClick()
end
