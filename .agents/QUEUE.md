# QUEUE.md — one change at a time

**Rule (user, 2026-08-06):** nothing new starts until the item in flight is **confirmed working
in-game by the user**, with no bugs and no compromises. New requests get appended here and
acknowledged, not begun.

**"Deployed" is not "done".** Only a boot moves an item out of §1.

---

## 1. IN FLIGHT — Origins Wunderfizz replacement (research done, not yet built)

**User, 2026-08-07:** replace Origins' native Wunderfizz machines with the mod's, keeping the
generator-power gating per location and the moving-location behaviour. "Make it seamlessly
replace the origins ones."

🛑 **This reverses an earlier instruction** recorded in `wunderfizz.gsc` ("NO ADDED MACHINE ON
ORIGINS. User, twice: get rid of them, keep the vanilla ones"). The user has been told; proceed.

### 🌟 THE BLOCKER IS DEAD — measured 2026-08-07

The queue said Origins' `scriptmover` set is 32/32 full, and it is (22 fields, 32 bits, from
`clientfields_zm_tomb_zclassic_tomb.txt`). **That only blocks REGISTERING a new field.** Origins
already registers the six the Wunderfizz needs, in `_zm_perk_random.gsc::init()`:

| field | bits |
|---|---|
| `perk_bottle_cycle_state` | 2 |
| `turn_active_perk_light_red` / `_green` | 1 + 1 |
| `turn_on_location_indicator` | 1 |
| `turn_active_perk_ball_light` | 1 |
| `zone_captured` | 1 |

**Drive those instead of registering `clientfield_perk_intro_fx`, and the wall is gone.**

### The design that follows from the architecture

Origins' machines are **map entities** — `getentarray( "random_perk_machine", "targetname" )` —
and everything the user wants kept is bolted to those entities:

- generator gating → `machine_power_indicators()` / `conditional_power_indicators()`, via
  `zone_captured`
- relocation → `machine_selector()`, plus `start_machine` (`script_noteworthy`) and the
  `j_ball` hidepart that gives one machine the ball
- the real model, animtree, unitrigger and all six clientfields

So **do not delete the entities and spawn the mod's script_models.** That path needs a new
clientfield (impossible) and throws away the gating and relocation. The correct build keeps the
native entities and `replaceFunc`s the *behaviour* onto them from `_zm_perk_random`.

📝 Note for whoever builds it: stock `get_perk_weapon_model()` already falls back to
`level._custom_perks[perk].perk_bottle`, so custom-perk bottles are supported natively.

---

## 1b. PREVIOUS IN FLIGHT — REVERTED, closed

### Diner fog — **REVERTED at v1.57.7**
User: *"still didn't move... forget it for now, just turn the fog back off entirely."* Both files
restored byte-identical to `d7cb7db` (pre-fog). `r_fog 0` is forced again and `.fog` is gone.
What was learned stands: fog **distance** cannot be changed on this build, and the ring did spawn
correctly (12/12) — it just never looked right. **Do not re-open.**

### Texture pack — **REMOVED at v1.57.7**
2,788 `.iwi` deleted, `mod.iwd` 2,210 MB → 53.9 MB. The mod's own 64 images kept (git-tracked was
the keep-list). Pack still at `H:\Claude\Projects Sources\add textures to mod`. The user loads
textures from `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead. README corrected.

<details><summary>old entry, superseded</summary>

### Diner fog: default OFF + ring stacked two rows high — **v1.57.6**

**Confirmed working already (2026-08-07 boot):** the ring spawns —
`[zm_qol] fog ring: 12 of 12 fog walls spawned around diner`.

Two defects the user's screenshot exposed, both fixed here:

1. **Default was fog ON.** Mode 1 ("pushed back") was the default and is a proven no-op —
   checkpoint 20 §2: fog *distance* cannot be changed on this build, only `r_fog` on/off. So every
   game started on stock fog and the user typed `.fog off` by hand. **Default is now 0 = off.**
   `.fog <number>` no longer claims to have moved anything.
2. **The ring was too short.** 600-tall walls at the boundary hid what sat just past the edge, but
   the distant hillside rose over the top. **Second row stacked at +500 → 24 walls, ~1100 tall.**
   Ring distance deliberately unchanged (user's choice: "raise them where they are").

**What to check:** boot Diner. Fog should be **off from the start with no command typed**, and the
cloud bank should now be tall enough to cover the hillside rather than sitting under it.

**The new log line reports both rows:** `fog ring: 24 of 24 ... (12 per row, 2 rows)`.

Verified offline: both files parse; deployed `mod.iwd` byte-identical to source; vector add and
vector indexing confirmed as stock GSC idioms; stock TranZit already places 587 createfx effects.

Never verified: whether `spawnfx` anchors the effect at its centre or its base.

</details>

---

## 2. QUEUED — in order, not started

1. **Pause-menu UI** — port the Strat Tester options menu (`H:\Claude\Strat-Tester-BO2`), header
   renamed **"Quality Of Life"**, exposing every existing chat command **plus** ones missing from
   the menu (infinite sprint, etc). Chat commands stay. Scoped already: `optionsstrattester.lua`
   881 lines, `options.lua` 560, `menu.gsc` 73; no LUI conflict with this mod's `ui_mp\`.
   🛑 A bad LUI file hard-crashes the game — this one ships alone.
2. **`night_mode 1` is broken** — the screen goes fully black (screenshot 2026-08-06). Came in from
   another script. Either fix it properly or remove it.
3. **`character` command does nothing** — no visible effect at all.
4. ~~Origins Wunderfizz replacement~~ — **moved to §1, in flight.**
5. **Galvaknuckles wallbuy on Bus Depot** — in the Tombstone room. Town, Farm and Diner already
   have one; Bus Depot does not. 🛑 Survival **only** — must NOT appear on TranZit proper, where
   the Diner wallbuy already covers it. Same `!is_classic()` gating as the other survival edits.
6. **Vulture Aid icon on the Wunderfizz** — the machine's perk icon set is missing Vulture.
7. **No prone points at Mob's Electric Cherry machine** — the +100 prone bonus does not fire there.
   Every other machine works, so this is likely a missing `vending_` tag for that machine.
8. **Solo must not behave like a custom game** — two parts:
   - a. Origins first-generator reward chest still gives Zombie Blood instead of double points, on
     the classic maps. NOTE: `qol_check_solo_status` shipped in v1.55.0 and the probe printed
     `expected=1 is_forever_solo_game=1`, so **re-verify before changing anything** — the flag is
     set, so if the chest is still wrong the cause is downstream of it.
   - b. The solo **intro cutscene** does not play — you get the custom-games loading screen instead.
9. **Death Machine pickup voice line** — the BO1 "Death Machine" announcer callout on pickup.
10. **Nuketown perk-machine placement** — Deadshot's icon lands at an angle, Speed Cola drops half
    into the ground in the back yard. Not diagnosed yet.
11. **Diner teddy bears** — the 3-bear secret-song easter egg on Diner survival (garage, diner,
    Juggernog room). **Blocked:** needs three `.where` readings from the user; coordinates will not
    be guessed.
12. **zm_refreshed weapon ports** — MP7 + Vector to all maps, Dragunov + Spas-12 to Nuketown and
    Mob, MGL to Mob, Remington transferable via fridge, B4KED's fixed Jetgun, **Quick Revive on
    Mob** (confirmed absent; `specialty_quickrevive_zombies` is in no zombies fastfile, so it needs
    shipping). ~400 assets into `mod.ff` — do these **one weapon at a time** with an ownership
    audit after each.

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
| v1.56.4 | **Wunderfizz: Origins' real FX + bear bottle on every map** — user: *"looks perfect, works perfect, basically identical to the actual wunderfizz in origins"* |
| v1.56.2 | **Tombstone on Nuketown** — all 12 perks confirmed |
| v1.55.x | **Who's Who** confirmed working |
| v1.54.1 | Origins generator progress bar reported fixed |
| — | **Every classic and survival map loads** — confirmed 2026-08-06 |
