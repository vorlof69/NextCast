local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Frostbolt = RH.S(116),
    Fireball = RH.S(133),
    FireBlast = RH.S(2136),
    Nova = RH.S(122),
    Cone = RH.S(120),
    ArcaneExplosion = RH.S(1449),
    Missiles = RH.S(5143),
    Scorch = RH.S(2948),
    Pyroblast = RH.S(11366),
    Blizzard = RH.S(10),
    Evocation = RH.S(12051),
    Intellect = RH.Named("Arcane Intellect", 1459),
    FrostArmor = RH.S(168),
    Counterspell = RH.S(2139),
    Blink = RH.S(1953),
    IceBlock = RH.Named("Ice Block", 45438),
    Shoot = RH.S(5019),
    ArcaneBlast = RH.Named("Arcane Blast"),
    Polymorph = RH.S(118),
    IceLance = RH.Named("Ice Lance"),
}
RubimRH.Rotation.SetAPL(8, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Frost"
    local pvp = RH.IsPvPContext(db.mageContext)
    local mana = RH.PowerPercent(0)
    local close = RH.UnitWithin("target", 10)
    local hp = P:HealthPercentage()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    if db.maintainBuffs ~= false then
        local unit = RH.FindMissingBuff("Arcane Intellect")
        if unit then
            local cast = RH.CastAllyBuff(S.Intellect, unit, "Arcane Intellect", 300)
            if cast then
                return cast
            end
        end
    end
    if db.maintainBuffs ~= false then
        local armor = RH.CastIfMissing(S.FrostArmor, { "Frost Armor", "Ice Armor", "Mage Armor" }, 300)
        if armor then
            return armor
        end
    end
    if not RH.ValidTarget() then
        return nil
    end
    if RH.Interrupts and RH.ShouldInterrupt() and RH.Ready(S.Counterspell, true) then
        return S.Counterspell:Cast()
    end
    if pvp and not P:AffectingCombat() and T:Debuff("Polymorph") ~= true and RH.Ready(S.Polymorph, true) then
        return S.Polymorph:Cast()
    end
    if db.defensives ~= false and hp and hp < (tonumber(db.defensiveHP) or 30) - 5 and RH.Ready(S.IceBlock) then
        return S.IceBlock:Cast()
    end
    if
        db.defensives ~= false
        and hp
        and hp < (tonumber(db.defensiveHP) or 30) + 15
        and close == true
        and RH.Ready(S.Blink)
    then
        return S.Blink:Cast()
    end
    if mana and mana < (tonumber(db.mageEvocationMana) or 15) and RH.Ready(S.Evocation) then
        return S.Evocation:Cast()
    end
    if
        db.mageControl ~= false
        and (pvp or RH.AoE)
        and close
        and T:Debuff("Frost Nova") ~= true
        and RH.Ready(S.Nova)
    then
        return S.Nova:Cast()
    end
    if
        db.mageControl ~= false
        and close
        and (pvp or RH.AoE)
        and RH.ResourceAbove(mana, 35)
        and RH.Ready(S.Cone, true)
    then
        return S.Cone:Cast()
    end
    -- Conserve with Wand only after Shoot is actually learned. Early Mages must
    -- continue using an affordable spell instead of showing a blank recommendation.
    if not RH.ResourceAbove(mana, reserve) and S.Shoot:IsAvailable() then
        return RH.RangedFallback(S.Shoot)
    end
    if RH.AoE then
        local aoeMana = tonumber(db.mageAoEMana) or 40
        if close and RH.ResourceAbove(mana, aoeMana) and RH.Ready(S.ArcaneExplosion) then
            return S.ArcaneExplosion:Cast()
        end
        if RH.ResourceAbove(mana, aoeMana + 5) and RH.Ready(S.Blizzard, true) then
            return S.Blizzard:Cast()
        end
    end
    if spec == "Arcane" then
        if RH.Ready(S.ArcaneBlast, true) then
            return S.ArcaneBlast:Cast()
        end
        if RH.Ready(S.Missiles, true) then
            return S.Missiles:Cast()
        end
    elseif spec == "Fire" then
        if P:Buff("Hot Streak") == true and RH.Ready(S.Pyroblast, true) then
            return S.Pyroblast:Cast()
        end
        if RH.Ready(S.FireBlast, true) then
            return S.FireBlast:Cast()
        end
        if RH.Ready(S.Fireball, true) then
            return S.Fireball:Cast()
        end
        if RH.Ready(S.Scorch, true) then
            return S.Scorch:Cast()
        end
    else
        if P:Buff("Fingers of Frost") == true and RH.Ready(S.IceLance, true) then
            return S.IceLance:Cast()
        end
        if RH.Ready(S.Frostbolt, true) then
            return S.Frostbolt:Cast()
        end
    end
    -- Level-aware cross-spec fallback. Automatic defaults to Frost before talent
    -- points exist, while a new Mage initially knows Fireball.
    if RH.Ready(S.Fireball, true) then
        return S.Fireball:Cast()
    end
    if RH.Ready(S.Frostbolt, true) then
        return S.Frostbolt:Cast()
    end
    if RH.Ready(S.Missiles, true) then
        return S.Missiles:Cast()
    end
    return RH.RangedFallback(S.Shoot)
end)
