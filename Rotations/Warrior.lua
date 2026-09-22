local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Attack = RH.S(6603),
    Charge = RH.S(100),
    Rend = RH.S(772),
    Thunder = RH.S(6343),
    Overpower = RH.S(7384),
    Execute = RH.S(5308),
    Sunder = RH.S(7386),
    Heroic = RH.S(78),
    Bloodrage = RH.S(2687),
    Hamstring = RH.S(1715),
    BerserkerRage = RH.S(18499),
    BattleStance = RH.S(2457),
    DefensiveStance = RH.S(71),
    BerserkerStance = RH.S(2458),
    BattleShout = RH.Named("Battle Shout", 6673),
    Demoralizing = RH.Named("Demoralizing Shout", 1160),
    ShieldBash = RH.S(72),
    Revenge = RH.S(6572),
    ShieldBlock = RH.S(2565),
    ShieldWall = RH.S(871),
    Slam = RH.S(1464),
    Cleave = RH.S(845),
    Whirlwind = RH.S(1680),
    Sweeping = RH.S(12292),
    DeathWish = RH.S(12328),
    LastStand = RH.S(12975),
    Concussion = RH.S(12809),
    MortalStrike = RH.S(12294),
    Bloodthirst = RH.S(23881),
    ShieldSlam = RH.S(23922),
    Taunt = RH.Named("Taunt", 355),
    Mocking = RH.Named("Mocking Blow", 694),
    Challenging = RH.Named("Challenging Shout", 1161),
    Disarm = RH.S(676),
    Intimidating = RH.S(5246),
    Intercept = RH.S(20252),
    Retaliation = RH.S(20230),
    Victory = RH.Named("Victory Rush", 402927),
    Spearing = RH.Named("Spearing Strike", 1310222),
}
local function queueSwing(spell)
    local attack = RH.AttackOnce()
    if attack then
        return attack
    end
    for _, id in ipairs({ S.Heroic:ID(), S.Cleave:ID() }) do
        local ok, active = pcall(IsCurrentSpell, id)
        if ok and HeroLib.SafeBoolean(active, false) then
            return nil
        end
    end
    local now = GetTime()
    if HeroLib.State.nextSwingSuggestedAt and now - HeroLib.State.nextSwingSuggestedAt < 1.4 then
        return nil
    end
    HeroLib.State.nextSwingSuggestedAt = now
    return spell:Cast()
end
local function needsTaunt()
    local okExists, exists = pcall(UnitExists, "targettarget")
    if not okExists or HeroLib.Secret(exists) or not exists then
        return false
    end
    local okSelf, isSelf = pcall(UnitIsUnit, "targettarget", "player")
    if okSelf and not HeroLib.Secret(isSelf) and isSelf then
        return false
    end
    local okFriend, isFriend = pcall(UnitIsFriend, "player", "targettarget")
    return okFriend and not HeroLib.Secret(isFriend) and isFriend == true
end
RubimRH.Rotation.SetAPL(1, function()
    if P:IsDeadOrGhost() or P:IsCasting() or not RH.ValidTarget() then
        return nil
    end
    local db = RH.EnsureDB()
    local rage = RH.Power(1)
    local targetHP = T:HealthPercentage()
    local playerHP = P:HealthPercentage()
    local ttd = T:TimeToDie()
    local shield = RH.HasShield()
    local formOK, formValue = pcall(GetShapeshiftForm)
    local liveForm = formOK and HeroLib.SafeNumber(formValue, nil) or nil
    local tank = db.spec == "Protection" or liveForm == 2
    local fury = db.spec == "Fury" and not tank
    local arms = not tank and not fury
    local pvp = RH.IsPvPContext(db.warriorContext)
    if liveForm == 1 or liveForm == 2 or liveForm == 3 then
        RH.Rotation.stance = liveForm
    end
    if not RH.Rotation.stance then
        RH.Rotation.stance = tank and 2 or 1
    end
    local form = RH.Rotation.stance
    if RH.ShiftPending() then
        if HeroLib.State.shiftAction == "enter" and HeroLib.State.shiftSpell then
            return HeroLib.State.shiftSpell:Cast()
        end
        return nil
    end
    local function enough(cost)
        return rage == nil or rage >= cost
    end
    local creature = RH.SafeUnitText(UnitCreatureType, "target")
    local bleedable = creature ~= "Mechanical" and creature ~= "Elemental"
    local needRend = db.warriorRend ~= false
        and RH.AbilityEnabled("Rend")
        and S.Rend:IsAvailable()
        and not tank
        and (not fury or form == 1)
        and bleedable
        and (pvp or not targetHP or targetHP > 35)
        and (pvp or not ttd or ttd > 8)
        and T:Debuff("Rend") ~= true
    local sunderCap = tank and (tonumber(db.tankSunderStacks) or 5) or (tonumber(db.sunderStacks) or 2)

    -- Gryph-style opener and utility ordering, adapted to Forever's learned spellbook.
    if tank and form ~= 2 and S.DefensiveStance:IsAvailable() and S.DefensiveStance:IsReady() then
        RH.NoteShift("enter", S.DefensiveStance)
        return S.DefensiveStance:Cast()
    end
    if arms and form ~= 1 and S.BattleStance:IsAvailable() and S.BattleStance:IsReady() then
        RH.NoteShift("enter", S.BattleStance)
        return S.BattleStance:Cast()
    end
    if
        fury
        and (not P:AffectingCombat() or needRend or not S.BerserkerStance:IsAvailable())
        and form ~= 1
        and S.BattleStance:IsReady()
    then
        RH.NoteShift("enter", S.BattleStance)
        return S.BattleStance:Cast()
    end
    if not P:AffectingCombat() and RH.Ready(S.Charge, true) then
        return S.Charge:Cast()
    end
    if
        P:AffectingCombat()
        and fury
        and form == 3
        and RH.Ready(S.Intercept, true)
        and RH.UnitWithin("target", 10) == false
    then
        return S.Intercept:Cast()
    end
    if
        fury
        and P:AffectingCombat()
        and not needRend
        and S.BerserkerStance:IsAvailable()
        and form ~= 3
        and S.BerserkerStance:IsReady()
    then
        RH.NoteShift("enter", S.BerserkerStance)
        return S.BerserkerStance:Cast()
    end
    if RH.Interrupts and RH.ShouldInterrupt() and shield and RH.Ready(S.ShieldBash, true) then
        return S.ShieldBash:Cast()
    end
    if
        pvp
        and RH.Interrupts
        and RH.ShouldInterrupt()
        and T:Debuff("Concussion Blow") ~= true
        and RH.Ready(S.Concussion, true)
    then
        return S.Concussion:Cast()
    end
    if tank and db.warriorTaunt ~= false and needsTaunt() then
        if RH.Ready(S.Taunt, true) then
            return S.Taunt:Cast()
        end
        if RH.Ready(S.Mocking, true) then
            return S.Mocking:Cast()
        end
    end
    if
        tank
        and db.warriorTaunt ~= false
        and RH.AoE
        and needsTaunt()
        and RH.CountNearbyEnemies() >= 3
        and RH.Ready(S.Challenging)
    then
        return S.Challenging:Cast()
    end
    if fury and RH.CDs and P:Buff("Berserker Rage") ~= true and RH.Ready(S.BerserkerRage) then
        return S.BerserkerRage:Cast()
    end
    if RH.CDs and (rage == nil or rage < 20) and (not playerHP or playerHP > 40) and RH.Ready(S.Bloodrage) then
        return S.Bloodrage:Cast()
    end

    if db.defensives ~= false and db.warriorDefensives ~= false then
        if playerHP and playerHP < (tonumber(db.shieldWallHP) or 35) and shield and RH.Ready(S.ShieldWall) then
            return S.ShieldWall:Cast()
        end
        if playerHP and playerHP < 32 and RH.Ready(S.LastStand) then
            return S.LastStand:Cast()
        end
        if tank and playerHP and playerHP < 72 and shield and enough(10) and RH.Ready(S.ShieldBlock) then
            return S.ShieldBlock:Cast()
        end
    end
    if db.warriorVictory ~= false and (not playerHP or playerHP <= 65) and RH.Ready(S.Victory, true) then
        return S.Victory:Cast()
    end
    if targetHP and targetHP <= 20 and RH.Ready(S.Execute, true) then
        return S.Execute:Cast()
    end
    if pvp and T:Debuff("Hamstring") ~= true and enough(10) and RH.Ready(S.Hamstring, true) then
        return S.Hamstring:Cast()
    end
    if pvp and T:Debuff("Disarm") ~= true and RH.Ready(S.Disarm, true) then
        return S.Disarm:Cast()
    end
    if
        pvp
        and db.defensives ~= false
        and playerHP
        and playerHP < (tonumber(db.defensiveHP) or 30)
        and RH.Ready(S.Intimidating)
    then
        return S.Intimidating:Cast()
    end

    if
        RH.CDs
        and RH.AoE
        and enough(tonumber(db.sweepingRage) or 50)
        and (not ttd or ttd > 10)
        and RH.Ready(S.Sweeping)
    then
        return S.Sweeping:Cast()
    end
    -- Death Wish is a full offensive cooldown (bonus damage, extra damage taken) --
    -- hold it for Burst mode instead of firing the instant it's off cooldown.
    if RH.CDs and RH.Burst and (not playerHP or playerHP > 45) and (not ttd or ttd > 15) and RH.Ready(S.DeathWish) then
        return S.DeathWish:Cast()
    end
    if arms and RH.Ready(S.Overpower, true) then
        return S.Overpower:Cast()
    end

    if
        db.maintainBuffs ~= false
        and db.warriorShout ~= false
        and enough(10)
    then
        local shout = RH.CastIfMissing(S.BattleShout, { "Battle Shout", "Greater Battle Shout" }, 90)
        if shout then
            return shout
        end
    end
    if
        db.warriorShout ~= false
        and (tank or RH.AoE or pvp)
        and (pvp or not ttd or ttd > 10)
        and enough(10)
    then
        local demo = RH.CastIfDebuffMissing(S.Demoralizing, "Demoralizing Shout", 24)
        if demo then
            return demo
        end
    end
    if needRend then
        local rend = RH.CastIfDebuffMissing(S.Rend, "Rend", 15, true)
        if rend then
            return rend
        end
    end

    if tank then
        if RH.Ready(S.ShieldSlam, true) then
            return S.ShieldSlam:Cast()
        end
        if RH.Ready(S.Revenge, true) then
            return S.Revenge:Cast()
        end
        if RH.AoE and enough(20) then
            local clap = RH.CastIfDebuffMissing(S.Thunder, "Thunder Clap", 18, true)
            if clap then
                return clap
            end
        end
        if
            not pvp
            and db.warriorSunder ~= false
            and sunderCap > 0
            and enough(15)
            and (HeroLib.State.targetStacks["Sunder Armor"] or 0) < sunderCap
            and RH.Ready(S.Sunder, true)
        then
            return S.Sunder:Cast()
        end
        if RH.AoE and rage and enough(tonumber(db.cleaveRage) or 40) and RH.Ready(S.Cleave, true) then
            local nextSwing = queueSwing(S.Cleave)
            if nextSwing then
                return nextSwing
            end
        end
        if rage and enough(tonumber(db.heroicRage) or 60) and RH.Ready(S.Heroic, true) then
            local nextSwing = queueSwing(S.Heroic)
            if nextSwing then
                return nextSwing
            end
        end
        return RH.AttackOnce()
    end

    if fury and RH.Ready(S.Bloodthirst, true) then
        return S.Bloodthirst:Cast()
    end
    if arms and RH.Ready(S.MortalStrike, true) then
        return S.MortalStrike:Cast()
    end
    if fury and RH.AoE and RH.Ready(S.Whirlwind) then
        return S.Whirlwind:Cast()
    end
    if (creature == "Giant" or creature == "Dragonkin") and RH.Ready(S.Spearing, true) then
        return S.Spearing:Cast()
    end
    if RH.AoE and rage and enough(tonumber(db.cleaveRage) or 40) and RH.Ready(S.Cleave, true) then
        local nextSwing = queueSwing(S.Cleave)
        if nextSwing then
            return nextSwing
        end
    end
    if RH.AoE and enough(20) then
        local clap = RH.CastIfDebuffMissing(S.Thunder, "Thunder Clap", 18, true)
        if clap then
            return clap
        end
    end
    if
        arms
        and db.warriorSlam ~= false
        and enough(tonumber(db.slamRage) or 30)
        and (not ttd or ttd > 4)
        and RH.Ready(S.Slam, true)
    then
        return S.Slam:Cast()
    end
    if
        not pvp
        and db.warriorSunder ~= false
        and sunderCap > 0
        and enough(15)
        and (HeroLib.State.targetStacks["Sunder Armor"] or 0) < sunderCap
        and ttd
        and ttd > 15
        and RH.Ready(S.Sunder, true)
    then
        return S.Sunder:Cast()
    end
    if rage and rage >= (tonumber(db.heroicRage) or 60) and RH.Ready(S.Heroic, true) then
        local nextSwing = queueSwing(S.Heroic)
        if nextSwing then
            return nextSwing
        end
    end
    return RH.AttackOnce()
end)
