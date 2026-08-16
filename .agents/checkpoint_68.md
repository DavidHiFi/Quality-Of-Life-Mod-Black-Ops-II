# Checkpoint 68 — v1.99.21. The stale `mod.ff` scripts are gone. 29 script assets → 16, zero `.gsc`.

Written 2026-08-16. **Supersedes 67 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.21 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | ~~Who's Who~~ · ~~Tac-45~~ · ~~Winter's Howl~~ · ~~Riser sound~~ · ~~Origins crash~~ · ~~invisible corpse~~ · ~~clone glow~~ | ✅ **CLOSED.** 🛑 Do not re-open. |
| 2 | **`mod.ff` stale scripts** | 🟡 **fixed, unbooted.** §1–§3 |
| 3 | Who's Who **description** | 🟡 built v1.98.0, never booted |
| 4 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 5 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 6 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 7–13 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 THE VERIFICATION IS A GREP, NOT A PLAYTHROUGH
Boot **any** map, quit, then search `console_zm.log` for `WARNING`. These four lines were there at
**every** map load and must now be **gone**:

```
WARNING: overriding server replaced func maps/mp/zombies/_zm_perks::perks_register_clientfield;
         scripts/zm/zm_expanded::perks_register_clientfield with scripts/zm/quality_of_life::...
         ... init_client_flags ... give_perk ... default_vending_precaching
```

Nothing should look or play differently. **If anything does, that is the finding** — say what.

---

## 1. WHAT WAS WRONG, AND THE LOG SAID SO IN THREE LINES

`console_zm.log` records where every script came from. It is unambiguous:

```
Script source "scripts/zm/zm_expanded.gsc" loaded successfully from fastfile
scripts/zm/zm_expanded.gsc (mod (source)): 0x6B419E9F
GSC Executed "scripts/zm/zm_expanded::main()"
GSC Executed "scripts/zm/zm_expanded::init()"
```

`zm_expanded.gsc` is the **pre-merge module that became `quality_of_life.gsc`** and was deleted from
the project months ago. `mod_base.zone` still declared it, so the Linker resolved it from the donor
fastfile and **every build re-shipped July's copy** — which then ran, in full, on every map, alongside
the current script, costing four `replaceFunc` collisions at every load.

🌟 **`grep "loaded successfully from" console_zm.log` is the whole diagnostic.** Every other `.gsc`
reads `from raw` (mod.iwd's current copy); this one read `from fastfile`. One grep, no theory.

## 2. THE AUDIT BEFORE REMOVING IT — every part, and where it lives now

A script that has been executing on every map for months does not get deleted on the strength of its
name being obsolete.

| what `zm_expanded.gsc` did | covered by |
|---|---|
| 4 `replaceFunc` hooks | `quality_of_life`'s, which already win — the WARNING lines name the winner |
| `perks()` — map gate + 4 `level.zombiemode_using_*` flags + `enable_divetonuke_perk_for_level()` | `quality_of_life::perks()` — **the same block**, same gate, same flags, same call |
| **82** `precacheitem` | all 82 present in `quality_of_life` (which has 83) — `comm` against both sorted lists, empty difference |
| `level.player_too_many_weapons_monitor_func` | `quality_of_life:547` |
| `level._zombie_*`, `solo_*`, `disable_deadshot_clientfield` | set inside `init_client_flags`/`perks_register_clientfield`, which never run (overridden) — and set by `quality_of_life` regardless |

**Nothing is lost.**

## 3. THE OTHER TWELVE, AND WHY THEY WENT TOO

Each reads `loaded successfully from raw`, so mod.iwd's copy wins **while a file of that name exists
on disk** — they were inert. But:

- **12 of the 13 shipped `.gsc` were measurably stale**, some wildly: `zm_tomb.gsc` was **4.6 KB** in
  the fastfile against **93 KB** on disk.
- they were the same trap one rename away from springing. That is precisely how `zm_expanded` got
  here — a file was removed and its declaration was not.

🛑 **Checked first that all twelve exist in the deployed `mod.iwd` at their current sizes**, so
removing a declaration could not orphan a live script.

**Every `.csc` stays.** Client scripts genuinely do load from the fastfile (same log:
`_zm_weap_freezegun.csc ... from fastfile`) and `build_ff.bat` stages current sources over them.
16 ship; 14 are byte-identical to source. The two with no source —
`_zm_perk_divetonuke.csc` and `_zm_perk_electric_cherry.csc` — are **deliberate stock re-ships** so
those perks have a client half on maps that never shipped one. 📝 Not leftovers; do not "clean" them.

## 4. THE FIX HAD TO GO IN THE GENERATOR, NOT THE FILE

`zone_source\mod_base.zone` is **generated** (`build_ff.bat regen`). A hand edit would have been
silently undone the next time anyone regenerated it — the trap checkpoint 67 §3 flagged before any
editing started. So `regen` now strips `script,*.gsc` itself and reports the count. The hand-edited
file and the generator now agree, and cannot drift.

This project never needs a `.gsc` in the fastfile: Plutonium's Mods menu runs raw `.gsc` straight out
of `mod.iwd`, which is how `quality_of_life.gsc` works while being declared in no zone file at all.

## 5. RESULT

| | before | after |
|---|---|---|
| script assets in `mod.ff` | 29 | **16** |
| `.gsc` | 13 | **0** |
| `.csc` | 16 | 16 |
| `mod.ff` size | 26,046,976 | 25,978,816 |

## 6. METHOD NOTE WORTH KEEPING

🌟 **The log already knew.** `loaded successfully from fastfile` vs `from raw`, and the
`(mod (source))` vs `(raw (source))` checksum lines, answer "which copy of this script is actually
running" directly — a question this project has previously answered by reasoning about load order.
Added to [[t6-modff-runs-stale-gsc]].
