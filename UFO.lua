-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@class Ufo -- IntelliJ-EmmyLua annotation
---@field myTitle string Ufo.toc Title
---@field thatWasMe boolean flag used to stop event handler responses to UFO actions related to macros
---@field droppedUfoOntoActionBar boolean flag used to stop event handler responses to UFO actions related to drag and drop
---@field pickedUpBtn table table of data for a UFO on the mouse cursor

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
zebug = Zebug:new()

-- Purely to satisfy my IDE
DB = Ufo.DB
L10N = Ufo.L10N

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local isUfoInitialized = false
local hasShitCalmedTheFuckDown = false

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    zebug.trace:print("Heard event: PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    initalizeAddonStuff() -- moved this here from PLAYER_LOGIN() because the Bliz API was just generally shitting the bed
    if isInCombatLockdown("Ignoring event PLAYER_ENTERING_WORLD because it") then return end
    GermCommander:updateAll() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
    if isInitialLogin then
        local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
        local msg = L10N.LOADED .. " v"..version
        msgUser(msg, IS_OPTIONAL)
    end
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    if isInCombatLockdownQuiet("Ignoring event ACTIONBAR_SLOT_CHANGED because it") then return end

    GermCommander:handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: PLAYER_SPECIALIZATION_CHANGED")
    if isInCombatLockdownQuiet("Ignoring event PLAYER_SPECIALIZATION_CHANGED because it") then return end
    GermCommander:updateAll()
end

function EventHandlers:UPDATE_MACROS()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:line(40,"Heard event: UPDATE_MACROS")
    if isInCombatLockdownQuiet("Ignoring event UPDATE_MACROS because it") then return end
    MacroShitShow:analyzeMacroUpdate()
end

function EventHandlers:UNIT_INVENTORY_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: UNIT_INVENTORY_CHANGED")
    if isInCombatLockdownQuiet("Ignoring event UNIT_INVENTORY_CHANGED because it") then return end

    GermCommander:handleEventChangedInventory()
end

function EventHandlers:UPDATE_VEHICLE_ACTIONBAR()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: UPDATE_VEHICLE_ACTIONBAR")
    if isInCombatLockdownQuiet("Ignoring event UPDATE_VEHICLE_ACTIONBAR because it") then return end
    GermCommander:handleEventPetChanged()
end

function EventHandlers:UPDATE_BINDINGS()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: UPDATE_BINDINGS")
    if isInCombatLockdownQuiet("Ignoring event UPDATE_BINDINGS because it") then return end
    --GermCommander:updateAll()
end

function EventHandlers:CURSOR_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    --zebug.trace:line(40,"Heard event: CURSOR_CHANGED",C_TradeSkillUI.GetProfessionForCursorItem())
    local type, spellId = GetCursorInfo()
    zebug.trace:print("type",type, "spellId",spellId)
    GermCommander:delayedAsynchronousConditionalDeleteProxy()
end

function EventHandlers:PLAYER_LOGIN()
    zebug.trace:print("Heard event: PLAYER_LOGIN")
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

    DB:initializeFlyouts()
    DB:initializePlacements()
    DB:initializeOptsMemory()
    Config:initializeOptionsMenu()

    MacroShitShow:init()
    GermCommander:delayedAsynchronousConditionalDeleteProxy()
    ThirdPartyAddonSupport:detectSupportedAddons()
    registerSlashCmd("ufo", slashFuncs)
    Catalog:definePopupDialogWindow()
    ButtonDef:registerToolTipRecorder()

    -- check to see if the usually on-demand Bliz windows have already been loaded (by some other addon)
    Catalog:createToggleButtonIfWeCan(SpellBookFrame) -- support WoW v10
    Catalog:createToggleButtonIfWeCan(PlayerSpellsFrame)
    Catalog:createToggleButtonIfWeCan(CollectionsJournal)
    Catalog:createToggleButtonIfWeCan(MacroFrame)

    IconPicker:init()

    -- flags to wait out the chaos happening when the UI first loads / reloads.
    isUfoInitialized = true
    C_Timer.After(1, function() hasShitCalmedTheFuckDown = true end)
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

BlizGlobalEventsListener:register(Ufo, EventHandlers, HandlersForOtherAddons)
