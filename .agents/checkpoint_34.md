# Checkpoint 34 — the T5 wonder weapon port. v1.68.0 → v1.69.8.

Written 2026-08-11, same day as 33. Supersedes 33 for status.
**Keep 33 §1 (the Survival fastfile split) and §5 (the placement lessons) — still true.**
Keep 32 §1 (frametimes unattributed), 31 §1–§2, 30 §3/§5, 29 §2–§3, 28 §1, 24 §2a/§2c, 23 §2,
22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **Zombie Blood ignoreme hold** (v1.68.1) | 🚧 deployed, never booted |
| **Semtex wall buy angle** (v1.68.1) | 🚧 deployed, never booted |
| **Diner shield / bears / semtex / PaP** | ✅ all confirmed earlier — see 33 |
| **T5 wonder weapons** | 🛑 **SHIPPED BUT GATED OFF.** Six crashes; cause not found |
| `zmqol_ww` | the bisect switch — **unset = off (default)** |
| **Frametimes** | 🛑 still open, still unattributed, `qol_perf_probe` still never run |

**Next action: `zmqol_ww 2` (thundergun only) and `zmqol_ww 4` (freeze only).** Those two never
reach the tesla init where every crash log ends. If either boots, that gun works and the port is
partially recoverable. If the DEFAULT build crashes, the assets alone are responsible — strip them
by deleting `include,mod_wonderweapons` from `zone_source/mod.zone`, one line.

---

## 1. 🛑 THE ONE THAT COST THE WHOLE SESSION — PLUTONIUM'S LOOSE `scripts\` FOLDER

`%LOCALAPPDATA%\Plutonium\storage\t6\scripts\` is loaded **globally and takes precedence over the
`.gsc` inside `mod.iwd`** — exactly like `raw\` does for `.lua`. It held **46 stale copies** of this
mod's scripts, some hours old.

**Every script fix from v1.69.3 to v1.69.6 was silently ignored.** Symptoms, in the order they
appeared and were missed:

- a dvar switch that "did nothing" (`zmqol_ww 0`)
- files deleted from the project that kept throwing their compile error
- a crash point that never moved no matter what changed

🌟 **"A switch I just added does nothing" means the gated code is not the code running.** That
symptom appeared twice before it was acted on.

**Fixed permanently:** `build.bat` step **[7/7]** reconciles that folder every build — refresh what
the project also has, delete stale files under `scripts\zm\`, never touch anything else. Idempotent
(second run reports `28 refreshed, 0 stale`).

📝 A mod's `.gsc` can be shadowed from **two** places outside `mod.iwd`: `raw\` and `scripts\`.
CLAUDE.md §3 warned about a stale copy in the mods folder; this was the same trap one directory over.

🛑 **A conclusion drawn while shadowed is worthless.** v1.69.5 "proved" the crash was asset-side
from a guns-off boot. The gate was shadowed, so the guns were never off. **That conclusion is
withdrawn**, and it is why the current default-off build is the first honest test.

---

## 2. WHAT THE WONDER WEAPON PORT ACTUALLY TAUGHT — keep all of this

| finding | how it was measured |
|---|---|
| 🌟 **Plutonium loads raw `.efx` out of `mod.iwd` at runtime.** OAT cannot read or write FxEffectDef, so this is the ONLY route for custom fx | the donor mod ships 61 `.efx` in its iwd while its `mod.ff` owns one; our 17 print `Loaded fx:` every boot |
| 🛑 **OAT does NOT walk GSC for `%anim` references.** The package's whole xanim strategy depends on that and it does not happen | declared all 24 `.gsc`, linked clean, xanim count unchanged 1549 → 1549. Declaring the 106 by name moved it to 1651 |
| 🛑 **Shipping `animtrees/*.atr` + `animstatedefs/*.asd` in `mod.ff` is dangerous.** BO2 ships none of them as rawfiles | and this project already recorded animtrees killing every map on load in v1.21.0 |
| the package cannot be linked as shipped | its raw techsets reference `technique` sub-assets it never exports; its xmodel JSONs reference meshes it never exports |
| the donor `mod.ff` is the fix for both | `--load`ed LAST so first-load-wins; supplies 17 xmodels, 13 techniquesets, `shock/electrocution.shock` |
| 🛑 **never `sed -i` a `.bat`** | it strips CRLF and `cmd.exe` then executes each line with the leading characters eaten |
| `getdvarintdefault` is NOT available everywhere | it lives in `maps\mp\_utility`; the ported root scripts include only `_zm_utility` + `_zm_weapons`. Use `getdvar` in files whose includes you do not control |
| Plutonium reports an unresolved external as a **script error dialog**, naming function/file/line | so the `0x80000003` crashes are NOT unresolved externals |

---

## 3. THE WONDER WEAPON CRASH — everything known, for whoever picks it up

**Symptom:** `A critical exception occurred! Exception Code: 0x80000003` at map load, no script
error, minidump only. Reproduced on Diner and Nuketown.

**Every crash log ends at the same line:**
```
Loaded fx: maps/zombie/fx_zombie_tesla_neck_spurt
```
That is the **final `loadfx()` in `_zm_weap_tesla::init()`**. The next statement is
`precacheshellshock( "electrocution" )`.

**Ruled out, each by measurement:**

- the raw `.efx` route — all 17 load successfully first, every boot
- missing xanims — fixed v1.69.1 (1549 → 1651), crash point unchanged
- the electrocution shellshock — `rawfile, shock/electrocution.shock` **is** in the deployed
  `mod.ff`, in the same form the donor carries it
- unresolved externals — `add_limited_weapon`, `add_zombie_weapon`, `include_weapon` are all stock
- the 65-71 `Could not load fx` lines — normal; a clean boot has 65

**Still open:** whether a `rawfile` is sufficient for `precacheshellshock`, and whether the assets
alone (gate closed) crash. The default-off build answers the second in one boot.

**Not tried yet:** `H:\Claude\Wonder_Weapons-T6ZM` — a different, self-contained port with a
**prebuilt `WW.ff`**. Portuguese README, `t6modm` toolchain. If the SRS route stays blocked, that is
the other source and it does not need any of this merge.

---

## 4. WHAT IS SHIPPED FROM THE PORT (inert while gated)

`mod.ff` 3876 → ~4188: 102 xanim, 92 image, 72 material, 30 script, 17 xmodel, 13 techniqueset,
7 rawfile, 3 camo. `mod.iwd` carries 27 `.efx`, 6 weapon defs, 3 base overrides, 3 registration
scripts. 78 sound aliases merged.

**Deliberately NOT shipped:** the 6 modified animtrees, the 6 modified animstatedefs, the 18
`anims_*.gsc`, all 34 raw techsets, all 17 raw xmodel JSONs.
`srs_ww_anims_supported()` is **forced false** — no zombie is driven into an animation state the
stock tree does not define. Cost: no wonder-weapon reaction animations.

New donor: `zone_source/ww_donor/mod.ff` (the friend's shipped fastfile, 35 MB, must keep that
exact filename).

---

## 5. 📝 THE PROCESS FAILURE, recorded because it is the point

Six user boots were spent on hypotheses. The audits this project mandates were run on **assets** but
never on the ported code's **entry points**, and never on **what the game was actually loading**.

Two checks, both cheap, would have caught nearly all of it before the first boot:

1. **List every `precache*` / `loadfx` / external call in ported code and confirm each target
   resolves.** Ten calls; one was broken.
2. **Confirm the game is running the file you just built** — no `raw\` or `scripts\` copy shadowing
   it. Now automated in `build.bat`.

And with a port this size, **ship the bisect switch first**, not after the third crash.

---

## 6. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry literal ports | ✅ DONE |
| 2 | Zombie Blood onto every map | ✅ DONE (functionality fix v1.68.1 unbooted) |
| 3 | Blood Money dropping from kills | 🚧 shipped v1.64.0, still never confirmed |
| 4 | Semtex wall buy on Diner and Bus Depot | 🚧 Diner shipped, **angle fix unbooted**; Bus Depot not started |
| 5 | Galvaknuckles wall buy in Bus Depot's Tombstone room | not started |
| — | T5 wonder weapons | 🛑 gated off, see §3 |

Governing rules: **port it, never tune it** · **one at a time** · **never ship a guess**.
