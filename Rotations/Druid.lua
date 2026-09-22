local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local S = {
    HealingTouch = RH.Named("Healing Touch", 5185),
    Rejuvenation = RH.Named("Rejuvenation", 774),
    Regrowth = RH.Named("Regrowth", 8936),
    Swiftmend = RH.Named("Swiftmend", 18562),
    Lifebloom = RH.Named("Lifebloom", 33763),
    WildGrowth = RH.Named("Wild Growth"),
    Tranquility = RH.Named("Tranquility", 740),
    NaturesSwiftness = RH.Named("Nature's Swiftness", 17116),
    Innervate = RH.Named("Innervate", 29166),
    Moonfire = RH.S(8921),
    Wrath = RH.S(5176),
    Starfire = RH.S(2912),
    Insect = RH.S(5570),
    Hurricane = RH.S(16914),
    Maul = RH.S(6807),
    Claw = RH.S(1082),
    Rake = RH.S(1822),
    Rip = RH.S(1079),
    Bite = RH.S(22568),
    Shred = RH.S(5221),
    Swipe = RH.S(779),
    Demo = RH.Named("Demoralizing Roar", 99),
    Bash = RH.S(5211),
    Faerie = RH.S(770),
    Tiger = RH.S(5217),
    Mark = RH.Named("Mark of the Wild", 1126),
    Thorns = RH.Named("Thorns", 467),
    Cat = RH.S(768),
    Bear = RH.S(5487),
    Prowl = RH.S(5215),
    Mangle = RH.Named("Mangle"),
    AbolishPoison = RH.Named("Abolish Poison"),
    RemoveCurse = RH.Named("Remove Curse"),
    Growl = RH.Named("Growl", 6795),
    Grasp = RH.Named("Nature's Grasp", 16689),
    Enrage = RH.S(5229),
    Charge = RH.Named("Feral Charge", 16979),
    Roots = RH.S(339),
    Dash = RH.S(1850),
    Challenging = RH.S(5209),
    Frenzied = RH.Named("Frenzied Regeneration", 22842),
    Lacerate = RH.Named("Lacerate", 33745),
    CurePoison = RH.Named("Cure Poison", 8946),
}

local function queueMaul()
    local id = S.Maul:ID()
    if id and id > 0 then
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
    return S.Maul:Cast()
end

-- Growl (Forever 8s CD) does nothing if the mob is already hitting you.
-- Trust targettarget first — threat APIs are often secret on this client.
local function shouldGrowl()
    if not RH.Ready(S.Growl, true) then
        return false
    end
    if RH.NeedsTaunt() then
        return true
    end
    if RH.GroupSize() > 1 then
        local threat = RH.ThreatStatus("player")
        if threat ~= nil and threat < 2 then
            return true
        end
    end
    return false
end

local function RecommendRestoration(db, mana, reserve, pvp)
    local bands = RH.HealBands(pvp)
    local entries = RH.FriendlySnapshot(1.25)
    local unit, hp = RH.PickHealTarget(entries, pvp)
    unit = unit or "player"
    hp = hp or 100
    local ally = HeroLib.Unit(unit)
    RH.healTarget = unit
    local rejuvHP = tonumber(db.druidRejuvenationHP) or bands.hot or 88
    local regrowthHP = tonumber(db.druidRegrowthHP) or 55
    local swiftHP = tonumber(db.druidSwiftmendHP) or 50
    local groupHP = tonumber(db.druidWildGrowthHP) or 80
    local groupCount = tonumber(db.druidWildGrowthCount) or 3
    local injured = RH.CountInjuredFriendlies(entries, groupHP, { "Wild Growth", S.WildGrowth:ID() })
    local hasRejuv = ally:Buff("Rejuvenation") == true
    local hasRegrowth = ally:Buff("Regrowth") == true
    local hasHot = hasRejuv or hasRegrowth
    local clearcasting = P:Buff("Clearcasting") == true
    local canSpend = clearcasting or RH.ResourceAbove(mana, reserve)
    local healer = bands.role == "healer"

    if RH.CDs and healer and mana and mana <= (tonumber(db.druidInnervateMana) or 20) and RH.Ready(S.Innervate) then
        RH.healTarget = "player"
        return S.Innervate:Cast()
    end
    if
        hp <= bands.emergency
        and db.druidNatureSwiftness ~= false
        and P:Buff("Nature's Swiftness") ~= true
        and RH.Ready(S.NaturesSwiftness)
    then
        return S.NaturesSwiftness:Cast()
    end
    if
        hp <= bands.emergency
        and P:Buff("Nature's Swiftness") == true
        and db.druidDirectHeals ~= false
        and RH.Ready(S.HealingTouch, unit)
    then
        return S.HealingTouch:Cast()
    end
    if db.druidSwiftmend ~= false and hp <= swiftHP and hasHot and RH.Ready(S.Swiftmend, unit) then
        return S.Swiftmend:Cast()
    end
    if hp <= bands.emergency and db.druidDirectHeals ~= false and RH.Ready(S.Regrowth, unit) then
        return S.Regrowth:Cast()
    end
    if hp <= bands.emergency and db.druidDirectHeals ~= false and RH.Ready(S.HealingTouch, unit) then
        return S.HealingTouch:Cast()
    end
    if not healer then
        RH.healTarget = nil
        return nil
    end
    if db.druidDispel ~= false and RH.Ready(S.AbolishPoison) then
        local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.AbolishPoison:Cast()
        end
    end
    if db.druidDispel ~= false and RH.Ready(S.CurePoison) then
        local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.CurePoison:Cast()
        end
    end
    if db.druidDispel ~= false and RH.Ready(S.RemoveCurse) then
        local dispelUnit = RH.FindDispelTarget({ Curse = true }, entries)
        if dispelUnit then
            RH.healTarget = dispelUnit
            return S.RemoveCurse:Cast()
        end
    end
    if
        db.druidGroupHeals ~= false
        and injured >= groupCount
        and hp <= bands.emergency + 10
        and RH.CDs
        and RH.Ready(S.Tranquility)
    then
        RH.healTarget = "group"
        return S.Tranquility:Cast()
    end
    if db.druidGroupHeals ~= false and injured >= groupCount and canSpend and RH.Ready(S.WildGrowth, unit) then
        return S.WildGrowth:Cast()
    end
    if
        db.druidDirectHeals ~= false
        and hp <= regrowthHP
        and not hasRegrowth
        and (hp <= bands.emergency or canSpend)
        and RH.Ready(S.Regrowth, unit)
    then
        return S.Regrowth:Cast()
    end
    if db.druidHoTs ~= false and hp <= rejuvHP and not hasRejuv and canSpend and RH.Ready(S.Rejuvenation, unit) then
        return S.Rejuvenation:Cast()
    end
    if
        db.druidHoTs ~= false
        and hp <= math.min(rejuvHP, bands.efficient + 8)
        and ally:Buff("Lifebloom") ~= true
        and canSpend
        and RH.Ready(S.Lifebloom, unit)
    then
        return S.Lifebloom:Cast()
    end
    if
        db.druidDirectHeals ~= false
        and hp <= bands.efficient
        and (hp <= bands.emergency or canSpend)
        and RH.Ready(S.HealingTouch, unit)
    then
        return S.HealingTouch:Cast()
    end
    RH.healTarget = nil
    return nil
end

RubimRH.Rotation.SetAPL(11, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Feral"
    local healer = spec == "Restoration"
    local pvp = RH.IsPvPContext(db.druidContext)
    local mana = RH.PowerPercent(0)
    local rage = RH.Power(1)
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local emergency = tonumber(db.emergencyHealHP) or 35
    local efficient = tonumber(db.efficientHealHP) or 70
    local playerHP = P:HealthPercentage()
    local level = UnitLevel("player")
    level = type(level) == "number" and level or 1
    local bear = RH.InForm("Bear Form")
    local cat = RH.InForm("Cat Form")
    local shapeshifted = RH.IsShapeshifted()
    -- Secret aura + no form name: below Cat (20) any shapeshift is Bear.
    if shapeshifted and not bear and not cat and level < 20 then
        bear = true
    end

    local engagedNow = P:AffectingCombat() and RH.ValidTarget() and RH.UnitWithin("target", 10) ~= false
    if engagedNow then
        HeroLib.State.druidEngagedSince = HeroLib.State.druidEngagedSince or GetTime()
    else
        HeroLib.State.druidEngagedSince = nil
    end

    -- Never recast Bear/Cat while a shift is in flight — second press dumps the form.
    if RH.ShiftPending() then
        local action = HeroLib.State.shiftAction
        if action == "enter" and not shapeshifted then
            local spell = HeroLib.State.shiftSpell or S.Bear
            return spell:Cast()
        end
        return nil
    end

    -- Stay in Bear/Cat. MotW and Thorns only while already caster — dropping
    -- form after every kill to recast them was flashing human then Bear.
    if db.maintainBuffs ~= false and not shapeshifted then
        local mark = RH.FindMissingBuff("Mark of the Wild")
        if mark then
            local cast = RH.CastAllyBuff(S.Mark, mark, "Mark of the Wild", 300)
            if cast then
                return cast
            end
        end
        if not RH.RecentlyBuffed("player", "Thorns") and P:Buff("Thorns") == false then
            local cast = RH.CastIfMissing(S.Thorns, "Thorns", 240)
            if cast then
                return cast
            end
        end
    end
    if db.healing ~= false and not shapeshifted then
        local heal = RecommendRestoration(db, mana, reserve, pvp)
        if heal then
            return heal
        end
    end
    RH.healTarget = nil

    if not RH.ValidTarget() then
        return nil
    end

    -- Feral: Cat from 20, Bear from 10. Bear Form is a toggle — never paint it
    -- while already shifted.
    if spec == "Feral" and not cat and not bear and not shapeshifted then
        if level >= 20 and S.Cat:IsAvailable() and RH.Ready(S.Cat) then
            RH.NoteShift("enter", S.Cat)
            return S.Cat:Cast()
        elseif S.Bear:IsAvailable() and RH.Ready(S.Bear) then
            RH.NoteShift("enter", S.Bear)
            return S.Bear:Cast()
        end
    end

    if bear then
        local nearby = RH.CountNearbyEnemies()
        local inMelee = RH.UnitWithin("target", 10) ~= false

        if RH.Interrupts and RH.ShouldInterrupt() and RH.Ready(S.Bash, true) then
            return S.Bash:Cast()
        end

        -- Feral Charge (talent) to close. Level 11 will skip until learned.
        if not inMelee and RH.Ready(S.Charge, true) then
            return S.Charge:Cast()
        end

        -- Auto-attack MUST be running. Maul is a next-swing. Pulse Attack
        -- once (Action's IsAttacking gate), then Maul.
        if inMelee then
            local attack = RH.AttackOnce()
            if attack then
                return attack
            end
        end

        -- Nature's Grasp: Forever baseline at 10, 100% next melee root, usable
        -- while shapeshifted. Hold for real pressure, not every pull.
        if
            db.defensives ~= false
            and (
                pvp
                or (playerHP and playerHP <= (tonumber(db.defensiveHP) or 30) + 30)
                or nearby >= 2
            )
        then
            local grasp = RH.CastIfMissing(S.Grasp, "Nature's Grasp", 40)
            if grasp then
                return grasp
            end
        end

        if
            db.defensives ~= false
            and playerHP
            and playerHP <= (tonumber(db.defensiveHP) or 30)
            and RH.Ready(S.Frenzied)
        then
            return S.Frenzied:Cast()
        end

        if shouldGrowl() then
            return S.Growl:Cast()
        end
        if RH.AoE and nearby >= 3 and RH.Ready(S.Challenging) then
            return S.Challenging:Cast()
        end

        -- Enrage (12): instant 10 rage + 20 over 10s. Skip if already dying —
        -- Forever's Enrage still cuts armor.
        if
            RH.CDs
            and inMelee
            and (rage == nil or rage < 15)
            and (not playerHP or playerHP > 35)
            and RH.Ready(S.Enrage)
        then
            return S.Enrage:Cast()
        end

        -- Demoralizing Roar (10, 10 rage, 30s). Latch so a false scan cannot
        -- dump rage every GCD.
        if inMelee and (rage == nil or rage >= 10) then
            local roar = RH.CastIfDebuffMissing(S.Demo, "Demoralizing Roar", 24)
            if roar then
                return roar
            end
        end

        if RH.AoE and nearby >= 2 and RH.Ready(S.Swipe, true) then
            return S.Swipe:Cast()
        end
        if RH.Ready(S.Mangle, true) then
            return S.Mangle:Cast()
        end
        if
            RH.DebuffMissing("Lacerate")
            and RH.TargetWillLive(8)
            and RH.Ready(S.Lacerate, true)
        then
            return S.Lacerate:Cast()
        end
        if (rage == nil or rage >= 15) and RH.Ready(S.Maul, true) then
            local maul = queueMaul()
            if maul then
                return maul
            end
        end
        return RH.AttackOnce()
    end

    if cat and spec == "Feral" then
        local cp = P:ComboPoints() or 0
        local energy = RH.Power(3)
        local behind = not HeroLib.State.notBehindUntil or HeroLib.State.notBehindUntil <= GetTime()
        if
            db.druidProwl ~= false
            and RH.UnitWithin("target", 25) == true
            and not P:AffectingCombat()
            and P:Buff("Prowl") == false
            and not RH.RecentlyBuffed("player", "Prowl")
            and RH.Ready(S.Prowl)
        then
            RH.NoteBuff("player", "Prowl", 60)
            return S.Prowl:Cast()
        end
        if P:Buff("Prowl") == true and behind and RH.Ready(S.Shred, true) then
            return S.Shred:Cast()
        end
        if
            pvp
            and db.defensives ~= false
            and playerHP
            and playerHP <= (tonumber(db.defensiveHP) or 30) + 20
            and RH.Ready(S.Dash)
        then
            return S.Dash:Cast()
        end
        if
            db.defensives ~= false
            and (pvp or (playerHP and playerHP <= (tonumber(db.defensiveHP) or 30) + 25))
        then
            local grasp = RH.CastIfMissing(S.Grasp, "Nature's Grasp", 40)
            if grasp then
                return grasp
            end
        end
        if cp >= 5 then
            if db.useDots ~= false and RH.TargetWillLive(tonumber(db.druidRipTTD) or 12) then
                local rip = RH.CastIfDebuffMissing(S.Rip, "Rip", 10, true)
                if rip then
                    return rip
                end
            end
            if RH.Ready(S.Bite, true) then
                return S.Bite:Cast()
            end
        end
        if db.useDots ~= false and RH.TargetWillLive(tonumber(db.druidRakeTTD) or 8) then
            local rake = RH.CastIfDebuffMissing(S.Rake, "Rake", 8, true)
            if rake then
                return rake
            end
        end
        if
            RH.CDs
            and energy
            and energy <= (tonumber(db.druidTigerEnergy) or 40)
            and P:Buff("Tiger's Fury") == false
            and not RH.RecentlyBuffed("player", "Tiger's Fury")
            and RH.Ready(S.Tiger)
        then
            RH.NoteBuff("player", "Tiger's Fury", 6)
            return S.Tiger:Cast()
        end
        if cp >= 5 then
            return RH.AttackOnce()
        end
        if RH.Ready(S.Mangle, true) then
            return S.Mangle:Cast()
        end
        if behind and RH.Ready(S.Shred, true) then
            return S.Shred:Cast()
        end
        if RH.Ready(S.Claw, true) then
            return S.Claw:Cast()
        end
        return RH.AttackOnce()
    end

    if pvp and db.defensives ~= false and T:Debuff("Entangling Roots") ~= true and RH.Ready(S.Roots, true) then
        return S.Roots:Cast()
    end
    if db.useDots ~= false and RH.TargetWillLive(10) then
        local faerie = RH.CastIfDebuffMissing(S.Faerie, "Faerie Fire", 32, true)
        if faerie then
            return faerie
        end
    end
    if
        db.useDots ~= false
        and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8)
        and RH.ResourceAbove(mana, reserve)
    then
        local moon = RH.CastIfDebuffMissing(S.Moonfire, "Moonfire", 10, true)
        if moon then
            return moon
        end
    end
    if
        db.useDots ~= false
        and spec == "Balance"
        and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8)
        and RH.ResourceAbove(mana, reserve)
    then
        local insect = RH.CastIfDebuffMissing(S.Insect, "Insect Swarm", 10, true)
        if insect then
            return insect
        end
    end
    if not RH.ResourceAbove(mana, reserve) then
        return RH.AttackOnce()
    end
    if RH.AoE and RH.ResourceAbove(mana, 45) and RH.Ready(S.Hurricane, true) then
        return S.Hurricane:Cast()
    end
    if spec == "Balance" and RH.Ready(S.Starfire, true) then
        return S.Starfire:Cast()
    end
    if RH.Ready(S.Wrath, true) then
        return S.Wrath:Cast()
    end
    return RH.AttackOnce()
end)
