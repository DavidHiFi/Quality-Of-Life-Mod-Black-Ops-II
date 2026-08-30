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
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">
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

There is no automated installer for Linux — it was dropped, not just unmaintained, because it never
worked reliably enough to keep supporting. Install by hand instead: see **"Rather install it by
hand?"** below. It's the same three steps as any other Plutonium mod — copy the `zm_qol` folder into
`storage\t6\mods\` inside your Plutonium prefix and launch from the Mods menu.

<br>

### 🎛️ What the installer can do

| | |
|---|---|
| 📦 **EVERYTHING** | One row that installs the mod, the HD textures and the sounds in one pass — with the same backup offer, asked once. **Not ReShade** — see why below. |
| 🧟 **The mod** | Install or update it. Asks whether to **keep your menu settings** or start fresh. |
| 🔎 **Update check** | Pulls the newest release from GitHub. Won't put an older release over a newer build without asking twice. |
| 🖼️ **HD texture pack** | Optional. Backs up your current textures first if you want. |
| 🔊 **Custom sound pack** | Optional. Same backup offer. |
| 🌈 **ReShade** | Optional, and its own row — not part of EVERYTHING. Ships **ReShade 6.7.3** and its full shader collection (856 files), plus four presets — one per Plutonium game, all four currently carrying the same BO2 look. In game: **End** opens the menu, **Numpad 0** turns the effects off and on, **Ctrl+Shift+PgUp / PgDn** changes preset. |
| 🐕 **Start ReShade watchdog only** | Its own row, separate from installing ReShade — for when you launch Plutonium yourself and just want the watchdog running alongside it. Same helper the ReShade install offers to start for you. |
| ▶️ **Play now (LAN, mod already loaded)** | One click straight into Zombies with the mod already running — no Mods menu, no manual pick. LAN/offline only for that session. |
| 🎮 **Controller icons** | Optional, and you pick one: **PlayStation 5**, **Nintendo Switch** or **Xbox One**. The HD texture pack no longer ships any controller art, so the base install leaves the game's own prompts alone and your pick is the only thing that changes them. Same backup offer; picking a different pack swaps it over cleanly. |
| 💾 **Backups** | Back up your **own** textures, sounds, ReShade setup or mod folder — each on its own — and put them back any time. Kept as plain folders in `storage\t6\backups\`. |
| 🧹 **Remove any of it** | **EVERYTHING** in one row, or one piece at a time. The mod folder really goes, so it stops showing in the Mods menu. Your game logs are moved to the backups, never deleted. Only deletes what the installer put there, and offers your backup back. |

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts.** It clears any file out of its own `bin`
> folder that it does not recognise, and that includes ReShade's `dxgi.dll` and its presets — so
> installing ReShade alone does not survive your next Plutonium launch. That is also why it is not
> part of **EVERYTHING**: a one-tap install shouldn't silently leave you with something that quietly
> breaks.
>
> **The fix:** the ReShade install also places **`Play BO2 with ReShade.bat`** next to
> `Windows Install.bat` (and offers to start the watchdog for you on the spot). Double-click it
> **instead of** opening Plutonium directly, and leave the window it opens running for as long as
> you're playing — it watches for Plutonium and puts ReShade straight back the moment it sees
> Plutonium clear it out. Closing that window doesn't uninstall anything; it just stops watching.

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

Nearly all of it is a **switch** in the in-game menu — **Options → Settings**, tabs **GAME / PATCHES / HUD / CHEATS**. 55 rows — 53 on Nuketown, where the CHEATS tab has no TELEPORT row because the map has no landmark list — plus five graphics rows on the stock **ADVANCED** tab and an **AIM ASSIST** row on **CONTROLS → GAMEPAD**. No chat commands required.

> [!NOTE]
> **Confirmed in game:** **UNLOCK ALL** and **RESET STATS** (Zombies main menu → THEATER), the pause-menu rows, the **Zombie Blood** HUD icon, and the scoreboard naming your start location — "Survival - Diner", not "Survival - Green Run".
>
> **Shipped and booted, not individually confirmed yet:** **BETTER SPEED COLA**, **NO BLEEDOUT PATCH**, **CHANGE ROUND** to 10000 with the round cap off, the Die Rise Sliquifier row, the Die Rise Semtex wall buy, the six newer PATCHES rows (including **3 HIT DOWN**), **SET POINTS** / **TELEPORT**, the DSR 50 and Five-Seven recoil, the Winter's Howl firing effects, and Depth Of Field actually staying off at round-end and game-over when DISABLED.
>
> **v2.7.3, shipped and booted, not individually confirmed yet:** the custom **Fire Sale icon** now actually applies (mod.ff owned the image and was shipping the stock art over the top of it); the Wunderfizz **interact-spam softlock** is fixed; **Fire Sale can drop on every map** with CUSTOM POWER-UPS on, including the static-box survival locations like Town; **3 HIT DOWN** now fires at all (it was testing the wrong means-of-death string and never once ran); **Pack-a-Punch** is reachable at every Nuketown spawn; Vulture Aid no longer changes zombie eye colour; and the mod no longer shadows custom sounds in your `storage\t6\zone` folder (the M1911 and Olympia shoot sounds among them).
>
> **v2.8.0, shipped and booted, not individually confirmed yet:** a **PERMA-PERKS** toggle on the GAME tab — off by default; on, every persistent upgrade *that map already has* is active from the start, with no challenge progress needed. It never adds a perma-perk to a map that was not meant to have one, so Perma-PhD stays a Buried perk, and only TranZit, Die Rise and Buried have any at all. Classic only, as in the base game. Also: the Diner claymore's own fix is finally **armed** — the watchdog that switches it on gave up 45 seconds into a match, long before anyone walks to the shack, so it had never once run.
>
> **v2.8.3, shipped and booted.** The **silent M1911 is fixed at its root**: `mod.ff` had inherited four weapon assets from its donor that renamed their fire-sound aliases (`wpn_m1911_fire_plr` where retail says `wpn_1911_fire_plr`, and the C96's `wpn_mc96_*`). Those names exist only in the donor's table, so the sound pack in your `storage\t6\zone` was never asked for. The mod now **stops owning `m1911_zm`, `m1911_upgraded_zm`, `m1911lh_upgraded_zm` and `c96_zm`** so the game loads its own and your pack is heard. **63 more gun sounds restored** — the Barrett/XPR-50, HAMR, Judge, M16, M32, Python, RPD, RPG, Saiga-12, Saritch, TAR-21, Type 95 and XM8 were silenced by v2.8.2's over-cautious restore rule. `.give` now reaches the **17 guns whose in-game name differs from their code name** (`.give olympia`, `scorpion`, `chicom`, `stg44`, `saiga`, `minigun` …). **WINTER'S HOWL INFINITE** is renamed **WINTERS HOWL BUFF**. And the **round counter tracks correctly with ROUND DELAY OFF** — its animation was missing `end_of_round` notifies once rounds turned over faster than the animation ran.
>
> **v2.8.8, shipped and confirmed in game.** A full audit of every sound the mod's weapons ask for, against the alias tables of all seven map soundbanks — **nothing the mod can play is silent on any map now.** **Reload and gun-cocking foley restored for 26 weapon families** (AK-47, AN-94, Ballista, Skorpion EVO, M27, Judge, KSG, LSAT, M16, MG08, MP40, MP5K, PDW-57, Executioner, RPD, Saiga-12, Saritch, SCAR-H, SVU, TAR-21, Thompson, Type 95, RPG, Uzi, XM8, XPR-50) — each was missing its `fly_*` set on between one and six maps. **The Jet Gun is audible everywhere** — its twelve aliases live only in TranZit's and Nuketown's banks, so it fired silently on the other five, pickup sound included. **The MP5K and Olympia are no longer silent on Origins**, the one map bank that never declared them. **Blood Money's announcer line now plays**: it is spoken by the mod itself at the moment the drop is grabbed instead of going through the announcer queue, which was dropping it. The **Death Machine** line now ships under both announcer voices, so it cannot fall silent either. And **four more of your sound pack's guns come through** (Python, HAMR, M32, Pack-a-Punched Executioner) — the mod was declaring those aliases with its own copy of the stock audio, shadowing your `storage\t6\zone` pack; those rows are gone.
>
> **v2.8.9, confirmed in game.** The **Mauser C96 sounds like a Mauser on every map**, not just Origins. Its shot alias is one Treyarch shared with the M1911, and each map's soundbank points that one name somewhere different — at the Mauser on Origins, at the M1911 everywhere else — which is fine in the base game, where the Mauser never leaves Origins, and wrong here, where it can be found on any map. The gun now asks for its own name instead, and the mod ships the stock Mauser shot behind it, with the same sub-bass, tail and distance layers Origins uses.
>
> **v2.9.0, built and deployed, not booted yet.** **`.give` now takes the name you would actually type.** Every weapon's command used to be the engine's internal name, so the Mauser was `.give c96`, the MSMC was `.give insas`, the Olympia was `.give rottweil72`, the Chicom was `.give qcw05`, the Paralyzer was `.give slowgun` and the XPR-50 was `.give as50`. All 87 of them now answer to their real name — `.give mauser`, `.give msmc`, `.give olympia`, `.give chicom`, `.give paralyzer`, `.give xpr50`, `.give s12`, `.give m27`, `.give type25`, `.give m8a1`, `.give galvaknuckles`, `.give semtex` — and `.give list` shows those names instead of the internal ones. Every old name still works, and every name the list prints is one `.give` accepts. The names are not guesses: they were read out of the game's own English text, so the gun is called what the game calls it.
>
> **v2.9.1, built and deployed, not booted yet.** **Your sound pack is authoritative again for nine guns** — the MP5, Olympia, M16, XPR-50, Barrett, Judge, S12, Saritch and MTAR. v2.8.8 had the mod declare their sounds so they would not be silent on Origins, the one map whose soundbank never listed them; because the mod's audio loads first, that silently overrode the pack on the other seven maps. Origins now gets its **own private copies** of those nine guns instead, so the mod only ever names sounds nothing else uses — the guns stay in the box on every map, nothing is silent anywhere, and the stock names go back to your pack. **One honest exception:** the reload and cocking foley for those nine is named by the shared weapon animations rather than by the gun, so it cannot be redirected per map and still comes from the mod on every map.
>
> **v2.9.2, built and deployed, not booted yet.** **The ReShade half is error-free on all four Plutonium games, not just Black Ops II.** Black Ops, MW3 and World at War are DirectX 9 games and 43 of the shipped shaders cannot compile there at all — the wall of red errors came from the overlay's *Force load all effects* button asking for every one of them, so that button is now hidden and ReShade builds only what the active preset uses. **BO1, MW3 and World at War now ship as genuinely empty presets**, so they can never report an effect error, and Black Ops II keeps its own. A new **Cinematic Colour Grading** preset ships with the mod and is what every game opens on; two of its effects were dropped because they cannot work everywhere — one is in no shader pack this mod ships, the other is one of the 43 — and the remaining eight are each confirmed compiling on DirectX 9.
>
> **v2.9.3, built and deployed, not booted yet.** **Pack-a-Punched guns have their gunshot back.** About thirty upgraded weapons played only the Pack-a-Punch electric zap and no actual gun sound — the FAL OSW and SVU the way you found them, plus the AK-47, AN-94, MSMC, Mk 48, MP7, Peacekeeper, QBB LSW, SWAT-556, Vector, KSG, LSAT, MG08, SCAR-H, Thompson, Uzi, Skorpion EVO, M27, XM8, Type 95, RPD, RPG, MP40, the Origins copies of the nine hand-back guns, and the Mob minigun. A Pack-a-Punched shot in BO2 is a chain of four sounds and the mod only ever declared the first one, so the chain stopped at the zap. All four links now exist, for every gun, on every map — checked by walking each chain against all eight map soundbanks. The **Pack-a-Punched XPR-50 was completely silent everywhere** and now is not, and the **Pack-a-Punched War Machine works in Grief**. None of the new sound names can collide with your sound pack: they are the mod's own, and the gunshot at the end of every chain is still whichever one your pack provides.<br>**Depth Of Field DISABLED now really is off.** The row read DISABLED and the blur was still there when aiming, because only the mod's own setting was saved between launches — the renderer's switch was never written unless you moved the selector that session. It is now applied on every spawn, the same way the Fog row works.<br>**`.give list` is a panel you toggle**, like `.help`, instead of a burst of chat that scrolls away before you can read it. Run it again to hide it.<br>**`.give fal` gives the FAL, `.give falosw` gives the FAL OSW.** They were both the FAL OSW.<br>**The solo intro cutscene now holds the match.** On Die Rise, Mob, Buried and Origins the round used to start underneath the video, so skipping part-way through dropped you into a match where zombies were already through the barrier. Round one now waits until you skip it or it ends. (The ROUND DELAY OFF switch was not the cause — it cannot touch round one — but the symptom was real.)<br>**Xenon Bloom loads.** It was failing to compile on one line of leftover debug code that calls a function the shader pack does not ship; the line's result was never used. And the **Cinematic preset now carries your in-game edits** — the watchdog saves preset changes back so a Plutonium wipe cannot undo them.
>
> **v2.9.4, built and deployed, not booted yet.** **Origins loads again.** v2.9.3 crashed on it, and the dump named the cause: the client was told to put the XPR-50 in the box display on a map where that gun is never loaded, so it looked up a model that was not there. Origins swaps three guns for its own private copies and only that one could crash, because the other two exist on every map regardless. **And the nine private Origins guns were never loading at all** — all sixteen files were carrying sixty extra entries that only appear when a weapon is exported back out of the game, and the loader rejects a file in that shape. Every one of them now matches the shape a working mod uses. Both faults were in v2.9.1; Origins had not been started since, which is why they only surfaced now.<br>**The Vulture Aid marker over the Wunderfizz is no longer a bright blur.** Its texture holds two symbols side by side and the effect never said so, so both were drawn stretched on top of each other. It now draws just the question mark, at its proper shape.<br>**Your latest ReShade preset is what ships**, exactly as you left it — Xenon Bloom off, and your gamma and white point.
>
> **Still open:** 15 gun sounds play the mod's own copy of the stock audio rather than your sound pack's — the AK-47, Tac-45, M27, INSAS, M16, MP40, MP5K, MP7, Olympia, FAL OSW, SVU, Thompson, Type 95, the Executioner's hammer and the Tac-45's reload. That is a hard limit of the linker, not a choice: those aliases are absent from at least one map's soundbank, the mod has to declare them so the gun is not silent there, and OpenAssetTools refuses to declare an alias without embedding its audio. Any one of them can be handed back to your pack, at the cost of that gun going silent on the maps whose bank lacks it.  Mob of the Dead's starting-weapon row is **not shipped** — the snub-nose Python it needs exists in no file in this workspace. The Winter's Howl **freeze-and-shatter** death is inert on every map: its animstatedefs are not linked into `mod.ff`, so the gun kills without ever freezing anything.

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

- **Diner as a Survival location** on TranZit — its own Pack-a-Punch, wall buys, Semtex wall buy, buildable shield, teddy bears and secret song.
- **Nuketown:** the sunken perk-drop pad is fixed, and **`MACHINE DROPS → ALL ON ROUND 1`** airlifts every machine in at match start instead of making you wait until round 26.
- **Die Rise:** the **Sliquifier pre-nerf** (a PATCHES switch) and the **Semtex wall buy**, which is always on.
- **The scoreboard and the loading screen name the place you are actually in** — "Survival - Diner" and "DINER", not "Survival - Green Run" and "GREEN RUN". The **scoreboard emblem** matches the team you are playing as, too.

### 🖥️ HUD & menus

- **Hitmarkers** with 8 selectable sound packs (Cold War, MW 2019, BO4, Overwatch, Apex, 8-bit, MW Classic, BO7) plus crit and squad-downed alerts.
- Round summary, timers, health bar, bleedout bar, zombies remaining, zone names, **compass**, velocity meter, Cold-War round HUD (top right, or **top left like BO4** with one switch), perk pop-ups, **power-up timers**.
- **RESTART GAME**, **INSTANT EXIT** and **QUIT TO DESKTOP** on the pause menu.
- **Night Mode**, **Fog** and **Higher Draw Distance** on the game's own ADVANCED tab — plus a **DISABLED** step for Depth Of Field that base BO2 never gave you.
- **Instant match start** — no lobby countdown. Classic intro cutscenes play again.

### 🧰 Quality of life

Instant Pack-a-Punch · BO4 Max Ammo · wall buys refill your magazine · high-round fix · animated camos · **prone at a perk machine for +100 points** · full backwards and sideways movement speed · **network frame patch** · **graphics boost** on the ADVANCED tab · **remove round cap**, **24-zombie solo cap**, **instakill rounds**, **Double Tap 1.0**, **no barrier attacks**, **no bleedout**, **Winters Howl buff**, **round delay off** and **no walkers** on the PATCHES tab · **better Speed Cola** and **perma-perks** on the GAME tab · **SET POINTS**, **TELEPORT** and **ONE SHOT ONE KILL** on the CHEATS tab · **your settings are remembered** between sessions.

<br>

### ⌨️ Commands

Every one works in chat with `.`, `!` or `/`, and every one can be bound to a key. Type **`.help`** in game for the live list.

```
.round 30          jump to a round              .give <weapon> [pap]   any gun on the map
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
| 🟠 **Deadshot Daiquiri's head lock-on is unconfirmed on controller** | The 1.99.61 fix is now independently re-checked line-for-line against stock's own client handler and matches it exactly — the only thing this mod changes is the damage multiplier, gated behind its own toggle. What's still missing is a gamepad actually on it; nobody has booted with a controller since. |
| 🟠 **The Diner claymore wall buy has no purchase prompt** | Its *position* is confirmed correct — a real in-game bullet-trace probe measured the wall, floor and mine placement in 2.3.2 and it matches. Looking straight at it on a fresh spawn shows no buy prompt at all, which is a separate, newer bug. A diagnostic probe is already shipped and waiting on the next boot to read its output. |
| 🔴 **Origins and Mob of the Dead can crash** | Roughly 20–35 s into a match. Four specific causes have been tested and ruled out with hard evidence. The one test that would actually settle it — booting classic Origins with the mod switched off — is designed and has never been run. |
| 🟠 **Who's Who clone glow only draws on TranZit and Die Rise** | Both use real, unmodified stock assets — nothing invented. The other four maps are hard-blocked, each for a specific measured reason: Nuketown's and Mob's own character models have no glow-capable material anywhere in the game, Origins' has neither the material nor a free `scriptmover` clientfield bit, and Buried's `actor` clientfield set is already completely full. No lookalike is built to paper over any of that. |
| 🟠 **Who's Who is stock on Origins and Mob of the Dead** | Confirmed again by directly reading both maps' own fastfiles: neither ships a single ballistic-knife asset, where every map that has this feature does. Porting the asset set in from another map's zone is technically possible but has never been attempted — it's a real, unproven job, not a toggle. |
| ⚪ **Bouncing Betty is not included** | Its assets are real and do exist — in Black Ops II's multiplayer files. They are confirmed absent from every fastfile Zombies itself loads, and Zombies has no equipment-plant mechanic for it to hook into at all. Porting it would mean pulling a weapon's full asset chain across game modes for the first time in this project, plus building a new placed-explosive mechanic from scratch. |

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
| **sehteria** — *T6-ZM-Expanded* *(unconfirmed, see below)* | The mod this one started from. Most of the original root scripts now merged into `quality_of_life.gsc` came from here: BO4 Max Ammo, Instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers and counters, the area notifier, the Cold War round HUD, secret song survival. |
| **SadSlothXL** *(unconfirmed, see below)* | The **Death Machine** power-up — the drop, the weapon swap and its sounds. |

> [!NOTE]
> Both names above are carried forward from this project's very first credits list, from before
> anything here was git-tracked. Nobody has since been able to verify either name or a source URL
> against anything in this workspace — that's a gap in this project's own records, not a claim that
> the credit is wrong. If either of these is you, or you know the real source, please open an issue
> so it can be fixed properly.

### 🔀 Ported or adapted from other mods

| Who | What |
|---|---|
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The **custom Survival locations** and the extra **gamemodes**. Treyarch left the data for these in the game files and never shipped them; Reimagined is the implementation that works, and Diner is a port of its work. It is this project's designated primary reference. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The **Die Rise weapons block**: the Sliquifier pre-nerf behaviours (kills to round 255, keeps chaining while put away, no extra goo) and the **Semtex wall buy** — its position and angles are Remix's, value for value. |
| **Fraaagaaa** — [Strat Tester for Black Ops II](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the **TELEPORT** row on the CHEATS tab, copied position and angles out of `scripts/zm/strattester/commands.gsc`. |
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
