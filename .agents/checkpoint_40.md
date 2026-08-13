# Checkpoint 40 — TranZit fixed, `.hud` switch, no Tombstone in solo, console commands, 9 MP weapons half-landed. v1.81.0 → v1.88.0.

Written 2026-08-13. **Supersedes 39 for status.** Keep 39 §2 (the vsmgr `*_lerp` trap and the
"vsmgr registers last" rule); 38 §2/§4; 37 §1/§4; 36 §1–§2; 35 §7; 34 §1–§2; 33 §1/§5; 32 §1;
31 §1–§2; 30 §3/§5; 29 §2–§3; 28 §1; 24 §2a/§2c; 23 §2; 22 §4–§5; 21 §2–§3; 20 §1–§2; 19; 18 §5;
15 §2.

---

## 0. STATE

🛑 **EVERY LINE IN THIS CHECKPOINT IS DEPLOYED AND UNVERIFIED. The user has not booted the game
since v1.81.0.** Eight versions shipped this session on the strength of offline measurement alone.

| item | state |
|---|---|
| **TranZit CLASSIC** | 🟡 **fix shipped** — Vulture off on classic only. Never booted |
| TranZit **survival** (Diner &c.) | 🟡 keeps all 12 perks — v1.83.0 briefly took Vulture off these too, v1.84.0 undid it |
| `.hud on` / `.hud off` | 🟡 shipped, then three defects found and fixed in v1.87.1. Never re-booted |
| Tombstone absent in solo | 🟡 shipped, never booted |
| Every chat command as a console dvar | 🟡 shipped, never booted |
| Timers at the top-left corner | 🟡 third position attempt (`x = -64`). The first two were measured wrong |
| Origins generator dial moved left | 🟡 shipped v1.82.0, never booted |
| Origins capture-meter probe | 🟡 repaired and shipped. **Needs one Origins game with a generator captured** |
| **9 MP weapons** | 🟠 **defs + assets in `mod.ff`, NOT wired to any box.** Game functionally unchanged |
| Titus-6, Bouncing Betty | ❌ **dropped, permanently** — see §5 |
| `qol_perf_probe 1` | 🛑 still never run |

---

## 1. 🌟 TRANZIT CLASSIC — FIXED, AND THE NUMBER THAT CRACKED IT

Three checkpoints of contradictory bit-arithmetic were resolved by one measurement nobody had taken:
**stock `toplayer` bits per map**, straight out of the per-map dumps.

| map | stock toplayer |
|---|---|
| **zm_transit (classic)** | **38** |
| zm_highrise | 33 |
| zm_prison | 50 |
| zm_tomb | 61 |
| zm_buried | 63 |

TranZit has *more* headroom than nearly every map and was still the only one that would not boot, so
the whole overflow is mod-added. And the per-configuration split is what made the fix precise:

    zclassic + transit  38     <- the only configuration that overflows
    zgrief  (7 locations) 28
    zstandard (7 locations) 27

**Classic carries 11 more stock bits than any survival location.** That is why the survivals ran
twelve perks happily while classic could not load at all.

**Fix:** `zmqol_vulture_enabled()` returns 0 when
`map == "zm_transit" && getdvar( "ui_zm_mapstartlocation" ) == "transit"`, on **both** halves.
Frees 10 toplayer bits (1+1+5+2 plus `overlay_lerp` narrowing 5→4 once the 31-step
`vulture_stink_overlay` is gone). Checkpoint 31 cleared the identical error class on Mob with **3**.

📝 **Why that dvar and not `g_gametype`.** The failing boot log printed both
(`struct_class_init - gametype=zclassic location=transit`), but `g_gametype` is a server dvar and
the identical test has to run inside `zm_expanded.csc`. The client already reads
`ui_zm_mapstartlocation` in four places for exactly that reason.

🛑 **v1.83.0 gated on the map name alone and cost every TranZit survival a perk.** The user caught
it. Measure the *configuration*, not the map.

---

## 2. 🛑 THE RULE THAT BIT THREE TIMES — ONE ALPHA OWNER PER HUDELEM

`.hud off` shipped in v1.85.0 and was a **partial feature**. The user reported one symptom; auditing
every `.alpha =` writer found three defects:

1. **Zombie counter flashing** — `qol_opt_hud_watcher` wrote `alpha = 0` while `zombiecounter()`
   wrote `alpha = 1`, both 4×/sec. This is the *exact* failure the health HUD already carried a
   warning about, and the rule was not applied when `hud_master` was added.
   📝 Never purely a `.hud` bug: `hud_remaining 0` would have flashed it identically on any build
   since that watcher existed.
2. **Shield bar would have corrupted on restore** — its background is deliberately `alpha 0.5` and
   `qol_opt_show()` only knows 0 and 1. Same "thick white border" bug this project already hit.
3. **The BOCW round chalk was never hidden at all** — a *server* hudelem (one shared, not per
   player) and *animation*-driven, so it cannot be driven from the per-player watcher.

> **THE RULE: an element repainted on a timer may only have its alpha written by that timer's own
> loop.** A master switch goes INSIDE each owning loop, never into a second thread. Now in memory as
> [[t6-hudelem-single-alpha-owner]].

⚠️ **Still not covered, stated rather than left to be found:** transient mod hudelems — hitmarkers,
the perk pop-up, the area-name notifier, the `.help` panel — still draw over a hidden HUD. The
game's own LUI *is* fully hidden by `setclientuivisibilityflag( "hud_visible", 0 )`.

---

## 3. TOMBSTONE IN SOLO, AND CONSOLE COMMANDS

**Tombstone.** 🌟 Treyarch already wrote this: `zm_transit_utility.gsc:205 solo_tombstone_removal()`
— `if ( getnumexpectedplayers() > 1 ) return;` then `level notify( "tombstone_removed" )` and
`_zm_perks::perk_machine_removal( "specialty_scavenger" )`. Threaded from `zm_transit_classic.gsc`
and `zm_transit_standard_town.gsc` **and nowhere else**, so stock does it on two configurations
only. This mod also hands the perk out through the Wunderfizz on every map, which stock never did.
Same rule now applies everywhere, using stock's own call.

🛑 **`level.zombiemode_using_tombstone_perk` is deliberately untouched** — it gates the
`perk_tombstone` clientfield on both halves and `zm_expanded.csc` cannot ask how many players are
expected. Gating it would desync the sides. **Availability changed, registration untouched.**

**Console commands.** Every chat command is now a dvar of the same name; any non-empty value fires
it (`round 100`, `pack 1`, `p 5000`). The watcher **reimplements nothing** — it writes the line back
through `level notify( "say", message, player )`, the same entry point the chat listener waits on,
so the two can never drift. `qol "<line>"` covers the prefix-matched alias families.

🌟 Names were checked against the **3,210 dvars this install dumps**; exactly one collided (`fly`,
the mod's own, excluded). ⚠️ The dump lists dvars, **not engine console COMMANDS** — `god`, `drop`,
`reload` will run the engine's version instead. `qol "god"` is the guaranteed route.

---

## 4. THE HUD POSITION LESSON — TWO SAMPLES BEAT ONE SAMPLE AND A THEORY

The timers took three attempts because v1.86.0 measured one point and then **assumed** the scale was
`2000/640 = 3.125` px per unit, hudelems being nominally a 640×480 space.

| `timer.x` | measured text left edge (2000px-wide grab) |
|---|---|
| -45 | 46px |
| -56 | 21px |
| **-64** | ~3px (predicted, matches the 3px it already sat from the top) |

Real scale is **25px / 11 units = 2.27 px per unit**. 🌟 The user's screenshots are pixel-scannable
with `System.Drawing`; two positions at different settings give the true scale of any HUD anchor
with no guessing.

---

## 5. 🟠 THE MP WEAPONS — 9 IN, 2 DROPPED, NOT YET OBTAINABLE

**In:** SWAT-556 (`sig556`), FAL-OSW (`sa58`), MK 48, QBB LSW (`qbb95`), MP7, Vector K10 (`vector`),
MSMC (`insas`), Peacekeeper, Crossbow. 24 raw defs in `weapons\zm\` + 329 assets in `mod.ff`.

**🌟 THE DELIVERY PATH WAS PROVEN BEFORE ANYTHING WAS PORTED.** `thundergun_zm`, `tesla_gun_zm` and
`freezegun_zm` are **not** in `mod.ff`'s asset list — they exist only as raw defs in `mod.iwd`'s
`weapons\zm\`, and they work in game. So Plutonium loads raw weapon defs out of `mod.iwd` and a new
weapon needs **no** `weapon,<name>` zone line. What the raw file cannot carry is its assets, which
is what the zone block is for.

**🌟 THE ASSET LIST WAS DERIVED FROM THE DEFS, NOT TYPED.** `extract_assets.ps1` parses each
`\key\value\` def: `gunModel`/`worldModel`/`attach*Model`→xmodel, every `*Anim`→xanim, the icon
fields→material, the effect fields→fx, `camo`→camo, minus everything `mod.ff` already had.

**🔴 THE OWNERSHIP TRAP FIRED AND THE A/B CAUGHT IT.** Adding only `common_mp.ff` + `patch_mp.ff`,
with nothing new declared, took the build 4,185 → 4,201: `impacts/fx_flesh_hit_splat`, ten
`blood_spatter` images, six `gfx_impact_blood_spatter` materials, `techniqueset effect_q01e8072`.
`mod_base.zone` has always declared that fx with nothing to resolve it, so it shipped as a bare
reference and the game used `common_zm`'s copy — until MP suddenly supplied one, which (mod.ff
loading ahead of the map) would have replaced the zombies blood fx **on every map**. Fixed by
loading `common_zm.ff` + `patch_zm.ff` **ahead of** the MP pair.

✅ **Final link audit: 4,201 → 4,712, 511 added, ZERO removed, 0 errors.** Zero removals is the
property that matters — no existing asset changed, was dropped or was re-owned.

🛑 **DROPPED PERMANENTLY, under "perfect or not at all" — my call, not a question:**

| | why, measured |
|---|---|
| **Titus-6** | `camo,camo_titus6` + `material,hud_monsoon_titus_arrow` exist in **no fastfile in this install**. Reimagined sources them from `zone_source\dependencies\camo_materials.ff` and **its repo ships that folder empty**. A Titus-6 with no camo is a visible defect. |
| **Bouncing Betty** | its 20 `viewmodel_mine_tc6_*` anims and `hud_bounce_betty_256` are absent from the workspace entirely. |

Settled earlier: XPR-50 / TAC-45 in no workspace mod, M16 already shipped and boxed, "Dragunov" is
not a BO2 weapon (the SVU-AS is, and already ships).

⚠️ **NOTHING CALLS `include_weapon` / `add_zombie_weapon` FOR THESE YET.** No box offers them; the
game is functionally unchanged. Deliberate safe intermediate state, not a half-shipped feature.

---

## 6. NEXT — in this order

1. 🛑 **BOOT AND VERIFY THE BACKLOG.** Eight versions are deployed unverified. In one sitting:
   **TranZit classic** (boots? 11 perks?) → **Diner** (12 perks back?) → any map for the timers,
   `.hud on/off` and a console command → **Origins**, capture a generator, then send
   `console_zm.log` **and** `mods\zm_qol\games_mp.log` for the capture-meter probe.
2. **Finish the weapons** — sound aliases (~350 rows; 🛑 a missing alias is **silent, never an
   error**), strings, then per-map `added_weapons()` + the `.csc` twin. **Additions only, never
   `is_in_box = 0`.** **Boot Origins first** — its weapon-count ceiling is only known to be ≥178.
3. 📥 `qol_perf_probe 1` — still never run.
