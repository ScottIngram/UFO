-------------------------------------------------------------------------------
-- Profession Shit Show - yet another Bliz fix!  Now for Trade Skill IDs!
-- When the user drags around any of the profession buttons that open up the profession window,
-- the Bliz API GetCursorInfo() reports *MOST* of them as {name="Herbalism Journal", type="spell"} (for example).
-- However, in a stunningly consistent display of Bliz inconsistently, not always!
-- Sometimes, seemingly on whim, it reports {name="Inscription", type="spell"} (note the lack of "Journal").
-- The SecureClickHandler can cast a "Herbalism Journal" spell to open it.
-- But it can NOT cast an "Inscription" spell and hence the prof window will not open.  WHOLE-ASS FAIL!
-- So, here I am, coding YAWA (Yet Another Work Around) for the Bliz API shitting the bed.
-- I must create a mapping of (localized) prof name -> its TradeSkillLineID
-- which, I pray to the cruel and capricious Bliz API gods, will match the localized name reported by GetCursorInfo()
-- I already admit in advance that such thinking is probably foolish.
-------------------------------------------------------------------------------

---@type Ufo
local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object

---@class ProfessionShitShow -- IntelliJ-EmmyLua annotation
ProfessionShitShow = {}

---@type table key="Name of profession" -> TradeSkillLineID
local indexOfProfIds

function ProfessionShitShow:getIndex()
    if not indexOfProfIds then
        indexOfProfIds = {}
        local foo = table.pack( GetProfessions() )
        for i, spellTabIndex in pairs(foo) do
            local name, _, _, _, _, _, skillLineId = GetProfessionInfo(spellTabIndex)
            indexOfProfIds[name or "HowTheFuckDoesThisReturnNil?!?! FOR FUCKS SAKE BLIZ"] = skillLineId

        end
        zebug.trace:dumpy("indexOfProfIds",indexOfProfIds)
    end
    return indexOfProfIds
end

function ProfessionShitShow:getMegaIndex()
    if not indexOfProfIds then
        indexOfProfIds = {}
        local skillLineIds = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        for i, skillLineId in ipairs(skillLineIds) do
            local profInfo = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineId)
            indexOfProfIds[profInfo.professionName] = skillLineId
        end
        zebug.trace:dumpy("indexOfProfIds",indexOfProfIds)
    end
    return indexOfProfIds
end

function ProfessionShitShow:forEach(fubarId, func)
    local commands = self:getIndex()[fubarId]
    assert(commands, "Unknown fubarId " .. (fubarId or "NIL") )

    for i, brokenPetCommand in ipairs(commands) do
        func(i,brokenPetCommand)
    end
end

function ProfessionShitShow:get(profName)
    local skillLineId = self:getIndex()[profName]
    return skillLineId
end
