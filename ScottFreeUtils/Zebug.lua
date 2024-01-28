-- Zebug.lua
-- developer utilities for displaying code behavior
--
-- Usage:
-- local zebug = Zebug:new(Zebug.OUTPUT.INFO) -- the arg turns on/off different noise levels: TRACE, INFO, WARN, ERROR
-- zebug.trace:print(arg1,arg2, etc) -- this would be silent considering the "Zebug.OUTPUT.INFO" above.  Otherwise, would display a header and all args as "arg1=arg2, arg3=arg4, " etc.
-- zebug.info:print(arg1,arg2, etc) -- displays the args and sets its priority as "INFO"
-- zebug.warn:print(arg1,arg2, etc) -- displays the args and sets its priority as "WARN"
-- zebug.error:print(arg1,arg2, etc) -- displays the args and sets its priority as "ERROR"
-- zebug:print() -- in the absence of a priority,  "INFO" is the default
-- zebug:line(10) -- behaves as print() but sets the header width to 10
-- zebug:out(10,"*") -- behaves as print() but sets the header width to 10 and the header character to "*"
--
-- You can chain some commands
-- zebug:setMethodName("DoMeNow"):print("foo", bar)
-- During development, you may want to silence some levels that are not currently of interest, so change the arg to WARN or ERROR
-- When you release your addon and want to silence even more levels, use NONE

local ADDON_NAME, ADDON_SYMBOL_TABLE = ...

-------------------------------------------------------------------------------
-- Module Loading / Exporting
-------------------------------------------------------------------------------

---@class Zebuggers -- IntelliJ-EmmyLua annotation
---@field error Zebug always shown, highest priority messages
---@field warn Zebug end user visible messages
---@field info Zebug dev dev messages
---@field trace Zebug tedious dev messages

---@class ZebugLevel -- IntelliJ-EmmyLua annotation
local OUTPUT = {
    ALL_MSGS = 0,
    ALL   = 0,
    TRACE = 2,
    INFO  = 4,
    WARN  = 6,
    ERROR = 8,
    NONE  = 10,
}

---@class Zebug -- IntelliJ-EmmyLua annotation
---@field OUTPUT ZebugLevel -- IntelliJ-EmmyLua annotation
local Zebug = {
    OUTPUT = OUTPUT
}

ADDON_SYMBOL_TABLE.Zebug = Zebug

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local DEFAULT_ZEBUG = OUTPUT.WARN

local ERR_MSG = "ZEBUGGER SYNTAX ERROR: invoke as zebug.info:func() not zebug.info.func()"
local PREFIX = "<" .. ADDON_NAME .. ">"
local DEFAULT_INDENT_CHAR = "#"
local DEFAULT_INDENT_WIDTH = 0

local COLORS = { }
COLORS[OUTPUT.TRACE] = GetClassColorObj("WARRIOR")
COLORS[OUTPUT.INFO]  = GetClassColorObj("MONK")
COLORS[OUTPUT.WARN]  = GetClassColorObj("ROGUE")
COLORS[OUTPUT.ERROR] = GetClassColorObj("DEATHKNIGHT")

-------------------------------------------------------------------------------
-- Inner Class - ZebuggersSharedData
-------------------------------------------------------------------------------

---@class ZebuggersSharedData -- IntelliJ-EmmyLua annotation
---@field OUTPUT ZebugLevel -- IntelliJ-EmmyLua annotation
local ZebuggersSharedData = { }

---@return ZebuggersSharedData -- IntelliJ-EmmyLua annotation
function ZebuggersSharedData:new()
    local sharedData = {
        doColors = true,
        indentChar = DEFAULT_INDENT_CHAR,
    }
    setmetatable(sharedData, { __index = ZebuggersSharedData })
    return sharedData
end

-------------------------------------------------------------------------------
-- Class Zebug - Functions / Methods
-------------------------------------------------------------------------------

local function isZebuggerObj(zelf)
    return zelf and zelf.isZebug
end

---@param myLevel ZebugLevel
local function newInstance(myLevel, canSpeakOnlyIfThisLevel, sharedData)
    local isSilent = myLevel < canSpeakOnlyIfThisLevel
    local self = {
        isZebug = true,
        level = myLevel,
        color = COLORS[myLevel],
        isSilent = isSilent,
        indentWidth = 5,
        sharedData = sharedData,
    }
    setmetatable(self, { __index = Zebug })
    return self
end

---@return Zebuggers -- IntelliJ-EmmyLua annotation
function Zebug:new(canSpeakOnlyIfThisLevel)
    if not canSpeakOnlyIfThisLevel then
        canSpeakOnlyIfThisLevel = DEFAULT_ZEBUG
    end
    local isValidNoiseLevel = type(canSpeakOnlyIfThisLevel) == "number"
    assert(isValidNoiseLevel, ADDON_NAME..": Zebugger:newZebugger() Invalid Noise Level: '".. tostring(canSpeakOnlyIfThisLevel) .."'")

    local sharedData = ZebuggersSharedData:new()
    local zebugger = { }
    zebugger.error = newInstance(OUTPUT.ERROR, canSpeakOnlyIfThisLevel, sharedData)
    zebugger.warn  = newInstance(OUTPUT.WARN,  canSpeakOnlyIfThisLevel, sharedData)
    zebugger.info  = newInstance(OUTPUT.INFO,  canSpeakOnlyIfThisLevel, sharedData)
    zebugger.trace = newInstance(OUTPUT.TRACE, canSpeakOnlyIfThisLevel, sharedData)
    setmetatable(zebugger, { __index = zebugger.info }) -- support syntax such as zebug:out() that bahaves as debuf.info:out()
    return zebugger
end

function Zebug:newZebuggers(...)
    local d = self:new(...)
    return d.trace, d.info, d.warn, d.error
end

function Zebug:isMute()
    assert(isZebuggerObj(self), ERR_MSG)
    return self.isSilent
end

function Zebug:isActive()
    assert(isZebuggerObj(self), ERR_MSG)
    return not self.isSilent
end

function Zebug:colorize(str)
    if not self.sharedData.doColors then return str end
    return self.color:WrapTextInColorCode(str)
end

function Zebug:startColor()
    if not self.sharedData.doColors then return "" end
    if not self.colorOpener then
        self.colorOpener = self.color:WrapTextInColorCode(""):sub(1,-3)
    end
    return self.colorOpener
end

function Zebug:stopColor()
    if not self.sharedData.doColors then return "" end
    return "|r"
end

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:setMethodName(methodName)
    self.methodName = methodName
    return self
end

Zebug.name = Zebug.setMethodName

function Zebug:alert(msg)
    UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.0)
    return self
end

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:dump(...)
    return self:dumpy("", ...)
end

local DOWN_ARROW = ".....vvvvvVVVVVvvvvv....."
local UP_ARROW   = "`````^^^^^AAAAA^^^^^`````"

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:dumpy(label, ...)
    assert(isZebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    self:out(2,DOWN_ARROW, label, DOWN_ARROW)
    DevTools_Dump(...)
    self:out(2,UP_ARROW, label, UP_ARROW)
    return self
end

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:print(...)
    assert(isZebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    --if not self.caller then self.caller = getfenv(2) end

    self:line(self.sharedData.indentWidth, ...)

    self.caller = nil
    return self
end

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:line(indentWidth, ...)
    assert(isZebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    --if not self.caller then self.caller = getfenv(2) end

    self:out(indentWidth, self.sharedData.indentChar, ...)

    self.caller = nil
    return self
end

---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:out(indentWidth, indentChar, ...)
    assert(isZebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    --if not self.caller then self.caller = getfenv(2) end

    --print("Zebug:out() calledBy-->", debugstack(2,4,0) )
    --print("caller ---> ", self:identifyOutsideCaller() )

    local indent = string.rep(indentChar or DEFAULT_INDENT_CHAR, indentWidth or DEFAULT_INDENT_WIDTH)
    local args = table.pack(...)
    local d = self.sharedData
    local label = self:getLabel()
    local out = { self:startColor(), indent, " ", label or "", " ", self:stopColor() }
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

    self.caller = nil
    return self
end

function table.pack(...)
    return { n = select("#", ...), ... }
end

-- find the name of the non-Zebug function who invoked the Zebug:Method
---@return string file name
---@return number line number
---@return string function name
function Zebug:identifyOutsideCaller()
    -- ask for the stack trace (the list of functions responsible for getting to this point in the code)
    -- skip past the top four (1 = this function, 2 = getLabel, 3 = some other Zebug function, 4 = the first possible non-Zebug function)
    -- start looking at callers 3 layers away and work back until we find something non-Zebug
    local stack = debugstack(4,4,0)
    local tmp = stack
    local j, line, isZebug, isTail, file, n, funcName
    local count = 1
    while stack do
        _, j = string.find(stack, "\n")
        line = string.sub(stack, 1, j)
        isZebug = string.find(line, "Zebug.lua")
        isTail = string.find(line, "tail call")
        if isZebug or isTail then
            stack = string.sub(stack, j+1)
        else
            _,_, file, n, funcName = string.find(line,'([%w_]+)%.[^"]*"]:(%d+):%s*in function%s*.(.+).\n');
            if not funcName then
                print(tmp)
                funcName = ""
            end
            if string.find(funcName, "/") then
                -- this is an anonymous function and funcName only contains file name and line number which we already know
                funcName = nil
            end
            stack = nil
        end

        -- guard against an infinite loop
        count = count + 1
        if count > 10 then
            stack = nil
            print "oops too loops"
        end
    end

    return file, n, funcName
end



---@return Zebug -- IntelliJ-EmmyLua annotation
function Zebug:setIndentChar(indentChar)
    self.sharedData.indentChar = indentChar
    return self
end

function Zebug:getLabel()
    local file, n, func = self:identifyOutsideCaller()
    local name = self.methodName or func
    name = (name and (name.."()~")) or ""
    local lineNumber = (n and "["..n.."]") or ""
    self.methodName = nil
    return (file and (file..":") or "") .. name .. lineNumber
end

local function getName(obj, default)
    assert(isZebuggerObj(self), ERR_MSG)
    if(obj and obj.GetName) then
        return obj:GetName() or default or "UNKNOWN"
    end
    return default or "UNNAMED"
end

function Zebug:messengerForEvent(eventName, msg)
    assert(isZebuggerObj(self), ERR_MSG)
    return function(obj)
        if self.isSilent then return end
        self:print(getName(obj,eventName).." said ".. msg .."! ")
    end
end

function Zebug:makeDummyStubForCallback(obj, eventName, msg)
    assert(isZebuggerObj(self), ERR_MSG)
    self:print("makeDummyStubForCallback for " .. eventName)
    obj:RegisterEvent(eventName);
    obj:SetScript(Script.ON_EVENT, self:messengerForEvent(eventName,msg))

end

function Zebug:run(callback)
    assert(isZebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    callback()
end

function Zebug:dumpKeys(object)
    assert(isZebuggerObj(self), ERR_MSG)
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

function Zebug:asString(v)
    assert(isZebuggerObj(self), ERR_MSG)
    return ((v==nil)and"nil") or ((type(v) == "string") and v) or tostring(v) -- or
end
