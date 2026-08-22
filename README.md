<div align="center">

<h1>🧟 Quality Of Life</h1>

<h3>Every weapon. Every perk. Every map.</h3>

A quality-of-life overhaul for **Black Ops II Zombies** on **Plutonium T6**.

<br>

<a href="https://github.com/DavidHiFi/zm_qol/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="46">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/zm_qol?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/zm_qol/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows%20%7C%20Linux-5865F2?style=flat-square&labelColor=161B22">
<img src="https://img.shields.io/badge/install-one%20click-5865F2?style=flat-square&labelColor=161B22">

</div>

<br>

> [!WARNING]
> ### 🚧 This mod is not finished
> Features land, change and get pulled between releases. Some are shipped but not yet play-tested, and a few are **known broken** — they are listed honestly in [Known issues](#-known-issues).
>
> It is very playable. It is **not** a clean, finished product. Expect rough edges.

<br>

## 📥 Install

> **Before you start:** install Plutonium and run it once so its folders exist, then **close it** while you install.

<br>

### 🪟 Windows

<table>
<tr><td width="60" align="center"><h3>1️⃣</h3></td><td><b><a href="https://github.com/DavidHiFi/zm_qol/releases/latest">Download the latest release</a></b> and unzip it anywhere.</td></tr>
<tr><td align="center"><h3>2️⃣</h3></td><td>Double-click <b><code>Windows Install.bat</code></b>.</td></tr>
<tr><td align="center"><h3>3️⃣</h3></td><td>Choose <b>INSTALL</b> → <b>the mod</b> → confirm. Done.</td></tr>
<tr><td align="center"><h3>🎮</h3></td><td>Launch Plutonium T6 → <b>Zombies → Mods → <code>Quality Of Life</code></b>.</td></tr>
</table>

Move with the **arrow keys**, choose with **ENTER**, quit with **Q**.

**No admin rights. Nothing left running. No game file is ever touched** — everything is written inside Plutonium's own folder.

<br>

### 🐧 Linux · Wine · Proton · Lutris · Bottles

Same download. Open the **`Linux Install`** folder and run:

```bash
bash "install-quality-of-life.sh"
```

It finds your Wine prefix on its own, and does everything the Windows version does. Its own `README.txt` covers the one extra step ReShade needs there.

<br>

### 🎛️ What the installer can do

| | |
|---|---|
| 📦 **EVERYTHING** | One row that installs the mod, the HD textures, the sounds and ReShade in one pass — with the same backup offer, asked once. |
| 🧟 **The mod** | Install or update it. Asks whether to **keep your menu settings** or start fresh. |
| 🔎 **Update check** | Pulls the newest release from GitHub. Won't put an older release over a newer build without asking twice. |
| 🖼️ **HD texture pack** | Optional. Backs up your current textures first if you want. |
| 🔊 **Custom sound pack** | Optional. Same backup offer. |
| 🌈 **ReShade** | Optional. Ships **ReShade 6.7.3** and the **full shader collection** (856 files), with four presets — one named for each Plutonium game, all four currently carrying the same BO2 look — and the mod's overlay theme ready to go. **End** opens it in game; **Ctrl+Shift+PgUp / PgDn** steps between presets. |
| 🎮 **Controller icons** | Optional, and you pick one: **PlayStation 5**, **Nintendo Switch** or **Xbox One**. The HD texture pack no longer ships any controller art, so the base install leaves the game's own prompts alone and your pick is the only thing that changes them. Same backup offer; picking a different pack swaps it over cleanly. |
| 💾 **Backups** | Back up your **own** textures, sounds, ReShade setup or mod folder — each on its own — and put them back any time. Kept as plain folders in `storage\t6\backups\`. |
| 🧹 **Remove any of it** | **EVERYTHING** in one row, or one piece at a time. The mod folder really goes, so it stops showing in the Mods menu. Your game logs are moved to the backups, never deleted. Only deletes what the installer put there, and offers your backup back. |

The texture and sound packs are separate downloads on the [release page](https://github.com/DavidHiFi/zm_qol/releases/latest) because of their size — the installer fetches whichever you say yes to.

<details>
<summary><b>Rather install it by hand?</b></summary>

<br>

1. Download the latest release zip and open the **`Mod Files`** folder inside it.
2. Copy the **`zm_qol`** folder into `%LOCALAPPDATA%\Plutonium\storage\t6\mods\`
   *(Linux: the same path inside your Plutonium prefix.)*
3. Launch Plutonium T6 → **Zombies → Mods → `Quality Of Life`**.

All five mod files go in that one folder.

> ⚠️ Cloning this repo does **not** give you a playable mod — `mod.iwd` is a build output and is not tracked in git. Use the release.

</details>

<br>

---

## ✨ What you get

Nearly all of it is a **switch** in the in-game menu — **Options → Settings**, tabs **GAME / PATCHES / HUD / CHEATS**. 49 rows — 48 on Nuketown, where the CHEATS tab has no TELEPORT row because the map has no landmark list — plus four graphics rows on the stock **ADVANCED** tab and an **AIM ASSIST** row on **CONTROLS → GAMEPAD**. No chat commands required.

> [!NOTE]
> **Confirmed working:** **UNLOCK ALL** and **RESET STATS** in the Zombies main menu under THEATER.
>
> **New in 2.2.0 and not play-tested yet:** **BETTER SPEED COLA** (GAME), **NO BLEEDOUT PATCH** (PATCHES), **CHANGE ROUND** up to 10000 when the round cap is off (CHEATS), and hellhound effects and sounds on Nuketown. Deadshot's controller head lock-on is back to stock behaviour.
>
> **Shipped in 2.0.0 but not play-tested yet:** the Die Rise Sliquifier row and the Semtex wall buy, the five new PATCHES rows, SET POINTS / TELEPORT, the DSR 50 and Five-Seven recoil, and the Winter's Howl firing effects. They are in the build; they have not had a boot yet.

<br>

### 🔫 Weapons

- **Every weapon on every map**, plus Pack-a-Punch on the maps that were missing it.
- **12 multiplayer and campaign guns in the mystery box**, each with its upgrade — SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6, Tac-45. Real models, animations, camos and stock audio. The Tac-45 goes **dual-wield when Pack-a-Punched**.
- **The M16 spins in the box** now, on every map — with its Skullcrusher upgrade.
- **3 Black Ops 1 wonder weapons** — Thundergun, Wunderwaffe DG-2, Winter's Howl, each upgradeable, each able to handle the special enemies.
- **No box limits** — duplicates allowed, both Ray Guns in play at once.
- **The Awful Lawton** pulls zombies to where its bolts stick, like BO1.
- **Launch-day recoil** on the 8 guns Treyarch nerfed after release.

### 🥤 Perks

- **All 12 perks on every map** that can physically take them.
- **PERK LIMIT** in the lobby — hold every perk the map offers, or cap it anywhere from 1 to 12 for stock rules.
- **Wunderfizz on every map.**
- **Who's Who hands you a Pack-a-Punched ballistic knife**, so you can revive your own body from range.

### 💥 Power-ups

**Death Machine** drop · **Blood Money** on every map · **Zombie Blood** on four more maps · 3 announcer lines Treyarch recorded and never used · **Instant Nuke** (no more staggered kills).

### 🗺️ Maps

- **Diner as a Survival location** on TranZit — its own Pack-a-Punch, wall buys, Semtex, buildable shield, teddy bears and secret song.
- **Nuketown:** the sunken perk-drop pad is fixed, and **`MACHINE DROPS → ALL ON ROUND 1`** airlifts every machine in at match start instead of making you wait until round 26.
- **Die Rise:** the **Sliquifier pre-nerf** (a PATCHES switch) and the **Semtex wall buy**, which is always on.
- **Scoreboard emblem** finally matches the team you are actually playing as, and the scoreboard now names the **start location** you are actually in — "Survival - Diner" instead of "Survival - Green Run".

### 🖥️ HUD & menus

- **Hitmarkers** with 8 selectable sound packs (Cold War, MW 2019, BO4, Overwatch, Apex, 8-bit, MW Classic, BO7) plus crit and squad-downed alerts.
- Round summary, timers, health bar, bleedout bar, zombies remaining, zone names, **compass**, velocity meter, Cold-War round HUD (top right, or **top left like BO4** with one switch), perk pop-ups, **power-up timers**.
- **RESTART GAME**, **INSTANT EXIT** and **QUIT TO DESKTOP** on the pause menu.
- **Night Mode**, **Fog** and **Higher Draw Distance** on the game's own ADVANCED tab — plus a **DISABLED** step for Depth Of Field that base BO2 never gave you.
- **Hellhounds on Nuketown survival** — Treyarch wired it and never showed the switch. · **Instant match start** — no lobby countdown. Classic intro cutscenes play again.

### 🧰 Quality of life

Instant Pack-a-Punch · BO4 Max Ammo · wall buys refill your magazine · high-round fix · animated camos · **prone at a perk machine for +100 points** · full backwards and sideways movement speed · **network frame patch** · **graphics boost** on the ADVANCED tab · **remove round cap**, **24-zombie solo cap**, **instakill rounds**, **Double Tap 1.0**, **no barrier attacks**, **no bleedout** on the PATCHES tab · **better Speed Cola** on the GAME tab · **SET POINTS** and **TELEPORT** on the CHEATS tab · **your settings are remembered** between sessions.

<br>

### ⌨️ Commands

Every one works in chat with `.`, `!` or `/`, and every one can be bound to a key. Type **`.help`** in game for the live list.

```
.round 30          jump to a round              .give <weapon> [pap]   spawn a gun
.fly  .god  .ghost  .hud  .velocity             .killall  .bring       crowd control
.brutus / .panzer / .jumpingjacks <n>           .pay <player> <n>      send points
.shield            the map's buildable shield   .staff <element>       Origins staffs
.machines          drop Nuketown's machines     .movespeed             1.5x speed
```

<br>

---

## ⚠️ Known issues

Kept here on purpose. Nothing below is hidden in the release notes.

| Issue | Where you'll see it |
|---|---|
| 🔴 **Deadshot Daiquiri's head lock-on does not work** | Every map. Treat the perk as aim-assist only for now. Being fixed. |
| 🔴 **Origins and Mob of the Dead can crash** | Roughly 20–35 s into a match. Cause never found; not currently being worked on. |
| 🟠 **Vulture Aid is missing on Origins and TranZit** | Those two maps are out of network space — shipping it there crashes the map at load. The other 11 perks are there. |
| 🟠 **Who's Who clone glow is TranZit-only** | The glow needs assets only the Victis crew have. The perk itself works everywhere it ships. |
| 🟠 **Who's Who is stock on Origins** | The ballistic knife it needs does not exist in any file Origins loads. |
| ⚪ **Bouncing Betty is not included** | Its viewmodel animations and HUD icon do not exist anywhere to ship. |

<br>

---

## 🛠️ Building it yourself

```
scripts\zm\      all the gameplay — plain GSC, no compiling
ui\  ui_mp\      LUI menu overrides
zone_source\     what gets linked into mod.ff
installer\       the release package
```

1. Edit a `.gsc` → double-click **`build.bat`** → play. That is the whole loop.
2. Only if you changed a `.csc` or a real asset: run **`build_ff.bat`** first, then `build.bat`.

<br>

---

## 🙏 Credits

**Made by DavidHiFi & Synarxis.**

Everything below is a source this mod actually uses, with what it was used for. If something of
yours belongs here and is missing, please open an issue and it gets added.

### 🧬 What this mod grew out of

| Who | What |
|---|---|
| **sehteria** — *T6-ZM-Expanded* | The mod this one started from. Most of the original root scripts now merged into `quality_of_life.gsc` came from here: BO4 Max Ammo, Instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers and counters, the area notifier, the Cold War round HUD, secret song survival. |
| **SadSlothXL** | The **Death Machine** power-up — the drop, the weapon swap and its sounds. |

### 🔀 Ported or adapted from other mods

| Who | What |
|---|---|
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The **custom Survival locations** and the extra **gamemodes**. Treyarch left the data for these in the game files and never shipped them; Reimagined is the implementation that works, and Diner is a port of its work. It is this project's designated primary reference. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The **Die Rise weapons block**: the Sliquifier pre-nerf behaviours (kills to round 255, keeps chaining while put away, no extra goo) and the **Semtex wall buy** — its position and angles are Remix's, value for value. |
| **5and5** — [BO2 Strat Tester](https://github.com/5and5/BO2-StratTester) | Every destination in the **TELEPORT** row on the CHEATS tab, copied coordinate for coordinate out of its `commands.gsc`. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The reference for most of the **PATCHES** tab. The **NETWORK FRAME PATCH** is its `fixed_wait_network_frame()` shape and its measured console figures (solo 100 ms, coop 50 ms); the backspeed values, the 24-zombie solo cap, instakill rounds, Double Tap 1.0 and no barrier attacks were all checked against it; and this mod's coordinates readout is modelled on its HUD. Used as a reference and re-derived against the shipped game scripts, never copied wholesale. |

### 📚 Reference data and dumps

| What | Used for |
|---|---|
| **T6-Data-Archive** | Per-map clientfield dumps — which made this mod's bit budgets something to measure instead of guess — and the authoritative `notifyonplayercommand` list behind the chat commands. |
| **The stock GSC dumps and BO2 raw files** | Treyarch's own scripts, read constantly so this mod matches vanilla behaviour instead of reinventing it. |

### 🧰 Built with

| What | Used for |
|---|---|
| [**Plutonium**](https://plutonium.pw) | The platform the whole mod runs on. |
| **OpenAssetTools** *(v0.32.0)* | Linking `mod.ff`, and reading the stock game's fastfiles — models, map entities, sound banks, images. |
| **gsc-tool** by **xensik** | Parse-checking every `.gsc` and `.csc` before a build. |

### 🌈 Bundled with the optional ReShade install

The installer's ReShade option ships these as they were released. All credit for them is theirs.

| Who | What |
|---|---|
| **crosire** | [ReShade](https://reshade.me) itself. |
| **Barbatos Bachiko** | BarbatosShaders — the sharpening and PHDR passes. |
| **Alex Tuduran** | FGFX. |
| **Marot Satil** and the **GShade** project, and **Ioxa** | GShadeShaders, including Clarity2. |
| **Lord of Lunacy** | InsaneShaders. |
| **prod80** | The PD80 / Prod80 shader and LUT packs. |
| **NVIDIA** | The NIS sharpening algorithm one of the Barbatos shaders is built on. |

### 🎮 The game itself

Every model, texture, sound, animation and script this mod builds on belongs to **Treyarch** and
**Activision**. A legitimate copy of Black Ops II is required to run any of it.

<br>

### 🤖 On the code, up front

**Most of this mod was written by [Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent** — directed, tested and signed off by me across a long run of sessions. It is fair to call it vibecoded.

AI is a divisive thing and plenty of people want nothing to do with it. That is a completely reasonable position, so you should know before you download rather than after. Everything here is play-tested in game before it is called finished, and anything that has not been tested yet says so.

<br>

<div align="center">

<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>

</div>
