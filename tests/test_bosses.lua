-- Checks the boss definitions themselves: a typo in bosses.lua should fail here, not in the game.

local Registry = require("bosschecklist/registry")

local MINI_BOSSES = { "spiderqueen", "leif", "lordfruitfly", "deciduous_monster", "spat", "warg" }

local function index_of(id)
    for i, boss in ipairs(Registry.list) do
        if boss.id == id then
            return i
        end
    end
    error("no boss with id " .. id)
end

return function(T)
    T.suite("bosses")

    T.test("every boss has the fields the book and the kill detection need", function()
        for _, boss in ipairs(Registry.list) do
            local where = "boss " .. tostring(boss.id)
            T.truthy(type(boss.id) == "string" and boss.id:match("^[%w_]+$"), where .. ": id must be letters, digits, _")
            T.truthy(type(boss.prefabs) == "table" and #boss.prefabs > 0, where .. ": needs prefabs")
            T.truthy(boss.title ~= nil or boss.title_prefab ~= nil, where .. ": needs title or title_prefab")
            T.truthy(type(boss.scrapbook) == "string", where .. ": needs scrapbook")
            T.truthy(boss.loot_table ~= nil or boss.extra_drops ~= nil, where .. ": needs loot_table or extra_drops")
            for _, field in ipairs({ "category", "location", "when", "summon", "tips" }) do
                T.truthy(type(boss[field]) == "string" and boss[field] ~= "", where .. ": needs " .. field)
            end
        end
    end)

    T.test("extra drops are well formed", function()
        for _, boss in ipairs(Registry.list) do
            for _, drop in ipairs(boss.extra_drops or {}) do
                local where = "boss " .. boss.id .. " extra drop " .. tostring(drop.prefab)
                T.truthy(type(drop.prefab) == "string", where .. ": needs prefab")
                T.truthy(drop.count == nil or (type(drop.count) == "number" and drop.count >= 1), where .. ": bad count")
                T.truthy(drop.chance == nil or (drop.chance > 0 and drop.chance <= 1), where .. ": chance must be in (0, 1]")
            end
        end
    end)

    T.test("the registry finds every boss by id and by each of its prefabs", function()
        for _, boss in ipairs(Registry.list) do
            T.equal(Registry.by_id[boss.id], boss)
            for _, prefab in ipairs(boss.prefabs) do
                local found = false
                for _, candidate in ipairs(Registry.by_prefab[prefab]) do
                    found = found or candidate == boss
                end
                T.truthy(found, boss.id .. " is not registered for prefab " .. prefab)
            end
        end
    end)

    T.test("every boss has a place in the progression order", function()
        -- Bosses missing from ORDER get a sort key of 1000 or more and end up last.
        for _, boss in ipairs(Registry.list) do
            T.truthy(boss._sort < 1000, "boss " .. boss.id .. " is missing from ORDER in bosses.lua")
        end
    end)

    T.test("exactly the chance-based mini-bosses are optional", function()
        local optional = {}
        for _, boss in ipairs(Registry.list) do
            if boss.optional then
                optional[#optional + 1] = boss.id
            end
        end
        table.sort(optional)
        table.sort(MINI_BOSSES)
        T.equal(optional, MINI_BOSSES)
    end)

    T.test("the progression starts with Deerclops and keeps the questline order", function()
        local first_main
        for _, boss in ipairs(Registry.list) do
            if not boss.optional then
                first_main = boss.id
                break
            end
        end
        T.equal(first_main, "deerclops")
        -- Bosses that need the previous one's loot or event must come after it.
        T.truthy(index_of("minotaur") < index_of("stalker_atrium"), "Ancient Guardian before Fuelweaver")
        T.truthy(index_of("eyeofterror") < index_of("twinsofterror"), "Eye of Terror before the Twins")
        T.truthy(index_of("toadstool") < index_of("toadstool_dark"), "Toadstool before Misery Toadstool")
        T.truthy(index_of("wagboss_robot") < index_of("alterguardian_scion"), "W.A.R.B.O.T. before Celestial Scion")
    end)

    T.test("a multi-death boss check and a loot-only boss check behave as documented", function()
        local klaus = Registry.by_id.klaus
        T.equal(klaus.final_check({ IsUnchained = function() return false end }), false)
        T.equal(klaus.final_check({ IsUnchained = function() return true end }), true)

        local tree = Registry.by_id.deciduous_monster
        T.equal(tree.loot_only, true)
        T.equal(tree.final_check({ monster = true }), true)
        T.equal(tree.final_check({ monster = false }), false)
        T.equal(tree.final_check({}), false)
    end)
end
