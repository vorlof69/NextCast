local RH = RubimRH
local WHITE = "Interface\\Buttons\\WHITE8X8"
local class = select(2, UnitClass("player")) or "ROGUE"
local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or { r = 0.78, g = 0.64, b = 0.32 }

local f = CreateFrame("Frame", "NextCastIcon", UIParent)
RH.IconFrame = f
f:SetSize(64, 104)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)

local rail = CreateFrame("Frame", nil, f)
rail:SetSize(64, 14)
rail:SetPoint("TOP", 0, 0)
local railBg = rail:CreateTexture(nil, "BACKGROUND")
railBg:SetAllPoints()
railBg:SetColorTexture(0.035, 0.038, 0.045, 0.94)

local function railBtn(text, x)
    local b = CreateFrame("Button", nil, rail)
    b:SetSize(32, 14)
    b:SetPoint("LEFT", x, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.text:SetPoint("CENTER")
    b.text:SetScale(0.72)
    b.text:SetText(text)
    b.glow = b:CreateTexture(nil, "BACKGROUND")
    b.glow:SetTexture(WHITE)
    b.glow:SetAllPoints()
    b.glow:SetColorTexture(cc.r, cc.g, cc.b, 0)
    return b
end
local modeToggle = railBtn("AUTO", 0)
local cdToggle = railBtn("CDS", 32)

local function paintRail(btn, on, hotR, hotG, hotB)
    btn.text:SetTextColor(on and hotR or 0.50, on and hotG or 0.52, on and hotB or 0.55)
    btn.glow:SetColorTexture(hotR, hotG, hotB, on and 0.22 or 0)
end

local function RefreshMiniToggles()
    local d = RH.EnsureDB()
    local mode = d.mode or "auto"
    modeToggle.text:SetText(mode == "single" and "ST" or (mode == "aoe" and "AOE" or "AUTO"))
    paintRail(modeToggle, mode == "aoe", 0.94, 0.72, 0.42)
    paintRail(cdToggle, d.cooldowns ~= false, 0.45, 0.86, 0.58)
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

local well = CreateFrame("Frame", nil, f)
well:SetSize(64, 64)
well:SetPoint("TOP", 0, -15)
local wellBg = well:CreateTexture(nil, "BACKGROUND")
wellBg:SetAllPoints()
wellBg:SetColorTexture(0.02, 0.022, 0.028, 1)

local icon = well:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local classLetter = well:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
classLetter:SetPoint("CENTER")
classLetter:SetText((class:sub(1, 1) or "?"))
classLetter:SetTextColor(cc.r, cc.g, cc.b)
classLetter:Hide()

local sweep
pcall(function()
    sweep = CreateFrame("Cooldown", nil, well, "CooldownFrameTemplate")
    sweep:SetAllPoints()
    sweep:SetReverse(true)
    if sweep.SetHideCountdownNumbers then
        sweep:SetHideCountdownNumbers(true)
    end
end)

local pulse = well:CreateTexture(nil, "OVERLAY")
pulse:SetTexture(WHITE)
pulse:SetAllPoints()
pulse:SetColorTexture(cc.r, cc.g, cc.b, 1)
pulse:SetAlpha(0)
pulse:SetBlendMode("ADD")

local plate = CreateFrame("Frame", nil, f)
plate:SetSize(64, 16)
plate:SetPoint("TOP", well, "BOTTOM", 0, -2)
local plateBg = plate:CreateTexture(nil, "BACKGROUND")
plateBg:SetAllPoints()
plateBg:SetColorTexture(0.035, 0.038, 0.045, 0.94)
local nameText = plate:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nameText:SetPoint("CENTER")
nameText:SetWidth(60)
nameText:SetJustifyH("CENTER")
nameText:SetScale(0.9)

local function showIdleClass()
    local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    icon:ClearAllPoints()
    icon:SetSize(56, 56)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    if c then
        icon:SetTexCoord(c[1], c[2], c[3], c[4])
        classLetter:Hide()
        icon:SetAlpha(1)
    else
        icon:SetTexture(WHITE)
        icon:SetVertexColor(cc.r * 0.18, cc.g * 0.18, cc.b * 0.18, 1)
        icon:SetTexCoord(0, 1, 0, 1)
        classLetter:Show()
    end
end

local pips = {}
for i = 1, 5 do
    local p = f:CreateTexture(nil, "OVERLAY")
    p:SetTexture(WHITE)
    p:SetSize(8, 3)
    p:SetPoint("BOTTOM", f, "BOTTOM", (i - 3) * 11, 3)
    pips[i] = p
end

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
    pulse:SetAlpha(pulseLeft > 0 and math.min(0.16, pulseLeft * 0.28) or 0)
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
        icon:ClearAllPoints()
        icon:SetAllPoints()
        icon:SetTexture(tex)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetAlpha(1)
        classLetter:Hide()
        pcall(icon.SetDesaturated, icon, false)
        local label = name or ""
        if RH.healTarget then
            local ally = RH.SafeUnitText(UnitName, RH.healTarget)
            if ally and ally ~= "" then
                label = ally
            end
        end
        nameText:SetText(label)
        nameText:SetTextColor(0.94, 0.94, 0.92)
        if sweep and result and GetSpellCooldown then
            local ok, start, duration = pcall(GetSpellCooldown, result)
            if ok and type(start) == "number" and type(duration) == "number" and duration > 1.4 then
                sweep:SetCooldown(start, duration)
            end
        end
    else
        showIdleClass()
        pcall(icon.SetDesaturated, icon, false)
        local paused = RH.EnsureDB().enabled == false
        nameText:SetText(paused and "Off" or "Ready")
        nameText:SetTextColor(0.62, 0.64, 0.66)
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
            p:SetColorTexture(0.16, 0.17, 0.20, 0.9)
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
end)
RefreshMiniToggles()
