local HL, HC = HeroLib, HeroCache
local Spell = {}
Spell.__index = Spell
local spellObjects = {}
function HL.Spell(id)
    id = tonumber(id) or 0
    if not spellObjects[id] then
        spellObjects[id] = setmetatable({ id = id }, Spell)
    end
    return spellObjects[id]
end
function Spell:ID()
    return HC:SpellID(self:Name()) or self.id
end
function Spell:Name()
    return HC:SpellInfo(self.id)
end
function Spell:Texture()
    local _, texture = HC:SpellInfo(self.id)
    return texture
end
function Spell:IsAvailable()
    local name = self:Name()
    if not name then
        return false
    end
    -- The live spellbook is authoritative on Forever, where learned levels differ.
    return HC:IsKnown(self:ID())
end
function Spell:IsUsable()
    local name = self:Name()
    local function consider(ok, usable)
        if not ok or HL.Secret(usable) then
            return nil
        end
        if usable == true or usable == 1 then
            return true
        end
        if usable == false or usable == 0 then
            return false
        end
        return nil
    end
    if IsUsableSpell then
        local v = consider(pcall(IsUsableSpell, name))
        if v ~= nil then
            return v
        end
        v = consider(pcall(IsUsableSpell, self:ID()))
        if v ~= nil then
            return v
        end
    elseif C_Spell and C_Spell.IsSpellUsable then
        local v = consider(pcall(C_Spell.IsSpellUsable, self:ID()))
        if v ~= nil then
            return v
        end
        if name then
            v = consider(pcall(C_Spell.IsSpellUsable, name))
            if v ~= nil then
                return v
            end
        end
    end
    -- Forever can protect this return. Availability, cooldown and range are
    -- still checked separately, so an unreadable result must not erase
    -- positional abilities such as Backstab.
    return true
end
function Spell:CooldownRemains()
    local name = self:Name()
    local now = GetTime()
    local best = 0
    local function consider(start, duration, enabled)
        if HL.Secret(start) or HL.Secret(duration) then
            return
        end
        if type(start) ~= "number" or type(duration) ~= "number" then
            return
        end
        if enabled == 0 or enabled == false then
            if duration <= 0 then
                duration = 1.5
                start = now
            end
        end
        if duration > 0 and start > 0 then
            local remain = start + duration - now
            if remain > best then
                best = remain
            end
        end
    end
    local function read(arg)
        if not arg or not GetSpellCooldown then
            return
        end
        local ok, start, duration, enabled = pcall(GetSpellCooldown, arg)
        if ok then
            consider(start, duration, enabled)
        end
    end
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, data = pcall(C_Spell.GetSpellCooldown, self:ID())
        if ok and type(data) == "table" and not HL.Secret(data) then
            consider(data.startTime, data.duration, data.isEnabled)
        end
    end
    read(self:ID())
    read(name)
    local slot = name and HeroCache.KnownSlots and HeroCache.KnownSlots[name]
    if slot then
        read(slot)
    end
    local expires = name and HL.State.cooldowns[name]
    if type(expires) == "number" then
        local remain = expires - now
        if remain > best then
            best = remain
        end
    end
    return math.max(0, best)
end
function Spell:IsReady()
    local name = self:Name()
    if name and HL.State.failedUntil[name] and HL.State.failedUntil[name] > GetTime() then
        return false
    end
    if RubimRH and RubimRH.AbilityEnabled and not RubimRH.AbilityEnabled(name) then
        return false
    end
    return self:IsAvailable() and self:CooldownRemains() <= 0.2
end
function Spell:IsInRange(unit)
    unit = unit or "target"
    local ok, value
    if C_Spell and C_Spell.IsSpellInRange then
        ok, value = pcall(C_Spell.IsSpellInRange, self:ID(), unit)
    end
    -- Legacy numeric arguments are spellbook slots, not spell IDs.
    if (not ok or HL.Secret(value) or value == nil) and IsSpellInRange then
        ok, value = pcall(IsSpellInRange, self:Name(), unit)
    end
    if ok and not HL.Secret(value) and value ~= nil then
        return value == 1 or value == true or value == "1"
    end
    -- Forever blocks its interaction-distance query. If normal spell range
    -- is hidden, keep the recommendation available and let the reader/player retry.
    return true
end
function Spell:Cast()
    return self:ID()
end
