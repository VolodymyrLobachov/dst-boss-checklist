-- Boss Checklist - lookup tables over the boss definitions.

local BOSSES = require("bosschecklist/bosses")

local Registry =
{
    list = BOSSES,   -- array, in progression order
    by_id = {},      -- [boss.id] = boss
    by_prefab = {},  -- [prefab] = { boss, ... }
}

for _, boss in ipairs(BOSSES) do
    assert(Registry.by_id[boss.id] == nil, "Boss Checklist: duplicate boss id " .. tostring(boss.id))
    Registry.by_id[boss.id] = boss
    for _, prefab in ipairs(boss.prefabs) do
        local bosses = Registry.by_prefab[prefab]
        if bosses == nil then
            bosses = {}
            Registry.by_prefab[prefab] = bosses
        end
        bosses[#bosses + 1] = boss
    end
end

return Registry
