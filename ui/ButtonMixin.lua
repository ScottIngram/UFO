-- ButtonMixin

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@class ButtonMixin -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname... set by "child" "classes"
ButtonMixin = { }

-------------------------------------------------------------------------------
--  Constants
-------------------------------------------------------------------------------

---@class SecureMouseClickId
SecureMouseClickId = {
    type = "type", -- all buttons
    type1 = "type1",
    type2 = "type2",
    type3 = "type3",
    type4 = "type4",
    type5 = "type5",
}

---@type { [MouseClick]: SecureMouseClickId }
MouseClickRemapToSecureMouseClickId = {
    [MouseClick.ANY]    = "type",
    [MouseClick.LEFT]   = "type1",
    [MouseClick.RIGHT]  = "type2",
    [MouseClick.MIDDLE] = "type3",
    [MouseClick.FOUR]   = "type4",
    [MouseClick.FIVE]   = "type5",
}

-------------------------------------------------------------------------------
--  Methods
-------------------------------------------------------------------------------

function ButtonMixin:inject(other)
    for name, func in pairs(ButtonMixin) do
        other[name] = func
    end
end

function ButtonMixin:getIconFrame()
    return _G[ self:GetName().."Icon" ]
end

function ButtonMixin:getCooldownFrame()
    return _G[ self:GetName().."Cooldown" ]
end

local ICON_PREFIX = "INTERFACE\\ICONS\\"

function ButtonMixin:setIcon(icon)
    if icon and type(icon) ~= "number" and string.sub(icon,1,string.len(ICON_PREFIX)) ~= ICON_PREFIX then
        icon = (ICON_PREFIX .. icon)
    end

    self:getIconFrame():SetTexture(icon)
end

function ButtonMixin:updateCooldownsAndCountsAndStatesEtc()
    local btnDef = self:getDef()
    local spellId = btnDef and btnDef.spellId
    if (spellId) then
        SpellFlyoutButton_UpdateState(self)
    end

    self:updateUsable()
    self:updateCooldown()
    self:updateCount()
end

function ButtonMixin:updateUsable()
    local isUsable = true
    local notEnoughMana = false
    local btnDef = self:getDef()
    if btnDef then
        local itemId = btnDef.itemId
        local spellId = btnDef.spellId

        if itemId or spellId then
            if itemId then
                _, spellId = GetItemSpell(itemId)
                isUsable = IsUsableSpell(spellId)
            else
                isUsable, notEnoughMana = IsUsableSpell(spellId)
            end
        end

        zebug.trace:print("isItem", itemId, "itemID",self.itemID, "spellID", spellId, "isUsable",isUsable)
    end

    local iconFrame = self:getIconFrame();
    if isUsable then
        iconFrame:SetVertexColor(1.0, 1.0, 1.0);
    elseif notEnoughMana then
        iconFrame:SetVertexColor(0.5, 0.5, 1.0);
    else
        iconFrame:SetVertexColor(0.4, 0.4, 0.4);
    end
end

function ButtonMixin:updateCooldown()
    local btnDef = self:getDef()
    local type = btnDef and btnDef.type
    local itemId = btnDef and btnDef.itemId
    local spellId = btnDef and btnDef.spellId
    zebug.trace:print("type",type, "itemId",itemId, "spellId",spellId)

    if exists(spellId) then
        -- use Bliz's built-in handler for the stuff it understands, ie, not items
        zebug.trace:print("spellId",spellId)
        SpellFlyoutButton_UpdateCooldown(self)
        return
    end

    -- for items, I copied and hacked Bliz's ActionButton_UpdateCooldown

    if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        self.cooldown:SetSwipeColor(0, 0, 0);
        self.cooldown:SetHideCountdownNumbers(false);
        self.cooldown:SetSwipeColor(0,0,0, .5);
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
    end

    local modRate = 1.0;
    local start, duration, enable = 0, 0.75, true;
    local id = btnDef and btnDef:getIdForBlizApi()
    if id then
        start, duration, enable = GetItemCooldown(id);
        if duration > (self.maxVisibleCooldownDuration or 9999) then return end
        CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
    else
        -- without an id, this must be the empty placeholder slot.  Make it sparkle.  Once.
        local p = self:GetParent()
        if p.enableTwinkle then
            p.enableTwinkle = false
            start = GetTime()
            CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
        end
    end

    zebug.trace:print("type",type, "start",start, "duration",duration, "enable",enable )

end

function ButtonMixin:updateCount()
    local btnDef = self:getDef()
    local itemId = btnDef and btnDef.itemId
    local hasItem = exists(itemId)

    if not hasItem then
        local spellId = btnDef and btnDef.spellId
        if exists(spellId) then
            zebug.trace:print("spellID",self.spellID)
            -- use Bliz's built-in handler for the stuff it understands, ie, not items
            SpellFlyoutButton_UpdateCount(self)
            return
        end
    end

    local name, itemType, display
    if hasItem then
        name, _, _, _, _, itemType = GetItemInfo(itemId)
    end
    local includeBank = false
    local includeCharges = true
    local count = GetItemCount(itemId, includeBank, includeCharges)
    local tooMany = ( count > (self.maxDisplayCount or 9999 ) )
    zebug.trace:print("itemId",itemId, "hasItem",hasItem, "name",name, "itemType",itemType, "max",self.maxDisplayCount, "count",count, "tooMany",tooMany)

    local max = self.maxDisplayCount or 9999
    if count > max then
        display = ">"..max
    elseif CONSUMABLE == itemType then
        display = (count == 0) and "" or count
    else
        display = (count == 0 or count == 1) and "" or count
    end

    local textFrame = _G[self:GetName().."Count"];
    textFrame:SetText(display);
end

-------------------------------------------------------------------------------
--  SECURE TEMPLATE / RESTRICTED ENVIRONMENT
-------------------------------------------------------------------------------

---@param secureMouseClickId SecureMouseClickId
function ButtonMixin:getMouseBtnNumber(secureMouseClickId)
    local mouseBtnNumber = string.sub(secureMouseClickId, -1) -- last digit of "type1" or "type3" etc
    return tonumber(mouseBtnNumber) and mouseBtnNumber or nil
end

-- because in the world of Bliz SECURE
-- if your type = "type3"
-- then your key must be key.."3"
---@param secureMouseClickId SecureMouseClickId
function ButtonMixin:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
    local mouseBtnNumber = self:getMouseBtnNumber(secureMouseClickId)
    if mouseBtnNumber then
        return key .. mouseBtnNumber
    else
        return key
    end
end

---@param mouseClick MouseClick
function ButtonMixin:updateSecureClicker(mouseClick)
    local btnDef = self:getDef()
    if btnDef then
        local secureMouseClickId = MouseClickRemapToSecureMouseClickId[mouseClick]
        local type, key, val = btnDef:asClickHandlerAttributes()
        local keyAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
        zebug.trace:print("name",btnDef.name, "type",type, "key",key, "keyAdjusted",keyAdjustedToMatchMouseClick, "val", val)
        self:SetAttribute(secureMouseClickId, type)
        self:SetAttribute(keyAdjustedToMatchMouseClick, val)

        -- for use by Germ
        if self.ufoType == ButtonOnFlyoutMenu.ufoType then
            self:SetAttribute("UFO_KEY", key)
            self:SetAttribute("UFO_VAL", val)
        end

    else
        self:SetAttribute("type", nil)
    end

end
