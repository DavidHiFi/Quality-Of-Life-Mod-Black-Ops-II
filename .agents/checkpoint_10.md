# Checkpoint 10 — v1.4.0. Mapents made surgical; Maze ghost + Die Rise clientfields.

Written 2026-08-02. Supersedes checkpoint 9. **Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game
- **TranZit**: Diner, Tunnel, Cornfield, classic.
- **Origins / Excavation Site.**
- **Docks survival**: visible characters, alive, `inarea=1` (probe-confirmed).
- **Cell Block**: clientfield crash gone, character model visible.
- **Audio**: the "no sound but the gun" report was NOT a mod bug — the user had
  missing game files in the Steam install and fixed it. Do not chase it.

### Fixed and deployed at v1.4.0, NOT run in game
| what | where | status |
|---|---|---|
| Die Rise Olympia→Ballista regression (v1.3.0) | `maps\mp\*.d3dbsp` | 🛑 untested |
| Cell Block instant death | `maps\mp\zm_prison.d3dbsp` tags | 🛑 untested |
| Maze spawning at Processing | `maps\mp\zm_buried.d3dbsp` maze structs | 🛑 untested |
| Maze ghost `Unresolved external` | `zone_source\mod_locations.zone` | 🛑 untested |
| Die Rise clientfield mismatch (7 of 8) | `scripts\zm\zm_highrise\zm_highrise.gsc` | 🛑 **incomplete — see §3** |

### The single next action
Test **Maze → Cell Block → Die Rise (any location) → Die Rise CLASSIC** (the last
one is the regression guard for the clientfield change). Confirm the Die Rise
Olympia wallbuy is an Olympia again.

---

## 1. 🛑 THE BIG LESSON — never import Reimagined's mapents wholesale

v1.3.0 copied all six of BO2-Reimagined's `.d3dbsp` mapents in. That fixed the
spawns **and silently changed base-map content** — the user found Die Rise's
Olympia wallbuy had become a Ballista. **Reimagined's mapents carry its weapon
and balance changes.**

**The user's standing instruction: add the survival locations ONLY. Do not alter
base maps.**

v1.4.0 reverts to the project's own mapents and applies a *surgical* patch —
only `script_string` tags on spawn/perk structs, plus Maze structs that did not
exist at all. Verified diff:

```
zm_prison.d3dbsp   16 lines, all "script_string"     zm_buried.d3dbsp  street tags + 25 Maze structs
zm_highrise / zm_nuked / zm_transit                  UNCHANGED
```

Patch script kept at `.agents/` reference: read raw text and use
`[IO.File]::WriteAllText` — **the mapents are CRLF and an `awk` rewrite silently
converts them to LF**, which produced a 54,000-line bogus diff on the first
attempt. Always check `od -c` after editing.

### The tag mechanism (this is what drives survival spawns)
`_zm_gametype.gsc:1373-1393` picks the first spawn by filtering `initial_spawn`
structs on `script_string == "<gametype>_<location>"`, falling back to
`getstructarray("initial_spawn_points")` — the map default — when nothing
matches. Probe evidence on Cell Block before the fix:

```
PRISON t=1 loc=cellblock org=(862, 10629, 1359.66) health=100 inarea=0
```
`(862 10629 1364)` is an `initial_spawn_points` struct. `inarea=0` → MotD's
unconditional out-of-area callback killed the player.

Tags added: `zstandard_cellblock` (×11), `zstandard_perks_cellblock` (×5),
`zstandard_street` (×11), and 25 Maze structs (`zstandard_maze`,
`zstandard_perks_maze`).

---

## 2. THE ASSET-CHAIN PATTERN (now hit five times)

Survival runs `zstandard`, and **TranZit is the only map in the game that ships a
`so_zsurvival_*.ff`**. Everything in `so_zclassic_*`/`so_zencounter_*` is absent
on every other map's survival. Each missing item fails differently:

| missing | symptom |
|---|---|
| xmodel | renders nothing; `.model` still set, so probes look healthy |
| rawfile (animtree) | `COM_ERROR (1) unknown anim tree` — fatal, unguardable |
| script | `Unresolved external` naming **that script's exports** |

Fix: declare it in `mod_locations.zone`, add its source `.ff` to `build_ff.bat`'s
`--load` list, verify with `Unlinker --list mod.ff`.

**Dependencies chain.** Pulling `aitype/zm_buried_ghost_female.gsc` in at v1.3.0
created a *new* failure because it references
`character\c_zom_zombie_buried_ghost_woman`. Always check what a pulled script
references (`tr -c '[:print:]' '\n' < file.gsc | grep -E '^(character|maps)/'`).

---

## 3. 🛑 DIE RISE — FIXED ONLY PARTIALLY, EXPECT IT TO STILL FAIL

`maps\mp\zm_highrise::zclassic_preinit` (zm_highrise.gsc:70-82) registers 7
clientfields + calls `zm_highrise_sq::sq_highrise_clientfield_init` for an 8th.
**That runs for zclassic only**, so survival registered none while the client
registered all → `EXE_CLIENT_FIELD_MISMATCH`. Now registered from
`zm_highrise.gsc::main()` under `!is_classic()`.

**But one field is still wrong, in the opposite direction:**
```
Clientfield buildable in set [toplayer] is not registered on the client
```
Server and client each choose between per-slot clientfields and a single
`buildable` field based on `level.buildable_slot_count`
(`_zm_buildables.gsc:170-180` vs `_zm_buildables.csc:40-50`). On Die Rise
survival those counts disagree. **Not diagnosed.** Next step: find what sets
`level.buildable_slot_count` / `level.buildable_piece_count` on each side for
Die Rise, and why survival differs. Until then Die Rise may still disconnect.

---

## 4. STILL NOT DONE — the custom gamemodes (Meat, Turned, Race, Containment…)

The user has asked twice. **Not shipped, deliberately** — a partial table risks
bricking the lobby, and it was not testable this round.

What is known:
- `zm\gametypestable.csv` is the driver. Reimagined's lists **8** modes
  (`zclassic, zstandard, zsr, zgrief, zrace, zcontain, zmeat, zturned`) plus a
  `maxnum_startloc,16` block of `5,<n>,<map>,<location>,…` rows for the start
  locations.
- It is a **stringtable** asset: `stringtable,zm/gametypestable.csv` in
  `reimagined.zone`. zm_qol's `mod.ff` currently contains **zero** stringtables,
  so the stock table is in force. Ours would go in
  `zone_assets\zm\gametypestable.csv` (the Linker's asset search path is
  `zone_assets`, never the project root — that pulls in `weapons\` and dies).
- Reimagined also ships `zm\gamesettings_zgrief.cfg`, `_zmeat.cfg`, `_zrace.cfg`,
  `_zcontain.cfg`, `_zsr.cfg`, `_zturned.cfg`, plus `factiontable.csv` and
  `mapstable.csv`. A mode with no gamesettings file is likely what breaks a lobby.
- The mod's own LUI already lists `zclassic/zstandard/zgrief` per map in
  `ui_mp\t6\menus\privategamelobby_project.lua` — so the LUI must be extended too.

**Open question for the user (asked, unanswered):** which gamemodes currently
appear in the Mods menu? That determines whether the stock table is even being
read.

---

## 5. TOOLING

- **`gsc-tool` 1.4.10 is installed** at `H:\Claude\gsc-tool-bo2\gsc-tool.exe`.
  `-m parse -g t6 -s pc -y <file>` → exit 0 = OK. All 32 project GSC files pass.
  Syntax only — it does **not** resolve cross-file externals.
- **`build.bat` can silently fail to deploy** while still printing `[ok]`, if
  Plutonium/the game has the files open. Always confirm the deployed `mod.ff`
  size and timestamp afterwards. This nearly had the user testing a stale build.
- Unlinker for "is this asset actually loaded?"; mapents are plain text and can
  be read straight out of `mod.iwd`.

---

## 6. TEST BACKLOG

1. 🛑 5-map stock-location boot test — still 2 of 5 (`zm_transit` ✅, `zm_prison` ✅).
2. Maze, Cell Block, Die Rise (all), Die Rise classic regression.
3. Buried Borough (`street`) survival — now tagged `zstandard_street`, never tested.
4. Nuketown survival — never touched or tested at all.
5. Regression: perk descriptions after several revives; instant start.

---

## 7. ADDENDUM — v1.5.0 (2026-08-02, later the same session)

### Confirmed working by the user
- **Maze survival** (Buried) — loads and plays.
- **Origins survival** — all locations except the Church tank issue below.
- **Die Rise CLASSIC** — Olympia wallbuy is back to normal, confirming the
  surgical mapents revert in v1.4.0 undid the base-map damage.
- **Audio** — was the user's missing Steam game files, NOT a mod bug. Closed.

### Fixed in v1.5.0, NOT run in game
| what | where |
|---|---|
| Power Station instant death | `scripts\zm\replaced\zm_transit.gsc` |
| Church spawning inside the tank / tank breaking containment | `scripts\zm\locs\zm_tomb_loc_church.gsc` |
| `!p` / `!god` dev chat commands + `sv_cheats 1` | `scripts\zm\ridgelandproject.gsc` |

**Power** was the Tunnel mechanism with a different symptom path. Its loc script
DOES register initial_spawn structs (16 of 17 `register_map_spawn` calls pass a
`team_num`), so the player spawns in the right place — unlike Cell Block, which
fell through to the map default. What killed them is
`_zm::in_enabled_playable_area()`: TranZit's non-classic `init_zones` is only
`zone_pri / zone_station_ext / zone_tow / zone_far_ext / zone_brn`
(`zm_transit.gsc:391-396`), so `zone_prr` / `zone_pow` / `zone_pow_warehouse` are
never enabled and the player stands in a volume that does not count. Now enabled,
gated on `ui_zm_mapstartlocation == "power"` so the other TranZit locations keep
the zone set they already work with.

**Church tank**: entity names verified in the stock Origins scripts —
`tank` (`zm_tomb_tank.gsc:35`), `trig_tank_station_call` (`:471,:589`),
`trig_use_tank` (`:266`). All deleted for that location, isdefined-guarded.

**Dev commands** use `level waittill( "say", player, message )`, verified against
`H:\Claude\BO2-GSC-Releases\Zombies Mods\Give Points Command` rather than
guessed. `enableinvulnerability`/`disableinvulnerability` and
`add_to_player_score` (`_zm_score.gsc:311`) confirmed in the stock dump;
`tell()` does NOT exist in T6 — use `iprintlnbold`.

### 🛑 DIE RISE — mechanism now fully identified, fix NOT shipped
The seven `zclassic_preinit` clientfields were fixed in v1.4.0. The remaining one:

```
Clientfield buildable in set [toplayer] is not registered on the client
```

`clientscripts\mp\zombies\_zm_buildables.csc:25-34` only calls
`register_clientfields()` when the **first** buildable is added client-side
(`if ( level.zombie_buildables.size == 1 )`). On Die Rise survival the server
registers buildables but the client adds none, so the client never registers the
field while the server does.

**Do NOT simply call `register_clientfields()` from our `zm_highrise.csc`.** Both
sides size the field with `getminbitcountfornum( level.buildable_piece_count )`,
and with zero client-side buildables that count is 0 while the server's is not —
so it would swap a "missing field" mismatch for a "wrong bit count" mismatch.
`level.buildable_slot_count` is irrelevant here: only Buried ever assigns it
(`zm_buried_buildables.gsc:75` / `.csc:33`).

**The real fix** is to make the client register the same buildables the server
does on Die Rise survival — i.e. mirror whatever `zstandard_preinit` /
`zm_highrise_gamemodes` sets up server-side into
`scripts\zm\zm_highrise\zm_highrise.csc::init_gamemodes`. Next step: enumerate
the server-side buildable set for a survival game and match it. Requires a
`build_ff.bat` relink since `.csc` lives in `mod.ff`.

---

## 8. CUSTOM GAMEMODES — the full recipe (user answered the blocking question)

**User confirmed 2026-08-02: the Mods menu shows exactly `Classic`, `Survival`,
`Grief` and nothing else.**

That settles it — the STOCK `zm/gametypestable.csv` is in force. Extracted from
`ui_zm.ff` with the Unlinker, it defines four modes:
`zclassic, zstandard, zgrief, zcleansed` (`maxnum_gametype,3`), with string keys
of the form `ZMUI_CLASSIC_CAPS`. Reimagined's replaces it with **eight**:
`zclassic, zstandard, zsr, zgrief, zrace, zcontain, zmeat, zturned`, using
different keys (`ZMUI_ZCLASSIC_CAPS`).

### The five pieces required — all now identified

| piece | where Reimagined keeps it | status in zm_qol |
|---|---|---|
| gametype definition rawfiles `maps/mp/gametypes_zm/{zmeat,zturned,zrace,zcontain,zsr}.txt` + `_gametypes.txt` | `maps/mp/gametypes_zm/` | ✅ **shipped v1.6.1** |
| mode scripts `{zrace,zcontain,zsr,zturned}.gsc` (thin wrappers → `zgrief::main()`; stock already has `zmeat`/`zcleansed`) | same folder | ✅ **shipped v1.6.1** |
| `zm/gametypestable.csv` as a **stringtable** asset | `zone_source/reimagined.zone:158` | ❌ TODO |
| localized strings `ZMUI_ZMEAT_CAPS` etc. | `english/localizedstrings/reimagined.str` | ❌ TODO |
| LUI `CoD.PrivateGameLobby.GameTypeSettings[N].gameTypes[]` | — | ❌ TODO |

**The `.txt` files were a real gap, not speculation:** the console log has
`Could not load rawfile "maps/mp/gametypes_zm/zmeat.txt"` (and `zrace`,
`zturned`, `zcontainment`, `znml`, `zdeadpool`, `zpitted`) on every single map
load. `_gametypes.txt` is the master list the engine walks — 14 entries.

### Order to do the rest in, and the traps
1. **LUI is the visible gate.** `ui_mp\t6\menus\privategamelobby_project.lua`
   hard-codes `gameTypes[1..3] = zclassic/zstandard/zgrief` per map index. Even
   with a perfect table, nothing new appears until these arrays grow.
2. **The stringtable must go in `mod.ff`**, sourced from `zone_assets\zm\...`.
   Never point `--add-asset-search-path` at the project root — it contains
   `weapons\` and the Linker dies rebuilding every weapon.
3. **Localized strings:** without them the menu shows raw keys. Either compile
   Reimagined's `.str` in as a `localizedstring` asset, or author our table using
   the STOCK keys (`ZMUI_CLASSIC_CAPS`…) for the four modes that already have
   them and only add new keys for the four that do not.
4. **A mode listed with no `zm\gamesettings_<mode>.cfg` is the likely way to
   brick the lobby.** Reimagined ships `gamesettings_{zgrief,zmeat,zrace,zcontain,zsr,zturned}.cfg`.
   Ship those alongside.
5. Test each new mode on ONE map before assuming the set works — the mapents
   already carry `zmeat_*`, `zrace_*`, `zturned_*`, `zcleansed_*`, `znml_*`,
   `zmaxis_*`/`zrichtofen_*` spawn tags, so the spawn data is largely present.
