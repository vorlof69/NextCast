local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
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
    return NC.Go(S.Maul)
end

-- Growl is an 8s Forever CD. Never paint it while latched or remaining.
local function shouldGrowl()
    if NC.OnCD(S.Growl) or not NC.Ready(S.Growl, true) then
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
    local hasRejuv = NC.Buff("Rejuvenation", unit)
    local hasRegrowth = NC.Buff("Regrowth", unit)
    local hasHot = hasRejuv or hasRegrowth
    local clearcasting = NC.Buff("Clearcasting")
    local canSpend = clearcasting or RH.ResourceAbove(mana, reserve)
    local healer = bands.role == "healer"
    return NC.Prio({
        {
            S.Innervate,
            when = function()
                return NC.CDs() and healer and mana and mana <= (tonumber(db.druidInnervateMana) or 20)
            end,
            note = function()
                RH.healTarget = "player"
            end,
        },
        {
            S.NaturesSwiftness,
            when = function()
                return hp <= bands.emergency
                    and db.druidNatureSwiftness ~= false
                    and not NC.Buff("Nature's Swiftness")
            end,
        },
        {
            S.HealingTouch,
            range = unit,
            when = function()
                return hp <= bands.emergency
                    and NC.Buff("Nature's Swiftness")
                    and db.druidDirectHeals ~= false
            end,
        },
        {
            S.Swiftmend,
            range = unit,
            when = function()
                return db.druidSwiftmend ~= false and hp <= swiftHP and hasHot
            end,
        },
        { S.Regrowth, range = unit, when = function() return hp <= bands.emergency and db.druidDirectHeals ~= false end },
        { S.HealingTouch, range = unit, when = function() return hp <= bands.emergency and db.druidDirectHeals ~= false end },
        function()
            if not healer then
                RH.healTarget = nil
                return NC.STOP
            end
        end,
        function()
            if db.druidDispel ~= false and NC.Ready(S.AbolishPoison) then
                local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.AbolishPoison)
                end
            end
        end,
        function()
            if db.druidDispel ~= false and NC.Ready(S.CurePoison) then
                local dispelUnit = RH.FindDispelTarget({ Poison = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.CurePoison)
                end
            end
        end,
        function()
            if db.druidDispel ~= false and NC.Ready(S.RemoveCurse) then
                local dispelUnit = RH.FindDispelTarget({ Curse = true }, entries)
                if dispelUnit then
                    RH.healTarget = dispelUnit
                    return NC.Go(S.RemoveCurse)
                end
            end
        end,
        {
            S.Tranquility,
            when = function()
                return db.druidGroupHeals ~= false
                    and injured >= groupCount
                    and hp <= bands.emergency + 10
                    and NC.CDs()
            end,
            note = function()
                RH.healTarget = "group"
            end,
        },
        {
            S.WildGrowth,
            range = unit,
            when = function()
                return db.druidGroupHeals ~= false and injured >= groupCount and canSpend
            end,
        },
        {
            S.Regrowth,
            range = unit,
            when = function()
                return db.druidDirectHeals ~= false
                    and hp <= regrowthHP
                    and not hasRegrowth
                    and (hp <= bands.emergency or canSpend)
            end,
        },
        {
            S.Rejuvenation,
            range = unit,
            when = function()
                return db.druidHoTs ~= false and hp <= rejuvHP and not hasRejuv and canSpend
            end,
        },
        {
            S.Lifebloom,
            range = unit,
            when = function()
                return db.druidHoTs ~= false
                    and hp <= math.min(rejuvHP, bands.efficient + 8)
                    and not NC.Buff("Lifebloom", unit)
                    and canSpend
            end,
        },
        {
            S.HealingTouch,
            range = unit,
            when = function()
                return db.druidDirectHeals ~= false
                    and hp <= bands.efficient
                    and (hp <= bands.emergency or canSpend)
            end,
        },
        function()
            RH.healTarget = nil
        end,
    })
end

RubimRH.Rotation.SetAPL(11, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    RH.TrackForm()
    local db = RH.EnsureDB()
    local spec = db.spec or "Feral"
    local healer = spec == "Restoration"
    local pvp = RH.IsPvPContext(db.druidContext)
    local mana = NC.Mana()
    local rage = NC.Rage()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0
    local playerHP = NC.HP()
    local level = UnitLevel("player")
    level = type(level) == "number" and level or 1
    local bear = NC.Form("Bear Form")
    local cat = NC.Form("Cat Form")
    local shapeshifted = RH.IsShapeshifted() or HeroLib.State.knownForm ~= nil
    if shapeshifted and not bear and not cat and level < 20 then
        bear = true
    end
    local inCombat = P:AffectingCombat()
    local wantCat = spec == "Feral" and not healer and level >= 20 and S.Cat:IsAvailable() and RH.HealRole() ~= "tank"

    if RH.ShiftPending() then
        local action = HeroLib.State.shiftAction
        if action == "enter" and not shapeshifted then
            return NC.Go(HeroLib.State.shiftSpell or S.Bear)
        end
        if action == "leave" and shapeshifted then
            return NC.Go(HeroLib.State.shiftSpell or S.Bear)
        end
        if action == "enter" then
            return nil
        end
    end

    local function hasMark()
        if RH.RecentlyBuffed("player", "Mark of the Wild") or RH.RecentlyBuffed("player", "Gift of the Wild") then
            return true
        end
        local have = P:Buff("Mark of the Wild")
        if have == true or P:Buff("Gift of the Wild") == true then
            return true
        end
        if have == false then
            return false
        end
        -- Unknown: never dump form. Caster OOC may recast.
        return shapeshifted or inCombat
    end

    return NC.Prio({
        -- Buffs only in caster form. Never cancel Bear/Cat to MotW.
        function()
            if db.maintainBuffs == false or shapeshifted then
                return
            end
            if not hasMark() then
                local unit = RH.FindMissingBuff("Mark of the Wild")
                if unit then
                    return RH.CastAllyBuff(S.Mark, unit, "Mark of the Wild", 300)
                end
            end
        end,
        function()
            if db.maintainBuffs == false or shapeshifted then
                return
            end
            if P:Buff("Thorns") == false and not RH.RecentlyBuffed("player", "Thorns") then
                return NC.Missing(S.Thorns, "Thorns", 240)
            end
        end,
        function()
            if db.healing ~= false and not shapeshifted then
                return RecommendRestoration(db, mana, reserve, pvp)
            end
        end,
        function()
            RH.healTarget = nil
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        -- Enter form once. Bear Form is a toggle — never paint it while shifted.
        {
            S.Cat,
            when = function()
                return spec == "Feral"
                    and wantCat
                    and not cat
                    and not bear
                    and not shapeshifted
            end,
            note = function()
                RH.NoteShift("enter", S.Cat)
            end,
        },
        {
            S.Bear,
            when = function()
                return spec == "Feral"
                    and not healer
                    and not wantCat
                    and not cat
                    and not bear
                    and not shapeshifted
                    and S.Bear:IsAvailable()
            end,
            note = function()
                RH.NoteShift("enter", S.Bear)
            end,
        },
        function()
            if not bear then
                return
            end
            local nearby = NC.Enemies()
            local inMelee = RH.UnitWithin("target", 10) ~= false
            return NC.Prio({
                { S.Bash, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
                { S.Charge, range = true, when = function() return not inMelee end },
                function()
                    if inMelee then
                        return RH.AttackOnce()
                    end
                end,
                function()
                    if
                        db.defensives ~= false
                        and (pvp or (playerHP and playerHP <= (tonumber(db.defensiveHP) or 30) + 30) or nearby >= 2)
                    then
                        return NC.Missing(S.Grasp, "Nature's Grasp", 40)
                    end
                end,
                {
                    S.Frenzied,
                    when = function()
                        return db.defensives ~= false
                            and playerHP
                            and playerHP <= (tonumber(db.defensiveHP) or 30)
                    end,
                },
                { S.Growl, range = true, when = shouldGrowl },
                { S.Challenging, when = function() return NC.AoE() and nearby >= 3 end },
                {
                    S.Enrage,
                    when = function()
                        return NC.CDs()
                            and inMelee
                            and (rage == nil or rage < 15)
                            and (not playerHP or playerHP > 35)
                    end,
                },
                function()
                    if inMelee and (rage == nil or rage >= 10) then
                        return NC.Dot(S.Demo, "Demoralizing Roar", 24)
                    end
                end,
                { S.Swipe, range = true, when = function() return NC.AoE() and nearby >= 2 end },
                { S.Mangle, range = true },
                {
                    S.Lacerate,
                    range = true,
                    when = function()
                        return RH.DebuffMissing("Lacerate") and RH.TargetWillLive(8)
                    end,
                },
                function()
                    if (rage == nil or rage >= 15) and NC.Ready(S.Maul, true) then
                        return queueMaul()
                    end
                end,
                function()
                    return RH.AttackOnce() or NC.STOP
                end,
            })
        end,
        function()
            if not (cat and spec == "Feral") then
                return
            end
            local cp = NC.Combo()
            local energy = NC.Energy()
            local behind = not HeroLib.State.notBehindUntil or HeroLib.State.notBehindUntil <= GetTime()
            return NC.Prio({
                {
                    S.Prowl,
                    when = function()
                        return db.druidProwl ~= false
                            and RH.UnitWithin("target", 25) == true
                            and not P:AffectingCombat()
                            and not NC.Buff("Prowl")
                            and not RH.RecentlyBuffed("player", "Prowl")
                    end,
                    note = function()
                        RH.NoteBuff("player", "Prowl", 60)
                    end,
                },
                { S.Shred, range = true, when = function() return NC.Buff("Prowl") and behind end },
                {
                    S.Dash,
                    when = function()
                        return pvp
                            and db.defensives ~= false
                            and playerHP
                            and playerHP <= (tonumber(db.defensiveHP) or 30) + 20
                    end,
                },
                function()
                    if db.defensives ~= false and (pvp or (playerHP and playerHP <= (tonumber(db.defensiveHP) or 30) + 25)) then
                        return NC.Missing(S.Grasp, "Nature's Grasp", 40)
                    end
                end,
                function()
                    if cp >= 5 and db.useDots ~= false and RH.TargetWillLive(tonumber(db.druidRipTTD) or 12) then
                        return NC.Dot(S.Rip, "Rip", 10, true)
                    end
                end,
                { S.Bite, range = true, when = function() return cp >= 5 end },
                function()
                    if db.useDots ~= false and RH.TargetWillLive(tonumber(db.druidRakeTTD) or 8) then
                        return NC.Dot(S.Rake, "Rake", 8, true)
                    end
                end,
                {
                    S.Tiger,
                    when = function()
                        return NC.CDs()
                            and energy
                            and energy <= (tonumber(db.druidTigerEnergy) or 40)
                            and not NC.Buff("Tiger's Fury")
                            and not RH.RecentlyBuffed("player", "Tiger's Fury")
                    end,
                    note = function()
                        RH.NoteBuff("player", "Tiger's Fury", 6)
                    end,
                },
                function()
                    if cp >= 5 then
                        return RH.AttackOnce() or NC.STOP
                    end
                end,
                { S.Mangle, range = true },
                { S.Shred, range = true, when = function() return behind end },
                { S.Claw, range = true },
                function()
                    return RH.AttackOnce() or NC.STOP
                end,
            })
        end,
        { S.Roots, range = true, when = function() return pvp and db.defensives ~= false and not NC.Debuff("Entangling Roots") end },
        function()
            if db.useDots ~= false and RH.TargetWillLive(10) then
                return NC.Dot(S.Faerie, "Faerie Fire", 32, true)
            end
        end,
        function()
            if db.useDots ~= false and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8) and RH.ResourceAbove(mana, reserve) then
                return NC.Dot(S.Moonfire, "Moonfire", 10, true)
            end
        end,
        function()
            if db.useDots ~= false and spec == "Balance" and RH.TargetWillLive(tonumber(db.dotMinTTD) or 8) and RH.ResourceAbove(mana, reserve) then
                return NC.Dot(S.Insect, "Insect Swarm", 10, true)
            end
        end,
        function()
            if not RH.ResourceAbove(mana, reserve) then
                return RH.AttackOnce() or NC.STOP
            end
        end,
        { S.Hurricane, range = true, when = function() return NC.AoE() and RH.ResourceAbove(mana, 45) end },
        { S.Starfire, range = true, when = function() return spec == "Balance" end },
        { S.Wrath, range = true },
        function()
            return RH.AttackOnce()
        end,
    })
end)
