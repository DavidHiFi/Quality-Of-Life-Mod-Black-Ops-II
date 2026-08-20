# Checkpoint 88 — v1.99.92 deployed. PATCHES tab + Set Points + Teleport are HALF BUILT.

Written 2026-08-20. **Supersedes 87 for status.** Read checkpoint 87 for the v1.99.91/.92 work
itself; this one is about what is in flight.

---

## 0. STATE — READ THIS FIRST

**Deployed and committed: v1.99.92.** Not booted since the RESTART LEVEL confirmation.

🛑 **IN FLIGHT AND HALF BUILT — the LUI half exists, the GSC half does NOT.** The working tree has
`ui/t6/menus/optionssettings.lua` edited with a new PATCHES tab, a SET POINTS row and a TELEPORT row.
**Nothing was rebuilt or deployed**, so the game is still running clean v1.99.92 and cannot be hurt
by this — but the source is not shippable as it stands, because every dvar those rows write is read
by nothing.

### THE NEXT ACTION, exactly

Write the GSC half (§2), then `build.bat` (LUI-only change — **no** `build_ff.bat` needed unless a
`.csc` is touched), bump to **v1.99.93**, commit.

**Do not deploy the LUI without the GSC.** A row that writes a dvar nothing reads is a dead switch.

---

## 1. THE REQUEST (user, 2026-08-20, two messages)

1. **SET POINTS** on the CHEATS tab — *"works similar the round change option ... start at 0 (none)
   and then go to 1000, 5000, 10000, 100000, 1000000. And the reason it's "set" points instead of
   "give" points is so if you wanna revert it ... you can just go back and set it to a lower number
   and have that amount of points."*
2. **A new PATCHES tab after GAME** — moves the existing patch toggles off the GAME tab and adds
   seven more (list in §2).
3. **The Strat Tester's teleport menu** in the CHEATS tab.

---

## 2. WHAT IS ALREADY DONE, AND WHAT IS LEFT

### DONE — `ui/t6/menus/optionssettings.lua` (uncommitted at time of writing, source only)

- `CoD.OptionsSettings.CreateQolPatchesTab` added, registered with
  `SettingsTabs:addTab(LocalClientIndex, "PATCHES", ...)` directly after the GAME tab.
- **BACKSPEED PATCH** (`move_speed`) and **ANIMATED CAMO PATCH** (`anim_pap_camo`) moved off GAME
  onto it — **dvars unchanged**, per the standing rule.
- Seven new rows on PATCHES, all default OFF except REMOVE ROUND CAP:
  | label | dvar |
  |---|---|
  | REMOVE ROUND CAP | `remove_round_cap` (default **1**) |
  | 24 ZOMBIE SOLO CAP | `solo_zombie_limit` |
  | INSTAKILL ROUNDS | `instakill_rounds` |
  | DOUBLE TAP 1.0 | `double_tap_1` |
  | SLIQUIFIER PRE-NERF | `sliquifier_prepatch` |
  | RECOIL PRE-NERF | `recoil_prepatch` |
  | NO BARRIER ATTACKS | `no_barrier_attacks` |
- **SET POINTS** row on CHEATS (`set_points`, choices 0/1000/5000/10000/100000/1000000).
- **TELEPORT** row on CHEATS (`teleport`), destination list built per map from `mapname`; no row at
  all on Nuketown, because the Strat Tester has no list for it and nothing is invented.
- `set_points` and `teleport` added to `QolNoArchive`.
- `luaparse` clean.

### LEFT — all of it in `scripts/zm/quality_of_life.gsc` + `scripts/zm/qol_options.gsc`

1. **Register the dvars** in `qol_options::init()` with `qol_opt_dvar( name, default )`:
   `remove_round_cap 1`, `solo_zombie_limit 0`, `instakill_rounds 0`, `double_tap_1 0`,
   `sliquifier_prepatch 0`, `recoil_prepatch 0`, `no_barrier_attacks 0`, `set_points 0`,
   `teleport 0`. 🛑 Without this the console cannot even see them
   ([[plutonium-dvar-descriptions-lookup]]).
2. **`zmqol_patches_watch()`** — one level thread, applies four of them live, on change only:
   - `double_tap_1` → `setdvar( "perk_weapRateEnhanced", 0 )`. **Stock default is 1**, read out of
     this install's own boot dvar dump.
   - `recoil_prepatch` → `setdvar( "sv_patch_zm_weapons", 0 )`. **Not in the dvar dump** — cache
     whatever it holds on the first flip and restore that, do not guess a default.
   - `sliquifier_prepatch` → `level.zombie_vars["slipgun_reslip_rate"] = 0` and
     `level.zombie_vars["slipgun_max_kill_round"] = undefined`; cache and restore both.
   - `no_barrier_attacks` → `level.attack_player_thru_boards_range = 0`; cache and restore.
3. **`zmqol_solo_zombie_limit()`** — level thread: `level waittill( "start_of_round" )`, then
   `if ( toggle && level.round_number > 5 && get_players().size == 1 ) level.zombie_total = 23;`
4. **`ai_calculate_health`** — `replaceFunc` in `main()`, one function with two branches (§3).
5. **The round cap** — in this mod's own `round_think()` (quality_of_life.gsc:1054), add stock's
   clamp back **only when the row is off**; and make `zmqol_goto_round()`'s existing `n_target > 255`
   clamp (quality_of_life.gsc:~8335) respect it too.
6. **`zmqol_set_points_watch()`** — PLAYER thread (same channel as godmode, `zmqol_toggle_dvar_watch`).
   Apply **on change only**, remembering the last applied value, and seed that from the dvar on the
   first pass so it does not zero anyone at spawn. Land exactly on the target with stock's own two
   functions: `add_to_player_score( delta )` when raising,
   `minus_to_player_score( -delta, 1 )` when lowering (the `1` skips the pers double-points upgrade
   so the exact amount comes off).
7. **`zmqol_teleport_watch()` + `zmqol_teleport_dest( n )`** — player thread, action-shaped: read,
   `setdvar( "teleport", "0" )`, `player setOrigin( pos ); player setPlayerAngles( ang );`.
   🛑 **The GSC index order must match the LUI list exactly** (§4).

---

## 3. THE SEVEN PATCHES — every mechanism, already measured

Source the user supplied: **`H:\Claude\legacy-decompiled.gsc`** (338 lines, gsc-tool decompile of a
"legacy"/pre-patch mod). It is four `replaceFunc`s plus an `init`, and every row maps to one line of
it. All of the following was checked against the stock dump, not taken on trust.

| row | mechanism | verified where |
|---|---|---|
| REMOVE ROUND CAP | stock `round_think` has `if ( 255 < level.round_number ) level.round_number = 255;` | diffed legacy's `round_think` against `_zm.gsc:3394+`; the clamp and both `setroundsplayed()` calls are the only meaningful removals |
| 24 ZOMBIE SOLO CAP | `level.zombie_total = 23` on `start_of_round` while solo past round 5 | legacy `zombie_total()` |
| INSTAKILL ROUNDS | `ai_calculate_health` capped at `ai_zombie_health( 155 )` | legacy vs `_zm.gsc::ai_calculate_health` |
| DOUBLE TAP 1.0 | `perk_weapRateEnhanced 0` | legacy `init()`; stock value `1` in the boot dvar dump |
| SLIQUIFIER PRE-NERF | `slipgun_reslip_rate 0`, `slipgun_max_kill_round` undefined | legacy `init()` |
| RECOIL PRE-NERF | `sv_patch_zm_weapons 0` | legacy `init()` |
| NO BARRIER ATTACKS | `level.attack_player_thru_boards_range = 0` | see below |

🌟 **THE ROUND CAP IS ALREADY GONE AND THAT IS WHY THE ROW DEFAULTS ON.** This mod replaces
`level.round_think_func` with its own `round_think()` for the Cold War round HUD
(quality_of_life.gsc:588 / :1054), and that copy **already has no 255 clamp and no
`setroundsplayed()`** — the same two removals the legacy mod makes. So ON = what the mod already
does, and OFF is the position that changes something. Say that plainly to the user; do not claim the
row "adds" anything.

🌟 **NO BARRIER ATTACKS NEEDS NO replaceFunc.** Legacy replaces
`_zm_spawner::should_attack_player_thru_boards` with `return false`, but
`level.attack_player_thru_boards_range` is read in exactly two places and both are in that one file:
`:833` builds `self.player_targets` from players inside that range, and `:878` squares it for the
damage pass over that same array. Set it to 0 and the array stays empty, so both the reach-through
animation and its damage stop — live, reversible, and with no copied function body. Only
`_zm_spawner.gsc:68-69` writes it (`109.8`), so nothing else fights over it.

🛑 **INSTAKILL ROUNDS DOES need the replaceFunc**, and the two branches differ in kind, not degree:
- stock **saturates** — on overflow it restores `old_health` and returns, so health stops growing;
- legacy **caps at round 155's value** and resets to the start value if it ever goes negative.
Write one function that branches on the dvar so the row is live and OFF is byte-exact stock.
`ai_zombie_health()` lives in `_zm.gsc`, so call it qualified.

---

## 4. THE TELEPORT LIST — LUI order, and the Strat Tester's own values

Copied value for value from
`H:\Claude\Strat-Tester-BO2\scripts\zm\strattester\commands.gsc::tpcase()`. **The GSC list must be
indexed in the LUI's order, which is not the Strat Tester's order for TranZit.**

| map | LUI index → destination | origin | angles |
|---|---|---|---|
| zm_transit | 1 DINER | (-5012,-6694,-60) | (0,-127,0) |
| | 2 FARM | (6908,-5750,-62) | (0,173,0) |
| | 3 TOWN | (1152,-717,-55) | (0,45,0) |
| | 4 BUS DEPOT | (-7384,4693,-63) | (0,18,0) |
| | 5 TUNNEL | (-11814,-1903,228) | (0,-60,0) |
| | 6 NACHT | (13840,-261,-188) | (0,-108,0) |
| | 7 POWER STATION | (12195,8266,-751) | (0,-90,0) |
| | 8 AK74U | (11200,7745,-564) | (0,-108,0) |
| | 9 WAREHOUSE | (10600,8272,-400) | (0,-108,0) |
| zm_prison | 1 CAFETERIA | (3309,9329,1336) | (0,131,0) |
| | 2 CAGE | (-1771,5401,-71) | (0,0,0) |
| | 3 WARDEN'S OFFICE | (-1042,9489,1350) | (0,-43,0) |
| | 4 DOUBLE TAP | (25,8762,1128) | (0,0,0) |
| zm_highrise | 1 SHAFT | (3805,1920,2197) | (0,-161,0) |
| | 2 TRAMPLESTEAM | (2159,1161,3070) | (0,135,0) |
| zm_buried | 1 SALOON | (553,-1214,56) | (0,-50,0) |
| | 2 JUGGERNOG | (-660,1030,8) | (0,-90,0) |
| | 3 TUNNEL | (-483,293,423) | (0,-40,0) |
| zm_tomb | 1 CHURCH | (1878,-1358,150) | (0,140,0) |
| | 2 CRAZY PLACE | (10335,-7902,-411) | (0,140,0) |
| | 3-8 GENERATOR 1-6 | (2340,4978,-303) (469,4788,-285) (740,2123,-125) (2337,-170,140) (-2830,-21,238) (732,-3923,300) | (0,-132,0) (0,-134,0) (0,135,0) (0,90,0) (0,40,0) (0,50,0) |
| | 9 TANK | `level.vh_tank.origin + (0,0,50)` | `level.vh_tank.angles` |

📝 `level.vh_tank` is a level VARIABLE, not a function reference, so guarding it with `isdefined` in a
root script is safe — it is not the AI_CONTEXT rule-2 trap.

🛑 **TRANZIT SURVIVAL NEEDS A GUARD.** These are classic-TranZit coordinates; in Diner survival they
are far outside the arena. Refuse and print when `getdvar( "ui_zm_mapstartlocation" )` is a survival
sub-location (non-empty and not `"transit"`), rather than dumping the player into dead space.

---

## 5. CARRIED FORWARD (unchanged from 87)

- **The whole of v1.99.91/.92 is still unbooted** except RESTART LEVEL, which the user confirmed on
  Origins 2026-08-20. Checkpoint 87 §0 has the full first-boot list — the clientfield fix and the
  Origins/Mob LUI fix are the two that gate everything else.
- Deadshot head lock-on, the AIM ASSIST row, and the jet gun overheat test all still need a boot.
- The Diner claymore's distance from the wall is dvar-tunable and unverified (checkpoint 87 §3).
- 🛑 GitHub release `v1.99.21` cannot start a map and is still downloadable — the user's call.
- Latest release published: **v1.99.89**. Nothing since has a release.
