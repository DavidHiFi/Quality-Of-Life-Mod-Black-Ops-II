# Checkpoint 27 — v1.62.10. Electric Cherry reverted to stock. Deployed, NOT booted.

Written 2026-08-09. Supersedes checkpoint 26 (v1.62.9 — **its two "fixes" were wrong and are gone**).
Keep 24 §2a (you can patch ONE LUI function) and §2c (offline Lua validation).
Keep 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

**Read §0, §1 and §2.**

---

## 0. THE SINGLE NEXT ACTION — an A/B, not a single test

1. **Mob of the Dead**, get Electric Cherry, **empty a full mag** next to a crowd, reload.
2. **Diner** (or Nuketown / Die Rise / Buried), same perk, same empty mag, same crowd.

**They must look and behave the same.** Mob and Origins now run **zero mod code** for this perk, so
they are a clean reference — the comparison settles "is the port correct?" by construction instead
of by argument.

Nothing else starts until that is confirmed — [[zm-qol-one-at-a-time]].

**Still deployed and NEVER booted, from earlier rounds:**

| version | how to test |
|---|---|
| v1.62.0 | Boot **Mob**, carry two plane parts at once. Log: `[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N` |
| v1.62.3 | Vulture's through-wall icons should have real shapes, not colour blurs |

🛑 v1.62.4 (Vulture perk-machine markers) is **measured broken** — `0 of 43 structs match`.
See checkpoint 24 §4.

---

## 1. 🌟 THE RULE THIS SESSION ADDED — A PORTED PERK IS NEVER MODIFIED

> **User, 2026-08-09:** *"don't change how electric cherry behaves because you're not meant to change
> the perk just leave it alone and then port it over to the maps that don't have it already. simple,
> same logic for literally any other perk (eg. who's who). No missing/wrong fx period."*

**The failure this corrects is subtle and worth stating precisely: v1.62.9's two changes were both
correct as bug-fixes and both wrong to ship.** Stock's consecutive-reload throttle really does make
reload #5 do nothing, and its 0.1s per-zombie stagger really does make a crowd resolve over two
seconds. Neither observation was hallucinated; both were traced to stock source and to
BO2-Reimagined deleting them too.

They were still wrong, because **the deliverable was a port, and a port's only correctness criterion
is parity with the thing being ported.** Improving stock moves the ported copy *past* parity, which
is the same defect class as leaving it short of parity — the user cannot tell "this is better than
Mob" from "this is broken" by looking at it, and neither can I.

**The line to hold:**

| allowed — closes a gap the port leaves | not allowed — moves past parity |
|---|---|
| register the perk on a map that never had it | delete a throttle stock ships |
| ship the fx/audio/model assets its chain needs | change a damage or radius curve |
| add it to the Wunderfizz table | add a watchdog stock does not have |
| supply an audio alias whose bank the map lacks (`zmqol_cherry_zap`) | "fix" a latch bug that also exists on Mob |

**Corollary that made the diagnosis possible: leave the donor maps running ZERO mod code.** Because
`zmqol_enable_electric_cherry()` returns at its first line on anything but the four ported maps, Mob
and Origins are an untouched baseline, and "is the port right?" becomes a two-minute A/B instead of
a three-round argument. Preserve that property for every future port.

📝 [[zm-qol-no-guessing-standard]] and the completeness audit are unchanged — "perfect or not at
all" now explicitly means *perfectly identical to the original*, not *perfect in my judgement*.

---

## 2. WHAT SHIPPED — v1.62.10

### Deleted outright

The pointer re-point (`level thread zmqol_ec_take_over()`) and all five functions behind it —
`zmqol_ec_take_over`, `zmqol_electric_cherry_reload_attack`, `zmqol_ec_check_reload_complete`,
`zmqol_ec_weapon_replaced_monitor`, `zmqol_ec_reload_watchdog` — plus every `[zm_qol] EC:` probe
line. 351 lines out of `quality_of_life.gsc`.

`level._custom_perks["specialty_grenadepulldeath"].player_thread_give` is now left exactly where
stock's `register_perk_threads()` put it, so **stock's own `electric_cherry_reload_attack()` runs on
every map.**

### Kept — all of it additive, none of it behaviour

- `zmqol_enable_electric_cherry()` — registers the perk on `zm_transit`, `zm_nuked`, `zm_highrise`,
  `zm_buried` by calling stock's own `enable_electric_cherry_perk_for_level()`; the
  `level.zmqol_ec_inited` one-shot guard around `init_electric_cherry()` stays (a second
  `registerclientfield( "electric_cherry_reload_fx" )` is fatal at load).
- `wunderfizz.gsc`'s entry for the perk.
- `qol_options.gsc::qol_opt_cherry_sound` — plays `zmqol_cherry_zap` on maps whose soundbanks lack
  Alcatraz's `zmb_cherry_explode` alias, and **returns early on `zm_prison` and `zm_tomb`**. This is
  a missing-asset fill, not a behaviour change.
- `zm_tomb/zm_tomb.gsc:200`'s survival-only clientfield mirror (gated `!is_classic()`).

### 🌟 THE FX AUDIT — the assets were already canonical, so the intensity had to be script

Run **before** touching anything, and it is the reason the diagnosis is not a guess:

| checked | result |
|---|---|
| the 6 lightning/arc materials mod.ff owns | **byte-identical** across `zm_prison`, `zm_tomb`, `zm_transit`, `zm_buried`, `zm_highrise`, `zm_nuked` and mod.ff |
| `rawfile vision/zm_electric_cherry.vision` | `ba7a920e…` in mod.ff, `zm_prison` **and** `zm_tomb` — one file, no per-map variant |
| `script clientscripts/mp/zombies/_zm_perk_electric_cherry.csc` | `198fc38c…`, identical to `zm_prison_patch.ff` — the **only** fastfile carrying it |
| tesla + alcatraz-cherry fx | present only in `zm_prison` and `zm_tomb`; `--load` order takes Mob's, and Mob is the perk's home map |
| tesla/lightning textures shipped by this mod | **none** — `images/` and `zone_assets/images/` carry none, so the pixels are the game's own |

With the chain canonical, the only remaining source of "overbearing" was v1.62.9's two deletions:
**no stagger** → every zombie's `tesla_shock` fx starting in the *same frame* instead of 0.1s apart,
reading as one bright mass; **no throttle** → reload #3+ playing full-strength fx where stock plays
a reduced set or none. The timeline corroborates it — v1.62.7 was **confirmed improved**, and
v1.62.9 is the only thing between that and this report.

### ⚠️ NOT CHANGED, and said out loud

**"Zombies untouched even up in my face" is stock's arithmetic.** From the user's own v1.62.8 log:
`radius = linear_map( clip_fraction, 1.0, 0.0, 32, 128 )` → a 39/40 clip is **radius 34 units,
27 damage**, and the log read `in_radius=1 nearest=31`. Reproduced exactly. Mob and Origins behave
the same — `patch_zm.ff` owns `_zm_perk_electric_cherry.gsc` and loads on every map.

Two stock quirks are deliberately **back**: a cancelled reload eats the next zap, and reload #5 in
quick succession does nothing. Both are on Mob and Origins too.

### Verified before hand-off

- parses — `quality_of_life.gsc`, `qol_options.gsc`, `wunderfizz.gsc`, and `zm_expanded.csc` (`-i client`)
- **0** dangling references to any of the five removed symbols, anywhere in `scripts/`
- deployed `mod.iwd` **byte-identical to source** (`0013564d3da5ae45780a49ae146224e5`) and contains
  **0** occurrences of the removed symbols
- deployed `mod.json` reads `1.62.10`
- `mod.ff` md5 `587f2f7c…` **unchanged** — `.gsc`-only round, no `build_ff.bat` needed
- `README.md` makes no Electric Cherry claim, so no doc correction was owed

---

## 3. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

Top to bottom, one at a time. Scope rule: *"if I ask you to add something don't just consider Diner —
add it to all maps unless specified otherwise."* **Plus the new rule in §1: port, never tune.**

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | **EC half done pending this boot**; Who's Who half scoped, not started — QUEUE §A2 |
| 2 | Zombie Blood power-up from Origins onto every map | not started |
| 3 | Blood Money power-up, dropping from kills rather than dig sites | not started |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

**Who's Who is next once EC is confirmed**, and §1 applies to it directly: ship the five stock calls
`activate_chugabud_effects_and_audio()` makes that the mod currently does not (QUEUE §A2), the two
`mod.ff` assets, and **nothing else**. 🛑 `level.chugabud_shellshock` is set nowhere in the 2,093-file
stock dump, so the shellshock never fires in stock either — **do not add it**; that would be exactly
the mistake this checkpoint exists to prevent.

Also outstanding and unstarted: QUEUE §0B, **every chat command must also be a dvar/console command**
— [[zm-qol-commands-as-dvars]].
