-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@class Ufo -- IntelliJ-EmmyLua annotation
---@field myTitle string Ufo.toc Title
---@field iconTexture string Ufo.toc IconTexture
---@field thatWasMeThatDidThatMacro boolean flag used to stop event handler responses to UFO actions related to macros
---@field droppedPlaceholderOntoActionBar boolean flag used to stop event handler responses to UFO actions related to drag and drop
---@field pickedUpBtn table table of data for a UFO on the mouse cursor
---@field germLock Event flag to lock out any simultaneous germ events
---@field hasShitCalmedTheFuckDown boolean all the loading sequences and initialization chaos is done and the Bliz APIs will provide reliable info (HA!)

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
ufoType = "UFO_BASE"

zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.INFO) -- will be used by everyone in the Wormhole unless they override
local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.TRACE)

time = GetTimePreciseSec -- fuck whole second bullshit

-- Purely to satisfy my IDE
DB = Ufo.DB
L10N = Ufo.L10N
Zebug = Ufo.Zebug
Event = Ufo.Event

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local isUfoInitialized = false
local eventChaosPreviousCheckMoment = time()
local eventChaosDurationTolerance = 0.5

-------------------------------------------------------------------------------
-- Util funcs
-------------------------------------------------------------------------------

function isEventChaosChilledOut()
    print (string.format("%.4f <- time :-)", time()))
    local elapsed = time() - eventChaosPreviousCheckMoment
    eventChaosPreviousCheckMoment = time()
    return elapsed > eventChaosDurationTolerance
end

function calmTheFuckDown()
    Ufo.hasShitCalmedTheFuckDown = false
    C_Timer.After(1, function() Ufo.hasShitCalmedTheFuckDown = true end)
end

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, arg2, arg3, arg4)
    local n = arg4 or arg3 -- because either warcraft.wiki.gg or Bliz is full of shit and nobody knows how many args are coming
    local eName = (arg4 and arg3) or arg2 -- because either warcraft.wiki.gg or Bliz is full of shit and nobody knows how many args are coming
    zebug.info:mSkull():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        initalizeAddonStuff(event)
        GermCommander:initializeAllSlots(event)
    end)
end

-- respond to the user dragging and dropping:
-- UFOs onto action bars;
-- spells/items/etc onto UFOs already on the action bars;
-- UFOs onto other UFOs already on the action bars.
-- We don't care any other action bar events.
function EventHandlers:ACTIONBAR_SLOT_CHANGED(btnSlotIndex, eName, n, z1, z2)
    if not Ufo.hasShitCalmedTheFuckDown then return end

    if Ufo.germLock then
        local btnInSlot = BlizActionBarButtonHelper:get(btnSlotIndex, eName)
        zebug.info:event(Ufo.germLock):name("handler"):print("LOCKED - ignoring", eName, "caused by",btnInSlot)
        return
    end

    zebug.info:mSquare():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        Ufo.germLock = event
        GermCommander:addOrRemoveSomeUfoDueToAnActionBarSlotChangedEvent(btnSlotIndex, event)
        Ufo.germLock = nil
    end, "btnSlotIndex", btnSlotIndex)
end

EventHandlers.ACTIONBAR_SLOT_CHANGED = Throttler:throttleAndNoQueue(0.125, "Ufo:ACTIONBAR_SLOT_CHANGED", EventHandlers.ACTIONBAR_SLOT_CHANGED)

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED(unit, eName, n)
    print("PLAYER_SPECIALIZATION_CHANGED",unit, eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    zebug.error:mCircle():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        zebug.error:name("handler"):print("spec was",Spec:getAcknowledgedSpec(), "spec is now", Spec:getSpecId(), "for unit", unit)
        if Spec:hasChanged() then
            Spec:getSpecId()
            GermCommander:changeSpec(event)
        else
            zebug.warn:name("handler"):print("No actual change to spec.  KTHXBAI!")
        end
    end)

    Spec:acknowledgeSpecChange()
end

--[[
function EventHandlers:EDIT_MODE_LAYOUTS_UPDATED(layoutInfo, eName, n)
    zebug.info:mCircle():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        --GermCommander:changeSpec(event)
        zebug:dumpy("layoutInfo",layoutInfo)
    end)
end
]]

-- TODO when action bars change direction update their UFOs to match.
EventRegistry:RegisterCallback("EditMode.Exit", function()
    zebug.info:mark(Mark.INFO):name("handler"):newEvent("Ufo", "EditMode.Exit"):run(function(event)
    end)
end, "UFO")


function EventHandlers:UPDATE_MACROS(eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end

    zebug.info:mCircle():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        UfoProxy:syncMyId()

        if Ufo.thatWasMeThatDidThatMacro then
            -- the event was caused by an action of this addon and as such we shall ignore it
            zebug.trace:newEvent("Ufo", eName, n):name("handler"):print("ignoring internally triggered event that was caused by", Ufo.thatWasMeThatDidThatMacro)
            Ufo.thatWasMeThatDidThatMacro = nil
            return
        else
            MacroShitShow:analyzeMacroUpdate(event)
        end
    end)
end

function EventHandlers:UNIT_INVENTORY_CHANGED(id, eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    if id ~= "player" then
        zebug.error:name("handler"):newEvent("Ufo", eName, n):print("not 'player' ! id",id, "eName",eName)
    end

    zebug.info:mDiamond():name("handler"):newEvent("Ufo", eName, n):run(function(event)
        GermCommander:notifyAllGermsWithItems(event)
    end)
end

-- an absolute shitstorm of UNIT_INVENTORY_CHANGED and BAG_UPDATE vomit during the loading screen, so throttle this motherfucker
EventHandlers.UNIT_INVENTORY_CHANGED = Throttler:throttleAndNoQueue(1.0, "Ufo:BAG_UPDATE", EventHandlers.UNIT_INVENTORY_CHANGED)

--[[
function EventHandlers:UPDATE_VEHICLE_ACTIONBAR(eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_VEHICLE_ACTIONBAR because it") then return end
    local event = Event:new("Ufo", eName, n)
    zebug.info:mSquare():name(eName):newEvent("Ufo", eName, n):run(function(event)
        GermCommander:handleEventPetChanged(event)
    end)
end
]]

function EventHandlers:UPDATE_BINDINGS(eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    zebug.trace:newEvent("Ufo", eName, n):print("bound!")
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_BINDINGS because it") then return end
    --GermCommander:updateAll()
end

function EventHandlers:PLAYER_LOGIN(eName, n)
    zebug.trace:mMoon():newEvent("Ufo", eName, n):print("Welcome!")
end

function EventHandlers:CURSOR_CHANGED(isCursorEmpty, me, eventCounter)
    eventCounter = eventCounter or "NO-EVENT-COUNTER"

    zebug.trace
        :name("handler")
        :newEvent("Ufo", Cursor:nameMakerForCursorChanged(isCursorEmpty), eventCounter, Zebug.trace)
        :run(function(event)
            GermCommander:forEachActiveGerm(Germ.maybeRegisterForClicksDependingOnCursorIsEmpty, event)
            Cursor:clearCache(event)
            UfoProxy:delayedAsyncDeleteProxyIfNotOnCursor(event)
            --Placeholder:doNotLetUserDragMe(event) -- this is more trouble than it's worth.
        end)
end

function EventHandlers:SPELL_UPDATE_COOLDOWN(spellID, --[[baseSpellID, ]]eName, n)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    zebug.info:mark(Mark.DPS):name("SPELL_UPDATE_COOLDOWN"):newEvent("Ufo", eName, n):run(function(event)
        local spellInfo = spellID and C_Spell.GetSpellInfo(spellID)
        local name = spellInfo and spellInfo.name or "UnKnOwN"
        zebug.info:name("SPELL_UPDATE_COOLDOWN"):event(event):print("spellID",spellID, "spell name", name --[[, "baseSpellID",baseSpellID, "eName",eName, "n",n]])
        GermCommander:forEachActiveGerm(Germ.render, event)
    end)
end

EventHandlers.SPELL_UPDATE_COOLDOWN = Throttler:throttleAndNoQueue(0.1, "Ufo:SPELL_UPDATE_COOLDOWN", EventHandlers.SPELL_UPDATE_COOLDOWN)

function EventHandlers:SPELL_UPDATE_USABLE(eName, n)
    EventHandlers:SPELL_UPDATE_COOLDOWN(nil, eName, n)
end

EventHandlers.SPELL_UPDATE_CHARGES = EventHandlers.SPELL_UPDATE_USABLE

-------------------------------------------------------------------------------
-- Event related methods - TODO: use these?
-------------------------------------------------------------------------------

-- set a semaphore so other code can decide to respond to the resulting UPDATE_MACROS event
-- TODO: if set during a Zebug:runEvent() AND the provided event arg is the same one being used by runEvent() then it will auto-erase it at the end of runEvent() ... todo: move to Zebug?
function Ufo:setEventSemaphore(semaphoreName, event)
    self.semaphores = self.semaphores or {}
    self.semaphores[semaphoreName] = event
end

function Ufo:isThereAnEventSemaphore(semaphoreName)
    if not self.semaphores then return end
    return self.semaphores[semaphoreName]
end

function Ufo:setEventSemaphore(semaphoreName, event)
    if not self.semaphores then return end
    self.semaphores[semaphoreName] = event
end

-------------------------------------------------------------------------------
-- Handlers for ADDON_LOADED of Other Addons
-------------------------------------------------------------------------------

local HandlersForAddonLoadedEvents = {}

function HandlersForAddonLoadedEvents:Blizzard_PlayerSpells(name)
    --v11 Bliz moved the spell book into its own internal, load-on-demand addon
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_PlayerSpells")
    Catalog:createToggleButton(PlayerSpellsFrame)
end

function HandlersForAddonLoadedEvents:Blizzard_Collections(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_Collections")
    Catalog:createToggleButton(CollectionsJournal)
end

function HandlersForAddonLoadedEvents:Blizzard_MacroUI(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_MacroUI")
    Catalog:createToggleButton(MacroFrame)
    MacroShitShow:init()
end

function HandlersForAddonLoadedEvents:Blizzard_ProfessionsBook(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_ProfessionsBook")
    Catalog:createToggleButton(ProfessionsBookFrame)
end

function HandlersForAddonLoadedEvents:LargerMacroIconSelection(name)
    zebug.trace:name("listener"):print("Heard addon load: LargerMacroIconSelection")
    supportLargerMacroIconSelection()
end

function HandlersForAddonLoadedEvents:UFO(name)
    zebug.trace:name("listener"):print("Heard addon load", name)
end

-------------------------------------------------------------------------------
-- Config for Slash Commands aka "/ufo"
-------------------------------------------------------------------------------

local slashFuncs = {
    [L10N.SLASH_CMD_CONFIG] = {
        desc = L10N.SLASH_DESC_CONFIG,
        fnc = function() Settings.OpenToCategory(Ufo.myTitle)  end,
    },
    [L10N.SLASH_CMD_OPEN] = {
        desc = L10N.SLASH_DESC_OPEN,
        fnc = Catalog.open,
    },
}

-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------

-- called by PLAYER_ENTERING_WORLD
function initalizeAddonStuff(event)
    if isUfoInitialized then return end

    Ufo.myTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title")
    Ufo.iconTexture = C_AddOns.GetAddOnMetadata(ADDON_NAME, "IconTexture")

    DB:initializeFlyouts()
    DB:initializePlacements()
    DB:initializeOptsMemory()
    Config:initializeOptionsMenu()

    MacroShitShow:init()
    print("initalizeAddonStuff", event)
    Spec:recordCurrentSpec() -- so we know what it was before any changes
    UfoProxy:deleteProxyMacro("Ufo:initalizeAddonStuff()")
    ThirdPartyAddonSupport:detectSupportedAddons()
    registerSlashCmd("ufo", slashFuncs)
    Catalog:definePopupDialogWindow()
    ButtonDef:registerToolTipRecorder()

    -- check to see if the usually on-demand Bliz windows have already been loaded (by some other addon)
    Catalog:createToggleButtonIfWeCan(SpellBookFrame) -- support WoW v10
    Catalog:createToggleButtonIfWeCan(PlayerSpellsFrame)
    Catalog:createToggleButtonIfWeCan(CollectionsJournal)
    Catalog:createToggleButtonIfWeCan(MacroFrame)
    Catalog:createToggleButtonIfWeCan(ProfessionsBookFrame)

    IconPicker:init()

    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    local msg = L10N.LOADED .. " v"..version
    msgUser(msg, IS_OPTIONAL)

    -- flags to wait out the chaos happening when the UI first loads / reloads.
    isUfoInitialized = true
    calmTheFuckDown()
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

BlizGlobalEventsListener:register(Ufo, EventHandlers, HandlersForAddonLoadedEvents)
