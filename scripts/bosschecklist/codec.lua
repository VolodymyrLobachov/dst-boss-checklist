-- Boss Checklist - text format of the defeated-boss list.
-- The same string is used for the client netvar and for shard-to-shard sync:
--   { deerclops = 30, bearger = 12 }  <->  "bearger:12,deerclops:30"
-- The number is the day of the first defeat (0 = unknown).

local Codec = {}

function Codec.encode(defeated)
    local parts = {}
    for id, day in pairs(defeated) do
        parts[#parts + 1] = id .. ":" .. tostring(day or 0)
    end
    table.sort(parts) -- stable output, so an unchanged list does not dirty the netvar
    return table.concat(parts, ",")
end

-- Returns { [boss_id] = day }. Anything that is not a string decodes to an empty table.
function Codec.decode(str)
    local defeated = {}
    if type(str) == "string" then
        for id, day in string.gmatch(str, "([%w_]+):(%d+)") do
            defeated[id] = tonumber(day) or 0
        end
    end
    return defeated
end

return Codec
