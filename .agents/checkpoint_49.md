# Checkpoint 49 — v1.96.0. Instant start was never actually shipped; the health readout, the CHEATS tab and the README.

Written 2026-08-16. **Supersedes 48 for status.** Keep 48 §1 (the generator-ring mechanism — still
the live untested fix), §2 (the Origins/Mob crash and the tests that remain), §3 (Who's Who), §4
(B-CONTROLS). Keep 45 §1, 44 §1 and §2.

---

## 0. STATE — v1.96.0 deployed, hash-verified, **never booted**

Four changes went in this round, at the user's explicit request (they were told to skip the
one-at-a-time rule by the size of the ask; all four are independent and none touches the ring fix).

| # | change | state |
|---|---|---|
| 1 | **Instant match start now actually ships** (LUI, two dvars) | 🟡 never booted |
| 2 | **Health HUD: the `+` and `100 / 100` are gone**, bar + name only | 🟡 never booted |
| 3 | **CHEATS tab** added; GAME/HUD/CHEATS re-sorted; HOLD TO SPRINT removed | 🟡 never booted |
| 4 | **README rewritten** short; the long form moved to `MOD_CATALOGUE.md` §11 | ✅ text only |

🛑 **v1.95.7's generator-ring fix is STILL UNTESTED and now rides on this build.** Nothing in this
round touches `hudcraftablestombzombie.lua` or Origins, so a ring result is still attributable.

---

## 1. 🌟 INSTANT START — the mod never had it, and the author's own PC hid that for two weeks

A friend on Linux installed the **v1.95.7 release** and got the stock **five-second** countdown in
Solo Play. The author has never seen it.

**Root cause, from two files on the author's machine:**

```
storage\t6\players\plutonium_zm.cfg.bak-before-instantstart   (2026-07-31 04:11)
storage\t6\players\plutonium_zm.cfg                           (live)
```

The only `party_*` lines that differ between them:

| dvar | before | after |
|---|---|---|
| `party_gameStartTimerLengthPrivate` | 5 | **0** |
| `party_pregameStartTimerLength` | 5 | **0** |

A session set those by hand on **one machine** on 2026-07-31 and nothing was ever shipped. The
friend reports exactly **5 seconds**, which is the shipped default of the first dvar. Plutonium's
`dvar_descriptions.json`: *"Time in seconds before a game start once enough party members are
ready."*

🛑 **THE MEMORY THAT SAID DVARS DO NOT WORK WAS WRONG, AND WORTH UNDERSTANDING WHY.** The earlier
finding ("all the `party_*StartTimer*` dvars can be 0 and the countdown still plays") was read off a
dvar dump — but `party_gameStartTimerLength`, the **public** one, is still `5` on this machine and
always has been. The Private variant is the one that matters for a private match, and it was never
the one checked.

🛑 **`CoD.PrivateGameLobby.ButtonStartGame` in `privategamelobby_project.lua` is still dead code.**
It is called by nothing (established 2026-08-11) and was left alone — removing it is a separate
change.

**The fix** (`ui\` and `ui_mp\t6\menus\privateonlinegamelobby.lua`, kept byte-identical):
`zmQolInstantStart()` zeroes those two dvars, called from three points — file load, lobby creation,
and the existing `Button_StartMatch` wrapper. One mechanism, three moments; the file-scope call
covers the one residual risk, that the party system samples the value once at frontend init.

📝 `party_gameStartTimerLength` (public) is deliberately untouched — it is 5 on the machine where
this works, so 5 is proven compatible.

📝 These are archived dvars, so a player keeps instant start in vanilla afterwards. Same state the
author's machine has been in since July.

### ▶️ THE DISCRIMINATOR IF IT DOES NOT WORK FOR THE FRIEND

**Ask whether his lobby header reads `SOLO PLAY` or `CUSTOM GAMES`.** That title comes from *this
very file*, and `privateonlinegamelobby.lua` exists **only inside `mod.iwd`** — it is not in
Plutonium's `raw\` on either machine. So:
- header says **SOLO PLAY** → mod LUI loads from `mod.iwd` on his install, and the dvar write ran;
  the next suspect is the party system re-reading the value.
- header says **CUSTOM GAMES** → mod LUI is not loading in his frontend at all, which is a much
  bigger finding and explains the countdown by itself.

---

## 2. HEALTH HUD — five hudelems became three

User: the friend's name **"SugarButterBuns"** overlapped the `+`.

**It was arithmetic, not a rendering quirk.** All three sat on the same row (y = 18 off
`BOTTOM_LEFT`): name ran right from x = −45, the `+` was pinned LEFT at x = 12, the `100 / 100`
pinned RIGHT at x = 58. Exactly **57 units** of clear space for the name, and a fontstring hudelem
neither scales nor clips. Every name wider than that collided.

`healthvalue` and `healthbar_mas` are deleted. `self.qol_hud_health` is now
`[0]=bg, [1]=bar, [2]=name`, the size guard is `== 3`, and the change-cache moved from `healthvalue`
onto `healthbar` (the `setshader` call is still a reliable command, so the guard still matters).

📝 **Two client hudelem slots per player go back to the pool** — the same budget Origins' capture
ring allocates from (48 §1).

---

## 3. THE OPTIONS MENU — GAME / HUD / CHEATS

Sorted by what each row *does*: HUD holds things that draw on the HUD, CHEATS holds things that
change the rules in the player's favour, GAME holds everything else.

| tab | rows | pitches |
|---|---|---|
| GAME | 3 Plutonium options · night mode, fog, DoF, model-detail fix · intro credits | 9.5 |
| HUD | master, hitmarkers, round summary, game/round timers, health bar, remaining, zone, velocity | 9.5 |
| CHEATS | god, ghost, infinite ammo, infinite sprint, fly, rapid fire, no power | 7 |

All three well under the proven 14.5 budget. The four rendering rows moved **out** of HUD, where
they never belonged.

**Tab strip 700 → 800**, re-derived from the same v1.95.1 pixel scan: gap is a constant 82 px,
capitals average ~14 px, so CHEATS adds ~166 px → 706 units of labels; stock leaves ~34 units per
side → 774 minimum. 800 gives 47 units per side. 🛑 **Biased wide on purpose:** too narrow is the
reported bug (arrows over the labels); too wide has never been reported, and CHEATS's width is the
one estimated number here.

### 🛑 HOLD TO SPRINT is removed and it did NOT go to CONTROLS

The user asked for it in CONTROLS "if that option didn't already exist". It does not exist there —
verified against the retail decompile now sitting at
`storage\t6\raw\ui\t6\menus\optionscontrols.lua.aside`, whose five tabs carry only the `+sprint`
**key bind**. Adding the row means shipping our own `optionscontrols.lua`, which would shadow
Plutonium's patched copy **exactly the way the `.aside` file did** — the bug root-caused in 48 §4,
which cost RAW INPUT / MOUSE ACCELERATION / FIX HIGH POLL RATE LAG. Three working rows for one new
row is a loss. `cg_holdToSprint 1` still works from the console.

📝 **The user has already run the B-CONTROLS rename test** — the file is `.aside` as of 2026-08-14
18:46. **The result was never reported.** Worth one question.

---

## 4. README — cut to a player-facing page

Removed: the textures disclaimer, and every wall of implementation narrative. Added: **install
instructions**, which it never had, even though the release is the only working download. Kept: the
WIP notice, a clean feature list, and a **Known issues table** (Origins/Mob crash, Winter's Howl fx,
kill-feed icons, Titus-6 silent dart/reload, Who's Who overlay, Bouncing Betty).

Everything cut is preserved verbatim-in-substance in **`MOD_CATALOGUE.md` §11** (11a textures,
11b weapons, 11c wonder weapons, 11d round jumping, 11e the options menu, 11f Diner, 11g Blood
Money / Zombie Blood).

---

## 5. 🟢 NEW QUEUE ITEM — B-DMBANK, and it is already measured

`deathmachine_zm.all.sabl` is **redundant**. Both banks were dumped: the Death Machine bank has 18
`wpn_vulcan_*` aliases, and **`mod.all` already contains all 18 with their own payloads**, differing
by exactly 2 bytes each (the Unlinker's FileSource path-length artefact). Dropping it makes the
release five files. Full entry and the one trap (`mod_base.zone` is generated) in `QUEUE.md`.

🛑 Not bundled into this round: a missing alias is **silent**, so the regression would be
unattributable next to four other changes.

---

## 6. NEXT, in order

1. **Boot Origins.** One boot now covers four things: the **generator ring** (48 §1), **Who's Who's
   overlay** (48 §3), and both of this round's visible changes — the health bar with no numbers and
   the CHEATS tab.
2. **Ask the friend to re-download and check the countdown**, and if it is still there, ask what his
   lobby header says (§1).
3. 🛑 **Origins with the mod OFF** — the crash (48 §2). Still never run; everything else is
   downstream of it.
4. Ask what the B-CONTROLS rename test showed (§3).
5. Then the queue, one at a time — **B-TOGGLECONFLICT** first, it is already diagnosed; then
   **B-DMBANK**, which is measured and only needs a boot.
