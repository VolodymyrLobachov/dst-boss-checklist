-- Boss Checklist - which bosses the book reveals. Pure logic, no game calls.
--
-- Defeated bosses are always revealed. Optional mini-bosses are always revealed and never block
-- anything. Of the remaining bosses only the first `reveal_count` in progression order are
-- revealed (so one that can't be reached yet can be skipped); the rest are locked.

local Progression = {}

local STATUS =
{
    DEFEATED = "defeated",
    OPTIONAL = "optional",  -- undefeated mini-boss outside the progression
    NEXT = "next",          -- first undefeated boss
    UPCOMING = "upcoming",  -- revealed ahead of time, after NEXT
    PENDING = "pending",    -- undefeated, in "all visible" mode
    LOCKED = "locked",      -- hidden until defeated or reached
}
Progression.STATUS = STATUS

local function is_optional(boss, config)
    return boss.optional == true and config.minibosses ~= "progression"
end

-- bosses:   array of boss definitions in progression order
-- defeated: { [boss.id] = day }
-- config:   needs reveal_mode, reveal_count, minibosses
-- Returns { status = { [index] = STATUS.* }, defeated_count = n, current_index = index or nil },
-- where current_index is the first undefeated main boss (nil when all of them are defeated).
function Progression.compute(bosses, defeated, config)
    local reveal_all = config.reveal_mode == "all"
    local state = { status = {}, defeated_count = 0, current_index = nil }
    local ahead = 0

    for i, boss in ipairs(bosses) do
        local status
        if defeated[boss.id] ~= nil then
            status = STATUS.DEFEATED
            state.defeated_count = state.defeated_count + 1
        elseif is_optional(boss, config) then
            status = STATUS.OPTIONAL
        else
            if state.current_index == nil then
                state.current_index = i
            end
            if reveal_all then
                status = STATUS.PENDING
            elseif ahead < config.reveal_count then
                ahead = ahead + 1
                status = ahead == 1 and STATUS.NEXT or STATUS.UPCOMING
            else
                status = STATUS.LOCKED
            end
        end
        state.status[i] = status
    end
    return state
end

-- Indexes of the bosses that must be defeated to reveal more (NEXT and UPCOMING), in order.
function Progression.get_upcoming(state)
    local indexes = {}
    for i, status in ipairs(state.status) do
        if status == STATUS.NEXT or status == STATUS.UPCOMING then
            indexes[#indexes + 1] = i
        end
    end
    return indexes
end

return Progression
