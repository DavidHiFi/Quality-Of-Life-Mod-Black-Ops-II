# Checkpoint 36 — the wonder weapons SHIP AND WORK. v1.69.9 → v1.74.2.

Written 2026-08-11. **Supersedes 35 for status.** Keep 35 §7 (a wallbuy's model is hidden until
first purchase) and §9's method note. Keep 34 §1 (Plutonium's loose `scripts\` folder) and §2.
Keep 33 §1 and §5. Keep 32 §1, 31 §1–§2, 30 §3/§5, 29 §2–§3, 28 §1, 24 §2a/§2c, 23 §2, 22 §4–§5,
21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **T5 wonder weapons** | ✅ **WORKING IN GAME** — all three from the box, correct names, fx, kills |
| Winter's Howl frost fx | ✅ confirmed in game (v1.74.1) |
| Wunderwaffe chain | ✅ 10 arcs, instant (v1.74.0) |
| Diner semtex wall buy | ✅ confirmed in game (v1.69.13) |
| Zombie Blood ignoreme hold (v1.68.1) | 🚧 deployed, still never booted |
| **Five items from the round-32 game** | 🔴 **queued, none started** — `.agents/QUEUE.md` |
| Frametimes | 🛑 still open, `qol_perf_probe` still never run |

---

## 1. 🌟 THE WONDER-WEAPON CRASH — the answer, after four wrong theories

**Cause: three fx were defined TWICE** — compiled inside our `mod.ff` *and* shipped raw as `.efx`
inside our `mod.iwd`: `fx_zombie_tesla_shock`, `_shock_ground`, `_shock_secondary`.
`fx_zombie_tesla_shock_ground` is precisely the fx that logged `Loaded fx:` at **line 741 of every
crashing boot**, during mod zone load, before any map script. Deleting the three raw copies fixed
it. **Nothing else did.**

### The four theories that were wrong, and why each looked right

| # | theory | why it died |
|---|---|---|
| 1 | `iwfx 2` is T5's format, not T6's | the working port ships 61 of 63 files as `iwfx 2` |
| 2 | LF line endings break the parser | converted all 27 to CRLF; crash reproduced identically |
| 3 | a missing **material** inside a loaded fx | fixed 22 of them, 0 missing; crash reproduced |
| 4 | 13 missing **techniquesets** | all 13 are in `common_zm`, which loads on every map |

🛑 **What actually found it: comparing against a SHIPPED WORKING BUILD, not source.**
`H:\Claude\Wonder_Weapons-T6ZM\wonder_wepons_zm\` is a complete mod (`mod.ff` + `mod.iwd` + 4 sound
banks) that ships **the same 63 raw `.efx`** and does not crash. Its `mod.ff` carries **zero fx
assets**; ours carried **143**. That difference is what made the double-definition possible at all —
their mod physically cannot have the collision.

📝 **The lesson worth keeping:** when a port crashes and a working build of the same port exists,
**diff the two builds' asset inventories before theorising about file contents.** Four rounds and
five boots went into content theories; the answer was one `comm -12` between two asset lists.

---

## 2. 🛑 THE PROCESS FAILURES THIS SESSION — recorded because they cost the most

1. **I read a rotating log as a fixed control.** `console_zm.log.000-.009` are ROTATING SLOTS.
   Checkpoint 35 §9's "decisive discriminator" compared crash logs against `.005`, which had been
   **overwritten by a later crashing boot** between reading it and citing it. Copy any log you
   intend to reason about out of that folder first.
2. **Log tails are buffered and are NOT the crash site.** Different boots of the same build ended
   115–142 lines apart. "Where the log ends" localises nothing.
3. **I ran `sed -i` on `build_ff.bat`** — the exact trap 34 §2 records. It stripped all 317 CRLFs.
   Caught by `tr -cd '\r' | wc -c` and restored with `git checkout --`. **Use the Edit tool on
   `.bat` files, never `sed -i`.**
4. **A wrong regex manufactured a false absence twice** — `^material, *NAME$` missed
   `material, ,NAME` (reference-only) rows, and a hardcoded GLB stride of 12 produced vertex values
   50 units outside the model's own bounds. Both were caught only because a number looked absurd.
   **Sanity-check every extraction against something you already know.**

---

## 3. WHAT SHIPPED, v1.69.9 → v1.74.2

| ver | change |
|---|---|
| 1.69.13 | Diner semtex: **yaw 270**, x −5176. The yaw was the whole bug; the position was right from the start |
| 1.70.0 | `.efx` → CRLF (necessary hygiene, not the fix) |
| 1.71.0 | 63 fx (36 were missing entirely), 22 materials substituted |
| 1.72.0 | shipped the booting configuration to establish the gun code was sound |
| 1.73.0 | **6 localize strings** (weapon names), **3 give commands**, **the duplicate-fx fix** |
| 1.73.1 | give commands routed through `_zm_weapons::weapon_give` — respects the weapon limit |
| 1.74.0 | Wunderwaffe: 10 arcs, stagger removed, idle hum off — **all three dvar-reversible** |
| 1.74.1 | **Winter's Howl frost fx** — the leak below |
| 1.74.2 | Winter's Howl base weapon announced itself as "Winter's Fury" |

### 🌟 The Winter's Howl leak — worth keeping as a pattern

`freezegun_end_all_extremity_damage_fx()` deleted the fx handles and left the **array defined**,
while its partner guards with `if ( IsDefined( ...[localclientnum] ) ) return;`. **And T6 recycles
zombie entities** — a dead zombie's entity returns to the pool carrying that client-side field. So
the failure was per-ENTITY-SLOT: frost worked until every actor in the pool had been frozen once,
then stopped for the match. **Any per-actor client state must be cleared on teardown, or it becomes
permanent for that entity slot.**

### 📝 Deliberate deviations from the port, on the user's explicit instruction

`tesla_max_arcs` 5→10, the per-arc stagger removed, `wpn_tesla_idle` off. **All three are faithful in
the source AND in the reference implementation** — they are changed only because the user twice
specified BO1/WaW parity as the target. Each is one dvar from the original: `scr_tesla_max_arcs`,
`scr_tesla_arc_delay 1`, `scr_tesla_idle_loop 1`. Under port-never-tune these would otherwise be
refused; the instruction overrides, and that is recorded so nobody "fixes" them back later.

---

## 4. NEXT — five queued items, none started

Full detail with the starting point for each in **`.agents\QUEUE.md`**. In priority order:

1. **Wunderwaffe never dropped from the box** across a round-32 legit game. Registration is
   identical across all three guns — measured, so it is NOT that. Start at the mod's own
   `maps\mp\zombies\_zm_magicbox.gsc` and diff it against stock.
2. **Stranded last zombie** at `.where` **x −6269 y −7206 z −63**. Same class as the boarded-window
   bug (checkpoint 28 / v1.63.1); use that method — `mapents` dump, find the spawner, check it
   against `disable_zombie_spawn_locations()`.
3. **Stray Vulture Aid icon** drawn detached from the perk row.
4. **Shield health bar** restacked as a white duplicate directly above the player bar.
5. **PaP camos** for the three guns — the pro7 donor `mod.ff` carries **2 `camo` assets**, check
   those first.

📝 Also still unshipped from the guns: the **over-bright Wunderwaffe view-model lights**. They live
in the raw `.efx` (`fx_zombie_tesla_tube_view*`), not in script. Do not edit those files on a
theory — this session shipped three wrong ones.
