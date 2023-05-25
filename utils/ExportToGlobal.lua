-- Global Export
-- Exports any function or variable with a name that starts with "GLOBAL_" into the global namespace.
-- Useful for callback functions named in XML file <Script> tags and "function" fields.
-- I decided to use a prefix "GLOBAL_Foo" approach instead of a table "GLOBAL.Foo" approach
-- because it's easier for my code editor to find the declarations and usages

local ADDON_NAME, Ufo = ...
local debug = Ufo.DEBUG.newDebugger(Ufo.DEBUG.ERROR)

local function exportGlobalSymbols(table)
    debug.trace:out("=",3,"exportGlobalSymbols...")
    for k,v in pairs(table) do
        if string.find(k,"^GLOBAL_") then
            _G[k] = v
            debug.trace:out("=",5,"EXPORT !", "func",k,"-->",v)
        else
            debug.trace:out("=",5,"skipping", "func",k)
        end
    end
end

exportGlobalSymbols(Ufo)
