# Checkpoint 81 — v1.99.70. Vulture markers CONFIRMED, the announcer narrowed, nine new queue items.

Written 2026-08-19. **Supersedes 80 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.70 is deployed, hash-verified into Plutonium, and NOT booted.**

**The next action is the user's boot test in §4.** It is ONE Nuketown game and it answers two open
questions. Do not start any queue item until it is done — items 26-34 are all queued, none started.

| this session | state |
|---|---|
| Vulture markers on perk machines | ✅ **CONFIRMED WORKING** by the user — item 24's core is done |
| Which Nuketown machines get the neutral icon | ✅ **MEASURED: exactly two** — Deadshot + PhD Flopper, §2 |
| Fallback marker HEIGHT raised to the machine's middle (v1.99.70) | 🟡 built, not booted |
| `vulture_marker_height` dvar + its live re-apply watcher | 🟡 built, not booted |
| Two println-only probes (marker codes, `soundexists`) | 🟡 built, not booted |
| Power-up announcer | ✅ **NARROWED**: every stock line works; only Blood Money + Zombie Blood are silent, §3 |
| Announcer voice question | ✅ **CLOSED by the user** — keep Samantha on every map |
| Scoreboard emblem, pre-game pick | 🛑 **REOPENED** — always CIA regardless of choice, §5 |
| Mod unload freeze | 🛑 trigger identified, not fixed, §5 |
| Nine new requests (26-34) | queued, none started |

---

## 1. WHAT SHIPPED IN v1.99.70

**One real change and two probes.** The change: `zm_expanded.csc::zmqol_vulture_marker_height()` now
lifts **code 10** (the neutral fallback) as well as code 1 (Wunderfizz), by
`getdvarintdefault( "vulture_marker_height", 38 )`.

🛑 **Codes 2-9 deliberately keep 0.** Those are Treyarch's own `fx_zm_vulture_glow_*` effects, drawn
by stock at the machine origin, and the user has never complained about them. Code 10's effect
(`fx_zm_vulture_glow_question`) was authored for a **wall buy**, whose entity origin already sits at
icon height on a wall — at a machine's base it lands on the floor. Same effect, different anchor.
That is the whole bug, and it is why the fix is a height and not a new icon.

**`zmqol_vulture_marker_height_watch()` — the pre-mortem earned its keep.** The height is only read
inside `zmqol_vulture_machines_enable()`, which runs when a marker's clientfield value changes or the
perk is gained. The server stops re-sending once every machine is marked, so typing the dvar mid-game
would have moved **nothing**. The watcher polls once a second and re-runs `enable` on change; that
function disables the old set first, so a re-apply cannot stack duplicate fx.

📝 **Generalise it:** when a constant becomes a dvar, find what re-reads it. If nothing does, ship
the re-read with it — otherwise the dvar is decoration.

**Probes (println only, zero behaviour change):**
- `[zm_qol] vulture marker: <perk> -> code <n>` — one line per machine, from the server scan.
- `[zm_qol] vox probe: stock_maxammo_0=... qol_zblood=... qol_bmoney=... qol_dmachine_0=...` —
  `soundexists()` on one stock alias as a control plus the four mod aliases.

**Deployment verified, not assumed:** the two `.gsc` were read back out of the deployed `mod.iwd`
(zip inflate, symbols present), and the `.csc` out of the deployed `mod.ff`
(`Unlinker --include-assets script`, `n_code == 1 || n_code == 10` at `:1709`). `build_ff` logged
`Loaded script "scripts/zm/zm_expanded.csc" (src: disk)`.

---

## 2. THE NUKETOWN FALLBACK MACHINES — MEASURED, NOT GUESSED

`zm_nuked.gsc:108-141` lists the nine machines the mod drops. Run each `script_noteworthy` through
`_zm_perk_vulture.gsc::zmqol_vulture_marker_code()`'s eight-case switch and exactly two fall through:

| machine | `script_noteworthy` | code |
|---|---|---|
| Quick Revive / Speed Cola / Double Tap / Juggernog | `specialty_quickrevive` / `fastreload` / `rof` / `armorvest` | 4 / 5 / 3 / 2 |
| Pack-a-Punch / Stamin-Up / Mule Kick | `specialty_weapupgrade` / `longersprint` / `additionalprimaryweapon` | 6 / 7 / 8 |
| **Deadshot** | `specialty_deadshot` | **10 — fallback** |
| **PhD Flopper** | `specialty_flakjacket` | **10 — fallback** |

🌟 **The user's own diagnosis was right.** Treyarch authored glow fx for eight perks only, because
Buried has eight machines, and neither of these is among them. No glow effect exists for either
anywhere in BO2, and new fx cannot be authored — OAT dumps no `FxEffectDef`, retested on
`OAT.BSP.v2.0`. A neutral icon is the ceiling, not a shortcut.

🛑 **STILL UNRESOLVED AND DO NOT GUESS AT IT: the user calls the fallback "a default weapon icon".**
The Wunderfizz uses the **identical** effect and they confirmed *that* one as a white/blue `?`
(checkpoint 80 §0). Both cannot be true of the same fx, so either they were looking at stock's
wall-buy markers (`vulture_perk_wallbuy_static` = `fx_zm_vulture_wallbuy_rifle`, genuinely a weapon
icon, drawn on wall weapons nearby) or something else is in play. **The §4 probe answers it.** Do not
change the icon before reading that log.

---

## 3. THE ANNOUNCER — WHAT IS RULED OUT, AND ONE NEGATIVE RESULT

User's test: **every stock power-up announced correctly; only Blood Money and Zombie Blood were
silent.** Death Machine was not observed either way.

That kills the entire shared path, all of it verified offline first:
- `_zm_audio_announcer::init()` runs on every map (`_zm_audio.gsc:23`) and registers the stock keys.
- `level.powerup_intro_vox` / `level.powerup_vo_available` are set by **`zm_transit` only** in the
  whole 2,093-file dump. `level.allowzmbannouncer` is cleared only by `zm_buried_sq.gsc:1449`.
- The mod overrides no announcer or power-up script, and `zmqol_register_announcer_vox()` only
  *adds* keys — it never clears `game["zmbdialog"]`.
- The `createvox` keys match the power-up names exactly: `bonus_points_player` (`:9095`) and
  `zombie_blood` (`:9332`).

🛑 **NEGATIVE RESULT WORTH KEEPING: the soundbank dump does NOT settle the payload question.**
`Unlinker --include-assets soundbank -o dump mod.ff` puts all six `vox_zmba_qol_*` rows in
`mod.all.aliases.csv` — so the rows shipped — but it recovered **0 payloads out of 2363 aliases**
while still emitting 472 "could not find data" warnings, including for sounds the mod demonstrably
plays. **Those warnings are a dumper limitation on this machine, not evidence.** Do not cite them.
The `soundexists()` probe exists precisely because this could not be settled offline.

📝 Also note: `strings` is **not installed** in this Bash environment and fails silently with no
output — an earlier sound-bank check returned nothing for that reason and proved nothing. Use
`tr -c '[:print:]' '\n' < file | grep -x ...` instead; that is how `quit`, `disconnect`,
`map_restart` and `fast_restart` were confirmed present in `t6zm.exe`.

✅ **Voice question closed by the user:** *"which should have the samantha ones due to them only
meant to be on origins."* Both ported lines are Samantha's (payloads dumped from `zmb_tomb.english`)
and stay that way on every map. The earlier open decision is resolved.

---

## 4. THE BOOT TEST — ONE GAME

**New Nuketown survival game. Buy VULTURE AID and nothing else.**

1. Look at **Deadshot** and **PhD Flopper**. Is the icon at the machine's middle now?
   If not, type `vulture_marker_height 25` (any number) in console — it re-applies live, no rebuild.
2. **What do those two icons actually look like?** This is the §2 dispute.
3. Grab a **Blood Money** or **Zombie Blood** if one drops (still expected silent — that is fine,
   the probe is what matters).

**In the log afterwards, three things:**
- `[zm_qol] vulture marker: <perk> -> code <n>` — expect `specialty_deadshot -> code 10` and
  `specialty_flakjacket -> code 10`, everything else 2-8.
- `[zm_qol] vox probe: ...` — read it against the table in `quality_of_life.gsc`'s block comment:
  stock 1 / qol 1 = payload or routing at fault; stock 1 / qol 0 = the engine cannot see a mod-bank
  alias by name; stock 0 = the probe itself is unusable, discard it.
- `[zm_qol] vulture marker height -> N` if they nudged the dvar.

---

## 5. THE NINE NEW QUEUE ITEMS (26-34), AND TWO REOPENED FACTS

All nine are written up in full in `QUEUE.md` under three dated sections; `QUEUE_LIST.md` is the
index. Headlines only:

- **26** announcer, now narrowed to §3. **27** CUSTOM POWER-UPS toggle (🛑 Origins keeps Zombie
  Blood; the client half must read the same dvar or the map will not boot).
- **28** the unload freeze. 🌟 **The friend's control test is the useful half:** load → **start a
  match** → unload = freeze; load → unload with no match = fine; another mod, same steps = fine.
  So `mod.ff` unloads cleanly on its own, and something the **map load** creates holds a reference
  into it. The user's own `console_zm.log` ends on the literal last line `Unloading fastfile mod`.
- **29 RESTART GAME.** 🌟 **It is already stock and the screenshot proves what hides it.**
  `patch_zm\ui_mp\t6\hud\class.lua:100-131` adds it as the second button, gated on
  `SessionModeIsMode(SYSTEMLINK)` or `(OFFLINE)`. RESUME GAME is inside the *outer* `if` and it
  renders — so that condition passed and only the session-mode test failed. That is the LUI face of
  [[t6-plutonium-session-mode-solo]]. Nothing new ships: `MENU_RESTART_LEVEL_CAPS` and
  `openRestartGamePopup` both already exist.
- **30 INSTANT EXIT / 31 QUIT TO DESKTOP.** Stock LUI already calls
  `Engine.Exec(<ctrl>, "disconnect")`; all four commands verified present in `t6zm.exe`.
  📝 **Open question for the user: does QUIT TO DESKTOP want a confirmation step?** It sits one row
  from END GAME.
- **32 BOX LIMITS toggle.** 🌟 **The feature already ships and is always on** — confirmed in the
  user's own log: `[zm_qol] _zm_magicbox override ACTIVE (double_weapons + no_limits)`, printed
  unconditionally from `init()`. The work is the **OFF** path, which must reproduce stock's
  `treasure_chest_canplayerreceiveweapon` / `limited_weapon_below_quota` from the dump.
- **33 teleport / 34 change round + kill horde + end round**, from `H:\Claude\Strat-Tester-BO2`
  (the user's own clone — **not** `H:\Claude\BO2-StratTester`, a different, smaller mod).
  🛑 The teleport's destinations are hand-authored per map and Strat Tester has **none for
  Nuketown**; ported as-is the row silently does nothing there. `.where` is the authoring tool.

**Two facts that changed:**
1. 🛑 **Checkpoint 80's "scoreboard emblem, pre-match ✅ confirmed" is WRONG.** The user, with a
   screenshot: whichever team they pick pre-game, the scoreboard shows CIA. Item 22 is reopened.
   The *mid-match* finding (proven impossible, checkpoint 80 §2) is unaffected.
2. ✅ **README updated this commit** — it never mentioned no-box-limits, which is an always-on
   gameplay change. One line added, marked "always on; toggle queued, not shipped".

---

## 6. RESIDUAL, UNCHANGED

`EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob (oldest live fault) · the LUI `beingAnimation`
crash fix is still unconfirmed (the jet gun has never been overheated) · **v1.99.62, the Death
Machine vs Mob's afterlife fix, has still never been booted** · published release **v1.99.21 cannot
start a map** and is still downloadable, deleting or annotating it is the user's open decision ·
Carpenter (item 21) still needs its two answers: which map, and how far were the barriers.
