-- ButtonOnFlyoutMenu - a button on a flyout menu
-- methods and functions for custom buttons put into our custom flyout menus

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new(Debug.OUTPUT.WARN)

---@class ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
local ButtonOnFlyoutMenu = {
    ufoType = "ButtonOnFlyoutMenu",
}
Ufo.ButtonOnFlyoutMenu = ButtonOnFlyoutMenu

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local pickedUpMount -- workaround the Bliz API which handles mounts inconsistently

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

function ButtonOnFlyoutMenu.oneOfUs(btnOnFlyout)
    btnOnFlyout.BlizGetParent = btnOnFlyout.GetParent -- rename for safekeeping so I can implement OO inheritance

    -- merge the Bliz ActionButton object
    -- with this class's methods, functions, etc
    deepcopy(ButtonOnFlyoutMenu, btnOnFlyout)
end

---@return FlyoutMenu -- IntelliJ-EmmyLua annotation
function ButtonOnFlyoutMenu:GetParent()
    return self:BlizGetParent()
end

function ButtonOnFlyoutMenu:setIconTexture(texture)
    _G[ self:GetName().."Icon" ]:SetTexture(texture)
end

function ButtonOnFlyoutMenu:updateCooldownsAndCountsAndStatesEtc()
    if (self.spellID) then
        SpellFlyoutButton_UpdateState(self)
    end

    self:UpdateUsable()
    self:UpdateCooldown()
    self:UpdateCount()
end

function ButtonOnFlyoutMenu:UpdateUsable()
    local itemId = self.itemID
    local spellId = self.spellID

    local isUsable = true
    local notEnoughMana = false
    if itemId or spellId then
        if itemId then
            _, spellId = GetItemSpell(itemId)
            isUsable = IsUsableSpell(spellId)
        else
            isUsable, notEnoughMana = IsUsableSpell(spellId)
        end
    end

    debug.trace:out("#",5,"UpdateUsable", "isItem", itemId, "itemID",self.itemID, "spellID", spellId, "isUsable",isUsable)

    local name = self:GetName();
    local icon = _G[name.."Icon"];
    if isUsable then
        icon:SetVertexColor(1.0, 1.0, 1.0);
    elseif notEnoughMana then
        icon:SetVertexColor(0.5, 0.5, 1.0);
    else
        icon:SetVertexColor(0.4, 0.4, 0.4);
    end
end

function ButtonOnFlyoutMenu:UpdateCooldown()
    local itemId = self.itemID
    debug.trace:out("X",40,"Ufo_UpdateCooldown 1 ITEM","self.itemID",self.itemID, "self.spellID",self.spellID)

    if (not exists(itemId)) and exists(self.spellID) then
        -- use Bliz's built-in handler for the stuff it understands, ie, not items
        debug.trace:out("@",20,"updateCooldownsAndCountsAndStatesEtc", "self.spellID",self.spellID)
        SpellFlyoutButton_UpdateCooldown(self)
        return
    end

    -- for items, I copied and hacked Bliz's ActionButton_UpdateCooldown
    local modRate = 1.0;
    local start, duration, enable = GetItemCooldown(itemId);
    debug.trace:out("X",5,"Ufo_UpdateCooldown 2 ITEM","actionType",actionType, "start",start, "duration",duration, "enable",enable )

    if ( self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL ) then
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        self.cooldown:SetSwipeColor(0, 0, 0);
        self.cooldown:SetHideCountdownNumbers(false);
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
    end

    CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
end

function ButtonOnFlyoutMenu:UpdateCount()
    local itemId = self.itemID
    local hasItem = exists(itemId)

    if not hasItem then
        if exists(self.spellID) then
            debug.trace:out("X",5,"UFO_UpdateCount 0... deferring to SpellFlyoutButton_UpdateCount ", "spellID",self.spellID)
            -- use Bliz's built-in handler for the stuff it understands, ie, not items
            SpellFlyoutButton_UpdateCount(self)
            return
        end
    end

    local name, itemType, display
    if hasItem then
        name, _, _, _, _, itemType = GetItemInfo(itemId)
    end
    local includeBank = false
    local includeCharges = true
    local count = GetItemCount(itemId, includeBank, includeCharges)
    local tooMany = ( count > (self.maxDisplayCount or 9999 ) )
    debug.trace:out("X",5,"UFO_UpdateCount 1 ", "itemId",itemId, "hasItem",hasItem, "name",name, "itemType",itemType, "max",self.maxDisplayCount, "count",count, "tooMany",tooMany)

    local max = self.maxDisplayCount or 9999
    if count > max then
        display = ">"..max
    elseif CONSUMABLE == itemType then
        display = (count == 0) and "" or count
    else
        display = (count == 0 or count == 1) and "" or count
    end

    local textFrame = _G[self:GetName().."Count"];
    textFrame:SetText(display);
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutBtn XML Callbacks
-------------------------------------------------------------------------------

function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnLoad(btnOnFlyout)
    -- initialize the Bliz ActionButton
    btnOnFlyout:SmallActionButtonMixin_OnLoad()
    btnOnFlyout.PushedTexture:SetSize(31.6, 30.9)
    btnOnFlyout:RegisterForDrag("LeftButton")
    _G[btnOnFlyout:GetName().."Count"]:SetPoint("BOTTOMRIGHT", 0, 0)
    btnOnFlyout.maxDisplayCount = 99
    btnOnFlyout:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    -- coerce the Bliz ActionButton into a ButtonOnFlyoutMenu
    ButtonOnFlyoutMenu.oneOfUs(btnOnFlyout)
end

---@param btnOnFlyout ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
function GLOBAL_UIUFO_ButtonOnFlyoutMenu_OnReceiveDrag(btnOnFlyout)
    btnOnFlyout:OnReceiveDragAddIt()
end

-- add a spell/item/etc to a flyout
function ButtonOnFlyoutMenu:OnReceiveDragAddIt()
    -- only the flyouts in the catalog are allowed to change.  TODO: let flyouts on the germs receive too?

    local flyoutMenu = self:GetParent()
    if not flyoutMenu.isForCatalog then return end

    local kind, info1, info2, info3 = GetCursorInfo() -- info2 is sometimes a tooltip
    local actionType = kind

    -- TODO: distinguish between toys and spells

    debug.trace:out(">",5,"OnReceiveDrag","kind",kind,"info1",info1 ,"info2",info2, "info3",info3)

    -- Here, in the absence of useful documentation, I'm researching the behavior of these mount/pointer APIs
    -- debug.info:out(">",7,"OnReceiveDrag", "GetAllCreatureDisplayIDsForMountID -> info1",info1 )
    -- debug.info:print( C_MountJournal.GetAllCreatureDisplayIDsForMountID(info1) )
    -- debug.info:out(">",7,"OnReceiveDrag", "GetMountInfoByID -> info1",info1 )
    -- debug.info:print( C_MountJournal.GetMountInfoByID(info1) )

    local thingyId, mountId, macroOwner, pet

    if kind == "spell" then
        thingyId = info3
    elseif kind == "companion" then
        -- this is an abnormal result containing a useless ID which isn't accepted by any API.  Not helpful.
        -- It's caused when the mouse pointer is loaded via Bliz's API PickupSpell(withTheSpellIdOfSomeMount)
        -- This is a workaround to Bliz's API and retrieves a usable ID from my secret stash created when the user grabbed the mount.
        if pickedUpMount then
            actionType = "spell"
            thingyId = pickedUpMount.spellId
            mountId = pickedUpMount.mountId
        else
            debug.warn:print("Sorry, the Blizzard API provided bad data for this mount.")
        end
    elseif kind == "mount" then
        actionType = "spell" -- mounts can be summoned by casting as a spell
        local name, spellId, icon, _, isUsable, _, _, _, _, shouldHideOnChar, _, _ = C_MountJournal.GetMountInfoByID(info1)
        thingyId = spellId
        mountId = info1
    elseif kind == "item" then
        -- TODO: parse info2 as a tooltip and find "toy"
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

    local flyoutId = flyoutMenu.id

    if actionType then
        local flyoutConf = FlyoutMenusDb:get(flyoutId)
        local btnIndex = self:GetID()

        local oldThingyId   = flyoutConf.spells[btnIndex]
        local oldActionType = flyoutConf.actionTypes[btnIndex]
        local oldmountId    = flyoutConf.mounts[btnIndex]
        local oldPet        = flyoutConf.pets[btnIndex]

        flyoutConf.spells[btnIndex] = thingyId
        flyoutConf.actionTypes[btnIndex] = actionType
        flyoutConf.mounts[btnIndex] = mountId
        flyoutConf.spellNames[btnIndex] = getThingyNameById(actionType, thingyId or pet)
        flyoutConf.macroOwners[btnIndex] = macroOwner
        flyoutConf.pets[btnIndex] = pet

        ClearCursor() -- drop the dragged spell/item/etc
        pickedUpMount = nil
        updateAllGerms()
        flyoutMenu:updateFlyoutMenuForCatalog(flyoutId)

        -- update the cursor to show the existing spell/item/etc (if any)
        if oldActionType == "spell" then
            if oldmountId then
                pickedUpMount = {
                    mountId = oldmountId,
                    spellId = oldThingyId
                }
            end
            PickupSpell(oldThingyId)
        elseif oldActionType == "item" then
            PickupItem(oldThingyId)
        elseif oldActionType == "macro" then
            PickupMacro(oldThingyId)
        elseif oldActionType == "battlepet" then
            C_PetJournal.PickupPet(oldPet)
        end
    else
        debug.warn:print("Sorry, unsupported type:", kind)
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
    local mountId = btnOnFlyout.mountId
    local pet = btnOnFlyout.battlepet

    debug.trace:out("<",5,"OnDragStart", "actionType",actionType, "mountId",mountId)
    if actionType == "spell" then
        if mountId then
            pickedUpMount = {
                mountId = mountId,
                spellId = spell
            }
        end

        PickupSpell(spell)
    elseif actionType == "item" then
        PickupItem(spell)
    elseif actionType == "macro" then
        PickupMacro(spell)
    elseif actionType == "battlepet" then
        C_PetJournal.PickupPet(pet)
    end

    local flyoutFrame = btnOnFlyout:GetParent()
    if flyoutFrame.isForCatalog then
        local flyoutMenuDef = FlyoutMenusDb:get(flyoutFrame.id)
        flyoutMenuDef:removeSpell(btnOnFlyout:GetID())
        updateAllGerms()
        flyoutFrame:updateFlyoutMenuForCatalog(flyoutFrame.id)
    end
end
