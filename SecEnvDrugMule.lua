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
---@field OPENER_NAME string keyname for the sec-env attribute that will hold the OPENER_SCRIPT
---@field OPENER_SCRIPT string code/script. will be initialized on-demand
---@field ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR string keyname for the sec-env attribute that will hold the
---@field ON_CLICK_RND_ETC_PICK_BTN_SCRIPT string code/script. will be initialized on-demand
SecEnv = {
    OPENER_NAME = "SEC_ENV_OPENER_NAME",
    ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR = "SEC_ENV_ON_CLICK_SCRIPT_NAME_PREFIX_FOR___ARBITRARY_BEHAVIOR_",
}

-------------------------------------------------------------------------------
--
-- SecEnv Scripts
--
-------------------------------------------------------------------------------

function SecEnv:getSecEnvScriptFor_Opener()
    if not SecEnv.OPENER_SCRIPT then
        local DIRECTION_AS_ANCHOR = serializeAsAssignments("DIRECTION_AS_ANCHOR", DirectionAsAnchor)
        local ANCHOR_OPPOSITE = serializeAsAssignments("ANCHOR_OPPOSITE", AnchorOpposite)

        SecEnv.OPENER_SCRIPT =
        [=[
        --local doDebug = true

            local mouseClick = button
            local isClicked = down
            local dir = germ:GetAttribute( "]=].. SecEnvAttribute.flyoutDirection ..[=[" )
    local isVert = dir == "UP" or dir == "DOWN"
    local isOpen = flyoutMenu:IsShown()
    local initialSpacing = ]=].. SPELLFLYOUT_INITIAL_SPACING ..[=[
    local defaultSpacing = ]=].. SPELLFLYOUT_DEFAULT_SPACING ..[=[
    local finalSpacing   = ]=].. SPELLFLYOUT_FINAL_SPACING ..[=[
    ]=].. DIRECTION_AS_ANCHOR ..[=[
    ]=].. ANCHOR_OPPOSITE ..[=[

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

    -- arrange all the buttons onto the flyout

    -- get the buttons, filtering out trash
    local btns = table.new(flyoutMenu:GetChildren())
    while btns[1] and btns[1]:GetID() < 1 do
        --print("discarding", btns[1]:GetObjectType())
        table.remove(btns, 1) -- this is the non-button UI element "Background" from ui.xml
    end

    -- count the buttons being used on the flyout
    local numButtons = 0
    for i, btn in ipairs(btns) do
        local isInUse = btn:GetAttribute("UFO_NAME")
        if isInUse then
            numButtons = numButtons + 1
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
    for i, btn in ipairs(btns) do
        local wrapper = btn.bumper
        local bumper = btn.bumper
        --[[DEBUG]] --print("wrapper =",wrapper)


    local muhKids = table.new(btn:GetChildren())
    for i, frame in ipairs(muhKids) do
        --[[DEBUG]] -- print("i =",i, "name", frame:GetName(), frame:GetID())
        if frame:GetID() == 99 then
            bumper = frame
        end
    end

        local isInUse = btn:GetAttribute("UFO_NAME")

	    --[[DEBUG]] if doDebug then
        --[[DEBUG]] print("i:",i, "btn:",btn:GetName(), "isInUse",isInUse)
        --[[DEBUG]] end

        if isInUse then

            --[[DEBUG]] if doDebug then
            --[[DEBUG]] print("SNIPPET... i:",i, "bumper:",bumper:GetName())
            --[[DEBUG]] end
            bumper:ClearAllPoints()

            local xLineBump = 0
            local yLineBump = 0
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
    xLineBump = 0 -- isVert and lineOff or 0
    yLineBump = 0 -- not isVert and lineOff or 0
    --[[DEBUG]] if doDebug then
    --[[DEBUG]] print("=== BREAK === maxBtnsPerLine",maxBtnsPerLine, "linesCount",linesCount, "btnCountForThisLine",btnCountForThisLine, "btnSize",btnSize, "lineGirth",lineGirth)
    --[[DEBUG]] end
    btnCountForThisLine = 0
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
                else
                    tmp = DIRECTION_AS_ANCHOR[horizLineWrapDir]
                    anchPrefix = ANCHOR_OPPOSITE[tmp]
                    anchPost = anchorOpposite
                end
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

            --
            -- keybind each button to 1-9 and 0
            --

            local doKeybindTheButtonsOnTheFlyout = germ:GetAttribute("doKeybindTheButtonsOnTheFlyout")
            if doKeybindTheButtonsOnTheFlyout then
                if i < 11 then
                    -- TODO: make first keybind same as the UFO's
                    local numberKey = (i == 10) and "0" or tostring(i)
                    flyoutMenu:SetBindingClick(true, numberKey, btn, "]=].. MouseClick.LEFT ..[=[")
                    if numberKey == "1" then
                        -- make the UFO's first button's keybind be the same as the UFO itself
                        local germKey = self:GetAttribute("UFO_KEYBIND_1")
                        if germKey then
                            flyoutMenu:SetBindingClick(true, germKey, btn, "]=].. MouseClick.LEFT ..[=[")
                        end
                    end
                end
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
    local btnsPerLine = (numButtons == 0) and 2 or maxBtnsPerLine

    if isVert then
        flyoutMenu:SetWidth(btnW * linesCount)
        flyoutMenu:SetHeight(btnH * btnsPerLine)
    else
        flyoutMenu:SetWidth(btnW * btnsPerLine)
        flyoutMenu:SetHeight(btnH * linesCount)
    end

    --[[DEBUG]] if doDebug then
    --[[DEBUG]]     print("<DEBUG>", myName, "SHOWING flyout")
    --[[DEBUG]] end
    flyoutMenu:Show()
]=]
    end

    return SecEnv.OPENER_SCRIPT
end
