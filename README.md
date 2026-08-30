<div align="center">

# Quality Of Life

**A Black Ops II Zombies overhaul for [Plutonium T6](https://plutonium.pw).**

Every weapon and every perk on every map, three wonder weapons brought over from Black Ops 1,
and an in-game menu to switch any of it on or off.

<a href="https://github.com/DavidHiFi/zm_qol/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="42">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/zm_qol?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/zm_qol/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">

<br>

<sub>Still in development — the rough edges are listed under <a href="#known-issues">known issues</a>.</sub>

</div>

<!-- SCREENSHOT SPOT 1 - the hero shot goes here, right under the badges.
     One wide image works best. Drop the file in and uncomment:

     <div align="center">
     <img src="docs/screenshot-hero.png" width="900" alt="">
     </div>
-->

---

<div align="center">

## The Black Ops 1 wonder weapons

### Thundergun · Wunderwaffe DG-2 · Winter's Howl

Not lookalikes — the real weapons, brought across from Black Ops 1.<br>
They come out of the mystery box, one player can carry each, and all three Pack-a-Punch.

<sub>On TranZit, Nuketown, Die Rise and Mob of the Dead — Buried and Origins keep their own.</sub>

</div>

<!-- SCREENSHOT SPOT 2 - the wonder weapons. Three narrow shots side by side
     read really well here, one per gun. Same pattern as above.
-->

---

## What else it changes

|  |  |
|---|---|
| **Every gun, every map** | The full roster everywhere, plus Pack-a-Punch on the maps that never had it. |
| **All 12 perks** | On every map that can physically take them, with Wunderfizz everywhere. |
| **12 more guns in the box** | Multiplayer and campaign weapons with real models, animations and audio — SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6 and Tac-45. |
| **Diner as a Survival map** | The TranZit location Treyarch built and never shipped, with its own Pack-a-Punch, wall buys, buildable shield and secret song. |
| **The Death Machine** | A power-up drop, with the announcer lines to match. |
| **A menu for all of it** | Four tabs in Options, and near enough every change is a switch you can turn off. |

<details>
<summary><b>The full list</b></summary>

<br>

**Weapons** — no box limits, so duplicates are allowed and both Ray Guns can be in play at once.
The M16 is in the box on every map. The Pack-a-Punched crossbow, the Awful Lawton, pulls zombies
to wherever its bolts stick, the way it did in Black Ops 1. The Tac-45 goes dual-wield when
Pack-a-Punched.

**Perks** — a **PERK LIMIT** row in the lobby lets you hold everything the map offers, or cap it
anywhere from 1 to 12. Who's Who hands you a Pack-a-Punched ballistic knife so you can revive your
own body from range.

**Power-ups** — Blood Money on every map, Zombie Blood taken off Origins and given to the others,
an Instant Nuke that kills everything at once instead of staggering, and three announcer lines
Treyarch recorded and never used.

**Maps** — Nuketown's sunken perk-drop pad is fixed, and the lobby can airlift every machine in at
match start instead of making you wait until round 26. Die Rise gets the Sliquifier's pre-nerf
behaviour as a switch, and a Semtex wall buy. The scoreboard and loading screen name where you
actually are — "Survival - Diner", not "Survival - Green Run".

**HUD** — hitmarkers with a choice of eight sound sets, plus crit and squad-downed alerts. Round
summary, timers, health and bleedout bars, zombies remaining, zone names, compass, velocity meter,
perk pop-ups, power-up timers, and a Cold War round counter that can sit top-right or top-left.

**Menus** — instant match start with no lobby countdown, and the intro cutscenes play again.
**INSTANT EXIT** and **QUIT TO DESKTOP** on the pause menu. Night Mode, Fog and Higher Draw
Distance on the game's own ADVANCED tab, plus a **DISABLED** step for Depth Of Field that base
Black Ops II never gave you. In the lobby: pick your character, set minimum players, and choose
when Nuketown's machines arrive.

**Everything else** — instant Pack-a-Punch, BO4 Max Ammo, wall buys that refill your magazine, the
high-round fix, the galaxy animated Pack-a-Punch camo, +100 points for going prone at a perk
machine, full backwards and sideways movement speed, a network frame patch, and switches for the
round cap, the 24-zombie solo cap, instakill rounds, Double Tap 1.0, barrier attacks, bleedout,
round delay, walkers, Speed Cola and perma-perks. Your settings are remembered between sessions.

</details>

<details>
<summary><b>Chat commands</b></summary>

<br>

Every command works with `.`, `!` or `/`, and any of them can be bound to a key.
Type **`.help`** in game for the live list — it is always current, this is not.

```
.help                    show / hide the command list
.give <weapon> [pap]     any gun on the map      .give list    browse them
.round <n>  .endround    jump or end a round
.god  .ghost  .fly  .afk  .infammo  .infsprint   .reload
.pack  .unpack           Pack-a-Punch what you are holding
.giveperks  .removeperks  .give jug / speed / dtap / mule ...
.pay <player> <n>  .bring  .killall  .movespeed
.shield  .staff <element>  .machines  .powerup <name>
```

</details>

---

## Install

Install Plutonium and run it once so its folders exist, then close it.

1. [Download the latest release](https://github.com/DavidHiFi/zm_qol/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

Arrow keys to move, **Enter** to choose, **Q** to quit. No admin rights, nothing left running, and
no game file is ever touched — everything is written inside Plutonium's own folder.

On **Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer. Install it by hand —
it works the same as any other Plutonium mod.

<details>
<summary><b>What else the installer can do</b></summary>

<br>

Optional HD texture and custom sound packs, fetched on request — they are separate downloads on the
release page because of their size. Controller icons for PlayStation 5, Nintendo Switch or Xbox One.
ReShade, with a curated shader set and a *Cinematic Colour Grading* preset. A one-click **Play now
(LAN)** shortcut that boots straight into Zombies with the mod loaded. Backups of your own textures,
sounds and settings, restorable at any time. And an uninstaller that removes all of it or one piece
at a time, touching only what it put there.

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts.** It clears anything it does not recognise out
> of its own `bin` folder, ReShade included, so installing ReShade on its own will not survive your
> next launch.
>
> The fix ships with it: launch using **`Play BO2 with ReShade.bat`** instead of opening Plutonium
> directly, and leave its window open while you play. It puts ReShade back the moment Plutonium
> clears it. Closing that window uninstalls nothing — it just stops watching.

</details>

<details>
<summary><b>Install by hand</b></summary>

<br>

1. Download the release zip and open the **`Mod Files`** folder inside it.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\`
   *(on Linux, the same path inside your Plutonium prefix).*
3. Copy these five files into it: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`.
   Nothing else from that folder is needed.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

> Cloning this repo does **not** give you a playable mod — `mod.iwd` is a build output and is not
> tracked in git. Use the release.

</details>

---

## Known issues

The rough edges, kept in the open. None of this is buried in the release notes.

<details>
<summary><b>Open issues</b></summary>

<br>

| Issue | Detail |
|---|---|
| **Launch-day recoil is not applied** | The mod ships pre-nerf recoil for the guns Treyarch nerfed after release, but it never reaches the game — most of the files sit in a folder Plutonium does not read, and the two that are in the right place are past the size the loader accepts. The guns work fine; they just use their patched recoil. |
| **Some gun sounds come from the mod, not your sound pack** | 15 of them, the AK-47, M16, MP40, MP5K, MP7, Olympia, FAL OSW, SVU, Thompson and Type 95 among them. Their sounds are missing from at least one map's audio bank, so the mod has to supply them or the gun is silent there. Any one can be handed back, at the cost of that gun going silent on the maps that lack it. |
| **Who's Who clone glow only draws on TranZit and Die Rise** | Both use real, unmodified stock assets. The other four maps are each blocked for a measured reason — Nuketown's and Mob's character models have no glow-capable material anywhere in the game, Origins' has neither that nor a spare clientfield bit, and Buried's is full. Nothing fake is built to paper over it. |
| **Who's Who is stock on Origins and Mob of the Dead** | Neither map ships a single ballistic-knife asset, where every map that has the feature does. Porting the set across is possible but has not been attempted. |
| **Deadshot Daiquiri's head lock-on is unconfirmed on controller** | The fix has been checked line by line against the game's own handler and matches it. What is missing is a gamepad actually on it. |
| **The Diner claymore wall buy has no purchase prompt** | Its position is confirmed correct by an in-game measurement. The missing prompt is a separate, newer bug. |
| **Mob of the Dead's starting-weapon row is not shipped** | The snub-nose Python it needs exists in no game file. |
| **Winter's Howl does not freeze and shatter** | The animation data is not linked into the mod, so the gun kills without freezing anything. |

</details>

---

## Shout-outs

**Made by DavidHiFi & Synarxis.**

| Who | What |
|---|---|
| **sehteria** — *T6-ZM-Expanded* | The mod this one grew out of. Most of the original scripts came from here: BO4 Max Ammo, instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers, the area notifier, the Cold War round HUD and secret song survival. |
| **SadSlothXL** | The Death Machine power-up — the drop, the weapon swap and its sounds. |
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | Diner as a Survival location, and the extra gamemodes. Treyarch left the data in the game files and never shipped it; Reimagined is the implementation that works. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The Die Rise weapons work — the Sliquifier's pre-nerf behaviour and the Semtex wall buy, position and angles value for value. |
| **Fraaagaaa** — [Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the teleport list. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The reference for most of the patches — the network frame fix, the backspeed values, the 24-zombie solo cap, instakill rounds, Double Tap 1.0 and barrier attacks. Used as a reference and re-derived against the game's own scripts, never copied wholesale. |
| **MOTD Galaxy Camo Animated**<br><sub>community texture pack, no author named in the download</sub> | The three textures behind the animated Pack-a-Punch camo. |

> ### Did we miss you?
> Then it was an oversight, not a decision. Some of this project's early history predates its own
> records, so a couple of the credits above are names carried forward with no source anyone has been
> able to trace since. **If any of this builds on your work and you are not credited — or you are
> credited under the wrong name — open an issue or message me and it gets fixed.** No proof needed
> and no argument required.

<details>
<summary><b>Tools, reference material and bundled shaders</b></summary>

<br>

Built on [**Plutonium**](https://plutonium.pw). **OpenAssetTools** links the mod's fastfile and
reads the stock game's; **gsc-tool** by **xensik** parse-checks every script before a build. The
**T6-Data-Archive** clientfield dumps made this mod's bit budgets something to measure instead of
guess, and Treyarch's own script dumps are read constantly so the mod matches vanilla behaviour
rather than reinventing it.

The optional ReShade install ships work by **crosire** ([ReShade](https://reshade.me)),
**Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**,
**Lord of Lunacy**, **prod80**, and **NVIDIA** — whose NIS algorithm one of the shaders is built
on. All shipped as released, and all credit for them is theirs.

</details>

<details>
<summary><b>Building it yourself</b></summary>

<br>

```
scripts/zm/      all the gameplay — plain GSC, nothing to compile
ui/  ui_mp/      menu overrides
zone_source/     what gets linked into mod.ff
zone_assets/     the materials, images and camo definitions it links
installer/       the release package
```

Edit a `.gsc`, run **`build.bat`**, play — that is the whole loop. Only if you changed a `.csc` or
a real asset do you need **`build_ff.bat`** first, then `build.bat`.

</details>

---

## On the code

**Most of this mod was written by [Claude Code](https://claude.com/claude-code), Anthropic's AI
coding agent**, directed and tested by me across a long run of sessions.

Plenty of people want nothing to do with AI-written code, which is fair — so you should know before
you download rather than after. Everything here is play-tested in game before it is called
finished, and anything that has not been tested yet says so.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
