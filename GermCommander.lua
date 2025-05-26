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

---@alias BtnSlotId number

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

--[[
local isAlreadyUpdatingAll
local throttleSecs = 2

function GermCommander:throttledUpdateAllSlots(eventId)
    if isAlreadyUpdatingAll then return end
    isAlreadyUpdatingAll = true
    C_Timer.After(throttleSecs, function(eventId)
        -- START FUNC
        isAlreadyUpdatingAll = nil
        self:updateAllSlots(eventId)
        -- END FUNC
    end)
end
]]

---@param flyoutId number
function flyLabel(flyoutId)
    return flyLabelNilOk(flyoutId) or "UnKnOwN fLyOuT"
end

function flyLabelNilOk(flyoutId)
    return FlyoutDefsDb:getName(flyoutId)
end

function isAlwaysTrue()
    return true
end

---@param func fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachGerm(func, event)
    self:forEachGermIf(func, isAlwaysTrue, event)
end

---@param func fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachActiveGerm(func, event)
    self:forEachGermIf(func, Germ.isActive, event)
end

---@param func fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachGermWithFlyoutId(flyoutId, func, event)
    local fun = function(germ)
        return germ:getFlyoutId() == flyoutId
    end
    self:forEachGermIf(func, fun, event)
end

---@param opFunction fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param fitnessFunc fun(germ:Germ) a function that will return true if the germ in question should be included in the operation
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachGermIf(opFunction, fitnessFunc, event)
    assert(isFunction(opFunction), 'must provide a "opFunction(Germ)" ')
    assert(isFunction(fitnessFunc), 'must provide a "fitnessFunc(Germ)" ')
    event = event or Event:new("oops!","last arg needs to be an event")
    for _, germ in pairs(germs) do
        if fitnessFunc(germ, event) then
            zebug.trace:event(event):owner(germ):line(8,"MATCH!")
            opFunction(germ, event)
        else
            zebug.trace:event(event):owner(germ):print("skipping because it failed the fitnessFunc()")
        end
    end
end

---@param func function(btnSlotIndex, flyoutId, eventId) will be invoked for every placement and get the btnSlotIndex & flyoutId for each one
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachPlacement(func, event)
    -- this is probably equivalent to forEachActiveGerm()
    local placements = Spec:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        func(btnSlotIndex, flyoutId, event)
    end
end

---@param flyoutId number
function GermCommander:updateGermsThatHaveFlyoutIdOf(flyoutId, event)
    -- TODO: refactor using forEachGermIf()
    --if isInCombatLockdown("Reconfiguring") then return end
    zebug.info:event(event):print("updating all Germs with",FlyoutDefsDb:get(flyoutId))

    self:forEachPlacement(function(btnSlotIndex, flyoutIdForGermInThisSlot)
        if flyoutIdForGermInThisSlot == flyoutId then
            local germ = self:recallGerm(btnSlotIndex)
            zebug.info:event(event):print("updating",germ, "in btnSlotIndex", btnSlotIndex)
            self:updateBtnSlot(btnSlotIndex, flyoutId, event)
        end
    end)
end

-- go through all placements saved in the DB.
-- I expect this will happen during
-- * addon initialization
-- * spec change
-- * maybe during zoning / player entering world ?
function GermCommander:updateAllSlots(event)
    zebug.trace:event(event):line(40, "hold on tight!")
    --if isInCombatLockdown("Reconfiguring") then return end

    -- closeAllGerms() -- this is only required because we sledge hammer all the germs every time. TODO don't do!

    zebug:setLowestAllowedSpeakingVolume(Zebug.INFO)
    self:forEachPlacement(function(btnSlotIndex, flyoutId)
        self:updateBtnSlot(btnSlotIndex, flyoutId, event)
    end)
    zebug:setLowestAllowedSpeakingVolumeBackToOriginal()



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


-- this can be used to update a slot that contains
-- * no germ
-- * an inactive germ
-- * an active germ which currently has a different flyoutId
---@param btnSlotIndex number
function GermCommander:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
    --if isInCombatLockdown("Reconfiguring") then return end

    if not flyoutId then
        local placements = Spec:getPlacementConfigForCurrentSpec()
        flyoutId = placements[btnSlotIndex]
    end

    local flyoutConf = FlyoutDefsDb:get(flyoutId)
    local germ = self:recallGerm(btnSlotIndex)
    local isEnabled = germ and germ:getFlyoutId()
    zebug.trace:event(eventId):line(5, "btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId, "flyoutConf", flyoutConf, "germ", germ)
    if flyoutConf then
        if not germ then
            -- create a new germ
            germ = Germ:new(flyoutId, btnSlotIndex, eventId)
            self:saveGerm(germ)
        end
        germ:update(flyoutId, eventId)
        germ:doKeybinding()
        if Config.opts.usePlaceHolders then
            if not Placeholder:isOnBtnSlot(btnSlotIndex, eventId) then
                Placeholder:put(btnSlotIndex, eventId)
            end
        end
    else
        -- because one toon can delete a flyout while other toons still have it on their bars
        -- also, this routine is invoked when the user deletes a UFO from the catalog
        zebug.warn:event(eventId):print("flyoutId",flyoutId, "no longer exists. Deleting it from action bar slot",btnSlotIndex)
        self:forgetPlacement(btnSlotIndex)
        if germ then
            germ:clearAndDisable(eventId)
        end
    end
end

function GermCommander:updateAllKeybindBehavior(event)
    if isInCombatLockdown("Keybind") then return end
    ---@param germ GERM_TYPE
    self:forEachActiveGerm(function(germ)
        germ:setMouseClickHandler(MouseClick.SIX, Config.opts.keybindBehavior or Config.optDefaults.keybindBehavior, event)
    end, event)
end

function GermCommander:updateAllActiveGermsWithConfigToBindTheButtons(event)
    local doKeybindTheButtonsOnTheFlyout = Config:get("doKeybindTheButtonsOnTheFlyout")

    ---@param germ Germ
    self:forEachActiveGerm(function(germ)
        germ:SetAttribute("doKeybindTheButtonsOnTheFlyout", doKeybindTheButtonsOnTheFlyout)
        germ:updateAllBtnHotKeyLabels(event)
    end, event)

end

---@param mouseClick MouseClick
function GermCommander:updateClickHandlerForAllActiveGerms(mouseClick, event)
    -- can't modify the inactive germs because they have no flyoutId
    ---@param germ Germ
    self:forEachActiveGerm(function(germ)
        germ:setMouseClickHandler(mouseClick, Config:getClickBehavior(self.flyoutId, mouseClick), event)
    end, event)
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
--- * a Ufo proxy for a new flyoutId than was there before this event - update the existing Germ with the new UFO config
--- * a Ufo Placeholder that we programmatically put there and should be ignored
function GermCommander:addOrRemoveSomeUfoDueToAnActionBarSlotChangedEvent(btnSlotIndex, event)
    local btnInSlot = BlizActionBarButton:new(btnSlotIndex, event) -- remove when debugging btnSlotIndex > 120
    if not btnInSlot then
        zebug.info:event(event):print("bullshit Bliz API reported a change to btnSlotIndex",btnSlotIndex)
        return
    end

    local savedFlyoutIdForSlot = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local germInSlot = self:recallGerm(btnSlotIndex)
    zebug.info:event(event):owner(btnInSlot):print("analyzing change to btnSlotIndex",btnSlotIndex, "config for slot", savedFlyoutIdForSlot, "existing germ", germInSlot)

    if btnInSlot:isEmpty() or btnInSlot:isUfoPlaceholder(event) then
        -- an empty slot or one with a Placeholder is meaningless to us.
        zebug.info:event(event):owner(btnInSlot):print("the btn slot is now empty/UfoPlaceholder and nobody cares")
    elseif btnInSlot:isUfoProxy() then
        -- user just dragged and dropped a UFO onto the bar.
        -- what was there before?
        local draggedAndDroppedFlyoutId = UfoProxy:getFlyoutId()
        zebug.info:event(event):owner(btnInSlot):print("user just dragged and dropped a UFO onto the bar. UfoProxy",UfoProxy)

        if savedFlyoutIdForSlot then
            -- there was already a germ there.
            -- was it the same one as was just dropped?
            if draggedAndDroppedFlyoutId == savedFlyoutIdForSlot then
                -- do absolutely nothing
                zebug.trace:event(event):owner(btnInSlot):print("The Ufo",UfoProxy, "was the same as the one already on the bar",germInSlot, "Nothing to do but exit.")
            else
                -- I don't think we can ever reach here.
                -- If there is a savedFlyoutIdForSlot there would also be an enabled germ in the slot.
                -- And if there is an enabled germ, it should have received the event and prevented the UfoProxy from reaching the action bar.
                -- user just dragged and dropped a different UFO than the one already/formerly there.
                -- save the new ID into the DB
                -- and reconfigure the existing germ
                -- was essentially self:updateBtnSlot(btnSlotIndex, eventId)

                assert(germInSlot, "config says there should already be a germ here but it's missing")
                zebug.trace:event(event):owner(btnInSlot):print("The Ufo",UfoProxy, "was dropped on an existing germ", germInSlot)
                germInSlot:changeFlyoutIdAndEnable(draggedAndDroppedFlyoutId, event)
            end
        else
            -- it's a UfoProxy but no savedFlyoutIdForSlot.
            -- the slot may have (1) an active germ, (2) an inactive one, (3) none at all.
            -- save the new ID into the DB
            -- and create a new germ or update the existing one
            local droppedFlyoutId = btnInSlot:getFlyoutIdFromUfoProxy()
            self:putUfoOntoActionBar(btnSlotIndex, droppedFlyoutId, event)
        end

        -- now that we are done with the UfoProxy it should be safe to synchronously nuke it
        UfoProxy:deleteProxyMacro(event)
    else
        -- a std Bliz thingy.
        -- altho, if that's true it would have been an event on the Germ itself.
        -- so this code may never be reached
        zebug.info:event(event):owner(btnInSlot):print("a std Bliz thingy. ERASE Ufo (if any)")
        self:eraseUfoFrom(btnInSlot, germInSlot, event)
    end
end

---@param btn number | BlizActionBarButton
---@param germ GERM_TYPE
function GermCommander:eraseUfoFrom(btn, germ, event)
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
    self:forgetPlacement(btnSlotIndex, event)
    if germ then
        germ:clearAndDisable(event)
    end
    Placeholder:clear(btnSlotIndex, event)
end

function GermCommander:savePlacement(btnSlotIndex, flyoutId, event)
    btnSlotIndex = tonumber(btnSlotIndex)
    flyoutId = FlyoutDefsDb:validateFlyoutId(flyoutId)
    zebug.info:event(event):print("btnSlotIndex",btnSlotIndex, "flyoutId",flyLabel(flyoutId))
    Spec:getPlacementConfigForCurrentSpec()[btnSlotIndex] = flyoutId
end

function GermCommander:forgetPlacement(btnSlotIndex, event)
    btnSlotIndex = tonumber(btnSlotIndex)
    --local flyoutId = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local placements = Spec:getPlacementConfigForCurrentSpec()
    local flyoutId = placements[btnSlotIndex]
    if flyoutId then
        zebug.info:event(event):print("DELETING PLACEMENT btnSlotIndex",btnSlotIndex, "flyoutId",flyoutId, "for", flyLabel(flyoutId))
        --zebug.trace:event(event):dumpy("BEFORE placements", placements)
        placements[btnSlotIndex] = nil
    end
end

function GermCommander:nukeGermsThatHaveFlyoutIdOf(flyoutId, event)
    self:forEachGermWithFlyoutId(flyoutId, function(germ)
        self:eraseUfoFrom(germ:getBtnSlotIndex(), germ, event)
    end, event)
    self:nukeFlyoutIdFromDb(flyoutId)
end

-- unused?  What does Catalog do when the user kills a Ufo?
function GermCommander:nukeFlyoutIdFromDb(flyoutId)
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
function GermCommander:dropDraggedUfoFromCursorOntoActionBar(btnSlotIndex, flyoutId, eventId)
    self:putUfoOntoActionBar(btnSlotIndex, flyoutId, eventId)
    --UfoProxy:deleteProxyMacro(eventId) -- um, what if the user swapped one UFO for another. Let the async event handler do this
end

function GermCommander:putUfoOntoActionBar(btnSlotIndex, flyoutId, event)
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    assert(flyoutDef, "no config exists for the specified flyoutId")

    self:savePlacement(btnSlotIndex, flyoutId, event)
    if Config.opts.usePlaceHolders then
        local clobberedBtnDef = Placeholder:put(btnSlotIndex, event)
        if UfoProxy:isOn(clobberedBtnDef) then
            zebug.info:event(event):print("clearing the re-picked-up UfoProxy from the cursor", clobberedBtnDef)
            Cursor:clear(event)
        end
    end
    local germ = self:recallGerm(btnSlotIndex)
    if not germ then
        germ = Germ:new(flyoutId, btnSlotIndex, event) -- this is expected to do everything required for a fully functioning germ
        germ:update(flyoutId, event) -- seemingly, Germ:new() didn't do enough
        self:saveGerm(germ)
    else
        germ:changeFlyoutIdAndEnable(flyoutId, event)
    end
end

function GermCommander:ensureAllGermsHavePlaceholders(event)
    Placeholder:createIfNotExists(event)
    Ufo.droppedPlaceholderOntoActionBar = event
    self:forEachPlacement(function(btnSlotIndex, flyoutId)
        Placeholder:put(btnSlotIndex, event)
    end)
    Ufo.droppedPlaceholderOntoActionBar = nil
end

---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:changeSpec_WORK_IN_PORGRESS(event)
    ---@type Placements
    local oldPlacements = Spec:getPlacementConfigForPreviousSpec()

    -- clear any germs that aren't being used in the new spec
    self:forEachActiveGerm(
        function(germ)
            if not oldPlacements[germ.btnSlotIndex] then
                germ:clearAndDisable(event)
            end
        end,
        event
    )

    -- TODO go through the new config and activate germs for each placement

end

---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:notifyAllGermsWithItems(event)
    ---@param germ GERM_TYPE
    local opFunc = function(germ)
        germ:getFlyoutDef():invalidateCache()
    end
    self:forEachGermIf(opFunc, Germ.hasItemsAndIsActive, event)
end

function GermCommander:handleEventPetChanged(event)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain pets
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAllSlots(event) -- change to updateSomeGerms(fitnessFunc)
end

function GermCommander:handleEventMacrosChanged(event)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain macros
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAllSlots(event) -- change to updateSomeGerms(fitnessFunc)
end
