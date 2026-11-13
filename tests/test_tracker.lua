local Tracker = require("components/bosschecklist_tracker")
local Fakes = require("fakes")
local SOURCE = Tracker.SOURCE

-- A tracker that records every change notification as { id, is_defeated, source }.
local function new_tracker()
    local tracker = Tracker({})
    local changes = {}
    tracker.onchanged = function(_, id, is_defeated, source)
        changes[#changes + 1] = { id, is_defeated, source }
    end
    return tracker, changes
end

return function(T)
    T.suite("tracker")

    T.test("a kill is recorded with the current day and reported once", function()
        Fakes.set_day(12)
        local tracker, changes = new_tracker()
        T.equal(tracker:SetDefeated("deerclops"), true)
        T.equal(tracker:IsDefeated("deerclops"), true)
        T.equal(tracker:GetDay("deerclops"), 12)
        T.equal(changes, { { "deerclops", true, SOURCE.KILL } })
    end)

    T.test("only the first defeat counts: the day is kept and nothing is reported again", function()
        Fakes.set_day(12)
        local tracker, changes = new_tracker()
        tracker:SetDefeated("deerclops")
        Fakes.set_day(40)
        T.equal(tracker:SetDefeated("deerclops"), false)
        T.equal(tracker:GetDay("deerclops"), 12)
        T.equal(#changes, 1)
    end)

    T.test("a day given by another shard is kept; 0 or nil means today", function()
        Fakes.set_day(50)
        local tracker, changes = new_tracker()
        tracker:SetDefeated("bearger", 7, SOURCE.SHARD)
        tracker:SetDefeated("moose", 0, SOURCE.SHARD)
        T.equal(tracker:GetDay("bearger"), 7)
        T.equal(tracker:GetDay("moose"), 50)
        T.equal(changes[1], { "bearger", true, SOURCE.SHARD })
    end)

    T.test("clearing removes the boss and reports it with its source", function()
        local tracker, changes = new_tracker()
        tracker:SetDefeated("deerclops")
        T.equal(tracker:ClearDefeated("deerclops", SOURCE.MANUAL), true)
        T.equal(tracker:IsDefeated("deerclops"), false)
        T.equal(tracker:GetDay("deerclops"), nil)
        T.equal(changes[2], { "deerclops", false, SOURCE.MANUAL })
    end)

    T.test("clearing a boss that is not defeated does nothing", function()
        local tracker, changes = new_tracker()
        T.equal(tracker:ClearDefeated("deerclops"), false)
        T.equal(changes, {})
    end)

    T.test("works without a change listener", function()
        local tracker = Tracker({})
        T.equal(tracker:SetDefeated("deerclops"), true)
    end)

    T.test("prefab kills are remembered per prefab", function()
        local tracker = new_tracker()
        tracker:RecordPrefabKill("twinofterror1")
        T.equal(tracker:HasPrefabKill("twinofterror1"), true)
        T.equal(tracker:HasPrefabKill("twinofterror2"), false)
    end)

    T.test("serialized list matches the defeated bosses", function()
        local tracker = new_tracker()
        tracker:SetDefeated("deerclops", 30)
        tracker:SetDefeated("bearger", 12)
        T.equal(tracker:GetSerialized(), "bearger:12,deerclops:30")
    end)

    T.test("save and load restore defeated bosses and prefab kills without reporting changes", function()
        local saved_tracker = new_tracker()
        saved_tracker:SetDefeated("deerclops", 30)
        saved_tracker:RecordPrefabKill("twinofterror1")
        local data = saved_tracker:OnSave()

        local tracker, changes = new_tracker()
        tracker:OnLoad(data)
        T.equal(tracker:GetDay("deerclops"), 30)
        T.equal(tracker:HasPrefabKill("twinofterror1"), true)
        T.equal(changes, {})
    end)

    T.test("loads saves from before 0.4, where the day was stored as { day = n }", function()
        local tracker = new_tracker()
        tracker:OnLoad({ defeated = { deerclops = { day = 30 }, bearger = {} }, prefab_kills = { "shadow_rook" } })
        T.equal(tracker:GetDay("deerclops"), 30)
        T.equal(tracker:GetDay("bearger"), 0)
        T.equal(tracker:IsDefeated("bearger"), true)
        T.equal(tracker:HasPrefabKill("shadow_rook"), true)
    end)

    T.test("loading nothing or an empty save is fine", function()
        local tracker = new_tracker()
        tracker:OnLoad(nil)
        tracker:OnLoad({})
        T.equal(tracker:GetSerialized(), "")
    end)
end
