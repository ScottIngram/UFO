local ADDON_NAME, Ufo = ...

Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo.CONST object
-- Now, FOO = "bar" is equivilent to Ufo.FOO = "bar" - Even though they all look like globals, they are not.

BLIZ_BAR_METADATA = {
    [1]  = {name="Action",              visibleIf="bar:1,nobonusbar:1,nobonusbar:2,nobonusbar:3,nobonusbar:4"}, -- primary "ActionBar" - page #1 - no stance/shapeshift --- ff: actionBarPage = 1
    [2]  = {name="Action",              visibleIf="bar:2"}, -- primary "ActionBar" - page #2 (regardless of stance/shapeshift) --- ff: actionBarPage = 2
    [3]  = {name="MultiBarRight",       }, -- config UI -> Action Bars -> checkbox #4
    [4]  = {name="MultiBarLeft",        }, -- config UI -> Action Bars -> checkbox #5
    [5]  = {name="MultiBarBottomRight", }, -- config UI -> Action Bars -> checkbox #3
    [6]  = {name="MultiBarBottomLeft",  }, -- config UI -> Action Bars -> checkbox #2
    [7]  = {name="Action",              visibleIf="bar:1,bonusbar:1"}, -- primary "ActionBar" - page #1 - bonusbar 1 - druid CAT
    [8]  = {name="Action",              visibleIf="bar:1,bonusbar:2"}, -- primary "ActionBar" - page #1 - bonusbar 2 - unknown?
    [9]  = {name="Action",              visibleIf="bar:1,bonusbar:3"}, -- primary "ActionBar" - page #1 - bonusbar 3 - druid BEAR
    [10] = {name="Action",              visibleIf="bar:1,bonusbar:4"}, -- primary "ActionBar" - page #1 - bonusbar 4 - druid MOONKIN
    [11] = {name="Action",              visibleIf="bar:1,bonusbar:5"}, -- primary "ActionBar" - page #1 - bonusbar 5 - dragon riding
    [12] = {name="Action",              visibleIf="bar:1,bonusbar:6"--[[just a guess]]}, -- unknown?
    [13] = {name="MultiBar5"}, -- config UI -> Action Bars -> checkbox #6
    [14] = {name="MultiBar6"}, -- config UI -> Action Bars -> checkbox #7
    [15] = {name="MultiBar7"}, -- config UI -> Action Bars -> checkbox #8
}

V_MAJOR = 10
V_MINOR = 1
V_PATCH = 0
V_UFO = "a"
VERSION = table.concat({V_MAJOR, V_MINOR, V_PATCH, V_UFO}, ".")

X = nil
MAX_FLYOUT_SIZE = 20
NON_SPEC_SLOT = 5
SPELLFLYOUT_DEFAULT_SPACING = 4
SPELLFLYOUT_INITIAL_SPACING = 7
SPELLFLYOUT_FINAL_SPACING = 4
STRIPE_COLOR = {r=0.9, g=0.9, b=1}
STRATA_DEFAULT = "MEDIUM"
STRATA_MAX = "TOOLTIP"
PROXY_MACRO_NAME = "_ufo_proxy"
MAX_GLOBAL_MACRO_ID = 120
DELIMITER = "\a"
EMPTY_ELEMENT = "\t" -- strjoin skips "" as if they were nil, but "" isn't treated as nil. omfg Lua, get it together.
CONSUMABLE = "Consumable"
