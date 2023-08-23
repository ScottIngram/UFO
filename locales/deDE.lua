local ADDON_NAME, Ufo = ...

if "deDE" == GetLocale() then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    -- Localized text
    CONFIRM_DELETE = "Sind Sie sicher, dass Sie das Flyout-Set %s löschen möchten?"
    NEW_FLYOUT = "Neues\nFlyout"
    TOY = TOY
    CAN_NOT_MOVE = "kann von diesem Toon nicht verwendet, verschoben, oder entfernt werden."
    BARTENDER_BAR_DISABLED = "Ein UFO ist in eine Deaktiviert Bartender4-Leiste.  Re-aktivieren die Leiste und nachladen UI um zu das UFO aktivieren."
    DETECTED = "Erkannt"
    LOADED = "Voll"
end
