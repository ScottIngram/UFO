-- SecEnvDrugMule.lua
-- the dark nether region where I store codez and valuez for Blizzard's "Secure" environment.
-- support for SetAttribute("type",action) or ON_CLICK handlers etc.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.TRACE)

-------------------------------------------------------------------------------
--
-- SecEnv constants and shared scripts
--
-- support for SetAttribute("type",action) or ON_CLICK etc
-------------------------------------------------------------------------------

---@class SecEnv
---@field FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME string keyname for the sec-env attribute that will hold the script that formats the flyout
---@field FLYOUT_LAYOUT_SCRIPT_NAME string keyname for the sec-env attribute that will hold the script that formats the flyout
---@field OPENER_SCRIPT_REF_NAME string keyname for the sec-env attribute that will hold the script that refers from germ/catalogEntry frame to the flyout frame's script that performs layout & open
---@field OPENER_SCRIPT string code/script. will be initialized on-demand
---@field LAYOUT_SCRIPT_REF_NAME string keyname for the sec-env attribute that will hold the script that refers from germ/catalogEntry frame to the flyout frame's script that performs layout & open
---@field LAYOUT_SCRIPT string code/script. will be initialized on-demand
---@field FLYOUT_KEY_BINDING_SCRIPT_NAME string keyname for the sec-env attribute that will hold the script that binds keys to buttons on the flyout
---@field FLYOUT_KEY_BINDING_SCRIPT string code/script. will be initialized on-demand
---@field ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR string keyname for the sec-env attribute that will hold the
---@field ON_CLICK_RND_ETC_PICK_BTN_SCRIPT string code/script. will be initialized on-demand
SecEnv = {
    FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME = "SEC_ENV_FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME",
    FLYOUT_LAYOUT_SCRIPT_NAME = "SEC_ENV_FLYOUT_LAYOUT_SCRIPT_NAME",
    FLYOUT_KEY_BINDING_SCRIPT_NAME = "SEC_ENV_FLYOUT_KEY_BINDING_SCRIPT_NAME",
    OPENER_SCRIPT_REF_NAME = "SEC_ENV_OPENER_SCRIPT_REF_NAME",
    LAYOUT_SCRIPT_REF_NAME = "SEC_ENV_LAYOUT_SCRIPT_REF_NAME",
    ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR = "SEC_ENV_ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR_",
}

-------------------------------------------------------------------------------
--
-- SecEnv Scripts
--
-------------------------------------------------------------------------------

function SecEnv:installEnumsAndConstants(fucker)
    local DIRECTION_AS_ANCHOR = serializeAsAssignments("DIRECTION_AS_ANCHOR", DirectionAsAnchor, true) -- disable "local" keyword
    local ANCHOR_OPPOSITE = serializeAsAssignments("ANCHOR_OPPOSITE", AnchorOpposite, true) -- disable "local" keyword

    fucker:Execute([=[
    ]=].. DIRECTION_AS_ANCHOR ..[=[
    ]=].. ANCHOR_OPPOSITE ..[=[
    ]=])
end


function SecEnv:getSecEnvScriptFor_Opener()
    if not SecEnv.OPENER_SCRIPT then
        --local DIRECTION_AS_ANCHOR = serializeAsAssignments("DIRECTION_AS_ANCHOR", DirectionAsAnchor, true) -- disable "local" keyword
        --local ANCHOR_OPPOSITE = serializeAsAssignments("ANCHOR_OPPOSITE", AnchorOpposite, true) -- disable "local" keyword

        SecEnv.OPENER_SCRIPT =
        [=[
--print("<<<START>>>")
        local arg1, arg2 = ...;

--print("SecEnv:getSecEnvScriptFor_Opener ... clicked clicked !!! self",self, "button",button, "down",down, "a,b,c,d",a,b,c,d)
        --local doDebug = true

            local mouseClick = button or arg1 --"button" is auto-assigned by Bliz for an ON_CLICK handler.  But for generic scripts, we must use ...
            local isClicked = down or arg2
            local dir = germ:GetAttribute( "]=].. SecEnvAttribute.flyoutDirection ..[=[" )
    local isOpen = flyoutMenu:IsShown()

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "OPENER_SCRIPT <START> germ =", germ, "flyoutMenu =",flyoutMenu, "mouseClick",mouseClick, "isClicked",isClicked, "dir",dir, "isOpen",isOpen)
    --[[DEBUG]] end

	if isOpen then
	    --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "closing")
        --[[DEBUG]] end
		flyoutMenu:Hide()
		flyoutMenu:ClearBindings()
		return
    end

--print("binding ESCAPE to mouseClick",mouseClick)
    flyoutMenu:SetBindingClick(true, "Escape", germ, mouseClick)

-- TODO: move this into FlyoutMenu:updateForGerm()

    -- attach the flyout to the germ

    flyoutMenu:ClearAllPoints()
    flyoutMenu:SetParent(germ)  -- holdover from single FM
    local anchorOnGerm = DIRECTION_AS_ANCHOR[dir]
    local ptOnMe   = ANCHOR_OPPOSITE[anchorOnGerm]
    flyoutMenu:SetPoint(ptOnMe, germ, anchorOnGerm, 0, 0)

    -- figure out if we need to layout the buttons BECAUSE
    -- it's never been done
    -- or the the old layout needs to adjust to accomodate a different number of buttons


    -- leverage global variable numButtons
    local IN_USE_BTN_COUNT = flyoutMenu:GetAttribute("IN_USE_BTN_COUNT")
    local isNewLayoutNeeded = false
    if (not numButtons) or (numButtons ~= IN_USE_BTN_COUNT) then
        isNewLayoutNeeded = true
    end

    --[[DEBUG]] if doDebug then print("numButtons",numButtons, "IN_USE_BTN_COUNT",IN_USE_BTN_COUNT, "isNewLayoutNeeded",isNewLayoutNeeded ) end

    numButtons = IN_USE_BTN_COUNT

    if isNewLayoutNeeded then
        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "RUNNING layout")
        --[[DEBUG]] end
        flyoutMenu:RunAttribute("_]=] .. SecEnv.FLYOUT_LAYOUT_SCRIPT_NAME .. [=[", numButtons, dir, flyoutMenu, "suckit")
    end

    --
    -- GERM only
    -- keybind each button to 1-9 and 0
    --

    if germ then
        local doKeybindTheButtonsOnTheFlyout = germ:GetAttribute("doKeybindTheButtonsOnTheFlyout")
        if doKeybindTheButtonsOnTheFlyout then
            local lastKeyNum = math.min(numButtons, 10)
            for i = 1, lastKeyNum do
                local btn = GLOBAL_BTNS[i]
                local numberKey = (i == 10) and "0" or tostring(i)
                flyoutMenu:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
                if numberKey == "1" then
                    -- make the UFO's first button's keybind be the same as the UFO itself
                    local germKeyBind = germ:GetAttribute("UFO_KEYBIND_1")
                    if germKeyBind then
                        flyoutMenu:SetBindingClick(true, germKeyBind, btn, "]=].. MouseClick.LEFT ..[=[")
                    end
                end
            end
        end
    end

    flyoutMenu:Show()
]=]
    end

    return SecEnv.OPENER_SCRIPT
end

---@param flyoutMenuFrame FlyoutMenu
function SecEnv:executeFromNonSecEnv_Layout(flyoutMenuFrame, numButtons, dir, displaceBtnsHere)
    zebug.info:event("EXE"):owner(flyoutMenuFrame):print("numButtons",numButtons, "dir",dir, "displaceBtnsHere",displaceBtnsHere)

    -- replace the safely - pacify the whole func
    flyoutMenuFrame:safelySetSecEnvAttribute("FU_NUMBUTTONS", numButtons)
    flyoutMenuFrame:safelySetSecEnvAttribute("FU_DIR", dir)
    flyoutMenuFrame:safelySetSecEnvAttribute("FU_TARGET_INDEX", displaceBtnsHere)
    flyoutMenuFrame:Execute([=[
        local numButtons = flyoutMenu:GetAttribute("FU_NUMBUTTONS")
        local dir = flyoutMenu:GetAttribute("FU_DIR")
        local displaceBtnsHere = flyoutMenu:GetAttribute("FU_TARGET_INDEX")
        --print("EXE bridge - numButtons",numButtons, "dir",dir, "displaceBtnsHere",displaceBtnsHere)
        flyoutMenu:RunAttribute("_]=] .. SecEnv.FLYOUT_LAYOUT_SCRIPT_NAME .. [=[", numButtons, dir, displaceBtnsHere)
     ]=])
end

function SecEnv:getSecEnvScriptFor_Layout()
    if not SecEnv.LAYOUT_SCRIPT then
        SecEnv.LAYOUT_SCRIPT =
        [=[
local initialSpacing = ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[; -- evidently, lua strips this line break hence the ;
local defaultSpacing = ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[;

local arg1, arg2, arg3 = ...;
local numButtons = arg1
local dir = arg2
local displaceBtnsHere = arg3
local isVert = dir == "UP" or dir == "DOWN"


--local doDebug = true
--[[DEBUG]] if doDebug then print("sucking pipe... numButtons",numButtons, "arg2",arg2, "arg3",arg3, "dir",dir, "displaceBtnsHere",displaceBtnsHere) end

    -- get the buttons, filtering out trash
    if not GLOBAL_BTNS then
        GLOBAL_BTNS = table.new(flyoutMenu:GetChildren())
        while GLOBAL_BTNS[1] and GLOBAL_BTNS[1]:GetID() < 1 do
            --print("discarding", GLOBAL_BTNS[1]:GetObjectType())
            table.remove(GLOBAL_BTNS, 1) -- this is the non-button UI element "Background" from ui.xml
        end
    end

-- calculate if the flyout is too long, then how many rows & columns
local configMaxLen = 20
local vertLineWrapDir = "RIGHT"
local horizLineWrapDir = "UP"
local linesCountMax = math.ceil(numButtons / configMaxLen, 1)
local maxBtnsPerLine = math.ceil(numButtons / linesCountMax)
--[[DEBUG]] -- print("configMaxLen",configMaxLen, "numButtons =",numButtons, "maxBtnsPerLine",maxBtnsPerLine, "linesCountMax",linesCountMax)
if linesCountMax > configMaxLen then
    linesCountMax = math.floor( math.sqrt(numButtons) )
	    --[[DEBUG]] if doDebug then
        --[[DEBUG]] print("TOO WIDE! sqrt =",linesCountMax)
        --[[DEBUG]] end
end

    local x,y,linesCount,btnCountForThisLine = 1,1,1,0
    local lineGirth, lineOff
	local anyBumper = nil
	local firstBumperOfPreviousLine = nil
	local anchorBuddy = flyoutMenu

    -- arrange and anchor all the buttons

    for i, btn in ipairs(GLOBAL_BTNS) do
        local bumper = btn:GetFrameRef("bumper")
        local isInUse = btn:GetAttribute("UFO_NAME")

	    --[[DEBUG]] if doDebug then
        --[[DEBUG]] print("i:",i, "btn:",btn:GetName(), "isInUse",isInUse)
        --[[DEBUG]] end

        if isInUse then

            --[[DEBUG]] if doDebug then
            --[[DEBUG]] print("SNIPPET... i:",i, "bumper:",bumper:GetName())
            --[[DEBUG]] end
            bumper:ClearAllPoints()

            btnCountForThisLine = btnCountForThisLine + 1

--local doDebug = true

local isFirstBtnOfLine
if btnCountForThisLine > maxBtnsPerLine then
    isFirstBtnOfLine = true
    anchorBuddy = firstBumperOfPreviousLine or flyoutMenu
    linesCount = linesCount + 1
    local btnSize = isVert and bumper:GetHeight() or bumper:GetWidth()
    lineGirth = (btnSize + defaultSpacing)
    lineOff = lineGirth * (linesCount-1)

    --[[DEBUG]] if doDebug then
    --[[DEBUG]] print("=== BREAK === i",i, "btn",btn:GetName(), "anchorBuddy",anchorBuddy:GetName(), "maxBtnsPerLine",maxBtnsPerLine, "linesCount",linesCount, "btnCountForThisLine",btnCountForThisLine, "btnSize",btnSize, "lineGirth",lineGirth)
    --[[DEBUG]] end
    btnCountForThisLine = 1
end

            local isFirstBtn     = anchorBuddy == flyoutMenu
            local spacing        = isFirstBtn and initialSpacing or defaultSpacing
            local anchorForDir   = DIRECTION_AS_ANCHOR[dir]
            local anchorOpposite = ANCHOR_OPPOSITE[anchorForDir]
            local ptOnMe     = anchorOpposite
            local ptOnAnchorBuddy = isFirstBtn and anchorOpposite or anchorForDir

            if isFirstBtn then
                -- anchor a corner of the btn to the same corner of the flyout
                -- the anchor is the opposite corner from the flyout's grow direction and wrap dir
                -- eg, flies up and grows right, then anchor corner is bottom-left
                local anchPrefix, tmp, anchPost
                if isVert then
                    anchPrefix = anchorOpposite
                    tmp = DIRECTION_AS_ANCHOR[vertLineWrapDir]
                    anchPost = ANCHOR_OPPOSITE[tmp]
                    --[[DEBUG]] if doDebug then print("===1=== isVert",isVert) end
                else
                    tmp = DIRECTION_AS_ANCHOR[horizLineWrapDir]
                    anchPrefix = ANCHOR_OPPOSITE[tmp]
                    anchPost = anchorOpposite
                    --[[DEBUG]] if doDebug then print("===2=== isVert",isVert) end
                end
                --[[DEBUG]] if doDebug then print("anchorForDir",anchorForDir, "anchorOpposite",anchorOpposite, "tmp",tmp, "anchPost",anchPost) end
                ptOnAnchorBuddy = anchPrefix..anchPost
                ptOnMe = ptOnAnchorBuddy
            elseif isFirstBtnOfLine then
                if isVert then
                    ptOnAnchorBuddy = DIRECTION_AS_ANCHOR[vertLineWrapDir]
                    ptOnMe = ANCHOR_OPPOSITE[ptOnAnchorBuddy]
                else
                    ptOnAnchorBuddy = DIRECTION_AS_ANCHOR[horizLineWrapDir]
                    ptOnMe = ANCHOR_OPPOSITE[ptOnAnchorBuddy]
                end
            end

            local wW = bumper:GetWidth()
            local wH = bumper:GetHeight()
            local aW = btn:GetWidth()
            local aH = btn:GetHeight()

            --[[DEBUG]] if doDebug then
            --[[DEBUG]] print("ptOnMe",ptOnMe, "ptOnAnchorBuddy",ptOnAnchorBuddy, "anchorBuddy", anchorBuddy:GetName(), "wW",math.floor(wW), "wH",math.floor(wH),  "aW",math.floor(aW), "aH",math.floor(aH))
            --[[DEBUG]] end

            bumper:SetPoint(ptOnMe, anchorBuddy, ptOnAnchorBuddy, 0, 0)
            anchorBuddy:Show()

            if btnCountForThisLine == 1 then
                firstBumperOfPreviousLine = bumper
            end

            anyBumper = bumper
            anchorBuddy = bumper
            btn:Show()
        else
            btn:Hide()
        end
    end

    local btnW = anyBumper and anyBumper:GetWidth() or 10
    local btnH = anyBumper and anyBumper:GetHeight() or 10
    local btnsPerLine = (numButtons == 0) and 2 or maxBtnsPerLine

    if isVert then
        flyoutMenu:SetWidth(btnW * linesCount)
        flyoutMenu:SetHeight(btnH * btnsPerLine)
    else
        flyoutMenu:SetWidth(btnW * btnsPerLine)
        flyoutMenu:SetHeight(btnH * linesCount)
    end
]=]
    end

    return SecEnv.LAYOUT_SCRIPT
end

function SecEnv:getSecEnvScriptFor_KeyBinding()
    if not SecEnv.FLYOUT_KEY_BINDING_SCRIPT then
        SecEnv.FLYOUT_KEY_BINDING_SCRIPT = [=[

        local arg1, arg2, arg3 = ...;
        local i = arg1
        local germ = arg2

        if i > 10 then return end

        local numberKey = (i == 10) and "0" or tostring(i)
        flyoutMenu:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
        if numberKey == "1" then
            -- make the UFO's first button's keybind be the same as the UFO itself
            local germKeyBind = germ:GetAttribute("UFO_KEYBIND_1")
            if germKeyBind then
                flyoutMenu:SetBindingClick(true, germKeyBind, btn, "]=].. MouseClick.LEFT ..[=[")
            end
        end

]=]
    end

    return SecEnv.FLYOUT_KEY_BINDING_SCRIPT
end

-------------------------------------------------------------------------------
--
-- Whatever.  I'm so over it
--
-------------------------------------------------------------------------------

function SecEnv:loadConfigOptions()
    UFO_DUM_DUM:setSecEnvAttribute("doCloseOnClick", Config:get("doCloseOnClick"))
end

function SecEnv:installSecEnvScriptFor_OpenMyFlyout(secFrame)
    assert(not secFrame.isOpenerScriptInitialized, "Wut?  The OPENER script is already installed.  Why you call again?")
    secFrame.isOpenerScriptInitialized = true
    secFrame:setSecEnvAttribute("_".. SecEnv.OPENER_SCRIPT_REF_NAME,
    [=[
        --print("Germ:installSecEnvScriptFor_Opener ... CLICKY CLICK !!! button",button, "down",down)
        flyoutMenu:RunAttribute("_]=]..SecEnv.FLYOUT_OPENER_AND_LAYOUT_SCRIPT_NAME ..[=[", button, down)
]=]
    )
end
