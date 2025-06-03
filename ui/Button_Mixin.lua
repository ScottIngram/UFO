-- Button_Mixin

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new(Zebug.WARN)

---@class Button_Mixin -- IntelliJ-EmmyLua annotation
---@field originalIconSetTextureFunc function Bliz's assigned SetTexture given to the .icon frame
---@field overrideIconSetTextureFunc function our new SetTexture for the .icon frame
Button_Mixin = { }
GLOBAL_Button_Mixin = Button_Mixin

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
    type6 = "type6", -- this isn't mentioned in the documentation
}

---@type { [MouseClick]: SecureMouseClickId }
REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID = {
    [MouseClick.ANY]    = "type",
    [MouseClick.LEFT]   = "type1",
    [MouseClick.RIGHT]  = "type2",
    [MouseClick.MIDDLE] = "type3",
    [MouseClick.FOUR]   = "type4",
    [MouseClick.FIVE]   = "type5",
    [MouseClick.SIX]    = "type6",
}

-------------------------------------------------------------------------------
--  Methods
-------------------------------------------------------------------------------

function Button_Mixin:getIconFrame()
    return self.icon or _G[ self:GetName().."Icon" ]
end

function Button_Mixin:getCooldownFrame()
    return self.cooldown or _G[ self:GetName().."Cooldown" ]
end

function Button_Mixin:getCountFrame()
    return self.count or self.Count or _G[ self:GetName().."Count" ]
end

function Button_Mixin:getHotKeyFrame()
    return self.HotKey
end

function Button_Mixin:setHotKeyOverlay(keybindText)
    local overlay = self.HotKey
    if overlay then
        local text = GetBindingText(keybindText, 1) or keybindText
        overlay:SetText(text)
    end
end

local ICON_PREFIX = "INTERFACE\\ICONS\\"

function Button_Mixin:setIcon(icon, event)
    if icon and type(icon) ~= "number" and string.sub(icon,1,string.len(ICON_PREFIX)) ~= ICON_PREFIX then
        icon = (ICON_PREFIX .. icon)
    end

    local iconFrame = self:getIconFrame()

    --self:getIconFrame():SetTexture(icon)
    -- IS THIS BROKEN?


    -- block the Bliz mixins from erroneously setting the icon to look like the contents of the action bar button (ie, the ZUFO macro)
    if not self.originalIconSetTextureFunc then
        self.originalIconSetTextureFunc = iconFrame.SetTexture
        iconFrame.SetTexture = function()
            zebug.warn:event(event):owner(self):line(20, "BLOCKED BLIZ SetTexture for germ")
        end
    end
    zebug.info:event(event):owner(self):print("setting icon",icon)
    self.originalIconSetTextureFunc(iconFrame, icon) -- the iconFrame is the self for the original SetTexture
end

-- TODO - go look at ActionBarActionButtonMixin:Update() and copy anything I'm missing
function Button_Mixin:updateCooldownsAndCountsAndStatesEtc(event)
    -- should I call self:Update() aka ActionBarActionButtonMixin:Update() ... um, maybe I'm not an ActionBarActionButtonMixin
    local btnDef = self:getDef()
    local spellId = btnDef and btnDef.spellId
    if spellId then
        if not self.spellID then
            -- internal Bliz code expects this field
            self.spellID = spellId -- TAINT?
        end
        local isThisTheSpell = C_Spell.IsCurrentSpell(spellId)
        self:SetChecked(isThisTheSpell);
    end

    self:updateUsable(event)
    self:updateCooldown(event)
    self:updateCount(event)
end

function Button_Mixin:updateUsable(event)
    local isUsable = true
    local notEnoughMana = false
    local btnDef = self:getDef()
    if btnDef then
        local itemId = btnDef.itemId
        local spellId = btnDef.spellId

        if itemId or spellId then
            if itemId then
                _, spellId = C_Item.GetItemSpell(itemId)
                if C_Spell.IsSpellUsable then --v11
                    isUsable = C_Spell.IsSpellUsable(spellId or 0)
                else --v10
                    isUsable = IsUsableSpell(spellId)
                end
            else
                if C_Spell.IsSpellUsable then --v11
                    isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellId)
                else --v10
                    isUsable, notEnoughMana = IsUsableSpell(spellId)
                end
            end
        end

        zebug.trace:event(event):owner(self):print("isItem", itemId, "itemID",self.itemID, "spellID", spellId, "isUsable",isUsable)
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

function Button_Mixin:updateCooldown(event)
    local btnDef = self:getDef()
    local type = btnDef and btnDef.type
    local itemId = btnDef and btnDef.itemId
    local spellId = btnDef and btnDef.spellId
    zebug.trace:event(event):owner(self):print("type",type, "itemId",itemId, "spellId",spellId)

    if exists(spellId) then
        -- use Bliz's built-in handler for the stuff it understands, ie, not items
        zebug.trace:event(event):owner(self):print("spellId",spellId)
        self.spellID = spellId --v11 -- internal Bliz code expects this field

        ActionButton_UpdateCooldown(self);
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
        if type == ButtonType.PET or type == ButtonType.BROKENP then
            id = AUTO_ATTACK_SPELL_ID --v11 has stricter param checks in some of its API calls
        end
        -- debugging to unsilence Bliz's err silencing so I can find out what's going wrong.
        --local isOk, err = pcall( function() start, duration, enable = C_Container.GetItemCooldown(btnDef.cooldownProxy or id) end  )
        --if err then zebug.error:print("DIED on C_Container.GetItemCooldown() where id",id) end
        start, duration, enable = C_Container.GetItemCooldown(btnDef.cooldownProxy or id)
        if (duration or 0) > (Config.opts.hideCooldownsWhen or 99999) then return end
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

    zebug.trace:event(event):owner(self):print("type",type, "start",start, "duration",duration, "enable",enable )

end

function OLD_CATA_SpellFlyoutButton_UpdateCount (self)
    local text = _G[self:GetName().."Count"];

    if ( IsConsumableSpell(self.spellID)) then
        local count = C_Spell.GetSpellCastCount(self.spellID);
        if ( count > (self.maxDisplayCount or 9999 ) ) then
            text:SetText("*");
        else
            text:SetText(count);
        end
    else
        text:SetText("");
    end
end

function Button_Mixin:updateCount(event)
    local btnDef = self:getDef()
    local itemId = btnDef and btnDef.itemId
    if not itemId then return end
    local hasItem = exists(itemId)

    if not hasItem then
        local spellId = btnDef and btnDef.spellId
        if exists(spellId) then
            zebug.trace:event(event):owner(self):print("spellID",self.spellID)
            -- use Bliz's built-in handler for the stuff it understands, ie, not items
            OLD_CATA_SpellFlyoutButton_UpdateCount(self)
            -- whatabout ActionBarActionButtonMixin:UpdateCount
            return
        end
    end

    local name, itemType, display
    if hasItem then
        name, _, _, _, _, itemType = C_Item.GetItemInfo(itemId)
    end
    local includeBank = false
    local includeCharges = true
    local count = C_Item.GetItemCount(itemId, includeBank, includeCharges)
    local tooMany = ( count > (self.maxDisplayCount or 9999 ) )
    zebug.trace:event(event):owner(self):print("itemId",itemId, "hasItem",hasItem, "name",name, "itemType",itemType, "max",self.maxDisplayCount, "count",count, "tooMany",tooMany)

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
function Button_Mixin:getMouseBtnNumber(secureMouseClickId)
    local mouseBtnNumber = string.sub(secureMouseClickId, -1) -- last digit of "type1" or "type3" etc
    return tonumber(mouseBtnNumber) and mouseBtnNumber or nil
end

-- because in the world of Bliz SECURE
-- if your type = "type3"
-- then your key must be key.."3" where key is typically "spell" or "item" etc.
---@param secureMouseClickId SecureMouseClickId
function Button_Mixin:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
    local mouseBtnNumber = self:getMouseBtnNumber(secureMouseClickId)
    if mouseBtnNumber then
        return key .. mouseBtnNumber
    else
        return key
    end
end

---@param mouseClick MouseClick
function Button_Mixin:updateSecureClicker(mouseClick, event)
    local btnDef = self:getDef()

    -- don't waste time repeating work
    -- oops! this is too simplistic as it fails to detect changes inside the btnDef
    -- need something more like FlyoutDef:isModNewerThan()
    local noChange = (self.mySecureClickerDef == btnDef)
--[[
    if noChange then
        return
    end
]]

    if btnDef then
        local secureMouseClickId = REMAP_MOUSE_CLICK_TO_SECURE_MOUSE_CLICK_ID[mouseClick]
        local type, key, val = btnDef:asSecureClickHandlerAttributes(event)
        local keyAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secureMouseClickId, key)
        zebug.trace:event(event):owner(self):print("name",btnDef.name, "type",type, "key",key, "keyAdjusted",keyAdjustedToMatchMouseClick, "val", val)

        -- TODO: v11.1 this concat is expensive. optimize.
        local id = "BUTTON-MIXIN:updateSecureClicker for " .. self:getName().. " with btnDef : ".. btnDef:getName();
        exeOnceNotInCombat(id, function()
            self:SetAttribute(secureMouseClickId, type)
            self:SetAttribute(keyAdjustedToMatchMouseClick, val)
            -- for use by Germ
            if self.ufoType == ButtonOnFlyoutMenu.ufoType then
                self:SetAttribute("UFO_KEY", key)
                self:SetAttribute("UFO_VAL", val)
            end
            self.mySecureClickerDef = btnDef
        end)
    else
        exeOnceNotInCombat("BUTTON-MIXIN:updateSecureClicker w/o btnDef : anon", function()
            self:SetAttribute("type", nil)
            self.mySecureClickerDef = btnDef
        end)
    end
end

-------------------------------------------------------------------------------
-- ExTrA SECURE TEMPLATE / RESTRICTED ENVIRONMENT - aka fUcK yOu BlIz
-- bliz base class code keeps calling my code and then
-- complains about taint (ref: stick in spokes of bicycle meme)
-- Which, yes, may mean that I'm extending Bliz mixins/templates that they don't intend for us -- and if so, label that shit plz.
-- But until I figure out that can of worms, here's a sledgehammer to beat back the BS
-------------------------------------------------------------------------------

-- replace the built-in SetAttribute with one that can only happen out of combat
function Button_Mixin:makeSafeSetAttribute()

    if not self.originalSetAttribute then
        local originalSetAttribute = self.SetAttribute
        assert("self:SetAttribute() is NULL", originalSetAttribute)

        self.originalSetAttribute = originalSetAttribute

        -- FUNC START
        self.SetAttribute = function(zelf, key, value, isTrusted)
            local inCombatLockdown = InCombatLockdown()
            zebug.trace:owner(self):print("self.SetAttribute for",(self.getName and self:getName()) or "misc obj", "key",key, "value",value, "isTrusted",isTrusted)
            if isTrusted then
                zebug.info:print("ufo is allowed to call originalSetAttribute with name", key, "value", value)
                if key == "pressAndHoldAction" then
                    --zebug.error:print("P&H! - getName",(self.getName and self:getName()) or "no getName", "isTrusted", isTrusted, "inCombat",inCombatLockdown)
                    return;
                end
                return originalSetAttribute(zelf, key, value)
            else
                if key == "pressAndHoldAction" then
                    --zebug.warn:print("P&H? - getName",(self.getName and self:getName()) or "no getName", "isTrusted", isTrusted, "inCombat",inCombatLockdown)
                end
                safelySetAttribute(zelf, key, value)
            end
        end
        -- FUNC END

    end
end

-------------------------------------------------------------------------------
-- OVERRIDES of
-- SmallActionButtonMixin methods
-- acquired via SmallActionButtonTemplate
-- See Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButton.lua
-------------------------------------------------------------------------------

function Button_Mixin:OnButtonStateChanged()
    -- defined in ButtonStateBehaviorMixin:OnButtonStateChanged() as "Derive and configure your button to the correct state."
    zebug.info:owner(self):print("calling parent in FlyoutButtonMixin")
    FlyoutButtonMixin.OnButtonStateChanged(self)
end
