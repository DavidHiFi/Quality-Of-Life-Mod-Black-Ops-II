# Checkpoint 84 — v1.99.81. Why the texture pack cannot ship the way we assumed, measured end to end.

Written 2026-08-19/20. **Supersedes 83 for status.** Checkpoint 83's whole texture theory
(`<decimal ipak name-hash>.iwi`) is **DISPROVEN** here — see §2. Do not act on it again.

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.81 is deployed, hash-verified into Plutonium, and NOT booted.**

**The next action is ONE boot, and it answers the last unmeasured question in the texture work.**

| this session | state |
|---|---|
| ✅ **BETTER DEADSHOT** | **CONFIRMED WORKING BY THE USER** 2026-08-19 — *"it does more damage when set to enabled"*. Close it. |
| 🛑 Texture pack by ipak **name-hash** (v1.99.79) | ❌ **disproven** — the naming theory was wrong, see §2 |
| 🛑 Texture pack in the **mod's own folders** (ranks 1, 2, 6) | ❌ **booted, nothing loaded** (user, 2026-08-19) |
| 🟡 Speed Cola at **rank 4** + an **ipak-path log probe** (v1.99.81) | built, deployed, **unbooted** — §4 |
| Deadshot **head lock-on** | still not working, probe still unread |
| Queue | **34 items**; item 34 is the texture pack |

The user's requirement, restated by them verbatim this session and unchanged:

> *"i want people who downloaded my mod and put it in their mods folder have textures so long as
> they dont already have textures for the files in their own images folder."*

They also said: only declare it impossible **if 100% certain beyond a shadow of a doubt**. §4 is the
one measurement still missing before that sentence may be written. **Do not write it early.**

---

## 1. THE SOURCE FOLDER GREW

`H:\Claude\ship these to the images of my mod claude` is now **131 `.iwi`, 260 MB** (was 121; the
user added 10 reticles mid-session: `c4_reticle`, `center_cross`, `flechette_reticle`,
`hatchet_reticle`, `hud_flamethrower_reticle`, `knife_ballistic_reticle`, `m203_reticle`,
`reticle_side_round01`, `tactical_gren_reticle`, `tank_reticle`).

**129 of the 131 are inside a stock `.ipak`.** Only two are not: `gamefonts_pc_720` and
`hud_tact_insert_32`. That ratio is the whole story of this session.

Measured with the ipak index parser (kept at
`%TEMP%\claude\H--Claude\<session>\scratchpad\ipakset.ps1`): every `.ipak` in `zone\all` →
**32,200** unique name hashes; names resolved through
`H:\Claude\T6-iPak-Unpacker\iPak_Utils\image_names.csv`.

---

## 2. 🌟 THE MECHANISM, MEASURED — AND CHECKPOINT 83 CORRECTED

Checkpoint 83 said stock textures need `<decimal name-hash>.iwi`. **That is wrong.** The evidence
against it was sitting in the user's own machine and in this repo:

- The **pack's own filenames are the real T6 asset names**, prefix mangling and all
  (`~-gzombie_vending_jugg_col.iwi`, `~~-gzombie_vending_marathon_s~26747f4f.iwi`). So does the
  user's own installed loose-texture set in `storage\t6\images\` (`~-gviewarm_zom_engineer_c.iwi`).
  Nothing anywhere is named by a decimal hash.
- Truncated `~<8 hex>` names are genuine asset names — this project already **declares** them in its
  own zone files (`image,~mtl_t5_wpn_zmb_thundergun_ao-rgb&~12c9c97d`).

### What is actually true (all of it measured this session)

1. **A T6 fastfile carries NO image pixels.** `Unlinker --include-assets image` on `mod.ff`, run in
   an isolated folder with no loose `.iwi` reachable: **1191 errors, zero images dumped.**
2. **The Linker never bakes pixels either — not even from disk.** A one-image zone
   (`image,~-gzombie_vending_jugg_col`, a 4,194,368-byte source) links to a **192-byte** fastfile.
   Linked the same image from stock `zm_transit.ff` instead: **also 192 bytes**. Both are headers.
   *So `mod.ff` can never carry a texture. That route is closed, permanently.*
3. **Loose `.iwi` DOES reach the renderer from inside `mod.iwd`** — but only for images that are in
   **no ipak**. The working precedent is this mod's own: the ported Thundergun / Wunderwaffe /
   Winter's Howl skins (**93** images in `images\` are in no ipak) render correctly and have no
   other pixel source.
4. **For ipak-backed images, every mod-side location failed:** by name in `mod.iwd` (v1.99.77),
   by hash in `mod.iwd` (v1.99.79), rank-2 `storage\t6\mods\zm_qol\images\` and rank-6
   `<BO2>\mods\zm_qol\images\` (this session). All booted, all did nothing.

**Conclusion so far: the ipak wins over loose files.** The one cell never tested is §4.

### The search path, and why rank matters (from the user's own log, two dumps)

| rank | path | |
|---|---|---|
| 1 | `storage\t6\mods\zm_qol\mod.iwd` | mod |
| 2 | `storage\t6\mods\zm_qol` | mod |
| 3 | `storage\t6\raw` | |
| **4** | `storage\t6\` | ← **the player's own `images\` resolves here** |
| 5 | `storage\t6\players` | |
| **6** | `<BO2>\mods\zm_qol` | mod, and **below** the player |
| 7-11 | `usermaps`, `storage\t6\main`, `<BO2>\main`, `main_shared`, `players` | |

🌟 **Rank 6 is the discovery worth keeping**: Plutonium puts `<BO2 install>\mods\<modname>` on the
search path *whether or not it exists*, and it sits **below** the player's `images\` folder. That is
the only known placement that both ships with a mod and loses to the player's own files — i.e. the
user's exact requirement. It is worthless only because the ipak beats it too.

🛑 **The menu is unreachable from a mod, whatever else is true.** The first search-path dump (boot)
has no mod paths at all; they appear only after `loadmod`. So menu-time art (fonts, `lui_loader`)
can only ever come from the player's global folder. `gamefonts_pc_720` changing at the menu proved
only that — it is one of the two files in no ipak.

---

## 3. WHAT IS PLACED WHERE RIGHT NOW (and how to undo it)

| location | contents |
|---|---|
| `storage\t6\images\` (the user's own) | **51 files** — 50 are theirs, untouched. The 51st is **one probe file**, `~-gzombie_vending_sleight_c.iwi`. Delete that one and the folder is back to theirs. |
| `storage\t6\mods\zm_qol\images\` | **121** pack files (rank 2) |
| `<BO2>\mods\zm_qol\images\` | **4** Quick Revive files (rank 6) |
| `%TEMP%\claude\…\scratchpad\parked\` | the 2 Speed Cola files, parked so rank 4 is the *only* source of that texture |

The copier refuses to overwrite anything the user already had, and wrote a manifest of every file it
added; the manifest was used to move all 95 back out again when the user objected to them being in
the global folder. **Nothing of the user's was ever overwritten or deleted.**

🛑 **Four pack files are deliberately never shipped** — the mod already has its own art under those
names: `loadscreen_zm_hellcatraz`, `loadscreen_transit_standard_busdepot`, `side_small`,
`hud_flamethrower_reticle`.

🛑 **`mod.iwd` still carries the 119 dead hash-named `.iwi`** (416 MB). Removing them was blocked by
the auto-mode classifier (bulk delete) and needs the user's go-ahead. They are inert, only bloat.

---

## 4. THE BOOT TEST — TWO ANSWERS, ONE GAME

1. **Speed Cola.** Its 4096×4096 texture is now the **only** pack file in the global `images\`
   folder, and the rank-2 duplicate was parked so nothing else can explain a change. Speed Cola is
   an ordinary ipak texture.
   - **Sharper** → loose CAN beat an ipak, from rank 4 only. The earlier failures are then about
     *location*, not the ipak, and the work continues.
   - **Stock** → nothing loose ever beats an ipak. Only then may the honest "cannot be done from a
     mods folder" be written, and it should be, plainly.
2. **The ipak-path probe.** `zone_source\mod.zone` now declares a **deliberately missing** ipak:
   ```
   >level.ipak_read,zm_qol_hd
   ```
   The engine prints `Zone mod is trying to find ipak zm_qol_hd in <dir>` for **every directory it
   will accept an ipak from**. Safe: stock zones already ask for `lowmip`, `common_zm` and
   `patch_all`, none of which exist, and the log just says `ipak file not found`. Read those lines
   out of `console_zm.log` after the boot.
   - If a **mod folder** appears in that list → a mod can ship its own `.ipak` and the whole thing
     is solvable. Chunk compression is LZO1X (`T6-iPak-Unpacker\src\formats\pc_ipak.cpp`), and the
     command table appears to allow **uncompressed** chunks (`compression == 0`), so a packer would
     not need an LZO compressor.
   - If only `<BO2>\zone\all` and `zone\english` appear → an ipak is a game-folder install, not a
     mod file, and that is the answer to give.
   🛑 **REMOVE the probe line from `mod.zone` once the log has been read.**

---

## 5. VERSIONS THIS SESSION

| version | change |
|---|---|
| 1.99.81 | `>level.ipak_read,zm_qol_hd` probe in `mod.zone`; `mod.ff` relinked (0 errors), deployed and hash-verified |

`build_ff.bat` then `build.bat`, both from PowerShell. `mod.ff` source-vs-deployed hash: **match**.

---

## 6. STILL OPEN, CARRIED FORWARD

- **Deadshot head lock-on** — shipped, not working, probe unread. Needs a controller, Deadshot
  bought, ~10 headshots, then the `deadshot cf:` lines. (BETTER DEADSHOT is DONE.)
- **AIM ASSIST row** on CONTROLS > GAMEPAD — built, unbooted.
- **The jet gun overheat crash test** — overheat it, let it cool.
- 🛑 **GitHub release `v1.99.21` cannot start a map** and is still downloadable. The user's call.
- **`mod.iwd`'s 119 dead hash-named images** — awaiting the user's OK to delete.
