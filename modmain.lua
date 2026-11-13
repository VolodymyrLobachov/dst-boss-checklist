-- Boss Checklist - entry point. Loads the settings, then the three parts of the mod.

local Config = GLOBAL.require("bosschecklist/config")
Config.load(GetModConfigData)

modimport("main/sync.lua")   -- defeated-boss list: saving, clients, shards, manual marking
modimport("main/kills.lua")  -- kill detection
modimport("main/hud.lua")    -- the book, its hotkey and mouse wheel
