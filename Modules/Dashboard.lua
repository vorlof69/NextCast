local RH = RubimRH
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GOLD = { r = 0.85, g = 0.68, b = 0.22 }
local function goldBox(edge)
    return {
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = edge or 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }
end
local token = select(2, UnitClass("player")) or "ROGUE"
local className = select(1, UnitClass("player")) or token
local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[token] or { r = 0.78, g = 0.64, b = 0.32 }
local specs = {
    WARRIOR = { "Automatic", "Arms", "Fury", "Protection" },
    PALADIN = { "Automatic", "Retribution", "Protection", "Holy" },
    HUNTER = { "Automatic", "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Automatic", "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Automatic", "Shadow", "Discipline", "Holy" },
    SHAMAN = { "Automatic", "Enhancement", "Elemental", "Restoration" },
    MAGE = { "Automatic", "Frost", "Fire", "Arcane" },
    WARLOCK = { "Automatic", "Affliction", "Demonology", "Destruction" },
    DRUID = { "Automatic", "Feral", "Balance", "Restoration" },
}
local oldMenu = RH.MenuFrame
if oldMenu then
    oldMenu:Hide()
end

local frame = CreateFrame("Frame", "NextCastDashboard", UIParent, "BackdropTemplate")
RH.MenuFrame = frame
frame:SetSize(800, 548)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:Hide()
do
    local gold = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    }
    if not pcall(frame.SetBackdrop, frame, gold) then
        gold.bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
        gold.edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border"
        frame:SetBackdrop(gold)
    end
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
end
local titlebg = frame:CreateTexture(nil, "BORDER")
titlebg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
if not titlebg:GetTexture() then
    titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
end
titlebg:SetPoint("TOPLEFT", 9, -6)
titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)
local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
local crest = frame:CreateTexture(nil, "ARTWORK")
crest:SetSize(26, 26)
crest:SetPoint("TOPLEFT", 16, -8)
crest:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
if coords then
    crest:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", crest, "RIGHT", 8, 0)
title:SetText("NextCast")
local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("LEFT", title, "RIGHT", 10, 0)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 1)

local function skinButton(parent, w, h, label)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    b:SetBackdropColor(0, 0, 0, 0.55)
    b:SetBackdropBorderColor(0.75, 0.6, 0.22, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(label or "")
    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(1, 0.82, 0.2, 1)
        s.text:SetTextColor(1, 0.94, 0.55)
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(0.75, 0.6, 0.22, 1)
        if not s.held then
            s.text:SetTextColor(1, 0.82, 0)
        end
    end)
    return b
end
local function panelButton(parent, w, h, label)
    local ok, b = pcall(function()
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(w, h)
        btn:SetText(label or "")
        btn.text = btn:GetFontString()
        return btn
    end)
    if ok and b then
        if not b.text then
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            b.text:SetPoint("CENTER")
            b.text:SetText(label or "")
        end
        return b
    end
    return skinButton(parent, w, h, label)
end
local active = panelButton(frame, 64, 22, "ON")
active:SetPoint("RIGHT", close, "LEFT", -4, -1)
local aoe = panelButton(frame, 56, 22, "AOE")
aoe:SetPoint("RIGHT", active, "LEFT", -4, 0)
local cds = panelButton(frame, 56, 22, "CDS")
cds:SetPoint("RIGHT", aoe, "LEFT", -4, 0)

local pages = {}
local tabs = {}
local selected = 1
for i = 1, 3 do
    pages[i] = CreateFrame("Frame", nil, frame)
    pages[i]:SetPoint("TOPLEFT", 18, -36)
    pages[i]:SetPoint("BOTTOMRIGHT", -18, 16)
    pages[i]:Hide()
end
local labels = { "Play", "Rotation", "Spells" }
local function SelectTab(index)
    selected = index
    for i, page in ipairs(pages) do
        page:SetShown(i == index)
    end
    for i, tab in ipairs(tabs) do
        local on = i == index
        if on and PanelTemplates_SelectTab then
            pcall(PanelTemplates_SelectTab, tab)
        elseif (not on) and PanelTemplates_DeselectTab then
            pcall(PanelTemplates_DeselectTab, tab)
        end
        if tab.text then
            tab.text:SetTextColor(on and 1 or 0.72, on and 0.82 or 0.7, on and 0 or 0.45)
        end
        if tab.SetBackdropColor then
            pcall(tab.SetBackdropColor, tab, 0, 0, 0, on and 0.7 or 0.4)
            pcall(tab.SetBackdropBorderColor, tab, 0.85, 0.68, 0.22, on and 1 or 0.7)
        end
    end
    if index == 3 and RH.RefreshClassDashboard then
        RH.RefreshClassDashboard()
    end
end
for i, label in ipairs(labels) do
    local b
    local ok, tab = pcall(function()
        return CreateFrame("Button", "NextCastTab" .. i, frame, "CharacterFrameTabButtonTemplate")
    end)
    if ok and tab then
        b = tab
        b:SetText(label)
        b.text = b:GetFontString()
        if PanelTemplates_TabResize then
            pcall(PanelTemplates_TabResize, b, 0, 140)
        end
    else
        b = skinButton(frame, 128, 24, label)
    end
    if i == 1 then
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 12)
    else
        b:ClearAllPoints()
        b:SetPoint("LEFT", tabs[i - 1], "RIGHT", -8, 0)
    end
    b:SetFrameLevel((frame:GetFrameLevel() or 1) + 4)
    b:SetScript("OnClick", function()
        SelectTab(i)
    end)
    tabs[i] = b
end

local function card(parent, titleText, top, height)
    local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    c:SetPoint("TOPLEFT", 4, top)
    c:SetPoint("TOPRIGHT", -4, top)
    c:SetHeight(height)
    c:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    c:SetBackdropColor(0.06, 0.06, 0.06, 0.72)
    c:SetBackdropBorderColor(0.72, 0.58, 0.22, 1)
    local titleTextFS = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTextFS:SetPoint("TOPLEFT", 16, -11)
    titleTextFS:SetText(titleText)
    local line = c:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetPoint("TOPLEFT", 14, -30)
    line:SetPoint("TOPRIGHT", -14, -30)
    line:SetHeight(1)
    line:SetColorTexture(0.55, 0.44, 0.16, 0.7)
    return c
end

local function tip(owner, titleLine, body)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(titleLine, 1, 0.82, 0.35)
    if body then
        GameTooltip:AddLine(body, 0.90, 0.91, 0.93, true)
    end
    GameTooltip:Show()
end

local function switchOn(d, w)
    if w.defaultOn then
        return d[w.key] ~= false
    end
    return d[w.key] == true
end

local function switch(parent, label, key, x, y, helpText, defaultOn)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(360, 28)
    b:SetPoint("TOPLEFT", x, y)
    b.key = key
    b.isSwitch = true
    b.defaultOn = defaultOn ~= false
    b.track = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.track:SetSize(36, 18)
    b.track:SetPoint("LEFT")
    b.track:SetBackdrop(goldBox(10))
    b.knob = b.track:CreateTexture(nil, "OVERLAY")
    b.knob:SetTexture(WHITE)
    b.knob:SetSize(12, 12)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.track, "RIGHT", 10, 0)
    b.text:SetText(label)
    b:SetScript("OnClick", function()
        local d = RH.EnsureDB()
        local on = switchOn(d, b)
        d[key] = not on
        RH.RefreshDashboard()
    end)
    b:SetScript("OnEnter", function()
        b.text:SetTextColor(1, 0.88, 0.58)
        if helpText then
            tip(b, label, helpText)
        end
    end)
    b:SetScript("OnLeave", function()
        b.text:SetTextColor(0.86, 0.87, 0.90)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    return b
end

local function slider(parent, label, key, minV, maxV, step, x, y, w, suffix)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetSize(w, 44)
    wrap:SetPoint("TOPLEFT", x, y)
    wrap.key = key
    wrap.isSlider = true
    wrap.minV, wrap.maxV, wrap.step = minV, maxV, step or 1
    wrap.suffix = suffix or ""
    local cap = wrap:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cap:SetPoint("TOPLEFT", 0, 0)
    cap:SetText(string.upper(label))
    cap:SetTextColor(0.52, 0.54, 0.58)
    wrap.valueText = wrap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wrap.valueText:SetPoint("TOPRIGHT", 0, 0)
    wrap.track = CreateFrame("Frame", nil, wrap, "BackdropTemplate")
    wrap.track:SetHeight(8)
    wrap.track:SetPoint("BOTTOMLEFT", 0, 6)
    wrap.track:SetPoint("BOTTOMRIGHT", 0, 6)
    wrap.track:SetBackdrop(goldBox(8))
    wrap.track:SetBackdropColor(0, 0, 0, 0.7)
    wrap.track:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    wrap.fill = wrap.track:CreateTexture(nil, "ARTWORK")
    wrap.fill:SetTexture(WHITE)
    wrap.fill:SetPoint("TOPLEFT", 2, -2)
    wrap.fill:SetPoint("BOTTOMLEFT", 2, 2)
    wrap.fill:SetColorTexture(GOLD.r, GOLD.g, GOLD.b, 1)
    wrap.thumb = CreateFrame("Button", nil, wrap.track, "BackdropTemplate")
    wrap.thumb:SetSize(14, 14)
    wrap.thumb:SetBackdrop(goldBox(8))
    wrap.thumb:SetBackdropColor(0.95, 0.88, 0.55, 1)
    wrap.thumb:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    local function clamp(v)
        v = tonumber(v) or minV
        v = math.max(minV, math.min(maxV, v))
        if step and step > 0 then
            v = math.floor((v - minV) / step + 0.5) * step + minV
        end
        return v
    end
    function wrap:Paint(v)
        v = clamp(v)
        local pct = (v - minV) / math.max(1, maxV - minV)
        local tw = wrap.track:GetWidth() or w
        wrap.fill:SetWidth(math.max(2, (tw - 2) * pct))
        wrap.thumb:ClearAllPoints()
        wrap.thumb:SetPoint("CENTER", wrap.track, "LEFT", 7 + (tw - 14) * pct, 0)
        wrap.valueText:SetText((wrap.step < 1 and string.format("%.1f", v) or tostring(v)) .. wrap.suffix)
    end
    local function fromCursor()
        local mx = GetCursorPosition()
        local scale = wrap.track:GetEffectiveScale()
        local left = wrap.track:GetLeft() or 0
        local tw = wrap.track:GetWidth() or w
        local pct = ((mx / scale) - left) / math.max(1, tw)
        pct = math.max(0, math.min(1, pct))
        return clamp(minV + pct * (maxV - minV))
    end
    wrap.track:EnableMouse(true)
    wrap.dragging = false
    local function stopDrag()
        wrap.dragging = false
        wrap.track:SetScript("OnUpdate", nil)
    end
    wrap.track:SetScript("OnMouseDown", function()
        wrap.dragging = true
        wrap:Apply(fromCursor())
        wrap.track:SetScript("OnUpdate", function()
            local down = true
            if IsMouseButtonDown then
                local ok, v = pcall(IsMouseButtonDown, "LeftButton")
                if ok then
                    down = v and true or false
                end
            end
            if not down then
                stopDrag()
                return
            end
            wrap:Apply(fromCursor())
        end)
    end)
    wrap.thumb:SetScript("OnMouseDown", function()
        wrap.track:GetScript("OnMouseDown")(wrap.track)
    end)
    function wrap:Apply(v)
        RH.EnsureDB()[key] = clamp(v)
        self:Paint(RH.EnsureDB()[key])
    end
    return wrap
end

local openDropdown
local function dropdown(parent, label, key, options, x, y, w, onSelect)
    local caption = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    caption:SetPoint("TOPLEFT", x, y)
    caption:SetText(label or "")
    caption:SetTextColor(0.52, 0.54, 0.58)
    if label == "" or not label then
        caption:Hide()
    end
    local values, display = {}, {}
    for i, option in ipairs(options) do
        values[i] = option[1]
        display[option[1]] = option[2]
    end
    local b = skinButton(parent, w, 28, "")
    b:SetPoint("TOPLEFT", x, (label == "" or not label) and y or (y - 16))
    b.key = key
    b.values = values
    b.display = display
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", 12, 0)
    b.text:SetPoint("RIGHT", -26, 0)
    b.text:SetJustifyH("LEFT")
    local chevron = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    chevron:SetPoint("RIGHT", -10, 0)
    chevron:SetText("v")
    chevron:SetTextColor(0.50, 0.52, 0.55)
    local list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    list:SetFrameStrata("TOOLTIP")
    list:SetSize(w, #options * 27 + 8)
    list:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    list:SetBackdropColor(0, 0, 0, 0.95)
    list:SetBackdropBorderColor(1, 1, 1, 1)
    list:Hide()
    b.dropdown = list
    for i, option in ipairs(options) do
        local value, text = option[1], option[2]
        local row = CreateFrame("Button", nil, list, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 27)
        row:SetSize(w - 8, 25)
        row:SetBackdrop(goldBox(8))
        row:SetBackdropColor(0, 0, 0, 0.55)
        row:SetBackdropBorderColor(GOLD.r * 0.5, GOLD.g * 0.5, GOLD.b * 0.5, 1)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 10, 0)
        row.text:SetText(text)
        row.value = value
        row.label = text
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.14, 0.05, 1)
            self:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
            self.text:SetTextColor(1, 0.9, 0.62)
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0, 0, 0, 0.55)
            self:SetBackdropBorderColor(GOLD.r * 0.5, GOLD.g * 0.5, GOLD.b * 0.5, 1)
            self.text:SetTextColor(0.84, 0.86, 0.90)
        end)
        row:SetScript("OnClick", function()
            if onSelect then
                onSelect(value)
            else
                RH.EnsureDB()[key] = value
            end
            list:Hide()
            openDropdown = nil
            RH.RefreshDashboard()
        end)
        if not b.rows then
            b.rows = {}
        end
        b.rows[#b.rows + 1] = row
    end
    local function refreshRows()
        local db = RH.EnsureDB()
        local current = key == "spec" and db.specMode == "auto" and "Automatic" or db[key]
        for _, row in ipairs(b.rows) do
            row.text:SetText((row.value == current and "✓  " or "    ") .. row.label)
        end
    end
    b:SetScript("OnClick", function()
        if openDropdown and openDropdown ~= list then
            openDropdown:Hide()
        end
        refreshRows()
        if list:IsShown() then
            list:Hide()
            openDropdown = nil
        else
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
            list:Show()
            openDropdown = list
        end
    end)
    return b
end

local widgets = {}
local function track(w)
    widgets[#widgets + 1] = w
    return w
end

-- PLAY
local play = card(pages[1], "SPECIALIZATION", -2, 118)
local specOptions = {}
for _, name in ipairs(specs[token] or { "Automatic", "Leveling" }) do
    specOptions[#specOptions + 1] = { name, name }
end
track(dropdown(play, "SPEC", "spec", specOptions, 16, -40, 740, function(value)
    RH.SetSpec(value)
end))
local engineReadout = play:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
engineReadout:SetPoint("TOPLEFT", 16, -96)
engineReadout:SetWidth(740)
engineReadout:SetJustifyH("LEFT")
engineReadout:SetTextColor(0.56, 0.60, 0.66)

local isHealer = token == "PRIEST" or token == "PALADIN" or token == "SHAMAN" or token == "DRUID"
local usesMana = token ~= "ROGUE" and token ~= "WARRIOR"
local usesDots = token == "ROGUE"
    or token == "HUNTER"
    or token == "WARLOCK"
    or token == "PRIEST"
    or token == "DRUID"
    or token == "WARRIOR"

local engineSwitches = {
    { "Cooldowns", "cooldowns", "Racials and class cooldowns.", true },
    { "Interrupts", "interrupts", "Kick when a hostile cast is readable.", true },
}
if isHealer then
    engineSwitches[#engineSwitches + 1] = { "Healing", "healing", "Role-aware heals. Healers full kit, tanks self-sustain.", true }
end
engineSwitches[#engineSwitches + 1] = { "Defensives", "defensives", "Personal survival at low health.", true }
engineSwitches[#engineSwitches + 1] = { "Maintain buffs", "maintainBuffs", "Keep class buffs, auras, and aspects up.", true }
if usesDots then
    engineSwitches[#engineSwitches + 1] = { "DoTs", "useDots", "Keep bleeds and magic dots on lasting targets.", true }
end
local engineRows = math.ceil(#engineSwitches / 2)
local engineH = 52 + engineRows * 40
local engine = card(pages[1], "ENGINE", -128, engineH)
for i, item in ipairs(engineSwitches) do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    track(switch(engine, item[1], item[2], col == 0 and 16 or 400, -44 - row * 40, item[3], item[4]))
end

local display = card(pages[1], "DISPLAY", -128 - engineH - 10, 92)
track(switch(display, "Lock HUD", "locked", 16, -44, "Prevent dragging the recommendation icon.", false))
track(slider(display, "HUD scale", "scale", 0.6, 2.0, 0.1, 400, -40, 340, "x"))

-- ROTATION
local rotScroll = CreateFrame("ScrollFrame", nil, pages[2], "UIPanelScrollFrameTemplate")
rotScroll:SetPoint("TOPLEFT", 0, 0)
rotScroll:SetPoint("BOTTOMRIGHT", -22, 0)
local rotContent = CreateFrame("Frame", nil, rotScroll)
rotContent:SetSize(746, 640)
rotScroll:SetScrollChild(rotContent)

local ctxKey = string.lower(token) .. "Context"
local combatH = 110
if isHealer or usesDots then
    combatH = 168
end
local combat = card(rotContent, "COMBAT", -2, combatH)
track(dropdown(combat, "CONTEXT", ctxKey, {
    { "auto", "Auto — battleground / arena = PvP" },
    { "pve", "PvE" },
    { "pvp", "PvP" },
}, 16, -40, 350))
track(slider(combat, "Defensive HP", "defensiveHP", 10, 70, 1, 390, -40, 330, "%"))
if isHealer then
    track(slider(combat, "Emergency HP", "emergencyHealHP", 15, 70, 1, 16, -96, 350, "%"))
    if usesDots then
        track(slider(combat, "Dot min TTD", "dotMinTTD", 4, 20, 1, 390, -96, 330, "s"))
    end
elseif usesDots then
    track(slider(combat, "Dot min TTD", "dotMinTTD", 4, 20, 1, 16, -96, 350, "s"))
end

local kitTop = -2 - combatH - 10
if isHealer or usesMana then
    local sustainH = isHealer and 168 or 110
    local sustain = card(rotContent, isHealer and "HEALING" or "RESOURCES", kitTop, sustainH)
    kitTop = kitTop - sustainH - 10
    local col = 16
    if usesMana then
        track(slider(sustain, "Mana reserve", "manaReserve", 0, 60, 5, 16, -40, 350, "%"))
        col = 390
    end
    if isHealer then
        track(slider(sustain, "Efficient heal HP", "efficientHealHP", 40, 95, 1, col, -40, 330, "%"))
        track(switch(sustain, "Mouseover heals", "healMouseover", 16, -104, "Prefer the friend under your cursor.", true))
        track(switch(sustain, "Resource logic", "resourceLogic", 400, -104, "Hold spenders when you would go empty.", true))
    else
        track(switch(sustain, "Resource logic", "resourceLogic", usesMana and 390 or 16, usesMana and -40 or -44, "Hold spenders when you would go empty.", true))
    end
end

local kit = card(rotContent, string.upper(className) .. "  KIT", kitTop, 240)
if token == "ROGUE" then
    track(dropdown(kit, "OPENER", "rogueOpener", {
        { "auto", "Auto" },
        { "cheap", "Cheap Shot" },
        { "garrote", "Garrote" },
        { "ambush", "Ambush" },
    }, 16, -40, 350))
    track(slider(kit, "Eviscerate CP", "evisCP", 1, 5, 1, 390, -40, 330, " CP"))
    track(slider(kit, "Stealth range", "stealthRange", 8, 40, 1, 16, -96, 350, " yd"))
    track(slider(kit, "Evasion HP", "evasionHP", 15, 70, 1, 390, -96, 330, "%"))
    track(switch(kit, "Slice and Dice", "rogueSnD", 16, -160, "Keep SnD rolling in PvE and PvP.", true))
    track(switch(kit, "Rupture", "rogueRupture", 400, -160, "Bleed on lasting targets after SnD.", true))
elseif token == "WARRIOR" then
    track(slider(kit, "Heroic Strike rage", "heroicRage", 20, 90, 5, 16, -40, 350, ""))
    track(slider(kit, "Sunder stacks", "sunderStacks", 1, 5, 1, 390, -40, 330, ""))
    track(switch(kit, "Battle Shout", "warriorShout", 16, -104, nil, true))
    track(switch(kit, "Taunt", "warriorTaunt", 400, -104, nil, true))
    track(switch(kit, "Rend", "warriorRend", 16, -144, nil, true))
    track(switch(kit, "Victory Rush", "warriorVictory", 400, -144, nil, true))
elseif token == "PALADIN" then
    track(switch(kit, "Blessings", "paladinBlessings", 16, -44, nil, true))
    track(switch(kit, "Auras", "paladinAuras", 400, -44, nil, true))
    track(switch(kit, "Seals", "paladinSeals", 16, -84, nil, true))
    track(switch(kit, "Group heals", "paladinGroupHeals", 400, -84, nil, true))
    track(slider(kit, "Flash of Light HP", "paladinFlashHP", 20, 80, 1, 16, -128, 350, "%"))
    track(slider(kit, "Holy Light HP", "paladinHolyLightHP", 40, 95, 1, 390, -128, 330, "%"))
elseif token == "HUNTER" then
    track(switch(kit, "Pet", "hunterPet", 16, -44, nil, true))
    track(switch(kit, "Concussive Shot", "hunterConcussive", 400, -44, nil, true))
    track(slider(kit, "Mend Pet HP", "hunterPetHealHP", 20, 90, 1, 16, -96, 350, "%"))
    track(slider(kit, "Arcane Shot mana", "hunterArcaneMana", 5, 60, 5, 390, -96, 330, "%"))
elseif token == "PRIEST" then
    track(switch(kit, "Group heals", "priestGroupHeals", 16, -44, nil, true))
    track(switch(kit, "HoTs", "priestHoTs", 400, -44, nil, true))
    track(switch(kit, "Dispel", "priestDispel", 16, -84, nil, true))
    track(slider(kit, "Flash Heal HP", "priestFlashHP", 20, 80, 1, 16, -128, 350, "%"))
    track(slider(kit, "Shield HP", "priestShieldHP", 30, 90, 1, 390, -128, 330, "%"))
elseif token == "SHAMAN" then
    track(switch(kit, "Totems", "shamanTotems", 16, -44, nil, true))
    track(switch(kit, "Group heals", "shamanGroupHeals", 400, -44, nil, true))
    track(slider(kit, "Chain Heal HP", "shamanChainHP", 40, 90, 1, 16, -96, 350, "%"))
    track(slider(kit, "Totem mana", "shamanTotemMana", 10, 70, 5, 390, -96, 330, "%"))
elseif token == "MAGE" then
    track(switch(kit, "Crowd control", "mageControl", 16, -44, nil, true))
    track(slider(kit, "Evocation mana", "mageEvocationMana", 5, 40, 5, 16, -96, 350, "%"))
    track(slider(kit, "AoE mana", "mageAoEMana", 10, 70, 5, 390, -96, 330, "%"))
elseif token == "WARLOCK" then
    track(switch(kit, "Pet", "warlockPet", 16, -44, nil, true))
    track(slider(kit, "Life Tap mana", "warlockLifeTapMana", 5, 50, 5, 16, -96, 350, "%"))
    track(slider(kit, "Drain Life HP", "warlockDrainLifeHP", 20, 70, 1, 390, -96, 330, "%"))
elseif token == "DRUID" then
    track(switch(kit, "Prowl", "druidProwl", 16, -44, nil, true))
    track(switch(kit, "HoTs", "druidHoTs", 400, -44, nil, true))
    track(switch(kit, "Direct heals", "druidDirectHeals", 16, -84, nil, true))
    track(switch(kit, "Group heals", "druidGroupHeals", 400, -84, nil, true))
    track(slider(kit, "Rejuvenation HP", "druidRejuvenationHP", 50, 95, 1, 16, -128, 350, "%"))
    track(slider(kit, "Regrowth HP", "druidRegrowthHP", 25, 80, 1, 390, -128, 330, "%"))
end

-- SPELLS
local abilitiesScroll = CreateFrame("ScrollFrame", nil, pages[3], "UIPanelScrollFrameTemplate")
abilitiesScroll:SetPoint("TOPLEFT", 0, 0)
abilitiesScroll:SetPoint("BOTTOMRIGHT", -22, 0)
local abilitiesContent = CreateFrame("Frame", nil, abilitiesScroll)
abilitiesContent:SetSize(746, 580)
abilitiesScroll:SetScrollChild(abilitiesContent)

local classStatus = card(abilitiesContent, token .. "  SPELLS", -2, 78)
local classStatusText = classStatus:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
classStatusText:SetPoint("TOPLEFT", 16, -40)
classStatusText:SetWidth(700)
classStatusText:SetJustifyH("LEFT")
local startHint = classStatus:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
startHint:SetPoint("TOPLEFT", 16, -58)
startHint:SetWidth(700)
startHint:SetJustifyH("LEFT")
startHint:SetText("Off = never recommend. Role, spec, and level still decide when it fires.")
local allAbilities = RH.Abilities[token] or {}
local listRows = math.max(1, math.ceil(#allAbilities / 2))
local listH = 52 + listRows * 34
local listCard = card(abilitiesContent, "LEARNED ROTATION", -90, listH)
abilitiesContent:SetHeight(90 + listH + 16)
local classRows = {}
for i = 1, #allAbilities do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local b = CreateFrame("Button", nil, listCard)
    b:SetSize(340, 31)
    b:SetPoint("TOPLEFT", 16 + col * 356, -44 - row * 34)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(22, 22)
    b.icon:SetPoint("LEFT")
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.box:SetSize(17, 17)
    b.box:SetPoint("RIGHT")
    b.box:SetBackdrop(goldBox(8))
    b.box:SetBackdropColor(0, 0, 0, 0.7)
    b.box:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    b.mark = b.box:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.mark:SetSize(20, 20)
    b.mark:SetPoint("CENTER")
    b.mark:SetVertexColor(color.r, color.g, color.b)
    b.map = CreateFrame("Button", nil, b, "BackdropTemplate")
    b.map:SetSize(34, 16)
    b.map:SetPoint("RIGHT", b.box, "LEFT", -6, 0)
    b.map:SetBackdrop(goldBox(8))
    b.map:SetBackdropColor(0, 0, 0, 0.7)
    b.map:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    b.map.text = b.map:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.map.text:SetPoint("CENTER")
    b.map.text:SetScale(0.82)
    b.map:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.name:SetPoint("LEFT", b.icon, "RIGHT", 8, 5)
    b.name:SetPoint("RIGHT", b.map, "LEFT", -6, 5)
    b.name:SetJustifyH("LEFT")
    b.role = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.role:SetPoint("LEFT", b.icon, "RIGHT", 8, -7)
    b:SetScript("OnClick", function()
        if b.entry then
            RH.SetAbilityEnabled(b.entry[2], not RH.AbilityEnabled(b.entry[2]))
            RH.RefreshClassDashboard()
        end
    end)
    classRows[i] = b
end

local iconPicker = CreateFrame("Frame", nil, abilitiesContent, "BackdropTemplate")
iconPicker:SetSize(230, 150)
iconPicker:SetFrameStrata("TOOLTIP")
iconPicker:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
iconPicker:SetBackdropColor(0, 0, 0, 0.95)
iconPicker:SetBackdropBorderColor(1, 1, 1, 1)
iconPicker:Hide()
local pickerTitle = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pickerTitle:SetPoint("TOPLEFT", 8, -7)
pickerTitle:SetText("OUTPUT ICON")
pickerTitle:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
for n = 0, 10 do
    local index = n
    local col = index % 2
    local row = math.floor(index / 2)
    local choice = CreateFrame("Button", nil, iconPicker, "BackdropTemplate")
    choice:SetSize(105, 18)
    choice:SetPoint("TOPLEFT", 7 + col * 111, -25 - row * 20)
    choice:SetBackdrop(goldBox(8))
    choice:SetBackdropColor(0, 0, 0, 0.7)
    choice:SetBackdropBorderColor(GOLD.r * 0.7, GOLD.g * 0.7, GOLD.b * 0.7, 1)
    if index > 0 then
        choice.icon = choice:CreateTexture(nil, "ARTWORK")
        choice.icon:SetSize(14, 14)
        choice.icon:SetPoint("LEFT", 3, 0)
        choice.icon:SetTexture(RH.UniversalIcons[index])
    end
    choice.text = choice:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    choice.text:SetPoint("CENTER", index > 0 and 8 or 0, 0)
    choice.text:SetText(index == 0 and "Default spell" or ("Universal " .. index))
    choice:SetScript("OnClick", function()
        if iconPicker.spell then
            RH.SetIconChoice(iconPicker.spell, index)
            iconPicker:Hide()
            RH.RefreshClassDashboard()
        end
    end)
    choice:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    end)
    choice:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(GOLD.r * 0.7, GOLD.g * 0.7, GOLD.b * 0.7, 1)
    end)
end
local function OpenIconPicker(row)
    if not row.entry then
        return
    end
    iconPicker.spell = row.entry[2]
    iconPicker:ClearAllPoints()
    iconPicker:SetPoint("TOPRIGHT", row.map, "BOTTOMRIGHT", 0, -3)
    iconPicker:Show()
end
for _, row in ipairs(classRows) do
    row.map:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            RH.SetIconChoice(row.entry and row.entry[2])
            RH.RefreshClassDashboard()
        else
            OpenIconPicker(row)
        end
    end)
    row.map:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
        tip(s, row.entry and row.entry[2] or "Output icon", "Left: Default or Universal 1–10. Right: reset.")
    end)
    row.map:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(GOLD.r * 0.7, GOLD.g * 0.7, GOLD.b * 0.7, 1)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end
pages[3]:HookScript("OnHide", function()
    iconPicker:Hide()
end)
function RH.RefreshClassDashboard()
    local all = RH.Abilities[token] or {}
    local d = RH.EnsureDB()
    local learned = 0
    for _, e in ipairs(all) do
        if RH.AbilityStatus(e) then
            learned = learned + 1
        end
    end
    classStatusText:SetText(
        "Level "
            .. tostring(UnitLevel("player") or "?")
            .. "   ·   "
            .. tostring(learned)
            .. "/"
            .. tostring(#all)
            .. " learned   ·   "
            .. tostring(d.spec or "Leveling")
    )
    for i, b in ipairs(classRows) do
        local e = all[i]
        b.entry = e
        if e then
            local known, texture = RH.AbilityStatus(e)
            local enabled = RH.AbilityEnabled(e[2])
            b.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            b.icon:SetVertexColor(1, 1, 1, 1)
            b.icon:SetAlpha(known and 1 or 0.42)
            pcall(b.icon.SetDesaturated, b.icon, not known)
            b.name:SetText(e[2])
            b.name:SetTextColor(enabled and 0.88 or 0.42, enabled and 0.89 or 0.43, enabled and 0.92 or 0.46)
            b.role:SetText((e[3] or "Ability") .. (known and "  ·  learned" or "  ·  locked"))
            b.mark:SetShown(enabled)
            local choice = RH.IconChoice(e[2])
            b.map.text:SetText(choice and ("U" .. choice) or "ICON")
            b.map.text:SetTextColor(choice and color.r or 0.72, choice and color.g or 0.75, choice and color.b or 0.82)
            b:Show()
        else
            b:Hide()
        end
    end
end

function RH.RefreshDashboard()
    local d = RH.EnsureDB()
    local enabled = d.enabled ~= false
    active.text:SetText(enabled and "ON" or "OFF")
    active.text:SetTextColor(enabled and 0.45 or 0.92, enabled and 0.86 or 0.42, enabled and 0.58 or 0.40)
    active.held = enabled
    pcall(active.SetBackdropBorderColor, active, enabled and 0.35 or 0.7, enabled and 0.55 or 0.22, enabled and 0.18 or 0.12, 1)
    local mode = d.mode or "auto"
    aoe.text:SetText(mode == "single" and "ST" or (mode == "aoe" and "AOE" or "AUTO"))
    aoe.text:SetTextColor(RH.AoE and 0.94 or 0.72, RH.AoE and 0.72 or 0.73, RH.AoE and 0.42 or 0.74)
    cds.text:SetText("CDS")
    cds.text:SetTextColor(
        d.cooldowns ~= false and 0.45 or 0.58,
        d.cooldowns ~= false and 0.86 or 0.59,
        d.cooldowns ~= false and 0.58 or 0.60
    )
    subtitle:SetText(
        string.upper(className)
            .. "  ·  "
            .. tostring(UnitLevel("player") or "?")
            .. "  ·  "
            .. string.upper(d.spec or "LEVELING")
    )
    if engineReadout then
        local role = RH.HealRole and RH.HealRole() or "dps"
        local ctx = d[ctxKey]
        local pvp = RH.IsPvPContext and RH.IsPvPContext(ctx)
        local bands = RH.HealBands and RH.HealBands(pvp)
            or { emergency = d.emergencyHealHP or 35, efficient = d.efficientHealHP or 70 }
        local kitText = role == "healer" and ("full kit below " .. tostring(bands.efficient) .. "%")
            or (role == "tank" and "self-sustain when dying")
            or "emergency saves only"
        engineReadout:SetText(string.upper(role) .. "  ·  " .. (pvp and "PVP" or "PVE") .. "  ·  " .. kitText)
    end
    for _, w in ipairs(widgets) do
        if w.isSwitch then
            local on = switchOn(d, w)
            w.track:SetBackdropColor(
                on and 0.45 or 0.05,
                on and 0.32 or 0.05,
                on and 0.08 or 0.05,
                1
            )
            w.track:SetBackdropBorderColor(
                on and 0.95 or 0.45,
                on and 0.75 or 0.38,
                on and 0.20 or 0.18,
                1
            )
            w.knob:ClearAllPoints()
            w.knob:SetPoint("CENTER", w.track, on and "RIGHT" or "LEFT", on and -10 or 10, 0)
            w.knob:SetColorTexture(on and 0.95 or 0.55, on and 0.96 or 0.56, on and 0.97 or 0.58, 1)
        elseif w.isSlider then
            local v = tonumber(d[w.key])
            if w.key == "scale" then
                v = v or 1
            end
            w:Paint(v or w.minV)
        elseif w.values then
            local value = w.key == "spec" and d.specMode == "auto" and "Automatic" or d[w.key]
            local shown = tostring(value or w.values[1])
            if w.display then
                shown = w.display[value] or shown
            end
            w.text:SetText(shown)
        end
    end
    if RH.IconFrame then
        RH.IconFrame:EnableMouse(not d.locked)
        RH.IconFrame:SetScale(d.scale or 1)
    end
    if selected == 3 then
        RH.RefreshClassDashboard()
    end
end
function RH.RefreshMenu()
    RH.RefreshDashboard()
end
active:SetScript("OnClick", function()
    local d = RH.EnsureDB()
    d.enabled = not d.enabled
    RH.RefreshDashboard()
end)
aoe:SetScript("OnClick", function()
    local d = RH.EnsureDB()
    d.mode = d.mode == "auto" and "single" or (d.mode == "single" and "aoe" or "auto")
    RH.RefreshDashboard()
end)
cds:SetScript("OnClick", function()
    local d = RH.EnsureDB()
    d.cooldowns = not d.cooldowns
    RH.RefreshDashboard()
end)
function RH.ToggleMenu()
    if frame:IsShown() then
        frame:Hide()
    else
        RH.RefreshDashboard()
        SelectTab(selected)
        frame:Show()
    end
end
frame:SetScript("OnHide", function()
    if openDropdown then
        openDropdown:Hide()
        openDropdown = nil
    end
end)
local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("LEFT", subtitle, "RIGHT", 14, 0)
footer:SetText("6.4.4")
footer:SetTextColor(0.72, 0.62, 0.32)
local footerRight = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footerRight:SetPoint("BOTTOMRIGHT", -22, 18)
footerRight:SetText("/nc")
footerRight:SetTextColor(color.r * 0.7, color.g * 0.7, color.b * 0.7)
local function fitWindow()
    frame:SetScale(math.max(0.4, math.min(1, (UIParent:GetWidth() - 24) / 800, (UIParent:GetHeight() - 24) / 560)))
    RH.RestoreFramePosition(frame, "menuPosition")
    RH.RefreshDashboard()
end
frame:SetScript("OnShow", fitWindow)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    RH.SaveFramePosition(self, "menuPosition")
end)
table.insert(UISpecialFrames, "NextCastDashboard")

local mini = CreateFrame("Button", "NextCastMinimapButton", Minimap, "BackdropTemplate")
mini:SetSize(34, 34)
mini:SetFrameStrata("MEDIUM")
mini:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
mini:SetBackdrop({
    bgFile = WHITE,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 11,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
mini:SetBackdropColor(0, 0, 0, 0.9)
mini:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
local mt = mini:CreateTexture(nil, "ARTWORK")
mt:SetPoint("TOPLEFT", 5, -5)
mt:SetPoint("BOTTOMRIGHT", -5, 5)
mt:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
if coords then
    mt:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end
mini:SetScript("OnEnter", function(s)
    s:SetBackdropBorderColor(1, 0.82, 0.2, 1)
    if GameTooltip then
        GameTooltip:SetOwner(s, "ANCHOR_LEFT")
        GameTooltip:AddLine("NextCast", 1, 0.82, 0.35)
        GameTooltip:AddLine("Left-click  Settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click  Cooldowns", 0.72, 0.75, 0.82)
        GameTooltip:Show()
    end
end)
mini:SetScript("OnLeave", function(s)
    s:SetBackdropBorderColor(GOLD.r, GOLD.g, GOLD.b, 1)
    if GameTooltip then
        GameTooltip:Hide()
    end
end)
mini:SetScript("OnClick", function(_, m)
    if m == "RightButton" then
        local d = RH.EnsureDB()
        d.cooldowns = not d.cooldowns
        RH.CDs = d.cooldowns
        RH.RefreshDashboard()
    else
        RH.ToggleMenu()
    end
end)
mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mini:SetScript("OnMouseDown", function(s)
    s:SetScript("OnUpdate", function(self)
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        local cx, cy = Minimap:GetCenter()
        local angle = math.deg(math.atan2(my - cy, mx - cx))
        RH.EnsureDB().minimapAngle = angle
        local r = (Minimap:GetWidth() / 2) + 8
        local rad = math.rad(angle)
        self:ClearAllPoints()
        self:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * r, math.sin(rad) * r)
    end)
end)
mini:SetScript("OnMouseUp", function(s)
    s:SetScript("OnUpdate", nil)
end)
local function placeMini()
    local angle = RH.EnsureDB().minimapAngle or 225
    local r = (Minimap:GetWidth() / 2) + 8
    local rad = math.rad(angle)
    mini:ClearAllPoints()
    mini:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * r, math.sin(rad) * r)
end
mini:SetScript("OnShow", placeMini)
placeMini()

SelectTab(1)
