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
- **Twelve MP and campaign guns in the mystery box**, each with its Pack-a-Punch upgrade:
  SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50,
  Titus-6, Tac-45. Real models, animations and camos — nothing is a stand-in. Audio is stock's
  own, which for the Titus-6 means it is incomplete; see the known-issues table.
  The Tac-45 becomes **dual-wield when Pack-a-Punched** ("Toughguy & Crybaby"), the same way
  stock's Mustang & Sally does, and ships its full multiplayer sound set — fire, dry-fire,
  distance, decay, LFE and the five reload foley cues.
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
| Winter's Howl firing effects | 🌟 v1.99.13 (deployed, not yet confirmed in game). v1.99.12 was wrong: it pointed **both** flash fields at `fx_freezegun_world`, whose `spawnOneShot` counts are 1–5 per element, so the first-person flash all but vanished. Muzzle flashes are played as **one-shots**, and `spawnOneShot` — not `spawnLooping` — is the count that matters; confirmed against Treyarch's own `fx_muz_*_gas_flash_1p` files. The assignment is now the convention both other wonder weapons use (`view` → `_view`, `world` → `_world`), which restores the flash the user approved in v1.99.7, and the two `gfx_fxt_env_snow_flakes` elements — the freezing storm, present only in the `_world` file — were copied **verbatim** into both `_view` files. They already carry `drawWithViewModel`, so they render in first person. |
| Kill-feed icons missing | Kills with the twelve added guns show a blank icon in the feed. |
| Titus-6 is partly silent | Its dart makes no in-flight sound and it reloads silently. Measured: BO2 ships only four Titus sounds and none is a reload, so the audio has to come from the animation notetracks. |
| Who's Who has no screen overlay | 🌟 SOLVED in v1.99.13 (deployed, not yet confirmed in game), and it was never a script bug. The audio still working was the clue: stock writes the audio and filter clientfields from the same four lines, so the whole effect path was running. **Five assets ship in `zm_highrise.ff` and nowhere else** — `material generic_filter_afterlife`, its two images `zm_whoswho_warpblur` / `zm_whoswho_mask`, its techset, and `rawfile vision/zm_whos_who.vision`. Off Die Rise the client asked for a filter material and a visionset that were not loaded, which in T6 is silent, not an error. All five now ship in `mod.ff`, the two images rebuilt from Treyarch's own source PNGs so their pixels travel too. |
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
