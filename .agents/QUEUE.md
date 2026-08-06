# QUEUE.md — one change at a time

**Rule (user, 2026-08-06):** nothing new starts until the item in flight is **confirmed working
in-game by the user**, with no bugs and no compromises. New requests get appended here and
acknowledged, not begun.

**"Deployed" is not "done".** Only a boot moves an item out of §1.

---

## 1. IN FLIGHT — deployed, AWAITING THE USER'S VERIFICATION

### Wunderfizz: Origins' real effects + real bear bottle, on every map — **v1.56.4**
What to check on Nuketown (or any non-Origins map):
- the arcs are the soft blue Origins ones, **not** harsh white bolts
- the orb light, location beam and departure steam all look like Origins
- when the machine relocates the bottle is a **perk bottle**, not an actual teddy bear
- the ball still spins up and vanishes on departure (that part already worked)

Verified offline: link 0 errors, script parses, all 5 assets in the deployed `mod.ff`, deployed
`mod.iwd` script confirmed to use the real bottle and load the dieselmagic fx.

---

## 2. QUEUED — in order, not started

1. **Pause-menu UI** — port the Strat Tester options menu (`H:\Claude\Strat-Tester-BO2`), header
   renamed **"Quality Of Life"**, exposing every existing chat command **plus** ones missing from
   the menu (infinite sprint, etc). Chat commands stay. Scoped already: `optionsstrattester.lua`
   881 lines, `options.lua` 560, `menu.gsc` 73; no LUI conflict with this mod's `ui_mp\`.
   🛑 A bad LUI file hard-crashes the game — this one ships alone.
2. **Death Machine pickup voice line** — the BO1 "Death Machine" announcer callout on pickup.
3. **Nuketown perk-machine placement** — Deadshot's icon lands at an angle, Speed Cola drops half
   into the ground in the back yard. Not diagnosed yet.
4. **Diner teddy bears** — the 3-bear secret-song easter egg on Diner survival (garage, diner,
   Juggernog room). **Blocked:** needs three `.where` readings from the user; coordinates will not
   be guessed.
5. **zm_refreshed weapon ports** — MP7 + Vector to all maps, Dragunov + Spas-12 to Nuketown and
   Mob, MGL to Mob, Remington transferable via fridge, B4KED's fixed Jetgun, **Quick Revive on
   Mob** (confirmed absent; `specialty_quickrevive_zombies` is in no zombies fastfile, so it needs
   shipping). ~400 assets into `mod.ff` — do these **one weapon at a time** with an ownership
   audit after each.
6. **Origins Wunderfizz replacement** — replace Origins' native machines with the mod's, keeping
   generator-power gating, relocation, ball behaviour and per-machine ball visibility.
   Blocker on record: Origins' `scriptmover` clientfield set is **32/32 full**.

---

## 3. PARKED — known-open, not currently requested

- **T5 wonder weapons** (Thundergun / Wunderwaffe / Winter's Howl). Reverted at v1.56.x after three
  byte-identical crashes: `0x80000003` at `0x129F75DB`, an engine assert with no script or asset
  error. Every asset class was checked and resolved. Leading unproven theory: a hard engine ceiling
  — the creators ship **one weapon per mod**, never all three. Work is in git (`bb44073`,
  `0084881`) and reappliable.
- **Vulture on Origins is a compromise** — ships with `vulture_perk_actor` and
  `vulture_perk_scriptmover` dropped, so the stink pile is invisible there (its entity is a bare
  `tag_origin`). Under "perfectly or not at all" this should be revisited: either revert Vulture on
  Origins or free the bits.
- **Origins generator ring** — the v1.55.2 intro-hold change was shipped as a falsifiable test and
  has never been booted. The probe logs objective index / contested state / players-in-zone.
- **Who's Who damage path** — the pointer is fine (probe confirmed). Remaining lead is
  `zm_tomb_tank::tank_ran_me_over` doing `disableinvulnerability()` then `dodamage(health+1000)`,
  which is also the best lead for `.god` dropping out.
- **`.hud` toggles** — `.hud` off/on plus `.hudtimer` / `.hudhealth` / `.hudcounters`. Dvars exist.

---

## 4. DONE — verified in-game by the user

| version | change |
|---|---|
| v1.56.2 | **Tombstone on Nuketown** — all 12 perks confirmed |
| v1.55.x | **Who's Who** confirmed working |
| v1.54.1 | Origins generator progress bar reported fixed |
