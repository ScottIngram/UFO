local ADDON_NAME, Ufo = ...

if "esMX" == GetLocale() or "es" == string.sub(GetLocale(),1,2) then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    -- Localized text
    CONFIRM_DELETE = "¿Estás seguro de que quieres eliminar el conjunto flotante %s?"
    NEW_FLYOUT = "Nuevo\nFlyout"
    TOY = TOY -- Bliz provides this as a global
    CAN_NOT_MOVE = "Este toon no puede usarlo, moverlo ni eliminarlo."
    BARTENDER_BAR_DISABLED = "Un UFO está en una barra Bartender4 deshabilitada. Vuelva a habilitar la barra y vuelva a cargar la interfaz de usuario para activar el UFO."
    DETECTED = "detectado"
    LOADED = "cargado"
end
