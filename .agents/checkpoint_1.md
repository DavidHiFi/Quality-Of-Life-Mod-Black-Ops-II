# Checkpoint 1 — perk-description HUD bug: fix applied and deployed, NOT yet verified in-game

**Written 2026-07-31.** Fix applied to `quality_of_life.gsc`, `build.bat` run successfully, deployed
to local Plutonium mods folder. **Not yet tested in-game.**

---

## 1. STATE

`CLAUDE.md` and this checkpoint workflow were just added to the project (adapted from
`H:\Claude\t6 modding starter kit\`). No gameplay code has changed. `mod.iwd`/`mod.ff` are whatever
was last built before this session.

---

## 2. WHAT'S DONE

Diagnosed a user-reported bug: on Mob of the Dead, a friend bought Mule Kick and the perk-pop-up
**icon + name animated correctly but the description line did not appear.**

Traced the pop-up code: `quality_of_life.gsc` "Vanguard Perk Animation" module, function
`perk_bought()` (~line 2587). It builds 4 HUD elements in sequence per purchase: icon, name, **desc**,
spec. `getPerkDesc("specialty_additionalprimaryweapon")` does return the correct Mule Kick text, so
the switch/case table itself is not the bug.

**Root cause found:** `counters_onplayerspawned()` (~line 647, the `counterszm` module) re-threads
`timer()`, `zombiecounter()`, and `shield_hud()` on **every** `"spawned_player"` event (i.e. every
respawn/revive), but none of those three functions ever destroy their previous HUD elements — they
just `newclienthudelem`/`createfontstring` fresh ones and loop forever. Only `first_spawn()` is
correctly guarded to run once. Result: every down+revive leaks a duplicate round-timer hudelem,
zombie-counter fontstring, and shield-durability hudelem, permanently, for the rest of the game.

This matches the reported symptom well: MOTD has frequent downs/revives; enough leaked HUD elements
over a match plausibly exhausts the client's HUD-element budget, and since `perk_bought()` creates its
4 elements in order (icon, name, desc, spec), a budget cap hit mid-sequence would explain icon+name
showing while desc silently fails.

**Fix applied 2026-07-31:** moved the three `self thread timer(); self thread zombiecounter();
self thread shield_hud();` calls inside the existing `if ( is_true( first_spawn ) )` guard in
`counters_onplayerspawned()` (`quality_of_life.gsc` ~line 647), so they start once per game instead
of once per respawn. `build.bat` run successfully (197 files packed, all 6 mod files verified and
copied to both the send-ready folder and `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\`, fresh
timestamps confirmed).

---

## 3. 🛑 WHAT NOT TO TRY AGAIN

- Don't re-theorize about `getPerkDesc()`'s switch/case table, string content, or HUD element
  positioning (x/y/fontscale) for Mule Kick specifically — verified correct by reading the code.
  Mule Kick's case (`specialty_additionalprimaryweapon`) is present and returns the right string.
- Don't assume the perk-purchase race (two perks bought in quick succession destroying each other's
  in-flight HUD elements) is the cause — considered and set aside because it doesn't explain why the
  *earlier*-created elements in the same `perk_bought()` call (icon, name) would survive while the
  *later*-created one (desc) fails; a HUD-element-budget exhaustion from the counterszm leak fits
  better, especially given the MOTD/frequent-revives context.

---

## 4. ⏳ TEST BACKLOG (highest risk first)

- **The fix itself, in-game:** launch Zombies → Mods → `zm_expanded_deathmachine`, play a session
  with several downs/revives (MOTD if possible, to match the original report), and confirm perk
  descriptions keep showing after many respawns. A single early-game perk buy won't reproduce the
  original bug — the leak needed several respawns to accumulate, so the fix needs the same to verify.
- **Regression check:** confirm the round timer (top of screen), zombie counter (bottom-left), and
  riot-shield durability icon still appear and update correctly after this change — they now start
  once on first spawn instead of re-threading each respawn, so watch specifically for: do they
  survive a down+revive without disappearing or freezing? (They should — their own internal loops
  were already `while(true)`/`for(;;)` and didn't depend on being re-threaded.)

---

## 5. NEXT, in order

1. In-game test per §4 — specifically after multiple revives, not just on first spawn.
2. If confirmed fixed and no regressions: delete this checkpoint, and fold the counterszm-leak gotcha
   into `AI_CONTEXT.md` (reusable lesson: any per-spawn `self thread` in this codebase needs to either
   destroy its previous HUD elements or be guarded to run once — same class of bug could recur
   elsewhere).
3. If NOT fixed, or a regression appears: reopen this checkpoint, note what was actually observed
   before forming a new theory (per `CLAUDE.md` §2 — don't re-theorize from scratch).
