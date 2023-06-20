-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

---@class ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local ButtonOnFlyoutMenu = {
    ufoType = "ButtonOnFlyoutMenu",
}
Ufo.ButtonOnFlyoutMenu = ButtonOnFlyoutMenu

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local pickedUpMount -- workaround the Bliz API which handles mounts inconsistently

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- can't do my usual metatable magic because (I think) the Bliz UI objects already have.
-- so, instead, just copy all of my methods onto the Bliz UI object
function ButtonOnFlyoutMenu.oneOfUs(btnOnFlyout)
    -- merge the Bliz ActionButton object
    -- with this class's methods, functions, etc
    deepcopy(ButtonOnFlyoutMenu, btnOnFlyout)
end

function ButtonOnFlyoutMenu:getId()
    -- the button ID never changes because it's never actually dragged or moved.
    -- It's the underlying btnDef that moves from one button to another.
    return self:GetID()
end

---@return FlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:getParent()
    return self:GetParent()
end

function ButtonOnFlyoutMenu:setIconTexture(texture)
    self:getIconFrame():SetTexture(texture)
end

function ButtonOnFlyoutMenu:getIconFrame()
    return _G[ self:GetName().."Icon" ]
end

function ButtonOnFlyoutMenu:isEmpty()
    return not self:hasDef()
end

function ButtonOnFlyoutMenu:hasDef()
    return self.btnDef and true or false
end

---@return ButtonDef
function ButtonOnFlyoutMenu:getDef()
    return self.btnDef
end

---@param btnDef ButtonDef
function ButtonOnFlyoutMenu:setDef(btnDef)
    self.btnDef = btnDef
    self:copyDefToBlizFields()
end

function ButtonOnFlyoutMenu:copyDefToBlizFields()
    local d = self.btnDef or {}
    -- the names on the left are used deep inside Bliz code
    self.actionType = d.type
    self.actionID   = d.spellId or d.itemId or d.toyId or d.mountId -- or d.petGuid
    self.spellID    = d.spellId
    self.itemID     = d.itemId
    self.mountID    = d.mountId
    self.battlepet  = d.petGuid
end

-- TODO: TEST dragging the empty button
-- pickup an existing button from an existing flyout
---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu:onDragStartDoPickup()
    if isInCombatLockdown("Drag and drop") then return end
    if self:isEmpty() then return end

    ---@type FlyoutMenu
    local flyoutFrame = self:GetParent()
    if flyoutFrame.isForCatalog then
        self:pickupToCursor()
        local flyoutId = flyoutFrame:getId()
        local flyoutMenuDef = FlyoutMenusDb:get(flyoutId)
        flyoutMenuDef:removeButton(self:getId())
        self:setDef(nil)
        flyoutFrame:updateForCatalog(flyoutId)
        GermCommander:updateAll()
    end
end

function ButtonOnFlyoutMenu:onReceiveDragAddIt()
    local flyoutMenu = self:getParent()
    if not flyoutMenu.isForCatalog then return end -- only the flyouts in the catalog are valid drop targets.  TODO: let flyouts on the germs receive too?

    local crsDef = ButtonOnFlyoutMenu:getFromCursor()
    if not crsDef.type then
        debug.warn:print("Sorry, unsupported type:", crsDef.kind)
        return
    end

    local flyoutId = flyoutMenu:getId()
    local flyoutDef = FlyoutMenusDb:get(flyoutId)
    local btnIndex = self:getId()
    local oldBtnDef = flyoutDef:getButtonDef(btnIndex)
    flyoutDef:replaceButton(btnIndex, crsDef)

    ClearCursor()
    GermCommander:updateAll()
    flyoutMenu:updateForCatalog(flyoutId)
    pickedUpMount = nil

    if oldBtnDef then
        ButtonOnFlyoutMenu:pickupToCursor(oldBtnDef)
    end
end

-- TODO: implement
local function parseToolTipForType(toolTip)
    debug.trace:out(")",10,"parseToolTipForType()", toolTip)
    debug.trace:dump(toolTip)
end

-- TODO: distinguish between toys and items
---@return ButtonDef
function ButtonOnFlyoutMenu:getFromCursor()
    ---@type ButtonDef
    local btnDef = ButtonDef:new()
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;
    debug.trace:out(">",5,"getFromCursor()", "type",type, "c1",c1, "c2",c2, "c3",c3)

    btnDef.type = type
    if type == ButtonType.SPELL then
        btnDef.spellId = c3
    elseif type == ButtonType.SNAFU then
        -- this is an abnormal result containing a useless ID which isn't accepted by any API.  Not helpful.
        -- It's caused when the mouse pointer is loaded via Bliz's API PickupSpell(withTheSpellIdOfSomeMount)
        -- This is a workaround to Bliz's API and retrieves a usable ID from my secret stash created when the user grabbed the mount.
        if pickedUpMount then
            btnDef.type = ButtonType.MOUNT
            btnDef.spellId = pickedUpMount.spellId
            btnDef.mountId = pickedUpMount.mountId
        else
            debug.warn:print("Sorry, the Blizzard API provided bad data for this mount.")
        end
    elseif type == ButtonType.MOUNT then
        local name, spellId = C_MountJournal.GetMountInfoByID(c1)
        btnDef.spellId = spellId
        btnDef.mountId = c1
    elseif type == ButtonType.ITEM then
        local ttType = parseToolTipForType(c2)
        if ttType == ButtonType.TOY then
            btnDef.type = ButtonType.TOY
        end
        btnDef.itemId = c1
    elseif type == ButtonType.MACRO then
        btnDef.macroId = c1
        if not isMacroGlobal(c1) then
            btnDef.macroOwner = getIdForCurrentToon()
        end
    elseif type == ButtonType.PET then
        btnDef.petGuid = c1
    else
        btnDef.kind = type or "UnKnOwN"
    end

    if type then
        -- discovering the name requires knowing its type
        btnDef:populateName()
    end

    return btnDef
end

function ButtonOnFlyoutMenu:pickupToCursor(btnDef)
    local def = btnDef or self:getDef()
    local type = def.type

    debug.trace:out("<",5,"ButtonOnFlyoutMenu:pickup", "actionType",def.type, "name",def.name, "spellId",def.spellId, "itemId",def.itemId, "mountId",def.mountId)

    if type == "mount" then
        -- set a global variable because the Bliz API is broken
        pickedUpMount = {
            mountId = def.mountId,
            spellId = def.spellId
        }
        PickupSpell(def.spellId)
    elseif type == "spell" then
        PickupSpell(def.spellId)
    elseif type == "item" then
        PickupItem(def.itemId)
    elseif type == "macro" then
        PickupMacro(def.macroId)
    elseif type == "battlepet" then
        C_PetJournal.PickupPet(def.petGuid)
    end
    -- TODO: bug - address TOY
end

function ButtonOnFlyoutMenu:updateCooldownsAndCountsAndStatesEtc()
    local btnDef = self:getDef()
    local spellId = btnDef and btnDef.spellId
    if (spellId) then
        SpellFlyoutButton_UpdateState(self)
    end

    self:updateUsable()
    self:updateCooldown()
    self:updateCount()
end

function ButtonOnFlyoutMenu:updateUsable()
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

        debug.trace:out("#",5,"updateUsable()", "isItem", itemId, "itemID",self.itemID, "spellID", spellId, "isUsable",isUsable)
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

function ButtonOnFlyoutMenu:updateCooldown()
    local btnDef = self:getDef()
    local itemId = btnDef and btnDef.itemId
    local spellId = btnDef and btnDef.spellId
    debug.trace:out("X",40,"updateCooldown() 1 ITEM","itemId",itemId, "spellId",spellId)

    if exists(spellId) then
        -- use Bliz's built-in handler for the stuff it understands, ie, not items
        debug.trace:out("X",20,"updateCooldown() SPELL", "spellId",spellId)
        SpellFlyoutButton_UpdateCooldown(self)
        return
    end

    -- for items, I copied and hacked Bliz's ActionButton_UpdateCooldown
    local start, duration, enable = 1, 1, true;
    if itemId then
        start, duration, enable = GetItemCooldown(itemId);
    end

    local type = btnDef and btnDef.type
    debug.trace:out("X",5,"updateCooldown() 2 ITEM","type",type, "start",start, "duration",duration, "enable",enable )

    if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        self.cooldown:SetSwipeColor(0, 0, 0);
        self.cooldown:SetHideCountdownNumbers(false);
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
    end

    local modRate = 1.0;
    CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
end

function ButtonOnFlyoutMenu:updateCount()
    local btnDef = self:getDef()
    local itemId = btnDef and btnDef.itemId
    local hasItem = exists(itemId)

    if not hasItem then
        local spellId = btnDef and btnDef.spellId
        if exists(spellId) then
            debug.trace:out("X",5,"UFO_UpdateCount 0... deferring to SpellFlyoutButton_UpdateCount ", "spellID",self.spellID)
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
    debug.trace:out("X",5,"UFO_UpdateCount 1 ", "itemId",itemId, "hasItem",hasItem, "name",name, "itemType",itemType, "max",self.maxDisplayCount, "count",count, "tooMany",tooMany)

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

function ButtonOnFlyoutMenu:setGeometry(direction, prevBtn)
    self:ClearAllPoints()
    if prevBtn then
        if direction == "UP" then
            self:SetPoint("BOTTOM", prevBtn, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
        elseif direction == "DOWN" then
            self:SetPoint("TOP", prevBtn, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
        elseif direction == "LEFT" then
            self:SetPoint("RIGHT", prevBtn, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
        elseif direction == "RIGHT" then
            self:SetPoint("LEFT", prevBtn, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
        end
    else
        if direction == "UP" then
            self:SetPoint("BOTTOM", 0, SPELLFLYOUT_INITIAL_SPACING)
        elseif direction == "DOWN" then
            self:SetPoint("TOP", 0, -SPELLFLYOUT_INITIAL_SPACING)
        elseif direction == "LEFT" then
            self:SetPoint("RIGHT", -SPELLFLYOUT_INITIAL_SPACING, 0)
        elseif direction == "RIGHT" then
            self:SetPoint("LEFT", SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    end

    self:Show()
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutBtn XML Callbacks
-------------------------------------------------------------------------------

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnLoad(self)
    -- initialize the Bliz ActionButton
    self:SmallActionButtonMixin_OnLoad()
    self.PushedTexture:SetSize(31.6, 30.9)
    self:RegisterForDrag("LeftButton")
    _G[self:GetName().."Count"]:SetPoint("BOTTOMRIGHT", 0, 0)
    self.maxDisplayCount = 99
    self:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    -- coerce the Bliz ActionButton into a ButtonOnFlyoutMenu
    ButtonOnFlyoutMenu.oneOfUs(self)
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnMouseUp(self)
    local isDragging = GetCursorInfo()
    if isDragging then
        self:onReceiveDragAddIt()
    end
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnReceiveDrag(self)
    self:onReceiveDragAddIt()
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip(self)
    if self:isEmpty() then
        -- this is the empty btn in the catalog... or is it?
        if not self:getParent().isForCatalog then
            local btnId = self:getId()
            local flyoutId = self:getParent():getId()
            debug.info:out(X,X,"GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip()", "No btnDef found for flyoutId",flyoutId, "btnId",btnId)
        end
        return
    end

    local btnDef = self:getDef()
    local type = btnDef.type
    local someId

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)

        local tooltipSetter
        if type == ButtonType.SPELL or type == ButtonType.MOUNT then
            tooltipSetter = GameTooltip.SetSpellByID
            someId = btnDef.spellId or btnDef.mountId
        elseif type == ButtonType.ITEM or type == ButtonType.TOY then
            tooltipSetter = GameTooltip.SetItemByID
            someId = btnDef.itemId or btnDef.toyId
        elseif type == ButtonType.MACRO then
            tooltipSetter = function(zelf, macroId)
                local name, _, _ = GetMacroInfo(macroId)
                if not macroId then macroId = "NiL" end
                return GameTooltip:SetText("Macro: ".. macroId .." " .. (name or "UNKNOWN"))
            end
            someId = btnDef.macroId
        elseif type == ButtonType.PET then
            tooltipSetter = GameTooltip.SetCompanionPet
            someId = btnDef.petGuid
        end

        if tooltipSetter and someId and tooltipSetter(GameTooltip, someId) then
            self.UpdateTooltip = GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip
        else
            self.UpdateTooltip = nil
        end
    else
        local parent = self:GetParent():GetParent():GetParent():GetParent()
        if parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        GameTooltip:SetText(btnDef.name, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        self.UpdateTooltip = nil
    end
end

-- pickup an existing button from an existing flyout
---@param self ButtonOnFlyoutMenu
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnDragStart(self)
    self:onDragStartDoPickup()
end
