# Checkpoint 50 — v1.97.0. The wonder-weapon fx were CRLF-corrupted for seven versions. Three fixes, one honest miss.

Written 2026-08-16. **Supersedes 49 for status.** Keep 48 §1 (the ring), §2 (the Origins/Mob
crash), §3 (Who's Who), §4 (B-CONTROLS) and 49 §1 (instant start).

---

## 0. STATE — v1.97.0 deployed, hash-verified, never booted

| # | change | state |
|---|---|---|
| 1 | **All 60 `.efx` restored to LF** — the Winter's Howl firing fx | 🟡 never booted |
| 2 | **`.infammo` / `.infsprint` write their dvar** — the menu no longer undoes them | 🟡 never booted |
| 3 | **Wunderfizz first location is random** by default | 🟡 never booted |
| 4 | Zombie riser sound on TranZit Survival | 🔴 **NOT FIXED — two theories disproved, nothing shipped** |

### ✅ CONFIRMED WORKING by the user this round — do not break these again
- **The health bar** (bar + name, no numbers, no `+`) — exactly as wanted.
- **The Origins generator progress overlay is back to vanilla stock.** 🛑 The v1.95.7 LUI wrap is
  correct; leave `ui_mp\t6\zombie\hudcraftablestombzombie.lua` alone.

### 📝 A correction the user made, and it is on us
I said they renamed `optionscontrols.lua` to `.aside` on the 14th. **They did not touch it.** So
either an earlier session did it or something else did. Do not attribute workspace changes to the
user without evidence. B-CONTROLS' result is therefore still unknown *and* the rename is unexplained.

📝 The friend is unavailable — the Linux instant-start fix (49 §1) stays unverified, and that is
fine; it was reported as information, not as a blocker.

---

## 1. 🌟 THE WONDER-WEAPON FX — v1.70.0 MATCHED A GIT CHECKOUT ARTEFACT, NOT THE SHIPPED FILE

User: *"the winters howl still has no shooting visual fx ... this was working at some stage but you
have done something to break it ... there is visual fx for shots, but this isn't the correct fx, you
gave it some weird looking wind effects."*

They are right, and the culprit is exact.

**v1.70.0** ("the wonder-weapon crash was LF line endings") diffed our `.efx` against
`H:\Claude\Wonder_Weapons-T6ZM\src\fx\`, concluded *"ours had ZERO CR bytes ... where the working
port's are CRLF"*, and converted all of ours to CRLF.

**`Wonder_Weapons-T6ZM` is a git clone with `core.autocrlf = true` and no `.gitattributes`.** Its
`src\fx` working copy is CRLF *because git rewrote it on checkout*. The file that actually ships is
LF:

| copy | bytes | CR |
|---|---|---|
| `src\fx\...\fx_freezegun_view.efx` (checkout) | 49,451 | 2,676 |
| `git show HEAD:src/fx/...` (the stored blob) | **46,775** | **0** |
| `wonder_wepons_zm\mod.iwd` (**the shipped working build**) | **46,775** | **0** |
| ours, v1.70.0 → v1.96.0 | 49,451 | 2,676 |

Delta is exactly one byte per line (2,676 lines). T6 parses `.efx` as text, so **35 of our 60
effects have been parsing wrong since v1.70.0** — including `fx_freezegun_view` (the muzzle flash)
and `fx_freezegun_smoke_cloud` (played at the muzzle on every shot by
`_zm_weap_freezegun.gsc:151`). `fx_freezegun_world.efx` was NOT among the 35, which is why *some*
effect still drew — the "weird wind".

**Fix:** all 60 overwritten from `wonder_wepons_zm\mod.iwd` and verified **60/60 byte-identical** to
that shipped build. Classification before the change: 25 already identical, **35 differed ONLY by
CR, 0 differed in content** — so nothing else was lost (v1.71.0's material substitutions are not
present in the current files either way).

🛑 **`pack_iwd.ps1`'s comment asserted byte-identity while 35 files were corrupt, and that claim is
why nobody looked for seven versions.** Rewritten with the measurements above.

📝 The 3 tesla `.efx` the reference ships and we do not (`fx_zombie_tesla_shock`, `_shock_ground`,
`_shock_secondary`) were deliberately NOT added back: `mod.ff` owns those three as compiled fx
assets, and v1.73.0 removed the raw copies precisely because defining them twice was a suspected
crash. Do not re-add them without dealing with that.

▶️ **If the fx are still wrong after this boot**, the next structural difference is the one v1.73.0
named: the reference's `mod.ff` carries **0** fx assets and ours carries **151**.

---

## 2. `.infammo` AND `.infsprint` — the chat command could never win

User's screenshot: `.infammo` → `infinite ammo ON` immediately followed by `infinite ammo OFF`.

`zmqol_toggle_dvar_watch()` polls `infinite_ammo` every 0.25 s and drives `self.zmqol_infammo` from
it. Both chat branches set the **field** and never the **dvar**, so the next poll saw want=0, is=1
and switched it straight back off. `.god`, `.ghost` and `.hud` were given `setdvar` in v1.95.0 for
exactly this reason; these two were missed.

Both now write their dvar. **They were the only two left** — audited every command in
`zmqol_console_command_names()` against every menu row: `.night` writes `night_mode`, `.fog` writes
`r_fog` via `setclientdvar`, `.hud`/`.god`/`.ghost`/`.fly` all write theirs.

📝 The dvar is global and the field is per-player, so in co-op this turns it on for everyone — the
contract `.god` and `.ghost` already have.

---

## 3. WUNDERFIZZ — the random first location was switched off by its own default

`wunderfizzUseRandomStart` defaulted to **0**, so every match started at location 1, the first
coordinate in the map's list. Default is now 1.

🛑 **The existing random-start code was moved, not just enabled, because it would have failed.** It
sat after `zmqol_wf_place()` as:

```gsc
level waittill( "connected", player );  wait 1;
level.currentWunderfizzLocation = chooseLocation( level.currentWunderfizzLocation );
level notify( "wunderfizzMove" );
```

It had **never run**, and it had two faults:
1. `waittill("connected")` is one-shot. Placement traces geometry first, so in solo the host has
   usually already connected — the waittill would block forever, `currentWunderfizzLocation` would
   stay 0, no machine would ever match its own `.location`, and **the mod would ship with no
   working Wunderfizz on any map.**
2. `wunderfizz()` reads `currentWunderfizzLocation` at setup to decide `hidepart("j_ball")`, so a
   value that changes a second later leaves the wrong machine holding the ball.

The draw now happens **inside `zmqol_wf_place()`, after filtering and before the first
`wunderfizzSetup()`** — the only moment where the final count is known and no machine exists. No
wait, no notify, no race.

**The "only one machine" case is free and already measured:** survival filters the map-wide list
down (Diner's boot logs `placed 1 of 6 candidate location(s)`), and the draw is skipped at
`size > 1`, so Diner / Town / Bus Depot keep their single machine live. The log line now also
prints `starting at location N`, so the randomisation is checkable from the log alone.

---

## 4. 🔴 THE RISER SOUND — NOT FIXED, AND HERE IS EXACTLY WHY

Full entry in `QUEUE.md` as **B-RISERSND**. Two theories raised and **both disproved offline**:

1. *"the audio isn't in a loaded bank"* ❌ — `zmb_common.all.sabl`, which owns the payload, loads at
   frontend start (`console_zm.log:363`).
2. *"the mod permutes the actor clientfield order"* ❌ — **stock has the same asymmetry** (server
   registers `zombie_riser_fx` first, client third), so T6 matches by name and both of the mod's
   copies mirror stock.

The mod touches nothing else on the riser path. **One observation splits what is left**: the sound
and the dirt burst share a single clientfield, so "burst but no sound" and "neither" point at
opposite halves. And Bus Depot / Farm Survival is a free control for "is this even Diner?".

🛑 Nothing was shipped. No substitute alias, no speculative fix.

---

## 5. NEXT, in order

1. **Boot Diner (or any TranZit Survival) and fire the Winter's Howl** — §1. Also answer the two
   riser questions in §4 while there; they cost nothing on a boot already happening.
2. **`.infammo` twice**, and set INFINITE AMMO to DISABLED in the CHEATS tab first — §2.
3. **Restart the same map twice** and read `starting at location N` in the log — §3.
4. **Origins** — the generator ring (48 §1) and Who's Who (48 §3) are STILL unbooted.
5. 🛑 **Origins with the mod OFF** — the crash (48 §2). Still never run.
6. Queue: B-TOGGLECONFLICT is now closed by §2. Next are **B-RISERSND**, **B-DMBANK**, B-VIEWMODEL.
