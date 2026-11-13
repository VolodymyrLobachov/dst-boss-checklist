local Codec = require("bosschecklist/codec")

return function(T)
    T.suite("codec")

    T.test("encodes bosses sorted by id, whatever order the table gives them in", function()
        T.equal(Codec.encode({ deerclops = 30, bearger = 12 }), "bearger:12,deerclops:30")

        -- Enough entries that an unsorted table walk cannot come out sorted by luck.
        local defeated, expected = {}, {}
        for i = 1, 40 do
            local id = string.format("boss_%02d", i)
            defeated[id] = i
            expected[i] = id .. ":" .. i
        end
        T.equal(Codec.encode(defeated), table.concat(expected, ","))
    end)

    T.test("encodes an empty list as an empty string", function()
        T.equal(Codec.encode({}), "")
    end)

    T.test("decodes what it encodes", function()
        local defeated = { deerclops = 30, bearger = 12, stalker_atrium = 0 }
        T.equal(Codec.decode(Codec.encode(defeated)), defeated)
    end)

    T.test("decodes ids with digits and underscores", function()
        T.equal(Codec.decode("daywalker2:5,worm_boss_shadow:120"), { daywalker2 = 5, worm_boss_shadow = 120 })
    end)

    T.test("decodes anything that is not a string to an empty list", function()
        T.equal(Codec.decode(nil), {})
        T.equal(Codec.decode(42), {})
        T.equal(Codec.decode(""), {})
    end)

    T.test("skips malformed entries and keeps the valid ones", function()
        T.equal(Codec.decode("garbage,deerclops:7,:3,moose:"), { deerclops = 7 })
    end)
end
