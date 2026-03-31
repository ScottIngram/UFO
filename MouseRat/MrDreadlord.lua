---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole()
local zebug = MouseRat.zebug

-------------------------------------------------------------------------------
-- MrDreadlord
-- a proxy that will stand in for stuff not supported by WoW cursor or action bar buttons
-- but nonetheless let you drag it around on the cursor and maybe drop it someplace.
-- Prolly not a good idea to use it to represent stuff actually supported by WoW cursor or abbs.
-------------------------------------------------------------------------------

local HelperHelper = { } -- jumping through hoops due to lexical scoping
local pickupToCursorHelper = function(...) return HelperHelper.pickupToCursor(...) end -- we will define this below

---@class MrDreadlord : MouseRat -- make this globally accessable
MrDreadlord = {
    type       = MouseRatType.DREADLORD,
    --parentType = MouseRatType.MACRO, -- MouseRatRegistry:register() will create the OO inheritance -- TODO: use this line!
    cursorType = MouseRatType.MACRO,
    abbType    = MouseRatTypeForActionBarButton.MACRO,
    primaryKey = "id",
    macroVesselName = "Z-Dreadlord-UFO", -- subClasses can define their own macro name
    helpers = {
        -- these are only used by non-MouseRat victims
        getName = function(self) return self.macroVesselName end,
        isUsable = false,
        canThisToonPickup = true, -- that's the whole point of this class!  to pick it up!
        getIcon = 5333371,
        setToolTip = function() _G.GameTooltip:SetText("Dreadlord") end,
        pickupToCursor = pickupToCursorHelper,
    },
    passSelfForHelper = { pickupToCursor = true, getName=true } -- will tell MouseRat:helpMe() to pass the self obj into the HelperHelper.pickupToCursor
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

        -- remove all the Dreadlord helpers and instead defer to the original MouseRat
        -- except for pickupToCursor
        dreadlord.helpers = { pickupToCursor = pickupToCursorHelper }
        setmetatable(dreadlord.helpers, { __index = victim.helpers }) -- dl is now a perfect mimic of the victim

        dreadlord.getOriginalMouseRat = function() return victim end -- TODO: would be ok to NOT wrap it inside a method?
        setmetatable(dreadlord, { __index = victim }) -- dl is now a perfect mimic of the victim

        -- both of these should already be true by virtue of victim's metatable... unless... yeah, lua prolly doesn't check metatable lineage for toString
        dreadlord:installMyToString() -- assumes we are a descendant of UfoMixin

    else
        --zebug.warn:event():owner(self):dumpy("victim",victim)
        dreadlord = self:oneOfUs(victim, self.type)
    end

    zebug.info:event():owner(dreadlord):print("Mwuhahaha")

    currentDreadlord = dreadlord

    return dreadlord
end

function MrDreadlord:getCurrent()
    if currentDreadlord then
        return currentDreadlord
    end

    -- TODO - reconstitute from the macro ?
    return nil
end

local DREADLORD_SINGLETON
function MrDreadlord:getSingleton()
    if not DREADLORD_SINGLETON then
        DREADLORD_SINGLETON = deepcopy(MrDreadlord,{})
    end
    return DREADLORD_SINGLETON
end

-- because the "id" never changes, it's ok for this method to be "static" / "class"
-- this fucks up the victim
function MrDreadlord:getId()
    return getMacroIndexByNameOrReturnNil(self.macroVesselName)
end

function MrDreadlord:isThisMySpawn(type, c2, c3, c4)
    local isIt = (type == self.cursorType) and ((c2 == self.macroVesselName) or (c2 == self:getId())) -- c2 ShOuLd always be numeric, but this is Bliz we're talking about, so ima not taking any chances
    zebug.info:event():owner(self):print("comparing... type",type, "to self.cursorType",self.cursorType, "and comparing c2",c2,"to self.macroVesselName", self.macroVesselName, "OR self:getId()",self:getId(), "... So, isIt",isIt)
    return isIt
end

function MrDreadlord:_isThisActionBarSlotDataMyClass(abbType, id, subType)
    local isMe = (abbType == self.abbType) and ((id == self.macroVesselName) or (id == self:getId()))
    zebug.warn:event():owner(self):print("abbType",abbType, "id",id, "subType",subType, "isMe",isMe)
    return isMe
end

function MrDreadlord:_isThisActionBarSlotDataMyInstance(...)
    self:assertIsInstance()
    return self:_isThisActionBarSlotDataMyClass(...)
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
    return self:isThisMySpawn(type, macroId)
end

function MrDreadlord:disamButtonGator(abbType, macroId)
    return self:isThisMySpawn(abbType, macroId)
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
-- HelperHelper Methods
-- required because lexical scoping prevents me from defining this directly into MrDreadlord.helpers
-- satisfy the MouseRat Contract
-------------------------------------------------------------------------------

-- the whole point of a MrDreadlord is to pickup something that otherwise can't be picked up
-- including arbitrary whatevers but also legit MouseRats that for whatever reason the current toon can't.
-- jump through elaborate hoops to "trick" the wow client
function HelperHelper:pickupToCursor()

    ---@type MrDreadlord
    local self = self -- these lines are here purely to help my IDE understand what I'm doing.

    self:assertIsInstance()
    zebug.warn:event():owner(self):name("HelperHelper:pickupToCursor"):print("DREAD to pick me up!!!!")

    -- because a Dreadlord is a fake thing, we must create a real thing if we want to drag it around.
    local index = nil -- never(?) reuse the old macro -- self:getMacroVesselIndex()
    if not index then
        zebug.warn:event():owner(self):name("HelperHelper:pickupToCursor"):print("DREAD MAKING a macro")
        index = self:createOrEditMacroVessel()
        zebug.warn:event():owner(self):name("HelperHelper:pickupToCursor"):print("DREAD made a macro. index",index, "name",self.macroVesselName, "macro text", self.macroText)
    end

    if index then
        _G.PickupMacro(--[[self.macroVesselName or]] index)
    else
        error("couldn't create a macro for the ".. self.type)
    end

    return self
end

-------------------------------------------------------------------------------
-- Instance Methods - unique to MrDreadlord
-------------------------------------------------------------------------------

function MrDreadlord:areYouMe(you)
    -- TODO this isn't actually useful
    self:assertIsInstance()
    if you == nil then
        return false
    elseif you == self then
        return true
    end

    return (you.type == self.type) and (you.macroText == self.macroText) and (you.macroIndex == self.macroIndex)
end

-- set a semaphore so other code can decide to respond to the resulting UPDATE_MACROS event
-- or possibly an ACTIONBAR_SLOT_CHANGED event if the macro is on an action bar when it's modified
---@param msg string
function MrDreadlord:setEventSemaphore(msg)
--[[
    if Ufo.setEventSemaphore then
        Ufo:setEventSemaphore("thatWasMeThatDidThatMacro", Event:new(self, msg))
    end
]]
    Ufo.thatWasMeThatDidThatMacro = Event:new(self, msg)
    zebug.info:event():print("set SEMAPHORE Ufo.thatWasMeThatDidThatMacro as EVENT", Ufo.thatWasMeThatDidThatMacro)
end

function MrDreadlord:clearEventSemaphore()
    zebug.info:event():print("clear SEMAPHORE thatWasMeThatDidThatMacro")
    Ufo.thatWasMeThatDidThatMacro = nil
end


function MrDreadlord:deleteMacroVessel()
    self:setEventSemaphore("MrDreadlord:delete") -- tell any EVENT handlers what caused the following event
    _G.DeleteMacro(self.macroVesselName)
    self:clearEventSemaphore() -- WoW lua is synchronous, so, we know if we reach this line, all event handlers have finished with the above line
    if _G.MacroFrame and _G.MacroFrame:IsShown() then
        _G.MacroFrame:Update()
    end
end

function MrDreadlord:createOrEditMacroVessel()
    self:assertIsInstance()
    local verb
    local icon = self:getIcon()
    self:makeMacroText()
    local existingIndex = getMacroIndexByNameOrReturnNil(self.macroVesselName)
    if existingIndex then
        verb = "EDITTED"
        self.macroIndex = existingIndex
        zebug.info:event():owner(self):print("EDIT macro",existingIndex, "named",self.macroVesselName, "macro text", self.macroText)
        self:setEventSemaphore("MrDreadlord:edit")
        _G.EditMacro(existingIndex, self.macroVesselName, icon, self.macroText)
        self:clearEventSemaphore() -- WoW lua is synchronous, so, we know if we reach this line, all event handlers have finished with the above line
    else
        verb = "Created"
        zebug.info:event():owner(self):print("CREATE macro",existingIndex, "named",self.macroVesselName, "macro text", self.macroText)
        self:setEventSemaphore("MrDreadlord:create")
        self.macroIndex = _G.CreateMacro(self.macroVesselName, icon, self.macroText)
        self:clearEventSemaphore() -- WoW lua is synchronous, so, we know if we reach this line, all event handlers have finished with the above line
    end

    zebug.info:event():owner(self):print(verb,"the proxy macro.", "macroText",self.macroText,  "icon",icon, "index", self.macroIndex)
    return self.macroIndex
end

function MrDreadlord:makeMacroText()
    local result, myData

    if self.getOriginalMouseRat then
        myData = self:getOriginalMouseRat()
    else
        myData = self
    end

    if myData.serialize then
        result = myData:serialize()
    else
        result = sprintf([=[##%s:%s]=], self.type, serialize(myData, nil, true))
    end

    self:setPvar("macroText", result)
    return self.macroText
end

function MrDreadlord:getMacroText()
    zebug.info:event():print("self.macroText",self.macroText)
    if self.macroText then return self.macroText end
    local index = self:getMacroVesselIndex()
    self.macroText = _G.GetMacroBody(index)
    zebug.info:event():print("index",index, "macroText",self.macroText)
    return self.macroText
end


-------------------------------------------------------------------------------
-- REGISTER NOW!
-------------------------------------------------------------------------------

MouseRatRegistry:register(MrDreadlord)

