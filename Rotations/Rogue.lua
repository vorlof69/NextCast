local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
local S = {
    Attack = RH.S(6603),
    SS = RH.S(1752),
    Evis = RH.Named("Eviscerate", 2098),
    Stealth = RH.S(1784),
    Sap = RH.S(6770),
    Cheap = RH.S(1833),
    Ambush = RH.S(8676),
    Garrote = RH.S(703),
    Kick = RH.S(1766),
    Riposte = RH.S(14251),
    Gouge = RH.S(1776),
    Evasion = RH.S(5277),
    BF = RH.S(13877),
    CB = RH.S(14177),
    SnD = RH.Named("Slice and Dice", 5171),
    Rupture = RH.Named("Rupture", 1943),
    Backstab = RH.S(53),
    Kidney = RH.S(408),
    Sprint = RH.S(2983),
    Ghostly = RH.S(14278),
    Hemo = RH.S(16511),
    Mutilate = RH.S(1329),
    Vanish = RH.S(1856),
    Feint = RH.S(1966),
    Expose = RH.Named("Expose Armor", 8647),
}
RubimRH.Rotation.SetAPL(4, function()
    if P:IsDeadOrGhost() or P:IsCasting() or not RH.ValidTarget() then
        return nil
    end
    local db = RH.EnsureDB()
    local cp = NC.Combo()
    local energy = RH.Power(3) or 0
    local melee = S.SS:IsInRange()
    local engageRange = RH.UnitWithin("target", tonumber(db.stealthRange) or 25)
    local hp = NC.HP()
    local targetHP = NC.HP("target")
    local ttd = T:TimeToDie()
    local dagger = RH.MainHandIsDagger()
    local behind = not HeroLib.State.notBehindUntil or HeroLib.State.notBehindUntil <= GetTime()
    local pvp = RH.IsPvPContext(db.rogueContext)
    local opener = db.rogueOpener or "auto"

    return NC.Prio({
        function()
            if not NC.Buff("Stealth") then
                return
            end
            if NC.Debuff("Sap") then
                return NC.STOP
            end
            return NC.Prio({
                {
                    S.Sap,
                    range = true,
                    when = function()
                        return opener == "auto"
                            and pvp
                            and db.rogueSap
                            and not P:AffectingCombat()
                            and not T:AffectingCombat()
                            and not NC.Debuff("Sap")
                    end,
                },
                {
                    S.Ambush,
                    range = true,
                    when = function()
                        return opener == "ambush" and S.Ambush:IsAvailable() and dagger == true and behind
                    end,
                },
                function()
                    if opener == "ambush" and S.Ambush:IsAvailable() then
                        return NC.STOP
                    end
                end,
                {
                    S.Garrote,
                    range = true,
                    when = function()
                        return opener == "garrote" and S.Garrote:IsAvailable()
                    end,
                },
                function()
                    if opener == "garrote" and S.Garrote:IsAvailable() then
                        return NC.STOP
                    end
                end,
                {
                    S.Cheap,
                    range = true,
                    when = function()
                        return opener == "cheap" and S.Cheap:IsAvailable()
                    end,
                },
                function()
                    if opener == "cheap" and S.Cheap:IsAvailable() then
                        return NC.STOP
                    end
                end,
                { S.Cheap, range = true, when = function() return pvp end },
                { S.Ambush, range = true, when = function() return dagger == true and behind end },
                { S.Garrote, range = true, when = function() return RH.TargetWillLive(10) end },
                { S.Cheap, range = true },
                { S.SS, range = true },
            })
        end,
        {
            S.Stealth,
            when = function()
                return db.rogueStealth
                    and not P:AffectingCombat()
                    and engageRange == true
                    and S.Stealth:IsReady()
                    and not NC.Buff("Stealth")
                    and not RH.RecentlyBuffed("player", "Stealth")
            end,
            note = function()
                RH.NoteBuff("player", "Stealth", 60)
            end,
        },
        function()
            if not P:AffectingCombat() and engageRange == false then
                return NC.STOP
            end
        end,
        { S.Kick, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        { S.Kidney, range = true, when = function() return pvp and cp >= (tonumber(db.kidneyCP) or 4) end },
        {
            S.Vanish,
            when = function()
                return pvp and db.defensives ~= false and hp and hp < (tonumber(db.defensiveHP) or 30) - 10
            end,
        },
        { S.Sprint, when = function() return pvp and hp and hp < 45 end },
        {
            S.Evasion,
            when = function()
                return db.defensives ~= false and db.rogueEvasion and hp and hp < (tonumber(db.evasionHP) or 35)
            end,
        },
        function()
            if db.defensives ~= false and hp and hp < 45 and melee then
                return NC.Missing(S.Feint, "Feint", 8)
            end
        end,
        {
            S.CB,
            when = function()
                return NC.CDs() and RH.Burst and cp >= (tonumber(db.rogueCooldownCP) or 4)
            end,
        },
        { S.BF, when = function() return NC.CDs() and NC.AoE() and melee end },
        {
            S.Gouge,
            range = true,
            when = function()
                return db.defensives ~= false
                    and db.rogueGouge
                    and hp
                    and hp < (tonumber(db.gougeHP) or 50)
                    and melee
                    and not NC.Debuff("Gouge")
            end,
        },
        function()
            if cp < (tonumber(db.evisCP) or 5) then
                return
            end
            local classification = RH.SafeUnitText(UnitClassification, "target")
            local durable = classification == "elite" or classification == "rareelite" or classification == "worldboss"
            local sndLifetime = tonumber(db.sndMinTTD) or 21
            local survivesSnD = (ttd and ttd >= sndLifetime) or (not ttd and durable and targetHP and targetHP >= 75)
            local sndActive = NC.Buff("Slice and Dice")
            return NC.Prio({
                {
                    S.SnD,
                    when = function()
                        return db.rogueSnD ~= false
                            and not sndActive
                            and not RH.RecentlyBuffed("player", "Slice and Dice")
                            and (pvp or survivesSnD)
                    end,
                    note = function()
                        RH.NoteBuff("player", "Slice and Dice", 12)
                    end,
                },
                function()
                    if sndActive and db.rogueRupture ~= false and db.useDots ~= false and ((ttd and ttd > (tonumber(db.ruptureMinTTD) or 18)) or durable) then
                        return NC.Dot(S.Rupture, "Rupture", 12, true)
                    end
                end,
                function()
                    if durable and db.rogueExpose then
                        return NC.Dot(S.Expose, "Expose Armor", 20, true)
                    end
                end,
                function()
                    if db.rogueEvis == false or not RH.AbilityEnabled("Eviscerate") then
                        return
                    end
                    local inMelee = melee or S.Evis:IsInRange()
                    if inMelee and ((energy or 0) >= 35 or S.Evis:IsUsable() == true) then
                        return NC.Go(S.Evis)
                    end
                    if inMelee then
                        return NC.STOP
                    end
                end,
            })
        end,
        { S.Riposte, when = function() return melee end },
        { S.Mutilate, range = true },
        { S.Hemo, range = true },
        { S.Ghostly, range = true, when = function() return cp < 5 and melee end },
        { S.Backstab, range = true, when = function() return behind and dagger == true and melee end },
        { S.SS, when = function() return melee end },
        function()
            return RH.AttackOnce()
        end,
    })
end)
