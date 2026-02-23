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

MouseRat:mixInto(MrBrokenPetAction)

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
    if false and self.brokenPetCommandId2 then
        return PetShitShow.BrokenPetCommand[self.brokenPetCommandId].name .. " or maybe " .. PetShitShow.BrokenPetCommand[self.brokenPetCommandId2].name
    else
        return PetShitShow.BrokenPetCommand[self.brokenPetCommandId].name
    end
end

---@return number texture ID
function MrBrokenPetAction:getIcon()
    return PetShitShow.BrokenPetCommand[self.brokenPetCommandId].icon
end

function MrBrokenPetAction:setToolTip()
    _G.GameTooltip:SetText(self:getName())
end

-- will the real spellId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param spellId number the 2nd arg from GetCursorInfo - Spell ID of the pet action on the cursor, or unknown 0-4 number if the spell is a shared pet control spell (Follow, Stay, Assist, Defensive, etc...)..
---@param spellIndex number the 3rd arg from GetCursorInfo - The index of the spell in the pet spell book, or nil if the spell is a shared pet control spell (Follow, Stay, Assist, Defensive, etc...).
---@param retVal3 any - unknown
function MrBrokenPetAction:consumeGetCursorInfo(type, spellId, spellIndex, retVal3)
    self:setId(spellId)

    -- holy fucking hell.  I had forgotten how abjectly terrible Bliz's pet API is until
    -- I looked at my old code that I wrote to mush it into some semblance of sanity.
    -- JFC.  To anyone who reads my comments and is taken aback by my unrestrained contempt for Bliz's WoW APIs,
    -- I invite you to read PetShitShow.lua to understand one of the worst examples of their fuckery.
    --print("=-=-=-=-=- _G.GetCursorInfo() -->", _G.GetCursorInfo())
    local id, anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues = PetShitShow:remapCursorIdIntoSomeUsefulIdOrTwo(spellId)
    self.brokenPetCommandId = id
    self:setPvar("brokenPetCommandId2", anotherIdThatAlsoMappedToTheSameSpellIdYesOneKeyForMultipleValues)
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrBrokenPetAction)
