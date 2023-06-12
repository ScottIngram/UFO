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
local DEBUG_OUTPUT = {
    ALL_MSGS = 0,
    ALL = 0,
    TRACE = 2,
    INFO = 4,
    WARN = 6,
    ERROR = 8,
    NONE = 10,
}

---@class Debug -- IntelliJ-EmmyLua annotation
---@field OUTPUT DebugLevel -- IntelliJ-EmmyLua annotation
local Debug = {
    OUTPUT = DEBUG_OUTPUT
}

ADDON_VARS.Debug = Debug
ADDON_VARS.DEBUG_OUTPUT = DEBUG_OUTPUT

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------


local ERR_MSG = "DEBUGGER SYNTAX ERROR: invoke as debug.info:func() not debugInfo.func()"

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

local function isDebuggerObj(zelf)
    return zelf and zelf.isDebug
end

local function newInstance(isSilent)
    local newInstance = {
        isSilent = isSilent,
        isDebug = true
    }
    setmetatable(newInstance, { __index = Debug })
    return newInstance
end

---@return Debuggers -- IntelliJ-EmmyLua annotation
function Debug:new(showOnlyMessagesAtOrAbove)
    local isValidNoiseLevel = type(showOnlyMessagesAtOrAbove) == "number"
    assert(isValidNoiseLevel, "Debugger:newDebugger() Invalid Noise Level: '".. tostring(showOnlyMessagesAtOrAbove) .."'")

    local debugger = { }
    debugger.error = newInstance(showOnlyMessagesAtOrAbove > DEBUG_OUTPUT.ERROR)
    debugger.warn = newInstance(showOnlyMessagesAtOrAbove  > DEBUG_OUTPUT.WARN)
    debugger.info = newInstance(showOnlyMessagesAtOrAbove  > DEBUG_OUTPUT.INFO)
    debugger.trace = newInstance(showOnlyMessagesAtOrAbove > DEBUG_OUTPUT.TRACE)
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


function Debug:dump(...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    DevTools_Dump(...)
end

function Debug:print(...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    print(...)
end

function table.pack(...)
    return { n = select("#", ...), ... }
end

function Debug:out(indentChar, indentWidth, label, ...)
    assert(isDebuggerObj(self), ERR_MSG)
    if self.isSilent then return end
    local indent = string.rep(indentChar or "#", indentWidth or 40)
    --local args = { ... } -- this may be where the nils are getting shortchanged
    local args = table.pack(...)
    local out = { indent, " ", label or "", " " }
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
    print(str)
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
        print(getName(obj,eventName).." said ".. msg .."! ")
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
