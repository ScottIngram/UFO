---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrFlyout : MouseRatSub
-- these are class fields and will not appear in instances
local MrFlyout = {
    type           = MouseRatType.FLYOUT,
    primaryKeyName = "spellId",
    pickerUpper    = C_Spell.PickupSpell,
    cursorConverter= function(type, _, _, spellId) return type, spellId  end
}

local Mr = MrFlyout



-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function Mr:init()
    -- would be called automatically by BtnDef:init()
    -- not sure what to do here
end

--[[
function Mr:newFromCursorData(type, foo, bar, zed)
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;

    MrFlyout:new(self.type)
end
]]

-------------------------------------------------------------------------------
-- Contracted Methods
-------------------------------------------------------------------------------

function Mr:getId()
    return self[self.primaryKeyName]
end


function Mr:setIdFromCursorData(type, _, _, spellId)
    self.id = spellId
    self.spellId = spellId
end

function Mr:getFromCursor(type, _, _, spellId)
    local type, c1, c2, c3 = GetCursorInfo() -- c1 is usually the ID; c2 is sometimes a tooltip;
    zebug.warn:event(event):owner(self):print("type",type, "c1",c1, "c2",c2, "c3",c3)

    local silenceWarnings = false
    local shhh = silenceWarnings and zebug.info or zebug.warn

    if not type then
        Ufo.pickedUpBtn = nil
        shhh:event(event):owner(self):print("Empty cursor is empty")
        return nil
    end

    if UfoProxy:isButtonOnCursor(type, c1, c2, c3) then
        shhh:event(event):owner(Ufo.pickedUpBtn):print("Ufo.pickedUpBtn")
        return Ufo.pickedUpBtn
    end

    local btnDef = BtnDef:new() -- this is nonsense
    btnDef.type = type
    btnDef.spellId = spellId

    if type == ButtonType.SPELL then
        btnDef.spellId = c3
    end

    if btnDef then
        if type then
            -- discovering the name requires knowing its type
            btnDef:getName()
        end

        if Ufo.pickedUpBtn then
            -- TODO: should this be done as part of receiveDrop instead?
            btnDef.noRnd = Ufo.pickedUpBtn.noRnd
        end
    end

    --Ufo.pickedUpBtn = nil -- we can't clear this here because "getFromCursor" doesn't necessarily mean "clearCursor" and we would still need this data

    return btnDef

end

function Mr:isUsable()
end

function Mr:getIcon()
end

function Mr:getName()
end

function Mr:getToolTipSetter()
end

function Mr:asSecureClickHandlerAttributes()
end


