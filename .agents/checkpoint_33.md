# Checkpoint 33 — Diner completed; Solo Play fixed. v1.62.9 → v1.68.0.

Written 2026-08-11. Supersedes 32 for status.
**Keep 32 §1 (the frametime bug is still unattributed) — it is the only open item from it.**
Keep 31 §1 (`*_lerp` trap) and §2 (LUI blind spot), 30 §3 and §5, 29 §2–§3, 28 §1, 24 §2a/§2c,
23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **Solo Play lobby header** | ✅ confirmed — reads SOLO PLAY (v1.65.6) |
| **Solo Classic intro cutscenes** | ✅ confirmed (v1.65.8) |
| **Diner Pack-a-Punch visible again** | ✅ confirmed (v1.66.3) |
| **Diner buildable riot shield** | ⚠️ parts spawn, models + HUD icons + craft sounds shipped — **never confirmed built and fired** |
| **Diner three teddy bears** | ✅ placements confirmed "perfect" (v1.67.10) — 🛑 **the song has NEVER been tested** |
| **Diner Semtex wall buy** | 🚧 v1.68.0, deployed, never booted |
| **Frametimes** | 🛑 **still open, still unattributed** — see §3 |
| `qol_perf_probe` | ⚠️ in the build, inert, **KEEP** until the frametime cause is known |
| `zmqol_bear_live`, `zmqol_loadmovie_probe`, `zmqol_pap_visibility_probe` | ⚠️ scaffolding — see §4 |

**Next action: the one boot that closes Diner** — interact with all three bears and confirm the
secret song plays, build and fire the riot shield, and look at the Semtex wall buy. Then §3.

---

## 1. 🌟 THE FINDING THAT EXPLAINS MOST OF THIS SESSION

**Diner Survival loads `so_zSURVIVAL_zm_transit.ff`. A large amount of TranZit content ships only
in `so_zCLASSIC_zm_transit.ff`, which it never loads.** Every one of these traced back to it:

| symptom | what was actually missing |
|---|---|
| shield part rendered as a black slab | `xmodel t6_wpn_zmb_shield_dolly` / `_door` |
| carried-part HUD icon was a checkerboard | `material zm_hud_icon_dolly` / `zm_hud_icon_cardoor` |
| no sound when adding a part | `zmb_buildable_piece_add` / `_complete` / `_loop` |

All now shipped in `mod.ff` / the mod's sound bank. `so_zclassic_zm_transit.ff` was added to
`build_ff.bat`'s `--load` list, **last**, so first-load-wins means it can only supply what no
earlier fastfile has.

🛑 **The three sound aliases keep their STOCK names**, against the usual `zmqol_` rule, because
core plays them from `_zm_buildables::player_build()` — called unqualified and unthreaded from the
same file (`:1983`), so `replaceFunc` cannot reach it. The alias itself has to resolve. Blast radius
was measured first: those names exist in **exactly one bank in the game**, loaded on TranZit Classic
only, and what ships here is a byte copy of it.

📝 **The general lesson:** before porting anything to a Survival location, check which fastfile
carries its assets. `Unlinker --list so_zclassic_<map>.ff` vs `so_zsurvival_<map>.ff`.

---

## 2. HOW THE DINER BUILDABLE ACTUALLY WORKS — the two calls nobody would guess

1. **`level.init_buildables`** — core `_zm_buildables::init()` does its resets and *then* calls this
   pointer. **Nothing in the 2,093-file stock dump ever assigns it**, only reads it, so it is free
   to take, and the client half (`_zm_buildables.csc:10`) uses the identical hook.
2. **`think_buildables()`** — registering a buildable puts NOTHING in the world. This is what runs
   each `triggerthink`, which builds the bench stub, which is what calls `generate_piece()`. It is
   threaded from `zm_transit_classic.gsc:108` **and nowhere else**, so Survival never ran it. That
   was the whole reason v1.66.0's parts did not appear.

Also: the bench trigger and the shield on the table carry `script_gameobjectname "zclassic"` and
`_zm_gametype.gsc:110 game_objects_allowed()` **deletes** them. Re-tagged to `"[all_modes]"` from the
location `precache()`, which `rungametypeprecache()` runs *before* the filter is threaded.

⚠️ Buildables cost a `toplayer` clientfield — `getminbitcountfornum( level.buildable_piece_count )`,
registered on the first `add_zombie_buildable()` on **both** sides. 27 is stock TranZit's own number,
kept for parity: 5 bits.

---

## 3. 🛑 FRAMETIMES — STILL OPEN, AND STILL WITHOUT A MEASUREMENT

Unchanged from checkpoint 32 §1. Reported again this session (`91 FPS / 30 LOW / FRAMETIME 12.8` on
Diner), **no probe run yet**.

**Do not ship a third guess.** The next step is the user's, and costs them ten seconds:

- **`qol_perf_probe 1`** — reads the dvar live, no map reload. Sleeps every always-on per-player loop
  (health bar 10Hz, zombie counter 4Hz, shield HUD 20Hz, perk slots 20Hz, hitmarkers per damage) and
  changes nothing else.
  - still framey → the mod's per-frame **scripts** are innocent; look at `mod.ff` (3,884 assets now)
    and the sound bank.
  - smooth → it **is** the scripts, and those five loops are the whole suspect list.
- **`developer_script 1`** — it has been `"0"` all session, so per `ERROR_CATALOGUE.md` §8 every GSC
  runtime error is being swallowed.

---

## 4. SCAFFOLDING TO REMOVE once its question is answered

| dvar / function | remove when |
|---|---|
| `qol_perf_probe` | the frametime cause is known — **not yet** |
| `zmqol_loadmovie_probe` (LUI + the GSC println) | now — cutscenes are confirmed |
| `zmqol_pap_visibility_probe` | now — the PaP is confirmed visible |
| `zmqol_bear_live` + the `tune` parameter | now — the bear placements are confirmed |
| `zmqol_bear2_diner_snap` | keep the `snap` parameter (general, fails safe); the dvar is 0 |

---

## 5. 📝 THE PROCESS LESSON WORTH KEEPING — placement cost 10 releases

The shelf teddy bear took **v1.67.0 → v1.67.10**, and most of it was avoidable:

1. **When a report names one axis, do not change a different one.** v1.67.3's reply was *"still
   floating"* — a **height** report. It was read as an angle problem, and three releases were spent
   rotating away from an orientation that was already correct.
2. **Solve heights from a confirmed rest, not an assumed one.** Every early height was derived by
   assuming an earlier bear was seated when the user had only ever said its *position* was fine.
3. **The model's real bounds are readable offline** (`zombie_teddybear_lod0.glb`: 26.1 × 10.6 × 17.4,
   origin near the feet), so the lift per pose is arithmetic: 3.46 upright, 5.32 on its side, 8.69
   flat on its back. That part was right and saved several rounds.
4. **A shelf you can see props resting on is not necessarily solid.** The `bullettrace` auto-snap
   reported `NO usable surface` — that shelf is decorative. Auto-snap only works against world
   brushes and collision-bearing models.
5. **Give the user a live handle early.** `zmqol_bear_live 1` should have existed at round two.

---

## 6. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal ports | ✅ DONE |
| 2 | Zombie Blood onto every map | ✅ DONE (Mob excluded on measured budget grounds) |
| 3 | Blood Money dropping from kills | 🚧 shipped v1.64.0, **still never confirmed** |
| 4 | Semtex wall buy on Diner and Bus Depot | 🚧 **Diner done v1.68.0**, Bus Depot not started |
| 5 | Galvaknuckles wall buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command should also be a dvar — [[zm-qol-commands-as-dvars]].
Governing rules: **port it, never tune it** — [[zm-qol-port-never-tune]]; **one at a time** —
[[zm-qol-one-at-a-time]].
