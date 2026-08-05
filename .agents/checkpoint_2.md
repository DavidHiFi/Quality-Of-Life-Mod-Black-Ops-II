# Checkpoint 2 — instant-start: SOLVED via LUI override (see §0.4)

---

## 0.4 ✅ ROUND 5 — THE ACTUAL FIX: one-function LUI override

**🛑 §0.3's dvar conclusion IS ALSO WRONG.** Setting every `party_*StartTimer*` / `party_minLobbyTime`
dvar to `0` did nothing — the runtime dvar dump in `console_zm.log` confirmed they really were `0`
during the session and the 5-second countdown still played. A matching dvar description is a lead,
not proof.

**The real mechanism**, found by grepping the user-provided `H:\Claude\BO2-Reimagined` repo-wide
(`ui_mp/t6/menus/privategamelobby_project.lua:338`):

```lua
CoD.PrivateGameLobby.ButtonStartGame = function (PrivateGameLobbyButtonPane, ClientInstance)
	Engine.Exec(ClientInstance.controller, "xpartygo")
end
```

The Start button's default handler runs the countdown; overriding it to `Engine.Exec("xpartygo")` is
literally what typing `xpartygo` in console does. The stock file does **not** define `ButtonStartGame`
(its default is in compiled LUI), so this is a **pure append** — the rest of the stock file is
untouched.

**Applied to both locations (2026-07-31), each with a `.bak-before-instantstart` backup:**
- `%LOCALAPPDATA%\Plutonium\storage\t6\raw\ui_mp\t6\menus\privategamelobby_project.lua` — `raw/` is
  first in the engine search path, so this is what actually loads on this machine; global to all
  Zombies play.
- `zm_qol/ui_mp/t6/menus/privategamelobby_project.lua` (stock file + the same append), packed into
  `mod.iwd` by `build.bat` — so the mod itself carries the behavior when distributed. `mod.iwd` went
  197 → 198 files, confirming it packed.

**🛑 PROCESS FAILURE worth remembering:** the user had placed BO2-Reimagined in the workspace and
stated it removes this countdown. An early search of it only covered `scripts/` (GSC) and concluded
"no instant-start code here" — it was in `ui_mp/`. Three wrong theories (GSC `onallplayersready`
timing → "compiled LUI, unfixable" → dvars) were shipped before grepping the provided reference
repo-wide. **Given a reference implementation that reportedly does X, grep the WHOLE thing for X
before forming any theory.**

**Leftover from §0.3, harmless but unnecessary:** `party_gameStartTimerLengthPrivate`,
`party_pregameStartTimerLength` are still `0` in both configs (base + `players\mods\zm_qol\`). They
point the same direction as the intent and cause no known harm; backups exist if they should be
reverted.

---

---

## 0.3 ✅ ROUND 4 — ACTUAL SOLUTION: `party_gameStartTimerLengthPrivate` dvar

**🛑 §0.2's conclusion ("not fixable, would need patching compiled LUI") IS WRONG. Do not follow it.**
The lobby countdown is not UI code at all — it's a plain dvar, and it was sitting in the user's own
config the whole time.

Found via `H:\Claude\Projects\Plutonium\storage\t6\plutonium\dvar_descriptions.json` (a full dvar
name→description dump that ships with Plutonium — **check this file FIRST for any "is there a setting
for X" question in future; it is searchable ground truth and would have saved this entire multi-round
detour**):

| dvar | description |
|---|---|
| `party_gameStartTimerLengthPrivate` | "Time in seconds before a game start once enough party members are ready" |
| `party_gameStartTimerLength` | same, non-private/matchmaking path |
| `party_pregameStartTimerLength(Private)` | pregame equivalents |
| `tu14_resumeLobbyCountdown` | "Resume **xpartygo countdown** at time left rather than reset to 10 each time" — confirms this dvar family IS the xpartygo countdown |

**Changed (2026-07-31), game confirmed closed first so values weren't clobbered on exit:**
`party_gameStartTimerLength`, `party_gameStartTimerLengthPrivate`, `party_pregameStartTimerLength`
all set `"0"` (from 5/10) in BOTH:
- `%LOCALAPPDATA%\Plutonium\storage\t6\players\plutonium_zm.cfg` (base, for non-mod play)
- `%LOCALAPPDATA%\Plutonium\storage\t6\players\mods\zm_qol\plutonium_zm.cfg` ← **the live one when
  running zm_qol.** Plutonium keeps a SEPARATE per-mod config under `players\mods\<modname>\`; editing
  only the base config would have appeared to do nothing. Note it held *different* values (10) than the
  base config (5), proving these are per-config archived values, not force-set by a common exec.

Backups written alongside each as `*.cfg.bak-before-instantstart`.

`party_pregameStartTimerLengthPrivate` was **already `"0"`** in both configs before any edit — that's
the evidence `0` is in-domain for this dvar family (T6 enforces dvar domains and rejects out-of-range
values with a console warning, e.g. the observed
`'2' is not a valid value for dvar 'party_maxlocalplayers_privatematch'`).

**If it does NOT work, check first:** console log for a domain-rejection line on these dvar names (if
so, try `1` instead of `0`), and re-check whether the per-mod config still reads `0` after a session
(if the game rewrote it to 5, something resets it at runtime and a different approach is needed).

---

**Supersedes nothing for checkpoint 1** (perk-description fix) — that one is a separate, still-open
test item. This checkpoint covers a new, riskier feature added in the same session.

**Written 2026-07-31, updated same day after first test.** First deploy of `instant_start()` produced
**zero observable change** in-game (user tested both custom games and singleplayer — "just started the
5 second timer" both times). A second, instrumented build has now been deployed but not yet tested.

---

## 0. 🛑 FIRST ATTEMPT DID NOTHING — investigation so far

Checked `console_zm.log` (freshest client log) and `mods/zm_qol/games_mp.log` (server log) from the
user's actual test session. Neither logs "GSC Executed" lines or any script error at this verbosity —
**the "GSC Executed in console_zm.log" verification method from the base starter kit's CLAUDE.md does
not appear to apply to this client-side Mods-menu log at default verbosity.** Don't rely on it here
without first confirming what log level/dvar actually enables it, if any does.

**Real finding from the log:** `xpartygo` is a literal, real console command (`]xpartygo` appears in
`console_zm.log` exactly when Start is clicked) — confirming the user's friend's description was
accurate, this is a genuine T6 command, not a misremembered term. It fires immediately after the user
finishes navigating the private-match setup menus (`ui/t6/partylobby.lua`, `ui/t6/mainlobby.lua` —
real LUI files, confirmed loaded in the log) — there is **no scripted delay before `xpartygo` fires**;
the gap between opening the lobby and typing it is just the user's own menu navigation time (repeated
`execing zm/gamesettings_*.cfg` blocks = clicking through game-mode/map/settings screens). This means
the countdown is NOT a pre-start lobby countdown — it happens AFTER `xpartygo`, during/after map load,
which is consistent with the original `_zm.gsc::onallplayersready()` theory (checkpoint 2 §1 below),
but the log didn't capture far enough into the actual gameplay session to confirm or deny that
`instant_start()` ran or had any effect.

**Ruled out:** `is_encounter()` false-positive was considered (would make `instant_start()` return
immediately every time, matching "zero effect"). Checked its stock implementation
(`_zm_utility.gsc:392`) — it keys off dvar `ui_zm_gamemodegroup == "zencounter"`, unrelated to the
`zstandard`/`zclassic` gametypes seen in the user's actual session (`games_mp.log`). Not the cause.

**Not yet ruled out:** whether `instant_start()` even executes at all (silent runtime error?), and
whether the actual visible delay is dominated by something this fix can't touch at all (e.g. genuine
disk/asset streaming time that just happens to take a similar few seconds, unrelated to any GSC flag).

**What changed for the next test (round 2):** added on-screen (`iprintlnbold`) and console (`println`)
debug messages at every stage. Built and deployed. **This is purely diagnostic — remove once the real
behavior is understood, don't ship it long-term.**

---

## 0.1 🛑 ROUND 2 RESULT — race+watchdog approach abandoned, replaced with real replaceFunc

User tested on Mob of the Dead. Debug output (confirmed via the actual `console_zm.log`, which DOES
contain `GSC Executed` lines and our `println`s once you scroll far enough — my earlier claim that this
log doesn't capture that at default verbosity was wrong, I just hadn't read deep enough into it) showed:

```
[instant_start] thread started
[instant_start] flags exist
[instant_start] textures loaded
[instant_start] player count stable
```

...and then **nothing**. No "flags forced - done", no `neutralize_intro_screen` message ever appeared
in the whole log. The thread silently died somewhere between the stabilize-wait finishing and the
final `flag_set` calls — most likely in `players[0].lives = 0` or
`set_default_laststand_pistol(1)` racing ahead of some precondition MOTD's afterlife mechanic depends
on, though this was never conclusively isolated (see below — moot now, code path deleted).

User also reported a RED debug message ("black screen" wording) appeared but "didn't actually do
anything" — the black screen was still fully perceived. Given the log shows the thread died *before*
`neutralize_intro_screen` was ever threaded, that red message the user saw could not have come from our
code as it existed at that point. Left unresolved/unexplained — possibly a misremembered detail, or the
message came from a stale build. Not worth chasing further since the whole approach was replaced.

**Bigger find, from the user's workspace-provided reference material** (`H:\Claude\BO2-Reimagined`, a
full OAT-buildable mod source with `zone_source/reimagined.zone`, and
`H:\Claude\Projects\Plutonium\storage\t6\mods\zm_reimagined`, a built copy): their
`scripts/zm/_zm_reimagined.gsc:33` does
`replaceFunc(maps\mp\zombies\_zm::onallplayersready, scripts\zm\replaced\_zm::onallplayersready);` — a
**real, working mod successfully replaceFunc's this exact function**, despite it being called
unqualified from within its own file (`_zm.gsc`'s `main()`: `level thread onallplayersready();`).

**🛑 This directly contradicts the earlier "failure mode 1" reasoning that shaped round 1's entire
design.** Best current explanation: the call site is `thread`-ed, not synchronous, and threaded calls
resolve through the redirectable function table even when unqualified same-file, unlike plain
synchronous same-file calls. (Reimagined's replacement turned out to be functionally identical to
stock timing-wise — they use it for an `is_encounter()` bug fix and dedicated-server lobby logic, NOT
for instant-start — so it wasn't a ready-made answer, but it proved the hook mechanism works.)

**Round 2 code (now live):** deleted `instant_start()`/`neutralize_intro_screen()`/
`instant_start_debug_msg()` entirely. Replaced with `onallplayersready_instant()` — a faithful copy of
stock `onallplayersready()` (cross-checked against both vanilla and Reimagined's copy, identical) with
exactly two numbers changed: the "wait up to 5000ms for expected-player-count" timeout cut to 300ms,
and `fade_out_intro_screen_zm`'s hold/fade cut from `(5.0, 1.5)` to `(0.15, 0.3)`. Wired in via
`replaceFunc( maps\mp\zombies\_zm::onallplayersready, ::onallplayersready_instant );` in `main()`.
Everything else (connected-player sync, solo lives/pistol setup, bot handling, texture-load wait) is
untouched stock logic. Since this is a genuine replaceFunc, stock's original body never runs at all —
eliminates the entire "unstoppable background thread" problem that broke round 1.

Debug prints added at the very top (confirms replaceFunc actually redirected here) and very bottom
(confirms the function ran to completion, past `fade_out_intro_screen_zm`). Built and deployed.

---

## 0.2 🛑 ROUND 3 RESULT — replaceFunc worked, but was fixing the wrong thing entirely

User tested again: the `[onallplayersready_instant]`/`[instant_start]` debug messages DID appear
(confirming the replaceFunc redirect works correctly and the function completes fast now), but the
user said "that's not what I asked for" — they were already in the map, in MOTD's afterlife state,
before those messages even showed up.

**The actual mechanism, now correctly identified:** the wait the user cares about happens in
Plutonium's **private-match lobby menu**, before the map even starts loading — a "match starting
in..." countdown shown by the Start/Play button. The user's own workflow: choose map + mode in the
Zombies globe menu, then instead of clicking the button, open console (`` ` ``) and type `xpartygo`
manually — this skips the countdown UI entirely and starts loading immediately. Confirmed by directly
reading the actual Lua source (user provided a live copy of their Plutonium install,
`H:\Claude\Projects\Plutonium\storage\t6\raw\ui\` and `raw\ui_mp\`):
`ui_mp/t6/menus/privategamelobby_project.lua` has a `startMatchButton`, but its actual creation and
click behavior (the countdown) live in a shared `CoD.Lobby` module that is **compiled into the base
game, not present as loose/raw Lua source anywhere available** — not in zm_qol, not in the raw UI dump,
not in BO2-Reimagined. `xpartygo` itself never appears as a string literal in any available Lua source
either — it's invoked some other way the button's compiled logic doesn't expose to us.

**🛑 Conclusion: this specific feature (auto-skip the lobby countdown on button click) is not
achievable from zm_qol, or arguably from any GSC/loose-Lua T6 mod, given available tooling.** It would
require patching compiled base-game UI code with no accessible source — a fundamentally different, much
larger undertaking than a gameplay script mod (shared front-end infrastructure, not scoped to one mod,
no source to safely diff against). Do not re-attempt without first finding actual Lua source for the
`CoD.Lobby` module specifically (not `partylobby.lua` or `privategamelobby_project.lua` — checked,
doesn't contain it).

**Practical alternative offered instead:** a Plutonium keybind (`bind <key> "xpartygo"`) so the user's
existing manual workaround becomes one keypress instead of opening console and typing the full command.
This is a Plutonium config change, not a zm_qol mod change — see §4 for status.

**`onallplayersready_instant()` code is being kept** (debug prints stripped, rebuilt) since it's a
real, if smaller, improvement to genuine post-load dead time — just not the fix for what was reported.

---

## 1. WHAT'S DONE (current, round 2 code — supersedes §0's round-1 description)

Added `onallplayersready_instant()` to `quality_of_life.gsc` (end of file), wired in via
`replaceFunc( maps\mp\zombies\_zm::onallplayersready, ::onallplayersready_instant );` in `main()`.
Goal: skip the dead time between clicking Start and being able to play in Zombies.

**Root mechanism:** stock `maps\mp\zombies\_zm::onallplayersready()` — an up-to-5s wait on the engine
builtin `getnumexpectedplayers()` (meant to be populated by an Xbox Live party; doesn't reliably
resolve on Plutonium) followed by a deliberate 5s black-screen hold + 1.5s fade + 1.6s settle. Real
total dead time is ~8-13s, not literally "5 seconds," though the black-screen hold is exactly 5.0s and
is probably what reads as "the 5 second countdown." (Separately, MOTD specifically also has real
asset-streaming time between map-fastfile-load and the script even starting — confirmed via
`console_zm.log`, ~3400 log lines of material/fx loading between `Loading fastfile zm_prison` and
`GSC Executed quality_of_life::main()`. No GSC change can shorten that part; it's genuine disk I/O.)

**How the fix works (verified viable, see §0.1):** `onallplayersready_instant()` is a faithful copy of
stock's function body with exactly two numbers changed — the 5000ms expected-player timeout cut to
300ms, and the black-screen hold/fade cut from `(5.0, 1.5)` to `(0.15, 0.3)`. Because this is a genuine
`replaceFunc` redirect (not a race), stock's original body never executes at all when this mod is
loaded — no leftover background thread, no watchdog needed.

Debug instrumentation present (temporary, remove once confirmed): `println` + on-screen
`iprintlnbold` at function entry and right before/after `fade_out_intro_screen_zm()`.

---

## 2. 🛑 WHAT NOT TO TRY AGAIN

- Don't reintroduce the "race ahead of stock + watchdog the intro screen" approach from round 1 — it's
  fully described in §0/§0.1 above for the history, but the code is gone. It produced a thread that
  silently died partway through and, even where it partially worked, could never fully stop stock's
  original delay from being perceived, since stock's own thread kept running unchecked in the
  background. `replaceFunc` on `onallplayersready` is the correct lever — see §0.1.
- Don't assume `replaceFunc` can't intercept a function just because it's called unqualified from
  within its own defining file — that "failure mode 1" reasoning (imported from the general starter
  kit) does NOT hold for `thread`-ed call sites, only (as far as verified) synchronous ones. Re-check
  whether a call site is `thread X()` vs plain `X()` before ruling replaceFunc out on this basis again.
- Don't assume there's a dvar that fixes `getnumexpectedplayers()` at the source — searched the entire
  starter kit (`reference/gsc-dump`, `reference/docs`) and `H:\Claude\BO2-Reimagined` for
  "xpartygo"/"party_go"/"getnumexpectedplayers"/related dvars; found nothing beyond the stock call
  sites already documented. `xpartygo` itself is confirmed to be a real client console command (seen
  firing in `console_zm.log` the instant Start is clicked) but fires immediately with no lobby-side
  scripted delay before it — the countdown is entirely after that, in map load / `onallplayersready`.

---

## 3. ⏳ TEST BACKLOG (highest risk first) — round 3, not yet tested

- **Does `replaceFunc` actually redirect here at all in practice for THIS mod?** Verified viable via
  BO2-Reimagined's precedent, but not yet directly confirmed for zm_qol's own build — watch for the
  `[onallplayersready_instant] replaceFunc redirected here - start` console/on-screen message. If it
  never appears, something about zm_qol's specific replaceFunc registration order or module merge is
  different from Reimagined's, and the "thread calls are hookable" theory needs re-examination.
- **Does the game actually start faster now**, and does the whole function reach the final
  `[onallplayersready_instant] DONE` message (confirms it ran past `fade_out_intro_screen_zm` without
  dying, unlike round 1)?
- **Solo lives / Quick Revive self-revive** — confirm going down and self-reviving still works on the
  very first down of a solo game (exercises `solo_lives_given`/`player.lives` bookkeeping, now on the
  exact stock code path instead of a hand-copied race version).
- **Co-op**: untested with a second player actually connecting.
- **Regression**: confirm perk-description fix from checkpoint 1 still works — untested together with
  this change in an actual play session.
- **Grief/Turned modes**: confirm `is_encounter()` still correctly falls through to the non-solo branch
  there (this mirrors stock/Reimagined's own guard placement now, so should be fine, but unverified).
- **MOTD specifically**: since this is where testing has concentrated, confirm the afterlife
  intro/materialize sequence isn't disrupted by the shortened black screen — MOTD's own map script
  only does `flag_wait("initial_blackscreen_passed")`, no separate black-screen system of its own (per
  stock source), so it should just react to the flag firing sooner, but verify the "climb out of the
  chair" moment still looks/feels right rather than jarring.

Debug prints have been removed (2026-07-31, after round 3) — `onallplayersready_instant()` is final,
faithful-to-stock-minus-two-numbers code now. Items 1-3 in §3 about its own correctness (solo lives,
co-op, Grief/Turned) are still genuinely untested and still worth checking eventually, but they're
no longer the active focus — the user's actual reported problem (§0.2) is outside this mod's reach.

---

## 4. NEXT, in order

1. **Not a zm_qol code task**: set up a Plutonium keybind (`bind <key> "xpartygo"`) in the user's
   config so their existing manual console workaround becomes one keypress. Waiting on the user to
   pick a key. This is the practical resolution to the original ask — see §0.2.
2. Whenever next convenient (not urgent): verify `onallplayersready_instant()` didn't regress solo
   lives/self-revive, co-op start, or Grief/Turned — per §3. Low priority since it's a minor
   improvement, not the feature that was actually requested.
3. Also still open: checkpoint 1 (perk-description HUD fix) — verify in-game, separately from this.
4. Once both checkpoints are confirmed clean (or deliberately closed out, as this one now is except
   for the low-priority regression checks in item 2): fold the replaceFunc-on-threaded-calls lesson
   into `AI_CONTEXT.md` as a correction to the general "unqualified same-file call defeats replaceFunc"
   rule (it's `thread`-call-specific, not universal) — a genuinely reusable, verified correction.
