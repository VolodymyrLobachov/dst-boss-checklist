-- Boss Checklist - keeps the defeated-boss list in one piece (imported by modmain).
--   server -> clients : net_string on the world network entity
--   shard <-> shard   : shard RPCs, so the surface and the caves agree
--   client -> server  : RPC for manual marking from the book

local G = GLOBAL
local require = G.require

local Codec = require("bosschecklist/codec")
local Config = require("bosschecklist/config")
local GameData = require("bosschecklist/gamedata")
local Registry = require("bosschecklist/registry")
local SOURCE = require("components/bosschecklist_tracker").SOURCE

local NAMESPACE = Config.RPC_NAMESPACE
local STARTUP_SYNC_DELAY = 5 -- seconds; gives the other shards time to connect

-- The tracker only exists on the server (master sim).
local function get_tracker()
    local world = G.TheWorld
    return world ~= nil and world.ismastersim and world.components.bosschecklist_tracker or nil
end

local function add_net_var(inst)
    inst.bosschecklist_defeated = G.net_string(inst.GUID, "bosschecklist.defeated", "bosschecklist_dirty")
end
AddPrefabPostInit("forest_network", add_net_var)
AddPrefabPostInit("cave_network", add_net_var)

local function is_from_this_shard(shard_id)
    return G.TheShard ~= nil and tostring(shard_id) == tostring(G.TheShard:GetShardId())
end

-- Sends a shard RPC to one shard, or to all other shards when shard_id is nil.
-- Protected call: in a world without caves there is nobody to send to.
local function send_to_shards(rpc_name, shard_id, ...)
    local ok, err = G.pcall(SendModRPCToShard, G.GetShardModRPC(NAMESPACE, rpc_name), shard_id, ...)
    if not ok then
        print("[Boss Checklist] Shard RPC failed: " .. tostring(err))
    end
end

local function merge_from_shard(tracker, encoded)
    for id, day in pairs(Codec.decode(encoded)) do
        if Registry.by_id[id] ~= nil then
            tracker:SetDefeated(id, day, SOURCE.SHARD)
        end
    end
end

AddShardModRPCHandler(NAMESPACE, "SetDefeated", function(shard_id, id, is_defeated, day)
    local tracker = get_tracker()
    if tracker == nil or is_from_this_shard(shard_id) or Registry.by_id[id] == nil then
        return
    end
    if is_defeated then
        tracker:SetDefeated(id, day, SOURCE.SHARD)
    else
        tracker:ClearDefeated(id, SOURCE.SHARD)
    end
end)

AddShardModRPCHandler(NAMESPACE, "SyncAll", function(shard_id, encoded, wants_reply)
    local tracker = get_tracker()
    if tracker == nil or is_from_this_shard(shard_id) then
        return
    end
    merge_from_shard(tracker, encoded)
    if wants_reply then
        -- Reply only to the shard that asked, and without asking back, so this never loops.
        send_to_shards("SyncAll", shard_id, tracker:GetSerialized(), false)
    end
end)

local function is_admin(player)
    return player ~= nil and player.Network ~= nil and player.Network:IsServerAdmin() == true
end

AddModRPCHandler(NAMESPACE, "SetDefeated", function(player, id, is_defeated)
    local tracker = get_tracker()
    -- Never trust the client: check the id and the permission again on the server.
    if tracker == nil or type(id) ~= "string" or Registry.by_id[id] == nil
        or not Config.can_mark(is_admin(player)) then
        return
    end
    if is_defeated then
        tracker:SetDefeated(id, nil, SOURCE.MANUAL)
    else
        tracker:ClearDefeated(id, SOURCE.MANUAL)
    end
end)

local function announce_first_kill(id)
    local boss = Registry.by_id[id]
    local name = boss ~= nil and GameData.get_boss_title(boss) or id
    G.TheNet:Announce(string.format("[Boss Checklist] %s has been defeated for the first time!", name))
end

local function on_tracker_changed(tracker, id, is_defeated, source)
    if source ~= SOURCE.SHARD then
        send_to_shards("SetDefeated", nil, id, is_defeated, tracker:GetDay(id) or 0)
    end
    if is_defeated and source == SOURCE.KILL and Config.announce_kills then
        announce_first_kill(id)
    end
end

AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then
        return
    end

    local tracker = inst:AddComponent("bosschecklist_tracker")
    tracker.onchanged = on_tracker_changed

    -- Replicate once the network entity exists, then ask the other shards for their list.
    inst:DoTaskInTime(0, function()
        tracker:Replicate()
    end)
    inst:DoTaskInTime(STARTUP_SYNC_DELAY, function()
        send_to_shards("SyncAll", nil, tracker:GetSerialized(), true)
    end)
end)
