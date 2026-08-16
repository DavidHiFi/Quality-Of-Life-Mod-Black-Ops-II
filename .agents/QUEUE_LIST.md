# QUEUE_LIST.md — the queue

**This is the list `/queue` prints.** One flat numbered list, in the order the items were set.
`QUEUE.md` stays the long write-up with the evidence; this is only the index.

**A ~~struck-through~~ line is FINISHED** — the user confirmed it in game — and is not being worked
on. Everything not struck through is still open. Nothing else is marked, on purpose: the user asked
(2026-08-16) for a plain list with no other differentiation.

When the user says an item is **resolved and can come off the list**, delete its line, renumber the
rest, and move it to *Closed* at the bottom of this file — never lose it, just stop printing it.

- SYNCED TO: checkpoint **58** · mod version **1.99.9**
- LAST VERIFIED: 2026-08-16 — every line below was checked against the checkpoints, the bottom of
  `QUEUE.md`, or the source tree on this date.
- BUILT, AWAITING THE USER'S BOOT: **1, 2, 4**.  Built ≠ done, so they are **not** struck through.
- **4 Winter's Howl** — the v1.99.7 `drawWithViewModel` fix is **CONFIRMED IN GAME**
  (*"the winters howl now has the correct shot fx"*). Still open only for the **wind**: v1.99.9
  disabled the distortion element, which a block diff proved was the Thundergun's own, scaled down.
  Unbooted.
- **3 Riser sound** — `.testsound` (v1.99.8) **answered it**: `zmb_zombie_spawn` produces no audio
  even 2D at point blank, while a matched control alias is audible in the same second. Next step is
  the payload bytes, not another theory.
- **5 Titus-6 reload** — the earlier "not possible" verdict is **RETRACTED**; it is a bank job and is
  scoped in `QUEUE.md`. The **box pickup/raise sound** belongs to the same pass.

<!-- LIST -->

1. **Who's Who description** — the joke line removed
2. **Wunderfizz first location is random** by default
3. **Zombie riser / dig-out sound is silent** — Diner, Town, Origins
4. **Winter's Howl has no firing fx**
5. **Titus-6 has no reload sound**
6. **Who's Who has no screen fx on a down** — Diner survival
7. **`mod.ff` runs a pre-merge copy of the mod's own script**, on every map
8. **`.character N` does nothing on survival**, and the CDC/CIA picker — needs your call
9. **Galvaknuckles wall-buy in Bus Depot's Tombstone room**
10. **GAME-tab toggle for the 4-perk limit**
11. **GAME-tab toggle for the backspeed fix**
12. **Prone at Mob's Electric Cherry machine gives no +100**
13. **Death Machine pickup voice line** — the BO1 announcer callout
14. **Drop `deathmachine_zm.all.sabl`**

<!-- /LIST -->

---

## Closed — off the list, kept for the record

🛑 **This section is history, not a to-do.** These are not printed by `/queue` and are not to be
worked on, re-probed or "improved" unless the user asks for that item by name. Touching a closed
item is exactly the "don't touch it when you don't need to" the user asked to prevent.

### Closed 2026-08-16 — the user reviewed the list and called these resolved

They are either already in the mod and the user is satisfied, or no longer needed. The user did not
give a per-item reason and none was inferred; the old number is kept so older notes cross-read.

| old # | old ID | item |
|---|---|---|
| 7 | — | **Instant start** (49 §1) — the Linux half stays unverified, that is accepted |
| 20 | B-CROSSHAIR | **HUD-tab toggle for the crosshair** |
| 22 | B-ROUND | **Mob round 1: the round counter is missing** from the top right |
| 24 | §2.6 | **Vulture Aid icon missing from the Wunderfizz** perk icon set |
| 26 | §2.10 | **Nuketown perk-machine placement** — Deadshot's icon at an angle, Speed Cola sunk into the back-yard ground |
| 27 | §2.8a | **Solo: Origins' first-generator chest gives Zombie Blood** instead of double points, on the classic maps |
| 28 | §2.2 | **`night_mode 1` blacks the screen out** |
| 29 | — | **Diner buildable shield** (asked 2026-08-11) |
| 30 | — | **Frametime lag from the mod** (asked 2026-08-11) |
| 32 | — | **Vulture on Origins is a compromise** — the stink pile is invisible there |
| 34 | §2.12 | **`zm_refreshed` weapon ports** (MP7, Vector, Spas-12, MGL, Jetgun, Quick Revive on Mob…) — this also settles the standing question; the answer is **no** |

**Renumbering that came with it**, so older references still resolve:

`8→7` · `9→8` · `10→9` · `11→10` · `12→11` · `13→12` · `14→13` · `15→14` · `16→15` · `17→16` ·
`18→17` · `19→18` · `21→19` · `23→20` · `25→21` · `31→22` · `33→23`. Lines 1–6 did not move.

### Closed 2026-08-16 (later the same day) — confirmed in game, then taken off the list

| old # | old ID | item |
|---|---|---|
| 1 | — | **Power-up timers** — countdown above the power-up icons, Death Machine included. Confirmed in game at v1.99.3 (*"ok it works now"*); the user's own icon artwork shipped at v1.99.4. Struck through first, then removed on their instruction |

**Renumbering that came with it:** every line moved up by one —
`2→1` · `3→2` · `4→3` · `5→4` · `6→5` · `7→6` · `8→7` · `9→8` · `10→9` · `11→10` · `12→11` ·
`13→12` · `14→13` · `15→14` · `16→15` · `17→16` · `18→17` · `19→18` · `20→19` · `21→20` ·
`22→21` · `23→22`.

### Closed 2026-08-16 (third pass) — the user removed eight more

*"remove 1, 2, 4, 10, 13, 14, 18, 22 get rid of all these from the queue, it's dealt with and/or
uneeded right now"*.

| old # | old ID | item |
|---|---|---|
| 1 | — | **Bleedout bar toggle** — confirmed in game at v1.99.6 |
| 2 | — | **Origins Death Machine ammo counter** — ⚠️ built v1.99.0, **never booted** |
| 4 | — | **Wonder-weapon box odds reversed** (`zmqol_box_ww_rarity`) — ⚠️ built v1.98.0, **never booted** |
| 10 | B-VIEWMODEL | **Arms and gun vanish when a horde gets close** — Origins, round 100+ |
| 13 | — | 🛑 **Origins / Mob `EXE_ERR_RELIABLE_CYCLED_OUT` crash** — see the warning below |
| 14 | T4 | **Semtex wall-buy on Bus Depot survival** — never built |
| 18 | B-CONTROLS | **Three Plutonium rows missing from CONTROLS → LOOK** — not this mod's code |
| 22 | T5 | **T5 wonder weapons** — reverted at v1.56.x, work is in git and reappliable |

**Renumbering that came with it:** `3→1` · `5→2` · `6→3` · `7→4` · `8→5` · `9→6` · `11→7` ·
`12→8` · `15→9` · `16→10` · `17→11` · `19→12` · `20→13` · `21→14`.

🛑 **FLAGGED AT REMOVAL, as the user asked — these three can resurface:**

1. **Old 13 is a CRASH, and removing the line does not fix it.** Origins and Mob of the Dead can
   still `EXE_ERR_RELIABLE_CYCLED_OUT` roughly 20–35 s into a match. It is off the list, not solved.
   If a future session sees Origins or Mob die early, this is the first thing to read — checkpoint 48
   §2 and `ERROR_CATALOGUE` §7b, **not** a fresh investigation.
2. **Old 2 and old 4 were closed having NEVER RUN.** Both ship live code (`zmqol_box_ww_rarity`, the
   Origins Death Machine ammo counter). Closed means "stop asking about it", not "verified" — if
   either misbehaves later it will look like a brand-new bug.
3. **Old 10** is a real rendering fault at Origins round 100+, never investigated. It will still
   happen; it is simply no longer tracked.

---

## Bookkeeping — not printed by `/queue`

### IDs, by current number

Kept here instead of on the lines so the printed list stays clean.

`2` B-WF · `3` B-RISERSOUND · `4` B-WHOWL · `5` B-TITUSRELOAD · `6` B-WHOSWHO2 · `7` B-STALEGSC ·
`8` B-CHARACTER · `9` T5 · `10` B-PERKLIMIT · `11` B-BACKSPEED · `12` B-CHERRY · `13` §2.9 ·
`14` B-DMBANK

Bugs filed twice under different IDs are ONE line. Current aliases:
`B-DIG` / `B-RISERSND` / `B-TOWN` = `B-RISERSOUND` · `B-WFHOWL` = `B-WHOWL` ·
`B-CDC` = `B-CHARACTER`.

### Extra detail, by current number

Short enough to stay out of the list, useful enough to keep somewhere:

- **Built and deployed, waiting on a boot:** 1 (v1.98.0) · 2 (v1.97.0) · 4's wind fix (v1.99.9).
- **4** — the muzzle **flash** half is confirmed in game at v1.99.7; only the wind is outstanding.
- **9** — left wall as you come in the outside door.
- **14** — measured redundant 2026-08-16.

### How to keep this file honest

1. **Only the user booting the game finishes an item.** "Built", "deployed", "hash-verified" all
   mean **not done** — leave those lines unstruck.
2. When the user confirms an item in game → **strike its line through in place** (`~~like this~~`)
   and note the version in `QUEUE.md`. Do not renumber for a strikethrough.
   🛑 Strike the **text only**, leaving the number outside: `1. ~~item~~`, never `~~1. item~~` —
   the second form stops the line being a list item and markdown then renumbers everything below it.
3. When the user says an item is **resolved / no longer needed** → cut it from the list, renumber
   the rest, add it to *Closed* above with its old number, and record the renumbering map.
4. When the user asks for something new → **append it at the end** with the next number.
5. Every line traces to a user request in `QUEUE.md`, `TASKS_QUEUE_01.txt`, or a checkpoint. Do not
   invent lines and do not quietly drop them.
6. Bump `SYNCED TO` when a checkpoint is written or the version changes; re-verify before printing
   if it does not match.
