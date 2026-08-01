# Checkpoint 7 — Tunnel root-caused and fixed; Origins visionset half re-fixed. Built, UNTESTED.

Written 2026-08-01. Supersedes checkpoint 6, whose §0 said "nothing has been run" — that was stale:
the 14:07 `console_zm.log` shows two runs happened after it was written. See §1.

**Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game
- **Diner survival**, **Tunnel wallbuys** (`1 of 1` both sides), loading screens / previews.
- **Origins `electric_cherry_reload_fx`** — checkpoint 6's registration DID work; that field is gone
  from the mismatch list in the 14:07 log.

### Fixed this round — built and deployed, **NOT run in game**
| what | file | status |
|---|---|---|
| Origins `visionset_slot` bit-count mismatch | `scripts\zm\zm_tomb\zm_tomb.gsc` | 🛑 untested |
| Tunnel instant death on spawn | `scripts\zm\replaced\zm_transit.gsc` (new) + `zm_transit\zm_transit.gsc` | 🛑 untested |

`build.bat` run clean, all three `.gsc` verified inside the deployed `mod.iwd`. **`.gsc` only — no
`build_ff.bat` needed** (checkpoint 6 §3: the fastfile's `.gsc` copies are inert).

`mod.json` → name **"Quality Of Life"**, version **1.1.1**.

### The single next action
Launch and keep the log:
1. **Tunnel (TranZit)** — expect to spawn *in the tunnel* and live. This is the big one.
2. **Origins / Excavation Site** — expect no `EXE_CLIENT_FIELD_MISMATCH` at all.
3. **Docks (Alcatraz)** — still never run since checkpoint 6's client fix.
4. **The 5-map stock-location boot test is STILL unrun.** Highest-risk outstanding item.
5. Regression: **classic TranZit** — the tunnel fix touches `transit_zone_init`, gated on
   `!is_classic()`, but classic is the thing it could plausibly break.

---

## 1. WHAT THE 14:07 LOG SAID (checkpoint 6 was written before these runs)

Two runs, `storage\t6\main\console_zm.log` (note: **not** the `mods\zm_qol\` copy — sort both by
mtime, see [[zm-qol-session-recall]]):

- **`ui_zm_mapstartlocation "tunnel"`** — inits clean, wallbuy tags, `[zm_qol] PROBE spawn 0 0 0
  health=0`, no `PROBE damage` lines, then `PLATFORM_DISCONNECTED_FROM_SERVER`. The probe latched on
  the player entity **before spawn**, so it was inconclusive as instrumentation — but "no damage at
  all" turned out to be the right signal anyway (§2).
- **`ui_zm_mapstartlocation "excavation_site"`** — one mismatch left:
  `visionset_slot in set[toplayer] ... [CLIENT: 2 SERVER : 1]`.

---

## 2. TUNNEL — ROOT CAUSE (static, decisive; no more guessing needed)

`_zm_zonemgr::manage_zones()` runs in a fixed order:

1. `get_player_spawns_for_gametype()` → `.locked = 1` on **every** `player_respawn_point`;
2. `[[ level.zone_manager_init_func ]]()` — i.e. `zm_transit::transit_zone_init`;
3. `zone_init()` + `enable_zone()` per initial zone.

`enable_zone( name )` is the **only** thing that unlocks a respawn point (it clears `.locked` where
`script_noteworthy == name`).

Tunnel registers its whole respawn group under `zone_amb_tunnel`. Stock TranZit only lists that zone
in `init_zones` **inside `if ( is_classic() )`** (`zm_transit.gsc:371-390`), and `transit_zone_init`
gives it no `add_adjacent_zone` edge at all — so in zstandard/zgrief the zone is never created, never
enabled, and unreachable by any door-opening. Every tunnel spawn stays locked →
`_zm_gametype::onspawnplayer` falls through to `getstructarray("initial_spawn_points","targetname")`,
the **map default at the Bus Depot**, where the non-classic pass has already deleted the
`classic_only` `player_volume` areas. Player lands out of bounds and dies instantly.

**This also explains why Diner works and Tunnel doesn't** — Diner's zones (`zone_gas`,
`zone_roadside_east/west`) all have adjacency edges. Cornfield's two zones are adjacent only to each
other, an island, so it has the same latent bug.

**Fix:** `scripts\zm\replaced\zm_transit.gsc` — stock `transit_zone_init` verbatim plus
`zone_init` + `enable_zone` for `zone_amb_tunnel`, `zone_amb_cornfield`, `zone_cornfield_prototype`,
gated `!is_classic()`. `replaceFunc`'d from `zm_transit\zm_transit.gsc::main()`.

The whole function has to be replaced rather than the level pointer re-pointed:
`level.zone_manager_init_func` is assigned inside `zm_transit::main()`, which runs **after** the
mod's `main()`. (CLAUDE.md §4 failure mode 2 does not apply here.)

Matches BO2-Reimagined `scripts\zm\replaced\zm_transit.gsc:228-235`, hooked at
`zm_transit\zm_transit_reimagined.gsc:24`. Reimagined applies it unconditionally; gated here so
classic TranZit's round-one zone set is untouched.

🛑 The temporary `zmqol_tunnel_death_probe` has been **deleted** from
`scripts\zm\locs\zm_transit_loc_tunnel.gsc`.

---

## 3. ORIGINS — why the visionset half of checkpoint 6 didn't take

`registerclientfield` is a bare engine builtin, so it works from `main()` — hence the electric-cherry
half landing. `_visionset_mgr::vsmgr_register_info` is **not**: it reads `level.vsmgr[type]` and
asserts on `level.vsmgr_initializing`, both created by `_visionset_mgr::init()` out of
`_load::main()` — **after** the mod's `main()`. The call hit an undefined `level.vsmgr` and did
nothing.

Split into `zmqol_register_survival_visionset()`, called from `zm_tomb.gsc::init()`, which is inside
the legal window (vsmgr exists; `vsmgr_initializing` is only cleared by `finalize_clientfields()`,
which the engine fires later via `codecallback_finalizeinitialization`). Guarded on
`isdefined( level.vsmgr["visionset"] )` so a future ordering change degrades to "not registered"
rather than erroring out of `init()`.

---

## 4. STANDING INSTRUCTION CHANGE — BO2-Reimagined is now the primary reference

The user's instruction (2026-08-01) **overrides `AI_CONTEXT.md` rule 7 for Reimagined only**. Full
source is cloned at `H:\Claude\BO2-Reimagined` (`https://github.com/Jbleezy/BO2-Reimagined`). The
stated goal is to get **all** of its gamemodes and maps working in zm_qol. Corrections written into
`AI_CONTEXT.md` (top + "Don't" list) and `H:\Claude\CLAUDE.md`.

The workspace is also much larger than `H:\Claude\CLAUDE.md` used to describe — `oat-windows`, the
starter kit's 2,093-file stock dump, and 7 further mod sources. Use them before reasoning from
scratch. The user will download more sources on request.

---

## 5. TEST BACKLOG (carried forward, all still open)

1. 🛑 **5-map stock-location boot test** — 2 of 5 (`zm_transit` ✅, `zm_prison` ✅). Unrun:
   `zm_buried`, `zm_highrise`, `zm_nuked`. Rollback: restore `zone_source\base\mod.ff` over
   `mod.ff`, run `build.bat`.
2. Tunnel (§2), Origins survival (§3), Docks — **all untested**.
3. Die Rise (shopping_mall / dragon_rooftop / sweatshop) and Buried (maze) — never tested at all.
   Checkpoint 6 §1 predicts they were black-screening; check §2's zone question for them too, since
   the same `init_zones` split exists on every map.
4. Borough/street wallbuys; Diner wallbuys physically present; Excavation Site loads; Cornfield's
   boundary wall; LUI hint text clears the preview panel.
5. Regression: perk descriptions after several revives; instant start; **classic TranZit**.

**Open gameplay question, not a crash:** on Origins survival `_zm_perks::init()` bails at line 52, so
no perk machinery initialises — yet Wunderfizz is set up by the loc scripts and Origins includes
Electric Cherry and PhD in its rotation. Can it hand out a perk whose FX were never loaded?
