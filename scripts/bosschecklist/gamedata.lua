-- Boss Checklist - reads live game data: names, icons, Scrapbook stats, respawn times.
-- Everything here is defensive: if a game update renames something, the book shows less
-- information instead of crashing.

local GameData = {}

local _scrapbook = nil -- table once loaded, false if it could not be loaded

local function get_scrapbook()
    if _scrapbook == nil then
        local ok, data = pcall(require, "screens/redux/scrapbookdata")
        _scrapbook = ok and type(data) == "table" and data or false
    end
    return _scrapbook or nil
end

local function get_scrapbook_entry(prefab)
    local data = prefab ~= nil and get_scrapbook() or nil
    return data ~= nil and data[prefab] or nil
end

-- Returns atlas, tex for a Scrapbook picture, or nil.
local function get_scrapbook_icon(tex)
    -- rawget: the game's strict mode raises an error when reading a global that does not exist.
    local get_atlas = rawget(_G, "GetScrapbookIconAtlas")
    if tex == nil or get_atlas == nil then
        return nil
    end
    local ok, atlas = pcall(get_atlas, tex)
    if ok and atlas ~= nil then
        return atlas, tex
    end
    return nil
end

-- Display name of a prefab, translated by the game. Blueprints and sketches are built from
-- the name of the item they are for.
function GameData.get_prefab_name(prefab)
    local names = STRINGS.NAMES
    local name = names[string.upper(prefab)]
    if name ~= nil then
        return name
    end

    local base = string.match(prefab, "^(.+)_blueprint$")
    local base_name = base ~= nil and names[string.upper(base)] or nil
    if base_name ~= nil then
        return base_name .. " " .. (names.BLUEPRINT or "Blueprint")
    end

    base = string.match(prefab, "^(.+)_sketch$")
    base_name = base ~= nil and names[string.upper(base)] or nil
    if base_name ~= nil then
        return subfmt(names.SKETCH or "{item} Sketch", { item = base_name })
    end

    -- Fall back to a readable version of the prefab name.
    local pretty = string.gsub(prefab, "_", " ")
    return (string.gsub(pretty, "^%l", string.upper))
end

function GameData.get_boss_title(boss)
    return boss.title or GameData.get_prefab_name(boss.title_prefab or boss.prefabs[1])
end

local function atlas_has(atlas, tex)
    local ok, result = pcall(function() return TheSim:AtlasContains(atlas, tex) end)
    return ok and result
end

local function get_item_image_candidates(prefab)
    local candidates = { prefab .. ".tex" }
    if string.match(prefab, "_sketch$") then
        candidates[#candidates + 1] = "sketch.tex"
    elseif string.match(prefab, "_blueprint$") then
        candidates[#candidates + 1] = "blueprint_rare.tex"
        candidates[#candidates + 1] = "blueprint.tex"
    else
        -- Items with random looks (e.g. Shell Bells) only have numbered images.
        candidates[#candidates + 1] = prefab .. "_1.tex"
    end
    return candidates
end

-- Returns atlas, tex for an item, or nil if no image exists.
function GameData.get_item_icon(prefab)
    for _, tex in ipairs(get_item_image_candidates(prefab)) do
        local atlas = GetInventoryItemAtlas(tex, true)
        if atlas ~= nil and atlas_has(atlas, tex) then
            return atlas, tex
        end
    end

    -- Not an inventory item (e.g. a creature that comes out of the boss): use its Scrapbook picture.
    local entry = get_scrapbook_entry(prefab)
    return get_scrapbook_icon(entry ~= nil and entry.tex or (prefab .. ".tex"))
end

-- Returns atlas, tex for the boss portrait from the Scrapbook, or nil.
function GameData.get_boss_portrait(boss)
    local entry = get_scrapbook_entry(boss.scrapbook)
    return get_scrapbook_icon(entry ~= nil and entry.tex or nil)
end

-- Numbers without a pointless ".0"; other values as text; nil stays nil.
local function format_number(value)
    if type(value) == "number" then
        if value == math.floor(value) then
            return tostring(value)
        end
        return string.format("%.1f", value)
    end
    return value ~= nil and tostring(value) or nil
end

-- Returns { health, damage, planardamage } as display strings (each may be nil), or nil.
function GameData.get_stats(boss)
    local entry = get_scrapbook_entry(boss.scrapbook)
    if entry == nil then
        return nil
    end
    return {
        health = format_number(entry.health),
        damage = format_number(entry.damage),
        planardamage = format_number(entry.planardamage),
    }
end

-- Respawn text for the book: computed from TUNING when the boss names a key, else the fixed text.
function GameData.get_respawn_text(boss)
    local seconds = boss.respawn_tuning ~= nil and TUNING[boss.respawn_tuning] or nil
    if type(seconds) == "number" and seconds > 0 then
        local days = math.floor(seconds / TUNING.TOTAL_DAY_TIME * 10 + .5) / 10
        return string.format("About %s days after it is defeated.", format_number(days))
    end
    return boss.respawn
end

return GameData
