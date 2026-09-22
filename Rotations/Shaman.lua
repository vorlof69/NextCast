local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Heal = RH.Named("Healing Wave", 331),
    Lesser = RH.Named("Lesser Healing Wave", 8004),
    ChainHeal = RH.Named("Chain Heal", 1064),
    HealingStream = RH.Named("Healing Stream Totem", 5394),
    NaturesSwiftness = RH.Named("Nature's Swiftness", 16188),
    ManaTide = RH.Named("Mana Tide Totem", 16190),
    Lightning = RH.S(403),
    Chain = RH.S(421),
    Flame = RH.S(8050),
    Earth = RH.S(8042),
    Frost = RH.S(8056),
    LightningShield = RH.S(324),
    Rockbiter = RH.S(8017),
    Flametongue = RH.S(8024),
    Windfury = RH.S(8232),
    Stormstrike = RH.S(17364),
    Searing = RH.S(3599),
    Magma = RH.S(8190),
    FireNova = RH.Named("Fire Nova"),
    LavaBurst = RH.Named("Lava Burst"),
    WaterShield = RH.Named("Water Shield"),
    Riptide = RH.Named("Riptide"),
    Purge = RH.Named("Purge", 370),
    Grounding = RH.Named("Grounding Totem", 8177),
    CurePoison = RH.Named("Cure Poison"),
    CureDisease = RH.Named("Cure Disease"),
}
local function RecommendRestoration(db, mana, reserve, pvp)
    local bands = RH.HealBands(pvp)
    local entries = RH.FriendlySnapshot(1.25)
    local unit, hp = RH.PickHealTarget(entries, pvp)
    unit = unit or "player"
    hp = hp or 100
    local ally = HeroLib.Unit(unit)
    RH.healTarget = unit
    local canSpend = RH.ResourceAbove(mana, reserve)
    local chainHP = tonumber(db.shamanChainHP) or 75
    local injured = RH.CountInjuredFriendlies(entries, chainHP, { "Chain Heal", S.ChainHeal:ID() })
    local chainCount = tonumber(db.shamanChainCount) or 3
    local healer = bands.role == "healer"
    if RH.CDs and healer and mana and mana <= (tonumber(db.shamanManaTideMana) or 20) and RH.Ready(S.ManaTide) then
        RH.healTarget = "group"
        return S.ManaTide:Cast()
    end
    if
        db.shamanEmergencyHeals ~= false
        and hp <= bands.emergency
        and P:Buff("Nature's Swiftness") ~= true
        and RH.Ready(S.NaturesSwiftness)
    then
        return S.NaturesSwiftness:Cast()
    end
    if
        db.shamanEmergencyHeals ~= false
        and hp <= bands.emergency
        and P:Buff("Nature's Swiftness") == true
        and RH.Ready(S.Heal, unit)
    then
        return S.Heal:Cast()
    end
    if db.shamanEmergencyHeals ~= false and hp <= bands.emergency and RH.Ready(S.Lesser, unit) then
        return S.Lesser:Cast()
    end
    if hp <= bands.emergency and RH.Ready(S.Heal, unit) then
        return S.Heal:Cast()
    end
    if not healer then
        RH.healTarget = nil
        return nil
    end
    if db.shamanDispel ~= false and RH.Ready(S.CurePoison) then
        local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.CurePoison:Cast()
        end
    end
    if db.shamanDispel ~= false and RH.Ready(S.CureDisease) then
        local dispelUnit = RH.FindDispelTarget({ Disease = true }, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.CureDisease:Cast()
        end
    end
    if
        db.shamanHoTs ~= false
        and hp <= (tonumber(db.shamanRiptideHP) or bands.hot or 85)
        and ally:Buff("Riptide") ~= true
        and (hp <= bands.emergency or canSpend)
        and RH.Ready(S.Riptide, unit)
    then
        return S.Riptide:Cast()
    end
    if
        db.shamanGroupHeals ~= false
        and injured >= chainCount
        and hp <= chainHP
        and canSpend
        and RH.Ready(S.ChainHeal, unit)
    then
        return S.ChainHeal:Cast()
    end
    if
        db.shamanGroupHeals ~= false
        and injured >= 2
        and RH.TotemActive(3, "Healing Stream Totem") == false
        and canSpend
        and RH.Ready(S.HealingStream)
    then
        RH.healTarget = "group"
        return S.HealingStream:Cast()
    end
    if db.shamanEmergencyHeals ~= false and hp <= bands.emergency + 10 and RH.Ready(S.Lesser, unit) then
        return S.Lesser:Cast()
    end
    if hp <= bands.efficient and (hp <= bands.emergency or canSpend) and RH.Ready(S.Heal, unit) then
        return S.Heal:Cast()
    end
    RH.healTarget = nil
    return nil
end
RubimRH.Rotation.SetAPL(7, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Enhancement"
    local healer = spec == "Restoration"
    local pvp = RH.IsPvPContext(db.shamanContext)
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local emergency = tonumber(db.emergencyHealHP) or 35
    local efficient = tonumber(db.efficientHealHP) or 70
    local shield = healer and S.WaterShield:IsAvailable() and S.WaterShield or S.LightningShield
    local shieldName = shield:Name()
    if not P:AffectingCombat() and db.maintainBuffs ~= false and shieldName then
        local cast = RH.CastIfMissing(shield, shieldName, 180)
        if cast then
            return cast
        end
    end
    if
        not P:AffectingCombat()
        and db.maintainBuffs ~= false
        and RH.MainHandEnchanted() == false
        and not RH.RecentlyBuffed("player", "Weapon Imbue")
    then
        local imbue = spec == "Enhancement" and (S.Windfury:IsAvailable() and S.Windfury or S.Rockbiter)
            or (S.Flametongue:IsAvailable() and S.Flametongue or S.Rockbiter)
        if RH.Ready(imbue) then
            RH.NoteBuff("player", "Weapon Imbue", 180)
            HeroLib.State.weaponEnchantUntil = GetTime() + 180
            return imbue:Cast()
        end
    end
    if db.healing ~= false then
        local heal = RecommendRestoration(db, mana, reserve, pvp)
        if heal then
            return heal
        end
    end
    RH.healTarget = nil
    if not RH.ValidTarget() then
        return nil
    end
    local melee = RH.UnitWithin("target", 10)
    local ttd = T:TimeToDie()
    local fireTotem = RH.TotemActive(1)
    if RH.Interrupts and RH.ShouldInterrupt() and RH.Ready(S.Earth, true) then
        return S.Earth:Cast()
    end
    if pvp and db.defensives ~= false and RH.ShouldInterrupt() and RH.Ready(S.Grounding) then
        return S.Grounding:Cast()
    end
    if pvp and RH.Burst and RH.Ready(S.Purge, true) then
        return S.Purge:Cast()
    end
    if pvp and T:Debuff("Frost Shock") ~= true and RH.Ready(S.Frost, true) then
        return S.Frost:Cast()
    end
    if
        db.useDots ~= false
        and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8)
        and RH.ResourceAbove(mana, reserve)
    then
        local flame = RH.CastIfDebuffMissing(S.Flame, "Flame Shock", 10, true)
        if flame then
            return flame
        end
    end
    if RH.AoE then
        local aoeMana = tonumber(db.shamanAoEMana) or 35
        if
            db.shamanTotems ~= false
            and RH.ResourceAbove(mana, tonumber(db.shamanTotemMana) or 40)
            and RH.TotemActive(1, "Magma Totem") == false
            and RH.Ready(S.Magma)
        then
            return S.Magma:Cast()
        end
        if fireTotem == true and RH.ResourceAbove(mana, aoeMana) and RH.Ready(S.FireNova) then
            return S.FireNova:Cast()
        end
        if RH.ResourceAbove(mana, aoeMana) and RH.Ready(S.Chain, true) then
            return S.Chain:Cast()
        end
    elseif
        db.shamanTotems ~= false
        and fireTotem == false
        and RH.TargetWillLive(10)
        and RH.ResourceAbove(mana, tonumber(db.shamanTotemMana) or 40)
        and RH.Ready(S.Searing)
    then
        return S.Searing:Cast()
    end
    if spec == "Enhancement" and RH.Ready(S.Stormstrike, true) then
        return S.Stormstrike:Cast()
    end
    if
        RH.ResourceAbove(mana, reserve)
        and (spec == "Elemental" or P:Buff("Maelstrom Weapon") == true)
        and RH.Ready(S.LavaBurst, true)
    then
        return S.LavaBurst:Cast()
    end
    if
        RH.ResourceAbove(mana, reserve)
        and (spec ~= "Enhancement" or melee ~= true or P:Buff("Maelstrom Weapon") == true)
        and RH.Ready(S.Lightning, true)
    then
        return S.Lightning:Cast()
    end
    return RH.AttackOnce()
end)
