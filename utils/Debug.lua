local ADDON_NAME, ADDON_VARS = ...

local ERR_MSG = "DEBUGGER SYNTAX ERROR: invoke as debug.info:func() not debug.info.func()"
local CONSTANTS = {
    ALL_MSGS = 0,
    ALL = 0,
    TRACE = 2,
    INFO = 4,
    WARN = 6,
    ERROR = 8,
    NONE = 10,
}
ADDON_VARS.DEBUG = CONSTANTS
local Debug = {}

local function isDebuggerObj(zelf)
    return zelf and zelf.isDEBUGGER
end

local function newInstance(isSilent)
    local newInstance = {
        isSilent = isSilent,
        isDEBUGGER = true
    }
    setmetatable(newInstance, { __index = Debug })
    return newInstance
end

function CONSTANTS.newDebugger(showOnlyMessagesAtOrAbove)
    local isValidNoiseLevel = type(showOnlyMessagesAtOrAbove) == "number"
    assert(isValidNoiseLevel, "Debugger:newDebugger() Invalid Noise Level: '".. tostring(showOnlyMessagesAtOrAbove) .."'")

    local debugger = { }
    debugger.error = newInstance(showOnlyMessagesAtOrAbove > CONSTANTS.ERROR)
    debugger.warn = newInstance(showOnlyMessagesAtOrAbove  > CONSTANTS.WARN)
    debugger.info = newInstance(showOnlyMessagesAtOrAbove  > CONSTANTS.INFO)
    debugger.trace = newInstance(showOnlyMessagesAtOrAbove > CONSTANTS.TRACE)
    return debugger
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
    local indent = string.rep(indentChar,indentWidth)
    --local args = { ... } -- this may be where the nils are getting shortchanged
    local args = table.pack(...)
    local out = { indent, " ", label, " " }
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
