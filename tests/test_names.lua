local GameData = require("bosschecklist/gamedata")
local Fakes = require("fakes")

return function(T)
    T.suite("names")

    Fakes.set_names({
        DEERCLOPS = "Deerclops",
        TRIDENT = "Strident Trident",
        CHESSPIECE_DEERCLOPS = "Deerclops Figure",
        BLUEPRINT = "Blueprint",
        SKETCH = "{item} Sketch",
    })

    T.test("a prefab uses the game's name", function()
        T.equal(GameData.get_prefab_name("deerclops"), "Deerclops")
    end)

    T.test("a blueprint is named after its item", function()
        T.equal(GameData.get_prefab_name("trident_blueprint"), "Strident Trident Blueprint")
    end)

    T.test("a sketch is named after its figure, using the game's format", function()
        T.equal(GameData.get_prefab_name("chesspiece_deerclops_sketch"), "Deerclops Figure Sketch")
    end)

    T.test("an unknown prefab gets a readable name instead of an error", function()
        T.equal(GameData.get_prefab_name("some_new_item"), "Some new item")
        T.equal(GameData.get_prefab_name("unknown_blueprint"), "Unknown blueprint")
    end)

    T.test("a boss title prefers the fixed title, then title_prefab, then the first prefab", function()
        T.equal(GameData.get_boss_title({ title = "Twins of Terror", prefabs = { "deerclops" } }), "Twins of Terror")
        T.equal(GameData.get_boss_title({ title_prefab = "deerclops", prefabs = { "trident" } }), "Deerclops")
        T.equal(GameData.get_boss_title({ prefabs = { "trident" } }), "Strident Trident")
    end)
end
