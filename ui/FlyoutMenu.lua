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

function FlyoutMenu:new(germ, event)
    local germName = germ:GetName()
    local myName = germName .. FlyoutMenu.nameSuffix
    zebug.info:owner(germ):mark(Mark.HORDE):print("germ",germ, "germName",germName, "myName",myName)

    ---@type FM_TYPE
    local self = CreateFrame(FrameType.FRAME, myName, germ, "UFO_FlyoutMenuTemplate") -- XML's mixin = FlyoutMenu

    -- calling self:GetParent() in any of the methods below returns some unknown object that is NOT the germ.
    -- but later, it will return the germ.  JFC.
    -- WORKAROUND - set the parent a SECOND time.  This one seems to stick.  FUCK YOU BLIZ.
    self:SetParent(germ)
    self.GetParent = function() return germ end -- fuck you again, Bliz!
    self.getParent = self.GetParent

    self.isForGerm = true
    self:setId(germ:getFlyoutId())
    self:installMyToString()


    self:installSecEnvBullshit(event)


    self:installSecEnvScriptIntoBtnKidsForCloseOnClick()
    self:HookScript(Script.ON_SHOW, ScriptHandlers.ON_SHOW)
    self:HookScript(Script.ON_HIDE, ScriptHandlers.ON_HIDE)

    return self
end

function FlyoutMenu:toString()
    if not self.flyoutId then
        return "<FM: EMPTY>"
    else
        return string.format("<FM: %s>", self:getUfoLabel())
    end
end

--[[
function FlyoutMenu:getLabel()
    self.label = self:getDef().name
    return self.label
end
]]

---@return BOFM_TYPE
function FlyoutMenu:getButtonFrame(i)
    return self[tostring(i)] -- the ui.xml defines parentKey="1" which evidently creates a string and not a number
end

function FlyoutMenu:close()
    -- TAINT / not secure ?
    self:Hide() -- does this trigger ON_HIDE ?
end

function FlyoutMenu:getBtnKids()
    if self.btnKids then
        return self.btnKids
    end

    -- eliminate the non-button UI element "Background" defined in ui.xml
    -- sometimes (during combat) it's already excluded from GetChildren() so... we have to jump through extra hoops
    local btnKids = { self:GetChildren() }

    while btnKids[1] and btnKids[1]:GetObjectType() ~= "CheckButton" do
        zebug.info:owner(self):print("discarding id", btnKids[1]:GetID(), "of",  btnKids[1]:GetObjectType())
        table.remove(btnKids, 1)
    end

    self.btnKids = btnKids

    return self.btnKids
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

---@return BOFM_TYPE
function FlyoutMenu:getBtn(n)
    assert(n, "Invalid value for n: nil")
    return self:getBtnKids()[n]
end

-- TODO move to SecEnvDrugMule

-- use non-local "global" variables to save values between executions
-- because GetParent() returns nil during combat lockdown
local CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SEC_ENV_SCRIPT = [=[
    -- follow convention and trigger on mouse UP / key UP, not down (and certainly not both up and down).  the "down" variable is passed in by the Bliz API
    if down then return end

    if not flyoutMenu then
        flyoutMenu = self:GetParent() or self:GetFrameRef("flyoutMenu")
    end

    --[[DEBUG]] local id = self:GetID()
    --[[DEBUG]] local flyoutName = flyoutMenu:GetAttribute("UFO_NAME") or flyoutMenu:GetName() or "bullshit"
    --[[DEBUG]] local doDebug = flyoutMenu:GetAttribute("DO_DEBUG") or false
    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SEC_ENV_SCRIPT <START>")
    --[[DEBUG]] end

    if not germ then
        germ = flyoutMenu:GetParent() or self:GetFrameRef("germ")
    end

        UFO_DUM_DUM= self:GetFrameRef("UFO_DUM_DUM")

    local doClose = germ:GetAttribute("doCloseOnClick")
    local doClose2 = flyoutMenu:GetAttribute("doCloseOnClick")
    local doClose3 = UFO_DUM_DUM:GetAttribute("doCloseOnClick")

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "doClose:", doClose, "doClose2",doClose2 "doClose3",doClose3)
    --[[DEBUG]] end

    if doClose or doClose2 or doClose3 then
        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "CLOSING!  doClose:", doClose, "doClose2:",doClose2)
        --[[DEBUG]] end

        flyoutMenu:Hide()
        flyoutMenu:SetAttribute("doCloseFlyout", false)
		flyoutMenu:ClearBindings()
    end
]=]

function FlyoutMenu:installSecEnvScriptIntoBtnKidsForCloseOnClick()
    if self.isCloserInitialized or not self.isForGerm then return end

    -- values used inside the secure environment code
    -- self:SetAttribute("DO_DEBUG", not zebug.info:isMute() )
    -- self:SetAttribute("UFO_NAME", self:getUfoLabel())

    local germ = self:GetParent()
    zebug.info:owner(self):print("germ", germ)

    ---@param btnFrame BOFM_TYPE
    self:forEachButton(function(btnFrame)
        -- move ALL of this into btnFrame:initializeSecEnv()
        btnFrame:SetFrameRef("flyoutMenu", self)
        btnFrame:SetFrameRef("germ", germ)
        btnFrame:SetFrameRef("UFO_DUM_DUM", _G["UFO_DUM_DUM"])
        btnFrame:WrapScript(btnFrame, "PostClick", CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SEC_ENV_SCRIPT) -- This threw: "Header frame must be explicitly protected" after combat.  I had managed to move a UFO during combat(?)
        btnFrame:Execute(CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SEC_ENV_SCRIPT) -- initialize the scriptlet's "global" vars
        btnFrame:initializeSecEnv()
    end)

    self.isCloserInitialized = true
end

FlyoutMenu.installSecEnvScriptIntoBtnKidsForCloseOnClick = Pacifier:wrap(FlyoutMenu.installSecEnvScriptIntoBtnKidsForCloseOnClick)

function FlyoutMenu:installSecEnvBullshit(event)
    SecureHandler_OnLoad(self) -- install self:SetFrameRef()

    -- set attributes used inside the secure scripts
    -- set attributes used inside the secure scripts
    self:setSecEnvAttribute("DO_DEBUG", not zebug.info:isMute() )
    self:setSecEnvAttribute("UFO_NAME", self:getUfoLabel())
    self:setSecEnvAttribute(SecEnvAttribute.flyoutDirection, self:getDirection(event))
    self:SetFrameRef("UFO_DUM_DUM", _G["UFO_DUM_DUM"])
    self:SetFrameRef("flyoutMenu", self)
    local germ = self:getParent()
    if germ then
        self:SetFrameRef("germ", self:getParent())
    end

    -- set global variables inside the restricted environment
    self:Execute([=[
        flyoutMenu = self
        germ       = self:GetFrameRef("germ")
        UFO_DUM_DUM= self:GetFrameRef("UFO_DUM_DUM")
        -- catalogEntry = self:GetFrameRef("catalogEntry") -- to be set on-demand by CatalogEntry
        myName     = self:GetAttribute("UFO_NAME")
        doDebug    = self:GetAttribute("DO_DEBUG") or false
    ]=])

    SecEnv:installEnumsAndConstants(self)

    self:installSecEnvScriptsTo_Open()

end

function FlyoutMenu:setSecEnvCatalogEntry(catalogEntry)
    -- set attributes used inside the secure scripts
    self:setSecEnvAttribute("UFO_NAME", self:getUfoLabel())
    self:SetFrameRef("catalogEntry", catalogEntry)

    -- set global variables inside the restricted environment of the germ
    self:Execute([=[
        myName       = self:GetAttribute("UFO_NAME")
        catalogEntry = self:GetFrameRef("catalogEntry")
    ]=])
end


function FlyoutMenu:getDirection()
    ---@type GERM_TYPE
    local p = self:getParent()
    if not p then
        if self.isForCatalog then
            return DIRECTION_FOR_CATALOG
        else
            error("no parent")
        end
    end

    local func = p.getDirection
    assert(func, "parent has no method named 'getDirection'")
    local dir = func(p)
    return dir
end


function FlyoutMenu:installSecEnvScriptsTo_Open()
    assert(not self.isOpenerScriptInitialized, "Wut?  The OPENER script is already installed.  Why you call again?")
    self.isOpenerScriptInitialized = true
    self:setSecEnvAttribute("_".. SecEnv.FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME, SecEnv:getSecEnvScriptFor_Opener())
    self:setSecEnvAttribute("_".. SecEnv.FLYOUT_LAYOUT_SCRIPT_NAME, SecEnv:getSecEnvScriptFor_Layout())
    --self:setSecEnvAttribute("_".. SecEnv.FLYOUT_KEY_BINDING_SCRIPT_NAME, SecEnv:getSecEnvScriptFor_KeyBinding())
end


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

function FlyoutMenu:attach(parent)
    self.parent = parent
    self:ClearAllPoints() -- remove myself from any previous position
    self:SetPoint(Anchor.LEFT, self.parent, Anchor.RIGHT)
end

---@param flyoutId string
function FlyoutMenu:applyConfigForCatalog(flyoutId, event)
    self:ClearAllPoints() -- remove myself from any previous position
    self:SetPoint(Anchor.LEFT, self.parent, Anchor.RIGHT)
    self.enableTwinkle = true
    self:setId(flyoutId)
    self.direction = "RIGHT"

    local flyoutDef = self:getDef()
    local numButtons = flyoutDef:howManyButtons() + 1
    self:SetAttribute("IN_USE_BTN_COUNT", numButtons)

    -- populate the buttons
    self:populateButtons(event)

    -- arrange all of the buttons
    self:updateButtonLayout(event)
end

function FlyoutMenu:offsetAndUpdateButtonLayout(displaceBtnsHere, event)
    -- zebug.error:event(event):owner(self):print("param displaceBtnsHere",displaceBtnsHere)
    self.displaceBtnsHere = displaceBtnsHere
    self:redraw(event)
    self.displaceBtnsHere = nil
end

function FlyoutMenu:redraw(event)
    self:populateButtons(event)
    self:updateButtonLayout(event)
end

function FlyoutMenu:updateButtonLayout(event)
    zebug.info:event(event):owner(self):print("self.isForCatalog",self.isForCatalog)
    local flyoutDef = self:getDef()
    local extraButton = self.isForCatalog and 1 or 0 -- this will always be for catalog
    local numButtons = flyoutDef:howManyButtons() + extraButton
    numButtons = math.min(numButtons, MAX_FLYOUT_SIZE)
    --self:RunAttribute(SecEnv.FLYOUT_LAYOUT_ATTR_NAME, numButtons, self.direction, self)
    --zebug.error:event(event):owner(self):print("self.displaceBtnsHere",self.displaceBtnsHere)
    SecEnv:executeFromNonSecEnv_Layout(self, numButtons, self.direction, self.displaceBtnsHere)
end

function FlyoutMenu:populateButtons(event)
    local flyoutDef = self:getDef()
    zebug.trace:event(event):dumpy("flyoutDef",flyoutDef)
    local n = flyoutDef:howManyButtons()
    local rows = n+1 -- one extra for an empty space
    local prevButton = nil
    local numButtons = 0

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
            local icon = self:getIcon(btnDef)
            btnFrame:setIcon(icon, event)
            -- NEW!
            btnFrame:SetAttribute("UFO_NAME",btnDef.name) -- SecEnv TEMPLATE
        else
            -- the empty slot on the end
            btnFrame:setDef(nil, event)
            btnFrame:setIcon(nil, event)
            btnFrame:SetAttribute("UFO_NAME"," ") -- NEW!!! SecEnv TEMPLATE
            btnFrame:setExcluderVisibility(nil)
        end

        --btnFrame:setGeometry(self.direction, prevButton)

        prevButton = btnFrame
        numButtons = i
    end

    -- Hide unused buttons
    local unusedButtonIndex = numButtons+1
    local btnFrame = self:getButtonFrame(unusedButtonIndex)
    while btnFrame do
        --zebug.error:event(event):owner(btnFrame):print("===== unusedButtonIndex",unusedButtonIndex)
        btnFrame:setDef(nil, event)
        btnFrame:setIcon(nil, event)
        btnFrame:SetAttribute("UFO_NAME",nil) -- SecEnv TEMPLATE - required flag used to indicate "inUse"
        btnFrame:Hide()
        unusedButtonIndex = unusedButtonIndex+1
        btnFrame = self:getButtonFrame(unusedButtonIndex)
    end

    if numButtons == 0 then
        self:Hide()
        --return
    end

    return prevButton, numButtons
end

---@param btnDef ButtonDef
function FlyoutMenu:getIcon(btnDef)
    local icon = DEFAULT_ICON_FULL
    local isOk, err = pcall( function() icon = btnDef:getIcon() end )
    if not isOk then
        zebug.warn:owner(self):print("Encountered bad button data for", btnDef:toString())
        zebug.info:owner(self):print("error", err)
    end
    return icon, err
end

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
            local icon = self:getIcon(btnDef)
            btnFrame:setIcon(icon, event)
            --btnFrame:setGeometry(self.direction) -- this call breaks the btns on the flyout - they all collapse into the same spot
            --TODO: figure out why
            btnFrame:SetAttribute("UFO_NAME",btnDef.name) -- SecEnv TEMPLATE

            -- label the keybinds
            btnNumber = btnNumber + 1
            updateHotKeyLabel(btnFrame, btnNumber)
        else
            btnFrame:setIcon(DEFAULT_ICON, event)
            btnFrame:SetAttribute("UFO_NAME",nil) -- SecEnv TEMPLATE
            return
        end
    end)

    --zebug.error:event("IN_USE_BTN_COUNT"):owner(self):print("btnNumber",btnNumber)
    self:SetAttribute("IN_USE_BTN_COUNT", btnNumber)

    if not self.hasOnHide then
        zebug.info:event(event):owner(self):print("setting OnHide for",self:GetName())
        local btn1 = self:getBtn1()
        btn1:SetFrameRef("flyout",self)
        btn1:SetAttribute("_onhide", "flyout:ClearBindings()") -- v11.1 replaces btn1:SetScript() and SecureHandlerExecute(germ, "keybindKeeper:ClearBindings()")
        self.hasOnHide = true
    end

    germ:SetAttribute("UFO_FLYOUT_MOD_TIME", flyoutDef:getModStamp())
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

function FlyoutMenu:displaceButtonsOnHover(index)
    if not self.isForCatalog then return end

    if GetCursorInfo() then
        self:offsetAndUpdateButtonLayout(index, "FlyoutMenu:displaceButtonsOnHover()")
    end
end

function FlyoutMenu:restoreButtonsAfterHover()
    ---@type FlyoutMenu
    if not self.displaceBtnsHere then
        -- return -- remove ???
    end

    if self:isMouseOverMeOrKids() then
        return
    end

    self.displaceBtnsHere = nil -- redundant with the nil param below
    self:redraw("FlyoutMenu:restoreButtonsAfterHover()")
end

function FlyoutMenu:isMouseOverMeOrKids()
    return self:IsMouseOver() or self.mouseOverKid
end

function FlyoutMenu:startHover(kid)
    if not self.isForCatalog then return end
    self.mouseOverKid = kid:GetName()
    self:displaceButtonsOnHover(kid:getId())
end

function FlyoutMenu:stopHover(kid)
    if not self.isForCatalog then return end
    if self.mouseOverKid == kid:GetName() then
        self.mouseOverKid = nil
    end
    self:restoreButtonsAfterHover()
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

function FlyoutMenu:onLoadForCatalog()
    -- initialize fields
    Catalog.flyoutMenu = self
    self.isForCatalog = true
    self.isForGerm = false
    self:SetParent(nil)

    zebug.trace:name("ForCatalog_OnLoad"):newEvent("FlyoutMenu", "on-load-for-catalog"):run(function(event)
        self:forEachButton(ButtonOnFlyoutMenu.installExcluder, event)
    end)

    self:installSecEnvBullshit("FlyoutMenu:onLoadForCatalog")
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
