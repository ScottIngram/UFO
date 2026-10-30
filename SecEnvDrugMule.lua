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
    scripts = {},
}

-------------------------------------------------------------------------------
--
-- SecEnv Scripts
--
-------------------------------------------------------------------------------

-- TODO move to SecEnvDrugMule

-- use non-local "global" variables to save values between executions
-- because GetParent() returns nil during combat lockdown
SecEnv.scripts.CLOSE_FLYOUT_WHEN_BTN_IS_CLICKED_SEC_ENV_SCRIPT = [=[
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
    --[[DEBUG]]     print("<DEBUG>", flyoutName, id, "doClose:", doClose, "doClose2",doClose2, "doClose3",doClose3)
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
        SecEnv.OPENER_SCRIPT = SecEnv:initSecEnvScriptFor_Opener()
    end

    return SecEnv.OPENER_SCRIPT
end

function SecEnv:initSecEnvScriptFor_Opener()
    SecEnv.OPENER_SCRIPT = [=[
    local arg1, arg2 = ...;

    local mouseClick = button or arg1 --"button" is auto-assigned by Bliz for an ON_CLICK handler.  But for generic scripts, we must use ...
    local isClicked = down or arg2
    local dir = germ:GetAttribute( "]=].. SecEnvAttribute.flyoutDirection ..[=[" )
    local isOpen = flyoutMenu:IsShown()
    flyoutName = flyoutMenu:GetAttribute("UFO_NAME")

    --local doDebug = true
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
    -- or the the old layout needs to adjust to accommodate a different number of buttons
    -- OR BECAUSE
    -- the max length config option has changed

    local POPULATED_BUTTON_COUNT = flyoutMenu:GetAttribute("POPULATED_BUTTON_COUNT")
    local OPTION_MAX_LEN         = UFO_DUM_DUM:GetAttribute("OPTION_MAX_LEN")
    local isNewLayoutNeeded      = false

    if (not renderedButtonCount) or (renderedButtonCount ~= POPULATED_BUTTON_COUNT) then
        isNewLayoutNeeded = true
    elseif (not optionMaxLen) or (optionMaxLen ~= OPTION_MAX_LEN) then
        isNewLayoutNeeded = true
    end

    --[[DEBUG]] if doDebug then print("renderedButtonCount",renderedButtonCount, "POPULATED_BUTTON_COUNT",POPULATED_BUTTON_COUNT, "optionMaxLen",optionMaxLen,  "OPTION_MAX_LEN",OPTION_MAX_LEN,  "isNewLayoutNeeded",isNewLayoutNeeded ) end

    renderedButtonCount = POPULATED_BUTTON_COUNT
    optionMaxLen = OPTION_MAX_LEN

    if isNewLayoutNeeded then
        --[[DEBUG]] if doDebug then
        --[[DEBUG]]     print("<DEBUG>", myName, "RUNNING layout")
        --[[DEBUG]] end
        flyoutMenu:RunAttribute("_]=] .. SecEnv.FLYOUT_LAYOUT_SCRIPT_NAME .. [=[", renderedButtonCount, dir, flyoutMenu, "suckit")
    end

    --
    -- GERM only
    -- keybind each button to 1-9 and 0
    --

    if germ then
        local doKeybindTheButtonsOnTheFlyout = germ:GetAttribute("doKeybindTheButtonsOnTheFlyout")
        if doKeybindTheButtonsOnTheFlyout then
            local LFT_BTN = "]=].. MouseClick.LEFT ..[=["
            local lastKeyNum = math.min(renderedButtonCount, 10)
            for i = 1, lastKeyNum do
                local btn = flyoutMenu:GetFrameRef(tostring(i))
                local btnName = btn and btn:GetName()
                local btnNameType = type(btnName)
                local numberKey = (i == 10) and "0" or tostring(i)
                --[[DEBUG]] if doDebug then print("=== ScriptFor_Opener()",flyoutName,"- GERM's flyout's btns -",numberKey, "DEBUG - btn",btn, "btnName",btnName, "btnNameType",btnNameType) end
                flyoutMenu:SetBindingClick(true, numberKey, btn, LFT_BTN)
                if numberKey == "1" then
                    -- make the UFO's first button's keybind be the same as the UFO itself
                    local germKeyBind = germ:GetAttribute("UFO_KEYBIND_1")
                    if germKeyBind then
                        --[[DEBUG]] if doDebug then print("=== ScriptFor_Opener()",flyoutName,"- GERM first btn -",numberKey,"binding btnName:", btnName, btnNameType, "to mouseClick ", LFT_BTN ) end
                        flyoutMenu:SetBindingClick(true, btnName, btnName, LFT_BTN)
                    end
                end
            end
        end

        --[[DEBUG]] if doDebug then print("=== ScriptFor_Opener()",flyoutName,"- GERM end!" ) end
    end

    flyoutMenu:Show()
    --[[DEBUG]] if doDebug then print("=== ScriptFor_Opener()",flyoutName,"- END !!!" ) end
]=]

    return SecEnv.OPENER_SCRIPT
end

---@param flyoutMenuFrame FlyoutMenu
function SecEnv:executeFromNonSecEnv_Layout(flyoutMenuFrame, populatedButtonCount, dir, displaceBtnsHere)
    zebug.info:event("EXE"):owner(flyoutMenuFrame):print("populatedButtonCount", populatedButtonCount, "dir",dir, "displaceBtnsHere",displaceBtnsHere)

    -- replace the safely - pacify the whole func
    flyoutMenuFrame:safelySetSecEnvAttribute("ARG_POPULATED_BUTTON_COUNT", populatedButtonCount)
    flyoutMenuFrame:safelySetSecEnvAttribute("ARG_DIR", dir)
    flyoutMenuFrame:safelySetSecEnvAttribute("ARG_TARGET_INDEX", displaceBtnsHere)
    flyoutMenuFrame:Execute([=[
        local populatedButtonCount = flyoutMenu:GetAttribute("ARG_POPULATED_BUTTON_COUNT")
        local displaceBtnsHere     = flyoutMenu:GetAttribute("ARG_TARGET_INDEX")
        local dir                  = flyoutMenu:GetAttribute("ARG_DIR")
        --print("EXE bridge - populatedButtonCount",populatedButtonCount, "dir",dir, "displaceBtnsHere",displaceBtnsHere)

        flyoutMenu:RunAttribute("_]=] .. SecEnv.FLYOUT_LAYOUT_SCRIPT_NAME .. [=[", populatedButtonCount, dir, displaceBtnsHere) ]=])
end

function SecEnv:getSecEnvScriptFor_Layout()
    if not SecEnv.LAYOUT_SCRIPT then
        SecEnv.LAYOUT_SCRIPT = SecEnv:initSecEnvScriptFor_Layout()
    end
    return SecEnv.LAYOUT_SCRIPT
end

function SecEnv:initSecEnvScriptFor_Layout()
    SecEnv.LAYOUT_SCRIPT = [=[
    local initialSpacing = ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[; -- evidently, lua strips this line break hence the ;
    local defaultSpacing = ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[;

    local arg1, arg2, arg3 = ...;
    local populatedButtonCount = math.max(1, arg1)
    local dir = arg2
    local displaceBtnsHere = arg3
    local isVert = dir == "UP" or dir == "DOWN"

    local flyoutName = flyoutMenu:GetAttribute("UFO_NAME")

    --local doDebug = true
    --[[DEBUG]] if doDebug then print("sucking pipe... populatedButtonCount",populatedButtonCount, "arg2",arg2, "arg3",arg3, "dir",dir, "displaceBtnsHere",displaceBtnsHere) end

    local isForCatalog = flyoutMenu:GetAttribute("IS_FOR_CATALOG")

    -- calculate if the flyout is too long, then how many rows & columns
    local configMaxLen = UFO_DUM_DUM:GetAttribute("FLYOUT_MAX_LEN") or 100
    local vertLineWrapDir = "RIGHT"
    local horizLineWrapDir = "UP"
    local linesCountMax = math.ceil(populatedButtonCount / configMaxLen)
    local maxBtnsPerLine = (isForCatalog and 15) or math.ceil(populatedButtonCount / linesCountMax)
    --[[DEBUG]] if doDebug then print("isForCatalog",isForCatalog, "configMaxLen",configMaxLen, "populatedButtonCount =",populatedButtonCount, "maxBtnsPerLine",maxBtnsPerLine, "linesCountMax",linesCountMax) end
    if linesCountMax > configMaxLen then
        linesCountMax = math.floor( math.sqrt(populatedButtonCount) )
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

    ALLOCATED_BUTTON_COUNT = flyoutMenu:GetAttribute("ALLOCATED_BUTTON_COUNT")
    POPULATED_BUTTON_COUNT = flyoutMenu:GetAttribute("POPULATED_BUTTON_COUNT")

    for i = 1, ALLOCATED_BUTTON_COUNT do
        local btn = flyoutMenu:GetFrameRef(tostring(i))
        local bumper = btn:GetFrameRef("bumper")
        local isInUse = btn:GetAttribute("UFO_NAME") -- the " " blank string is used to indicate the empty slot in catalog flyouts

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

            -- avoid accidentally opening the flyout menu
            if anchorBuddy ~= flyoutMenu then
                anchorBuddy:Show()
            end

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
    local btnsPerLine = (populatedButtonCount == 0) and 2 or maxBtnsPerLine

    if isVert then
        flyoutMenu:SetWidth(btnW * linesCount)
        flyoutMenu:SetHeight(btnH * btnsPerLine)
    else
        flyoutMenu:SetWidth(btnW * btnsPerLine)
        flyoutMenu:SetHeight(btnH * linesCount)
    end
]=]

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
print("=== ScriptFor_KeyBinding()",flyoutName, " binding numberKey:", numberKey, "to mouseClick MouseClick.LEFT")
        flyoutMenu:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
        if numberKey == "1" then
            -- make the UFO's first button's keybind be the same as the UFO itself
            local germKeyBind = germ:GetAttribute("UFO_KEYBIND_1")
            if germKeyBind then
print("=== ScriptFor_Opener() prime? binding germKeyBind:", germKeyBind, "to mouseClick MouseClick.LEFT")
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
    UFO_DUM_DUM:setSecEnvAttribute("FLYOUT_MAX_LEN", Config:get(Config.field.name.flyoutMaxSize))
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
