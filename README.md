# Quality Of Life

A **Plutonium T6 (Black Ops II) Zombies** mod: every weapon and perk on every map, three Black
Ops 1 wonder weapons, the Death Machine power-up, Diner as a Survival location, and a pile of
quality-of-life fixes — all toggleable from an in-game options menu.

> ### ⚠️ Work in progress
> Features land, change and get reverted between releases. It is playable, not final.
> See [Known issues](#known-issues).

## Install

1. Download the latest **[release](https://github.com/DavidHiFi/zm_qol/releases/latest)** zip.
2. Extract it into `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\`
   (Linux/Wine: the same path inside your Plutonium prefix). All six files go in that folder.
3. Launch Plutonium T6 → **Zombies → Mods → `Quality Of Life`**.

> Cloning the repo does **not** give you a playable mod — `mod.iwd` is not tracked in git.
> Use the release.

## Features

**Weapons**
- Every weapon on every map, plus Pack-a-Punch on the maps that lack it.
- **Eleven MP and campaign guns in the mystery box**, each with its Pack-a-Punch upgrade:
  SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50,
  Titus-6. Real models, animations and camos — nothing is a stand-in. Audio is stock's own,
  which for the Titus-6 means it is incomplete; see the known-issues table.
- **Three Black Ops 1 wonder weapons**: Thundergun, Wunderwaffe DG-2, Winter's Howl, each with
  its upgrade. They handle the special enemies properly — Brutus dies in two hits from any of
  them, helmet off on the first.

**Perks**
- All twelve perks on every map that can physically take them, with no perk limit.
- Wunderfizz on every map.
- ⚠️ **Vulture Aid is absent on Origins and TranZit** — both maps are out of per-player network
  field space, and shipping it there crashes the map at load. Those two keep the other eleven.

**Power-ups**
- **Death Machine** drop, **Blood Money** on every map, **Zombie Blood** on four more maps,
  and three announcer lines Treyarch recorded but never wired up.

**Maps**
- **Diner as a Survival location** on TranZit, with its own Pack-a-Punch, wall buys, Semtex,
  buildable riot shield, teddy bears and secret song.

**HUD and menus**
- **GAME / HUD / CHEATS tabs** in the pause menu: Options → Settings. 27 toggles, so you never
  have to type a chat command.
- Hitmarkers, on-screen counters, round summary, game and round timers, health bar, bleedout bar,
  zombies remaining, zone names, velocity meter, Cold-War round HUD, perk pop-ups.
- **Power-up timers** — seconds remaining above each power-up icon, the mod's own **Death Machine**
  power-up included. Confirmed working in game.
- **Instant match start** — no lobby countdown.
- Solo Play is titled Solo Play, and the Classic intro cutscenes play again.

**Quality of life**
- Instant Pack-a-Punch, BO4 Max Ammo, wall buys refill your magazine, high-round fix,
  animated camos, prone at a perk machine for +100 points.

**Commands** — chat command and bindable console command for each:
- `.round 30` jump to a round · `.give <weapon>` (add `pap` for upgraded, `.give list` for names)
- `.velocity`, `.fly`, `.god`, `.ghost`, `.hud`
- `.brutus <n>` / `.panzer <n>` / `.jumpingjacks <n>` spawn that map's real boss

## Known issues

| issue | detail |
|---|---|
| Origins and Mob can crash | `EXE_ERR_RELIABLE_CYCLED_OUT`, roughly 20–35 s into a match. Under active investigation. |
| Winter's Howl firing effects | **Muzzle flash fixed and confirmed in game (v1.99.7).** Only 1 of the gun's 11 muzzle-flash elements was flagged to draw with the viewmodel, so the rest rendered in the world pass at the camera and were invisible; v1.99.7 flags the six remaining visible ones. The Wunderwaffe (14 of 14 flagged) always looked right and the Thundergun (8 of 14) partly right. The separate "wind" the gun also showed was **not** the heat-shimmer element — v1.99.9 disabled that on a wrong theory and the boot proved it is part of the correct flash, so it was restored. The wind was `fx_freezegun_smoke_cloud`, a world-space cloud spawned at the player on every shot; v1.99.10 stops playing it. **Deployed, not yet confirmed in game.** |
| Zombie risers are silent on TranZit Survival | No sound when they climb out of the ground. **Every link in the chain is now verified end to end and the sound is still inaudible**: the trigger fires, the handler runs, the actor origin is valid and 513 units away (well inside the alias's 1000-unit range), the alias is defined in a loaded bank with an entirely ordinary volume and distance curve, its audio payload is present in the loaded bank the alias asks for, and the mod's own bank does not shadow it. v1.99.8 adds `.testsound` to answer the one question no file can — whether that alias makes any sound at all when played point blank. |
| Kill-feed icons missing | Kills with the eleven added guns show a blank icon in the feed. |
| Titus-6 is partly silent | Its dart makes no in-flight sound and it reloads silently. Measured: BO2 ships only four Titus sounds and none is a reload, so the audio has to come from the animation notetracks. |
| Who's Who has no screen overlay | The perk works and the clone spawns; the afterlife filter does not draw off Die Rise. |
| Bouncing Betty is not included | Its viewmodel animations and HUD icon do not exist anywhere to ship. |

## For developers

```
scripts\zm\        <- all the gameplay (plain GSC, no compiling)
   quality_of_life.gsc        weapons + perks + Death Machine + QoL, one merged file
   zm_buried\, zm_tomb\, ...  per-map scripts
ui\, ui_mp\        <- LUI menu overrides
zone_source\       <- what gets linked into mod.ff
```

1. Edit a `.gsc` → double-click **`build.bat`** → play. That is the whole loop.
2. Only if you changed a `.csc` or a real asset: run **`build_ff.bat`** first, then `build.bat`.

Longer documentation, kept out of this page on purpose:

| file | contents |
|---|---|
| [`MOD_CATALOGUE.md`](MOD_CATALOGUE.md) | every change this mod makes, how it was implemented, and what is still unfinished |
| [`STOCK_REFERENCE.md`](STOCK_REFERENCE.md) | vanilla BO2 Zombies behaviour — perk internals, clientfield limits, asset rules |
| [`ERROR_CATALOGUE.md`](ERROR_CATALOGUE.md) | every class of error this project has hit, and the check that catches each one |

**Credits:** sehteria (T6-ZM-Expanded), SadSlothXL (Death Machine), Jbleezy (BO2-Reimagined —
the reference for the Survival locations), and the authors of the bundled scripts.
