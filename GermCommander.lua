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

---@param flyoutId number
function flyLabel(flyoutId)
    return flyLabelNilOk(flyoutId) or "UnKnOwN fLyOuT"
end

function flyLabelNilOk(flyoutId)
    return FlyoutDefsDb:getName(flyoutId)
end

---@param func function(germ, eventId) will be invoked for every existing "active" germ and get the germ for each one
function GermCommander:forEachGerm(func, eventId)
    for _, germ in pairs(germs) do
        if germ:isActive() then
            func(germ, eventId)
        end
    end
end

---@param func function(btnSlotIndex, flyoutId, eventId) will be invoked for every placement and get the btnSlotIndex & flyoutId for each one
function GermCommander:forEachPlacement(func, eventId)
    local placements = Spec:getPlacementConfigForCurrentSpec()
    for btnSlotIndex, flyoutId in pairs(placements) do
        func(btnSlotIndex, flyoutId, eventId)
    end
end

---@param flyoutId number
function GermCommander:updateGermsFor(flyoutId, eventId)
    if isInCombatLockdown("Reconfiguring") then return end
    zebug.info:event(eventId):print("updating all Germs with",flyoutId)

    self:forEachPlacement(function(btnSlotIndex, flyoutIdForGermInThisSlot)
        if flyoutIdForGermInThisSlot == flyoutId then
            local germ = self:recallGerm(btnSlotIndex)
            zebug.info:event(eventId):print("nuking",germ, "in btnSlotIndex", btnSlotIndex)
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

local function isAlwaysTrue()
    return true
end

function GermCommander:updateAllGerms(eventId)
    return self:updateSomeGerms(isAlwaysTrue, eventId)
end

-- go through all existing germs
---@param fitnessFunc function(Germ) a func that will return true if the germ in question should be included in the operation
function GermCommander:updateSomeGerms(fitnessFunc, eventId)
    assert(fitnessFunc, 'must provide a "fitnessFunc(germ)" ')

    zebug:setLowestAllowedSpeakingVolume(Zebug.INFO)
    ---@param germ GERM_TYPE
    self:forEachGerm(function(germ)
        if fitnessFunc(germ) then
            germ:update()
            self:updateBtnSlot(btnSlotIndex, flyoutId, eventId)
        else
            zebug.trace:event(eventId):print("skipping",germ, "because it failed fitnessFunc()")
        end
    end)
    zebug:setLowestAllowedSpeakingVolumeBackToOriginal()
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
        zebug.info:owner(germ):print("btnSlotIndex",btnSlotIndex, "germ", germ:getFlyoutDef().name)
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

-- TODO: refactor GermCommander / Germ so that Germ directly handles the event. GermCommander only instantiates new germs and pokes it to handle the event
-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- The altered slot could now be:
--- * empty - so we must clear any existing UFO that was there before
--- * a std Bliz thingy - ditto
--- * a Ufo proxy for the same flyoutId as before this event - NO ACTION REQUIRED
--- * a Ufo proxy for a new flyoutId as before this event - update the existing Germ with the new UFO config
--- * a Ufo Placeholder that we programmatically put there and should be ignored
function GermCommander:handleActionBarSlotChangedEvent(btnSlotIndex, event)
    local btnInSlot = BlizActionBarButton:new(btnSlotIndex, event) -- remove when debugging btnSlotIndex > 120
    if not btnInSlot then
        zebug.info:event(event):print("bullshit Bliz API reported a change to btnSlotIndex",btnSlotIndex)
        return
    end

    local savedFlyoutIdForSlot = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local germInSlot = self:recallGerm(btnSlotIndex)
    zebug.info:event(event):owner(btnInSlot):print("analyzing change to btnSlotIndex",btnSlotIndex, "config for slot", savedFlyoutIdForSlot, "existing germ", germInSlot)


    --local btnInSlot = BlizActionBarButton:new(btnSlotIndex, eventId) -- for debugging btnSlotIndex > 120
    zebug.info:event(event):owner(btnInSlot):print("what got dropped",btnInSlot)

    if btnInSlot:isEmpty() or btnInSlot:isUfoPlaceholder(event) then
        -- an empty slot or one with a Placeholder is meaningless to us.
        zebug.info:event(event):owner(btnInSlot):print("the btn slot is now empty/UfoPlaceholder and nobody cares")
    elseif btnInSlot:isUfoProxy() then
        -- user just dragged and dropped a UFO onto the bar.
        -- what was there before?
        local draggedAndDroppedFlyoutId = UfoProxy:getFlyoutId()
        zebug.info:event(event):owner(btnInSlot):print("user just dragged and dropped a UFO onto the bar.",btnInSlot)

        if savedFlyoutIdForSlot then
            -- there was already a germ there.
            -- was it the same one as was just dropped?
            if draggedAndDroppedFlyoutId == savedFlyoutIdForSlot then
                -- do absolutely nothing
                zebug.trace:event(event):owner(btnInSlot):print("the dropped UFO was the same as the one already on the bar.  Nothing to do but exit.")
            else
                -- I don't think we can ever reach here.
                -- If there is a savedFlyoutIdForSlot there would also be an enabled germ in the slot.
                -- And if there is an enabled germ, it should have received the event and prevented the UfoProxy from reaching the action bar.
                -- user just dragged and dropped a different UFO than the one already/formerly there.
                -- save the new ID into the DB
                -- and reconfigure the existing germ
                -- was essentially self:updateBtnSlot(btnSlotIndex, eventId)

                assert(germInSlot, "config says there should already be a germ here but it's missing")
                zebug.trace:event(event):owner(btnInSlot):print("The UFO was dropped on an existing germ", germInSlot)
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
        zebug.info:event(event):print("DELETING PLACEMENT", "btnSlotIndex",btnSlotIndex, "flyoutId", flyLabel(flyoutId))
        zebug.trace:event(event):dumpy("BEFORE placements", placements)
        placements[btnSlotIndex] = nil
    end
end

-- unused?  What does Catalog do when the user kills a Ufo?
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
    Placeholder:create(event)
    Ufo.droppedPlaceholderOntoActionBar = event
    self:forEachPlacement(function(btnSlotIndex, flyoutId)
        Placeholder:put(btnSlotIndex, event)
    end)
    Ufo.droppedPlaceholderOntoActionBar = nil
end

function GermCommander:handleEventChangedInventory(event)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain inventory items
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAllSlots(event) -- change to updateSomeGerms(fitnessFunc) -- ACTUALLY, push the event listener into Germ class and have each instance handle its own shit
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
