# zm_expanded_deathmachine

A Plutonium T6 (BO2) Zombies mod: **all weapons + all perks on every map**, the
**BO2 Death Machine** power-up, and a stack of QoL scripts. All gameplay is plain
GSC you can edit — no compiling, no linker.

## How to change something (the whole loop)

1. Edit any `.gsc` in **`scripts\zm\`**.
2. Double-click **`build.bat`**.
3. Play: **Plutonium T6 → Zombies → Mods → `zm_expanded_deathmachine`**.

`build.bat` does everything — it rebuilds the mod and installs it for you. Done.

## Where stuff is

```
scripts\zm\        <- EDIT THESE (all the gameplay)
   ridgelandproject.gsc    all weapons + perks + Death Machine + QoL scripts, merged into one file
   zm_tomb\, zm_buried\, ...  per-map scripts
mod.ff / mod.iwd / mod.json / mod.all.sabl / mod.all.sabs / deathmachine_zm.all.sabl   <- the built mod (don't edit)
build.bat          <- edit → double-click → play
```

Only touch files in `scripts\zm\`. Everything else is built or don't-touch.

## What's in it

- **Weapons & perks** on every map, plus Pack-a-Punch where it's missing.
- **Death Machine** power-up drop. Dvars: `sv_deathmachine_duration` (30), `sv_deathmachine_powerup`.
- **Instant Pack-a-Punch**, **BO4 Max Ammo**, **wall buys refill the mag**.
- **Prone at a perk machine = +100 points** (once per machine, every map).
- Hitmarkers, on-screen counters, high-round fix, Cold-War round HUD, no-perk-limit.
- Night mode (Buried), animated camos, area names (Tranzit), and more.

## Add your own script

Drop a `.gsc` in `scripts\zm\`, give it an `init()`, run `build.bat`. That's it.
(Map-specific? Guard it: `if ( level.script != "zm_prison" ) return;`)

---
**Credits:** sehteria (T6-ZM-Expanded), SadSlothXL (Death Machine), and the authors of the bundled scripts.
