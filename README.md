# Quality Of Life

> ## ⚠️ WORK IN PROGRESS
>
> **This mod is unfinished and under active development.** Features land, change and get
> reverted between releases; some are deployed but not yet verified in game. Expect bugs,
> and expect things to move. It is playable, not final.
>
> ### Vulture Aid is not on every map
>
> **Vulture Aid is absent on Origins and on TranZit**, and that is deliberate. Both maps
> run out of per-player network field space, which is fatal at load rather than cosmetic —
> TranZit Classic used to refuse to start entirely with
> `Trying to assign 1 bits for netfield vulture_perk_toplayer but Client Field Set toplayer
> is out of space`. The perk cannot be shipped complete on either map, so it is not shipped
> there at all rather than shipped broken. **Both maps keep the other eleven perks**, and
> Vulture Aid is unchanged on Nuketown, Die Rise and Mob of the Dead (Buried has it natively).

A Plutonium T6 (Black Ops II) Zombies mod: **all weapons on every map, and all twelve perks
on every map that can physically take them** (see the note above),
the **BO2 Death Machine** power-up, **Diner as a Survival location**, and a stack of
QoL tweaks. All gameplay is plain GSC you can edit — no compiling, no linker.

> **Textures:** this mod no longer ships an upscaled texture pack. It was removed in
> v1.57.7 because loose `.iwi` files in `mod.iwd` did not reliably override the stock
> art, and it cost 2 GB for no visible result. Load a texture pack from
> `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead — that path works.
>
> **v1.93.0:** two perk icons the mod still shipped, `specialty_vulture_zombies.iwi` and
> `specialty_tombstone_zombies.iwi`, were beating a custom pack because `mod.iwd\images\`
> wins over `storage\t6\images\`. Both are gone, so those two now come from your pack.
> 🛑 **Consequence, stated plainly:** without a pack, the Vulture Aid icon now falls back to
> the game's own copy — which only Buried owns, so it may not draw on other maps. The
> Tombstone icon is safe either way (its pixels are in the game's base pak).
> `specialty_vulture_zombies_glow.iwi` is deliberately still shipped, because no known pack
> replaces it.

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
- **Eleven multiplayer and campaign weapons added to the mystery box on every map** — the
  **SWAT-556**, **FAL OSW**, **Mk 48**, **QBB LSW**, **MP7**, **Vector K10**, **MSMC**,
  **Peacekeeper**, **Crossbow**, **XPR-50** and **Titus-6**, each with its Pack-a-Punch upgrade
  (FBI-667, WN OTW, HtMk 4800, RCC MTX, Matter Penetrator 700, Matrix K1000, Modern Sub Machine
  Catastrophe, Warmonger, Awful Lawton, Xtreme Pain Releaser 5000, Augustus-9). Nothing is a
  stand-in: their models, animations and camos are the
  real assets baked into `mod.ff`, and their fire audio — including the `_decay`, `_dist` and
  `_LFE` layers and the Pack-a-Punch shot — ships in the mod's own sound bank. The SWAT-556's
  grenade launcher and the FAL OSW's select-fire work on the Pack-a-Punched versions.
  `zmqol_mp_weapons 0` turns them all off.
  **Reload sounds work on all eleven as of v1.93.0.** The SWAT-556 and the Peacekeeper were the
  only two shipping with no foley aliases at all — six each, which is why the SWAT reloaded in
  silence; the other nine already matched their source one for one. Not yet confirmed in game.
  ⚠️ **One gap still open:** their **kill-feed icons are missing**, so a kill with one shows a
  blank icon in the feed. Cosmetic; it does not affect handling.
  📝 **The XPR-50** is stored under its development name `as50`, which is why it was twice
  reported as absent from the game — the defs are `as50_*` and the art is `xpr50_*`.
  📝 **The Titus-6 is new in v1.93.0 and not yet confirmed in game.** It is dual-mode: the
  explosive-dart launcher with a buckshot masterkey on alt-fire, both halves and both dart
  projectiles included. Its Pack-a-Punch camo is compiled from source rather than copied (the
  game ships no `camo_titus6` asset), and all three of its effects — muzzle bolt, dart trail and
  dart explosion — are baked into `mod.ff` from the campaign fastfile that owns them.
  🛑 **Known gap on it:** `wpn_titus_proj_loop`, the dart's in-flight loop, exists in no bank in
  this install, so a fired dart travels silently. Everything else it asks for is present.
  🛑 **One weapon is still left out:** the **Bouncing Betty** — its viewmodel anims and HUD icon
  are absent everywhere in the workspace, so it would be a visibly broken weapon.
- **Three Black Ops 1 wonder weapons in the mystery box** — the **Thundergun**,
  **Wunderwaffe DG-2** and **Winter's Howl**, each with its Pack-a-Punch upgrade
  (Zeus Cannon / DG-3 JZ / Winter's Fury). They fire, chain, freeze and knock back
  properly, and handle the special enemies (Brutus, the Avogadro, screechers,
  leapers, mechz, dogs).
  **Brutus takes exactly two hits from any of the three as of v1.93.0** — the first knocks his
  helmet off (and he pulls his tear gas, because it calls Mob of the Dead's own
  `brutus_remove_helmet`), the second kills him through the normal damage path so his powerup
  drops. Before this he was effectively immune: all three damaged him through `DoDamage`, which
  carries no hit location, so his own damage override scaled every hit to 10% and could never
  pop the helmet. Not yet confirmed in game. Console commands give one directly:
  `give_thundergun 1`, `give_wunderwaffe 1`, `give_wintershowl 1` — or in chat,
  `.thundergun`, `.wunderwaffe`, `.wintershowl`. `zmqol_ww 0` turns all three off.
  🛑 **Known gaps, honestly:** the Wunderwaffe's view-model lights are still too
  bright. **The Winter's Howl's missing effects are fixed in v1.91.0 but not yet
  confirmed in game** — the effects themselves always shipped (as raw `.efx` in
  `mod.iwd`), but **19 of the materials they draw with were not reachable on any
  map**, so half the muzzle flash and most of the freeze visuals rendered
  nothing. Measured against a full index of all 191 retail fastfiles; v1.91.0
  adds those 19 materials and 12 textures to `mod.ff`. Pack-a-Punch camos are **fixed in v1.76.0 but not yet confirmed in game**:
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
- **Give yourself any added weapon** — `.give <weapon>`, or `.give <weapon> pap` for the
  Pack-a-Punched one; `.give list` prints every name it takes. Covers all eleven ported guns
  and the three wonder weapons. Console twin, bindable and self-clearing so a bind fires every
  time: `give_weapon "titus"` / `give_weapon "titus pap"`. It routes through the same
  `weapon_give()` the mystery box uses, so it respects your weapon limit and behaves exactly
  like pulling the gun out of the box — which is the point, if you are testing one.
- **A "QUALITY OF LIFE" tab in Settings** — pause, **Options → Settings**, and it is the last tab
  after Voice Chat. **22 toggles**, so you never have to type a chat command: god mode, ghost,
  infinite ammo, infinite sprint, fly, rapid fire, no-power, night mode, fog, depth of field,
  model-detail fix, the whole HUD and each HUD element individually, and the velocity meter —
  plus the standard Plutonium options (allow downloading, draw identifier, flash script hashes,
  hold to sprint). Everything still has its chat command and its dvar; this is a third front-end,
  not a replacement. **New in v1.94.0 and not yet confirmed in game.**
  📝 Two requested entries are **not** there, deliberately: **"reduce engine sleeps"**, because no
  dvar of that name exists in this build and inventing one would be a guess, and **perma-perks**,
  because this mod has no perma-perk system to toggle.
  📝 There was never a GAME tab for the mod to hide: Plutonium's own `optionssettings.lua` builds
  exactly four tabs unconditionally, and this mod owns no options LUI. This **adds** a tab.
- **Velocity meter** — `.velocity on` / `.velocity off` (also `.vel`, `.speed`), or the
  `velocity` dvar so you can bind it. Horizontal speed in units/sec, colour-banded:
  green, yellow from 330, red from 370.
- **Boss spawn commands** — `.brutus (amount)` on Mob of the Dead, `.panzer (amount)` on
  Origins, `.jumpingjacks (amount)` on Die Rise. Each goes through that map's own stock
  spawner, so you get the real boss with its own fx, audio and behaviour. Console twins:
  `spawn_brutus <n>`, `spawn_panzer <n>`, `spawn_jumpingjacks <n>`.
- Hitmarkers, on-screen counters, high-round fix, Cold-War round HUD, no perk limit,
  animated camos, area names (TranZit), perk pop-up HUD.

## Add your own script

Drop a `.gsc` in `scripts\zm\`, give it an `init()`, run `build.bat`. That's it.
(Map-specific? It belongs in `scripts\zm\<mapname>\` — a map-specific reference in a
root script crashes every *other* map.)

**Credits:** sehteria (T6-ZM-Expanded), SadSlothXL (Death Machine), Jbleezy
(BO2-Reimagined, the reference for the survival locations), and the authors of the
bundled scripts.
