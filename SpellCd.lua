-- SpellCd
-- Because Bliz APIs are a whiny bitch and won't let me trigger cooldown displays using the normal sEcReT riddled way during combat,
-- I must manually track spell casts, their start times, and calculate their remaining cooldown my own damn self.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO)

---@class SpellCd -- IntelliJ-EmmyLua annotation
---@field fullDuration table<number, number>  cooldown duration indexed by spell ID
---@field startTime table <number, number> moment a spell was most recently cast
SpellCd = {
    fullDuration = {},
    startTime = {},
    trackedIds = {},
}

local fullDuration, startTime, trackedIds = SpellCd.fullDuration, SpellCd.startTime, SpellCd.trackedIds

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

function SpellCd:register(spellId)
    trackedIds[spellId] = true
end

function SpellCd:isRegistered(spellId)
    return trackedIds[spellId]
end

---@param btnDef ButtonDef
function SpellCd:registerBtnDefIfSpell(btnDef)
    if btnDef:isSpell() then
        zebug.info:owner(btnDef):event():print("spellId",btnDef.spellId)
        SpellCd:register(btnDef.spellId)
    end
end

function SpellCd:getFullDuration(spellId)
    if not fullDuration[spellId] then
        -- look up the spell's standard duration and cache it
        local cooldownDurationMilliseconds = GetSpellBaseCooldown(spellId) or 0
        fullDuration[spellId] = cooldownDurationMilliseconds/1000
    end

    return fullDuration[spellId]
end

function SpellCd:getStart(spellId)
    return startTime[spellId]
end

function SpellCd:setStart(spellId, time)
    startTime[spellId] = time
end

---@return number|nil, number, number - when the spell was most recently cast / cooldownFullDuration / remainder left on the cooldown
function SpellCd:calculateStatus(spellId, event, owner)
    local now = time()
    local cdState = C_Spell.GetSpellCooldown(spellId)
    local isEnabled, isActive = cdState.isEnabled, cdState.isActive
    local passage = math.floor(now - (startTime[spellId] or now))
    local cooldownFullDuration = self:getFullDuration((spellId))
    local remainder

    if isEnabled and isActive then
        local justCast = (startTime[spellId] == nil) -- this is an assumption and depends on the timeliness of events
        local expired = passage > cooldownFullDuration
        if justCast or expired then
            startTime[spellId] = now
            passage = 0
            remainder = cooldownFullDuration
        else
            remainder = cooldownFullDuration - passage
        end
    else
        startTime[spellId] = nil
        remainder = 0
    end
    zebug.info:owner(owner or spellId):event(event):print("spellId",spellId, "isEnabled", isEnabled, "isActive",isActive, "duration", cooldownFullDuration, "passage", passage, "remainder",remainder)

    return startTime[spellId], cooldownFullDuration, remainder
end

SpellCd.getStatus = SpellCd.calculateStatus

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

function SpellCd:startListeningForEvents()
    local EventHandlers = {}

    function EventHandlers:SPELL_UPDATE_COOLDOWN(eName, n, spellId, baseSpellId, category, startRecoveryCategory)
        if not Ufo.hasShitCalmedTheFuckDown then return end
        if not spellId then return end
        if self:isRegistered(spellId) then
            self:calculateStatus(spellId, eName, self)
            if baseSpellId then
                self:calculateStatus(baseSpellId, eName, self)
            end

        end
    end

    -- EventHandlers.SPELL_UPDATE_USABLE = EventHandlers.SPELL_UPDATE_COOLDOWN
    -- EventHandlers.SPELL_UPDATE_CHARGES = EventHandlers.SPELL_UPDATE_COOLDOWN

    BlizGlobalEventsListener:register(SpellCd, EventHandlers)
end
