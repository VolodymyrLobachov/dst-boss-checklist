-- Boss Checklist - mod settings.
-- modmain calls Config.load() once; every other file just requires this module and reads fields.

local DEFAULTS =
{
    toggle_key = "B",
    show_tab = true,
    manual_marking = "none",     -- "all" | "admins" | "none"
    reveal_mode = "progression", -- "progression" | "all"
    reveal_count = 2,            -- undefeated bosses shown at once in progression mode
    minibosses = "shown",        -- "shown" | "progression"
    announce_kills = true,
}

-- Set by each player for themselves (`client = true` in modinfo).
local CLIENT_OPTIONS =
{
    toggle_key = true,
    show_tab = true,
}

local Config =
{
    RPC_NAMESPACE = "BossChecklist",
}

for name, value in pairs(DEFAULTS) do
    Config[name] = value
end

-- get_option: fn(name, get_local_config) returning the saved value of a mod option, or nil (GetModConfigData).
function Config.load(get_option)
    assert(type(get_option) == "function", "Config.load expects a function")
    for name, default in pairs(DEFAULTS) do
        local value = get_option(name, CLIENT_OPTIONS[name] == true)
        -- Explicit nil check: `false` is a valid saved value.
        if value == nil then
            value = default
        end
        Config[name] = value
    end
    Config.reveal_count = math.max(1, tonumber(Config.reveal_count) or DEFAULTS.reveal_count)
end

-- May a player mark bosses by hand? Used by the server (to check) and the client (to show the button).
function Config.can_mark(is_admin)
    if Config.manual_marking == "all" then
        return true
    end
    return Config.manual_marking == "admins" and is_admin == true
end

return Config
