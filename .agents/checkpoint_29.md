# Checkpoint 29 — Who's Who CONFIRMED. Electric Cherry CLOSED. v1.63.2, no code change this round.

Written 2026-08-09. Supersedes checkpoint 28 for status only — 28's §1 (the three methods) is still
the useful part and should be kept.
Keep 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **Who's Who visuals** | ✅ **CONFIRMED IN GAME** — user: *"working fine, all effects working good"* |
| **Electric Cherry** | 🛑 **CLOSED. Vanilla by the user's explicit decision.** Do not re-open. |
| **Boarded-window fix** | ⏳ shipped v1.63.1, booted since, **not reported on either way** |
| v1.62.0 solo gameplay | ⏳ still never tested — boot Mob, carry two plane parts at once |
| v1.62.3 Vulture icon shapes | ⏳ still never tested |
| v1.62.4 Vulture machine markers | 🛑 measured broken (`0 of 43 structs match`) |

**Next action: ask whether the Diner window fix held.** That is the only thing in flight. Once it is
confirmed, the next item is TASKS_QUEUE_01 #2, the Zombie Blood power-up.

---

## 1. 🛑 ELECTRIC CHERRY IS CLOSED — DO NOT RE-OPEN IT

Four rounds. The answer never changed. The user has now chosen, with the numbers in front of them.

The perk is **byte-for-byte stock on every map**, verified by decompiling
`maps/mp/zombies/_zm_perk_electric_cherry.gsc` **out of the shipped `patch_zm.ff`**, not the
gsc-dump. `BO2-Reimagined` keeps the identical curves; it only deletes the throttle.

```
radius = linear_map( clip_fraction, 1.0, 0.0,  32, 128 )
dmg    = linear_map( clip_fraction, 1.0, 0.0,   1, 1045 )
round-10 zombie health = 1045
```

| clip | radius | damage | round 10 |
|---|---|---|---|
| 8/8 | 32 | 1 | nothing |
| **7/8** | **44** | **131** | **8 zaps — what the user was doing** |
| 0/8 | **128** | **1045** | **one-shots the close ring** |

**44 units does not reach a zombie mid-swing** (~50-70 units origin to origin). Those zaps were not
weak, they were out of range.

Offered as three numeric tables — raised floor, flat maximum, vanilla. **The user chose vanilla.**
Stock's consecutive-reload throttle (#6+ does literally nothing) stays too.

**Already ruled out — do not re-tread any of it:** `get_round_enemy_array()` (only filters
`ignore_enemy_count`); `get_array_of_closest()` (squares maxdist correctly, so the radius test is
right); the mod's damage hooks (`register_zombie_damage_callback` only — additive, cannot reduce
damage); the reload latch (no `SKIPPED` lines in the instrumented boot); the whole fx/material chain
(byte-identical to `zm_prison`'s).

📝 How to use it: fire the WHOLE magazine dry, then reload into the horde.

---

## 2. 🌟 WHAT ACTUALLY ENDED THE ARGUMENT — decode the user's recording

Three rounds of "is our code stock?" answered correctly and never moved them. What ended it was
**decoding their clip and reading the HUD**.

`ffmpeg` at `C:\Program Files\File Converter\ffmpeg.exe` is the **only** build in this workspace that
decodes NVIDIA AV1 captures — the two BlackOpsII SoundStudio copies carry libaom and fail.

```
ffmpeg -i clip.mp4 -vf "fps=8" -q:v 2 clip/f_%03d.png
ffmpeg -i "clip/f_%03d.png" -vf "crop=360:80:1540:930,tile=4x17:margin=4:padding=4:color=white" sheet.png
```

Crop the HUD region, tile the crops, read the sequence at a glance. The ammo counter read
`8/49 -> 7/49 -> 8/48 -> 7/48 -> 8/47 -> 7/47 -> 8/46` — **one bullet fired, then reload, every
time.** That single observation explained the entire four-round report.

**Reuse this whenever a user's report and the code keep disagreeing.**

---

## 3. WHO'S WHO — what made it work, worth keeping

The perk shipped functional but with **every** effect skipped, because
`_zm_chugabud::activate_chugabud_effects_and_audio()` is wrapped in
`if ( isdefined( level.whos_who_client_setup ) )` and only `zm_highrise.gsc:81` sets it.

The one that cost a boot: **`vsmgr_register_visionset_info()` must run inside the client's visionset
window, and you cannot poll for it.** The whole client init is synchronous — `_zm.csc::init()` runs
`_visionset_mgr::init()` at :39 and everything after it without yielding, and the engine fires
`finalize_clientfields()` in the same sequence. A thread that waits one frame wakes after the window
shut, registers nothing, and prints nothing. It now runs at the end of this mod's client
`perks_register_clientfield()` override, which stock calls from `_zm_perks::init()` at `_zm.csc:~63`
— same synchronous run, after the manager exists, before finalize.
Full detail: [[t6-visionset-registration-timing]].

Buried is dropped (its classic `actor` set is 32/32); Origins now sits at exactly 32/32 and can never
take another actor bit.

---

## 4. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | ✅ **DONE** — Who's Who confirmed, EC closed as vanilla |
| 2 | Zombie Blood power-up from Origins onto every map | **NEXT**, not started |
| 3 | Blood Money power-up, dropping from kills rather than dig sites | not started |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command must also be a dvar — [[zm-qol-commands-as-dvars]].
Governing rule for all of them: **port it, never tune it** — [[zm-qol-port-never-tune]].
