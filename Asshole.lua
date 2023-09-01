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
    local asshole = CreateFrame("CheckButton", "Asshole", UIParent, "SmallActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
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

    --asshole:SetAttribute("type2","macro")
    --asshole:SetAttribute("macrotext",  "/s asshole's type2 (right-click) macro goes Booyah!")
    asshole:SetAttribute("type2","spell")
    asshole:SetAttribute("spell",  "Regrowth")

    asshole:SetAttribute("type1","customscript");-- Can be anything as long as it isn't one of the predefined actions
    asshole:SetAttribute("_customscript", [[
print("asshole's type1 (left-click) customscript is running...")
local isChecked = not self:GetAttribute("isChecked");
local turd_getter = self.GetFrameRef
local turdRef = getter and getter("turdRef")
local kids = table.new(self:GetChildren())

local turd

    for i, kid in ipairs(kids) do
        local kidName = kid:GetName()
        print(i,kidName)
        if kidName == "Turd" then
            turd = kid
            break
        end
    end


    print("turdRef =", turdRef, "turd",turd, self:GetChildren()[1],  table.new(self:GetChildren())[1]);
    if isChecked then
        print("turd:Show()")
        turd:Show()
    else
        print("turd:Hide()")
        turd:Hide()
    end

    self:SetAttribute("isChecked",isChecked)

]]
);

    --print(asshole:GetName(), "asshole: type1 -> customscript... turd_getter =", turd_getter, "turd =", turd, "kid_getter =",kid_getter, "kids =",kids, "kidn",kidn, "kid1 =",kid1, "kid1_name",kid1_name);
    -- not
    asshole:Show()



    -- TURD ---

    local turd = CreateFrame("CheckButton", "Turd", asshole, "SmallActionButtonTemplate, SecureActionButtonTemplate")
    --local self = CreateFrame("CheckButton", "Asshole", UIParent, "SecureHandlerClickTemplate, SmallActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
    --local turd = CreateFrame("Button", "Turd", asshole, "UIPanelButtonTemplate")
    --turd:RegisterForClicks("AnyDown", "AnyUp")
    --local turd = CreateFrame("Button", "Turd", self, "UIPanelButtonTemplate")
    turd:SetSize(80 ,22) -- width, height
    turd:SetText("Button!")
    turd:SetPoint("TOPLEFT", asshole, "BOTTOMLEFT", 0, 0)
    turd:RegisterForClicks("AnyDown", "AnyUp")

    --turd:SetScript("OnClick", function() print("turd OnClick") end)
    --turd:SetAttribute("type","macro")
    --turd:SetAttribute("macrotext",  "/s TURD type = macro")
    turd:SetAttribute("type","spell")
    turd:SetAttribute("spell",  "Regrowth")


    -- Notice that turd has NO RegisterForClicks

    turd:Hide()


    --asshole:SetFrameRef("turdRef", turd)

    return self
end
