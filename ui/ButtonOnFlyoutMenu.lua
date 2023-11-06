-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field id number unique identifier

---@type ButtonOnFlyoutMenu|ButtonMixin
ButtonOnFlyoutMenu = {
    ufoType = "ButtonOnFlyoutMenu",
}
ButtonMixin:inject(ButtonOnFlyoutMenu)

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- can't do my usual metatable magic because (I think) the Bliz UI objects already have.
-- so, instead, just copy all of my methods onto the Bliz UI object
function ButtonOnFlyoutMenu:oneOfUs(btnOnFlyout)
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

    -- install click behavior but only if it's on a Germ (i.e. not in the Catalog)
    local flyoutMenu = self:GetParent()
    if flyoutMenu.isForGerm then -- essentially, not self.isForCatalog
        self:updateSecureClicker(MouseClick.ANY)
    end
end

function ButtonOnFlyoutMenu:copyDefToBlizFields()
    local d = self.btnDef or {}
    -- the names on the left are used deep inside Bliz code by the likes of SpellFlyoutButton_UpdateCooldown() etc
    self.actionType = d.type
    self.actionID   = d.spellId or d.itemId or d.toyId or d.mountId -- or d.petGuid
    self.spellID    = d.spellId
    self.itemID     = d.itemId
    self.mountID    = d.mountId
    self.battlepet  = d.petGuid
end

-- pickup an existing button from an existing flyout
---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu:onDragStartDoPickup()
    if isInCombatLockdown("Drag and drop") then return end
    if self:isEmpty() then return end

    ---@type FlyoutMenu
    local flyoutFrame = self:GetParent()
    if not flyoutFrame.isForCatalog then
        return
    end

    local isDragging = GetCursorInfo()
    if isDragging then
        self:onReceiveDragAddIt()
        return
    end

    local btnDef = self:getDef()
    if self:abortIfUnusable(btnDef) then
        -- TODO - work some sort of proxy magic to let a toon drag around a spell they don't know
        return
    end

    btnDef:pickupToCursor()
    local flyoutId = flyoutFrame:getId()
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    flyoutDef:removeButton(self:getId())
    self:setDef(nil)
    flyoutFrame:updateForCatalog(flyoutId)
    GermCommander:updateAll()
end

---@param btnDef ButtonDef
function ButtonOnFlyoutMenu:abortIfUnusable(btnDef)
    if (not btnDef) or btnDef:isUsable() then
        return false
    end

    local name = btnDef:getName()
    local msg = QUOTE .. name .. QUOTE .. " " .. L10N.CAN_NOT_MOVE
    msgUser(msg)
    zebug.warn:alert(msg)
    return true
end


function ButtonOnFlyoutMenu:onReceiveDragAddIt()
    local flyoutMenu = self:getParent()
    if not flyoutMenu.isForCatalog then return end -- only the flyouts in the catalog are valid drop targets.  TODO: let flyouts on the germs receive too?

    local crsDef = ButtonDef:getFromCursor()
    if not crsDef then
        zebug.warn:print("Sorry, unsupported type:", Ufo.unknownType)
        return
    end

    local btnDef = self:getDef()
    if self:abortIfUnusable(btnDef) then
        return
    end

    local flyoutId = flyoutMenu:getId()
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    local btnIndex = self:getId()

    flyoutDef:insertButton(btnIndex, crsDef)

    ClearCursor()
    GermCommander:updateAll() -- TODO: only update germs for flyoutId
    flyoutMenu.displaceBtnsHere = nil
    flyoutMenu:updateForCatalog(flyoutId)
    Ufo.pickedUpBtn = nil
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

---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu.FUNC_updateCooldownsAndCountsAndStatesEtc(self)
    self:updateCooldownsAndCountsAndStatesEtc()
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutBtn XML Callbacks
-------------------------------------------------------------------------------

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnLoad(self)
    -- coerce the Bliz ActionButton into a ButtonOnFlyoutMenu
    ButtonOnFlyoutMenu:oneOfUs(self)

    -- initialize my fields
    self.maxDisplayCount = 99 -- limits how big of a number to show on stacks

    -- initialize the Bliz ActionButton
    self:SmallActionButtonMixin_OnLoad()
    self.PushedTexture:SetSize(31.6, 30.9)
    self:getCountFrame():SetPoint("BOTTOMRIGHT", 0, 0)

    -- Drag Handler
    self:RegisterForDrag("LeftButton")
    local pickupAction = [[print("WEEE"); return "action", self:GetAttribute("action")]]
    --self:SetAttribute("_ondragstart", pickupAction)
    --self:SetAttribute("_onreceivedrag", pickupAction)

    -- Click handler
    --self:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    self:RegisterForClicks("AnyDown", "AnyUp")
    -- see also ButtonMixin:updateSecureClicker
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

---@param self ButtonOnFlyoutMenu
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnEnter(self)
    self:setTooltip()

    -- push catalog buttons out of the way for easier btn relocation
    ---@type FlyoutMenu
    local flyoutMenu = self:GetParent()
    flyoutMenu:setMouseOverKid(self)
    flyoutMenu:displaceButtonsOnHover(self:getId())
end

function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnLeave(self)
    GameTooltip:Hide()
    ---@type FlyoutMenu
    local flyoutMenu = self:GetParent()
    flyoutMenu:clearMouseOverKid(self)
    flyoutMenu:restoreButtonsAfterHover()
end

-- taken from SpellFlyoutButton_SetTooltip in bliz API SpellFlyout.lua
---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:setTooltip()
    if self:isEmpty() then
        -- this is the empty btn in the catalog... or is it?
        if not self:getParent().isForCatalog then
            local btnId = self:getId()
            local flyoutId = self:getParent():getId()
            zebug.info:print("No btnDef found for flyoutId",flyoutId, "btnId",btnId)
        end
        return
    end

    local btnDef = self:getDef()

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)

        local tooltipSetter = btnDef:getToolTipSetter()

        if tooltipSetter and tooltipSetter() then
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
        GameTooltip:SetText(btnDef.getName(), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        self.UpdateTooltip = nil
    end
end

-- pickup an existing button from an existing flyout
---@param self ButtonOnFlyoutMenu
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnDragStart(self)
    self:onDragStartDoPickup()
end
