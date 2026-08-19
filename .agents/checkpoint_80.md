# Checkpoint 80 — v1.99.69. Eight versions, Vulture Aid rebuilt, three things settled by probe.

Written 2026-08-19. **Supersedes 79 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.69 is deployed and NOT booted.**

Everything from **v1.99.61 through v1.99.64** is now **confirmed in game** by the user across this
session. **v1.99.65 – v1.99.69** are partly confirmed and partly still open; the table is §4.

| shipped | state |
|---|---|
| Death Machine no longer survives Mob's afterlife (v1.99.62) | 🟡 **not tested** — the user never went to Mob |
| Nuketown MACHINE DROPS lobby row + `.machines` (v1.99.63/64) | ✅ confirmed, incl. the one-line hint |
| Machines land together, one siren (v1.99.65/66) | ✅ confirmed — log shows 9 sent, 9 landed |
| Brighter blue timers (v1.99.66) | ✅ confirmed in the screenshots |
| Lobby CHARACTER picks the right team (v1.99.65) | ✅ confirmed |
| Scoreboard emblem, pre-match | ✅ confirmed · mid-match 🛑 **proven impossible**, §2 |
| Wunderfizz Vulture marker (v1.99.67/68) | ✅ confirmed, white/blue `?`, centred |
| Mystery box Vulture marker (v1.99.68) | ✅ confirmed |
| Perk machine Vulture markers (v1.99.68) | 🟡 **disputed — probably correct already**, §3 |
| Zombie eyes brighter + single glow (v1.99.68/69) | 🟡 colour confirmed changed; single-glow **not booted** |

**Next action when they return:** the boot test in §4. It is ONE game and it settles two open items.

**🛑 Do not start anything new.** Queue items 24 and 25 are what this whole run has been; both are
still in flight.

---

## 1. WHAT SHIPPED, v1.99.62 → v1.99.69

**v1.99.62 — Death Machine vs Mob's afterlife.** Going down on Mob is not last stand:
`afterlife_player_damage_callback` (`_zm_afterlife.gsc:347-355`) intercepts the lethal hit and
threads `afterlife_laststand()`, whose third statement snapshots `getweaponslistprimaries()` into
`self.loadout`. The Death Machine went into that snapshot and `afterlife_give_loadout()` re-gave it
on revive — permanently, because the mod's timer had already expired. `zm_prison.gsc` now chains
`level.afterlife_save_loadout` and blanks the entry to `"none"`, **stock's own skip token**
(`:1268`), repointing `loadout.current_weapon` at the first real weapon.

**v1.99.63/64 — Nuketown MACHINE DROPS.** A lobby row (`nuked_all_machines`, STOCK / ALL ON ROUND 1)
filtered to `zm_nuked` + `zsurvival`, which is every game of Nuketown there is. Plus `.machines` /
`machines 1`. The hint was 147 chars, wrapped, and the second line drew through the map preview;
**87 chars is the ceiling** — see §5.

**v1.99.65/66 — everything lands together.** The queue was never a choice: one
`level.perk_arrival_vehicle` means nine arrivals are nine trips. `bring_perk()` takes `b_no_flight`,
which skips the quad and `moveto`s the machine down instead, sharing the whole landing block. One
machine failed to land on the first test; the fix was a fixed `wait 3.05` instead of
`waittill( "movedone" )` (`move_perk()`'s own 5.0s lift can still be running) plus a 5.0s pre-drop
pause. The log now names every machine SENT and LANDED.

**v1.99.67/68 — Vulture Aid markers, rebuilt server-side.** See §3.

**v1.99.69 — one eye glow.** The doubling is **stock**: `_zm.csc:644` gives every zombie its normal
eye and `_zm_perk_vulture.csc:504` adds the perk's on the same tag. `zmqol_vulture_single_eye()`
suppresses the normal one while the perk is held using stock's own `deletezombieeyes()` /
`createzombieeyes()`, both idempotent. A loop, not an event, because zombies spawn constantly.

---

## 2. 🛑 THE SCOREBOARD EMBLEM MID-MATCH — PROVEN IMPOSSIBLE, DO NOT RE-OPEN

The pre-game pick works and is confirmed. A **mid-match** change cannot move the badge, and this is
measured, not suspected. The v1.99.66 watcher logs every write; the user's `console_zm.log`:

```
[zm_qol] scoreboard emblem -> faction_cia (should_use_cia=1)
[zm_qol] scoreboard emblem -> faction_cdc (should_use_cia=0)
```

The second line fired the instant `character 2` ran — `g_TeamIcon_Allies` **was** set to
`faction_cdc` — and the scoreboard still drew CIA. The icon is resolved when the scoreboard widget is
built, and `setdvar` is the only lever GSC has (`_scoreboard.gsc` is four setdvar calls, nothing
else). `qol_opt_character()` now says so once on screen. Memory updated:
`t6_zombies_scoreboard_emblem.md`.

---

## 3. VULTURE AID — WHAT CHANGED AND WHAT IS STILL DISPUTED

**Markers now come from the SERVER.** The old route built its list from
`getstructarray( "zm_perk_machine" )` and matched `script_string` against
`"<gametype>_perks_<location>"`. **Nuketown deletes every one of those structs**
(`zm_nuked_perks::init_nuked_perks`) and drops machines on random pads at runtime, so the match
returned nothing. Die Rise's moving elevator perks are the same problem.

`_zm_perk_vulture.gsc::zmqol_vulture_marker_scan()` walks `getentarray( "zombie_vending" )` and marks
each trigger's own machine through **`use_trigger.machine`** — stock's direct entity reference, set
in `perk_machine_spawn_init` on every machine on every map — writing a 4-bit `zmqol_vulture_marker`
code. The client turns the code back into an icon and a perk name and reads the position **at draw
time**, so a machine that moves is still drawn correctly. Nuketown flags its sky-parked machines
(`zmqol_not_ready`) so no icon floats in the clouds.

🛑 **The gate is about who owns the CLIENT half.** `_zm_perk_vulture.gsc` ships raw and shadows stock
on Buried too, where the client half is Buried's compiled `.csc`. Registering a field there that it
does not register is `EXE_CLIENT_FIELD_MISMATCH` for everyone. Both gates exclude
`zm_buried` / `zm_tomb` / `zm_transit` and were **diffed to prove they agree**.

🌟 **The bit was measured.** Stock scriptmover usage from the per-map dumps: Nuketown 8/32, Die Rise
11/32, Mob 15/32; this mod adds 4+1 (and 4 more on Die Rise). Worst case ≈ 20/32. Buried is 25/32 and
Origins 32/32 — both out of scope anyway.

**Mystery box and fire sale were a real defect.** `vulture_perk_watch_mystery_box()` is
`wait_network_frame()` then a `while` testing `level.chests` — and it is an **init thread**. Off
Buried, `_zm_magicbox` has not built `level.chests` on its first evaluation, so it returned
immediately and the box was never marked, silently, forever. Both now wait for `level.chests`; the
loops themselves are untouched stock.

**🟡 STILL DISPUTED: the user reports perk machines unmarked — but they were holding ALL ELEVEN
PERKS in the screenshot.** Stock's rule, which this mod keeps, is that a machine glows only for a
perk you do **not** own; only Pack-a-Punch and Vulture Aid always show. So the report is very
probably correct behaviour. **Do not "fix" this before §4's test.** A `println` now names how many
machines the scan marked, which separates "the scan missed them" from "hidden by design".

**The eye glow took four rounds and the lesson is the probe.** Stock plays
`misc/fx_zombie_eye_vulture` — a *different* eye, not a brighter one. v1.99.65-67 drew the map's own
eye twice; the client's own log line proved that **applied** and the user still saw no change, so
that theory is dead rather than unproven. Brightness cannot be measured offline — **OAT can neither
load nor dump `FxEffectDef`, and the new `OAT.BSP.v2.0` build cannot either (tested)**. So
`vulture_eye_fx` selects between five candidates in game:

| value | effect |
|---|---|
| 0 | stock, no override |
| 1 | the map's own eye drawn twice — **known applied, known invisible** |
| **2** | `misc/fx_zombie_eye_side_quest` — **default**, authored to be spotted across a map |
| 3 | `maps/zombie/fx_zombie_eye_returned_orng` |
| 4 | `maps/zombie/fx_zombie_eye_returned_blue` |

All three new fx linked cleanly from Buried's fastfiles. **Delete the losers from
`mod_locations.zone` once the user picks.**

---

## 4. THE BOOT TEST — ONE GAME, TWO ANSWERS

**New Nuketown survival game, MACHINE DROPS = ALL ON ROUND 1.**

1. **Buy Vulture Aid and NOTHING ELSE.** Every other perk machine should now carry its icon. This is
   the §3 dispute and this is the only test that settles it.
2. **Look at a zombie's eyes** — expect ONE glow, not two.
3. Try `vulture_eye_fx 3` and `vulture_eye_fx 4` in console and say which of 2/3/4 reads best.
4. Then, separately: **Mob of the Dead** — take the Death Machine into a down, go to the afterlife,
   get revived. Expect your normal guns and **no** Death Machine. v1.99.62 has never been booted.

**In the log afterwards:** `vulture markers: N machine(s) marked` and `vulture eye fx = N`.

---

## 5. THINGS THAT WILL SAVE TIME LATER

- 🌟 **`use_trigger.machine` is the handle for a perk machine's MODEL** (`_zm_perks.gsc:2904`), set
  for every machine on every map next to `targetname = "zombie_vending"`. Never match structs again.
- 🛑 **`vulture_perk_scriptmover` is a BITMASK, not a value.** `vulture_callback_scriptmover` walks
  `clientfields.scriptmovers[i]` with `newval & 1 << i` and all four slots are taken — there are no
  spare values in it. An earlier note in this project said otherwise and was wrong.
- 🌟 **The lobby hint budget is ~90 characters.** Measured off a 2000 px screenshot: LUI is 1280
  units wide so 1.5625 px/unit; a 97-char line rendered 1186 px and the next word (~72 px) did not
  fit. PERK LIMIT's 83-char hint has shipped on one line since v1.99.26.
- 🌟 **A stock "watch" function that opens with `while ( isdefined( X ) )` and is threaded from an
  init path is a silent-exit waiting to happen.** Two of Vulture's three did exactly that off Buried.
- 🛑 **Nuketown has TEN drop pads and the mod fills NINE.** One crate stack always survives, in a
  random place. That is not a failed drop — the log's SENT/LANDED lines prove it. Adding a tenth
  machine is an open offer to the user, not a bug.
- 📝 A `waittill( "movedone" )` is unsafe when an earlier `moveto` on the same entity may still be
  running. Prefer a fixed wait matched to the move time.

---

## 6. RESIDUAL, UNCHANGED

`EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob (oldest live fault) · the LUI `beingAnimation` crash
fix is still unconfirmed (the jet gun has never been overheated) · published release **v1.99.21
cannot start a map** and is still downloadable; deleting or annotating it is the user's open
decision · Carpenter (queue 21) still needs its two answers: which map, and how far were the
barriers.
