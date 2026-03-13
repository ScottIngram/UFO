---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrMacro : MouseRat
local MrMacro = {
    type       = MouseRatType.MACRO,
    primaryKey = "macroId",
    helpers = {
        getName = C_Macro.GetMacroName, -- maybe GetMacroInfo
        pickupToCursor = PickupMacro,
        --getIcon = C_Macro.GetSelectedMacroIcon, -- replaced by getIcon() below
        --isUsable = ???, -- replaced by isUsable() defined below
        --setToolTip = ????, -- replaced by getToolTipSetter() below
    },
}

-------------------------------------------------------------------------------
-- Utility functions
-------------------------------------------------------------------------------

local function getIdForCurrentToon()
    local name = UnitFullName("player")
    local realm = GetRealmName() or "Irvine"
    return name.."-"..realm
end

-------------------------------------------------------------------------------
-- Instance Methods
-------------------------------------------------------------------------------

---@return number texture ID
function MrMacro:getIcon()
    if self:isUsable() then
        _, icon = GetMacroInfo(self.name or self.macroId) -- temp fix until I reintegrate MacroShitShow
    else
        icon = self.fallbackIcon or DEFAULT_ICON_FULL
    end
    return icon
end

function MrMacro:isGlobal()
    return self.macroId <= MAX_GLOBAL_MACRO_ID
end

function MrMacro:isUsable()
    self:assertIsInstance()
    zebug.info:owner("self"):event():print("macroId",self.macroId, "isGlobal",self:isGlobal(), "owner",self.macroOwner, "toon",getIdForCurrentToon())
    local isUsable = self:isGlobal() or (getIdForCurrentToon() == self.macroOwner)
    if not isUsable then
        local err = isUsable or (L10N.NOT_MACRO_OWNER .. " " .. (self.macroOwner or L10N.UNKNOWN))
        zebug.info:owner("self"):event():print("macroId",self.macroId, "isUsable",isUsable, "err", err)
    end
    return isUsable
end

function MrMacro:setToolTip()
    local name = self:getName()
    local text = "Macro: ".. (self.macroId or "nil") .." " .. (name or "UnKnOwN")
    if not self:isUsable() then
        text = "Toon " .. text .. " for " .. self.macroOwner
    end
    return _G.GameTooltip:SetText(text)
end

-- will the real macroId please stand up!
---@param type BlizCursorType the 1st arg from GetCursorInfo
---@param macroId number the 2nd arg from GetCursorInfo
function MrMacro:consumeGetCursorInfo(type, macroId)
    self:setId(macroId)
    if not self:isGlobal() then
        self.macroOwner = getIdForCurrentToon()
        self.fallbackIcon = self:getIcon()
    end
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrMacro)
