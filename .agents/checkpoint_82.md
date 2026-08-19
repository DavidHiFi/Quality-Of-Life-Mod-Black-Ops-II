# Checkpoint 82 — v1.99.75. Vulture Aid CLOSED, Deadshot open with two probes in the field.

Written 2026-08-19. **Supersedes 81 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.75 is deployed, hash-verified into Plutonium, and NOT booted.**

**The next action is the user's boot test in §4, and it is ONE game on a CONTROLLER.** Two features
shipped and neither works; both now carry a print-only probe that names the cause. Do not change
either one before reading those lines out of the log.

| this session | state |
|---|---|
| Vulture Aid — every missing marker icon | ✅ **CLOSED BY THE USER** — see §2 |
| BETTER DEADSHOT (double bullet-headshot damage) | 🛑 **SHIPPED AND NOT WORKING** — probe in, §3 |
| Deadshot head lock-on on controller | 🛑 **STILL DEAD** even with both assists on — probe in, §3 |
| AIM ASSIST row on CONTROLS > GAMEPAD | 🟡 built, moved under TARGET ASSIST, unbooted |
| CONTROLS heading centred in game | ✅ **CONFIRMED** by the user's own screenshot |
| Queue | renumbered to **33 items**, two Vulture items closed |

🛑 **The user closed the terminal expecting to resume with `.`** — this section is the hand-off.
The queued next action is: **read `console_zm.log` for the two probe line families in §4** and act on
what they say. Nothing else starts first.

---

## 1. WHAT SHIPPED, v1.99.71 → v1.99.75

| version | change |
|---|---|
| **1.99.71** | Deadshot + PhD Flopper Vulture icons (**drew nothing** — see the LF/CRLF fault below) |
| **1.99.72** | Fixed those, added the shared skull for Tombstone / Electric Cherry / Who's Who, and the Wunderfizz's white/blue `?` |
| **1.99.73** | BETTER DEADSHOT toggle on the GAME tab; CONTROLS heading centred in game |
| **1.99.74** | AIM ASSIST row on CONTROLS > GAMEPAD (appended at the bottom) |
| **1.99.75** | Row moved under TARGET ASSIST; two diagnostic probes |

### 🌟 THE ONE FACT MOST WORTH KEEPING: raw `.efx` MUST BE CRLF

v1.99.71 shipped two new raw `.efx` written with **LF** line endings. `loadfx()` returned undefined,
`level._effect[...]` was never set, and `zmqol_vulture_machines_enable()`'s `continue` skipped those
machines outright — a *worse* result than the wrong icon it replaced, and it printed no error at all.
Every `.efx` the engine does load here (`fx_zombie_tesla_tube_view` and friends) is CRLF; the header
bytes are `69 77 66 78 20 32 0d 0a`. **Any new `.efx` in this project must be CRLF.**

That `continue` is now a fallback to a stock effect, so a missing effect can never again mean a
missing marker. Same class of lesson as the whole Vulture pass: a silent skip looks like nothing was
ever built.

### The Vulture material pair, worth not re-deriving

Each stock vulture marker is TWO materials: `gfx_fxt_perk_<x>_blend` (`depthTest: less_equal`) and
`gfx_fxt_perk_<x>_lesnflare` (`depthTest: disabled`, additive). **That pair is what makes a marker
draw through walls.** Cloning both — dumped out of this mod's own `mod.ff` with
`Unlinker --include-assets material` — is what let two new icons inherit it exactly.

---

## 2. VULTURE AID IS CLOSED — AND WHAT WAS NOT CONFIRMED

*"im ok with the state of vulture aid so close any tasks related to it, everything works fine."*

Old items **24** and **25** are cut from `QUEUE_LIST.md` and recorded in its *Closed* section with
the old→new map (26→24 … 35→33; 1–23 unchanged). The list is now **33 items**.

🛑 **It was closed while v1.99.72 was deployed and never reported as booted.** v1.99.72 is the
version where the icons first actually drew. So "everything works fine" may describe v1.99.71's
behaviour or v1.99.72's. **If a marker icon is ever questioned again, start from
`MOD_CATALOGUE.md` §5a-2, not from scratch.**

📝 Ported-perk parity was left intact: the user was asked whether to override stock's "hide a
machine's marker once you own that perk" and chose **leave it as stock**.

📝 `zone_assets/images/VULTURE_TODO.md` carried a **wrong** claim — that
`fx_zm_vulture_glow_question` draws `fxt_zmb_perk_magic_box` (a `?` and a hook). It draws
`fxt_zmb_perk_rifle`, **crossed rifles**. Corrected in place; the user's screenshot settled it, with
the yellow `?`-and-hook visible on the mystery box in the same frame.

---

## 3. THE TWO THINGS THAT DO NOT WORK, AND WHY THERE ARE PROBES INSTEAD OF FIXES

### 3a. BETTER DEADSHOT — the hook installs, the multiplier never applies

The user played a full round 25 with the toggle flipped on and off and saw no change. **Their log
contains `[zm_qol] better deadshot: damage chain installed`**, so `level.callbackactordamage` was
re-pointed and `zmqol_actor_damage_wrapper()` is running. One of the tests inside
`zmqol_better_deadshot_scale()` is silently saying no.

Ruled out offline already:
- Normal zombies have **no** `self.actor_damage_func` — only the Who's Who clone sets one
  (`_zm_clone.gsc:61`), so pre-scaled damage does reach `final_damage`.
- `meansofdeath` is **not** converted to `MOD_HEAD_SHOT` on this path: that conversion lives in
  `_globallogic_actor::callback_actordamage`, which zombies *replace* (`_zm.gsc:976`).
- `is_headshot()` is `_zm_utility.gsc:4440` and only needs `shitloc` head/helmet plus a non-melee
  means of death.

**The probe** prints one line per headshot, capped at 12 a game:
`[zm_qol] bd probe: dvar=… perk=… bullet=… mod=… loc=… wep=… dmg=…`
Whichever field reads `0` is the bug. Read it before touching the function.

### 3b. Deadshot's head lock-on — dead on controller with BOTH assists ENABLED

The v1.99.61 fix (`zmqol_deadshot_perk_callback` on the already-paid-for `perk_dead_shot`
clientfield, registered through `replaceFunc(...perks_register_clientfield)`) has **never** been
verified, and the user's controller test says it does not work. Confirmed present offline:
`level.zombiemode_using_deadshot_perk = 1` on the client for zm_transit / nuked / highrise / prison /
buried (`zm_expanded.csc::perks()`), so the field *is* registered, and `give_perk()` calls
`set_perk_clientfield( perk, 1 )`.

**The probe** prints `[zm_qol] deadshot cf: newval=… client=… initial=…` **before** the local-player
guard, plus a distinct line if that guard rejects, plus one on the `usealternateaimparams()` call.
That splits the two causes that need completely different fixes:
- no `deadshot cf:` line at all → the callback never fires → the clientfield/registration is wrong;
- lines present, `usealternateaimparams()` reached → the engine call itself is not producing the
  head lock, and the next question is whether it needs something the retail build no longer wires.

### 3c. AIM ASSIST — what the row can and cannot do (do not widen the label)

Measured from the user's own log and `t6zm.exe`:
- The live game registers **9** `aim_*` dvars, all turn-rate ones, out of **3080** total.
- `aim_lockon_enabled`, `aim_slowdown_enabled`, `aim_autoaim_enabled`, `aim_automelee_enabled` and
  the whole `aim_alternate_lockon_*` block are **strings in the exe but not registered dvars**.
- `input_targetAssist` is a **profile var** — no `input_*` dvar appears in the dump at all.
- `enableaimassist()` / `disableaimassist()` are per-**target-entity** calls.

So the row drives `disableaimassist()` on zombies: it can take assist away, it cannot give it back
with TARGET ASSIST off. The user was told this and asked for the row anyway. 🛑 **It only ever
disables** — a blanket re-enable would hand aim assist to Buried's Ghost and Sloth and Origins'
quadrotor, which stock deliberately disables.

⚠️ Caveat kept honest: that dvar dump was a **mouse-and-keyboard** session. If those dvars register
lazily when a controller is connected, the verdict changes. A gamepad session's log settles it — and
the §4 test is on a controller, so **check for `aim_lockon_enabled` in the new dump**.

---

## 4. THE BOOT TEST — ONE GAME, ON THE CONTROLLER

1. Any map. **Use the gamepad.** Both TARGET ASSIST and AIM ASSIST enabled.
2. Settings → GAME → **BETTER DEADSHOT on, and leave it on for the whole run** (last time it was
   toggled repeatedly, which makes the probe lines ambiguous).
3. Buy **Deadshot**. Shoot about ten zombies in the head.
4. Check CONTROLS > GAMEPAD: is **AIM ASSIST** directly under **TARGET ASSIST** now?
5. Quit out.

**Then read, in `console_zm.log` and its `.000`-`.009` rotations:**
- `[zm_qol] bd probe: …` — the field reading `0` is the BETTER DEADSHOT bug.
- `[zm_qol] deadshot cf: …` — present or absent decides which lock-on fix to write.
- the dvar dump, for `aim_lockon_enabled` — settles §3c's caveat on a controller session.

🛑 **Both probes are print-only and must be DELETED once the causes are known.**

---

## 5. RESIDUAL, UNCHANGED

`EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob (oldest live fault) · the LUI `beingAnimation`
crash fix is still unconfirmed (the jet gun has never been overheated) · **v1.99.62, the Death
Machine vs Mob's afterlife fix, has still never been booted** · published release **v1.99.21 cannot
start a map** and is still downloadable, deleting or annotating it is the user's open decision ·
Carpenter (item 19 now) still needs its two answers · the **mod-unload freeze** trigger is identified
and not fixed.
