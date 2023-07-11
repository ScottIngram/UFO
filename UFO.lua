-- UFO.lua
-- addon lifecycle methods, coordination between submodules, etc.

--[[

TODO
* BUG: dropping a flyout from the cursor onto nothing fails to delete its proxy.  FIX: use CURSOR_CHANGED event
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
        return -- EXIT
    end

    if not macrosIndex then
        -- initialze and exit
        zebug.trace:print("initialze and exit")
        macrosIndex = {}
        macrosMap = {}
        forEveryMacro(function(i, name)
            macrosIndex[i] = name
            macrosMap[name] = i
        end)
        --zebug.trace:dumpy("INIT macrosMap",macrosMap)
        --zebug.trace:dumpy("INIT macrosIndex",macrosIndex)

        return -- EXIT
    end

    -- analyze and act
    local delta = didAnyMacroChange()
    if delta then
        zebug.trace:dumpy("delta",delta)
        zebug.info:print("initiating macro sync")
        syncFlyoutButtonsWithMacros(delta)
        macrosMap = delta.macrosMap
        macrosIndex = delta.macrosIndex
        zebug.info:line(50,"triggering global updates!")
        Catalog:update()
        GermCommander:updateAll()
    else
        zebug.trace:print("no macro changes")
    end

end

function forEveryMacro(callback)
    local funcResult

    function scanMacrosBetween(start, stop)
        zebug.trace:line(30,"SCANNING start",start, "stop",stop)
        for i = start, stop do
            local name, _, _ = GetMacroInfo(i)
            zebug.trace:print("scanned i",i, "name",name)
            if not name then return end -- stop when we run out of macros
            local result = callback(i, name)
            if result then return result end
        end
    end

    -- macros are grouped as
    -- account-wide 1 to 120
    -- toon-specific >120
    local nGlobal, nPerChar = GetNumMacros()

    -- ACCOUNT macros scan
    zebug.trace:line(30,"ACCOUNT macros scan. 1",nGlobal)
    funcResult = scanMacrosBetween(1, nGlobal)
    if funcResult then return funcResult end

    -- TOON macros scan
    local toonStart = 1 + MAX_GLOBAL_MACRO_ID
    local toonStop  = nPerChar + MAX_GLOBAL_MACRO_ID
    zebug.trace:line(30,"TOON macros scan",toonStart, toonStop)
    funcResult = scanMacrosBetween(toonStart, toonStop)
    if funcResult then return funcResult end
end

function didAnyMacroChange()
    local oldNames = macrosMap
    local oldMacrosIndex = macrosIndex

    local newNames = {}
    local newMacrosIndex = {}
    forEveryMacro(function(i, name)
        newNames[name] = i
        newMacrosIndex[i] = name
    end)

    -- search all previous macro NAMES and find one that vanished
    local missingName
    local oldIndex
    for i, oldName in pairs(oldMacrosIndex) do
        --zebug.trace:print("scanning for obsolete macros.  i",i, "name",oldName, "still exists",newNames[oldName])
        if not newNames[oldName] then
            zebug.info:print("FOUND! DELETED macro.  i",i, "name",oldName)
            oldIndex = i
            missingName = oldName
            break
        end
    end

    -- search all new macro NAMES and find one that didn't exist before
    local addedName
    local newIndex
    for i, newName in pairs(newMacrosIndex) do -- can't use ipairs because there is a gap between account macro IDs and toon macro IDs
        --zebug.trace:print("scanning for new macros.  i",i, "name",newName, "exists",oldNames[newName])
        if not oldNames[newName] then
            zebug.info:print("FOUND! NEW macro.  i",i, "name",newName)
            newIndex = i
            addedName = newName
            break
        end
    end

    local oldN = #oldMacrosIndex
    local newN = #newMacrosIndex
    local sameNumberOfMacros  = (oldN == newN)
    local someNameChanged     = (missingName and addedName) and true or false
    local someMacroDeleted    = (missingName and (not addedName)) and true or false
    local newMacroAdded       = (addedName and (not missingName)) and true or false
    local didRenamedMacroMove = someNameChanged and (oldIndex ~= newIndex)
    local somethingChanged    = someNameChanged or newMacroAdded or someMacroDeleted

    return somethingChanged and {
        sameNumberOfMacros  = sameNumberOfMacros,
        someNameChanged     = someNameChanged,
        didRenamedMacroMove = didRenamedMacroMove,
        newMacroAdded       = newMacroAdded,
        someMacroDeleted    = someMacroDeleted,
        oldN      = oldN,
        oldIndex  = oldIndex,
        oldName   = missingName,
        newN      = newN,
        newIndex  = newIndex,
        newName   = addedName,
        macrosMap = newNames,
        macrosIndex = newMacrosIndex,
    }
end

function forEveryButtonOnEveryFlyout(callback)
    ---@param flyoutDef FlyoutDef
    FlyoutDefsDb:forEachFlyoutDef(
        function(flyoutDef)
            zebug.trace:setMethodName("forEveryButtonOnEveryFlyout"):line(20, "flyout ID",flyoutDef.id)
            flyoutDef:forEachBtn(callback)
        end
    )
end

-- when comparing two macros, they must both be ACCOUNT wide or both be TOON specific.  Never mix them together
function comparable(aMacroId, bMacroId)
    if aMacroId <= MAX_GLOBAL_MACRO_ID then
        return bMacroId <= MAX_GLOBAL_MACRO_ID
    else
        return bMacroId > MAX_GLOBAL_MACRO_ID
    end
end

---@param flyoutDef FlyoutDef
---@param btnDef ButtonDef
function redefineMacro(flyoutDef, btnDef, delta)
    if btnDef.macroId == delta.oldIndex or btnDef.name == delta.oldName then
        zebug.info:print("macro name/ID change for flyout",flyoutDef.id,  "RENAMING old",delta.oldName, "new",delta.newName, "RENUMBERING old",delta.oldIndex, "new",delta.newIndex)
        btnDef:redefine(delta.newIndex, delta.newName)
        return true
    end
    return false
end

-- TODO: move to ButtonDef.lua
---@param btnDef ButtonDef
function canThisToonUse(btnDef)
    if isMacroGlobal(btnDef.macroId) then
        return true
    end

    local owner = btnDef.macroOwner
    local me = getIdForCurrentToon()
    if owner == me then
        return true
    end

    return false
end

---@class TypeOfDelta
local TypeOfDelta = {
    MOVE   = { shiftBy = 0 },
    ADD    = { shiftBy = 1 },
    DELETE = { shiftBy = -1 },
}

---@return function
---@param TypeOfDelta TypeOfDelta
function makeMoverFunc(typeOfDelta, initialPos, destinationPos)
    -- every macro with an ID between the old and new locations of the moved macro have also moved
    -- if the macro moved to an earlier spot, the ones before its original spot but after its new spot get bumped UP by 1
    -- if the macro moved to a later spot, the ones after its original spot but before its new spot get bumped DOWN by 1
    -- Example: abcDe -> aDbce -- In addition to the "D" moving, so have the "b" and "c", while "a" remains at 1 and "e" at 5.
    local floorId, ceilingId, shiftBy

    if typeOfDelta == TypeOfDelta.MOVE then
        local movedUp = initialPos < destinationPos
        if movedUp then
            floorId   = initialPos
            ceilingId = destinationPos
            shiftBy   = -1
        else
            floorId   = destinationPos
            ceilingId = initialPos
            shiftBy   = 1
        end
    else
        floorId = initialPos
        ceilingId = 9999
        shiftBy = typeOfDelta.shiftBy
    end
    zebug.trace:print("making mover to shift by", shiftBy)

    -- FUNC START
    ---@param btnDef ButtonDef
    ---@param flyoutDef FlyoutDef
    local mover = function(btnDef, _, i, flyoutDef)
        if comparable(initialPos, btnDef.macroId) and btnDef.macroId >= floorId and btnDef.macroId <= ceilingId then
            if not canThisToonUse(btnDef) then return end
            local newId = btnDef.macroId + shiftBy
            zebug.info:setMethodName("MACRO MOVER"):print("macro ID SHIFT for flyout",flyoutDef.id, "btn #",i, "name",btnDef.name, "shifting ID",btnDef.macroId, "by", shiftBy)
            btnDef.macroId = newId
            return true -- signal "we did something"
        end
    end
    -- FUNC END

    return mover
end

---@param macroDelta table
function syncFlyoutButtonsWithMacros(delta)
    ---@type function
    local remapper

    if delta.someNameChanged then
        -- RENAMED
        if delta.didRenamedMacroMove then
            -- AND MOVED
            zebug.info:print("renamed AND moved.  oldName",delta.oldName, "newName",delta.newName, "oldIndex",delta.oldIndex, "newIndex",delta.newIndex)
            local mover = makeMoverFunc(TypeOfDelta.MOVE, delta.oldIndex, delta.newIndex)

            -- FUNC START
            remapper = function(btnDef, _, i, flyoutDef)
                -- rename the specific macro
                local didSomething = redefineMacro(flyoutDef, btnDef, delta)

                -- move other macros up or down as needed
                if not didSomething then
                    didSomething = mover(btnDef, _, i, flyoutDef)
                end

                return didSomething
            end
            -- FUNC END
        else
            -- RENAMED but stayed in its original position
            zebug.info:print("renamed  oldName",delta.oldName, "newName",delta.newName)
            remapper = function(btnDef, _, _, flyoutDef)
                return redefineMacro(flyoutDef, btnDef, delta)
            end
        end
    elseif delta.newMacroAdded then
        -- ADDED
        zebug.info:print("ADDED newName",delta.newName, "at pos",delta.newIndex)
        remapper = makeMoverFunc(TypeOfDelta.ADD, delta.newIndex)
    elseif delta.someMacroDeleted then
        -- DELETED
        zebug.info:print("DELETED newName",delta.oldName, "from pos",delta.oldIndex)
        remapper = makeMoverFunc(TypeOfDelta.DELETE, delta.oldIndex)

        -- delete the macro from every flyout.
        -- it's safe to do this immediately even before we've adjusted the other buttons
        ---@param flyoutDef FlyoutDef
        FlyoutDefsDb:forEachFlyoutDef(function(flyoutDef)
            ---@param btnDef ButtonDef
            flyoutDef:batchDeleteBtns(function(btnDef)
                if btnDef.type == ButtonType.MACRO then
                    if not canThisToonUse(btnDef, delta.oldIndex) then return end -- don't delete non-account macros owned by other toons

                    local killIt = btnDef.macroId == delta.oldIndex
                    zebug.info:setMethodName("syncFlyoutButtonsWithMacros:CALLBACK"):print("flyoutId",flyoutDef.flyoutId, "macroId",btnDef.macroId, "deletedMacro.id",delta.oldIndex, "killIt", killIt)
                    return killIt
                end
            end)
        end)
    end

    -- FUNC START
    ---@param btnDef ButtonDef
    ---@param flyoutDef FlyoutDef
    ---@return boolean true if an action was performed
    local compositeFunc = function(btnDef, _, i, flyoutDef)
        if btnDef.type == ButtonType.MACRO then
            local didSomething = remapper(btnDef, _, i, flyoutDef)
            return didSomething
        end
        return false -- signal "nothing happened"
    end
    -- FUNC END

    -- now that we've defined what operations should be performed
    -- perform those ops on every stupid button
    forEveryButtonOnEveryFlyout(compositeFunc)
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
