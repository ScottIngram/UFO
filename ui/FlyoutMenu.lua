-- FlyoutMenu
-- methods and functions for flyout creation, behavior, etc

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local debug = Debug:new()

---@class FlyoutMenu -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field id number
---@field isForGerm boolean
---@field isForCatalog boolean
local FlyoutMenu = {
    ufoType = "FlyoutMenu",
    isForGerm = false,
    isForCatalog = false,
}
Ufo.FlyoutMenu = FlyoutMenu

-------------------------------------------------------------------------------
-- Functions / Methods
-------------------------------------------------------------------------------

-- coerce the incoming table into a FlyoutMenu instance
---@return FlyoutMenu
function FlyoutMenu:oneOfUs(fomu)
    -- merge the Bliz ActionButton object
    -- with this class's methods, functions, etc
    return deepcopy(self, fomu)
end

---@return ButtonOnFlyoutMenu
function FlyoutMenu:getButtonFrame(i)
    return _G[ self:GetName().."Button"..i ]
end

function FlyoutMenu:forEachButton(handler)
    for i, button in ipairs({self:GetChildren()}) do
        if button:GetObjectType() == "CheckButton" then
            handler(button)
        end
    end
end

function FlyoutMenu:initializeOnClickHandlersForFlyouts()
    UIUFO_FlyoutMenuForGerm:forEachButton(function(button)
        SecureHandlerWrapScript(button, "OnClick", button, "self:GetParent():Hide()")
    end)
    UIUFO_FlyoutMenuForCatalog.isForCatalog = true
end

function FlyoutMenu:getId()
    return self.id or self.flyoutId
end

function FlyoutMenu:setId(flyoutId)
    self.id = tonumber(flyoutId)
    self.flyoutId = tonumber(flyoutId)
end

function FlyoutMenu:ensureId(flyoutId)
    if self == FlyoutMenu then
        assert(flyoutId, ADDON_NAME..": You must provide the flyoutId when invoking this as a CLASS method.")
    else
        flyoutId = self:getId()
        assert(flyoutId, ADDON_NAME..": This FlyoutMenu has not been assigned an id / flyoutId.")
    end
    return flyoutId
end

-- when the user picks up a flyout from the catalog (or a germ from the actionbars?)
-- we need a draggable UI element, so create a dummy macro with the same icon as the flyout
function FlyoutMenu:pickup(flyoutId)
    if isInCombatLockdown("Drag and drop") then return; end

    flyoutId = self:ensureId(flyoutId)

    local flyoutConf = FlyoutMenusDb:get(flyoutId)
    local icon = flyoutConf:getIcon()
    local proxy = GermCommander:newGermProxy(flyoutId, icon)
    PickupMacro(proxy)
end

---@return FlyoutMenuDef
function FlyoutMenu:getDef(flyoutId)
    flyoutId = self:ensureId(flyoutId)
    return FlyoutMenusDb:get(flyoutId)
end

-- TODO: merge updateForCatalog() and updateForGerm()
function FlyoutMenu:updateForCatalog(flyoutId)
    self:setId(flyoutId)
    self.direction = "RIGHT"

    local prevButton = nil;
    local numButtons = 0;
    local flyoutDef = self:getDef()
    local n = flyoutDef:howManyButtons()
    local rows = n+1 -- one extra for an empty space

    for i=1, math.min(rows, MAX_FLYOUT_SIZE) do
        local btnFrame = self:getButtonFrame(i)
        local btnDef = flyoutDef:getButtonDef(i)
        if btnDef then
            btnFrame:setDef(btnDef)
            btnFrame:setIconTexture( btnDef:getIcon() ) -- TODO: do this automatically as part of setDef() ?
        else
            -- the empty slot on the end
            btnFrame:setDef(nil)
            btnFrame:setIconTexture(nil)
        end

        btnFrame:updateCooldownsAndCountsAndStatesEtc()
        btnFrame:setGeometry(self.direction, prevButton)

        prevButton = btnFrame
        numButtons = i
    end

    -- Hide unused buttons
    local unusedButtonIndex = numButtons+1
    local btnFrame = self:getButtonFrame(unusedButtonIndex)
    while btnFrame do
        btnFrame:Hide()
        unusedButtonIndex = unusedButtonIndex+1
        btnFrame = self:getButtonFrame(unusedButtonIndex)
    end

    if numButtons == 0 then
        self:Hide()
        return
    end

    self:ClearAllPoints()
    self:SetFrameStrata("DIALOG")
    self:setGeometry()

    if self.direction == "UP" or self.direction == "DOWN" then
        self:SetWidth(prevButton:GetWidth())
        self:SetHeight((prevButton:GetHeight()+SPELLFLYOUT_DEFAULT_SPACING) * numButtons - SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)
    else
        self:SetHeight(prevButton:GetHeight())
        self:SetWidth((prevButton:GetWidth()+SPELLFLYOUT_DEFAULT_SPACING) * numButtons - SPELLFLYOUT_DEFAULT_SPACING + SPELLFLYOUT_INITIAL_SPACING + SPELLFLYOUT_FINAL_SPACING)
    end
end

---@param germ Germ
function FlyoutMenu:updateForGerm(germ, whichMouseButton, down)
    --[[DEBUG]] debug.trace:setHeader("~","FlyoutMenu:updateForGerm()")

    germ:SetChecked(not germ:GetChecked())

    local flyoutId = germ:getFlyoutId()
    self:setId(flyoutId)
    local flyoutDef = self:getDef(flyoutId)
    local buttonFrames = { self:GetChildren() }
    local firstThing = table.remove(buttonFrames, 1) -- TODO: what is this?
     --[[DEBUG]] debug.trace:line(3,"firstThing", firstThing)
     --[[DEBUG]] debug.trace:dump(firstThing)

    local flyoutId = flyoutDef
    self:setId(flyoutId)

    ---@param btnFrame ButtonOnFlyoutMenu
    for i, btnFrame in ipairs(buttonFrames) do
        if btnFrame.ignoreInlayout then
            -- this is prolly the contents of firstThing
             --[[DEBUG]] debug.trace:line(3, "btnFrame.ignoreInlayout",btnFrame.ignoreInlayout)
             --[[DEBUG]] debug.trace:dump(btnFrame)
        end

        local btnDef = flyoutDef:getButtonDef(i)
        btnFrame:setDef(btnDef)
        --[[DEBUG]] debug.trace:line(3, "i",i, "btnDef", btnDef)

        if btnDef then
            --[[DEBUG]] debug.trace:line(5, "i",i, "spellId",btnDef.spellId, "type", btnDef.type)
            btnFrame:setIconTexture( btnDef:getIcon() )
            btnFrame:setGeometry(self.direction)
        end
        btnFrame:updateCooldownsAndCountsAndStatesEtc()
    end

    self:setGeometry()
end

function FlyoutMenu:setGeometry()
    local distance = 3

    self:SetBorderColor(0.7, 0.7, 0.7);
    self:SetBorderSize(47);

    self.Background.End:ClearAllPoints()
    self.Background.Start:ClearAllPoints()
    self.Background.VerticalMiddle:ClearAllPoints()
    self.Background.HorizontalMiddle:ClearAllPoints()

    if (self.direction == "UP") then
        self:SetPoint("BOTTOM", self.parent, "TOP");
        self.Background.End:SetPoint("TOP", 0, SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(self.Background.End, 0);
        SetClampedTextureRotation(self.Background.VerticalMiddle, 0);
        self.Background.Start:SetPoint("TOP", self.Background.VerticalMiddle, "BOTTOM");
        SetClampedTextureRotation(self.Background.Start, 0);
        self.Background.HorizontalMiddle:Hide();
        self.Background.VerticalMiddle:Show();
        self.Background.VerticalMiddle:ClearAllPoints();
        self.Background.VerticalMiddle:SetPoint("TOP", self.Background.End, "BOTTOM");
        self.Background.VerticalMiddle:SetPoint("BOTTOM", 0, distance);
    elseif (self.direction == "DOWN") then
        self:SetPoint("TOP", self.parent, "BOTTOM");
        self.Background.End:SetPoint("BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING);
        SetClampedTextureRotation(self.Background.End, 180);
        SetClampedTextureRotation(self.Background.VerticalMiddle, 180);
        self.Background.Start:SetPoint("BOTTOM", self.Background.VerticalMiddle, "TOP");
        SetClampedTextureRotation(self.Background.Start, 180);
        self.Background.HorizontalMiddle:Hide();
        self.Background.VerticalMiddle:Show();
        self.Background.VerticalMiddle:ClearAllPoints();
        self.Background.VerticalMiddle:SetPoint("BOTTOM", self.Background.End, "TOP");
        self.Background.VerticalMiddle:SetPoint("TOP", 0, -distance);
    elseif (self.direction == "LEFT") then
        self:SetPoint("RIGHT", self.parent, "LEFT");
        self.Background.End:SetPoint("LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(self.Background.End, 270);
        SetClampedTextureRotation(self.Background.HorizontalMiddle, 180);
        self.Background.Start:SetPoint("LEFT", self.Background.HorizontalMiddle, "RIGHT");
        SetClampedTextureRotation(self.Background.Start, 270);
        self.Background.VerticalMiddle:Hide();
        self.Background.HorizontalMiddle:Show();
        self.Background.HorizontalMiddle:ClearAllPoints();
        self.Background.HorizontalMiddle:SetPoint("LEFT", self.Background.End, "RIGHT");
        self.Background.HorizontalMiddle:SetPoint("RIGHT", -distance, 0);
    elseif (self.direction == "RIGHT") then
        self:SetPoint("LEFT", self.parent, "RIGHT");
        self.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0);
        SetClampedTextureRotation(self.Background.End, 90);
        SetClampedTextureRotation(self.Background.HorizontalMiddle, 0);
        self.Background.Start:SetPoint("RIGHT", self.Background.HorizontalMiddle, "LEFT");
        SetClampedTextureRotation(self.Background.Start, 90);
        self.Background.VerticalMiddle:Hide();
        self.Background.HorizontalMiddle:Show();
        self.Background.HorizontalMiddle:ClearAllPoints();
        self.Background.HorizontalMiddle:SetPoint("RIGHT", self.Background.End, "LEFT");
        self.Background.HorizontalMiddle:SetPoint("LEFT", distance, 0);
    end
end

-------------------------------------------------------------------------------
-- GLOBAL Functions Supporting FlyoutMenu XML Callbacks
-------------------------------------------------------------------------------

---@param flyoutMenu FlyoutMenu
function GLOBAL_UIUFO_FlyoutMenuForGerm_OnLoad(flyoutMenu)
    -- call Blizzard handler
    SpellFlyout_OnLoad(flyoutMenu)

    -- initialize fields
    FlyoutMenu:oneOfUs(flyoutMenu)
    Germ.flyoutMenu = flyoutMenu
    flyoutMenu.isForGerm = true
end

---@param flyoutMenu FlyoutMenu
function GLOBAL_UIUFO_FlyoutMenuForCatalog_OnLoad(flyoutMenu)
    -- call Blizzard handler
    SpellFlyout_OnLoad(flyoutMenu)

    -- initialize fields
    FlyoutMenu:oneOfUs(flyoutMenu)
    flyoutMenu.isForCatalog = true
end

-- TODO: should I put the  RegisterEvent() calls back in?
---@param flyoutMenu FlyoutMenu
function GLOBAL_UIUFO_FlyoutMenuForGerm_OnShow(flyoutMenu)
    debug.trace:out("/",20,"GLOBAL_UIUFO_FlyoutMenuForGerm_OnShow")
    SpellFlyout_OnShow(flyoutMenu) -- call Blizzard handler

    -- TODO: the below probably aren't needed anymore
    --flyoutMenu:RegisterEvent("BAG_UPDATE_COOLDOWN"); -- to support items
    --flyoutMenu:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- to support items

    ---@param btn ButtonOnFlyoutMenu -- IntelliJ-EmmyLua annotation
    flyoutMenu:forEachButton(function(btn)
        --debug.trace:out("~",40, "btn updatery from FlyoutMenu:OnShow()")
        btn:updateCooldownsAndCountsAndStatesEtc()
    end)

end

function GLOBAL_UIUFO_FlyoutMenuForGerm_OnHide(self)
    SpellFlyout_OnHide(self) -- call Blizzard handler
    if (self.eventsRegistered == true) then
        --self:UnregisterEvent("BAG_UPDATE_COOLDOWN"); -- to support items
        --self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- to support items
    end
end
