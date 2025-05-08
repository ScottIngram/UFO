-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

-------------------------------------------------------------------------------
-- ButtonType
-- identifies a button as a Spell, Item, Pet, etc. as used by most(some?) APIs including GetCursorInfo.
-- and provides methods for unified, consistent behavior in the face of Bliz's inconsistent API
-- For now, this class is tightly coupled with the ButtonDef class -- most methods here require its arg to be a ButtonDef
-------------------------------------------------------------------------------
---@class ButtonType -- IntelliJ-EmmyLua annotation
ButtonType = {
    SPELL = "spell",
    MOUNT = "mount",
    ITEM  = "item",
    TOY   = "toy",
    PET   = "battlepet",
    MACRO = "macro",
    PSPELL = "petaction",
    BROKENP = "brokenPetCommand",
    SNAFU = "companion",
}

-------------------------------------------------------------------------------
-- BlizApiFieldDef
-- maps my types into Bliz types.
-------------------------------------------------------------------------------
---@class BlizApiFieldDef -- IntelliJ-EmmyLua annotation
---@field pickerUpper function the Bliz API that can load the mouse pointer
---@field typeForBliz ButtonType the corresponding SecureActionButtonTemplate keyname
---@field key string which field should be used as the ID
-- the key is a ButtonType as returned by GetCursorInfo while the user is dragging it around on the mouse.
BlizApiFieldDef = {
    [ButtonType.SPELL] = { pickerUpper = C_Spell.PickupSpell, typeForBliz = ButtonType.SPELL, },
    [ButtonType.MOUNT] = { pickerUpper = C_Spell.PickupSpell, typeForBliz = ButtonType.SPELL, },
    [ButtonType.ITEM ] = { pickerUpper = C_Item.PickupItem, typeForBliz = ButtonType.ITEM,  },
    [ButtonType.TOY  ] = { pickerUpper = C_Item.PickupItem, typeForBliz = ButtonType.TOY, key = "itemId"  },
    [ButtonType.MACRO] = { pickerUpper = PickupMacro, typeForBliz = ButtonType.MACRO --[[, key = "name"]] },
    [ButtonType.SNAFU] = { pickerUpper = nil,         typeForBliz = ButtonType.SPELL, key = "mountId" },
    [ButtonType.PET  ] = { pickerUpper = C_PetJournal.PickupPet, typeForBliz = ButtonType.PET, key = "petGuid" },
    [ButtonType.PSPELL]= { pickerUpper = PickupPetSpell, typeForBliz = ButtonType.SPELL, key="petSpellId" },
    [ButtonType.BROKENP]= { pickerUpper = function(id) print("pickerupper not defined for pet action", id)  end, typeForBliz=ButtonType.MACRO, key="name" }, -- for attack, assist, stopattack, etc.
}

-------------------------------------------------------------------------------
-- Broken Professions
-- In a shocking turn of events, Bliz broke something!  IKR?!
-- In the professions tab of the spell book, there are buttons to open its trade skill panel / cookbook.
-- The Bliz API GetCursorInfo() provides a spell ID when you drag those buttons. Sometimes this spell ID is bullshit.
-- Here is a map of IDs suitable for C_TradeSkillUI.OpenTradeSkill()
-- The keys are localized strings, so, this will only work for supported languages.
-------------------------------------------------------------------------------

BrokenProfessions = {
    [INSCRIPTION] = 773, -- Bliz provides this localized "Inscription"
    [L10N.JEWELCRAFTING] = 755, -- but not these!  Blizzard is consistent only in their inconsistency!  Blizconsistency!!!
    [L10N.BLACKSMITHING] = 164,
    [L10N.LEATHERWORKING] = 165,
    [L10N.ENGINEERING] = 202,
}

-------------------------------------------------------------------------------
-- ButtonDef
-- data for a single button, its spell/pet/macro/item/etc.  and methods for manipulating that data
-------------------------------------------------------------------------------
---@class ButtonDef : UfoMixIn
---@field type ButtonType
---@field name string
---@field spellId number
---@field itemId number
---@field mountId number
---@field petGuid string
---@field petSpellId number
---@field brokenPetCommandId number custom field to solve Blizzard's broken API
---@field macroId number
---@field macroOwner string
ButtonDef = {
    ufoType = "ButtonDef"
}
UfoMixIn:mixInto(ButtonDef)

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

function getPetNameAndIcon(petGuid)
    --local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petGuid)
    local _, _, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(petGuid)
    return name, icon
end

function isMacroGlobal(macroId)
    return macroId <= MAX_GLOBAL_MACRO_ID
end

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a ButtonDef instance
---@return ButtonDef
function ButtonDef:oneOfUs(self)
    zebug.trace:print("self",self)
    if self.ufoType == ButtonDef.ufoType then
        -- it's already "one of us" so nothing needs to be done.
        return
    end

    -- create a table to store stuff that we do NOT want persisted out to SAVED_VARIABLES
    -- and attach methods to get and put that data
    local privateData = { }
    function privateData:setIdForBlizApi(id) privateData.idForBlizApis = id end

    -- tie the privateData table to the ButtonDef class definition
    setmetatable(privateData, { __index = ButtonDef })
    -- tie the "self" instance to the privateData table (which in turn is tied to  the class)
    setmetatable(self, { __index = privateData })
end

---@return ButtonDef
function ButtonDef:new()
    ---@type ButtonDef
    local self = {}
    ButtonDef:oneOfUs(self)
    self:installMyToString()
    return self
end

local s = function(v) return v or "nil"  end

function ButtonDef:toString()
    if not self.type then
        return "<ButtonDef: EMPTY>"
    else
        return string.format("<ButtonDef: type=%s, name=%s>", s(self.type), s(self.name))
    end
end

function ButtonDef:invalidateCache()
    zebug.trace:line(75)
    self.name = nil
    self:setIdForBlizApi(nil)
end

function ButtonDef:whatsMyBlizApiIdField()
    assert(self.type, "can't discern ID key without a type.")
    local blizDef = BlizApiFieldDef[self.type]
    if not blizDef then return nil end
    local type    = blizDef.typeForBliz
    local idKey   = blizDef.key or (type .."Id") -- spellId or itemId or petGuid or etcId
    return idKey
end

function ButtonDef:redefine(id, name)
    self:invalidateCache()
    local idKey = self:whatsMyBlizApiIdField()
    self[idKey] = id
    self.name   = name
end

-- A few different types of buttons share Bliz APIs.
-- For example, you get a mount's icon by calling C_Spell.GetSpellTexture(mountId)
-- This method remaps the various ID fields to match what Bliz API expects
---@return number
function ButtonDef:getIdForBlizApi()
    if self.idForBlizApis then
        return self.idForBlizApis
    end

    local idKey = self:whatsMyBlizApiIdField()
    local happyBlizId = self[idKey]
    zebug.trace:print("self.type",self.type, "idKey",idKey, "happyBlizId",happyBlizId)
    self:setIdForBlizApi(happyBlizId) -- cache the result to save processing cycles on repeated calls
    return happyBlizId
end

function ButtonDef:getTypeForBlizApi()
    local blizApiFieldDef = BlizApiFieldDef[self.type]
    return blizApiFieldDef.typeForBliz
end

function ButtonDef:isUsable()
    local t = self.type
    local id = self:getIdForBlizApi()
    zebug.trace:print("name", self.name, "type",t, "spellId", self.spellId, "id",id)
    if t == ButtonType.MOUNT or t == ButtonType.PET then
        -- TODO: figure out how to find a mount
        return true -- GetMountInfoByID(mountId)
    elseif t == ButtonType.TOY then
        return  PlayerHasToy(id) -- and C_ToyBox.IsToyUsable(id) -- nope, unreliable and overreaching
    elseif t == ButtonType.SPELL then
        --zebug.trace:print("IsSpellKnownOrOverridesKnown",IsSpellKnownOrOverridesKnown(id))
        return IsSpellKnownOrOverridesKnown(id)
    elseif t == ButtonType.PSPELL then
        --zebug.warn:print("IsSpellKnownOrOverridesKnown PET",IsSpellKnownOrOverridesKnown(id, true))
        return IsSpellKnownOrOverridesKnown(id, true)
    elseif t == ButtonType.ITEM then
        -- isUseable = C_PlayerInfo.CanUseItem(itemID)
        local n = C_Item.GetItemCount(id)
        return n > 0
    elseif t == ButtonType.MACRO then
        zebug.info:print("macroId",self.macroId, "isMacroGlobal",isMacroGlobal(self.macroId), "owner",self.macroOwner, "me",getIdForCurrentToon())
        return isMacroGlobal(self.macroId) or getIdForCurrentToon() == self.macroOwner
    elseif t == ButtonType.BROKENP then
        return PetShitShow:canHazPet()
    end
end

function ButtonDef:getIcon()
    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.SPELL or t == ButtonType.MOUNT or t == ButtonType.PSPELL then
        if C_Spell.GetSpellTexture then --v11
            return C_Spell.GetSpellTexture(id)
        else --v10
            return GetSpellTexture(id)
        end
    elseif t == ButtonType.ITEM or t == ButtonType.TOY then
        if C_Item.GetItemIconByID then --v11
            return C_Item.GetItemIconByID(id)
        else --v10
            return GetItemIcon(id)
        end
    elseif t == ButtonType.MACRO then
        if self:isUsable() then
            local _, texture, _ = GetMacroInfo(id)
            return texture
        else
            return "Interface\\Icons\\" .. DEFAULT_ICON
        end
    elseif t == ButtonType.PET then
        local _, icon = getPetNameAndIcon(id)
        return icon
    elseif t == ButtonType.BROKENP then
        return BrokenPetCommand[self.brokenPetCommandId].icon
    end
end

function ButtonDef:getName()
    if self.name then
        return self.name
    end

    local t = self.type
    local id = self:getIdForBlizApi()
    if t == ButtonType.SPELL or t == ButtonType.MOUNT or t == ButtonType.PSPELL then
        if GetSpellInfo then --v10
            self.name = GetSpellInfo(id)
        elseif C_Spell.GetSpellInfo then --v11
            local foo = C_Spell.GetSpellInfo(id)
            self.name = foo and foo.name
        end
    elseif t == ButtonType.ITEM or t == ButtonType.TOY then
        self.name =  C_Item.GetItemInfo(id)
    elseif t == ButtonType.TOY then
        self.name =  C_Item.GetItemInfo(id)
    elseif t == ButtonType.MACRO then
        self.name =  GetMacroInfo(self.macroId)
    elseif t == ButtonType.PET then
        self.name =  getPetNameAndIcon(id)
    elseif t == ButtonType.BROKENP then
        --zebug.warn:dumpy("btndef",self)
        self.name = BrokenPetCommand[self.brokenPetCommandId].name
    else
        zebug.warn:print("Unknown type:",t)
    end

    return self.name
end

function trim1(s)
    if not s then return nil end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function ButtonDef:getToolTipSetter()
    local type = self.type
    local id = self:getIdForBlizApi()
    zebug.info:line(20, "type",type, "id",id)

    local tooltipSetter
    if type == ButtonType.SPELL or type == ButtonType.MOUNT or type == ButtonType.PSPELL then
        tooltipSetter = GameTooltip.SetSpellByID
    elseif type == ButtonType.ITEM then
        tooltipSetter = GameTooltip.SetItemByID
    elseif type == ButtonType.TOY then
        tooltipSetter = GameTooltip.SetToyByItemID
    elseif type == ButtonType.PET then
        tooltipSetter = GameTooltip.SetCompanionPet
    elseif type == ButtonType.MACRO then
        -- START FUNC
        tooltipSetter = function(zelf, Cache1macroId)
            local upToDateId = self:getIdForBlizApi()
            local macroId = self.macroId
            local i_name, _, i_body = GetMacroInfo(macroId)
            local n_name, _, n_body = GetMacroInfo(self.name)
            if not macroId then macroId = "NiL" end
            zebug.info:print("MACRO! macroId",macroId, "cached1",Cache1macroId,"cahced2",upToDateId, "btnDef name",self.name, "i_name",i_name, "n_name",n_name, "i_body", trim1(i_body), "n_body",trim1(n_body))
            zebug.trace:dumpy("self",self)
            local text
            if self:isUsable() then
                text = "Macro: ".. macroId .." " .. (i_name or "UNKNOWN")
            else
                text = "Toon Macro for " .. self.macroOwner
            end
            return zelf:SetText(text)
        end
        -- END FUNC
    elseif type == ButtonType.BROKENP then
        -- START FUNC
        tooltipSetter = function(zelf, _)
            return zelf:SetText(self.name)
        end
        -- END FUNC
    end

    if tooltipSetter and id then
        return function()
            -- because Bliz doesn't understand the concept of immutable IDs
            -- and Bliz allows macro IDs to shift will-fucking-nilly
            -- we must always refresh the ID
            local upToDateId = self:getIdForBlizApi()
            return tooltipSetter(GameTooltip, upToDateId)
        end
    end

    return nil
end

local ttData

function ButtonDef:registerToolTipRecorder()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip == GameTooltip then
            ttData = data
        end
    end)
end

function ButtonDef:readToolTipForToyType()
    ttData = nil -- will be re-populated by the registerToolTipRecorder() event handler above

    -- trigger the tooltip
    local tooltipSetter = self:getToolTipSetter()
    local foo = tooltipSetter and tooltipSetter()
    if not ttData then
        return false
    end

    -- scan the text in the tooltip
    for i, ttLine in ipairs(ttData.lines) do
        zebug.trace:print("ttLine.leftText",ttLine.leftText)
        if ttLine.leftText == L10N.TOY then
            zebug.trace:out(30,")","TOY !!!")
            return true
        end
    end

    return false
end

-- TODO: fixx bug - doesn't understand Bliz flyouts such as Dragon Riding
-- TODO: consolidate / integrate with BlizActionBarButton:get()
---@return ButtonDef
function ButtonDef:getFromCursor()
    ---@type ButtonDef
    local btnDef = ButtonDef:new()
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;
    zebug.trace:print("type",type, "c1",c1, "c2",c2, "c3",c3)

    btnDef.type = type
    if type == ButtonType.SPELL then
        btnDef.spellId = c3
    elseif type == ButtonType.SNAFU then
        -- this is an abnormal result containing a useless ID which isn't accepted by any API.  Not helpful.
        -- It's caused when the mouse pointer is loaded via Bliz's API PickupSpell(withTheSpellIdOfSomeMount)
        -- This is a workaround to Bliz's API and retrieves a usable ID from my secret stash created when the user grabbed the mount.
        if Ufo.pickedUpBtn then
            btnDef = Ufo.pickedUpBtn
        else
            zebug.warn:print("Sorry, the Blizzard API provided bad data for this mount.")
        end
    elseif type == ButtonType.MOUNT then
        local name, spellId = C_MountJournal.GetMountInfoByID(c1)
        btnDef.spellId = spellId
        btnDef.mountId = c1
    elseif type == ButtonType.ITEM then
        btnDef.itemId = c1
        local isToy = btnDef:readToolTipForToyType()
        if isToy then
            btnDef.type = ButtonType.TOY
        end
    elseif type == ButtonType.MACRO then
        btnDef.macroId = c1
        if not isMacroGlobal(c1) then
            btnDef.macroOwner = (Ufo.pickedUpBtn and Ufo.pickedUpBtn.macroOwner) or getIdForCurrentToon()
        end
    elseif type == ButtonType.PET then
        btnDef.petGuid = c1
    elseif type == ButtonType.PSPELL then
        if c1 < 10 then
            --zebug.error:print("BROKENP !!! ",GetCursorInfo() )
            btnDef.type = ButtonType.BROKENP
            local brokenPetCommandId, alsoCommand = PetShitShow:get(c1)
            btnDef.brokenPetCommandId = brokenPetCommandId
            btnDef.brokenPetCommandId2 = alsoCommand
            --zebug.error:dumpy("BROKENP btnDef",btnDef)
        else
            btnDef.petSpellId = c1
        end
    else
        Ufo.unknownType = type or "UnKnOwN"
        type = nil
        btnDef = nil
    end

    if btnDef then
        if type then
            -- discovering the name requires knowing its type
            btnDef:getName()
        end

        if Ufo.pickedUpBtn then
            -- TODO: should this be done as part of receiveDrop instead?
            btnDef.noRnd = Ufo.pickedUpBtn.noRnd
        end
    end

    Ufo.pickedUpBtn = nil

    return btnDef
end

function ButtonDef:pickupToCursor()
    local type = self.type
    local id = self:getIdForBlizApi()
    local pickup = BlizApiFieldDef[type].pickerUpper
    Ufo.pickedUpBtn = self

    zebug.trace:print("actionType", self.type, "name", self.name, "spellId", self.spellId, "itemId", self.itemId, "mountId", self.mountId, "pickup", pickup, "PickupSpell",PickupSpell)

    local isOk, err = pcall( function()  pickup(id) end  )
    if not isOk then
        zebug.error:print("pickupToCursor failed! ERROR is",err)
    end
    --pickup(id)
    zebug.trace:print("grabbed id", id)
end

---@return ButtonType buttonType what kind of action is performed by the btn
---@return string key for the SecureActionButtonTemplate:SetAttribute(key, val)
---@return string val for the SecureActionButtonTemplate:SetAttribute(key, val)
function ButtonDef:asSecureClickHandlerAttributes()
    -- Check special (as in "short bus" special) cases for special needs
    if ButtonType.PET == self.type then
        -- COMPANION PET
        -- this fails with "invalid attribute name"
        --local snippet = "C_PetJournal.SummonPetByGUID(" .. QUOTE .. self.petGuid .. QUOTE ..")"
        --return "UFO_customscript", "_UFO_customscript", snippet

        -- summon the pet via a macro
        -- TODO: fix bug where this fails in combat - perhaps control:CallMethod(keyName, ...) ?
        local petMacro = "/run C_PetJournal.SummonPetByGUID(" .. QUOTE .. self.petGuid .. QUOTE ..")"
        return ButtonType.MACRO, "macrotext", petMacro
    elseif ButtonType.SPELL == self.type then
        -- PROFESSIONS
        --local altId = BrokenProfessions[self.name]
        local professionSnafuId = ProfessionShitShow:get(self.name)
        --zebug.error:print("name",self.name, "id",self.spellId, "altId",altId, "professionSnafuId", professionSnafuId)
        if professionSnafuId then
            local profMacro = sprintf("/run C_TradeSkillUI.OpenTradeSkill(%d)", professionSnafuId)
            zebug.trace:print("name",self.name, "professionSnafuId", professionSnafuId, "profMacro",profMacro)
            return ButtonType.MACRO, "macrotext", profMacro
        end
        -- if the prof name was NOT found in the ProfessionShitShow mapping, then,
        -- it was something like "Herbalism Journal" and not "Herbalism"
        -- if so, then, the "fall-through" block below will cast it as type "spell" and that works for any "journal"
    elseif ButtonType.BROKENP == self.type then
        local brokenPetCommand = BrokenPetCommand[self.brokenPetCommandId]
        if brokenPetCommand.macro then
            local bpc = BrokenPetCommand[self.brokenPetCommandId]
            --zebug.warn:print("self.brokenPetCommandId",self.brokenPetCommandId, "bpc.macro",bpc.macro)
            --zebug.warn:dumpy("BrokenPetCommand bpc",bpc)
            return ButtonType.MACRO, "macrotext", bpc.macro
        elseif brokenPetCommand.scripty then
            local scripty = BrokenPetCommand[self.brokenPetCommandId].scripty
            local type = "SCRIPT_FOR_" .. self.brokenPetCommandId
            return type, "_"..type, scripty
        end
        local macroText = BrokenPetCommand[self.brokenPetCommandId]
        return ButtonType.MACRO, "macrotext", macroText
    elseif ButtonType.ITEM == self.type then
        -- because using items by name implies rank 1 and never rank 2 or 3 we must use by the item's ID
        return ButtonType.ITEM, ButtonType.ITEM, "item:".. self.itemId -- but not just itemId, it must be item:itemId - I hate you Bliz
    end

    local blizType = self:getTypeForBlizApi()
    zebug.info:print("catch-all block... blizType",blizType, "self.name",self.name)
    return blizType, blizType, self.name
end
