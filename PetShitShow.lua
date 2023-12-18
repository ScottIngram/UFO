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
---@field fubarId number the non-unique "identifier" provided by Bliz's broken API
---@field icon number
---@field macro string text that will be interpreted as a macro
---@field scripty string text that will be used as a "restricted snippet"
BrokenPetCommand = {
    ASSIST     = { fubarId=3, icon=524348, macro="/petassist",    name="Assist", }, -- Sets pet to assist mode.
    ATTACK     = { fubarId=2, icon=132152, macro="/petattack",    name="Attack", }, -- Sends pet to attack currently selected target.
    FOLLOW     = { fubarId=1, icon=132328, macro="/petfollow",    name="Follow", }, -- Set pet to follow you... is effectively PetStopAttack()
    DEFENSIVE  = { fubarId=4, icon=132110, macro="/petdefensive", name="Defensive", }, -- Set pet to defensive.
    MOVETO     = { fubarId=4, icon=457329, macro="/petmoveto",    name="Move To", }, -- Set pet to move to and stay at a hover-targeted location.
    PASSIVE    = { fubarId=0, icon=132311, macro="/petpassive",   name="Passive", }, -- Set pet to passive mode.
    STAY       = { fubarId=0, icon=136106, macro="/petstay",      name="Stay", }, -- Set pet to stay where it is at.
    -- TODO: also map STOPATTACK to fubarId=2 (same as ATTACK)
    STOPATTACK = { fubarId=9, icon=236372, macro="/run PetStopAttack()", scripty="PetStopAttack()", }, -- stop attack
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
}

---@type table key=fubarIdProvidedByBlizAPI -> array or corresponding BrokenPetCommands
local indexOfBrokenPetCommands

function PetShitShow:getIndex()
    -- because Blizzard can't seem to grasp the concept of unique IDs, build an index that compensates for dupe IDs
    if not indexOfBrokenPetCommands then
        indexOfBrokenPetCommands = {}
        for brokenPetCommandId, howToFix in pairs(BrokenPetCommand) do
            local fubarId = howToFix.fubarId
            if not indexOfBrokenPetCommands[fubarId] then
                indexOfBrokenPetCommands[fubarId] = {}
            end
            local a = indexOfBrokenPetCommands[fubarId]
            a[#a+1] = brokenPetCommandId
        end
        --zebug.warn:dumpy("indexOfBrokenPetCommands",indexOfBrokenPetCommands)
    end
    return indexOfBrokenPetCommands
end

function PetShitShow:forEach(fubarId, func)
    local commands = self:getIndex()[fubarId]
    assert(commands, "Unknown fubarId " .. (fubarId or "NIL") )

    for i, brokenPetCommand in ipairs(commands) do
        func(i,brokenPetCommand)
    end
end

function PetShitShow:get(fubarId)
    local commands = self:getIndex()[fubarId]
    assert(commands, "Unknown fubarId " .. (fubarId or "NIL") )
    return unpack(commands)
end

function PetShitShow:canHazPet()
    if DB:canHazPet() then
        return true
    end
    return DB:canHazPet(HasPetSpells())
end
