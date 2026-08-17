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
  own, taken from the game's own banks — including the Titus-6's reload and first-raise cues, which
  the port was missing until v1.99.50 and which come field-for-field from the campaign's own rows.
  The Tac-45 becomes **dual-wield when Pack-a-Punched** ("Toughguy & Crybaby"), the same way
  stock's Mustang & Sally does, and ships its full multiplayer sound set — fire, dry-fire,
  distance, decay, LFE and the five reload foley cues.
- **Three Black Ops 1 wonder weapons**: Thundergun, Wunderwaffe DG-2, Winter's Howl, each with
  its upgrade. They handle the special enemies properly — Brutus dies in two hits from any of
  them, helmet off on the first.

**Perks**
- All twelve perks on every map that can physically take them. **PERK LIMIT** in the pre-game
  lobby picks how many you may hold at once — `MAP MAX` (the default, every perk the map offers)
  or any number from 1 to 12, so you can play stock four-perk rules if you want to.
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
- **GAME / HUD / CHEATS tabs** in the pause menu: Options → Settings. 29 toggles, so you never
  have to type a chat command.
- **Sound packs on the SOUND tab** (main menu *and* pause menu): pick the hitmarker **hit** and **kill** sound from
  eight — Cold War, MW 2019, Black Ops 4, Overwatch, Apex, 8-bit, MW Classic, Black Ops 7 — plus a
  **crit** sound on headshot and melee kills and a **downed** alert the whole squad hears. All four
  default to the mod's original sound, and all four switch live.
- Hitmarkers, on-screen counters, round summary, game and round timers, health bar, bleedout bar,
  zombies remaining, zone names, **compass**, velocity meter, Cold-War round HUD, perk pop-ups.
- **Power-up timers** — seconds remaining above each power-up icon, the mod's own **Death Machine**
  power-up included. Confirmed working in game.
- **Instant match start** — no lobby countdown.
- Solo Play is titled Solo Play, and the Classic intro cutscenes play again.

**Quality of life**
- Instant Pack-a-Punch (switch it off on the GAME tab, mid-match, and the stock machine comes
  back — gun in, wait, gun out), BO4 Max Ammo (also a GAME-tab switch — off is exact vanilla,
  reload before you grab the drop), wall buys refill your
  magazine, high-round fix, animated camos, prone at a perk machine for +100 points.
- **Who's Who hands you a Pack-a-Punched ballistic knife** instead of the starting pistol, so you
  can revive your own downed body from range — stock already wires the upgraded ballistic knife to
  revive a player clone, the perk just never gave you one. GAME-tab switch, live while you are down.
  **Not on Origins:** every one of the 43 assets that weapon needs is absent from every fastfile
  Origins loads, so the perk stays stock there.
  **Confirmed in game — the gun in v1.99.39, the revive in v1.99.44.** The revive took two goes: off
  Die Rise the corpse is a `script_model`, not an actor, so stock's own damage callback never runs —
  and a character model carries no collision, so the bolt passes through the body without damaging
  it either. v1.99.44 watches the bolt instead, through the same `ballistic_knife_stationary` notify
  that puts the pick-it-back-up prompt in the world.
- **Instant Nuke** (GAME-tab switch, on by default) — the Nuke kills every zombie it would have
  killed at the same instant, instead of staggering them 0.1–0.7 s apart while a survivor swings at
  you. Same zombies, same 400 points; off is exact vanilla.
  **New in v1.99.48 — confirmed in game.**
- **Full move speed** (GAME-tab switch, on by default) — you move backwards and sideways at full
  speed instead of BO2's 0.7× back / 0.8× strafe / 0.667× sprint-strafe. The mod has always forced
  this; v1.99.51 makes it a switch you can throw mid-match, and off restores the exact stock values.
  **New in v1.99.51 — deployed, not yet confirmed in game.**
- **The Awful Lawton** (Pack-a-Punched crossbow) — its explosive bolts draw zombies to where they
  stick, like a monkey bomb, as in BO1. Upgraded only; the box crossbow is unchanged.
  **New in v1.99.39 — confirmed in game.**
- **Your settings are remembered.** Everything in the mod's own options tabs is now saved with the
  rest of your game settings and survives a restart; before v1.99.45 only the handful of rows that
  happened to share a name with an existing dvar came back. The CHEATS tab is deliberately not
  saved — god mode and fly are per-match states, not preferences.

**Commands** — chat command and bindable console command for each:
- `.round 30` jump to a round · `.give <weapon>` (add `pap` for upgraded, `.give list` for names)
- `.velocity`, `.fly`, `.god`, `.ghost`, `.hud`
- `.brutus <n>` / `.panzer <n>` / `.jumpingjacks <n>` spawn that map's real boss
- `.pay <player> <n>` send points (it costs you) · `.bring` pull everyone to you · `.killall`
- `.shield` the map's own buildable shield · `.staff <fire/ice/lightning/wind>` on Origins
- `.movespeed` 1.5× movement

Every command works with `.`, `!` or `/`. `.help` prints the full, self-updating list in game.

## Known issues

| issue | detail |
|---|---|
| Origins and Mob can crash | `EXE_ERR_RELIABLE_CYCLED_OUT`, roughly 20–35 s into a match. **Open, and not currently being worked on** — the cause was never found. An Origins session on v1.99.22 ran without it, which is one clean run and not a fix. |
| Winter's Howl firing effects | 🌟 v1.99.14 — the real cause, after four rounds of looking at muzzle flashes. The gun is `weaponType projectile` with `projectileSpeed 2000` and had **no `projTrailEffect` at all**, so it fired an invisible projectile. The Wunderwaffe, which works, has one. The mod has shipped `fx_trail_freezegun_geotail` (a proper emission trail that spawns `fx_trail_freezegun_ring_emit` along the path) since the port landed — declared, loading, referenced by nothing. Both defs now point at it, and the one trail material absent from TranZit now ships. **Deployed, not yet confirmed in game.** |
| ~~Kill-feed icons missing~~ | 🌟 FIXED in v1.99.14 (deployed, not yet confirmed). Cause found by the new weapon-asset audit: the `menu_mp_weapons_*` material each ported gun names ships only in `code_post_gfx_mp.ff` and `frontend.ff`, neither of which a zombies map loads, so the icon resolved to nothing. Nine of them now ship in `mod.ff`. |
| ~~Titus-6 reloads silently~~ | 🌟 **FIXED in v1.99.50 and confirmed in game.** The sounds live in the animation notetracks, not the weapon file: all 45 Titus animations were dumped and scanned, and nine of the aliases they call existed in no bank the game loads. Five were defined from the campaign's own rows in `spl_monsoon.all` (`fly_titus_bolt_back`, `_bolt_release`, `_mag_in`, `_mag_out`, `_tap`), against payloads the mod's bank already carried. The same fix restored the **first-raise** sound — the cue that plays when the gun leaves the box calls two of the missing nine. 📝 Two remain undefined on purpose: `fly_titus_futz` and `fly_tar21_futz` exist in **no bank in the game**, the campaign's own Titus set included, so they are silent in stock too; the dart still has no in-flight loop for the same reason. |
| Who's Who fx | 🌟 **Finished at v1.99.20 and confirmed in game.** Listed here only for its accepted limits: the clone glow is **TranZit-only**, the TranZit clone wears the Die Rise outfit, and Buried and Mob do not get the perk. Full audit of every effect stock gives the perk: **ghost-state colour grade** — Die Rise's own `vision/zm_whos_who.vision`, shipped in `mod.ff` and applied client-side with `visionsetnaked()` (stock's own call, save/restore pattern from `_proximity_grenade.csc`), because the visionset *manager* can drop a slot between server and client with no load error — `visionset_slot` is `getminbitcountfornum(count-1)` bits, so 3 and 4 registrations are both 2 bits and the mismatch check never fires. Night mode's three renderer overrides (`r_filmUseTweaks`, `r_exposureTweak`, `r_bloomTweaks`) are suspended for the duration and restored after, since `r_filmUseTweaks 1` makes the renderer ignore **every** visionset however it was applied; **audio** — sting, looper and mixer snapshot (confirmed working); **clone glow** — the corpse is only an *actor* on maps shipping a `fake_player_spawner` entity (`mapents` dump: Die Rise 1, TranZit 0, Origins 0), so the stock `actor` clientfield reached nothing; a `scriptmover` twin carries it, using stock's own callback, on **TranZit only** — the glow needs the `_g` glow-capable materials, which exist for the Victis crew and nobody else, and Origins has no free `scriptmover` bit (32/32) for the field regardless; **screen filter** — `generic_filter_afterlife` and its assets ship since v1.99.13. Two things stock does *not* do and this mod therefore does not fake: the shellshock (gated on `level.chugabud_shellshock`, which stock sets nowhere) and a red last-stand screen (with Who's Who the player never enters last stand at all — `_zm.gsc:4239` returns before `player_laststand()`). |
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
