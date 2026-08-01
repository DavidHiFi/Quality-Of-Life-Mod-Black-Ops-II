# Checkpoint 9 — Buried load failure ROOT-CAUSED (stock packaging gap). Docks/Cell Block fixed.

Written 2026-08-02. Supersedes checkpoint 8. **Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game
- **TranZit: Diner, Tunnel, Cornfield, classic** — the v1.1.2 `#include` fix worked.
- **Origins / Excavation Site.**
- **Mob of the Dead clientfield crash is gone** (v1.1.4 visionset fix took).
- **Cell Block shows a character model** (v1.1.4 precache fix took) — but see below.

### Fixed and deployed, NOT run in game (v1.1.5 + v1.1.6)
| what | file | status |
|---|---|---|
| Cell Block instant death on spawn | `scripts\zm\replaced\zm_prison.gsc` (new) | 🛑 untested |
| Buried survival fails to load | `character\c_buried_player_reporter_dam.gsc` (new) | 🛑 untested |
| Buried invisible characters (pre-empted) | `scripts\zm\zm_buried\zm_buried.gsc` | 🛑 untested |

`mod.json` → **1.1.6**. `.gsc` only, no `build_ff.bat` needed.

### The single next action
Launch and keep the log: **Maze → Docks → Cell Block → Tunnel** (Tunnel is the regression guard
for the prison zone change; it shares no code but confirms nothing global broke).

---

## 1. THE BIG ONE — why Buried survival could never load

`maps\mp\zm_buried.gsc:43` has `#include character\c_buried_player_reporter_dam;`, and that script
defines **exactly `main()` and `precache()`** — the two 0-parameter symbols the error named. The
error reports the file holding the *reference*, same convention as the TranZit
`disconnect_door_zones` error.

Unlinker evidence (`H:\Claude\oat-windows`):

| fastfile | has `c_buried_player_reporter_dam`? |
|---|---|
| `zm_buried.ff` | no character scripts at all |
| `zm_buried_patch.ff` | has the three `c_transit_player_*` + `c_transit_player_reporter`, **not this one** |
| `so_zclassic_zm_buried.ff` | ✅ |
| `so_zencounter_zm_buried.ff` | ✅ |

A zstandard game loads only `zm_buried_patch` + `zm_buried`. **There is no `so_zsurvival_zm_buried.ff`
— TranZit is the ONLY map in the game that ships a `so_zsurvival` file.** So the include cannot
resolve, the map script fails to link, and nothing runs. That is why the v1.1.3 MAZE marker
printlns never appeared: the failure is at script LOAD, before any `main()`.

**Fix:** ship the stock script raw in `character\`, and add `'character'` to `pack_iwd.ps1`'s folder
list. Same audit run across every map — prison/highrise/tomb are covered by their always-loaded
fastfiles, TranZit's come from `so_zsurvival_zm_transit.ff`. **Buried was the only gap**, matching
exactly which map failed.

---

## 2. THE PATTERN BEHIND MOST OF THIS SESSION

**The mod ships Reimagined's mapents but not the code that matches them.** `mod.iwd` contains
custom `maps\mp\zm_{buried,highrise,nuked,prison,transit}.d3dbsp` overrides. Cell Block's instant
death was exactly this: `in_enabled_playable_area()` needs the player touching a `player_volume`
whose targetname is an **enabled zone** (`_zm.gsc:1442-1456`), MotD's out-of-area callback kills
unconditionally, and we had Reimagined's entity data with stock zone setup. Fixed by porting
`working_zone_init`.

**Second recurring cause:** the survival locations run `zstandard`, and only TranZit has a
`so_zsurvival` fastfile. Anything stock survival would normally set up — character precaching,
visionset registration — silently does not happen elsewhere. Both Alcatraz fixes in v1.1.4 and the
Buried one in v1.1.6 are this.

---

## 3. ON PORTING FROM BO2-Reimagined — measured, not guessed

Reimagined has **195 files in `replaced/`**; zm_qol has 9. But bulk-porting is wrong, and this
round proved it concretely. Reimagined's `replaced\zm_buried.gsc` was diffed function-by-function
against stock before porting anything:

- `buried_zone_init` — differs by **one** `add_adjacent_zone` line.
- `init_level_specific_wall_buy_fx` — only renames `ak74u_zm_chalk_fx` → `vector_zm_chalk_fx`,
  a Reimagined weapon swap this project does **not** want.
- `give_team_characters` — only adds a `should_use_cia` branch.

None of it was the blocker. **It was deliberately not ported.** Always diff the Reimagined function
against the stock dump first; take the delta, not the file.

---

## 4. TOOLING LEARNED THIS SESSION

- **The OAT Unlinker settles "is this asset actually loaded?" questions.** `--list <zone.ff>` plus
  `--include-assets script -o <dir>` to extract. Stock map scripts in fastfiles are **compiled
  bytecode**, not raw text (contra a claim in CLAUDE.md §8, which is true only of the mod's own
  `.csc` rawfiles). Read their symbol tables with
  `tr -c '[:print:]' '\n' < file.gsc | grep -x <name>` — enough to verify a function exists without
  a decompiler.
- **`gsc-tool.exe` is NOT installed** — `t6 modding starter kit\tools\gsc-tool\` has only the
  wrapper `.bat` files and a README. Installing it (v1.4.10, windows-x64) would allow *offline*
  syntax/link validation and would have caught the v1.1.1 TranZit include bug and this one without
  burning game rounds. **Worth doing.**
- Audit every unqualified call and qualified reference in a new `replaced\` file against its
  `#include` list before shipping. Two separate load failures this session were exactly this.

---

## 5. TEST BACKLOG (carried forward)

1. 🛑 **5-map stock-location boot test** — still 2 of 5 (`zm_transit` ✅, `zm_prison` ✅). Unrun:
   `zm_buried`, `zm_highrise`, `zm_nuked`.
2. Maze, Docks, Cell Block — all untested at v1.1.6.
3. Die Rise (shopping_mall / dragon_rooftop / sweatshop) — never tested at all. Highrise's
   characters ARE covered by its patch ff, so it should at least load.
4. Borough/street wallbuys; Cornfield's boundary wall; LUI hint text.
5. Regression: perk descriptions after several revives; instant start.

**Open, unverified for Maze:** `zone_maze` is NOT in Buried's `init_zones` (22 zones, no maze
entry). `zm_buried_loc_maze::struct_init` re-tags the maze respawn point to `zone_mansion_backyard`
and repopulates the `initial_spawn` fallback, which is how Docks avoids the locked-spawn problem —
so it may be fine. If Maze loads but insta-kills, that is the first thing to look at (compare the
Tunnel fix in `scripts\zm\replaced\zm_transit.gsc`).
