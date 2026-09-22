local HL = HeroLib
local builders = {
    ["Sinister Strike"] = 1,
    ["Backstab"] = 1,
    ["Ambush"] = 1,
    ["Garrote"] = 1,
    ["Gouge"] = 1,
    ["Cheap Shot"] = 2,
    ["Ghostly Strike"] = 1,
    ["Hemorrhage"] = 1,
    ["Mutilate"] = 2,
    ["Claw"] = 1,
    ["Rake"] = 1,
    ["Shred"] = 1,
    ["Mangle"] = 1,
}
local finishers = {
    ["Eviscerate"] = true,
    ["Rupture"] = true,
    ["Slice and Dice"] = true,
    ["Kidney Shot"] = true,
    ["Expose Armor"] = true,
    ["Rip"] = true,
    ["Ferocious Bite"] = true,
}
local buffDurations = {
    ["Stealth"] = 3600,
    ["Evasion"] = 15,
    ["Sprint"] = 15,
    ["Blade Flurry"] = 15,
    ["Cold Blood"] = 30,
    ["Battle Shout"] = 120,
    ["Bloodrage"] = 10,
    ["Sweeping Strikes"] = 10,
    ["Death Wish"] = 30,
    ["Shield Block"] = 7,
    ["Last Stand"] = 20,
    ["Berserker Rage"] = 10,
    ["Blessing of Might"] = 300,
    ["Blessing of Wisdom"] = 300,
    ["Blessing of Kings"] = 300,
    ["Devotion Aura"] = 3600,
    ["Retribution Aura"] = 3600,
    ["Concentration Aura"] = 3600,
    ["Righteous Fury"] = 1800,
    ["Seal of Righteousness"] = 30,
    ["Seal of Command"] = 30,
    ["Seal of Fury"] = 30,
    ["Seal of Wisdom"] = 30,
    ["Seal of Light"] = 30,
    ["Divine Protection"] = 8,
    ["Holy Shield"] = 10,
    ["Rapid Fire"] = 15,
    ["Aspect of the Hawk"] = 3600,
    ["Aspect of the Monkey"] = 3600,
    ["Arcane Intellect"] = 1800,
    ["Frost Armor"] = 1800,
    ["Ice Armor"] = 1800,
    ["Mage Armor"] = 1800,
    ["Power Word: Fortitude"] = 1800,
    ["Inner Fire"] = 600,
    ["Lightning Shield"] = 600,
    ["Water Shield"] = 600,
    ["Demon Skin"] = 1800,
    ["Demon Armor"] = 1800,
    ["Mark of the Wild"] = 1800,
    ["Thorns"] = 600,
    ["Hot Streak"] = 10,
    ["Fingers of Frost"] = 15,
    ["Power Word: Shield"] = 30,
    ["Renew"] = 15,
    ["Prayer of Mending"] = 30,
    ["Rejuvenation"] = 12,
    ["Regrowth"] = 21,
    ["Lifebloom"] = 7,
    ["Wild Growth"] = 7,
    ["Riptide"] = 15,
    ["Light's Vigil"] = 30,
    ["Nature's Swiftness"] = 30,
    ["Innervate"] = 20,
    ["Tiger's Fury"] = 6,
    ["Nature's Grasp"] = 45,
    ["Enrage"] = 10,
    ["Prowl"] = 3600,
    ["Divine Shield"] = 12,
}
local formToggles = {
    ["Bear Form"] = true,
    ["Dire Bear Form"] = true,
    ["Cat Form"] = true,
    ["Travel Form"] = true,
    ["Aquatic Form"] = true,
    ["Moonkin Form"] = true,
    ["Righteous Fury"] = true,
    ["Battle Stance"] = true,
    ["Defensive Stance"] = true,
    ["Berserker Stance"] = true,
}
local debuffDurations = {
    ["Sap"] = 25,
    ["Gouge"] = 4,
    ["Garrote"] = 18,
    ["Rupture"] = 16,
    ["Kidney Shot"] = 5,
    ["Rend"] = 18,
    ["Hamstring"] = 15,
    ["Thunder Clap"] = 22,
    ["Demoralizing Shout"] = 30,
    ["Sunder Armor"] = 30,
    ["Concussion Blow"] = 5,
    ["Hammer of Justice"] = 6,
    ["Hunter's Mark"] = 120,
    ["Serpent Sting"] = 15,
    ["Wing Clip"] = 10,
    ["Frost Nova"] = 8,
    ["Shadow Word: Pain"] = 18,
    ["Flame Shock"] = 12,
    ["Frost Shock"] = 8,
    ["Bane of Agony"] = 24,
    ["Curse of Agony"] = 24,
    ["Corruption"] = 18,
    ["Immolate"] = 15,
    ["Siphon Life"] = 30,
    ["Faerie Fire"] = 40,
    ["Moonfire"] = 12,
    ["Insect Swarm"] = 12,
    ["Rake"] = 9,
    ["Demoralizing Roar"] = 30,
}
local keepsStealth = { ["Stealth"] = true, ["Prowl"] = true, ["Sap"] = true, ["Distract"] = true }
debuffDurations["Rip"] = 12
local positionalSpells = { ["Backstab"] = true, ["Ambush"] = true, ["Shred"] = true }
local f = CreateFrame("Frame")
local function register(e)
    if not pcall(f.RegisterUnitEvent, f, e, "player") then
        pcall(f.RegisterEvent, f, e)
    end
end
register("UNIT_SPELLCAST_SENT")
register("UNIT_SPELLCAST_SUCCEEDED")
register("UNIT_SPELLCAST_FAILED")
register("UNIT_SPELLCAST_INTERRUPTED")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(f.RegisterEvent, f, "PLAYER_ENTER_COMBAT")
pcall(f.RegisterEvent, f, "PLAYER_LEAVE_COMBAT")
pcall(f.RegisterEvent, f, "UI_ERROR_MESSAGE")
pcall(f.RegisterEvent, f, "UNIT_POWER_UPDATE")
pcall(f.RegisterEvent, f, "UNIT_POWER_FREQUENT")
pcall(f.RegisterEvent, f, "PLAYER_COMBO_POINTS")
f:SetScript("OnEvent", function(_, event, unit, a, b, c)
    if RubimRH then
        RubimRH.recommendationDirty = true
    end
    -- Party/raid HoTs, shields and lockout debuffs drive every healer priority.
    -- Invalidating only player/target left ally aura results stale until a full
    -- cache reset, causing repeat casts or missed refreshes.
    if event == "UNIT_AURA" then
        if type(unit) == "string" and not HL.Secret(unit) then
            HL.InvalidateAuras(unit)
        end
        return
    end
    if event == "PLAYER_ENTER_COMBAT" then
        -- Vanilla/Classic: auto-attack started (not the same as entering combat).
        HL.State.meleeAttacking = true
        return
    end
    if event == "PLAYER_LEAVE_COMBAT" then
        -- Auto-attack stopped. May still be in combat.
        HL.State.meleeAttacking = false
        HL.State.attackSuggested = nil
        HL.State.attackSuggestedAt = nil
        return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        HL.State.combatStartedAt = GetTime()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        HL.State.lastCombatDuration = HL.State.combatStartedAt and GetTime() - HL.State.combatStartedAt or 0
        HL.State.combatStartedAt = nil
        HL.State.meleeAttacking = false
        HL.State.attackSuggested = nil
        HL.State.attackSuggestedAt = nil
        HL.State.autoShotSuggested = nil
        HL.State.autoShotSuggestedAt = nil
        wipe(HL.State.pending)
        return
    end
    if event == "UI_ERROR_MESSAGE" then
        local message = type(a) == "string" and a or type(b) == "string" and b
        if HL.Secret(message) or type(message) ~= "string" then
            return
        end
        local positional = string.find(string.lower(message), "behind", 1, true)
            or message == _G.SPELL_FAILED_NOT_BEHIND
            or message == _G.ERR_BADATTACKPOS
        local recommended = RubimRH and RubimRH.currentRecommendation
        if positional and recommended and positionalSpells[HeroCache:SpellInfo(recommended)] then
            HL.State.notBehindUntil = GetTime() + 3
        end
        return
    end
    if event == "PLAYER_TARGET_CHANGED" then
        HL.State.targetRevision = (HL.State.targetRevision or 0) + 1
        HL.State.combo = 0
        HL.State.lastComboBuildAt = nil
        HL.State.attackSuggested = nil
        HL.State.attackSuggestedAt = nil
        HL.State.autoShotSuggested = nil
        HL.State.autoShotSuggestedAt = nil
        HL.State.notBehindUntil = nil
        wipe(HL.State.debuffs)
        wipe(HL.State.targetHealth)
        wipe(HL.State.targetStacks)
        HL.InvalidateAuras()
        return
    end
    if event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "PLAYER_COMBO_POINTS" then
        if event == "PLAYER_COMBO_POINTS" or (unit == "player" and (a == "COMBO_POINTS" or a == nil)) then
            HL.Unit.Player:ComboPoints()
        end
        return
    end
    if unit ~= "player" then
        return
    end
    if event == "UNIT_SPELLCAST_SENT" then
        local guid = type(b) == "string" and not HL.Secret(b) and b
        local id = type(c) == "number" and not HL.Secret(c) and c
        local record = {
            id = id,
            at = GetTime(),
            targetRevision = HL.State.targetRevision or 0,
            combo = HL.Unit.Player:ComboPoints(),
        }
        local ok, playerName = pcall(UnitName, "player")
        record.otherTarget = not HL.Secret(a)
            and type(a) == "string"
            and a ~= ""
            and ok
            and not HL.Secret(playerName)
            and a ~= playerName
        for key, pending in pairs(HL.State.pending) do
            if GetTime() - pending.at > 15 then
                HL.State.pending[key] = nil
            end
        end
        if guid then
            HL.State.pending[guid] = record
        end
        -- Heal is queued on the ally. Put the enemy back so the next GCD is DPS.
        if RubimRH and RubimRH.RestoreAfterHeal then
            RubimRH.RestoreAfterHeal(true)
        end
        return
    end
    local guid = type(a) == "string" and not HL.Secret(a) and a
    local record = guid and HL.State.pending[guid]
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
        local failedID = type(b) == "number" and not HL.Secret(b) and b or (record and record.id)
        if event == "UNIT_SPELLCAST_FAILED" and failedID then
            local name = HeroCache:SpellInfo(failedID)
            if name then
                HL.State.failedUntil[name] = GetTime() + 0.75
            end
        end
        if event == "UNIT_SPELLCAST_FAILED" and failedID and positionalSpells[HeroCache:SpellInfo(failedID)] then
            local energy = HL.SafeNumber(UnitPower("player", 3), 0)
            if energy >= 55 then
                HL.State.notBehindUntil = GetTime() + 3
            end
        end
        if guid then
            HL.State.pending[guid] = nil
        end
        HL.State.lastSent = nil
        return
    end
    local id = type(b) == "number" and not HL.Secret(b) and b or (record and record.id)
    if guid then
        HL.State.pending[guid] = nil
    end
    HL.State.lastSent = nil
    if not id then
        return
    end
    local name = HeroCache:SpellInfo(id)
    if not name then
        return
    end
    local now = GetTime()
    HL.State.failedUntil[name] = nil
    local sameTarget = not record or record.targetRevision == (HL.State.targetRevision or 0)
    if name and not keepsStealth[name] then
        HL.State.buffs["Stealth"] = nil
        HL.State.buffs["Prowl"] = nil
    end
    if formToggles[name] then
        -- Shapeshift is a toggle. SUCCEEDED fires on enter AND cancel, so never
        -- infer a 3600s "in form" buff — that recast Bear while already Bear.
        for form in pairs(formToggles) do
            HL.State.buffs[form] = nil
        end
    elseif buffDurations[name] and not (record and record.otherTarget) then
        HL.State.buffs[name] = now + buffDurations[name]
        if RubimRH and RubimRH.NoteBuff then
            RubimRH.NoteBuff("player", name, buffDurations[name])
        end
    end
    if name == "Vanish" then
        HL.State.buffs["Stealth"] = now + 10
    end
    if name == "Rockbiter Weapon" or name == "Flametongue Weapon" or name == "Windfury Weapon" then
        HL.State.weaponEnchantUntil = now + 300
    end
    if sameTarget and debuffDurations[name] then
        HL.State.debuffs[name] = now + debuffDurations[name]
    end
    if sameTarget and name == "Sunder Armor" then
        HL.State.targetStacks[name] = math.min(5, (HL.State.targetStacks[name] or 0) + 1)
    end
    if RubimRH and name == "Battle Stance" then
        RubimRH.Rotation.stance = 1
    elseif RubimRH and name == "Defensive Stance" then
        RubimRH.Rotation.stance = 2
    elseif RubimRH and name == "Berserker Stance" then
        RubimRH.Rotation.stance = 3
    end
    if RubimRH and RubimRH.RestoreAfterHeal then
        RubimRH.RestoreAfterHeal(true)
    end
    if name == "Slice and Dice" then
        HL.State.buffs[name] = now + 6 + 3 * math.max(1, record and record.combo or HL.State.combo or 0)
    end
    if sameTarget then
        if finishers[name] then
            HL.State.combo = 0
            HL.State.lastComboBuildAt = nil
        elseif builders[name] then
            local ok, points = pcall(GetComboPoints, "player", "target")
            points = ok and HL.SafeNumber(points, nil) or nil
            HL.State.combo = points or math.min(5, HL.State.combo + builders[name])
            HL.State.lastComboBuildAt = now
        end
    end
    HL.State.lastCast = name
    HL.State.lastCastAt = now
    table.insert(HL.State.casts, 1, { name = name, id = id, at = now })
    while #HL.State.casts > 5 do
        table.remove(HL.State.casts)
    end
    local cd = HeroDBC.Cooldowns[HeroDBC.CompactName and HeroDBC.CompactName(name) or name:gsub("[%s']", "")]
    if name and cd then
        HL.State.cooldowns[name] = now + cd
    end
    if name == "Earth Shock" or name == "Flame Shock" or name == "Frost Shock" then
        for _, shock in ipairs({ "Earth Shock", "Flame Shock", "Frost Shock" }) do
            HL.State.cooldowns[shock] = now + 6
        end
    end
    HL.InvalidateAuras()
end)
