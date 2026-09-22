HeroCache = HeroCache or { Spells = {}, Known = {}, KnownIDs = {}, KnownSlots = {}, Revision = 0 }
local HC = HeroCache
local function secret(v)
    return issecretvalue and issecretvalue(v)
end
local function compactName(n)
    if type(n) ~= "string" then
        return n
    end
    return (n:gsub("%s*%(?[Rr]ank%s*%d+%)?", ""):gsub("%s+$", ""):gsub("^%s+", ""))
end

function HC:SpellInfo(id)
    local cached = self.Spells[id]
    if cached then
        return cached.name, cached.texture
    end
    local ok, name, texture
    if GetSpellInfo then
        local rank
        ok, name, rank, texture = pcall(GetSpellInfo, id)
    elseif C_Spell and C_Spell.GetSpellInfo then
        local data
        ok, data = pcall(C_Spell.GetSpellInfo, id)
        if ok and not secret(data) and type(data) == "table" then
            name, texture = data.name, data.iconID
        end
    elseif C_Spell and C_Spell.GetSpellName then
        ok, name = pcall(C_Spell.GetSpellName, id)
        if ok and C_Spell.GetSpellTexture then
            local textureOK
            textureOK, texture = pcall(C_Spell.GetSpellTexture, id)
            if not textureOK then
                texture = nil
            end
        end
    end
    if not ok or secret(name) or type(name) ~= "string" or name == "" then
        local alias = self.FallbackNames and self.FallbackNames[id]
        if alias then
            local live = self.KnownIDs and (self.KnownIDs[alias] or self.KnownIDs[compactName(alias)])
            if live and live ~= id then
                return self:SpellInfo(live)
            end
            local tex
            if GetSpellTexture then
                local tok, byName = pcall(GetSpellTexture, alias)
                if tok and byName and not secret(byName) then
                    tex = byName
                end
            end
            return alias, tex
        end
        return nil
    end
    if secret(texture) then
        texture = nil
    end
    if (not texture or texture == "") and name and GetSpellTexture then
        local tok, byName = pcall(GetSpellTexture, name)
        if tok and byName and not secret(byName) then
            texture = byName
        end
    end
    if (not texture or texture == "") and GetSpellTexture then
        local tok, byId = pcall(GetSpellTexture, id)
        if tok and byId and not secret(byId) then
            texture = byId
        end
    end
    cached = { name = name, texture = texture }
    self.Spells[id] = cached
    return name, texture
end

function HC:ScanSpellbook()
    -- Keep Spells (GetSpellInfo by id) — rank-1 fallback IDs stay valid across
    -- SPELLS_CHANGED. Only rebuild the live spellbook maps.
    wipe(self.Known)
    wipe(self.KnownIDs)
    self.KnownSlots = self.KnownSlots or {}
    wipe(self.KnownSlots)
    local misses = 0
    for index = 1, 2048 do
        local name, spellID
        local future = false
        if GetSpellBookItemName then
            local nameOK, value = pcall(GetSpellBookItemName, index, BOOKTYPE_SPELL or "spell")
            if nameOK then
                name = value
            end
            if GetSpellBookItemInfo then
                local ok, kind, id = pcall(GetSpellBookItemInfo, index, BOOKTYPE_SPELL or "spell")
                if ok then
                    future = not secret(kind) and kind == "FUTURESPELL"
                    if type(id) == "number" and not secret(id) then
                        spellID = id
                    end
                end
            end
        elseif C_SpellBook and C_SpellBook.GetSpellBookItemName and Enum and Enum.SpellBookSpellBank then
            local ok, value = pcall(C_SpellBook.GetSpellBookItemName, index, Enum.SpellBookSpellBank.Player)
            if ok then
                name = value
            end
            if C_SpellBook.GetSpellBookItemInfo then
                local infoOK, data = pcall(C_SpellBook.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Player)
                if infoOK and data then
                    future = Enum.SpellBookItemType
                        and not secret(data.itemType)
                        and data.itemType == Enum.SpellBookItemType.FutureSpell
                    if type(data.spellID) == "number" and not secret(data.spellID) then
                        spellID = data.spellID
                    end
                end
            end
        elseif C_SpellBook and C_SpellBook.GetSpellBookItemInfo and Enum and Enum.SpellBookSpellBank then
            local ok, data = pcall(C_SpellBook.GetSpellBookItemInfo, index, Enum.SpellBookSpellBank.Player)
            if ok and data and data.spellID then
                spellID = data.spellID
                name = self:SpellInfo(data.spellID)
            end
        end
        if type(name) == "string" and not secret(name) and name ~= "" then
            misses = 0
            if not future then
                self.Known[name] = true
                self.KnownSlots[name] = index
                local compact = compactName(name)
                if compact ~= name then
                    self.Known[compact] = true
                    self.KnownSlots[compact] = index
                end
                if spellID then
                    self.KnownIDs[name] = spellID
                    self.KnownIDs[compact] = spellID
                end
            end
        else
            misses = misses + 1
            if misses >= 40 then
                break
            end
        end
    end
    self.Revision = self.Revision + 1
end
function HC:SpellID(name)
    if type(name) ~= "string" then
        return nil
    end
    if self.KnownIDs and self.KnownIDs[name] then
        return self.KnownIDs[name]
    end
    local compact = compactName(name)
    return self.KnownIDs and self.KnownIDs[compact]
end

function HC:IsKnown(id)
    local name = self:SpellInfo(id)
    if name and (self.Known[name] or self.Known[compactName(name)]) then
        return true
    end
    if IsPlayerSpell then
        local ok, value = pcall(IsPlayerSpell, id)
        if ok and not secret(value) and (value == true or value == 1) then
            return true
        end
    end
    if IsSpellKnown then
        local ok, value = pcall(IsSpellKnown, id)
        if ok and not secret(value) and (value == true or value == 1) then
            return true
        end
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, value = pcall(C_SpellBook.IsSpellKnown, id)
        if ok and not secret(value) and (value == true or value == 1) then
            return true
        end
    end
    return false
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("SPELLS_CHANGED")
pcall(f.RegisterEvent, f, "LEARNED_SPELL_IN_TAB")
f:SetScript("OnEvent", function()
    HC:ScanSpellbook()
end)
