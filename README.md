# Quality Of Life

> ## ⚠️ WORK IN PROGRESS
>
> **This mod is unfinished and under active development.** Features land, change and get
> reverted between releases; some are deployed but not yet verified in game. Expect bugs,
> and expect things to move. It is playable, not final.
>
> ### 🛑 Known issue in this release
>
> **TranZit in Classic mode does not load.** It exits to the menu with
> `Trying to assign 1 bits for netfield vulture_perk_toplayer but Client Field Set toplayer
> is out of space` — the map runs out of per-player network field space once the mod adds
> Vulture Aid on top of everything else it enables there. **Every other map loads and plays:
> Nuketown, Die Rise, Mob of the Dead, Buried and Origins in Classic, and all Survival modes
> including TranZit's.** The cause is measured and the fix is in progress; it is not a
> mistake in your install and nothing you can configure will work around it.

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

## Reference docs

Two long-form catalogues, kept deliberately separate so "what we changed" is never confused with
"what the game already did":

| file | contents |
|---|---|
| [`MOD_CATALOGUE.md`](MOD_CATALOGUE.md) | every change and addition this mod makes, by category, with how each was implemented and what is still broken or unfinished |
| [`STOCK_REFERENCE.md`](STOCK_REFERENCE.md) | **vanilla, unmodded** BO2 Zombies behaviour — perk internals, clientfield limits, the LUI perk row, Vulture Aid's stock implementation, asset/fastfile rules. Every entry cites a file you can re-open |

**Update both in the same change that alters behaviour**, exactly like this README.

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
- **Blood Money on every map, dropping from kills.** The powerup (`bonus_points_player`,
  1-2500 points to whoever grabs it) is registered in core BO2 on all six maps but switched
  on only by Origins, which hands it out from a dig site alone. It is now included on every
  map and moved into the ordinary drop rotation — including on Origins, whose dig sites keep
  working unchanged. Costs no clientfield bits; the icon model ships in `mod.ff` for the four
  maps that lack it.
- **Zombie Blood on four more maps** — TranZit, Nuketown, Die Rise and Buried. Origins'
  power-up: 30 seconds during which every zombie ignores you completely, with the red screen
  filter, the visionset, the first- and third-person effects, the player-model swap and the
  looping audio — the full thing, ported asset for asset from `zm_tomb.ff`. Origins is
  deliberately left running its own copy. Its dig-site reveal is inert elsewhere because no
  other map has dig sites to reveal. **Not on Mob of the Dead**: that map's `toplayer`
  clientfield set is out of space, measured from a real boot failure rather than guessed.
- **Three announcer lines that were missing.** Zombie Blood's and Blood Money's exist only in
  Origins' sound bank, so both drops were silent on every other map; the Death Machine's
  (`zmb_vox_ann_death_machine`, Die Rise's bank) was recorded by Treyarch and **never wired up
  anywhere in the game** — zero references across all 2,093 stock scripts. All three are
  re-shipped in the mod's own sound bank and routed through the stock announcer path.
- **Three Black Ops 1 wonder weapons in the mystery box** — the **Thundergun**,
  **Wunderwaffe DG-2** and **Winter's Howl**, each with its Pack-a-Punch upgrade
  (Zeus Cannon / DG-3 JZ / Winter's Fury). They fire, chain, freeze and knock back
  properly, and handle the special enemies (Brutus, the Avogadro, screechers,
  leapers, mechz, dogs). Console commands give one directly:
  `give_thundergun 1`, `give_wunderwaffe 1`, `give_wintershowl 1` — or in chat,
  `.thundergun`, `.wunderwaffe`, `.wintershowl`. `zmqol_ww 0` turns all three off.
  🛑 **Known gaps, honestly:** the Wunderwaffe's view-model lights are still too
  bright, and **Winter's Howl's freeze fx can stop appearing during sustained
  rapid fire** — not yet root-caused, so nothing speculative has been shipped for
  it. Pack-a-Punch camos are **fixed in v1.76.0 but not yet confirmed in game**:
  the camo assets were already in `mod.ff` and the upgraded defs' `camo` field was
  empty (v1.75.0), but the real blocker was that all three camo assets were
  missing **slot 3** — stock asks for camo index 39 on every map except MotD (40)
  and Origins (45), and every stock camo carries entries at exactly slots
  {3, 8, 12} while these three carried {0, 8, 12}.
  📝 The report of the DG-2 never appearing from the box **was measured and is not
  a bug**: all three guns register identically, and with stock's box filters
  removed a specific gun is ~3.8% per spin, so missing it across a long game is
  ordinary variance. `zmqol_box_wonder_weight` (default 2, `0` = stock) now
  weights an unheld wonder weapon from round 10 — see `.agents/QUEUE.md`.
- **Jump to any round** — `.round 30` in chat (or `.setround 30`; `.round` alone
  prints the current one). Console/bind twin: `set_round 30`. 📝 Stock's own
  `zombie_devgui_goto_round()` cannot be used — its whole body, *and* every
  `endon( "kill_round" )` it relies on, sit inside `/# #/` developer blocks, so
  neither exists in a retail game. This drives stock's normal round-end path
  instead.
- **Instant Pack-a-Punch**, **BO4 Max Ammo**, **wall buys refill the mag**.
- **Prone at a perk machine = +100 points** (once per machine, every map).
- **Diner as a Survival location** on TranZit, ported from BO2-Reimagined. Treyarch left
  the map data in the game but never shipped it as a Survival start. This is the only
  added location — `scripts\zm\locs\` holds exactly one location script. It now carries a
  full set of its own:
  - **Pack-a-Punch** on the roof, reachable by the restored hatch climb.
  - **Its wall buys turned back on** — the MP5K inside and the Galvaknuckles on the roof are
    tagged `zclassic_transit` in the stock map, so Survival spawned neither.
  - **A Semtex wall buy** by the exit door. The map ships exactly one Semtex struct and it
    lives in Town, so this one is *created*, on both the server and the client — a wall buy
    is a clientfield, and a one-sided one drops every player at load.
  - **The buildable riot shield.** The parts and their spawns were always in the map; what
    was missing is that TranZit only registers buildables in Classic. Its part models, HUD
    icons and craft sounds ship in `mod.ff` — all of them are in the *Classic-only* fastfile
    that Survival never loads.
  - **The three teddy bears and the secret song**, matching Bus Depot, Farm and Town. Diner
    was the last Survival location without them.
- **Solo Play looks like Solo Play.** The lobby header read "CUSTOM GAMES" because Solo and
  Custom Games are the same menu, and the **Classic intro cutscenes** (Die Rise, Mob, Buried,
  Origins) never played because the game gates them on a party size the lobby kept resetting.
  Both fixed in the menu LUI.
- **Tombstone's HUD icon fixed** — stock ships it with the badge frame upside down
  relative to every other perk. Uses BO2-Reimagined's corrected 64x64 icon.
- Hitmarkers, on-screen counters, high-round fix, Cold-War round HUD, no perk limit,
  animated camos, area names (TranZit), perk pop-up HUD.

## Add your own script

Drop a `.gsc` in `scripts\zm\`, give it an `init()`, run `build.bat`. That's it.
(Map-specific? It belongs in `scripts\zm\<mapname>\` — a map-specific reference in a
root script crashes every *other* map.)

**Credits:** sehteria (T6-ZM-Expanded), SadSlothXL (Death Machine), Jbleezy
(BO2-Reimagined, the reference for the survival locations), and the authors of the
bundled scripts.
