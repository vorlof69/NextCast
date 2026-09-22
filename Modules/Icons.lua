local RH = RubimRH
local WHITE = "Interface\\Buttons\\WHITE8X8"
local class = select(2, UnitClass("player")) or "ROGUE"
local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or { r = 0.78, g = 0.64, b = 0.32 }

local f = CreateFrame("Frame", "NextCastIcon", UIParent)
RH.IconFrame = f
f:SetSize(64, 108)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)

local function flyBtn(label, w)
    local b = CreateFrame("Button", nil, f, "BackdropTemplate")
    b:SetSize(w or 31, 16)
    b:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    b:SetBackdropColor(0.08, 0.06, 0.02, 0.92)
    b:SetBackdropBorderColor(0.85, 0.68, 0.22, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER", 0, 0)
    b.text:SetText(label)
    b.text:SetTextColor(1, 0.82, 0)
    return b
end
local modeToggle = flyBtn("AUTO", 31)
modeToggle:SetPoint("TOPLEFT", 0, 0)
local cdToggle = flyBtn("CDS", 31)
cdToggle:SetPoint("TOPRIGHT", 0, 0)

local function paintRail(btn, on)
    if on then
        btn:SetBackdropColor(0.38, 0.28, 0.08, 1)
        btn.text:SetTextColor(1, 0.92, 0.45)
    else
        btn:SetBackdropColor(0.08, 0.06, 0.02, 0.92)
        btn.text:SetTextColor(0.82, 0.68, 0.32)
    end
end

local function RefreshMiniToggles()
    local d = RH.EnsureDB()
    local mode = d.mode or "auto"
    modeToggle.text:SetText(mode == "single" and "ST" or (mode == "aoe" and "AOE" or "AUTO"))
    paintRail(modeToggle, mode == "aoe")
    paintRail(cdToggle, d.cooldowns ~= false)
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

local well = CreateFrame("Frame", nil, f, "BackdropTemplate")
well:SetSize(64, 64)
well:SetPoint("TOP", 0, -18)
well:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
well:SetBackdropColor(0, 0, 0, 1)
well:SetBackdropBorderColor(0.85, 0.68, 0.22, 1)

local icon = well:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 4, -4)
icon:SetPoint("BOTTOMRIGHT", -4, 4)
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

local plate = flyBtn("Ready", 64)
plate:SetHeight(16)
plate:SetPoint("TOP", well, "BOTTOM", 0, -4)
local nameText = plate.text
nameText:SetWidth(58)
nameText:SetJustifyH("CENTER")

local function showIdleClass()
    local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
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
    p:SetPoint("BOTTOM", plate, "TOP", (i - 3) * 11, 3)
    pips[i] = p
end

local function toggleEnabled()
    local d = RH.EnsureDB()
    d.enabled = d.enabled == false
    if RH.RefreshDashboard then
        RH.RefreshDashboard()
    end
end

local dragging
f:SetScript("OnDragStart", function(s)
    if not RH.EnsureDB().locked then
        dragging = true
        s:StartMoving()
    end
end)
f:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    dragging = nil
    RH.SaveFramePosition(s, "position")
end)
f:SetScript("OnMouseUp", function(_, b)
    if dragging then
        return
    end
    if b == "RightButton" and RH.ToggleMenu then
        RH.ToggleMenu()
    elseif b == "LeftButton" then
        toggleEnabled()
    end
end)
well:EnableMouse(true)
well:RegisterForDrag("LeftButton")
well:SetScript("OnDragStart", function()
    if not RH.EnsureDB().locked then
        dragging = true
        f:StartMoving()
    end
end)
well:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    dragging = nil
    RH.SaveFramePosition(f, "position")
end)
well:SetScript("OnMouseUp", function(_, b)
    if dragging then
        return
    end
    if b == "RightButton" and RH.ToggleMenu then
        RH.ToggleMenu()
    end
end)
plate:SetScript("OnMouseUp", function(_, b)
    if b == "RightButton" and RH.ToggleMenu then
        RH.ToggleMenu()
    else
        toggleEnabled()
    end
end)
plate:SetScript("OnEnter", function(s)
    s:SetBackdropBorderColor(1, 0.88, 0.35, 1)
    if GameTooltip then
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:AddLine("NextCast", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click  On / Off", 1, 1, 1)
        GameTooltip:AddLine("Right-click  Settings", 0.84, 0.86, 0.90)
        GameTooltip:Show()
    end
end)
plate:SetScript("OnLeave", function(s)
    s:SetBackdropBorderColor(0.85, 0.68, 0.22, 1)
    if GameTooltip then
        GameTooltip:Hide()
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
    local paused = RH.EnsureDB().enabled == false
    local result = (not paused) and RH.MainRotation() or nil
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
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
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
        nameText:SetTextColor(1, 0.82, 0)
        if sweep and result and GetSpellCooldown then
            local ok, start, duration = pcall(GetSpellCooldown, result)
            if ok and type(start) == "number" and type(duration) == "number" and duration > 1.4 then
                sweep:SetCooldown(start, duration)
            end
        end
    else
        showIdleClass()
        nameText:SetText(paused and "Off" or "Ready")
        nameText:SetTextColor(paused and 0.85 or 1, paused and 0.22 or 0.82, paused and 0.12 or 0)
        pcall(icon.SetDesaturated, icon, paused)
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
