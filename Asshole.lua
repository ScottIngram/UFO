-------------------------------------------------------------------------------
-- Module Loading
-------------------------------------------------------------------------------

local ADDON_NAME, Ufo = ...
Ufo.Wormhole() -- Lua voodoo magic that replaces the current Global namespace with the Ufo object
local zebug = Zebug:new()

---@class Asshole -- IntelliJ-EmmyLua annotation
---@field ufoType string The classname
---@field turd Frame
Asshole = {
    ufoType = "Asshole",
}

Asshole.getIconFrame = ButttonMixin.getIconFrame
Asshole.setIcon      = ButttonMixin.setIcon

function Asshole:new()
    local asshole = CreateFrame("CheckButton", "Asshole", UIParent, "SecureHandlerClickTemplate, SmallActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
    asshole:SmallActionButtonMixin_OnLoad()
    asshole:RegisterForClicks("AnyDown", "AnyUp")

    deepcopy(Asshole, asshole)

    --self:setIcon(369278)
    asshole:SetFrameStrata(STRATA_DEFAULT)
    asshole:SetFrameLevel(100)
    asshole:SetToplevel(true)
    --self:SetSize(80 ,80) -- width, height
    asshole:SetPoint("CENTER")

--[[
    assholeSetScript("OnClick", function()
        print("I'm in your buttonz. Checked =", assholeGetChecked() )
        if assholeGetChecked() then
            self.turd:Show()
        else
            self.turd:Hide()
        end
    end)
]]--

    asshole:SetAttribute("type2","macro")
    asshole:SetAttribute("macrotext",  "/s self type2 macro goes Booyah")

    asshole:SetAttribute("type1","customscript");-- Can be anything as long as it isn't one of the predefined actions
    asshole:SetAttribute("_customscript", [[
print(1)
local isChecked = not self:GetAttribute("isChecked");
local turd_getter = self.GetFrameRef
local turd = getter and getter("turd")
local kids = table.new(self:GetChildren())
local kid1 = kids[1]
local kid1_name = kid1 and kid1:GetName()

local Turd

    for i, kid in ipairs(kids) do
        local kidName = kid:GetName()
        print(i,kidName)
        if kidName == "Turd" then
            Turd = kid
            break
        end
    end


    print("turd =", turd, "kid1 =",kid1, "kid1_name",kid1_name, "Turd",Turd);
    if isChecked then
        print("Turd:Show()")
        Turd:Show()
    else
        print("Turd:Hide()")
        Turd:Hide()
    end

    self:SetAttribute("isChecked",isChecked)

]]
);

    --print(asshole:GetName(), "asshole: type1 -> customscript... turd_getter =", turd_getter, "turd =", turd, "kid_getter =",kid_getter, "kids =",kids, "kidn",kidn, "kid1 =",kid1, "kid1_name",kid1_name);
    -- not
    asshole:Show()



    -- TURD ---

    --local turd = CreateFrame("CheckButton", "Turd", asshole, "SmallActionButtonTemplate, SecureActionButtonTemplate")
    --local self = CreateFrame("CheckButton", "Asshole", UIParent, "SecureHandlerClickTemplate, SmallActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
    local turd = CreateFrame("Button", "Turd", asshole, "UIPanelButtonTemplate")
    turd:RegisterForClicks("AnyDown", "AnyUp")
    --local turd = CreateFrame("Button", "Turd", self, "UIPanelButtonTemplate")
    turd:SetSize(80 ,22) -- width, height
    turd:SetText("Button!")
    turd:SetPoint("TOP", asshole, "BOTTOM", 0, 0)

    turd:SetScript("OnClick", function()
        print("turd OnClick")
    end)

    turd:SetAttribute("type","macro")
    turd:SetAttribute("macrotext",  "/s TURD type = macro")

    -- Notice that turd has NO RegisterForClicks

    turd:Show()


    asshole:SetFrameRef("turd", turd)

    return self
end
