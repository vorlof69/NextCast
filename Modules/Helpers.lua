local RH, HL = RubimRH, HeroLib
RH.Player = HL.Unit.Player
RH.Target = HL.Unit.Target
function RH.S(id)
    return HL.Spell(id)
end
function RH.Named(name, fallback)
    local proxy = {}
    local function current()
        return HL.Spell(HeroCache:SpellID(name) or fallback or 0)
    end
    for _, method in ipairs({
        "ID",
        "Name",
        "Texture",
        "IsAvailable",
        "IsUsable",
        "CooldownRemains",
        "IsReady",
        "IsInRange",
        "Cast",
    }) do
        local methodName = method
        proxy[methodName] = function(_, ...)
            local spell = current()
            return spell[methodName](spell, ...)
        end
    end
    -- ExtraIcon / GGL profiles key off the classic rank-1 ID. Live Forever
    -- rank IDs (e.g. Demo Shout 6190) show on the HUD but miss the bind.
    proxy.Cast = function()
        if fallback and fallback > 0 then
            return fallback
        end
        return current():Cast()
    end
    return proxy
end
-- Per-spell minimum-player-level overrides. LevelGates.lua fills this after
-- load; Ready() still requires a live spellbook hit.
RH.levelGates = {}
function RH.SetLevelGate(name, minLevel)
    if name and minLevel then
        RH.levelGates[name] = minLevel
    end
end
function RH.MeetsLevelGate(name)
    local minLevel = name and RH.levelGates[name]
    if not minLevel then
        return true
    end
    local level = UnitLevel("player")
    return type(level) == "number" and not HL.Secret(level) and level >= minLevel
end
function RH.Ready(spell, range)
    if not spell then
        return false
    end
    local name = spell:Name()
    if name and RH.AbilityEnabled and not RH.AbilityEnabled(name) then
        return false
    end
    if not RH.MeetsLevelGate(name) then
        return false
    end
    if not spell:IsReady() or not spell:IsUsable() then
        return false
    end
    if not range then
        return true
    end
    local unit = type(range) == "string" and range or "target"
    if unit == "player" then
        return true
    end
    local okFriend, friend = pcall(UnitIsFriend, "player", unit)
    if okFriend and HL.SafeBoolean(friend, false) then
        return RH.FriendlyInRange(unit) ~= false
    end
    return spell:IsInRange(unit)
end
function RH.IsFriendlyUnit(unit)
    if not unit then
        return false
    end
    local ok, exists = pcall(UnitExists, unit)
    if not ok or HL.Secret(exists) or not exists then
        return false
    end
    if unit == "player" then
        return true
    end
    local okFriend, friend = pcall(UnitIsFriend, "player", unit)
    return okFriend and HL.SafeBoolean(friend, false) == true
end
function RH.ResolveUnit(unit)
    if not unit or unit == "player" or unit == "group" then
        return unit
    end
    if unit == "mouseover" or unit == "focus" or unit == "target" then
        local roster = RH.GroupUnits and RH.GroupUnits() or { "player" }
        for i = 1, #roster do
            local ok, same = pcall(UnitIsUnit, unit, roster[i])
            if ok and not HL.Secret(same) and same then
                return roster[i]
            end
        end
    end
    return unit
end
function RH.MouseoverAlly()
    local db = RH.EnsureDB and RH.EnsureDB()
    if db and db.healMouseover == false then
        return nil
    end
    if not RH.IsFriendlyUnit("mouseover") then
        return nil
    end
    local ally = HL.Unit("mouseover")
    if ally:IsDeadOrGhost() then
        return nil
    end
    return "mouseover", ally
end
function RH.ValidTarget()
    if not RH.Target:Exists() or RH.Target:IsDeadOrGhost() then
        return false
    end
    local ok, value = pcall(UnitCanAttack, "player", "target")
    return ok and not HL.Secret(value) and (value == true or value == 1)
end
function RH.IsPvPContext(setting)
    if setting == "pvp" then
        return true
    end
    if setting == "pve" then
        return false
    end
    local ok, value = pcall(UnitIsPlayer, "target")
    return ok and HL.SafeBoolean(value, false) == true
end
-- True when your current target is beating on someone who isn't you -- the
-- signal every tanking class uses to know a taunt is actually needed, not
-- just "am I not top of the threat table" (which can be secret/unreadable on
-- Forever). Shared so any tanking spec (Warrior, Paladin, Bear Druid) can use
-- the same check instead of re-deriving it per class file.
function RH.NeedsTaunt()
    local okExists, exists = pcall(UnitExists, "targettarget")
    if not okExists or HL.Secret(exists) or not exists then
        return false
    end
    local okSelf, isSelf = pcall(UnitIsUnit, "targettarget", "player")
    if okSelf and not HL.Secret(isSelf) and isSelf then
        return false
    end
    local okFriend, isFriend = pcall(UnitIsFriend, "player", "targettarget")
    return okFriend and not HL.Secret(isFriend) and isFriend == true
end
-- UnitThreatSituation("player", "target") return values: nil = not on the
-- threat table at all, 0/1 = not tanking (1 means about to pull aggro), 2/3 =
-- tanking (insecurely/securely). Used to drive auto-taunt for tanking forms
-- (e.g. Bear Form Growl). Wrapped for Forever's secret-value caution: an
-- unreadable status returns nil rather than a guessed number, so callers
-- never taunt blind off bad data.
function RH.ThreatStatus(unit)
    if not UnitThreatSituation then
        return nil
    end
    local ok, status = pcall(UnitThreatSituation, unit or "player", "target")
    if not ok or HL.Secret(status) or type(status) ~= "number" then
        return nil
    end
    return status
end
function RH.ShouldInterrupt(unit)
    local target = unit and HL.Unit(unit) or RH.Target
    if not target:IsCasting() then
        return false
    end
    -- A nil interruptibility result means Forever protected the flag. Keep the
    -- recommendation available instead of incorrectly suppressing every kick.
    return target:IsInterruptible() ~= false
end
local rangeProbes = {
    ROGUE = { near = { "Sinister Strike", 1752 }, far = { "Throw", 2764 } },
    WARRIOR = { near = { "Heroic Strike", 78 }, far = { "Charge", 100 } },
    PALADIN = { near = { "Attack", 6603 }, far = { "Judgement", 20271 } },
    HUNTER = { near = { "Raptor Strike", 2973 }, far = { "Arcane Shot", 3044 } },
    MAGE = { near = { "Attack", 6603 }, far = { "Fireball", 133 } },
    PRIEST = { near = { "Attack", 6603 }, far = { "Smite", 585 } },
    SHAMAN = { near = { "Attack", 6603 }, far = { "Lightning Bolt", 403 } },
    WARLOCK = { near = { "Attack", 6603 }, far = { "Shadow Bolt", 686 } },
    DRUID = { near = { "Attack", 6603 }, far = { "Moonfire", 8921 } },
}
local function spellRange(name, id, unit)
    local knownID = HeroCache:SpellID(name) or id
    local ok, value
    if C_Spell and C_Spell.IsSpellInRange then
        ok, value = pcall(C_Spell.IsSpellInRange, knownID, unit)
    end
    if (not ok or HL.Secret(value) or value == nil) and IsSpellInRange then
        ok, value = pcall(IsSpellInRange, name, unit)
    end
    if ok and not HL.Secret(value) and value ~= nil then
        return value == true or value == 1 or value == "1"
    end
    return nil
end
-- Public wrapper so rotations/healing logic can range-check any known spell
-- against any unit (party/raid heal range, not just the melee/ranged weapon
-- probes RH.UnitWithin uses). Unknown stays nil, same caution as elsewhere.
function RH.SpellRange(name, id, unit)
    return spellRange(name, id, unit or "target")
end
function RH.UnitWithin(unit, yards)
    -- Forever blocks its interaction-distance query from addon code. A readable spell-range
    -- probe is safe; unknown remains unknown so optional proximity actions yield to
    -- the normal ranged rotation instead of blocking it.
    local class = select(2, UnitClass("player"))
    local probes = rangeProbes[class]
    if not probes then
        return nil
    end
    local probe = yards <= 10 and probes.near or probes.far
    return spellRange(probe[1], probe[2], unit or "target")
end
function RH.CountNearbyEnemies()
    local now = GetTime()
    if RH.enemyCountAt and now - RH.enemyCountAt < 0.2 then
        return RH.enemyCount or 0
    end
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local okExists, exists = pcall(UnitExists, unit)
        if okExists and not HL.Secret(exists) and exists then
            local okAttack, attackable = pcall(UnitCanAttack, "player", unit)
            local okDead, dead = pcall(UnitIsDeadOrGhost, unit)
            if
                okAttack
                and not HL.Secret(attackable)
                and attackable
                and okDead
                and not HL.Secret(dead)
                and not dead
                and RH.UnitWithin(unit, 10) == true
            then
                count = count + 1
            end
        end
    end
    -- Nameplates may be disabled or protected; the current hostile target still
    -- counts as one, but never invent extra enemies when the client hides them.
    if count == 0 and RH.ValidTarget() and RH.UnitWithin("target", 10) == true then
        count = 1
    end
    RH.enemyCountAt = now
    RH.enemyCount = count
    return count
end
function RH.Power(kind)
    local ok, value = pcall(UnitPower, "player", kind)
    if ok and not HL.Secret(value) and type(value) == "number" then
        return value
    end
    -- Do not substitute a Druid's energy/rage for an unreadable mana value.
    return nil
end
function RH.PowerPercent(kind)
    local power = RH.Power(kind)
    if power == nil then
        return nil
    end
    local ok, maximum = pcall(UnitPowerMax, "player", kind)
    maximum = ok and HL.SafeNumber(maximum, nil) or nil
    if not maximum or maximum <= 0 then
        return nil
    end
    return power / maximum * 100
end
function RH.ResourceAbove(percent, floor)
    return percent == nil or percent >= (tonumber(floor) or 0)
end
function RH.TargetWillLive(seconds)
    local ttd = RH.Target:TimeToDie()
    if ttd then
        return ttd > seconds
    end
    local hp = RH.Target:HealthPercentage()
    return hp == nil or hp > 35
end
function RH.RangedFallback(spell)
    if spell and RH.Ready(spell, true) then
        local ok, active = pcall(IsCurrentSpell, spell:ID())
        if ok and HL.SafeBoolean(active, false) then
            return nil
        end
        return spell:Cast()
    end
    return RH.AttackOnce()
end
function RH.SafeUnitText(api, unit)
    if not api then
        return nil
    end
    local ok, value = pcall(api, unit or "target")
    if not ok or HL.Secret(value) or type(value) ~= "string" then
        return nil
    end
    return value
end
function RH.TotemActive(slot, wanted)
    if not GetTotemInfo then
        return nil
    end
    local ok, active, name, start, duration = pcall(GetTotemInfo, slot)
    if not ok then
        return nil
    end
    active = HL.SafeBoolean(active, nil)
    if active ~= true then
        return active
    end
    if not wanted then
        return true
    end
    if HL.Secret(name) or type(name) ~= "string" then
        return nil
    end
    return name == wanted or string.find(name, wanted, 1, true) ~= nil
end
function RH.Paused()
    if RH.Player and RH.Player:IsDeadOrGhost() then
        return true
    end
    if IsMounted then
        local ok, v = pcall(IsMounted)
        if ok and not HL.Secret(v) and v then
            return true
        end
    end
    if SpellIsTargeting then
        local ok, v = pcall(SpellIsTargeting)
        if ok and not HL.Secret(v) and v then
            return true
        end
    end
    if UnitInVehicle then
        local ok, v = pcall(UnitInVehicle, "player")
        if ok and not HL.Secret(v) and v then
            return true
        end
    end
    if LootFrame and LootFrame.IsShown and LootFrame:IsShown() then
        return true
    end
    return false
end
function RH.StartAttackTexture()
    local icons = RH.UniversalIcons or {}
    local choice = RH.IconChoice and (RH.IconChoice("StartAttack") or RH.IconChoice("Attack"))
    if choice and icons[choice] then
        return icons[choice]
    end
    if HeroCache and HeroCache.SpellInfo then
        local _, tex = HeroCache:SpellInfo(6603)
        if tex then
            return tex
        end
    end
    if GetSpellTexture then
        local ok, tex = pcall(GetSpellTexture, 6603)
        if ok and tex and (type(tex) == "string" or type(tex) == "number") then
            return tex
        end
    end
    return "Interface\\Icons\\Ability_MeleeDamage"
end
-- Action (MisterCrab): Player:IsAttacking() then A:Show(CONST_AUTOATTACK).
-- Classic auto-attack is PLAYER_ENTER_COMBAT / PLAYER_LEAVE_COMBAT, not
-- UnitAffectingCombat. Forever often hides IsCurrentSpell(6603), so we
-- also watch the Attack action slot (IsAttackAction + IsCurrentAction).
local cachedAttackSlot
local function FindAttackSlot()
    if not IsAttackAction then
        return nil
    end
    if cachedAttackSlot then
        local ok, isAtk = pcall(IsAttackAction, cachedAttackSlot)
        if ok and isAtk then
            return cachedAttackSlot
        end
        cachedAttackSlot = nil
    end
    for slot = 1, 120 do
        local ok, isAtk = pcall(IsAttackAction, slot)
        if ok and isAtk then
            cachedAttackSlot = slot
            return slot
        end
    end
end
function RH.AutoAttacking()
    if HL.State.meleeAttacking then
        return true
    end
    local function current(id)
        local ok, v = pcall(IsCurrentSpell, id)
        return ok and HL.SafeBoolean(v, false) == true
    end
    if current(6603) or current("Attack") then
        HL.State.meleeAttacking = true
        return true
    end
    if IsCurrentAction then
        local slot = FindAttackSlot()
        if slot then
            local ok, cur = pcall(IsCurrentAction, slot)
            if ok and cur then
                HL.State.meleeAttacking = true
                return true
            end
        end
    end
    return false
end
function RH.AttackOnce()
    if not RH.ValidTarget() or RH.UnitWithin("target", 10) == false then
        return nil
    end
    if RH.AbilityEnabled and not RH.AbilityEnabled("StartAttack") then
        return nil
    end
    -- Action skips AutoAttack while stealthed or casting.
    if RH.Player then
        if RH.Player:Buff("Stealth") == true or RH.Player:Buff("Prowl") == true then
            return nil
        end
        if RH.Player:IsCasting() then
            return nil
        end
    end
    if RH.AutoAttacking() then
        HL.State.attackSuggested = nil
        HL.State.attackSuggestedAt = nil
        return nil
    end
    local now = GetTime()
    local started = HL.State.attackSuggestedAt
    -- One GGLoader press, then hide. Painting every tick spams a toggle
    -- Attack bind (on / off / on). /startattack is safe but still blocks ST.
    if started then
        local elapsed = now - started
        if elapsed < 0.45 then
            return 6603
        end
        if elapsed < 1.6 then
            return nil
        end
    end
    HL.State.attackSuggested = true
    HL.State.attackSuggestedAt = now
    return 6603
end
-- Shapeshift form from the stance bar (more reliable than aura names on Forever).
-- Returns localized name, slot index. Index 0 / nil = caster form.
function RH.ActiveForm()
    if not GetShapeshiftForm then
        return nil, 0
    end
    local ok, index = pcall(GetShapeshiftForm)
    index = ok and HL.SafeNumber(index, 0) or 0
    if not index or index <= 0 then
        return nil, 0
    end
    if GetShapeshiftFormInfo then
        -- Classic: icon, name, active. Retail-like: icon, active, castable, spellID.
        local iok, a, b, c = pcall(GetShapeshiftFormInfo, index)
        if iok then
            local name, isActive
            if type(b) == "string" then
                name, isActive = b, c
            elseif type(b) == "boolean" or type(b) == "number" then
                isActive = b == true or b == 1
            end
            if isActive == false then
                return nil, 0
            end
            if type(name) == "string" and not HL.Secret(name) then
                return name, index
            end
        end
    end
    return nil, index
end
function RH.NoteShift(action, spell)
    HL.State.shiftAction = action
    HL.State.shiftSpell = spell
    HL.State.shiftAt = GetTime()
end
function RH.ShiftPending()
    return HL.State.shiftAt and GetTime() - HL.State.shiftAt < 1.8
end
function RH.InForm(needle)
    if not needle then
        return false
    end
    local name, index = RH.ActiveForm()
    if type(name) == "string" then
        local n, w = string.lower(name), string.lower(needle)
        if string.find(n, w, 1, true) then
            return true
        end
        if w == "bear form" and string.find(n, "bear", 1, true) then
            return true
        end
        if w == "cat form" and string.find(n, "cat", 1, true) then
            return true
        end
    end
    if RH.Player:Buff(needle) == true then
        return true
    end
    if needle == "Bear Form" and RH.Player:Buff("Dire Bear Form") == true then
        return true
    end
    -- Secret aura names: Feral below 20 only has Bear. Treat any shapeshift as Bear.
    if needle == "Bear Form" and index and index > 0 then
        local level = UnitLevel("player")
        if type(level) == "number" and not HL.Secret(level) and level < 20 then
            return true
        end
    end
    return false
end
function RH.IsShapeshifted()
    local _, index = RH.ActiveForm()
    if index and index > 0 then
        return true
    end
    if GetShapeshiftFormInfo then
        local n = 4
        if GetNumShapeshiftForms then
            local okN, count = pcall(GetNumShapeshiftForms)
            count = okN and HL.SafeNumber(count, 0) or 0
            if count and count > 0 then
                n = count
            end
        end
        for i = 1, n do
            local iok, a, b, c = pcall(GetShapeshiftFormInfo, i)
            if iok then
                if type(b) == "string" and (c == true or c == 1) then
                    return true
                end
                if b == true or b == 1 then
                    return true
                end
            end
        end
    end
    return false
end

local anchors = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}
function RH.SaveFramePosition(frame, key)
    local point, _, relative, x, y = frame:GetPoint()
    RH.EnsureDB()[key] = { point, relative, x, y }
end
function RH.RestoreFramePosition(frame, key)
    local p = RH.EnsureDB()[key]
    if type(p) ~= "table" or not anchors[p[1]] or not anchors[p[2]] then
        return
    end
    local x, y = tonumber(p[3]), tonumber(p[4])
    if not x or not y or x ~= x or y ~= y or math.abs(x) > 10000 or math.abs(y) > 10000 then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[2], x, y)
end
function RH.MainHandIsDagger()
    local ok, itemID = pcall(GetInventoryItemID, "player", 16)
    if not ok or HL.Secret(itemID) then
        return nil
    end
    if not itemID then
        return false
    end
    if GetItemInfoInstant then
        local infoOK, _, _, _, _, _, classID, subclassID = pcall(GetItemInfoInstant, itemID)
        if infoOK and not HL.Secret(classID) and not HL.Secret(subclassID) then
            return classID == 2 and subclassID == 15
        end
    end
    return nil
end
function RH.HasShield()
    local ok, itemID = pcall(GetInventoryItemID, "player", 17)
    if not ok or HL.Secret(itemID) then
        return nil
    end
    if not itemID then
        return false
    end
    if GetItemInfoInstant then
        local infoOK, _, _, _, _, _, classID, subclassID = pcall(GetItemInfoInstant, itemID)
        if infoOK and not HL.Secret(classID) and not HL.Secret(subclassID) then
            return classID == 4 and subclassID == 6
        end
    end
    return nil
end
function RH.MainHandSpeed()
    local ok, speed = pcall(UnitAttackSpeed, "player")
    if ok and not HL.Secret(speed) and type(speed) == "number" then
        return speed
    end
    return nil
end
function RH.MainHandEnchanted()
    if GetWeaponEnchantInfo then
        local ok, has = pcall(GetWeaponEnchantInfo)
        if ok and not HL.Secret(has) then
            return has == true or has == 1
        end
    end
    return HL.State.weaponEnchantUntil and HL.State.weaponEnchantUntil > GetTime() or nil
end
function RH.AutoShotOnce(spell)
    if not RH.ValidTarget() or (spell and not RH.Ready(spell, true)) then
        return nil
    end
    if RH.AbilityEnabled and not RH.AbilityEnabled("Auto Shot") then
        return nil
    end
    local ok, active = pcall(IsCurrentSpell, 75)
    if ok and HL.SafeBoolean(active, nil) == true then
        HL.State.autoShotSuggested = true
        return nil
    end
    local now = GetTime()
    if HL.State.autoShotSuggested then
        if
            RH.Player:AffectingCombat()
            or not HL.State.autoShotSuggestedAt
            or now - HL.State.autoShotSuggestedAt < 5
        then
            return nil
        end
        HL.State.autoShotSuggested = nil
    end
    HL.State.autoShotSuggested = true
    HL.State.autoShotSuggestedAt = now
    return (spell and spell:Cast()) or 75
end
-- Forever may return a secret aura name.  Unit:Debuff then deliberately returns
-- nil (unknown), which must not be confused with "the player's debuff exists".
-- A successful cast is recorded by HeroLib.Events, so ~= true both applies a
-- missing/hidden debuff and stops recommending it immediately after it lands.
function RH.DebuffMissing(name)
    if RH.RecentlyDebuffed and RH.RecentlyDebuffed(name) then
        return false
    end
    return RH.Target:Debuff(name) ~= true
end
local function FriendlyReachable(unit)
    if unit == "player" then
        return true
    end
    local connected = true
    if UnitIsConnected then
        local ok, v = pcall(UnitIsConnected, unit)
        if ok then
            connected = HL.SafeBoolean(v, true)
        end
    end
    return connected
end

function RH.FriendlyInRange(unit)
    if not unit or unit == "player" then
        return true
    end
    if UnitInRange then
        local ok, v, checked = pcall(UnitInRange, unit)
        if ok and not HL.Secret(v) then
            if checked == nil or HL.SafeBoolean(checked, true) then
                local ranged = HL.SafeBoolean(v, nil)
                if ranged ~= nil then
                    return ranged
                end
            end
        end
    end
    local check = RH.SpellRange("Heal", 2054, unit)
        or RH.SpellRange("Healing Wave", 331, unit)
        or RH.SpellRange("Holy Light", 635, unit)
        or RH.SpellRange("Healing Touch", 5185, unit)
        or RH.SpellRange("Lesser Heal", 2050, unit)
    if check ~= nil then
        return check
    end
    return true
end

function RH.GroupUnits()
    local units = {}
    local raidCount = 0
    if GetNumRaidMembers then
        raidCount = HL.SafeNumber(GetNumRaidMembers(), 0) or 0
    end
    local groupCount = 0
    if GetNumGroupMembers then
        groupCount = HL.SafeNumber(GetNumGroupMembers(), 0) or 0
    end
    local partyCount = 0
    if GetNumPartyMembers then
        partyCount = HL.SafeNumber(GetNumPartyMembers(), 0) or 0
    end
    local inRaid = raidCount > 0
    if not inRaid and IsInRaid then
        local ok, v = pcall(IsInRaid)
        inRaid = ok and HL.SafeBoolean(v, false) == true
    end
    if inRaid then
        local n = math.max(raidCount, groupCount)
        for i = 1, n do
            units[#units + 1] = "raid" .. i
        end
    else
        units[1] = "player"
        local n = partyCount
        if n == 0 and groupCount > 1 then
            n = groupCount - 1
        end
        for i = 1, n do
            units[#units + 1] = "party" .. i
        end
    end
    local function addUnit(unit)
        local ok, exists = pcall(UnitExists, unit)
        if not ok or HL.Secret(exists) or not exists then
            return
        end
        local okFriend, friend = pcall(UnitIsFriend, "player", unit)
        if okFriend and not HL.Secret(friend) and HL.SafeBoolean(friend, false) ~= true then
            return
        end
        for _, existing in ipairs(units) do
            local okSame, same = pcall(UnitIsUnit, existing, unit)
            if okSame and not HL.Secret(same) and same then
                return
            end
        end
        units[#units + 1] = unit
    end
    addUnit("player")
    addUnit("focus")
    addUnit("target")
    addUnit("mouseover")
    addUnit("pet")
    return units
end

function RH.NoteBuff(unit, name, seconds)
    if not unit or not name then
        return
    end
    HL.State.unitBuffs = HL.State.unitBuffs or {}
    HL.State.unitBuffs[unit .. "\031" .. name] = GetTime() + (tonumber(seconds) or 12)
end

function RH.RecentlyBuffed(unit, name)
    if not unit or not name or not HL.State.unitBuffs then
        return false
    end
    local expires = HL.State.unitBuffs[unit .. "\031" .. name]
    return type(expires) == "number" and expires > GetTime()
end

function RH.CastAllyBuff(spell, unit, buffName, seconds)
    if not spell or not unit then
        return nil
    end
    if not RH.Ready(spell, unit == "player" and nil or unit) then
        return nil
    end
    RH.healTarget = unit
    RH.NoteBuff(unit, buffName or spell:Name(), seconds or 120)
    return spell:Cast()
end

-- Action HealingEngine: paint TargetColor so GGL can retarget, AND snap the
-- ally onto target so ExtraIcon still lands the raw spell. Restore only after
-- the heal is SENT/SUCCEEDED (or 1.4s with no heal), never mid-press.
function RH.SnapHealTarget(unit)
    if not unit or unit == "group" then
        return
    end
    local resolved = unit
    if RH.ResolveUnit then
        resolved = RH.ResolveUnit(unit) or unit
    end
    local okSame, same = pcall(UnitIsUnit, "target", resolved)
    if okSame and not HL.Secret(same) and same then
        HL.State.healSnapAt = HL.State.healSnapAt or GetTime()
        return
    end
    local okAtk, atk = pcall(UnitCanAttack, "player", "target")
    local onEnemy = okAtk and not HL.Secret(atk) and atk
    if onEnemy then
        HL.State.needHealSnapBack = true
        HL.State.healSnapAt = GetTime()
    elseif resolved ~= "player" then
        HL.State.needHealSnapBack = true
        HL.State.healSnapAt = GetTime()
    end
    pcall(TargetUnit, resolved)
end

function RH.RestoreAfterHeal(force)
    if not HL.State.needHealSnapBack then
        return
    end
    if not force then
        if RH.healTarget then
            return
        end
        local at = HL.State.healSnapAt
        if at and GetTime() - at < 1.4 then
            return
        end
    end
    HL.State.needHealSnapBack = nil
    HL.State.healSnapAt = nil
    pcall(TargetLastEnemy)
end

-- Self buff / aura / aspect / armor.
-- Visible true  → skip.
-- Visible false → recast.
-- Unknown (nil) → recast only out of combat (latched). Combat unknown must
-- not pulse every GCD — Forever secrets auras in form / in combat.
function RH.CastIfMissing(spell, names, seconds)
    if not spell then
        return nil
    end
    if type(names) == "string" then
        names = { names }
    elseif type(names) ~= "table" then
        local n = spell.Name and spell:Name()
        names = n and { n } or {}
    end
    if #names == 0 then
        return nil
    end
    local inCombat = RH.Player and RH.Player:AffectingCombat()
    for i = 1, #names do
        local n = names[i]
        if RH.RecentlyBuffed("player", n) then
            return nil
        end
        local have = RH.Player:Buff(n)
        if have == true then
            return nil
        end
        if have ~= false and inCombat then
            return nil
        end
    end
    if not RH.Ready(spell) then
        return nil
    end
    local hold = tonumber(seconds) or 120
    for i = 1, #names do
        RH.NoteBuff("player", names[i], hold)
    end
    return spell:Cast()
end

function RH.NoteDebuff(name, seconds)
    if not name then
        return
    end
    local hold = tonumber(seconds) or 20
    local now = GetTime()
    HL.State.debuffs[name] = now + hold
    local guid
    if UnitGUID then
        local ok, g = pcall(UnitGUID, "target")
        if ok and type(g) == "string" and not HL.Secret(g) then
            guid = g
        end
    end
    HL.State.notedDebuffs = HL.State.notedDebuffs or {}
    HL.State.notedDebuffs[(guid or "target") .. "\031" .. name] = now + hold
end

function RH.RecentlyDebuffed(name)
    if not name then
        return false
    end
    local guid
    if UnitGUID then
        local ok, g = pcall(UnitGUID, "target")
        if ok and type(g) == "string" and not HL.Secret(g) then
            guid = g
        end
    end
    local expires = HL.State.notedDebuffs and HL.State.notedDebuffs[(guid or "target") .. "\031" .. name]
    return type(expires) == "number" and expires > GetTime()
end

-- Maintain a target debuff. Latch on recommend so a false scan cannot GCD-spam
-- 0-cooldown abilities (Demo Roar, Hunter's Mark, Moonfire).
function RH.CastIfDebuffMissing(spell, names, seconds, melee)
    if not spell then
        return nil
    end
    if type(names) == "string" then
        names = { names }
    elseif type(names) ~= "table" then
        return nil
    end
    for i = 1, #names do
        local n = names[i]
        if RH.RecentlyDebuffed(n) or RH.Target:Debuff(n) == true then
            return nil
        end
    end
    if not RH.Ready(spell, melee) then
        return nil
    end
    local hold = tonumber(seconds) or 20
    for i = 1, #names do
        RH.NoteDebuff(names[i], hold)
    end
    return spell:Cast()
end

function RH.FindMissingBuff(buffName, entries)
    if not buffName then
        return nil
    end
    local list = entries
    if not list then
        local units = RH.GroupUnits()
        list = {}
        for _, unit in ipairs(units) do
            list[#list + 1] = { unit = unit, ally = HL.Unit(unit) }
        end
    end
    for _, entry in ipairs(list) do
        local unit = entry.unit
        if
            unit
            and unit ~= "group"
            and unit ~= "target"
            and unit ~= "focus"
            and unit ~= "mouseover"
            and not string.find(unit, "pet", 1, true)
            and FriendlyReachable(unit)
        then
            local ally = entry.ally or HL.Unit(unit)
            if ally:Exists() and not ally:IsDeadOrGhost() then
                if RH.RecentlyBuffed(unit, buffName) then
                    -- already pulsed this buff at this ally
                else
                    local have = ally:Buff(buffName)
                    local missing = have == false
                    if not missing and have ~= true and unit == "player" then
                        missing = not (RH.Player and RH.Player:AffectingCombat())
                    end
                    if missing and RH.FriendlyInRange(unit) ~= false then
                        return unit
                    end
                end
            end
        end
    end
    return nil
end

function RH.FriendlySnapshot(horizon)
    local units = RH.GroupUnits()
    local entries, best, bestHP = {}, nil, 101
    for _, unit in ipairs(units) do
        local ally = HL.Unit(unit)
        if FriendlyReachable(unit) and ally:Exists() and not ally:IsDeadOrGhost() then
            local hp = ally:ProjectedHealth(horizon or 1.25) or ally:HealthPercentage()
            hp = HL.SafeNumber(hp, nil)
            if not hp then
                local cached = HL.State.healthTrend[unit]
                hp = cached and HL.SafeNumber(cached.hp, nil) or nil
            end
            if not hp then
                -- Forever often hides UnitHealth. Last-seen sample first.
                -- Still unknown in combat: healer-efficient (65) so healers
                -- act, tanks/DPS emergency bands do not spam.
                if unit == "player" and ally:AffectingCombat() then
                    hp = 40
                elseif RH.Player and RH.Player:AffectingCombat() then
                    hp = 65
                else
                    hp = 100
                end
            end
            hp = math.max(0, math.min(100, hp))
            local entry = { unit = unit, hp = hp, ally = ally }
            entries[#entries + 1] = entry
            if hp < bestHP then
                best, bestHP = unit, hp
            end
        end
    end
    if not best then
        best, bestHP = "player", 100
        entries[1] = { unit = best, hp = bestHP, ally = RH.Player }
    end
    return entries, best, bestHP
end
function RH.LowestFriendly()
    local _, unit, hp = RH.FriendlySnapshot(1.25)
    return unit, hp
end
function RH.CountInjuredFriendlies(entries, threshold, rangeSpell)
    local total = 0
    threshold = tonumber(threshold) or 100
    for _, entry in ipairs(entries or {}) do
        if entry.hp < threshold then
            if not rangeSpell then
                total = total + 1
            else
                local inRange = RH.SpellRange(rangeSpell[1], rangeSpell[2], entry.unit)
                if inRange ~= false then
                    total = total + 1
                end
            end
        end
    end
    return total
end

-- ---------------------------------------------------------------------------
-- Raid/party healing checks
--
-- Modeled on the query surface Action's HealingEngine exposes to rotation
-- profiles (GetBelowHealthPercentUnits, GetMinimumUnits, a dispel scan), but
-- implemented natively against HeroLib/FriendlySnapshot so NextCast stays a
-- standalone addon with no TellMeWhen/Action dependency, and so it only uses
-- APIs verified against this client instead of Action's (partly retail-only)
-- surface.
-- ---------------------------------------------------------------------------

-- Equivalent of Action's HealingEngine.GetBelowHealthPercentUnits(hp, range).
-- rangeSpell, if given, is {name, id} of any known spell to range-check
-- against (e.g. your group heal) so out-of-range allies aren't counted.
function RH.CountBelowHP(hp, rangeSpell, horizon)
    local entries = RH.FriendlySnapshot(horizon)
    return RH.CountInjuredFriendlies(entries, hp, rangeSpell)
end

-- Live group size (party/raid), independent of the FriendlySnapshot filtering
-- (dead/disconnected/unreadable-HP allies are still part of the roster).
function RH.GroupSize()
    if GetNumRaidMembers then
        local n = HL.SafeNumber(GetNumRaidMembers(), 0) or 0
        if n > 0 then
            return n
        end
    end
    if GetNumGroupMembers then
        local n = HL.SafeNumber(GetNumGroupMembers(), 0) or 0
        if n > 0 then
            return n
        end
    end
    if GetNumPartyMembers then
        local n = HL.SafeNumber(GetNumPartyMembers(), 0) or 0
        if n > 0 then
            return n + 1
        end
    end
    return 1
end

-- Equivalent of Action's HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit):
-- how many injured allies are "enough" to justify an AoE/group heal instead of
-- single-target, scaled to current group size. raidLimit caps the number for
-- very large raids (e.g. a group heal that only ever needs to catch 5 people).
function RH.MinimumHealTargets(fullPartyMinus, raidLimit)
    local size = RH.GroupSize()
    if size <= 1 then
        return 1
    elseif size <= 3 then
        return math.max(1, size - math.min(fullPartyMinus or 0, 1))
    elseif size <= 5 then
        return math.max(1, size - (fullPartyMinus or 0))
    elseif raidLimit and size >= raidLimit then
        return raidLimit
    end
    return size
end

-- Scans a unit's harmful auras for one this class can dispel. `types` is a
-- set of dispel-type strings this spec cures, e.g. {Magic=true, Poison=true}.
-- Returns the debuff name if found, false if the unit is clean, or nil if
-- the client hid enough of the aura list to make that call unsafe (mirrors
-- the same secret-value caution Unit:Debuff already uses).
function RH.DispellableDebuff(unit, types)
    if not types or not next(types) then
        return nil
    end
    local hidden = false
    for i = 1, 40 do
        local ok, name, dispelType
        if UnitDebuff then
            ok, name, _, _, dispelType = pcall(UnitDebuff, unit, i)
        elseif UnitAura then
            ok, name, _, _, dispelType = pcall(UnitAura, unit, i, "HARMFUL")
        elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local data
            ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if ok and type(data) == "table" then
                name, dispelType = data.name, data.dispelName
            end
        else
            return nil
        end
        if not ok then
            return nil
        end
        if HL.Secret(name) or HL.Secret(dispelType) then
            hidden = true
        elseif name == nil then
            if hidden then
                return nil
            end
            return false
        elseif type(dispelType) == "string" and types[dispelType] then
            return name
        end
    end
    if hidden then
        return nil
    end
    return false
end

-- Convenience: first dispellable ally found across the raid/party snapshot,
-- or nil if none/unknown. Combine with RH.DispellableDebuff's return to know
-- which debuff it is.
function RH.FindDispelTarget(types, entries)
    entries = entries or select(1, RH.FriendlySnapshot(0))
    for _, entry in ipairs(entries) do
        local debuff = RH.DispellableDebuff(entry.unit, types)
        if debuff then
            return entry.unit, debuff
        end
    end
    return nil
end

-- Role-aware healing: healers run the full kit, tanks self-sustain,
-- DPS only emergency saves. PvP biases the player.
function RH.HealRole()
    local db = RH.EnsureDB()
    local override = db.healRole
    if override == "healer" or override == "tank" or override == "dps" then
        return override
    end
    local spec = db.spec or ""
    local class = select(2, UnitClass("player"))
    if class == "PRIEST" then
        if spec == "Shadow" and RH.Player and RH.Player:Buff("Shadowform") == true then
            return "dps"
        end
        return "healer"
    end
    if spec == "Holy" or spec == "Discipline" or spec == "Restoration" then
        return "healer"
    end
    if spec == "Protection" then
        return "tank"
    end
    if class == "DRUID" and RH.InForm and RH.InForm("Bear Form") then
        return "tank"
    end
    if class == "WARRIOR" and GetShapeshiftForm then
        local ok, form = pcall(GetShapeshiftForm)
        if ok and HL.SafeNumber(form, 0) == 2 then
            return "tank"
        end
    end
    return "dps"
end

function RH.HealBands(pvp)
    local db = RH.EnsureDB()
    local role = RH.HealRole()
    local emergency = tonumber(db.emergencyHealHP) or 35
    local efficient = tonumber(db.efficientHealHP) or 70
    if role == "healer" then
        return {
            role = role,
            emergency = emergency,
            efficient = efficient,
            hot = math.min(92, efficient + 18),
            shield = math.min(82, efficient + 8),
            group = 75,
        }
    end
    if role == "tank" then
        return {
            role = role,
            emergency = pvp and math.max(emergency, 38) or math.min(emergency, 32),
            efficient = pvp and 48 or 40,
            hot = nil,
            shield = pvp and 55 or 42,
            group = 0,
        }
    end
    return {
        role = role,
        emergency = pvp and math.max(emergency, 42) or emergency,
        efficient = pvp and 45 or (emergency + 4),
        hot = nil,
        shield = pvp and 48 or (emergency + 6),
        group = 0,
    }
end

function RH.IsTankUnit(unit)
    if not unit then
        return false
    end
    local okSelf, isSelf = pcall(UnitIsUnit, unit, "player")
    if okSelf and not HL.Secret(isSelf) and isSelf then
        return RH.HealRole() == "tank"
    end
    if GetPartyAssignment then
        local ok, assigned = pcall(GetPartyAssignment, "MAINTANK", unit)
        if ok and not HL.Secret(assigned) and assigned then
            return true
        end
    end
    local ally = HL.Unit(unit)
    return ally:Buff("Righteous Fury") == true
        or ally:Buff("Bear Form") == true
        or ally:Buff("Dire Bear Form") == true
        or ally:Buff("Defensive Stance") == true
end

function RH.PickHealTarget(entries, pvp)
    local db = RH.EnsureDB and RH.EnsureDB()
    if not db or db.healMouseover ~= false then
        local mo, ally = RH.MouseoverAlly()
        if mo and ally then
            local hp = HL.SafeNumber(ally:HealthPercentage(), nil)
            if not hp then
                return "mouseover", 50
            end
            local bands = RH.HealBands(pvp)
            local cap = bands.hot or bands.efficient or 92
            if bands.role == "healer" then
                cap = math.max(cap, 98)
            end
            if hp <= cap then
                return "mouseover", hp
            end
        end
    end
    local best, bestHP, bestScore
    for _, entry in ipairs(entries or {}) do
        local hp = entry.hp
        if hp then
            local score = hp
            local proj = entry.ally and entry.ally.ProjectedHealth and entry.ally:ProjectedHealth(1.25)
            proj = HL.SafeNumber(proj, nil)
            if proj and proj < hp then
                score = score - (hp - proj)
            end
            if RH.IsTankUnit(entry.unit) then
                score = score - 16
            end
            if pvp then
                local okSelf, isSelf = pcall(UnitIsUnit, entry.unit, "player")
                if okSelf and not HL.Secret(isSelf) and isSelf then
                    score = score - 12
                end
            end
            local tt = entry.unit .. "target"
            local okExists, exists = pcall(UnitExists, tt)
            if okExists and not HL.Secret(exists) and exists then
                local okAttack, attackable = pcall(UnitCanAttack, "player", tt)
                if okAttack and not HL.Secret(attackable) and attackable then
                    score = score - 8
                end
            end
            if not bestScore or score < bestScore then
                best, bestHP, bestScore = entry.unit, hp, score
            end
        end
    end
    -- Action HealingEngine delays target swaps so GGL is not flicked every tick.
    local now = GetTime()
    if best and HL.State.stickyHeal and HL.State.stickyHealUntil and HL.State.stickyHealUntil > now then
        if not (bestHP and HL.State.stickyHealHP and bestHP < HL.State.stickyHealHP - 18) then
            return HL.State.stickyHeal, HL.State.stickyHealHP or bestHP
        end
    end
    if best then
        HL.State.stickyHeal = best
        HL.State.stickyHealHP = bestHP
        HL.State.stickyHealUntil = now + 0.45
    end
    return best, bestHP
end

function RH.NoteCooldown(id)
    if type(id) ~= "number" or id <= 0 or not HeroDBC or not HeroDBC.Cooldowns then
        return
    end
    local name = HeroCache and HeroCache.SpellInfo and HeroCache:SpellInfo(id)
    if not name then
        return
    end
    local cd = HeroDBC.Cooldowns[HeroDBC.CompactName and HeroDBC.CompactName(name) or name:gsub("[%s']", "")]
    if not cd then
        return
    end
    local now = GetTime()
    if HL.State.cooldowns[name] and HL.State.cooldowns[name] > now + 0.5 then
        return
    end
    HL.State.cdShownAt = HL.State.cdShownAt or {}
    if not HL.State.cdShownAt[name] or (HL.State.cooldowns[name] and HL.State.cooldowns[name] <= now) then
        HL.State.cdShownAt[name] = now
    end
    if now - HL.State.cdShownAt[name] < 0.4 then
        return
    end
    HL.State.cooldowns[name] = now + cd
end
