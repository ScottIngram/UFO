local ADDON_NAME, Ufo = ...

if "zhCN" == GetLocale() then
    local ADDON_NAME, Ufo = ...
    Ufo.Wormhole(Ufo.L10N) -- Lua voodoo magic that replaces the current Global namespace with the Ufo.L10N object
    -- Now, FOO = "bar" is equivilent to Ufo.L10N.FOO = "bar" - Even though they all look like globals, they are not.

    CONFIRM_DELETE = "确定删除“%s”吗？"
    NEW_FLYOUT = "新建"
    TOY = TOY -- Bliz将其作为全局功能提供
    CAN_NOT_MOVE = "此角色无法使用、移动或移除。"
    BARTENDER_BAR_DISABLED = "一个UFO在禁用的Bartender4动作条上。启用Bartender4并重载UI以激活UFO。"
    DOMINOS_BAR_DISABLED = "一个UFO在禁用的Dominos动作条上。启用Dominos并重载UI以激活UFO。"
    DETECTED = "检测到"
    LOADED = "已加载"
    LEFT_CLICK = "左键点击"
    RIGHT_CLICK = "右键点击"
    MIDDLE_CLICK = "中键点击"
    OPEN_CATALOG = "打开目录"
    OPEN_CONFIG = "打开配置"

    SLASH_CMD_HELP = "帮助"
    SLASH_CMD_CONFIG = "配置"
    SLASH_DESC_CONFIG = "打开选项配置面板"
    SLASH_CMD_OPEN = "打开"
    SLASH_DESC_OPEN = "打开弹出式菜单目录"
    SLASH_UNKNOWN_COMMAND = "未知命令"

    -- 专业技能 / 商业技能，必须和当前语言中的名称匹配。
    ALCHEMY = "炼金术"
    BLACKSMITHING = "锻造"
    COOKING = "烹饪"
    ENCHANTING = "附魔"
    ENGINEERING = "工程学"
    FISHING = "钓鱼"
    HERBALISM = "草药学"
    INSCRIPTION = "铭文"
    JEWELCRAFTING = "珠宝加工"
    LEATHERWORKING = "制皮"
    MINING = "采矿"
    SKINNING = "剥皮"
    TAILORING = "裁缝"
end
