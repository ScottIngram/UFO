local ADDON_NAME, Ufo = ...

if "koKR" == GetLocale() or "ko" == string.sub(GetLocale(),1,2) then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    -- Professions / Trade Skills
    -- These MUST match what Bliz uses in its UI
    JEWELCRAFTING = "보석세공"
    BLACKSMITHING = "대장기술"
    LEATHERWORKING = "가죽세공"
end
