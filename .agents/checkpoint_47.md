# Checkpoint 47 — v1.95.2. Five versions shipped; the Origins crash has a bisect switch waiting.

Written 2026-08-14, evening. **Supersedes 46 for status.** Keep 46 §3 (what shipped in v1.93–94
and why), 45 §1 (the Origins ring LUI mechanism), 44 §1 (the runaway-`join` incident) and §2
(XPR-50 asset measurements).

---

## 0. STATE — v1.95.2 deployed, tree clean, tagged

| version | what | state |
|---|---|---|
| v1.94.1 | thundergun boss hook added to the close-range branch | ✅ **user confirmed: helmet off, then dead** |
| v1.95.0 | QoL menu rebuilt: arrows, two tabs, god/ghost dvar collision, 3 new toggles | ✅ **user confirmed: "looks much nicer"** |
| v1.95.1 | tabs renamed GAME / HUD, heading centred, `zmqol_minimal` bisect switch | 🟡 renames confirmed; **the switch has never been used** |
| v1.95.2 | direct Wunderwaffe hits on Brutus, Titus PaP camo slot 8 | 🔴 **never booted** |

**Confirmed working by the user this session:** the thundergun two-shotting Brutus; the QoL menu
layout and arrows; the GAME / HUD tab renames; the centred QUALITY OF LIFE heading; Origins and Mob
both booting on v1.94.1.

---

## 1. 🔴 OPEN #1 — ORIGINS STILL DIES WITH `EXE_ERR_RELIABLE_CYCLED_OUT`

**Two maps unplayable. Nothing else matters more.**

🛑 **Checkpoint 46's successor entry claimed this was fixed. It was not — that call was made on one
clean 2:03 run and I should not have made it.** Origins died again on v1.95.0 at 0:32, same error,
same place in the log (immediately after `[zm_qol] BASE zm_tomb/tomb t=20`).

### Four theories are now dead, each killed by evidence rather than by a boot

| version | theory | how it died |
|---|---|---|
| v1.93.1 | the night-mode ramp | Mob shares Origins' exact night branch and is fine; the ramp is one-shot now |
| v1.94.0 | the capture re-declare + HUD nudge | **neither line appears in the crash log** — both were provably not running |
| v1.95.0 | the zone-HUD `settext` at 4/sec | the crashing session's own dump reads `hud_zone "0"` |
| — | the mod's HUD generally | see below |

### 🌟 The dvar dump from the crashing session is the most valuable thing here

`console_zm.log.001`, at the moment Origins loaded:

```
hitmarkers "0"      hud_health_bar "0"   hud_master "0"     hud_remaining "0"
hud_round_timer "0" hud_timer "0"        hud_zone "0"       lod_fix "0"
round_summary "0"   night_mode "1"       velocity "1"
```

**Almost the entire mod HUD was already switched off and Origins crashed anyway.** The HUD
elements, hitmarkers, round summary and LOD fix are all exonerated. Still running: night mode
(one-shot ramp) and the velocity meter (`setvalue` at 20/sec — hudelem value state, believed not
the reliable channel, unproven).

### ▶️ NEXT ACTION — `zmqol_minimal 1`, one boot, no build

Shipped in v1.95.1 and **never used**. Set it at the console before starting a map and all **18**
periodic threads the mod owns return immediately (HUD watcher, round-counter master, LOD fix, night
mode, co-op pause, both timers, zombie counter, round chalk, velocity meter and its poll, Death
Machine state monitor, credits banner, console-command watcher, all five dvar watchers).
Default 0 and unregistered, so unset it changes nothing. Everything one-shot still runs.

- **Origins survives** → the emitter is one of those 18 and that list is the whole pool.
- **Origins still dies** → every periodic thread is exonerated; the cause is one-shot map setup
  (Wunderfizz placement, mp40 retag, perk/weapon registration) or is not this mod.

🛑 **Buried has never been retested** since v1.94.0. It must be booted before this is closed.

---

## 2. 🔴 OPEN #2 — WINTER'S HOWL STILL HAS NO FIRING FX

Unchanged from checkpoint 46 §2 and **not touched this session**. v1.91.0's "missing materials"
explanation is disproven; all six materials are reachable and the `.efx` is in the deployed
`mod.iwd`. The untested assumption is whether T6 loads a raw `.efx` from `mod.iwd\fx\` at all.

▶️ **Free discriminator, still not done:** fire the **Wunderwaffe** and look at the gun.
`maps/zombie/fx_zombie_tesla_electric_bolt` and `fx_zombie_tesla_tube_view` exist in no retail
fastfile and not in `mod.ff`, so they can only come from raw `.efx`. Bolts visible → raw `.efx`
load. Nothing → no raw `.efx` loads and every wonder-weapon effect needs another route.

---

## 3. WHAT SHIPPED THIS SESSION, and the mechanism behind each

| fix | the real cause |
|---|---|
| thundergun didn't pop Brutus's helmet | `thundergun_get_enemies_in_range()` splits targets into two buckets by distance. v1.94.0 hooked only `thundergun_knockdown_zombie` (480–1200 units). Inside 480 — the range Brutus is actually fought at — targets go to `thundergun_fling_zombie()`, which had no hook. The ragdoll launch the user described exists **only** on that branch, which is what pinned it. |
| god / ghost switched themselves back off | `god` and `ghost` are already owned by `zmqol_console_command_names()`, the chat-command channel, which blanks every name in its list. v1.94.0's state watcher used the same two names. The dump shows it: `god ""` and `ghost ""` next to `infinite_ammo "1"`. State dvars renamed `godmode` / `ghostmode`; `.god` / `.ghost` now write them back. |
| the menu arrows sat on the text | `SetupTabManager(widget, N)` — N is the tab strip's **total width**, and 500 was stock's value for four tabs. Measured the label runs off the screenshot (1280×720 LUI, 1.5625 px/unit). 800 for six long names, then **700** once they were renamed GAME / HUD. |
| the option list overflowed the ESC prompt | `CoD.ButtonList` neither clips nor scrolls. Stock's largest tab is 13 rows + 3 spacers = 14.5 pitches; the v1.94.0 tab was 23.5. Split into two tabs of 13 and 13.5. |
| the heading was left-aligned and said SETTINGS | `CoD.InGameMenu.New` calls `addTitle(title)` with no alignment and the default is Left. `codmenu.lua`'s constant table shows `addTitle` building `self.titleElement … :setAlignment(…)`, so re-aligning that handle is the supported route. |
| a direct Wunderwaffe hit on Brutus did nothing | `tesla_damage_init()` early-returns on any target still carrying `zombie_tesla_hit`, and the loop meant to clear it on survivors was gated on **`tesla_damage_func`, a field assigned nowhere** — not in this mod, the stock dump, or either donor. Brutus stayed flagged forever after his first arc. Now cleared per shot on every AI that is still alive. |
| Titus-6 had no PaP camo on Mob | Mob / Buried / Origins use camo index **40**; everywhere else 39. The three BO1 camos carry slots 0/3/8/12; `camo_titus6` had only 3 and 11, and slot 8 was an empty filler. |

🌟 **Two latent defects found while hunting other things**, both fixed on their own merits and
neither claimed as a cause: `qol_opt_zone_hud()` was sending `settext` — one reliable command —
four times a second forever whenever `hud_zone` was on; and both dvar watchers announced on their
first pass, so a config carrying `velocity 1` shouted at the player on every spawn.

🌟 **One false alarm caught before shipping:** the mod's `replaceFunc` of
`_zm::init_client_flag_callback_funcs` references nine `::handler` functions it does not define.
That looked fatal. `zm_expanded.csc:15` has `#include clientscripts\mp\zombies\_zm;`, so all nine
resolve. Recorded in QUEUE so nobody re-raises it.

---

## 4. THE QUEUE, in the user's own words — nine open items

| id | item |
|---|---|
| **B-GEN** | Origins generator progress overlay stays hidden until the scoreboard is toggled. 🛑 Coupled to OPEN #1: the code that made the ring appear is the code that was killing the game, so the next attempt must be event-driven, not on a timer. Untested lead: the mod skips the Origins intro, which flips the order the client HUD is built in relative to `declare_objectives()`. |
| **B-DIG** | zombie ground-spawn sound missing. Alias is `zmb_zombie_spawn`, played by stock `handle_zombie_risers()` off the `zombie_riser_fx` actor clientfield. Four causes eliminated (see QUEUE). ▶️ Free discriminator: is the dirt **burst** present at the moment of emergence? |
| **B-TITUSRELOAD** | Titus-6 reloads in silence. Not the weapon def and not the notetrack map — it needs the `fly_titus_*` foley family, and the names live in `viewmodel_titus_gl_reload_empty`'s notetracks in `monsoon.ff`. Do not guess them: a missing alias is silent. |
| **B-ROUND** | Mob round 1 — the round counter is missing from the top right. |
| **B-CHERRY** | prone at the Electric Cherry machine on Mob gives no +100. |
| **B-WF** | randomise the Wunderfizz's **first** spawn point on every map (single-location maps exempt). |
| **B-CDC** | CHOOSE CHARACTER: CDC / CIA above DIFFICULTY, survival only, solo and custom. 📝 `qol_options.gsc` already has a `character` dvar and watcher (gated off `zm_tomb` / `zm_prison`) — that is the server half. |
| **B-PERKLIMIT** | GAME-tab toggle for the 4-perk limit. |
| **B-BACKSPEED** | GAME-tab toggle for the backspeed fix. |

Also still open from earlier: `wpn_titus_proj_loop` (dart flies silently, in no bank on this
install), kill-feed icons for the ported weapons, and the Vulture Aid icon fallback for users with
no custom texture pack.

---

## 5. NEXT, in order

1. 🛑 **`zmqol_minimal 1` then Origins** (§1). Two maps unplayable; the switch is already deployed
   and costs one boot.
2. 🛑 **Boot Buried.** Never retested since v1.94.0.
3. **Verify v1.95.2**: a direct Wunderwaffe hit on Brutus (helmet, then dead), and the Titus-6's
   Pack-a-Punch camo on Mob.
4. **The Wunderwaffe fx look** (§2). Free, and it decides the whole raw-`.efx` question.
5. **One glance at the dirt burst** (B-DIG). Free, and it halves that search too.
6. Then the queue in §4, one item at a time.
