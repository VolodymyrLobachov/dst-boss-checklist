-- Boss Checklist - what a boss drops, in a form the book can show.
-- Loot tables are read from the game (LootTables global), so chances follow game updates.
-- Drops that the game builds in code come from boss.extra_drops.

local GameData = require("bosschecklist/gamedata")

local Drops = {}

local function format_chance(chance)
    local percent = chance * 100
    if percent >= 10 then
        return string.format("%d%%", math.floor(percent + .5))
    end
    return string.format("%.1f%%", percent)
end

-- Groups equal chances: { .5, .5, .25 } -> "50% (x2), 25%".
local function describe_chances(chances)
    local order, counts = {}, {}
    for _, chance in ipairs(chances) do
        local text = format_chance(chance)
        if counts[text] == nil then
            counts[text] = 0
            order[#order + 1] = text
        end
        counts[text] = counts[text] + 1
    end
    for i, text in ipairs(order) do
        if counts[text] > 1 then
            order[i] = string.format("%s (x%d)", text, counts[text])
        end
    end
    return table.concat(order, ", ")
end

-- guaranteed: how many always drop.  chances: list of chances, each for one extra item.
-- Returns a short label for under the icon and a full explanation for the hover text:
--   (2, {})         -> "x2",   "Always drops 2."
--   (0, { .33 })    -> "33%",  "33% chance to drop."
--   (4, { .5, .5 }) -> "x4-6", "Drops 4 to 6.\nAlways 4. Chance for each extra one: 50% (x2)."
local function describe_amount(guaranteed, chances)
    local extra = #chances
    if extra == 0 then
        return "x" .. guaranteed, "Always drops " .. guaranteed .. "."
    end
    if guaranteed == 0 and extra == 1 then
        local text = format_chance(chances[1])
        return text, text .. " chance to drop."
    end

    local most = guaranteed + extra
    local short = string.format("x%d-%d", guaranteed, most)
    local long = string.format("Drops %d to %d.\n%sChance for each extra one: %s.",
        guaranteed, most,
        guaranteed > 0 and ("Always " .. guaranteed .. ". ") or "",
        describe_chances(chances))
    return short, long
end

-- Collects every loot roll of a boss per prefab, keeping the order of first appearance.
-- Returns an array of { prefab, guaranteed, chances, note }.
local function collect_rolls(boss)
    local rolls, by_prefab = {}, {}

    local function add(prefab, chance, note)
        local roll = by_prefab[prefab]
        if roll == nil then
            roll = { prefab = prefab, guaranteed = 0, chances = {}, note = note }
            by_prefab[prefab] = roll
            rolls[#rolls + 1] = roll
        end
        if chance == nil or chance >= 1 then
            roll.guaranteed = roll.guaranteed + 1
        else
            roll.chances[#roll.chances + 1] = chance
        end
    end

    local table_names = boss.loot_table
    if type(table_names) == "string" then
        table_names = { table_names }
    end
    -- rawget: the game's strict mode raises an error when reading a global that does not exist.
    local loot_tables = rawget(_G, "LootTables")
    if table_names ~= nil and loot_tables ~= nil then
        for _, name in ipairs(table_names) do
            for _, row in ipairs(loot_tables[name] or {}) do
                if type(row[1]) == "string" then
                    add(row[1], row[2])
                end
            end
        end
    end

    for _, drop in ipairs(boss.extra_drops or {}) do
        for _ = 1, drop.count or 1 do
            add(drop.prefab, drop.chance, drop.note)
        end
    end

    return rolls
end

-- Returns an array of { prefab, name, amount, details }:
--   amount   short label ("x2", "x4-8", "33%"; a "*" marks a drop with a condition)
--   details  full explanation for the hover text
function Drops.for_boss(boss)
    local drops = {}
    for i, roll in ipairs(collect_rolls(boss)) do
        local amount, details = describe_amount(roll.guaranteed, roll.chances)
        if roll.note ~= nil then
            amount = amount .. "*"
            details = details .. "\n" .. roll.note
        end
        drops[i] = {
            prefab = roll.prefab,
            name = GameData.get_prefab_name(roll.prefab),
            amount = amount,
            details = details,
        }
    end
    return drops
end

return Drops
