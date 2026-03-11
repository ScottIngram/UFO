---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrBrokenPetAction : MouseRat
---@field myTwinActionIdAction MrBrokenPetAction some of these fuckers are eXtRa broken and one "ID" actually represents TWO different behaviors.  FU Bliz.
local MrBrokenPetAction = {
    type       = MouseRatType.BROKEN_PET_ACTION,
    cursorType = MouseRatType.PETACTION,
    abbType    = MouseRatTypeForActionBarButton.SPELL,
    primaryKey = "brokenPetCommandId",
    helpers = {
        --getName = xxx, -- replaced by getName() defined below
        --getIcon = xxx, -- replaced by getIcon() defined below
        --pickupToCursor = xxx,
        canThisToonPickup = false, -- Bliz provides no API to do so.  FU.
        --setToolTip = xxx, -- replaced by setToolTip() defined below
        --isUsable = C_SpellBook.HasPetSpells,  -- TODO: bugfix the lag between dismounting and the pet abilities being reported as existing
    },
}

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrBrokenPetAction
-------------------------------------------------------------------------------

-- examines the results of _G.GetCursorInfo() and decides if those results describe a BROKEN_PET_ACTION
---@param type MouseRatType must be MouseRatType.SPELL
---@param maybeSpellId any could be a spellId
---@param maybeSpellIndex any could be a spellIndex
function MrBrokenPetAction:disambiguator(type, maybeSpellId, maybeSpellIndex)
    if type ~= self.cursorType then return false end

    zebug.warn:print("type", type, "maybeSpellId",maybeSpellId, "maybeSpellIndex",maybeSpellIndex)
    return (maybeSpellId and (maybeSpellId < 10))
end

-- examines the results of _G.GetActionInfo() and
-- decides if those results describe a MouseRatTypeForActionBarButton.BROKEN_PET_ACTION
---@param abbType MouseRatTypeForActionBarButton must match the configured abbType
---@param id any 2nd return val from _G.GetActionInfo()
---@param subType 3rd return val from _G.GetActionInfo()
function MrBrokenPetAction:disamButtonGator(abbType, id, subType)
    if abbType ~= self.abbType then return false end

    zebug.warn:print("abbType", abbType, "id", id, "subType", subType)
    return (id and (id < 10))
end

-------------------------------------------------------------------------------
-- Instance Methods for MouseRat Contract
-------------------------------------------------------------------------------

---@return string "Assist" or "Attack" or etc
function MrBrokenPetAction:getName()
    self.name = self:getMyPetCommandDefinition("name")
    return self.name
end

---@return number texture ID
function MrBrokenPetAction:getIcon()
    --zebug.error:dumpy("MrBrokenPetAction", self)
    --zebug.error:print("self.brokenPetCommandId", self.brokenPetCommandId, "self:getId",self:getId())

    return self:getMyPetCommandDefinition("icon")
end

function MrBrokenPetAction:setToolTip()
    _G.GameTooltip:SetText(_G.PET .. ": " .. self:getName())
end

-- will the real spellId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param spellId number the 2nd arg from GetCursorInfo - Spell ID of the pet action on the cursor, or unknown 0-4 number if the spell is a shared pet control spell (Follow, Stay, Assist, Defensive, etc...)..
---@param spellIndex number the 3rd arg from GetCursorInfo - The index of the spell in the pet spell book, or nil if the spell is a shared pet control spell (Follow, Stay, Assist, Defensive, etc...).
function MrBrokenPetAction:consumeGetCursorInfo(type, spellId, spellIndex)
    -- holy fucking hell.  I had forgotten how abjectly terrible Bliz's pet API is until
    -- I looked at my old code that I wrote to mush it into some semblance of sanity.
    -- JFC.  To anyone who reads my comments and is taken aback by my unrestrained contempt for Bliz's WoW APIs,
    -- I invite you to read PetShitShow.lua to understand one of the worst examples of their fuckery.
    local id, anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues = PetShitShow:remapCursorIdIntoSomeUsefulIdOrTwo(spellId)
    self:setId(id)
    self.name = self:getMyPetCommandDefinition("name")
    zebug.warn:owner(self):event():print("myTwinActionId",anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues)
    self:setPvar("myTwinActionId", anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues)
end

function MrBrokenPetAction:isUsable()
    -- because pets are sometimes not yet summoned when combat is already underway (eg while mounted)
    -- a positive result may come too late for the UI to react before combat lockdown happens, thus,
    -- cache any positive result to ensure it's available even when the pet is momentarily AWOL
    if not self.wasEverUsable then
        self:setPvar("wasEverUsable", C_SpellBook.HasPetSpells())
    end
    return self.wasEverUsable
end

-- expresses the MrBrokenPetAction in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute (according to Bliz's fucking insane rules) related to the above "type" attribute
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrBrokenPetAction:asSecureClickHandlerAttributes()
    local cfg = self:getMyPetCommandDefinition()
    if cfg.scripty then
        local type = "SCRIPT_FOR_" .. self.brokenPetCommandId
        return type, "_"..type, cfg.scripty
    end
    local macro = self:getMyPetCommandDefinition("macro")
    return ButtonType.MACRO, "macrotext", macro
end

-- some MrBrokenPetAction are eXtRa broken and one "ID" actually represents TWO different behaviors.  FU Bliz.
---@return MrBrokenPetAction|nil
function MrBrokenPetAction:getTwin()
    if self.myTwinActionId then
        ---@type MrBrokenPetAction
        local twin = {}
        setmetatable(twin, { __index = self })
        twin:setId(self.myTwinActionId)
        twin.name = twin:getMyPetCommandDefinition("name")
        twin.type = self.type -- even though type is already in self, it would be hidden from SavedVariables. rectify.
        return twin
    end
    return nil
end

------------------------------------------------------------------------------------------
-- Instance Methods - utils
------------------------------------------------------------------------------------------

function MrBrokenPetAction:getMyPetCommandDefinition(key)
    local cfg = BrokenPetCommand[self:getId()]
    if not cfg then
        error("bad id:" .. nilStr(self:getId()))
    end
    return (key and (cfg[key] or "bad key:"..nilStr(key))) or cfg
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrBrokenPetAction)
