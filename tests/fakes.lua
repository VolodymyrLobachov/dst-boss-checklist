-- Boss Checklist tests - minimal stand-ins for the game globals the tested modules use.

local Fakes = {}

-- The game's Class(): calling the class creates an instance and runs the constructor.
local function Class(ctor)
    local class = {}
    class.__index = class
    return setmetatable(class, {
        __call = function(_, ...)
            local instance = setmetatable({}, class)
            ctor(instance, ...)
            return instance
        end,
    })
end

-- The game's subfmt(): subfmt("{item} Sketch", { item = "Figure" }) -> "Figure Sketch".
local function subfmt(format, values)
    return (string.gsub(format, "{(%w+)}", values))
end

function Fakes.install()
    _G.Class = Class
    _G.subfmt = subfmt
    _G.STRINGS = { NAMES = {} }
    _G.LootTables = {}
    _G.TheWorld = { state = { cycles = 0 }, net = nil }

    -- Like the game's strict mode: reading a global that was never set is an error, so a
    -- misspelled name in the tested code fails the test instead of silently being nil.
    setmetatable(_G, {
        __index = function(_, name)
            error("read of undeclared global '" .. tostring(name) .. "'", 2)
        end,
    })
end

-- Replaces the fake item names: Fakes.set_names({ MEAT = "Meat" }).
function Fakes.set_names(names)
    STRINGS.NAMES = names
end

-- Replaces the fake loot tables: Fakes.set_loot_tables({ deerclops = { { "meat", 1 } } }).
function Fakes.set_loot_tables(tables)
    LootTables = tables
end

-- Sets the current day of the fake world (the game counts cycles from 0, so day = cycles + 1).
function Fakes.set_day(day)
    TheWorld.state.cycles = day - 1
end

return Fakes
