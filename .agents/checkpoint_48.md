# Checkpoint 48 — v1.95.7. The generator ring is fixed at the mechanism; the crash hunt has a switch that finally works.

Written 2026-08-14, late. **Supersedes 47 for status.** Keep 47 §3 (what shipped in v1.94–95 and
why), 45 §1 (the ring's LUI mechanism — still the reference), 44 §1 (the runaway-`join` incident)
and §2 (XPR-50 asset measurements).

---

## 0. STATE — v1.95.7 deployed, tree clean

| version | what | state |
|---|---|---|
| v1.95.3 | both timers moved under the round counter, top right, dull navy | ✅ **confirmed in the user's screenshot** |
| v1.95.4 | generator-ring fix via a `hud_visible` flip after spawn | 🔴 **ran and did not work — superseded, now removed** |
| v1.95.5 | `zmqol_minimal` registered + `[zm_qol] minimal mode: N` printed at init | ✅ prints correctly |
| v1.95.6 | Mods-menu description shortened 130 → 45 visible chars | 🟡 never seen |
| v1.95.7 | **the ring fixed in LUI**, and the v1.95.4 HUD-hiding thread deleted | 🟡 **never booted** |

---

## 1. 🌟 THE GENERATOR RING — fixed at the mechanism, not the timing (v1.95.7)

**Three attempts failed because they were all the same shape: flip `hud_visible` 0 → 1 and hope it
lands after the client has built its LUI.**

| version | when it flipped | result |
|---|---|---|
| v1.90.10 | t+8s | ring stayed hidden |
| v1.90.11 | during an active capture | ring appeared, **whole HUD blinked** — user rejected it |
| v1.95.4 | after `spawned_player` + blackscreen + 0.5s | 🛑 **the log proves it ran** (`[zm_qol] ring hud: hud_visible cycled 0->1`) and the ring was still missing |

The server cannot observe when the client builds its menus, so **no timing is safe** — that is the
whole lesson, and it is why this kept coming back.

**Root cause, upstream of all of it:** `CoD.GametypeBase.new()` ends in `setAlpha(0)`, and the only
thing that ever raises that alpha is `CoD.TCZWaypoint.UpdateVisibility`, which runs solely on an
incoming `hud_update_bit_<N>` event. Adding an objective does **not** —
`GametypeBase.NewObjectiveEvent` builds the waypoint child and never touches the parent.

**The fix:** this mod already ships `ui_mp\t6\zombie\hudcraftablestombzombie.lua`, so it now wraps
the ring menu's own constructor — run stock's, then raise the menu it just built. No timer, no
event, no flag. Both load orders are covered (wrap in place, or a `__newindex` hook that wraps at
registration and passes every other key through with `rawset`).

- The menu name `TombCaptureZoneDisplay` came from the **string constant table of the shipped
  bytecode** in `zm_tomb_patch.ff`, not from a decompile.
- Alpha 1 on the parent draws nothing by itself: the wheel is a waypoint child created per
  objective, and stock keeps those objectives `"invisible"` until a capture starts.
- `.visible = true` is set too, so `UpdateVisibility`'s hide branch (`visible == true`) still works
  for the pause menu and scoreboard.
- 🛑 **`zmqol_ring_hud_visibility()` is no longer started.** It did not work and it took the
  player's HUD down for half a second at every spawn. User: *"no more hidden stuff"*.

▶️ **Untested.** One boot: Origins, first generator, hold F.

---

## 2. 🔴 OPEN #1 — ORIGINS/MOB STILL DIE WITH `EXE_ERR_RELIABLE_CYCLED_OUT`

🛑 **CORRECTION THAT MATTERS: `zmqol_minimal` HAD NEVER BEEN ON.** It shipped in v1.95.1 as a bare
`getdvarintdefault()` read with **no registration anywhere**, so typing `zmqol_minimal 1` was an
unknown command that silently did nothing. Proven from the dvar dump: every other `zmqol_*` the mod
creates is listed and that one never appears. v1.95.5 registers it and prints
`[zm_qol] minimal mode: N` at init, so the question can never be re-argued from a screenshot.

**Two boots were spent on a switch that could not be thrown**, and one Origins survival was
mis-read as a bisect result when it was just the intermittency.

### The offline sweep of all 18 gated threads — none is a plausible flood

Scanned for calls that actually cost a reliable command (`iprintln`, `setclientdvar`,
`setclientuivisibilityflag`, `settext`, `setshader`, `objective_*`), **comments excluded** — a first
pass counted the word "settext" inside a comment and was wrong.

| thread | reliable calls | when |
|---|---|---|
| `qol_opt_night_on` | 16 × setclientdvar | once, at spawn |
| `powerup_state_monitor` | 4 × setclientdvar | Death Machine only |
| `round_hud` | 5 × setshader | once per round transition |
| `zmqol_toggle_dvar_watch` / `_fly_` / `coop_pause` / `credits` | iprintln | only on a state change |
| `qol_opt_hud_watcher` | 1 × setclientuivisibilityflag | only on change |
| the other 11 | **none** | — |

The velocity meter is clean — it uses `setvalue`. **So a bisect that comes back "still crashes" is
the expected result, not a surprise.**

### Two more measurements, both NOT discriminators

- The crash lands 1–4 log lines after the **second `lui checksum` exchange** in all three crash
  logs — but a surviving session shows the same exchange and plays on.
- A **6.5–7.2 second main-thread hitch** happens at map load on **every** map, crashing or not
  (Diner 6977 ms, Die Rise 6854, Nuketown 6603, Origins 7246, Mob 6471). 📝 It does explain the
  `connected=0` that used to break the ring: the client finishes connecting *after* the mod's init.

### ▶️ THE TEST THAT HAS NEVER BEEN RUN, and it needs no build

**Boot classic Origins with the mod OFF.** Four theories are dead and the emitter cannot be found by
inspection; nothing in the record settles whether this is even the mod's fault.
- Vanilla crashes too → Plutonium/base-game on these two maps, and the hunt stops.
- Vanilla is fine → it is the mod, and `zmqol_minimal 1` (now real, now provable in the log) bisects.

---

## 3. 🔴 OPEN #2 — WHO'S WHO HAS NO SCREEN OVERLAY

🛑 **I got this wrong once and the correction is the useful part.** I said the overlay assets do not
exist off Die Rise. Wrong — I listed the retail fastfiles and never listed the mod's own.
`Unlinker --list mod.ff` carries all four: `rawfile vision/zm_whos_who.vision`,
`material generic_filter_afterlife`, `techniqueset sw4_2d_afterlife_q51e4w21`,
`image zm_afterlife_alcatraz_vignette_noise` — and the vision file and material **hash byte-identical
to Die Rise's own copies**. `mod_locations.zone:544` records the overlay as confirmed in game.

**The user's screenshot proves the code path ran:** the clone spawned and the audio played, so
`create_corpse == 1` and `activate_chugabud_effects_and_audio()` completed. Only the two visual
calls fail. *(Stock only calls that function inside `if ( create_corpse == 1 )` — the clone and the
effects are one branch and can never fail separately.)*

### The suspect: a shared filter-material counter, and the timing fits

`_filter.csc` hands out filter material slots from one counter starting at 4:

```gsc
init_filter_indices()  { ... level.filter_matcount = 4; }
map_material_helper( player, name )
{ ... level.filter_matid[name] = level.filter_matcount; player map_material( level.filter_matcount, name ); level.filter_matcount++; }
```

| map | slot 4 | slot 5 | slot 6 | slot 7 |
|---|---|---|---|---|
| Die Rise (stock, known good) | hud_outline | zm_turned | **afterlife** | — |
| Origins (Zombie Blood off) | hud_outline | zm_turned | **afterlife** | — |
| Diner (both on) | hud_outline | zm_turned | zombie_blood_b | **afterlife** ← |

**Zombie Blood (v1.65.0) landed immediately after v1.63.1, the version in which the overlay was
confirmed working**, and it pushes the afterlife material one slot past anything a stock map ever
uses. 📝 Pass indices were already checked by an earlier session and do *not* collide (Vulture 0,
Zombie Blood 1, Who's Who 5) — the **material counter** is a different resource and was never
checked.

▶️ **FREE DISCRIMINATOR:** `zm_tomb` is the **only** map with Who's Who and no Zombie Blood. Go down
with Who's Who on Origins.
- Overlay appears there, absent on Diner → confirmed; fix is the mapping order.
- Absent on both → Zombie Blood exonerated; next suspect is night mode, which pins `r_filmUseTweaks`
  and the whole `vc_*` grade (`night_mode "1"` is in the user's saved config).

---

## 4. 🟡 B-CONTROLS — three Plutonium rows missing, root-caused, NOT this mod's code

CONTROLS → LOOK should end MOUSE SENSITIVITY / **RAW INPUT / MOUSE ACCELERATION / FIX HIGH POLL RATE
LAG**. `%LOCALAPPDATA%\Plutonium\storage\t6\raw\ui\t6\menus\optionscontrols.lua` is a **retail
decompile dated 2025-11-01** sitting in Plutonium's raw folder, shadowing Plutonium's own patched
version; its `CreateLookTab` ends at the sensitivity slider. zm_qol does not ship that file and
`build.bat` never touches it. **Test handed to the user:** rename it aside, restart, look.

🛑 **The same disease is in `optionssettings.lua`** — the mod's copy is built on the same retail
decompile, which is why v1.93.0 had to hand-re-add four Plutonium GAME-tab rows. The proper fix is
to rebase the mod's copy on Plutonium's current file.

---

## 5. THE QUEUE — see `QUEUE.md` for the full entries

**B-TOGGLECONFLICT** 🌟 *diagnosed, mechanism certain, not yet fixed* — a chat command can never turn
ON what the menu turned off. The menu writes the dvar, `.infammo` writes only `player.zmqol_infammo`,
and `zmqol_toggle_dvar_watch()` polls the dvar and forces the field back within 0.25 s. Fix: the chat
commands must write the **dvar**, for all four toggles. · **B-VIEWMODEL** the viewmodel vanishes in a
high-round horde; lead is `lod_fix` forcing every model to max detail (`lod_fix 0` is the free
test) · **B-CDC** CIA/CDC picker above DIFFICULTY (lobby LUI; the server half already exists at
`qol_options.gsc:749`, but that dvar is recorded as doing nothing — prove it first) · **B-CROSSHAIR**
(`cg_drawCrosshair` is in the live dvar dump) · **B-WF** randomise the Wunderfizz's first spawn ·
**B-GEN** superseded by §1 · **B-DIG**, **B-TITUSRELOAD**, **B-ROUND**, **B-CHERRY**, **B-PERKLIMIT**,
**B-BACKSPEED** · Winter's Howl firing fx (**the free Wunderwaffe look is STILL not done** and it
decides the whole raw-`.efx` question).

---

## 6. NEXT, in order

1. **Origins, first generator** — the ring (§1). One boot closes a four-round bug.
2. **Origins, go down with Who's Who** — same boot, settles §3.
3. 🛑 **Origins with the mod OFF** — the crash (§2). Never run, and everything else is downstream.
4. The controls-menu rename test (§4).
5. Then the queue, one at a time — **B-TOGGLECONFLICT** first; it is already diagnosed.
