# Checkpoint 8 — Origins CONFIRMED FIXED. TranZit root-caused (my own bug). Docks instrumented.

Written 2026-08-02. Supersedes checkpoint 7.

**Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game (new this round)
- 🎉 **Origins / Excavation Site loads and plays.** The `visionset_slot` fix from checkpoint 7
  (`vsmgr_register_info` moved `main()` → `init()`) **worked**. No `EXE_CLIENT_FIELD_MISMATCH`.
  Mechanism: [[t6-visionset-registration-timing]].
- Previously confirmed: Diner survival, Tunnel wallbuys, loading screens / previews.

### Fixed this round — built and deployed, **NOT run in game**
| what | file | status |
|---|---|---|
| TranZit: unresolved external kills every location | `scripts\zm\replaced\zm_transit.gsc` | 🛑 untested |

### Instrumented this round — no fix, diagnostic only
| what | file | status |
|---|---|---|
| Docks: invisible model+weapon, immune to zombies | `scripts\zm\locs\zm_prison_loc_docks.gsc` | 🛑 probe added, **not root-caused** |

`mod.json` → **1.1.2**. `.gsc` only — no `build_ff.bat` needed. Verified inside the deployed
`mod.iwd`, not just "build.bat exited 0".

### The single next action
Launch and keep the log:
1. **Tunnel (TranZit)** — the checkpoint-7 tunnel zone fix has *still never actually executed*
   (see §1); this is its first real test.
2. **Diner** and **classic TranZit** — regression, same root cause blocked them.
3. **Docks (Alcatraz)** — read the `[zm_qol] DOCKS ...` probe lines out of the log (§2).
4. Still unrun: the **5-map stock-location boot test** (checkpoint 7 §5). Highest-risk open item.

---

## 1. TRANZIT — root cause was mine, from checkpoint 7

`console_zm.log` 2026-08-02, three separate runs (tunnel, diner, classic transit), identical:

```
**** Unresolved external : "disconnect_door_zones" with 3 parameters
     in "scripts/zm/replaced/zm_transit.gsc" at lines 1,1 ****
```

Checkpoint 7 copied stock `transit_zone_init` verbatim into a new file. The stock body calls
`disconnect_door_zones()` **unqualified**, and stock `maps\mp\zm_transit.gsc` only resolves that
through its own `#include maps\mp\zm_transit_utility` — which the copy didn't carry. GSC resolves
externals at **script load**, so this is a `COM_ERROR` before the map starts, killing *every*
TranZit location including classic. Fix: added the missing `#include`.

**The tunnel zone fix itself was never exercised** — the script died at load, so its correctness is
still completely unverified.

**Lesson, generalised:** when copying a stock function body into a `replaced\` file, port the
`#include` list too, then re-check every unqualified call resolves. All 16 identifiers in that file
were audited this round; only `disconnect_door_zones` was missing.

---

## 2. DOCKS — NOT root-caused. Two theories killed, probe added.

Symptom: player spawns in, **body model and weapon invisible, zombies deal no damage**. The Docks
run produced **no script errors and no warnings at all** — this is a logic gap, not a crash.

Those three symptoms together are the exact signature of the **MotD afterlife state**:
`_zm_afterlife::afterlife_enter()` calls `enableafterlife()` (ghost body + ghost viewhands) and
`afterlife_player_damage_callback()` has two early `if (self.afterlife) return 0;` guards. Lethal
damage on MotD converts a player into afterlife rather than killing them
(`_zm_afterlife.gsc` ~line 348).

**Theory A — "same as the tunnel zone bug" — KILLED.** `zone_dock` / `zone_dock_gondola` /
`zone_studio` / `zone_citadel_basement_building` really are absent from `zm_prison`'s non-classic
`init_zones` (`zm_prison.gsc:201-204`) and really are an unreachable island. **But it doesn't
matter**: `zm_prison_loc_docks::struct_init` clears and repopulates
`level.struct_class_names["script_noteworthy"]["initial_spawn"]` (lines 15, 38-43), so the docks
spawns come through the `initial_spawn` fallback, not through zone unlocking. The player does spawn
at the docks legitimately.

**Theory B — "missing grief character models" — KILLED.** `give_team_characters` sets a model in
every branch, and `precachemodel` on a missing asset raises a script error. The run had none.

**Do NOT port Reimagined's `replaced\zm_prison.gsc::working_zone_init` as a fix.** Diffed against
stock this round: its substantive change is turning stock's `is_gametype_active("zgrief")` into
`!is_classic()`, which would start **deleting the `classic_only` `player_volume` areas in
zstandard**. On Docks survival that risks putting the player out of bounds — the opposite of what
we want. (Its other change is `add_adjacent_zone("zone_dock", "zone_dock_puzzle",
"docks_inner_gate_unlocked")`, which is unrelated.)

**The probe** (`zmqol_docks_probe`, read-only, prints every 5s for 40s) reports per player:
`origin`, `health`, `afterlife`, `lives`, `characterindex`, `model`, `getcurrentweapon()`, plus the
`is_enabled` state of the four docks zones. That distinguishes the remaining possibilities in one
run:
- `afterlife=1` → afterlife state; find what set it.
- `afterlife=0`/`UNDEF` + `model=UNDEF` → `givecustomcharacters` never ran → chase
  `zstandard_preinit` / `giveloadoutlevelspecific`.
- `health` dropping → something is damaging the player on spawn after all.

Remove the probe once answered.

---

## 3. TEST BACKLOG (carried forward)

1. 🛑 **5-map stock-location boot test** — 2 of 5 (`zm_transit` ✅, `zm_prison` ✅). Unrun:
   `zm_buried`, `zm_highrise`, `zm_nuked`. Rollback: restore `zone_source\base\mod.ff` over
   `mod.ff`, run `build.bat`.
2. Tunnel, Diner, classic TranZit — blocked all round by §1, all still untested.
3. Die Rise (shopping_mall / dragon_rooftop / sweatshop) and Buried (maze) — never tested at all.
   Same `init_zones` split exists on every map; check §2 Theory A's reasoning per map, but note it
   only bites where the loc script does *not* repopulate `initial_spawn`.
4. Borough/street wallbuys; Diner wallbuys physically present; Cornfield's boundary wall; LUI hint
   text clears the preview panel.
5. Regression: perk descriptions after several revives; instant start.

**Open gameplay question, not a crash:** on Origins survival `_zm_perks::init()` bails at line 52,
so no perk machinery initialises — yet Wunderfizz is set up by the loc scripts and Origins includes
Electric Cherry and PhD in its rotation. Now testable, since Origins loads.
