# Checkpoint 87 — v1.99.92. Both fatal bugs found in the logs and fixed, plus nine requests.

Written 2026-08-20. **Supersedes 86 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.92 is deployed, hash-verified into Plutonium, committed, NOT booted.**
Everything from checkpoints 85 and 86 is also still unbooted.

### 🔴 THE FIRST BOOT — in this order

1. **Any map starts at all.** v1.99.90 could not: four maps died at load with
   `EXE_CLIENT_FIELD_MISMATCH` and Origins/Mob froze after the intro. Both causes are fixed;
   this is the gate for everything else.
2. **Origins and Mob specifically** — they crashed in LUI, not on the clientfield, so they are a
   separate test from 1.
3. **Esc → FAST RESTART** (the new row under RESTART LEVEL, v1.99.92): restarts the match with no
   cutscene. ✅ RESTART LEVEL itself is CONFIRMED WORKING by the user on Origins, 2026-08-20 -
   *"it restarted the game here when testing on Origins and the intro cinematic played again"*.
4. **Diner survival:** the claymore wall buy in the Jugg shack — is it ON the wall and the right way
   round? (§3 — the position is the one thing that could not be measured offline.)
5. **HUD off** (`.hud off` or the HUD row): velocity meter AND the session watermark must both go.
6. **Options → ADVANCED → FOG**: set it, quit the game fully, relaunch — it must still be set.
7. **GAME tab**: the row now reads **NO BOX LIMITS** and ENABLED = unlocked box.
8. **Box**: spin for the M14. **Wall buys**: buy the B23R off the wall, then box a B23R — you should
   NOT end up with two.
9. **Vulture Aid**: buy PhD with vision up — its marker must vanish. Only the live Wunderfizz should
   carry a marker.
10. **Wunderfizz**: a TAP should buy, and a TAP should take the bottle.

---

## 1. 🌟 THE TWO CRASHES — both were in the logs, and they were unrelated

**Method note worth keeping: the split between which maps failed how is what proved both
mechanisms.** Four maps died at load, two got in and then froze, one (Diner survival) was fine.

### 1a. EXE_CLIENT_FIELD_MISMATCH — the CUSTOM POWER-UPS row

`console_zm.log`, three times:

    Clientfield 'powerup_zombie_blood' in set [toplayer] is not registered on the server

v1.99.83 wrapped Zombie Blood's `include_powerup` + `add_zombie_powerup` in
`if ( zmqol_custom_powerups_enabled() )`, on the stated belief that `add_zombie_powerup()` only
fills the drop table. It does not — `_zm_powerups.gsc:446-452`:

    if ( isdefined( client_field_name ) )
        registerclientfield( "toplayer", client_field_name, clientfield_version, 2, "int" );

so the row was gating a **clientfield**, while `zm_expanded.csc` registers it unconditionally.
🛑 **Origins and Mob were the only maps that still loaded, and that is the proof, not luck**:
Origins registers Zombie Blood itself in stock, and `zmqol_zombie_blood_enabled()` returns 0 on Mob,
so on those two maps the two sides still agreed.

**Fix:** registration is never gated again. The row is enforced in the drop predicate —
`::zmqol_zb_should_drop`, `::zmqol_bm_should_drop`, and a new first line in `drop_deathmachine()` —
which `get_valid_powerup()` calls on every drop attempt, so it is read live. That is also the fix
for *"I set Custom Powerups to Disabled and still got a zombie blood drop in Diner"*: the row now
takes effect on the next drop rather than the next map.

### 1b. The Origins / Mob freeze — a LUI require that ran too early

    Havok Script Panic — Unprotected error
    (ui_mp/T6/HUD.lua:367: function expected instead of nil)
    ... in function 'AddHUDWidgets' <- 'ForceHUDRefresh'

A `LUI.createMenu.*` was nil while the zombie HUD was being built. Chain, all measured:

1. Stock ships `ammoareazombie.lua` **only** inside `zm_buried_patch.ff` / `zm_prison_patch.ff` /
   `zm_tomb_patch.ff`, so stock can only load it after that fastfile is loaded.
2. `huddigit.lua` — what its top-level `require("T6.HUD.HUDDigit")` resolves to — ships in exactly
   those same three fastfiles, plus `patch/` and `patch_mp/` (neither loaded in a zombies session).
   **It is not in `patch_zm.ff`.**
3. Shipping our own copy on disk makes the engine load it early:
   `console_zm.log.004` line **897** `Loaded menu file: ui_mp/t6/zombie/ammoareazombie.lua`,
   line **935** `Loading fastfile zm_tomb_patch`.
4. So the require ran when it could not resolve, the menu loader swallowed the error (the log shows
   the load line and no panic), the rest of the chunk never executed, and
   `LUI.createMenu.AmmoAreaZombie` was never assigned.

**Fix:** the require is deferred into the constructor. Nothing at file scope may touch
`CoD.HUDDigit` — already true, and it must stay true.

🌟 **"Loaded menu file:" only appears for LUI loaded from DISK** (Plutonium's `raw\` or the mod's
`mod.iwd`); fastfile-resident LUI logs nothing. Every one of those lines in the log is a Plutonium or
zm_qol override. That is what made the load-order argument readable at all.

---

## 2. WHAT ELSE SHIPPED

| request | what was done |
|---|---|
| RESTART GAME froze | ✅ **CONFIRMED WORKING 2026-08-20.** one `Engine.Exec( ..., "map_restart" )`, as asked. `restartgamepopupzombie.lua` **deleted** — its fade / `silence` / `ui_busyBlockIngameMenu` / `fast_restart` was the "wacky stuff", and the busy-block is why a failed restart froze the UI |
| HUD off is not total | velocity meter now reads `hud_master` in its watcher (the `velocity` dvar is NOT written, so the preference survives); `cg_drawIdentifier` is saved on switch-off and restored verbatim on switch-on |
| options don't save | **measured**: 39 of 40 rows already archive to `players\mods\zm_qol\plutonium_zm.cfg`; the ten CHEATS rows are excluded on purpose. Only FOG failed — `r_fog` is cheat-protected so `seta` is refused, and `nofog_onplayerconnect` forced it back to 1 every connect. The row drives `fog_enabled` now, applied by `zmqol_fog_dvar_watch()` |
| BOX LIMITS | renamed **NO BOX LIMITS**, meaning inverted. New dvar `no_box_limits` (default 1) with a one-time migration `no_box_limits = !box_limits`, so nobody's saved choice flips |
| M14 in the box | the v1.99.58 "it needs assets" note was **wrong** and is corrected in place: all seven map scripts call `add_zombie_weapon( "m14_zm", ... )` themselves, so only `is_in_box` moved. Client twin updated too |
| B23R duplicate | `zmqol_wallbuy_variant_keep()` in `quality_of_life.gsc` retags wall-buy stubs to the box's variant on every map — `beretta93r_zm`→`_extclip_zm`, `ak74u_zm`→`_extclip_zm`, `mp40_zm`→`mp40_stalker_zm` — reusing Origins' proven stub + live-trigger mechanism. **Measured cause:** stock has attachment variants in the box on Origins only; this mod adds two of them to every map (5 per-map scripts), which is what let the same gun be held twice |
| Vulture markers stay lit | `zmqol_vulture_marker_perk_watch()` (client) rebuilds the marker set when the local player's owned-perk signature changes. Deadshot only appeared to work because stock hooks `perk_dead_shot` itself |
| Wunderfizz markers on every location | written on **arrival**, cleared on **departure**, next to the ball and the glow. `zmqol_wf_mark_for_vulture()` is now `zmqol_wf_vulture_marker( n_code )` |
| Wunderfizz hold-to-use | the trigger was a **proximity** `trigger_radius`, so `waittill("trigger")` fired on touch and the buy only landed if USE was already down. It is `trigger_radius_use` now (stock's press-to-use trigger); the bottle poll runs every frame instead of every 0.2s; prompts say **Press** |
| claymore wall buy | §3 |

---

## 3. THE DINER CLAYMORE — what is settled and what is not

`scripts\zm\locs\zm_transit_loc_diner.gsc` + the twin in `zm_expanded.csc`.

**Settled by measurement:**
- shape — stock's own farm claymore is two structs at one origin: `claymore_purchase` +
  `zombie_weapon_upgrade "claymore_zm"` targeting a `t6_wpn_claymore_world` model struct. Both are
  picked up like a `weapon_upgrade` pair (`_zm_weapons.gsc:849`, `.csc:182`), hence the server+client
  pair.
- **yaw rule** — at the farm claymore every pathnode within 120 units is on the +Y side, so the wall
  normal there is 90°, and stock's structs are buy 90 / model 180. So **buy yaw = wall normal,
  model yaw = +90**. `.where` reported yaw 270 and this mod's convention for it is *"stand where you
  want it, face the way it should face"*, so the pair is buy 270 / model 0.
- **height** — stock's claymore sits 51 units above its floor (struct z 103; nearest pathnodes 78;
  a pathnode is 26 above the floor in this map, from the Diner nodes at -32 with the floor at -58).
  Flashed z -58 is the player's feet, so z = **-7**.

**NOT settled:** the distance to the wall. `.where` reports where the player stood, not the surface
they were aiming at, and neither `zm_transit`'s ents nor `so_zsurvival_zm_transit`'s addonmapents
(89 lines, no barriers) nor `zm_transit_gump_diner.ff` (models only) carry a face within 1000 units
to pin the plane down. The origin therefore defaults to the flashed spot exactly, with dvars:

    zmqol_claymore_diner_x -3615   zmqol_claymore_diner_y -7398
    zmqol_claymore_diner_z -7      zmqol_claymore_diner_yaw 270

🛑 **Both sides read the same dvars with the same defaults.** The wall-buy clientfield is named from
`zombie_weapon_upgrade + "_" + origin`, so a one-unit disagreement between the server and client
copies is the same fatal mismatch as §1a.

---

## 4. CARRIED FORWARD

- **Deadshot head lock-on** — shipped, unverified; needs a gamepad and the `deadshot cf:` lines.
- **AIM ASSIST row** (CONTROLS > GAMEPAD) — built, unbooted, needs a gamepad.
- **Jet gun overheat crash test** — overheat it and let it cool. Queue items 6/7/8 sit on it.
- **Mod unload (U)** — ✅ confirmed working by the user 2026-08-20. Item 26 closed.
- **Diner hellhounds** — ✅ confirmed 2026-08-20: *"Finished the dog round on round 6 in Diner, all
  the dogs spawned in the map"*. v1.99.90's item is closed.
- **FAST RESTART** (v1.99.92) - a second row under RESTART LEVEL running `fast_restart`, stock
  RESTART GAME's own command. Same one-Exec shape, same gate, unbooted.
- **The new GAME / CHEATS rows** — ✅ confirmed working by the user, except RESTART GAME (fixed here).
- 🛑 GitHub release `v1.99.21` cannot start a map and is still downloadable — the user's call.
- Latest release published: **v1.99.89**. v1.99.90 and .91 have no release yet.

---

## 5. RULES THIS SESSION ADDS

1. 🛑 **Never gate a registration call on a settings dvar.** Not `registerclientfield`, not
   `add_zombie_powerup`, not `include_powerup` — anything that can reach a registration. Gate the
   BEHAVIOUR (a drop predicate, a callback body). v1.99.83's comment block explicitly promised this
   and still broke it, because it did not know what `add_zombie_powerup` does at the end.
2. 🌟 **Overriding a stock LUI file changes WHEN it loads, not just what it contains.** A file that
   stock keeps inside a map's patch fastfile gets loaded from disk before that fastfile is loaded,
   so any top-level `require` for a dependency that also lives there will fail. Defer such requires.
3. 🌟 **`Loaded menu file:` in console_zm.log = loaded from disk.** Absence of a line does not mean a
   file was not loaded; it means it came from a fastfile.
