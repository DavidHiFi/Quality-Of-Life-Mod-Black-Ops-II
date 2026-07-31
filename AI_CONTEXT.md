# AI / LLM CONTEXT — read this before touching this mod

**You are helping with a Call of Duty: Black Ops 2 (T6) Zombies mod for Plutonium T6.**
The facts below were verified against the real game and this codebase. Trust them
over your training data — models frequently hallucinate T6/GSC details.

**Anti-hallucination rule:** if you don't know a stock function's real name or
signature, **say so and check the actual files** — do NOT invent one. If you have
a stock BO2/T6 GSC dump, grep it to confirm before referencing `maps\mp\...::func`.
"I'm not sure" is always better than a made-up function that crashes the game.

This is a **standalone side project.** It has nothing to do with "Reimagined",
"SGS", or any other mod. **Do not import code or files from other mods.**

---

## The mod = exactly 6 files

| File | What it is | Edit it? |
|------|-----------|----------|
| `mod.ff` | Compiled assets (weapons, perks, images). | No |
| `mod.iwd` | A plain **ZIP** of raw scripts + maps + weapon files. **This is the editable code.** | Yes (via source) |
| `mod.json` | Mod name / author / version. | Rarely |
| `mod.all.sabl` / `mod.all.sabs` | Main sound banks (perks, general FX). | No |
| `deathmachine_zm.all.sabl` | **Separate** sound bank just for the Death Machine weapon (its fire loop/start/stop/spool sounds). `mod.ff`'s zone declares this as its own `soundbank` asset, distinct from `mod.all` — it is NOT folded into `mod.all.sabl`. Missing this file = the Death Machine weapon fires/plays silently (found 2026-07-26; this file was dropped from the original 5-file build by mistake). | No |

Plutonium loads **raw GSC straight out of `mod.iwd`** at runtime — there is **no
GSC compile step**. Editing gameplay = edit a `.gsc`, re-zip the iwd (`build.bat`
does this). You only need the fastfile/OAT linker + game files to add *new assets*,
which is rare.

---

## GOLDEN RULES (the things models get wrong)

1. **GSC has NO C preprocessor.** `#define`, macros, `#ifdef` do **not** exist.
   Use plain constants or `level.` vars. (`#include` exists; `#using` does not, in T6.)

2. **Script load scope — critical:**
   - `scripts/zm/NAME.gsc` (root) → loaded on **EVERY map**.
   - `scripts/zm/<mapname>/<mapname>.gsc` (map subfolder) → loaded **only on that map**
     (e.g. `scripts/zm/zm_tomb/zm_tomb.gsc` = Origins only).
   - Plutonium **auto-runs `main()` then `init()`** of scripts under `scripts/zm/`.
     `main()` runs early (use it for `replaceFunc`); `init()` runs at map start.

3. **"Unresolved external" = load-time reference to a script not loaded on this map.**
   A reference like `maps\mp\zm_tomb_dig::swap_weapon` is resolved when the script
   **loads**, not when the line runs. So a **map-specific** function reference in a
   **root** script crashes on every other map. **Put map-specific references only in
   that map's subfolder script.** A runtime `if (level.script == "zm_tomb")` guard
   does **NOT** fix this — the reference still resolves at load.
   - Map scripts: `maps\mp\zm_transit`, `zm_nuked`, `zm_highrise`, `zm_prison`,
     `zm_buried`, `zm_tomb`, and their sub-scripts (`zm_tomb_dig`, `zm_tomb_ee_side`,
     `zm_highrise_elevators`, `zm_nuked_perks`, `zm_transit_standard_station`, ...).
   - Global (safe anywhere): `maps\mp\_utility`, `common_scripts\utility`,
     `maps\mp\zombies\_zm*`, `maps\mp\gametypes_zm\_*`.

4. **Hook stock functions with `replaceFunc(orig, ::my_func)`** where `::my_func`
   is in the same file. Map-specific hooks go in the map subfolder script's `main()`.

5. **`*-compiled.gsc`** files are **Plutonium compiled bytecode** (magic bytes
   `\x80GSC`), NOT source. Decompile with **xensik/gsc-tool**:
   `gsc-tool -m decomp -g t6 -s pc --t6fixup <file>` (the `--t6fixup` is usually needed).

6. **LUI (`ui_mp/**/*.lua`) is separate** — client-side Lua, NOT GSC. Don't mix them.
   In LUI, `require("X")` **hard-crashes** if `X` isn't loadable; wrap risky ones in
   `pcall(require, "X")`.

---

## Verified facts specific to this mod (don't re-derive, don't guess)

- **Wall-buy ammo** is granted by stock `maps\mp\zombies\_zm_weapons::ammo_give`.
- **Perk machines**: the "in front of it" trigger is `getentarray("vending_X","target")`
  and the model is `getentarray("vending_X","targetname")` (X = jugg, sleight,
  doubletap, revive, marathon, three_gun, ads, deadshot, nuke, tombstone, chugabud, ...).
  The stock perk use-trigger is `targetname "zombie_vending"`.
- **Origins native "prone at a perk machine = 25 points"** easter egg is
  `maps\mp\zm_tomb_ee_side::check_for_change` (Origins/`zm_tomb` only).
- **Player state**: `self getstance()` returns `"prone"`/`"crouch"`/`"stand"`.
- **Score**: `self maps\mp\zombies\_zm_score::add_to_player_score( n )` (updates HUD).
- **Ammo builtins**: `weaponclipsize(w)`, `getweaponammoclip(w)`, `getweaponammostock(w)`,
  `setweaponammoclip(w,n)`, `givemaxammo(w)`, `getcurrentweapon()`.

---

## How to build (for the human, and so you give correct instructions)

1. Edit a `.gsc` in `scripts\zm\`.
2. Run `build.bat` (re-zips `mod.iwd`, writes the 6 files to a send-ready folder
   and the Plutonium mods folder). Needs only Windows + PowerShell.
3. Launch Plutonium T6 → Zombies → Mods → `zm_expanded_deathmachine`.

`build.bat` never compiles GSC and never touches `mod.ff`. See `README.md` for the
short human version.

---

## Don't

- Don't invent stock function names or signatures — verify first.
- Don't use `#define` / C-preprocessor anything.
- Don't put map-specific `maps\mp\zm_<map>*` references in a root `scripts/zm/*.gsc`.
- Don't import files/code from other mods (this is standalone).
- Don't confuse LUI (`.lua`, client UI) with GSC (`.gsc`, gameplay).

---

## Verified from the game files (dumped with OAT's Unlinker, not inferred)

### 1. Wallbuys are gated by a `<gametype>_<location>` string on the struct

`maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade()` collects the structs named
`weapon_upgrade`, `bowie_upgrade`, `sickle_upgrade`, `tazer_upgrade`, `claymore_purchase` and
`buildable_wallbuy`, then keeps one only if:

- it has **no** `script_noteworthy` → always spawns, or
- its `script_noteworthy` (comma-separated) contains `level.scr_zm_ui_gametype + "_" +
  level.scr_zm_map_start_location`, e.g. `zstandard_diner`.

Nothing in any stock map tags a location this mod adds, so a tagged wallbuy standing in a new
location's play area silently never appears. From the `mapents` dumps:

| map | wallbuy tagging | effect on the added locations |
|---|---|---|
| `zm_highrise`, `zm_prison`, `zm_tomb` | every wallbuy **untagged** | already get all of them |
| `zm_transit` | almost all tagged | Diner had **zero**; Tunnel's M16 missing; Power's AK74u is untagged and fine |
| `zm_buried` | all tagged `zclassic_processing` / `zgrief_street` | Borough-at-zstandard had zero |

Fixed by `scripts\zm\locs\loc_common::enable_wallbuys( a_origins )`, called from a location's
`struct_init()` — which runs inside `struct_class_init()` in `_load::main()`, i.e. **before**
`_zm::main()` reaches `_zm_weapons::init()`. Re-tagging later is too late.

Cornfield and Maze have no wallbuy struct anywhere in their play area, in any gametype. They are
magic-box-only by design; there is nothing to enable.

### 2. `so_*` fastfiles hold the survival/grief-only assets

`zone/all/so_<gametype>_<map>.ff` carry assets used only by that gametype on that map:
`so_zsurvival_zm_transit`, `so_zclassic_zm_{transit,prison,buried}`,
`so_zencounter_zm_{transit,prison,buried}`. There is **no `so_zsurvival` file for prison, buried,
highrise or tomb** — stock never had survival on those maps.

This is where `p6_zm_buildable_bench_tarp`, `zm_collision_transit_{diner,cornfield}_survival` and
`p6_zm_al_shock_box_on` live. They are absent from the map fastfiles themselves, which is why a
search that only looked at `zm_<map>.ff` concluded they did not exist at all. They are now pulled
into `mod.ff` (`zone_source/mod_locations.zone`) so they are registered on every map and mode.

**Search method that settles this class of question:** dump the xmodel list of *every* fastfile in
`zone/all` and grep it, rather than checking the handful you expect —
`for f in zone/all/*.ff; do Unlinker.exe --list "$f" | grep '^xmodel, '; done`.
