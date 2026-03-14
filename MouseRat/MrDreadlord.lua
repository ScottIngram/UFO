---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = MouseRat.zebug

DREADLORD_VESSEL_NAME = "Z-Dreadlord"

-------------------------------------------------------------------------------
-- MrDreadlord
-- a proxy that will stand in for stuff not supported by WoW cursor or action bar buttons
-- but nonetheless let you drag it around on the cursor and maybe drop it someplace.
-- Prolly not a good idea to use it to represent stuff actually supported by WoW cursor or abbs.
-------------------------------------------------------------------------------

---@class MrDreadlord : MouseRat -- make this globally accessable
MrDreadlord = {
    type       = MouseRatType.DREADLORD,
    cursorType = MouseRatType.MACRO,
    primaryKey = "id",
    macroVesselName = DREADLORD_VESSEL_NAME,
    helpers = {
        -- these are only used by non-MouseRats victims
        getName = function() return DREADLORD_VESSEL_NAME end,
        isUsable = false,
        getIcon = 5333371,
        setToolTip = function() _G.GameTooltip:SetText("Dreadlord") end,
        -- pickupToCursor = PickupMacro, is defined below as pickupToCursorHelper()
    },
}

local currentDreadlord

-------------------------------------------------------------------------------
-- Class Methods -- operate as self = MrToy
-------------------------------------------------------------------------------

---@param victim table|MouseRat|nil optional table of arbitrary stuff, or, perhaps a different MouseRat
function MrDreadlord:new(victim)
    if victim == nil then
        victim = {}
    elseif not isTable(victim) then
        victim = { data = victim }
    end

    local dreadlord

    if (victim.ufoType == self.ufoType) and (victim.isInstance) then
        -- special case: this is already a MouseRat.
        -- inherit all of its existing behavior & data PLUS wrap it inside dreadlord magic
        zebug.info:event():owner(victim):print("wrapping inside Dreadlord")
        --zebug.warn:event():owner(victim):dumpy("victim",victim)

        dreadlord = deepcopy(MrDreadlord,{})
        dreadlord.primaryKey = nil
        dreadlord.getId = nil
        --zebug.warn:event():owner("proto-DL"):dumpy("proto-DL", dreadlord)
        -- remove all the Dreadlord helpers and instead defer to the original MouseRat
        -- except for pickupToCursor
        dreadlord.helpers = { pickupToCursor = function() dreadlord:pickupToCursorHelper() end }
        setmetatable(dreadlord.helpers, { __index = victim.helpers }) -- dl is now a perfect mimic of the victim

        dreadlord.getOriginalMouseRat = function() return victim end -- TODO: would be ok to NOT wrap it inside a method?
        setmetatable(dreadlord, { __index = victim }) -- dl is now a perfect mimic of the victim

        -- both of these should already be true by virtue of victim's metatable... unless... yeah, lua prolly doesn't check metatable lineage for toString
        dreadlord:installMyToString() -- assumes we are a descendant of UfoMixin

    else
        --zebug.warn:event():owner(self):dumpy("victim",victim)
        victim.type = self.type
        dreadlord = self:oneOfUs(victim)
    end

    zebug.info:event():owner(dreadlord):print("Mwuhahaha")

    return dreadlord
end

-- because the "id" never changes, it's ok for this method to be "static" / "class"
-- this fucks up the victim
function MrDreadlord:getId()
    return self.macroId or getMacroIndexByNameOrReturnNil(self.macroVesselName)
end

function MrDreadlord:isThisMySpawn(type, c2, c3, c4)
    return (type == self.cursorType) and ((c2 == DREADLORD_VESSEL_NAME) or (c2 == getMacroIndexByNameOrReturnNil(DREADLORD_VESSEL_NAME)))
end

function MrDreadlord:getMacroVesselIndex()
    local index = getMacroIndexByNameOrReturnNil(self.macroVesselName)
    zebug.info:event():owner(self):print("self.macroVesselName",self.macroVesselName, "getMacroIndexByNameOrReturnNil",index)
    return index
end

-- examines the results of _G.GetCursorInfo() and decides if those results describe a Toy
---@param type MouseRatType must be MouseRatType.SPELL
---@param macroId any could be an itemId
---@return boolean true if the data implies this class
function MrDreadlord:disambiguator(type, macroId)
    zebug.warn:event():print("type", type, "macroId", macroId, "my ID",self:getId())
    if type ~= self.cursorType then return false end

    local maybeId = self:getId()
    zebug.warn:event():print("2 type", type, "macroId", macroId, "my ID",self:getId())
    if maybeId and (maybeId == macroId) then return true end

    --local maybeMe = self:getMostRecentlyPickedUpMr()
    --zebug.warn:event():print("3 type", type, "macroId", macroId, "my ID",self:getId(), "maybeMe",maybeMe, "maybeMe:getId()",maybeMe and maybeMe:getId())
    --if maybeMe and (maybeMe:getId() == macroId) then return true end

    return false
end

-------------------------------------------------------------------------------
-- Utility functions
-------------------------------------------------------------------------------

function getMacroIndexByNameOrReturnNil(name)
    local index = GetMacroIndexByName(name) -- omfg, BLiz.  Returns 0 not nil if the macro does not exist. JFC
    local exists = index and index > 0
    return exists and index or nil
end

-------------------------------------------------------------------------------
-- Instance Methods for MouseRat Contract
-------------------------------------------------------------------------------

-- the whole point of a MrDreadlord is to pickup something that otherwise can't be pickedup
-- including arbitrary whatevers but also legit MouseRats that for whatever reason the current toon can't.
-- jump through elaborate hoops to "trick" the wow client
function MrDreadlord:pickupToCursorHelper()
    self:assertIsInstance()
    zebug.warn:event():owner(self):print("DREAD to pick me up!!!!")

    -- because a Dreadlord is a fake thing, we must create a real thing if we want to drag it around.
    local index = nil -- never(?) reuse the old macro -- self:getMacroVesselIndex()
    if not index then
        zebug.warn:event():owner(self):print("DREAD MAKING a macro")
        index = self:makeMacroVessel()
        zebug.warn:event():owner(self):print("DREAD made a macro. index",index, "name",self.macroVesselName, "macro text", self.macroText)
    end

    if index then
        PickupMacro(--[[self.macroVesselName or]] index)
    else
        error("couldn't create a macro for the ".. self.type)
    end

    return self
end

MrDreadlord.helpers.pickupToCursor = MrDreadlord.pickupToCursorHelper

-------------------------------------------------------------------------------
-- Instance Methods - unique to MrDreadlord
-------------------------------------------------------------------------------

function MrDreadlord:areYouMe(you)
    self:assertIsInstance()
    if you == nil then
        return false
    elseif you == self then
        return true
    end

    return (you.type == self.type) and (you.macroText == self.macroText) and (you.macroIndex == self.macroIndex)
end

function MrDreadlord:makeMacroVessel()
    self:assertIsInstance()
    local verb
    local icon = self:getIcon()
    self.macroText = self.macroText or self:makeMacroText()
    local existingIndex = getMacroIndexByNameOrReturnNil(self.macroVesselName)
    if existingIndex then
        verb = "EDITTED"
        self.macroIndex = existingIndex
        EditMacro(existingIndex, self.macroVesselName, icon, self.macroText)
    else
        verb = "Created"
        self.macroIndex = CreateMacro(self.macroVesselName, icon, self.macroText)
    end

    zebug.info:event():owner(self):print(verb,"the proxy macro.", "macroText",self.macroText,  "icon",icon, "index", self.macroIndex)
    return self.macroIndex
end

function MrDreadlord:makeMacroText()
    if self.macroText then return self.macroText end

    local myData
    if self.getOriginalMouseRat then
        myData = self:getOriginalMouseRat()
    else
        myData = self
    end

    local data = (self.getOriginalMouseRat and self:getOriginalMouseRat()) or self
    self.macroText = sprintf([=[##%s:%s]=], self.type, serialize(data, nil, true))
    return self.macroText
end

-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrDreadlord)

