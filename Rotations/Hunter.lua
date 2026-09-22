local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    local playerHP = NC.HP()
    local needsMonkey = db.defensives ~= false
        and playerHP
        and playerHP < (tonumber(db.defensiveHP) or 30)
        and RH.UnitWithin("target", 10) == true
    local aspect = (needsMonkey or not S.Hawk:IsAvailable()) and S.Monkey or S.Hawk
    if not RH.AbilityEnabled(aspect:Name()) then
        aspect = aspect == S.Monkey and S.Hawk or S.Monkey
    end
    local aspectName = aspect:Name()
    local melee = S.Raptor:IsInRange()

    return NC.Prio({
        {
            S.RevivePet,
            when = function()
                return db.hunterPet ~= false and not P:AffectingCombat() and pet:IsDeadOrGhost()
            end,
        },
        {
            S.CallPet,
            when = function()
                return db.hunterPet ~= false and not P:AffectingCombat() and not pet:Exists()
            end,
        },
        {
            S.Mend,
            range = "pet",
            when = function()
                local need = pvp and math.max(tonumber(db.hunterPetHealHP) or 65, 70) or (tonumber(db.hunterPetHealHP) or 65)
                return db.hunterPet ~= false
                    and db.healing ~= false
                    and petHP
                    and petHP < need
                    and not NC.Buff("Mend Pet", "pet")
            end,
            note = function()
                RH.healTarget = "pet"
            end,
        },
        function()
            if db.maintainBuffs ~= false and aspectName then
                return NC.Missing(aspect, aspectName, 180)
            end
        end,
        function()
            RH.healTarget = nil
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        {
            S.Feign,
            when = function()
                return db.defensives ~= false
                    and P:AffectingCombat()
                    and playerHP
                    and playerHP <= (tonumber(db.defensiveHP) or 30)
            end,
        },
        { S.Scatter, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        { S.Intimidation, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        { S.Wing, range = true, when = function() return pvp and melee and not NC.Debuff("Wing Clip") end },
        {
            S.Concussive,
            range = true,
            when = function()
                return pvp and db.hunterConcussive ~= false and not NC.Debuff("Concussive Shot")
            end,
        },
        function()
            if db.maintainBuffs ~= false and RH.TargetWillLive(10) then
                return NC.Dot(S.Mark, "Hunter's Mark", 90, true)
            end
        end,
        function()
            if db.useDots ~= false and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8) and RH.ResourceAbove(mana, reserve) then
                return NC.Dot(S.Serpent, "Serpent Sting", 12, true)
            end
        end,
        { S.Rapid, when = function() return NC.CDs() and RH.Burst end },
        { S.ExplosiveTrap, when = function() return NC.AoE() and melee end },
        {
            S.Multi,
            range = true,
            when = function()
                return NC.AoE() and RH.ResourceAbove(mana, math.max(tonumber(db.hunterMultiMana) or 35, reserve))
            end,
        },
        {
            S.Aimed,
            range = true,
            when = function()
                return spec == "Marksmanship" and RH.ResourceAbove(mana, math.max(30, reserve))
            end,
        },
        { S.Mongoose, range = true, when = function() return melee end },
        { S.Raptor, range = true, when = function() return melee end },
        {
            S.Arcane,
            range = true,
            when = function()
                return RH.ResourceAbove(mana, math.max(tonumber(db.hunterArcaneMana) or 25, reserve))
            end,
        },
        function()
            if S.Auto:IsAvailable() and not melee then
                return RH.AutoShotOnce(S.Auto)
            end
        end,
        function()
            if melee then
                return RH.AttackOnce()
            end
        end,
    })
end)
