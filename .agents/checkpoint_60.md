# Checkpoint 60 — v1.99.12. The riser sound is FIXED AND CLOSED. The Winter's Howl was pointed at the wrong FX file all along.

Written 2026-08-16. **Supersedes 59 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.12 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Who's Who description | 🟡 built v1.98.0, never booted |
| 2 | Wunderfizz random first location (B-WF) | 🟡 built v1.97.0, never booted — needs a **multi-machine** map |
| 3 | ~~Riser sound (B-RISERSOUND)~~ | ✅ **CONFIRMED IN GAME AND CLOSED.** §2. 🛑 Do not re-open. |
| 4 | **Winter's Howl fx** (B-WHOWL) | 🟡 real cause found and fixed in v1.99.12, **unbooted**. §1 |
| 5 | Titus-6 reload (B-TITUSRELOAD) | 🔴 a bank job — checkpoint 58 §3 has the spec, and §2 below now proves the method works |
| 6 | Who's Who screen fx (B-WHOSWHO2) | 🔴 leading theory disproven in 57; night mode is the suspect |
| 7–14 | `mod.ff` stale script · `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers, the bleedout bar and its live mid-down toggle, the Winter's Howl muzzle
flash rendering at all, and now **the zombie riser dirt sound**.

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
`.wintershowl`, fire it. **Is there snow / a freezing storm?**

---

## 1. 🌟 B-WHOWL — THREE FAILED ATTEMPTS, ONE ROOT CAUSE, AND THE LESSON IS ABOUT METHOD

User: *"i see a wind gust sort of effect which... the thundergun has that effect when i shoot it...
the winters howl needs the freezing storm sort of fx."*

**The gun was reading the wrong file.** Both `viewFlashEffect` and `worldFlashEffect` named
`fx_freezegun_view`. Dumped side by side:

| file | elements | element names | materials |
|---|---|---|---|
| `fx_freezegun_view.efx` ← in use | 11 | `wraith_looping_def0..6` — **the FX editor's default template names** | distortion_heat, lensflare_diamond, smk_whisp_spiral, light_flare_star ×4. **No snow material at all.** |
| `fx_freezegun_world.efx` ← the real one | 14 | `light`, `distortion`, `flash`, `smoke_rings_large_out/in`, **`freeze_trailer`**, **`distortion_aftermath_long`/`longer`**, `spiral_flare`, `xcircle`, `xfigure_eight`, `xspiral` | **`gfx_fxt_env_snow_flakes` on 2 elements, `spawnLooping 400 3` each** |

Hand-authored names and 800 snow particles versus a generic template with none. The real file
shipped in the mod, its material was already declared in `mod_freezefx.zone`, and **nothing
referenced it.**

Convention confirms it: both guns the user is happy with point `worldFlashEffect` at their own
`_world` file (`fx_thundergun_world`, `fx_tesla_world`). The Winter's Howl was the only one aiming
**both** fields at its `_view` file — and all three freezegun ports in the workspace share that
mistake, so it is inherited, not local.

**The change:** two weapon defs, one field value each. **No `.efx` edited, nothing deleted.** The two
snow elements already carry `drawWithViewModel`, so they render in the viewmodel pass with no flag
edit — the v1.99.7 mechanism applied to the correct file.

🟡 **Reported, not silently patched:** `fx_freezegun_ug_world.efx` has **no** snow elements (stock's
own authoring), so the Pack-a-Punched gun will look different.

### 🛑 THE LESSON — this is the one worth keeping

Three attempts failed in a row and every one of them was a measurement of **the wrong file**:

| version | what it did | outcome |
|---|---|---|
| 1.99.9 | disabled `wraith_looping_def0`, a 2-line diff from the Thundergun's element | reverted — it was part of the correct flash |
| 1.99.10 | removed `fx_freezegun_smoke_cloud`, the user's own pick from a menu of measured descriptions | reverted — the gun then drew nothing at all |
| 1.99.12 | repointed the weapon def | 🟡 pending |

**Every failed step asked "which element resembles the Thundergun's?" instead of "which file is this
gun supposed to be using?"** The block diff, the `drawWithViewModel` census and the isolation
question were all rigorous, all correctly executed, and all aimed at a file the gun should never have
been reading. 🌟 **Verify the ASSIGNMENT before auditing the CONTENTS.** A perfect audit of the wrong
input is worth less than nothing — it produces confident, well-evidenced wrong answers, twice.

📝 Second lesson: **an unreferenced asset that ships is a clue, not clutter.** `fx_freezegun_world`,
`fx_trail_freezegun_ring_emit` and `fx_trail_freezegun_geotail` are all declared and used by nothing.
The first one was the answer. The other two are still unused and are the obvious next lead if the
snow alone is not enough — the def also lacks `projTrailEffect`, `projExplosionEffect`,
`projExplosionType` and `projectileSound`, all four of which the Thundergun and Wunderwaffe have.

---

## 2. ✅ B-RISERSOUND — SOLVED, CONFIRMED, CLOSED

*"the sound effects for the zombies crawling out of the ground are fixed... don't touch it."*

**The cause was a stock defect, not a mod bug.** Measured with OpenAssetTools:

| | |
|---|---|
| `zmb_zombie_spawn` | → `spawn\dirt\dirt_00/01.**LN55**.pc.snd`, `Storage=loaded` |
| that payload | **ships in no bank** — `Could not find data for sound` in *every* bank defining the alias (`zmb_survival_transit.all`, `zmb_tomb.all`) |
| the same audio | **does** ship, `Storage=streamed`, as `dirt_00/01.**SN50**.pc.snd.flac` (139 KB / 176 KB) under Origins' `evt_zombie_dig_dirt` |

The alias resolved, the engine played it, and there was nothing behind it. Every other theory —
origin, distance curve, bank load, mix, shadowing — had already been eliminated by `.testsound` in
v1.99.8; this was what remained.

**The fix:** both `.flac` payloads copied into `sound\evt\zombie_global\spawn\dirt\`, and
`zmqol_zombie_riser` added to `mod.all.aliases.additions.csv` as **`zmb_zombie_spawn`'s own row
verbatim** — `bus_hdrfx`, `grp_hdrfx`, `snp_hdrfx`, VolMin/Max 88, DistMin 250, DistMaxDry 1000,
DistMaxWet 1125, `nonlooping`, `3d` — with only `Name`, `FileSource` and `Storage` changed.
`Secondary` left empty so no transitive closure was needed. `zm_expanded.csc` plays it.

🌟 **The soundbank pipeline is proven end to end now** — CSV row + payload + `build_ff.bat` →
audible in game. [[t6-soundbank-facts]]. **This is the method B-TITUSRELOAD needs**, so that item is
no longer speculative.

🟡 `zmb_zombie_spawn_snow` is untouched and probably has the identical defect. Not fixed blind — it
needs the same OAT check. **Not part of the closed item.**

---

## 3. WHAT THIS SESSION CHANGED, in order

| version | change | state |
|---|---|---|
| 1.99.10 | Winter's Howl — v1.99.9 reverted; smoke cloud removed | 🛑 wrong, reverted next |
| 1.99.11 | smoke cloud restored (gun back to the confirmed-good v1.99.7 state); **riser sound fixed** | ✅ riser confirmed |
| 1.99.12 | Winter's Howl — both weapon defs repointed to `fx_freezegun_world` / `_ug_world` | 🟡 **unbooted** |

Plus: README rows rewritten twice and the riser row retired; `prefers-evidence-over-questions` memory
extended with the perceptual-ambiguity exception; queue updated; **tagged and released**.
