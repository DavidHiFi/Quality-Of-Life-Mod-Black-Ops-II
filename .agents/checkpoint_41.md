# Checkpoint 41 — the Pack-a-Punch crash, root-caused and CONFIRMED FIXED. v1.89.5 → v1.89.7.

Written 2026-08-13. **Supersedes 40 for status.** Keep 40 §2 (one alpha owner per hudelem) and
§4 (measure two HUD points, never one and a theory); 39 §2; 38 §2/§4; 37 §1/§4; 36 §1–§2; 35 §7;
34 §1–§2; 33 §1/§5; 32 §1; 31 §1–§2; 30 §3/§5; 29 §2–§3; 28 §1; 24 §2a/§2c; 23 §2; 22 §4–§5;
21 §2–§3; 20 §1–§2; 19; 18 §5; 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **PaP crash on a ported weapon** | ✅ **FIXED AND USER-CONFIRMED.** Vector packed and fired on Bus Depot, no crash |
| Vulture Aid on Bus Depot | ✅ confirmed by screenshot — its box/PaP markers are drawn |
| Tombstone absent in solo | ✅ confirmed — 11 perks on the HUD, which is 12 minus Tombstone |
| **White Peacekeeper** | 🟡 fixed v1.89.7, deployed, **never booted** |
| **SIG556 GL / SA58 select-fire** | 🟡 fixed v1.89.6, deployed, **never booted** |
| 9 kill-feed icons, reload sounds | ❌ open, cosmetic. Now stated in the README |
| ~66 MP HUD materials logging "could not load" | ❌ open, unassessed. Arrived with v1.88.0's MP link |
| Titus-6 | 🔁 **"permanent" drop RETRACTED.** Blocked on a user decision — QUEUE.md |
| `qol_perf_probe 1` | 🛑 still never run |
| The whole v1.82–v1.88 backlog | 🛑 **still never booted** — timers, `.hud on/off`, console dvars, Origins dial + capture-meter probe |

---

## 1. 🌟 THE PAP CRASH — FOUR VERSIONS OF WRONG FIXES, THEN THE LOG SAID IT PLAINLY

v1.89.1 → v1.89.4 each shipped a plausible fix and each failed. The answer had been printed at
**map load** in every one of those boots:

    Couldn't find attachmentunique 'au_mp7_dualclip'
    ... 13 lines, exactly the 13 the nine upgraded defs name, and ZERO for the 89 stock ones

**Only the upgraded def of each pair carries `attachmentUniques`.** So a Pack-a-Punched weapon was
built pointing at a record that did not exist and the first shot dereferenced it — `0xC0000005`,
no GSC error, log ending mid-line. The user's report pinned it exactly: *packs fine, dies the
instant you shoot.*

🛑 **WHY v1.89.1 FOUND THE RIGHT FILES AND STILL FAILED.** It put all 13 in the raw
`attachmentunique\` folder and verified them inside the deployed `mod.iwd`. Both true, both
irrelevant: **`attachmentunique` is a FASTFILE-ONLY asset class.** They are still in `mod.iwd`
today and the engine could not see them. `mod_base.zone` declares 91 `attachmentunique,` lines;
`mod_locations.zone` declared none.

🌟 **THE TRAP THAT MADE THE WRONG ANSWER LOOK RIGHT:** 89 stock `au_*` files sit in that raw folder
and nothing is broken — because stock resolves them from **its own fastfile** first, so those raw
copies have never once been loaded. **A folder full of working-looking files is not evidence that
the folder is a load path.** Now ERROR_CATALOGUE §11 and [[t6-fastfile-only-asset-classes]].

🌟 **CONFIRMING A MISSING-ASSET DIAGNOSIS FROM THE LINK, BEFORE BOOTING.** Declaring 13 assets added
**110** — the fast-mag xmodels, the holo sight, the DBAL, 64 attachment viewmodel anims. Everything
a packed weapon needs hangs off the attachmentunique node. **If a declaration pulls in a dependency
chain, the assets really were absent. If it adds exactly N, doubt the diagnosis.**

---

## 2. THE METHOD THAT ACTUALLY FOUND IT — DIFF THE LOG, DO NOT COUNT IT

A normal boot logs **300+** `Could not load` / `Couldn't find` lines. The absolute count is noise.
**Only the set difference against an older boot names what you broke.**

    grep -ioE "(could not load|couldn't find) [a-z]+ [\"']([^\"']+)[\"']" <log> | sort -u
    comm -13 old.txt new.txt

That one pipeline produced the 13 attachmentuniques, and then — on the very next boot — the two
alt-weapon lines in §3. Same technique as checkpoint 40's fx hunt; it has now paid off twice.

📝 Also settled this round: **the crash `.txt` dumps are worthless here.** All four of 2026-08-13
share exception address `0x009539BE`, and one names `playerhealthregen` as "last gsc pos" on a
crash that had nothing to do with it. It is wherever script happened to be, not the cause.

---

## 3. THE FIX EXPOSED THE NEXT BUG — `altWeapon` POINTED AT MULTIPLAYER

Making the engine read the 13 produced two lines that had **never appeared in any earlier log**:

    Could not load weapon "gl_sig556_mp"
    Could not load weapon "sf_sa58_mp"

Only 2 of the 13 carry a non-empty `altWeapon`, and both name **MP's** weapon, because that is
where the asset was extracted from. The packed SIG556's grenade launcher and the packed SA58's
select-fire pointed at nothing. `gl_sig556_upgraded_zm` / `sf_sa58_upgraded_zm` shipped in v1.88.0,
are `Loaded weapon:` in the log, and are `include_weapon`'d on **both** halves — nothing referenced
them. Reimagined edits exactly these two fields to exactly these two values.

🌟 **HOW TO EDIT AN ASSET THIS PROJECT HAS NO SOURCE FOR.** The Linker resolves a declared asset
from the **asset search path first**, and only then from a `--load`ed fastfile — the same mechanism
`build_ff.bat` already uses to stage `.csc` over the donor's stale copies. So the two edited files
live in `zone_assets\attachmentunique\`, the link log says **`(src: disk)`**, and the value was read
back **out of the built `mod.ff`** with `Unlinker --include-assets attachmentunique`. Never trust
the source file — the CRLF bug taught that.

📝 **What was deliberately NOT copied.** Reimagined also fills ~40 anim fields per file that MP
leaves empty. The user's packed Vector fired and rendered correctly with all 34 of its own empty,
which **proves empty fields inherit from the weapon def**. Adapt, don't bulk-copy.

---

## 4. THE WHITE PEACEKEEPER — A FASTFILE HAS NO PIXELS, AND ZOMBIES LOADS THREE IPAKS

Everything was present: all 11 materials the GLBs name, all 68 the camo names, both xmodels, the
4 images, 24 anims, and **zero log failures mentioning "peacekeeper"**. Nothing was missing from
the build, so the white had to be **pixel data**, which `mod.ff` never carries.

The boot log names the packs a zombies session loads:

    ipak base already loaded / ipak en_base already loaded / ipak zm already loaded

**The Peacekeeper is the only one of the nine that is DLC** (Revolution) — which is also exactly why
it was absent from `common_mp.ff` and had to come from `common_patch_mp.ff` in v1.88.0. The other
eight are base-game MP, so `base.ipak` has their pixels. Nothing loads `dlc1`.

**Fix:** ship the four textures as loose `.iwi` in `mod.iwd` (CLAUDE.md §8's documented mechanism).
Robust even if the ipak reasoning is off in detail — a loose `.iwi` wins regardless of which pack
lacks the bytes.

📝 **The pixels came from the workspace, not from another mod.** All four are PNGs in
`BO2 Files Organized By Volkz\Files\mp\`, carrying the exact `~-g`-mangled derived names `mod.ff`
uses. Converted with this project's own `png2dds.ps1` → `ImageConverter --t6`. Each result is
**format 01, flags 02 — the same header shape as the 41 format-1 textures this mod already ships
and that already work in game**, so the A8B8G8R8 trap did not fire.

🛑 **ipak names are HASHED.** Grepping `base.ipak` for an image name returns nothing; that is not
evidence of absence. Do not repeat that test.

---

## 5. TITUS-6 — THE "PERMANENT" DROP IS RETRACTED

Checkpoint 40 §5 declared it permanently dropped because `camo_titus6` and
`hud_monsoon_titus_arrow` "exist in no fastfile in this install". **Both are in the user's friend's
mod**, `mods\SynarxisReimagined\mod.ff` (6,913 assets), along with the models, muzzle fx, reticle
and anims; the raw defs are in its `mod.iwd`.

🛑 **Blocked on a user decision, not on assets.** Using it means `--load`ing another person's mod as
a donor, which rule 7 forbids outside Reimagined. Preferred route: ask the friend for
`zone_source\dependencies\camo_materials.ff`, the file Reimagined intends to be there and ships
empty. Full entry at the bottom of `QUEUE.md`.

**The lesson worth keeping:** "exists in no fastfile in this install" was a verdict issued from an
incomplete search. There was a fastfile nobody had looked in, sitting in the Plutonium mods folder.

---

## 6. NEXT — in this order

1. 🛑 **BOOT AND VERIFY.** Peacekeeper textured? SIG556 packed → alt-fire GL? SA58 packed →
   select-fire? They are unrelated subsystems, so one boot attributes cleanly.
2. 🛑 **THEN THE v1.82–v1.88 BACKLOG, STILL NEVER BOOTED** — timers, `.hud on/off`, a console
   command, TranZit classic, Diner's 12 perks, and Origins with a generator captured (send
   `console_zm.log` **and** `mods\zm_qol\games_mp.log` for the capture-meter probe).
3. Ask the friend about `camo_materials.ff` → unblocks the Titus-6.
4. The two open cosmetics: 9 kill-feed icons, reload-sound notetracks.
5. Assess the ~66 MP HUD materials that started logging with v1.88.0.
6. 📥 `qol_perf_probe 1` — still never run.
