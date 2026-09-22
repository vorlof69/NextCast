local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    Shield = RH.Named("Power Word: Shield", 17),
    Renew = RH.Named("Renew", 139),
    LesserHeal = RH.Named("Lesser Heal", 2050),
    Heal = RH.Named("Heal", 2054),
    GreaterHeal = RH.Named("Greater Heal", 2060),
    Flash = RH.Named("Flash Heal", 2061),
    PrayerHealing = RH.Named("Prayer of Healing", 596),
    Pain = RH.S(589),
    MindBlast = RH.S(8092),
    MindFlay = RH.S(15407),
    Smite = RH.S(585),
    HolyFire = RH.S(14914),
    PsychicScream = RH.S(8122),
    Fortitude = RH.Named("Power Word: Fortitude", 1243),
    InnerFire = RH.Named("Inner Fire", 588),
    Shoot = RH.S(5019),
    Penance = RH.Named("Penance"),
    PrayerMending = RH.Named("Prayer of Mending"),
    BindingHeal = RH.Named("Binding Heal"),
    DispelMagic = RH.Named("Dispel Magic"),
    AbolishDisease = RH.Named("Abolish Disease"),
    CureDisease = RH.Named("Cure Disease"),
    Desperate = RH.Named("Desperate Prayer", 13908),
    HolyNova = RH.Named("Holy Nova", 15237),
}
local priestDispels = { Magic = true }
local function RecommendHealing(db, spec, mana, reserve, pvp)
    local bands = RH.HealBands(pvp)
    local entries = RH.FriendlySnapshot(1.25)
    local unit, hp = RH.PickHealTarget(entries, pvp)
    unit = unit or "player"
    hp = hp or 100
    local ally = HeroLib.Unit(unit)
    RH.healTarget = unit
    local canSpend = RH.ResourceAbove(mana, reserve)
    local playerHP = P:HealthPercentage() or 100
    local healer = bands.role == "healer"
    local groupHP = tonumber(db.priestGroupHP) or bands.group or 75
    local injured = RH.CountInjuredFriendlies(entries, groupHP, { "Prayer of Healing", S.PrayerHealing:ID() })
    local groupCount = tonumber(db.priestGroupCount) or 3
    local direct = S.GreaterHeal:IsAvailable() and S.GreaterHeal or (S.Heal:IsAvailable() and S.Heal or S.LesserHeal)
    local shieldHP = healer and (tonumber(db.priestShieldHP) or bands.shield) or bands.shield
    local flashHP = healer and (tonumber(db.priestFlashHP) or 50) or bands.emergency
    local renewHP = healer and (tonumber(db.priestRenewHP) or bands.hot) or nil

    if playerHP <= bands.emergency and RH.Ready(S.Desperate) then
        RH.healTarget = "player"
        return S.Desperate:Cast()
    end
    if
        db.priestEmergencyHeals ~= false
        and hp <= (healer and (tonumber(db.priestPenanceHP) or 40) or bands.emergency)
        and RH.Ready(S.Penance, unit)
    then
        return S.Penance:Cast()
    end
    if db.priestEmergencyHeals ~= false and hp <= flashHP and RH.Ready(S.Flash, unit) then
        return S.Flash:Cast()
    end
    if hp <= bands.emergency and RH.Ready(direct, unit) then
        return direct:Cast()
    end
    if
        hp < shieldHP
        and ally:Buff("Power Word: Shield") ~= true
        and ally:Debuff("Weakened Soul") ~= true
        and RH.Ready(S.Shield, unit)
    then
        return S.Shield:Cast()
    end
    if not healer then
        RH.healTarget = nil
        return nil
    end
    if spec == "Holy" and playerHP < 80 and hp < 65 and RH.Ready(S.BindingHeal, unit) then
        return S.BindingHeal:Cast()
    end
    if db.priestDispel ~= false and RH.Ready(S.DispelMagic) then
        local dispelUnit = RH.FindDispelTarget(priestDispels, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.DispelMagic:Cast()
        end
    end
    if db.priestDispel ~= false then
        local disease = S.AbolishDisease:IsAvailable() and S.AbolishDisease or S.CureDisease
        if RH.Ready(disease) then
            local dispelUnit = RH.FindDispelTarget({ Disease = true }, entries)
            if dispelUnit then
                RH.healTarget = dispelUnit
                return disease:Cast()
            end
        end
    end
    if
        db.priestGroupHeals ~= false
        and injured >= 2
        and RH.UnitWithin("target", 10) ~= false
        and canSpend
        and RH.Ready(S.HolyNova)
    then
        RH.healTarget = "group"
        return S.HolyNova:Cast()
    end
    if
        db.priestGroupHeals ~= false
        and injured >= groupCount
        and hp <= groupHP
        and canSpend
        and RH.Ready(S.PrayerHealing)
    then
        RH.healTarget = "group"
        return S.PrayerHealing:Cast()
    end
    if
        db.priestHoTs ~= false
        and hp < (tonumber(db.priestRenewHP) or 88)
        and ally:Buff("Prayer of Mending") ~= true
        and canSpend
        and RH.Ready(S.PrayerMending, unit)
    then
        return S.PrayerMending:Cast()
    end
    if hp < bands.efficient and (hp < bands.emergency or canSpend) and RH.Ready(direct, unit) then
        return direct:Cast()
    end
    if
        renewHP
        and db.priestHoTs ~= false
        and hp < renewHP
        and ally:Buff("Renew") ~= true
        and canSpend
        and RH.Ready(S.Renew, unit)
    then
        return S.Renew:Cast()
    end
    RH.healTarget = nil
    return nil
end
RubimRH.Rotation.SetAPL(5, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Shadow"
    local healer = spec == "Discipline" or spec == "Holy"
    local pvp = RH.IsPvPContext(db.priestContext)
    local mana = RH.PowerPercent(0)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local emergency = tonumber(db.emergencyHealHP) or 35
    local efficient = tonumber(db.efficientHealHP) or 70
    if db.maintainBuffs ~= false then
        local inner = RH.CastIfMissing(S.InnerFire, "Inner Fire", 180)
        if inner then
            return inner
        end
        local fort = RH.FindMissingBuff("Power Word: Fortitude")
        if fort then
            local cast = RH.CastAllyBuff(S.Fortitude, fort, "Power Word: Fortitude", 300)
            if cast then
                return cast
            end
        end
    end
    if db.healing ~= false then
        local heal = RecommendHealing(db, spec, mana, reserve, pvp)
        if heal then
            return heal
        end
    end
    RH.healTarget = nil
    if not RH.ValidTarget() then
        return nil
    end
    if
        db.defensives ~= false
        and pvp
        and P:HealthPercentage()
        and P:HealthPercentage() < (tonumber(db.defensiveHP) or 30)
        and RH.UnitWithin("target", 10) == true
        and RH.Ready(S.PsychicScream)
    then
        return S.PsychicScream:Cast()
    end
    if
        db.useDots ~= false
        and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8)
        and RH.ResourceAbove(mana, reserve)
    then
        local pain = RH.CastIfDebuffMissing(S.Pain, "Shadow Word: Pain", 14, true)
        if pain then
            return pain
        end
    end
    if not RH.ResourceAbove(mana, reserve) then
        return RH.RangedFallback(S.Shoot)
    end
    if spec == "Shadow" then
        if RH.Ready(S.MindBlast, true) then
            return S.MindBlast:Cast()
        end
        if RH.Ready(S.MindFlay, true) then
            return S.MindFlay:Cast()
        end
    else
        if RH.Ready(S.HolyFire, true) then
            return S.HolyFire:Cast()
        end
        if RH.Ready(S.Smite, true) then
            return S.Smite:Cast()
        end
    end
    if RH.Ready(S.Smite, true) then
        return S.Smite:Cast()
    end
    return RH.RangedFallback(S.Shoot)
end)
