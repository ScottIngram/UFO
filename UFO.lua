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
---@field manifestedPlaceholder boolean flag used to stop event handler responses to UFO actions related to drag and drop
---@field pickedUpBtn table table of data for a UFO on the mouse cursor
---@field hasShitCalmedTheFuckDown boolean all the loading sequences and initialization chaos is done and the Bliz APIs will provide reliable info (HA!)

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
zebug = Zebug:new()
local zebug = Zebug:new(Zebug.TRACE)

-- Purely to satisfy my IDE
DB = Ufo.DB
L10N = Ufo.L10N

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local isUfoInitialized = false
local width = 30

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi, me, eventCounter)
    local eventCounter = eventCounter or isReloadingUi -- because either warcraft.wiki.gg or Bliz is full of shit
    local eventId = makeEventId(me, eventCounter)
    zebug.error:name(eventId):out(width, "=","START! isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi, "!START!")
    initalizeAddonStuff()
    --if isInCombatLockdown("Ignoring event PLAYER_ENTERING_WORLD because it") then return end
    GermCommander:updateAllSlots(eventId)
    zebug.error:name(eventId):out(width, "=","END!")
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.error:name(eventId):out(width, ">","!START --------------- !START! actionBarSlotId", actionBarSlotId)
    GermCommander:handleActionBarSlotChangedEvent(actionBarSlotId, eventId)
    zebug.error:name(eventId):out(width, ">","!END --------------- END!")
end

--[[
function EventHandlers:CURSOR_CHANGED(isDefault, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    local eventId = makeEventId(me, eventCounter)
    local cursor = Cursor:get()
    zebug.info:name(eventId):out(width, "c","START! ", cursor, "!START!")
    Ufo.cursorSnapshot = ButtonDef:getFromCursor()
    zebug.info:name(eventId):print("cursorSnapshot", Ufo.cursorSnapshot)
    zebug.info:name(eventId):out(width, "c","END!")
end
]]

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED(id, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event PLAYER_SPECIALIZATION_CHANGED because it") then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.trace:name(eventId):out(width, "S","!START --------------- !START!")
    GermCommander:updateAllSlots(eventId)   -- change to handleChangeSpec() aka updateAllGermsANDallSlots()
    zebug.trace:name(eventId):out(width, "S","!END --------------- END!")
end

function EventHandlers:UPDATE_MACROS(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_MACROS because it") then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.trace:name(eventId):out(width, "M","!START --------------- !START!", "Ufo.thatWasMeThatDidThatMacro",Ufo.thatWasMeThatDidThatMacro)
    MacroShitShow:analyzeMacroUpdate(eventId)
    zebug.trace:name(eventId):out(width, "M","!END --------------- END!")
end

function EventHandlers:BAG_UPDATE(id, me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UNIT_INVENTORY_CHANGED because it") then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.trace:name(eventId):out(width, "I","START! Bags be different now? !START!")
    GermCommander:handleEventChangedInventory(eventId)
    zebug.trace:name(eventId):out(width, "I","END!")
end

function EventHandlers:UPDATE_VEHICLE_ACTIONBAR(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_VEHICLE_ACTIONBAR because it") then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.trace:name(eventId):out(width, "X","START! vehicle wut? !START!")
    GermCommander:handleEventPetChanged(eventId)
    zebug.trace:name(eventId):out(width, "X","END!")
end

function EventHandlers:UPDATE_BINDINGS(me, eventCounter)
    if not Ufo.hasShitCalmedTheFuckDown then return end
    local eventId = makeEventId(me, eventCounter)
    zebug.trace:name(eventId):print("bound!")
    --if isInCombatLockdownQuiet("Ignoring event UPDATE_BINDINGS because it") then return end
    --GermCommander:updateAll()
end

function EventHandlers:PLAYER_LOGIN()
    zebug.error:name("PLAYER_LOGIN"):print("Welcome!")
end

function makeEventId(name, n)
    return tostring(name or "UnKnOwN eVeNt") .. "_" .. tostring(n or "UnKnOwN N")
end

-------------------------------------------------------------------------------
-- Handlers for Other Addons
-------------------------------------------------------------------------------

local HandlersForOtherAddons = {}

function HandlersForOtherAddons:Blizzard_PlayerSpells()
    --v11 Bliz moved the spell book into its own internal, load-on-demand addon
    zebug.trace:print("Heard addon load: Blizzard_PlayerSpells", PlayerSpellsFrame)
    Catalog:createToggleButton(PlayerSpellsFrame)
end

function HandlersForOtherAddons:Blizzard_Collections()
    zebug.trace:print("Heard addon load: Blizzard_Collections")
    Catalog:createToggleButton(CollectionsJournal)
end

function HandlersForOtherAddons:Blizzard_MacroUI()
    zebug.trace:print("Heard addon load: Blizzard_MacroUI")
    Catalog:createToggleButton(MacroFrame)
    MacroShitShow:init()
end

function HandlersForOtherAddons:Blizzard_ProfessionsBook()
    zebug.trace:print("Heard addon load: Blizzard_ProfessionsBook")
    Catalog:createToggleButton(ProfessionsBookFrame)
end

function HandlersForOtherAddons:LargerMacroIconSelection()
    zebug.trace:print("Heard addon load: LargerMacroIconSelection")
    supportLargerMacroIconSelection()
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
function initalizeAddonStuff()
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
    C_Timer.After(1, function() Ufo.hasShitCalmedTheFuckDown = true end)
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

BlizGlobalEventsListener:register(Ufo, EventHandlers, HandlersForOtherAddons)
