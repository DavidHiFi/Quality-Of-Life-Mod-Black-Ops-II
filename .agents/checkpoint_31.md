# Checkpoint 31 — Zombie Blood + announcers SHIPPED AND WORKING. One open bug: frametimes.

Written 2026-08-11, same session as checkpoint 30. Supersedes 30 for status; **30 §3 (the four
findings) and §5 (pipeline facts) are still the useful parts and should be kept.**
Keep 29 §2–§3, 28 §1, 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE — v1.65.0 → v1.65.5 all shipped this session

| item | state |
|---|---|
| **Zombie Blood** (TranZit, Nuketown, Die Rise, Buried) | ✅ **CONFIRMED IN GAME** on TranZit — red overlay, model swap, zombies ignoring the player |
| **Zombie Blood power-up icon** | 🚧 was a checkerboard, fixed v1.65.1, **not re-verified** |
| **Mob of the Dead boots** | ✅ **CONFIRMED** on v1.65.2 (screenshot is Mob gameplay) |
| **Origins unaffected** | ✅ booted clean on v1.65.0 (`console_zm.log.006`, normal quit only) |
| **The three announcer lines** | 🚧 deployed, **the user has not said whether they hear them** |
| Fire Sale icon on TranZit / Die Rise | 🚧 fixed v1.65.1, never verified (was broken since v1.55.x) |
| Wunderfizz docks machine moved | 🚧 v1.65.5, deployed, not booted |
| 🔴 **FRAMETIME / LATENCY** | ❌ **OPEN AND UNDIAGNOSED.** Two fix attempts made no difference. Probe shipped in v1.65.4, awaiting the test |
| Buried classic with Zombie Blood | ⏳ never booted — the remaining budget risk |
| Die Rise / Nuketown with Zombie Blood | ⏳ never booted |

**Next action: get the `qol_perf_probe 1` result.** It is the only thing that moves the open bug,
and it is decisive in both directions (§3).

---

## 1. 🌟 THE `*_lerp` TRAP — the most valuable thing learned this session

Mob failed to boot on v1.65.1 with `Trying to assign 3 bits for netfield visionset_slot but Client
Field Set toplayer is out of space`.

🛑 **`visionset_slot` was not the culprit.** It is registered LAST, by
`_visionset_mgr::finalize_type_clientfields()`, so it is merely whoever asked when the space had
already gone — ERROR_CATALOGUE §2, the failure mode that has now cost time three times.

**The real cost is invisible in every per-map clientfield dump.** Stock Mob has **no
`visionset_lerp` and no `overlay_lerp` field at all**, because every one of its own visionsets and
overlays has `lerp_step_count 1`, and `finalize_type_clientfields()` only registers the lerp field
when the max needs more than one bit. This mod adds PhD (5 steps → creates `visionset_lerp` at
3 bits) and Vulture (31 steps → creates `overlay_lerp` at **5**).

**Eight bits appear out of nowhere from two features that each look like they cost one.**

🛑 **THE RULE: before adding a visionset or overlay to a map, check that map's existing MAX
`lerp_step_count`, not just the bit count of the field you meant to add.** Now in
`MOD_CATALOGUE.md` §7a.

Zombie Blood's own share on Mob was only 3 (`powerup_zombie_blood` 2, plus widening
`visionset_lerp` 3→4 for its 15 steps), and removing it was enough — Mob boots.

📝 **If Mob ever runs out again, the lever is Vulture**, justified on its own terms rather than as a
budget raid: the perk already ships incomplete there (`zmqol_vulture_has_disease_meter()` returns 0
for `zm_prison`), which is the exact condition that took it off Origins in v1.59.0. Turning it off
frees 7 more bits — 1 + 1 + the whole 5-bit `overlay_lerp`, which no other Mob overlay needs.

---

## 2. 🌟 A COMPLETENESS-AUDIT BLIND SPOT — LUI-only assets

The Zombie Blood power-up icon shipped as a missing-material checkerboard, and **no script-side
audit could ever have caught it**, because nothing in the `.gsc` or `.csc` names it:

```
ui_mp\t6\zombie\hudpowerupszombie.lua:38-41
CoD.PowerUps.ClientFieldNames[6] = {
    clientFieldName = "powerup_zombie_blood",
    material = RegisterMaterial( "specialty_zomblood_zombies" ) }
```

That table is stock's own and the mod already shipped it, so the LUI was correctly asking for a
material that lives in `zm_tomb.ff` only and was absent from `mod.ff`.

**Auditing every `RegisterMaterial` in that file against every fastfile found a SECOND, already
shipped instance**: `specialty_firesale_zombies` scores `tra 0 nuk 1 hig 0 pri 1 bur 1 tom 1` —
absent from exactly the two maps this mod enables Fire Sale on. That icon had been a checkerboard
on TranZit and Die Rise since **v1.55.x**; nobody had grabbed one there to see it. The model shipped
and the icon did not, because the model is named in GSC (`add_zombie_powerup` precaches it) and the
icon only in LUI.

🛑 **Add to the completeness audit: when a power-up or perk is enabled on a map that never had it,
check the LUI's `RegisterMaterial` list too, not just the script's precaches.**

📝 A checkerboard is a missing **material**; missing *pixels* draw **black** (ERROR_CATALOGUE §5).
The two symptoms point at different halves of the asset, so read them precisely.

---

## 3. 🔴 THE OPEN BUG — frametimes, and what is already ruled out

User: *"whenever i have my mod loaded now my frametimes are all weird"*, then after v1.65.3,
*"its still framey as hell, started happening with the mod earlier i just wasnt sure"*.

### Established from the logs — do not re-derive

- **`com_maxfps "90"`.** The screenshot's 91 FPS is the CAP, with GPU 53% and CPU 40%. This is
  frametime **variance**, not throughput. Do not chase "low FPS".
- **`logfile "2"` is already set** (flush per write), and the gameplay period logged **zero** hitch
  warnings — all 14 in that session were during map load. The spikes are **below the engine's hitch
  threshold**, so they are small and frequent, not multi-hundred-ms stalls.
- **Hitch warnings appear in ALL eleven kept logs** at similar or worse magnitudes (worst 9184 ms)
  across five maps and many versions → the hitching is **long-standing, not a v1.65.x regression**.
- **`developer_script "0"`** — per ERROR_CATALOGUE §8, GSC runtime errors are being **swallowed**
  right now. An error firing every frame inside a loop would be invisible and would cause exactly
  this. **Ask for `developer_script 1` before anything else.**

### What was fixed anyway (v1.65.3) — real defects, but NOT proven to be the cause

Found by auditing every permanent loop for per-iteration HUD writes and array walks:

| loop | was |
|---|---|
| `first_spawn` health HUD | `settext` + `setshader` every 100 ms **unconditionally** — the exact pattern ERROR_CATALOGUE §7 names as the reliable-command flood |
| `shield_hud` | `setvalue` at **20 Hz**, for every player, even with no shield and the element invisible |
| `zombiecounter` | label set inside the loop by an `if/else` **whose two branches were identical**, costing a second full `get_round_enemy_array()` walk per tick |

All three now write only on change. 🌟 **The caches live ON THE HUDELEM, not in a local**, because
the health HUD destroys and recreates its elements when `hud_health_bar` is toggled — a local would
survive that and leave the fresh element permanently blank.

### The probe (v1.65.4) — the next concrete step

`qol_perf_probe 1`, read live so it toggles mid-game with no map reload, sleeps every always-on
per-player loop: health HUD (destroyed), zombie counter, shield HUD, perk-slot watcher, and
`updatedamagefeedback` (the only **per-bullet** path the mod owns).

- **still framey with it ON** → the mod's per-frame **scripts are exonerated**; the whole
  HUD/reliable-command theory is dead. Remaining suspects: `mod.ff`'s 3,870 assets and 776
  header-only images that load ahead of every map, or the 48 MB sound bank.
- **smooth with it ON** → it **is** the scripts, and those five loops are the entire suspect list.

📝 It is scaffolding, not a setting — absent from README and the options menu, **remove it once the
cause is known**.

🛑 **Do not ship a third speculative fix before this result comes back.** Two have already landed
with no effect; a third would make attribution impossible, which is what the one-at-a-time rule
exists to prevent.

---

## 4. MAPENTS SETTLES PLACEMENT QUESTIONS — the Wunderfizz docks move

The docks machine sat **11.5 units** from `alcatraz_shield_zm_dolly` at `(-831.73, 5587.2, -71.75)`.
Moved 57 west to `(-900, 5585, -72)`; separation now 68.3.

**The method is reusable**: dump `mapents`, extract every candidate/part struct with its origin,
and check ALL machines against ALL parts programmatically. All six Mob machines × all ten
`alcatraz_shield_zm_*` structs → exactly one pair under 400 units, and none under 60 after the move.

📝 The dolly is one of **three** possible spawns, which is why the clash only appeared on some games
and survived this long.

🌟 **Pathnodes are the game's own record of clear walkable floor** and are the right anchor when
choosing a spot — the new origin sits 42 units from `(-890,5544)`, beside it rather than on it, so
zombie pathing is untouched.

⚠️ **mapents cannot see static BSP geometry.** A crate that is world brush rather than an entity
appears in none of those checks. When precision matters, ask the user to stand where they want it
and send a `.where` — that removes all inference.

---

## 5. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | ✅ DONE |
| 2 | Zombie Blood power-up from Origins onto every map | ✅ **DONE and confirmed on TranZit** — four maps; Mob excluded on measured budget grounds |
| 3 | Blood Money dropping from kills rather than dig sites | 🚧 shipped v1.64.0, still never confirmed |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command must also be a dvar — [[zm-qol-commands-as-dvars]].
Governing rule: **port it, never tune it** — [[zm-qol-port-never-tune]].

🛑 **Nothing on this list starts until the frametime bug is closed.** It is the item in flight.
