local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
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
    -- Baseline TBC Protection taunt, gained at level 20 -- stable Blizzard ID,
    -- not Forever-specific. Named lookup so it stays a no-op below that level
    -- or if untalented, instead of guessing it's always available.
    RighteousDefense = RH.Named("Righteous Defense", 31789),
}
-- Baseline Cleanse only cures Poison/Disease; Magic requires a talent this
-- rotation can't detect, so it's left out rather than risk a wasted cast.
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
    if
        holy
        and db.paladinGroupHeals ~= false
        and injured >= (tonumber(db.paladinGroupCount) or 3)
        and ally:Buff("Light's Vigil") ~= true
        and canSpend
        and RH.Ready(S.LightsVigil, unit)
    then
        return S.LightsVigil:Cast()
    end
    if db.paladinLayOnHands ~= false and RH.CDs and hp <= 15 and RH.Ready(S.LayOnHands, unit) then
        return S.LayOnHands:Cast()
    end
    if db.paladinHolyShock ~= false and hp <= math.max(bands.emergency + 8, flashHP) and RH.Ready(S.HolyShock, unit) then
        return S.HolyShock:Cast()
    end
    if hp <= flashHP and (hp <= bands.emergency or canSpend) and RH.Ready(S.Flash, unit) then
        return S.Flash:Cast()
    end
    if hp <= bands.emergency and RH.Ready(S.HolyLight, unit) then
        return S.HolyLight:Cast()
    end
    if bands.role ~= "healer" then
        RH.healTarget = nil
        return nil
    end
    if db.paladinDispel ~= false and RH.Ready(cleanse) then
        local dispelUnit = RH.FindDispelTarget(paladinDispels, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return cleanse:Cast()
        end
    end
    if hp <= holyLightHP and (hp <= bands.emergency or canSpend) and RH.Ready(S.HolyLight, unit) then
        return S.HolyLight:Cast()
    end
    RH.healTarget = nil
    return nil
end
RubimRH.Rotation.SetAPL(2, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec ~= "" and db.spec or "Retribution"
    local holy = spec == "Holy"
    local tank = spec == "Protection"
    local playerHP = P:HealthPercentage()
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local emergency = tonumber(db.emergencyHealHP) or 35
    local efficient = tonumber(db.efficientHealHP) or 70
    local shield = RH.HasShield()
    local pvp = RH.IsPvPContext(db.paladinContext)

    -- Healing works before hostile-target checks so Holy can serve parties and raids.
    if db.healing ~= false and db.paladinHealing ~= false then
        local heal = RecommendHealing(db, holy, mana, reserve, pvp)
        if heal then
            return heal
        end
    end
    RH.healTarget = nil

    if db.maintainBuffs ~= false and db.paladinBlessings ~= false then
        local blessing = holy and S.Wisdom:IsAvailable() and RH.AbilityEnabled("Blessing of Wisdom") and S.Wisdom
            or (S.Kings:IsAvailable() and RH.AbilityEnabled("Blessing of Kings") and S.Kings or S.Might)
        local blessingName = blessing:Name()
        if blessingName then
            local unit = RH.FindMissingBuff(blessingName)
            if unit then
                local cast = RH.CastAllyBuff(blessing, unit, blessingName, 300)
                if cast then
                    return cast
                end
            end
        end
    end
    if db.maintainBuffs ~= false and db.paladinAuras ~= false then
        local aura = holy
                and (S.Concentration:IsAvailable() and RH.AbilityEnabled("Concentration Aura") and S.Concentration or S.Devotion)
            or tank and S.Devotion
            or (S.Retribution:IsAvailable() and RH.AbilityEnabled("Retribution Aura") and S.Retribution or S.Devotion)
        local auraName = aura:Name()
        if auraName then
            local cast = RH.CastIfMissing(aura, auraName, 180)
            if cast then
                return cast
            end
        end
    end
    if db.maintainBuffs ~= false and tank then
        local fury = RH.CastIfMissing(S.RighteousFury, "Righteous Fury", 180)
        if fury then
            return fury
        end
    end
    if not RH.ValidTarget() then
        return nil
    end

    local targetHP = T:HealthPercentage()
    local ttd = T:TimeToDie()
    local creature = RH.SafeUnitText(UnitCreatureType, "target")
    local holyTarget = creature == "Undead" or creature == "Demon"
    if RH.Interrupts and RH.ShouldInterrupt() and RH.Ready(S.Hammer, true) then
        return S.Hammer:Cast()
    end
    if pvp and T:Debuff("Hammer of Justice") ~= true and RH.Ready(S.Hammer, true) then
        return S.Hammer:Cast()
    end
    if tank and db.paladinTaunt ~= false and RH.NeedsTaunt() and RH.Ready(S.RighteousDefense, true) then
        return S.RighteousDefense:Cast()
    end
    if db.paladinDefensives ~= false and db.defensives ~= false and playerHP then
        local defensiveAt = tonumber(db.defensiveHP) or 30
        if playerHP < math.max(10, defensiveAt - 15) and RH.Ready(S.DivineShield) then
            return S.DivineShield:Cast()
        end
        if playerHP < math.max(15, defensiveAt - 5) and RH.Ready(S.DivineProtection) then
            return S.DivineProtection:Cast()
        end
    end

    if db.paladinSeals ~= false then
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
        if sealName and missingAny(seals) and RH.Ready(seal) then
            RH.NoteBuff("player", sealName, 25)
            return seal:Cast()
        end
    end

    if tank then
        if shield then
            local hs = RH.CastIfMissing(S.HolyShield, "Holy Shield", 8)
            if hs then
                return hs
            end
        end
        if shield and RH.Ready(S.TemplarsBulwark, true) then
            return S.TemplarsBulwark:Cast()
        end
        if
            RH.AoE
            and RH.ResourceAbove(mana, tonumber(db.paladinConsecrationMana) or 45)
            and RH.Ready(S.Consecration)
        then
            return S.Consecration:Cast()
        end
        if RH.Ready(S.HolyStrike, true) then
            return S.HolyStrike:Cast()
        end
        if RH.Ready(S.Judgement, true) then
            return S.Judgement:Cast()
        end
    elseif holy then
        if holyTarget and RH.Ready(S.Exorcism, true) then
            return S.Exorcism:Cast()
        end
        if RH.Ready(S.HolyShock, true) then
            return S.HolyShock:Cast()
        end
        if
            RH.AoE
            and RH.ResourceAbove(mana, math.max(50, tonumber(db.paladinConsecrationMana) or 45))
            and RH.Ready(S.Consecration)
        then
            return S.Consecration:Cast()
        end
        if RH.Ready(S.Judgement, true) then
            return S.Judgement:Cast()
        end
        if RH.Ready(S.HolyStrike, true) then
            return S.HolyStrike:Cast()
        end
    else
        if RH.Ready(S.HolyStrike, true) then
            return S.HolyStrike:Cast()
        end
        if
            RH.AoE
            and RH.ResourceAbove(mana, tonumber(db.paladinConsecrationMana) or 45)
            and RH.Ready(S.Consecration)
        then
            return S.Consecration:Cast()
        end
        if holyTarget and (not ttd or ttd > 2) and RH.Ready(S.Exorcism, true) then
            return S.Exorcism:Cast()
        end
        if RH.Ready(S.Judgement, true) then
            return S.Judgement:Cast()
        end
    end
    return RH.AttackOnce()
end)
