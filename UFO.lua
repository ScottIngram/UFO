-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

--[[

TODO
* BUG: when a macro is added or deleted (from the Bliz macro editor) then all of the macro IDs shift by 1 FUBARing the macro IDs in UFO
* BUG: the empty btn sparkles on every OnUpdate
* FEATURE: export/import - look at MacroManager for the [link] code.
* FEATURE: replace existing icon picker with something closer to MacroManager / Weak Auras
* make germs glow when you mouseover their flyouts in the catalog (same way spells on the actionbars glow when you point at them in the spellbook)
* optimize handlers so that everything isn't always updating ALL germs.  Only update the affected ones.
* use ACE Lib/DataBroker so Titan Panel and other addons can open the UFO catalog
* question: can I use GetItemSpell(itemId) to simplify my code ?
* BUG: when germs omit unusable buttons they exclude combat abilities based on not-enough-mana/runicpower/etc
*
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
        zebug.trace:print("ADDON_LOADED", addonName)
    end

    if addonName == "Blizzard_Collections" then
        Catalog:createToggleButton(CollectionsJournal)
    end

    if addonName == "Blizzard_MacroUI" then
        Catalog:createToggleButton(MacroFrame)
    end
end

function EventHandlers:PLAYER_LOGIN()
    zebug.trace:print("PLAYER_LOGIN")
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    local msg = ADDON_NAME .. " v"..version .. " loaded"
    local colorMsg = GetClassColorObj("ROGUE"):WrapTextInColorCode(msg)
    print(colorMsg)
end

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    zebug.trace:print("PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    initalizeAddonStuff() -- moved this here from PLAYER_LOGIN() because the Bliz API was just generally shitting the bed
    GermCommander:updateAll() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not isUfoInitialized then return end
    zebug.trace:print("ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    GermCommander:handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not isUfoInitialized then return end
    zebug.trace:print("PLAYER_SPECIALIZATION_CHANGED")
    GermCommander:updateAll()
end


function EventHandlers:UPDATE_MACROS()
    if not isUfoInitialized then return end
    zebug.trace:print("UPDATE_MACROS")
    analyzeMacroUpdate()
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
-- Random stuff - TODO: tidy up
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

function deleteFromArray(array, killTester)
    local j = 1
    local modified = false

    for i=1,#array do
        if (killTester(array, i, j)) then
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
-- Macro Monitor and Reactor
-------------------------------------------------------------------------------

local nMacros
local macrosIndex
local macrosMap

-- if the user changes the macros:
---- renames a macro which could change the alphabetical ordering of all macros and thus their IDs.
------ no, a good programmer would never allow the ID to change like that but yes, the Bliz code is really dumb.
---- Adds or removes one which again could change how many and thus shift their IDs up or down.  Again, stupid.
-- So, thanks to a macro's ID being very fluid and utterly unreliable, I get to compensate for this terrible design.  Thanks yet again, Bliz!

function analyzeMacroUpdate()
    -- The Bliz API helpfully informs me that something, anything, who knows what,
    -- but yes macro related might have just happened.  Figure out WTF it was.

    if Ufo.thatWasMe then
        -- the event was caused by an action of this addon and as such we shall ignore it
        zebug.trace:print("ignoring proxy draggable creation/death")
        Ufo.thatWasMe = false
        return
    end

    local nGlobal, nPerChar = GetNumMacros()
    local n = nGlobal + nPerChar

    -- initialze and exit
    if not nMacros then
        zebug.trace:print("initialze and exit")
        nMacros = n
        macrosMap = {}
        macrosIndex = forEveryMacro(function(i, name, index, map)
            index[i] = name
            macrosMap[name] = i
        end)
        return
    end

    if n == nMacros then
        -- did any macro names change?
        local renamedMacro = findChangedMacroName()
        if renamedMacro then
            -- update it wherever it exists in any flyout
            zebug.trace:dumpy("renamedMacro",renamedMacro)
            renameMacro(renamedMacro)
        else
            zebug.trace:print("no macro changes")
        end
    else
        if n > nMacros then
            -- a macro was added.
            -- we don't know which one, its id, or its name.  Thanks Bliz!
            -- all we know is that every other macro ID may have been shifted up.  Becoz dumbfucks.
            -- potentially remap every macro id in every flyout
            zebug.trace:print("a macro was ADDED", nMacros, "---",n)
            remapEveryMacroIdInEveryBtnInEveryFlyout()
        elseif n < nMacros then
            -- a macro was deleted
            -- we don't know which one, its id, or its name.  Thanks Bliz!
            -- all we know is that every other macro ID may have been shifted up.  Becoz dumbfucks.
            -- potentially remap every macro id in every flyout
            -- remove it wherever it existed in any flyouts
            zebug.trace:print("a macro was DELETED", nMacros, "---",n)
            deleteMacroAndThenRemapEveryMacroIdInEveryBtnInEveryFlyout()
        end

        nMacros = n
    end
end

function forEveryMacro(callback)
    local index = {}
    local map = {}
    local funcResult

    function doIndex(start,stop)
        for i = start, stop do
            local name, _, _ = GetMacroInfo(i)
            local result = callback(i, name, index, map)
            if result then return result end
        end
        return nil
    end

    -- macros are grouped as
    -- account-wide 1 to 120
    -- toon-specific >120
    local nGlobal, nPerChar = GetNumMacros()

    -- scan macros for account
    funcResult = doIndex(1, nGlobal)
    zebug.error:print(funcResult)
    if funcResult then return funcResult end

    -- scan macros for toon
    funcResult = doIndex(1 + MAX_GLOBAL_MACRO_ID, nPerChar + MAX_GLOBAL_MACRO_ID)
    zebug.error:print(funcResult)
    if funcResult then return funcResult end

    zebug.error:print("index is",index)
    return index
end

-- after we've determined that the number of macros has not changed
-- we can safely assume they are all in the same positions as before and that their IDs are also the same as before.
-- So, let's see if a macro was given a new name.
function findChangedMacroName()
    -- define a callback to do the detail work inside indexMacros()
    function findChange(i, currentName)
        local oldName = macrosIndex[i]
        if oldName ~= currentName then
            return {
                id = i,
                name = currentName,
                oldName = oldName,
                found = true,
            }
        end
    end

    local renamedMacro = forEveryMacro(findChange)
    if renamedMacro and renamedMacro.found == true then
        return renamedMacro
    end
    return nil
end

function forEveryFlyoutBtn(callback)
    ---@param flyoutDef FlyoutDef
    FlyoutDefsDb:forEachFlyoutDef(
        function(flyoutDef)
            zebug.info:line(20, "flyout ID",flyoutDef.id)
            flyoutDef:forEachBtn(callback)
        end
    )
end

---@param renamedMacro table
function renameMacro(renamedMacro)
    local m = renamedMacro
    zebug.info:line(25, "id",m.id, "name",m.name, "was", m.oldName)

    function rename(btnDef, _, i)
        if btnDef.macroId then
            zebug.info:line(15, "i",i, "btn macroId",btnDef.macroId, "btn name",btnDef.name)
        end
        if btnDef.macroId == m.id then
            zebug.warn:line(10,"FOUND UFO entry for macro #",m.id, "changing name from ",m.oldName, "to", m.name)
            btnDef.name = m.name
            macrosIndex[m.id] = m.name
        end
    end

    forEveryFlyoutBtn(rename)
end

function remapEveryMacroIdInEveryBtnInEveryFlyout()
    -- when a macro is ADDED then the UFO flyouts don't care
    -- they don't have any data for it and thus don't need updated.
    -- But, the macro index


end

function deleteMacroAndThenRemapEveryMacroIdInEveryBtnInEveryFlyout()
    zebug.info:line(25)
    local deletedMacro
    local shiftItsMacroId
    local mapCopy

    -- fix the macro index.
    -- identify which macro was deleted.
    function recreateIndexAndIdentifyTheMissingMacro(i, currentName, index, map)
        -- try to figure out which macro was deleted
        local oldName = macrosIndex[i]
        -- assume that the FIRST macro with a different name than before is THE added/deleted macro
        if oldName ~= currentName then
            deletedMacro = {
                id = i,
                name = currentName,
                oldName = oldName,
                found = true,
            }

            -- every subsequent macro has been shifted to a new slot.
            -- modify the macro ID by 1 via an inner loop, then exit the outer loop
            forEveryFlyoutBtn(function(btnDef, _, i)
                -- is this btn a macro?
                if btnDef.type == ButtonType.MACRO then
                    zebug.info:line(15, "i",i, "btnDef macroId",btnDef.macroId, "btnDef name",btnDef.name)
                    -- TODO - consider account VS toon... all toon macros > any account macro
                    if btnDef.macroId == deletedMacro.id then
                        zebug.warn:line(10,"IGNORING deleted macro ID", deletedMacro.id, "name ",btnDef.name)

                    elseif btnDef.macroId > deletedMacro.id then
                        local newMacroId = btnDef.macroId - 1
                        zebug.warn:line(10,"deleted macro ID", deletedMacro.id, "FOUND UFO entry for macro ",btnDef.name, "changing macro ID from", btnDef.macroId, "to", newMacroId)
                        btnDef.macroId = newMacroId
                    end
                end
            end)

            -- delete the macro from every flyout
            ---@param flyoutDef FlyoutDef
            FlyoutDefsDb:forEachFlyoutDef(function(flyoutDef)
                zebug.info:print("flyoutId",flyoutDef.flyoutId)
                flyoutDef:batchDeleteBtns(function(array, i)
                    ---@type ButtonDef
                    local btnDef = array[i]
                    if btnDef.type == ButtonType.MACRO then
                        local die = btnDef.macroId == deletedMacro.id
                        zebug.info:print("flyoutId",flyoutDef.flyoutId, "macroId",btnDef.macroId, "deletedMacro.id",deletedMacro.id, "die",die)
                        return die
                    end
                end)
            end)

            return true -- signal "the dishes are done, man!"
        end

        -- becoz potentially every macro is in a different slot,
        -- we must completely rebuild our now FUBAR index.  Thanks Bliz!
        index[i] = name
        map[name] = i
        mapCopy = map -- export the fresh new map to the outer scope
    end

    -- finally, now that the logic is all defined above, pull the trigger!
    macrosIndex = forEveryMacro(recreateIndexAndIdentifyTheMissingMacro)
    macrosMap = mapCopy -- ug, sorry for relying on side-effects
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
    Catalog:createToggleButton(SpellBookFrame)
    isUfoInitialized = true

    --FlyoutDefsDb:convertFloFlyoutToUfoAlpha1()
    --FlyoutDefsDb:convertfoAlpha1ToUfoAlpha2()
    --FlyoutDefsDb:convertfoAlpha1PlacementsToUfoAlpha2()

end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

createEventListener(Ufo, EventHandlers)
