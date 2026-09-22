local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
local S = {
    Attack = RH.S(6603),
    HolyLight = RH.Named("Holy Light", 635),
    Flash = RH.Named("Flash of Light", 19750),
    Judgement = RH.S(20271),
    SoR = RH.S(21084),
    Consecration = RH.S(26573),
    Hammer = RH.S(853),
    Exorcism = RH.S(879),
    Might = RH.Named("Blessing of Might", 19740),
    Kings = RH.Named("Blessing of Kings", 20217),
    Wisdom = RH.Named("Blessing of Wisdom", 19742),
    Devotion = RH.S(465),
    Retribution = RH.S(7294),
    Concentration = RH.S(19746),
    RighteousFury = RH.S(25780),
    DivineProtection = RH.S(498),
    DivineShield = RH.S(642),
    LayOnHands = RH.Named("Lay on Hands", 633),
    HolyShock = RH.Named("Holy Shock", 20473),
    HolyShield = RH.S(20925),
    SealCommand = RH.Named("Seal of Command", 20375),
    SealFury = RH.Named("Seal of Fury"),
    SealWisdom = RH.Named("Seal of Wisdom", 20166),
    SealLight = RH.Named("Seal of Light", 20165),
    HolyStrike = RH.Named("Holy Strike"),
    LightsVigil = RH.Named("Light's Vigil"),
    VoiceTruth = RH.Named("Voice of Truth"),
    TemplarsBulwark = RH.Named("Templar's Bulwark"),
    Cleanse = RH.Named("Cleanse"),
    Purify = RH.Named("Purify", 1152),
    RighteousDefense = RH.Named("Righteous Defense", 31789),
}
local paladinDispels = { Poison = true, Disease = true }
local function missingAny(names)
    for _, name in ipairs(names) do
        if RH.RecentlyBuffed("player", name) then
            return false
        end
        if P:Buff(name) ~= false then
            return false
        end
    end
    return true
end
local function RecommendHealing(db, holy, mana, reserve, pvp)
    local bands = RH.HealBands(pvp)
    local entries = RH.FriendlySnapshot(1.25)
    local unit, hp = RH.PickHealTarget(entries, pvp)
    unit = unit or "player"
    hp = hp or 100
    local ally = HeroLib.Unit(unit)
    RH.healTarget = unit
    local flashHP = holy and (tonumber(db.paladinFlashHP) or 55) or bands.emergency
    local holyLightHP = holy and (tonumber(db.paladinHolyLightHP) or 80) or bands.efficient
    local groupHP = tonumber(db.paladinGroupHP) or 75
    local injured = RH.CountInjuredFriendlies(entries, groupHP)
    local canSpend = RH.ResourceAbove(mana, reserve)
    local cleanse = S.Cleanse:IsAvailable() and S.Cleanse or S.Purify
    return NC.Prio({
        {
            S.LightsVigil,
            range = unit,
            when = function()
                return holy
                    and db.paladinGroupHeals ~= false
                    and injured >= (tonumber(db.paladinGroupCount) or 3)
                    and not NC.Buff("Light's Vigil", unit)
                    and canSpend
            end,
        },
        {
            S.LayOnHands,
            range = unit,
            when = function()
                return db.paladinLayOnHands ~= false and NC.CDs() and hp <= 15
            end,
        },
        {
            S.HolyShock,
            range = unit,
            when = function()
                return db.paladinHolyShock ~= false and hp <= math.max(bands.emergency + 8, flashHP)
            end,
        },
        { S.Flash, range = unit, when = function() return hp <= flashHP and (hp <= bands.emergency or canSpend) end },
        { S.HolyLight, range = unit, when = function() return hp <= bands.emergency end },
        function()
            if bands.role ~= "healer" then
                RH.healTarget = nil
                return NC.STOP
            end
        end,
        function()
            if db.paladinDispel ~= false and NC.Ready(cleanse) then
                local dispelUnit = RH.FindDispelTarget(paladinDispels, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(cleanse)
                end
            end
        end,
        { S.HolyLight, range = unit, when = function() return hp <= holyLightHP and (hp <= bands.emergency or canSpend) end },
        function()
            RH.healTarget = nil
        end,
    })
end
RubimRH.Rotation.SetAPL(2, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec ~= "" and db.spec or "Retribution"
    local holy = spec == "Holy"
    local tank = spec == "Protection"
    local playerHP = NC.HP()
    local mana = NC.Mana()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local shield = RH.HasShield()
    local pvp = RH.IsPvPContext(db.paladinContext)
    local targetHP = NC.HP("target")
    local ttd = T:TimeToDie()
    local creature = RH.SafeUnitText(UnitCreatureType, "target")
    local holyTarget = creature == "Undead" or creature == "Demon"

    return NC.Prio({
        function()
            if db.healing ~= false and db.paladinHealing ~= false then
                return RecommendHealing(db, holy, mana, reserve, pvp)
            end
        end,
        function()
            RH.healTarget = nil
        end,
        function()
            if db.maintainBuffs == false or db.paladinBlessings == false then
                return
            end
            local blessing = holy and S.Wisdom:IsAvailable() and RH.AbilityEnabled("Blessing of Wisdom") and S.Wisdom
                or (S.Kings:IsAvailable() and RH.AbilityEnabled("Blessing of Kings") and S.Kings or S.Might)
            local blessingName = blessing:Name()
            if blessingName then
                local unit = RH.FindMissingBuff(blessingName)
                if unit then
                    return RH.CastAllyBuff(blessing, unit, blessingName, 300)
                end
            end
        end,
        function()
            if db.maintainBuffs == false or db.paladinAuras == false then
                return
            end
            local aura = holy
                    and (S.Concentration:IsAvailable() and RH.AbilityEnabled("Concentration Aura") and S.Concentration or S.Devotion)
                or tank and S.Devotion
                or (S.Retribution:IsAvailable() and RH.AbilityEnabled("Retribution Aura") and S.Retribution or S.Devotion)
            local auraName = aura:Name()
            if auraName then
                return NC.Missing(aura, auraName, 180)
            end
        end,
        function()
            if db.maintainBuffs ~= false and tank then
                return NC.Missing(S.RighteousFury, "Righteous Fury", 180)
            end
        end,
        function()
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        { S.Hammer, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        { S.Hammer, range = true, when = function() return pvp and not NC.Debuff("Hammer of Justice") end },
        {
            S.RighteousDefense,
            range = true,
            when = function()
                return tank and db.paladinTaunt ~= false and RH.NeedsTaunt()
            end,
        },
        {
            S.DivineShield,
            when = function()
                local defensiveAt = tonumber(db.defensiveHP) or 30
                return db.paladinDefensives ~= false
                    and db.defensives ~= false
                    and playerHP
                    and playerHP < math.max(10, defensiveAt - 15)
            end,
        },
        {
            S.DivineProtection,
            when = function()
                local defensiveAt = tonumber(db.defensiveHP) or 30
                return db.paladinDefensives ~= false
                    and db.defensives ~= false
                    and playerHP
                    and playerHP < math.max(15, defensiveAt - 5)
            end,
        },
        function()
            if db.paladinSeals == false then
                return
            end
            local seal
            if tank and S.SealFury:IsAvailable() and RH.AbilityEnabled("Seal of Fury") then
                seal = S.SealFury
            elseif holy and S.SealWisdom:IsAvailable() and RH.AbilityEnabled("Seal of Wisdom") then
                seal = S.SealWisdom
            else
                local speed = RH.MainHandSpeed()
                seal = (S.SealCommand:IsAvailable() and RH.AbilityEnabled("Seal of Command") and speed and speed >= 3.8)
                        and S.SealCommand
                    or S.SoR
            end
            local sealName = seal:Name()
            local seals = { "Seal of Righteousness", "Seal of Command", "Seal of Fury", "Seal of Wisdom", "Seal of Light" }
            if sealName and missingAny(seals) and NC.Ready(seal) then
                RH.NoteBuff("player", sealName, 25)
                return NC.Go(seal)
            end
        end,
        function()
            if not tank then
                return
            end
            return NC.Prio({
                function()
                    if shield then
                        return NC.Missing(S.HolyShield, "Holy Shield", 8)
                    end
                end,
                { S.TemplarsBulwark, range = true, when = function() return shield end },
                {
                    S.Consecration,
                    when = function()
                        return NC.AoE() and RH.ResourceAbove(mana, tonumber(db.paladinConsecrationMana) or 45)
                    end,
                },
                { S.HolyStrike, range = true },
                { S.Judgement, range = true },
            })
        end,
        function()
            if not holy then
                return
            end
            return NC.Prio({
                { S.Exorcism, range = true, when = function() return holyTarget end },
                { S.HolyShock, range = true },
                {
                    S.Consecration,
                    when = function()
                        return NC.AoE() and RH.ResourceAbove(mana, math.max(50, tonumber(db.paladinConsecrationMana) or 45))
                    end,
                },
                { S.Judgement, range = true },
                { S.HolyStrike, range = true },
            })
        end,
        { S.HolyStrike, range = true },
        {
            S.Consecration,
            when = function()
                return NC.AoE() and RH.ResourceAbove(mana, tonumber(db.paladinConsecrationMana) or 45)
            end,
        },
        { S.Exorcism, range = true, when = function() return holyTarget and (not ttd or ttd > 2) end },
        { S.Judgement, range = true },
        function()
            return RH.AttackOnce()
        end,
    })
end)
