local RH = RubimRH
RH.UniversalIcons = { 133667, 133663, 133658, 133653, 133650, 133648, 133646, 133643, 133639, 133632 }

local function ClassToken()
    return select(2, UnitClass("player")) or "ROGUE"
end
local function canonicalName(name)
    -- Forever uses both Agony names across spellbook versions. Keep one setting.
    if name == "Curse of Agony" and ClassToken() == "WARLOCK" then
        return "Bane of Agony"
    end
    return name
end
function RH.IconChoice(name)
    name = canonicalName(name)
    if name == "Attack" then
        name = "StartAttack"
    end
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local db = RH.EnsureDB()
    local map = db.iconMappings and db.iconMappings[ClassToken()]
    if type(map) ~= "table" then
        return nil
    end
    local choice = map and tonumber(map[name])
    if choice and choice >= 1 and choice <= #RH.UniversalIcons then
        return choice
    end
end
function RH.SetIconChoice(name, choice)
    if type(name) ~= "string" or name == "" then
        return
    end
    if name == "Attack" then
        name = "StartAttack"
    end
    local db = RH.EnsureDB()
    local token = ClassToken()
    if type(db.iconMappings[token]) ~= "table" then
        db.iconMappings[token] = {}
    end
    choice = tonumber(choice)
    db.iconMappings[token][name] = choice and choice >= 1 and choice <= #RH.UniversalIcons and choice or nil
end
function RH.OutputTexture(name, defaultTexture)
    if name == "Attack" then
        name = "StartAttack"
    end
    local choice = RH.IconChoice(name)
    return choice and RH.UniversalIcons[choice] or defaultTexture
end
function RH.AbilityEnabled(name)
    name = canonicalName(name)
    if name == "Attack" then
        name = "StartAttack"
    end
    if type(name) ~= "string" or name == "" then
        return true
    end
    local db = RH.EnsureDB()
    local map = db.abilityDisabled and db.abilityDisabled[ClassToken()]
    if type(map) ~= "table" then
        return true
    end
    return not (map and map[name] == true)
end
function RH.SetAbilityEnabled(name, enabled)
    if type(name) ~= "string" or name == "" then
        return
    end
    local db = RH.EnsureDB()
    local token = ClassToken()
    if type(db.abilityDisabled[token]) ~= "table" then
        db.abilityDisabled[token] = {}
    end
    db.abilityDisabled[token][name] = enabled == false and true or nil
end

-- The catalogue is deliberately data-only.  It documents what NextCast can
-- reason about without attempting to cast, create macros, or register combat
-- log events.  Rank-one IDs are icon fallbacks; name lookup still wins on
-- Forever where spell IDs may differ from Classic.
RH.Abilities = {
    ROGUE = {
        { 6603, "StartAttack", "Opener" },
        { 1752, "Sinister Strike", "Rotation" },
        { 2098, "Eviscerate", "Rotation" },
        { 1784, "Stealth", "Opener" },
        { 53, "Backstab", "Rotation" },
        { 6770, "Sap", "Opener" },
        { 8676, "Ambush", "Opener" },
        { 703, "Garrote", "Opener" },
        { 1833, "Cheap Shot", "PvP" },
        { 5171, "Slice and Dice", "Finisher" },
        { 1943, "Rupture", "Finisher" },
        { 8647, "Expose Armor", "Finisher" },
        { 408, "Kidney Shot", "PvP" },
        { 1766, "Kick", "Interrupt" },
        { 1776, "Gouge", "Defensive" },
        { 1966, "Feint", "Defensive" },
        { 14251, "Riposte", "Proc" },
        { 5277, "Evasion", "Defensive" },
        { 2983, "Sprint", "Utility" },
        { 1856, "Vanish", "Defensive" },
        { 13877, "Blade Flurry", "Cooldown" },
        { 14177, "Cold Blood", "Cooldown" },
        { 14278, "Ghostly Strike", "Talent" },
        { 16511, "Hemorrhage", "Talent" },
        { 1329, "Mutilate", "Talent" },
    },
    WARRIOR = {
        { 6603, "StartAttack", "Opener" },
        { 78, "Heroic Strike", "Rage dump" },
        { 6673, "Battle Shout", "Buff" },
        { 2457, "Battle Stance", "Stance" },
        { 100, "Charge", "Opener" },
        { 772, "Rend", "Rotation" },
        { 6343, "Thunder Clap", "AoE" },
        { 1715, "Hamstring", "PvP" },
        { 2687, "Bloodrage", "Resource" },
        { 7386, "Sunder Armor", "Rotation" },
        { 355, "Taunt", "Tank" },
        { 71, "Defensive Stance", "Stance" },
        { 7384, "Overpower", "Proc" },
        { 72, "Shield Bash", "Interrupt" },
        { 6572, "Revenge", "Tank" },
        { 1160, "Demoralizing Shout", "Tank" },
        { 694, "Mocking Blow", "Tank" },
        { 2565, "Shield Block", "Tank" },
        { 676, "Disarm", "Utility" },
        { 845, "Cleave", "AoE" },
        { 20230, "Retaliation", "Cooldown" },
        { 402927, "Victory Rush", "Proc" },
        { 1464, "Slam", "Rotation" },
        { 5246, "Intimidating Shout", "Utility" },
        { 5308, "Execute", "Finisher" },
        { 1161, "Challenging Shout", "Tank" },
        { 871, "Shield Wall", "Defensive" },
        { 2458, "Berserker Stance", "Stance" },
        { 18499, "Berserker Rage", "Cooldown" },
        { 1680, "Whirlwind", "AoE" },
        { 20252, "Intercept", "Mobility" },
        { 12292, "Sweeping Strikes", "Cooldown" },
        { 12294, "Mortal Strike", "Talent" },
        { 12328, "Death Wish", "Talent" },
        { 12975, "Last Stand", "Talent" },
        { 12809, "Concussion Blow", "Talent" },
        { 23881, "Bloodthirst", "Talent" },
        { 23922, "Shield Slam", "Talent" },
        { 1310222, "Spearing Strike", "Forever" },
    },
    PALADIN = {
        { 6603, "StartAttack", "Opener" },
        { 635, "Holy Light", "Healing" },
        { 19750, "Flash of Light", "Healing" },
        { 20473, "Holy Shock", "Healing" },
        { 633, "Lay on Hands", "Emergency" },
        { 1152, "Purify", "Dispel" },
        { 20271, "Judgement", "Rotation" },
        { 0, "Holy Strike", "Forever" },
        { 879, "Exorcism", "Rotation" },
        { 26573, "Consecration", "AoE" },
        { 853, "Hammer of Justice", "Control" },
        { 21084, "Seal of Righteousness", "Seal" },
        { 20375, "Seal of Command", "Seal" },
        { 20166, "Seal of Wisdom", "Seal" },
        { 20165, "Seal of Light", "Seal" },
        { 19740, "Blessing of Might", "Blessing" },
        { 19742, "Blessing of Wisdom", "Blessing" },
        { 20217, "Blessing of Kings", "Blessing" },
        { 465, "Devotion Aura", "Aura" },
        { 7294, "Retribution Aura", "Aura" },
        { 19746, "Concentration Aura", "Aura" },
        { 25780, "Righteous Fury", "Tank" },
        { 20925, "Holy Shield", "Tank" },
        { 498, "Divine Protection", "Defensive" },
        { 642, "Divine Shield", "Defensive" },
        { 0, "Templar's Bulwark", "Forever" },
        { 0, "Light's Vigil", "Forever" },
        { 0, "Voice of Truth", "Forever" },
    },
    HUNTER = {
        { 6603, "StartAttack", "Opener" },
        { 75, "Auto Shot", "Rotation" },
        { 2973, "Raptor Strike", "Melee" },
        { 1978, "Serpent Sting", "Rotation" },
        { 13163, "Aspect of the Monkey", "Aspect" },
        { 3044, "Arcane Shot", "Rotation" },
        { 1130, "Hunter's Mark", "Rotation" },
        { 5116, "Concussive Shot", "Control" },
        { 13165, "Aspect of the Hawk", "Aspect" },
        { 883, "Call Pet", "Pet" },
        { 982, "Revive Pet", "Pet" },
        { 136, "Mend Pet", "Pet" },
        { 2974, "Wing Clip", "PvP" },
        { 1495, "Mongoose Bite", "Proc" },
        { 2643, "Multi-Shot", "AoE" },
        { 3045, "Rapid Fire", "Cooldown" },
        { 19434, "Aimed Shot", "Talent" },
        { 19503, "Scatter Shot", "Interrupt" },
        { 19577, "Intimidation", "Interrupt" },
        { 13813, "Explosive Trap", "AoE" },
    },
    MAGE = {
        { 116, "Frostbolt", "Rotation" },
        { 133, "Fireball", "Rotation" },
        { 2136, "Fire Blast", "Rotation" },
        { 122, "Frost Nova", "Control" },
        { 120, "Cone of Cold", "AoE" },
        { 1449, "Arcane Explosion", "AoE" },
        { 5143, "Arcane Missiles", "Rotation" },
        { 2948, "Scorch", "Rotation" },
        { 11366, "Pyroblast", "Talent" },
        { 10, "Blizzard", "AoE" },
        { 12051, "Evocation", "Resource" },
        { 1459, "Arcane Intellect", "Buff" },
        { 168, "Frost Armor", "Buff" },
        { 2139, "Counterspell", "Interrupt" },
        { 118, "Polymorph", "Control" },
        { 1953, "Blink", "Mobility" },
        { 45438, "Ice Block", "Defensive" },
        { 5019, "Shoot", "Fallback" },
        { 30455, "Ice Lance", "Rotation" },
        { 0, "Arcane Blast", "Forever" },
    },
    PRIEST = {
        { 17, "Power Word: Shield", "Absorb" },
        { 139, "Renew", "Healing over time" },
        { 2050, "Lesser Heal", "Direct heal" },
        { 2054, "Heal", "Direct heal" },
        { 2060, "Greater Heal", "Direct heal" },
        { 2061, "Flash Heal", "Emergency heal" },
        { 596, "Prayer of Healing", "Group heal" },
        { 589, "Shadow Word: Pain", "Rotation" },
        { 8092, "Mind Blast", "Rotation" },
        { 15407, "Mind Flay", "Rotation" },
        { 585, "Smite", "Rotation" },
        { 14914, "Holy Fire", "Rotation" },
        { 8122, "Psychic Scream", "Control" },
        { 1243, "Power Word: Fortitude", "Buff" },
        { 588, "Inner Fire", "Buff" },
        { 527, "Dispel Magic", "Utility" },
        { 5019, "Shoot", "Fallback" },
        { 0, "Penance", "Forever heal" },
        { 0, "Prayer of Mending", "Forever heal" },
        { 0, "Binding Heal", "Forever heal" },
        { 13908, "Desperate Prayer", "Self heal" },
        { 15237, "Holy Nova", "Group heal" },
    },
    SHAMAN = {
        { 6603, "StartAttack", "Opener" },
        { 331, "Healing Wave", "Direct heal" },
        { 8004, "Lesser Healing Wave", "Emergency heal" },
        { 1064, "Chain Heal", "Group heal" },
        { 5394, "Healing Stream Totem", "Group heal" },
        { 16188, "Nature's Swiftness", "Emergency cooldown" },
        { 16190, "Mana Tide Totem", "Mana cooldown" },
        { 403, "Lightning Bolt", "Rotation" },
        { 421, "Chain Lightning", "AoE" },
        { 8050, "Flame Shock", "Rotation" },
        { 8042, "Earth Shock", "Interrupt" },
        { 8056, "Frost Shock", "PvP" },
        { 324, "Lightning Shield", "Buff" },
        { 17364, "Stormstrike", "Talent" },
        { 3599, "Searing Totem", "Totem" },
        { 8190, "Magma Totem", "AoE" },
        { 1535, "Fire Nova Totem", "AoE" },
        { 8024, "Flametongue Weapon", "Weapon" },
        { 8017, "Rockbiter Weapon", "Weapon" },
        { 8232, "Windfury Weapon", "Weapon" },
        { 8143, "Tremor Totem", "Utility" },
        { 8177, "Grounding Totem", "PvP" },
        { 370, "Purge", "Utility" },
        { 0, "Lava Burst", "Forever" },
        { 0, "Water Shield", "Forever" },
        { 0, "Riptide", "Forever heal" },
        { 0, "Fire Nova", "Forever" },
    },
    WARLOCK = {
        { 686, "Shadow Bolt", "Rotation" },
        { 172, "Corruption", "Rotation" },
        { 348, "Immolate", "Rotation" },
        { 980, "Bane of Agony", "Rotation" },
        { 1454, "Life Tap", "Resource" },
        { 689, "Drain Life", "Healing" },
        { 1120, "Drain Soul", "Resource" },
        { 18265, "Siphon Life", "Talent" },
        { 5782, "Fear", "Control" },
        { 5484, "Howl of Terror", "Control" },
        { 5740, "Rain of Fire", "AoE" },
        { 17962, "Conflagrate", "Talent" },
        { 687, "Demon Skin", "Buff" },
        { 706, "Demon Armor", "Buff" },
        { 688, "Summon Imp", "Pet" },
        { 697, "Summon Voidwalker", "Pet" },
        { 712, "Summon Succubus", "Pet" },
        { 5019, "Shoot", "Fallback" },
        { 0, "Incinerate", "Forever" },
        { 0, "Wrack", "Forever" },
        { 0, "Bane of Havoc", "Forever" },
    },
    DRUID = {
        { 6603, "StartAttack", "Opener" },
        { 5185, "Healing Touch", "Direct heal" },
        { 774, "Rejuvenation", "Healing over time" },
        { 8936, "Regrowth", "Emergency heal" },
        { 18562, "Swiftmend", "Instant heal" },
        { 33763, "Lifebloom", "Healing over time" },
        { 0, "Wild Growth", "Forever group heal" },
        { 740, "Tranquility", "Group cooldown" },
        { 17116, "Nature's Swiftness", "Emergency cooldown" },
        { 29166, "Innervate", "Mana cooldown" },
        { 8921, "Moonfire", "Rotation" },
        { 5176, "Wrath", "Rotation" },
        { 2912, "Starfire", "Rotation" },
        { 5570, "Insect Swarm", "Talent" },
        { 16914, "Hurricane", "AoE" },
        { 6807, "Maul", "Bear" },
        { 6795, "Growl", "Tank" },
        { 99, "Demoralizing Roar", "Bear" },
        { 16689, "Nature's Grasp", "Defensive" },
        { 5229, "Enrage", "Bear" },
        { 1082, "Claw", "Cat" },
        { 1822, "Rake", "Cat" },
        { 1079, "Rip", "Finisher" },
        { 22568, "Ferocious Bite", "Finisher" },
        { 5221, "Shred", "Cat" },
        { 779, "Swipe", "AoE" },
        { 5211, "Bash", "Interrupt" },
        { 16979, "Feral Charge", "Talent" },
        { 339, "Entangling Roots", "Control" },
        { 770, "Faerie Fire", "Utility" },
        { 5217, "Tiger's Fury", "Cooldown" },
        { 1126, "Mark of the Wild", "Buff" },
        { 467, "Thorns", "Buff" },
        { 768, "Cat Form", "Form" },
        { 5487, "Bear Form", "Form" },
        { 5215, "Prowl", "Opener" },
        { 1850, "Dash", "Utility" },
        { 5209, "Challenging Roar", "Tank" },
        { 0, "Mangle", "Forever" },
        { 0, "Lacerate", "Forever" },
    },
}

function RH.AbilityStatus(entry)
    local id, name = entry[1], entry[2]
    if name == "StartAttack" or name == "Attack" then
        return true, RH.StartAttackTexture and RH.StartAttackTexture() or "Interface\\Icons\\Ability_MeleeDamage"
    end
    local spell = RH.Named(name, id and id > 0 and id or nil)
    return spell:IsAvailable(), spell:Texture()
end
