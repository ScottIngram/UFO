-- DetailerPopup
-- Opened by the "Change Name/Icon" button in catalog to let the user pick an icon for a flyoutmenu.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(Debug.OUTPUT.WARN)

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local NUM_FLYOUT_ICONS_SHOWN = 15
local NUM_FLYOUT_ICONS_PER_ROW = 5
local NUM_FLYOUT_ICON_ROWS = 3
local FLYOUT_ICON_ROW_HEIGHT = 36
local FC_ICON_FILENAMES = {}

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting DetailerPopup XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_DetailerPopup_Update()
    refreshFlyoutIconInfo()

    local popup = UIUFO_DetailerPopup
    local buttons = popup.buttons
    local offset = FauxScrollFrame_GetOffset(UIUFO_DetailerPopupScrollFrame) or 0
    -- Icon list
    local texture, index, _
    for i=1, NUM_FLYOUT_ICONS_SHOWN do
        local button = buttons[i]
        index = (offset * NUM_FLYOUT_ICONS_PER_ROW) + i
        if index <= #FC_ICON_FILENAMES then
            texture = getFlyoutIconInfo(index)

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
    detailerPopup.isEdit = false
    GLOBAL_UIUFO_RecalculateDetailerPopup()
end

function GLOBAL_UIUFO_DetailerPopup_OnHide(detailerPopup)
    UIUFO_DetailerPopup.name = nil
    UIUFO_DetailerPopup:SetSelection(true, nil)
    --UIUFO_DetailerPopupEditBox:SetText("")
    FC_ICON_FILENAMES = nil
    collectgarbage()
end

function GLOBAL_UIUFO_DetailerPopupOkayBtn_OnClick(okayBtn, whichMouseButton, pushed)
    local popup = okayBtn:GetParent()
    local iconTexture
    if popup.selectedIcon ~= 1 then
        iconTexture = getFlyoutIconInfo(popup.selectedIcon)
    end

    local config
    if popup.isEdit then
        -- Modifying a flyout
        config = FlyoutMenusDb:get(popup.name)
    else
        -- Saving a new flyout
        config = FlyoutMenusDb:appendNewOne()
    end
    config.icon = iconTexture
    popup:Hide()
    updateCatalog()
    updateAllGerms()
end

function GLOBAL_UIUFO_CatalogFlyoutOptionsDetailerBtn_OnDragStart(btn)
    if btn.name and btn.name ~= "" then
        pickupFlyout(btn.name)
    end
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

function GLOBAL_UIUFO_RecalculateDetailerPopup(iconTexture)
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
    refreshFlyoutIconInfo()
    local totalItems = #FC_ICON_FILENAMES
    local texture, _
    if popup.selectedTexture then
        local foundIndex = nil
        for index=1, totalItems do
            texture = getFlyoutIconInfo(index)
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

--[[
RefreshFlyoutIconInfo() counts how many uniquely textured spells the player has in the current flyout.
]]
function refreshFlyoutIconInfo()
    FC_ICON_FILENAMES = {}
    FC_ICON_FILENAMES[1] = "INV_MISC_QUESTIONMARK"
    local index = 2

    local popup = UIUFO_DetailerPopup
    local flyoutId = popup.name
    if flyoutId then
        local flyoutDef = FlyoutMenusDb:get(flyoutId)
        local spells = flyoutDef.spells
        local actionTypes = flyoutDef.actionTypes
        local pets = flyoutDef.pets
        for i = 1, #actionTypes do
            local itemTexture = getTexture(actionTypes[i], spells[i], pets[i])
            if itemTexture then
                FC_ICON_FILENAMES[index] = gsub( strupper(itemTexture), "INTERFACE\\ICONS\\", "" )
                if FC_ICON_FILENAMES[index] then
                    index = index + 1
                    for j=1, (index-1) do
                        if FC_ICON_FILENAMES[index] == FC_ICON_FILENAMES[j] then
                            FC_ICON_FILENAMES[index] = nil
                            index = index - 1
                            break
                        end
                    end
                end
            end
        end
    end
    GetLooseMacroIcons(FC_ICON_FILENAMES)
    GetMacroIcons(FC_ICON_FILENAMES)
end

function getFlyoutIconInfo(index)
    return FC_ICON_FILENAMES[index]
end
