local RH = RubimRH
local WHITE = "Interface\\Buttons\\WHITE8X8"
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
frame:SetSize(720, 428)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()
frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
frame:SetBackdropColor(0.043, 0.047, 0.055, 0.97)
frame:SetBackdropBorderColor(0.16, 0.17, 0.19, 1)
local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
shadow:SetTexture(WHITE)
shadow:SetPoint("TOPLEFT", -10, 10)
shadow:SetPoint("BOTTOMRIGHT", 10, -10)
shadow:SetColorTexture(0, 0, 0, 0.45)
local header = frame:CreateTexture(nil, "BACKGROUND")
header:SetTexture(WHITE)
header:SetPoint("TOPLEFT", 1, -1)
header:SetPoint("TOPRIGHT", -1, -1)
header:SetHeight(58)
header:SetColorTexture(0.055, 0.059, 0.068, 1)
local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
local crestRing = frame:CreateTexture(nil, "ARTWORK")
crestRing:SetTexture(WHITE)
crestRing:SetSize(38, 38)
crestRing:SetPoint("TOPLEFT", 16, -10)
crestRing:SetColorTexture(color.r, color.g, color.b, 0.35)
local crest = frame:CreateTexture(nil, "ARTWORK")
crest:SetSize(34, 34)
crest:SetPoint("CENTER", crestRing, "CENTER")
crest:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
if coords then
    crest:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 62, -14)
title:SetText("NextCast")
title:SetTextColor(0.93, 0.93, 0.91)
local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
subtitle:SetTextColor(0.55, 0.56, 0.58)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -4, -6)
local accent = frame:CreateTexture(nil, "ARTWORK")
accent:SetTexture(WHITE)
accent:SetPoint("TOPLEFT", 1, -59)
accent:SetPoint("TOPRIGHT", -1, -59)
accent:SetHeight(1)
accent:SetColorTexture(0.18, 0.19, 0.21, 1)

local function skinButton(parent, w, h, label)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b:SetBackdropColor(0.07, 0.075, 0.085, 1)
    b:SetBackdropBorderColor(0.18, 0.19, 0.21, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(label or "")
    b:SetScript("OnEnter", function(s)
        s:SetBackdropColor(0.10, 0.11, 0.13, 1)
        s:SetBackdropBorderColor(color.r * 0.55, color.g * 0.55, color.b * 0.55, 1)
    end)
    b:SetScript("OnLeave", function(s)
        if not s.held then
            s:SetBackdropColor(0.07, 0.075, 0.085, 1)
            s:SetBackdropBorderColor(0.18, 0.19, 0.21, 1)
        end
    end)
    return b
end
local active = skinButton(frame, 68, 22, "ON")
active:SetPoint("TOPRIGHT", close, "TOPLEFT", -6, -8)
local aoe = skinButton(frame, 52, 22, "AOE")
aoe:SetPoint("RIGHT", active, "LEFT", -6, 0)
local cds = skinButton(frame, 52, 22, "CDS")
cds:SetPoint("RIGHT", aoe, "LEFT", -6, 0)

local tabBar = CreateFrame("Frame", nil, frame)
tabBar:SetPoint("TOPLEFT", 12, -62)
tabBar:SetPoint("TOPRIGHT", -12, -62)
tabBar:SetHeight(32)
local pages = {}
local tabs = {}
local selected = 1
for i = 1, 2 do
    pages[i] = CreateFrame("Frame", nil, frame)
    pages[i]:SetPoint("TOPLEFT", 14, -98)
    pages[i]:SetPoint("BOTTOMRIGHT", -14, 32)
    pages[i]:Hide()
end
local labels = { "Overview", "Abilities" }
local tabPageOrder = { 1, 2 }
local function SelectTab(index)
    selected = index
    local activePage = tabPageOrder[index]
    for i, page in ipairs(pages) do
        page:SetShown(i == activePage)
    end
    for i, tab in ipairs(tabs) do
        local on = i == index
        tab:SetBackdropColor(on and 0.09 or 0.055, on and 0.095 or 0.059, on and 0.11 or 0.068, 1)
        tab:SetBackdropBorderColor(on and 0.22 or 0.14, on and 0.23 or 0.15, on and 0.25 or 0.16, 1)
        tab.text:SetTextColor(on and 0.94 or 0.58, on and 0.94 or 0.59, on and 0.92 or 0.60)
        if tab.line then
            tab.line:SetShown(on)
        end
    end
    if activePage == 2 and RH.RefreshClassDashboard then
        RH.RefreshClassDashboard()
    end
end
for i, label in ipairs(labels) do
    local b = skinButton(tabBar, 340, 28, label)
    b:SetPoint("LEFT", (i - 1) * 348, 0)
    b.line = b:CreateTexture(nil, "OVERLAY")
    b.line:SetTexture(WHITE)
    b.line:SetHeight(2)
    b.line:SetPoint("BOTTOMLEFT", 10, 0)
    b.line:SetPoint("BOTTOMRIGHT", -10, 0)
    b.line:SetColorTexture(color.r, color.g, color.b, 1)
    b.line:Hide()
    b:SetScript("OnClick", function()
        SelectTab(i)
    end)
    tabs[i] = b
end

local function card(parent, titleText, top, height)
    local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    c:SetPoint("TOPLEFT", 8, top)
    c:SetPoint("TOPRIGHT", -8, top)
    c:SetHeight(height)
    c:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    c:SetBackdropColor(0.062, 0.066, 0.076, 1)
    c:SetBackdropBorderColor(0.15, 0.16, 0.18, 1)
    local titleTextFS = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTextFS:SetPoint("TOPLEFT", 16, -12)
    titleTextFS:SetText(titleText)
    titleTextFS:SetTextColor(0.78, 0.79, 0.80)
    local line = c:CreateTexture(nil, "ARTWORK")
    line:SetTexture(WHITE)
    line:SetPoint("TOPLEFT", 14, -32)
    line:SetPoint("TOPRIGHT", -14, -32)
    line:SetHeight(1)
    line:SetColorTexture(0.18, 0.19, 0.21, 1)
    return c
end
local function toggle(parent, label, key, x, y, helpText)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(330, 24)
    b:SetPoint("TOPLEFT", x, y)
    b.box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.box:SetSize(16, 16)
    b.box:SetPoint("LEFT")
    b.box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b.box:SetBackdropColor(0.04, 0.045, 0.052, 1)
    b.box:SetBackdropBorderColor(0.28, 0.29, 0.31, 1)
    b.mark = b.box:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture(WHITE)
    b.mark:SetSize(8, 8)
    b.mark:SetPoint("CENTER")
    b.mark:SetColorTexture(color.r, color.g, color.b, 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b.box, "RIGHT", 8, 0)
    b.text:SetText(label)
    b.key = key
    b.helpText = helpText
    b:SetScript("OnClick", function()
        local d = RH.EnsureDB()
        d[key] = not d[key]
        RH.RefreshDashboard()
    end)
    b:SetScript("OnEnter", function()
        b.text:SetTextColor(1, 0.88, 0.58)
        if helpText and GameTooltip then
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label, 1, 0.82, 0.35)
            GameTooltip:AddLine(helpText, 0.92, 0.92, 0.94, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function()
        b.text:SetTextColor(0.84, 0.86, 0.90)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    return b
end
local openDropdown
local function dropdown(parent, label, key, options, x, y, w, onSelect)
    local caption = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    caption:SetPoint("TOPLEFT", x, y)
    caption:SetText(label or "")
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
    b.chevron = chevron
    local list = CreateFrame("Frame", nil, b, "BackdropTemplate")
    list:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
    list:SetSize(w, #options * 27 + 8)
    list:SetFrameLevel(b:GetFrameLevel() + 20)
    list:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    list:SetBackdropColor(0.012, 0.017, 0.024, 0.99)
    list:SetBackdropBorderColor(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1)
    list:Hide()
    b.dropdown = list
    local rows = {}
    for i, option in ipairs(options) do
        local value, text = option[1], option[2]
        local row = CreateFrame("Button", nil, list, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 27)
        row:SetSize(w - 8, 25)
        row:SetBackdrop({ bgFile = WHITE })
        row:SetBackdropColor(0.025, 0.032, 0.043, 0.98)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 10, 0)
        row.text:SetText(text)
        row.value = value
        row.label = text
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(color.r * 0.16, color.g * 0.16, color.b * 0.16, 1)
            self.text:SetTextColor(1, 0.9, 0.62)
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.025, 0.032, 0.043, 0.98)
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
        rows[#rows + 1] = row
    end
    b.rows = rows
    local function refreshRows()
        local db = RH.EnsureDB()
        local current = key == "spec" and db.specMode == "auto" and "Automatic" or db[key]
        for _, row in ipairs(rows) do
            row.text:SetText((row.value == current and "✓  " or "    ") .. row.label)
        end
    end
    b:SetScript("OnClick", function()
        if openDropdown and openDropdown ~= list then
            openDropdown:Hide()
        end
        refreshRows()
        list:SetShown(not list:IsShown())
        openDropdown = list:IsShown() and list or nil
    end)
    return b
end
local generalControls = {}
local play = card(pages[1], "SPECIALIZATION", -4, 118)
local specOptions = {}
for _, name in ipairs(specs[token] or { "Automatic", "Leveling" }) do
    specOptions[#specOptions + 1] = { name, name }
end
generalControls[#generalControls + 1] = dropdown(
    play,
    "SPEC",
    "spec",
    specOptions,
    18,
    -42,
    660,
    function(value)
        RH.SetSpec(value)
    end
)
local engineReadout = play:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
engineReadout:SetPoint("TOPLEFT", 18, -96)
engineReadout:SetWidth(660)
engineReadout:SetJustifyH("LEFT")
engineReadout:SetTextColor(0.58, 0.62, 0.68)

local switches = card(pages[1], "SWITCHES", -130, 168)
generalControls[#generalControls + 1] =
    toggle(switches, "Cooldowns", "cooldowns", 20, -48, "Racials and class cooldowns when Burst is on.")
generalControls[#generalControls + 1] =
    toggle(switches, "Interrupts", "interrupts", 360, -48, "Kick when a hostile cast is readable.")
generalControls[#generalControls + 1] = toggle(
    switches,
    "Healing",
    "healing",
    20,
    -86,
    "On = role-aware heals. Healers full kit, tanks self-sustain, DPS emergency only."
)
generalControls[#generalControls + 1] =
    toggle(switches, "Defensives", "defensives", 360, -86, "Personal survival at low health.")
generalControls[#generalControls + 1] =
    toggle(switches, "Lock icon", "locked", 20, -124, "Prevent dragging the recommendation icon.")
local scaleOptions = {}
for _, value in ipairs({ 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2 }) do
    scaleOptions[#scaleOptions + 1] = { value, tostring(math.floor(value * 100 + 0.5)) .. "%" }
end
local scaleCaption = switches:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
scaleCaption:SetPoint("TOPLEFT", 360, -118)
scaleCaption:SetText("ICON SCALE")
scaleCaption:SetTextColor(0.52, 0.54, 0.58)
generalControls[#generalControls + 1] = dropdown(switches, "", "scale", scaleOptions, 360, -132, 276)

local abilitiesScroll = CreateFrame("ScrollFrame", nil, pages[2], "UIPanelScrollFrameTemplate")
abilitiesScroll:SetPoint("TOPLEFT", 0, 0)
abilitiesScroll:SetPoint("BOTTOMRIGHT", -26, 0)
local abilitiesContent = CreateFrame("Frame", nil, abilitiesScroll)
abilitiesContent:SetSize(726, 580)
abilitiesScroll:SetScrollChild(abilitiesContent)

local classStatus = card(abilitiesContent, token .. " SPELLS", -4, 86)
local classStatusText = classStatus:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
classStatusText:SetPoint("TOPLEFT", 18, -42)
classStatusText:SetWidth(680)
classStatusText:SetJustifyH("LEFT")
local startHint = classStatus:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
startHint:SetPoint("TOPLEFT", 18, -62)
startHint:SetWidth(680)
startHint:SetJustifyH("LEFT")
startHint:SetText("Turn a spell off to never recommend it. Everything else is automatic from role, spec, and level.")
local listCard = card(abilitiesContent, "LEARNED ROTATION", -100, 400)
local classRows = {}
local classPage = 1
local CLASS_PER_PAGE = 20
for i = 1, CLASS_PER_PAGE do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local b = CreateFrame("Button", nil, listCard)
    b:SetSize(330, 31)
    b:SetPoint("TOPLEFT", 18 + col * 350, -46 - row * 35)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(22, 22)
    b.icon:SetPoint("LEFT")
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.box:SetSize(17, 17)
    b.box:SetPoint("RIGHT")
    b.box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b.box:SetBackdropColor(0.025, 0.03, 0.04, 1)
    b.box:SetBackdropBorderColor(0.34, 0.36, 0.40, 1)
    b.mark = b.box:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.mark:SetSize(20, 20)
    b.mark:SetPoint("CENTER")
    b.mark:SetVertexColor(color.r, color.g, color.b)
    -- Output-icon mapper, inline on the same row as the enable/disable box
    -- instead of a separate popup -- one list, one click each.
    b.map = CreateFrame("Button", nil, b, "BackdropTemplate")
    b.map:SetSize(34, 16)
    b.map:SetPoint("RIGHT", b.box, "LEFT", -6, 0)
    b.map:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b.map:SetBackdropColor(0.025, 0.03, 0.04, 1)
    b.map:SetBackdropBorderColor(0.30, 0.32, 0.36, 1)
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

-- Shared output-icon picker popup, opened next to whichever row's map
-- button was clicked. Assign the ability's normal spell icon or one of the
-- Universal 1-10 slots (Universal textures match the installed GGL reader;
-- each Universal slot also needs a key assigned in GGL).
local iconPicker = CreateFrame("Frame", nil, abilitiesContent, "BackdropTemplate")
iconPicker:SetSize(230, 150)
iconPicker:SetFrameStrata("TOOLTIP")
iconPicker:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
iconPicker:SetBackdropColor(0.018, 0.024, 0.034, 0.995)
iconPicker:SetBackdropBorderColor(color.r, color.g, color.b, 1)
iconPicker:Hide()
local pickerTitle = iconPicker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pickerTitle:SetPoint("TOPLEFT", 8, -7)
pickerTitle:SetText("OUTPUT ICON")
pickerTitle:SetTextColor(color.r, color.g, color.b)
for n = 0, 10 do
    local index = n
    local col = index % 2
    local row = math.floor(index / 2)
    local choice = CreateFrame("Button", nil, iconPicker, "BackdropTemplate")
    choice:SetSize(105, 18)
    choice:SetPoint("TOPLEFT", 7 + col * 111, -25 - row * 20)
    choice:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    choice:SetBackdropColor(0.04, 0.047, 0.058, 1)
    choice:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
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
        s:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    end)
    choice:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
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
        s:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:AddLine(row.entry and row.entry[2] or "Output icon", 1, 0.82, 0.35)
        GameTooltip:AddLine("Left-click: choose Default or Universal 1-10", 1, 1, 1)
        GameTooltip:AddLine("Right-click: reset to the spell icon", 0.72, 0.75, 0.82)
        GameTooltip:Show()
    end)
    row.map:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(0.30, 0.32, 0.36, 1)
        GameTooltip:Hide()
    end)
end
pages[2]:HookScript("OnHide", function()
    iconPicker:Hide()
end)
local classPrev = skinButton(abilitiesContent, 80, 24, "PREVIOUS")
classPrev:SetPoint("TOPLEFT", listCard, "BOTTOMLEFT", 10, -14)
local classNext = skinButton(abilitiesContent, 80, 24, "NEXT")
classNext:SetPoint("TOPRIGHT", listCard, "BOTTOMRIGHT", -10, -14)
local classPageText = abilitiesContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
classPageText:SetPoint("TOP", classPrev, "TOP", 0, -7)
function RH.RefreshClassDashboard()
    local all = RH.Abilities[token] or {}
    local d = RH.EnsureDB()
    local list = {}
    local learned = 0
    for _, e in ipairs(all) do
        local known = RH.AbilityStatus(e)
        if known then
            learned = learned + 1
        end
        list[#list + 1] = e
    end
    local pagesCount = math.max(1, math.ceil(#list / CLASS_PER_PAGE))
    classPage = math.max(1, math.min(classPage, pagesCount))
    local first = (classPage - 1) * CLASS_PER_PAGE + 1
    classStatusText:SetText(
        "Level "
            .. tostring(UnitLevel("player") or "?")
            .. "   |   "
            .. tostring(learned)
            .. "/"
            .. tostring(#all)
            .. " learned   |   "
            .. tostring(d.spec or "Leveling")
    )
    for i, b in ipairs(classRows) do
        local e = list[first + i - 1]
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
            b.role:SetText((e[3] or "Ability") .. (known and "  |  learned" or "  |  locked"))
            b.mark:SetShown(enabled)
            local choice = RH.IconChoice(e[2])
            b.map.text:SetText(choice and ("U" .. choice) or "ICON")
            b.map.text:SetTextColor(choice and color.r or 0.72, choice and color.g or 0.75, choice and color.b or 0.82)
            b:Show()
        else
            b:Hide()
        end
    end
    classPageText:SetText("Page " .. classPage .. " / " .. pagesCount)
    classPrev:SetEnabled(classPage > 1)
    classNext:SetEnabled(classPage < pagesCount)
end
classPrev:SetScript("OnClick", function()
    classPage = classPage - 1
    RH.RefreshClassDashboard()
end)
classNext:SetScript("OnClick", function()
    classPage = classPage + 1
    RH.RefreshClassDashboard()
end)


function RH.RefreshDashboard()
    local d = RH.EnsureDB()
    local enabled = d.enabled ~= false
    active.text:SetText(enabled and "ON" or "OFF")
    active.text:SetTextColor(enabled and 0.45 or 0.92, enabled and 0.86 or 0.42, enabled and 0.58 or 0.40)
    active.held = enabled
    active:SetBackdropBorderColor(
        enabled and 0.22 or 0.45,
        enabled and 0.42 or 0.18,
        enabled and 0.28 or 0.16,
        1
    )
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
            .. "  /  LEVEL "
            .. tostring(UnitLevel("player") or "?")
            .. "  /  "
            .. string.upper(d.spec or "LEVELING")
            .. "  /  FOREVER"
    )
    if engineReadout then
        local role = RH.HealRole and RH.HealRole() or "dps"
        local ctx = d[string.lower(token) .. "Context"]
        local pvp = RH.IsPvPContext and RH.IsPvPContext(ctx)
        local bands = RH.HealBands and RH.HealBands(pvp)
            or { emergency = d.emergencyHealHP or 35, efficient = d.efficientHealHP or 70 }
        local kit = role == "healer" and ("full kit below " .. tostring(bands.efficient) .. "%")
            or (role == "tank" and "self-sustain when dying")
            or "emergency saves only"
        engineReadout:SetText(
            string.upper(role)
                .. "  ·  "
                .. (pvp and "PVP" or "PVE")
                .. "  ·  "
                .. kit
        )
    end
    for _, collection in ipairs({ generalControls }) do
        for _, b in ipairs(collection) do
            if b.mark then
                local on = d[b.key] == true
                b.mark:SetShown(on)
                b.box:SetBackdropColor(
                    on and color.r * 0.22 or 0.04,
                    on and color.g * 0.22 or 0.045,
                    on and color.b * 0.22 or 0.052,
                    1
                )
                b.box:SetBackdropBorderColor(
                    on and color.r * 0.7 or 0.28,
                    on and color.g * 0.7 or 0.29,
                    on and color.b * 0.7 or 0.31,
                    1
                )
            elseif b.values then
                local value = b.key == "spec" and d.specMode == "auto" and "Automatic" or d[b.key]
                local shown = b.key == "scale" and tostring(math.floor((value or 1) * 100 + 0.5)) .. "%"
                    or tostring(value or b.values[1])
                local lk = string.lower(b.key)
                if string.find(lk, "rage") then
                    shown = shown .. " rage"
                elseif b.key == "stealthRange" then
                    shown = shown .. " yd"
                elseif string.find(lk, "ttd") or string.find(lk, "lifetime") then
                    shown = shown .. " sec"
                elseif string.find(lk, "mana") or string.find(lk, "hp") then
                    shown = shown .. "%"
                elseif string.find(lk, "energy") then
                    shown = shown .. " energy"
                elseif string.find(lk, "cp") then
                    shown = shown .. " CP"
                end
                if b.display then
                    shown = b.display[value] or shown
                end
                if b.formatValue then
                    shown = b.formatValue(b.key, value or b.values[1])
                end
                b.text:SetText(shown)
                if b.SetValue then
                    local at, distance = 1, math.huge
                    for i, v in ipairs(b.values) do
                        local diff = math.abs(v - (tonumber(value) or b.values[1]))
                        if diff < distance then
                            at, distance = i, diff
                        end
                    end
                    b.settingValue = true
                    b:SetValue(at)
                    b.settingValue = nil
                end
            end
        end
    end
    if RH.IconFrame then
        RH.IconFrame:EnableMouse(not d.locked)
        RH.IconFrame:SetScale(d.scale or 1)
    end
    if tabPageOrder[selected] == 2 then
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
local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("BOTTOMLEFT", 14, 10)
footer:SetText("NEXTCAST  5.9.3")
footer:SetTextColor(0.38, 0.42, 0.49)
local footerRight = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footerRight:SetPoint("BOTTOMRIGHT", -14, 10)
footerRight:SetText("/nextcast")
footerRight:SetTextColor(color.r * 0.7, color.g * 0.7, color.b * 0.7)
local function fitWindow()
    frame:SetScale(math.max(0.4, math.min(1, (UIParent:GetWidth() - 24) / 780, (UIParent:GetHeight() - 24) / 540)))
    RH.RestoreFramePosition(frame, "menuPosition")
end
frame:SetScript("OnShow", fitWindow)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    RH.SaveFramePosition(self, "menuPosition")
end)
table.insert(UISpecialFrames, "NextCastDashboard")

local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
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
mini:SetBackdropColor(0.015, 0.02, 0.03, 1)
mini:SetBackdropBorderColor(0.58, 0.48, 0.25, 1)
local mt = mini:CreateTexture(nil, "ARTWORK")
mt:SetPoint("TOPLEFT", 5, -5)
mt:SetPoint("BOTTOMRIGHT", -5, 5)
mt:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
if coords then
    mt:SetTexCoord(coords[1] + 0.012, coords[2] - 0.012, coords[3] + 0.012, coords[4] - 0.012)
end
mini:SetScript("OnEnter", function(s)
    s:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    if GameTooltip then
        GameTooltip:SetOwner(s, "ANCHOR_LEFT")
        GameTooltip:AddLine("NextCast", 1, 0.82, 0.35)
        GameTooltip:AddLine("Left-click  Settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click  Cooldowns", 0.72, 0.75, 0.82)
        GameTooltip:Show()
    end
end)
mini:SetScript("OnLeave", function(s)
    s:SetBackdropBorderColor(0.58, 0.48, 0.25, 1)
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
