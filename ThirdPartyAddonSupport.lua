-------------------------------------------------------------------------------
-- 3rd-Party Addon Support
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.WARN)

---@class ThirdPartyAddonSupport : UfoMixIn
---@field isAnyActionBarAddonActive boolean
---@field ufoType string The classname
ThirdPartyAddonSupport = {
    ufoType = "ThirdPartyAddonSupport",
    isAnyActionBarAddonActive = false,
}
UfoMixIn:mixInto(ThirdPartyAddonSupport)

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@class SUPPORTED_ADDONS -- IntelliJ-EmmyLua annotation
---@field activate function
local SUPPORTED_ADDONS -- to be defined below
local warned = false
local _getterOfBtnParentAsProvidedByAddon

-------------------------------------------------------------------------------
-- Methods / Functions
-------------------------------------------------------------------------------

function ThirdPartyAddonSupport:detectSupportedAddons()
    for addonName, methods in pairs(SUPPORTED_ADDONS) do
        zebug.info:print("Checking - addon", addonName)
        if C_AddOns.IsAddOnLoaded(addonName) then
            msgUser(L10N.DETECTED .. " " .. addonName, IS_OPTIONAL)
            SUPPORTED_ADDONS[addonName].activate(addonName)
        end
    end
end

-------------------------------------------------------------------------------
-- Action Bar Addons
-------------------------------------------------------------------------------

---@param babb BlizActionBarButton
function ThirdPartyAddonSupport:getBtnParentAsProvidedByAddon(babb)
    if not _getterOfBtnParentAsProvidedByAddon then return end
    local btnParent = _getterOfBtnParentAsProvidedByAddon(babb)
    if btnParent then
        btnParent.btnYafName = babb.btnYafName
        btnParent.btnName = babb.btnName
    end
    return btnParent
end

---@param babb BlizActionBarButton
function getParentForBartender4(babb)
    local btnSlotIndex = babb.btnSlotIndex
    local name = "BT4Button" .. btnSlotIndex
    local parent = _G[name]
    zebug.trace:owner(babb):name("BARTENDER4:getParent"):print("btnSlotIndex",btnSlotIndex, "name",name, "parent",parent)
    if parent then
        -- poor-man's polymorphism
        parent.GetName = function() return name end
        parent.btnSlotIndex = btnSlotIndex
        parent.bar = {}
        parent.bar.GetSpellFlyoutDirection = function() return parent.config.flyoutDirection or "LEFT" end
    else
        if not warned then
            msgUser(L10N.BARTENDER_BAR_DISABLED)
            warned = true
        end
    end
    return parent
end

---@param babb BlizActionBarButton
function getParentForElvUI(babb)
    local btnSlotIndex = babb.btnSlotIndex
    local barNum = babb.barNum
    local btnNum = babb.btnNum
    local barName =  "ElvUI_Bar" .. barNum
    local btnName = barName .."Button".. btnNum
    local parent = _G[btnName]
    local zebugger = parent and zebug.trace or zebug.error
    zebugger:owner(babb):name("ElvUI:getParent"):print("btnSlotIndex",btnSlotIndex, "barNum",barNum, "barName",barName, "btnName",btnName, "parent",parent)
    if parent then
        -- poor-man's polymorphism
        --parent.GetName = function() return barName end
        --parent.btnSlotIndex = btnSlotIndex
        parent.bar = {}
        parent.bar.GetSpellFlyoutDirection = function() return parent.db.flyoutDirection or "LEFT" end -- Um, I forgot what this "db" is ? Was that an ElvUI thing?
    end
    return parent
end

---@param babb BlizActionBarButton
function getParentForDominos(babb)
    local btnSlotIndex = babb.btnSlotIndex

    -- for some reason that I can't figure out,
    -- action buttons 13 through 25 won't show UFOs.
    -- so for the moment, I'm just not supporting UFOs in those.
    -- Also, some (but not all) empty button slots will throw this error when you point at them:
    -- Interface/FrameXML/SecureTemplates.lua:120: Wrong object type for function
    --if btnSlotIndex >= 13 and btnSlotIndex <=25 then return end

    local name = "DominosActionButton" .. btnSlotIndex
    local parent = _G[name]

    if parent then
        zebug.info:owner(babb):name("DOMINOS:getParent"):print("FOUND Dominos button",parent, " with the name",name)
    else
        zebug.info:owner(babb):name("DOMINOS:getParent"):print("failed to find a Dominos button with the name",name)

        -- I'm trying to construct something like "MultiBarLeftActionButton4" istead of Blizzard's standard name of "MultiBarLeftButton4" because everybody has to be special.
        local barName =  babb.barName -- MultiBarLeft
        local btnNum = babb.btnNum -- 1-12
        name = barName .."ActionButton".. btnNum
        parent = _G[name]

        if parent then
            zebug.info:owner(babb):name("DOMINOS:getParent"):print("FOUND Dominos button",parent, " with the name",name)
        else
            zebug.info:owner(babb):name("DOMINOS:getParent"):print("failed to find a Dominos button with the name",name)
        end
    end

    --zebug.info:owner(babb):name("DOMINOS:getParent"):print("btnSlotIndex",btnSlotIndex, "name",name, "parent",parent)
    if parent then
        -- poor-man's polymorphism - will this cause TAINT ?
        parent.GetName = function() return name end
        parent.btnSlotIndex = btnSlotIndex

        -- UFOs looks to the standard Bliz actionbar button which has a "bar" attribute which in turn has a GetSpellFlyoutDirection() method
        if parent.GetSpellFlyoutDirection or (parent.bar and parent.bar.GetSpellFlyoutDirection) then
            zebug.trace:owner(babb):name("DOMINOS:getParent"):print("DOMINOS: already has parent.bar.GetSpellFlyoutDirection", parent.bar.GetSpellFlyoutDirection)
        else
            zebug.trace:owner(babb):name("DOMINOS:getParent"):print("DOMINOS: creating target.GetSpellFlyoutDirection")
            function parent:GetSpellFlyoutDirection(event)
                local dir = parent:GetAttribute("flyoutDirection") or "LEFT"
                zebug.info:event(event):owner(babb):name("DOMINOS:GetSpellFlyoutDirection"):print("btnSlotIndex",btnSlotIndex, "name",name, "dir",dir)
                return dir
            end
        end
    else
        if not warned then
            msgUser(L10N.DOMINOS_BAR_DISABLED)
            warned = true
        end
    end
    return parent
end

function activateActionBarAddon(parentGetterFunc)
    ThirdPartyAddonSupport.isAnyActionBarAddonActive = true
    _getterOfBtnParentAsProvidedByAddon = parentGetterFunc
end

-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------

function supportLargerMacroIconSelection()
    LargerMacroIconSelection:Initialize(UFO_IconPicker)
end

function supportMacroToolkit()
    Catalog:createToggleButton(MacroToolkitFrame, MacroToolkitFrameCloseButton)
    MacroShitShow:init()
end

-------------------------------------------------------------------------------
-- Constants
-- I have to put these after the function declarations due to Lua's one-pass compiler.
-------------------------------------------------------------------------------

SUPPORTED_ADDONS = {
    Bartender4 = {
        activate = function(addonName)
            activateActionBarAddon(getParentForBartender4)
        end,
    },
    ElvUI = {
        activate = function(addonName)
            activateActionBarAddon(getParentForElvUI)
        end,
    },
    Dominos = {
        activate = function(addonName)
            activateActionBarAddon(getParentForDominos)
        end,
    },
    LargerMacroIconSelection = {
        activate = supportLargerMacroIconSelection,
    },
    MacroToolkit = {
        activate = supportMacroToolkit,
    }
}

