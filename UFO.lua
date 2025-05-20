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
zebug = Zebug:new()
local zebug = Zebug:new(Zebug.TRACE)

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
    local eventCounter = arg4 or arg3 -- because either warcraft.wiki.gg or Bliz is full of shit and nobody knows how many args are coming
    local me = (arg4 and arg3) or arg2 -- because either warcraft.wiki.gg or Bliz is full of shit and nobody knows how many args are coming
    local event = Event:new("Ufo", me, eventCounter)
    zebug.info:mSkull():name(me):runEvent(event, function()
        initalizeAddonStuff(event)
        --if isInCombatLockdown("Ignoring event PLAYER_ENTERING_WORLD because it") then return end
        GermCommander:updateAllSlots(event)
    end)
end

local qq = 0
function ACTIONBAR_SLOT_CHANGED(self, btnSlotIndex, me, eventCounter, z1, z2)
    print("btnSlotIndex:",btnSlotIndex, "ufoType", isTable(btnSlotIndex) and btnSlotIndex.ufoType, "me:",me, "eventCounter:",eventCounter, "z1:", z1, "z2:",z2)
--zebug.error:dumpy("self???",self)
    qq=1
    print(qq,"...");qq=qq+1
    if not Ufo.hasShitCalmedTheFuckDown then return end
    print(qq,"...");qq=qq+1

    local event = Event:new("Ufo", me, eventCounter)
    print(qq,"...");qq=qq+1
    if Ufo.germLock then
        print(qq,"... A");qq=qq+1
        local btnInSlot = BlizActionBarButton:new(btnSlotIndex, event)
        print(qq,"... A");qq=qq+1
        zebug.info:event(Ufo.germLock):name(me):print("LOCKED - ignoring", event, "caused by",btnInSlot)
        print(qq,"... A");qq=qq+1
        return
    end
    print(qq,"... B");qq=qq+1

    zebug.info:mSkull():name(me):runEvent(event, function()
        print(qq,"... C");qq=qq+1
        Ufo.germLock = event
        print(qq,"... C");qq=qq+1
        GermCommander:handleActionBarSlotChangedEvent(btnSlotIndex, event)
        print(qq,"... C");qq=qq+1
        Ufo.germLock = nil
    end, "btnSlotIndex", btnSlotIndex)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED(id, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event PLAYER_SPECIALIZATION_CHANGED because it") then return end
    local event = Event:new("Ufo", me, eventCounter)
    zebug.info:mCircle():name(me):runEvent(event, function()
        GermCommander:updateAllSlots(event)   -- change to handleChangeSpec() aka updateAllGermsANDallSlots()
    end)
end

function EventHandlers:UPDATE_MACROS(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_MACROS because it") then return end

    local event = Event:new("Ufo", me, eventCounter)
    if Ufo.thatWasMeThatDidThatMacro then
        -- the event was caused by an action of this addon and as such we shall ignore it
        zebug.trace:event(event):print("ignoring internally triggered event", Ufo.thatWasMeThatDidThatMacro)
        Ufo.thatWasMeThatDidThatMacro = nil
        return
    end

    zebug.info:mCircle():name(me):runEvent(event, function()
        MacroShitShow:analyzeMacroUpdate(event)
    end)
end

function BAG_UPDATE(id, me, eventCounter)
    print("...BAG_UPDATE...")
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if not isEventChaosChilledOut() then return end
    --if isInCombatLockdownQuiet("Ignoring event UNIT_INVENTORY_CHANGED because it") then return end
    local event = Event:new("Ufo", me, eventCounter)
    zebug.info:mDiamond():name(me):runEvent(event, function()
        GermCommander:handleEventChangedInventory(event)
    end)
end

--[[
function EventHandlers:UPDATE_VEHICLE_ACTIONBAR(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_VEHICLE_ACTIONBAR because it") then return end
    local event = Event:new("Ufo", me, eventCounter)
    zebug.info:mSquare():name(me):runEvent(event, function()
        GermCommander:handleEventPetChanged(event)
    end)
end
]]

function EventHandlers:UPDATE_BINDINGS(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    local event = Event:new("Ufo", me, eventCounter)
    zebug.trace:event(event):print("bound!")
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_BINDINGS because it") then return end
    --GermCommander:updateAll()
end

function EventHandlers:PLAYER_LOGIN(me, eventCounter)
    local event = Event:new("Ufo", me, eventCounter)
    zebug.trace:mMoon():event(event):print("Welcome!")
end

function makeEventId(name, n)
    return tostring(name or "UnKnOwN eVeNt") .. "_" .. tostring(n or "UnKnOwN N")
end

-------------------------------------------------------------------------------
-- Handlers for Other Addons
-------------------------------------------------------------------------------

local HandlersForOtherAddons = {}

function HandlersForOtherAddons:Blizzard_PlayerSpells(name)
    --v11 Bliz moved the spell book into its own internal, load-on-demand addon
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_PlayerSpells")
    Catalog:createToggleButton(PlayerSpellsFrame)
end

function HandlersForOtherAddons:Blizzard_Collections(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_Collections")
    Catalog:createToggleButton(CollectionsJournal)
end

function HandlersForOtherAddons:Blizzard_MacroUI(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_MacroUI")
    Catalog:createToggleButton(MacroFrame)
    MacroShitShow:init()
end

function HandlersForOtherAddons:Blizzard_ProfessionsBook(name)
    zebug.trace:name("listener"):print("Heard addon load: Blizzard_ProfessionsBook")
    Catalog:createToggleButton(ProfessionsBookFrame)
end

function HandlersForOtherAddons:LargerMacroIconSelection(name)
    zebug.trace:name("listener"):print("Heard addon load: LargerMacroIconSelection")
    supportLargerMacroIconSelection()
end

function HandlersForOtherAddons:UFO(name)
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

EventHandlers.ACTIONBAR_SLOT_CHANGED = Throttler:throttle(0.1, "Ufo:ACTIONBAR_SLOT_CHANGED", ACTIONBAR_SLOT_CHANGED)
--EventHandlers.BAG_UPDATE = Throttler:throttle(0.1, "Ufo:BAG_UPDATE", BAG_UPDATE)
--EventHandlers.ACTIONBAR_SLOT_CHANGED = Throttler:throttle(0.1, "Ufo:ACTIONBAR_SLOT_CHANGED", function() print("=-=-=-=-=- ACTIONBAR_SLOT_CHANGED ??? =-=-=-=-=-")  end)

BlizGlobalEventsListener:register(Ufo, EventHandlers, HandlersForOtherAddons)
