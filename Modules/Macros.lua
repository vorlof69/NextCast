local RH = RubimRH

-- GGLoader MetaEngine, ExtraIcon edition.
--
-- Action's MetaEngine paints TMW "Shown Main" slots 6–10 and binds each
-- slot to a unit-conditional macro (@party1 … @player). ExtraIcon GGL
-- instead scans ONE texture (ST) and clicks the matching action-bar key.
-- If that key is the raw spell, heals hit the enemy and MotW never leaves
-- Bear. If that key is a NextCast macro, the same press does the right
-- unit — no snap-target, no form-dance from the addon.
--
-- /nc → Macros → CREATE ALL → PLACE ON BAR
--   CREATE ALL writes character macros (out of combat).
--   PLACE ON BAR (must be a click) replaces the matching spell on the
--   scanned bar with the macro. GGL then presses the macro.
--
-- Click UNIT on a row to cycle smart / @player / @mouseover / @party1–4.
-- Form macros (MotW, Thorns) stay /cancelform + [@player].

local UNITS = { "smart", "player", "mouseover", "party1", "party2", "party3", "party4" }

local catalog = {
    DRUID = {
        { "NC MotW", "Mark of the Wild", "form" },
        { "NC Thorns", "Thorns", "form" },
        { "NC HT", "Healing Touch", "heal" },
        { "NC Rejuv", "Rejuvenation", "heal" },
        { "NC Regrowth", "Regrowth", "heal" },
        { "NC Swiftmend", "Swiftmend", "heal" },
    },
    PRIEST = {
        { "NC FlashHeal", "Flash Heal", "heal" },
        { "NC Heal", "Heal", "heal" },
        { "NC LHeal", "Lesser Heal", "heal" },
        { "NC GHeal", "Greater Heal", "heal" },
        { "NC Renew", "Renew", "heal" },
        { "NC Shield", "Power Word: Shield", "heal" },
        { "NC Fort", "Power Word: Fortitude", "buff" },
        { "NC PoH", "Prayer of Healing", "heal" },
    },
    PALADIN = {
        { "NC FoL", "Flash of Light", "heal" },
        { "NC HolyLight", "Holy Light", "heal" },
        { "NC HolyShock", "Holy Shock", "heal" },
        { "NC LoH", "Lay on Hands", "heal" },
        { "NC BoM", "Blessing of Might", "buff" },
        { "NC BoW", "Blessing of Wisdom", "buff" },
        { "NC BoK", "Blessing of Kings", "buff" },
    },
    SHAMAN = {
        { "NC HWave", "Healing Wave", "heal" },
        { "NC LHWave", "Lesser Healing Wave", "heal" },
        { "NC CHeal", "Chain Heal", "heal" },
        { "NC Riptide", "Riptide", "heal" },
    },
    MAGE = {
        { "NC AI", "Arcane Intellect", "buff" },
    },
}

local function DefaultUnit(kind)
    if kind == "form" or kind == "buff" then
        return "player"
    end
    return "smart"
end

function RH.MacroUnits()
    return UNITS
end

function RH.MacroUnitLabel(kind, unit)
    if kind == "form" then
        return "form"
    end
    unit = unit or DefaultUnit(kind)
    if unit == "smart" then
        return "smart"
    end
    return "@" .. unit
end

local function MacroDB()
    local db = RH.EnsureDB and RH.EnsureDB() or {}
    db.macroUnits = db.macroUnits or {}
    return db
end

function RH.GetMacroUnit(name, kind)
    local db = MacroDB()
    return db.macroUnits[name] or DefaultUnit(kind)
end

function RH.SetMacroUnit(name, unit)
    MacroDB().macroUnits[name] = unit
end

function RH.CycleMacroUnit(name, kind)
    if kind == "form" then
        RH.SetMacroUnit(name, "player")
        return "player"
    end
    local cur = RH.GetMacroUnit(name, kind)
    local idx = 1
    for i = 1, #UNITS do
        if UNITS[i] == cur then
            idx = i
            break
        end
    end
    local nxt = UNITS[(idx % #UNITS) + 1]
    RH.SetMacroUnit(name, nxt)
    return nxt
end

function RH.MacroBody(spell, kind, unit)
    unit = unit or DefaultUnit(kind)
    if kind == "form" then
        return "#showtooltip " .. spell .. "\n/cancelform\n/cast [@player] " .. spell
    end
    local cond
    if unit == "smart" then
        cond = "[@mouseover,help,nodead][@target,help,nodead][@player]"
    elseif unit == "mouseover" then
        cond = "[@mouseover,help,nodead][@player]"
    elseif unit == "player" then
        cond = "[@player]"
    else
        cond = "[@" .. unit .. ",help,nodead][@player]"
    end
    return "#showtooltip " .. spell .. "\n/cast " .. cond .. " " .. spell
end

function RH.MacroCatalog()
    local class = select(2, UnitClass("player"))
    local list = catalog[class] or {}
    local out = {}
    for i = 1, #list do
        local name, spell, kind = list[i][1], list[i][2], list[i][3]
        local unit = RH.GetMacroUnit(name, kind)
        out[i] = {
            name = name,
            spell = spell,
            kind = kind,
            unit = unit,
            body = RH.MacroBody(spell, kind, unit),
        }
    end
    return out
end

function RH.MacroExists(name)
    if not GetMacroIndexByName then
        return false
    end
    local index = GetMacroIndexByName(name)
    return index and index > 0
end

local function SpellNameFromAction(id)
    if HeroCache and HeroCache.SpellInfo then
        local n = HeroCache:SpellInfo(id)
        if type(n) == "string" and n ~= "" then
            return n
        end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, id)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

function RH.FindMacroActionSlot(name)
    if not GetMacroIndexByName or not GetActionInfo then
        return nil
    end
    local index = GetMacroIndexByName(name)
    if not index or index == 0 then
        return nil
    end
    for slot = 1, 120 do
        local ok, actionType, id = pcall(GetActionInfo, slot)
        if ok and actionType == "macro" then
            if id == index then
                return slot
            end
            if GetMacroInfo then
                local ok2, n = pcall(GetMacroInfo, id)
                if ok2 and n == name then
                    return slot
                end
            end
        end
    end
    return nil
end

function RH.FindSpellActionSlot(spell)
    if not GetActionInfo or not spell then
        return nil
    end
    for slot = 1, 120 do
        local ok, actionType, id = pcall(GetActionInfo, slot)
        if ok and actionType == "spell" and type(id) == "number" then
            if SpellNameFromAction(id) == spell then
                return slot
            end
        end
    end
    return nil
end

function RH.EnsureMacro(name, spell, kind)
    if not CreateMacro then
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        return RH.MacroExists(name)
    end
    local unit = RH.GetMacroUnit(name, kind)
    local body = RH.MacroBody(spell, kind, unit)
    local index = GetMacroIndexByName and GetMacroIndexByName(name)
    if not index or index == 0 then
        local ok = pcall(CreateMacro, name, "INV_MISC_QUESTIONMARK", body, 1)
        if not ok then
            ok = pcall(CreateMacro, name, "INV_MISC_QUESTIONMARK", body)
        end
        return ok and RH.MacroExists(name)
    end
    pcall(EditMacro, index, name, nil, body)
    return true
end

function RH.EnsureAllMacros()
    local list = RH.MacroCatalog()
    local made = 0
    for i = 1, #list do
        if RH.EnsureMacro(list[i].name, list[i].spell, list[i].kind) then
            made = made + 1
        end
    end
    return made, #list
end

local function SlotEmpty(slot)
    if HasAction then
        local ok, has = pcall(HasAction, slot)
        if ok then
            return not has
        end
    end
    local ok, actionType = pcall(GetActionInfo, slot)
    return not ok or actionType == nil or actionType == ""
end

-- Must run from a hardware event (button click). Replaces the raw spell
-- on the bar so ExtraIcon GGL presses the macro, not the spell.
function RH.PlaceMacroOnBar(name, spell)
    if InCombatLockdown and InCombatLockdown() then
        return false, "combat"
    end
    if not PickupMacro or not PlaceAction then
        return false, "api"
    end
    local index = GetMacroIndexByName and GetMacroIndexByName(name)
    if not index or index == 0 then
        return false, "missing"
    end
    local have = RH.FindMacroActionSlot(name)
    local spellSlot = RH.FindSpellActionSlot(spell)
    -- If the raw spell is still on the bar, GGL may click it instead of the
    -- macro. Always replace that slot, even when the macro already lives
    -- somewhere else (PickupMacro moves it).
    if have and not spellSlot then
        return true, have
    end
    local target = spellSlot
    if not target then
        for slot = 1, 72 do
            if SlotEmpty(slot) then
                target = slot
                break
            end
        end
    end
    if not target then
        return false, "full"
    end
    local picked = PickupMacro(index)
    if picked == false then
        return false, "pickup"
    end
    PlaceAction(target)
    if ClearCursor then
        ClearCursor()
    end
    local placed = RH.FindMacroActionSlot(name)
    if placed then
        return true, placed
    end
    return false, "place"
end

function RH.PlaceAllMacros()
    local list = RH.MacroCatalog()
    local placed, failed = 0, 0
    for i = 1, #list do
        if not RH.EnsureMacro(list[i].name, list[i].spell, list[i].kind) then
            failed = failed + 1
        else
            local ok = RH.PlaceMacroOnBar(list[i].name, list[i].spell)
            if ok then
                placed = placed + 1
            else
                failed = failed + 1
            end
        end
    end
    return placed, #list, failed
end

function RH.EnsureFriendlyMacros()
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    RH.EnsureAllMacros()
end
