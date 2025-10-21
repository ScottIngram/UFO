-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

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
        self:assignSecEnvMouseClickBehaviorVia_AttributeFromBtnDef(MouseClick.ANY, event)
        -- TODO: v11.1 build this into my Button_Mixin
        safelySetAttribute(self, "UFO_NO_RND", btnDef and btnDef.noRnd or nil) -- SECURE TEMPLATE
        safelySetAttribute(self, "myName", self:getLabel()) -- SECURE TEMPLATE

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

    local name = btnDef:getName() or L10N.UNKNOWN
    local msg = QUOTE .. name .. QUOTE .. " " .. L10N.CANNOT_BE_USED_BY_THIS_TOON
    msgUser(msg)
    zebug.warn:alert(msg)
    return true
end

function ButtonOnFlyoutMenu:onReceiveDragAddItTryCatch(event)
    local isOk, err = pcall( function()  self:onReceiveDragAddIt(event) end  )
    if not isOk then
        zebug.error:event(event):owner(self):print("Drag and drop failed! ERROR",err)
    end
end

function ButtonOnFlyoutMenu:onReceiveDragAddIt(event)
    local flyoutMenu = self:getParent()
    if not flyoutMenu.isForCatalog then return end -- only the flyouts in the catalog are valid drop targets.  TODO: let flyouts on the germs receive too?

    local crsDef = ButtonDef:getFromCursor(event)
    if not crsDef then
        zebug.info:event(event):owner(self):print("Sorry, unsupported type:", Ufo.unknownType)
        msgUser(L10N.UNSUPPORTED_TYPE, ": ", Ufo.unknownType)
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

    local name = btnDef:getName()
    if not name then
        msgUser(L10N.UNKNOWN, "button on", self:getParent():getLabel())
        name = L10N.UNKNOWN
    end

    if tooltipSetter then
        tooltipSetter()
    else
        GameTooltip:SetText(name, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    end
end

function ButtonOnFlyoutMenu:warnIfUnusable()
    local btnDef = self:getDef()
    if not btnDef then return end
    local isUsable, err =  btnDef:isUsable()
--[[
    if not isUsable then
        local btn = btnDef:toString()
        msgUser(btn .. " " .. L10N.CANNOT_BE_USED_BY_THIS_TOON .. " " .. (err or ""))
    end
]]
end

-------------------------------------------------------------------------------
--
-- SecEnv Scripts
--
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:initializeSecEnv()
    local flyoutMenu = self:getParent()
    local germ = flyoutMenu:getParent()
    zebug.info:owner(self):print("germ",germ, "flyoutMenu",flyoutMenu)

    -- set attributes used inside the secure scripts
    self:setSecEnvAttribute("DO_DEBUG", not zebug.info:isMute() )
    self:setSecEnvAttribute("UFO_NAME", self:getLabel())
    self:SetFrameRef("flyoutMenu", flyoutMenu)
    self:SetFrameRef("germ", germ)

    -- set global variables inside the restricted "secure" environment
    self:Execute([=[
        germ       = self:GetFrameRef("germ")
        flyoutMenu = self:GetFrameRef("flyoutMenu")
        doDebug    = self:GetAttribute("DO_DEBUG") or false
     ]=])

    self:installSecEnvScriptFor_ON_CLICK()
end

local SEC_ENV_SCRIPT_FOR_ON_CLICK

function ButtonOnFlyoutMenu:installSecEnvScriptFor_ON_CLICK()
    assert(not self.onClickScriptInitialized, "Wut?  The ON_CLICK_SCRIPT is already installed.  Why you call again?")
    self.isOnClickScriptInitialized = true
    local script = self:getSecEnvScriptFor_ON_CLICK()
    self:WrapScript(self, Script.ON_CLICK, script )
end

function ButtonOnFlyoutMenu:getSecEnvScriptFor_ON_CLICK()
    if not SEC_ENV_SCRIPT_FOR_ON_CLICK then
        SEC_ENV_SCRIPT_FOR_ON_CLICK =
[=[
    -- INCOMING PARAMS - rename/remap Blizard's idiotic variables and SHITTY identifiers
    local isClicked  = down -- true/false
    local mouseClick = button -- "LeftButton" etc
    if not isClicked then
        -- ABORT - only execute once per mouseclick, not on both UP and DOWN
        return
    end

    -- local icon = self:GetNormalTexture() -- nope.  doesn't exist

    local myName  = self:GetAttribute("UFO_NAME")
    local SEC_ENV_ACTION_TYPE   = self:GetAttribute("SEC_ENV_ACTION_TYPE")
    local SEC_ENV_ACTION_TYPE_D = self:GetAttribute("SEC_ENV_ACTION_TYPE_DUMBER")
    local SEC_ENV_ACTION_ARG    = self:GetAttribute("SEC_ENV_ACTION_ARG")
    local icon          = self:GetAttribute("UFO_ICON")
    local isPrimeRecent = germ:GetAttribute("IS_PRIME_RECENT")
    local isModifierKeyDown = IsModifierKeyDown()

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() germ",germ:GetAttribute("UFO_NAME"), "flyoutMenu",flyoutMenu:GetAttribute("UFO_NAME"),"germSignaler",germSignaler)
    --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() isClicked",isClicked, "mouseClick",mouseClick, "SEC_ENV_ACTION_TYPE",SEC_ENV_ACTION_TYPE, "SEC_ENV_ACTION_TYPE_D",SEC_ENV_ACTION_TYPE_D, "SEC_ENV_ACTION_ARG",SEC_ENV_ACTION_ARG)
    --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() icon",icon)
    --[[DEBUG]]     print("<DEBUG>", myName, "ON_CLICK() isPrimeRecent",isPrimeRecent, "isModifierKeyDown",isModifierKeyDown)
    --[[DEBUG]] end

    -- are these 3 in use ?
    germ:SetAttribute("SEC_ENV_ACTION_TYPE", SEC_ENV_ACTION_TYPE)
    germ:SetAttribute("SEC_ENV_ACTION_ARG", SEC_ENV_ACTION_ARG)
    germ:SetAttribute("SEC_ENV_ACTION_TYPE_DUMBER_AND_ADJUSTED", SEC_ENV_ACTION_TYPE_D) -- misnomer

    -- when the Prime Button is clicked AND Prime is defined as "most recent"
    -- OR -- shift/alt/etc was also pressed
    -- copy my behavior to the germ
    if isPrimeRecent or isModifierKeyDown then
        -- find out which mouse clicks are assigned the "Primary Button" behavior
        for i = 1, 10 do -- TODO: don't hardcode this
            local flagNameForIsThisBtmPrime = "IS_A_PRIME_BTN_" .. i
            local isThisBtmPrime = germ:GetAttribute(flagNameForIsThisBtmPrime)

            --[[DEBUG]] if doDebug then print ("<DEBUG>", myName, flagNameForIsThisBtmPrime, isThisBtmPrime) end

            if isThisBtmPrime then
                -- Bliz nomenclature for "mouse click X" where x=[1,2,3...] which corresponds to left, right, middle...
                local typeKey = "type"..i
                local actionKeyAdj = SEC_ENV_ACTION_TYPE .. i -- macrotext1
                local actionKeyDumberAdj = SEC_ENV_ACTION_TYPE_D .. i -- macrotext1

                if SEC_ENV_ACTION_TYPE == SEC_ENV_ACTION_TYPE_D then
                    germ:SetAttribute(typeKey, SEC_ENV_ACTION_TYPE) -- macro
                    germ:SetAttribute(actionKeyAdj, SEC_ENV_ACTION_ARG)
                    --[[DEBUG]] if doDebug then print ("<DEBUG> EQUALZ", myName, flagNameForIsThisBtmPrime, isThisBtmPrime, typeKey, "=", SEC_ENV_ACTION_TYPE, actionKeyAdj, '= "', SEC_ENV_ACTION_ARG, '"',  actionKeyDumberAdj, "= nil") end
                else
                    germ:SetAttribute(typeKey, SEC_ENV_ACTION_TYPE) -- macro
                    germ:SetAttribute(actionKeyDumberAdj, SEC_ENV_ACTION_ARG)
                    -- clear stale data
                    germ:SetAttribute(actionKeyAdj, nil)
                    --[[DEBUG]] if doDebug then print ("<DEBUG> ELSE", myName, flagNameForIsThisBtmPrime, isThisBtmPrime, typeKey, "=", SEC_ENV_ACTION_TYPE, actionKeyDumberAdj, '= "', SEC_ENV_ACTION_ARG, '"',  actionKeyAdj, "= nil") end
                end
            end
        end
    end
]=]
    end
    return SEC_ENV_SCRIPT_FOR_ON_CLICK
end

-------------------------------------------------------------------------------
-- XML Callbacks - see ui/ui.xml
-------------------------------------------------------------------------------

-- TODO: should this be in Button_Mixin so that Germ can enjoy it too?
---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onLoad()
    -- leverage inheritance - invoke parent's OnLoad()
    self:SmallActionButtonMixin_OnLoad()
    SecureHandler_OnLoad(self)

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
    self:warnIfUnusable()

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
        zebug.info:mTriangle():owner(self):newEvent(self, "bofm-mouse-up"):run(function(event)
            self:onReceiveDragAddItTryCatch(event)
        end)
    end
end

---@param mouseClick MouseClick
function ButtonOnFlyoutMenu:OnMouseDown(mouseClick)
    local flyoutMenu = self:GetParent()
    if not flyoutMenu.isForGerm then return end

    -- is any mouse button configured for PrimaryButtonIs.RECENT ?
    -- OR - is shift/alt/etc also pressed?
    local doPromote = IsModifierKeyDown() or Config:isAnyClickerUsingRecent(self.flyoutId)
    if not doPromote then return end -- NOPE!  No promotion for you!

    ---@type GERM_TYPE
    local germ = flyoutMenu and flyoutMenu:GetParent()
    zebug.info:owner(self):event("OnMouseDown"):print("flyoutMenu",flyoutMenu, "germ",germ)
    germ:promoteButtonToPrime(self)
end

---@param self ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:onReceiveDrag()
    zebug.info:mTriangle():owner(self):newEvent(self, "bofm-drag-hit-me"):run(function(event)
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
    if not flyoutFrame.isForCatalog then return end

    local isDragging = GetCursorInfo()
    if isDragging then
        zebug.info:mTriangle():owner(self):newEvent(self, "bofm-drag-hit-me-SWAP"):run(function(event)
            self:onReceiveDragAddItTryCatch(event)
        end)
        return
    end

    local btnDef = self:getDef()
--[[
    if self:abortIfUnusable(btnDef) then
        -- TODO - work some sort of proxy magic to let a toon drag around a spell they don't know
        return
    end
]]

    zebug.info:mTriangle():owner(self):newEvent(self, "bofm-dragged-away"):run(function(event)
        local isOk, err = btnDef:pickupToCursor(event)
        if not isOk then
            zebug.error:event(event):owner(self):print("FAILED to drag! err",err)
            return
        end

        local flyoutId = flyoutFrame:getId()
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        flyoutDef:removeButton(self:getId())
        self:setDef(nil, event)
        flyoutFrame:updateForCatalog(flyoutId, event)
        GermCommander:notifyOfChangeToFlyoutDef(flyoutId, event)
    end)
end

-------------------------------------------------------------------------------
-- Debugger tools
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:printDebugDetails(event)
    local t = self:GetAttribute("type")
    local secEnvType = self:GetAttribute("SEC_ENV_ACTION_TYPE")
    local secEnvTypeDumb = self:GetAttribute("SEC_ENV_ACTION_TYPE_DUMBER")
    local secEnvArg = self:GetAttribute("SEC_ENV_ACTION_ARG")
    local type = self:GetAttribute("type")
    local tVal = self:GetAttribute(type)

    zebug.warn:event(event):name("details"):owner(self):print("type",type, "tVal",tVal, "SEC type", secEnvType, "DUMB type", secEnvTypeDumb, "SEC arg", secEnvArg)
end

-------------------------------------------------------------------------------
-- Awesome toString() magic
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:toString()
    local btnDef = self:getDef()
    if btnDef then
        return string.format("<BOFM: %s:%s>", nilStr(btnDef.type), nilStr(btnDef.name))
    else
        return "<BOFM: EMPTY>"
    end
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

