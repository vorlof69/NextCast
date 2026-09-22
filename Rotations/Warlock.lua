local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    local hp = NC.HP()
    local targetHP = NC.HP("target")
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local armor = S.DemonArmor:IsAvailable() and RH.AbilityEnabled("Demon Armor") and S.DemonArmor or S.DemonSkin
    local armorName = armor:Name()
    local pet = HeroLib.Unit("pet")
    local summon = (spec == "Demonology" and S.SummonVoidwalker:IsAvailable()) and S.SummonVoidwalker or S.SummonImp

    return NC.Prio({
        function()
            if db.maintainBuffs ~= false and armorName then
                return NC.Missing(armor, armorName, 300)
            end
        end,
        {
            summon,
            when = function()
                return db.warlockPet ~= false
                    and not P:AffectingCombat()
                    and (not pet:Exists() or pet:IsDeadOrGhost())
            end,
        },
        function()
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        {
            S.Howl,
            when = function()
                return db.defensives ~= false
                    and pvp
                    and RH.UnitWithin("target", 10) == true
                    and hp
                    and hp < (tonumber(db.defensiveHP) or 30)
            end,
        },
        { S.Fear, range = true, when = function() return pvp and not NC.Debuff("Fear") end },
        function()
            if mana and mana < (tonumber(db.warlockLifeTapMana) or 25) then
                if hp and hp > 65 and NC.Ready(S.LifeTap) then
                    return NC.Go(S.LifeTap)
                end
                return RH.RangedFallback(S.Shoot)
            end
        end,
        function()
            if db.useDots ~= false and RH.ResourceAbove(mana, reserve) and RH.TargetWillLive(math.max(10, tonumber(db.dotMinTTD) or 8)) then
                return NC.Dot(S.Wrack, { "Wrack", "Bane of Agony", "Curse of Agony" }, 20, true)
                    or NC.Dot(S.Agony, { "Wrack", "Bane of Agony", "Curse of Agony" }, 20, true)
            end
        end,
        function()
            if db.useDots ~= false and RH.ResourceAbove(mana, reserve) and RH.TargetWillLive(math.max(9, tonumber(db.dotMinTTD) or 8)) then
                return NC.Dot(S.Corruption, "Corruption", 14, true)
            end
        end,
        function()
            if db.useDots ~= false and spec == "Affliction" and RH.ResourceAbove(mana, reserve) and RH.TargetWillLive(12) then
                return NC.Dot(S.Siphon, "Siphon Life", 24, true)
            end
        end,
        function()
            if db.useDots ~= false and spec == "Destruction" and RH.ResourceAbove(mana, reserve) and RH.TargetWillLive(8) then
                return NC.Dot(S.Immolate, "Immolate", 12, true)
            end
        end,
        { S.DrainSoul, range = true, when = function() return targetHP and targetHP < 15 end },
        function()
            if NC.AoE() and RH.ResourceAbove(mana, 40) then
                return NC.Dot(S.BaneHavoc, "Bane of Havoc", 20, true)
            end
        end,
        { S.Rain, range = true, when = function() return NC.AoE() and RH.ResourceAbove(mana, 40) end },
        {
            S.Drain,
            range = true,
            when = function()
                local need = pvp and math.max(tonumber(db.warlockDrainLifeHP) or 45, 52) or (tonumber(db.warlockDrainLifeHP) or 45)
                return db.healing ~= false and hp and hp < need
            end,
        },
        { S.Conflagrate, range = true, when = function() return spec == "Destruction" and NC.Debuff("Immolate") end },
        { S.Incinerate, range = true, when = function() return spec == "Destruction" end },
        function()
            if mana and mana < (tonumber(db.warlockLifeTapMana) or 25) then
                if hp and hp > 65 and NC.Ready(S.LifeTap) then
                    return NC.Go(S.LifeTap)
                end
                return RH.RangedFallback(S.Shoot)
            end
        end,
        function()
            if not RH.ResourceAbove(mana, reserve) then
                return RH.RangedFallback(S.Shoot)
            end
        end,
        { S.ShadowBolt, range = true },
        function()
            return RH.RangedFallback(S.Shoot)
        end,
    })
end)
