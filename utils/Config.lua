-------------------------------------------------------------------------------
-- Module Loading
--
-- Bliz's SavedVariables don't like my Wormhole magic, so, I've isolated them
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...

---@class Config -- IntelliJ-EmmyLua annotation
local Config = {}
Ufo.Config = Config

function Config:initializeFlyouts()
    if not UFO_SV_ACCOUNT then
        UFO_SV_ACCOUNT = { flyouts = {} }
    end
end

function Config:initializePlacements()
    if not UFO_SV_TOON then
        UFO_SV_TOON = { placementsForAllSpecs = {} }
    end
end
