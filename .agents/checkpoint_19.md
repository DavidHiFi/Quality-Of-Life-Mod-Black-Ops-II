# Checkpoint 19 — v1.55.0. Plutonium lies about the session, and decompiles lie about loops.

Written 2026-08-06. Supersedes checkpoint 18 (v1.54.1), 4 commits ago.
Keep 18 for §1 (the generator ring is an OBJECTIVE, not a hudelem) and §5
(the Zombie Blood asset inventory, still unbuilt). **Its §2 is too
optimistic about `BO2-Raw-files/` and §3 below corrects it.**
Keep 17 for §1 (measure-don't-estimate) and §3 (clientfield budgets per set).
Keep 15 for §2 (the mod.ff asset-ownership trap). Keep 10 for §8 (custom
gamemodes).

**Read §0, then §1. §1 is the reusable one.**

---

## 0. THE SINGLE NEXT ACTION

**Boot v1.55.0 and read the log. Nothing else should be written first.**

The backlog of built-but-never-booted work is now seven releases deep
(v1.52.0 → v1.55.0): Who's Who on four maps, Fire Sale on two, the LOD fix,
and now the solo fix, the box Pack-a-Punch fix and Vulture-everywhere. That
is far too much unverified surface to keep adding to.

Two new probe lines answer three open questions between them. Grep the log:

```
[zm_qol] solo status: expected=N is_forever_solo_game=N
[zm_qol] whoswho: ...
```

- `solo status` should say `expected=1 is_forever_solo_game=1` in a
  single-player game on Origins or Mob. If it says `expected=0`, the fix is
  right but the call site reads the count too early and needs a wait — see §2.
- `whoswho:` will say either "present after Ns" or "MISSING … Repairing".
  **That single line decides where the Who's Who bug lives** (§4).

`developer 1` / `developer_script 1` is still worth setting before loading —
checkpoint 18 §0 asked for it and it never happened, and Plutonium still
swallows GSC runtime errors without it ([[t6-plutonium-hides-script-errors]]).
It is no longer blocking, though: the probes print through `println` either way.

---

## 1. 🛑 PLUTONIUM RUNS EVERY GAME AS AN ONLINE PRIVATE MATCH

The user's report: started **single player** Zombies, captured the first
Origins generator, and the reward chest gave **Zombie Blood** — the co-op
reward. On Mob, plane parts had to be fetched one at a time.

One cause, and it is worth memorising because it is not specific to this mod:

```gsc
check_solo_status()   // zm_tomb_utility.gsc:225, zm_alcatraz_utility.gsc:443
{
    if ( getnumexpectedplayers() == 1 && ( !sessionmodeisonlinegame() || !sessionmodeisprivate() ) )
        level.is_forever_solo_game = 1;
    else
        level.is_forever_solo_game = 0;
}
```

On retail the session clause separates "alone on the couch" (offline → solo
rules) from "online private lobby my friends can still join" (co-op rules).
**Plutonium runs everything — including the Solo menu entry — as an online
private match, so both builtins return true, the OR is false, and the flag is
never set no matter how the game was started.**

Fixed by `replaceFunc` on both maps, keeping stock's player-count test and
dropping only the clause Plutonium always fails. BO2-Reimagined hooks the same
two functions (`zm_tomb_reimagined.gsc:87`, `zm_prison_reimagined.gsc:19`),
which is what proved the hook takes before a line was written.

**Only Origins and Mob read `is_forever_solo_game`** — that is exactly why
those were the only two maps with symptoms, and grepping the dump for the
readers is what turned a vague "single player is wrong" into a two-file fix.
What it restores:

| map | behaviour |
|---|---|
| Origins | reward chest → double points, not zombie blood (`zm_tomb_utility::zone_capture_powerup`) |
| Origins | solo door/debris price cut, 750-point Beretta + 870 (`adjustments_for_solo`) |
| Origins | 4 recapture zombies not 6; `rate_capture_solo` instead of the co-op rate scaled by players-in-zone |
| Origins | solo Mechz behaviour (`_zm_ai_mechz`) |
| Mob | all five plane pieces AND all five fuel cans carried at once (`is_shared`) |
| Mob | solo Brutus below round 9, solo afterlife timings, solo side-quest gate |

### 🌟 The general lesson, and the leads it leaves

**Any stock behaviour gated on `sessionmodeisonlinegame()` /
`sessionmodeisprivate()` behaves on Plutonium as though the game were online
and private, always.** Other sites found in the dump, none yet investigated:

| site | gates |
|---|---|
| `_zm_banking::onplayerconnect_bank_deposit_box` | offline → bank always 0; online → persistent stat. Plutonium takes the **persistent** branch, which is what you want — not a bug |
| `_zm_weapon_locker:17` | `level.weapon_locker_online`, same shape |
| `zm_transit_classic:450` | offline-only account deduction |
| `zm_buried:295` | offline-only `level.pers_nube_lose_round = 0` |
| `zm_tomb_achievement:21`, `zm_buried_achievement:21` | achievements skipped offline |

None of these is known broken. They are listed so the next "why does stock do
X on Plutonium but not on console" question starts here instead of from zero.

---

## 2. THE ONE THING THAT COULD STILL BE WRONG ABOUT §1

`getnumexpectedplayers()` can return **0** early in a map's life —
`_zm.gsc:283` literally polls `while ( getnumexpectedplayers() == 0 && ... )`
with a timeout, and Reimagined's `_zm.gsc:764` does the same.

The replacements deliberately add **no wait**, because stock reads the same
value at the same instant on retail and gets it right:

- Origins calls it directly (`level check_solo_status()`) *after*
  `flag_wait( "start_zombie_round_logic" )` — late, players connected.
- Mob threads it early in `main()`, but `zm_alcatraz_craftables::init` reads
  `level.is_forever_solo_game` **unguarded**, which is Treyarch's own proof
  that it is set by then.

If the probe prints `expected=0`, that reasoning was wrong and the Mob call is
the one to fix — it is threaded, so a bounded wait is safe there. Origins is a
blocking call and must not gain one.

---

## 3. 📉 CORRECTION TO CHECKPOINT 18 §2 — THE DECOMPILES ARE LOSSY

Checkpoint 18 called `BO2-Raw-files/` the thing that unblocks Vulture, on the
strength of "every compiled `.csc` has a readable `.txt` decompile beside it".
That is true and it **did** unblock Vulture. But the `.txt` files are not
source, and the obvious move — ship the decompile as raw text — was tried and
**rejected on evidence**:

```
clientscripts/mp/zombies/_zm_perk_vulture.txt
    _zombie_eye_glow_enable()  → three assignments to n_fx_id in a row.
                                 An if/else chain, flattened; only the last survives.
clientscripts/mp/zombies/_zm_perks.txt
    init_perk_custom_threads() → `i = 0; ...[i]...; i++;` with the loop gone.
```

🛑 **It parses cleanly under gsc-tool.** Syntax was never the question. Had it
shipped, it would have quietly degraded Vulture Aid on TranZit, Die Rise and
Nuketown — where the perk already works — to buy it on two maps.

**The rule that came out of this: a decompile is trustworthy in proportion to
how little control flow the function has.** Straight-line assignment blocks
(precache lists, clientfield registrations, struct setup) are safe to copy
verbatim. Anything with a loop or a branch must be read as a *hint* and
verified against behaviour. `// SP = 0x0 - check OK` in those files is the
decompiler's stack check, not a correctness guarantee.

So §18's "cross-check bit counts against the shipped `.ff` before writing" was
the right instinct and did not go far enough — cross-check *shape*, not just
numbers.

---

## 4. WHAT SHIPPED — v1.55.0

| change | note |
|---|---|
| **fix(solo)** | §1. Origins + Mob. |
| **fix(magicbox)** | Re-pulling a weapon you already hold Pack-a-Punched kept the base gun. |
| **feat(vulture)** | Vulture Aid on Origins and Mob — **all 11 perks on all 6 maps**. |
| **fix(whoswho)** | `zmqol_whoswho_verify` — a probe, not yet a fix. |

### The box Pack-a-Punch downgrade

Rolled the Ray Gun twice, PaP'd the first, grabbed the second, PaP gone. This
case **only exists because of this mod's own `double_weapons` change**: stock's
`has_weapon_or_upgrade` check meant the box would never offer a weapon whose
upgrade you held, so it could not arise. Lifting that check opened it, and
`weapon_give( "raygun_zm" )` on a player holding `raygun_upgraded_zm` does the
naive thing. `treasure_chest_give_weapon` now gives max ammo instead, mirroring
`custom_swap_weapon` in `zm_tomb/zm_tomb.gsc`.

📝 **Lifting a stock restriction creates cases stock never had to handle.**
Worth a sweep of the other lifted checks (`limited_weapon_below_quota`,
`special_weapon_magicbox_check`) for the same shape.

### Vulture on the last two maps

Each map was blocked by exactly one clientfield, in a different set:

| map | dropped field | bits/set | cost |
|---|---|---|---|
| `zm_tomb` | `vulture_perk_actor` | 2, actor | zombie eye glow + stink trail |
| `zm_prison` | `vulture_perk_disease_meter` | 5, toplayer | the stink meter |

Both cosmetic. Server half edited directly (it already ships raw): two gated
registrations, seven gated use sites — the actor uses turned out to live in two
accessors, so that guard is four lines. Client half does **not** replace the
compiled `.csc` (§3); only `init_vulture` is re-implemented in
`zm_expanded.csc` and `level._custom_perks[perk].init_thread` re-pointed at it.

🛑 **Four functions must now agree**, two per side:
`zmqol_vulture_has_actor_field()` / `zmqol_vulture_has_disease_meter()` in
`maps\mp\zombies\_zm_perk_vulture.gsc` and in `scripts\zm\zm_expanded.csc`.
Check those first on any Vulture clientfield error. The overlay stays
registered unconditionally on **both** sides, as stock does — dropping it on
one side is what produced `[CLIENT: 4 SERVER: 5]` twice before.

All Vulture assets were already in `mod_locations.zone`, so **no `mod.ff`
relink was needed**. v1.55.0 is `.gsc`/`.csc` only.

⚠️ The log shows `Could not load material "specialty_vulture_zombies"` on
Origins **from before this change**, when Vulture was disabled there. Something
precaches the icon regardless of the perk being on. Now that the perk is
enabled it may show as a checkerboard. Pre-existing, unfixed, first thing to
look at if the icon looks wrong.

---

## 5. WHO'S WHO — WHY IT IS A PROBE AND NOT A FIX

Reported: gave Who's Who with the chat command on Origins, let the tank run
them over, straight to game over.

The gate, `_zm.gsc:4239` inside `player_damage_override`:

```gsc
if ( self.lives > 0 && self hasperk( "specialty_finalstand" ) )
{
    self.lives--;
    if ( isdefined( level.chugabud_laststand_func ) )
    {
        self thread [[ level.chugabud_laststand_func ]]();
        return 0;
    }
}
```

🛑 **Note what happens when that inner `isdefined` fails: `self.lives` has
already been decremented and there is no `else`.** The player falls silently
through to an ordinary down, one life poorer. "Perk equipped, nothing happened,
game over" is precisely that shape.

Everything on the give side was **re-read, not assumed**, and all of it checks
out: our `give_perk` override does set `self.lives = 1`; `.give<perk>` routes
through `_zm_perks::give_perk`, which is the function we replace;
`_zm_perks::init()` threads `turn_chugabud_on()` off a flag we set in `main()`;
and that thread's *first* statement is `_zm_chugabud::init()`, whose *first*
statement sets the pointer.

Static analysis says it should work. The game says it does not. That is exactly
the junction where checkpoint 18 §1 was written, so this time nothing was
shipped on a theory: `zmqol_whoswho_verify()` polls for the pointer, logs its
real state, and installs it only if genuinely missing.

**How to read the next log:**

| line | means | next step |
|---|---|---|
| `chugabud_laststand_func present after Ns` | the pointer is fine | the **damage path** is the cause, not the pointer. Start at `zm_tomb_tank::tank_ran_me_over` — it does `disableinvulnerability()` then `dodamage( self.health + 1000 )` |
| `MISSING after 60s … Repairing` | stock's `turn_chugabud_on` never reached `_zm_chugabud::init()` | find out why `_zm_perks::init()` died before line 99; the repair is a workaround, not the fix |

🌟 **`tank_ran_me_over` doing `disableinvulnerability()` is also the best lead
so far for `.god` / `.ghost` dropping out** (§6 item 4). That is stock clearing
invulnerability on a player, which is exactly the mechanism suspected.

---

## 6. STILL OPEN — user-reported, in their words

1. ~~"the generator progress bar is missing again"~~ — **user reports it fixed
   as of v1.54.1**, no longer misbehaving. Checkpoint 18 §1's objective-system
   correction stands as the record of what it actually is.
2. ~~"i want all perks available on ALL maps"~~ — **Vulture done (§4).**
   Remaining: **Tombstone** missing on 5 maps, needs `ch_tombstone1`
   (`zm_transit.ff` only) shipped in `mod.ff`; **Who's Who + Quick Revive on
   Mob**, which need `specialty_quickrevive_zombies` — Mob alone lacks it.
3. **"add zombie blood power up to all the maps"** — NOT STARTED. Full verified
   asset list in **checkpoint 18 §5**; nothing has changed about it.
4. **".ghost is still kinda inconsistent"**, **"god and ghost mode were both not
   working"** — see the `tank_ran_me_over` lead in §5.
5. **"one of the templar zombies was still there"** after a generator.
6. **"the bottle is off to the left sometimes still after spinning"** — a real
   defect was fixed in v1.53.0; still reported after, so either not deployed
   when tested or not the whole cause.
7. **"i already have mule kick"** — v1.53.1 fixed the paused-perk half only.
8. **MP40 wallbuy → adjustable-stock variant on Origins** (it is the box version).
9. **Python: always the 6-round speed reload**, not only when Pack-a-Punched.
10. ~~Box: keep the PaP and refill ammo~~ — **done in v1.55.0 (§4).**
11. **`.hud` to toggle all HUD off, plus `.hudtimer` / `.hudhealth` /
    `.hudcounters`** — the dvars already exist, so this is thin.

---

## 7. METHOD NOTES

- **Grep for the READERS of a flag, not just its setter.** "Single player is
  wrong" became a bounded two-file fix the moment
  `grep is_forever_solo_game` showed only Origins and Mob read it.
- **Check whether the reference mod already solved it before designing.**
  Reimagined `replaceFunc`s both `check_solo_status` functions — that settled
  "is this hookable" in one grep, against a starter-kit rule that says
  unqualified calls are not.
- **A decompile's trustworthiness is inversely proportional to its control
  flow.** §3. It parsed clean and was still wrong.
- **Lifting a stock restriction creates cases stock never had to handle.** §4.
- **When static analysis and the game disagree, ship a probe, not a theory.**
  §5. This is checkpoint 18 §1's lesson applied rather than re-learned.
- **Read the failure branch, not just the success branch.** The Who's Who gate
  decrements a life *before* the `isdefined` that can fail, and that asymmetry
  is the whole signature of the bug.

---

## 8. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`,
  `-m parse -g t6 -s pc -y <file>` (`-i client` for `.csc`). Validates syntax
  only — see §3.
- OAT — `H:\Claude\oat-windows\`. Pass fastfiles as fully-quoted absolute paths.
- `build.bat` for `.gsc`/`.csc`; `build_ff.bat` only for
  `zone_source`/`zone_assets`. **v1.55.0 needed only `build.bat`.**
  From PowerShell both need `dangerouslyDisableSandbox` and a full path:
  `& "H:\Claude\Projects Sources\zm_qol\build.bat"`. Verify deployed byte sizes
  afterwards — `[ok]` does not prove deployment.
- Raw client-script override confirmed working: the log line to look for is
  `Script source "scripts/zm/zm_expanded.csc" loaded successfully from raw`.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- Screenshots — newest in `G:\Gallery`.
- GitHub `github.com/DavidHiFi/zm_qol`, private, tags v1.1.1 → **v1.55.0**.
