-- Global Export
-- Exports any function or variable with a name that starts with "GLOBAL_" into the global namespace.
-- Useful for callback functions named in XML file <Script> tags and "function" fields.
-- I decided to use a prefix "GLOBAL_Foo" approach instead of a table "GLOBAL.Foo" approach
-- because it's easier for my code editor to find the declarations and usages

local ADDON_NAME, ADDON_SYMBOL_TABLE = ...

local function exportGlobalSymbols(table)
    for k,v in pairs(table) do
        if string.find(k,"^GLOBAL_") then
            _G[k] = v
        end
    end
end

exportGlobalSymbols(ADDON_SYMBOL_TABLE)
