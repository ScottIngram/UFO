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
---@field nopeIcon Frame w/ a little X indicator

---@type ButtonOnFlyoutMenu|ButtonMixin|SmallActionButtonMixin|BaseActionButtonMixin
ButtonOnFlyoutMenu = {
    ufoType = "ButtonOnFlyoutMenu",
}
GLOBAL_ButtonOnFlyoutMenu = ButtonOnFlyoutMenu

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

function ButtonOnFlyoutMenu:getName()
    local btnDef = self:getDef()
    return (btnDef and btnDef:getName()) or "UnKnOwN"
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
function ButtonOnFlyoutMenu:setDef(btnDef)
    self.btnDef = btnDef
    self:copyDefToBlizFields()

    -- install click behavior but only if it's on a Germ (i.e. not in the Catalog)
    local flyoutMenu = self:GetParent()
    if flyoutMenu.isForGerm then -- essentially, not self.isForCatalog
        self:updateSecureClicker(MouseClick.ANY)
        -- TODO: v11.1 build this into my ButtonMixin
        safelySetAttribute(self, "UFO_NO_RND", btnDef and btnDef.noRnd or nil) -- SECURE TEMPLATE
    else
        self:setExcluderVisibility()
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

---@param isDown MouseClick
function ButtonOnFlyoutMenu:handleExcluderClick(mouseClick, isDown)
    local btnDef = self:getDef()
    if not btnDef then return end

    if mouseClick == MouseClick.RIGHT and isDown then
        zebug.info:print("name",btnDef.name, "changing exclude from",btnDef.noRnd, "to", not btnDef.exclude)
        --zebug.error:dumpKeys(self)
        btnDef.noRnd = not btnDef.noRnd
        self:setExcluderVisibility()

        local flyoutDef = self:getParent():getDef()
        flyoutDef:setModStamp()
        GermCommander:updateGermsFor(flyoutDef.id)
    end
end

function ButtonOnFlyoutMenu:setExcluderVisibility()
    if not self.nopeIcon then return end

    local btnDef = self:getDef()
    local noRnd = btnDef and btnDef.noRnd or nil

    self:SetAttribute("UFO_NO_RND", noRnd) -- SECURE TEMPLATE

    if noRnd then
        self.nopeIcon:Show()
    else
        self.nopeIcon:Hide()
    end
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
    if crsDef.brokenPetCommandId2 then
        local twin = ButtonDef:getFromCursor()
        twin.brokenPetCommandId = twin.brokenPetCommandId2
        twin.brokenPetCommandId2 = nil
        twin.name = nil
        flyoutDef:insertButton(btnIndex+1, twin)
    end

    ClearCursor()
    GermCommander:updateAll() -- TODO: only update germs for flyoutId
    flyoutMenu.displaceBtnsHere = nil
    flyoutMenu:updateForCatalog(flyoutId)
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

function ButtonOnFlyoutMenu:installExcluder(i)
    zebug.info:print("self",self,"i",i)

    local nopeIcon = self:CreateTexture("nope") -- name , layer , inherits , subLayer
    nopeIcon:SetPoint("TOPLEFT",-3,3)
    nopeIcon:SetTexture(3281887) -- 3281887, atlas: "common-search-clearbutton"
    nopeIcon:SetAtlas("common-search-clearbutton") -- 3281887, atlas: "common-search-clearbutton"
    nopeIcon:SetSize(10,10)
    nopeIcon:SetAlpha(0.75)

    self.nopeIcon = nopeIcon
    self:SetScript(Script.ON_CLICK, self.handleExcluderClick)
end

---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu.FUNC_updateCooldownsAndCountsAndStatesEtc(self)
    self:updateCooldownsAndCountsAndStatesEtc()
end

-------------------------------------------------------------------------------
-- XML Callbacks
-------------------------------------------------------------------------------

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onLoad()
    -- coerce the Bliz ActionButton into a ButtonOnFlyoutMenu
    --ButtonOnFlyoutMenu:oneOfUs(self) - nope, this is now performed vix xml's mixin

    -- initialize my fields
    self.maxDisplayCount = 99 -- limits how big of a number to show on stacks

    -- initialize the Bliz ActionButton
    -- if I call neither of these: no badly sized overlay (yay) but a popup arrow appears (boo)
    self:SmallActionButtonMixin_OnLoad() -- this does some things right but some things wrong
    --self:BaseActionButtonMixin_OnLoad()


    --self.PushedTexture:SetSize(31.6, 30.9)
    --self:getCountFrame():SetPoint("BOTTOMRIGHT", 0, 0) -- this seems tgo be happening automatically now... NOPE, is bug!  Bliz code assume actionSlot=1 TODO: v11.1 fix

    -- Drag Handler
    self:RegisterForDrag("LeftButton")
    local pickupAction = [[print("WEEE"); return "action", self:GetAttribute("action")]]
    --self:SetAttribute("_ondragstart", pickupAction)-- try to use this
    --self:SetAttribute("_onreceivedrag", pickupAction)

    -- Click handler
    --self:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    self:RegisterForClicks("AnyDown", "AnyUp")
    -- see also ButtonMixin:updateSecureClicker

    --self:makeSafeSetAttribute() -- experiment that didn't pan out

    SecureHandler_OnLoad(self) -- TODO: v11.1 evaluate if this is actually safe or is it causing taint
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onMouseUp()
    -- used during drag & drop in the catalog. but also is called by buttons on germ flyouts
    local isDragging = GetCursorInfo()
    if isDragging then
        fuckYouHardBlizzard(self)
    end
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onReceiveDrag()
    fuckYouHardBlizzard(self)
end

function fuckYouHardBlizzard(self)
    -- YAY!  Bliz's code is eating exceptions now so I've got to catch and report them my damn self!
    local isOk, err = pcall( function()  self:onReceiveDragAddIt() end  )
    if not isOk then
        zebug.error:print("Drag and drop failed! ERROR",err)
    end
end

function ButtonOnFlyoutMenu:hideButtonFrame()
--[[
    self:ClearNormalTexture()
    self.NormalTexture:Show() -- 4615764
    self.NormalTexture:SetSize(32,31) -- 4615764
]]
end

function ButtonOnFlyoutMenu:showButtonFrame()
--[[
    self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame");-- UI-HUD-ActionBar-IconFrame-AddRow
    self.NormalTexture:SetTexture(4615764) -- 4615764
]]
end


function ButtonOnFlyoutMenu:UpdateButtonArt()

    SmallActionButtonMixin.UpdateButtonArt(self) -- the IsPressed highlight RIGHT size, but, it has the bad small frame
    --BaseActionButtonMixin.UpdateButtonArt(self);  -- BADx2 - the IsPressed highlight WRONG size, AND, it has the bad small frame

--[[
    zebug.error:ifMe1st(self):print("self:isForCatalog()", self:isForCatalog())
    if self:isForCatalog() then
        self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame"); -- what if set(nil) ? nil has no effect
    else
        self:ClearNormalTexture()
    end
]]



    --self:hideButtonFrame()
    self:ClearNormalTexture() -- get rid of the odd nameless Atlas member that is the wrong size
    self.NormalTexture:Show() -- show the square
    self.NormalTexture:SetSize(32,31)


    --[[
        _ = self.SlotArt        and self.SlotArt:Hide()
        _ = self.SlotBackground and self.SlotBackground:Hide()
    ]]
    --self.NormalTexture:SetSize(160, 160) -- what is this?
    --self.PushedTexture:SetSize(35, 35) -- fixes IsPressed highlight

    --self.NormalTexture:SetSize(99, 160) -- what is this?
--self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame"); -- what if set(nil) ? nil has no effect
    --self.NormalTexture:SetSize(1600, 160) -- what is this?
--self:ClearNormalTexture()
    --self:SetPushedAtlas("UI-HUD-ActionBar-IconFrame-Down");
    -- self.PushedTexture:SetDrawLayer("OVERLAY");
    --self.PushedTexture:SetSize(46, 45);
    --self.PushedTexture:SetSize(35, 35);

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

-- pickup an existing button from an existing flyout
---@param self ButtonOnFlyoutMenu
function ButtonOnFlyoutMenu:onDragStart()
    self:onDragStartDoPickup()
end
