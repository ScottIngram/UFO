if "esES" == GetLocale() then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    -- Localized text
    --USAGE = "Foo"
    --CONFIRM_DELETE = "Are you sure you want to delete the flyout set %s?"
    --NEW_FLYOUT = "New\nFlyout"
end
