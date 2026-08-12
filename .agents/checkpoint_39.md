# Checkpoint 39 — TranZit scope closed to ONE map, the ceiling myth killed, MP40 actually fixed. v1.77.0 → v1.81.0.

Written 2026-08-13. **Supersedes 38 for status.** Keep 38 §2 (the no-degraded-variants rule) and
§4 (the 15-weapon scoping); 37 §1/§4; 36 §1–§2; 35 §7; 34 §1–§2; 33 §1/§5; 32 §1; 31 §1–§2;
30 §3/§5; 29 §2–§3; 28 §1; 24 §2a/§2c; 23 §2; 22 §4–§5; 21 §2–§3; 20 §1–§2; 19; 18 §5; 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **TranZit CLASSIC** | 🛑 still broken. Scope now known: **it is the ONLY broken map** |
| Die Rise / Mob / Buried / Origins **classic** | ✅ **all four booted clean by the user on v1.77.0** |
| Nuketown, all Survival modes (incl. TranZit) | ✅ |
| Origins MP40 wallbuy → adjustable stock | ✅ real cause found and fixed in **v1.80.0** — 🟡 not yet re-verified |
| Origins generator ring | ✅ user reports drawing; round indicator hides behind the dial, **user wants that kept** |
| Origins "red box" textures | ✅ **CLOSED — the user's own images folder, not the mod** |
| v1.76.0 `.round` | ✅ confirmed working |
| v1.77.0 HUD fixes | ✅ shipped, no complaints |
| TranZit free-bit measurement | 🟡 **probe was built and DEPLOYED but never booted** — see §4 |
| 15 MP/campaign weapons | 📥 queued, scoped, nothing built |
| Frametimes / `qol_perf_probe` | 🛑 still never run |

**v1.81.0 is clean: every probe from this session has been reverted and that is verified in the
deployed files.** See §5.

---

## 1. 🌟 THE CEILING MYTH IS DEAD — `toplayer` IS NOT 64

The user booted all five classic maps. **Only TranZit fails.** Buried classic boots, and Buried is
63 stock `toplayer` bits *before* the mod adds Zombie Blood (+2 and a `visionset_lerp` widening),
Deadshot (+2), Tombstone (+2) and Electric Cherry (+1) — **≥71 bits registered successfully.**

`ERROR_CATALOGUE.md` §2's "[inferred] 64" was quoted in three checkpoints and is **wrong**. It is
corrected in place. Quote the ceiling as *"unknown, >71 observed to work"*, never as a number.

### 🛑 AND THE ACCOUNTING ITSELF IS DISPROVEN, NOT MERELY IMPRECISE

| | |
|---|---|
| TranZit, full source-derived accounting | **65** → fails |
| Buried, same method | **≥71** → boots |

A map at 65 cannot die while a map at 71 lives. Working the ceiling backwards from each failure
gives **43** (TranZit) and **~55** (Mob), which contradict each other *and* Buried's stock 63.
**~28 bits of TranZit's real usage are unaccounted for.** Searched and NOT found in: the mod's own
`registerclientfield` calls (all of `scripts/`, `maps/`, `clientscripts/`), weapon includes (no
Paralyzer / Time Bomb / gas mask), buildables (the Diner shield is gated to
`ui_zm_mapstartlocation == "diner"`, off in classic), powerups, `scripts/zm/replaced/`, and
`wunderfizz.gsc` (which registers nothing).

**Issue no verdict from this arithmetic. It has been shown to lie.**

---

## 2. ✅ TWO THINGS THAT ARE NOW EXACT

**1. The vsmgr widening on TranZit is +5.** Not "±2 to ±4". The model was validated by reproducing
stock TranZit's four dumped widths from source *before* applying the mod: visionset info.size 2
(default + `zm_power_high_low`, 7 steps) → slot 1, lerp 3 ✓; overlay (default + `zm_transit_burn` +
`zm_ai_avogadro_electrified` + `zm_ai_screecher_blur`) → slot 2, lerp 4 ✓. The mod adds 3 visionsets
(divetonuke, zombie blood, whos_who) and 2 overlays (vulture stink 31 steps, zombie blood 15).

**2. 🌟 THE FOUR VSMGR FIELDS REGISTER LAST, SO EVERY ERROR UNDERSTATES THE HOLE.**
`_visionset_mgr::init()` does `onfinalizeinitialization_callback( ::finalize_clientfields )`
(`_visionset_mgr.gsc:16`).

> Freeing exactly the N bits an error names is **never** enough. TranZit's 7-bit shortfall would
> have failed again 15 bits later at `visionset_slot` — literally the error Mob gave in v1.65.2.

Also measured across all 48 dumps: `actor` 32, `scriptmover` 32, `allplayers` max 28 — and **TranZit
uses only 25 allplayers bits**, which is the most promising place to relocate mod-added fields if it
comes to that. Behaviour-identical, implementation-relocated. Not designed yet.

---

## 3. ✅ ORIGINS MP40 — THE REAL CAUSE, AND A CORRECTION TO MY OWN FIX

**v1.79.0 was aimed at the wrong thing and the log proved it.** It shipped as *"verified mechanism,
unproven cause"* with a watcher attached specifically so the evidence could kill it. It did:

    retagged 0 mp40 wallbuy stub(s); 0 wallbuy stub(s) total; corrected 0 already-live trigger(s)

Zero stubs, not three — so the trigger-vs-stub split was never reached. **That correction stays**
(it is right, and matters once the retag runs) but it was not why the gun was wrong.

🌟 **THE CAUSE: the retag was a one-shot against a race it could lose.** It waited only for
`level._unitriggers.trigger_stubs` to be non-empty — which the *first unitrigger of any kind*
satisfies, a door or a perk machine — then waited 2s and walked the list **once**, giving up
permanently if the three MP40 stubs had not registered yet.

Both faces appear across boots of **identical code**: logs `.003`/`.004` saw 23 stubs and 3 MP40 and
worked; `.007`/`.008` and one this session saw 0 and handed out the plain gun. **No version boundary
lines up with it** — "you had it working then broke it" was "it won a race, then lost it".

**v1.80.0 fix:** re-scan every 2s for the whole match (`zmqol_mp40_keep_wallbuys_stalker`), so a
late stub is retagged whenever it appears. Re-correcting something already correct is a no-op. One
loud line fires if 15 passes find nothing, so total failure can never be silent again.

📝 The user also asked *"when/why did you remove this"* — **it was never removed.**
`git log -S zmqol_tomb_mp40_stalker_wallbuys` returns exactly one commit, the one that added it.
Check before conceding; conceding a false premise would have sent the next session hunting a
non-existent revert.

---

## 4. 🟡 THE STAIRCASE PROBE — BUILT, DEPLOYED, NEVER BOOTED, NOW REVERTED

Registered 1-bit `toplayer` fields `zmqol_probe_1..24` on TranZit only, immediately after
`clientfield_whos_who_filter` **on both halves** (chosen because those two Who's Who fields already
register consecutively on both sides and Who's Who works in game — empirical proof the sites are
equivalently ordered). First one that will not fit names itself in the error ⇒ **H = N−1 free bits,
from one boot.**

🌟 **The threshold it was built to answer, and it still stands:**

> With Vulture off the four vsmgr fields cost 14 on TranZit. Turning Vulture back on costs 9
> non-finalize bits **and** widens `overlay_lerp` 4→5.
> **VULTURE FITS WHOLE ON TRANZIT ⟺ H ≥ 24.**

**It was reverted un-run for the release** (§5). Restore it from `881cedb` — it is complete and
symmetry-checked; do not redesign it.

📝 Also learned: **`zmqol_vulture` could not be set from the console.** Three boots with it typed
produced no such entry in the game's own dvar dump (3,135 dvars; the dump is comprehensive — the
mod's runtime-set `zmqol_loadmovie_probe` appears in it). **The console will not create a dvar that
nothing has registered.** Any future probe dvar must be `setdvar`-registered by the mod first, or
hard-coded. `developer 1` / `developer_script 1` are likewise dead ends — both read back `0`.

---

## 5. ✅ WHAT SHIPPED — v1.81.0, RELEASE BUILD, PROBES OUT

| version | change |
|---|---|
| 1.78.0 | `zmqol_vulture` dvar (default 1, inert) |
| 1.78.1 | 🔬 hard-coded Vulture off on TranZit — **reverted** |
| 1.79.0 | MP40: correct the live trigger as well as the stub — **kept** |
| 1.79.1 | 🔬 staircase probe — **reverted** |
| 1.80.0 | MP40: persistent re-scan, the real fix — **kept** |
| 1.81.0 | probes removed, README known-issue added, release |

**Verified in the DEPLOYED files, not assumed:** `staircase=0` and `transit_vulture_gate=0` in both
`quality_of_life.gsc` and `zm_expanded.csc` inside `mod.iwd`; `mp40_scanner=4` in `zm_tomb.gsc`.
`build_ff.bat` reported `zm_expanded.csc (src: disk)`.

⚠️ **TranZit classic is back to its original overflow crash** — that is the intended state. It is
the documented status quo, not a regression, and the README now says so plainly.

---

## 6. NEXT — in this order

1. 🛑 **Restore the staircase probe (`881cedb`) and boot TranZit classic once.** It is the only
   thing standing between here and a verdict on Vulture. One boot, exact number.
2. Re-verify the MP40 wallbuy on Origins (v1.80.0 is unverified in game).
3. 📥 `qol_perf_probe 1` — still never run.
4. 📥 The 15 MP/campaign weapons.

❌ **Cancelled by the user:** moving Origins' generator dial to the top-left. The round indicator
already hides while the dial is up and they want that behaviour kept. Good outcome — the dial is
engine-drawn (`setupclientfieldcodecallbacks`, no script draw call) and might not have been movable.
