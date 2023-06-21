-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

--[[

TODO
* put a ufo -> catalog button on the collections and macro panels too
* replace existing icon picker with something closer to MacroManager / Weak Auras
* make germs glow when you mouseover their flyouts in the catalog (same way spells on the actionbars glow when you point at them in the spellbook)
* optimize handlers so that everything isn't always updating ALL germs.  Only update the affected ones.
* use ACE Lib/DataBroker so Titan Panel and other addons can open the UFO catalog
* question: can I use GetItemSpell(itemId) to simplify my code ?
* BUG: Oops, I clobbered the frames on the germ flyouts
* BUG: when germs omit unusable buttons they exclude combat abilities based on not-enough-mana/runicpower/etc
*
* DONE: BUG: OnDragStart needs to accommodate when there is already something on the cursor
* DONE: - steps to recreate: pick up any spell, release the mouse button over thin air such that the spell stays on the cursor, then hover over a germ, hold down left-mouse, begin dragging
* DONE: BUG: macros sometimes(?) have the wrong image / tooltip
* DONE: centralize the numerous "if ButtonType == FOO then BAR" blocks into some common solution
* DONE: BUG: when germs omit unusable buttons, they still appear and now it and each subsequent btn behaves as though it were the one after
* DONE: refactor FlyoutMenu:updateFlyoutMenuForGerm and move some logic into a germ:Method(); replace all mentions of UIUFO_FlyoutMenuForGerm with simply self
* DONE: implement UFO_SV_FLYOUTS as array of self-contained button objects rather than each button spread across multiple parallel arrays
* DONE: encapsulate as FlyoutConfigData
* DONE: encapsulate as PlacementConfigData
* DONE: BUG: germs that extend horizontally (as the ones on the vertical action bars) sometimes have weirdly wide borders
* DONE: fix C_MountJournal OnPickup global var bug
* DONE: consolidate all the redundant code, such as the if actionType == "spell" then PickupSpell(spellId) --> function ButtonOnFlyoutMenu:PickMeUp()
* DONE: BLIZ BUG: fixed flyouts on side bars pointing in the wrong direction because the Bliz API reported the wrong direction
* DONE: BUG: bliz bug: C_MountJournal index is in flux (e.g. a search filter will change the indices)
* DONE: BLIZ BUG: picking up a mount by its spell ID results in a cursor whose GetCursorInfo() returns "companion" n "MOUNT" where n is... a meaningless number?
* DONE: BUG: flyouts don't indicate if an item is usable / not usable
* DONE: BUG: stacks, charges, etc for things that don't have stacks etc.
* DONE: BUG: cooldown display only works for spells, not inventory items (hearthstone, trinkets, potions, etc)
* DONE: NUKE all function paramsNamed(self) and rename them with actual NAMES
* DONE: identify which Ufo:Foo() methods actually need to be global
* DONE: eliminate as many Ufo:Foo() -> foo()
* DONE: eliminate all "legacy data" fixes
* DONE: eliminate any support for classic
]]

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
local L10N = Ufo.L10N

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local isUfoInitialized = false

-------------------------------------------------------------------------------
-- Event Handlers
-------------------------------------------------------------------------------

local EventHandlers = { }

function EventHandlers:ADDON_LOADED(addonName)
    if addonName == ADDON_NAME then
        debug.trace:print("ADDON_LOADED", addonName)
    end
end

function EventHandlers:PLAYER_LOGIN()
    debug.trace:print("PLAYER_LOGIN")
    debug.warn:print("v",VERSION,"loaded")
end

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    debug.trace:out("",1,"PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    initalizeAddonStuff() -- moved this here from PLAYER_LOGIN() because the Bliz API was just generally shitting the bed
    GermCommander:updateAll() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not isUfoInitialized then return end
    debug.trace:out("",1,"ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    GermCommander:handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not isUfoInitialized then return end
    debug.trace:print("PLAYER_SPECIALIZATION_CHANGED")
    GermCommander:updateAll()
end

-------------------------------------------------------------------------------
-- Event Handler Registration
-------------------------------------------------------------------------------

function createEventListener(targetSelfAsProxy, eventHandlers)
    debug.trace:print(ADDON_NAME .. " EventListener:Activate() ...")

    local dispatcher = function(listenerFrame, eventName, ...)
        -- ignore the listenerFrame and instead
        eventHandlers[eventName](targetSelfAsProxy, ...)
    end

    local eventListenerFrame = CreateFrame("Frame")
    eventListenerFrame:SetScript("OnEvent", dispatcher)

    for eventName, _ in pairs(eventHandlers) do
        debug.trace:print("EventListener:activate() - registering " .. eventName)
        eventListenerFrame:RegisterEvent(eventName)
    end
end

-------------------------------------------------------------------------------
-- Random stuff - TODO: tidy up
-------------------------------------------------------------------------------

function isInCombatLockdown(actionDescription)
    if InCombatLockdown() then
        local msg = actionDescription or "That action"
        debug.warn:print(msg .. " is not allowed during combat.")
        return true
    else
        return false
    end
end

function getIdForCurrentToon()
    local name, realm = UnitFullName("player") -- FU Bliz, realm is arbitrarily nil sometimes but not always
    realm = GetRealmName()
    return name.." - "..realm
end

function getPetNameAndIcon(petGuid)
    --print("getPetNameAndIcon(): petGuid =",petGuid)
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petGuid)
    --print("getPetNameAndIcon(): petGuid =",petGuid, "| name =", name, "| icon =", icon)
    return name, icon
end

function isMacroGlobal(macroId)
    return macroId <= MAX_GLOBAL_MACRO_ID
end

-- I had to create this function to replace lua's strjoin() because
-- lua poops the bed in the strsplit(strjoin(array)) roundtrip whenever the "array" is actually a table because an element was set to nil
function fknJoin(array)
    array = array or {}
    local n = lastIndex(array)
    --print ("OOOOO fknJoin() n =",n, "| array -->")
    --DevTools_Dump(array)
    local omfgDumbAssLanguage = {}
    for i=1,n,1 do
        --print("$$$$$ fknJoin() i =",i, "| array[",i,"] =",array[i])
        omfgDumbAssLanguage[i] = array[i] or EMPTY_ELEMENT
    end
    local result = strjoin(DELIMITER,unpack(omfgDumbAssLanguage,1,n)) or ""
    --print("$$$$= fknJoin() #omfgDumbAssLanguage =",#omfgDumbAssLanguage, "result =",result)
    return result
end

-- because lua arrays turn into tables when an element = nil
function lastIndex(table)
    local biggest = 0
    for k,v in pairs(table) do
        if (k > biggest) then
            biggest = k
        end
    end
    return biggest
end

-- ensures then special characters introduced by fknJoin()
function fknSplit(str)
    local omfgDumbassLanguage = { strsplit(DELIMITER, str or "") }
    omfgDumbassLanguage = stripEmptyElements(omfgDumbassLanguage)
    return omfgDumbassLanguage
end

function stripEmptyElements(table)
    for k,v in ipairs(table) do
        if (v == EMPTY_ELEMENT) then
            table[k] = nil
        end
    end
    return table
end

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

function deepcopy(src, target)
    local orig_type = type(src)
    local copy
    if orig_type == 'table' then
        copy = target or {}
        for orig_key, orig_value in next, src, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        --setmetatable(copy, deepcopy(getmetatable(src)))
    else -- number, string, boolean, etc
        copy = src
    end
    return copy
end

function isEmpty(s)
    return s == nil or s == ''
end

function exists(s)
    return not isEmpty(s)
end

-- convert data structures into JSON-like strings
-- useful for injecting tables into secure functions because SFs don't allow tables
function serialize(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serialize(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" or type(val) == "boolean" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

local QUOTE = "\""
local EOL = "\n"

-- convert data structures into lines of Lua variable assignments
-- useful for injecting tables into secure functions because SFs don't allow tables
-- TODO: can I use this instead of the "asLists" solution?  Or would it produce gigantic strings?
function serializeAsAssignments(name, val, isRecurse)
    assert(val, ADDON_NAME..": val is required")
    assert(name, ADDON_NAME..": name is required")

    local tmp
    if isRecurse then
        tmp = ""
    else
        tmp = "local "
    end
    tmp = tmp .. name .. " = "

    local typ = type(val)
    if "table" == typ then
        tmp = tmp .. "{}" .. EOL
        -- trust that if there is an index #1 then all other indices are also numbers.  Otherwise, this will fail.
        local iterFunc = val[1] and ipairs or pairs
        for k, v in iterFunc(val) do
            if type(k) ~= "number" then
                k = string.format("%q", k)
            end
            local nextName = name .. "["..k.."]"
            tmp = tmp .. serializeAsAssignments(nextName, v, true)
        end
    elseif "number" == typ or "boolean" == typ then
        tmp = tmp .. tostring(val) .. EOL
    elseif "string" == typ then
        tmp = tmp .. string.format("%q", val) .. EOL
    else
        tmp = tmp .. QUOTE .. "INVALID" .. QUOTE .. EOL
    end

    return tmp
end

function isClass(firstArg, class)
    assert(class, ADDON_NAME..": nil is not a Class")
    return (firstArg and type(firstArg) == "table" and firstArg.ufoType == class.ufoType)
end

function assertIsFunctionOf(firstArg, class)
    assert(not isClass(firstArg, class), ADDON_NAME..": Um... it's var.foo() not var:foo()")
end

function assertIsMethodOf(firstArg, class)
    assert(isClass(firstArg, class), ADDON_NAME..": Um... it's var:foo() not var.foo()")
end

-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------

function initalizeAddonStuff()
    if isUfoInitialized then return end

    Catalog:definePopupDialogWindow()
    Config:initializeFlyouts()
    Config:initializePlacements()
    FlyoutMenu:initializeOnClickHandlersForFlyouts()
    ButtonDef:registerToolTipRecorder()
    isUfoInitialized = true

    --FlyoutMenusDb:convertOldToNew()
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

createEventListener(Ufo, EventHandlers)
