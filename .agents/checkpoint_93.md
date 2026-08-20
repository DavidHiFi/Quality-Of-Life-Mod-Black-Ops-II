# Checkpoint 93 — v2.0.0. The installer package, and the Die Rise block still unbooted.

Written 2026-08-20 at the user's request, before a terminal restart and the 2.0.0 release.

---

## 0. STATE — READ THIS FIRST

| | |
|---|---|
| version | **2.0.0** (`mod.json` = `"^32.0.0"`), built and deployed |
| released | **v2.0.0** on GitHub, three assets — see §3 |
| 🛑 unbooted | **the Die Rise weapons block (v1.99.96) has still never been tested in game**, and neither have v1.99.93 / 94 / 95 |
| in flight | nothing. The installer is done; the next item needs the user's Die Rise boot first |

🛑 **The single most important open thing is not code.** Four builds are deployed and unverified.
Checkpoint 92 §6 has the boot list; the Die Rise one is at the top and its one visual risk is
whether the semtex wall buy sits flat on the wall.

---

## 1. WHY 2.0.0

The user's call, and their reasoning: *"this is a big deal for a release/version for the mod, the
full mod package with all the options on a user friendly script that makes it easy for even
beginners to plutonium mods to install."*

🌟 **`^3` IN `mod.json` IS A COLOUR CODE, NOT PART OF THE VERSION.** Confirmed by reading the file:
`"name": "^5Quality Of Life"`, `"author": "^3DavidHiFi & Synarxis"`. So `"^31.99.96"` was `^3` +
`1.99.96`, and 2.0.0 is **`"^32.0.0"`**. The installer's version parser had been special-casing a
leading `31.` — wrong, and it would have read 2.0.0 as "32.0.0". Both installers now strip the caret
**and** the colour digit. Found by checking the file rather than by the bump failing in the user's
hands.

---

## 2. THE MOD PACKAGE — this is what a release now is

Source of truth in the repo is **`installer\`**; the release zip is that folder renamed
**`Quality Of Life Mod T6 ZM <version>`**. The user set the layout, and the point is that the root
has four entries and nothing else:

```
Quality Of Life Mod T6 ZM 2.0.0\
   Windows Install.bat      <- the only thing a Windows user touches
   README.txt               <- minimal: how to run it, and the prerequisites
   Linux Install\           <- install-quality-of-life.sh + its own README.txt
   Mod Files\               <- qol-installer.ps1, reshade\, zm_qol\ (the 5 mod files)
```

`zm_qol\` inside `Mod Files\` is assembled **at packaging time** from the built files in the project
root — it is not tracked in the repo, because `mod.iwd` is gitignored.

### The installer itself

`Mod Files\qol-installer.ps1`, launched by the .bat. It is PowerShell because the user asked for
arrow-key navigation and a .bat cannot draw that; the .bat stays as the thing you double-click, and
`README.txt` says plainly that you never need to open anything in `Mod Files`.

One menu — INSTALL / REMOVE / MORE — with live status per row, a confirm screen per action, and
every path, every "found this" and the run log moved behind **Details and log** (the user asked for
the header clutter to go). Warnings are their own yellow block with emoji.

| what | notes |
|---|---|
| install / update the mod | asks **keep my settings** (default) or **fresh install, wipe everything**. Settings live in `storage\t6\players\mods\zm_qol\`, not in the mod folder |
| HD texture pack | offers to **back up the player's own textures first** |
| custom sounds | same |
| ReShade + BO2 preset | backs up an existing `ReShade.ini` / `BO2.ini` as `.backup` |
| remove any of the four | deletes **only what a manifest recorded installing**, and offers to restore the backup |
| check for a newer release | compares versions and **refuses to downgrade** without a second yes |

🛑 **The prune is limited to the five mod extensions** (`.ff .iwd .json .sabl .sabs`). The game writes
`games_mp.log` and `console_zm.log*` into the mod folder, and the first version of this installer
deleted them. That is the user's own session history.

### The ReShade payload — 19 files, 17 MB, everything else proven inert

`Mod Files\reshade\` is the standard (non-addon) ReShade 6.7.3 32-bit `dxgi.dll`, a byte copy of the
user's own `BO2.ini`, a freshly written `ReShade.ini` with no personal paths, and the 13 shader
files + 4 textures that BO2.ini's six enabled techniques `#include` transitively. The full library
is 857 files / 128 MB and ReShade compiles **all** of it at startup, so the trim is also a faster
load.

- The eight `.addon32` files were dropped because `ReShade.log1` says *"Skipped loading add-on …
  because this build of ReShade has only limited add-on functionality"* for every one.
- **No background watcher.** The old script kept one alive to restore files Plutonium might delete.
  Measured: the `dxgi.dll` in `Plutonium\bin` is dated **28 Feb 2026** while the launcher and
  bootstrapper beside it are dated **7 Aug 2026** — it already survives a Plutonium update. The log
  agrees: 285 "bin already up to date" against 123 seeds.

### Linux

`Linux Install\install-quality-of-life.sh` — same menu, same actions, finds the Wine prefix itself
(`$WINEPREFIX`, `~/.wine`, `~/Games/plutonium`, Lutris, Bottles, Steam `compatdata`) or takes
`--root`. 🛑 ReShade there needs `WINEDLLOVERRIDES="dxgi=n,b"` on the launch command; the script and
its README say so rather than pretending it just works.

---

## 3. THE RELEASE

`v2.0.0`, three assets:

| asset | size | what |
|---|---|---|
| `Quality Of Life Mod T6 ZM 2.0.0.zip` | ~200 MB | the package above |
| `zm_qol-textures.zip` | 524 MB | `images/` — 1,018 files, 1.21 GB unpacked |
| `zm_qol-sounds.zip` | 641 MB | `zone/` — the 3 sound files |

The two pack names are **exactly what the installer asks GitHub for**, so they must not be renamed.
Textures compress to 45%; the sounds are stored uncompressed because deflate made them *bigger*
(692 MB vs 672 MB).

🛑 `Optionals.zip` (1.1 GB) in the project root is the user's own and is now gitignored — GitHub
rejects any repo file over 100 MB.

---

## 4. HOW IT WAS VERIFIED — fake Plutonium trees, never the real install

`LOCALAPPDATA` redirected on Windows, `--root` on Linux. Both sides:

- mod install keeping settings, and wiping them
- a planted `games_mp.log` and `console_zm.log.003` **still present afterwards**
- texture install with backup, then removal restoring a planted `my_own_texture.iwi` byte-for-byte
- ReShade install then removal leaving a planted custom shader and the user's `ReShade.ini` intact
- the update check reading v1.99.89, comparing, and saying *"your copy is NEWER"*
- a real 154 MB release download unpacked and installed
- the finished 2.0.0 package driven end to end from its own folder — reports **version 2.0.0**

Defects this found, all fixed: LF line endings broke `call :label` in the old .bat; a PowerShell
one-liner's `\"` escapes could not survive `FOR /F`; `^|` reached PowerShell literally; the update
check would have installed an **older** release over a newer build; the Linux empty-directory
cleanup deleted the destination folder itself, taking out Plutonium's `bin`; and `ReadKey` throws
when input is redirected, so the menu now falls back to typing a number.

---

## 5. NEXT

1. 🛑 **The user boots Die Rise.** PATCHES tab → SLIQUIFIER PRE-NERF and SEMTEX WALL BUY. Does the
   semtex sit flat on the wall? Does the Sliquifier keep chaining with another gun out, and stop
   leaving extra goo?
2. Then queue item 35, **PERMA-PERKS on the GAME tab** — settled with the user: ENABLED = every
   perma-perk that map has is active immediately, DISABLED = stock progression, DISABLED is the
   default. Scope measured: 13 upgrades on TranZit and Die Rise, 14 on Buried (Perma-PhD is
   Buried-only), none on Mob / Origins / Nuketown, all inside `is_classic()`. 📝 Unmeasured: what
   "active immediately" must write — `_zm_pers_upgrades` tracks per-player stat progress, so the
   `level.pers_upgrade_*` flags are probably not enough on their own.
3. The rest of `QUEUE_LIST.md`.
