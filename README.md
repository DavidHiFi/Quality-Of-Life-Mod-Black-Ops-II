# Quality Of Life

A Plutonium T6 (Black Ops II) Zombies mod: **all weapons + all perks on every map**,
the **BO2 Death Machine** power-up, **Diner as a Survival location**, and a stack of
QoL tweaks. All gameplay is plain GSC you can edit — no compiling, no linker.

> **Textures:** this mod no longer ships an upscaled texture pack. It was removed in
> v1.57.7 because loose `.iwi` files in `mod.iwd` did not reliably override the stock
> art, and it cost 2 GB for no visible result. Load a texture pack from
> `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead — that path works.

## How to change something (the whole loop)

1. Edit any `.gsc` in **`scripts\zm\`**.
2. Double-click **`build.bat`**.
3. Play: **Plutonium T6 → Zombies → Mods → `Quality Of Life`**.

`build.bat` rebuilds `mod.iwd` and installs the mod for you. That is all a GSC
change needs.

Only if you changed a **client script (`.csc`)** or a real asset under
`zone_source\` / `zone_assets\`, run **`build_ff.bat`** first — that relinks
`mod.ff` — then `build.bat`.

## Where stuff is

```
scripts\zm\        <- EDIT THESE (all the gameplay)
   quality_of_life.gsc        all weapons + perks + Death Machine + QoL, merged into one file
   zm_buried\, zm_tomb\, ...  per-map scripts (server .gsc + client .csc)
   locs\, replaced\           the Diner survival location and stock-function overrides
maps\mp\*.d3dbsp   <- map entity files shipped in mod.iwd
zone_source\       <- what gets linked into mod.ff (build_ff.bat)
build.bat          <- edit -> double-click -> play
build_ff.bat       <- only for .csc / asset changes
```

The six shipped files are `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`,
`mod.all.sabs` and `deathmachine_zm.all.sabl`. Everything except `mod.iwd`'s raw
source folders is built or don't-touch.

## What's in it

- **Weapons & perks** on every map, plus Pack-a-Punch where it's missing.
- **Death Machine** power-up drop. Dvars: `sv_deathmachine_duration` (30), `sv_deathmachine_powerup`.
- **Instant Pack-a-Punch**, **BO4 Max Ammo**, **wall buys refill the mag**.
- **Prone at a perk machine = +100 points** (once per machine, every map).
- **Diner as a Survival location** on TranZit, ported from BO2-Reimagined. Treyarch left
  the map data in the game but never shipped it as a Survival start. This is the only
  added location — `scripts\zm\locs\` holds exactly one location script.
- Hitmarkers, on-screen counters, high-round fix, Cold-War round HUD, no perk limit,
  animated camos, area names (TranZit), perk pop-up HUD.

## Add your own script

Drop a `.gsc` in `scripts\zm\`, give it an `init()`, run `build.bat`. That's it.
(Map-specific? It belongs in `scripts\zm\<mapname>\` — a map-specific reference in a
root script crashes every *other* map.)

**Credits:** sehteria (T6-ZM-Expanded), SadSlothXL (Death Machine), Jbleezy
(BO2-Reimagined, the reference for the survival locations), and the authors of the
bundled scripts.
