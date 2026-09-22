local RH = RubimRH

-- GriphRotations ExtraIcon protocol
-- https://github.com/gryph1231/GriphRotations/blob/main/Rubim-RH_ExtraIcon/rubim-rh_extraicon.lua
--
-- This is the strip GGLoader is calibrated to. NextCast draws it so the
-- ExtraIcon addon (and TellMeWhen) are not required.
--
--   parent  240x30  TOPLEFT -29, 12  unparented
--           scale = 0.42666670680046 * (1080 / physicalHeight)
--   cc      1x1   @ 0,0     cyan flag
--   kick    1x1   @ 30,0    cyan flag
--   ST      30x30 @ 60,0    main rotation texture
--           Attack is pulsed once on ST, then hidden (Action IsAttacking).
--           Bind Attack on the scanned bar. No extra StartAttack macro.
--   AoE     30x30 @ 90,0    AoE / heal (secondary)
--   glad    30x30 @ 120,0   PvP CC texture
--   passive 30x30 @ 150,0   defensive texture
--   TargetColor 1x1 @ 737,-12  named ExtraIcon child  (Griph heal-unit UC)
--   Action TargetColor 1x1 @ UIParent TOPLEFT 163, 0  (Action HealingEngine)
--
-- Dual protocol so ExtraIcon GGL and Action GGL both see the heal unit.
-- Heals/buffs: ExtraIcon GGL clicks ST and presses the matching bar key.
-- Put the NextCast macro (Modules/Macros.lua) on that slot via
-- /nc → Macros → PLACE ON BAR so the press is [@player]/[@partyN], not
-- the raw spell on the current enemy.
--
-- Contrast / gamma / nameplate CVars are NOT touched.

local CYAN_ON = { 0, 1, 1, 1 }
local CYAN_OFF = { 0, 1, 1, 0 }
local SCALE_K = 0.42666670680046
local TARGET_SCALE_K = 0.71111112833023
local REF_HEIGHT = 1080

local function MakePixel(name, parent, w, h, x, y, r, g, b, a)
    local f = CreateFrame("Frame", name, parent)
    f:SetFrameStrata("TOOLTIP")
    f:EnableMouse(false)
    f:SetSize(w, h)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(r, g, b, a)
    f.texture = tex
    f:Show()
    return f
end

local topIcons = CreateFrame("Frame", "NextCastExtraIcon", UIParent)
topIcons:SetFrameStrata("TOOLTIP")
topIcons:SetToplevel(true)
topIcons:EnableMouse(false)
topIcons:SetSize(240, 30)
topIcons:SetPoint("TOPLEFT", -29, 12)
topIcons.texture = topIcons:CreateTexture(nil, "BACKGROUND")
topIcons.texture:SetAllPoints(true)
topIcons.texture:SetColorTexture(0, 0, 0, 1)
topIcons:Show()

local ccIcon = MakePixel(nil, topIcons, 1, 1, 0, 0, 0, 1, 1, 0)
local kickIcon = MakePixel(nil, topIcons, 1, 1, 30, 0, 0, 1, 1, 0)
local stIcon = MakePixel(nil, topIcons, 30, 30, 60, 0, 0, 1, 0, 0)
local aoeIcon = MakePixel(nil, topIcons, 30, 30, 90, 0, 1, 1, 0, 0)
local gladiatorIcon = MakePixel(nil, topIcons, 30, 30, 120, 0, 0, 0, 1, 0)
local passiveIcon = MakePixel(nil, topIcons, 30, 30, 150, 0, 1, 0, 0, 0)
local targetColor = MakePixel("NextCastTargetColor", topIcons, 1, 1, 737, -12, 0, 0, 0, 1)

-- Action HealingEngine pixel. Action GGL samples UIParent TOPLEFT 163,0
-- by the global name TargetColor. ExtraIcon GGL samples the child at 737,-12.
-- Both get the same UC color so either reader works. No TellMeWhen.
local actionTargetColor = CreateFrame("Frame", "TargetColor", UIParent)
actionTargetColor:SetFrameStrata("TOOLTIP")
actionTargetColor:SetToplevel(true)
actionTargetColor:EnableMouse(false)
actionTargetColor:SetSize(1, 1)
actionTargetColor:SetScale(1)
actionTargetColor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 163, 0)
actionTargetColor.texture = actionTargetColor:CreateTexture(nil, "OVERLAY")
actionTargetColor.texture:SetAllPoints()
actionTargetColor.texture:SetColorTexture(0, 0, 0, 1)
actionTargetColor:Show()

RH.topIcons = topIcons
RH.ccIcon = ccIcon
RH.kickIcon = kickIcon
RH.stIcon = stIcon
RH.aoeIcon = aoeIcon
RH.gladiatorIcon = gladiatorIcon
RH.passiveIcon = passiveIcon
RH.ShownMain = topIcons
RH.TargetColor = targetColor
RH.ActionTargetColor = actionTargetColor
-- Older NextCast / Action docs named the rotation pixel ActionLiteMiniFrame.
_G.ActionLiteMiniFrame = stIcon
_G.TargetColor = actionTargetColor

-- Action Data.UC heal-unit colors. Index layout matches HealingEngine:
-- raid1-40, party1-4, player, focus, partypet1-4, raidpet1-40.
local UC = {
    [0] = { 0, 0, 0, 1.0 },
    [1] = { 0.192157, 0.878431, 0.015686, 1.0 },
    [2] = { 0.780392, 0.788235, 0.745098, 1.0 },
    [3] = { 0.498039, 0.184314, 0.521569, 1.0 },
    [4] = { 0.627451, 0.905882, 0.882353, 1.0 },
    [5] = { 0.145098, 0.658824, 0.121569, 1.0 },
    [6] = { 0.639216, 0.490196, 0.921569, 1.0 },
    [7] = { 0.172549, 0.368627, 0.427451, 1.0 },
    [8] = { 0.949020, 0.333333, 0.980392, 1.0 },
    [9] = { 0.109804, 0.388235, 0.980392, 1.0 },
    [10] = { 0.615686, 0.694118, 0.435294, 1.0 },
    [11] = { 0.066667, 0.243137, 0.572549, 1.0 },
    [12] = { 0.113725, 0.129412, 1.000000, 1.0 },
    [13] = { 0.592157, 0.023529, 0.235294, 1.0 },
    [14] = { 0.545098, 0.439216, 1.000000, 1.0 },
    [15] = { 0.890196, 0.800000, 0.854902, 1.0 },
    [16] = { 0.513725, 0.854902, 0.639216, 1.0 },
    [17] = { 0.078431, 0.541176, 0.815686, 1.0 },
    [18] = { 0.109804, 0.184314, 0.666667, 1.0 },
    [19] = { 0.650980, 0.572549, 0.098039, 1.0 },
    [20] = { 0.541176, 0.466667, 0.027451, 1.0 },
    [21] = { 0.000000, 0.988235, 0.462745, 1.0 },
    [22] = { 0.211765, 0.443137, 0.858824, 1.0 },
    [23] = { 0.949020, 0.949020, 0.576471, 1.0 },
    [24] = { 0.972549, 0.800000, 0.682353, 1.0 },
    [25] = { 0.031373, 0.619608, 0.596078, 1.0 },
    [26] = { 0.670588, 0.925490, 0.513725, 1.0 },
    [27] = { 0.647059, 0.945098, 0.031373, 1.0 },
    [28] = { 0.058824, 0.490196, 0.054902, 1.0 },
    [29] = { 0.050980, 0.992157, 0.239216, 1.0 },
    [30] = { 0.949020, 0.721569, 0.388235, 1.0 },
    [31] = { 0.254902, 0.749020, 0.627451, 1.0 },
    [32] = { 0.470588, 0.454902, 0.603922, 1.0 },
    [33] = { 0.384314, 0.062745, 0.266667, 1.0 },
    [34] = { 0.639216, 0.168627, 0.447059, 1.0 },
    [35] = { 0.874510, 0.058824, 0.400000, 1.0 },
    [36] = { 0.925490, 0.070588, 0.713725, 1.0 },
    [37] = { 0.098039, 0.803922, 0.905882, 1.0 },
    [38] = { 0.243137, 0.015686, 0.325490, 1.0 },
    [39] = { 0.847059, 0.376471, 0.921569, 1.0 },
    [40] = { 0.341176, 0.533333, 0.231373, 1.0 },
    [41] = { 0.345098, 0.239216, 0.741176, 1.0 },
    [42] = { 0.407843, 0.501961, 0.086275, 1.0 },
    [43] = { 0.160784, 0.470588, 0.164706, 1.0 },
    [44] = { 0.725490, 0.572549, 0.647059, 1.0 },
    [45] = { 0.788235, 0.470588, 0.858824, 1.0 },
    [46] = { 0.615686, 0.227451, 0.988235, 1.0 },
    [47] = { 0.486275, 0.176471, 1.000000, 1.0 },
    [48] = { 0.031373, 0.572549, 0.152941, 1.0 },
    [49] = { 0.874510, 0.239216, 0.239216, 1.0 },
    [50] = { 0.117647, 0.870588, 0.635294, 1.0 },
    [51] = { 0.458824, 0.945098, 0.784314, 1.0 },
    [52] = { 0.239216, 0.654902, 0.278431, 1.0 },
    [53] = { 0.537255, 0.066667, 0.905882, 1.0 },
    [54] = { 0.333333, 0.415686, 0.627451, 1.0 },
    [55] = { 0.576471, 0.811765, 0.011765, 1.0 },
    [56] = { 0.517647, 0.164706, 0.627451, 1.0 },
    [57] = { 0.439216, 0.074510, 0.941176, 1.0 },
    [58] = { 0.984314, 0.854902, 0.376471, 1.0 },
    [59] = { 0.082353, 0.286275, 0.890196, 1.0 },
    [60] = { 0.058824, 0.003922, 0.964706, 1.0 },
    [61] = { 0.956863, 0.509804, 0.949020, 1.0 },
    [62] = { 0.474510, 0.858824, 0.031373, 1.0 },
    [63] = { 0.509804, 0.882353, 0.423529, 1.0 },
    [64] = { 0.337255, 0.647059, 0.427451, 1.0 },
    [65] = { 0.611765, 0.525490, 0.352941, 1.0 },
    [66] = { 0.921569, 0.129412, 0.913725, 1.0 },
    [67] = { 0.117647, 0.933333, 0.862745, 1.0 },
    [68] = { 0.733333, 0.015686, 0.937255, 1.0 },
    [69] = { 0.819608, 0.392157, 0.686275, 1.0 },
    [70] = { 0.823529, 0.976471, 0.541176, 1.0 },
    [71] = { 0.043137, 0.305882, 0.800000, 1.0 },
    [72] = { 0.737255, 0.270588, 0.760784, 1.0 },
    [73] = { 0.807843, 0.368627, 0.058824, 1.0 },
    [74] = { 0.364706, 0.078431, 0.078431, 1.0 },
    [75] = { 0.094118, 0.901961, 1.000000, 1.0 },
    [76] = { 0.772549, 0.690196, 0.047059, 1.0 },
    [77] = { 0.415686, 0.784314, 0.854902, 1.0 },
    [78] = { 0.470588, 0.733333, 0.047059, 1.0 },
    [79] = { 0.619608, 0.086275, 0.572549, 1.0 },
    [80] = { 0.517647, 0.352941, 0.678431, 1.0 },
    [81] = { 0.003922, 0.149020, 0.694118, 1.0 },
    [82] = { 0.454902, 0.619608, 0.831373, 1.0 },
    [83] = { 0.674510, 0.741176, 0.050980, 1.0 },
    [84] = { 0.560784, 0.713725, 0.784314, 1.0 },
    [85] = { 0.400000, 0.721569, 0.737255, 1.0 },
    [86] = { 0.094118, 0.274510, 0.392157, 1.0 },
    [87] = { 0.298039, 0.498039, 0.462745, 1.0 },
    [88] = { 0.125490, 0.196078, 0.027451, 1.0 },
    [89] = { 0.937255, 0.564706, 0.368627, 1.0 },
    [90] = { 0.929412, 0.592157, 0.501961, 1.0 },
}
local UnitToColorIndex = {}
for i = 1, 40 do
    UnitToColorIndex["raid" .. i] = i
end
for i = 1, 4 do
    UnitToColorIndex["party" .. i] = 40 + i
end
UnitToColorIndex.player = 45
UnitToColorIndex.focus = 46
for i = 1, 4 do
    UnitToColorIndex["partypet" .. i] = 46 + i
end
for i = 1, 40 do
    UnitToColorIndex["raidpet" .. i] = 50 + i
end

local lastColorIndex = 0
function RH.UpdateTargetColorPixel(unit)
    if unit == "mouseover" or unit == "focus" or unit == "target" then
        unit = RH.ResolveUnit and RH.ResolveUnit(unit) or unit
        if unit == "mouseover" or unit == "focus" or unit == "target" then
            unit = nil
        end
    end
    local index = (unit and UnitToColorIndex[unit]) or 0
    if index ~= lastColorIndex then
        lastColorIndex = index
        local c = UC[index] or UC[0]
        targetColor.texture:SetColorTexture(c[1], c[2], c[3], c[4])
        if actionTargetColor and actionTargetColor.texture then
            actionTargetColor.texture:SetColorTexture(c[1], c[2], c[3], c[4])
        end
    end
end

local interruptNames = {
    Kick = true,
    ["Shield Bash"] = true,
    Pummel = true,
    Counterspell = true,
    ["Earth Shock"] = true,
}
local ccNames = {
    ["Cheap Shot"] = true,
    ["Kidney Shot"] = true,
    Gouge = true,
    Sap = true,
    ["Hammer of Justice"] = true,
    Polymorph = true,
    Fear = true,
    ["Howl of Terror"] = true,
    ["Psychic Scream"] = true,
    ["Frost Nova"] = true,
    Bash = true,
    ["Scatter Shot"] = true,
    Intimidation = true,
    ["Concussion Blow"] = true,
    ["Intimidating Shout"] = true,
    Hamstring = true,
    ["Wing Clip"] = true,
    ["Concussive Shot"] = true,
    ["Frost Shock"] = true,
}
local aoeNames = {
    ["Blade Flurry"] = true,
    Cleave = true,
    Whirlwind = true,
    ["Sweeping Strikes"] = true,
    Consecration = true,
    ["Holy Wrath"] = true,
    ["Multi-Shot"] = true,
    Volley = true,
    ["Arcane Explosion"] = true,
    Blizzard = true,
    ["Cone of Cold"] = true,
    Flamestrike = true,
    ["Holy Nova"] = true,
    ["Prayer of Healing"] = true,
    ["Magma Totem"] = true,
    ["Chain Lightning"] = true,
    ["Fire Nova"] = true,
    ["Seed of Corruption"] = true,
    Hellfire = true,
    ["Rain of Fire"] = true,
    Swipe = true,
    Hurricane = true,
    ["Wild Growth"] = true,
    Tranquility = true,
    ["Chain Heal"] = true,
    ["Light's Vigil"] = true,
}
local defensiveNames = {
    Evasion = true,
    Vanish = true,
    ["Shield Wall"] = true,
    ["Last Stand"] = true,
    ["Shield Block"] = true,
    ["Divine Protection"] = true,
    ["Divine Shield"] = true,
    ["Ice Block"] = true,
    Blink = true,
    Fade = true,
    Barkskin = true,
    ["Feign Death"] = true,
    ["Nature's Grasp"] = true,
    ["Stoneclaw Totem"] = true,
    ["Survival Instincts"] = true,
}
function RH.IsInterruptSpell(name)
    return name and interruptNames[name] == true
end
function RH.IsCCSpell(name)
    return name and ccNames[name] == true
end

local CLASS_INTERRUPTS = {
    ROGUE = { { "Kick", 1766 } },
    WARRIOR = { { "Shield Bash", 72 }, { "Pummel", 6552 } },
    MAGE = { { "Counterspell", 2139 } },
    SHAMAN = { { "Earth Shock", 8042 } },
    DRUID = { { "Bash", 5211 } },
    HUNTER = { { "Scatter Shot", 19503 }, { "Intimidation", 19577 } },
}
local interruptCache = {}
local function IndependentKickTexture()
    if RH.Interrupts == false then
        return nil
    end
    if not RH.ShouldInterrupt or not RH.ShouldInterrupt() then
        return nil
    end
    local class = select(2, UnitClass("player"))
    local list = CLASS_INTERRUPTS[class]
    if not list then
        return nil
    end
    if not interruptCache[class] then
        interruptCache[class] = {}
        for i, entry in ipairs(list) do
            interruptCache[class][i] = RH.Named(entry[1], entry[2])
        end
    end
    for _, spell in ipairs(interruptCache[class]) do
        if RH.Ready(spell, true) then
            return spell:Texture()
        end
    end
    return nil
end

local function PaintFlag(frame, on)
    local c = on and CYAN_ON or CYAN_OFF
    frame.texture:SetTexture(nil)
    frame.texture:SetColorTexture(c[1], c[2], c[3], c[4])
end

local function PaintTexture(frame, texture)
    if texture then
        frame.texture:SetTexture(texture)
        frame.texture:SetVertexColor(1, 1, 1, 1)
    else
        frame.texture:SetTexture(nil)
    end
end

local pixelH = 0
local function ApplyScale(height)
    local myscale = SCALE_K * (REF_HEIGHT / height)
    topIcons:SetParent(nil)
    topIcons:ClearAllPoints()
    topIcons:SetPoint("TOPLEFT", nil, "TOPLEFT", -29, 12)
    topIcons:SetScale(myscale)
    topIcons:SetFrameStrata("TOOLTIP")
    topIcons:SetToplevel(true)
    topIcons:Show()
    local parentScale = topIcons:GetEffectiveScale() or 1
    if parentScale <= 0 then
        parentScale = 1
    end
    targetColor:SetScale((TARGET_SCALE_K * (REF_HEIGHT / height)) / parentScale)
    if not targetColor:IsShown() then
        targetColor:Show()
    end
end

function RH.LayoutShownMain()
    local height
    if GetPhysicalScreenSize then
        local ok, _, h = pcall(GetPhysicalScreenSize)
        if ok and not HeroLib.Secret(h) and type(h) == "number" and h > 0 then
            height = h
        end
    end
    if not height then
        if pixelH == 0 then
            pixelH = REF_HEIGHT
            ApplyScale(REF_HEIGHT)
        end
        return
    end
    if height == pixelH then
        return
    end
    pixelH = height
    ApplyScale(height)
end

local scaleEvents = CreateFrame("Frame")
scaleEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(scaleEvents.RegisterEvent, scaleEvents, "UI_SCALE_CHANGED")
pcall(scaleEvents.RegisterEvent, scaleEvents, "DISPLAY_SIZE_CHANGED")
scaleEvents:SetScript("OnEvent", function()
    pixelH = 0
    RH.LayoutShownMain()
end)

local calibrated = false
function RH.GGLCalibrate(enable)
    calibrated = enable and true or false
    RH.gglCalibrating = calibrated
    if calibrated then
        local icons = RH.UniversalIcons or {}
        PaintFlag(ccIcon, true)
        PaintFlag(kickIcon, true)
        PaintTexture(stIcon, icons[1] or 133667)
        PaintTexture(aoeIcon, icons[2] or 133663)
        PaintTexture(gladiatorIcon, icons[3] or 133658)
        PaintTexture(passiveIcon, icons[4] or 133653)
        local c = UC[45]
        targetColor.texture:SetColorTexture(c[1], c[2], c[3], c[4])
        if actionTargetColor and actionTargetColor.texture then
            actionTargetColor.texture:SetColorTexture(c[1], c[2], c[3], c[4])
        end
        lastColorIndex = -1
        print("|cffc8ccd4NextCast|r: ExtraIcon + Action TargetColor calibration ON. /nc ggl again to stop.")
    else
        PaintFlag(ccIcon, false)
        PaintFlag(kickIcon, false)
        PaintTexture(stIcon, nil)
        PaintTexture(aoeIcon, nil)
        PaintTexture(gladiatorIcon, nil)
        PaintTexture(passiveIcon, nil)
        targetColor.texture:SetColorTexture(UC[0][1], UC[0][2], UC[0][3], UC[0][4])
        if actionTargetColor and actionTargetColor.texture then
            actionTargetColor.texture:SetColorTexture(UC[0][1], UC[0][2], UC[0][3], UC[0][4])
        end
        lastColorIndex = 0
        print("|cffc8ccd4NextCast|r: ExtraIcon calibration OFF.")
    end
end

local lastST
function RH.PaintShownMain(result)
    if calibrated then
        return
    end
    local name, tex
    if result then
        name, tex = HeroCache:SpellInfo(result)
        if result == 6603 or name == "Attack" or name == "StartAttack" then
            name = "StartAttack"
            tex = RH.StartAttackTexture and RH.StartAttackTexture() or tex
        else
            tex = RH.OutputTexture and RH.OutputTexture(name, tex) or tex
        end
    end
    local kickTex = IndependentKickTexture()
    local isKick = name and interruptNames[name] == true
    local isCC = name and ccNames[name] == true
    local isAoE = name and aoeNames[name] == true
    local isDefensive = name and defensiveNames[name] == true
    local playerCasting = RH.Player and RH.Player:IsCasting()

    PaintFlag(ccIcon, isCC == true)
    PaintFlag(kickIcon, kickTex ~= nil or isKick == true)

    -- Hold ST/AoE while the player is mid-cast or mid-channel so the reader
    -- does not clip the current spell by jumping to the next press.
    if playerCasting and lastST then
        RH.UpdateTargetColorPixel(RH.healTarget)
        return
    end

    PaintTexture(stIcon, tex)
    lastST = tex

    if RH.healTarget or isAoE or RH.AoE then
        PaintTexture(aoeIcon, tex)
    else
        PaintTexture(aoeIcon, nil)
    end

    if isCC then
        PaintTexture(gladiatorIcon, tex)
    else
        PaintTexture(gladiatorIcon, nil)
    end

    if isDefensive then
        PaintTexture(passiveIcon, tex)
    else
        PaintTexture(passiveIcon, nil)
    end

    RH.UpdateTargetColorPixel(RH.healTarget)
end

RH.LayoutShownMain()
