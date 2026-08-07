# Checkpoint 20 — v1.57.5. Four working-practice rules, and the limits of this engine.

Written 2026-08-06. Supersedes checkpoint 19 (v1.55.0), 16 commits ago.
Keep 19 for §1 (the Plutonium session-mode trap) and §3 (decompiles are lossy).
Keep 18 for §5 (the Zombie Blood asset inventory, still unbuilt).
Keep 17 for §1 (measure-don't-estimate). Keep 15 for §2 (mod.ff asset ownership).
Keep 10 for §8 (custom gamemodes).

**Read §0 and §1. §1 is the reusable one and it is now enforced by files, not memory.**

---

## 0. THE SINGLE NEXT ACTION

**Boot Diner and look at the horizon.** v1.57.5 rings it with 12 fog walls.
Then work `.agents\QUEUE.md` **top down, one item at a time**.

The queue is the authority on what happens next. Do not start item 2 until
item 1 is confirmed by the user in game.

---

## 1. 🛑 FOUR RULES THE USER SET THIS SESSION — ALL FOUR ARE IN FILES NOW

These came out of real failures in this session and they are not optional.
Every one is written into `H:\Claude\CLAUDE.md` and into memory, so they
survive a context reset.

| rule | where it lives | what caused it |
|---|---|---|
| **Never ship a guess. Perfectly or not at all.** | `CLAUDE.md` top | a mismatch crash and a half-built Wunderfizz |
| **One change at a time; queue the rest.** | `CLAUDE.md`, `.agents\QUEUE.md` | three changes stacked on unverified ones, nothing attributable |
| **Pre-mortem before every hand-off.** | `CLAUDE.md` | `.fog` shipped and did nothing; user had to report it |
| **README + GitHub description must be true.** | `CLAUDE.md` | README claimed 7 survival locations; only Diner ships |

Also new: **`ERROR_CATALOGUE.md`** — every error class this project has hit,
each with the offline check that catches it. Walk it before building.

### 🌟 The pre-mortem, because it is the one that pays immediately

Before saying "boot it": assume it will FAIL, write down three ways, check
each offline. It caught two show-stoppers in one pass on the fog work —
`r_fogTweak` silently swapping half-height to 1, and the map's fog being
unreadable at runtime — either of which would have burned a boot.

🛑 **"The API exists" is NOT "the API applies here."** That single confusion
cost four boots on the fog. `setexpfog` was verified to exist and never
verified to override *volumetric* fog, and the stock call that appeared to
prove it sat inside a `/# #/` developer block that never runs in retail.

---

## 2. 🛑 ENGINE LIMITS PROVEN THIS SESSION — DO NOT RE-LITIGATE

**Every clientfield set is 32 bits.** Measured two independent ways from the
per-map dumps in `Black Ops 2 Grand Resources\T6-Data-Archive-main\ZM\Clientfields\`
(total a set with `awk '$1=="scriptmover"{s+=$4}'`):

| set | Origins classic | note |
|---|---|---|
| `scriptmover` | **32 / 32 — zero free** | highest of any map in the game |
| `actor` | 31 / 32 | |
| `toplayer` | 61 / 64 | 64 is *inferred*, not proven |

That also retro-explains checkpoint 17's unexplained crash: Vulture's 2-bit
actor field ate the last free bit, so stock's 1-bit `zone_capture_zombie`
errored with our name nowhere in it. **The field named in an "out of space"
error is whichever asks LAST.**

**Fog DISTANCE cannot be changed on this build.** Four mechanisms, all no-ops:
`setexpfog`, `setvolfog` (the map's own call), the `r_fog*` tweak dvars via
`setclientdvar`, and **the same dvars typed straight into the client console**.
That last one is conclusive — it was never `setclientdvar` being refused. Only
`r_fog` on/off does anything. Vision files carry only colour grading (`vc_*`),
no distances.

**mod.ff ownership collisions are harmless when the assets are IDENTICAL.**
Checkpoint 15's rule was "owning a map's asset breaks that map". Tested by
extracting the actual materials from `zm_nuked`/`zm_tomb`/`zm_buried` and
comparing byte for byte: the shared ones are the same file. What genuinely
broke Origins at v1.22.0 was `xmodel,p6_zm_vending_diesel_magic`, whose
dependency chain pulled in 108 Origins-specific assets. **Judge a collision by
whether the copies differ, not by its existence.**

---

## 3. WHAT SHIPPED AND IS CONFIRMED IN GAME

| version | change |
|---|---|
| v1.56.4 | **Wunderfizz: Origins' real FX + bear bottle on every map.** User: *"looks perfect... basically identical to the actual wunderfizz in origins"* |
| v1.56.2 | **Tombstone everywhere — all 12 perks.** All five assets live only in `zm_transit.ff`; they now ship in `mod.ff` |
| v1.55.x | Who's Who; solo fix (`is_forever_solo_game=1` confirmed by probe) |
| — | Every classic and survival map loads |

**The 12th perk mattered:** the mod's no-perk-limit floor was hardcoded to 11.
BO2 has twelve. Diner hid it because a map with the mod's own machine raised
the cap dynamically; only maps using their own machine were capped.

---

## 4. 📉 THE WONDER WEAPONS — REVERTED, AND WHY IT IS PARKED NOT ABANDONED

Thundergun / Wunderwaffe / Winter's Howl crashed Plutonium three times with
**byte-identical dumps**: `0x80000003` at `0x129F75DB`, an engine assert with
no com error and no gsc error.

🛑 **The lesson is procedural, not technical.** The crash dump was available
after the FIRST crash and was not read until the third. Two speculative fixes
shipped in between — and being byte-identical, neither had changed anything.
**Read the dump before theorising.**

Both defects found on the way were real and are fixed in the reverted commits:
- **xanim and fx travel RAW in `mod.iwd`**, not the fastfile. The upstream
  README's claim that the per-map `anims_*.gsc` make the Linker pull xanims in
  is true only of a pipeline that COMPILES scripts; OAT stores T6 script as raw
  text and never parses it. **The zone linked with 0 errors and the game still
  crashed.**
- The merge package shipped only `fx/maps/zombie/**` and none of the 21
  `fx/weapon/**`, plus no audio for two guns and no meshes at all.

Leading unproven theory for the assert: a hard engine ceiling. The creators
ship **one weapon per mod**, never all three. Work is in `bb44073` + `0084881`.

---

## 5. THE TEXTURE PACK — AND THE TRAP INSIDE IT

2,788 upscaled textures now ship in `mod.iwd` (2.24 GB). No zone changes: a
fastfile holds only image *headers*, pixels always come from a loose `.iwi`, so
these add **zero** entries to `mod.ff` and cannot cause ownership collisions.

🛑 **The pack re-encodes particle textures and that breaks FX.**
`fxt_spark_pcloud_blue_1` is format 11 / 760 bytes in stock and format 13 /
16,448 in the pack. Of its 67 `fxt_*` files, 30 have a stock copy to compare
and **all 30 differ**. That was the cause of the dead power-up glow, missing
Ray Gun FX and blue "templar" eyes on Nuketown — **not** anything in `mod.ff`.
Those 64 are excluded from the mod and moved out of the user's loose
`storage\t6\images` override into `_disabled_particle_overrides\`.

📝 `mod.iwd` is now **gitignored** (2.24 GB would pass GitHub's limit in one
release) and `images/*.iwi` with it. The mod's own 64 images stay tracked
because gitignore does not affect already-tracked files. **A fresh clone builds
and plays but at stock texture resolution** until the pack is copied back from
`H:\Claude\Projects Sources\add textures to mod`.

---

## 6. WORKSPACE / ENVIRONMENT CHANGES

- **GitHub clones moved to `D:\GitHub\`** (`zm_qol`). GitHub Desktop needs it
  re-added. 🛑 That `zm_qol` clone is a **stale v1.18.1** and is NOT the working
  copy — the live one is still `H:\Claude\Projects Sources\zm_qol`.
  🛑 **`TestCord` was moved BY MISTAKE and should never have been touched** — it
  was not in the `GitHub` folder and is not the user's project (it is
  `TestcordDev/TestCord`, a Discord client mod that runs from
  `C:\Users\localuser\Documents\TestCord`). Moving it broke their Discord; the
  user restored it themselves on 2026-08-07. **Move exactly what is named,
  nothing a scan turns up next to it.**
- `build_ff.bat` now `--load`s `common_zm.ff` and `zm_transit.ff`, both LAST
  (first-loaded-wins), as donors for techniquesets and the Tombstone assets.
- `pack_iwd.ps1` stores `.iwi` uncompressed — already DXT-compressed, so
  deflate bought nothing and cost minutes. 2.24 GB packs in 60 s.

---

## 7. THE QUEUE

`.agents\QUEUE.md` is the live list. In flight: the Diner fog ring. Then, in
order: pause-menu UI, `night_mode 1` (renders black), `.character` (does
nothing), Origins Wunderfizz replacement, Bus Depot Galvaknuckles (survival
only), Vulture icon on the Wunderfizz, Mob Electric Cherry prone points, solo
cutscene + reward chest, Death Machine voice line, Nuketown crooked machines,
Diner teddy bears (blocked on three `.where` readings), zm_refreshed weapons.

**Fog is Diner-only.** Town, Farm and Bus Depot need their own measured
rectangles and were deliberately not guessed.

---

## 8. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`,
  `-m parse -g t6 -s pc -y <file>` (`-i client` for `.csc`). **Syntax only** —
  it passed a `.fog` command that referenced a variable the chat handler does
  not define, which would have failed silently in game.
- OAT — `H:\Claude\oat-windows\`. `--list`, `--include-assets`,
  `--model-format GLTF`, `--image-format IWI`. A fastfile's filename must match
  its internal zone name or it will not open.
- Plutonium's `dvar_descriptions.json` (under
  `Projects\Plutonium\storage\t6\plutonium\`) documents every dvar — that is
  where `r_fogTweak` / `r_fogBaseDist` came from.
- Per-map clientfield dumps: `Black Ops 2 Grand Resources\T6-Data-Archive-main`.
- **A boot's `console_zm.log` contains a full dvar dump** — use it to read real
  runtime values instead of assuming.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
  🛑 Diff "Could not load" lines against a previous boot; ~90 are normal, so the
  count means nothing and only the set difference identifies what you broke.
