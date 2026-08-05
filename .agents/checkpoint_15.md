# Checkpoint 15 — v1.22.0. Ten fixes, one long asset-ownership hunt.

Written 2026-08-03. Supersedes checkpoint 14. Keep 14 for its §2 rules
(19–24) and §1b's dead-end list; everything in its §0 is done.

**Read §0, then §2 — §2 is the expensive lesson.**

---

## 0. THE SINGLE NEXT ACTION

**Load classic Origins and start generator 1.** That is the one thing this
release turns on and nobody has seen yet. Everything else below is shipped
and unverified in the same way.

| what | how | why it matters |
|---|---|---|
| **Origins generator indicator** | classic Origins, start gen 1 | the whole point of v1.22.0 |
| Wunderfizz look | any map | now Juggernog's cabinet, no ball spin/beam — expected, see §2 |
| box jingle | Farm, spin the box | v1.21.2 moved it onto the zbarrier |
| `.fly` | toggle, hold W, then read the log | `[zm_qol] fly: move=…` decides its fate, see §3 |
| `.removeperks` | take 5 perks, run it | must clear ALL, not 2 |
| `.unpack` | pack an Olympia → Hades, unpack it | was refused before |
| `.help` | run it twice | toggles, no auto-close |
| MOTD Electric Cherry | Mob of the Dead | **untested risk**, see §2 |

---

## 1. WHAT SHIPPED

v1.18.2 → v1.22.0. Every one of these was a user-reported bug.

- **Electric Cherry duplicate clientfield** killed every map on load.
  `_zm_perks::init()` threads every custom perk's `perk_machine_thread`
  with no check that a machine exists, so `init_electric_cherry()` ran
  twice. Fix: clear the pointer.
- **Wunderfizz placement** — survival spawned all six map-wide machines
  while one was reachable. Now filtered to machines within 2500u of a
  `get_player_spawns_for_gametype()` spawn.
- **Teddy bear on relocate** — model was in `mod.ff` but never precached;
  runtime `setModel` to an unprecached model fails silently.
- **`.help`** — rewritten from the iprintln feed to a HUD panel, toggled.
- **`.pack` / `.unpack`** added. `.unpack` was gated on
  `can_upgrade_weapon()`, which for an upgraded weapon really asks "can it
  be RE-packed with attachments" — hence Mustang & Sally and Hades refused.
- **`.giveperks` / `.removeperks`** walked only `level._custom_perks`. The
  nine core perks are `level.zombiemode_using_*_perk` flags. Now both.
- **Box jingle** moved off `playsoundatposition()` onto the zbarrier —
  the Richtofen laugh proved entity-attached playback works where
  positional did not.
- **Credits banner** `^4` → `^5`.

---

## 2. 🛑 THE BIG ONE — mod.ff ASSET OWNERSHIP

**Declaring a stock map's asset in the zone makes `mod.ff` OWN it, and
`mod.ff` loads first, so the map's own copy is refused.**

- soundbank → **fatal**: `COM_ERROR Attempting to override asset
  'zmb_tomb.all' from zone 'mod' with zone 'zm_tomb'`, Origins unbootable.
- image/material → **silent**: `Could not load fx "..."`, garbled HUD.

**You do not choose what you own — the dependency chain does.**
`p6_zm_vending_diesel_magic` is skinned with `mtl_p6_zm_tm_monolith_rock`
and `mtl_p6_zm_tm_crystal`, the same textures as Origins' Pack-a-Punch
monolith. One `xmodel,` line took 108 of Origins' assets.

**Audit after ANY `zone_source` change** — see
`[[t6-modff-asset-ownership-trap]]` for the exact `Unlinker --list` +
`comm` recipe. Current state: **78 added, 49 colliding, 0 Origins-critical.**

- Collisions are not automatically fatal. Generic shared fx materials
  collide on every map (22–34 each) with no harm. What breaks is an asset
  the map *actively uses*.
- **There is no conditional form.** One `mod.ff`, every map.
- The only clean way to ship a map-owned asset globally is under
  **mod-private names**. Do not re-add `p6_zm_vending_diesel_magic`.

**⚠ Residual, untested:** 33 owned collisions remain, nearly all the
Electric Cherry chain from `zm_prison.ff` (73 collisions with that map).
Mob of the Dead's own Electric Cherry may render wrong. Nobody has looked.

### The sound corollary

`soundbank,zmb_tomb.all` genuinely fixed the silent Wunderfizz spin and
Electric Cherry reload on five maps — then bricked Origins, which owns that
bank. Reverted. **The sounds are silent again off Origins.** The
collision-free route is the mod's own `mod.all`: five aliases
(`zmb_rand_perk_start/_loop/_stop/_leave`, `zmb_cherry_explode`), source
audio already extracted under `BO2 Files Organized By Volkz\Sounds`, built
in Sound Studio Extended (GUI-only, so the user has to do it).

---

## 3. STILL OPEN

- **`.fly` does not fly.** Linked to a `script_origin` via `playerlinkto`;
  the player is held in place but the mover never moved. v1.21.2 switched
  to `moveto()` and added a probe printing `getnormalizedmovement()` for
  ~3s. **All zeros means input is unreadable while linked and the script
  approach is dead** — the answer is then `t6-gsc-utils.dll` in
  `Plutonium\storage\t6\plugins\` (not installed), which exposes
  `entity ufo()` / `noclip()` outright. Docs: starter kit
  `reference\docs\T6-Gsc-utils documentation.md` §4.5. There is **no**
  `noclip`/`ufo` dvar in this build — checked the 2996-dvar dump.
- **Wunderfizz sounds + Electric Cherry reload sound** — §2 corollary.
- **Two probes still in the shipped build, remove when answered:**
  `[zm_qol] box open:` in `maps\mp\zombies\_zm_magicbox.gsc`, and
  `[zm_qol] capture probe:` in `scripts\zm\zm_tomb\zm_tomb.gsc`.
- Perma-Flopper in classic Buried (`zmqol_flopper_probe`, never read).
- Gun sounds / menu music — `.agents\sound_work_notes.md`.

---

## 4. METHOD NOTES FROM THIS SESSION

- **Ship a probe instead of a third theory.** The `placed 5 of 6` line
  killed the zone-manager approach in one run; the `box open:` probe ruled
  out both silent paths at once. Both paid for themselves immediately.
- **Three confident mechanism claims were wrong** and each cost a release:
  zones discriminate by location (they do not), `scriptmodelsuseanimtree`
  clobbers other trees (it registers, cumulatively), a mod soundbank is
  free (it collides with the owning map). When writing "deliberately NOT
  doing X because Y", Y is exactly the claim to verify first.
- **The user's screenshots are evidence** — the blown-out orb glow was a
  looping fx retriggered every second, visible at a glance.
- Extracted bank contents live under `BO2 Files Organized By Volkz\Sounds`,
  named per file: the fastest way to answer "is this sound in that bank?".

---

## 5. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`, **`-m comp`**.
- OAT — `H:\Claude\oat-windows\`. `--list <ff>` is the asset audit.
- `build.bat` for `.gsc` only; `build_ff.bat` also when `zone_source`
  changes.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- Screenshots — newest file in `G:\Gallery`.
- GitHub `github.com/DavidHiFi/zm_qol`, private, tags v1.1.1 → **v1.22.0**.
