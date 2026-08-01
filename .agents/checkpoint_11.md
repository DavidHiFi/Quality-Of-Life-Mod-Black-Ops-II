# Checkpoint 11 — v1.8.2. Origins survival work in progress; 5 items outstanding.

Written 2026-08-02. Supersedes checkpoint 10 (keep 10 for the gamemode recipe in
its §8 and the asset-chain pattern in its §2). **Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game (user-verified)
- **TranZit**: Diner, Tunnel, Cornfield, **Power Station**, classic.
- **Origins**: Excavation Site, Crazy Place, Church (tank removed), Trenches loads.
- **Docks** and **Cell Block** (Alcatraz survival).
- **Die Rise survival** — all three locations, fixed in v1.7.0.
- **Nuketown** — exits clean, no errors.
- **`.p <amount>` and `.god`** chat commands, `sv_cheats 1` auto-set.
- Origins dig sites hidden on survival (v1.8.1).
- Classic Die Rise Olympia wallbuy — correct again after the v1.4.0 mapents revert.

### 🛑 OUTSTANDING — the user's explicit list, 2026-08-02
| # | item | status |
|---|---|---|
| 1 | Origins survival: mystery box still demands generators | **partially addressed v1.8.2 — perks only** |
| 2 | Origins survival: Speed Cola machine missing | **v1.8.2 attempts this — UNTESTED** |
| 3 | Origins survival: easter eggs interactable (lightning staff switch in tank-station generator) | ❌ not started |
| 4 | Origins Trenches: 2 Wunderfizz machines (gen 2 + gen 3) should alternate between just those two | ❌ not started |
| 5 | Origins Trenches: disable the 3 giant robots (they let you reach wind staff parts) | ❌ not started |
| 6 | Buried Borough: `subwoofer_flings_zombie` clientfield mismatch | ❌ not started |
| 7 | Maze: no zombies — **probe shipped in v1.6.4, never yet run** | ❌ needs one Maze load |
| 8 | Custom gamemodes missing from menu + survival locations showing the parent map name | ❌ see checkpoint 10 §8 |

### The single next action
Load **Trenches** and confirm Speed Cola now appears, then load **Maze** and send
the `[zm_qol] MAZEZONE` lines — item 7 has been blocked on that one run for
several versions.

---

## 1. WHAT v1.8.2 DID, AND WHAT IT DID NOT

`scripts\zm\replaced\zm_tomb_capture_zones.gsc::setup_perk_machines_not_controlled_by_zone_capture`
now adds **every** perk specialty to `level.zone_capture.perk_machines_always_on`
when `!is_classic()`.

Why that is the right lever: `check_perk_machine_valid` consults that list, and
anything absent from it is owned by a generator zone and gated behind capturing
it. Speed Cola's machine belongs to `generator_mid_trench`, which is never
captured on a survival arena — hence a machine that never finished spawning while
part of its geometry still showed through the wall.

**It does NOT unlock the mystery box.** Boxes are registered separately via
`register_mystery_box_for_zone` inside
`register_elements_powered_by_zone_capture_generators`, and the "turn on the
power" prompt comes from `magic_box_stub_update_prompt`. Both are already ported
into our copy, so the fix is a local edit — see §2.

---

## 2. HOW TO FINISH ITEMS 1-5 (all in files we already own)

Everything below is in `scripts\zm\replaced\zm_tomb_capture_zones.gsc` unless
stated. **Gate every change on `!is_classic()`** — the standing instruction is
that classic Origins stays stock.

**1. Mystery box without generators.** In
`register_elements_powered_by_zone_capture_generators`, the three location
branches (`trenches`, `excavation_site`, `church`, lines ~166/179/189) each call
`register_mystery_box_for_zone(...)`. On `!is_classic()`, skip only those
`register_mystery_box_for_zone` calls, then confirm the box still spawns —
`enable_mystery_boxes_in_zone` / `disable_mystery_boxes_in_zone` are both hooked,
and `magic_box_stub_update_prompt` is what prints the power prompt, so that is the
place to force the buyable prompt if skipping registration is not enough.

**3. Easter eggs.** The staff switch inside the tank-station generator is the
elemental-staff quest. Reimagined replaces the whole quest chain and we ported
none of it — see `zm_tomb_reimagined.gsc:20-30`
(`zm_tomb_main_quest`, `zm_tomb_quest_air/elec/fire/ice`). Do **not** bulk-port
those; they carry Reimagined balance. Prefer deleting the trigger entities in the
loc script the way `zm_tomb_loc_church::disable_tank` does — find them with
`Unlinker --include-assets mapents` on `zm_tomb.ff` and grep for the staff/chamber
triggers.

**4. Wunderfizz alternation.** `register_random_perk_machine_for_zone(<generator>,
<name>)` is what places them — Trenches registers `starting_bunker`,
`trenches_right`, `trenches_left`. Restrict the survival set to the two the user
wants (gen 2 + gen 3).

**5. Giant robots.** Origins robots are `zm_tomb_robot*` scripts; find the
entities in the mapents and delete them from the Trenches loc `main()`, same
pattern as `disable_tank`.

---

## 3. HARD-WON RULES — do not relearn these

1. **Never bulk-import Reimagined mapents.** v1.3.0 did and silently turned Die
   Rise's Olympia wallbuy into a Ballista. Patch tags surgically instead; the
   mapents are **CRLF** and an `awk` rewrite converts them to LF (54,000-line
   bogus diff). Use `[IO.File]::WriteAllText` and check with `od -c`.
2. **Before porting a Reimagined file, grep it for `scripts\zm\reimagined\` and
   `scripts\zm\replaced\` references.** `zm_tomb_dig.gsc` needed two
   `_zm_weap_bouncingbetty` calls stripped or it would have been an unresolved
   external that killed Origins entirely — the same failure that broke every
   TranZit location in v1.1.1.
3. **Diff the Reimagined function against the stock dump first and take the
   delta.** Its `buried_zone_init` differs by one line; its
   `init_level_specific_wall_buy_fx` only renames ak74u→vector, a balance change
   this project does not want.
4. **`mod.iwd` serves scripts but NOT rawfiles.** Rawfiles (`.txt`, `.atr`,
   `.asd`) must be declared in `mod_locations.zone` and linked into `mod.ff`.
   Proven in v1.6.5.
5. **Only TranZit ships a `so_zsurvival_*.ff`.** Anything living solely in
   `so_zclassic_*`/`so_zencounter_*` is absent on every other map's survival —
   missing xmodels render nothing while `.model` still reads correctly.
6. **Two opposite zone failure modes:** too few zones enabled → instant death /
   death barrier (Tunnel, Cell Block, Power); too many → zombies spawn across the
   whole map and never reach you (Maze).
7. **Clientfield mismatches have a direction.** "not registered on the server" =
   fix server-side (v1.4.0 Die Rise). "not registered on the client" = fix
   client-side, needs a `.csc` edit and a `build_ff` relink (v1.7.0 Die Rise).
8. **`build.bat` can print `[ok]` and still not deploy** if Plutonium holds the
   files. Always verify the deployed `mod.ff`/`mod.iwd` size and timestamp.
9. **Validate before shipping:** `gsc-tool -m parse -g t6 -s pc -y` over every
   `.gsc` (34 files, all passing). Syntax only — it does not resolve externals.

---

## 4. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe` (use `-i client` for `.csc`).
- OAT Unlinker — `H:\Claude\oat-windows\Unlinker.exe`; `--list <zone.ff>` answers
  "is this asset actually loaded?", `--include-assets mapents` dumps map entities.
- Mapents are plain text and readable straight out of `mod.iwd`.
- GitHub: `github.com/ridgelanded/zm_qol`, private, tagged **v1.1.1 → v1.8.2**.
  Separate commit per fix, `chore: release vX.Y.Z` + tag each round.
