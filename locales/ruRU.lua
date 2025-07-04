local ADDON_NAME, Ufo = ...

if "ruRU" == GetLocale() then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.
    -- Translator into Russian ZamestoTV
    -- Professions / Trade Skills
    -- These MUST match what Bliz uses in its UI
CONFIRM_DELETE = "Вы уверены, что хотите удалить набор всплывающих меню %s?"
NEW_FLYOUT = "Новое\nВсплывающее меню"
TOY = TOY -- Bliz provides this as a global
CAN_NOT_MOVE = "нельзя использовать, перемещать или удалять этим персонажем."
BARTENDER_BAR_DISABLED = "UFO находится на отключённой панели Bartender4. Включите панель и перезагрузите интерфейс, чтобы активировать UFO."
DOMINOS_BAR_DISABLED = "UFO находится на отключённой панели Dominos. Включите панель и перезагрузите интерфейс, чтобы активировать UFO."
DETECTED = "обнаружено"
LOADED = "загружено"
LEFT_CLICK = "ЛКМ"
RIGHT_CLICK = "ПКМ"
MIDDLE_CLICK = "СКМ"
OPEN_CATALOG = "открыть каталог"
OPEN_CONFIG = "открыть настройки"

SLASH_CMD_HELP = "помощь"
SLASH_CMD_CONFIG = "настройки"
SLASH_DESC_CONFIG = "открыть панель конфигурации настроек."
SLASH_CMD_OPEN = "открыть"
SLASH_DESC_OPEN = "открыть каталог всплывающих меню."
SLASH_UNKNOWN_COMMAND = "неизвестная команда"

-- Professions / Trade Skills
-- These MUST match what Bliz uses in its UI
JEWELCRAFTING = "Ювелирное дело"
BLACKSMITHING = "Кузнечное дело"
LEATHERWORKING = "Кожевничество"
ENGINEERING = "Инженерное дело"

WAITING_UNTIL_COMBAT_ENDS = "Ожидание окончания боя для "
COMBAT_HAS_ENDED_SO_NOW_WE_CAN = "Бой закончился, теперь мы можем "
RECONFIGURE_AUTO_CLOSE = "перенастроить автозакрытие."
CHANGE_KEYBINDING = "изменить привязку клавиш."
RECONFIGURE_BUTTON = "перенастроить кнопку."
CHANGE_KEYBIND_ACTION = "изменить действие привязки клавиш."
RECONFIGURE_FLYOUT_BUTTON_KEYBINDING = "перенастроить привязку клавиш для кнопки всплывающего меню."
SWITCH_TO_PLACEHOLDERS = "переключиться на заглушки."
DELETE_PLACEHOLDERS = "удалить заглушки."
CHANGE_MOUSE_BUTTON_BEHAVIOR = "изменить поведение кнопок мыши"
end
