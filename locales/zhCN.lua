local ADDON_NAME, Ufo = ...

if "zhCN" == GetLocale() then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    -- Professions / Trade Skills
    -- These MUST match what Bliz uses in its UI
    JEWELCRAFTING = "珠宝加工"
    BLACKSMITHING = "锻造"
    LEATHERWORKING = "制皮"
end
