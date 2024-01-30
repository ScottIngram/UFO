-- BlizApiEnums.lua
-- a bunch of IntelliJ-EmmyLua annotations
-- I should be using @enum but it's not supported by... my version of EmmyLua?  Something?  Regardless, @enum isn't recognized by my IDE
-- ref: Interface/FrameXML/UI_shared.xsd

local ADDON_NAME, ADDON_SYMBOL_TABLE = ...
ADDON_SYMBOL_TABLE.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo

---@class MouseClick
MouseClick = {
    ANY    = "any",
    LEFT   = "LeftButton",
    RIGHT  = "RightButton",
    MIDDLE = "MiddleButton",
    FOUR   = "Button4",
    FIVE   = "Button5",
    SIX    = "Button6", -- there is no "Button6" in the API docs, so,  I've reserved this for use by my keybind code
}

---@class Anchor
Anchor = {
    LEFT        = "LEFT",
    RIGHT       = "RIGHT",
    CENTER      = "CENTER",
    BOTTOM      = "BOTTOM",
    TOP         = "TOP",
    TOPLEFT     = "TOPLEFT",
    TOPRIGHT    = "TOPRIGHT",
    BOTTOMLEFT  = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT",
}

---@class TooltipAnchor
TooltipAnchor = {
    BOTTOM_LEFT = "ANCHOR_BOTTOMLEFT",
    CURSOR      = "ANCHOR_CURSOR",
    LEFT        = "ANCHOR_LEFT",
    NONE        = "ANCHOR_NONE",
    PRESERVE    = "ANCHOR_PRESERVE",
    RIGHT       = "ANCHOR_RIGHT",
    TOP_LEFT    = "ANCHOR_TOPLEFT",
    TOP_RIGHT   = "ANCHOR_TOPRIGHT",
}

---@class FrameType
FrameType = {
    FRAME           = "Frame",
    ARCHAEOLOGY_DIG_SITE_FRAME = "ArchaeologyDigSiteFrame",
    BROWSER         = "Browser",
    BUTTON          = "Button",
    CHECK_BUTTON    = "CheckButton",
    CHECKOUT        = "Checkout",
    CINEMATIC_MODEL = "CinematicModel",
    COLOR_SELECT    = "ColorSelect",
    COOLDOWN        = "Cooldown",
    DRESS_UP_MODEL  = "DressUpModel",
    EDIT_BOX        = "EditBox",
    FOG_OF_WAR_FRAME = "FogOfWarFrame",
    GAME_TOOLTIP     = "GameTooltip",
    MESSAGE_FRAME    = "MessageFrame",
    MODEL            = "Model",
    MODEL_SCENE      = "ModelScene",
    MOVIE_FRAME      = "MovieFrame",
    OFF_SCREEN_FRAME = "OffScreenFrame",
    PLAYER_MODEL     = "PlayerModel",
    QUEST_POIFrame   = "QuestPOIFrame",
    SCENARIO_POIFrame = "ScenarioPOIFrame",
    SCROLL_FRAME      = "ScrollFrame",
    SIMPLE_HTML       = "SimpleHTML",
    SLIDER            = "Slider",
    STATUS_BAR        = "StatusBar",
    TABARD_MODEL      = "TabardModel",
    UNIT_POSITION_FRAME = "UnitPositionFrame",
}

---@class Script -- widget script handlers
Script = {
    ON_LOAD              = "OnLoad", --func(self) - object is created.
    ON_HIDE              = "OnHide", --func(self) - widget's visibility changes to hidden.
    ON_ENTER             = "OnEnter", --func(self, motion) - cursor enters the widget's interactive area.
    ON_LEAVE             = "OnLeave", --func(self, motion) - mouse cursor leaves the widget's interactive area.
    ON_MOUSE_DOWN        = "OnMouseDown", --func(self, button) - mouse button is pressed while the cursor is over the widget.
    ON_MOUSE_UP          = "OnMouseUp", --func(self) - widget becomes visible.
    ON_MOUSE_WHEEL       = "OnMouseWheel", --func(self, requested) - animation group finishes animating.
    ON_ATTRIBUTE_CHANGED = "OnAttributeChanged", --func(self, key, value) - secure frame attribute is changed.
    ON_SIZE_CHANGED      = "OnSizeChanged", --func(self, width, height) - frame's size changes
    ON_EVENT             = "OnEvent", --func(self, event, ...) - any and all events.
    ON_UPDATE            = "OnUpdate", -- func(self, elapsed) - Invoked on every frame, as in, the "frame" in Frame Per Second.
    ON_DRAG_START        = "OnDragStart", --func(self, button) - mouse is dragged starting in the frame
    ON_DRAG_STOP         = "OnDragStop", --func(self) - mouse button is released after a drag started in the frame,
    ON_RECEIVE_DRAG      = "OnReceiveDrag", --func(self) - mouse button is released after dragging into the frame.
    PRE_CLICK            = "PreClick", --func(self, button, down) - before `OnClick`.
    ON_CLICK             = "OnClick", --func(self, self, button, down) - clicking a button.
    POST_CLICK           = "PostClick", --func(self, button, down) - after `OnClick`.
    ON_DOUBLE_CLICK      = "OnDoubleClick", --func(self, self, button) - double-clicking a button.
    ON_VALUE_CHANGED     = "OnValueChanged", --func(self, value, userInput) - the slider's or status bar's value changes.
    ON_MIN_MAX_CHANGED   = "OnMinMaxChanged", --func(self, min, max) - the slider's or status bar's minimum and maximum values change.
    ON_UPDATE_MODEL      = "OnUpdateModel",
    ON_MODEL_CLEARED     = "OnModelCleared",
    ON_MODEL_LOADED      = "OnModelLoaded", --func(self) - model is loaded
    ON_ANIM_STARTED      = "OnAnimStarted", --func(self) - model's animation starts
    ON_ANIM_FINISHED     = "OnAnimFinished", --func(self) - model's animation finishes
    ON_ENTER_PRESSED     = "OnEnterPressed", --func(self) - pressing Enter while the widget has focus
    ON_ESCAPE_PRESSED    = "OnEscapePressed", --func(self) - pressing Escape while the widget has focus
    ON_SPACE_PRESSED     = "OnSpacePressed", --func(self) - pressing Space while the widget has focus
    ON_TAB_PRESSED       = "OnTabPressed", --func(self) - pressing Tab while the widget has focus
    ON_TEXT_CHANGED      = "OnTextChanged", --func(self, userInput) - changing the value
    ON_TEXT_SET          = "OnTextSet", --func(self) - setting the value programmatically
    ON_CURSOR_CHANGED    = "OnCursorChanged", --func(self, x, y, w, h) - moving the text insertion cursor
    ON_INPUT_LANGUAGE_CHANGED = "OnInputLanguageChanged", --func(self, language) - changing the language input mode 
    ON_EDIT_FOCUS_GAINED    = "OnEditFocusGained", --func(self) - gaining edit focus
    ON_EDIT_FOCUS_LOST      = "OnEditFocusLost", --func(self) - losing edit focus
    ON_HORIZONTAL_SCROLL    = "OnHorizontalScroll", --func(self, offset) - the horizontal scroll position changes
    ON_VERTICAL_SCROLL      = "OnVerticalScroll", --func(self, offset) - the vertical scroll position changes
    ON_SCROLL_RANGE_CHANGED = "OnScrollRangeChanged", --func(self, xrange, yrange) - the scroll position changes 
    ON_CHAR_COMPOSITION     = "OnCharComposition", --func(self, text) - changing the input composition mode
    ON_CHAR                 = "OnChar", --func(self, text) - any text character typed in the frame.
    ON_KEY_DOWN             = "OnKeyDown", --func(self, key) - keyboard key is pressed if the frame is keyboard enabled
    ON_KEY_UP               = "OnKeyUp", --func(self, key) - keyboard key is released if the frame is keyboard enabled
    ON_GAME_PAD_BUTTON_DOWN = "OnGamePadButtonDown", --func(self, button) - gamepad button is pressed.
    ON_GAME_PAD_BUTTON_UP   = "OnGamePadButtonUp", --func(self, button) - gamepad button is released.
    ON_GAME_PAD_STICK       = "OnGamePadStick", --func(self, stick, x, y, len) - gamepad stick is moved
    ON_COLOR_SELECT         = "OnColorSelect", --func(self, r, g, b) - ColorSelect frame's color selection changes
    ON_HYPERLINK_ENTER      = "OnHyperlinkEnter", --func(self, link, text, region, left, bottom, width, height) - mouse moves over a hyperlink on the FontInstance object
    ON_HYPERLINK_LEAVE      = "OnHyperlinkLeave", --func(self) - mouse moves away from a hyperlink on the FontInstance object
    ON_HYPERLINK_CLICK      = "OnHyperlinkClick", --func(self, link, text, button, region, left, bottom, width, height) - mouse clicks a hyperlink on the FontInstance object
    ON_MESSAGE_SCROLL_CHANGED = "OnMessageScrollChanged",
    ON_MOVIE_FINISHED         = "OnMovieFinished", --func(self) - a movie frame's movie ends
    ON_MOVIE_SHOW_SUBTITLE    = "OnMovieShowSubtitle", --func(self, text) - Runs when a subtitle for the playing movie should be displayed
    ON_MOVIE_HIDE_SUBTITLE    = "OnMovieHideSubtitle", --func(self) - Runs when the movie's most recently displayed subtitle should be hidden
    ON_TOOLTIP_SET_DEFAULT_ANCHOR = "OnTooltipSetDefaultAnchor", --func(self) - the tooltip is repositioned to its default anchor location 
    ON_TOOLTIP_CLEARED        = "OnTooltipCleared", --func(self) - the tooltip is hidden or its content is cleared
    ON_TOOLTIP_ADD_MONEY      = "OnTooltipAddMoney", --func(self, cost, maxcost) - an amount of money should be added to the tooltip
    ON_TOOLTIP_SET_UNIT       = "OnTooltipSetUnit", --func(self) - the tooltip is filled with information about a unit
    ON_TOOLTIP_SET_ITEM       = "OnTooltipSetItem", --func(self) - the tooltip is filled with information about an item
    ON_TOOLTIP_SET_SPELL      = "OnTooltipSetSpell",
    ON_TOOLTIP_SET_QUEST      = "OnTooltipSetQuest", --func(self) - the tooltip is filled with information about a quest
    ON_TOOLTIP_SET_ACHIEVEMENT= "OnTooltipSetAchievement", --func(self) - the tooltip is filled with information about an achievement
    ON_TOOLTIP_SET_FRAMESTACK = "OnTooltipSetFramestack", --func(self, highlightFrame) - the tooltip is filled with a list of frames under the mouse cursor
    ON_TOOLTIP_SET_EQUIPMENT_SET = "OnTooltipSetEquipmentSet", --func(self) - the tooltip is filled with information about an equipment set 
    ON_ENABLE           = "OnEnable", --func(self) - frame is enabled.
    ON_DISABLE          = "OnDisable", --func(self) - frame is disabled.
    ON_ARROW_PRESSED    = "OnArrowPressed", --func(self, key)
    ON_EXTERNAL_LINK    = "OnExternalLink",
    ON_BUTTON_UPDATE    = "OnButtonUpdate",
    ON_ERROR            = "OnError",
    ON_DRESS_MODEL      = "OnDressModel", --func(self) - modelscene model is updated
    ON_COOLDOWN_DONE    = "OnCooldownDone", --func(self) - cooldown has finished
    ON_PAN_FINISHED     = "OnPanFinished", --func(self) - camera has finished panning
    ON_UI_MAP_CHANGED   = "OnUiMapChanged", --func(self, uiMapID)
    ON_REQUEST_NEW_SIZE = "OnRequestNewSize",
}

---@class FrameStrata
FrameStrata = {
    PARENT = "PARENT",
    BACKGROUND = "BACKGROUND",
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    DIALOG = "DIALOG",
    FULLSCREEN = "FULLSCREEN",
    FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
    TOOLTIP = "TOOLTIP",
    BLIZZARD = "BLIZZARD",
}

---@class Drawlayer
Drawlayer = {
    BACKGROUND = "BACKGROUND",
    BORDER = "BORDER",
    ARTWORK = "ARTWORK",
    OVERLAY = "OVERLAY",
    HIGHLIGHT = "HIGHLIGHT",
}

-- some useful regular expressions I used to reformat raw listings into the above code
-- REGEX 1
-- <xs:element name="([^"]*)".+
-- $1 = "$1",
-- REGEX 2
-- ^On([A-Z])([a-z]+)
-- ON_$1\U$2_
-- REGEX 2 continued
-- _([A-Z])([a-z]+)
-- _$1\U$2_
--  ([^ = "([^",
