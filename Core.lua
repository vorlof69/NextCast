RubimRH = RubimRH or { Rotation = { APLs = {} }, CDs = true, AoE = false, Interrupts = true }
local RH = RubimRH
NextCast = RH
local defaults = {
    enabled = true,
    locked = false,
    x = 0,
    y = 0,
    scale = 1,
    healing = true,
    healMouseover = true,
    defensives = true,
    mode = "auto",
    spec = "",
    specMode = "auto",
    uiMode = "simple",
    cooldowns = true,
    interrupts = true,
    minimapAngle = 225,
    manaReserve = 25,
    dotMinTTD = 8,
    emergencyHealHP = 35,
    efficientHealHP = 70,
    defensiveHP = 30,
    healRole = "auto",
    preset = "auto",
    maintainBuffs = true,
    useDots = true,
    resourceLogic = true,
    rogueEvis = true,
    rogueSnD = true,
    rogueRupture = true,
    rogueGouge = true,
    rogueEvasion = true,
    rogueStealth = true,
    rogueSap = true,
    rogueOpener = "auto",
    evisCP = 5,
    rogueContext = "auto",
    stealthRange = 25,
    sndMinTTD = 21,
    ruptureMinTTD = 18,
    evasionHP = 35,
    gougeHP = 50,
    kidneyCP = 4,
    rogueCooldownCP = 4,
    warriorRend = true,
    warriorShout = true,
    warriorSunder = true,
    warriorVictory = true,
    warriorDefensives = true,
    warriorTaunt = true,
    warriorSlam = true,
    heroicRage = 60,
    cleaveRage = 40,
    sunderStacks = 2,
    tankSunderStacks = 5,
    slamRage = 30,
    sweepingRage = 50,
    shieldWallHP = 35,
    warriorContext = "auto",
    paladinBlessings = true,
    paladinAuras = true,
    paladinSeals = true,
    paladinHealing = true,
    paladinDefensives = true,
    paladinTaunt = true,
    paladinGroupHeals = true,
    paladinHolyShock = true,
    paladinLayOnHands = true,
    paladinContext = "auto",
    paladinConsecrationMana = 45,
    paladinFlashHP = 55,
    paladinHolyLightHP = 80,
    paladinGroupHP = 75,
    paladinGroupCount = 3,
    hunterContext = "auto",
    hunterPet = true,
    hunterPetHealHP = 65,
    hunterArcaneMana = 25,
    hunterMultiMana = 35,
    hunterConcussive = true,
    mageContext = "auto",
    mageControl = true,
    mageEvocationMana = 15,
    mageAoEMana = 40,
    mageFireBlastHP = 25,
    priestContext = "auto",
    priestShieldHP = 65,
    priestRenewHP = 88,
    priestGroupHeals = true,
    priestEmergencyHeals = true,
    priestHoTs = true,
    priestPenanceHP = 40,
    priestFlashHP = 50,
    priestGroupHP = 75,
    priestGroupCount = 3,
    shamanContext = "auto",
    shamanTotems = true,
    shamanTotemMana = 40,
    shamanAoEMana = 35,
    shamanGroupHeals = true,
    shamanEmergencyHeals = true,
    shamanHoTs = true,
    shamanRiptideHP = 85,
    shamanChainHP = 75,
    shamanChainCount = 3,
    shamanManaTideMana = 20,
    warlockContext = "auto",
    warlockPet = true,
    warlockLifeTapMana = 25,
    warlockDrainLifeHP = 45,
    druidContext = "auto",
    druidProwl = true,
    druidTigerEnergy = 40,
    druidRakeTTD = 8,
    druidRipTTD = 12,
    druidHoTs = true,
    druidDirectHeals = true,
    druidGroupHeals = true,
    druidSwiftmend = true,
    druidNatureSwiftness = true,
    druidRejuvenationHP = 88,
    druidRegrowthHP = 55,
    druidSwiftmendHP = 50,
    druidWildGrowthHP = 80,
    druidWildGrowthCount = 3,
    druidInnervateMana = 20,
    priestDispel = true,
    paladinDispel = true,
    shamanDispel = true,
    druidDispel = true,
    specByClass = {},
    classProfiles = {},
    iconMappings = {},
    abilityDisabled = {},
    burst = false,
    configVersion = 30,
}
local validSpecs = {
    ROGUE = { Assassination = true, Combat = true, Subtlety = true },
    WARRIOR = { Arms = true, Fury = true, Protection = true },
    PALADIN = { Retribution = true, Protection = true, Holy = true },
    HUNTER = { ["Beast Mastery"] = true, Marksmanship = true, Survival = true },
    MAGE = { Frost = true, Fire = true, Arcane = true },
    PRIEST = { Shadow = true, Discipline = true, Holy = true },
    SHAMAN = { Enhancement = true, Elemental = true, Restoration = true },
    WARLOCK = { Affliction = true, Demonology = true, Destruction = true },
    DRUID = { Feral = true, Balance = true, Restoration = true },
}
local defaultSpecs = {
    ROGUE = "Combat",
    WARRIOR = "Arms",
    PALADIN = "Retribution",
    HUNTER = "Beast Mastery",
    MAGE = "Frost",
    PRIEST = "Shadow",
    SHAMAN = "Enhancement",
    WARLOCK = "Affliction",
    DRUID = "Feral",
}
local initializedDB, detectedSpec, detectSpecAt, activeProfileClass
local profileGlobal = {
    enabled = true,
    locked = true,
    x = true,
    y = true,
    scale = true,
    uiMode = true,
    minimapAngle = true,
    configVersion = true,
    spec = true,
    specByClass = true,
    classProfiles = true,
    classProfileSeed = true,
    iconMappings = true,
    abilityDisabled = true,
    position = true,
    menuPosition = true,
}
local function copyProfile(source, target)
    for key, default in pairs(defaults) do
        if not profileGlobal[key] and type(default) ~= "table" then
            local value = source[key]
            target[key] = value == nil and default or value
        end
    end
end
local numericLimits = {
    scale = { 0.6, 2 },
    stealthRange = { 10, 30 },
    evisCP = { 1, 5 },
    kidneyCP = { 1, 5 },
    rogueCooldownCP = { 1, 5 },
    sunderStacks = { 0, 5 },
    tankSunderStacks = { 0, 5 },
    paladinGroupCount = { 2, 5 },
    priestGroupCount = { 2, 5 },
    shamanChainCount = { 2, 5 },
    druidWildGrowthCount = { 2, 5 },
}
local function normalize(db)
    for key, default in pairs(defaults) do
        if type(default) == "number" then
            local value = tonumber(db[key])
            if not value or value ~= value or value == math.huge or value == -math.huge then
                value = default
            end
            local bounds = numericLimits[key]
            if bounds then
                value = math.max(bounds[1], math.min(bounds[2], value))
            elseif key ~= "x" and key ~= "y" and key ~= "configVersion" and key ~= "minimapAngle" then
                value = math.max(0, math.min(100, value))
            end
            db[key] = value
        elseif type(default) == "table" then
            if type(db[key]) ~= "table" then
                db[key] = {}
            end
        elseif type(db[key]) ~= type(default) then
            db[key] = default
        end
    end
    if db.mode ~= "auto" and db.mode ~= "single" and db.mode ~= "aoe" then
        db.mode = "auto"
    end
    if db.uiMode ~= "advanced" then
        db.uiMode = "simple"
    end
    if db.specMode ~= "manual" then
        db.specMode = "auto"
    end
    if db.healRole ~= "healer" and db.healRole ~= "tank" and db.healRole ~= "dps" then
        db.healRole = "auto"
    end
    -- Overview no longer exposes role presets — spec + form decide the kit.
    if db.preset ~= "auto" then
        db.healRole = "auto"
        db.preset = "auto"
    end
    if
        db.preset ~= "dps"
        and db.preset ~= "tank"
        and db.preset ~= "healer"
        and db.preset ~= "pvp"
        and db.preset ~= "reset"
    then
        db.preset = "auto"
    end
end
function RH.EnsureDB()
    if type(NextCastDB) ~= "table" then
        NextCastDB = type(RubimRHDB) == "table" and RubimRHDB or {}
    end
    RubimRHDB = NextCastDB
    if initializedDB ~= NextCastDB then
        activeProfileClass = nil
        normalize(NextCastDB)
        for k, v in pairs(defaults) do
            if NextCastDB[k] == nil then
                NextCastDB[k] = type(v) == "table" and {} or v
            end
        end
        if (NextCastDB.configVersion or 0) < 2 then
            NextCastDB.rogueStealth = true
            NextCastDB.rogueContext = "auto"
            NextCastDB.configVersion = 2
        end
        if (NextCastDB.configVersion or 0) < 3 then
            NextCastDB.rogueStealth = true
            NextCastDB.rogueSap = true
            NextCastDB.configVersion = 3
        end
        if (NextCastDB.configVersion or 0) < 4 then
            NextCastDB.warriorRend = true
            NextCastDB.warriorShout = true
            NextCastDB.warriorSunder = true
            NextCastDB.warriorVictory = true
            NextCastDB.warriorDefensives = true
            NextCastDB.heroicRage = 60
            NextCastDB.configVersion = 4
        end
        if (NextCastDB.configVersion or 0) < 5 then
            NextCastDB.evisCP = 5
            NextCastDB.configVersion = 5
        end
        if (NextCastDB.configVersion or 0) < 6 then
            NextCastDB.paladinBlessings = true
            NextCastDB.paladinAuras = true
            NextCastDB.paladinSeals = true
            NextCastDB.paladinHealing = true
            NextCastDB.paladinDefensives = true
            NextCastDB.configVersion = 6
        end
        if type(NextCastDB.specByClass) ~= "table" then
            NextCastDB.specByClass = {}
        end
        if (NextCastDB.configVersion or 0) < 7 then
            NextCastDB.configVersion = 7
        end
        if (NextCastDB.configVersion or 0) < 8 then
            NextCastDB.warriorContext = "auto"
            NextCastDB.paladinContext = "auto"
            if NextCastDB.mode ~= "single" and NextCastDB.mode ~= "aoe" then
                NextCastDB.mode = "auto"
            end
            NextCastDB.configVersion = 8
        end
        if (NextCastDB.configVersion or 0) < 9 then
            NextCastDB.cleaveRage = 40
            NextCastDB.configVersion = 9
        end
        if (NextCastDB.configVersion or 0) < 10 then
            NextCastDB.stealthRange = 25
            NextCastDB.configVersion = 10
        end
        if (NextCastDB.configVersion or 0) < 11 then
            for _, c in ipairs({ "hunter", "mage", "priest", "shaman", "warlock", "druid" }) do
                if NextCastDB[c .. "Context"] == nil then
                    NextCastDB[c .. "Context"] = "auto"
                end
            end
            NextCastDB.configVersion = 11
        end
        if (NextCastDB.configVersion or 0) < 12 then
            NextCastDB.warriorTaunt = true
            NextCastDB.warriorSlam = true
            NextCastDB.sunderStacks = 2
            NextCastDB.tankSunderStacks = 5
            NextCastDB.slamRage = 30
            NextCastDB.sweepingRage = 50
            NextCastDB.shieldWallHP = 35
            NextCastDB.configVersion = 12
        end
        if type(NextCastDB.iconMappings) ~= "table" then
            NextCastDB.iconMappings = {}
        end
        if (NextCastDB.configVersion or 0) < 13 then
            NextCastDB.configVersion = 13
        end
        if (NextCastDB.configVersion or 0) < 14 then
            if NextCastDB.enabled == nil then
                NextCastDB.enabled = true
            end
            NextCastDB.configVersion = 14
        end
        if type(NextCastDB.abilityDisabled) ~= "table" then
            NextCastDB.abilityDisabled = {}
        end
        if (NextCastDB.configVersion or 0) < 15 then
            NextCastDB.configVersion = 15
        end
        if (NextCastDB.configVersion or 0) < 16 then
            NextCastDB.uiMode = "simple"
            NextCastDB.configVersion = 16
        end
        if (NextCastDB.configVersion or 0) < 17 then
            NextCastDB.specMode = "auto"
            NextCastDB.configVersion = 17
        end
        if (NextCastDB.configVersion or 0) < 18 then
            NextCastDB.manaReserve = 25
            NextCastDB.dotMinTTD = 8
            NextCastDB.configVersion = 18
        end
        if (NextCastDB.configVersion or 0) < 19 then
            NextCastDB.emergencyHealHP = 35
            NextCastDB.efficientHealHP = 70
            NextCastDB.defensiveHP = 30
            NextCastDB.maintainBuffs = true
            NextCastDB.useDots = true
            NextCastDB.resourceLogic = true
            NextCastDB.configVersion = 19
        end
        if (NextCastDB.configVersion or 0) < 20 then
            NextCastDB.sndMinTTD = 21
            NextCastDB.ruptureMinTTD = 18
            NextCastDB.evasionHP = 35
            NextCastDB.gougeHP = 50
            NextCastDB.kidneyCP = 4
            NextCastDB.rogueCooldownCP = 4
            NextCastDB.configVersion = 20
        end
        if (NextCastDB.configVersion or 0) < 21 then
            NextCastDB.paladinConsecrationMana = 45
            NextCastDB.hunterPet = true
            NextCastDB.hunterPetHealHP = 65
            NextCastDB.hunterArcaneMana = 25
            NextCastDB.hunterMultiMana = 35
            NextCastDB.mageEvocationMana = 15
            NextCastDB.mageAoEMana = 40
            NextCastDB.mageFireBlastHP = 25
            NextCastDB.priestShieldHP = 65
            NextCastDB.priestRenewHP = 88
            NextCastDB.shamanTotems = true
            NextCastDB.shamanTotemMana = 40
            NextCastDB.shamanAoEMana = 35
            NextCastDB.warlockPet = true
            NextCastDB.warlockLifeTapMana = 25
            NextCastDB.warlockDrainLifeHP = 45
            NextCastDB.druidProwl = true
            NextCastDB.druidTigerEnergy = 40
            NextCastDB.druidRakeTTD = 8
            NextCastDB.druidRipTTD = 12
            NextCastDB.configVersion = 21
        end
        if (NextCastDB.configVersion or 0) < 22 then
            NextCastDB.rogueOpener = "auto"
            NextCastDB.configVersion = 22
        end
        if (NextCastDB.configVersion or 0) < 23 then
            NextCastDB.mageControl = true
            NextCastDB.configVersion = 23
        end
        if (NextCastDB.configVersion or 0) < 24 then
            NextCastDB.classProfiles = {}
            NextCastDB.classProfileSeed = nil
            NextCastDB.configVersion = 24
        end
        if (NextCastDB.configVersion or 0) < 25 then
            NextCastDB.druidHoTs = true
            NextCastDB.druidDirectHeals = true
            NextCastDB.druidGroupHeals = true
            NextCastDB.druidSwiftmend = true
            NextCastDB.druidNatureSwiftness = true
            NextCastDB.druidRejuvenationHP = 88
            NextCastDB.druidRegrowthHP = 55
            NextCastDB.druidSwiftmendHP = 50
            NextCastDB.druidWildGrowthHP = 80
            NextCastDB.druidWildGrowthCount = 3
            NextCastDB.druidInnervateMana = 20
            NextCastDB.configVersion = 25
        end
        if (NextCastDB.configVersion or 0) < 26 then
            NextCastDB.paladinGroupHeals = true
            NextCastDB.paladinHolyShock = true
            NextCastDB.paladinLayOnHands = true
            NextCastDB.paladinFlashHP = 55
            NextCastDB.paladinHolyLightHP = 80
            NextCastDB.paladinGroupHP = 75
            NextCastDB.paladinGroupCount = 3
            NextCastDB.priestGroupHeals = true
            NextCastDB.priestEmergencyHeals = true
            NextCastDB.priestHoTs = true
            NextCastDB.priestPenanceHP = 40
            NextCastDB.priestFlashHP = 50
            NextCastDB.priestGroupHP = 75
            NextCastDB.priestGroupCount = 3
            NextCastDB.shamanGroupHeals = true
            NextCastDB.shamanEmergencyHeals = true
            NextCastDB.shamanHoTs = true
            NextCastDB.shamanRiptideHP = 85
            NextCastDB.shamanChainHP = 75
            NextCastDB.shamanChainCount = 3
            NextCastDB.shamanManaTideMana = 20
            NextCastDB.configVersion = 26
        end
        if (NextCastDB.configVersion or 0) < 27 then
            NextCastDB.priestDispel = true
            NextCastDB.paladinDispel = true
            NextCastDB.shamanDispel = true
            NextCastDB.druidDispel = true
            NextCastDB.configVersion = 27
        end
        if (NextCastDB.configVersion or 0) < 30 then
            local classes = { "ROGUE", "WARRIOR", "PALADIN", "HUNTER", "MAGE", "PRIEST", "SHAMAN", "WARLOCK", "DRUID" }
            for _, c in ipairs(classes) do
                local map = NextCastDB.iconMappings and NextCastDB.iconMappings[c]
                if type(map) == "table" and map.StartAttack == 1 then
                    map.StartAttack = nil
                end
            end
            NextCastDB.configVersion = 30
        end
        if
            NextCastDB.rogueOpener ~= "auto"
            and NextCastDB.rogueOpener ~= "ambush"
            and NextCastDB.rogueOpener ~= "garrote"
            and NextCastDB.rogueOpener ~= "cheap"
        then
            NextCastDB.rogueOpener = "auto"
        end
        initializedDB = NextCastDB
        detectSpecAt = nil
    end
    local class = select(2, UnitClass("player"))
    local valid = validSpecs[class]
    if activeProfileClass ~= class then
        if activeProfileClass and NextCastDB.classProfiles[activeProfileClass] then
            copyProfile(NextCastDB, NextCastDB.classProfiles[activeProfileClass])
        end
        local profile = NextCastDB.classProfiles[class]
        if type(profile) ~= "table" then
            profile = {}
            NextCastDB.classProfiles[class] = profile
            if not NextCastDB.classProfileSeed then
                copyProfile(NextCastDB, profile)
                NextCastDB.classProfileSeed = class
            else
                copyProfile(defaults, profile)
            end
        end
        copyProfile(profile, NextCastDB)
        activeProfileClass = class
        detectedSpec = nil
        detectSpecAt = nil
    end
    if valid then
        if not valid[NextCastDB.specByClass[class]] then
            NextCastDB.specByClass[class] = valid[NextCastDB.spec] and NextCastDB.spec or defaultSpecs[class]
        end
        local active = NextCastDB.specByClass[class]
        if NextCastDB.specMode == "auto" and GetTalentTabInfo then
            if not detectSpecAt or GetTime() - detectSpecAt >= 1 then
                local names = ({
                    ROGUE = { "Assassination", "Combat", "Subtlety" },
                    WARRIOR = { "Arms", "Fury", "Protection" },
                    PALADIN = { "Holy", "Protection", "Retribution" },
                    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
                    MAGE = { "Arcane", "Fire", "Frost" },
                    PRIEST = { "Discipline", "Holy", "Shadow" },
                    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
                    WARLOCK = { "Affliction", "Demonology", "Destruction" },
                    DRUID = { "Balance", "Feral", "Restoration" },
                })[class]
                local bestPoints, bestIndex = 0, nil
                for i = 1, 3 do
                    local points = 0
                    if GetNumTalents and GetTalentInfo then
                        local okN, n = pcall(GetNumTalents, i)
                        n = okN and HeroLib.SafeNumber(n, 0) or 0
                        for t = 1, n do
                            local okT, _, _, _, _, rank = pcall(GetTalentInfo, i, t)
                            points = points + (okT and HeroLib.SafeNumber(rank, 0) or 0)
                        end
                    end
                    if points == 0 then
                        local ok, _, _, spent = pcall(GetTalentTabInfo, i)
                        points = ok and HeroLib.SafeNumber(spent, 0) or 0
                    end
                    if points > bestPoints then
                        bestPoints, bestIndex = points, i
                    end
                end
                detectedSpec = bestIndex and names and names[bestIndex] or nil
                detectSpecAt = GetTime()
            end
            active = detectedSpec or active
        end
        NextCastDB.spec = active
    end
    copyProfile(NextCastDB, NextCastDB.classProfiles[class])
    RH.CDs = NextCastDB.cooldowns ~= false
    RH.AoE = NextCastDB.mode == "aoe"
        or (NextCastDB.mode == "auto" and RH.CountNearbyEnemies and RH.CountNearbyEnemies() >= 3)
    RH.Interrupts = NextCastDB.interrupts ~= false
    RH.Burst = NextCastDB.burst == true
    return NextCastDB
end

function RH.ContextKey()
    local class = select(2, UnitClass("player")) or "ROGUE"
    return string.lower(class) .. "Context"
end

function RH.ResetClassProfile()
    local db = RH.EnsureDB()
    for key, default in pairs(defaults) do
        if not profileGlobal[key] then
            db[key] = default
        end
    end
    db.healRole = "auto"
    db.preset = "auto"
    normalize(db)
    return db
end

function RH.ApplyPreset(id)
    local db = RH.EnsureDB()
    local ctx = RH.ContextKey()
    if id == "reset" then
        return RH.ResetClassProfile()
    end
    if id == "dps" then
        db.healRole = "dps"
        db[ctx] = "pve"
        db.healing = true
        db.emergencyHealHP = 35
        db.efficientHealHP = 70
        db.defensiveHP = 30
        db.defensives = true
        db.interrupts = true
    elseif id == "tank" then
        db.healRole = "tank"
        db[ctx] = "pve"
        db.healing = true
        db.emergencyHealHP = 32
        db.efficientHealHP = 55
        db.defensiveHP = 40
        db.defensives = true
        db.interrupts = true
    elseif id == "healer" then
        db.healRole = "healer"
        db[ctx] = "pve"
        db.healing = true
        db.emergencyHealHP = 35
        db.efficientHealHP = 75
        db.defensiveHP = 30
        db.defensives = true
        db.resourceLogic = true
    elseif id == "pvp" then
        db[ctx] = "pvp"
        db.emergencyHealHP = 42
        db.defensiveHP = 40
        db.defensives = true
        db.interrupts = true
        db.healing = true
    else
        db.healRole = "auto"
        db[ctx] = "auto"
        db.preset = "auto"
        return db
    end
    db.preset = id
    normalize(db)
    return db
end

function RH.SetSpec(name)
    local db = RH.EnsureDB()
    local class = select(2, UnitClass("player"))
    if name == "Automatic" then
        db.specMode = "auto"
    else
        db.specMode = "manual"
        db.spec = name
        db.specByClass[class] = name
    end
    RH.EnsureDB()
end
function RH.Rotation.SetAPL(classID, apl)
    if type(classID) == "number" and type(apl) == "function" then
        RH.Rotation.APLs[classID] = apl
    end
end

-- Manual spell-queue override: /click a macro to force a specific spell to
-- the top of the recommendation ahead of whatever the rotation would pick,
-- e.g. for a cooldown you want timed by hand. Queuing an already-queued
-- spell un-queues it. Entries expire on their own so a queue press that
-- never became castable (wrong target, spell went on a long cooldown after
-- queuing, etc.) doesn't silently override the rotation forever.
local QUEUE_TIMEOUT = 20
RH.queue = RH.queue or {}
function RH.PruneQueue()
    local now = GetTime()
    for i = #RH.queue, 1, -1 do
        local entry = RH.queue[i]
        if not entry.queuedAt or now - entry.queuedAt > QUEUE_TIMEOUT then
            table.remove(RH.queue, i)
        end
    end
end
function RH.QueueSpell(name)
    if not name or name == "" then
        return
    end
    RH.PruneQueue()
    for i, entry in ipairs(RH.queue) do
        if entry.name == name then
            table.remove(RH.queue, i)
            return
        end
    end
    table.insert(RH.queue, { name = name, queuedAt = GetTime() })
end
function RH.PopQueue()
    RH.PruneQueue()
    for i, entry in ipairs(RH.queue) do
        local id = HeroCache and HeroCache:SpellID(entry.name)
        local spell = id and id ~= 0 and HeroLib.Spell(id)
        if spell and RH.Ready(spell) then
            table.remove(RH.queue, i)
            return spell:Cast()
        end
    end
    return nil
end
-- Macro-callable: /run NextCast_Queue("Riposte")
function NextCast_Queue(name)
    RH.QueueSpell(name)
end

-- Burst-mode toggle: a simple flag rotation files can check to unlock
-- on-use cooldowns/racials the player wants timed manually rather than
-- auto-fired the instant they come off cooldown.
function NextCast_Burst()
    local db = RH.EnsureDB()
    RH.Burst = not RH.Burst
    db.burst = RH.Burst and true or false
    if RH.RefreshMiniToggles then
        RH.RefreshMiniToggles()
    end
end

-- Offensive burst racials, applied to every class uniformly instead of
-- being wired into each rotation file individually. RH.Ready() already
-- checks the live spellbook (IsAvailable/IsUsable), so a player without the
-- matching race simply never sees these fire -- there's no per-race branch
-- to get wrong. These two IDs (Blood Fury / Berserking) are standard
-- Blizzard racial spells that have been stable since Vanilla/TBC across
-- every official realm; if Forever has re-implemented racials as custom
-- abilities with different IDs, these will just stay "not ready" like any
-- other unverified spell rather than misfiring, but that's the one
-- assumption in this feature worth flagging.
local racialSpells
local function GetRacialBurst()
    if not racialSpells then
        racialSpells = {
            RH.Named("Blood Fury", 20572),
            RH.Named("Berserking", 26297),
        }
    end
    for _, spell in ipairs(racialSpells) do
        if RH.Ready(spell) then
            return spell
        end
    end
    return nil
end

-- Rolling in-memory log of recommendation changes, for "it recommended X
-- when Y was clearly right" debugging without needing a full combat-log
-- parser. Not persisted to SavedVariables -- /nc log dumps it to chat.
RH.debugLog = RH.debugLog or {}
local DEBUG_LOG_MAX = 50
function RH.LogRecommendation(name)
    local entry = {
        time = date("%H:%M:%S"),
        spell = name or "(none)",
        heal = RH.healTarget,
        mode = RH.EnsureDB().mode,
        burst = RH.Burst and true or false,
    }
    table.insert(RH.debugLog, entry)
    if #RH.debugLog > DEBUG_LOG_MAX then
        table.remove(RH.debugLog, 1)
    end
end

function RH.MainRotation()
    RH.healTarget = nil
    if RH.EnsureDB().enabled == false then
        return nil
    end
    if RH.Paused and RH.Paused() then
        return nil
    end
    local now = GetTime()
    if RH.aplRetryAt and now < RH.aplRetryAt then
        return nil
    end
    local queued = RH.PopQueue()
    if queued then
        return queued
    end
    local id = select(3, UnitClass("player")) or 0
    local apl = RH.Rotation.APLs[id]
    if not apl then
        return nil
    end
    local ok, result = pcall(apl)
    if ok then
        RH.aplRetryAt = nil
        -- Only substitute a racial when the apl just decided this tick is a
        -- DPS action (healTarget nil) -- never preempt a heal recommendation.
        if RH.CDs and RH.Burst and not RH.healTarget then
            local racial = GetRacialBurst()
            if racial then
                result = racial:Cast()
            end
        end
        if result then
            if RH.healTarget and RH.SnapHealTarget then
                RH.SnapHealTarget(RH.healTarget)
            elseif RH.RestoreAfterHeal then
                RH.RestoreAfterHeal(false)
            end
            if RH.NoteCooldown then
                RH.NoteCooldown(result)
            end
        elseif RH.RestoreAfterHeal then
            RH.RestoreAfterHeal(false)
        end
        return result
    end
    RH.aplRetryAt = now + 1
    if not RH.lastError or now - RH.lastError > 10 or RH.lastErrorMessage ~= result then
        RH.lastError = now
        RH.lastErrorMessage = result
        print("|cffff5050NextCast|r: " .. tostring(result))
    end
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHARACTER_POINTS_CHANGED")
f:RegisterEvent("SPELLS_CHANGED")
f:SetScript("OnEvent", function()
    detectSpecAt = nil
    RH.EnsureDB()
end)
SLASH_NEXTCAST1 = "/nextcast"
SLASH_NEXTCAST2 = "/nc"
SlashCmdList.NEXTCAST = function(msg)
    local c = string.lower((msg or ""):match("^%s*(%S*)") or "")
    local db = RH.EnsureDB()
    if c == "cd" then
        RH.CDs = not RH.CDs
        db.cooldowns = RH.CDs
    elseif c == "aoe" then
        RH.AoE = not RH.AoE
        db.mode = RH.AoE and "aoe" or "single"
    elseif c == "kick" then
        RH.Interrupts = not RH.Interrupts
        db.interrupts = RH.Interrupts
    elseif c == "burst" then
        NextCast_Burst()
        print("|cff00d1ffNextCast|r: burst " .. (RH.Burst and "ON" or "OFF"))
        return
    elseif c == "queue" then
        local name = (msg or ""):match("^%s*%S+%s+(.-)%s*$")
        if name and name ~= "" then
            NextCast_Queue(name)
            print("|cff00d1ffNextCast|r: queue " .. name)
        else
            print("|cff00d1ffNextCast|r: usage /nc queue <spell name>")
        end
        return
    elseif c == "log" then
        if #RH.debugLog == 0 then
            print("|cff00d1ffNextCast|r: no recommendation changes logged yet")
        else
            print("|cff00d1ffNextCast|r: last " .. #RH.debugLog .. " recommendation changes")
            for _, entry in ipairs(RH.debugLog) do
                print(
                    string.format(
                        "  [%s] %s%s%s",
                        entry.time,
                        entry.spell,
                        entry.heal and ("  heal:" .. entry.heal) or "",
                        entry.burst and "  [burst]" or ""
                    )
                )
            end
        end
        return
    elseif c == "logclear" then
        wipe(RH.debugLog)
        print("|cffc8ccd4NextCast|r: debug log cleared")
        return
    elseif c == "ggl" or c == "shown" then
        if RH.GGLCalibrate then
            RH.GGLCalibrate(not RH.gglCalibrating)
        end
        return
    elseif c == "preset" then
        local id = string.lower((msg or ""):match("^%s*%S+%s+(%S+)") or "")
        if id == "dps" or id == "tank" or id == "healer" or id == "pvp" or id == "reset" or id == "auto" then
            RH.ApplyPreset(id)
            if RH.RefreshDashboard then
                RH.RefreshDashboard()
            end
            print("|cffc8ccd4NextCast|r: preset " .. id)
        else
            print("|cff00d1ffNextCast|r: usage /nc preset dps|tank|healer|pvp|auto|reset")
        end
        return
    elseif c == "reset" then
        local class = select(2, UnitClass("player"))
        if db.classProfiles then
            db.classProfiles[class] = nil
        end
        activeProfileClass = nil
        RH.EnsureDB()
        print("|cffc8ccd4NextCast|r: " .. tostring(class) .. " profile restored")
        return
    elseif c == "menu" or c == "" then
        if RH.ToggleMenu then
            RH.ToggleMenu()
        end
        return
    else
        print("|cffc8ccd4NextCast|r: /nc menu, cd, aoe, kick, burst, queue <spell>, preset, ggl, reset, log")
        return
    end
    local enabled = (c == "cd" and RH.CDs) or (c == "aoe" and RH.AoE) or (c == "kick" and RH.Interrupts)
    print("|cff00d1ffNextCast|r: " .. c .. " " .. (enabled and "ON" or "OFF"))
end

