---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()

---@class MrFlyout : MouseRat
local MrFlyout = {
    type       = MouseRatType.FLYOUT,
    primaryKey = "flyoutId", -- 2nd return value of _G.GetCursorInfo()
    --getName_helper = GetFlyoutInfo, -- initialized by consumeGetCursorInfo() and used by MouseRat:getName()
    --getIcon_helper = xxx, -- no such api. see getIcon() below
    --pickupToCursor_helper = xxx, -- no such api. see pickupToCursor() below
    --setToolTip_helper = xxx, -- no such api. see setToolTip() below,
    --isUsable_helper = xxx, -- implemented isUsable()
}

-- TODO: why does leaving out this line result in failure to find
-- getIcon, isUsable, pickupToCursor, and setToolTip
MouseRat:mixInto(MrFlyout)

-------------------------------------------------------------------------------
-- Instance Methods -- operate as self = {} with its metatable linked to MrToy
-------------------------------------------------------------------------------

function MrFlyout:setToolTip()
    local name = self:getName()
    local text = (name or "UnKnOwN") .. " " .. (self.description or "")
    return _G.GameTooltip:SetText(text)
end

---@param flyoutId number will the real flyoutId please stand up!
---@param dunno any no documentation to be found
function MrFlyout:consumeGetCursorInfo(type, flyoutId, dunno)
    zebug.error:print("type, flyoutId, dunno",type, flyoutId, dunno)
    local name, description, numSlots, isKnown = _G.GetFlyoutInfo(flyoutId)
    self:setId(flyoutId)
    self.name = name
    self:setPvar("description",description)
    self:setPvar("numSlots",numSlots)
    self:setPvar("isKnown",isKnown) -- do not persist, but, hang onto it for use by
end

-- because Bliz didn't include icon in the results of GetFlyoutInfo(), jump through ridiculous hoops
---@return number texture Id
function MrFlyout:getIcon()
    if self.icon then return self.icon end

    local spells = self:getSpells()
    if not spells then
        self.icon = DEFAULT_ICON_FULL
    else
        -- DevTools_Dump( C_SpellBook.GetSpellBookItemInfo( C_SpellBook.FindSpellBookSlotForSpell(460905) ) )
        local firstSpellInfo = spells[1]
        local spellId = firstSpellInfo.spellId
        --local spellOneIcon = C_Spell.GetSpellTexture(spellId)
        local spellBookSlot = C_SpellBook.FindSpellBookSlotForSpell(spellId)
        --zebug.error:print("spellId",spellId, "spellBookSlot",spellBookSlot, "isNumber",isNumber(spellBookSlot))
        local foo = C_SpellBook.GetSpellBookItemInfo(spellBookSlot, Enum.SpellBookSpellBank.Player)
        if not foo then
            foo = C_SpellBook.GetSpellBookItemInfo(spellBookSlot, Enum.SpellBookSpellBank.Pet)
        end
        self.icon = foo.iconID

        local flyoutId = foo.actionID
        if flyoutId ~= self.flyoutId then
            zebug.warn:print("OOPS!  the convoluted hoops moved from flyoutId",self.flyoutId, "to",flyoutId)
        end
    end

    -- jeezus, I can't believe all of that actually worked.  smfh

    return self.icon
end

---@return table<number,number> array of spellIds
function MrFlyout:getSpells()
    if self.spells then return self.spells end
    if self.numSlots < 1 then return nil end

    local spells = {}

    for i = 1, self.numSlots do
        local spellId, overrideSpellId, isKnown, name, slotSpecId = GetFlyoutSlotInfo(self.flyoutId, i)
        if isKnown then
            spells[#spells+1] = {
                type = self.type,
                spellId = spellId,
                name = name,
                overrideSpellId = overrideSpellId,
            }
        end
    end

    self:setPvar("spells",spells)

    return spells
end

function MrFlyout:pickupToCursor()
    -- Bliz provides no API to programmatically pickup a flyout (unless it is already on your actionbar)
    -- TODO: implement via fancy macro proxy magic
    -- see ButtonOnFlyoutMenu:abortIfUnusable() for an example of the limitations
end

function MrFlyout:isUsable()
    --local _, _, _, isKnown = _G.GetFlyoutInfo(self.flyoutId)
    return self.isKnown -- initialized on the fly.  not persisted
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrFlyout)
