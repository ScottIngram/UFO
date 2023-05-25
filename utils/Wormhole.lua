-- Wormhole
-- Lua voodoo magic that replaces the current Global namespace with the ADDON_VARS object (or the incoming table arg, if any)

local _, ADDON_VARS = ...

function ADDON_VARS.Wormhole(table)
    if not table then
        table = ADDON_VARS
    end
    setmetatable(table, { __index = _G }) -- inherit all members of the Global namespace
    setfenv(2, table) -- the 2 designates the CALLER's env
end
