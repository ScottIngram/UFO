-- BlizGlobalEventsListener.lua
-- register callbacks for global (non-frame) events

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, ADDON_SYMBOL_TABLE = ...
ADDON_SYMBOL_TABLE.Wormhole()
local zebug = Zebug:new(Zebug.OUTPUT.WARN)

---@class BlizGlobalEventsListener
BlizGlobalEventsListener = {}

-------------------------------------------------------------------------------
-- Event Handler Registration
-------------------------------------------------------------------------------

---@param zelf table will act as the "self" object in all eventHandlers
---@param eventHandlers table<string, function> key -> "EVENT_NAME" , value -> handlerCallback
---@param addonLoadedHandlers table<string, function> key -> "OtherAddonName" , value -> funcToCallWhenOtherAddonLoads
-- Note: addons that load before yours will not be handled.  Use IsAddOnLoaded(addonName) instead
function BlizGlobalEventsListener:register(zelf, eventHandlers, addonLoadedHandlers)
    local dispatcher = function(listenerFrame, eventName, ...)
        eventHandlers[eventName](zelf, ...)
    end

    local eventListenerFrame = CreateFrame(FrameType.FRAME, ADDON_NAME.."BlizGlobalEventsListener")
    eventListenerFrame:SetScript(Script.ON_EVENT, dispatcher)

    -- handle the ADDON_LOADED event for specific addons

    local oldHandler = eventHandlers.ADDON_LOADED
    local newHandler = function(zelf, loadedAddonName)
        --[START CALLBACK]--
        if oldHandler then
            zebug.trace:print("triggering the existing ADDON_LOADED handler", oldHandler)
            oldHandler(zelf)
        end

        -- find a handler for the addon that just triggered the ADDON_LOADED event
        for addonName, handler in pairs(addonLoadedHandlers) do
            zebug.trace:name("dispatcher"):print("loaded",loadedAddonName, "comparing to",addonName, "handler",handler)
            if addonName == loadedAddonName then
                zebug.info:print("invoking", addonName)
                handler(zelf, addonName)
            end
        end
        --[END CALLBACK]--
    end

    eventHandlers.ADDON_LOADED = newHandler

    -- handle GENERIC events

    for eventName, _ in pairs(eventHandlers) do
        zebug.info:print("registering ",eventName)
        eventListenerFrame:RegisterEvent(eventName)
    end

end
