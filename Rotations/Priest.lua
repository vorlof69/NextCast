local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    local playerHP = NC.HP() or 100
    local healer = bands.role == "healer"
    local groupHP = tonumber(db.priestGroupHP) or bands.group or 75
    local injured = RH.CountInjuredFriendlies(entries, groupHP, { "Prayer of Healing", S.PrayerHealing:ID() })
    local groupCount = tonumber(db.priestGroupCount) or 3
    local direct = S.GreaterHeal:IsAvailable() and S.GreaterHeal or (S.Heal:IsAvailable() and S.Heal or S.LesserHeal)
    local shieldHP = healer and (tonumber(db.priestShieldHP) or bands.shield) or bands.shield
    local flashHP = healer and (tonumber(db.priestFlashHP) or 50) or bands.emergency
    local renewHP = healer and (tonumber(db.priestRenewHP) or bands.hot) or nil
    local disease = S.AbolishDisease:IsAvailable() and S.AbolishDisease or S.CureDisease
    return NC.Prio({
        {
            S.Desperate,
            when = function()
                return playerHP <= bands.emergency
            end,
            note = function()
                RH.healTarget = "player"
            end,
        },
        {
            S.Penance,
            range = unit,
            when = function()
                return db.priestEmergencyHeals ~= false
                    and hp <= (healer and (tonumber(db.priestPenanceHP) or 40) or bands.emergency)
            end,
        },
        { S.Flash, range = unit, when = function() return db.priestEmergencyHeals ~= false and hp <= flashHP end },
        { direct, range = unit, when = function() return hp <= bands.emergency end },
        {
            S.Shield,
            range = unit,
            when = function()
                return hp < shieldHP and not NC.Buff("Power Word: Shield", unit) and not NC.Debuff("Weakened Soul", unit)
            end,
        },
        function()
            if not healer then
                RH.healTarget = nil
                return NC.STOP
            end
        end,
        { S.BindingHeal, range = unit, when = function() return spec == "Holy" and playerHP < 80 and hp < 65 end },
        function()
            if db.priestDispel ~= false and NC.Ready(S.DispelMagic) then
                local dispelUnit = RH.FindDispelTarget(priestDispels, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.DispelMagic)
                end
            end
        end,
        function()
            if db.priestDispel ~= false and NC.Ready(disease) then
                local dispelUnit = RH.FindDispelTarget({ Disease = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(disease)
                end
            end
        end,
        {
            S.HolyNova,
            when = function()
                return db.priestGroupHeals ~= false
                    and injured >= 2
                    and RH.UnitWithin("target", 10) ~= false
                    and canSpend
            end,
            note = function()
                RH.healTarget = "group"
            end,
        },
        {
            S.PrayerHealing,
            when = function()
                return db.priestGroupHeals ~= false and injured >= groupCount and hp <= groupHP and canSpend
            end,
            note = function()
                RH.healTarget = "group"
            end,
        },
        {
            S.PrayerMending,
            range = unit,
            when = function()
                return db.priestHoTs ~= false
                    and hp < (tonumber(db.priestRenewHP) or 88)
                    and not NC.Buff("Prayer of Mending", unit)
                    and canSpend
            end,
        },
        { direct, range = unit, when = function() return hp < bands.efficient and (hp < bands.emergency or canSpend) end },
        {
            S.Renew,
            range = unit,
            when = function()
                return renewHP and db.priestHoTs ~= false and hp < renewHP and not NC.Buff("Renew", unit) and canSpend
            end,
        },
        function()
            RH.healTarget = nil
        end,
    })
end
RubimRH.Rotation.SetAPL(5, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Shadow"
    local pvp = RH.IsPvPContext(db.priestContext)
    local mana = NC.Mana()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    return NC.Prio({
        function()
            if db.maintainBuffs ~= false then
                return NC.Missing(S.InnerFire, "Inner Fire", 180)
            end
        end,
        function()
            if db.maintainBuffs == false then
                return
            end
            local fort = RH.FindMissingBuff("Power Word: Fortitude")
            if fort then
                return RH.CastAllyBuff(S.Fortitude, fort, "Power Word: Fortitude", 300)
            end
        end,
        function()
            if db.healing ~= false then
                return RecommendHealing(db, spec, mana, reserve, pvp)
            end
        end,
        function()
            RH.healTarget = nil
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        {
            S.PsychicScream,
            when = function()
                return db.defensives ~= false
                    and pvp
                    and NC.HP()
                    and NC.HP() < (tonumber(db.defensiveHP) or 30)
                    and RH.UnitWithin("target", 10) == true
            end,
        },
        function()
            if db.useDots ~= false and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8) and RH.ResourceAbove(mana, reserve) then
                return NC.Dot(S.Pain, "Shadow Word: Pain", 14, true)
            end
        end,
        function()
            if not RH.ResourceAbove(mana, reserve) then
                return RH.RangedFallback(S.Shoot)
            end
        end,
        { S.MindBlast, range = true, when = function() return spec == "Shadow" end },
        { S.MindFlay, range = true, when = function() return spec == "Shadow" end },
        { S.HolyFire, range = true, when = function() return spec ~= "Shadow" end },
        { S.Smite, range = true },
        function()
            return RH.RangedFallback(S.Shoot)
        end,
    })
end)
