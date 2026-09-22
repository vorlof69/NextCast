local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    return NC.Prio({
        {
            S.ManaTide,
            when = function()
                return NC.CDs() and healer and mana and mana <= (tonumber(db.shamanManaTideMana) or 20)
            end,
            note = function()
                RH.healTarget = "group"
            end,
        },
        {
            S.NaturesSwiftness,
            when = function()
                return db.shamanEmergencyHeals ~= false
                    and hp <= bands.emergency
                    and not NC.Buff("Nature's Swiftness")
            end,
        },
        {
            S.Heal,
            range = unit,
            when = function()
                return db.shamanEmergencyHeals ~= false
                    and hp <= bands.emergency
                    and NC.Buff("Nature's Swiftness")
            end,
        },
        { S.Lesser, range = unit, when = function() return db.shamanEmergencyHeals ~= false and hp <= bands.emergency end },
        { S.Heal, range = unit, when = function() return hp <= bands.emergency end },
        function()
            if not healer then
                RH.healTarget = nil
                return NC.STOP
            end
        end,
        function()
            if db.shamanDispel ~= false and NC.Ready(S.CurePoison) then
                local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.CurePoison)
                end
            end
        end,
        function()
            if db.shamanDispel ~= false and NC.Ready(S.CureDisease) then
                local dispelUnit = RH.FindDispelTarget({ Disease = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.CureDisease)
                end
            end
        end,
        {
            S.Riptide,
            range = unit,
            when = function()
                return db.shamanHoTs ~= false
                    and hp <= (tonumber(db.shamanRiptideHP) or bands.hot or 85)
                    and not NC.Buff("Riptide", unit)
                    and (hp <= bands.emergency or canSpend)
            end,
        },
        {
            S.ChainHeal,
            range = unit,
            when = function()
                return db.shamanGroupHeals ~= false and injured >= chainCount and hp <= chainHP and canSpend
            end,
        },
        {
            S.HealingStream,
            when = function()
                return db.shamanGroupHeals ~= false
                    and injured >= 2
                    and RH.TotemActive(3, "Healing Stream Totem") == false
                    and canSpend
            end,
            note = function()
                RH.healTarget = "group"
            end,
        },
        { S.Lesser, range = unit, when = function() return db.shamanEmergencyHeals ~= false and hp <= bands.emergency + 10 end },
        { S.Heal, range = unit, when = function() return hp <= bands.efficient and (hp <= bands.emergency or canSpend) end },
        function()
            RH.healTarget = nil
        end,
    })
end
RubimRH.Rotation.SetAPL(7, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Enhancement"
    local healer = spec == "Restoration"
    local pvp = RH.IsPvPContext(db.shamanContext)
    local mana = NC.Mana()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local shield = healer and S.WaterShield:IsAvailable() and S.WaterShield or S.LightningShield
    local shieldName = shield:Name()
    local melee = RH.UnitWithin("target", 10)
    local fireTotem = RH.TotemActive(1)
    return NC.Prio({
        function()
            if not P:AffectingCombat() and db.maintainBuffs ~= false and shieldName then
                return NC.Missing(shield, shieldName, 180)
            end
        end,
        function()
            if
                not P:AffectingCombat()
                and db.maintainBuffs ~= false
                and RH.MainHandEnchanted() == false
                and not RH.RecentlyBuffed("player", "Weapon Imbue")
            then
                local imbue = spec == "Enhancement" and (S.Windfury:IsAvailable() and S.Windfury or S.Rockbiter)
                    or (S.Flametongue:IsAvailable() and S.Flametongue or S.Rockbiter)
                if NC.Ready(imbue) then
                    RH.NoteBuff("player", "Weapon Imbue", 180)
                    HeroLib.State.weaponEnchantUntil = GetTime() + 180
                    return NC.Go(imbue)
                end
            end
        end,
        function()
            if db.healing ~= false then
                return RecommendRestoration(db, mana, reserve, pvp)
            end
        end,
        function()
            RH.healTarget = nil
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        { S.Earth, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        { S.Grounding, when = function() return pvp and db.defensives ~= false and RH.ShouldInterrupt() end },
        { S.Purge, range = true, when = function() return pvp and RH.Burst end },
        { S.Frost, range = true, when = function() return pvp and not NC.Debuff("Frost Shock") end },
        function()
            if db.useDots ~= false and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8) and RH.ResourceAbove(mana, reserve) then
                return NC.Dot(S.Flame, "Flame Shock", 10, true)
            end
        end,
        {
            S.Magma,
            when = function()
                return NC.AoE()
                    and db.shamanTotems ~= false
                    and RH.ResourceAbove(mana, tonumber(db.shamanTotemMana) or 40)
                    and RH.TotemActive(1, "Magma Totem") == false
            end,
        },
        {
            S.FireNova,
            when = function()
                return NC.AoE() and fireTotem == true and RH.ResourceAbove(mana, tonumber(db.shamanAoEMana) or 35)
            end,
        },
        {
            S.Chain,
            range = true,
            when = function()
                return NC.AoE() and RH.ResourceAbove(mana, tonumber(db.shamanAoEMana) or 35)
            end,
        },
        {
            S.Searing,
            when = function()
                return not NC.AoE()
                    and db.shamanTotems ~= false
                    and fireTotem == false
                    and RH.TargetWillLive(10)
                    and RH.ResourceAbove(mana, tonumber(db.shamanTotemMana) or 40)
            end,
        },
        { S.Stormstrike, range = true, when = function() return spec == "Enhancement" end },
        {
            S.LavaBurst,
            range = true,
            when = function()
                return RH.ResourceAbove(mana, reserve)
                    and (spec == "Elemental" or NC.Buff("Maelstrom Weapon"))
            end,
        },
        {
            S.Lightning,
            range = true,
            when = function()
                return RH.ResourceAbove(mana, reserve)
                    and (spec ~= "Enhancement" or melee ~= true or NC.Buff("Maelstrom Weapon"))
            end,
        },
        function()
            return RH.AttackOnce()
        end,
    })
end)
