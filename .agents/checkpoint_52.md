# Checkpoint 52 — v1.99.0. Origins' ammo counter root-caused, power-up timers ported (minus their crash), and mod.ff caught running a script that does not exist.

Written 2026-08-16. **Supersedes 51 for status.** 48 §1–§4 and 50 §1–§4 are all still unbooted.

---

## 0. STATE — v1.99.0 deployed, hash-verified, never booted

| # | item | state |
|---|---|---|
| 1 | **Origins Death Machine ammo counter** — one-word inversion, root-caused | 🟡 never booted |
| 2 | **Power-up timers** — ported, with the forum mod's crash removed | 🟡 never booted |
| 3 | **Zombie riser sound** — probe + candidate fix shipped | 🟡 never booted |
| 4 | **Winter's Howl fx** | 🔴 **NOT FIXED — offline checks exhausted**, see B-WHOWL |
| 5 | **Titus-6 reload sound** | 🔴 **NOT FIXED — measured**, see B-TITUSRELOAD |
| 6 | **`mod.ff` runs a pre-merge script** | 🛑 **FOUND, not fixed**, see B-STALEGSC |

### ✅ CONFIRMED WORKING by the user this round
`.infammo` (the dvar fix took), the perk pop-up toggle, the health bar, the Origins generator
progress overlay, and the Death Machine on every map. 🛑 Do not disturb any of these.

---

## 1. 🌟 THE ORIGINS AMMO COUNTER — one word, and the map-specificity was the clue

`ui_mp/t6/zombie/hudpowerupszombie.lua` patches three ammo-counter tables so the Death Machine can
hide the counter. Two of them return `true` from `ShouldHideAmmoCounter` while it is active.
The third — `CoD.AmmoAreaZombie` — returned **`false`**, which means *"do not hide me"*.

**And Origins is the only map that could ever show it.** `ui_mp/t6/zombie/ammoareazombie.lua` is
shipped by **`zm_tomb_patch.ff` and by no other fastfile** — `patch_zm.ff` carries
`otherammocounters.lua` and no `ammoareazombie.lua` at all (`Unlinker --list` on both). So
`CoD.AmmoAreaZombie` exists on Origins alone, every other map was covered by the two siblings, and a
plain typo looked like a map-specific bug for months.

---

## 2. POWER-UP TIMERS — ported, and the crash in the source removed

From the user's `H:\Claude\POWER UP TIMERS` (a Plutonium-forums mod). The LUI half is used close to
verbatim; the server half could not be.

🛑 **THE FORUM MOD AS SHIPPED WOULD KILL EVERY MAP IN ABOUT ONE SECOND.** Its
`set_clientfield_powerups` ends in an unconditional `self setclientdvar( "powerup_times", str )`, and
stock drives that function from a `wait 0.05` loop, once per player per power-up type
(`_zm_powerups.gsc:208-263`). With six client fields that is **~120 reliable commands per second**
against a **128-entry ring** — a guaranteed `EXE_ERR_RELIABLE_CYCLED_OUT`, and the same crash class
already open on Origins and Mob, so it would have poisoned that hunt too.

**The fix costs nothing visually:** the LUI only ever draws `math.ceil(t)`, so the server sends
whole seconds and **only when the string changes** — ≤1 command/sec while a power-up runs, 0
otherwise. The cache lives on the player. Everything below the write is stock's body verbatim.

📝 Not hardcoded to a power-up list: it follows whatever stock's own loop iterates, i.e. every entry
in `level.zombie_powerups` with a `client_field_name`. The Death Machine has one, so it is included
for free, and so is anything added later.

`hud_powerup_timers` (default 1) + a POWER-UP TIMERS row in the HUD tab. The dvar is read
**server-side**, so switching it off stops the traffic rather than just hiding the text.

---

## 3. THE RISER SOUND — a probe, because guessing has failed three times

`zm_expanded.csc` now registers its own wrapper for `zombie_riser_fx`: it plays `zmb_zombie_spawn`
itself, logs **one** line the first time the field fires, then calls stock's handler unchanged.

▶️ **Read the log after the next Diner boot:**
- `[zm_qol] CLIENT riser clientfield FIRED` **present** → the trigger works; the fault is audio-side,
  and the wrapper's own `playsound` may already have fixed it.
- **absent** → the clientfield never arrives, and the spawner path is where to look.

Ruled out this round, both measured: the payload's bank **is** loaded (`console_zm.log:363`), and
stock itself registers `zombie_riser_fx` first server-side (`_zm.gsc:1161`) and third client-side
(`_zm.csc:419`) — so T6 matches by name and the mod's copies mirror stock faithfully.

---

## 4. 🛑 B-STALEGSC — `mod.ff` SHIPS AND RUNS A SCRIPT THAT IS NOT IN THIS PROJECT

Four of these are in `console_zm.log` at every map load:

```
WARNING: overriding server replaced func maps/mp/zombies/_zm::init_client_flags;
         scripts/zm/zm_expanded::init_client_flags with scripts/zm/quality_of_life::init_client_flags
```

`scripts/zm/zm_expanded.gsc` **does not exist in the tree** — it is the pre-merge module that became
`quality_of_life.gsc`. But `mod_base.zone` still declares it, so the Linker pulls the donor's July
copy in every single build, and Plutonium executes it. The link output says it outright:

```
Loaded script "scripts/zm/zm_expanded.csc" (src: disk)   <- ours
Loaded script "scripts/zm/zm_expanded.gsc" (src: mod)    <- the donor's, 542 lines
```

🛑 **`CLAUDE.md` §8 and `build_ff.bat`'s comment both say `.gsc` cannot be affected. They are wrong**
— that holds only for a script the zone does not declare. Fixed wording belongs with the fix.

The four colliding bodies happen to be **identical** to the current ones today (dumped and compared),
so it is inert right now. That is luck. Full entry + the `regen` trap in `QUEUE.md`.

🌟 **General technique worth keeping: `grep WARNING console_zm.log` is a free audit of replaceFunc
collisions, and it names the winner** (the one after "with").

---

## 5. WHAT WAS MEASURED AND NOT FIXED

Both have full entries in `QUEUE.md`; the short version:

- **B-WHOWL (Winter's Howl fx).** The v1.97.0 CRLF fix was a real defect fixed, but it was not this.
  Everything checkable offline now passes: byte-identical to the working build, `Loaded fx:` in the
  log, the def matches two independent ports, it is not a copy of the thundergun's file, and all 7
  of its materials resolve. What is left needs the game — the freezegun and thundergun flashes share
  three elements, so if the freezegun-only ones drop at runtime, what remains genuinely looks like
  the thundergun's. Next: a `.testfx <name>` command to compare them side by side in one boot.
- **B-TITUSRELOAD.** BO2 contains **four** Titus sound payloads in total and none is a reload;
  `notetrackSoundMap` is empty in **Treyarch's own campaign def** as well as ours. So the audio comes
  from the reload animation's notetracks. Next: dump `viewmodel_titus_mk_reload` from `mod.ff` and
  read its notetrack names. 📝 Side finding: three `titus6_zm` animations (`_d2p_in/loop/out`) are
  absent from `mod.ff`.

---

## 6. NEXT, in order

1. **Diner** — check the log for the riser probe line (§3), and look at whether dirt bursts appear.
2. **Origins** — Death Machine, then look at the ammo counter (§1). Same boot covers the generator
   ring (48 §1) and Who's Who (48 §3), both STILL unbooted.
3. **Power-up timers** — grab any power-up anywhere and check the seconds count down (§2).
4. 🛑 **Origins with the mod OFF** — the crash (48 §2). Still never run, still blocks everything.
5. Then: B-STALEGSC (its own round), B-WHOWL's `.testfx` probe, B-TITUSRELOAD's notetrack dump.
