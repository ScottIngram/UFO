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

---@class SecEnvMouseClickId
SecEnvMouseClickId = {
    type = "type", -- all buttons
    type1 = "type1",
    type2 = "type2",
    type3 = "type3",
    type4 = "type4",
    type5 = "type5",
    type6 = "type6", -- this isn't mentioned in the documentation
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
    --self:safelySetSecEnvAttribute("UFO_ICON", icon) -- for use by the promoter
    self.iconTexture = icon
end

-- TODO - go look at ActionBarActionButtonMixin:Update() and copy anything I'm missing
function Button_Mixin:renderCooldownsAndCountsAndStatesEtc(event)
    -- should I call self:Update() aka ActionBarActionButtonMixin:Update() ... um, maybe I'm not an ActionBarActionButtonMixin
    local btnDef = self:getDef()
    local spellId = btnDef and btnDef.spellId
    if spellId then
        if not self.spellID then
            -- internal Bliz code expects this field
            self.spellID = spellId -- "Secret value" TAINT as of 3/26
        end
        local isThisTheSpell = C_Spell.IsCurrentSpell(spellId)
        self:SetChecked(isThisTheSpell);
    end

    -- the following methods are based on the ones in SpellFlyoutButton
    -- mine have custom code that can handle both items and spells
    -- TODO support macros which can have #show which displays spell/item icons & cooldowns
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
    else
        isUsable = false
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

--local startTime = {}

function Button_Mixin:updateCooldown(event)
    local btnDef = self:getDef()

    if not btnDef then
        -- without an id, this must be the empty placeholder slot.
        return
    end

    local type    = btnDef.type
    local itemId  = btnDef.itemId
    local spellId = btnDef.spellId
    zebug.trace:event(event):owner(self):print("type",type, "itemId",itemId, "spellId",spellId)

    if type == ButtonType.SUMMON_RANDOM_FAVORITE_MOUNT then
        return
    end

    -- don't touch Bliz's radioactive secret shit during combat
    -- instead, fallback to the code further below
    if not InCombatLockdown() then
        if exists(spellId) then
            --zebug.trace:event(event):owner(self):print("spellId",spellId)

            -- use Bliz's built-in handler
            self.spellID = spellId --v11 -- internal Bliz code expects this field -- "Secret value" TAINT as of 3/26

            -- the above InCombatLockdown() can STILL fail because combat can commence in the microsecond after it says "false"
            -- so, wrap that shit in a try/catch block and eat the exception
            local isOk, errMsg = pcall(function()
                Bliz_API.ActionButton_UpdateCooldown(self) -- <== uses sEcReT shit that barfs in combat
                zebug.info:owner(self):event(event):print("non-combat-call A-OK")
            end)

            if isOk then
                -- miracle of miracles, Bliz's code didn't shit the bed!  So, we're done.
                return
            else
                zebug.info:owner(self):event(event):print("non-combat-call DED !!!")
                -- unsurprisingly, Bliz's code SHIT the bed!  Can't exit.  More work to do to clean up Bliz's fucking mess.
                zebug.info:owner(self):event(event):print("Hey, I asked Bliz.InCombatLockdown() which said nope, but then:", errMsg)
            end
        end
    end

    -- I copied and hacked Bliz's ActionButton_UpdateCooldown

    local modRate = 0.6;
    local id = btnDef:getIdForBlizApi()
    local cdFrame = self:getCooldownFrame()
    zebug.info:owner(self):event(event):print("ZZZ type",type, "id", id, "spellId",spellId)
    --print(self:toString(), event, "type",type, "id", id, "spellId",spellId)

    if id then
        if ButtonType.SPELL == type then
            local timeSpellWasCast, cooldownFullDuration, cooldownRemainder = SpellCd:getStatus(id, event, self)
            if timeSpellWasCast then
                zebug.warn:owner(spellId):event(event):print("triggerering cooldown display NOW! remainder", cooldownRemainder)
                cdFrame:SetDrawEdge(true);
                cdFrame:SetCooldown(timeSpellWasCast, cooldownFullDuration)
            else
                zebug.warn:owner(spellId):event(event):print("CLEARING cooldown display remainder", cooldownRemainder)
                cdFrame:Clear()
            end
--[[
-- I moved this into SpellCd.lua

            -- avoid secret values
            -- avoid the Bliz ActionButton_UpdateCooldown
            local cooldownFullDurationMilliseconds = GetSpellBaseCooldown(spellId) or 0
            local cooldownFullDuration = cooldownFullDurationMilliseconds /1000
            local cdState = C_Spell.GetSpellCooldown(spellId)
            local isEnabled, isActive = cdState.isEnabled, cdState.isActive
            local passage = time() - (startTime[spellId] or 0)
            if isEnabled and isActive then
                if passage > cooldownFullDuration then
                    startTime[spellId] = time()
                    passage = 0
                end
                zebug.warn:owner(self):event(event):print("IN-COMBAT-HACK... isEnabled", isEnabled, "isActive",isActive, "cooldownDuration", cooldownFullDuration, "delta", passage)
                cd:SetDrawEdge(true);
                cd:SetCooldown(startTime[spellId], cooldownFullDuration)
            else
                zebug.warn:owner(self):event(event):print("IN-COMBAT-HACK... CLEAR! - isEnabled", isEnabled, "isActive",isActive, "cooldownDuration", cooldownFullDuration, "delta", passage)
                cd:Clear()
                startTime[spellId] = nil
            end
]]
        else
            if (ButtonType.PET == type) or (ButtonType.BROKENP == type) then
                id = AUTO_ATTACK_SPELL_ID --v11 has stricter param checks in some of its API calls
            end

            local startTime, duration, isEnabled = C_Container.GetItemCooldown(btnDef.cooldownProxy or id)
            zebug.warn:event(event):owner(self):print("ITEMS - cd:SetCooldown() start", startTime, "duration",duration, "isEnabled", isEnabled)
            if startTime and duration then
                cdFrame:SetCooldown(startTime, duration, isEnabled, false, modRate);
            end
        end
    end
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
--  SecEnv TEMPLATE / RESTRICTED ENVIRONMENT
-------------------------------------------------------------------------------

---@param secEnvMouseClickId SecEnvMouseClickId
function Button_Mixin:getMouseBtnNumber(secEnvMouseClickId)
    local mouseBtnNumber = string.sub(secEnvMouseClickId, -1) -- last digit of "type1" or "type3" etc
    return tonumber(mouseBtnNumber) and mouseBtnNumber or nil
end

-- because in the world of Bliz SECURE
-- if your type = "type3"
-- then your key must be key.."3" where key is typically "spell" or "item" etc.
---@param secEnvMouseClickId SecEnvMouseClickId
function Button_Mixin:adjustSecureKeyToMatchTheMouseClick(secEnvMouseClickId, key)
    local mouseBtnNumber = self:getMouseBtnNumber(secEnvMouseClickId)
    if mouseBtnNumber then
        return key .. mouseBtnNumber
    else
        return key
    end
end


---@param mouseClick MouseClick
function Button_Mixin:assignSecEnvMouseClickBehaviorVia_AttributeFromBtnDef(mouseClick, event)
    ---@type ButtonDef
    local btnDef = self:getDef()

    if btnDef then
        local secEnvMouseClickId = MouseClickAsSecEnvId[mouseClick] -- "type1" or "type2" etc
        local typeOfAction, typeOfActionButDumber, actualAction = btnDef:asSecureClickHandlerAttributes(event)
        -- typeOfActionButDumber = typeOfActionButDumber or typeOfAction
        local typeOfActionButDumberAdjustedToMatchMouseClick = self:adjustSecureKeyToMatchTheMouseClick(secEnvMouseClickId, typeOfActionButDumber)
        zebug.info:event(event):owner(self):noName():print("t",secEnvMouseClickId, "type", typeOfAction, "typeDumber", typeOfActionButDumber, "typeDumberAdjusted", typeOfActionButDumberAdjustedToMatchMouseClick, "actualAction", actualAction)

        self:SetAttribute(secEnvMouseClickId, typeOfAction) -- eg "type1" -> "macro"
        self:SetAttribute(typeOfActionButDumberAdjustedToMatchMouseClick, actualAction) -- eg, "macro1" -> "/say weak sauce"

        -- TODO - investigate potential bug of WHEN a flyout def changes and the btnDefs change / change positions THEN will there be stale macro/macrotext values?  See prime button code

        -- for use by Germ's ON_CLICK script
        if self.ufoType == ButtonOnFlyoutMenu.ufoType then
            self:SetAttribute("SEC_ENV_ACTION_TYPE", typeOfAction)-- typeOfActionButDumber)
            self:SetAttribute("SEC_ENV_ACTION_TYPE_DUMBER", typeOfActionButDumber)-- typeOfActionButDumber)
            self:SetAttribute("SEC_ENV_ACTION_ARG", actualAction)
        end
    else
        self:SetAttribute("type", nil)
    end
end

Button_Mixin.assignSecEnvMouseClickBehaviorVia_AttributeFromBtnDef = Pacifier:wrap(Button_Mixin.assignSecEnvMouseClickBehaviorVia_AttributeFromBtnDef)

function Button_Mixin:getsecEnvMouseClickId(mouseClick)
    return MouseClickAsSecEnvId[mouseClick]
end

Button_Mixin.setSecEnvAttribute = UfoMixIn.setSecEnvAttribute
Button_Mixin.safelySetSecEnvAttribute = UfoMixIn.safelySetSecEnvAttribute

