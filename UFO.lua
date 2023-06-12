-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

--[[

TODO
* implement UFO_SV_FLYOUTS as array of self-contained button objects rather than each button spread across multiple parallel arrays
* encapsulate as FlyoutConfigData
* encapsulate as PlacementConfigData
* refactor FlyoutMenu:updateFlyoutMenuForGerm and move some logic into a germ:Method(); replace all mentions of UIUFO_FlyoutMenuForGerm with simply self
* replace existing icon picker with something closer to MacroManager / Weak Auras
* question: can I use GetItemSpell(itemId) to simplify my code ?
* BUG: when germs omit unusable buttons they exclude combat abilities based on not-enough-mana/runicpower/etc
* BUG: germs that extend horizontally (as the ones on the vertical action bars) sometimes have weirdly wide borders
* BUG: OnDragStart needs to accommodate when there is already something on the cursor
* - steps to recreate: pick up any spell, release the mouse button over thin air such that the spell stays on the cursor, then hover over a germ, hold down left-mouse, begin dragging
* make germs glow when you mouseover their flyouts in the catalog (same way spells on the actionbars glow when you point at them in the spellbook)
* optimize handlers so that everything isn't always updating ALL germs.  Only update the affected ones.
* NUKE all OO syntax that's not actual OO.  Foo:Bar() doesn't need "self" if there is never an instance foo:Bar()
* fix C_MountJournal OnPickup global var bug
* consolidate all the redundant code, such as the if actionType == "spell" then PickupSpell(spellId) --> function ButtonOnFlyoutMenu:PickMeUp()
* use ACE Lib/DataBroker
*
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

local debug = Debug:new(DEBUG_OUTPUT.WARN)

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
    DEFAULT_CHAT_FRAME:AddMessage( "|cffd78900"..ADDON_NAME.." v"..VERSION.."|r loaded." )
    initalizeAddonStuff()
end

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    debug.trace:out("",1,"PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    updateAllGerms() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not isUfoInitialized then return end
    debug.trace:out("",1,"ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not isUfoInitialized then return end
    debug.trace:print("PLAYER_SPECIALIZATION_CHANGED")
    updateAllGerms()
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

function getTexture(actionType, spellId, petId)
    local id = pickSpellIdOrPetId(actionType, spellId, petId)
    --print("getTexture(): actionType =",actionType, "| spellId =",spellId, "| petId =",petId, "| id =",id)
    if actionType == "spell" then
        return GetSpellTexture(id)
    elseif actionType == "item" then
        return GetItemIcon(id)
    elseif actionType == "macro" then
        local _, texture, _ = GetMacroInfo(id)
        return texture
    elseif actionType == "battlepet" then
        local _, icon = getPetNameAndIcon(id)
        return icon
    end
end

function pickSpellIdOrPetId(type, spellId, petId)
    return ((type == "battlepet") and petId) or spellId
end

function getThingyNameById(actionType, id)
    if actionType == "spell" then
        return GetSpellInfo(id)
    elseif actionType == "item" then
        return GetItemInfo(id)
    elseif actionType == "macro" then
        local name, _, _ = GetMacroInfo(id)
        return name
    elseif actionType == "battlepet" then
        return getPetNameAndIcon(id)
    end
end

function isThingyUsable(id, actionType, mountId, macroOwner,petId)
    if mountId or petId then
        -- TODO: figure out how to find a mount
        return true -- GetMountInfoByID(mountId)
    elseif actionType == "spell" then
        return IsSpellKnown(id)
    elseif  actionType == "item" then
        local n = GetItemCount(id)
        local t = PlayerHasToy(id) -- TODO: update the config code so it sets actionType = toy
        return t or n > 0
    elseif actionType == "macro" then
        return isMacroGlobal(id) or getIdForCurrentToon() == macroOwner
    end
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

-- useful for injecting tables into secure functions because SFs don't allow tables
function serializeAsAssignments(name, val, isRecurse)
    assert(val, "val is required")
    assert(name, "name is required")

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
    assert(class, "nil is not a Class")
    return (firstArg and type(firstArg) == "table" and firstArg.ufoType == class.ufoType)
end

function assertIsFunctionOf(firstArg, class)
    assert(not isClass(firstArg, class), "Um... it's var.foo() not var:foo()")
end

function assertIsMethodOf(firstArg, class)
    assert(isClass(firstArg, class), "Um... it's var:foo() not var.foo()")
end

-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------

function initalizeAddonStuff()
    Catalog:definePopupDialogWindow()
    Config:initializeFlyouts()
    Config:initializePlacements()
    FlyoutMenu:initializeOnClickHandlersForFlyouts()
    isUfoInitialized = true
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

createEventListener(Ufo, EventHandlers)
