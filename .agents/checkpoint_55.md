# Checkpoint 55 — v1.99.6. Power-up timers CLOSED and off the list. The riser probe answered. The bleedout toggle is now live mid-down.

Written 2026-08-16. **Supersedes 54 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.6 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | **Power-up timers + the Death Machine icon** | ✅ **CONFIRMED IN GAME.** *"the power up timers are working so forget that it's a finished task"*. **Removed from the queue entirely** |
| 2 | **Bleedout bar — live toggle** (queue #1) | 🟡 v1.99.6, deployed, **never booted**. See §2 |
| 3 | **Riser origin probe** (queue #6) | ✅ **RAN.** The origin theory is **dead** — see §1. The bug is still open, with a new direction |
| 4 | **Origins Death Machine ammo counter** (queue #2) | 🟡 still never booted |
| 5 | Titus-6 reload · Winter's Howl fx · `.character` · `mod.ff` stale script | 🔴 unchanged — queue #8, #7, #12, #11 |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers **with** the Death Machine and the user's own icon artwork, and the
bleedout bar itself (visible in their screenshot, *"Bleeding out in: 39"*).

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
Quick Revive, go down, flip **BLEEDOUT BAR** off in Options → HUD, close the menu. The bar should be
gone; flipping it back on should bring it straight back. That is queue #1 settled either way.

---

## 1. B-RISERSOUND — THE PROBE ANSWERED, AND IT KILLED THE THEORY

The v1.99.5 probe printed on Diner, once, exactly as designed:

    [zm_qol] RISER PROBE  riser=(-5283, -7466, -64)  player=(-4770.45, -7442.69, -60.1549)
             dist=513  bnewent=0  binitialsnap=0

Read against checkpoint 54 §3's own table: **`dist` well under 1000 → origin theory dead.** The
origin is valid (not `(0 0 0)`, not `UNDEFINED`), the entity is not fresh (`bnewent=0`), there is no
initial snap, and 513 units sits between `DistMin 250` and `DistMaxDry 1000` — attenuated, but
audible by design.

🌟 **So the sound is being emitted next to the player, at a valid position, and is still inaudible.**
Everything asset-side, script-side and now position-side is eliminated by measurement. What remains
is the **mix**: volume/ducking/occlusion, or the bank's own gain on this alias.

🛑 **Do not "fix" this by moving the sound onto the player.** That was already ruled out as the wrong
response even when the origin theory was live, and the origin turned out fine anyway.

📝 The probe cost nothing extra — it printed during a boot the user was making regardless. Worth
repeating as a pattern: a print-only probe that cannot regress anything rides along free.

---

## 2. THE BLEEDOUT BAR TOGGLE — v1.99.1 SHIPPED A DOCUMENTED COMPROMISE, AND IT CAME BACK

The user tested precisely the gap v1.99.1's own comment described:

> *"the toggle does work but not in realtime [...] when you turn it off via the settings it wont
> update on screen and the bar will still be there, but if you have it set to disabled then go down
> it will not be visible, so basically i cant update it to on or off realtime."*

v1.99.1 read `hud_bleedout_bar` **once**, above element creation, and its comment called that
acceptable, citing the `hud_perk_popup` precedent.

### 🌟 THE LESSON, and it is the important part of this checkpoint

**A documented compromise is still a compromise.** The note did not make the behaviour acceptable —
it just recorded the defect in the file where nobody but us reads it, and shipped anyway. That is
the completeness audit failing quietly: writing down what is missing is not the same as deciding it
may be missing. The user found it on the first boot.

Ask instead: *would the user call this finished?* If the honest answer is no, it is not a note, it
is unfinished work.

### The change (v1.99.6)

The dvar read moved **inside** the loop; elements are created and destroyed to follow it.

| | before | after |
|---|---|---|
| dvar read | once, at creation | every server frame (`wait 0.05`) |
| HUD writes | every 1s, unconditional | only when the whole SECOND changes — **still ~1/sec** |
| OFF mid-down | bar stays until revive | gone within a frame |
| ON mid-down | nothing until the next down | appears with the live count |

🌟 **The poll costs nothing on the wire, by construction.** `updateBar` (→ `setshader`) and
`setvalue` are what spend reliable commands; `n_shown` holds them to one write per whole second,
the same rate the old `wait 1` produced. Reading a dvar is local. ERROR_CATALOGUE §7b (the
128-entry ring) is why this was designed rather than hoped.

Two real bugs fixed alongside, both found by reading rather than by symptom:

1. **The bar is FOUR hud elements, not two.** `_hud_util::createbar` (`:499`) makes three — bar,
   frame, background — and the text is a fourth. The old comment said two. Destroy-on-OFF is kept
   precisely because four out of a finite allowance is not something to charge a player who
   switched the row off.
2. **`Bleedout_bar_End_game_fix()` `&&`-ed the two references**, so if only one existed it tore down
   **neither**. It now shares the new `bleedout_bar_destroy_hud()`, which checks each independently
   and clears both — the clearing matters because the state machine now keys off
   `isdefined( self.ProcessBar2 )`.

### Pre-mortem — four failure modes, all checked offline

1. **Element leak on repeat toggling** — no: `createbar` returns `barelembg` carrying `.bar` and
   `.barframe`, and `destroyelem()` (`:750`) destroys all three plus itself.
2. **`int( self.bleedout_time )` errors at 20 Hz** — no: never assigned `undefined` anywhere in the
   2,093-file dump, and stock threads `laststand_bleedout` (which sets it at `:395`) at
   `_zm_laststand.gsc:208`, **before** the `player_downed` notify at `:214`.
3. **`ProcessBar2` read while undefined** — cannot: creation runs in the same pass, above the update
   block.
4. **Division changed** — it did not; `n_now` is the identical `int( self.bleedout_time )`.

🟡 **Residual, pre-existing, NOT introduced here:** if `level.laststandgetupallowed` is true, or the
`is_zombie` / `no_revive_trigger` branch at `_zm_laststand.gsc:385` is taken, stock never sets
`bleedout_time` for that down. The old code had the same exposure and the bar demonstrably works.

📝 **How to judge it:** the text element carries `hidewheninmenu = 1`, so the number is hidden while
any menu is open. The verdict is what the screen shows **the moment the menu closes**.

---

## 3. THE QUEUE WAS RENUMBERED AGAIN — read this before citing a number

The user closed the power-up timers and asked for the line to be **removed**, not struck. So on
2026-08-16 every remaining line moved **up by one**: `2→1` … `23→22`. The map is in
`QUEUE_LIST.md`'s *Closed* section, along with the eleven items closed earlier the same day.

🛑 **Two renumberings happened on the same date.** Any note citing a queue number must be read
against both maps, in order.

---

## 4. DOCS — the README was overclaiming by one, and under-listing by one

`README.md` said **26 toggles**; `optionssettings.lua` has **27** (GAME 8 + HUD 12 + CHEATS 7),
counted rather than incremented. The BLEEDOUT BAR row took HUD to 12 back in v1.99.1 and the README
was never updated. Both the count and the missing feature are fixed.

The ⚠️ WORK IN PROGRESS notice stays at the top, and in the release notes.

---

## 5. WHAT WAS **NOT** DONE THIS SESSION, deliberately

- **No new feature started.** One at a time; queue #1 is in flight and unbooted.
- **The riser-sound mix investigation was not begun** — the probe answered, but acting on it means
  opening a second unverified change while #1 is in flight.
- **"Does a HUD toggle survive a restart?"** was raised (no `hud_*` line appears in
  `players\plutonium_zm.cfg`, suggesting these are plain non-`seta` dvars) and **flagged as
  suspected, not proven**. It affects every HUD row equally, so it is not a defect of #1 and was not
  opened as work.
