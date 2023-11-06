-------------------------------------------------------------------------------
-- 3rd-Party Addon Support
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

---@class ThirdPartyAddonSupport -- IntelliJ-EmmyLua annotation
---@field isAnyActionBarAddonActive boolean
---@field ufoType string The classname
ThirdPartyAddonSupport = {
    ufoType = "ThirdPartyAddonSupport",
    isAnyActionBarAddonActive = false,
}

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@class SUPPORTED_ADDONS -- IntelliJ-EmmyLua annotation
---@field activate function
local SUPPORTED_ADDONS -- to be defined below
local warned = false
local _getParent

-------------------------------------------------------------------------------
-- Methods / Functions
-------------------------------------------------------------------------------

function ThirdPartyAddonSupport:detectSupportedAddons()
    for addon, methods in pairs(SUPPORTED_ADDONS) do
        zebug.info:print("Checking - addon",addon)
        if IsAddOnLoaded(addon) then
            msgUser(L10N.DETECTED .. " " .. addon)
            SUPPORTED_ADDONS[addon].activate()
        end
    end
end

-------------------------------------------------------------------------------
-- Action Bar Addons
-------------------------------------------------------------------------------

function ThirdPartyAddonSupport:getParent(bbInfo)
    return _getParent(bbInfo)
end

function getParentForBartender4(btnBarInfo)
    local btnSlotIndex = btnBarInfo.btnSlotIndex
    local name = "BT4Button" .. btnSlotIndex
    local parent = _G[name]
    zebug.trace:name("BARTENDER4:getParent"):print("btnSlotIndex",btnSlotIndex, "name",name, "parent",parent)
    if parent then
        -- poor-man's polymorphism
        parent.GetName = function() return name end
        parent.btnSlotIndex = btnSlotIndex
        parent.bar = {}
        parent.bar.GetSpellFlyoutDirection = function() return parent.config.flyoutDirection end
    else
        if not warned then
            msgUser(L10N.BARTENDER_BAR_DISABLED)
            warned = true
        end
    end
    return parent
end

function getParentForElvUI(btnBarInfo)
    local btnSlotIndex = btnBarInfo.btnSlotIndex
    local barName =  "ElvUI_Bar".. btnBarInfo.barNum
    local btnName = barName .."Button"..  btnBarInfo.btnNum
    local parent = _G[btnName]
    local zebugger = parent and zebug.trace or zebug.error
    zebugger:name("ElvUI:getParent"):print("btnSlotIndex",btnSlotIndex, "barNum",btnBarInfo.barNum, "barName",barName, "btnName",btnName, "parent",parent)
    if parent then
        -- poor-man's polymorphism
        --parent.GetName = function() return barName end
        --parent.btnSlotIndex = btnSlotIndex
        parent.bar = {}
        parent.bar.GetSpellFlyoutDirection = function() return parent.db.flyoutDirection end
    end
    return parent
end

function activateActionBarAddon(parentGetterFunc)
    ThirdPartyAddonSupport.isAnyActionBarAddonActive = true
    _getParent = parentGetterFunc
end

-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------

function supportLargerMacroIconSelection()
    LargerMacroIconSelection:Initialize(UIUFO_IconPicker)
end

-------------------------------------------------------------------------------
-- Constants
-- I have to put these after the function declarations due to Lua's one-pass compiler.
-------------------------------------------------------------------------------

SUPPORTED_ADDONS = {
    Bartender4 = {
        activate = function()
            activateActionBarAddon(getParentForBartender4)
        end,
    },
    ElvUI = {
        activate = function()
            activateActionBarAddon(getParentForElvUI)
        end,
    },
    LargerMacroIconSelection = {
        activate = supportLargerMacroIconSelection,
    }
}

