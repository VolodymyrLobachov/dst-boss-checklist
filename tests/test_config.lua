local Config = require("bosschecklist/config")

-- Loads the config from a plain table of saved options.
local function load(options)
    Config.load(function(name) return options[name] end)
end

return function(T)
    T.suite("config")

    T.test("uses the defaults when nothing is saved", function()
        load({})
        T.equal(Config.toggle_key, "B")
        T.equal(Config.show_tab, true)
        T.equal(Config.manual_marking, "none")
        T.equal(Config.reveal_mode, "progression")
        T.equal(Config.reveal_count, 2)
        T.equal(Config.minibosses, "shown")
        T.equal(Config.announce_kills, true)
    end)

    T.test("keeps a saved false instead of falling back to the default true", function()
        load({ show_tab = false, announce_kills = false })
        T.equal(Config.show_tab, false)
        T.equal(Config.announce_kills, false)
    end)

    T.test("loading again resets options that are no longer saved", function()
        load({ toggle_key = "K", reveal_count = 5 })
        load({})
        T.equal(Config.toggle_key, "B")
        T.equal(Config.reveal_count, 2)
    end)

    T.test("reveal_count is always a number of at least 1", function()
        load({ reveal_count = "3" })
        T.equal(Config.reveal_count, 3)
        load({ reveal_count = 0 })
        T.equal(Config.reveal_count, 1)
        load({ reveal_count = "nonsense" })
        T.equal(Config.reveal_count, 2)
    end)

    T.test("each player picks their own key and button, the host decides the game rules", function()
        Config.load(function(name, get_local_config)
            local player = { toggle_key = "K", show_tab = false }
            local host = { toggle_key = "B", show_tab = true, reveal_mode = "all", manual_marking = "admins" }
            return (get_local_config and player or host)[name]
        end)
        T.equal(Config.toggle_key, "K")
        T.equal(Config.show_tab, false)
        T.equal(Config.reveal_mode, "all")
        T.equal(Config.manual_marking, "admins")
    end)

    T.test("manual marking: nobody", function()
        load({ manual_marking = "none" })
        T.equal(Config.can_mark(false), false)
        T.equal(Config.can_mark(true), false)
    end)

    T.test("manual marking: admins only", function()
        load({ manual_marking = "admins" })
        T.equal(Config.can_mark(false), false)
        T.equal(Config.can_mark(nil), false)
        T.equal(Config.can_mark(true), true)
    end)

    T.test("manual marking: everyone", function()
        load({ manual_marking = "all" })
        T.equal(Config.can_mark(false), true)
        T.equal(Config.can_mark(true), true)
    end)

    -- Leave the defaults behind for the other suites.
    load({})
end
