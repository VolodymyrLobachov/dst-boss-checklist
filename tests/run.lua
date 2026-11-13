-- Boss Checklist - unit tests for the game-independent logic.
-- Run from the mod folder:   lua tests/run.lua
--
-- Only business rules are tested (what is revealed, how drops are worded, what is saved...).
-- Code that just talks to the game (widgets, RPCs, atlases) is not: it needs the game to run.
-- The few game globals the tested modules touch are replaced by small fakes in tests/fakes.lua.

package.path = "scripts/?.lua;tests/?.lua;" .. package.path

local passed, failed = 0, {}
local current_suite = ""

-- Readable form of any value; tables are printed with sorted keys so equal tables print equally.
local function dump(value)
    if type(value) ~= "table" then
        return type(value) == "string" and string.format("%q", value) or tostring(value)
    end
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for i, key in ipairs(keys) do
        parts[i] = "[" .. dump(key) .. "]=" .. dump(value[key])
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function deep_equal(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if not deep_equal(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

local T = {}

function T.suite(name)
    current_suite = name
end

function T.test(name, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if ok then
        passed = passed + 1
    else
        failed[#failed + 1] = current_suite .. ": " .. name .. "\n    " .. tostring(err):gsub("\n", "\n    ")
    end
end

-- Compares deeply, so tables can be compared with tables.
function T.equal(actual, expected, what)
    if not deep_equal(actual, expected) then
        error(string.format("%s\n  expected: %s\n  actual:   %s", what or "values differ", dump(expected), dump(actual)), 2)
    end
end

function T.truthy(value, what)
    if not value then
        error(what or "expected a true value", 2)
    end
end

require("fakes").install()

local SUITES = { "test_codec", "test_config", "test_progression", "test_drops", "test_names", "test_tracker", "test_bosses" }
for _, name in ipairs(SUITES) do
    require(name)(T)
end

for _, message in ipairs(failed) do
    print("FAIL " .. message)
end
print(string.format("%d passed, %d failed", passed, #failed))
os.exit(#failed == 0 and 0 or 1)
