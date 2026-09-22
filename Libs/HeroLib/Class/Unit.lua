local HL = HeroLib
local Unit = {}
Unit.__index = Unit
local Units = {}
local unitObjects = {}
setmetatable(Units, {
    __call = function(_, id)
        if not unitObjects[id] then
            unitObjects[id] = setmetatable({ UnitID = id }, Unit)
        end
        return unitObjects[id]
    end,
})
HL.Unit = Units
HL.Unit.Player = HL.Unit("player")
HL.Unit.Target = HL.Unit("target")
local function unitBoolean(api, unit, fallback)
    if not api then
        return fallback
    end
    local ok, value = pcall(api, unit)
    if not ok then
        return fallback
    end
    return HL.SafeBoolean(value, fallback)
end
function Unit:Exists()
    return unitBoolean(UnitExists, self.UnitID, false)
end
function Unit:IsDeadOrGhost()
    return unitBoolean(UnitIsDeadOrGhost, self.UnitID, false)
end
function Unit:AffectingCombat()
    return unitBoolean(UnitAffectingCombat, self.UnitID, false)
end
function Unit:HealthPercentage()
    local okH, h = pcall(UnitHealth, self.UnitID)
    local okM, m = pcall(UnitHealthMax, self.UnitID)
    if not okH or not okM then
        return nil
    end
    if HL.Secret(h) or HL.Secret(m) or type(h) ~= "number" or type(m) ~= "number" or m <= 0 then
        return nil
    end
    return h / m * 100
end
function Unit:ProjectedHealth(seconds)
    local hp = self:HealthPercentage()
    if not hp then
        return nil
    end
    local ok, guid = pcall(UnitGUID, self.UnitID)
    if not ok or HL.Secret(guid) then
        guid = self.UnitID
    end
    local now = GetTime()
    local sample = HL.State.healthTrend[self.UnitID]
    if not sample or sample.guid ~= guid or hp > sample.hp + 2 or now - sample.at > 5 then
        sample = { guid = guid, hp = hp, at = now, rate = 0 }
        HL.State.healthTrend[self.UnitID] = sample
        return hp
    end
    local dt = now - sample.at
    if dt >= 0.15 then
        local change = (sample.hp - hp) / dt
        if change > 0 then
            sample.rate = sample.rate * 0.6 + change * 0.4
        else
            sample.rate = sample.rate * 0.5
        end
        sample.hp = hp
        sample.at = now
    end
    return math.max(0, math.min(100, hp - (sample.rate or 0) * (seconds or 1)))
end
function Unit:TimeToDie()
    if self.UnitID ~= "target" then
        return nil
    end
    local hp = self:HealthPercentage()
    if not hp then
        return nil
    end
    local ok, guid = pcall(UnitGUID, "target")
    if not ok or HL.Secret(guid) then
        guid = nil
    end
    local now = GetTime()
    local s = HL.State.targetHealth
    if s.guid ~= guid or not s.at or now - s.at > 4 or hp > s.hp + 0.5 then
        wipe(s)
        s.guid = guid
        s.hp = hp
        s.at = now
        return nil
    end
    local dt = now - s.at
    if dt >= 0.35 then
        local loss = s.hp - hp
        if loss > 0 then
            local rate = loss / dt
            s.rate = s.rate and (s.rate * 0.7 + rate * 0.3) or rate
            s.lastLossAt = now
        elseif s.lastLossAt and now - s.lastLossAt > 2 then
            s.rate = nil
        end
        s.hp = hp
        s.at = now
    end
    if s.rate and s.rate > 0.05 then
        return math.min(600, hp / s.rate)
    end
    return nil
end
function Unit:Energy()
    return HL.SafeNumber(UnitPower(self.UnitID, 3), nil)
end
function Unit:ComboPoints()
    local function consider(ok, value)
        if ok and not HL.Secret(value) and type(value) == "number" then
            HL.State.combo = math.max(0, math.min(5, value))
            HL.State.comboConfirmedAt = GetTime()
            return true
        end
        return false
    end
    if consider(pcall(GetComboPoints, "player", "target")) then
        return HL.State.combo
    end
    if consider(pcall(GetComboPoints)) then
        return HL.State.combo
    end
    if consider(pcall(UnitPower, "player", 4)) then
        return HL.State.combo
    end
    local enum = Enum and Enum.PowerType and Enum.PowerType.ComboPoints
    if enum and consider(pcall(UnitPower, "player", enum)) then
        return HL.State.combo
    end
    return HL.State.combo or 0
end
local auraAliases = {
    ["Mark of the Wild"] = { "Gift of the Wild" },
    ["Power Word: Fortitude"] = { "Prayer of Fortitude" },
    ["Arcane Intellect"] = { "Arcane Brilliance" },
    ["Blessing of Might"] = { "Greater Blessing of Might" },
    ["Blessing of Wisdom"] = { "Greater Blessing of Wisdom" },
    ["Blessing of Kings"] = { "Greater Blessing of Kings" },
    ["Blessing of Salvation"] = { "Greater Blessing of Salvation" },
    ["Blessing of Light"] = { "Greater Blessing of Light" },
    ["Blessing of Sanctuary"] = { "Greater Blessing of Sanctuary" },
    ["Battle Shout"] = { "Greater Battle Shout" },
    ["Demoralizing Roar"] = { "Demo Roar" },
    ["Demoralizing Shout"] = { "Demo Shout" },
    ["Thorns"] = { "Thorns" },
    ["Inner Fire"] = { "Inner Fire" },
    ["Power Word: Shield"] = { "Power Word: Shield" },
}
local function stripRank(s)
    return (s:gsub("%s*%(?[Rr]ank%s*%d+%)?", ""):gsub("%s+$", ""):gsub("^%s+", ""))
end
local function namesMatch(got, wanted)
    if type(got) ~= "string" or type(wanted) ~= "string" or got == "" then
        return false
    end
    if got == wanted then
        return true
    end
    local g, w = stripRank(got):lower(), stripRank(wanted):lower()
    if g == w then
        return true
    end
    if g:find(w, 1, true) or w:find(g, 1, true) then
        return true
    end
    local extra = auraAliases[wanted]
    if extra then
        for i = 1, #extra do
            local a = extra[i]:lower()
            if got:lower() == a or g == a or g:find(a, 1, true) then
                return true
            end
        end
    end
    return false
end
local function looksTexture(v)
    if type(v) == "number" and v > 100 then
        return true
    end
    if type(v) == "string" and (
        v:find("Interface\\", 1, true)
        or v:find("Interface/", 1, true)
        or v:find("INV_", 1, true)
        or v:find("Spell_", 1, true)
        or v:find("Ability_", 1, true)
        or v:find("Ability ", 1, true)
    ) then
        return true
    end
    return false
end
local function wantedTexture(wanted)
    if GetSpellTexture then
        local ok, tex = pcall(GetSpellTexture, wanted)
        if ok and tex and not HL.Secret(tex) then
            return tex
        end
    end
    if HeroCache and HeroCache.SpellID then
        local id = HeroCache:SpellID(wanted)
        if id then
            local _, tex = HeroCache:SpellInfo(id)
            if tex then
                return tex
            end
        end
    end
end
local function parseAura(a, b, c, d, e, f, g, h, i10, i11)
    if HL.Secret(a) then
        return nil, nil, nil, true
    end
    local name, icon, spellId
    if type(a) == "string" and not looksTexture(a) then
        name = a
        if looksTexture(b) then
            icon = b
        elseif looksTexture(c) then
            icon = c
        end
        if type(i11) == "number" then
            spellId = i11
        elseif type(i10) == "number" then
            spellId = i10
        elseif type(h) == "number" and h > 10 then
            spellId = h
        end
    elseif looksTexture(a) then
        icon = a
    elseif type(a) == "table" then
        name, icon, spellId = a.name, a.icon or a.iconID, a.spellId
    end
    return name, icon, spellId, false
end
local function auraAt(unit, index, helpful)
    local filter = helpful and "HELPFUL" or "HARMFUL"
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok and type(data) == "table" and not HL.Secret(data) then
            return data.name, data.icon or data.iconID, data.spellId, false
        end
    end
    local api = helpful and UnitBuff or UnitDebuff
    if api then
        local ok, a, b, c, d, e, f, g, h, i10, i11 = pcall(api, unit, index)
        if ok and a ~= nil then
            return parseAura(a, b, c, d, e, f, g, h, i10, i11)
        end
    end
    if UnitAura then
        local ok, a, b, c, d, e, f, g, h, i10, i11 = pcall(UnitAura, unit, index, filter)
        if (not ok or a == nil) then
            ok, a, b, c, d, e, f, g, h, i10, i11 = pcall(UnitAura, unit, index)
        end
        if ok then
            return parseAura(a, b, c, d, e, f, g, h, i10, i11)
        end
        return nil, nil, nil, true
    end
    return nil
end
local function aura(unit, wanted, filter)
    if type(wanted) ~= "string" then
        return nil
    end
    local helpful = not (type(filter) == "string" and filter:find("HARMFUL", 1, true))
    local key = unit .. "\031" .. (helpful and "B" or "D") .. "\031" .. wanted
    local cached = HL.State.auraCache[key]
    if cached and GetTime() - cached.at < 0.10 then
        return cached.value
    end
    local function found()
        HL.State.auraCache[key] = { at = GetTime(), value = true }
        return true
    end
    -- Forever / Midnight: C_UnitAuras.GetAuraDataBySpellName is the TMW 12.1.5
    -- path. Index scans throw when auras are secret; name lookup still works.
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local filter = helpful and "HELPFUL" or "HARMFUL"
        local names = { wanted }
        local extra = auraAliases[wanted]
        if extra then
            for i = 1, #extra do
                names[#names + 1] = extra[i]
            end
        end
        for i = 1, #names do
            local ok, data = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, names[i], filter)
            if ok and type(data) == "table" and not HL.Secret(data) then
                return found()
            end
        end
    end
    -- Direct name lookup (WotLK+ / some Classic builds).
    if UnitAura then
        local ok, name = pcall(UnitAura, unit, wanted)
        if ok and not HL.Secret(name) and namesMatch(name, wanted) then
            return found()
        end
        ok, name = pcall(UnitAura, unit, wanted, nil, helpful and "HELPFUL" or "HARMFUL")
        if ok and not HL.Secret(name) and namesMatch(name, wanted) then
            return found()
        end
    end
    if helpful and UnitBuff then
        local ok, name = pcall(UnitBuff, unit, wanted)
        if ok and not HL.Secret(name) and namesMatch(name, wanted) then
            return found()
        end
    end
    if not helpful and UnitDebuff then
        local ok, name = pcall(UnitDebuff, unit, wanted)
        if ok and not HL.Secret(name) and namesMatch(name, wanted) then
            return found()
        end
    end
    local spellId = HeroCache and HeroCache.SpellID and HeroCache:SpellID(wanted)
    if spellId and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and unit == "player" then
        local ok, data = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
        if ok and type(data) == "table" then
            return found()
        end
    end
    if GetPlayerAuraBySpellID and unit == "player" and spellId then
        local ok, data = pcall(GetPlayerAuraBySpellID, spellId)
        if ok and data then
            return found()
        end
    end
    local wantTex = wantedTexture(wanted)
    local hidden = false
    local sawAny = false
    -- Player 1.12 GetPlayerBuff is the most reliable self-buff scan.
    if unit == "player" and GetPlayerBuff then
        for i = 0, 31 do
            local ok, buffIndex = pcall(GetPlayerBuff, i, helpful and "HELPFUL" or "HARMFUL")
            buffIndex = ok and HL.SafeNumber(buffIndex, nil) or nil
            if buffIndex and buffIndex > 0 then
                sawAny = true
                local name
                if GetPlayerBuffName then
                    local nok, n = pcall(GetPlayerBuffName, buffIndex)
                    if nok and not HL.Secret(n) then
                        name = n
                    elseif nok and HL.Secret(n) then
                        hidden = true
                    end
                end
                if namesMatch(name, wanted) then
                    return found()
                end
                if wantTex and GetPlayerBuffTexture then
                    local tok, tex = pcall(GetPlayerBuffTexture, buffIndex)
                    if tok and tex and not HL.Secret(tex) and tex == wantTex then
                        return found()
                    end
                end
            end
        end
    end
    for i = 1, 40 do
        local name, icon, id, secret = auraAt(unit, i, helpful)
        if secret then
            hidden = true
        elseif name == nil and icon == nil and id == nil then
            if i == 1 and not sawAny then
                break
            end
            if hidden then
                HL.State.auraCache[key] = { at = GetTime(), value = nil }
                return nil
            end
            break
        else
            sawAny = true
            if namesMatch(name, wanted) then
                return found()
            end
            if spellId and id and id == spellId then
                return found()
            end
            if wantTex and icon and icon == wantTex then
                return found()
            end
        end
    end
    if hidden and not sawAny then
        HL.State.auraCache[key] = { at = GetTime(), value = nil }
        return nil
    end
    HL.State.auraCache[key] = { at = GetTime(), value = false }
    return false
end
function HL.InvalidateAuras(unit)
    if not unit then
        wipe(HL.State.auraCache)
        return
    end
    local prefix = unit .. "\031"
    for key in pairs(HL.State.auraCache) do
        if string.sub(key, 1, #prefix) == prefix then
            HL.State.auraCache[key] = nil
        end
    end
end
local function inferred(bucket, name)
    local expires = bucket[name]
    if type(expires) == "number" then
        if expires > GetTime() then
            return true
        end
        bucket[name] = nil
    end
    return false
end
function Unit:Buff(name)
    local visible = aura(self.UnitID, name, "HELPFUL")
    if visible == true then
        return true
    end
    local unitKey = self.UnitID .. "\031" .. name
    local noted = HL.State.unitBuffs and HL.State.unitBuffs[unitKey]
    if type(noted) == "number" and noted > GetTime() then
        return true
    end
    if inferred(HL.State.buffs, name) and self.UnitID == "player" then
        return true
    end
    return visible
end
function Unit:Debuff(name)
    local visible = aura(self.UnitID, name, "HARMFUL")
    if visible == true then
        return true
    end
    -- Same as Buff: a successful/noted apply wins over a false aura scan.
    -- Target swaps wipe HL.State.debuffs.
    if self.UnitID == "target" and inferred(HL.State.debuffs, name) then
        return true
    end
    return visible
end
function Unit:IsCasting()
    local ok, name = pcall(UnitCastingInfo, self.UnitID)
    if ok and not HL.Secret(name) and name then
        return true
    end
    ok, name = pcall(UnitChannelInfo, self.UnitID)
    return ok and not HL.Secret(name) and name ~= nil or false
end
local function castDetails(api, unit, channel)
    if not api then
        return nil
    end
    local ok, name, _, _, startMS, endMS, _, a, b, c = pcall(api, unit)
    if not ok or HL.Secret(name) or not name then
        return nil
    end
    -- UnitCastingInfo exposes castID before notInterruptible; UnitChannelInfo
    -- does not. Keep the two layouts explicit so spell IDs never become flags.
    local notInterruptible, spellID
    if channel then
        notInterruptible, spellID = a, b
    else
        notInterruptible, spellID = b, c
    end
    local start = HL.SafeNumber(startMS, nil)
    local finish = HL.SafeNumber(endMS, nil)
    local blocked = HL.SafeBoolean(notInterruptible, nil)
    if HL.Secret(spellID) or type(spellID) ~= "number" then
        spellID = nil
    end
    local interruptible
    if blocked ~= nil then
        interruptible = not blocked
    end
    return { name = name, start = start and start / 1000, finish = finish and finish / 1000, interruptible = interruptible, id = spellID }
end
function Unit:CastInfo()
    return castDetails(UnitCastingInfo, self.UnitID, false) or castDetails(UnitChannelInfo, self.UnitID, true)
end
function Unit:CastRemains()
    local info = self:CastInfo()
    if not info then
        return 0
    end
    return info.finish and math.max(0, info.finish - GetTime()) or nil
end
function Unit:IsInterruptible()
    local info = self:CastInfo()
    if info then
        return info.interruptible
    end
end
