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
GLOBAL_IconPickerMixin = IconPicker

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

local alreadyPlayedSoundViaOnShow
local isAlreadyOpenForFlyoutId

function IconPicker:init()
    -- replace self with the fully amalgamated / instantiated mixin version so that "self" has all methods available
    Ufo.IconPicker = UIUFO_IconPicker
    IconPicker = UIUFO_IconPicker
end

function IconPicker:open(btnInCatalog)
    local flyoutId = btnInCatalog and btnInCatalog.flyoutId
    if isAlreadyOpenForFlyoutId and isAlreadyOpenForFlyoutId == flyoutId then return end

    local i, icon, name
    self:Show()
    if not alreadyPlayedSoundViaOnShow then
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    end
    alreadyPlayedSoundViaOnShow = false
    isAlreadyOpenForFlyoutId = flyoutId

    if btnInCatalog then
        self.flyoutId = flyoutId
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        icon = flyoutDef.icon or DEFAULT_ICON_FULL
        i = self:GetIndexOfIcon(icon)
        name = flyoutDef.name
    else
        self.flyoutId = nil
    end

    zebug.info:name("open"):print("name",name, "icon",icon, "GetIndexOfIcon",i)

    self.IconSelector:SetSelectedIndex(i)
    self.IconSelector.selectedCallback(i,icon)
    self.BorderBox.IconSelectorEditBox:SetText(name or "")
end

function IconPicker:OnShow()
    MacroPopupFrameMixin.OnShow(self)
    alreadyPlayedSoundViaOnShow = true
end

function IconPicker:OnHide()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    isAlreadyOpenForFlyoutId = nil
end

function IconPicker:Update()
    MacroPopupFrameMixin.Update(self)
end

function IconPicker:CancelButton_OnClick()
    self:Hide()
    Catalog:update()
end

function IconPicker:OkayButton_OnClick()
    local txt = self.BorderBox.IconSelectorEditBox:GetText();
    local iconIndex = self.IconSelector:GetSelectedIndex()
    local icon = iconIndex and self:GetIconByIndex(iconIndex)
    if icon == DEFAULT_ICON_FULL or icon == DEFAULT_ICON_FULL_CAPS then
        icon = nil
    end

    local flyoutId = self.flyoutId
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    flyoutDef.name = txt
    flyoutDef.icon = icon

    zebug.info:print("txt",txt, "iconIndex",iconIndex, "icon",icon, "flyoutId",flyoutId, "flyoutDef",flyoutDef)
    self:Hide()
    Catalog:update()
end
