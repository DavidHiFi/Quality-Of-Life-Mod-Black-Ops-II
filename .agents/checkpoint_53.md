# Checkpoint 53 — v1.99.1. The power-up timers had TWO fatal bugs, both found offline. Riser narrowed to audio.

Written 2026-08-16. **Supersedes 52 for status.** 48 §1–§4 and 50 §1–§4 are all still unbooted.

---

## 0. STATE — v1.99.1 deployed, hash-verified, never booted

| # | item | state |
|---|---|---|
| 1 | **Power-up timers** — both halves rewritten, two root causes | 🟡 never booted |
| 2 | **Bleedout bar toggle** — user-requested, agent-built | 🟡 never booted |
| 3 | **Origins Death Machine ammo counter** (52 §1) | 🟡 still never booted |
| 4 | **Riser sound** | 🔴 **NOT FIXED — narrowed to audio**, see §2 + B-RISERSOUND |
| 5 | **Titus-6 reload sound** | 🔴 NOT FIXED, unchanged from 52, see B-TITUSRELOAD |
| 6 | **Winter's Howl fx** | 🔴 NOT FIXED, unchanged from 52, see B-WHOWL |
| 7 | **`.character` on survival** | 🔴 root-caused, BLOCKED ON A USER DECISION, see B-CHARACTER |
| 8 | **`mod.ff` runs a pre-merge script** | 🛑 FOUND, not fixed, see B-STALEGSC |

🛑 **Two changes are in this boot, not one.** The user asked for the bleedout toggle directly while
the power-up fix was in flight, which overrides the one-at-a-time rule — but it must be said out
loud: if this boot goes wrong, the cause is not self-naming.

### ✅ CONFIRMED WORKING (52, unchanged)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map. 🛑 Do not disturb.

### 🛑 CONFIRMED BROKEN by the user this round
Power-up timers (fixed here), riser sound (narrowed), Titus reload (untouched).

---

## 1. 🌟 POWER-UP TIMERS — two independent bugs, EITHER of which alone was fatal

v1.99.0 shipped with both. The user reported no timers at all, toggle on or off. Neither bug needed
a boot to find; both were sitting in the files.

### Bug 1 — the client, and it made the feature invisible no matter what the server did

`hudpowerupszombie.lua` read **`w.powerupId`**. Lua is case-sensitive and the live field is
**`powerUpId`**.

The trap is that stock *does* write a lowercase one — `Widget.powerupId = nil` at construction
(~line 515) — but **nothing ever assigns it again.** It is a dead leftover in Treyarch's own file.
The real field is set in `CoD.PowerUps.UpdateState` and read by `GetExistingPowerUpIndex` and
`UpdatePosition`.

🌟 **How it was settled without a boot:** the icons position themselves correctly in game, and
`UpdatePosition` keys *entirely* off `powerUpId`. If that were the dead name the icons could not
move. So the capital-U field is provably the live one.

### Bug 2 — the server hook could never have fired

v1.99.0 used `replaceFunc( _zm_powerups::set_clientfield_powerups, ... )`. Stock's call site:

```
_zm_powerups.gsc:257    player set_clientfield_powerups( ... );
```

**Unqualified, same-file, and SYNCHRONOUS** — CLAUDE.md §4 failure mode #1. The one verified
exception in this project (`_zm::onallplayersready`) is `level thread`-ed, and *that is exactly the
difference* the working theory turns on: threaded calls resolve through the redirectable pointer
table, a plain synchronous local call compiles to a direct jump.

**The hook is gone.** `zmqol_powerup_timer_think()` is now our own level thread reading the same
source data stock's loop reads (`level`/`player.zombie_vars`, keyed off `level.zombie_powerups`).
It cannot silently fail to run, and it no longer replaces a core function — so stock's icon and
flashing behaviour is untouched and there is one less thing that can regress.

Still ≤1 reliable command/sec/player: 2 Hz loop, whole seconds, dvar written only on change.

### Why this one is not another guess — the whole chain has a working precedent IN THE SAME FILE

| risk | cleared by |
|---|---|
| does the 100 ms `UITimer` driving the handler fire? | the **identical** construction at line 524 drives the Death Machine ammo counter, **user-confirmed working** |
| does `setclientdvar` → LUI `Dvar` read work? | that is exactly how `deathmachine_powerup_state` works, **user-confirmed working** |
| does a **fontless** `UIText` render? | `selectmaplistzombie.lua:230` — no font set, visible in game |
| do `flag_wait` / `get_players` resolve here? | already used unqualified 10× and 13× in this same root script |
| syntax | `gsc-tool` parse ✅, `luaparse` 5.1 ✅ |
| deployment | both new symbols confirmed **inside** the deployed `mod.iwd`; **nothing in `raw\` shadows the LUI** |

📝 Residual risk, stated honestly: the text sits in the bottom 18 units *of* the icon widget
(the forum mod's own layout), so it may overlap the icon rather than sit cleanly under it. That is
cosmetic and a boot will show it.

---

## 2. THE RISER SOUND — the probe did its job; this is no longer a mystery

`console_zm.log` carries the v1.99.0 probe line **twice** (Origins and Diner):
`[zm_qol] CLIENT riser clientfield FIRED`.

So: the clientfield arrives, the handler runs, our wrapper plays the sound **and then calls stock's
handler which plays it again** — two calls, zero audible sound. Registration was re-diffed against
stock and is line-for-line faithful, including stock's own odd `12000` version on the foliage field.

🛑 **A dead end recorded so it is not walked twice:** `zmb_zombie_spawn` appears in
`T5-Stock-Soundaliases` (Black Ops **1**) and in no T6 CSV in this workspace. **That is not
evidence it is BO1-only** — T6 aliases live inside the `.sabl`/`.sabs` banks, not CSVs, and stock
T6 script calls it in four places. I briefly drew the wrong conclusion here and corrected it.

▶️ Next: dump the alias tables from the **loaded banks** — the mod ships its own 60 MB
`mod.all.sabl` — and check whether `zmb_zombie_spawn` is present and whether the mod's bank
shadows the stock one carrying it.

---

## 3. NEXT, in order

1. **Any map** — grab a power-up, confirm seconds count down under the icon (§1). Then go down and
   check the bleedout bar, and its new HUD-tab row.
2. **Origins** — the ammo counter (52 §1), the generator ring (48 §1), Who's Who (48 §3).
3. 🛑 **Origins with the mod OFF** — the crash (48 §2). Still never run, still blocks everything.
4. **B-CHARACTER** needs a user decision before any code: survival ships only 2 characters, and 4
   would mean shipping 8 stock xmodels into `mod.ff` (which makes the mod own them on every map).
5. Then: B-RISERSOUND's bank dump, B-STALEGSC, B-WHOWL's `.testfx` probe, B-TITUSRELOAD's notetracks.
