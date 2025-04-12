-- FlyoutMenu
-- methods and functions for flyout creation, behavior, etc

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

---@class FlyoutMenu -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field id string
---@field isForGerm boolean
---@field isForCatalog boolean
---@field nameSuffix string part of its name used to identify it as a flyout frame
---@field displaceBtnsHere number used to push buttons out of the way during "OnHover"
---@type FlyoutMenu|SpellFlyoutMixin|FlyoutPopupMixin
local FlyoutMenu = {
    ufoType = "FlyoutMenu",
    isForGerm = false,
    isForCatalog = false,
    nameSuffix = "_FlyoutMenu"
}
Ufo.FlyoutMenu = FlyoutMenu
GLOBAL_FlyoutMenu = FlyoutMenu
_G["FlyoutMenu"] = FlyoutMenu

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a FlyoutMenu instance
---@return FlyoutMenu
function FlyoutMenu:oneOfUs(fomu)
    -- merge the Bliz ActionButton object
    -- with this class's methods, functions, etc
    return deepcopy(self, fomu)
end

---@return FlyoutMenu|SpellFlyoutMixin|FlyoutPopupMixin
function FlyoutMenu.new(germ)
    local myName = germ:GetName() .. FlyoutMenu.nameSuffix
    ---@type FlyoutMenu|SpellFlyoutMixin|FlyoutPopupMixin
    local protoSelf = CreateFrame(FrameType.FRAME, myName, germ, "UIUFO_FlyoutMenuTemplate") -- XML's mixin = FlyoutMenu
    ---@type FlyoutMenu
    --local self = FlyoutMenu:oneOfUs(protoSelf)
    --doBlizOnLoad(self)
    return protoSelf
end

---@return ButtonOnFlyoutMenu
function FlyoutMenu:getButtonFrame(i)
    return _G[ self:GetName().."_Button"..i ]
end

function FlyoutMenu:getBtnKids()
    -- eliminate the non-button UI element "Background" defined in ui.xml
    -- sometimes (during combat) it's already excluded from GetChildren() so... we have to jump through extra hoops
    local btnKids = self.btnKids
    if not btnKids then
        btnKids = { self:GetChildren() }
        while btnKids[1] and btnKids[1]:GetObjectType() ~= "CheckButton" do
            table.remove(btnKids, 1)
        end
        self.btnKids = btnKids
    end
    return btnKids
end

function FlyoutMenu:forEachButton(handler)
    for i, button in ipairs(self:getBtnKids()) do
        if button.ufoType == ButtonOnFlyoutMenu.ufoType then
            handler(button,i)
        end
    end
end

---@return ButtonOnFlyoutMenu
function FlyoutMenu:getBtn1()
    return self:getBtnKids()[1]
end

-- use non-local "global" variables to save values between executions
-- because GetParent() returns nil during combat lockdown
local CLOSE_ON_CLICK_SCRIPTLET = [=[
    -- only trigger on mouse UP.  the down variable is passed in by the Bliz API
    if down then return end

    if not flyoutMenu then
        flyoutMenu = self:GetParent()
    end

    if not germ then
        germ = flyoutMenu:GetParent()
    end

    local doClose = germ:GetAttribute("doCloseOnClick")
    if doClose then
        --print("CLOSING: ", germ:GetName() )
        flyoutMenu:Hide()
        flyoutMenu:SetAttribute("doCloseFlyout", false)
		flyoutMenu:ClearBindings()
    end
]=]

function FlyoutMenu:installHandlerForCloseOnClick()
    if self.isCloserInitialized or not self.isForGerm then return end

    self:forEachButton(function(button)
        SecureHandlerWrapScript(button, "PostClick", button, CLOSE_ON_CLICK_SCRIPTLET) -- Is the the cause of "Cannot call restricted closure from insecure code" ??? NOPE
        SecureHandlerExecute(button, CLOSE_ON_CLICK_SCRIPTLET) -- initialize the scriptlet's "global" vars
    end)

    self.isCloserInitialized = true
end

function FlyoutMenu:getId()
    return self.id or self.flyoutId
end

function FlyoutMenu:setId(flyoutId)
    self.id = flyoutId
    self.flyoutId = flyoutId
end

function FlyoutMenu:ensureId(flyoutId)
    if self == FlyoutMenu then
        assert(flyoutId, ADDON_NAME..": You must provide the flyoutId when invoking this as a CLASS method.")
    else
        flyoutId = self:getId()
        assert(flyoutId, ADDON_NAME..": This FlyoutMenu has not been assigned an id / flyoutId.")
    end
    return flyoutId
end

-- when the user picks up a flyout from the catalog (or a germ from the actionbars?)
-- we need a draggable UI element, so create a dummy macro with the same icon as the flyout
function FlyoutMenu:pickup(flyoutId)
    if isInCombatLockdown("Drag and drop") then return; end

    flyoutId = self:ensureId(flyoutId)

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local icon = flyoutConf:getIcon()
    local proxy = GermCommander:newGermProxy(flyoutId, icon)
    PickupMacro(proxy)
end

---@return FlyoutDef
function FlyoutMenu:getDef(flyoutId)
    flyoutId = self:ensureId(flyoutId)
    return FlyoutDefsDb:get(flyoutId)
end

-- TODO: merge updateForCatalog() and updateForGerm()
---@param flyoutId string
function FlyoutMenu:updateForCatalog(flyoutId)
    self.enableTwinkle = true
    self:setId(flyoutId)
    local dir = "RIGHT"
    self.direction = dir

    local prevButton = nil;
    local numButtons = 0;
    local flyoutDef = self:getDef()
    zebug.trace:dumpy("flyoutDef",flyoutDef)
    local n = flyoutDef:howManyButtons()
    local rows = n+1 -- one extra for an empty space

    for i=1, math.min(rows, MAX_FLYOUT_SIZE) do
        local btnFrame = self:getButtonFrame(i)
        local btnDef = flyoutDef:getButtonDef(i)

        if self.displaceBtnsHere then
            if i == self.displaceBtnsHere then
                btnDef = nil -- force it to be the empty slot
            elseif i > self.displaceBtnsHere then
                btnDef = flyoutDef:getButtonDef(i - 1)
            end
        else
             btnDef = flyoutDef:getButtonDef(i)
        end

        if btnDef then
            btnFrame:setDef(btnDef)
            btnFrame:setIcon( btnDef:getIcon() )
        else
            -- the empty slot on the end
            btnFrame:setDef(nil)
            btnFrame:setIcon(nil)
            btnFrame:setExcluderVisibility(nil)
        end

        btnFrame:setGeometry(dir, prevButton)

        prevButton = btnFrame
        numButtons = i
    end

    -- Hide unused buttons
    local unusedButtonIndex = numButtons+1
    local btnFrame = self:getButtonFrame(unusedButtonIndex)
    while btnFrame do
        btnFrame:Hide()
        unusedButtonIndex = unusedButtonIndex+1
        btnFrame = self:getButtonFrame(unusedButtonIndex)
    end

    if numButtons == 0 then
        self:Hide()
        return
    end

    self:ClearAllPoints()

    -- assuming dir == RIGHT
    self:SetPoint(Anchor.LEFT, self.parent, Anchor.RIGHT);
    self:SetHeight(prevButton:GetHeight())
    self:SetWidth((prevButton:GetWidth()+SPELLFLYOUT_DEFAULT_SPACING) * numButtons - SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)

    self:setBorderGeometry()
end

---@param germ Germ
function FlyoutMenu:updateForGerm(germ)
    self:SetParent(germ)
    self.direction = germ:getDirection()
    local flyoutId = germ:getFlyoutId()
    self:setId(flyoutId)
    local flyoutDef = self:getDef(flyoutId)
    zebug.trace:dumpy("flyoutDef",flyoutDef)
    local usableFlyout = flyoutDef:filterOutUnusable()
    local btnNumber = 0

    ---@param btnFrame ButtonOnFlyoutMenu
    self:forEachButton(function(btnFrame, i)
        local btnDef = usableFlyout:getButtonDef(i)
        btnFrame:setDef(btnDef)
        zebug.trace:print("i",i, "btnDef", btnDef)

        if btnDef then
            zebug.trace:print("i",i, "type", btnDef.type, "ID",btnDef:getIdForBlizApi(), "name",btnDef.name)
            btnFrame:setIcon( btnDef:getIcon() )
            --btnFrame:setGeometry(self.direction) -- this call breaks the btns on the flyout - they all collapse into the same spot
            --TODO: figure out why
            btnFrame:SetAttribute("UFO_NAME",btnDef.name) -- SECURE TEMPLATE

            -- label the keybinds
            btnNumber = btnNumber + 1 -- TODO: make first keybind same as the UFO's
            updateHotKeyLabel(btnFrame, btnNumber)
        else
            btnFrame:setIcon(DEFAULT_ICON)
            btnFrame:SetAttribute("UFO_NAME",nil) -- SECURE TEMPLATE
            return
        end
    end)

    if not self.hasOnHide then
        zebug.info:print("setting OnHide for",self:GetName())
        local btn1 = self:getBtn1()
        btn1:SetFrameRef("flyout",self)
        btn1:SetAttribute("_onhide", "flyout:ClearBindings()") -- v11.1 replaces btn1:SetScript() and SecureHandlerExecute(germ, "keybindKeeper:ClearBindings()")
        self.hasOnHide = true
    end

    germ:SetAttribute("UFO_FLYOUT_MOD_TIME", flyoutDef:getModStamp())
    self:setBorderGeometry()
end

function updateHotKeyLabel(btnFrame, btnNumber)
    local hotKeyLabel
    if Config:get("flyoutButtonsWillBind") then
        if btnNumber < 11 then
            hotKeyLabel = (btnNumber == 10) and "0" or tostring(btnNumber)
        end
    end
    btnFrame.HotKey:SetText(hotKeyLabel)
end

function FlyoutMenu:setBorderGeometry()
    local bg = self.Background
    local distance = 3
    local dir = self.direction

    bg.End:ClearAllPoints()
    bg.Start:ClearAllPoints()
    bg.VerticalMiddle:ClearAllPoints()
    bg.HorizontalMiddle:ClearAllPoints()

    if (dir == "UP") then
        bg.End:SetPoint(Anchor.TOP, 0, SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(bg.End, 0);
        SetClampedTextureRotation(bg.VerticalMiddle, 0);
        bg.Start:SetPoint(Anchor.TOP, bg.VerticalMiddle, Anchor.BOTTOM);
        SetClampedTextureRotation(bg.Start, 0);
        bg.HorizontalMiddle:Hide();
        bg.VerticalMiddle:Show();
        --bg.VerticalMiddle:ClearAllPoints();
        bg.VerticalMiddle:SetPoint(Anchor.TOP, bg.End, Anchor.BOTTOM);
        bg.VerticalMiddle:SetPoint(Anchor.BOTTOM, 0, distance);
    elseif (dir == "DOWN") then
        bg.End:SetPoint(Anchor.BOTTOM, 0, -SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(bg.End, 180);
        SetClampedTextureRotation(bg.VerticalMiddle, 180);
        bg.Start:SetPoint(Anchor.BOTTOM, bg.VerticalMiddle, Anchor.TOP);
        SetClampedTextureRotation(bg.Start, 180);
        bg.HorizontalMiddle:Hide();
        bg.VerticalMiddle:Show();
        --bg.VerticalMiddle:ClearAllPoints();
        bg.VerticalMiddle:SetPoint(Anchor.BOTTOM, bg.End, Anchor.TOP);
        bg.VerticalMiddle:SetPoint(Anchor.TOP, 0, -distance);
    elseif (dir == "LEFT") then
        bg.End:SetPoint(Anchor.LEFT, -SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(bg.End, 270);
        SetClampedTextureRotation(bg.HorizontalMiddle, 180);
        bg.Start:SetPoint(Anchor.LEFT, bg.HorizontalMiddle, Anchor.RIGHT);
        SetClampedTextureRotation(bg.Start, 270);
        bg.VerticalMiddle:Hide();
        bg.HorizontalMiddle:Show();
        --bg.HorizontalMiddle:ClearAllPoints();
        bg.HorizontalMiddle:SetPoint(Anchor.LEFT, bg.End, Anchor.RIGHT);
        bg.HorizontalMiddle:SetPoint(Anchor.RIGHT, -distance, 0);
    elseif (dir == "RIGHT") then
        bg.End:SetPoint(Anchor.RIGHT, SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(bg.End, 90);
        SetClampedTextureRotation(bg.HorizontalMiddle, 0);
        bg.Start:SetPoint(Anchor.RIGHT, bg.HorizontalMiddle, Anchor.LEFT);
        SetClampedTextureRotation(bg.Start, 90);
        bg.VerticalMiddle:Hide();
        bg.HorizontalMiddle:Show();
        --bg.HorizontalMiddle:ClearAllPoints();
        bg.HorizontalMiddle:SetPoint(Anchor.RIGHT, bg.End, Anchor.LEFT);
        bg.HorizontalMiddle:SetPoint(Anchor.LEFT, distance, 0);
    end
    self:SetBorderColor(0.7, 0.7, 0.7);
    --self:SetBorderSize(47);
end

---@param flyoutMenu FlyoutMenu
function doBlizOnLoad(flyoutMenu)
    --SpellFlyout_OnLoad(flyoutMenu) - breaks... um... something.  I removed this days ago :-/
end

---@param btn ButtonOnFlyoutMenu
function FlyoutMenu:displaceButtonsOnHover(index)
    if not self.isForCatalog then
        return
    end

    if GetCursorInfo() then
        self.displaceBtnsHere = index
        self:updateForCatalog(self.flyoutId)
    end
end

function FlyoutMenu:restoreButtonsAfterHover()
    ---@type FlyoutMenu
    if not self.displaceBtnsHere then
        return
    end

    if self:isMouseOverMeOrKids() then
        return
    end

    self.displaceBtnsHere = nil
    self:updateForCatalog( self.flyoutId )
end

-- currently unused -- TODO use it
---@param btnDef ButtonDef
---@param btnIndex number
function FlyoutMenu:addBtnAt(btnDef, btnIndex)
    local flyoutDef = self:getDef()
    flyoutDef:replaceButton(btnIndex, btnDef) -- TODO - repects displace
    self:updateForCatalog(self.flyoutId)
    GermCommander:updateAll() -- TODO: only update germs for flyoutId
end

function FlyoutMenu:isMouseOverMeOrKids()
    return self:IsMouseOver() or self.mouseOverKid
end

function FlyoutMenu:setMouseOverKid(kid)
    self.mouseOverKid = kid:GetName()
end

function FlyoutMenu:clearMouseOverKid(kid)
    if self.mouseOverKid == kid:GetName() then
        self.mouseOverKid = nil
    end
end

-------------------------------------------------------------------------------
-- XML Callbacks
-------------------------------------------------------------------------------

function FlyoutMenu:onLeave()
    self:restoreButtonsAfterHover()
end

function FlyoutMenu:onLoadForGerm()
    doBlizOnLoad(self)
    zebug.info:name("ForGerm_OnLoad"):print("flyoutMenu", self:GetName())
    -- initialize fields
    FlyoutMenu:oneOfUs(self)
    Germ.flyoutMenu = self -- not used anywhere?
    self.isForGerm = true
    self.isSharedByAllGerms = true
end

function FlyoutMenu:onLoadForCatalog()
    doBlizOnLoad(self)
    zebug.info:name("ForCatalog_OnLoad"):print("flyoutMenu", self:GetName())

    -- initialize fields
    local self = FlyoutMenu:oneOfUs(self)
    Catalog.flyoutMenu = self
    self.isForCatalog = true
    self:forEachButton(ButtonOnFlyoutMenu.installExcluder)
end

-- throttle OnUpdate because it can fire as often as FPS and is very resource intensive
local ON_UPDATE_TIMER_FREQUENCY = 1.0
local onUpdateTimer = ON_UPDATE_TIMER_FREQUENCY

function FlyoutMenu:onUpdate(elapsed)
    onUpdateTimer = onUpdateTimer + elapsed
    if onUpdateTimer < ON_UPDATE_TIMER_FREQUENCY then
        return
    end
    onUpdateTimer = 0

    zebug.trace:print("elapsed",elapsed)
    self:updateAllBtnCooldownsEtc()
end

-- Is the the cause of "Cannot call restricted closure from insecure code" ???
-- it's set in the XML via <OnShow  method="onShow"/>
function FlyoutMenu:onShow()
    zebug.error:print("WOOOO? am even I being called???") -- nope, I commented out the XML.  no effect on "Cannot call restricted closure from insecure code"
    local originalEventsRegistered = self.eventsRegistered -- SpellFlyout_OnShow will reset this so snapshot it
    SpellFlyout_OnShow(self) -- call Blizzard handler
    -- TODO: v11.1 - is the above dead and gone by way of Cata ?!  Do I need to call self:OnShow()
    self:updateAllBtnCooldownsEtc()

    -- Cooldown indicators are enabled by the above which is usually sufficient.
    -- But, the following event registrations support the rare condition of
    -- a flyout is still open while one of its spells/items/etc is being cast/used/etc and completes.
    -- At that point, flyoutMenu:updateAllBtnCooldownsEtc() must be called again via these events
    -- because there won't be a OnShow event to do so.
    if not originalEventsRegistered then
        self:RegisterEvent("BAG_UPDATE_COOLDOWN") -- to support items
        self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN") -- to support items
        -- TODO: v11.1 - do I need to listen to more events?  Different / more specific ones?
    end
end

function FlyoutMenu:onHide()
    if (self.eventsRegistered == true) then
        -- supplement SpellFlyout_OnHide() with extra events specifically for items
        self:UnregisterEvent("BAG_UPDATE_COOLDOWN"); -- to support items
        self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- to support items
    end
    SpellFlyout_OnHide(self) -- call Blizzard handler (it sets eventsRegistered = false)
    -- TODO: v11.1 - is the above dead and gone by way of Cata ?!  Do I need to call self:OnHide()
end

function FlyoutMenu:updateAllBtnCooldownsEtc()
    zebug.trace:print("self:getId()",self:getId())
    self:forEachButton(ButtonOnFlyoutMenu.FUNC_updateCooldownsAndCountsAndStatesEtc)
end
