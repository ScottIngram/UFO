-- UfoMacroPopupFrameMixin
-- methods and functions for the icon popup in the Catalog

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class UfoMacroPopupFrameMixin -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local UfoMacroPopupFrameMixin = {
    ufoType = "UfoMacroPopupFrameMixin",
}
Ufo.UfoMacroPopupFrameMixin = UfoMacroPopupFrameMixin

-- export to the global namespace (via ExportToGlobal) so it's available to ui.xml
GLOBAL_UfoMacroPopupFrameMixin = UfoMacroPopupFrameMixin

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function UfoMacroPopupFrameMixin:OnShow()
    zebug.error:print("weee!")
    MacroPopupFrameMixin.OnShow(self);
end
