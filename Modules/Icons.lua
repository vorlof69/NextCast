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

local rail = CreateFrame("Frame", nil, f, "BackdropTemplate")
rail:SetSize(68, 14)
rail:SetPoint("TOP", 0, 0)
rail:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
rail:SetBackdropColor(0.035, 0.038, 0.045, 0.94)
rail:SetBackdropBorderColor(0.16, 0.17, 0.19, 1)

local function railBtn(text, x)
    local b = CreateFrame("Button", nil, rail)
    b:SetSize(22, 12)
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
local modeToggle = railBtn("AUTO", 1)
local cdToggle = railBtn("CDS", 23)
local burstToggle = railBtn("GO", 45)

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
    paintRail(burstToggle, RH.Burst and true or false, 0.95, 0.42, 0.32)
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
burstToggle:SetScript("OnClick", function()
    NextCast_Burst()
end)

local well = CreateFrame("Frame", nil, f, "BackdropTemplate")
well:SetSize(64, 64)
well:SetPoint("TOP", 0, -16)
well:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
well:SetBackdropColor(0.02, 0.022, 0.028, 0.96)
well:SetBackdropBorderColor(cc.r * 0.85, cc.g * 0.85, cc.b * 0.85, 1)

local icon = well:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 3, -3)
icon:SetPoint("BOTTOMRIGHT", -3, 3)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local sweep
pcall(function()
    sweep = CreateFrame("Cooldown", nil, well, "CooldownFrameTemplate")
    sweep:SetPoint("TOPLEFT", 3, -3)
    sweep:SetPoint("BOTTOMRIGHT", -3, 3)
    sweep:SetReverse(true)
    if sweep.SetHideCountdownNumbers then
        sweep:SetHideCountdownNumbers(true)
    end
end)

local pulse = well:CreateTexture(nil, "OVERLAY")
pulse:SetTexture(WHITE)
pulse:SetPoint("TOPLEFT", 3, -3)
pulse:SetPoint("BOTTOMRIGHT", -3, 3)
pulse:SetColorTexture(cc.r, cc.g, cc.b, 1)
pulse:SetAlpha(0)
pulse:SetBlendMode("ADD")

local caption = well:CreateTexture(nil, "OVERLAY")
caption:SetTexture(WHITE)
caption:SetPoint("BOTTOMLEFT", 3, 3)
caption:SetPoint("BOTTOMRIGHT", -3, 3)
caption:SetHeight(13)
caption:SetColorTexture(0.02, 0.022, 0.028, 0.82)
local nameText = well:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nameText:SetPoint("BOTTOM", 0, 4)
nameText:SetWidth(56)
nameText:SetJustifyH("CENTER")
nameText:SetScale(0.86)

local pips = {}
for i = 1, 5 do
    local p = f:CreateTexture(nil, "OVERLAY")
    p:SetTexture(WHITE)
    p:SetSize(8, 3)
    p:SetPoint("BOTTOM", f, "BOTTOM", (i - 3) * 11, 4)
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
        well:SetBackdropBorderColor(cc.r, cc.g, cc.b, 1)
    end
    if tex then
        icon:SetTexture(tex)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetAlpha(1)
        pcall(icon.SetDesaturated, icon, false)
        local label = name or ""
        if RH.healTarget then
            local ally = RH.SafeUnitText(UnitName, RH.healTarget)
            if ally and ally ~= "" then
                label = ally
            end
        end
        nameText:SetText(label)
        nameText:SetTextColor(0.96, 0.96, 0.94)
        caption:SetAlpha(0.82)
        if sweep and result and GetSpellCooldown then
            local ok, start, duration = pcall(GetSpellCooldown, result)
            if ok and type(start) == "number" and type(duration) == "number" and duration > 1.4 then
                sweep:SetCooldown(start, duration)
            end
        end
        if RH.healTarget then
            well:SetBackdropBorderColor(0.32, 0.82, 0.48, 1)
        end
    else
        local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetAlpha(0.92)
        pcall(icon.SetDesaturated, icon, false)
        if c then
            icon:SetTexCoord(c[1] + 0.012, c[2] - 0.012, c[3] + 0.012, c[4] - 0.012)
        else
            icon:SetTexCoord(0, 1, 0, 1)
        end
        local paused = RH.EnsureDB().enabled == false
        nameText:SetText(paused and "Off" or "")
        nameText:SetTextColor(0.62, 0.64, 0.66)
        caption:SetAlpha(paused and 0.82 or 0)
        well:SetBackdropBorderColor(cc.r * 0.45, cc.g * 0.45, cc.b * 0.45, 1)
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
