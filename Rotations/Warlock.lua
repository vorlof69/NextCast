local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    ShadowBolt = RH.S(686),
    Corruption = RH.S(172),
    Immolate = RH.S(348),
    Agony = RH.Named("Bane of Agony", 980),
    LifeTap = RH.S(1454),
    Drain = RH.S(689),
    DrainSoul = RH.S(1120),
    Siphon = RH.S(18265),
    Fear = RH.S(5782),
    Howl = RH.S(5484),
    Rain = RH.S(5740),
    Conflagrate = RH.S(17962),
    DemonSkin = RH.S(687),
    DemonArmor = RH.S(706),
    SummonImp = RH.S(688),
    SummonVoidwalker = RH.S(697),
    Shoot = RH.S(5019),
    Incinerate = RH.Named("Incinerate"),
    Wrack = RH.Named("Wrack"),
    BaneHavoc = RH.Named("Bane of Havoc"),
}
RubimRH.Rotation.SetAPL(9, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Affliction"
    local pvp = RH.IsPvPContext(db.warlockContext)
    local hp = P:HealthPercentage()
    local targetHP = T:HealthPercentage()
    local ttd = T:TimeToDie()
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local armor = S.DemonArmor:IsAvailable() and RH.AbilityEnabled("Demon Armor") and S.DemonArmor or S.DemonSkin
    local armorName = armor:Name()
    if db.maintainBuffs ~= false and armorName then
        local cast = RH.CastIfMissing(armor, armorName, 300)
        if cast then
            return cast
        end
    end
    local pet = HeroLib.Unit("pet")
    if db.warlockPet ~= false and not P:AffectingCombat() and (not pet:Exists() or pet:IsDeadOrGhost()) then
        local summon = (spec == "Demonology" and S.SummonVoidwalker:IsAvailable()) and S.SummonVoidwalker or S.SummonImp
        if RH.Ready(summon) then
            return summon:Cast()
        end
    end
    if not RH.ValidTarget() then
        return nil
    end
    if
        db.defensives ~= false
        and pvp
        and RH.UnitWithin("target", 10) == true
        and hp
        and hp < (tonumber(db.defensiveHP) or 30)
        and RH.Ready(S.Howl)
    then
        return S.Howl:Cast()
    end
    if pvp and T:Debuff("Fear") ~= true and RH.Ready(S.Fear, true) then
        return S.Fear:Cast()
    end
    if mana and mana < (tonumber(db.warlockLifeTapMana) or 25) then
        if hp and hp > 65 and RH.Ready(S.LifeTap) then
            return S.LifeTap:Cast()
        end
        return RH.RangedFallback(S.Shoot)
    end
    if db.useDots ~= false and RH.ResourceAbove(mana, reserve) and RH.TargetWillLive(math.max(10, tonumber(db.dotMinTTD) or 8)) then
        local curse = RH.CastIfDebuffMissing(S.Wrack, { "Wrack", "Bane of Agony", "Curse of Agony" }, 20, true)
            or RH.CastIfDebuffMissing(S.Agony, { "Wrack", "Bane of Agony", "Curse of Agony" }, 20, true)
        if curse then
            return curse
        end
    end
    if
        db.useDots ~= false
        and RH.ResourceAbove(mana, reserve)
        and RH.TargetWillLive(math.max(9, tonumber(db.dotMinTTD) or 8))
    then
        local corr = RH.CastIfDebuffMissing(S.Corruption, "Corruption", 14, true)
        if corr then
            return corr
        end
    end
    if
        db.useDots ~= false
        and spec == "Affliction"
        and RH.ResourceAbove(mana, reserve)
        and RH.TargetWillLive(12)
    then
        local siphon = RH.CastIfDebuffMissing(S.Siphon, "Siphon Life", 24, true)
        if siphon then
            return siphon
        end
    end
    if
        db.useDots ~= false
        and spec == "Destruction"
        and RH.ResourceAbove(mana, reserve)
        and RH.TargetWillLive(8)
    then
        local imm = RH.CastIfDebuffMissing(S.Immolate, "Immolate", 12, true)
        if imm then
            return imm
        end
    end
    if targetHP and targetHP < 15 and RH.Ready(S.DrainSoul, true) then
        return S.DrainSoul:Cast()
    end
    if RH.AoE and RH.ResourceAbove(mana, 40) then
        local havoc = RH.CastIfDebuffMissing(S.BaneHavoc, "Bane of Havoc", 20, true)
        if havoc then
            return havoc
        end
    end
    if RH.AoE and RH.ResourceAbove(mana, 40) and RH.Ready(S.Rain, true) then
        return S.Rain:Cast()
    end
    if db.healing ~= false and hp and hp < (pvp and math.max(tonumber(db.warlockDrainLifeHP) or 45, 52) or (tonumber(db.warlockDrainLifeHP) or 45)) and RH.Ready(S.Drain, true) then
        return S.Drain:Cast()
    end
    if spec == "Destruction" then
        if T:Debuff("Immolate") == true and RH.Ready(S.Conflagrate, true) then
            return S.Conflagrate:Cast()
        end
        if RH.Ready(S.Incinerate, true) then
            return S.Incinerate:Cast()
        end
    end
    if mana and mana < (tonumber(db.warlockLifeTapMana) or 25) then
        if hp and hp > 65 and RH.Ready(S.LifeTap) then
            return S.LifeTap:Cast()
        end
        return RH.RangedFallback(S.Shoot)
    end
    if not RH.ResourceAbove(mana, reserve) then
        return RH.RangedFallback(S.Shoot)
    end
    if RH.Ready(S.ShadowBolt, true) then
        return S.ShadowBolt:Cast()
    end
    return RH.RangedFallback(S.Shoot)
end)
