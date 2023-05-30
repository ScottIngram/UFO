-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
---@type Debug -- IntelliJ-EmmyLua annotation
local debugTrace, debugInfo, debugWarn, debugError = Debug:new(Debug.TRACE)

-- TODO add @class and fields like name and methods like registerHandlers
---@class ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
local ButtonOnFlyoutMenu = {
    flyoutId = false,
    isOnGerm = false,
    isInCatalog = false,
}
Ufo.ButtonOnFlyoutMenu = ButtonOnFlyoutMenu

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu:registerHandlers()

end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutBtn XML Callbacks
-------------------------------------------------------------------------------

-- initialize and coerce the Bliz ActionButton into a ButtonOnFlyoutMenu
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnLoad(btnOnFlyout)
    btnOnFlyout:SmallActionButtonMixin_OnLoad()
    btnOnFlyout.PushedTexture:SetSize(31.6, 30.9)
    btnOnFlyout:RegisterForDrag("LeftButton")
    _G[btnOnFlyout:GetName().."Count"]:SetPoint("BOTTOMRIGHT", 0, 0)
    btnOnFlyout.maxDisplayCount = 99
    btnOnFlyout:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    -- TODO: copy ButtonOnFlyoutMenu fields and methods onto the btnOnFlyout object
end

-- add a spell/item/etc to a flyout
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnReceiveDrag(btnOnFlyout)
    local thingyId, mountIndex, macroOwner, pet

    local flyoutMenu = btnOnFlyout:GetParent()
    if not flyoutMenu.IsConfig then return end

    local flyoutId = flyoutMenu.idFlyout

    local kind, info1, info2, info3 = GetCursorInfo()
    local actionType = kind

    -- TODO: distinguish between toys and spells
    --print("@@@@ GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnReceiveDrag-->  kind =",kind, " --  info1 =",info1, " --  info2 =",info2, " --  info3 =",info3)
    if kind == "spell" then
        thingyId = info3
    elseif kind == "mount" then
        actionType = "spell" -- mounts can be summoned by casting as a spell
        _, thingyId, _, _, _, _, _, _, _, _, _ = C_MountJournal.GetDisplayedMountInfo(Ufo.mountIndex);
        mountIndex = Ufo.mountIndex
    elseif kind == "item" then
        thingyId = info1
    elseif kind == "macro" then
        thingyId = info1
        if not isMacroGlobal(thingyId) then
            macroOwner = getIdForCurrentToon()
        end
    elseif kind == "battlepet" then
        pet = info1
    else
        actionType = nil
    end

    if actionType then
        local flyoutConf = getFlyoutConfig(flyoutId)
        local btnIndex = btnOnFlyout:GetID()

        local oldThingyId   = flyoutConf.spells[btnIndex]
        local oldActionType = flyoutConf.actionTypes[btnIndex]
        local oldMountIndex = flyoutConf.mountIndex[btnIndex]
        local oldPet        = flyoutConf.pets[btnIndex]

        flyoutConf.spells[btnIndex] = thingyId
        flyoutConf.actionTypes[btnIndex] = actionType
        flyoutConf.mountIndex[btnIndex] = mountIndex
        flyoutConf.spellNames[btnIndex] = getThingyNameById(actionType, thingyId or pet)
        flyoutConf.macroOwners[btnIndex] = macroOwner
        flyoutConf.pets[btnIndex] = pet

        --print("@#$* GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnReceiveDrag-->  btnIndex =",btnIndex, "| kind =",kind, "| thingyId =",thingyId, "| petId =", pet)

        -- drop the dragged spell/item/etc
        ClearCursor()
        updateAllGerms()
        updateFlyoutMenuForCatalog(flyoutMenu, flyoutId)

        -- update the cursor to show the existing spell/item/etc (if any)
        if oldActionType == "spell" then
            if oldMountIndex then
                C_MountJournal.Pickup(oldMountIndex)
            else
                PickupSpell(oldThingyId)
            end
        elseif oldActionType == "item" then
            PickupItem(oldThingyId)
        elseif oldActionType == "macro" then
            PickupMacro(oldThingyId)
        elseif oldActionType == "battlepet" then
            C_PetJournal.PickupPet(oldPet)
        end
    else
        print("sorry, unsupported type:", kind)
    end
end

function GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip(btnOnFlyout)
    local thingyId = btnOnFlyout.spellID
    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, btnOnFlyout)

        local tooltipSetter
        if btnOnFlyout.actionType == "spell" then
            tooltipSetter = GameTooltip.SetSpellByID
        elseif btnOnFlyout.actionType == "item" then
            tooltipSetter = GameTooltip.SetItemByID
        elseif btnOnFlyout.actionType == "macro" then
            tooltipSetter = function(zelf, macroId)
                local name, _, _ = GetMacroInfo(macroId)
                if not macroId then macroId = "NiL" end
                return GameTooltip:SetText("Macro: ".. macroId .." " .. (name or "UNKNOWN"))
            end
        elseif btnOnFlyout.actionType == "battlepet" then
            thingyId = btnOnFlyout.battlepet
            tooltipSetter = GameTooltip.SetCompanionPet
            -- print("))))) GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip(): actionType = battlepet | thingyId =", thingyId)
        end

        if tooltipSetter and thingyId and tooltipSetter(GameTooltip, thingyId) then
            btnOnFlyout.UpdateTooltip = GLOBAL_UIUFO_ButtonOnFlyoutMenu_SetTooltip
        else
            btnOnFlyout.UpdateTooltip = nil
        end
    else
        local parent = btnOnFlyout:GetParent():GetParent():GetParent():GetParent()
        if parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft then
            GameTooltip:SetOwner(btnOnFlyout, "ANCHOR_LEFT")
        else
            GameTooltip:SetOwner(btnOnFlyout, "ANCHOR_RIGHT")
        end
        local spellName = getThingyNameById(btnOnFlyout.actionType, thingyId)
        GameTooltip:SetText(spellName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        btnOnFlyout.UpdateTooltip = nil
    end
end

-- pickup an existing button from an existing flyout
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnDragStart(btnOnFlyout)
    if InCombatLockdown() then return end

    local actionType = btnOnFlyout.actionType
    local spell = btnOnFlyout.spellID
    local mountIndex = btnOnFlyout.mountIndex
    local pet = btnOnFlyout.battlepet

    if actionType == "spell" then
        if mountIndex then
            C_MountJournal.Pickup(mountIndex)
        else
            PickupSpell(spell)
        end
        Ufo.mountIndex = mountIndex
    elseif actionType == "item" then
        PickupItem(spell)
    elseif actionType == "macro" then
        PickupMacro(spell)
    elseif actionType == "battlepet" then
        C_PetJournal.PickupPet(pet)
    end

    --print("#### GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnDragStart-->  actionType =",actionType, " spellID =", spell, " mountIndex =", mountIndex, "petId =", pet)

    local flyoutFrame = btnOnFlyout:GetParent()
    if flyoutFrame.IsConfig then
        removeSpell(flyoutFrame.idFlyout, btnOnFlyout:GetID())
        updateAllGerms()
        updateFlyoutMenuForCatalog(flyoutFrame, flyoutFrame.idFlyout)
    end
end
