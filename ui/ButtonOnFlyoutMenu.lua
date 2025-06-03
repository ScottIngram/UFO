-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(zVol or Zebug.INFO)

---@class ButtonOnFlyoutMenu : UfoMixIn
---@field ufoType string The classname
---@field id number unique identifier
---@field nopeIcon Frame w/ a little X indicator

---@type ButtonOnFlyoutMenu | BOFM_INHERITANCE
ButtonOnFlyoutMenu = {
    ufoType = "ButtonOnFlyoutMenu",
}
UfoMixIn:mixInto(ButtonOnFlyoutMenu)
GLOBAL_ButtonOnFlyoutMenu = ButtonOnFlyoutMenu

---@alias BOFM_INHERITANCE  Button_Mixin | SpellFlyoutPopupButtonMixin | SmallActionButtonTemplate | SecureActionButtonTemplate | Frame
---@alias BOFM_TYPE ButtonOnFlyoutMenu | BOFM_INHERITANCE

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:getName()
    local btnDef = self:getDef()
    return (btnDef and btnDef:getName()) or "empty"
end

function ButtonOnFlyoutMenu:getId()
    -- the button ID never changes because it's never actually dragged or moved.
    -- It's the underlying btnDef that moves from one button to another.
    return self:GetID()
end

ButtonOnFlyoutMenu.getLabel = ButtonOnFlyoutMenu.getName

---@return FlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:getParent()
    return self:GetParent()
end

function ButtonOnFlyoutMenu:isEmpty()
    return not self:hasDef()
end

function ButtonOnFlyoutMenu:isForCatalog()
    return self:getParent().isForCatalog
end

function ButtonOnFlyoutMenu:hasDef()
    return self.btnDef and true or false
end

---@return ButtonDef
function ButtonOnFlyoutMenu:getDef()
    return self.btnDef
end

---@param btnDef ButtonDef
function ButtonOnFlyoutMenu:setDef(btnDef, event)
    self.btnDef = btnDef
    self:copyDefToBlizFields()

    -- install click behavior but only if it's on a Germ (i.e. not in the Catalog)
    local flyoutMenu = self:GetParent()
    if flyoutMenu.isForGerm then -- essentially, not self.isForCatalog
        self:updateSecureClicker(MouseClick.ANY, event)
        -- TODO: v11.1 build this into my Button_Mixin
        safelySetAttribute(self, "UFO_NO_RND", btnDef and btnDef.noRnd or nil) -- SECURE TEMPLATE
    else
        self:setExcluderVisibility()
    end
end

local emptyTable = {}

-- TODO: eval if these are still used now that I've migrated away from the old CATA code
-- TODO: eval if these are tainty.  If so, can I SetAttribute instead?
-- TODO: should I move this into Button_Mixin ?
function ButtonOnFlyoutMenu:copyDefToBlizFields()
    local d = self.btnDef or emptyTable
    -- the names on the left are used deep inside Bliz code by the likes of SpellFlyoutButton_UpdateCooldown() etc
    self.actionType = d.type
    self.actionID   = d.spellId or d.itemId or d.toyId or d.mountId -- or d.petGuid
    self.spellID    = d.spellId
    self.itemID     = d.itemId
    self.mountID    = d.mountId
    self.battlepet  = d.petGuid
end

---@param isDown MouseClick
function ButtonOnFlyoutMenu:handleExcluderClick(mouseClick, isDown)
    local btnDef = self:getDef()
    if not btnDef then return end

    if mouseClick == MouseClick.RIGHT and isDown then
        local event = Event:new(self, "bofm-excluder-click")
        zebug.info:event(event):owner(self):print("name",btnDef.name, "changing exclude from",btnDef.noRnd, "to", not btnDef.exclude)
        btnDef.noRnd = not btnDef.noRnd
        self:setExcluderVisibility()

        local flyoutDef = self:getParent():getDef()
        flyoutDef:setModStamp()
        GermCommander:notifyOfChangeToFlyoutDef(flyoutDef.id, event)
    end
end

function ButtonOnFlyoutMenu:setExcluderVisibility()
    if not self.nopeIcon then return end
    if isInCombatLockdownQuiet("toggling the exclusion setting") then return end

    local btnDef = self:getDef()
    local noRnd = btnDef and btnDef.noRnd or nil

    self:SetAttribute("UFO_NO_RND", noRnd) -- SECURE TEMPLATE

    if noRnd then
        self.nopeIcon:Show()
    else
        self.nopeIcon:Hide()
    end
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


function ButtonOnFlyoutMenu:onReceiveDragAddIt(event)
    local flyoutMenu = self:getParent()
    if not flyoutMenu.isForCatalog then return end -- only the flyouts in the catalog are valid drop targets.  TODO: let flyouts on the germs receive too?

    local crsDef = ButtonDef:getFromCursor(event)
    if not crsDef then
        zebug.error:event(event):owner(self):print("Sorry, unsupported type:", Ufo.unknownType)
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
    if crsDef.brokenPetCommandId2 then
        local twin = ButtonDef:getFromCursor(event)
        twin.brokenPetCommandId = twin.brokenPetCommandId2
        twin.brokenPetCommandId2 = nil
        twin.name = nil
        flyoutDef:insertButton(btnIndex+1, twin)
    end

    Cursor:clear(event)
    GermCommander:notifyOfChangeToFlyoutDef(flyoutId, event)
    flyoutMenu.displaceBtnsHere = nil
    flyoutMenu:updateForCatalog(flyoutId, event)
    Ufo.pickedUpBtn = nil
end

-- only used by FlyoutMenu:updateForCatalog()
function ButtonOnFlyoutMenu:setGeometry(direction, prevBtn)
    self:ClearAllPoints()
    if prevBtn then
        if direction == "UP" then
            self:SetPoint(Anchor.BOTTOM, prevBtn, Anchor.TOP, 0, SPELLFLYOUT_DEFAULT_SPACING)
        elseif direction == "DOWN" then
            self:SetPoint(Anchor.TOP, prevBtn, Anchor.BOTTOM, 0, -SPELLFLYOUT_DEFAULT_SPACING)
        elseif direction == "LEFT" then
            self:SetPoint(Anchor.RIGHT, prevBtn, Anchor.LEFT, -SPELLFLYOUT_DEFAULT_SPACING, 0)
        elseif direction == "RIGHT" then
            self:SetPoint(Anchor.LEFT, prevBtn, Anchor.RIGHT, SPELLFLYOUT_DEFAULT_SPACING, 0)
        end
    else
        if direction == "UP" then
            self:SetPoint(Anchor.BOTTOM, 0, SPELLFLYOUT_INITIAL_SPACING)
        elseif direction == "DOWN" then
            self:SetPoint(Anchor.TOP, 0, -SPELLFLYOUT_INITIAL_SPACING)
        elseif direction == "LEFT" then
            self:SetPoint(Anchor.RIGHT, -SPELLFLYOUT_INITIAL_SPACING, 0)
        elseif direction == "RIGHT" then
            self:SetPoint(Anchor.LEFT, SPELLFLYOUT_INITIAL_SPACING, 0)
        end
    end

    self:Show()
end

function ButtonOnFlyoutMenu:installExcluder(event)
    local i = self:GetID()
    zebug.trace:event(event):owner(self):print("i",i)

    local nopeIcon = self:CreateTexture("nope") -- name , layer , inherits , subLayer
    nopeIcon:SetPoint("TOPLEFT",-3,3)
    nopeIcon:SetTexture(3281887) -- 3281887, atlas: "common-search-clearbutton"
    nopeIcon:SetAtlas("common-search-clearbutton") -- 3281887, atlas: "common-search-clearbutton"
    nopeIcon:SetSize(10,10)
    nopeIcon:SetAlpha(0.75)

    self.nopeIcon = nopeIcon
    self:SetScript(Script.ON_CLICK, self.handleExcluderClick)
end

function ButtonOnFlyoutMenu:renderCooldownsAndCountsAndStatesEtcEtc(event)
    self:renderCooldownsAndCountsAndStatesEtc(self,event)
end

function ButtonOnFlyoutMenu:onReceiveDragAddItTryCatch(event)
    -- YAY!  Bliz's code is eating exceptions now so I've got to catch and report them my damn self!
    local isOk, err = pcall( function()  self:onReceiveDragAddIt(event) end  )
    if not isOk then
        zebug.error:event(event):owner(self):print("Drag and drop failed! ERROR",err)
    end
end

-- taken from SpellFlyoutButton_SetTooltip in bliz API SpellFlyout.lua
---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:setTooltip()
    if self:isEmpty() then
        -- this is the empty btn in the catalog... or is it?
        if not self:isForCatalog() then
            local btnId = self:getId()
            local flyoutId = self:getParent():getId()
            zebug.info:print("No btnDef found for flyoutId",flyoutId, "btnId",btnId)
        end
        return
    end

    local btnDef = self:getDef()

    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
    else
        GameTooltip:SetOwner(self, TooltipAnchor.LEFT)
    end

    local tooltipSetter = btnDef:getToolTipSetter()

    if tooltipSetter then
        tooltipSetter()
    else
        GameTooltip:SetText(btnDef:getName(), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    end
end

-------------------------------------------------------------------------------
-- XML Callbacks - see ui/ui.xml
-------------------------------------------------------------------------------

-- TODO: should this be in Button_Mixin so that Germ can enjoy it too?
---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onLoad()
    -- leverage inheritance - invoke parent's OnLoad()
    self:SmallActionButtonMixin_OnLoad()
    SecureHandler_OnLoad(self) -- TODO: v11.1 evaluate if this is actually safe or is it causing taint

    -- initialize my fields
    self.maxDisplayCount = 99 -- used inside Bliz code - limits how big of a number to show on stacks

    -- Register for events
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("AnyDown", "AnyUp")
    -- TODO - register for spell and cooldown events (?)
end

---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu:onEnter()
    self:setTooltip()

    -- push catalog buttons out of the way for easier btn relocation
    ---@type FlyoutMenu
    local flyoutMenu = self:GetParent()
    flyoutMenu:setMouseOverKid(self)
    flyoutMenu:displaceButtonsOnHover(self:getId())
end

function ButtonOnFlyoutMenu:onLeave()
    GameTooltip:Hide()
    ---@type FlyoutMenu
    local flyoutMenu = self:GetParent()
    flyoutMenu:clearMouseOverKid(self)
    flyoutMenu:restoreButtonsAfterHover()
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onMouseUp()
    -- used during drag & drop in the catalog. but also is called by buttons on germ flyouts
    local isDragging = GetCursorInfo()
    if isDragging then
        zebug.info:mTriangle():owner(self):runEvent(Event:new(self, "bofm-mouse-up"), function(event)
            self:onReceiveDragAddItTryCatch(event)
        end)
--        self:onReceiveDragAddItTryCatch(Event:new(self, "mouse-up"))
    end
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onReceiveDrag()
    zebug.info:mTriangle():owner(self):runEvent(Event:new(self, "bofm-drag-hit-me"), function(event)
        self:onReceiveDragAddItTryCatch(event)
    end)
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
        zebug.info:mTriangle():owner(self):runEvent(Event:new(self, "bofm-drag-hit-me"), function(event)
            self:onReceiveDragAddItTryCatch(event)
        end)
        return
    end

    local btnDef = self:getDef()
    if self:abortIfUnusable(btnDef) then
        -- TODO - work some sort of proxy magic to let a toon drag around a spell they don't know
        return
    end

    zebug.info:mTriangle():owner(self):runEvent(Event:new(self, "bofm-dragged-away"), function(event)
        btnDef:pickupToCursor(event)
        local flyoutId = flyoutFrame:getId()
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        flyoutDef:removeButton(self:getId())
        self:setDef(nil, event)
        flyoutFrame:updateForCatalog(flyoutId, event)
        GermCommander:notifyOfChangeToFlyoutDef(flyoutId, event)
    end)
end

-------------------------------------------------------------------------------
-- OVERRIDES of
-- SmallActionButtonMixin methods
-- acquired via SmallActionButtonTemplate
-- See Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButton.lua
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:UpdateButtonArt()
    SmallActionButtonMixin.UpdateButtonArt(self)
    self:ClearNormalTexture() -- get rid of the odd nameless Atlas member that is the wrong size
    self.NormalTexture:Show() -- show the square
    self.NormalTexture:SetSize(32,31)
end

