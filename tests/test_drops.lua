local Drops = require("bosschecklist/drops")
local Fakes = require("fakes")

-- Drops of a boss as { prefab = amount label }.
local function amounts(boss)
    local result = {}
    for _, drop in ipairs(Drops.for_boss(boss)) do
        result[drop.prefab] = drop.amount
    end
    return result
end

-- The one drop of a boss whose loot table "t" holds the given rolls of "item".
local function single(chances)
    local rows = {}
    for i, chance in ipairs(chances) do
        rows[i] = { "item", chance }
    end
    Fakes.set_loot_tables({ t = rows })
    return Drops.for_boss({ loot_table = "t" })[1]
end

return function(T)
    T.suite("drops")
    Fakes.set_names({ ITEM = "Item", MEAT = "Meat" })

    T.test("guaranteed drops are counted", function()
        local drop = single({ 1, 1, 1 })
        T.equal(drop.amount, "x3")
        T.equal(drop.details, "Always drops 3.")
    end)

    T.test("a single chance is shown as a percentage", function()
        local drop = single({ 0.33 })
        T.equal(drop.amount, "33%")
        T.equal(drop.details, "33% chance to drop.")
    end)

    T.test("small chances keep one decimal", function()
        T.equal(single({ 0.05 }).amount, "5.0%")
        T.equal(single({ 0.005 }).amount, "0.5%")
    end)

    T.test("guaranteed plus chances become a range, equal chances are grouped", function()
        local drop = single({ 1, 1, 1, 1, 0.5, 0.5, 0.25 })
        T.equal(drop.amount, "x4-7")
        T.equal(drop.details, "Drops 4 to 7.\nAlways 4. Chance for each extra one: 50% (x2), 25%.")
    end)

    T.test("several chances without a guaranteed drop start the range at 0", function()
        local drop = single({ 0.5, 0.25 })
        T.equal(drop.amount, "x0-2")
        T.equal(drop.details, "Drops 0 to 2.\nChance for each extra one: 50%, 25%.")
    end)

    T.test("a chance of 1 or more, or no chance at all, is guaranteed", function()
        Fakes.set_loot_tables({ t = { { "item", 1.0 }, { "item", 2 }, { "item" } } })
        T.equal(Drops.for_boss({ loot_table = "t" })[1].amount, "x3")
    end)

    T.test("drops keep the order of first appearance and carry the item name", function()
        Fakes.set_loot_tables({ t = { { "meat", 1 }, { "item", 1 }, { "meat", 0.5 } } })
        local drops = Drops.for_boss({ loot_table = "t" })
        T.equal(#drops, 2)
        T.equal(drops[1].prefab, "meat")
        T.equal(drops[1].name, "Meat")
        T.equal(drops[1].amount, "x1-2")
        T.equal(drops[2].prefab, "item")
    end)

    T.test("several loot tables are added together", function()
        Fakes.set_loot_tables({ one = { { "item", 1 }, { "meat", 1 } }, two = { { "item", 1 } } })
        T.equal(amounts({ loot_table = { "one", "two" } }), { item = "x2", meat = "x1" })
    end)

    T.test("extra_drops are added to the loot table, with count and chance", function()
        Fakes.set_loot_tables({ t = { { "item", 1 } } })
        local boss = {
            loot_table = "t",
            extra_drops =
            {
                { prefab = "item", count = 2 },
                { prefab = "item", count = 2, chance = 0.5 },
                { prefab = "meat", chance = 0.2 },
            },
        }
        T.equal(amounts(boss), { item = "x3-5", meat = "20%" })
    end)

    T.test("a note marks the amount with * and is added to the details", function()
        Fakes.set_loot_tables({})
        local drop = Drops.for_boss({ extra_drops = { { prefab = "item", note = "Only from a level 3 piece." } } })[1]
        T.equal(drop.amount, "x1*")
        T.equal(drop.details, "Always drops 1.\nOnly from a level 3 piece.")
    end)

    T.test("a missing loot table or a boss without loot gives no drops instead of an error", function()
        Fakes.set_loot_tables({})
        T.equal(Drops.for_boss({ loot_table = "renamed_by_an_update" }), {})
        T.equal(Drops.for_boss({}), {})
    end)

    T.test("loot table rows that are not items are ignored", function()
        Fakes.set_loot_tables({ t = { { 42, 1 }, {}, { "item", 1 } } })
        T.equal(amounts({ loot_table = "t" }), { item = "x1" })
    end)
end
