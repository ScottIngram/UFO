-- Wormhole
-- Lua voodoo magic that replaces the current Global namespace with the ADDON_VARS object (or the incoming table arg, if any)

local _, ADDON_SYMBOL_TABLE = ...

function ADDON_SYMBOL_TABLE.Wormhole(table, parent)
    if not table then
        table = ADDON_SYMBOL_TABLE
    end
    if not parent then
        if table == ADDON_SYMBOL_TABLE then
            parent = _G
        else
            parent = ADDON_SYMBOL_TABLE -- can I automatically get the parent to "table" ?
        end
    end
    setmetatable(table, { __index = parent }) -- inherit all members of the Global namespace (or parent, if provided)
    setfenv(2, table) -- the 2 designates the CALLER's env
end
