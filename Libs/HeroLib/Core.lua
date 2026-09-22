HeroLib = HeroLib or {}
HeroLibEx = HeroLib
local HL = HeroLib
function HL.Secret(v)
    return issecretvalue and issecretvalue(v)
end
function HL.SafeNumber(v, fallback)
    if HL.Secret(v) or type(v) ~= "number" then
        return fallback
    end
    return v
end
function HL.SafeBoolean(v, fallback)
    if HL.Secret(v) then
        return fallback
    end
    if v == true or v == 1 then
        return true
    end
    if v == false or v == 0 then
        return false
    end
    return fallback
end
function HL.GetTime()
    return GetTime()
end
HL.State = HL.State
    or {
        cooldowns = {},
        buffs = {},
        debuffs = {},
        combo = 0,
        pending = {},
        targetHealth = {},
        targetStacks = {},
        auraCache = {},
        healthTrend = {},
        casts = {},
        unitBuffs = {},
    }
HL.State.targetHealth = HL.State.targetHealth or {}
HL.State.targetStacks = HL.State.targetStacks or {}
HL.State.auraCache = HL.State.auraCache or {}
HL.State.healthTrend = HL.State.healthTrend or {}
HL.State.casts = HL.State.casts or {}
HL.State.failedUntil = HL.State.failedUntil or {}
function HL.PreviousSpell(index, spell)
    local cast = HL.State.casts[index or 1]
    if not cast then
        return false
    end
    if spell == nil then
        return cast.name, cast.id, cast.at
    end
    return cast.id == spell or cast.name == spell
end
