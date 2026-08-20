# Checkpoint 92 — Die Rise weapons block WRITTEN AND VALIDATED, NOT BUILT. Resume mid-task.

Written 2026-08-20 at the user's 90% usage notice. They are closing the terminal and will return in
~2 hours when the limit resets, and will type `.`.

**`.` MEANS: FINISH THE DIE RISE WEAPONS BLOCK. Do not re-derive anything below — it is all verified
and the source edits are already on disk. Start at §3.**

---

## 0. STATE — READ THIS FIRST

| | |
|---|---|
| deployed / committed | **v1.99.95** — unchanged, still the last built version |
| working tree | **DIRTY.** Three source files edited, described in §2 |
| built? | **NO.** `mod.json` is still `1.99.95`. `build.bat` has NOT been run |
| validated? | **YES** — both `.gsc` parse clean under gsc-tool, the `.lua` parses clean under luaparse |
| still unbooted from before | v1.99.93, v1.99.94, v1.99.95 (see checkpoint 91) |

---

## 1. WHAT THE USER ASKED FOR, 2026-08-20

They went hunting online for a pre-patch Die Rise fastfile and found something better: **BO2-Remix's
feature list**, whose source is already in the workspace at `H:\Claude\BO2-Remix\`.

**IN FLIGHT — the Die Rise / Weapons block, four items, verbatim:**
> *"Semtex wallbuy added by b23r / Sliquifier kills till round 255 / Sliquifier continues to chain
> while put away / Sliquifier no longer drops extra goo — get that done"*

**EVERYTHING ELSE THEY LISTED IS QUEUED, NOT STARTED.** Written up in full in §5 so it is not lost.

---

## 2. THE THREE FILES ALREADY EDITED (all source-only, nothing built)

### `scripts\zm\zm_highrise\zm_highrise.gsc` — 938 → ~965 lines
1. `main()` gained one line:
   `replaceFunc( maps\mp\zombies\_zm_weap_slipgun::explode_to_near_zombies, ::zmqol_explode_to_near_zombies );`
2. `init()` gained `precachemodel( "t6_wpn_grenade_semtex_world" )`, a
   `register_zombie_death_animscript_callback( ::zmqol_slipgun_death_response )`, and two threads
   (`zmqol_slipgun_prenerf_watch`, `zmqol_semtex_wallbuy`).
3. A large banner + six new functions appended at the end of the file:
   `zmqol_slipgun_prenerf_watch`, `zmqol_explode_to_near_zombies`, `zmqol_slipgun_death_response`,
   `zmqol_semtex_wallbuy`, `zmqol_spawn_wallbuy_weapon`, `zmqol_play_chalk_fx`.

### `scripts\zm\quality_of_life.gsc`
`create_dvar( "sliquifier_prenerf", 0 )` and `create_dvar( "semtex_wallbuy", 0 )` added to the
PATCHES block, with a banner recording why the sliquifier row is no longer being held back.

### `ui\t6\menus\optionssettings.lua`
Two rows appended to `CreateQolPatchesTab` after a spacer — **SLIQUIFIER PRE-NERF**
(`sliquifier_prenerf`) and **SEMTEX WALL BUY** (`semtex_wallbuy`). Comment count updated to 9 total.

A pre-edit backup of the map script is at
`%TEMP%\claude\H--Claude\b860ae21-…\scratchpad\zm_highrise.gsc.bak`, and the appended block alone at
`…\scratchpad\highrise_append.gsc`.

---

## 3. 🛑 THE NEXT ACTIONS, IN ORDER

1. **One open lever, and it is worth 60 seconds before building.** The very last thing being read
   when the session stopped was stock's own wall-buy placer,
   `_zm_weapons.gsc:1025`, which picks its model with **`model = getweaponmodel( weapon )`** rather
   than a hard-coded name. If `getweaponmodel( "sticky_grenade_zm" )` returns a real model on Die
   Rise, use **that** instead of the literal `"t6_wpn_grenade_semtex_world"` currently in
   `zmqol_semtex_wallbuy()` — it removes the last piece of judgement from the feature and makes the
   model the game's own answer. Check `getweaponmodel` usage in the dump; if it is not conclusive
   offline, keep the literal (it IS verified present in `zm_highrise.ff`) and say so.
2. Bump `mod.json` to **1.99.96**.
3. `build.bat` from PowerShell (`Set-Location …; cmd /c ".\build.bat"`). **`build_ff.bat` is NOT
   needed** — no `.csc` and no `zone_assets\` change.
4. Verify deployment properly, per the standing rule that `[ok]` proves nothing: the new symbols
   (`zmqol_spawn_wallbuy_weapon`, `sliquifier_prenerf`) inside the deployed `mod.iwd` opened as a
   zip, **and** `optionssettings.lua` hashed against Plutonium's `raw\` shadow copy.
5. Update `README.md` (and the GitHub description if the headline set changed), commit, tag.
6. Give the user the plain-language summary + the boot checklist, then append §5 to `QUEUE.md` /
   `QUEUE_LIST.md`.

---

## 4. THE EVIDENCE — VERIFIED, DO NOT RE-DERIVE

Every line of it was measured this session. The long-form version is in the banner at the bottom of
`zm_highrise.gsc`; this is the index.

- **Remix's shipped build matches its source.** `BO2-Remix\scripts\` holds **compiled** `\x80GSC`
  (Dec 2022); `BO2-Remix\src\scripts\` is the source. Decompiling `Remix2_highrise.gsc` confirmed the
  `main()` replaceFunc list is identical, so the commented-out `add_slippery_spot` / `slip_bolt` /
  `pool_of_goo` replaceFuncs really are dead — **Remix does NOT disable the slippery-spot mechanic.**
- **Only ONE stock function is replaced for the sliquifier:** `explode_to_near_zombies`, and Remix's
  copy differs from stock by exactly one added line, `enemy.slipgun_marked = 1`.
- **`level.slipgun_damage` is the value that matters.** `_zm_weap_slipgun.gsc:65` computes it once
  from `slipgun_max_kill_round`; setting the zombie_var after init does nothing on its own.
- **`ai_zombie_health()` saturates** (`_zm.gsc:3605` returns `old_health` on wrap), so
  `ai_zombie_health( 255 )` is the curve's maximum, not an overflow.
- **reslip = 0 really does mean "no extra goo".** `:741`/`:745` gate every re-slip pool on
  `reslip_max_spots` (8) and `reslip_rate > 0` (6). The bolt's own pool comes from
  `slip_bolt` → `add_slippery_spot` (`:645`) and is untouched.
- **Death callbacks run in registration order and the first `true` wins**
  (`_zm_spawner.gsc:1840`). Stock's slipgun callback is registered at `:49`. Ours is a pure fallback
  and is order-independent anyway, because for a chain-marked corpse it performs the identical two
  calls stock's would have.
- **Die Rise already has everything the semtex wall buy needs.** `zm_highrise.gsc:848`
  `add_zombie_weapon( "sticky_grenade_zm", …, 250, "grenade", "", 250 )`; `:870`
  `include_weapon( "sticky_grenade_zm", 0 )` keeps it out of the box, so the wall buy is the only
  source on the map. `_zm.gsc:1227` loads `level._effect["sticky_grenade_zm_fx"]` unless
  `level._uses_sticky_grenades` is cleared — **grepped every writer in the dump: only Buried and Mob
  of the Dead clear it.** `_zm_weapons.gsc:1975` `weapon_spawn_think` has an explicit
  `weapontype(…) == "grenade"` branch.
- 🌟 **THE MODEL — measured, and this is where the mod departs from Remix.** Remix draws this wall
  buy with `t6_wpn_claymore_world`, i.e. a claymore where a semtex should be. `Unlinker --list` over
  the real fastfiles shows **`t6_wpn_grenade_semtex_world` IS in `zm_highrise.ff`**, following the
  `t6_wpn_*_world` convention every other wall buy on the map uses. The name Remix's own
  commented-out Buried line reaches for, `t6_wpn_grenade_sticky_grenade_world`, is **in no zombies
  fastfile at all**. `weapon_mp_sticky_grenade` exists but only in `zm_highrise.ff` and is the
  third-person model, not a wall-buy model.
- **Every helper called is stock and resolvable:** `wall_weapon_update_prompt` (`:1118`),
  `weapon_spawn_think` (`:1973`), `get_weapon_hint` (`:1537`), `get_weapon_cost` (`:1543`),
  `get_weapon_display_name` (`:1565`) all in `_zm_weapons`, which `zm_highrise.gsc` already
  `#include`s; `unitrigger_force_per_player_triggers` (`:32`) and `register_static_unitrigger`
  (`:198`) in `_zm_unitrigger`, reached qualified. `spawnfx` + `triggerfx` is stock's own pattern
  (`maps\mp\_fx.gsc:248-256`). `useweaponhidetags` on a throwaway wall model is stock's own pattern
  (`_zm_weapons.gsc:922`, `:1036`).
- **Both rows are Die Rise-only by construction, not by a runtime guard** —
  `maps\mp\zombies\_zm_weap_slipgun` ships in `zm_highrise_patch.ff` and nowhere else, so every line
  lives in the map script (AI_CONTEXT rule 2).

### Pre-mortem already run, and the two things it changed
- **The dvar read was moved to AFTER `flag_wait( "initial_blackscreen_passed" )`** in
  `zmqol_semtex_wallbuy()`. `create_dvar()` only writes when the dvar is unset, and root-init vs
  map-init order is not guaranteed — reading early would have made a first-ever boot with the row on
  silently read 0.
- **`precachemodel` was moved into `init()`**, which is inside the precache window (`added_weapons()`
  calls `include_weapon` from the same place), instead of being left in the post-blackscreen thread
  where Remix has it.

### 🛑 THE ONE RESIDUAL RISK TO TELL THE USER
The position `( 2119, 1826, 3115 )` and angles `( 0, 270, 0 )` are **Remix's, tuned against the
CLAYMORE model**. The semtex model has a different pivot and bounding box, so it may sit at a
visibly wrong angle or offset on the wall. There is no offline test for this. **The one thing to
look at on the first Die Rise boot is whether the semtex sits flat on the wall.** If it does not,
that is a numeric tweak to the angles/origin, not a rethink.

---

## 5. QUEUED — EVERYTHING ELSE THE USER ASKED FOR IN THE SAME MESSAGE

Not started. **Do not begin any of these until the Die Rise block is confirmed working in game.**

1. **Claymore wall buys** on TranZit's **Farm, Bus Depot and Town** (Remix's
   `src\scripts\zm\zm_transit\remix\_transit_weapons.gsc` — three
   `spawn_wallbuy_weapon( …, "claymore_zm_fx", "claymore_zm", "t6_wpn_claymore_world", … )` calls at
   `(550,-1363,168)`, `(8826,-5777,105)`, `(-6319.88,5428,-13)` ). The generic placer
   `zmqol_spawn_wallbuy_weapon()` this session added already covers it, but claymores need the
   `claymore_unitrigger_update_prompt` / `buy_claymores` branch that was deliberately dropped.
2. **Remix's NO POWER game mode** (`no_power 1`: disables the turbine workbench and the jet gun).
   🛑 **DVAR COLLISION — flag this to the user before building.** `no_power` is ALREADY a zm_qol
   CHEATS row, "NO POWER NEEDED", meaning *perks and doors work without power* — very nearly the
   opposite. Two different features cannot share the name, and per the standing rule an existing
   dvar must never be renamed. The new one needs a different name.
3. **`anim_pap_camo_mob` / `anim_pap_camo_buried` / `anim_pap_camo_origins`** as three separate
   toggles in the PATCHES tab. 🛑 The tab already has a single `anim_pap_camo` row covering all
   three maps — decide with the user whether the three replace it or sit under it.
4. **`disable_player_quotes`** as a toggle at the **bottom of the SOUNDS tab**.
5. 🌟 **THE INSTALLER — the biggest item, and it is its own project.** A Windows `.bat` the user
   ships with the release, "super simple and clean, simple yes or no options", one script:
   - install / update the base mod;
   - **optional texture pack** → copies `H:\Claude\Projects Sources\zm_qol\Optionals\images\` into
     `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. **Must warn it overwrites any custom textures
     already there.** 🌟 This is the resolution of long-running queue item 34 — the pack goes in the
     PLAYER's images folder, not into the mod, which is what every failed attempt was trying to do.
   - **optional custom sounds** → the 3 files in
     `…\zm_qol\Optionals\zone\` into `%LOCALAPPDATA%\Plutonium\storage\t6\zone\`. **Must warn it
     replaces custom sounds already there.** No game files are touched.
   - **optional ReShade** for Plutonium, adapted from the user's own script at
     `E:\Miscallaneous\Scripts` — **rework it so it does not need to keep running in the
     background**, ship only the files that are actually needed (that folder is cluttered), and
     apply the **`BO2.ini` preset by default**.
   - **clean uninstall** of previous mod versions before installing a new one;
   - **check GitHub for a new release**, update the package and remove files that are no longer part
     of it.
   🛑 Read `Optionals\` before writing any of it — its contents have not been inspected yet.

---

## 6. FIRST BOOT, WHENEVER IT HAPPENS

Unchanged from checkpoint 91 §2, plus this session's:

1. **Die Rise, PATCHES tab.** SLIQUIFIER PRE-NERF on → the Sliquifier one-shots at high round, keeps
   chaining after switching weapons, and stops leaving extra goo pools under chained corpses (the
   pool where the bolt lands still appears). SEMTEX WALL BUY on → restart the map, then look for the
   semtex on the wall; **check it sits flat** (see §4's residual risk).
2. Checkpoint 89 §4's list for v1.99.93; PERK LIMIT's red ⨯ for v1.99.94; DSR 50 recoil for v1.99.95.
3. Older backlog: jet-gun overheat crash test, Deadshot head lock-on probe, checkpoint 87 §0.
