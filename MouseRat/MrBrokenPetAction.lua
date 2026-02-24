---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrBrokenPetAction : MouseRat
local MrBrokenPetAction = {
    type       = MouseRatType.BROKEN_PET_ACTION,
    cursorType = MouseRatType.PETACTION,
    primaryKey = "brokenPetCommandId",
    --getName_helper = xxx, -- replaced by getName() defined below
    --getIcon_helper = xxx, -- replaced by getIcon() defined below
    --pickupToCursor_helper = xxx, -- replaced by pickupToCursor() defined below
    --setToolTip_helper = xxx, -- replaced by setToolTip() defined below
    isUsable_helper = C_SpellBook.HasPetSpells,
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

    zebug.warn:print("type", type, "maybeSpellId",maybeSpellId, "maybeSpellIndex",maybeSpellIndex, "c4",c4)
    if not type == self.cursorType then return false end
    return (maybeSpellId and (maybeSpellId < 10)) or maybeSpellIndex == nil -- not 100% about checking maybeSpellIndex
end

------------------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrBrokenPetAction
------------------------------------------------------------------------------------------

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
    _G.GameTooltip:SetText(self:getName())
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
    self:setPvar(self.primaryKey.."2", anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues)
end

-- expresses the MrBrokenPetAction in a way that can be executed in WoW's "secure environment" hellscape / action bar button.
---@return string hardcoded value that will be assigned to the SecureActionButton's "type" attribute
---@return string the name of some key recognized by SecureActionButton as an attribute (according to Bliz's fucking insane rules) related to the above "type" attribute
---@return string the actual fucking value assigned to whatever goddamn key was decided above
function MrBrokenPetAction:asSecureClickHandlerAttributes()
    local macro = self:getMyPetCommandDefinition("macro")
    return ButtonType.MACRO, "macrotext", macro
end

function MrBrokenPetAction:getMyPetCommandDefinition(key)
    local cfg = BrokenPetCommand[self:getId()]
    if not cfg then
        error("bad id:" .. nilStr(self:getId()))
    end
    return cfg[key] or "bad key:"..nilStr(key)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrBrokenPetAction)
