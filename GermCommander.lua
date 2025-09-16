-- GermCommander
-- collects and manages instances of the Germ class which sit on the action bars

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

---@type Ufo -- IntelliJ-EmmyLua annotation
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

local zebug = Zebug:new(Z_VOLUME_GLOBAL_OVERRIDE or Zebug.TRACE)

---@class GermCommander -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field updatingAll boolean true when updateAllGerms() is making a LOT of noise
GermCommander = { ufoType="GermCommander" }

---@alias BtnSlotIndex number

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

---@type table<number,Germ|GERM_TYPE>
local germs = {}
local slotsByLabel = {}

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------

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

---@param funcFor fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachActiveGerm(funcFor, event)
    self:forEachGermIf(funcFor, Germ.isActive, event)
end

---@param func fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachGermWithFlyoutId(flyoutId, func, event)
    function germHasFlyoutId(germ)
        return germ:hasFlyoutId(flyoutId)
    end
    self:forEachGermIf(func, germHasFlyoutId, event)
end

local oopsEvent = Event:new("oops!","last arg needs to be an event")

---@param opFunction fun(germ:Germ, optional:Event) will be invoked for every germ and passed args: germ,event
---@param fitnessFunc fun(germ:Germ) a function that will return true if the germ in question should be included in the operation
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachGermIf(opFunction, fitnessFunc, event)
    assert(isFunction(opFunction), 'must provide a "opFunction(Germ)" ')
    assert(isFunction(fitnessFunc), 'must provide a "fitnessFunc(Germ)" ')
    event = event or oopsEvent
    for _, germ in pairs(germs) do
        if fitnessFunc(germ, event) then
            zebug.trace:event(event):owner(germ):line(8,"MATCH!")
            opFunction(germ, event)
        else
            zebug.trace:event(event):owner(germ):print("skipping because it failed the fitnessFunc()")
        end
    end
end

-- Used to go through the saved config when the germs may not all have been created yet (during first load or spec change).
-- Is also a *slightly* more efficient forEachActiveGerm() due to the fact that inactive Germs get removed from the placements.
---@param func function(btnSlotIndex, flyoutId, eventId) will be invoked for every placement and get the btnSlotIndex & flyoutId for each one
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:forEachPlacement(func, event)
    -- this is probably equivalent to forEachActiveGerm()
    local placements = Spec:getCurrentSpecPlacementConfig()
    for btnSlotIndex, flyoutId in pairs(placements) do
        func(btnSlotIndex, flyoutId, event)
    end
end

-- is being called mostly when the button move around / change
---@param flyoutId number
function GermCommander:notifyOfChangeToFlyoutDef(flyoutId, event)
    zebug.info:event(event):print("updating all Germs with",FlyoutDefsDb:get(flyoutId))
    self:forEachGermWithFlyoutId(flyoutId, Germ.notifyOfChangeToFlyoutDef, event)
end

GermCommander.notifyOfChangeToFlyoutDef = Pacifier:wrap(GermCommander.notifyOfChangeToFlyoutDef)

-- go through all placements saved in the DB.
-- I expect this will happen during
-- * addon initialization
-- * spec change
-- * maybe during zoning / player entering world ?
function GermCommander:initializeAllSlots(event)
    self:forEachPlacement(function(btnSlotIndex, flyoutId)
        local flyoutDef = FlyoutDefsDb:get(flyoutId)
        if not flyoutDef then
            -- because one toon can delete a flyout while other toons still have it on their bars
            zebug.warn:event(event):print("flyoutId",flyoutId, "no longer exists. Deleting it from action bar slot #",btnSlotIndex)
            self:forgetPlacement(btnSlotIndex)
        else
            self:putUfoOntoActionBar(btnSlotIndex, flyoutId, event)
        end
    end)
end

function GermCommander:updateAllKeybindBehavior(event)
    self:forEachActiveGerm(Germ.updateClickerForKeybind, event)
end

GermCommander.updateAllKeybindBehavior = Pacifier:wrap(GermCommander.updateAllKeybindBehavior, L10N.CHANGE_KEYBIND_ACTION)

function GermCommander:applyConfigForBindTheButtons(event)
    local doKeybindTheButtonsOnTheFlyout = Config:get("doKeybindTheButtonsOnTheFlyout")

    ---@param germ Germ
    self:forEachActiveGerm(function(germ)
        germ:SetAttribute("doKeybindTheButtonsOnTheFlyout", doKeybindTheButtonsOnTheFlyout)
        germ:updateAllBtnHotKeyLabels(event)
    end, event)

end

GermCommander.applyConfigForBindTheButtons = Pacifier:wrap(GermCommander.applyConfigForBindTheButtons, L10N.RECONFIGURE_FLYOUT_BUTTON_KEYBINDING)

---@param mouseClick MouseClick
function GermCommander:updateClickerForAllActiveGerms(mouseClick, event)
    -- can't modify the inactive germs because they have no flyoutId
    ---@param germ Germ
    self:forEachActiveGerm(function(germ)
        local behaviorName = Config:getGermClickBehavior(germ.flyoutId, mouseClick)
        germ:assignTheMouseClicker(mouseClick, behaviorName, event)
    end, event)
end

GermCommander.updateClickerForAllActiveGerms = Pacifier:wrap(GermCommander.updateClickerForAllActiveGerms, L10N.CHANGE_MOUSE_BUTTON_BEHAVIOR)

---@return GERM_TYPE
function GermCommander:recallGerm(btnSlotIndex)
    return germs[btnSlotIndex]
end

---@param germ Germ -- IntelliJ-EmmyLua annotation
function GermCommander:saveGerm(germ)
    local btnSlotIndex = germ:getBtnSlotIndex()
    germs[btnSlotIndex] = germ
    local label = germ:getLabel()
    slotsByLabel[label] = btnSlotIndex
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

-- useful for debugging
function GermCommander:getGermByLabel(label)
    return self:recallGerm(slotsByLabel[label])
end

-- Responds to event: ACTIONBAR_SLOT_CHANGED
-- The altered slot could now be:
--- * empty - so we must clear any existing UFO that was there before
--- * a std Bliz thingy - ditto
--- * a Ufo proxy for the same flyoutId as before this event - NO ACTION REQUIRED
--- * a Ufo proxy for a new flyoutId than was there before this event - update the existing Germ with the new UFO config
--- * a Ufo Placeholder that we programmatically put there and should be ignored
function GermCommander:addOrRemoveSomeUfoDueToAnActionBarSlotChangedEvent(btnSlotIndex, event)
    local btnInSlot = BlizActionBarButtonHelper:get(btnSlotIndex, event)
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
    elseif btnInSlot:isUfoProxyForFlyout() then
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
    elseif btnInSlot:isUfoProxyForButton() then
        event = "woo"
        -- The user has dropped the fake button proxy onto the action bar.
        ButtonOnFlyoutMenu:abortIfUnusable(Ufo.pickedUpBtn)

        -- Clear it from the bar and put it back on the cursor.

        if Cursor:isEmpty() then
            zebug.info:event(event):owner(btnInSlot):print("picking up",btnInSlot)
            PickupAction(btnInSlot.btnSlotIndex)
        else
            -- the user dropped the proxy onto an action bar that already had something on it.
            -- put it back on the action bar.
            zebug.info:event(event):owner(btnInSlot):print("our net scooped up",Cursor:get(), "put it back!")
            PlaceAction(btnInSlot.btnSlotIndex)
            zebug.info:event(event):owner(btnInSlot):print("did it work?  Cursor is now",Cursor:get())
        end

        -- now put restore the UfoProxyForButton to the cursor

        local isOk = Ufo.pickedUpBtn:pickupToCursor(event)
        if isOk then
            zebug.info:event(event):owner(btnInSlot):dumpy("YAY, isOk! post-pickup Ufo.pickedUpBtn",Ufo.pickedUpBtn)
        else
            zebug.info:event("wahhhh"):owner(btnInSlot):print("failed to re-pickup Ufo.pickedUpBtn",Ufo.pickedUpBtn)
        end
    else
        -- a std Bliz thingy.
        -- altho, if that's true it would have been an event on the Germ itself.
        -- so this code may never be reached
        -- maybe during programmatic button swaps such as changing specs?
        zebug.info:event(event):owner(btnInSlot):print("a std Bliz thingy. ERASE Ufo (if any)")
        self:eraseUfoFrom(btnInSlot, germInSlot, event)
    end
end

---@param btn BtnSlotIndex | BlizActionBarButton
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
    Spec:getCurrentSpecPlacementConfig()[btnSlotIndex] = flyoutId
end

function GermCommander:forgetPlacement(btnSlotIndex, event)
    btnSlotIndex = tonumber(btnSlotIndex)
    --local flyoutId = Spec:getUfoFlyoutIdForSlot(btnSlotIndex)
    local placements = Spec:getCurrentSpecPlacementConfig()
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

-- Things that will put a UFO onto the action bar
-- * addon initialization - all UFOs are newly created and placed based on SAVED_VARIABLES
-- * a UFO is on the cursor and is dropped onto an action bar slot that is empty
-- * a UFO is on the cursor and is dropped onto an action bar slot that contains a std bliz thingy
-- * a UFO is on the cursor and is dropped onto another UFO (maybe empty slot, maybe a slot with the placeholder macro)
-- in most of the above, there may be a Germ already there but is perhaps disabled because the user previously dragged it away
function GermCommander:dropDraggedUfoFromCursorOntoActionBar(btnSlotIndex, flyoutId, eventId)
    self:putUfoOntoActionBar(btnSlotIndex, flyoutId, eventId)
end

function GermCommander:putUfoOntoActionBar(btnSlotIndex, flyoutId, event)
    local flyoutDef = FlyoutDefsDb:get(flyoutId)
    assert(flyoutDef, "no config exists for the specified flyoutId")

    self:savePlacement(btnSlotIndex, flyoutId, event)

    local clobberedBtnDef = Placeholder:put(btnSlotIndex, event)
    if UfoProxy:isOn(clobberedBtnDef) then
        zebug.info:event(event):print("clearing the re-picked-up UfoProxy from the cursor", clobberedBtnDef)
        Cursor:clear(event)
    end

    local germ = self:recallGerm(btnSlotIndex)
    if not germ then
        germ = Germ:new(flyoutId, btnSlotIndex, event) -- this is expected to do everything required for a fully functioning germ
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

GermCommander.ensureAllGermsHavePlaceholders = Pacifier:wrap(GermCommander.ensureAllGermsHavePlaceholders, L10N.SWITCH_TO_PLACEHOLDERS) -- allow only out of combat

---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:changeSpec(event)
    local oldPlacements = Spec:getPreviousSpecPlacementConfig()
    if oldPlacements then
        -- clobber any UFOs that exist in the old spec but not the new one
        local newPlacements = Spec:getCurrentSpecPlacementConfig()
        for btnSlotIndex, flyoutId in pairs(oldPlacements) do
            local inNewConfig =  newPlacements[btnSlotIndex]
            if not inNewConfig then
                self:eraseUfoFrom(btnSlotIndex, nil, event)
            end
        end
    end

    -- a bunch of abilities were just learned / forgotten.
    -- so many of the cached usableFlyoutDef are now wrong.
    FlyoutDefsDb:clearCaches()

    -- put germs where they need to go with fresh usableBtnDefs
    self:initializeAllSlots(event)
end

-- we don't know exactly what in the bags changed, but, such changes could alter usableFlyoutDef.
-- For example, conjure food would want a UFO with such food to show it.  Or, a UFO showing a potion needs to know if the player drank the last one.
---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:notifyAllGermsWithItems(event)
    ---@param germ GERM_TYPE
    self:forEachGermIf(Germ.refreshFlyoutDefAndApply, Germ.hasItemsAndIsActive, event)
end

-- because the above eventually calls a method that does combat-unfriendly stuff,
-- silently pacify it here so the user isn't spammed with RECONFIGURE_BUTTON messages
GermCommander.notifyAllGermsWithItems = Pacifier:wrap(GermCommander.notifyAllGermsWithItems)

---@param event string|Event custom UFO metadata describing the instigating event - good for debugging
function GermCommander:handleEventMacrosChanged(event)
    self:forEachGermIf(Germ.invalidateFlyoutCache, Germ.hasMacrosAndIsActive, event)
end
GermCommander.handleEventMacrosChanged = Pacifier:wrap(GermCommander.handleEventMacrosChanged)

function GermCommander:notifyAllGermsWithSpells(event)
    ---@param germ GERM_TYPE
    self:forEachGermIf(Germ.refreshFlyoutDefAndApply, Germ.hasSpellsAndIsActive, event)
end
GermCommander.notifyAllGermsWithSpells = Pacifier:wrap(GermCommander.notifyAllGermsWithSpells)

--[[
-- unused atm
function GermCommander:handleEventPetChanged(event)
    -- TODO: be a little less NUKEy... create an index of which flyouts contain pets
    FlyoutDefsDb:forEachFlyoutDef(FlyoutDef.invalidateCache)
    self:updateAllSlots(event) -- change to updateSomeGerms(fitnessFunc)
end
]]

