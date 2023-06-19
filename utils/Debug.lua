-- Debug.lua
-- developer utilities for displaying code behavior
--
-- Usage:
-- local debug = Debug:new(Debug.OUTPUT.INFO) -- the arg turns on/off different noise levels: TRACE, INFO, WARN, ERROR
-- debug.trace:print() -- this would be silent considering the "INFO" above.
-- debug.info:print() -- displays info and sets its priority as "INFO"
-- debug:print() -- ALSO displays info and sets its priority as "INFO" (the default priority)
-- debug.error:print() -- displays info and sets its priority as "ERROR"
--
-- During development, you may want to silence some levels that are not currently of interest, so change the arg to WARN or ERROR
-- When you release your addon and want to silence even more levels, use NONE


local ADDON_NAME, ADDON_VARS = ...

-------------------------------------------------------------------------------
-- Module Loading / Exporting
-------------------------------------------------------------------------------

---@class Debuggers -- IntelliJ-EmmyLua annotation
---@field error Debug always shown, highest priority messages
---@field warn Debug end user visible messages
---@field info Debug dev dev messages
---@field trace Debug tedious dev messages

---@class DebugLevel -- IntelliJ-EmmyLua annotation
local OUTPUT = {
    ALL_MSGS = 0,
    ALL   = 0,
    TRACE = 2,
    INFO  = 4,
    WARN  = 6,
    ERROR = 8,
    NONE  = 10,
}

---@class Debug -- IntelliJ-EmmyLua annotation
---@field OUTPUT DebugLevel -- IntelliJ-EmmyLua annotation
local Debug = {
    OUTPUT = OUTPUT
}

ADDON_VARS.Debug = Debug

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_DEBUG = OUTPUT.WARN
local ERR_MSG = "DEBUGGER SYNTAX ERROR: invoke as debug.info:func() not debug.info.func()"
local PREFIX = "<" .. ADDON_NAME .. ">"
local DEFAULT_LABEL = "[DEBUG]"
local DEFAULT_INDENT_CHAR = "#"
local DEFAULT_INDENT_WIDTH = 0

local COLORS = { }
COLORS[OUTPUT.TRACE] = GetClassColorObj("MAGE")
COLORS[OUTPUT.INFO]  = GetClassColorObj("MONK")
COLORS[OUTPUT.WARN]  = GetClassColorObj("ROGUE")
COLORS[OUTPUT.ERROR] = GetClassColorObj("DEATHKNIGHT")


-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

local function isDebuggerObj(zelf)
    return zelf and zelf.isDebug
end

---@param myLevel DebugLevel
local function newInstance(myLevel, canSpeakOnlyIfThisLevel, doColors)
    local isSilent = myLevel < canSpeakOnlyIfThisLevel
    local self = {
        level = myLevel,
        color = COLORS[myLevel],
        doColors = doColors,
        isSilent = isSilent,
        isDebug = true,
        indentWidth = 5,
        indentChar = DEFAULT_INDENT_CHAR,
        label = DEFAULT_LABEL

    }
    setmetatable(self, { __index = Debug })
    return self
end

---@return Debuggers -- IntelliJ-EmmyLua annotation
function Debug:new(canSpeakOnlyIfThisLevel, doColors)
    if doColors == nil then doColors = true end
    if not canSpeakOnlyIfThisLevel then
        canSpeakOnlyIfThisLevel = DEFAULT_DEBUG
    end
    local isValidNoiseLevel = type(canSpeakOnlyIfThisLevel) == "number"
    assert(isValidNoiseLevel, ADDON_NAME..": Debugger:newDebugger() Invalid Noise Level: '".. tostring(canSpeakOnlyIfThisLevel) .."'")

    local debugger = { }
    debugger.error = newInstance(OUTPUT.ERROR, canSpeakOnlyIfThisLevel, doColors)
    debugger.warn  = newInstance(OUTPUT.WARN,  canSpeakOnlyIfThisLevel, doColors)
    debugger.info  = newInstance(OUTPUT.INFO,  canSpeakOnlyIfThisLevel, doColors)
    debugger.trace = newInstance(OUTPUT.TRACE, canSpeakOnlyIfThisLevel, doColors)
    setmetatable(debugger, { __index = debugger.info }) -- support syntax such as debug:out() that bahaves as debuf.info:out()
    return debugger
end

function Debug:newDebuggers(...)
    local d = self:new(...)
    return d.trace, d.info, d.warn, d.error
end

function Debug:isMute()
    assert(isDebuggerObj(self), ERR_MSG)
    return self.isSilent
end

function Debug:isActive()
    assert(isDebuggerObj(self), ERR_MSG)
    return not self.isSilent
end

function Debug:colorize(str)
    if not self.doColors then return str end
    return self.color:WrapTextInColorCode(str)
end

function Debug:startColor()
    if not self.doColors then return "" end
    if not self.colorOpener then
        self.colorOpener = self.color:WrapTextInColorCode(""):sub(1,-3)
    end
    return self.colorOpener
end

function Debug:stopColor()
    if not self.doColors then return "" end
    return "|r"
end

function Debug:alert(msg)
    UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.0)
end

function Debug:dump(...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    print(self:startColor())
    DevTools_Dump(...)
    print(self:stopColor())
end

function Debug:dumpy(indentChar, indentWidth, label, ...)
    self:out(indentChar, indentWidth, label, ...)
    local lastArgIndex = select("#", ...)
    local lastArg = select(lastArgIndex, ...)
    self:dump(lastArg)
end

function Debug:print(...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    -- print(self:startColor(), ..., self:stopColor())
    print(self:colorize(PREFIX), ...)
end

function table.pack(...)
    return { n = select("#", ...), ... }
end

function Debug:setHeader(indentChar, label)
    if indentChar then
        self.indentChar = indentChar
    end
    if label then
        self.label = label
    end
    return self
end

function Debug:line(indentWidth, ...)
    self:out(self.indentChar, indentWidth, self.label, ...)
end

function Debug:out(indentChar, indentWidth, label, ...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    if indentChar then
        self.indentChar = indentChar
    end
    if label then
        self.label = label
    end
    local indent = string.rep(self.indentChar or DEFAULT_INDENT_CHAR, indentWidth or DEFAULT_INDENT_WIDTH)

    --local args = { ... } -- this may be where the nils are getting shortchanged
    local args = table.pack(...)
    local out = { self:startColor(), indent, " ", self.label or "", " ", self:stopColor() }
    --for i,v in ipairs(args) do
    for i=1,args.n do
        local v = args[i]
        local isOdd = i%2 == 1
        if isOdd then
            -- table.insert(out, " .. ")
            table.insert(out, self:asString(v))
        else
            table.insert(out, ": ")
            table.insert(out, self:asString(v))
            if i~= args.n then
                table.insert(out, " .. ")
            end
        end
    end
    local str = table.concat(out,"")
    print(self:colorize(PREFIX), str)
end

local function getName(obj, default)
    assert(isDebuggerObj(self), ERR_MSG)
    if(obj and obj.GetName) then
        return obj:GetName() or default or "UNKNOWN"
    end
    return default or "UNNAMED"
end

function Debug:messengerForEvent(eventName, msg)
    assert(isDebuggerObj(self), ERR_MSG)
    return function(obj)
        if self.isSilent then return end
        self:print(getName(obj,eventName).." said ".. msg .."! ")
    end
end

function Debug:makeDummyStubForCallback(obj, eventName, msg)
    assert(isDebuggerObj(self), ERR_MSG)
    self:print("makeDummyStubForCallback for " .. eventName)
    obj:RegisterEvent(eventName);
    obj:SetScript("OnEvent", self:messengerForEvent(eventName,msg))

end

function Debug:run(callback)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    callback()
end

function Debug:dumpKeys(object)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    if not object then
        self:print("NiL")
        return
    end

    local isNumeric = true
    for k,v in pairs(object) do
        if (type(k) ~= "number") then isNumeric = false end
    end
    local keys = {}
    for k, v in pairs(object or {}) do
        local key = isNumeric and k or self:asString(k)
        table.insert(keys,key)
    end
    table.sort(keys)
    for i, k in ipairs(keys) do
        self:print(k.." <-> ".. self:asString(object[k]))
    end
end

function Debug:asString(v)
    assert(isDebuggerObj(self), ERR_MSG)
    return ((v==nil)and"nil") or ((type(v) == "string") and v) or tostring(v) -- or
end
