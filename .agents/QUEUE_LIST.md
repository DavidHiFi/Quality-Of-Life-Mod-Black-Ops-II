# QUEUE_LIST.md — the queue

**This is the list `/queue` prints.** One flat numbered list, in the order the items were set.
`QUEUE.md` stays the long write-up with the evidence; this is only the index.

**A ~~struck-through~~ line is FINISHED** — the user confirmed it in game — and is not being worked
on. Everything not struck through is still open. Nothing else is marked, on purpose: the user asked
(2026-08-16) for a plain list with no other differentiation.

When the user says an item is **resolved and can come off the list**, delete its line, renumber the
rest, and move it to *Closed* at the bottom of this file — never lose it, just stop printing it.

- SYNCED TO: checkpoint **69** · mod version **1.99.22**
- LAST VERIFIED: 2026-08-17 — every line below was re-checked against `checkpoint_69.md` §0, the
  bottom of `QUEUE.md`, and the source tree on this date.
- BUILT, AWAITING THE USER'S BOOT: **1, 2, 14**.  Built ≠ done, so they are **not** struck through.
- **4 is now struck** — confirmed in game on the 2026-08-17 Origins boot (checkpoint 69 §6). It is
  left on the list because only the user removes an item.
- **14 was missing from this list entirely** and was added 2026-08-17. It is tracked in
  checkpoint 68/69 §0 and in the README's Known issues, and was never a numbered line; it is not a
  new request. It traces to a checkpoint, per rule 5.
- **3 Titus-6 reload** — the earlier "not possible" verdict is **RETRACTED**; it is a bank job and is
  scoped in `QUEUE.md`. The **box pickup/raise sound** belongs to the same pass.

<!-- LIST -->

1. **Who's Who description** — the joke line removed
2. **Wunderfizz first location is random** by default
3. **Titus-6 has no reload sound**
4. ~~**`mod.ff` runs a pre-merge copy of the mod's own script**, on every map~~
5. **`.character N` does nothing on survival**, and the CDC/CIA picker — needs your call
6. **Galvaknuckles wall-buy in Bus Depot's Tombstone room**
7. **GAME-tab toggle for the 4-perk limit**
8. **GAME-tab toggle for the backspeed fix**
9. **Prone at Mob's Electric Cherry machine gives no +100**
10. **Death Machine pickup voice line** — the BO1 announcer callout
11. **Drop `deathmachine_zm.all.sabl`**
12. **PhD Flopper's HUD icon may be missing**
13. **`fxanim_props` animtree re-registration warning** on Origins, Mob and TranZit
14. **Kill-feed icons missing** for the ported weapons
15. ~~**Jet gun: confirm it behaves as stock when built at the bench**~~
16. **Jet gun in a real weapon slot**, and it never breaks
17. **Jet gun gets the Paralyzer's cooldown** so it cannot be fired forever

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

### Closed 2026-08-16 (fourth pass) — Who's Who, plus two that were confirmed earlier and never taken off

*"whos who is done remove it from the queue, it's fine as is im happy with it."*

| old # | item |
|---|---|
| 6 | **Who's Who has no screen fx on a down** — closed **by the user's decision**, v1.99.20. The log proves the grade is applied client-side (`CLIENT whoswho: vision -> zm_whos_who (was 'zm_transit')`); see checkpoint 67 for the one thing about it that is still unexplained and for the rest of the perk's audit, which is complete |
| 3 | **Zombie riser / dig-out sound** — confirmed in game at checkpoint 60 and never removed from the list |
| 4 | **Winter's Howl firing fx** — confirmed in game at checkpoint 63 (*"the fx are correct"*) and never removed from the list |

🛑 **3 and 4 were already closed in the checkpoints; this pass only corrects the list to match.** They
were not re-tested and must not be re-opened.

**Renumbering that came with it:**
`1→1` · `2→2` · `5→3` · `7→4` · `8→5` · `9→6` · `10→7` · `11→8` · `12→9` · `13→10` · `14→11`.
Old 3, 4 and 6 are gone.

📝 **Item 1, "Who's Who description", is deliberately still on the list.** It is a separate entry
about the perk's description text (built v1.98.0, never booted), not about the screen fx. Say the
word and it comes off too.

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

🛑 **Rewritten 2026-08-17.** This block had never been put through the fourth-pass renumbering
(`1→1 · 2→2 · 5→3 · 7→4 · 8→5 · 9→6 · 10→7 · 11→8 · 12→9 · 13→10 · 14→11`), so every ID below it
pointed at the wrong line. Mapped through, with the three closed IDs (`B-RISERSOUND`, `B-WHOWL`,
`B-WHOSWHO2`) dropped:

`2` B-WF · `3` B-TITUSRELOAD · `4` B-STALEGSC · `5` B-CHARACTER · `6` T5 · `7` B-PERKLIMIT ·
`8` B-BACKSPEED · `9` B-CHERRY · `10` §2.9 · `11` B-DMBANK · `12` B-PHDICON · `13` B-ANIMTREE ·
`14` B-KILLFEED

Bugs filed twice under different IDs are ONE line. Current aliases:
`B-DIG` / `B-RISERSND` / `B-TOWN` = `B-RISERSOUND` · `B-WFHOWL` = `B-WHOWL` ·
`B-CDC` = `B-CHARACTER`.

### Extra detail, by current number

Short enough to stay out of the list, useful enough to keep somewhere:

- **Built and deployed, waiting on a boot:** 1 (v1.98.0) · 2 (v1.97.0) · 14 (v1.99.14).
- **2** — needs a map with more than one Wunderfizz location to show anything.
- **4** — confirmed in game 2026-08-17, checkpoint 69 §6: the 4 `replaceFunc` collision `WARNING`s
  are gone and `zm_expanded.gsc` is mentioned 0 times in the log, against 2 in every prior session.
  🛑 Removing that script broke **every** map until v1.99.22 repointed the one call still reaching
  into it — checkpoint 69 §1–§3.
- **6** — left wall as you come in the outside door.
- **11** — measured redundant 2026-08-16.
- **12** — `Could not load material "specialty_divetonuke_zombies"`, twice a session, in **every**
  session including before v1.99.21, so not a regression. ~300 stock materials log the same line, so
  it is **not yet proven to be a defect** — one look at the PhD Flopper icon in game settles it.
- **13** — `Warning - re-registration of animtree fxanim_props / fxanim_props_dlc4`, server and
  client. Pre-dates v1.99.21 (yesterday's Mob and TranZit logs carry it under v1.99.20). Origins'
  pair is symmetric, which is the safe shape; Mob logged the server half without the client half.
- **14** — fixed v1.99.14: the nine `menu_mp_weapons_*` materials ship only in `code_post_gfx_mp.ff`
  and `frontend.ff`, which no zombies map loads, so nine of them now ship in `mod.ff`. Never booted.

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
