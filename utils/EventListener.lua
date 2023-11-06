-- EventListener.lua
-- register callbacks for global (non-frame) events

-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, ADDON_SYMBOL_TABLE = ...
ADDON_SYMBOL_TABLE.Wormhole()
EventListener = {}

-------------------------------------------------------------------------------
-- Event Handler Registration
-------------------------------------------------------------------------------

---@param zelf table will act as the "self" object in all eventHandlers
---@param eventHandlers table<string, function> key -> "EVENT_NAME" , value -> handlerCallback
---@param handlersForOtherAddons table<string, function> key -> "OtherAddonName" , value -> funcToCallWhenOtherAddonLoads
-- Note: addons that load before yours will not be handled.  Use IsAddOnLoaded(addonName) instead
function EventListener:register(zelf, eventHandlers, handlersForOtherAddons)
    local dispatcher = function(listenerFrame, eventName, ...)
        eventHandlers[eventName](zelf, ...)
    end

    local eventListenerFrame = CreateFrame("Frame", ADDON_NAME.."EventListener")
    eventListenerFrame:SetScript("OnEvent", dispatcher)

    if isTableNotEmpty(handlersForOtherAddons) then
        local existingHandler = eventHandlers.ADDON_LOADED
        eventHandlers.ADDON_LOADED = function(zelf, loadedAddonName)
            if existingHandler then
                zebug.trace:print("running the existing ADDON_LOADED", existingHandler)
                existingHandler(zelf)
            end
            for addonName, handler in pairs(handlersForOtherAddons) do
                zebug.trace:print("loadedAddonName",loadedAddonName, "addonName",addonName, "handler",handler)
                if addonName == loadedAddonName then
                    zebug.trace:print("invoking", addonName)
                    handler(zelf, addonName)
                end
            end
        end
    end

    for eventName, _ in pairs(eventHandlers) do
        zebug.trace:print("registering ",eventName)
        eventListenerFrame:RegisterEvent(eventName)
    end
end
