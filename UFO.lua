-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

--[[

TODO
* FEATURE: support ElvUI
* BUG: dropping a flyout from the cursor onto nothing fails to delete its proxy.  FIX: use CURSOR_CHANGED event
* BUG: fix the funky macro picker blank spaces
* BUG: fix empty (unusable) flyouts showing remnants from previously opened flyout
* BUG: if a toon edits a flyout containing buttons they can't use, the buttons go bye-bye.
* FEATURE: support various action bar addons
* FEATURE: export/import - look at MacroManager for the [link] code.
* FEATURE: replace existing icon picker with something closer to MacroManager / Weak Auras
* BUG: canUse filter doesn't respect faction restricted pets / mounts
* make germs glow when you mouseover their flyouts in the catalog (same way spells on the actionbars glow when you point at them in the spellbook)
* optimize handlers so that everything isn't always updating ALL germs.  Only update the affected ones.
* use ACE Lib/DataBroker so Titan Panel and other addons can open the UFO catalog
* question: can I use GetItemSpell(itemId) to simplify my code ?
* BUG: edit-mode -> change direction doesn't automatically update existing germs
* BUG: when germs omit unusable buttons they exclude combat abilities based on not-enough-mana/runicpower/etc
*
* DONE: FEATURE: support Bartender4
* DONE: FEATURE: reorder flyouts in the catalog
* DONE: BUG: when a macro is added or deleted (from the Bliz macro editor) then all of the macro IDs shift by 1 FUBARing the macro IDs in UFO
* DONE: BUG: the empty btn sparkles on every OnUpdate
* DONE: BUG: Oops, I clobbered the frames on the germ flyouts
* DONE: change onupdate to always happen on initial open
* DONE: optimize xedni - don't throw away the whole thing - for flyoutId = deleted index to howMany { flyout[flyoutId]-- }
* DONE: BUG: deleting a flyout sometimes loses the guid
* DONE: bug: if one toon deletes a flyout causing the IDs of the subsequent ones to change by 1, then the other toons' configs are FUBAR
* DONE: put a ufo -> catalog button on the collections and macro panels too
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

local zebug = Zebug:new()

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
        zebug.trace:print("Heard event: ADDON_LOADED", addonName)
    end

    -- Add the [UFO] button to the Pet/Mount/Etc window and the Macro window.
    -- But, we can't do that until those windows exist.
    -- They are created by Bliz's built-in addons.
    -- Inexplicably, Bliz doesn't necessarily load its own addons before it starts calling user addons.
    -- So, we have to write anti-GOTCHA! code to compensate for yet another example of Bliz's bad decisions.
    -- Why bad?  Otherwise, we could have simply created the [UFO] buttons in the XML

    if addonName == "Blizzard_Collections" then
        Catalog:createToggleButton(CollectionsJournal)
    end

    if addonName == "Blizzard_MacroUI" then
        Catalog:createToggleButton(MacroFrame)
    end
end

function EventHandlers:PLAYER_LOGIN()
    zebug.trace:print("Heard event: PLAYER_LOGIN")
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    local msg = ADDON_NAME .. " v"..version .. " loaded"
    local colorMsg = GetClassColorObj("ROGUE"):WrapTextInColorCode(msg)
    print(colorMsg)
end

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    zebug.trace:print("Heard event: PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    initalizeAddonStuff() -- moved this here from PLAYER_LOGIN() because the Bliz API was just generally shitting the bed
    GermCommander:updateAll() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not isUfoInitialized then return end
    zebug.trace:print("Heard event: ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    GermCommander:handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not isUfoInitialized then return end
    zebug.trace:print("Heard event: PLAYER_SPECIALIZATION_CHANGED")
    GermCommander:updateAll()
end

function EventHandlers:UPDATE_MACROS()
    if not isUfoInitialized then return end
    zebug.trace:line(40,"Heard event: UPDATE_MACROS")
    MacroShitShow:analyzeMacroUpdate()
end

function EventHandlers:CURSOR_CHANGED()
    if not isUfoInitialized then return end
    zebug.trace:line(40,"Heard event: CURSOR_CHANGED")
    -- this event happens before ACTIONBAR_SLOT_CHANGED which needs the proxy -- TODO: find a workaround
    --Catalog:clearProxyOnCursosChange()
end

-------------------------------------------------------------------------------
-- Event Handler Registration
-------------------------------------------------------------------------------

function createEventListener(targetSelfAsProxy, eventHandlers)
    local dispatcher = function(listenerFrame, eventName, ...)
        -- ignore the listenerFrame and instead
        eventHandlers[eventName](targetSelfAsProxy, ...)
    end

    local eventListenerFrame = CreateFrame("Frame")
    eventListenerFrame:SetScript("OnEvent", dispatcher)

    for eventName, _ in pairs(eventHandlers) do
        zebug.trace:print("registering ",eventName)
        eventListenerFrame:RegisterEvent(eventName)
    end
end

-------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------

function isInCombatLockdown(actionDescription)
    if InCombatLockdown() then
        local msg = actionDescription or "That action"
        zebug.warn:print(msg .. " is not allowed during combat.")
        return true
    else
        return false
    end
end

function getIdForCurrentToon()
    local name, realm = UnitFullName("player") -- FU Bliz, realm is arbitrarily nil sometimes but not always
    realm = GetRealmName()
    return name.."-"..realm
end

function getPetNameAndIcon(petGuid)
    --local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(petGuid)
    local _, _, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(petGuid)
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
    local omfgDumbAssLanguage = {}
    for i=1,n,1 do
        omfgDumbAssLanguage[i] = array[i] or EMPTY_ELEMENT
    end
    local result = strjoin(DELIMITER,unpack(omfgDumbAssLanguage,1,n)) or ""
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

function deleteFromArray(array, killTester)
    local j = 1
    local modified = false

    for i=1,#array do
        if (killTester(array[i])) then
            array[i] = nil
            modified = true
        else
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                array[j] = array[i]
                array[i] = nil
            end
            j = j + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return modified
end

function moveElementInArray(array, oldPos, newPos)
    if oldPos == newPos then return false end

    zebug.info:line(80)
    -- iterate through the array in whichever direction will encounter the oldPos first and newPos last
    -- ahhh, I feel like I'm writing C code again... flashback to 1994... I'm old :-/
    local forward = oldPos < newPos
    local start = forward and 1 or #array
    local last  = forward and #array or 1
    local inc   = forward and 1 or -1

    local nomad = array[oldPos]
    zebug.info:print("moving",nomad, "from", oldPos, "to",newPos)
    zebug.info:dumpy("ORIGINAL array", array)

    local inMoverMode
    for i=start,last,inc do
        if i == oldPos then
            inMoverMode = true
        elseif i == newPos then
            array[i] = nomad
            zebug.info:dumpy("shifted array", array)
            return true
        end

        if inMoverMode then
            array[i] = array[i + inc]
        end
    end

    return true
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
-- 3rd-Party Addon Support
-------------------------------------------------------------------------------

local SUPPORTED_ADDONS = {
    BARTENDER4 = {
        getParent = function(btnSlotIndex)
            local name = "BT4Button" .. btnSlotIndex
            local parent = _G["BT4Button" .. btnSlotIndex]
            parent.GetName = function() return name end
            parent.btnSlotIndex = btnSlotIndex
            return parent
        end,
        getDirection = function(parent)
            return parent.config.flyoutDirection
        end,
    },
}

function findSupportedAddons()
    for addon, methods in pairs(SUPPORTED_ADDONS) do
        if IsAddOnLoaded(addon) then
            Ufo.thirdPartyAddon = methods
            break
        end
    end
end

-- if I go nuts and really abstract this to the max
--[[
local BLIZ_METHODS = {
    getParent = function(btnSlotIndex)
        local barNum = ActionButtonUtil.GetPageForSlot(btnSlotIndex)
        local actionBarDef = BLIZ_BAR_METADATA[barNum]
        local btnNum = (btnSlotIndex % NUM_ACTIONBAR_BUTTONS)  -- defined in bliz internals ActionButtonUtil.lua
        if (btnNum == 0) then btnNum = NUM_ACTIONBAR_BUTTONS end -- button #12 divided by 12 is 1 remainder 0.  Thus, treat a 0 as a 12
        local actionBarName    = actionBarDef.name
        local actionBarBtnName = actionBarName .. "Button" .. btnNum

        -- set conditional visibility based on which bar we're on.  Some bars are only visible for certain class stances, etc.
        self.visibleIf = actionBarDef.visibleIf
        local stateCondition = "nopetbattle,nooverridebar,novehicleui,nopossessbar," .. self.visibleIf
        RegisterStateDriver(self, "visibility", "["..stateCondition.."] show; hide")

        return _G[actionBarBtnName] -- grab the button object from Blizzard's GLOBAL dumping ground
    end,
    getDirection = function(parent)
        return parent.config.flyoutDirection
    end,
}
]]


-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------

function initalizeAddonStuff()
    if isUfoInitialized then return end

    findSupportedAddons()

    Catalog:definePopupDialogWindow()
    Config:initializeFlyouts()
    Config:initializePlacements()
    FlyoutMenu:initializeOnClickHandlersForFlyouts()
    ButtonDef:registerToolTipRecorder()
    Catalog:createToggleButton(SpellBookFrame)

    isUfoInitialized = true
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

createEventListener(Ufo, EventHandlers)
