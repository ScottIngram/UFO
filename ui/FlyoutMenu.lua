-- FlyoutMenu
-- methods and functions for flyout creation, behavior, etc

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@class FlyoutMenu : UfoMixIn
---@field ufoType string The classname
---@field id string
---@field isForGerm boolean
---@field isForCatalog boolean
---@field nameSuffix string part of its name used to identify it as a flyout frame
---@field displaceBtnsHere number used to push buttons out of the way during "OnHover"

---@type FlyoutMenu | FM_INHERITANCE
FlyoutMenu = {
    ufoType = "FlyoutMenu",
    isForGerm = false,
    isForCatalog = false,
    nameSuffix = "_FlyoutMenu"
}
UfoMixIn:mixInto(FlyoutMenu)
GLOBAL_FlyoutMenu = FlyoutMenu

---@alias FM_INHERITANCE  UfoMixIn | FlyoutPopupTemplate | SecureFrameTemplate | Frame
---@alias FM_TYPE FlyoutMenu | FM_INHERITANCE

---@type FlyoutMenu | FM_INHERITANCE for the benefit of my IDE's autocomplete
local ScriptHandlers = {}

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function FlyoutMenu:new(germ)
    local myName = germ:GetName() .. FlyoutMenu.nameSuffix
    ---@type FM_TYPE
    local self = CreateFrame(FrameType.FRAME, myName, germ, "UFO_FlyoutMenuTemplate") -- XML's mixin = FlyoutMenu

    -- calling self:GetParent() in any of the methods below returns some unknown object that is NOT the germ.
    -- but later, it will return the germ.  JFC.
    -- WORKAROUND - set the parent a SECOND time.  This one seems to stick.  FUCK YOU BLIZ.
    self:SetParent(germ)

    self.isForGerm = true
    self:setId(germ:getFlyoutId())
    self:installMyToString()
    self:installHandlerForCloseOnClick()
    self:HookScript(Script.ON_SHOW, ScriptHandlers.ON_SHOW)
    self:HookScript(Script.ON_HIDE, ScriptHandlers.ON_HIDE)
    return self
end

function FlyoutMenu:toString()
    if not self.flyoutId then
        return "<FM: EMPTY>"
    else
        return string.format("<FM: %s>", self:getLabel())
    end
end

function FlyoutMenu:getLabel()
    self.label = self:getDef().name
    return self.label
end

---@return BOFM_TYPE
function FlyoutMenu:getButtonFrame(i)
    return _G[ self:GetName().."_Button"..i ]
end

function FlyoutMenu:close()
    -- TAINT / not secure ?
    self:Hide() -- does this trigger ON_HIDE ?
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

function FlyoutMenu:forEachButton(handler, event)
    for i, button in ipairs(self:getBtnKids()) do
        if button.ufoType == ButtonOnFlyoutMenu.ufoType then
            handler(button,event)
        end
    end
end

---@return BOFM_TYPE
function FlyoutMenu:getBtn1()
    return self:getBtnKids()[1]
end

-- use non-local "global" variables to save values between executions
-- because GetParent() returns nil during combat lockdown
local CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SECURE_SCRIPT = [=[
    -- follow convention and trigger on mouse UP / key UP, not down (and certainly not both up and down).  the "down" variable is passed in by the Bliz API
    if down then return end

    if not flyoutMenu then
        flyoutMenu = self:GetParent() or self:GetFrameRef("flyoutMenu")
    end

    --[[DEBUG]] local id = self:GetID()
    --[[DEBUG]] local flyoutName = flyoutMenu:GetAttribute("UFO_NAME") or flyoutMenu:GetName() or "bullshit"
    --[[DEBUG]] local doDebug = flyoutMenu:GetAttribute("DO_DEBUG") or false
    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SECURE_SCRIPT <START>")
    --[[DEBUG]] end

    if not germ then
        germ = flyoutMenu:GetParent() or self:GetFrameRef("germ")
    end

    local doClose = germ:GetAttribute("doCloseOnClick")
    local doClose2 = flyoutMenu:GetAttribute("doCloseOnClick")

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "doClose:", doClose, "doClose2",doClose2)
    --[[DEBUG]] end

    if doClose or doClose2 then
        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "CLOSING!  doClose:", doClose, "doClose2:",doClose2)
        --[[DEBUG]] end

        flyoutMenu:Hide()
        flyoutMenu:SetAttribute("doCloseFlyout", false)
		flyoutMenu:ClearBindings()
    end
]=]

function FlyoutMenu:installHandlerForCloseOnClick()
    if self.isCloserInitialized or not self.isForGerm then return end

    -- values used inside the secure environment code
    self:SetAttribute("DO_DEBUG", not zebug.info:isMute() )
    self:SetAttribute("UFO_NAME", self:getLabel())

    ---@param btnFrame BOFM_TYPE
    self:forEachButton(function(btnFrame)
        btnFrame:SetFrameRef("flyoutMenu", self)
        btnFrame:SetFrameRef("germ", self:GetParent())
        btnFrame:WrapScript(btnFrame, "PostClick", CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SECURE_SCRIPT) -- Is the the cause of "Cannot call restricted closure from insecure code" ??? NOPE
        btnFrame:Execute(CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SECURE_SCRIPT) -- initialize the scriptlet's "global" vars
    end)

    self.isCloserInitialized = true
end

FlyoutMenu.installHandlerForCloseOnClick = Pacifier:wrap(FlyoutMenu.installHandlerForCloseOnClick)

function FlyoutMenu:getId()
    return self.id or self.flyoutId
end

function FlyoutMenu:setId(flyoutId)
    self.id = flyoutId
    self.flyoutId = flyoutId
end

---@return FlyoutDef
function FlyoutMenu:getDef()
    return FlyoutDefsDb:get(self.flyoutId)
end










-- TODO: merge updateForCatalog() and updateForGerm() -- fix updates
---@param flyoutId string
function FlyoutMenu:updateForCatalog(flyoutId, event)
    self.enableTwinkle = true
    self:setId(flyoutId)
    local dir = "RIGHT"
    self.direction = dir

    local prevButton = nil;
    local numButtons = 0;
    local flyoutDef = self:getDef()
    zebug.trace:event(event):dumpy("flyoutDef",flyoutDef)
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
            btnFrame:setDef(btnDef, event)
            btnFrame:setIcon( btnDef:getIcon(), event )
        else
            -- the empty slot on the end
            btnFrame:setDef(nil, event)
            btnFrame:setIcon(nil, event)
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

    self:setBorderFrameGeometry()
end

-- TODO: split into
-- * initialize (changes to flyoutId or flyoutDef)
-- * doUpdate (changes to the game state -- cooldowns, item counts, etc.)

---@param germ Germ
function FlyoutMenu:applyConfigForGerm(germ, event)
    self:SetParent(germ)
    self.direction = germ:getDirection(event)
    local flyoutId = germ:getFlyoutId()
    self:setId(flyoutId)
    local flyoutDef = self:getDef()
    zebug.trace:event(event):owner(self):dumpy("flyoutDef",flyoutDef)
    local usableFlyout = flyoutDef:filterOutUnusable()
    local btnNumber = 0

    ---@param btnFrame BOFM_TYPE
    self:forEachButton(function(btnFrame)
        local i = btnFrame:GetID()
        local btnDef = usableFlyout:getButtonDef(i)
        btnFrame:setDef(btnDef, event)
        zebug.trace:event(event):owner(self):print("i",i, "btnDef", btnDef)

        if btnDef then
            zebug.trace:event(event):owner(self):print("i",i, "type", btnDef.type, "ID",btnDef:getIdForBlizApi(), "name",btnDef.name)
            btnFrame:setIcon( btnDef:getIcon(), event)
            --btnFrame:setGeometry(self.direction) -- this call breaks the btns on the flyout - they all collapse into the same spot
            --TODO: figure out why
            btnFrame:SetAttribute("UFO_NAME",btnDef.name) -- SECURE TEMPLATE

            -- label the keybinds
            btnNumber = btnNumber + 1
            updateHotKeyLabel(btnFrame, btnNumber)
        else
            btnFrame:setIcon(DEFAULT_ICON, event)
            btnFrame:SetAttribute("UFO_NAME",nil) -- SECURE TEMPLATE
            return
        end
    end)

    if not self.hasOnHide then
        zebug.info:event(event):owner(self):print("setting OnHide for",self:GetName())
        local btn1 = self:getBtn1()
        btn1:SetFrameRef("flyout",self)
        btn1:SetAttribute("_onhide", "flyout:ClearBindings()") -- v11.1 replaces btn1:SetScript() and SecureHandlerExecute(germ, "keybindKeeper:ClearBindings()")
        self.hasOnHide = true
    end

    germ:SetAttribute("UFO_FLYOUT_MOD_TIME", flyoutDef:getModStamp())
    self:setBorderFrameGeometry()
end

function updateHotKeyLabel(btnFrame, btnNumber)
    local hotKeyLabel
    if Config:get("doKeybindTheButtonsOnTheFlyout") then
        if btnNumber < 11 then
            hotKeyLabel = (btnNumber == 10) and "0" or tostring(btnNumber)
        end
    end
    btnFrame.HotKey:SetText(hotKeyLabel)
end

function FlyoutMenu:setBorderFrameGeometry()
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

function FlyoutMenu:displaceButtonsOnHover(index)
    if not self.isForCatalog then
        return
    end

    if GetCursorInfo() then
        self.displaceBtnsHere = index
        self:updateForCatalog(self.flyoutId, "FlyoutMenu:displaceButtonsOnHover()")
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
    self:updateForCatalog(self.flyoutId, "FlyoutMenu:restoreButtonsAfterHover()" )
end

-- currently unused -- TODO use it
---@param btnDef ButtonDef
---@param btnIndex number
function FlyoutMenu:addBtnAt(btnDef, btnIndex)
    local flyoutDef = self:getDef()
    flyoutDef:replaceButton(btnIndex, btnDef) -- TODO - respects displace
    self:updateForCatalog(self.flyoutId, "FlyoutMenu:addBtnAt()")
    GermCommander:notifyOfChangeToFlyoutDef(self.flyoutId, "FlyoutMenu:addBtnAt")
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
-- Handlers
-------------------------------------------------------------------------------

function ScriptHandlers:ON_SHOW()
    zebug.info:mark(Mark.LOOT):owner(self):newEvent(self, "ON_SHOW"):run(function(event)
        local parent = self:GetParent()
        zebug.info:event(event):owner(self):print("parent", parent)
        parent:OnPopupToggled() -- call Bliz super method
        self:renderAllBtnCooldownsEtc(event)
    end)
end

function ScriptHandlers:ON_HIDE()
    zebug.info:mark(Mark.NOLOOT):owner(self):newEvent(self, "ON_HIDE"):run(function(event)
        self:GetParent():OnPopupToggled() -- call Bliz super method
    end)
end

-------------------------------------------------------------------------------
-- XML Callbacks
-------------------------------------------------------------------------------

function FlyoutMenu:onLeave()
    self:restoreButtonsAfterHover()
end

function FlyoutMenu:onLoadForGerm()
    zebug.info:name("ForGerm_OnLoad"):print("flyoutMenu", self:GetName())
    -- initialize fields
    self.isForGerm = true
    self.isSharedByAllGerms = true
end

function FlyoutMenu:onLoadForCatalog()
    -- initialize fields
    Catalog.flyoutMenu = self
    self.isForCatalog = true

    zebug.trace:name("ForCatalog_OnLoad"):newEvent("FlyoutMenu", "on-load-for-catalog"):run(function(event)
        self:forEachButton(ButtonOnFlyoutMenu.installExcluder, event)
    end)
end

function FlyoutMenu:renderAllBtnCooldownsEtc(event)
    if not self:IsShown() then return end
    self:forEachButton(ButtonOnFlyoutMenu.renderCooldownsAndCountsAndStatesEtcEtc, event)
end

function FlyoutMenu:FOR_DEMO_PURPOSES_ONLY()
    -- methods that get called by the Bliz built-ins
    self:OnLoad()
    self:OnClick()
    self:SetTooltip()
    self:OnLeave()
    self:OnDragStart()
end

-------------------------------------------------------------------------------
-- Debugger tools
-------------------------------------------------------------------------------

function FlyoutMenu:printDebugDetails(event)
    zebug.warn:event(event):name("details"):owner(self):print("IsShown",self:IsShown(), "IsVisible",self:IsVisible(), "parent",self:GetParent())
end

-------------------------------------------------------------------------------
-- FlyoutPopupMixin OVERRIDES
-- see Interface/AddOns/Blizzard_Flyout/Flyout.lua
-------------------------------------------------------------------------------

function FlyoutMenu:DetatchFromButton()
    -- NOP
    -- unlike the Bliz built-in flyouts, rather than reusing a single flyout object that is passed around from one action bar button to another
    -- each UFO keeps its own flyout object.  Thus, detaching it is a bad idea.
end
