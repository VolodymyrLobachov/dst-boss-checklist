# Boss Checklist (Don't Starve Together)

A checklist and guide book for DST bosses, inspired by Terraria's Boss Checklist.

- **Book**: press **B**, or click the book button in the bottom-right corner (left of the map button). The book opens in the centre of the screen.
- **Manual marking** of bosses is off by default; it can be enabled for admins or everyone in the mod settings.
- **Left page**: all 38 bosses the game's Scrapbook marks as bosses, plus three mini-bosses the game does not mark (Varg, Ewecus, Poison Birchnut Tree), in progression order, with a check mark when defeated.
- **Progression reveal**: defeated bosses are always shown. Of the undefeated ones, only the next two are shown (so you can skip a boss you can't reach yet; change this with **Bosses shown ahead**); the rest appear as a black silhouette with "???" until they are defeated. Mini-bosses that appear by chance (Spider Queen, Treeguard, Lord of the Fruit Flies, Poison Birchnut Tree, Ewecus, Varg) are always shown, in blue, and never take one of those two places (change this with **Mini-bosses**). Killing a boss out of order reveals it too. Set **Boss reveal** to **All visible** to turn this off.
- **Right page**: portrait, location and season, health and damage, respawn time, how to find or summon it, drops with chances, and tips.
- **Kill tracking**: done on the server and saved with the world. It is synced between the surface and the caves and shared with all players.

## Project layout

```
modinfo.lua                               mod metadata + config options
modmain.lua                               entry point: loads the settings, imports main/*
main/sync.lua                             defeated list: netvar to clients, shard RPCs, manual-marking RPC
main/kills.lua                            kill detection
main/hud.lua                              adds the book to the HUD, hotkey, mouse wheel
scripts/bosschecklist/bosses.lua          boss definitions (guide text, prefabs, loot tables, order)
scripts/bosschecklist/registry.lua        lookups over the definitions: by id, by prefab
scripts/bosschecklist/config.lua          mod settings + "may this player mark bosses" rule
scripts/bosschecklist/codec.lua           text format of the defeated list (netvar and shard sync)
scripts/bosschecklist/progression.lua     which bosses are revealed / next / locked (pure logic)
scripts/bosschecklist/gamedata.lua        reads live game data: names, icons, scrapbook stats
scripts/bosschecklist/drops.lua           reads loot tables and words the drop amounts
scripts/bosschecklist/ui.lua              colours and helpers shared by the widgets
scripts/components/bosschecklist_tracker.lua   world component that stores and saves defeated bosses
scripts/widgets/bosschecklist_book.lua    the book: HUD button, frame, boss list
scripts/widgets/bosschecklist_detail.lua  right page: one boss in detail
```

### Code conventions
- `snake_case` for variables, local functions and the functions of our own modules; `UPPER_CASE` for constants; `PascalCase` for modules and classes.
- Methods of game classes (widgets, components) are `PascalCase`, because the game calls some of them by name (`OnSave`, `OnLoad`, `GetDebugString`) and the rest should match. A leading underscore marks a private method.
- Each file has one job. Game-independent logic (`codec`, `progression`, the wording in `drops`) is kept apart from code that touches the game, so it can be read and checked on its own.
- No globals: modules are shared with `require`, settings come from `bosschecklist/config`.

### Where the data comes from
- **Names** come from `STRINGS.NAMES`, so they are translated automatically.
- **Health, damage and portraits** come from the game's Scrapbook data (`screens/redux/scrapbookdata`).
- **Drop amounts** are shown as `x2` (always 2), `x4-8` (4 always, up to 8 with luck) or `33%` (a single chance). Hover an icon for the full breakdown; `*` marks a drop with a condition.
- **Drops** are read live from the game's `LootTables`, so drop chances follow game updates. Bosses whose loot is built in code (Klaus, Ancient Fuelweaver, Frostjaw) use `extra_drops` instead.
- **Summon and tips text** is written by hand in `bosses.lua`. It was checked against the game's Lua scripts (build 762172).

### How kills are detected
A boss counts as defeated when one of these happens:
- it fires `death`,
- it enters a stategraph state tagged `defeated` (Frostjaw),
- its `lootdropper:DropLoot` runs (Nightmare Werepig).

Klaus counts only on his second, unchained death. The Poison Birchnut Tree counts when it is chopped down while it is a monster. The Twins of Terror count once both have died.

## Testing locally

1. Copy or link this folder into the game's mods folder:
   `<Steam folder>\steamapps\common\Don't Starve Together\mods\BossChecklist`
   (from an admin `cmd`: `mklink /J "<that path>" "<path to this folder>"`).
2. Start DST, go to **Create Game → Mods**, and enable **Boss Checklist**. Enable caves to test shard sync.
3. Useful console commands (press `~`, and toggle to **Remote** for server commands):
   - `c_spawn("deerclops")`, then kill it with `c_select() c_sel().components.health:Kill()`
   - `print(TheWorld.components.bosschecklist_tracker:GetDebugString())`
   - `TheWorld.components.bosschecklist_tracker:ClearDefeated("deerclops")`
4. Errors are written to `Documents\Klei\DoNotStarveTogether\client_log.txt`. Search it for `bosschecklist`.

## Tests

```
lua tests/run.lua
```

Run it from the mod folder; it needs a standalone Lua (5.1 or newer) and nothing else. The tests cover the game-independent rules only:

- `test_progression` - which bosses are revealed, next, upcoming or locked in every mode
- `test_drops` - how loot tables are added up and worded (`x2`, `x4-8`, `33%`)
- `test_tracker` - recording and clearing defeats, saving, loading old saves
- `test_codec`, `test_config`, `test_names` - the list format, settings and permissions, item names
- `test_bosses` - the definitions in `bosses.lua`: required fields, order, mini-bosses

Widgets, RPCs and kill detection are not covered, because they only run inside the game. `tests/fakes.lua` holds the few fake game globals the tested modules need. The `tests` folder is not used by the game.

## Adding a boss
Add an entry to `scripts/bosschecklist/bosses.lua` and put its id in the `ORDER` list at the bottom of that file. Use the existing entries as a template; the fields are documented at the top of the file. Then run the tests: they check that the new entry is complete. Never rename an existing `id`, because ids are stored in world saves.

## Not done yet
- Custom book art (the mod icon `modicon.tex` is built from the game's `book_brimstone` inventory icon plus a check mark; it is stored uncompressed, because DXT compression leaves blocky edges around the check mark).
- Controller support for the book.
- Translations of the guide text.
