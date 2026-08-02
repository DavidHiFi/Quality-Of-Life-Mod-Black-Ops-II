# Checkpoint 14 — v1.18.1. The mod got much smaller, then grew new features.

Written 2026-08-03. Supersedes checkpoint 13 entirely — **the bug checkpoint 13
was built around no longer exists, because the feature it belonged to was
deleted.** Keep 13 only for its §3 root causes and §4 rules; ignore its §0.

**Read §0, then §1.**

---

## 0. THE SINGLE NEXT ACTION

**Nothing is broken that we know of. Everything below is shipped and UNTESTED.**
Load a map and check, in this order:

| what | how |
|---|---|
| Electric Cherry | Nuketown survival, Wunderfizz until you have **9** perks. 8 = it did not register. |
| clientfield mismatch | if you are dropped on connect, the log names the field and the side. This is the #1 risk this release. |
| chat commands | `.help` lists all 14. Try `.giveperks`, `.removeperks`, `.fly`, `.where`. |
| bleed-out bar | go down; a bar + countdown should appear, with NO author credit line. |
| credits banner | blue line, bottom-left, ~1s after the blackscreen. |
| Wunderfizz | still works? (model is real; sounds/anims are NOT — see §3) |

---

## 1. WHAT HAPPENED THIS SESSION

### 1a. The custom survival locations were deleted (user's call)

Borough/Maze never worked. After three failed diagnoses the user decided the
ported locations were not worth it. **~8,000 lines removed**, `mod.ff` 23.3 → 15.9 MB.

Gone: 12 loc scripts, 10 `replaced/` modules, the custom gamemodes
(zcontain/zrace/zsr/zturned/zmeat + `_gametypes.txt`), and all the Buried
survival support built earlier that same session.

Kept: **Diner** (on `zstandard` AND `zgrief` — stock registers it for neither),
the Reimagined **menu** work (instant start + the list popups), and all base QoL.

`d722590` is the restore point immediately before the deletion. Everything
removed is recoverable from there.

### 1b. The Buried freeze was never solved — and does not matter now

Three theories died, in this order. **Do not re-run any of them:**

1. **Not the zbarriers.** The classic-vs-Borough A/B showed `zbarriers=0` on
   BOTH, and classic works fine.
2. **Not `ignoreall`.** Borough zombies reported `ignoreall=0` — they were
   activated. The "thread died before zombie_setup_attack_properties" chain was
   wrong.
3. **Not zones or distance.** A zombie at `dist=67`, right next to the player,
   was frozen too.

What was measured and never explained: Borough zombies had
`first_node.zbarrier=no_first_node` while classic zombies had `yes`. If Buried
survival is ever revisited, **start there**, and start by porting Reimagined's
own `zm_buried_grief_street` rather than theorising.

### 1c. New features

- **Wunderfizz on every map** (`scripts\zm\wunderfizz.gsc`), using the REAL
  Origins machine — `p6_zm_vending_diesel_magic` + its fx, copied out of
  `zm_tomb.ff`. Upstream could only stand a Juggernog machine in its place.
- **Electric Cherry** as the 9th perk on transit/nuked/highrise/buried.
- **`_zm_magicbox` override** — pull duplicate weapons, no wonder-weapon caps.
- **14 chat commands**, **bleed-out bar**, **credits banner**.

---

## 2. RULES ADDED THIS SESSION

19. **🛑 VALIDATE WITH `gsc-tool -m comp`, NOT `-m parse`.** `parse` checks
    grammar only and passes code Plutonium rejects at load with `COM_ERROR (6)`
    → `SV_Shutdown` → no map boots. Cost one shipped-broken release (v1.16.0,
    `local variable 'fx' not found`). `comp` reproduces it exactly.
20. **Third-party GSC is usually written in another compiler's dialect.** Three
    separate imports this session used `#include maps/mp/...` with FORWARD
    slashes. T6 needs backslashes; gsc-tool rejects the file at line 1. Check
    every import.
21. **🛑 `sed` eats backslashes out of `maps\mp\...` paths.** It produced
    `mapsmpzombies_zm_perks::`, which *parses* (valid identifier) and then fails
    at load as an unresolved external. **Use literal edits for GSC namespace
    paths, never sed.**
22. **OAT *can* copy FX** — the starter kit's "FxEffectDef ❌/❌" means it cannot
    COMPILE one from raw source. Copying out of a `--load`ed fastfile that owns
    it works; `fx_tomb_dieselmagic_on` is in `mod.ff`. Same for `weapon`,
    `rawfile`, and client `.csc` assets.
23. **`REM` cannot sit between caret-continued arguments in a .bat.** cmd passes
    it to the program. The Linker failed with `Could not find zone definition
    file for target "REM"`.
24. **A perk is removed by `notify( perk + "_stop" )`,** not `unsetperk()`.
    There is no stock remove function — `unsetperk` lives inside
    `perk_think()`'s `waittill_any_return`. Bypassing the notify skips the
    per-perk teardown and leaves you on 250 health with no Juggernog.

---

## 3. WUNDERFIZZ IS NOT THE REAL THING YET

The user has asked twice. Current state: real MODEL, imitation BEHAVIOUR.

- **The right fix is `maps\mp\zombies\_zm_perk_random.gsc`** — Treyarch's actual
  Wunderfizz, 657 lines, Origins-only. Ship it the same way
  `_zm_perk_divetonuke.gsc` is shipped. It has the real `turn_on` /
  `on_idle` / `ballspin_loop` anims and the teddy bear.
- **🛑 THE SOUNDS CANNOT BE FIXED FROM SCRIPT.** Both the current script and
  `_zm_perk_random` call the same aliases (`zmb_rand_perk_start` / `_loop` /
  `_stop` / `_leave`). They are silent off Origins because **sound aliases live
  in per-map soundbanks**. Alias names are stored HASHED in `.sabl`, there is no
  CLI bank builder anywhere in the workspace, and Sound Studio is GUI-only.
  See [[t6-soundbank-facts]] and `.agents\sound_work_notes.md`.

---

## 4. STILL OPEN

- **Perma-Flopper** does not explode in classic Buried. A probe is in
  (`zmqol_flopper_probe`, classic-only) and has never been read. The chain needs
  `pers_upgrades_awarded["flopper"]` AND `pers_flopper_active` AND real fall
  damage — the probe prints all three.
- **`_zm_magicbox` override unconfirmed.** Look for
  `[zm_qol] _zm_magicbox override ACTIVE` in the log and try pulling a weapon
  you already hold. Present-but-not-working = the edit; absent = the override
  did not take.
- **Gun sounds / menu music** — the two sound jobs. Blocked on the same
  soundbank limits; full findings in `.agents\sound_work_notes.md`.
- Wunderfizz anims/teddy (§3).

---

## 5. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`. **`-m comp`.**
- OAT — `H:\Claude\oat-windows\Unlinker.exe`. `--list <ff>` to find which
  fastfile owns an asset; this settled the Wunderfizz and Electric Cherry
  imports without guessing.
- `build_ff.bat` now `--load`s zm_tomb.ff, zm_prison.ff and zm_prison_patch.ff.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- GitHub `github.com/ridgelanded/zm_qol`, private, tags v1.1.1 → **v1.18.1**.
