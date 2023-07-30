-- DetailerPopup
-- Opened by the "Change Name/Icon" button in catalog to let the user pick an icon for a flyoutmenu.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local NUM_FLYOUT_ICONS_SHOWN = 15
local NUM_FLYOUT_ICONS_PER_ROW = 5
local NUM_FLYOUT_ICON_ROWS = 3
local FLYOUT_ICON_ROW_HEIGHT = 36
local FC_ICON_FILENAMES

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting DetailerPopup XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_DetailerPopup_Update()
    initIconList()

    local popup = UIUFO_DetailerPopup
    local buttons = popup.buttons
    local offset = FauxScrollFrame_GetOffset(UIUFO_DetailerPopupScrollFrame) or 0
    -- Icon list
    local texture, index, _
    for i=1, NUM_FLYOUT_ICONS_SHOWN do
        local button = buttons[i]
        index = (offset * NUM_FLYOUT_ICONS_PER_ROW) + i
        if index <= #FC_ICON_FILENAMES then
            texture = getIcon(index)

            if(type(texture) == "number") then
                button.icon:SetTexture(texture);
            else
                button.icon:SetTexture("INTERFACE\\ICONS\\"..texture);
            end
            button:Show()
            if index == popup.selectedIcon then
                button:SetChecked(1)
            elseif string.upper(texture) == popup.selectedTexture then
                button:SetChecked(1)
                popup:SetSelection(false, index)
            else
                button:SetChecked(nil)
            end
        else
            button.icon:SetTexture("")
            button:Hide()
        end

    end

    -- Scrollbar stuff
    FauxScrollFrame_Update(UIUFO_DetailerPopupScrollFrame, ceil(#FC_ICON_FILENAMES / NUM_FLYOUT_ICONS_PER_ROW), NUM_FLYOUT_ICON_ROWS, FLYOUT_ICON_ROW_HEIGHT)
end

function GLOBAL_UIUFO_DetailerPopup_OnLoad (detailerPopup)
    detailerPopup.buttons = {}

    local button = CreateFrame("CheckButton", "UIUFO_DetailerPopupButton1", UIUFO_DetailerPopup, "UIUFO_CatalogPopupBtnTemplate")
    button:SetPoint("TOPLEFT", 24, -37)
    button:SetID(1)
    tinsert(detailerPopup.buttons, button)

    local lastPos
    for i = 2, NUM_FLYOUT_ICONS_SHOWN do
        button = CreateFrame("CheckButton", "UIUFO_DetailerPopupButton" .. i, UIUFO_DetailerPopup, "UIUFO_CatalogPopupBtnTemplate")
        button:SetID(i)

        lastPos = (i - 1) / NUM_FLYOUT_ICONS_PER_ROW
        if lastPos == math.floor(lastPos) then
            button:SetPoint("TOPLEFT", detailerPopup.buttons[i-NUM_FLYOUT_ICONS_PER_ROW], "BOTTOMLEFT", 0, -8)
        else
            button:SetPoint("TOPLEFT", detailerPopup.buttons[i-1], "TOPRIGHT", 10, 0)
        end
        tinsert(detailerPopup.buttons, button)
    end

    detailerPopup.SetSelection = function(detailerPopup, isTexture, texture)
        if isTexture then
            detailerPopup.selectedTexture = texture
            detailerPopup.selectedIcon = nil
        else
            detailerPopup.selectedTexture = nil
            detailerPopup.selectedIcon = texture
        end
    end
end

function GLOBAL_UIUFO_DetailerPopup_OnShow(detailerPopup)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    detailerPopup.name = nil
    detailerPopup.flyoutId = nil
    detailerPopup.isEdit = false
    initDetailerPopup()
end

function GLOBAL_UIUFO_DetailerPopup_OnHide(detailerPopup)
    detailerPopup.name = nil
    detailerPopup.flyoutId = nil
    detailerPopup:SetSelection(true, nil)
    --UIUFO_DetailerPopupEditBox:SetText("")
    FC_ICON_FILENAMES = nil
    collectgarbage()
end

function GLOBAL_UIUFO_DetailerPopupOkayBtn_OnClick(okayBtn, whichMouseButton, pushed)
    local popup = okayBtn:GetParent()
    local iconTexture
    if popup.selectedIcon ~= 1 then
        iconTexture = getIcon(popup.selectedIcon)
    end

    local flyoutDef
    if popup.isEdit then
        -- Modifying a flyout
        flyoutDef = FlyoutDefsDb:get(popup.flyoutId)
    else
        -- Saving a new flyout
        flyoutDef = FlyoutDefsDb:appendNewOne()
        zebug:dumpy("appendNewOne -> flyoutDef",flyoutDef)
    end
    zebug:print("popup.isEdit",popup.isEdit, "popup.flyoutId",popup.flyoutId, "flyoutDef",flyoutDef)
    flyoutDef.icon = iconTexture
    popup:Hide()
    Catalog:update()
    GermCommander:updateAll()
end

function GLOBAL_UIUFO_CatalogPopupBtn_OnClick(btn, whichMouseButton, down)
    local popup = btn:GetParent()
    local offset = FauxScrollFrame_GetOffset(UIUFO_DetailerPopupScrollFrame) or 0
    popup.selectedIcon = (offset * NUM_FLYOUT_ICONS_PER_ROW) + btn:GetID()
    popup.selectedTexture = nil
    GLOBAL_UIUFO_DetailerPopup_Update()

    if popup.selectedIcon --[[and popup.name]] then
        UIUFO_DetailerPopupOkayBtn:Enable()
    else
        UIUFO_DetailerPopupOkayBtn:Disable()
    end
end

function initDetailerPopup(iconTexture)
    local popup = UIUFO_DetailerPopup;

    if iconTexture then
        popup:SetSelection(true, iconTexture)
    else
        popup:SetSelection(false, 1)
    end

    --[[
    Scroll and ensure that any selected equipment shows up in the list.
    When we first press "save", we want to make sure any selected equipment set shows up in the list, so that
    the user can just make his changes and press Okay to overwrite.
    To do this, we need to find the current set (by icon) and move the offset of the UIUFO_DetailerPopup
    to display it. Issue ID: 171220
    ]]
    initIconList()
    local totalItems = #FC_ICON_FILENAMES
    local texture, _
    if popup.selectedTexture then
        local foundIndex = nil
        for index=1, totalItems do
            texture = getIcon(index)
            if texture == popup.selectedTexture then
                foundIndex = index
                break
            end
        end
        if foundIndex == nil then
            foundIndex = 1
        end
        -- now make it so we always display at least NUM_FLYOUT_ICON_ROWS of data
        local offsetnumIcons = floor((totalItems-1)/NUM_FLYOUT_ICONS_PER_ROW)
        local offset = floor((foundIndex-1) / NUM_FLYOUT_ICONS_PER_ROW)
        offset = offset + min((NUM_FLYOUT_ICON_ROWS-1), offsetnumIcons-offset) - (NUM_FLYOUT_ICON_ROWS-1)
        if foundIndex<=NUM_FLYOUT_ICONS_SHOWN then
            offset = 0			--Equipment all shows at the same place.
        end
        FauxScrollFrame_OnVerticalScroll(UIUFO_DetailerPopupScrollFrame, offset*FLYOUT_ICON_ROW_HEIGHT, FLYOUT_ICON_ROW_HEIGHT, nil);
    else
        FauxScrollFrame_OnVerticalScroll(UIUFO_DetailerPopupScrollFrame, 0, FLYOUT_ICON_ROW_HEIGHT, nil);
    end
    GLOBAL_UIUFO_DetailerPopup_Update()
end

-------------------------------------------------------------------------------
-- Functions Supporting DetailerPopup UI
-------------------------------------------------------------------------------

function initIconList()
    if FC_ICON_FILENAMES then
        return
    end

    FC_ICON_FILENAMES = {}
    FC_ICON_FILENAMES[1] = "INV_MISC_QUESTIONMARK"
    GetLooseMacroIcons(FC_ICON_FILENAMES)
    GetMacroIcons(FC_ICON_FILENAMES)
end

function getIcon(index)
    return FC_ICON_FILENAMES[index]
end
