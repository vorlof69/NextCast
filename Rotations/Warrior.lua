local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    return NC.Go(spell)
end
RubimRH.Rotation.SetAPL(1, function()
    if P:IsDeadOrGhost() or P:IsCasting() or not RH.ValidTarget() then
        return nil
    end
    local db = RH.EnsureDB()
    local rage = RH.Power(1)
    local targetHP = NC.HP("target")
    local playerHP = NC.HP()
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
            return NC.Go(HeroLib.State.shiftSpell)
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
        and not NC.Debuff("Rend")
    local sunderCap = tank and (tonumber(db.tankSunderStacks) or 5) or (tonumber(db.sunderStacks) or 2)

    return NC.Prio({
        {
            S.DefensiveStance,
            when = function()
                return tank and form ~= 2 and S.DefensiveStance:IsAvailable() and S.DefensiveStance:IsReady()
            end,
            note = function()
                RH.NoteShift("enter", S.DefensiveStance)
            end,
        },
        {
            S.BattleStance,
            when = function()
                return arms and form ~= 1 and S.BattleStance:IsAvailable() and S.BattleStance:IsReady()
            end,
            note = function()
                RH.NoteShift("enter", S.BattleStance)
            end,
        },
        {
            S.BattleStance,
            when = function()
                return fury
                    and (not P:AffectingCombat() or needRend or not S.BerserkerStance:IsAvailable())
                    and form ~= 1
                    and S.BattleStance:IsReady()
            end,
            note = function()
                RH.NoteShift("enter", S.BattleStance)
            end,
        },
        { S.Charge, range = true, when = function() return not P:AffectingCombat() end },
        {
            S.Intercept,
            range = true,
            when = function()
                return P:AffectingCombat() and fury and form == 3 and RH.UnitWithin("target", 10) == false
            end,
        },
        {
            S.BerserkerStance,
            when = function()
                return fury
                    and P:AffectingCombat()
                    and not needRend
                    and S.BerserkerStance:IsAvailable()
                    and form ~= 3
                    and S.BerserkerStance:IsReady()
            end,
            note = function()
                RH.NoteShift("enter", S.BerserkerStance)
            end,
        },
        { S.ShieldBash, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() and shield end },
        {
            S.Concussion,
            range = true,
            when = function()
                return pvp and NC.Interrupts() and RH.ShouldInterrupt() and not NC.Debuff("Concussion Blow")
            end,
        },
        { S.Taunt, range = true, when = function() return tank and db.warriorTaunt ~= false and RH.NeedsTaunt() end },
        { S.Mocking, range = true, when = function() return tank and db.warriorTaunt ~= false and RH.NeedsTaunt() end },
        {
            S.Challenging,
            when = function()
                return tank and db.warriorTaunt ~= false and NC.AoE() and RH.NeedsTaunt() and NC.Enemies() >= 3
            end,
        },
        { S.BerserkerRage, when = function() return fury and NC.CDs() and not NC.Buff("Berserker Rage") end },
        {
            S.Bloodrage,
            when = function()
                return NC.CDs() and (rage == nil or rage < 20) and (not playerHP or playerHP > 40)
            end,
        },
        {
            S.ShieldWall,
            when = function()
                return db.defensives ~= false
                    and db.warriorDefensives ~= false
                    and playerHP
                    and playerHP < (tonumber(db.shieldWallHP) or 35)
                    and shield
            end,
        },
        {
            S.LastStand,
            when = function()
                return db.defensives ~= false and db.warriorDefensives ~= false and playerHP and playerHP < 32
            end,
        },
        {
            S.ShieldBlock,
            when = function()
                return db.defensives ~= false
                    and db.warriorDefensives ~= false
                    and tank
                    and playerHP
                    and playerHP < 72
                    and shield
                    and enough(10)
            end,
        },
        { S.Victory, range = true, when = function() return db.warriorVictory ~= false and (not playerHP or playerHP <= 65) end },
        { S.Execute, range = true, when = function() return targetHP and targetHP <= 20 end },
        { S.Hamstring, range = true, when = function() return pvp and not NC.Debuff("Hamstring") and enough(10) end },
        { S.Disarm, range = true, when = function() return pvp and not NC.Debuff("Disarm") end },
        {
            S.Intimidating,
            when = function()
                return pvp and db.defensives ~= false and playerHP and playerHP < (tonumber(db.defensiveHP) or 30)
            end,
        },
        {
            S.Sweeping,
            when = function()
                return NC.CDs() and NC.AoE() and enough(tonumber(db.sweepingRage) or 50) and (not ttd or ttd > 10)
            end,
        },
        {
            S.DeathWish,
            when = function()
                return NC.CDs() and RH.Burst and (not playerHP or playerHP > 45) and (not ttd or ttd > 15)
            end,
        },
        { S.Overpower, range = true, when = function() return arms end },
        function()
            if db.maintainBuffs ~= false and db.warriorShout ~= false and enough(10) then
                return NC.Missing(S.BattleShout, { "Battle Shout", "Greater Battle Shout" }, 90)
            end
        end,
        function()
            if db.warriorShout ~= false and (tank or NC.AoE() or pvp) and (pvp or not ttd or ttd > 10) and enough(10) then
                return NC.Dot(S.Demoralizing, "Demoralizing Shout", 24)
            end
        end,
        function()
            if needRend then
                return NC.Dot(S.Rend, "Rend", 15, true)
            end
        end,
        function()
            if not tank then
                return
            end
            return NC.Prio({
                { S.ShieldSlam, range = true },
                { S.Revenge, range = true },
                function()
                    if NC.AoE() and enough(20) then
                        return NC.Dot(S.Thunder, "Thunder Clap", 18, true)
                    end
                end,
                {
                    S.Sunder,
                    range = true,
                    when = function()
                        return not pvp
                            and db.warriorSunder ~= false
                            and sunderCap > 0
                            and enough(15)
                            and (HeroLib.State.targetStacks["Sunder Armor"] or 0) < sunderCap
                    end,
                },
                function()
                    if NC.AoE() and rage and enough(tonumber(db.cleaveRage) or 40) and NC.Ready(S.Cleave, true) then
                        return queueSwing(S.Cleave)
                    end
                end,
                function()
                    if rage and enough(tonumber(db.heroicRage) or 60) and NC.Ready(S.Heroic, true) then
                        return queueSwing(S.Heroic)
                    end
                end,
                function()
                    return RH.AttackOnce() or NC.STOP
                end,
            })
        end,
        { S.Bloodthirst, range = true, when = function() return fury end },
        { S.MortalStrike, range = true, when = function() return arms end },
        { S.Whirlwind, when = function() return fury and NC.AoE() end },
        { S.Spearing, range = true, when = function() return creature == "Giant" or creature == "Dragonkin" end },
        function()
            if NC.AoE() and rage and enough(tonumber(db.cleaveRage) or 40) and NC.Ready(S.Cleave, true) then
                return queueSwing(S.Cleave)
            end
        end,
        function()
            if NC.AoE() and enough(20) then
                return NC.Dot(S.Thunder, "Thunder Clap", 18, true)
            end
        end,
        {
            S.Slam,
            range = true,
            when = function()
                return arms and db.warriorSlam ~= false and enough(tonumber(db.slamRage) or 30) and (not ttd or ttd > 4)
            end,
        },
        {
            S.Sunder,
            range = true,
            when = function()
                return not pvp
                    and db.warriorSunder ~= false
                    and sunderCap > 0
                    and enough(15)
                    and (HeroLib.State.targetStacks["Sunder Armor"] or 0) < sunderCap
                    and ttd
                    and ttd > 15
            end,
        },
        function()
            if rage and rage >= (tonumber(db.heroicRage) or 60) and NC.Ready(S.Heroic, true) then
                return queueSwing(S.Heroic)
            end
        end,
        function()
            return RH.AttackOnce()
        end,
    })
end)
