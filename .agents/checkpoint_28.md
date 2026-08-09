# Checkpoint 28 — v1.63.1. Barrier bug fixed, Who's Who visuals ported, EC answered. NOT booted.

Written 2026-08-09. Supersedes checkpoint 27 (v1.62.10, the Electric Cherry revert — still unbooted,
and it rides along in this build).
Keep 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

**Read §0 and §1.** Full write-up: `QUEUE.md` §IN FLIGHT.

---

## 0. THE SINGLE NEXT ACTION

1. **Diner Survival** — hold a window. Nothing should cross intact boards.
2. **Who's Who** on Diner / Nuketown / Origins — buy it and go down. Expect the blue afterlife
   filter + the `zm_whos_who` vision, the sting and looper audio, and a glow on the downed body.
   🛑 **Boot Die Rise too** — `mod.ff` now owns two of its assets.
3. **Electric Cherry** — **empty the mag completely**, then reload into a crowd at round ≤10.

Also still unbooted from earlier rounds: **v1.62.0** (Mob, two plane parts at once) and **v1.62.3**
(Vulture through-wall icon shapes). 🛑 v1.62.4's Vulture machine markers are measured broken.

---

## 1. 🌟 THE THREE METHODS THAT DID THE WORK — reuse these

### a. When the user gives you a clip, DECODE IT. It is primary evidence.

Three rounds of arguing about Electric Cherry ended in one step. `ffmpeg` lives at
`C:\Program Files\File Converter\ffmpeg.exe` — the only build in this workspace with a working AV1
decoder; the two BlackOpsII SoundStudio copies carry libaom only and fail on NVIDIA AV1 captures.
Extract frames, then **crop the HUD and tile the crops into one contact sheet** so a numeric
sequence can be read at a glance:

```
ffmpeg -i clip.mp4 -vf "fps=8" -q:v 2 clip/f_%03d.png
ffmpeg -i "clip/f_%03d.png" -vf "crop=360:80:1540:930,tile=4x17:margin=4:padding=4:color=white" sheet.png
```

The ammo counter read `8/49 -> 7/49 -> 8/48 -> 7/48 -> 8/47 -> 7/47 -> 8/46` — **one bullet fired,
then reload, every time.** That single observation explained the whole report, and no probe build
was needed. Arithmetic in QUEUE.

### b. Decompile the SHIPPED bytecode, not the gsc-dump, when a claim is load-bearing.

`Unlinker --include-assets script -o <dir> patch_zm.ff`, then
`gsc-tool -m decomp -g t6 -s pc --t6fixup <file>`. Used twice, and the second use cracked the
barrier bug: **`_zm_blockers::blocker_disconnect_paths()` is an EMPTY STUB in the shipped game.**
The function whose name promises to close a barrier's mantle path does nothing at all. So the only
thing keeping zombies out of a boarded window is that barrier-bound zombies are goal-driven through
`tear_into_building()` — and any zombie that skips that (`script_string "find_flesh"` ->
`should_skip_teardown()`) free-paths and mantles straight over six intact planks.

### c. 🛑 THE PRE-MORTEM CAUGHT A THREE-MAP HARD DROP. Run it every time.

The first draft of the Who's Who client half called `vsmgr_register_visionset_info()` inline from
`perks()`. [[t6-visionset-registration-timing]] flagged it; the check confirmed it:

- on the client, `level.vsmgr` is created by `_visionset_mgr::init()`, called from
  `clientscripts\mp\zombies\_zm.csc:39` — inside the client `_zm::init()`
- this mod's `.csc` `main()` runs **before** that, and the proof is a shipped behaviour: the perk
  flags `perks()` sets are read during that same init, and the perk icons work today
- so the call lands on an undefined `level.vsmgr` and **silently does nothing**, while the server
  still registers `zm_whos_who` in `turn_chugabud_on()` -> different visionset counts -> a different
  `visionset_slot` bit width -> `EXE_CLIENT_FIELD_MISMATCH` for everyone at load

Fixed by polling (`zmqol_whoswho_register_visionset`), which registers the first frame the manager
exists and while `vsmgr_initializing` is still 1. The window opens at `_zm.csc:39` and closes only at
`finalize_clientfields()` (an `on_finalize_initialization` callback, long after map init).

**Generalise: on the client, nothing that touches `level.vsmgr` may run from a mod `.csc` main().**
Die Rise gets away with the direct call only because it registers after `start_zombie_stuff()` has
run `_zm::init()`.

---

## 2. WHAT SHIPPED

| # | change | file |
|---|---|---|
| 1 | two `zone_diner_roof` ground spawners disabled — outside the diner window line, `script_string "find_flesh"` | `scripts/zm/locs/zm_transit_loc_diner.gsc` |
| 2 | Who's Who's three clientfields + `whos_who_client_setup` + visionset prio; Buried dropped | `quality_of_life.gsc` |
| 3 | client twin: same three with our own filter/audio callbacks, polled visionset registration, afterlife filter setup | `zm_expanded.csc` |
| 4 | `material generic_filter_afterlife`, `rawfile vision/zm_whos_who.vision` | `zone_source/mod_locations.zone` |
| 5 | `zmqol_ww_activate` / `zmqol_ww_looper` aliases + the two Die Rise FLAC payloads | `soundbank/`, `sound/` |
| 6 | Electric Cherry: **no change** — measured as vanilla from the user's own clip | — |

### 🛑 Why Buried is dropped — `actor` bit budget, counted field by field

| map | stock actor | +1 glow bit |
|---|---|---|
| `zm_transit` | 5/32 classic, 4/32 survival | fits easily |
| `zm_nuked` | 4/32 | fits easily |
| `zm_tomb` | **31/32** | lands on exactly 32/32 — legal, zero margin forever |
| `zm_buried` | **32/32 classic** | would be 33 -> fatal at load |

Buried survival is only 13/32, but a perk present in one mode of a map and absent in the other is
the half-implementation this project does not ship.

### Verified before hand-off

- all four scripts parse (`gsc-tool`, incl. `-i client`)
- `mod.ff` links with 0 errors and the same 34 pre-existing sound warnings
- asset list **3811 -> 3816**: the 5 additions (2 requested + 3 pulled dependencies) and nothing
  else; **nothing removed, nothing re-owned**
- the two dependency images need no loose `.iwi` — `minimap_icon_chugabud` and the Who's Who bottle
  texture are already Die Rise-only headers inside `mod.ff` with no loose copy and they render
  correctly, so stock pixels resolve from the ipaks on every map
- both sound aliases and both payloads confirmed inside the built banks at byte-exact sizes; the
  doubled `.flac.flac` seen on re-dump is an Unlinker artifact — the confirmed-working
  `zmqol_cherry_zap` shows the same
- all 6 deployed files byte-identical to source; the three new client symbols confirmed inside the
  **deployed** `mod.ff`

### ⚠️ Residual risks, stated not hidden

1. **Origins is now at exactly 32/32 `actor` bits.** Legal — stock Buried classic ships at 32 — but
   nothing may ever take another actor bit there.
2. **`mod.ff` now owns two Die Rise assets.** Byte-copies, but Die Rise must be booted.
3. The `zmb_duck_ww` mixer snapshot is Die Rise-only and is **not** ported; the looper's Duck column
   was cleared. Effect: other audio is not ducked under the Who's Who looper. Everything audible is
   present.

---

## 3. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | **both done pending this boot** |
| 2 | Zombie Blood power-up from Origins onto every map | not started |
| 3 | Blood Money power-up, dropping from kills | not started |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command must also be a dvar — [[zm-qol-commands-as-dvars]].
The standing rule from checkpoint 27 §1 still governs all of them: **port it, never tune it** —
[[zm-qol-port-never-tune]].
