# Checkpoint 87 — v1.99.91. The two fatal bugs found and fixed, plus ten items from one report.

Written 2026-08-20. **Supersedes 86 for status.**

---

## 0. STATE — READ THIS FIRST

**v1.99.91 is built, hash-verified into Plutonium, NOT booted.** Nothing is half-built.
Everything from checkpoints 85 and 86 is also still unbooted, except the one thing the user *did*
confirm: **Diner hellhounds are FIXED** — *"Finished the dog round on round 6 in Diner, all the dogs
spawned in the map"* — and **the mod unloads cleanly with U**. Both can be struck off.

### 🔴 THE FIRST BOOT — in this order

1. **Any map at all starts.** Every map was dead before this build; that is the whole point.
2. **Origins and Mob of the Dead, classic** — they froze after the intro. Must reach the HUD now.
3. **Esc → RESTART GAME** — must behave exactly like `map_restart`, no fade, no freeze.
4. **HUD off** (`.hud off` or the HUD row) — the velocity meter AND the session watermark must go.
5. **Options → ADVANCED → FOG**, set it, quit the game fully, relaunch — it must still be set.
6. **GAME tab** — the row now reads **NO BOX LIMITS**, ENABLED = unlocked box.
7. **Nuketown:** buy the B23R off the wall, then hit the box — you must not end up with two.
8. **Diner survival:** the claymore wall buy in the Jugg shack (see §4 — one value is an estimate).
9. **Vulture Aid:** buy PhD with the markers up — its icon must vanish. Only the LIVE Wunderfizz
   should carry an icon, and it must go the moment the orb moves.
10. **Wunderfizz:** a TAP buys, and a TAP takes the bottle. No holding.

---

## 1. 🛑 WHY EVERY MAP DIED — `EXE_CLIENT_FIELD_MISMATCH`

`console_zm.log` names it outright, three times:

```
Clientfield 'powerup_zombie_blood' in set [toplayer] is not registered on the server
====================== COM_ERROR (3) === Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
```

**Cause.** v1.99.83's CUSTOM POWER-UPS row wrapped `add_zombie_powerup()` in
`if ( zmqol_custom_powerups_enabled() )`, on the stated belief that it only fills the drop table.
It does not — `_zm_powerups.gsc:446-452` ends with
`registerclientfield( "toplayer", client_field_name, ..., 2, "int" )`. The client half
(`zm_expanded.csc::zmqol_enable_zombie_blood`) registers it unconditionally. So the moment the user
set the row to Disabled, the two sides differed by one field and **every map dropped at load**.

🌟 The split proves the mechanism: Nuketown, Buried, Die Rise and TranZit died; **Origins and Mob did
not**, because Origins registers Zombie Blood itself in stock and `zmqol_zombie_blood_enabled()`
returns 0 on Mob — the only two maps where both sides still agreed.

**Fix (v1.99.91).** No registration is ever gated on that row again. Zombie Blood, Blood Money and
the Death Machine all register unconditionally; the row is enforced in the **drop predicate**
(`::zmqol_zb_should_drop`, `::zmqol_bm_should_drop`, `drop_deathmachine`), which
`get_valid_powerup()` calls per drop attempt, so it is read live and takes effect on the next drop
instead of the next map. **This also fixes the user's other report** — Zombie Blood dropping in Diner
with the row off.

## 2. 🛑 WHY ORIGINS AND MOB FROZE — a LUI panic, not a clientfield

`console_zm.log.004` (tomb) and `.005` (prison), identical:

```
Havok Script Panic — Unprotected error (ui_mp/T6/HUD.lua:367: function expected instead of nil)
  ... in function 'AddHUDWidgets' <- 'ForceHUDRefresh'
```

i.e. HUD.lua called a nil where a `LUI.createMenu.*` was expected while building the zombie HUD.

**Cause, every link measured.** v1.99.88 shipped `ui_mp/t6/zombie/ammoareazombie.lua`.
1. Stock ships that file **only** inside `zm_buried_patch.ff` / `zm_prison_patch.ff` /
   `zm_tomb_patch.ff`, so stock can only load it after the map's fastfile is loaded.
2. `huddigit.lua` — what its first line `require("T6.HUD.HUDDigit")` resolves to — ships in exactly
   those same three fastfiles. **It is not in `patch_zm.ff`.**
3. Shipping our copy on disk makes the engine load it early: log `.004` line 897
   `Loaded menu file: .../ammoareazombie.lua`, line 935 `Loading fastfile zm_tomb_patch`.
4. So the require ran when its dependency could not resolve, the menu loader swallowed the error
   (the log shows the load line and no panic), the rest of the chunk never executed, and
   `LUI.createMenu.AmmoAreaZombie` was never assigned.

Consistent with everything observed: only DLC2/3/4 maps call it, and Diner survival — which does
not — ran fine in the same session.

**Fix.** The require is deferred into the constructor, where the map's patch fastfile is long
loaded. `require()` is cached, so the later `CoD.HUDDigit` reads are covered by the same call.
Nothing at file scope may ever touch `CoD.HUDDigit` again.

## 3. THE OTHER NINE ITEMS

| # | item | what changed |
|---|---|---|
| 1 | RESTART GAME "wacky stuff", froze | `class.lua` now runs one `Engine.Exec(..., "map_restart")`, the same shape as INSTANT EXIT. The v1.99.87 popup override (fade, `silence`, `ui_busyBlockIngameMenu`, `fast_restart`) is **deleted**; stock's copy in `patch_zm.ff` is untouched. |
| 2 | HUD off left the velocity meter | `zmqol_velocity_dvar_watch` now ANDs `hud_master`. The `velocity` dvar is not written, so the preference survives. |
| 3 | HUD off left DRAW IDENTIFIER | `qol_opt_hud_watcher` stashes `cg_drawIdentifier` on switch-off and restores the user's own value on switch-on. |
| 4 | options not saving | Measured: 39 of 40 rows already write `seta` lines to the per-mod config. The one failure was **FOG** — `r_fog` is cheat-protected so it never archives, and the mod forced it to 1 on every connect. The row now drives `fog_enabled` (archives normally); `zmqol_fog_dvar_watch` carries it to `r_fog`. `.fog` writes the same dvar. |
| 5 | BOX LIMITS → NO BOX LIMITS, inverted | New dvar `no_box_limits` (default 1 = unlocked). `qol_options::init()` **migrates** any archived `box_limits` across inverted, once, so nobody's saved choice flips. |
| 6 | M14 not in the box | It is now. The v1.99.58 note claiming this needed assets was **wrong** and is corrected in place: every map registers `m14_zm` itself (7 stock call sites listed), so `zmqol_wallbuy_box_add` takes its already-registered path and only flips `is_in_box`. Client twin updated. |
| 7 | two B23Rs at once | **The mod caused it**: stock has attachment variants in the box on Origins only, and this mod adds `beretta93r_extclip_zm` / `ak74u_extclip_zm` to the box on all five other maps while the wall buy still gave the plain def. New `zmqol_wallbuy_variant_keep` generalises Origins' proven MP40 retag (stub + already-live triggers + full-match re-scan) to `beretta93r`, `ak74u`, `mp40`. Origins' own MP40 thread is deliberately left running — same value, no-op overlap. |
| 8 | Vulture icon stayed after buying PhD | The owned-perk filter existed but was never re-run. `zmqol_vulture_marker_perk_watch` (client) rebuilds the marker set when the local player's perk signature changes. Perk-agnostic, so it covers the three skull machines too. |
| 9 | every Wunderfizz had an icon | The marker was written once per machine at spawn. It is now written by the **arrival** branch and cleared by the **departure** branch, next to the ball and the glow. |
| 10 | Wunderfizz hold-to-interact | The trigger was `trigger_radius` (proximity), so `UseButtonPressed()` was only true if you were already holding. Now `trigger_radius_use` — stock's press-to-use trigger. Hints say "Press", and the bottle grab polls every frame instead of every 0.2s. |

## 4. ⚠️ THE CLAYMORE — ONE VALUE IS AN ESTIMATE, SAID PLAINLY

Struct shape and angles are stock's own, dumped from the TranZit farm claymore
(`claymore_purchase` + a `t6_wpn_claymore_world` model struct at the same origin, the model 90°
round from the buy struct). Height is measured: stock sits 51 units above its floor, so z = -7 here.
Both halves ship (server + `zm_expanded.csc` twin, same dvars, same defaults) — mandatory, because
`_zm_weapons.csc:182` registers a clientfield per `claymore_purchase` struct.

🛑 **What could NOT be measured offline: how far the wall is in front of the flashed spot.** The
`.d3dbsp` files here are entity dumps with no brush geometry, the survival addon mapents is 89 lines
with no barriers, and `zm_transit_gump_diner.ff` carries models only. So the origin defaults to the
flashed spot and four dvars nudge it:
`zmqol_claymore_diner_x / _y / _z / _yaw`. Changing one renames the clientfield **identically on both
sides**, so tuning is safe.

📝 **Open question for the boot: the yaw.** The shipped default is 270 (the direction the player was
facing). Stock's own claymore uses buy-yaw 90 with the room on the +Y side, and the Diner wall also
has its room side at +Y — which argues for **90**, i.e. 180° from what ships. If it looks backwards,
try `zmqol_claymore_diner_yaw 90` before anything else.

## 5. VERIFICATION DONE OFFLINE

- `gsc-tool -m parse` clean on all five changed `.gsc` and on `zm_expanded.csc` (`-i client`).
- `luaparse` (5.1) clean on all five shipped `.lua`.
- `build_ff.bat` then `build.bat`; `mod.ff` / `mod.iwd` / `mod.json` hash-match the deployed copies.
- New client symbol `zmqol_vulture_marker_perk_watch` confirmed **inside** the deployed `mod.ff`
  via `Unlinker --include-assets script`.
- Every new symbol confirmed inside the deployed `mod.iwd` (opened as a zip), and
  `restartgamepopupzombie.lua` confirmed **gone** from it.

## 6. CARRIED FORWARD

- Deadshot head lock-on and the AIM ASSIST row still need a gamepad.
- Jet gun overheat crash test still outstanding; items 6/7/8 sit on top of it.
- GitHub release `v1.99.21` still cannot start a map and is still downloadable — the user's call.
- Latest release published: **v1.99.89**. No release for .90 or .91 yet.
