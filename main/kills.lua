-- Boss Checklist - detects that a boss was defeated (imported by modmain, acts on the server only).
--
-- A boss counts as defeated when one of these happens to one of its prefabs:
--   * it fires "death"                                  (most bosses)
--   * it enters a stategraph state tagged "defeated"    (Frostjaw gives up instead of dying)
--   * its lootdropper drops the loot                    (Nightmare Werepig; Poison Birchnut Tree)

local G = GLOBAL
local require = G.require

local Registry = require("bosschecklist/registry")

-- Bosses with several "deaths" (e.g. Klaus) only count once every final_check passes.
local function is_final_defeat(inst, bosses)
    for _, boss in ipairs(bosses) do
        if boss.final_check ~= nil and not boss.final_check(inst) then
            return false
        end
    end
    return true
end

-- Bosses made of several prefabs (e.g. the Twins of Terror) need all of them defeated.
local function is_complete(boss, tracker)
    if boss.require_all then
        for _, prefab in ipairs(boss.prefabs) do
            if not tracker:HasPrefabKill(prefab) then
                return false
            end
        end
    end
    return true
end

local function on_boss_defeated(inst)
    local bosses = Registry.by_prefab[inst.prefab]
    if bosses == nil or inst._bosschecklist_counted or not is_final_defeat(inst, bosses) then
        return
    end
    -- The same entity can report its defeat in several ways (death + loot); count it once.
    inst._bosschecklist_counted = true

    local tracker = G.TheWorld.components.bosschecklist_tracker
    if tracker == nil then
        return
    end
    tracker:RecordPrefabKill(inst.prefab)
    for _, boss in ipairs(bosses) do
        if is_complete(boss, tracker) then
            tracker:SetDefeated(boss.id)
        end
    end
end

local function on_new_state(inst)
    if inst.sg ~= nil and inst.sg:HasStateTag("defeated") then
        on_boss_defeated(inst)
    end
end

local function watch_creature(inst)
    if not G.TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("death", on_boss_defeated)
    inst:ListenForEvent("newstate", on_new_state)
end

-- loot_only bosses are not creatures (e.g. a tree), so the events above mean nothing for them
-- and there can be hundreds of them in a world: leave those to the loot hook alone.
local function needs_creature_events(bosses)
    for _, boss in ipairs(bosses) do
        if not boss.loot_only then
            return true
        end
    end
    return false
end

for prefab, bosses in pairs(Registry.by_prefab) do
    if needs_creature_events(bosses) then
        AddPrefabPostInit(prefab, watch_creature)
    end
end

AddComponentPostInit("lootdropper", function(self)
    local drop_loot = self.DropLoot
    function self:DropLoot(...)
        if G.TheWorld.ismastersim then
            on_boss_defeated(self.inst)
        end
        return drop_loot(self, ...)
    end
end)
