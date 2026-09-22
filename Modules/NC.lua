-- NextCast rotation language. Recommend-only — never CastSpell.
-- Rotations are a priority list. First matching step wins.
local RH, HL = RubimRH, HeroLib
local NC = {}
RH.NC = NC
NC.STOP = {}

function NC.Ready(spell, range)
    return RH.Ready(spell, range)
end

function NC.Buff(name, unit)
    unit = unit or "player"
    local who = unit == "player" and RH.Player or (unit == "target" and RH.Target or HL.Unit(unit))
    return who and who:Buff(name) == true
end

function NC.Debuff(name, unit)
    unit = unit or "target"
    local who = unit == "player" and RH.Player or (unit == "target" and RH.Target or HL.Unit(unit))
    return who and who:Debuff(name) == true
end

function NC.Combo()
    if RH.Player and RH.Player.ComboPoints then
        return RH.Player:ComboPoints() or 0
    end
    return (HL.State and HL.State.combo) or 0
end

function NC.HP(unit)
    unit = unit or "player"
    local who = unit == "player" and RH.Player or (unit == "target" and RH.Target or HL.Unit(unit))
    if not who then
        return nil
    end
    return who:HealthPercentage()
end

function NC.Enemies()
    return RH.CountNearbyEnemies() or 0
end

function NC.Go(spell)
    if not spell then
        return nil
    end
    if type(spell) == "number" then
        return spell
    end
    if type(spell) == "function" then
        return spell()
    end
    return spell:Cast()
end

function NC.CDs()
    return RH.CDs ~= false
end

function NC.AoE()
    return RH.AoE == true
end

function NC.Interrupts()
    return RH.Interrupts ~= false
end

function NC.Form(needle)
    return RH.InForm and RH.InForm(needle)
end

function NC.Rage()
    return RH.Power(1)
end

function NC.Energy()
    return RH.Power(3)
end

function NC.Mana()
    return RH.PowerPercent(0)
end

function NC.OnCD(spell)
    if not spell or not spell.CooldownRemains then
        return false
    end
    return (spell:CooldownRemains() or 0) > 0.4
end

function NC.Missing(spell, names, seconds)
    return RH.CastIfMissing(spell, names, seconds)
end

function NC.Dot(spell, names, seconds, melee)
    return RH.CastIfDebuffMissing(spell, names, seconds, melee)
end

-- Walk a priority list. Each step is:
--   function() return NC.Go(S.Kick) end
--   { S.Kick, when = function() return NC.Interrupts() end, range = true }
-- First truthy return wins.
function NC.Prio(steps)
    if not steps then
        return nil
    end
    for i = 1, #steps do
        local step = steps[i]
        local id
        local kind = type(step)
        if kind == "function" then
            id = step()
        elseif kind == "table" then
            local spell = step.spell or step[1]
            local when = step.when
            if when == nil or when() then
                if type(spell) == "function" then
                    id = spell()
                elseif spell then
                    if NC.Ready(spell, step.range) then
                        if step.note then
                            step.note()
                        end
                        id = NC.Go(spell)
                    end
                end
            end
        end
        if id == NC.STOP then
            return nil
        end
        if id then
            return id
        end
    end
    return nil
end
