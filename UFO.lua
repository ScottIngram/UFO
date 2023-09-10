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
local ADDON_NAME, Ufo = ...

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new()

-- Purely to satisfy my IDE
DB = Ufo.DB

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

local isUfoInitialized = false
local hasShitCalmedTheFuckDown = false

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
    -- And they won't exist until Bliz's built-in addons load.

    if addonName == "Blizzard_Collections" then
        Catalog:createToggleButton(CollectionsJournal)
    end

    if addonName == "Blizzard_MacroUI" then
        Catalog:createToggleButton(MacroFrame)
        MacroShitShow:init() -- this is worthless at the point in time because Bliz hasn't actually loaded macros yet.  Golfclap.
    end

    if addonName == "LargerMacroIconSelection" then
        supportLargerMacroIconSelection()
    end
end

function EventHandlers:PLAYER_LOGIN()
    zebug.trace:print("Heard event: PLAYER_LOGIN")
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    local msg = L10N.LOADED .. " v"..version
    msgUser(msg)
end

function EventHandlers:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    zebug.trace:print("Heard event: PLAYER_ENTERING_WORLD", "isInitialLogin",isInitialLogin, "isReloadingUi",isReloadingUi)
    initalizeAddonStuff() -- moved this here from PLAYER_LOGIN() because the Bliz API was just generally shitting the bed
    GermCommander:updateAll() -- moved this here from PLAYER_LOGIN() because the Bliz API was misrepresenting the bar directions >:(
end

function EventHandlers:ACTIONBAR_SLOT_CHANGED(actionBarSlotId)
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: ACTIONBAR_SLOT_CHANGED","actionBarSlotId",actionBarSlotId)
    GermCommander:handleActionBarSlotChanged(actionBarSlotId)
end

function EventHandlers:PLAYER_SPECIALIZATION_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: PLAYER_SPECIALIZATION_CHANGED")
    GermCommander:updateAll()
end

function EventHandlers:UPDATE_MACROS()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:line(40,"Heard event: UPDATE_MACROS")
    MacroShitShow:analyzeMacroUpdate()
end

function EventHandlers:UNIT_INVENTORY_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    zebug.trace:print("Heard event: UNIT_INVENTORY_CHANGED")

    GermCommander:handleEventChangedInventory()
end

function EventHandlers:CURSOR_CHANGED()
    if not hasShitCalmedTheFuckDown then return end
    --zebug.trace:line(40,"Heard event: CURSOR_CHANGED",C_TradeSkillUI.GetProfessionForCursorItem())
    local type, spellId = GetCursorInfo()
    zebug.trace:print("type",type, "spellId",spellId)
    GermCommander:delayedAsynchronousConditionalDeleteProxy()
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
        zebug.info:print(msg .. " is not allowed during combat.")
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

function registerSlashCmd()
    _G.SLASH_UFO1 = "/ufo"

    local slashFunc
    local slashHelp = function()
        --msgUser("commands...")
        for name, cmd in pairs(slashFunc) do
            local wee = cmd.desc and print("/ufo ".. name.. " - " .. cmd.desc)
        end
    end

    slashFunc = {
        help   = { fnc = slashHelp,},
        [L10N.SLASH_CMD_CONFIG] = { fnc = openConfig,   desc = L10N.SLASH_DESC_CONFIG },
        [L10N.SLASH_CMD_OPEN]   = { fnc = Catalog.open, desc = L10N.SLASH_DESC_OPEN },
    }

    SlashCmdList["UFO"] = function(arg)
        if isEmpty(arg) then
            arg = "help"
        end
        local cmd = slashFunc[arg]
        if not cmd then
            msgUser(L10N.SLASH_UNKNOWN_COMMAND .. ": \"".. arg .."\"")
        else
            msgUser(arg .."...")
            local func =cmd.fnc
            func()
        end
    end
end

function openConfig()
    Settings.OpenToCategory(Ufo.myTitle)
end

function msgUser(msg)
    print(zebug.info:colorize(ADDON_NAME .. ": ") .. msg)
end

-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------

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
    registerSlashCmd()
    Catalog:definePopupDialogWindow()
    ButtonDef:registerToolTipRecorder()
    Catalog:createToggleButton(SpellBookFrame)
    IconPicker:init()

    -- flags to wait out the chaos happening when the UI first loads / reloads.
    isUfoInitialized = true
    C_Timer.After(1, function() hasShitCalmedTheFuckDown = true end)
end

-------------------------------------------------------------------------------
-- OK, Go for it!
-------------------------------------------------------------------------------

createEventListener(Ufo, EventHandlers)
