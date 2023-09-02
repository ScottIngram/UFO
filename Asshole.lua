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
    local asshole = CreateFrame("CheckButton", "Asshole", UIParent, "ActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
    --asshole:SmallActionButtonMixin_OnLoad()
    asshole:RegisterForClicks("AnyDown", "AnyUp")

    deepcopy(Asshole, asshole)

    asshole:setIcon(369278)
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
local asshole = self
print("asshole's type1 (left-click) customscript is running...")
local isChecked = not asshole:GetAttribute("isChecked");
local turd_getter = asshole.GetFrameRef
local turdRef = getter and getter("turdRef")
local kids = table.new(asshole:GetChildren())

local turd

    for i, kid in ipairs(kids) do
        local kidName = kid:GetName()
        print(i,kidName)
        if kidName == "Turd" then
            turd = kid
            break
        end
    end

local pp = turd:GetParent()
local ppp = pp == asshole
    print( pp, ppp )

    print("turdRef =", turdRef, "turd",turd, asshole:GetChildren()[1],  table.new(asshole:GetChildren())[1]);
    if isChecked then
        print("turd:Show()")
        turd:Show()
    else
        print("turd:Hide()")
        turd:Hide()

        -- move the turd just for fun
        turd:ClearAllPoints()
        local whichSpot = turd:GetAttribute("whichSpot")
        if (whichSpot) then
            turd:SetPoint("BOTTOMRIGHT", asshole, "BOTTOMLEFT", 0, 0)
        else
            turd:SetPoint("TOPLEFT", asshole, "BOTTOMLEFT", 0, 0)
        end
        turd:SetAttribute("whichSpot",not whichSpot)
    end

    asshole:SetAttribute("isChecked",isChecked)

]]
);


    --print(asshole:GetName(), "asshole: type1 -> customscript... turd_getter =", turd_getter, "turd =", turd, "kid_getter =",kid_getter, "kids =",kids, "kidn",kidn, "kid1 =",kid1, "kid1_name",kid1_name);
    -- not
    asshole:Show()



    -- TURD ---

    local turd = CreateFrame("CheckButton", "Turd", asshole, "ActionButtonTemplate, SecureActionButtonTemplate")
    --local self = CreateFrame("CheckButton", "Asshole", UIParent, "SecureHandlerClickTemplate, SmallActionButtonTemplate, SecureActionButtonTemplate") -- SecureHandlerTemplate
    --local turd = CreateFrame("Button", "Turd", asshole, "UIPanelButtonTemplate")
    --turd:RegisterForClicks("AnyDown", "AnyUp")
    --local turd = CreateFrame("Button", "Turd", self, "UIPanelButtonTemplate")
    local w,h = asshole:GetSize()
    --turd:SetSize(80,22) -- width, height
    turd:SetSize(w,h) -- width, height
    turd:SetText("Button!")
    turd:SetPoint("TOPLEFT", asshole, "BOTTOMLEFT", 0, 0)
    turd:ClearAllPoints()
    turd:SetPoint("BOTTOMRIGHT", asshole, "BOTTOMLEFT", 0, 0)
    turd:RegisterForClicks("AnyDown", "AnyUp")

    --turd:SetScript("OnClick", function() print("turd OnClick") end)
    --turd:SetAttribute("type","macro")
    --turd:SetAttribute("macrotext",  "/s TURD type = macro")
    turd:SetAttribute("type","spell")
    turd:SetAttribute("spell",  "Regrowth")



    turd:Hide()

    deepcopy(Asshole, turd)
    turd:setIcon(4200123)



    --asshole:SetFrameRef("turdRef", turd)

    return self
end
