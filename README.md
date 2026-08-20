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
| 🧟 **The mod** | Install or update it. Asks whether to **keep your menu settings** or start fresh. |
| 🔎 **Update check** | Pulls the newest release from GitHub. Won't put an older release over a newer build without asking twice. |
| 🖼️ **HD texture pack** | Optional. Backs up your current textures first if you want. |
| 🔊 **Custom sound pack** | Optional. Same backup offer. |
| 🌈 **ReShade** | Optional, with the mod's BO2 preset and overlay theme ready to go. **End** opens it in game. |
| 💾 **Backups** | Back up your **own** textures, sounds, ReShade setup or mod folder — each on its own — and put them back any time. Kept as plain folders in `storage\t6\backups\`. |
| 🧹 **Remove any of it** | One piece at a time. Only deletes what the installer put there, and offers your backup back. |

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

Nearly all of it is a **switch** in the in-game menu — **Options → Settings**, tabs **GAME / PATCHES / HUD / CHEATS**. 47 rows, no chat commands required.

> [!NOTE]
> **Shipped in 2.0.0 but not play-tested yet:** the Die Rise Sliquifier and Semtex rows, the five new PATCHES rows, SET POINTS / TELEPORT, the DSR 50 and Five-Seven recoil, and the Winter's Howl firing effects. They are in the build; they have not had a boot yet.

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
- **Die Rise:** the **Sliquifier pre-nerf** and the **Semtex wall buy** the map was built for.
- **Scoreboard emblem** finally matches the team you are actually playing as.

### 🖥️ HUD & menus

- **Hitmarkers** with 8 selectable sound packs (Cold War, MW 2019, BO4, Overwatch, Apex, 8-bit, MW Classic, BO7) plus crit and squad-downed alerts.
- Round summary, timers, health bar, bleedout bar, zombies remaining, zone names, **compass**, velocity meter, Cold-War round HUD, perk pop-ups, **power-up timers**.
- **RESTART GAME**, **INSTANT EXIT** and **QUIT TO DESKTOP** on the pause menu.
- **Night Mode**, **Fog** and **Higher Draw Distance** on the game's own ADVANCED tab — plus a **DISABLED** step for Depth Of Field that base BO2 never gave you.
- **Instant match start** — no lobby countdown. Classic intro cutscenes play again.

### 🧰 Quality of life

Instant Pack-a-Punch · BO4 Max Ammo · wall buys refill your magazine · high-round fix · animated camos · **prone at a perk machine for +100 points** · console movement speed on PC · **remove round cap**, **24-zombie solo cap**, **instakill rounds**, **Double Tap 1.0**, **no barrier attacks** on the PATCHES tab · **SET POINTS** and **TELEPORT** on the CHEATS tab · **your settings are remembered** between sessions.

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

**DavidHiFi & Synarxis**

With thanks to **sehteria** (T6-ZM-Expanded), **SadSlothXL** (Death Machine), **Jbleezy** ([BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) — the reference for the Survival locations), the **BO2-Remix** authors, and everyone whose scripts are bundled here.

<br>

### 🤖 On the code, up front

**Most of this mod was written by [Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent** — directed, tested and signed off by me across a long run of sessions. It is fair to call it vibecoded.

AI is a divisive thing and plenty of people want nothing to do with it. That is a completely reasonable position, so you should know before you download rather than after. Everything here is play-tested in game before it is called finished, and anything that has not been tested yet says so.

<br>

<div align="center">

<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>

</div>
