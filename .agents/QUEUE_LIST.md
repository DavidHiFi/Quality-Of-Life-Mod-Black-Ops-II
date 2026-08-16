# QUEUE_LIST.md — the queue

**This is the list `/queue` prints.** One flat numbered list, in the order the items were set.
`QUEUE.md` stays the long write-up with the evidence; this is only the index.

**A ~~struck-through~~ line is FINISHED** — the user confirmed it in game — and is not being worked
on. Everything not struck through is still open. Nothing else is marked, on purpose: the user asked
(2026-08-16) for a plain list with no other differentiation.

When the user says an item is **resolved and can come off the list**, delete its line, renumber the
rest, and move it to *Closed* at the bottom of this file — never lose it, just stop printing it.

- SYNCED TO: checkpoint **53** · mod version **1.99.4**
- LAST VERIFIED: 2026-08-16 — every line below was checked against the checkpoints, the bottom of
  `QUEUE.md`, or the source tree on this date.
- BUILT, AWAITING THE USER'S BOOT: **1–6** — bookkeeping for the closing "do this now" line only.
  Built ≠ done, so these are **not** struck through.

<!-- LIST -->

1. ~~**Power-up timers** — countdown above the power-up icons, Death Machine included~~
2. **Bleedout bar toggle**
3. **Origins Death Machine ammo counter**
4. **Who's Who description** — the joke line removed
5. **Wonder-weapon box odds reversed** (`zmqol_box_ww_rarity`)
6. **Wunderfizz first location is random** by default
7. **Zombie riser / dig-out sound is silent** — Diner, Town, Origins
8. **Winter's Howl has no firing fx**
9. **Titus-6 has no reload sound**
10. **Who's Who has no screen fx on a down** — Diner survival
11. **Arms and gun vanish when a horde gets close** — Origins, round 100+
12. **`mod.ff` runs a pre-merge copy of the mod's own script**, on every map
13. **`.character N` does nothing on survival**, and the CDC/CIA picker — needs your call
14. **Origins / Mob `EXE_ERR_RELIABLE_CYCLED_OUT` crash** — needs you to boot Origins with the mod OFF
15. **Semtex wall-buy on Bus Depot survival**
16. **Galvaknuckles wall-buy in Bus Depot's Tombstone room**
17. **GAME-tab toggle for the 4-perk limit**
18. **GAME-tab toggle for the backspeed fix**
19. **Three Plutonium rows missing from CONTROLS → LOOK** — not this mod's code
20. **Prone at Mob's Electric Cherry machine gives no +100**
21. **Death Machine pickup voice line** — the BO1 announcer callout
22. **Drop `deathmachine_zm.all.sabl`**
23. **T5 wonder weapons** — reverted at v1.56.x, work is in git and reappliable

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

---

## Bookkeeping — not printed by `/queue`

### IDs, by current number

Kept here instead of on the lines so the printed list stays clean.

`6` B-WF · `7` B-RISERSOUND · `8` B-WHOWL · `9` B-TITUSRELOAD · `10` B-WHOSWHO2 · `11` B-VIEWMODEL ·
`12` B-STALEGSC · `13` B-CHARACTER · `15` T4 · `16` T5 · `17` B-PERKLIMIT · `18` B-BACKSPEED ·
`19` B-CONTROLS · `20` B-CHERRY · `21` §2.9 · `22` B-DMBANK

Bugs filed twice under different IDs are ONE line. Current aliases:
`B-DIG` / `B-RISERSND` / `B-TOWN` = `B-RISERSOUND` · `B-WFHOWL` = `B-WHOWL` ·
`B-CDC` = `B-CHARACTER`.

### Extra detail, by current number

Short enough to stay out of the list, useful enough to keep somewhere:

- **1–6** are built and deployed, waiting on a boot. Versions: 1–2 v1.99.1 · 3 v1.99.0 ·
  4–5 v1.98.0 · 6 v1.97.0.
- **15** — the Diner half of the Semtex wall-buy already shipped in v1.68; this is the Bus Depot one,
  next to the added Speed Cola.
- **16** — left wall as you come in the outside door.
- **22** — measured redundant 2026-08-16.

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
