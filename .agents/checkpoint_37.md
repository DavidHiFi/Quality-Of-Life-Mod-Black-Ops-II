# Checkpoint 37 — the five round-32 items, all built. v1.74.2 → v1.75.0.

Written 2026-08-12. **Supersedes 36 for status.** Keep 36 §1 (the duplicate-fx crash) and §2 (the
process failures — especially "copy a rotating log before reasoning about it"). Keep 35 §7, 34 §1–§2,
33 §1/§5, 32 §1, 31 §1–§2, 30 §3/§5, 29 §2–§3, 28 §1, 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3,
20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **All five round-32 items** | 🟡 **BUILT, DEPLOYED, NOT YET BOOTED** (v1.75.0) |
| T5 wonder weapons | ✅ working in game since v1.74.1 |
| Zombie Blood ignoreme hold (v1.68.1) | 🚧 deployed, still never booted |
| Frametimes | 🛑 still open, `qol_perf_probe` **still never run** |

🛑 **The user explicitly overrode the one-at-a-time rule** for this round. Five changes are in
flight simultaneously. They sit in four independent subsystems (magic box / AI spawn probe / HUD /
weapon defs) so a bad boot should still be attributable, but that is the known cost.

---

## 1. 🌟 THE BIGGEST FINDING — TWO OF THE FIVE WERE NOT WHAT THEY LOOKED LIKE

**Item 1 was not a bug at all, and item 3 was item 4.** Both were settled by measurement, and both
would have been "fixed" wrongly by going straight to code.

- **#1 Wunderwaffe.** All three guns register identically; the boot log shows all three loading with
  no error; and **the user pulled two of the three from the box in that same game**. The mod's own
  `_zm_magicbox.gsc` strips stock's three filters, making selection a uniform draw over 26 in-box
  weapons. A specific gun is 3.8%/spin → 21% chance of missing it across ~40 spins. **Variance.**
- **#3 "stray green Vulture Aid icon".** It is `shield_hud()`'s own icon, drawn on TranZit with the
  **`damage_feedback`** shader (the hitmarker), and positioned with `alignx = 240` / `aligny = 460`
  — those are STRING alignment fields, so the element landed on an engine fallback. Fixing #4
  deleted it.

📝 **The method that found both: read the log and the screenshot before reading the code.** The log
proved #1's guns were live; cropping the screenshot proved #3's icon was the shield HUD.

---

## 2. WHAT SHIPPED, v1.75.0

| # | change | file |
|---|---|---|
| 1 | `zmqol_box_wonder_weapon_weights_init/…weights()` — bounded pity weighting via `level.customrandomweaponweights` | `quality_of_life.gsc` |
| 2 | `zmqol_stranded_zombie_probe()` — prints a stuck zombie's `spawn_point` | `quality_of_life.gsc` |
| 3+4 | `shield_hud()` rewritten + `qol_shield_hud_create/_destroy()` — white bar stacked on the player bar, allocate-on-demand | `quality_of_life.gsc` |
| 5 | `camo` field filled on the three `*_upgraded_zm` defs | `weapons/zm/*` |

New dvars: `zmqol_box_wonder_weight` (default 2, `0` = stock), `zmqol_stranded_probe` (default 1).

**`build.bat` only.** Nothing in `zone_source`/`zone_assets` changed — `weapons/` rides in `mod.iwd`.

---

## 3. 🌟 #5 WAS A ONE-VALUE FIX, AND THE ASSETS WERE ALREADY THERE

`Unlinker --list` on the **built** `mod.ff` shows `camo_tesla`, `camo_thundergun` and
`camo_freezegun` all present, alongside their `mtl_*_camo` materials — they were authored and linked
in an earlier round. The three `*_upgraded_zm` weapon files simply ended with `\camo\` and **an
empty value**.

Stock's mechanism, confirmed against `ak74u_upgraded_zm` / `rpd_upgraded_zm` / `ray_gun_upgraded_zm`
in the ZM weapons dump: the upgraded def keeps the **same** `gunModel`/`worldModel` as the base and
differs **only** by `camo = camo_<weapon>`. Base defs carry an empty `camo`. So appending the name
is the whole fix, and leaving the base files empty is correct, not an omission.

Verified byte-exactly in the **deployed** `mod.iwd`: `9514 / 8559 / 7737`, tails
`\camo\camo_tesla`, `\camo\camo_thundergun`, `\camo\camo_freezegun`; the three base defs still end
`\camo\`.

---

## 4. 🛑 #2 IS A MEASUREMENT, NOT A FIX — and that is deliberate

The cause could not be established offline. Four candidate mechanisms were each checked and killed
(full list in `QUEUE.md`); the decisive negative is that **no enabled regular spawner exists within
555 units of the reported spot**, while the nearest one of any kind, 198 units away, is already
disabled. So the zombie is most likely standing where it was *blocked*, not where it spawned, and
only its own `spawn_point` can identify the source.

`self.spawn_point` is assigned in exactly one place in stock (`_zm_spawner.gsc:2674`), so the probe
reads a real field, not an inferred one.

📝 One caveat worth keeping: `do_zombie_spawn()` returns at `:2621` for a `self._rise_spot` zombie,
**before** `:2674`, so such a zombie would carry no `spawn_point`. Nothing in the stock dump ever
sets `_rise_spot`, so this should never happen — but the probe prints `spawn_point none` rather than
erroring if it does.

---

## 5. NEXT — ask for these two, in this order

1. **Boot Diner survival and play to the end of a round.** All five items are visible in one game:
   the shield bar (carry a riot shield), the PaP camos (Pack any of the three guns), the box
   weighting (round 10+), and the probe (last zombie of a round).
2. 🛑 **Run `qol_perf_probe 1` mid-game.** It is still never once run, it toggles live with no map
   reload, and it is the only thing standing between the open frametime complaint and a real fix
   instead of a third guess. Also set `developer_script 1` — it was `"0"` all last session, so per
   `ERROR_CATALOGUE.md` §8 every GSC runtime error was being swallowed.
