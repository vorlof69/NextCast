local RH, P, T = RubimRH, RubimRH.Player, RubimRH.Target
local NC = RH.NC
local S = {
    Frostbolt = RH.S(116),
    Fireball = RH.S(133),
    FireBlast = RH.S(2136),
    Nova = RH.S(122),
    Cone = RH.S(120),
    ArcaneExplosion = RH.S(1449),
    Missiles = RH.S(5143),
    Scorch = RH.S(2948),
    Pyroblast = RH.S(11366),
    Blizzard = RH.S(10),
    Evocation = RH.S(12051),
    Intellect = RH.Named("Arcane Intellect", 1459),
    FrostArmor = RH.S(168),
    Counterspell = RH.S(2139),
    Blink = RH.S(1953),
    IceBlock = RH.Named("Ice Block", 45438),
    Shoot = RH.S(5019),
    ArcaneBlast = RH.Named("Arcane Blast"),
    Polymorph = RH.S(118),
    IceLance = RH.Named("Ice Lance"),
}
RubimRH.Rotation.SetAPL(8, function()
    if P:IsDeadOrGhost() or P:IsCasting() then
        return nil
    end
    local db = RH.EnsureDB()
    local spec = db.spec or "Frost"
    local pvp = RH.IsPvPContext(db.mageContext)
    local mana = RH.PowerPercent(0)
    local close = RH.UnitWithin("target", 10)
    local hp = NC.HP()
    local reserve = db.resourceLogic ~= false and (tonumber(db.manaReserve) or 25) or 0

    return NC.Prio({
        function()
            if db.maintainBuffs == false then
                return
            end
            local unit = RH.FindMissingBuff("Arcane Intellect")
            if unit then
                return RH.CastAllyBuff(S.Intellect, unit, "Arcane Intellect", 300)
            end
        end,
        function()
            if db.maintainBuffs ~= false then
                return NC.Missing(S.FrostArmor, { "Frost Armor", "Ice Armor", "Mage Armor" }, 300)
            end
        end,
        function()
            if not RH.ValidTarget() then
                return NC.STOP
            end
        end,
        { S.Counterspell, range = true, when = function() return NC.Interrupts() and RH.ShouldInterrupt() end },
        {
            S.Polymorph,
            range = true,
            when = function()
                return pvp and not P:AffectingCombat() and not NC.Debuff("Polymorph")
            end,
        },
        {
            S.IceBlock,
            when = function()
                return db.defensives ~= false and hp and hp < (tonumber(db.defensiveHP) or 30) - 5
            end,
        },
        {
            S.Blink,
            when = function()
                return db.defensives ~= false
                    and hp
                    and hp < (tonumber(db.defensiveHP) or 30) + 15
                    and close == true
            end,
        },
        { S.Evocation, when = function() return mana and mana < (tonumber(db.mageEvocationMana) or 15) end },
        {
            S.Nova,
            when = function()
                return db.mageControl ~= false and (pvp or NC.AoE()) and close and not NC.Debuff("Frost Nova")
            end,
        },
        {
            S.Cone,
            range = true,
            when = function()
                return db.mageControl ~= false and close and (pvp or NC.AoE()) and RH.ResourceAbove(mana, 35)
            end,
        },
        function()
            if not RH.ResourceAbove(mana, reserve) and S.Shoot:IsAvailable() then
                return RH.RangedFallback(S.Shoot)
            end
        end,
        {
            S.ArcaneExplosion,
            when = function()
                return NC.AoE() and close and RH.ResourceAbove(mana, tonumber(db.mageAoEMana) or 40)
            end,
        },
        {
            S.Blizzard,
            range = true,
            when = function()
                return NC.AoE() and RH.ResourceAbove(mana, (tonumber(db.mageAoEMana) or 40) + 5)
            end,
        },
        { S.ArcaneBlast, range = true, when = function() return spec == "Arcane" end },
        { S.Missiles, range = true, when = function() return spec == "Arcane" end },
        { S.Pyroblast, range = true, when = function() return spec == "Fire" and NC.Buff("Hot Streak") end },
        { S.FireBlast, range = true, when = function() return spec == "Fire" end },
        { S.Fireball, range = true, when = function() return spec == "Fire" end },
        { S.Scorch, range = true, when = function() return spec == "Fire" end },
        { S.IceLance, range = true, when = function() return spec ~= "Arcane" and spec ~= "Fire" and NC.Buff("Fingers of Frost") end },
        { S.Frostbolt, range = true, when = function() return spec ~= "Arcane" and spec ~= "Fire" end },
        { S.Fireball, range = true },
        { S.Frostbolt, range = true },
        { S.Missiles, range = true },
        function()
            return RH.RangedFallback(S.Shoot)
        end,
    })
end)
