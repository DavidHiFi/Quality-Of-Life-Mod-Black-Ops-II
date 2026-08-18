# Checkpoint 79 — v1.99.61. Six fixes in one batch; one refused for lack of a mechanism.

Written 2026-08-18. **Supersedes 78 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. One version is deployed AND RELEASED but NOT BOOTED.**

The user gave a seven-part batch in one message and explicitly asked for it to be worked straight
through (*"make sure to not skip this get this done right now"*), which overrides the usual
one-at-a-time rule. It is recorded here because **six changes are unverified at once** — if the boot
goes wrong, nothing names its own cause and the first job is bisecting, not fixing.

| shipped | queue # | state |
|---|---|---|
| Prone perk bonus rewritten off `zombie_vending` | 3 + 19 | 🟡 **DEPLOYED, NOT BOOTED** |
| PERK BONUS POINTS row + `perk_bonus_points` dvar | 19 | 🟡 not booted |
| FLASH CREDITS moved to HUD, FLASH HELP added | 1 (Part C) | 🟡 not booted |
| Deadshot controller head aim-assist | 20 | 🟡 not booted |
| Scoreboard CDC/CIA emblem | 22 | 🟡 not booted |
| Nuketown sunken drop pad raised to z -66.16 | 23 | 🟡 not booted |
| **Carpenter animation** | 21 | 🛑 **NOT ATTEMPTED — see §2** |

**Released:** GitHub release **v1.99.61**, published unbooted at the user's explicit instruction
(*"checkpoint and release, then shutdown my computer I give permission"*). They were told plainly in
chat that it had not been booted.

**Next action when they return:** the boot test in §4, then Carpenter needs its two answers (§2).

---

## 1. WHAT WAS FIXED, AND THE EVIDENCE FOR EACH

**PRONE PERK BONUS — one root cause, two symptoms.** The old code enumerated sixteen hand-written
`vending_*` names and, per name, took both `getentarray(name,"target")` and
`getentarray(name,"targetname")`, deduping by name.

- 🛑 **Deadshot is tagged ASYMMETRICALLY by stock.** `_zm_perks.gsc:3050-3051`:
  `use_trigger.target = "vending_deadshot"` but `perk_machine.targetname = "vending_deadshot_model"`.
  Two strings, one machine, two dedupe buckets → **100 twice**. Every other perk uses one string for
  both, which is exactly why only Deadshot did it.
- 🛑 **Electric Cherry's model tag is `vendingelectric_cherry`** — no underscore after "vending"
  (`_zm_perk_electric_cherry.gsc:65`) — and was never in the list, so Mob paid nothing.

🌟 **The replacement asks the game instead of guessing.** `perk_machine_spawn_init()` sets, at
`_zm_perks.gsc:2878`, `use_trigger.targetname = "zombie_vending"` on **every** perk machine on every
map, before the per-perk switch and before any custom perk's `perk_machine_set_kvps` callback
(checked: Electric Cherry's does not overwrite it). PaP is filtered by `script_noteworthy ==
"specialty_weapupgrade"`, which is how stock tells it apart at `:38`. Die Rise and Nuketown reroute
via `level.override_perk_targetname` but land in the same function. One entity per machine, so the
128-unit dedupe radius that once cost Mule Kick its points on Farm is **deleted**, not narrowed.

🌟 **One award per machine per MATCH, stored on the machine** (`trig.zmqol_prone_paid`). That is
stock's semantics, not a choice: `zm_tomb_ee_side::check_for_change` threads one loop per machine and
breaks after the first successful prone. 🛑 Do not copy its *anchor* though — it hangs off
`audio_bump_trigger`, and Mob sets `level._no_vending_machine_bump_trigs = 1` (`zm_prison.gsc:133`),
so Mob has no bump triggers at all.

**DEADSHOT CONTROLLER AIM.** `init_client_flags()` set `level.disable_deadshot_clientfield = 1` on
every map; stock sets it on **Buried alone** (`zm_buried.gsc:222` + `.csc:40`). Both halves matched,
so it was symmetric and nothing ever errored — the `deadshot_perk` field simply never registered and
`_zm.csc:611 player_deadshot_perk_handler`'s `usealternateaimparams()` never ran. **The perk's
headline effect was missing on every map**, invisible on mouse and keyboard.

🌟 The fix spends **zero clientfield bits**: `perk_dead_shot` is already registered on both sides and
`_zm_perks::set_perk_clientfield()` (`:2224`) writes it 1 from `give_perk()` and 0 from
`perk_think()`'s take path — the same two functions, same frames, that used to drive `deadshot_perk`.
`zmqol_deadshot_perk_callback()` in `zm_expanded.csc` chains
`level.zombies_global_perk_client_callback` (read at CALL time, `isdefined`-guarded — stock leaves it
undefined off Buried) then runs stock's handler body verbatim. Restoring the real field would have
cost 1 `toplayer` bit on every map and Mob's headroom has never been measured.

**SCOREBOARD CDC/CIA.** `_scoreboard.gsc:17-21` hardcodes `g_TeamIcon_Allies` to `"faction_cdc"` in
zombies and reads `game["icons"][...]` only on the MP branch. Every zombies player is on `allies`, so
**stock shows a CIA player under a CDC badge about half the time** (`zm_nuked.gsc:41-44` rolls
`should_use_cia` at random). `zmqol_team_emblem_watch()` repoints it. 🛑 Grief and cleansed are
excluded — both teams are real there and the stock pair is already correct.

**NUKETOWN DROP PAD.** `zm_nuked.ff` mapents dumped with OAT. Each `zm_random_machine` struct (z 2204)
targets a landing struct which targets a `p6_zm_cratepile` blocker standing on the floor. Landing z
minus crate z, all ten pads: 2887 -3.84 · 2899 -2.00 · **2900 -11.84** · 2901 -2.00 · 2902 +0.50 ·
2903 -2.00 · 2904 -0.39 · 2905 -3.96 · 2906 +0.94 · 2907 +0.48. Three use exactly -2.00, so
`pf15_auto2900` goes to -64.16 - 2.00 = **-66.16**. Matched by position with a 4-unit tolerance, so a
different map file quietly does nothing. Stock fault; the mod fills 9 pads where stock fills 5.

---

## 2. 🛑 CARPENTER (queue 21) — REFUSED, AND WHY THAT IS THE RIGHT ANSWER

Reported by the user's friend: the barriers **snap** up instead of playing the rebuild animation.

**Everything the mod could be doing was checked and it does none of it.** No `replaceFunc` on
`_zm_powerups::init`, `start_carpenter`, `start_carpenter_new` or `_zm_blockers::replace_chunk`; no
write to `level.use_new_carpenter_func`; no write to `level.board_repair_distance_squared`; there is
no `scripts/zm/replaced/_zm_powerups.gsc`. The mod's only `_zm_powerups` hooks are `nuke_powerup` and
`full_ammo_powerup`.

🌟 **And stock genuinely snaps distant barriers.** `start_carpenter_new()` splits the list with
`get_near_boards` / `get_far_boards` on `level.board_repair_distance_squared = 562500` (= **750
units**, `_zm_powerups.gsc:76`) and hands the far half to `repair_far_boards()`, which sets every
piece straight to `"closed"` with no animation. Only boards inside 750 units go through
`replace_chunk()`, which is the only thing that animates.

**Needed from the user before anything is written: which map, and roughly how far the barriers were.**
A patch without a mechanism is a guess wearing a diff — see the 2026-08-18 line in
[[zm-qol-no-guessing-standard]].

---

## 3. THINGS THAT WILL SAVE TIME LATER

- 🌟 **`zombie_vending` is THE handle for perk machines.** Never hand-write `vending_*` lists again.
  New memory: `t6_perk_machine_enumeration.md`.
- 🌟 **A symmetric clientfield removal is invisible.** Both sides agreeing means no error and no
  feature. `disable_deadshot_clientfield` hid a dead perk for months. New memory:
  `t6_deadshot_aim_assist.md`.
- 🌟 **`level.zombies_global_perk_client_callback` is undefined in stock unless Vulture Aid loads**
  (only `Buried/clientscripts/.../_zm_perk_vulture.csc:12` assigns it). Always `isdefined`-guard.
- 🌟 **The chat key on this install is SEMICOLON**, read from
  `%LOCALAPPDATA%\Plutonium\storage\t6\players\bindings_zm.bdg` (`bind SEMICOLON "chatmodepublic"`,
  `bind Y "chatmodeteam"`, `bind Z "+talk"`). It is **not** T. Never name a key without reading it.
- 🌟 **The options-tab ceiling is 15.0 pitches, not 14.5.** 14.5 was stock's GRAPHICS tab, a
  proven-good lower bound quoted as a hard limit. SOUND already ships at 15.0 with ~27 px of clear
  air under the hint line; 15.5 is where the user actually reported a collision. HUD is now 15.0.
  The note in `optionssettings.lua` was corrected to say so.
- 📝 `toplayer` headroom is **still unmeasured**. Mob stock 50 + roughly 18 from the mod ≈ 68; Buried
  booted at ~68-69, so the ceiling is ≥69 and no more is known. This round deliberately spent zero.

---

## 4. THE BOOT TEST, IN ORDER

1. **Bus Depot survival, Deadshot machine** — prone: expect **+100 exactly once**. Prone again:
   expect **nothing**. (This is the reported bug and its regression test in one.)
2. **Mob of the Dead, Electric Cherry** — prone: expect **+100**. It paid nothing before.
3. **Options → Settings → HUD** — confirm 15 rows lay out cleanly and the last row does not touch the
   hint line or the ESC prompt. **This is the one layout risk in the build.**
4. **FLASH CREDITS / FLASH HELP** — two lines at match start; turn each off separately and confirm.
5. **GAME → PERK BONUS POINTS off** — prone at a machine: expect nothing. On Origins too.
6. **Nuketown** — scoreboard badge matches the model; and if a machine drops on the rock slope near
   the crater (x≈1624 y≈960) it should now sit on the ground.
7. **Deadshot on a controller** — the friend's test. Expect head lock-on, not upper torso.

---

## 5. RESIDUAL, UNCHANGED

`EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob (oldest live fault) · the LUI `beingAnimation` crash
fix is still unconfirmed (the jet gun has never been overheated) · published release **v1.99.21
cannot start a map** and is still downloadable; deleting or annotating it is the user's open decision.
