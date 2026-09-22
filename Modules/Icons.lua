local RH = RubimRH
local WHITE = "Interface\\Buttons\\WHITE8X8"
local class = select(2, UnitClass("player")) or "ROGUE"
local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or { r = 0.78, g = 0.64, b = 0.32 }
local f = CreateFrame("Frame", "NextCastIcon", UIParent)
RH.IconFrame = f
f:SetSize(72, 108)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)
local card = CreateFrame("Frame", nil, f, "BackdropTemplate")
card:SetPoint("TOP", 0, -16)
card:SetSize(56, 56)
card:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
card:SetBackdropColor(0.043, 0.047, 0.055, 0.96)
card:SetBackdropBorderColor(0.18, 0.19, 0.21, 1)
local icon = card:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 3, -3)
icon:SetPoint("BOTTOMRIGHT", -3, 5)
local accent = card:CreateTexture(nil, "OVERLAY")
accent:SetTexture(WHITE)
accent:SetPoint("BOTTOMLEFT", 1, 1)
accent:SetPoint("BOTTOMRIGHT", -1, 1)
accent:SetHeight(3)
accent:SetColorTexture(cc.r, cc.g, cc.b, 1)
local pulse = card:CreateTexture(nil, "OVERLAY")
pulse:SetTexture(WHITE)
pulse:SetAllPoints(icon)
pulse:SetColorTexture(cc.r, cc.g, cc.b, 1)
pulse:SetAlpha(0)
pulse:SetBlendMode("ADD")

local function miniToggle(parent, point, x, y, w)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w or 30, 12)
    b:SetPoint(point, x, y)
    b:SetFrameLevel(parent:GetFrameLevel() + 2)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b:SetBackdropColor(0.043, 0.047, 0.055, 0.92)
    b:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.text:SetPoint("CENTER")
    b.text:SetScale(0.78)
    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(cc.r * 0.7, cc.g * 0.7, cc.b * 0.7, 1)
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)
    end)
    return b
end
local modeToggle = miniToggle(f, "TOP", -16, 0, 30)
local cdToggle = miniToggle(f, "TOP", 16, 0, 30)
local burstToggle
local modeLabels = { auto = "AUTO", single = "ST", aoe = "AOE" }
local function RefreshMiniToggles()
    local d = RH.EnsureDB()
    modeToggle.text:SetText(modeLabels[d.mode] or "AUTO")
    modeToggle.text:SetTextColor(d.mode == "aoe" and 0.94 or 0.72, d.mode == "aoe" and 0.72 or 0.73, d.mode == "aoe" and 0.42 or 0.74)
    local cdsOn = d.cooldowns ~= false
    cdToggle.text:SetText("CDS")
    cdToggle.text:SetTextColor(cdsOn and 0.45 or 0.55, cdsOn and 0.86 or 0.57, cdsOn and 0.58 or 0.60)
    if burstToggle then
        burstToggle.text:SetText("BURST")
        burstToggle.text:SetTextColor(RH.Burst and 0.95 or 0.48, RH.Burst and 0.42 or 0.50, RH.Burst and 0.32 or 0.52)
        burstToggle:SetBackdropBorderColor(RH.Burst and 0.7 or 0.22, RH.Burst and 0.28 or 0.23, RH.Burst and 0.18 or 0.25, 1)
    end
end
RH.RefreshMiniToggles = RefreshMiniToggles
modeToggle:SetScript("OnClick", function()
    local d = RH.EnsureDB()
    d.mode = d.mode == "auto" and "single" or (d.mode == "single" and "aoe" or "auto")
    RH.AoE = d.mode == "aoe"
    RefreshMiniToggles()
end)
cdToggle:SetScript("OnClick", function()
    local d = RH.EnsureDB()
    d.cooldowns = d.cooldowns == false
    RH.CDs = d.cooldowns ~= false
    RefreshMiniToggles()
end)
local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nameText:SetPoint("TOP", card, "BOTTOM", 0, -4)
nameText:SetWidth(120)
nameText:SetJustifyH("CENTER")
local stateText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
stateText:SetPoint("TOP", nameText, "BOTTOM", 0, 0)
stateText:SetWidth(120)
stateText:SetTextColor(0.55, 0.56, 0.58)

burstToggle = CreateFrame("Button", nil, f, "BackdropTemplate")
burstToggle:SetSize(48, 12)
burstToggle:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
burstToggle:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
burstToggle:SetBackdropColor(0.043, 0.047, 0.055, 0.92)
burstToggle:SetBackdropBorderColor(0.22, 0.23, 0.25, 1)
burstToggle.text = burstToggle:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
burstToggle.text:SetPoint("CENTER")
burstToggle.text:SetScale(0.78)
burstToggle:SetScript("OnClick", function()
    NextCast_Burst()
end)
RefreshMiniToggles()
local pips = {}
for i = 1, 5 do
    local p = f:CreateTexture(nil, "OVERLAY")
    p:SetTexture(WHITE)
    p:SetSize(7, 2)
    p:SetPoint("BOTTOM", f, "BOTTOM", (i - 3) * 9, 2)
    pips[i] = p
end

-- GGL / ExtraIcon protocol lives in Modules/GGL.lua (Griph strip).
-- The HUD below is the player's visible recommendation; the strip is what
-- a reader binds.
f:SetScript("OnDragStart", function(s)
    if not RH.EnsureDB().locked then
        s:StartMoving()
    end
end)
f:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    RH.SaveFramePosition(s, "position")
end)
f:SetScript("OnMouseUp", function(_, b)
    if b == "RightButton" and RH.ToggleMenu then
        RH.ToggleMenu()
    end
end)
local elapsed, lastResult, pulseLeft = 0, nil, 0
f:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    pulseLeft = math.max(0, pulseLeft - dt)
    pulse:SetAlpha(pulseLeft > 0 and math.min(0.11, pulseLeft * 0.20) or 0)
    local interval = RH.recommendationDirty and 0.05 or (RH.Player:AffectingCombat() and 0.10 or 0.20)
    if elapsed < interval then
        return
    end
    elapsed = 0
    RH.recommendationDirty = nil
    local result = RH.MainRotation()
    RH.currentRecommendation = result
    local name, tex
    if result then
        name, tex = HeroCache:SpellInfo(result)
        if result == 6603 then
            name = "Attack"
            tex = RH.StartAttackTexture and RH.StartAttackTexture() or tex
        end
    end
    if result ~= lastResult then
        lastResult = result
        pulseLeft = 0.55
        if RH.LogRecommendation then
            RH.LogRecommendation(name)
        end
    end
    if tex then
        icon:SetTexture(tex)
        icon:SetTexCoord(0.045, 0.955, 0.045, 0.955)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetAlpha(1)
        pcall(icon.SetDesaturated, icon, false)
        nameText:SetText(name or "")
        nameText:SetTextColor(0.92, 0.92, 0.90)
        local ttd = RH.Target.TimeToDie and RH.Target:TimeToDie()
        stateText:SetText(ttd and (math.floor(ttd + 0.5) .. "s") or "")
    else
        local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetAlpha(1)
        pcall(icon.SetDesaturated, icon, false)
        if c then
            icon:SetTexCoord(c[1] + 0.012, c[2] - 0.012, c[3] + 0.012, c[4] - 0.012)
        else
            icon:SetTexCoord(0, 1, 0, 1)
        end
        nameText:SetText(RH.EnsureDB().enabled == false and "Paused" or "")
        nameText:SetTextColor(0.55, 0.56, 0.58)
        stateText:SetText("")
    end
    if result and RH.healTarget then
        local ally = RH.SafeUnitText(UnitName, RH.healTarget) or RH.healTarget
        stateText:SetText("HEAL  •  " .. ally)
        stateText:SetTextColor(0.4, 1, 0.6)
    else
        stateText:SetTextColor(0.62, 0.65, 0.72)
    end
    local points, pr, pg, pb
    if class == "WARRIOR" then
        points = math.floor((HeroLib.SafeNumber(UnitPower("player", 1), 0) or 0) / 20)
        pr, pg, pb = 0.78, 0.18, 0.12
    elseif class == "ROGUE" then
        points = HeroLib.State.combo or 0
        pr, pg, pb = 1, 0.72, 0.12
    else
        local power = HeroLib.SafeNumber(UnitPower("player"), 0) or 0
        local maximum = HeroLib.SafeNumber(UnitPowerMax("player"), 0) or 0
        points = maximum > 0 and math.ceil((power / maximum) * 5) or 0
        pr, pg, pb = cc.r, cc.g, cc.b
    end
    for i, p in ipairs(pips) do
        if i <= points then
            p:SetColorTexture(pr, pg, pb, 1)
        else
            p:SetColorTexture(0.17, 0.18, 0.21, 0.85)
        end
    end
    RefreshMiniToggles()
    if RH.LayoutShownMain then
        RH.LayoutShownMain()
    end
    if RH.PaintShownMain then
        RH.PaintShownMain(result)
    end
end)
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_ENTERING_WORLD")
login:SetScript("OnEvent", function()
    local d = RH.EnsureDB()
    RH.RestoreFramePosition(f, "position")
    f:SetScale(d.scale or 1)
    f:EnableMouse(not d.locked)
    if RH.EnsureFriendlyMacros then
        RH.EnsureFriendlyMacros()
    end
end)
