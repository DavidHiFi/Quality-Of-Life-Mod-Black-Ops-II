<div align="center">

# Quality Of Life

**A quality-of-life overhaul for Black Ops II Zombies on [Plutonium T6](https://plutonium.pw).**

Every weapon, every perk, on every map — plus the switches to turn it all off again.

<a href="https://github.com/DavidHiFi/zm_qol/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="42">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/zm_qol?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/zm_qol/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">

</div>

> [!NOTE]
> **Still in development.** It is very playable, but features change between releases and a few
> things are known broken. They are listed honestly under [Known issues](#known-issues).

---

## Install

Install Plutonium and run it once so its folders exist, then close it.

1. [Download the latest release](https://github.com/DavidHiFi/zm_qol/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

Arrow keys to move, **Enter** to choose, **Q** to quit. No admin rights, nothing left running, and
no game file is ever touched — everything is written inside Plutonium's own folder.

**On Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer. Install by hand — it
is the same as any other Plutonium mod.

<details>
<summary><b>Install by hand</b></summary>

<br>

1. Download the release zip and open the **`Mod Files`** folder inside it.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\`
   *(Linux: the same path inside your Plutonium prefix).*
3. Copy the five `mod.*` files into it — `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`
   and `mod.all.sabs`. Nothing else from that folder is needed.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

> Cloning this repo does **not** give you a playable mod — `mod.iwd` is a build output and is not
> tracked in git. Use the release.

</details>

### What the installer can do

| | |
|---|---|
| **The mod** | Install or update. Asks whether to keep your menu settings. |
| **EVERYTHING** | The mod, HD textures and custom sounds in one pass. Not ReShade — see the note below. |
| **HD texture pack** | Optional, separate download. Fetched on request. |
| **Custom sound pack** | Optional, separate download. Fetched on request. |
| **Controller icons** | PlayStation 5, Nintendo Switch or Xbox One prompts. |
| **ReShade** | Optional, on its own row. Ships a curated shader set and a *Cinematic Colour Grading* preset. In game: **End** opens the menu, **Numpad 0** toggles effects, **Ctrl+Shift+PgUp/PgDn** changes preset. |
| **Play now (LAN)** | Straight into Zombies with the mod already loaded. |
| **Backups** | Back up and restore your own textures, sounds, ReShade setup or mod folder. Kept as plain folders in `storage\t6\backups\`. |
| **Uninstall** | All of it, or one piece at a time. Only removes what the installer put there. |

The texture and sound packs are separate downloads on the release page because of their size.

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts** — it clears anything it does not recognise out
> of its own `bin` folder, ReShade's `dxgi.dll` included. So installing ReShade on its own does not
> survive your next launch, and that is why it is not part of EVERYTHING.
>
> The fix ships with it: launch with **`Play BO2 with ReShade.bat`** instead of opening Plutonium
> directly, and leave its window open while you play. It puts ReShade back the moment Plutonium
> clears it. Closing that window uninstalls nothing; it just stops watching.

---

## What you get

### Weapons

- **Every weapon on every map**, plus Pack-a-Punch on the maps that were missing it.
- **12 multiplayer and campaign guns in the mystery box**, each with its upgrade — SWAT-556,
  FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6 and
  Tac-45, with real models, animations, camos and stock audio. The Tac-45 goes **dual-wield when
  Pack-a-Punched**.
- **Three Black Ops 1 wonder weapons** — Thundergun, Wunderwaffe DG-2 and Winter's Howl, each
  upgradeable and each able to handle the special enemies.
- **The M16 is in the box** on every map, with its Skullcrusher upgrade.
- **No box limits** — duplicates allowed, both Ray Guns in play at once.
- **The Awful Lawton** pulls zombies to where its bolts stick, like BO1.

### Perks

- **All 12 perks on every map** that can physically take them.
- **Wunderfizz on every map.**
- **PERK LIMIT** in the lobby — hold every perk the map offers, or cap it anywhere from 1 to 12.
- **Who's Who hands you a Pack-a-Punched ballistic knife**, so you can revive your own body from
  range.

### Power-ups

**Death Machine** · **Blood Money** on every map · **Zombie Blood** ported off Origins ·
**Instant Nuke**, with no staggered kills · three announcer lines Treyarch recorded and never used.

### Maps

- **Diner as a Survival location** on TranZit, with its own Pack-a-Punch, wall buys, Semtex wall
  buy, buildable shield, teddy bears and secret song.
- **Nuketown** — the sunken perk-drop pad is fixed, and the lobby can airlift every machine in at
  match start instead of making you wait until round 26.
- **Die Rise** — the **Sliquifier pre-nerf** as a switch, and a **Semtex wall buy**.
- **The scoreboard and loading screen name where you actually are** — "Survival - Diner", not
  "Survival - Green Run".

### HUD and menus

- **Hitmarkers**, with a choice of eight sound sets — Cold War, MW 2019, BO4, Overwatch, Apex,
  8-bit, MW Classic and BO7 — plus crit and squad-downed alerts.
- Round summary, timers, health bar, bleedout bar, zombies remaining, zone names, compass, velocity
  meter, perk pop-ups, power-up timers, and a Cold War round counter that can sit top-right or
  **top-left like BO4**.
- **INSTANT EXIT** and **QUIT TO DESKTOP** on the pause menu.
- **Night Mode**, **Fog** and **Higher Draw Distance** on the game's own ADVANCED tab, plus a
  **DISABLED** step for Depth Of Field that base BO2 never gave you.
- **Instant match start** — no lobby countdown, and the classic intro cutscenes play again.

### In the lobby

**SOLO PLAY** as the header instead of CUSTOM GAMES, plus rows to pick your **character**, set
**MIN PLAYERS**, and choose when Nuketown's **machine drops** arrive.

### Everything else

Instant Pack-a-Punch · BO4 Max Ammo · wall buys refill your magazine · high-round fix · galaxy
animated Pack-a-Punch camo · prone at a perk machine for +100 points · full backwards and sideways
movement speed · network frame patch · remove round cap · 24-zombie solo cap · instakill rounds ·
Double Tap 1.0 · no barrier attacks · no bleedout · round delay off · no walkers · better Speed
Cola · perma-perks · and your settings are remembered between sessions.

### The menu

Almost all of it is a switch in **Options → Settings**. The mod adds four tabs — **GAME**,
**PATCHES**, **HUD** and **CHEATS** — and adds rows to the stock **GRAPHICS**, **ADVANCED** and
**SOUND** tabs, plus an **AIM ASSIST** row under **Controls → Gamepad**. Nothing needs a chat
command.

### Commands

Every command works in chat with `.`, `!` or `/`, and any of them can be bound to a key.
Type **`.help`** in game for the live list.

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

---

## Known issues

Kept here on purpose — none of this is hidden in the release notes.

| Issue | Detail |
|---|---|
| **Launch-day recoil is not applied** | The mod ships pre-nerf recoil for the guns Treyarch nerfed after release, but it does not currently reach the game: the DSR 50 and Five-Seven files are past the size the loader accepts, and the rest sit in a folder Plutonium does not read. The guns themselves are unaffected — they just use their patched recoil. |
| **Some gun sounds come from the mod, not your sound pack** | 15 of them, including the AK-47, M16, MP40, MP5K, MP7, Olympia, FAL OSW, SVU, Thompson and Type 95. Their sounds are missing from at least one map's audio bank, so the mod has to supply them or the gun is silent there — and the tool that builds the mod cannot name a sound without also embedding it. Any one can be handed back, at the cost of that gun going silent on the maps that lack it. |
| **Who's Who clone glow only draws on TranZit and Die Rise** | Both use real, unmodified stock assets. The other four maps are each blocked for a measured reason — Nuketown's and Mob's character models have no glow-capable material anywhere in the game, Origins' has neither that nor a spare clientfield bit, and Buried's is full. No lookalike is built to paper over it. |
| **Who's Who is stock on Origins and Mob of the Dead** | Neither map ships a single ballistic-knife asset, where every map that has the feature does. Porting the asset set across is possible but has never been attempted. |
| **Deadshot Daiquiri's head lock-on is unconfirmed on controller** | The fix has been re-checked line-for-line against stock's own client handler and matches it. What is missing is a gamepad actually on it. |
| **The Diner claymore wall buy has no purchase prompt** | Its position is confirmed correct by an in-game measurement. The missing prompt is a separate, newer bug. |
| **Mob of the Dead's starting-weapon row is not shipped** | The snub-nose Python it needs exists in no game file. |
| **Winter's Howl does not freeze-and-shatter** | The animation data is not linked into the mod, so the gun kills without freezing anything. |

---

## Building it yourself

```
scripts/zm/      all the gameplay — plain GSC, nothing to compile
ui/  ui_mp/      LUI menu overrides
zone_source/     what gets linked into mod.ff
zone_assets/     the materials, images and camo definitions it links
installer/       the release package
```

1. Edit a `.gsc`, run **`build.bat`**, play. That is the whole loop.
2. Only if you changed a `.csc` or a real asset: run **`build_ff.bat`** first, then `build.bat`.

---

## Credits

**Made by DavidHiFi & Synarxis.**

Everything below is a source this mod actually uses. If something of yours belongs here and is
missing, open an issue and it gets added.

### What this mod grew out of

| Who | What |
|---|---|
| **sehteria** — *T6-ZM-Expanded* | The mod this one started from. Most of the original scripts came from here: BO4 Max Ammo, Instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers, the area notifier, the Cold War round HUD, secret song survival. |
| **SadSlothXL** | The **Death Machine** power-up — the drop, the weapon swap and its sounds. |

Both names are carried forward from this project's first credits list, from before any of it was
git-tracked, and neither has since been traceable to a source. That is a gap in our records, not a
doubt about the credit — if either is you, or you know the real source, please open an issue.

### Ported or adapted from other mods

| Who | What |
|---|---|
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The **custom Survival locations** and the extra **gamemodes**. Treyarch left the data in the game files and never shipped it; Reimagined is the implementation that works, and Diner is a port of its work. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The **Die Rise weapons block** — the Sliquifier pre-nerf behaviour and the **Semtex wall buy**, position and angles value for value. |
| **Fraaagaaa** — [Strat Tester for Black Ops II](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the **TELEPORT** row. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The reference for most of the **PATCHES** tab — the network frame patch, the backspeed values, the 24-zombie solo cap, instakill rounds, Double Tap 1.0 and no barrier attacks. Used as a reference and re-derived against the shipped game scripts, never copied wholesale. |
| **MOTD Galaxy Camo Animated** <sub>(community texture pack, no author named in the download)</sub> | The three textures behind the **animated Pack-a-Punch camo**. |

### Reference data and tools

| What | Used for |
|---|---|
| **T6-Data-Archive** | Per-map clientfield dumps, which made this mod's bit budgets something to measure instead of guess. |
| **The stock GSC dumps and BO2 raw files** | Treyarch's own scripts, read constantly so this mod matches vanilla behaviour instead of reinventing it. |
| [**Plutonium**](https://plutonium.pw) | The platform the whole mod runs on. |
| **OpenAssetTools** | Linking `mod.ff`, and reading the stock game's fastfiles. |
| **gsc-tool** by **xensik** | Parse-checking every script before a build. |

### Bundled with the optional ReShade install

Shipped as released. All credit for them is theirs.

**crosire** ([ReShade](https://reshade.me)) · **Barbatos Bachiko** (BarbatosShaders) ·
**Alex Tuduran** (FGFX) · **Marot Satil**, the **GShade** project and **Ioxa** (GShadeShaders) ·
**Lord of Lunacy** (InsaneShaders) · **prod80** (PD80 shaders and LUTs) · **NVIDIA** (the NIS
sharpening algorithm).

### The game itself

Every model, texture, sound, animation and script this mod builds on belongs to **Treyarch** and
**Activision**. A legitimate copy of Black Ops II is required to run any of it.

---

## On the code

**Most of this mod was written by [Claude Code](https://claude.com/claude-code), Anthropic's AI
coding agent**, directed and tested by me across a long run of sessions.

Plenty of people want nothing to do with AI-written code, which is a fair position — so you should
know before you download rather than after. Everything here is play-tested in game before it is
called finished, and anything that has not been tested yet says so.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
