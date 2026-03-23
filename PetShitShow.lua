-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

-------------------------------------------------------------------------------
-- BrokenPetCommand
-------------------------------------------------------------------------------
---@class BrokenPetCommand
---@field name string
---@field notSpellId number the non-unique "identifier" provided by Bliz's broken API
---@field icon number
---@field macro string text that will be interpreted as a macro
---@field scripty string text that will be used as a "restricted snippet"
BrokenPetCommand = {
    ASSIST     = { notSpellId=3, icon=524348, macro="/petassist",    name="Assist", }, -- Sets pet to assist mode.
    ATTACK     = { notSpellId=2, icon=132152, macro="/petattack",    name="Attack", }, -- Sends pet to attack currently selected target.
    FOLLOW     = { notSpellId=1, icon=132328, macro="/petfollow",    name="Follow", }, -- Set pet to follow you... is effectively PetStopAttack()
    -- the /petdefensive macro has been broken since at least 2020 https://us.forums.blizzard.com/en/wow/t/petdefensive-macro/437857
    -- also, PetDefensiveMode() is not available inside the restricted environment hellscape.
    -- so, Bliz provides no way for us to implement DEFENSIVE.  FU yet another time, Bliz.
    DEFENSIVE  = { notSpellId=4, icon=132110, X_scripty="PetDefensiveMode()", macroX="/petdefensive", name="Defensive", macro="/s the /petdefensive macro has been broken since circa 2020." },
    MOVETO     = { notSpellId=4, icon=457329, macro="/petmoveto",    name="Move To", }, -- Set pet to move to and stay at a hover-targeted location.
    PASSIVE    = { notSpellId=0, icon=132311, macro="/petpassive",   name="Passive", }, -- Set pet to passive mode.
    STAY       = { notSpellId=0, icon=136106, macro="/petstay",      name="Stay", }, -- Set pet to stay where it is at.
    -- TODO: also map STOPATTACK to notSpellId=2 (same as ATTACK)
    STOPATTACK = { notSpellId=9, icon=236372, macro="/run PetStopAttack()", scripty="PetStopAttack()", }, -- stop attack
    --Dismiss        = { name="Dismiss",         icon="12345678", macro="petdismiss", }, -- Dismiss your pet.
    --Autocastoff    = { name="Autocast Off",    icon="12345678", macro="petautocastoff", }, -- Turn off autocast for a pet spell.
    --Autocaston     = { name="Autocast On",     icon="12345678", macro="petautocaston", }, -- Turn on autocast for a pet spell.
    --Autocasttoggle = { name="Autocast Toggle", icon="12345678", macro="petautocasttoggle", }, -- Toggle autocast for a pet spell.
}

-------------------------------------------------------------------------------
-- PetShitShow - how to fix the Broken Pet Commands
-------------------------------------------------------------------------------
---@class PetShitShow -- IntelliJ-EmmyLua annotation
PetShitShow = {
    BrokenPetCommand = BrokenPetCommand
}

---@type table key=notSpellIdProvidedByBlizAPI -> array or corresponding BrokenPetCommands
local indexOfBrokenPetCommands

function PetShitShow:getIndex()
    -- because Blizzard can't seem to grasp the concept of unique IDs, build an index that compensates for dupe IDs
    if not indexOfBrokenPetCommands then
        indexOfBrokenPetCommands = {}
        for brokenPetCommandId, howToFix in pairs(BrokenPetCommand) do
            local notSpellId = howToFix.notSpellId
            if not indexOfBrokenPetCommands[notSpellId] then
                indexOfBrokenPetCommands[notSpellId] = {}
            end
            local a = indexOfBrokenPetCommands[notSpellId]
            a[#a+1] = brokenPetCommandId
        end
        --zebug.warn:dumpy("indexOfBrokenPetCommands",indexOfBrokenPetCommands)
    end
    return indexOfBrokenPetCommands
end

function PetShitShow:forEach(notSpellId, func)
    local commands = self:getIndex()[notSpellId]
    assert(commands, "Unknown notSpellId " .. (notSpellId or "NIL") )

    for i, brokenPetCommand in ipairs(commands) do
        func(i,brokenPetCommand)
    end
end

-- fuck you Bliz.  All the fucks are for you.  Please try to enjoy each fuck equally.
---@param notSpellId number the second return val from GetCursorInfo() which is NOT actually a spellId.  It is a NON-unique "id" that refers to one or MORE different BrokenPetCommands
---@return BrokenPetCommand one of potentially many that the Bliz dumbass devs mapped to the given "id"
---@return BrokenPetCommand|nil possibly another command that the Bliz dumbass devs mapped to the given "id" (flames on the side of my face)
function PetShitShow:remapCursorIdiotSpellIdToBrokenPetCommandId(notSpellId)
    local mapFromNotSpellIdToCommandName = self:getIndex()
    local commandNameOneAndMaybeTwo = mapFromNotSpellIdToCommandName[notSpellId]
    if not commandNameOneAndMaybeTwo then
        error("Unknown notSpellId: " .. (notSpellId or "NIL") )
    end
    return unpack(commandNameOneAndMaybeTwo)
end

function PetShitShow:canHazPet()
    if DB:canHazPet() then -- I do not remember why I persisted this to DB
        return true
    end

    if HasPetSpells then
        return DB:canHazPet( HasPetSpells() ) --v10
    else
        return DB:canHazPet( C_SpellBook.HasPetSpells() ) --v11
    end
end
