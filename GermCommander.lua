-- GermCommander
-- collects and manages instances of the Germ class which sit on the action bars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Zebug.TRACE)

---@class GermCommander -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field updatingAll boolean true when updateAllGerms() is making a LOT of noise
GermCommander = { }

---@class Placeholder
Placeholder = {}

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@type table<number,Germ|GERM_TYPE>
local germs = {}

-------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------

local function closeAllGerms()
    -- no longer used.
    exeOnceNotInCombat("GermCommander:closeAllGerms()", function()
        for btnSlotIndex, germ in pairs(germs) do
            germ:closeFlyout()
        end
    end)
end

local function doesFlyoutExist(flyoutId)
    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    return flyoutConf and true or false
end

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

local isAlreadyUpdatingAll
local throttleSecs = 2

function GermCommander:throttledUpdateAll(eventId)
    if isAlreadyUpdatingAll then return end
    isAlreadyUpdatingAll = true
    C_Timer.After(throttleSecs, function(eventId)
        -- START FUNC
        isAlreadyUpdatingAll = nil
        self:updateAll(eventId)
        -- END FUNC
    end)
end

---@param flyoutId number
function flyLabel(flyoutId)
    return flyLabelNilOk(flyoutId) or "UnKnOwN fLyOuT"
end

function flyLabelNilOk(flyoutId)
    return FlyoutDefsDb:getName(flyoutId)
end

---@param func function(btnSlotIndex, flyoutId) will be invoked for every placement and get the btnSlotIndex & flyoutId for each one
function GermCommander:forEach(func)
    local placements = Spec:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        func(btnSlotIndex, flyoutId)
    end
end

---@param flyoutId number
function GermCommander:updateGermsFor(flyoutId, eventId)
    if isInCombatLockdown("Reconfiguring") then return end
    zebug.info:label(eventId):print("updating all Germs with",flyoutId)

    self:forEach(function(btnSlotIndex, flyoutIdFoo)
        if flyoutIdFoo == flyoutId then
            local germ = self:recallGerm(btnSlotIndex)
            zebug.info:label(eventId):print("nuking",germ, "in btnSlotIndex", btnSlotIndex)
            self:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
        end
    end)

--[[
    local placements = Spec:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutIdFoo in pairs(placements) do
        if flyoutIdFoo == flyoutId then
            local germ = self:recallGerm(btnSlotIndex)
            zebug.info:label(eventId):print("nuking",germ, "in btnSlotIndex", btnSlotIndex)
            self:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
        end
    end
]]
end

function GermCommander:updateAll(eventId)
    zebug.trace:line(40, "eventId",eventId)
    --if isInCombatLockdown("Reconfiguring") then return end

    -- closeAllGerms() -- this is only required because we sledge hammer all the germs every time. TODO don't do!

    zebug:setNoiseLevel(Zebug.INFO)
    self:forEach(function(btnSlotIndex, flyoutId)
        self:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
    end)
    zebug:setNoiseLevelBackToOriginal()



--[[
    zebug:setNoiseLevel(Zebug.INFO)
    local placements = Spec:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        self:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
    end
    zebug:setNoiseLevelBackToOriginal()
]]
end

local originalZebug

-- momentarily calm down the debugging noise
---@param hush boolean
function GermCommander:beQuiet(hush)
    if hush then
        if not originalZebug then
            originalZebug = zebug
        end
        zebug = zebug.error
    else
        zebug = originalZebug
    end
end


---@param btnSlotIndex number
function GermCommander:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
    --if isInCombatLockdown("Reconfiguring") then return end

    if not flyoutId then
        local placements = Spec:getPlacementConfigForCurrentSpec()
        flyoutId = placements[btnSlotIndex]
    end

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local germ = self:recallGerm(btnSlotIndex)
    zebug.trace:label(eventId):line(5, "btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId, "flyoutConf", flyoutConf, "germ", germ)
    if flyoutConf then
        if not germ then
            -- create a new germ
            germ = Germ:new(flyoutId, btnSlotIndex, eventId)
            self:saveGerm(germ)
        end
        germ:update(flyoutId, eventId)
        germ:doKeybinding()
        if Config.opts.usePlaceHolders then
            if not Placeholder:exists(btnSlotIndex) then
                Placeholder:put(btnSlotIndex, eventId)
            end
        end
    else
        -- because one toon can delete a flyout while other toons still have it on their bars
        -- also, this routine is invoked when the user deletes a UFO from the catalog
        zebug.warn:label(eventId):print("flyoutId",flyoutId, "no longer exists. Deleting it from action bar slot",btnSlotIndex)
        self:deletePlacement(btnSlotIndex)
        if germ then
            germ:clear(eventId)
        end
    end
end

function GermCommander:updateAllKeybinds()
    if isInCombatLockdown("Keybind") then return end
    ---@param germ Germ
    for btnSlotIndex, germ in pairs(germs) do
        germ:clearKeybinding()
        germ:doKeybinding()
    end
end

function GermCommander:updateAllKeybindBehavior()
    if isInCombatLockdown("Keybind") then return end
    ---@param germ Germ
    for btnSlotIndex, germ in pairs(germs) do
        germ:setMouseClickHandler(MouseClick.SIX, Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior)
    end
end

function GermCommander:updateAllGermsWithButtonsWillBind()
    local doKeybindTheButtonsOnTheFlyout = Config:get("doKeybindTheButtonsOnTheFlyout")

    ---@param germ Germ
    for btnSlotIndex, germ in pairs(germs) do
        germ:SetAttribute("doKeybindTheButtonsOnTheFlyout", doKeybindTheButtonsOnTheFlyout)
        germ:updateAllBtnHotKeyLabels()
    end
end

--[[
-- not used
function GermCommander:updateAllGermsAllClickHandlers()
    ---@param germ Germ
    for btnSlotIndex, germ in pairs(germs) do
        zebug.info:label(germ):print("btnSlotIndex",btnSlotIndex, "germ", germ:getFlyoutDef().name)
        germ:setAllSecureClickScriptlettesBasedOnCurrentFlyoutId()
    end
end
]]

---@param mouseClick MouseClick
function GermCommander:updateClickHandlerForAllGerms(mouseClick)
    ---@param germ Germ
    for btnSlotIndex, germ in pairs(germs) do
        zebug.info:label(germ):print("btnSlotIndex",btnSlotIndex, "germ", germ:getFlyoutDef().name)
        germ:setMouseClickHandler(mouseClick, Config:getClickBehavior(self.flyoutId, mouseClick))
    end
end

---@return GERM_TYPE
function GermCommander:recallGerm(btnSlotIndex)
    return germs[btnSlotIndex]
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function GermCommander:saveGerm(germ)
    local btnSlotIndex = germ:getBtnSlotIndex()
    germs[btnSlotIndex] = germ
end

---@param obj number | GERM_TYPE
---@return GERM_TYPE
function GermCommander:rememberGerm(obj)
    local germ
    if UfoMixIn:isA(obj, Germ) then
        germ = obj
        local btnSlotIndex = germ:getBtnSlotIndex()
        germs[btnSlotIndex] = germ
    else
        germ = germs[obj]
    end
    return germ
end


-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- The altered slot could now be:
--- * empty - so we must clear any existing UFO that was there before
--- * a std Bliz thingy - ditto
--- * a Ufo proxy for the same flyoutId as before this event - NO ACTION REQUIRED
--- * a Ufo proxy for a new flyoutId as before this event - update the existing Germ with the new UFO config
--- * a Ufo Placeholder that we programmatically put there and should be ignored
function GermCommander:handleActionBarSlotChangedEvent(btnSlotIndex, eventId)

    local precludingEvent = Ufo.droppedPlaceholderOntoActionBar or Ufo.deletedPlaceholder
    if precludingEvent then
        -- we triggered this event ourselves elsewhere and don't need to do anything more
        zebug.info:label(eventId):print("SHORT-CIRCUIT - btnSlotIndex",btnSlotIndex, "has",btnInSlot, "was a result of previous event", precludingEvent)
        Ufo.droppedPlaceholderOntoActionBar = false
        return
    end

    local btnInSlot = BlizActionBarButton:new(btnSlotIndex, eventId) -- TODO fix bug where vehicle UI can be off the upper end of btnSlots and action bars
    local savedFlyoutIdForSlot = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local germInSlot = self:recallGerm(btnSlotIndex)

    zebug.info:label(eventId):print("what got dropped",btnInSlot, "config for slot", savedFlyoutIdForSlot, "existing germ", germInSlot)

    if btnInSlot:isEmpty() then
        -- the btn slot is now empty, so clear the Germ in that slot (if any)
        zebug.info:label(eventId):print("the btn slot is now empty, so clear the Germ in that slot (if any)")
        if germInSlot then
            self:eraseUfoFrom(btnInSlot, germInSlot, eventId)
        else
            -- no need to do anything.  there was nothing before.  there is nothing now.  nothing from nothing, carry the nothing...
        end
    elseif btnInSlot:isUfoProxy() then
        -- user just dragged and dropped a UFO onto the bar.
        -- what was there before?
        local draggedAndDroppedFlyoutId = UfoProxy:getFlyoutId()
        zebug.info:label(eventId):print("user just dragged and dropped a UFO onto the bar.",btnInSlot)

        if savedFlyoutIdForSlot then
            -- there was already a germ there.
            -- was it the same one as was just dropped?
            if draggedAndDroppedFlyoutId == savedFlyoutIdForSlot then
                -- do absolutely nothing
                zebug.trace:label(eventId):print("the dropped UFO was the same as the one already on the bar.  Nothing to do but exit.")
            else
                -- user just dragged and dropped a different UFO than the one already/formerly there.
                -- save the new ID into the DB
                -- and reconfigure the existing germ
                -- was essentially self:updateBtnSlot(btnSlotIndex, eventId)

                assert(germInSlot, "config says there should already be a germ here but it's missing")
                zebug.trace:label(eventId):print("The UFO was dropped on an existing germ", germInSlot)
                germInSlot:changeFlyoutId(draggedAndDroppedFlyoutId, eventId)
            end
        else
            -- is proxy but no savedFlyoutIdForSlot
            -- there is no germ already there
            -- save the new ID into the DB
            -- and create a new germ
            local droppedFlyoutId = btnInSlot:getFlyoutIdFromUfoProxy()
            print("droppedFlyoutId---->",droppedFlyoutId)
            self:putUfoOntoActionBar(btnSlotIndex, droppedFlyoutId, eventId)
        end
    else
        -- a std Bliz thingy.
        zebug.info:label(eventId):print("a std Bliz thingy. ERASE if any")
        self:eraseUfoFrom(btnInSlot, germInSlot, eventId)
    end








--[[
    if true then return end

    local typeOnBar, macroIdOnBar = GetActionInfo(btnSlotIndex)
    local droppedFlyoutId = UfoProxy:getFlyoutIdFromGermProxy(typeOnBar, macroIdOnBar)

    zebug.info:label(eventId):print("btn", btnInSlot, "btnSlotIndex",btnSlotIndex, "savedFlyoutIdForSlot", savedFlyoutIdForSlot, "typeOnBar", typeOnBar, "macroIdOnBar", macroIdOnBar)


    if droppedFlyoutId then
        self:dropUfoFromCursorOntoActionBar(btnSlotIndex, droppedFlyoutId, eventId)
        isConfigChanged = true
    end

    -- after dropping the flyout on the cursor, pickup the one we just replaced
    if savedFlyoutIdForSlot then
        UfoProxy:pickupUfoCursor(savedFlyoutIdForSlot, eventId)
        if not isConfigChanged then
            GermCommander:deletePlacement(btnSlotIndex)
            --configChanged = true
        end
    end

    if isConfigChanged then
        self:updateBtnSlot(btnSlotIndex, eventId)
    end
]]
end

--[[
function GermCommander:BROKEN_handleActionBarSlotChanged(btnSlotIndex)
    if Ufo.droppedPlaceholderOntoActionBar then
        -- we triggered this event ourselves elsewhere and don't need to do anything more
        Ufo.droppedPlaceholderOntoActionBar = false
        return
    end

    local configChanged
    local existingFlyoutId = getFlyoutIdForSlot(btnSlotIndex)
    local existingName = flyLabelNilOk(existingFlyoutId)
    local cursorId = self:getFlyoutIdFromCursor()
    local cursorName = flyLabelNilOk(cursorId)
    local type, macroId = GetCursorInfo()

    zebug.info:print("btnSlotIndex",btnSlotIndex, "existingFlyoutId",existingFlyoutId, "existingName",existingName,  "type",type, "macroId",macroId,  "cursorId",cursorId, "cursorName",cursorName)

    -- abort if empty cursor
    if not cursorId then
        zebug.info:dumpy("btnSlotIndex is empty - config For Spec ", Spec:getPlacementConfigForCurrentSpec())
        return
    end

    if isInCombatLockdownQuiet("GermCommander:handleActionBarSlotChanged - Ignoring event ACTIONBAR_SLOT_CHANGED because it") then return end

    self:dropUfoFromCursorOntoActionBar(btnSlotIndex, cursorId, eventId)
    configChanged = true

    -- after dropping the flyout from the cursor onto an action bar, pickup the one we just replaced
    if existingFlyoutId then
        self:copyFlyoutToCursor(existingFlyoutId, "BROKEN")
        if not configChanged then
            self:deletePlacement(btnSlotIndex)
            --configChanged = true
        end
    end

    if configChanged then
        self:updateBtnSlot(btnSlotIndex, "BROKEN")
    end
end
]]

---@param btn number | BlizActionBarButton
---@param germ GERM_TYPE
function GermCommander:eraseUfoFrom(btn, germ, eventId)
    local btnSlotIndex
    --print("BlizActionBarButton ------>",BlizActionBarButton)
    if UfoMixIn:isA(btn, BlizActionBarButton) then
        btnSlotIndex = btn:getBtnSlotIndex()
        --print("btn",btn, "btn:btnSlotIndex ---->",btnSlotIndex)
    else
        btnSlotIndex = btn
        --print("simple btnSlotIndex ---->",btnSlotIndex)
    end

    germ = germ or self:recallGerm(btnSlotIndex)
    self:deletePlacement(btnSlotIndex, eventId)
    if germ then
        germ:clear(eventId)
    end
    Placeholder:clear(btnSlotIndex, eventId)
end

function GermCommander:savePlacement(btnSlotIndex, flyoutId, eventId)
    btnSlotIndex = tonumber(btnSlotIndex)
    flyoutId = FlyoutDefsDb:validateFlyoutId(flyoutId)
    zebug.info:label(eventId):print("btnSlotIndex",btnSlotIndex, "flyoutId",flyLabel(flyoutId), "for event", eventId)
    Spec:getPlacementConfigForCurrentSpec()[btnSlotIndex] = flyoutId
end

function GermCommander:deletePlacement(btnSlotIndex, eventId)
    btnSlotIndex = tonumber(btnSlotIndex)
    --local flyoutId = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local placements = Spec:getPlacementConfigForCurrentSpec()
    local flyoutId = placements[btnSlotIndex]
    zebug.info:label(eventId):print("DELETING PLACEMENT", "btnSlotIndex",btnSlotIndex, "flyoutId", flyLabel(flyoutId), "for event", eventId)
    zebug.trace:label(eventId):dumpy("BEFORE placements", placements)
    -- the germ UI Frame stays in place but is now empty
    placements[btnSlotIndex] = nil
end

function GermCommander:nukeFlyout(flyoutId)
    flyoutId = FlyoutDefsDb:validateFlyoutId(flyoutId)
    for i, allSpecsConfig in ipairs(DB:getAllSpecsPlacementsConfig()) do
        for i, specConfig in ipairs(allSpecsConfig) do
            for btnSlotIndex, flyoutId2 in pairs(specConfig) do
                if flyoutId == flyoutId2 then
                    specConfig[btnSlotIndex] = nil
                end
            end
        end
    end
end

-- unused
---@param btnSlotIndex number
--[[
function GermCommander:createUfo(btnSlotIndex, flyoutId, eventId)
    if isInCombatLockdown("Creating a new UFO") then return end

    if not flyoutId then
        local placements = Spec:getPlacementConfigForCurrentSpec()
        flyoutId = placements[btnSlotIndex]
    end

    local doesFoExist = doesFlyoutExist(flyoutId)
    zebug.info:label(eventId):line(5, "btnSlotIndex",btnSlotIndex, "flyoutId",flyLabel(flyoutId), "doesFoExist", doesFoExist)
    if doesFoExist then
        local germ = self:recallGerm(btnSlotIndex)
        if not germ then
            -- create a new germ
            germ = Germ:new(flyoutId, btnSlotIndex, eventId)
            self:saveGerm(germ)
        end
        germ:update(flyoutId, eventId)
        germ:doKeybinding()
        if Config.opts.usePlaceHolders then
            if not Placeholder:exists(btnSlotIndex) then
                Placeholder:put(btnSlotIndex, eventId)
            end
        end
    else
        -- because one toon can delete a flyout while other toons still have it on their bars
        zebug.warn:label(eventId):print("flyoutId",flyoutId, "no longer exists. Deleting it from action bar slot",btnSlotIndex)
        self:deletePlacement(btnSlotIndex)
    end
end
]]

-- TODO HEY LOOK HERE!  we seem to be relying on a subsequent updateAll() or for a placeholder, handleActionBarSlotChanged()
-- invoked by Germ:OnPickupAndDrag() and GermCommander:handleActionBarSlotChanged()
-- by the time this is invoked
-- * there is a proxy macro freshly dropped on the action bar

-- Ways that will put a UFO onto the action bar
-- * addon initialization - all UFOs are newly created and placed based on SAVED_VARIABLES
-- * a UFO is on the cursor and is dropped onto an action bar slot that is empty
-- * a UFO is on the cursor and is dropped onto an action bar slot that contains a std bliz thingy
-- * a UFO is on the cursor and is dropped onto another UFO (maybe empty slot, maybe a slot with the placeholder macro)
-- in most of the above, there may be a Germ already there but is perhaps disabled because the user previously dragged it away
function GermCommander:dropUfoFromCursorOntoActionBar(btnSlotIndex, flyoutId, eventId)
    self:putUfoOntoActionBar(btnSlotIndex, flyoutId, eventId)
    UfoProxy:deleteProxyMacro(eventId) -- um, what if the user swapped one UFO for another
end

function GermCommander:putUfoOntoActionBar(btnSlotIndex, flyoutId, eventId)
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    assert(flyoutDef, "no config exists for the specified flyoutId")

    self:savePlacement(btnSlotIndex, flyoutId, eventId)
    if Config.opts.usePlaceHolders then
        Placeholder:put(btnSlotIndex, eventId)
    end
    local germ = self:recallGerm(btnSlotIndex)
    if not germ then
        germ = Germ:new(flyoutId, btnSlotIndex, eventId) -- this is expected to do everything required for a fully functioning germ
        self:saveGerm(germ)
    else
        germ:changeFlyoutId(flyoutId, eventId)
    end
end

function GermCommander:ensureAllGermsHavePlaceholders(eventId)
    Placeholder:create()
    Ufo.droppedPlaceholderOntoActionBar = eventId
    self:forEach(function(btnSlotIndex, flyoutId)
        Placeholder:put(btnSlotIndex, eventId)
    end)
    Ufo.droppedPlaceholderOntoActionBar = nil
end

function GermCommander:handleEventChangedInventory(eventId)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain inventory items
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAll(eventId)
end

function GermCommander:handleEventPetChanged(eventId)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain pets
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAll(eventId)
end

function GermCommander:handleEventMacrosChanged(eventId)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain macros
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAll(eventId)
end

-------------------------------------------------------------------------------
-- Placeholder class
-- a special macro that holds onto the action bar button slot for the Germ
-------------------------------------------------------------------------------

function Placeholder:create()
    Ufo.thatWasMeThatDidThatMacro = true
    local exists = GetMacroInfo(PLACEHOLDER_MACRO_NAME)
    if not exists then
        local icon = Ufo.iconTexture
        zebug.info:print("name",PLACEHOLDER_MACRO_NAME, "icon",icon, "PLACEHOLDER_MACRO_TEXT", PLACEHOLDER_MACRO_TEXT)
        CreateMacro(PLACEHOLDER_MACRO_NAME, icon, PLACEHOLDER_MACRO_TEXT)
    end
end

function Placeholder:pickup(eventId)
    self:create()
    Ufo.myPlaceholderSoDoNotDelete = true
    Cursor:pickupMacro(PLACEHOLDER_MACRO_NAME, eventId)
end

function Placeholder:put(btnSlotIndex, eventId)
    if not Config.opts.usePlaceHolders then return end

    Ufo.droppedPlaceholderOntoActionBar = eventId or true

    -- preserve the current contents of the cursor
    local crsDef = ButtonDef:getFromCursor()

    -- clobber anything on the cursor and replace it with the placeholder
    self:pickup(eventId)
    zebug.trace:label(eventId):print("btnSlotIndex",btnSlotIndex)
    Cursor:dropOntoActionBar(btnSlotIndex, eventId)

    -- yes? we're synchronous, yes?
    -- Ufo.droppedPlaceholderOntoActionBar = nil

    -- restore anything that had originally been on the cursor
    if crsDef then
        zebug.info:label(self):print("triggering updateAll()  eventId",eventId)
        crsDef:pickupToCursor()
        --GermCommander:updateAll(eventId.."+putPlaceholder()") -- draw the dropped UFO -- TODO: update ONLY the one specific germ
    end
end

function Placeholder:clear(btnSlotIndex, eventId)
    --if not Config.opts.usePlaceHolders then return end
    if not Placeholder:exists(btnSlotIndex) then return end
    Cursor:pickupFromActionBar(btnSlotIndex, eventId)
    Cursor:clear()
end

function Placeholder:exists(btnSlotIndex)
    local type, id = GetActionInfo(btnSlotIndex)
    zebug.trace:print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end

---@param btn BlizActionBarButton
function Placeholder:isOn(btn)
    if not btn then return end

    local type, id = btn:getType(), btn:getId()
    zebug.trace:print("type",type, "id",id)
    if type == ButtonType.MACRO then
        local name = GetMacroInfo(id)
        zebug.trace:print("name",name)
        return name == PLACEHOLDER_MACRO_NAME
    end
    return false
end


function Placeholder:nuke()
    while GetMacroInfo(PLACEHOLDER_MACRO_NAME) do
        DeleteMacro(PLACEHOLDER_MACRO_NAME)
    end
end
