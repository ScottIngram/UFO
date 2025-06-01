-- MacroShitShow
-- Macro Monitor and Reactor
--[[

The WoW macro implementation is a travesty of computer science.  A fifth grader would be ashamed to turn it in
as a homework assignment.  I've run into a number of things I dislike about the various WoW APIs, but this is the worst.

Macros do not have a unique, immutable identifier.  They have name and position.

If the user:
* Renames a macro it can change the alphabetical ordering of all macros and thus their positions.
* Adds or removes one, it also can change how many and thus shift their positions up or down.
Thanks to this, the following 300+ lines of code exist to overcome the needless complexities caused by a terrible design.

/golfclap

]]

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(zVol or Zebug.INFO)

---@class MacroShitShow
MacroShitShow = {}

local WAS_INITIALIZED = true
local macrosIndex
local macrosMap

function MacroShitShow:init()
    if macrosIndex then return WAS_INITIALIZED end

    zebug.info:print("initalizing macro index...")

    macrosIndex = {}
    macrosMap = {}
    local didAnything = false
    forEveryMacro(function(i, name)
        zebug.trace:print("forEveryMacro...i",i, "name",name)
        didAnything = true
        macrosIndex[i] = name
        macrosMap[name] = i
    end)

    if not didAnything then
        zebug.info:print("There are no macros... Yeah, sure.  FU Bliz.")
        macrosIndex = nil
        macrosMap = nil
    end

    return not WAS_INITIALIZED
end

function MacroShitShow:analyzeMacroUpdate(event)
    -- The Bliz API helpfully informs me that something, anything, who knows what,
    -- but yes macro related might have just happened.  Figure out WTF it was.

    zebug.info:print("Ufo.thatWasMeThatDidThatMacro",Ufo.thatWasMeThatDidThatMacro)
    if Ufo.thatWasMeThatDidThatMacro then
        -- the event was caused by an action of this addon and as such we shall ignore it
        zebug.trace:print("ignoring proxy draggable creation/death")
        Ufo.thatWasMeThatDidThatMacro = nil
        return -- EXIT
    end

    if self:init() ~= WAS_INITIALIZED then
        -- was only just now initialzed so abort
        zebug.info:print("not WAS_INITIALIZED")
        return
    end

    zebug.trace:print("analyzing...")

    -- analyze and act
    local delta = didAnyMacroChange()
    if delta then
        zebug.trace:dumpy("delta",delta)
        zebug.info:print("initiating macro sync")
        syncFlyoutButtonsWithMacros(delta)
        macrosMap = delta.macrosMap
        macrosIndex = delta.macrosIndex
        zebug.info:line(50,"triggering global updates!")
        Catalog:update(event)
        GermCommander:handleEventMacrosChanged(event) -- was updateAll()
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
            if not btnDef:isUsable() then return end
            local newId = btnDef.macroId + shiftBy
            zebug.info:setMethodName("MACRO MOVER"):print("macro ID SHIFT for flyout",flyoutDef.id, "btn #",i, "name",btnDef.name, "shifting ID",btnDef.macroId, "by", shiftBy)
            btnDef.macroId = newId
            return true -- signal "we did something"
        end
    end
    -- FUNC END

    return mover
end

---@param delta table
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
                    if not btnDef:isUsable() then return end -- don't delete non-account macros owned by other toons

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

