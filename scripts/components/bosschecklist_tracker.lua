-- Boss Checklist - server-side record of defeated bosses (lives on TheWorld, master sim only).
-- Saved with the world and replicated to clients through a net_string on TheWorld.net.
-- It only stores and replicates; reacting to changes (shard sync, announcements) is done by
-- whoever sets `onchanged`.

local Codec = require("bosschecklist/codec")

-- Where a change came from.
local SOURCE =
{
    KILL = "kill",      -- the boss was really defeated on this shard
    MANUAL = "manual",  -- a player marked or unmarked it in the book
    SHARD = "shard",    -- another shard reported it (must not be sent back)
}

local Tracker = Class(function(self, inst)
    self.inst = inst
    self.defeated = {}      -- [boss_id] = day of the first defeat
    self.prefab_kills = {}  -- [prefab] = true, for bosses that need several prefabs dead (e.g. the Twins)
    self.onchanged = nil    -- fn(tracker, boss_id, is_defeated, source)
end)

Tracker.SOURCE = SOURCE

function Tracker:_Changed(id, is_defeated, source)
    self:Replicate()
    if self.onchanged ~= nil then
        self.onchanged(self, id, is_defeated, source or SOURCE.KILL)
    end
end

function Tracker:IsDefeated(id)
    return self.defeated[id] ~= nil
end

-- Day of the first defeat, or nil if the boss is not defeated.
function Tracker:GetDay(id)
    return self.defeated[id]
end

-- day: day of the defeat; nil or 0 means "today". Returns false if it was already defeated.
function Tracker:SetDefeated(id, day, source)
    if self.defeated[id] ~= nil then
        return false
    end
    if day == nil or day <= 0 then
        day = TheWorld.state.cycles + 1
    end
    self.defeated[id] = day
    self:_Changed(id, true, source)
    return true
end

function Tracker:ClearDefeated(id, source)
    if self.defeated[id] == nil then
        return false
    end
    self.defeated[id] = nil
    self:_Changed(id, false, source)
    return true
end

function Tracker:RecordPrefabKill(prefab)
    self.prefab_kills[prefab] = true
end

function Tracker:HasPrefabKill(prefab)
    return self.prefab_kills[prefab] == true
end

function Tracker:GetSerialized()
    return Codec.encode(self.defeated)
end

function Tracker:Replicate()
    local net = TheWorld.net
    if net ~= nil and net.bosschecklist_defeated ~= nil then
        net.bosschecklist_defeated:set(self:GetSerialized())
    end
end

function Tracker:OnSave()
    local prefab_kills = {}
    for prefab in pairs(self.prefab_kills) do
        prefab_kills[#prefab_kills + 1] = prefab
    end
    return { defeated = self.defeated, prefab_kills = prefab_kills }
end

function Tracker:OnLoad(data)
    if data == nil then
        return
    end
    for id, value in pairs(data.defeated or {}) do
        -- Saves from before 0.4 stored { day = n } instead of n.
        if type(value) == "table" then
            value = value.day
        end
        self.defeated[id] = tonumber(value) or 0
    end
    for _, prefab in ipairs(data.prefab_kills or {}) do
        self.prefab_kills[prefab] = true
    end
    self:Replicate()
end

function Tracker:GetDebugString()
    return self:GetSerialized()
end

return Tracker
