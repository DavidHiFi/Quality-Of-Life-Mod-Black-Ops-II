# Checkpoint 83 — v1.99.80. The texture pack, the crash it exposed, and the ipak hash rule.

Written 2026-08-19. **Supersedes 82 for status.** Checkpoint 82's boot test is still owed and is
listed again below — nothing in it was answered this session.

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.80 is deployed, hash-verified into Plutonium, and NOT booted.**

**The next action is ONE boot, and the first thing to look at is the MAIN MENU FONT.** That single
glance decides which of two paths the texture pack takes. Everything else on the boot rides along.

| this session | state |
|---|---|
| 🛑 **Load-time crash — no map could start** | ✅ **FIXED v1.99.78**, unbooted |
| Texture pack shipped by NAME (v1.99.77) | ❌ **did nothing** — user booted it and reported so |
| Texture pack re-shipped by **ipak name-hash** (v1.99.79) | 🟡 built, hash-verified, **unbooted** |
| Search-order probe (v1.99.76) | ✅ deleted v1.99.80 — its premise was invalid, see §3 |
| Deadshot probes from checkpoint 82 | 🛑 **STILL UNREAD** — the crash blocked every map |
| Queue | **34 items**; item 34 is the texture pack |

**The user asked for a checkpoint and closed the terminal.** Resume signal `.` means: read §4, act on
whatever they report.

---

## 1. WHAT THE USER ASKED FOR, AND THE ONE THING THEY COULD NOT HAVE

*"i simply want my mod to come with the .iwi textures as apart of my mod ... but if someone who's
using my mod has their own custom textures in the images folder for plutonium for the same .iwi
filenames it uses their custom textures instead of mine."*

Source: `H:\Claude\ship these to the images of my mod claude` — 121 `.iwi`, 259 MB, all valid
(`IWi` + `0x1b`, DXT1/DXT3/DXT5).

🛑 **The second half is not achievable, and that is now MEASURED rather than assumed.**
`console_zm.log` prints the engine's own lookup order at startup (`Current search path:`):

| rank | path |
|---|---|
| **1** | `storage\t6\mods\zm_qol\mod.iwd` |
| 2 | `storage\t6\mods\zm_qol` |
| 3 | `storage\t6\raw` |
| **4** | `storage\t6\` ← the player's `images\` folder resolves here |
| 5-11 | `storage\t6\players`, `<BO2>\mods\zm_qol`, `<BO2>\usermaps`, `storage\t6\main`, `<BO2>\main`, … |

Anything the mod ships is rank 1-2; the player's folder is rank 4. **No mod-shipped file can rank
below it.** The only writable slots that do are `storage\t6\main` (8) and `<BO2>\mods\zm_qol` (6),
both manual installs. The user was shown this, reaffirmed the request, and the pack shipped — that
decision is theirs and is recorded in QUEUE.md item 34.

This retro-confirms `MOD_CATALOGUE.md` §11a, which `QUEUE.md:3434` had flagged as never verified.

---

## 2. 🌟 THE FACT WORTH KEEPING FOREVER — T6 HAS TWO LOOSE-IMAGE PATHS

v1.99.77 shipped 118 `.iwi` **by name** into `mod.iwd\images\`. The user booted it: *"none of the
textures worked."* Correct, and here is why.

- **By NAME** — `images\<name>.iwi` supplies pixels **only for images that are in no `.ipak`.** That
  is why this mod's own invented images (the Vulture markers, its camos, its fx textures) have
  always worked that way, and why nobody noticed the rule.
- **By HASH** — stock textures stream from the `.ipak` archives, which are indexed by a 32-bit
  **name hash**, not by name. A replacement must be named `<decimal name-hash>.iwi`.

**End-to-end proof, not inference:** `1111625965.iwi` — a file from the user's *own* installed
texture pack — is hex `424210ED`, which is the name hash of `playlist_single_ctf`, and that hash is
present in a real ipak index.

**The measurement:** every `.ipak` in `zone\all` parsed → **32,200** unique name hashes.
**119 of the 121** pack files are in that set. `gamefonts_pc_720` is in none (ships by name);
`hud_tact_insert_32` is absent from the name database (ships by name as a fallback).

ipak format: magic `KAPI`, `u32` version `0x00050000`, `u32` size, `u32` section count; 16-byte
sections `{type, offset, size, item_count}` (1 = index, 2 = data); 16-byte index entries
`{data_hash, name_hash, offset, physical_size}`. Name→hash:
`H:\Claude\T6-iPak-Unpacker\iPak_Utils\image_names.csv` (10 MB, `name_hash,name,source`).

🛑 **Correction to checkpoint 42, which mattered:** *"mod.ff bakes pixel data for 208 images"* is
**wrong**. A fastfile stores no image pixels at all. `Unlinker --include-assets image` prints
`ERROR: Could not find data for image X` and then `Dumped image X` — the error is the fastfile; the
dump came from a loose `.iwi` on the Unlinker's search path (dumped byte sizes match the pack files
exactly, +128 for the DDS header). **No image is un-overridable for that reason.** Saved as agent
memory `t6-ipak-hash-named-image-overrides`.

### What v1.99.79 actually ships

- **119** files as `<decimal hash>.iwi`
- **2** by name (`gamefonts_pc_720`, `hud_tact_insert_32`)
- by-name copies of the **20** names `mod.ff` declares (61 MB) — those also resolve through the
  mod's own asset record, so they get both chances
- **3 deliberately NOT taken:** `loadscreen_zm_hellcatraz`, `loadscreen_transit_standard_busdepot`,
  `side_small`. The mod ships its own from `zone_assets\images\`, which `build.bat` step [1/6]
  re-copies over `images\` every build anyway. `side_small` is the sharp one — mod's is **8×8
  DXT5**, the pack's is **128×128 DXT3**, and `mod_tac45.zone` + `mod_wonderweapons.zone` declare
  the name.

`mod.iwd` is now **416 MB**, 380 image entries, 119 hash-named — all verified inside the *deployed*
file, not just built.

---

## 3. THE CRASH — NOT THE TEXTURES, AND IT WAS SHIPPED IN v1.99.75

The user's second screenshot: `**** 2 script error(s): Unresolved external "is_headshot" with 3
parameters ... "get_base_weapon_name" with 2 parameters in "scripts/zm/quality_of_life.gsc"`.

Two calls in the v1.99.75 BETTER DEADSHOT probe had **lost their backslashes**:

```
mapsmpzombies_zm_utility::is_headshot( ... )        -> maps\mp\zombies\_zm_utility::is_headshot
mapsmpzombies_zm_weapons::get_base_weapon_name(...) -> maps\mp\zombies\_zm_weapons::get_base_weapon_name
```

Unresolved externals resolve at **load** time, so every map died before it started. Fixed in
v1.99.78; `is_headshot( sweapon, shitloc, meansofdeath )` verified against stock
(`_zm_utility.gsc:4440`, 3 params, same order); `gsc-tool -m parse` clean; and the corrected text
was confirmed **inside the deployed `mod.iwd`** (0 mangled, 3 correct occurrences).

🛑 **The cause is a tooling hazard, not a typo: writing GSC through `sed`/shell escaping eats
backslashes.** The same thing happened to this session's `QUEUE_LIST.md` edit, where `images\xen…`
became a literal `0x0E` byte. **Edit `.gsc` with the Edit tool, never with `sed`**, and grep for
`mapsmp` before every build.

📝 The v1.99.76 search-order probe was deleted in v1.99.80: its target `xenonbutton_a` is itself an
ipak image (hash `ED4036FA`), so a by-name file could never have overridden it. The probe could not
have answered anything — §1's search-path table answers it instead.

---

## 4. THE BOOT TEST — ONE GAME, AND THE FIRST GLANCE IS THE MENU

1. **Main menu font.** Sharper/different → the hash naming works → item 34 is done and the pack can
   be written up. Identical → **the hash-named files are not being read out of `mod.iwd`**, and the
   next move is to ship the same files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead
   (rank 4, the one place this is known to work) as an optional download.
2. **A match must now start at all** — that is the v1.99.78 fix. If a script error dialog appears
   again, screenshot it; do not assume it is the same two functions.
3. **In-match textures:** a scope (ADS with any optic), the perk machines, the HUD perk icons.
   Anything rendering as noise = a mip/format mismatch on that specific file; pull that file.
4. **The checkpoint 82 Deadshot probes, still unread.** On a controller: buy Deadshot, leave BETTER
   DEADSHOT on, ~10 headshots, then read from `console_zm.log`:
   - `[zm_qol] bd probe: dvar=… perk=… bullet=… mod=… loc=… wep=… dmg=…` — whichever field reads
     `0` is the bug
   - `[zm_qol] deadshot cf: newval=… client=… initial=…` — absent entirely means the callback never
     fires; present means the engine call is the problem
   🛑 Do not change either feature before those lines are read.

---

## 5. VERSIONS THIS SESSION

| version | change |
|---|---|
| 1.99.76 | search-order probe (`images\xenonbutton_a.iwi` = a Y glyph) — later proved meaningless |
| 1.99.77 | 118 pack textures shipped **by name** — booted, did nothing |
| **1.99.78** | 🛑 **load-time crash fixed** — the two backslash-stripped externals |
| 1.99.79 | pack re-shipped as **119 `<decimal ipak name-hash>.iwi`** + 2 by name + 20 by both |
| 1.99.80 | dead probe deleted |

Committed on `main`, tag `checkpoint-83`. `mod.iwd` is gitignored, so a clone still does not build a
playable mod — the release is the only working download, and **no release has been cut with any of
this**.

---

## 6. STILL OPEN, CARRIED FROM 82

- **BETTER DEADSHOT** and **Deadshot head lock-on** — both shipped, both reported not working, both
  carry print-only probes. Unread.
- **AIM ASSIST row** on CONTROLS > GAMEPAD — built, unbooted. Its dvar caveat (the dump was a
  mouse-and-keyboard session) is still worth checking in a gamepad log.
- **The jet gun overheat crash test** — overheat it and let it cool.
- 🛑 **GitHub release `v1.99.21` cannot start a map** and is still downloadable. Deleting or
  annotating it is the user's decision.
