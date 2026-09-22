local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Attack = RH.S(6603),
    SS = RH.S(1752),
    Evis = RH.Named("Eviscerate", 2098),
    Stealth = RH.S(1784),
    Sap = RH.S(6770),
    Cheap = RH.S(1833),
    Ambush = RH.S(8676),
    Garrote = RH.S(703),
    Kick = RH.S(1766),
    Riposte = RH.S(14251),
    Gouge = RH.S(1776),
    Evasion = RH.S(5277),
    BF = RH.S(13877),
    CB = RH.S(14177),
    SnD = RH.Named("Slice and Dice", 5171),
    Rupture = RH.Named("Rupture", 1943),
    Backstab = RH.S(53),
    Kidney = RH.S(408),
    Sprint = RH.S(2983),
    Ghostly = RH.S(14278),
    Hemo = RH.S(16511),
    Mutilate = RH.S(1329),
    Vanish = RH.S(1856),
    Feint = RH.S(1966),
    Expose = RH.Named("Expose Armor", 8647),
}
RubimRH.Rotation.SetAPL(4, function()
    if P:IsDeadOrGhost() or P:IsCasting() or not RH.ValidTarget() then
        return nil
    end
    local db = RH.EnsureDB()
    local cp = P:ComboPoints() or 0
    local energy = RH.Power(3) or 0
    local melee = S.SS:IsInRange()
    local engageRange = RH.UnitWithin("target", tonumber(db.stealthRange) or 25)
    local hp = P:HealthPercentage()
    local targetHP = T:HealthPercentage()
    local ttd = T:TimeToDie()
    local dagger = RH.MainHandIsDagger()
    local behind = not HeroLib.State.notBehindUntil or HeroLib.State.notBehindUntil <= GetTime()
    local pvp = RH.IsPvPContext(db.rogueContext)
    if P:Buff("Stealth") then
        local opener = db.rogueOpener or "auto"
        local sapped = T:Debuff("Sap")
        -- Do not let the reader immediately break a Sap that NextCast just suggested.
        if sapped == true then
            return nil
        end
        if
            opener == "auto"
            and pvp
            and db.rogueSap
            and not P:AffectingCombat()
            and not T:AffectingCombat()
            and sapped == false
            and RH.Ready(S.Sap, true)
        then
            return S.Sap:Cast()
        end
        if opener == "ambush" and S.Ambush:IsAvailable() then
            if dagger == true and behind and RH.Ready(S.Ambush, true) then
                return S.Ambush:Cast()
            end
            return nil
        end
        if opener == "garrote" and S.Garrote:IsAvailable() then
            if RH.Ready(S.Garrote, true) then
                return S.Garrote:Cast()
            end
            return nil
        end
        if opener == "cheap" and S.Cheap:IsAvailable() then
            if RH.Ready(S.Cheap, true) then
                return S.Cheap:Cast()
            end
            return nil
        end
        -- Automatic: Cheap Shot controls players; Ambush is the dagger PvE burst
        -- opener; Garrote works as the durable/no-dagger fallback.
        if pvp and RH.Ready(S.Cheap, true) then
            return S.Cheap:Cast()
        end
        if dagger == true and behind and RH.Ready(S.Ambush, true) then
            return S.Ambush:Cast()
        end
        if RH.TargetWillLive(10) and RH.Ready(S.Garrote, true) then
            return S.Garrote:Cast()
        end
        if RH.Ready(S.Cheap, true) then
            return S.Cheap:Cast()
        end
        -- Exit Stealth with the baseline builder only when no learned opener works.
        if RH.Ready(S.SS, true) then
            return S.SS:Cast()
        end
        return nil
    end
    if
        db.rogueStealth
        and not P:AffectingCombat()
        and engageRange == true
        and S.Stealth:IsReady()
        and P:Buff("Stealth") == false
        and not RH.RecentlyBuffed("player", "Stealth")
    then
        RH.NoteBuff("player", "Stealth", 60)
        return S.Stealth:Cast()
    end
    if not P:AffectingCombat() and engageRange == false then
        return nil
    end
    if RH.Interrupts and RH.ShouldInterrupt() and RH.Ready(S.Kick, true) then
        return S.Kick:Cast()
    end
    if pvp and cp >= (tonumber(db.kidneyCP) or 4) and RH.Ready(S.Kidney, true) then
        return S.Kidney:Cast()
    end
    if pvp and db.defensives ~= false and hp and hp < (tonumber(db.defensiveHP) or 30) - 10 and RH.Ready(S.Vanish) then
        return S.Vanish:Cast()
    end
    if pvp and hp and hp < 45 and RH.Ready(S.Sprint) then
        return S.Sprint:Cast()
    end
    if
        db.defensives ~= false
        and db.rogueEvasion
        and hp
        and hp < (tonumber(db.evasionHP) or 35)
        and RH.Ready(S.Evasion)
    then
        return S.Evasion:Cast()
    end
    if db.defensives ~= false and hp and hp < 45 and melee then
        local feint = RH.CastIfMissing(S.Feint, "Feint", 8)
        if feint then
            return feint
        end
    end
    -- Cold Blood guarantees a crit -- save it for Burst mode so it lands on a
    -- cooldown-stacked finisher instead of firing on the first big combo point.
    if RH.CDs and RH.Burst and cp >= (tonumber(db.rogueCooldownCP) or 4) and RH.Ready(S.CB) then
        return S.CB:Cast()
    end
    if RH.CDs and RH.AoE and melee and RH.Ready(S.BF) then
        return S.BF:Cast()
    end
    if
        db.defensives ~= false
        and db.rogueGouge
        and hp
        and hp < (tonumber(db.gougeHP) or 50)
        and melee
        and RH.Ready(S.Gouge, true)
        and T:Debuff("Gouge") ~= true
    then
        return S.Gouge:Cast()
    end
    -- Five-point leveling finisher. A 5 CP Slice and Dice lasts about 21 seconds;
    -- prefer direct damage unless the target is actually likely to live that long.
    if cp >= (tonumber(db.evisCP) or 5) then
        local classification = RH.SafeUnitText(UnitClassification, "target")
        local durable = classification == "elite" or classification == "rareelite" or classification == "worldboss"
        local sndLifetime = tonumber(db.sndMinTTD) or 21
        local survivesSnD = (ttd and ttd >= sndLifetime) or (not ttd and durable and targetHP and targetHP >= 75)
        local sndActive = P:Buff("Slice and Dice") == true
        if
            db.rogueSnD ~= false
            and not sndActive
            and not RH.RecentlyBuffed("player", "Slice and Dice")
            and (pvp or survivesSnD)
            and RH.Ready(S.SnD)
        then
            RH.NoteBuff("player", "Slice and Dice", 12)
            return S.SnD:Cast()
        end
        if
            sndActive
            and db.rogueRupture ~= false
            and db.useDots ~= false
            and ((ttd and ttd > (tonumber(db.ruptureMinTTD) or 18)) or durable)
        then
            local rupture = RH.CastIfDebuffMissing(S.Rupture, "Rupture", 12, true)
            if rupture then
                return rupture
            end
        end
        if durable and db.rogueExpose and RH.Ready(S.Expose, true) then
            local expose = RH.CastIfDebuffMissing(S.Expose, "Expose Armor", 20, true)
            if expose then
                return expose
            end
        end
        -- Eviscerate is the default dump. Do not gate it on IsUsableSpell —
        -- Forever can report "not usable" with 5 CP while builders still work.
        -- Wait on energy/range instead of falling through to Sinister Strike.
        if db.rogueEvis ~= false and RH.AbilityEnabled("Eviscerate") then
            local inMelee = melee or S.Evis:IsInRange()
            if inMelee and ((energy or 0) >= 35 or S.Evis:IsUsable() == true) then
                return S.Evis:Cast()
            end
            if inMelee then
                return nil
            end
        end
    end
    if melee and RH.Ready(S.Riposte) then
        return S.Riposte:Cast()
    end
    if RH.Ready(S.Mutilate, true) then
        return S.Mutilate:Cast()
    end
    if RH.Ready(S.Hemo, true) then
        return S.Hemo:Cast()
    end
    if cp < 5 and melee and RH.Ready(S.Ghostly, true) then
        return S.Ghostly:Cast()
    end
    if behind and dagger == true and melee and RH.Ready(S.Backstab, true) then
        return S.Backstab:Cast()
    end
    if melee and RH.Ready(S.SS) then
        return S.SS:Cast()
    end
    return RH.AttackOnce()
end)
