# QUEUE_LIST.md — the queue

**This is the list `/queue` prints.** One flat numbered list, in the order the items were set.
`QUEUE.md` stays the long write-up with the evidence; this is only the index.

**A ~~struck-through~~ line is FINISHED** — the user confirmed it in game — and is not being worked
on. Everything not struck through is still open. Nothing else is marked, on purpose: the user asked
(2026-08-16) for a plain list with no other differentiation.

When the user says an item is **resolved and can come off the list**, delete its line, renumber the
rest, and move it to *Closed* at the bottom of this file — never lose it, just stop printing it.

- SYNCED TO: checkpoint **75** · mod version **1.99.50**
- LAST VERIFIED: 2026-08-18 — **twenty-one items were removed across two passes this day** and the
  list renumbered twice, 29 → 19 → 8. Both passes are recorded in full at the bottom with old
  numbers, per-item detail and the old→new maps. Nothing was lost; the list stops printing them.
- BUILT, AWAITING THE USER'S BOOT: nothing.
- 🛑 **NOTHING IS IN FLIGHT.** Old 2 (the backspeed toggle) was confirmed in game and removed on
  2026-08-18; the list is 8 → 7. A new request can start immediately.
- 🛑 Three things survive their closed parent items and are **the user's call, not to-dos**:
  Who's Who on **Origins** (43 absent assets, checkpoint 75 §3), the Titus's `fly_titus_futz` /
  `fly_tar21_futz` (defined in no bank in the game), and the freezegun's non-lethal hit marker
  (measured firing on 5 of 6 paths; the 6th was never exercised).

<!-- LIST -->

1. **`.character N` does nothing on survival**, and the CDC/CIA picker — needs your call
2. **Prone at Mob's Electric Cherry machine gives no +100**
3. **Death Machine pickup voice line** — the BO1 announcer callout
4. **Drop `deathmachine_zm.all.sabl`**
5. **Jet gun in a real weapon slot**, and it never breaks
6. **Jet gun gets the Paralyzer's cooldown** so it cannot be fired forever
7. **Ammo counter for the jet gun** in the bottom right

<!-- /LIST -->

---

## Closed — off the list, kept for the record

### Closed 2026-08-18 (third pass) — one, confirmed in game

Old **2** of the 8-line list → the list is now 7, old 3-8 become 1-7 (old 1 keeps its number).

| old # | item | state when it was closed |
|---|---|---|
| 2 | **GAME-tab toggle for the backspeed fix** | shipped v1.99.51 and **confirmed by the user in game** — *"the option for backspeed works toggling it on or off"*. Renamed to **BACKSPEED PATCH** in v1.99.52 at their request, dvar still `move_speed`. |

🛑 **Can it resurface?** One thing to know, so it is not debugged from scratch later: the three
movement dvars (`player_backSpeedScale` / `player_strafeSpeedScale` /
`player_sprintStrafeSpeedScale`) now have exactly ONE writer, `qol_options::qol_opt_move_speed()`.
The old unconditional `setdvar` lines in `quality_of_life::init()`'s high_round_fix block are gone.
If backward movement ever feels wrong again, that watcher is the only place to look — and note that
`zmqol_minimal 1` (the Origins bisect switch) now skips it, so under minimal the speeds stay at
stock PC values instead of being forced to 1.

### Closed 2026-08-18 (second pass) — eleven more, by the user's instruction

*"get rid of 19, 18, 17, 16, 12, 10, 11, 5, 4, 1, 2. remove all those from the queue as they are
already dealt with or i no longer require their addition to the mod."*

🛑 **The user gave a combined reason for the batch, not per item, and none was inferred.** Some of
these are built and shipping, some were never started; which is which is recorded below as fact, but
**why each was dropped is not guessed at**. Old numbers are from the 19-line list.

| old # | item | state when it was dropped |
|---|---|---|
| 1 | **Who's Who description** — joke line removed | shipped v1.98.0; verified present in the deployed `mod.iwd` 2026-08-18, never booted |
| 2 | **Wunderfizz first location is random** by default | built, never booted |
| 4 | **Galvaknuckles wall-buy in Bus Depot's Tombstone room** | never started |
| 5 | **GAME-tab toggle for the 4-perk limit** | never started |
| 10 | **PhD Flopper's HUD icon may be missing** | never confirmed to be a defect — `Could not load material` appears for ~300 stock materials, so it may never have been one |
| 11 | **`fxanim_props` animtree re-registration warning** | pre-dates v1.99.21, symmetric on Origins; a warning, not a fault |
| 12 | **Kill-feed icons missing** for the ported weapons | fixed v1.99.14 — the nine `menu_mp_weapons_*` materials ship in `mod.ff`; never booted |
| 16 | **Compass** in the HUD tab | shipped v1.99.26, never booted |
| 17 | **Five-seven wall-buy removed from Origins** | shipped v1.99.39, never booted. 🛑 It is **stock Origins**, not something this mod added — removed anyway because that is what was asked |
| 18 | **BO4 MAX AMMO toggle** in the GAME tab | shipped v1.99.39, never booted; off is exact vanilla |
| 19 | **Hitmarker / crit feedback on the three BO1 wonder weapons** | fixed v1.99.47 and **measured working on 5 of 6 paths** from the log — thundergun hit+kill, tesla hit+kill, freezegun kill. The freezegun non-lethal hit was never exercised |

**Renumbering that came with it** — 19 lines to 8, no gaps:

`3→1` · `6→2` · `7→3` · `8→4` · `9→5` · `13→6` · `14→7` · `15→8`.
Old 1, 2, 4, 5, 10, 11, 12, 16, 17, 18 and 19 are gone.

### Closed 2026-08-18 (first pass) — every confirmed item, removed together

*"remove anything from the queue that is already completed and/or i've given confirmation that it's
ticked off the list because i confirmed it working."*

All ten were struck through **because the user confirmed them in game**; this pass only stops the
list printing them. Every one traces to a dated entry in `QUEUE.md`.

| old # | item | shipped | confirmed |
|---|---|---|---|
| 3 | **Titus-6 has no reload sound** — reload, empty reload, masterkey reload, and the first-raise cue when it leaves the box. Five aliases defined from the campaign's own `spl_monsoon.all` rows | v1.99.50 | 2026-08-18 *"all sound fx are working all 3 of them"* |
| 4 | **`mod.ff` ran a pre-merge copy of the mod's own script**, on every map | v1.99.22 | 2026-08-17, checkpoint 69 §6 — the 4 `replaceFunc` collision warnings gone |
| 15 | **Jet gun behaves as stock when built at the bench** | — | 2026-08-16 |
| 19 | **INSTANT PAP toggle** in the GAME tab | v1.99.30 | 2026-08-17 |
| 21 | **PERK LIMIT selector** in the pre-game lobby | v1.99.29 | 2026-08-17 |
| 23 | **Who's Who gives a Pack-a-Punched ballistic knife**, GAME-tab toggle | gun v1.99.39 · mid-down toggle v1.99.43 · revive v1.99.44 | 2026-08-18 *"that works exactly how i want it"* |
| 25 | **Awful Lawton bolts distract zombies** like a monkey bomb | v1.99.39 | 2026-08-18 *"works perfectly as expected"* |
| 26 | **The mod's own menu settings did not survive a restart** — every option row now marks its dvar archived as it is built | v1.99.45 | 2026-08-18, and by the config file itself carrying the user's own values as `seta` lines |
| 27 | **Hitmarker sounds far quieter than gunfire** — the feedback aliases were on the same compressed bus as gunfire; rerouted to stock's own hitmarker routing | v1.99.46 | 2026-08-18 *"it's good"* |
| 29 | **INSTANT NUKE toggle** in the GAME tab | v1.99.48 | 2026-08-18 *"works perfectly toggled it on or off"* |

**Renumbering that came with it** — 29 lines to 19, no gaps:

`1→1` · `2→2` · `5→3` · `6→4` · `7→5` · `8→6` · `9→7` · `10→8` · `11→9` · `12→10` · `13→11` ·
`14→12` · `16→13` · `17→14` · `18→15` · `20→16` · `22→17` · `24→18` · `28→19`.
Old 3, 4, 15, 19, 21, 23, 25, 26, 27 and 29 are gone.

📝 Two things that were part of these items and are **not** closed with them: Who's Who on **Origins**
(43 absent assets — the user's decision to make, checkpoint 75 §3), and `fly_titus_futz` /
`fly_tar21_futz`, which exist in no bank in the game and were offered and not taken.

### Closed 2026-08-17 — confirmed in game, then taken off the list

*"both the sounds & my custom menu texture i gave for you both work no problems at least not from
what i could tell. Cross them off the list."*

| old # | item |
|---|---|
| 19 | **Hitmarker hit/kill, downed and crits sound options** in the SOUND tab — shipped v1.99.31, made visible v1.99.32, spacing corrected v1.99.33. Confirmed in game at v1.99.38 |

📝 The **custom title-screen texture** (v1.99.35–38) was confirmed in the same message. It was never
a numbered line — it came in as a direct request — so there is nothing to remove for it.

**Renumbering that came with it:** `20→19` · `21→20` · `22→21`. Lines 1–18 did not move.


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
