---@diagnostic disable: lowercase-global
-- (the game reads these settings as plain globals)
name = "Boss Checklist"
description = [[A boss checklist and guide book for Don't Starve Together.

Open the book (default key: B, or the book button in the bottom-right corner) to see every boss:
- how to find or summon it
- what it drops, with exact drop chances read from the game's loot tables
- health and damage
- whether it has been defeated in this world (shared by all players and shards)]]
author = "Renco"
version = "0.5.0"

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

-- The server tracks defeated bosses and syncs them to clients, so everyone needs the mod.
client_only_mod = false
all_clients_require_mod = true
server_only_mod = false

priority = 0
server_filter_tags = { "boss checklist" }

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local keys = { "B", "C", "G", "H", "J", "K", "L", "N", "O", "P", "U", "V", "X", "Z", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12" }
local key_options = {}
for i = 1, #keys do
    key_options[i] = { description = keys[i], data = keys[i] }
end

configuration_options =
{
    {
        name = "toggle_key",
        label = "Open/close key",
        hover = "Key that opens and closes the Boss Checklist book. Each player sets this for themselves.",
        options = key_options,
        default = "B",
        client = true,
    },
    {
        name = "show_tab",
        label = "Show book button",
        hover = "Show the book button in the bottom-right corner of the screen. Each player sets this for themselves.",
        options =
        {
            { description = "Yes", data = true },
            { description = "No", data = false },
        },
        default = true,
        client = true,
    },
    {
        name = "reveal_mode",
        label = "Boss reveal",
        hover = "Progression: only the next bosses are shown, the rest stay hidden until defeated. All: every boss is visible.",
        options =
        {
            { description = "Progression", data = "progression" },
            { description = "All visible", data = "all" },
        },
        default = "progression",
    },
    {
        name = "reveal_count",
        label = "Bosses shown ahead",
        hover = "In Progression mode: how many undefeated bosses are shown at once. With 2 or more you can skip a boss you can't reach yet.",
        options =
        {
            { description = "1", data = 1 },
            { description = "2", data = 2 },
            { description = "3", data = 3 },
            { description = "5", data = 5 },
        },
        default = 2,
    },
    {
        name = "minibosses",
        label = "Mini-bosses",
        hover = "Always shown: mini-bosses that appear by chance (Treeguard, Varg...) are always visible, have their own colour and never block the progression. Progression: they are hidden and unlocked like any other boss.",
        options =
        {
            { description = "Always shown", data = "shown" },
            { description = "Progression", data = "progression" },
        },
        default = "shown",
    },
    {
        name = "manual_marking",
        label = "Manual marking",
        hover = "Who can manually mark bosses as defeated or not defeated in the book.",
        options =
        {
            { description = "Everyone", data = "all" },
            { description = "Admins only", data = "admins" },
            { description = "Nobody", data = "none" },
        },
        default = "none",
    },
    {
        name = "announce_kills",
        label = "Announce first kills",
        hover = "Announce in chat when a boss is defeated for the first time in this world.",
        options =
        {
            { description = "Yes", data = true },
            { description = "No", data = false },
        },
        default = true,
    },
}
