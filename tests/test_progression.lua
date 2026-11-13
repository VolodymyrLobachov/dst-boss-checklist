local Progression = require("bosschecklist/progression")
local STATUS = Progression.STATUS

-- Five main bosses with two mini-bosses in between, in progression order.
local BOSSES =
{
    { id = "mini1", optional = true },
    { id = "a" },
    { id = "b" },
    { id = "mini2", optional = true },
    { id = "c" },
    { id = "d" },
    { id = "e" },
}

local function config(overrides)
    local result = { reveal_mode = "progression", reveal_count = 2, minibosses = "shown" }
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

-- Statuses of BOSSES as { id = status }, which reads better in a failure than indexes.
local function statuses(defeated, overrides)
    local state = Progression.compute(BOSSES, defeated, config(overrides))
    local by_id = {}
    for i, boss in ipairs(BOSSES) do
        by_id[boss.id] = state.status[i]
    end
    return by_id, state
end

return function(T)
    T.suite("progression")

    T.test("new world: the first two main bosses are revealed, mini-bosses are always shown", function()
        local by_id, state = statuses({})
        T.equal(by_id, {
            mini1 = STATUS.OPTIONAL,
            a = STATUS.NEXT,
            b = STATUS.UPCOMING,
            mini2 = STATUS.OPTIONAL,
            c = STATUS.LOCKED,
            d = STATUS.LOCKED,
            e = STATUS.LOCKED,
        })
        T.equal(state.defeated_count, 0)
        T.equal(state.current_index, 2)
    end)

    T.test("defeating the next boss moves the window forward", function()
        local by_id, state = statuses({ a = 5 })
        T.equal(by_id.a, STATUS.DEFEATED)
        T.equal(by_id.b, STATUS.NEXT)
        T.equal(by_id.c, STATUS.UPCOMING)
        T.equal(by_id.d, STATUS.LOCKED)
        T.equal(state.current_index, 3)
    end)

    T.test("a boss can be skipped: defeating the second one reveals the third", function()
        local by_id, state = statuses({ b = 5 })
        T.equal(by_id.a, STATUS.NEXT)
        T.equal(by_id.b, STATUS.DEFEATED)
        T.equal(by_id.c, STATUS.UPCOMING)
        T.equal(by_id.d, STATUS.LOCKED)
        T.equal(state.current_index, 2)
    end)

    T.test("a boss defeated out of order is revealed without unlocking the ones before it", function()
        local by_id = statuses({ e = 5 })
        T.equal(by_id.e, STATUS.DEFEATED)
        T.equal(by_id.c, STATUS.LOCKED)
        T.equal(by_id.d, STATUS.LOCKED)
    end)

    T.test("mini-bosses do not take a place in the window, defeated or not", function()
        local by_id, state = statuses({ mini1 = 3 })
        T.equal(by_id.mini1, STATUS.DEFEATED)
        T.equal(by_id.a, STATUS.NEXT)
        T.equal(by_id.b, STATUS.UPCOMING)
        T.equal(by_id.c, STATUS.LOCKED)
        T.equal(state.defeated_count, 1)
    end)

    T.test("a day of 0 (unknown) still counts as defeated", function()
        local by_id = statuses({ a = 0 })
        T.equal(by_id.a, STATUS.DEFEATED)
    end)

    T.test("reveal_count changes how many bosses are shown ahead", function()
        local one = statuses({}, { reveal_count = 1 })
        T.equal(one.a, STATUS.NEXT)
        T.equal(one.b, STATUS.LOCKED)

        local three = statuses({}, { reveal_count = 3 })
        T.equal(three.b, STATUS.UPCOMING)
        T.equal(three.c, STATUS.UPCOMING)
        T.equal(three.d, STATUS.LOCKED)
    end)

    T.test("mini-bosses set to 'progression' are locked and unlocked like any other boss", function()
        local by_id, state = statuses({}, { minibosses = "progression" })
        T.equal(by_id.mini1, STATUS.NEXT)
        T.equal(by_id.a, STATUS.UPCOMING)
        T.equal(by_id.b, STATUS.LOCKED)
        T.equal(by_id.mini2, STATUS.LOCKED)
        T.equal(state.current_index, 1)
    end)

    T.test("'all visible' mode locks nothing and names no next boss", function()
        local by_id, state = statuses({ a = 5 }, { reveal_mode = "all" })
        T.equal(by_id, {
            mini1 = STATUS.OPTIONAL,
            a = STATUS.DEFEATED,
            b = STATUS.PENDING,
            mini2 = STATUS.OPTIONAL,
            c = STATUS.PENDING,
            d = STATUS.PENDING,
            e = STATUS.PENDING,
        })
        T.equal(state.current_index, 3)
    end)

    T.test("everything defeated: no current boss", function()
        local defeated = {}
        for _, boss in ipairs(BOSSES) do
            defeated[boss.id] = 1
        end
        local _, state = statuses(defeated)
        T.equal(state.defeated_count, #BOSSES)
        T.equal(state.current_index, nil)
    end)

    T.test("all main bosses defeated, mini-bosses left: no current boss, nothing locked", function()
        local by_id, state = statuses({ a = 1, b = 1, c = 1, d = 1, e = 1 })
        T.equal(state.current_index, nil)
        T.equal(by_id.mini1, STATUS.OPTIONAL)
        T.equal(by_id.mini2, STATUS.OPTIONAL)
    end)

    T.test("fewer bosses left than the window: the last one is just the next", function()
        local by_id = statuses({ a = 1, b = 1, c = 1, d = 1 })
        T.equal(by_id.e, STATUS.NEXT)
    end)

    T.test("get_upcoming lists the next and upcoming bosses in order", function()
        local _, state = statuses({ a = 5 })
        T.equal(Progression.get_upcoming(state), { 3, 5 })
    end)

    T.test("get_upcoming is empty when nothing is left or in 'all visible' mode", function()
        local _, all_mode = statuses({}, { reveal_mode = "all" })
        T.equal(Progression.get_upcoming(all_mode), {})
        local _, done = statuses({ a = 1, b = 1, c = 1, d = 1, e = 1 })
        T.equal(Progression.get_upcoming(done), {})
    end)
end
