local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Auto = RH.S(75),
    Mark = RH.Named("Hunter's Mark", 1130),
    Serpent = RH.Named("Serpent Sting", 1978),
    Arcane = RH.Named("Arcane Shot", 3044),
    Multi = RH.Named("Multi-Shot", 2643),
    Aimed = RH.Named("Aimed Shot", 19434),
    Raptor = RH.Named("Raptor Strike", 2973),
    Mongoose = RH.Named("Mongoose Bite", 1495),
    Wing = RH.Named("Wing Clip", 2974),
    CallPet = RH.S(883),
    RevivePet = RH.S(982),
    Mend = RH.Named("Mend Pet", 136),
    Rapid = RH.S(3045),
    Scatter = RH.S(19503),
    Intimidation = RH.S(19577),
    ExplosiveTrap = RH.S(13813),
    Concussive = RH.Named("Concussive Shot", 5116),
    Hawk = RH.S(13165),
    Monkey = RH.S(13163),
    Feign = RH.Named("Feign Death", 5384),
}
RubimRH.Rotation.SetAPL(3, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local pvp = RH.IsPvPContext(db.hunterContext)
    local spec = db.spec or "Beast Mastery"
    local petHP = HeroLib.Unit("pet"):HealthPercentage()
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local pet = HeroLib.Unit("pet")
    if db.hunterPet ~= false and not P:AffectingCombat() then
        if pet:IsDeadOrGhost() and RH.Ready(S.RevivePet) then
            return S.RevivePet:Cast()
        elseif not pet:Exists() and RH.Ready(S.CallPet) then
            return S.CallPet:Cast()
        end
    end
    if
        db.hunterPet ~= false
        and db.healing ~= false
        and petHP
        and petHP < (pvp and math.max(tonumber(db.hunterPetHealHP) or 65, 70) or (tonumber(db.hunterPetHealHP) or 65))
        and HeroLib.Unit("pet"):Buff("Mend Pet") ~= true
        and RH.Ready(S.Mend, "pet")
    then
        RH.healTarget = "pet"
        return S.Mend:Cast()
    end
    local playerHP = P:HealthPercentage()
    local needsMonkey = db.defensives ~= false
        and playerHP
        and playerHP < (tonumber(db.defensiveHP) or 30)
        and RH.UnitWithin("target", 10) == true
    local aspect = (needsMonkey or not S.Hawk:IsAvailable()) and S.Monkey or S.Hawk
    if not RH.AbilityEnabled(aspect:Name()) then
        aspect = aspect == S.Monkey and S.Hawk or S.Monkey
    end
    local aspectName = aspect:Name()
    if db.maintainBuffs ~= false and aspectName then
        local cast = RH.CastIfMissing(aspect, aspectName, 180)
        if cast then
            return cast
        end
    end
    RH.healTarget = nil
    if not RH.ValidTarget() then
        return nil
    end
    if
        db.defensives ~= false
        and P:AffectingCombat()
        and playerHP
        and playerHP <= (tonumber(db.defensiveHP) or 30)
        and RH.Ready(S.Feign)
    then
        return S.Feign:Cast()
    end
    local melee = S.Raptor:IsInRange()
    local ttd = T:TimeToDie()
    if RH.Interrupts and RH.ShouldInterrupt() then
        if RH.Ready(S.Scatter, true) then
            return S.Scatter:Cast()
        end
        if RH.Ready(S.Intimidation, true) then
            return S.Intimidation:Cast()
        end
    end
    if pvp and melee and T:Debuff("Wing Clip") ~= true and RH.Ready(S.Wing, true) then
        return S.Wing:Cast()
    end
    if
        pvp
        and db.hunterConcussive ~= false
        and T:Debuff("Concussive Shot") ~= true
        and RH.Ready(S.Concussive, true)
    then
        return S.Concussive:Cast()
    end
    if db.maintainBuffs ~= false and RH.TargetWillLive(10) then
        local mark = RH.CastIfDebuffMissing(S.Mark, "Hunter's Mark", 90, true)
        if mark then
            return mark
        end
    end
    if
        db.useDots ~= false
        and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8)
        and RH.ResourceAbove(mana, reserve)
    then
        local sting = RH.CastIfDebuffMissing(S.Serpent, "Serpent Sting", 12, true)
        if sting then
            return sting
        end
    end
    -- Rapid Fire is a ranged-attack-speed cooldown -- hold it for Burst mode
    -- instead of dumping it on the first Serpent Sting refresh.
    if RH.CDs and RH.Burst and RH.Ready(S.Rapid) then
        return S.Rapid:Cast()
    end
    if RH.AoE and melee and RH.Ready(S.ExplosiveTrap) then
        return S.ExplosiveTrap:Cast()
    end
    if
        RH.AoE
        and RH.ResourceAbove(mana, math.max(tonumber(db.hunterMultiMana) or 35, reserve))
        and RH.Ready(S.Multi, true)
    then
        return S.Multi:Cast()
    end
    if spec == "Marksmanship" and RH.ResourceAbove(mana, math.max(30, reserve)) and RH.Ready(S.Aimed, true) then
        return S.Aimed:Cast()
    end
    if melee then
        if RH.Ready(S.Mongoose, true) then
            return S.Mongoose:Cast()
        end
        if RH.Ready(S.Raptor, true) then
            return S.Raptor:Cast()
        end
    end
    if RH.ResourceAbove(mana, math.max(tonumber(db.hunterArcaneMana) or 25, reserve)) and RH.Ready(S.Arcane, true) then
        return S.Arcane:Cast()
    end
    if S.Auto:IsAvailable() and not melee then
        return RH.AutoShotOnce(S.Auto)
    end
    if melee then
        return RH.AttackOnce()
    end
end)
