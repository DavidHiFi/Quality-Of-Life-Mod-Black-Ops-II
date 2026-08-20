# Checkpoint 89 — v1.99.93 deployed. The PATCHES tab is COMPLETE; two of its rows were held back.

Written 2026-08-20. **Supersedes 88 for status.** Checkpoint 88 described the half-built state; this
one describes what actually shipped, and it differs from 88's plan in two places on purpose.

---

## 0. STATE — READ THIS FIRST

**Deployed, committed, NOT BOOTED: v1.99.93.** `.gsc` + LUI only — no `.csc`, no assets, so
`build.bat` alone was correct and `build_ff.bat` was not run.

Deployment verified rather than assumed: `mod.iwd` / `mod.ff` / `mod.json` hash-match the source
tree, all five new GSC symbols were read back out of the **deployed** `mod.iwd`, and
`optionssettings.lua` matches in both places it lives (inside `mod.iwd` and in Plutonium's
shadowing `raw\ui\t6\menus\`).

### THE NEXT ACTION

Nothing to build. **Wait for the user's boot**, then work the first-boot list in §4.

---

## 1. WHAT SHIPPED

**PATCHES tab** (new, sits directly after GAME):

| row | dvar | default | mechanism |
|---|---|---|---|
| BACKSPEED PATCH | `move_speed` | 1 | moved off GAME, dvar unchanged |
| ANIMATED CAMO PATCH | `anim_pap_camo` | 1 | moved off GAME, dvar unchanged |
| REMOVE ROUND CAP | `remove_round_cap` | **1** | OFF re-adds stock's `if ( 255 < round )` clamp to this mod's own `round_think()`, and to `zmqol_goto_round()`'s target clamp |
| 24 ZOMBIE SOLO CAP | `solo_zombie_limit` | 0 | `level.zombie_total = 23` on `start_of_round`, solo, past round 5 |
| INSTAKILL ROUNDS | `instakill_rounds` | 0 | `replaceFunc` on `_zm::ai_calculate_health`, one function, two branches |
| DOUBLE TAP 1.0 | `double_tap_1` | 0 | `perk_weapRateEnhanced 0`, cached/restored |
| NO BARRIER ATTACKS | `no_barrier_attacks` | 0 | `level.attack_player_thru_boards_range = 0`, cached/restored |

**CHEATS tab**: `set_points` (holds its value, applied on change only, score written directly) and
`teleport` (action row, writes itself back to 0, classic games only).

GSC lives at the end of `scripts/zm/quality_of_life.gsc` —
`zmqol_ai_calculate_health`, `zmqol_patches_watch`, `zmqol_solo_zombie_limit`,
`zmqol_set_points_watch`, `zmqol_teleport_watch`, `zmqol_teleport_dest`.

---

## 2. 🛑 THE TWO ROWS THAT WERE HELD BACK — the user's decision, not a to-do

Checkpoint 88 planned both of these. **Both were disproven before they were written**, so neither
shipped, and the LUI rows were deleted rather than left as dead switches.

### SLIQUIFIER PRE-NERF — legacy's lines do the OPPOSITE on this build

- `level.zombie_vars["slipgun_reslip_rate"] = 0`. The shipped script reads it as
  `if ( level.zombie_vars["slipgun_reslip_rate"] > 0 && randomint( ... ) == 0 )` —
  `_zm_weap_slipgun.gsc:745` in the stock dump, `:779` in the `zm_highrise_patch` decompile. **0
  therefore means NEVER re-slip**, not always. BO2-Reimagined sets the same 0 and its README treats
  no-reslip as a deliberate balance change, which corroborates the reading.
- `level.zombie_vars["slipgun_max_kill_round"] = undefined` feeds
  `ai_zombie_health( undefined )` at `:65`, whose `for ( i = 2; i <= round_number; ... )` cannot
  loop — so `level.slipgun_damage` ends up 150 or undefined. **Weaker goo, not uncapped goo.**
- There is **no pre-patch copy of that script in the workspace**: `BO2-Raw-files`' base decompile
  carries the same `6` / `100` values the patch fastfile does, so there is nothing to port.
- A *reconstruction* is possible and was not shipped because it would be invention: reslip rate 1
  (always) plus `level.slipgun_damage` raised so the goo is lethal at any round — the same effect
  Reimagined gets by replacing the damage call with `dodamage( enemy.health )`.

### RECOIL PRE-NERF — the dvar does not exist

`sv_patch_zm_weapons` is absent from: the boot dvar dump in `console_zm.log` (2,764 dvars, printed
alphabetically — `sv_paused` and `sv_playlistFetchInterval` sit either side of where it would be),
`t6zm.exe`'s string table (both the Steam copy and Plutonium's), the Plutonium bootstrapper, and
`dvar_descriptions.json`. The same searches **find** `perk_weapRateEnhanced` in the dvar dump at
`"1"` and in the bootstrapper, which is what makes the negative result meaningful rather than a
failed search. T6-B2OP registers the name itself, which proves only that another mod created it.
`setdvar` would create a dvar nothing reads.

Recoil lives in the weapon defs (`viewkick_*`), so a live toggle is not reachable from GSC at all;
the only routes are a global recoil scale (`bg_viewKickScale` and friends — a *tuning*, not the
patch) or shipping pre-patch weapon defs in `mod.ff` (permanent, not toggleable, and the
asset-ownership trap). Both need the user's say-so.

---

## 3. WHAT WAS MEASURED, so it is not re-derived

- **Round 163 is real and simulated, not folklore.** Over the stock numbers
  (`zombie_health_start` 150, `+100` a round to 9, `+10%` from 10 — `_zm.gsc:860-862`): round 155 =
  1,044,606,723; rounds 156-162 clamp to that; round 163's addition wraps to **-2,055,760,018**,
  which legacy's `< 0` branch resets to 150. Stock never gets there because it saturates and
  returns (`_zm.gsc:3583-3587`).
- **`perk_weapRateEnhanced 0` = "removed shooting 2 bullets for every shot"** — BO2-Reimagined sets
  the same dvar and says exactly that in its README under Double Tap.
- **NO BARRIER ATTACKS needs no replaceFunc.** `level.attack_player_thru_boards_range` is read in
  exactly two places in the whole dump, both in `_zm_spawner.gsc` (`:833` builds
  `self.player_targets`, `:878` squares it), and written in one (`:68-69`, 109.8).
- **SET POINTS must not use `minus_to_player_score`.** It fires `level notify( "spent_points" )`
  (`_zm_score.gsc:341`) and Origins counts that toward the Rituals of the Ancients points challenge
  (`zm_tomb_challenges.gsc:49`), whose reward is a free Double Tap. Direct assignment is stock's own
  route in this situation — `player_downed_score_loss`, `_zm_score.gsc:303-308`.
- **The teleport guard is `ui_gametype == "zclassic"`, NOT the location dvar.** Bus Depot is
  `zstandard` at location `transit`; a location-only test is the exact false negative that cost every
  TranZit survival a perk in v1.83.0.
- **No name collisions**: neither `teleport` nor `set_points` appears in the 2,764-dvar dump or in
  `zmqol_console_command_names()` (that channel blanks its names, which is what broke `god`/`ghost`
  in v1.94.0). Nothing else in the mod replaces `ai_calculate_health`.

---

## 4. FIRST BOOT — what to look at, in order

1. **The tab exists and the GAME tab lost exactly two rows.** GAME should now be 11 rows, PATCHES 7.
2. **REMOVE ROUND CAP off + `.round 300`** should announce and land on **255**; on (the default) it
   should land on 300.
3. **NO BARRIER ATTACKS on** — stand at a boarded window and let a zombie reach in. It should not
   swing at all. Off again should restore it within half a second.
4. **DOUBLE TAP 1.0** — the console prints `[zm_qol] DOUBLE TAP 1.0 on - perk_weapRateEnhanced 0` on
   every flip; with Double Tap bought, damage per shot should drop back to one bullet's worth.
5. **24 ZOMBIE SOLO CAP** — solo, past round 5, with the zombies-remaining HUD on: the count should
   start at about two dozen instead of climbing every round. 📝 The code pins 23 *remaining* at
   `start_of_round`; whether the round total reads 23 or 24 depends on whether one zombie has already
   spawned in that frame, and the HUD will say which. The row's label says 24 — if the HUD reads 23,
   the label is what should change, not the port.
6. **SET POINTS** — step it up and back down; the points readout should land exactly on each value
   and the chat line should say so. On Origins, check the Rituals challenge does NOT tick.
7. **TELEPORT** — one destination per map, and confirm the refusal line appears in a survival game.
8. Still outstanding from before: the jet-gun overheat crash test, the Deadshot head lock-on probe,
   and everything in checkpoint 87 §0 that has not been booted.

---

## 5. RESIDUAL RISK

- The two watchers read a **server** dvar per player, so in co-op SET POINTS sets everyone — the same
  shape the god / ghost / infinite-ammo rows already ship with, and stated in the source.
- `setroundsplayed()` is missing from this mod's `round_think()` entirely (both of stock's calls).
  That is **pre-existing**, was deliberately not restored under the round-cap row, and is worth a
  queue item on its own if the end-of-game "rounds survived" stat ever looks wrong.
- INSTAKILL ROUNDS is only observable past round 155, so it will not be verified by a normal test
  session; `.round 163` is the way to see it.
