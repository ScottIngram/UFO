-------------------------------------------------------------------------------
-- 3rd-Party Addon Support
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@class ThirdPartyAddonSupport -- IntelliJ-EmmyLua annotation
---@field isActive boolean
---@field ufoType string The classname
local ThirdPartyAddonSupport = {
    ufoType = "ThirdPartyAddonSupport",
    isActive = false,
}
Ufo.ThirdPartyAddonSupport = ThirdPartyAddonSupport

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local SUPPORTED_ADDONS -- to be defined below
local warned = false
local _getParent

-------------------------------------------------------------------------------
-- Methods / Functions
-------------------------------------------------------------------------------

function ThirdPartyAddonSupport:detectSupportedAddons()
    for addon, methods in pairs(SUPPORTED_ADDONS) do
        if IsAddOnLoaded(addon) then
            ThirdPartyAddonSupport.isActive = true
            _getParent = SUPPORTED_ADDONS[addon].getParent
            break
        end
    end
end

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
            print(zebug.error:colorize(L10N.BARTENDER_BAR_DISABLED))
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

-------------------------------------------------------------------------------
-- Constants
-- I have to put these after the function declarations due to Lua's one-pass compiler.
-------------------------------------------------------------------------------

SUPPORTED_ADDONS = {
    Bartender4 = {
        getParent = getParentForBartender4,
    },
    ElvUI = {
        getParent = getParentForElvUI,
    },
}

