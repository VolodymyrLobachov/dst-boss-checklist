--[[
Boss Checklist - boss definitions.

Fields:
  id            unique key, also used for save data (never rename an existing id)
  title_prefab  prefab whose STRINGS.NAMES entry is used as the title (localized by the game)
  title         optional fixed title, used when there is no good STRINGS.NAMES entry
  prefabs       prefabs that count as this boss being defeated
  require_all   if true, every prefab in `prefabs` must be defeated (e.g. Twins of Terror)
  optional      mini-boss that appears by chance: always shown in the book (in its own colour) and
                never blocks the progression (unless the "Mini-bosses" mod option says otherwise)
  final_check   optional fn(inst): the defeat only counts when it returns true (e.g. Klaus's second death)
  loot_only     if true, the boss is only detected when it drops its loot (things that are not
                creatures, e.g. the Poison Birchnut Tree, which is chopped down instead of killed)
  scrapbook     prefab used for health/damage/portrait from the game's Scrapbook data
  loot_table    name (or list of names) of the game's shared loot tables, read live so drop chances stay accurate
  extra_drops   drops that are not in the loot table: { prefab, count, chance, note }
                (note is a full sentence shown in the hover text; the icon label gets a "*")
  drops_note    extra text shown under the drops
  respawn_tuning TUNING key with a respawn time in seconds
  respawn       respawn text, used when there is no respawn_tuning
  location / when / summon / tips  guide text

Summon conditions were checked against the game's own scripts. When adding a boss, prefer
facts you can confirm in the game code (prefabs/, components/) over wiki memory.
]]

local BOSSES =
{
    -------------------------------------------------------------------------
    -- Surface: seasonal giants
    -------------------------------------------------------------------------
    {
        id = "deerclops",
        title_prefab = "deerclops",
        prefabs = { "deerclops" },
        scrapbook = "deerclops",
        loot_table = "deerclops",
        category = "Seasonal Giant",
        location = "Surface",
        when = "Winter",
        respawn = "Returns every Winter.",
        summon = "Arrives on its own during Winter near a player. You will hear growls shortly before it shows up.",
        tips = "It destroys structures and freezes things around it, so lead it away from your base. Kite it: step out of range of its swipe, then hit it.",
    },
    {
        id = "bearger",
        title_prefab = "bearger",
        prefabs = { "bearger" },
        scrapbook = "bearger",
        loot_table = "bearger",
        category = "Seasonal Giant",
        location = "Surface",
        when = "Autumn",
        respawn = "Returns every Autumn.",
        summon = "Arrives on its own during Autumn near a player. It is drawn to food and beehives and smashes trees on its way.",
        tips = "Keep food out of its reach. It hibernates when Winter starts, so a sleeping Bearger is an easy target late in Autumn.",
    },
    {
        id = "moose",
        title = "Moose/Goose",
        prefabs = { "moose" },
        scrapbook = "moose",
        loot_table = "moose",
        category = "Seasonal Giant",
        location = "Surface",
        when = "Spring",
        respawn = "Returns every Spring.",
        summon = "In Spring, Moose/Goose land at nests around the surface and lay an egg. Mosslings hatch from the egg later in the season.",
        tips = "Kill her before the Mosslings hatch, or deal with them first. Her honk knocks your weapon out of your hands.",
    },
    {
        id = "antlion",
        title_prefab = "antlion",
        prefabs = { "antlion" },
        scrapbook = "antlion",
        loot_table = "antlion",
        category = "Seasonal Giant",
        location = "Surface: Oasis Desert",
        when = "Summer",
        respawn = "Comes back every Summer.",
        summon = "Lives in the Oasis Desert. During Summer it causes sinkholes around players unless you keep it happy by giving it items such as trinkets. Attack it while it is above ground to start the fight.",
        tips = "It raises sand spikes and sand walls around you, so keep moving.",
    },

    -------------------------------------------------------------------------
    -- Surface: raid bosses
    -------------------------------------------------------------------------
    {
        id = "dragonfly",
        title_prefab = "dragonfly",
        prefabs = { "dragonfly" },
        scrapbook = "dragonfly",
        loot_table = "dragonfly",
        category = "Raid Boss",
        location = "Surface: Dragonfly Desert",
        when = "Any season",
        respawn_tuning = "DRAGONFLY_RESPAWN_TIME",
        summon = "Rests in her arena among magma pools in the Dragonfly Desert. Attack her to start the fight.",
        tips = "She becomes enraged periodically and calls Lavae from the magma pools. Build walls around the pools or freeze the Lavae as they appear.",
    },
    {
        id = "beequeen",
        title_prefab = "beequeen",
        prefabs = { "beequeen" },
        scrapbook = "beequeen",
        loot_table = "beequeen",
        category = "Raid Boss",
        location = "Surface: Gigantic Beehive",
        when = "Any season",
        respawn_tuning = "BEEQUEEN_RESPAWN_TIME",
        summon = "Find the Gigantic Beehive on a patch of honey turf. Hammer it, or keep harvesting honey from it, until the Bee Queen comes out.",
        tips = "Her Grumble Bees shield her and her screech causes panic. Fight her with enough damage to kill the guards quickly, and bring armor that protects against bees.",
    },
    {
        id = "klaus",
        title_prefab = "klaus",
        prefabs = { "klaus" },
        scrapbook = "klaus",
        extra_drops =
        {
            { prefab = "monstermeat" },
            { prefab = "charcoal" },
            { prefab = "chesspiece_klaus_sketch" },
            { prefab = "klaussackkey" },
        },
        drops_note = "Use the Stag Antler he drops on the Loot Stash to get the real rewards.",
        -- Klaus "dies" once and revives unchained; only the second death counts.
        final_check = function(inst) return inst.IsUnchained ~= nil and inst:IsUnchained() end,
        category = "Raid Boss",
        location = "Surface: Loot Stash",
        when = "Winter",
        respawn = "A new Loot Stash appears every Winter.",
        summon = "A Loot Stash appears somewhere on the surface in Winter. Get a Deer Antler from a No-Eyed Deer and use it on the Loot Stash to release Klaus.",
        tips = "He has two phases: after his first death he gets back up unchained and stronger. He also comes with two gem deer, and killing them enrages him.",
    },

    -------------------------------------------------------------------------
    -- Ocean
    -------------------------------------------------------------------------
    {
        id = "malbatross",
        title_prefab = "malbatross",
        prefabs = { "malbatross" },
        scrapbook = "malbatross",
        loot_table = "malbatross",
        category = "Ocean Boss",
        location = "Ocean: deep water",
        when = "Any season",
        respawn = "Can appear again some days after being defeated.",
        summon = "Appears at a school of fish in deep water when a player sails close to it.",
        tips = "Fight from a sturdy boat with repair supplies. She dives at boats and causes leaks.",
    },
    {
        id = "crabking",
        title_prefab = "crabking",
        prefabs = { "crabking" },
        scrapbook = "crabking",
        loot_table = "crabking",
        category = "Ocean Boss",
        location = "Ocean: near Pearl's island",
        when = "Any season",
        respawn_tuning = "CRABKING_RESPAWN_TIME",
        summon = "Lives in the ocean near Pearl's island. Socket gems into it to make it stronger and its loot better, then give it Pearl's Pearl (earned by helping Pearl, the Hermit Crab) to start the fight.",
        tips = "Bring several boats and repair kits. Its claws hold your boat in place, so destroy them first.",
    },
    {
        id = "sharkboi",
        title_prefab = "sharkboi",
        prefabs = { "sharkboi" },
        scrapbook = "sharkboi",
        extra_drops =
        {
            { prefab = "chesspiece_sharkboi_sketch" },
            { prefab = "bootleg" },
        },
        drops_note = "Frostjaw does not drop loot. After he gives up, trade him ocean fish weighing 150 or more for rewards. Heavier fish give more rewards.",
        category = "Ocean Boss",
        location = "Ocean: sea ice arena",
        when = "Any season (bigger arena in Winter)",
        summon = "A patch of sea ice with an ice fishing hole appears in the ocean. Fish in the hole to lure Frostjaw out.",
        tips = "He digs under the ice and leaps out. Stay away from the edges of the ice.",
    },

    -------------------------------------------------------------------------
    -- Caves & Ruins
    -------------------------------------------------------------------------
    {
        id = "toadstool",
        title_prefab = "toadstool",
        prefabs = { "toadstool" },
        scrapbook = "toadstool",
        loot_table = "toadstool",
        category = "Raid Boss",
        location = "Caves: Toadstool's stump",
        when = "Any season",
        respawn_tuning = "TOADSTOOL_RESPAWN_TIME",
        summon = "A large mushroom stump grows somewhere in the Caves. Chop it to wake Toadstool.",
        tips = "Chop down the Spore Caps he grows around the arena: each one makes him stronger. Spores slow you, so bring speed boosts.",
    },
    {
        id = "toadstool_dark",
        title_prefab = "toadstool_dark",
        prefabs = { "toadstool_dark" },
        scrapbook = "toadstool_dark",
        loot_table = "toadstool_dark",
        category = "Raid Boss",
        location = "Caves: Toadstool's stump",
        when = "Any season",
        respawn_tuning = "TOADSTOOL_RESPAWN_TIME",
        summon = "Keep a Canary in a Bird Cage in the Caves while Toadstool is giving off toxic gas, until it turns into a volatile Canary. Release it next to the stump. It bursts and turns the stump dark for one day; chop it during that day to wake Misery Toadstool.",
        tips = "A much tougher Toadstool. Fight it only with a prepared group.",
    },
    {
        id = "minotaur",
        title_prefab = "minotaur",
        prefabs = { "minotaur" },
        scrapbook = "minotaur",
        loot_table = "minotaur",
        drops_note = "A Large Ornate Chest also appears in the Labyrinth after the fight.",
        category = "Ruins Boss",
        location = "Ruins: Labyrinth",
        when = "Any season",
        respawn = "Comes back when the Ruins regenerate (if this is turned on in world settings).",
        summon = "Guards the center of the Labyrinth in the Ancient Ruins.",
        tips = "Get it to charge into the pillars: it stuns itself. It drops the Ancient Key needed for the Ancient Fuelweaver.",
    },
    {
        id = "stalker_atrium",
        title_prefab = "stalker_atrium",
        prefabs = { "stalker_atrium" },
        scrapbook = "stalker_atrium",
        -- Built in code (AtriumLootFn in prefabs/stalker.lua), not a shared loot table.
        extra_drops =
        {
            { prefab = "thurible" },
            { prefab = "armorskeleton" },
            { prefab = "skeletonhat" },
            { prefab = "chesspiece_stalker_sketch" },
            { prefab = "nightmarefuel", count = 4 },
            { prefab = "nightmarefuel", count = 2, chance = 0.5 },
        },
        drops_note = "If the Ancient Gateway runs out of power before he dies, he collapses and drops only a Shadow Atrium.",
        category = "Raid Boss",
        location = "Caves: Atrium",
        when = "Night only (to summon)",
        respawn_tuning = "ATRIUM_GATE_COOLDOWN",
        summon = "1. Insert the Ancient Key (from the Ancient Guardian) into the Ancient Gateway in the Atrium.\n2. Assemble the Fossil Fragments correctly into a skeleton near the gateway.\n3. At night, give the skeleton a Shadow Atrium. Shadow Chess Pieces drop the first one.",
        tips = "Kill the Woven Shadows he summons before he absorbs them to heal.",
    },

    -------------------------------------------------------------------------
    -- Terrarium
    -------------------------------------------------------------------------
    {
        id = "eyeofterror",
        title_prefab = "eyeofterror",
        prefabs = { "eyeofterror" },
        scrapbook = "eyeofterror",
        loot_table = "eyeofterror",
        category = "Night Boss",
        location = "Surface: Terrarium",
        when = "Night",
        summon = "Find the Terrarium in a special chest on the surface and turn it on. When night falls, the Eye of Terror arrives. It leaves at dawn.",
        tips = "It charges in straight lines and calls in Suspicious Peepers. Dodge sideways.",
    },
    {
        id = "twinsofterror",
        title = "Twins of Terror",
        prefabs = { "twinofterror1", "twinofterror2" },
        require_all = true,
        scrapbook = "twinofterror1",
        loot_table = { "twinofterror1", "twinofterror2" },
        extra_drops =
        {
            { prefab = "chesspiece_twinsofterror_sketch", note = "Dropped by the last twin killed." },
            { prefab = "shieldofterror", note = "Dropped by the last twin killed." },
        },
        category = "Night Boss",
        location = "Surface: Terrarium",
        when = "Night",
        summon = "Give Nightmare Fuel to the Terrarium so it turns crimson, then turn it on. At night, Retinazor and Spazmatism arrive instead of the Eye of Terror.",
        tips = "They fight together and get more dangerous as they lose health. Focus one twin at a time.",
    },

    -------------------------------------------------------------------------
    -- Lunar
    -------------------------------------------------------------------------
    {
        id = "alterguardian",
        title_prefab = "alterguardian_phase3",
        prefabs = { "alterguardian_phase3" },
        scrapbook = "alterguardian_phase1",
        loot_table = "alterguardian_phase3",
        category = "Final Boss",
        location = "Lunar Island",
        when = "Any season",
        summon = "Place the Celestial Altar pieces on the Lunar Island to start a Moon Storm. Help Wagstaff with his experiments in the storm and finish building the Lunar Siphonator. The Celestial Champion is released when it is complete.",
        tips = "Three phases, each with new attacks. Plan for a long fight and bring planar or high-damage weapons.",
    },

    -------------------------------------------------------------------------
    -- Shadow / Rifts
    -------------------------------------------------------------------------
    {
        id = "daywalker",
        title_prefab = "daywalker",
        prefabs = { "daywalker" },
        scrapbook = "daywalker",
        loot_table = "daywalker",
        category = "Shadow Boss",
        location = "Caves",
        when = "Any season",
        respawn = "Can come back about 10 days after being defeated.",
        summon = "Found in the Caves, held by shadow chains attached to pillars. Mine the pillars so he can break free and fight.",
        tips = "Shadow Leeches latch on and blind you, so knock them off fast.",
    },
    {
        id = "daywalker2",
        title_prefab = "daywalker2",
        prefabs = { "daywalker2" },
        scrapbook = "daywalker2",
        loot_table = "daywalker2",
        category = "Boss",
        location = "Surface: junk pile",
        when = "Any season",
        summon = "Hides in a large junk pile on the surface. Dig through the junk to bring him out.",
        tips = "He throws junk and grabs items. Keep your distance while he is buried.",
    },

    -------------------------------------------------------------------------
    -- Early game
    -------------------------------------------------------------------------
    {
        id = "spiderqueen",
        title_prefab = "spiderqueen",
        prefabs = { "spiderqueen" },
        scrapbook = "spiderqueen",
        extra_drops =
        {
            { prefab = "monstermeat", count = 4 },
            { prefab = "silk", count = 4 },
            { prefab = "spidereggsack" },
            { prefab = "spiderhat" },
        },
        category = "Mini Boss",
        optional = true,
        location = "Surface / Caves: spider dens",
        when = "Any season",
        summon = "A fully grown (tier 3) Spider Den eventually turns into a Spider Queen, who walks off to start new dens.",
        tips = "Clear the spiders she spawns first. Her Spiderhat lets you befriend spiders.",
    },
    {
        id = "leif",
        title_prefab = "leif",
        prefabs = { "leif", "leif_sparse" },
        scrapbook = "leif",
        extra_drops =
        {
            { prefab = "livinglog", count = 6 },
            { prefab = "monstermeat" },
        },
        category = "Mini Boss",
        optional = true,
        location = "Surface: forests",
        when = "Any season",
        summon = "Chopping down Evergreens has a small chance to wake a nearby tree as a Treeguard.",
        tips = "It is slow, so you can hit it and step back before it swings.",
    },
    {
        id = "lordfruitfly",
        title_prefab = "lordfruitfly",
        prefabs = { "lordfruitfly" },
        scrapbook = "lordfruitfly",
        loot_table = "lordfruitfly",
        extra_drops =
        {
            { prefab = "fruitflyfruit", note = "Only if you have no Friendly Fruit Fly yet." },
        },
        category = "Mini Boss",
        optional = true,
        location = "Surface: farm plots",
        when = "Any season",
        summon = "Appears near player farms when there are many growing farm plants close together.",
        tips = "Its fruit flies damage your crops. Its Friendly Fruit Fly Fruit gives you a fly that tends your farm.",
    },

    {
        id = "deciduous_monster",
        title = "Poison Birchnut Tree",
        -- A normal Birchnut Tree that turned into a monster. It has no health: it is defeated by
        -- chopping it down, so it is detected through its loot drop while inst.monster is set.
        prefabs = { "deciduoustree" },
        loot_only = true,
        final_check = function(inst) return inst.monster == true end,
        scrapbook = "deciduoustree_tall",
        -- Built in code (chop_down_tree in prefabs/deciduoustrees.lua).
        extra_drops =
        {
            { prefab = "livinglog" },
            { prefab = "livinglog", chance = 0.2 },
            { prefab = "acorn", count = 3 },
            { prefab = "nightmarefuel", chance = 0.2 },
        },
        category = "Mini Boss",
        optional = true,
        location = "Surface: Birchnut forests",
        when = "Autumn, Spring or Summer (not Winter)",
        respawn = "It calms down by itself after about half a day.",
        summon = "From day 3, chopping down a fully grown Birchnut Tree that still has leaves has a chance to turn 3-4 nearby Birchnut Trees into Poison Birchnut Trees. The chance is highest in Autumn and grows the longer you have survived.",
        tips = "It does not have health: chop it down to defeat it. It attacks with roots from the ground (30 damage) and drops Birchnutters. Keep moving between chops.",
    },
    {
        id = "spat",
        title_prefab = "spat",
        prefabs = { "spat" },
        scrapbook = "spat",
        loot_table = "spat",
        category = "Mini Boss",
        optional = true,
        location = "Surface",
        when = "Any season",
        summon = "Follow the tracks from a Suspicious Dirt Pile. Instead of a Koalefant, a hunt sometimes ends with an Ewecus or a Varg. The chance is about 5% early on and grows to 33% by day 100.",
        tips = "Its spit glues you in place, so fight it with a friend or with ranged weapons, or dodge the spit before going in.",
    },
    {
        id = "warg",
        title_prefab = "warg",
        prefabs = { "warg" },
        scrapbook = "warg",
        loot_table = "warg",
        category = "Mini Boss",
        optional = true,
        location = "Surface",
        when = "Any season",
        summon = "Follow the tracks from a Suspicious Dirt Pile. Instead of a Koalefant, a hunt sometimes ends with a Varg or an Ewecus. The chance is about 5% early on and grows to 33% by day 100.",
        tips = "It keeps howling for Hounds. Kill it quickly, or the pack only gets bigger.",
    },

    -------------------------------------------------------------------------
    -- Shadow pieces & skeletons
    -------------------------------------------------------------------------
    {
        id = "shadowchess",
        title = "Shadow Chess Pieces",
        prefabs = { "shadow_rook", "shadow_knight", "shadow_bishop" },
        require_all = true,
        scrapbook = "shadow_rook",
        loot_table = "shadow_chesspiece",
        extra_drops =
        {
            { prefab = "shadowheart", note = "Only from a level 3 piece." },
            { prefab = "armor_sanity", note = "Only from a level 3 piece." },
            { prefab = "nightsword", note = "Only from a level 3 piece." },
        },
        drops_note = "Pieces grow stronger by absorbing each other. Only a level 3 piece drops a Shadow Atrium. Counts as defeated once you have killed all three: Rook, Knight and Bishop.",
        category = "Shadow Boss",
        location = "Surface: marble sculptures",
        when = "New Moon",
        summon = "Find a headless marble Knight, Bishop or Rook sculpture and put its Suspicious Marble piece back on. During a New Moon, mine the completed sculpture to release a Shadow piece.",
        tips = "Kill pieces one at a time before they level each other up.",
    },
    {
        id = "stalker_forest",
        title = "Reanimated Skeleton (Surface)",
        prefabs = { "stalker_forest" },
        scrapbook = "stalker_forest",
        loot_table = "stalker",
        category = "Shadow Boss",
        location = "Surface",
        when = "Night only (to summon)",
        summon = "Assemble Fossil Fragments into a correct skeleton on the surface, then give it a Shadow Atrium at night.",
        tips = "The weakest form of the skeleton. It raises Bone Spikes and plant traps around it.",
    },
    {
        id = "stalker",
        title = "Reanimated Skeleton (Caves)",
        prefabs = { "stalker" },
        scrapbook = "stalker",
        loot_table = "stalker",
        extra_drops =
        {
            { prefab = "shadowheart" },
            { prefab = "nightmarefuel", count = 2 },
            { prefab = "nightmarefuel", count = 2, chance = 0.5 },
        },
        category = "Shadow Boss",
        location = "Caves (outside the Atrium)",
        when = "Night only (to summon)",
        summon = "Assemble Fossil Fragments into a correct skeleton in the Caves (but not in the Atrium), then give it a Shadow Atrium at night.",
        tips = "It summons Bone Spikes and shadow hands. It also drops the Shadow Atrium back.",
    },

    -------------------------------------------------------------------------
    -- Caves
    -------------------------------------------------------------------------
    {
        id = "worm_boss",
        title_prefab = "worm_boss",
        prefabs = { "worm_boss" },
        scrapbook = "worm_boss",
        loot_table = "worm_boss",
        category = "Raid Boss",
        location = "Caves",
        when = "Any season",
        summon = "Can replace one of the Depths Worm attacks in the Caves. You can change how often it comes in the world settings.",
        tips = "Stay away from its mouth when it surfaces, and hit its body segments.",
    },

    -------------------------------------------------------------------------
    -- Lunar Rift
    -------------------------------------------------------------------------
    {
        id = "mutateddeerclops",
        title_prefab = "mutateddeerclops",
        prefabs = { "mutateddeerclops" },
        scrapbook = "mutateddeerclops",
        loot_table = "mutateddeerclops",
        category = "Lunar Boss",
        location = "Surface",
        when = "Winter (with a Lunar Rift open)",
        summon = "If Deerclops is killed while a Lunar Rift is open, its corpse can be possessed by lunar energy and rise again as Crystal Deerclops. The corpse can't mutate if it is burning or on the ocean.",
        tips = "Deals planar damage, so bring planar defense.",
    },
    {
        id = "mutatedwarg",
        title_prefab = "mutatedwarg",
        prefabs = { "mutatedwarg" },
        scrapbook = "mutatedwarg",
        loot_table = "mutatedwarg",
        category = "Lunar Boss",
        location = "Surface",
        when = "Any season (with a Lunar Rift open)",
        summon = "If a Varg is killed while a Lunar Rift is open, its corpse can be possessed by lunar energy and rise again as a Possessed Varg.",
        tips = "It calls hounds to help it. Deals planar damage.",
    },
    {
        id = "mutatedbearger",
        title_prefab = "mutatedbearger",
        prefabs = { "mutatedbearger" },
        scrapbook = "mutatedbearger",
        loot_table = "mutatedbearger",
        category = "Lunar Boss",
        location = "Surface",
        when = "Autumn (with a Lunar Rift open)",
        summon = "If Bearger is killed while a Lunar Rift is open, its corpse can be possessed by lunar energy and rise again as Armored Bearger.",
        tips = "Heavily armored and deals planar damage.",
    },
    {
        id = "alterguardian_lunarrift",
        title_prefab = "alterguardian_phase1_lunarrift",
        prefabs = { "alterguardian_phase1_lunarrift" },
        scrapbook = "alterguardian_phase1_lunarrift",
        loot_table = "alterguardian_phase1_lunarrift",
        category = "Lunar Boss",
        location = "Wagstaff's arena (Pearl's old island)",
        when = "Any season",
        summon = "Part of Wagstaff's quest after the Lunar Rift. While you build his arena and the W.A.R.B.O.T. is not powered yet, a Celestial Revenant appears.",
        tips = "A stronger, rift-powered version of the Celestial Champion's first phase.",
    },
    {
        id = "wagboss_robot",
        title_prefab = "wagboss_robot",
        prefabs = { "wagboss_robot" },
        scrapbook = "wagboss_robot",
        loot_table = "wagboss_robot",
        category = "Lunar Boss",
        location = "Wagstaff's arena (Pearl's old island)",
        when = "Any season",
        summon = "Help Wagstaff build his arena: place the turf, set up the robots and power the W.A.R.B.O.T., then pull the arena lever to start the fight.",
        tips = "Its drones and missiles cover the arena. Destroy the drones when you can.",
    },
    {
        id = "alterguardian_scion",
        title_prefab = "alterguardian_phase4_lunarrift",
        prefabs = { "alterguardian_phase4_lunarrift" },
        scrapbook = "alterguardian_phase4_lunarrift",
        loot_table = "alterguardian_phase4_lunarrift",
        category = "Final Boss",
        location = "Wagstaff's arena (Pearl's old island)",
        when = "Any season",
        summon = "Emerges from the W.A.R.B.O.T. after it is defeated.",
        tips = "Very high damage, including planar damage. Come with full health and good armor.",
    },

    -------------------------------------------------------------------------
    -- Atrium ritual (Shadow Rift)
    -------------------------------------------------------------------------
    {
        id = "rocky_boss_shadow",
        title_prefab = "rocky_boss_shadow",
        prefabs = { "rocky_boss_shadow" },
        scrapbook = "rocky_boss_shadow",
        loot_table = "rocky_boss_shadow",
        category = "Shadow Boss",
        location = "Caves: Rock Lobster herds",
        when = "Any season",
        summon = "A Rock Lobster in a herd in the Caves can grow into a Rock Master. Its Blighted form drops the Blighted Claw, one of the three organs for the ritual at the Ancient Gateway.",
        tips = "Nearby Rock Lobsters help it fight.",
    },
    {
        id = "bat_boss_shadow",
        title_prefab = "bat_boss_shadow",
        prefabs = { "bat_boss_shadow" },
        scrapbook = "bat_boss_shadow",
        loot_table = "bat_boss_shadow",
        category = "Shadow Boss",
        location = "Caves: bat cave",
        when = "Any season",
        summon = "The Hound Batilisk lives in a bat cave in the Caves. During the fight it splits off a Blighted copy. Defeat the copy for the Blighted Larynx, one of the three organs for the ritual.",
        tips = "The copy shares the original's health when it splits off.",
    },
    {
        id = "worm_boss_shadow",
        title_prefab = "worm_boss_shadow",
        prefabs = { "worm_boss_shadow" },
        scrapbook = "worm_boss_shadow",
        loot_table = "worm_boss_shadow",
        category = "Shadow Boss",
        location = "Caves",
        when = "Any season",
        summon = "While the Atrium ritual still needs Blighted Guts, the Great Depths Worm is guaranteed to come in the next worm attack, and it turns into its Blighted form during the fight.",
        tips = "Drops the Blighted Guts, one of the three organs for the ritual.",
    },
    {
        id = "shrouden",
        title_prefab = "shrouden",
        prefabs = { "shrouden" },
        scrapbook = "shrouden",
        loot_table = "shrouden",
        category = "Shadow Boss",
        location = "Caves: Atrium",
        when = "Any season",
        summon = "Collect the three Blighted organs (Claw, Larynx and Guts) and use them in the ritual at the Ancient Gateway in the Atrium to summon the Umbral Abomination.",
        tips = "The Atrium changes into its arena for the fight.",
    },
    {
        id = "charlie_boss",
        title_prefab = "charlie_boss",
        prefabs = { "charlie_boss" },
        scrapbook = "charlie_boss",
        loot_table = "charlie_boss",
        category = "Final Boss",
        location = "Caves: Atrium",
        when = "Any season",
        summon = "Fought in the Atrium as part of the same ritual questline as the Umbral Abomination.",
        tips = "The final fight of the shadow questline.",
    },
    {
        id = "vault_pillar_guard",
        title_prefab = "vault_pillar_guard",
        prefabs = { "vault_pillar_guard" },
        scrapbook = "vault_pillar_guard",
        loot_table = "vault_pillar_guard",
        category = "Ruins Boss",
        location = "Caves: Ancient Vault",
        when = "Any season",
        summon = "Guards the Ancient Vault, opened through the Atrium ritual questline.",
        tips = "A stationary tower. Stay out of its line of fire.",
    },
}

-- Progression order. Bosses unlock in this order in the book: only the first few undefeated ones
-- (mod option "Bosses shown ahead", default 2) are shown, the rest stay hidden until they are
-- defeated. Bosses with `optional = true` are always shown and do not take one of those places.
-- Bosses missing from this list go last.
local ORDER =
{
    "spiderqueen", "leif", "lordfruitfly",
    "deerclops", "deciduous_monster", "moose", "spat", "antlion", "warg", "bearger", "klaus",
    "eyeofterror", "shadowchess", "stalker_forest",
    "malbatross", "dragonfly", "beequeen",
    "minotaur", "stalker", "toadstool", "twinsofterror", "worm_boss",
    "crabking", "sharkboi", "stalker_atrium", "toadstool_dark",
    "alterguardian", "daywalker", "daywalker2",
    "mutateddeerclops", "mutatedwarg", "mutatedbearger",
    "alterguardian_lunarrift", "wagboss_robot", "alterguardian_scion",
    "rocky_boss_shadow", "bat_boss_shadow", "worm_boss_shadow",
    "shrouden", "charlie_boss", "vault_pillar_guard",
}

local rank = {}
for i, id in ipairs(ORDER) do
    rank[id] = i
end
for i, boss in ipairs(BOSSES) do
    boss._sort = (rank[boss.id] or (1000 + i))
end
table.sort(BOSSES, function(a, b) return a._sort < b._sort end)

return BOSSES
