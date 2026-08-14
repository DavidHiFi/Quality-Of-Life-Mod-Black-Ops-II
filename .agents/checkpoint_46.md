# Checkpoint 46 — v1.94.0. Six versions shipped in one session; TWO BUGS STILL OPEN AND NAMED.

Written 2026-08-14. **Supersedes 45 for status.** Keep 45 §1 (the Origins ring LUI mechanism),
44 §1 (the runaway-`join` incident) and §2 (XPR-50 asset measurements), 43 §3–§5.

---

## 0. STATE — v1.94.0 deployed, tree clean, tagged

| version | what | state |
|---|---|---|
| v1.91.0 | freeze fx materials into `mod.ff` | 🔴 **theory later DISPROVEN — see §3** |
| v1.92.0 | XPR-50 into the box | ✅ **user confirmed: "i did get the xpr and it works fine"** |
| v1.93.0 | Titus-6, Brutus 2-shot, reload foley, `.give`, options tab, perk icons | 🟡 partly confirmed |
| v1.93.1 | night-mode ramp: run once, not forever | ✅ **Mob boots and plays** |
| v1.94.0 | thundergun helmet, Titus PaP camo, options tab rebuilt | 🟡 **never booted** |

**Confirmed working by the user this session:** XPR-50 in the box; Titus-6 obtainable and firing;
`.give` commands; Mob of the Dead no longer crashing; the wonder weapons damaging Brutus; the
options tab existing.

---

## 1. 🔴 OPEN #1 — ORIGINS AND BURIED DIE WITH `EXE_ERR_RELIABLE_CYCLED_OUT`

**The single most important open item. Two maps are unplayable.**

### What is measured and settled

| session | map | outcome |
|---|---|---|
| 1 | `zm_tomb` | CRASH at ~t=20–25 |
| 2 | `zm_nuked` | ok |
| 3, 4 | `zm_transit` | ok (one ran 4:27) |
| 5 | `zm_highrise` | ok |
| 6 | `zm_buried` | CRASH at ~t=30–35 |

- 🛑 **All six ran v1.93.1.** Deploy 09:32:24, Mob OK 09:42, Origins crash 09:53, Buried crash
  10:12 (times from the screenshots' own identifier strings). So the night-mode fix was live.
- 🛑 **Mob shares Origins' EXACT night-mode branch** (`zm_prison || zm_tomb`) and Mob is fine.
  **Therefore the emitter on tomb/buried is a SECOND, slower one — not the night ramp.**
- Not a weapon overflow: tomb 32 and buried 32 `Loaded weapon:` lines vs **38** on the healthy
  maps (the six fewer are the three wonder weapons + upgrades, gated off on those two maps).
- Swept `setclientdvar` / `setclientuivisibilityflag` / `iprintln` / `settext` inside every loop
  across `scripts\`, `maps\`, `clientscripts\`. Nothing unbounded remains and nothing found is
  gated to those two maps. `bo2dd_onplayerconnect` is per-connect; the HUD watcher writes its
  visibility flag on change only; the prison probe uses `println` and is bounded to 24 passes.

### What was removed anyway (NOT claimed as the fix)

`zmqol_capture_objectives_fix()` and `zmqol_capture_hud_nudge()` no longer start on Origins.
Both emit reliable commands on a timer (`objective_add`, `setclientuivisibilityflag`), checkpoint
45 already ruled the re-declare disproven as load-bearing, and the user rejected the nudge
outright. The functions are left in the file, unreferenced, for their comments.

### ▶️ NEXT ACTION — a free bisect, no build

**Set `night_mode 0` at the console, then start Origins.**
- Survives → night mode is still involved despite the one-shot change; the ramp burst or something
  else in `qol_opt_night_on()`'s 17 `setclientdvar` calls is the lead.
- Still crashes → night mode is exonerated and the space narrows to whatever runs only on
  `zm_tomb` + `zm_buried`.

🌟 **The one structural thing those two maps share, still unexplored:** they are the only maps
where all three wonder weapons return early (`freeze.gsc`, `teslagun.gsc`, `thundergun.gsc` and
their `.csc` twins all gate on `zm_tomb || zm_buried`), and the only maps where
`freezegun_actor_fx_enabled()` is false because the **actor clientfield set is at its 32-bit
ceiling**. Worth examining what runs *because* those returns happen.

---

## 2. 🔴 OPEN #2 — WINTER'S HOWL HAS NO FIRING FX, AND v1.91.0's EXPLANATION WAS WRONG

v1.91.0 said the effects had no materials to draw with and shipped 19 of them. **Re-measured
after the user reported the fx still missing: that theory is dead.** All six materials
`fx_freezegun_view.efx` names are reachable at runtime —

| material | where |
|---|---|
| `gfx_fxt_light_flare_cool`, `_star`, `gfx_fxt_fx_distortion_ring_warp`, `gfx_fxt_smk_whisp_spiral` | in `mod.ff` |
| `gfx_fxt_fx_distortion_heat`, `gfx_fxt_lensflare_diamond` | in `common_zm` / `patch_zm`, loaded on every map |

— and `fx/weapon/muzzleflashes/fx_freezegun_view.efx` is inside the deployed `mod.iwd` (49,451 B).

### 🛑 The real untested assumption: does T6 load a raw `.efx` from `mod.iwd\fx\` AT ALL?

That belief came from the Declassified Winter's Howl module carrying zero fx in any of its three
fastfiles — strong precedent, **never confirmed for this mod**.

### ▶️ NEXT ACTION — a free discriminator, no build

Fire the **Wunderwaffe** on Mob or TranZit and look at the gun.
`maps/zombie/fx_zombie_tesla_electric_bolt` and `maps/zombie/fx_zombie_tesla_tube_view` exist in
**no retail fastfile and not in `mod.ff`** — measured against the 191-fastfile index. They can only
come from raw `.efx`.
- Bolts and tube glow visible → raw `.efx` DO load; the freeze gun has its own specific problem
  (next suspect: `chr_shock_hb1`, named by all four freeze muzzle `.efx` and matching **no asset of
  any type** in retail or either donor).
- Nothing visible → **no raw `.efx` loads** and every wonder-weapon effect needs a different
  delivery route. That would also retro-explain v1.91.0 changing nothing.

---

## 3. WHAT SHIPPED THIS SESSION, and the mechanism behind each

| fix | the real cause |
|---|---|
| Mob crash | `qol_opt_night_visual_fix()` ran forever. The original's `while( getDvar(x) != 0 )` guard **can never fire** — `setclientdvar` does not write back into the server's `getdvar()`. v1.90.3's 4× rate cut only moved the crash 0:06 → 0:12. Now ramps once and returns. |
| Thundergun didn't pop the helmet | the hook was in `zombie_knockdown()`, which **Brutus never reaches** — `thundergun_knockdown_zombie()` dispatches via the per-AI `self.thundergun_knockdown_func`, set only in `_zm_spawner.gsc:260` and `_zm_ai_dogs.gsc:445`. Moved above the dispatch. |
| Titus PaP camo missing | `camo_titus6.json` had overrides in **slot 11 only**. **Slot 3 is the zombies PaP slot** — verified across `camo_xpr50`, `camo_sig556`, `camo_mk48`, which all fill 0..14. Slot 3 rebuilt from the file's own base materials. |
| SWAT reloaded in silence | not the notetrack theory the README blamed. `sig556` and `peacekeeper` had **zero** foley aliases; the other nine matched Reimagined one-for-one. 12 rows + 6 payloads imported. |
| options tab arrows broken | **the tab POSITION.** Registering ours first shifted the stock tabs while the manager laid arrows out from the original extents. Registered last now. |
| hold-to-sprint wouldn't turn off | the 5th argument to `addChoice` **replaces** the widget's own `DvarSelectorSetDvarFunc`. All rows now pass `nil`. |

🌟 **Two near-misses the completeness audit caught before shipping:** the Pack-a-Punched XPR-50
would have fired **silently** (no `wpn_as50_fire_*_pap` aliases), and the Titus-6 would have had
**no muzzle flash and no dart trail** plus silent fire (its fx and its four fire aliases live only
in campaign files). Both found by walking the six-point audit, not by a boot.

🌟 **New, load-bearing fact:** *"OAT cannot read or write FxEffectDef"* is true of a **raw `.efx`**
and **false of an fx already inside a `--load`ed fastfile** — proven by `mod_locations.zone`
declaring 34 `fx,` lines that are all present in the built `mod.ff`. That is what made the Titus
effects possible.

---

## 4. ASSET-PIPELINE STATE

`build_ff.bat`'s `--load` chain gained three entries this session, **all after the zombies commons**
so first-load-wins keeps every shared name on its zombies copy:
`code_post_gfx_mp.ff` (XPR-50 HUD icon), `monsoon.ff` + `code_post_gfx.ff` (Titus-6 — the first
campaign fastfiles this mod has ever linked), and `zone_source\fx_donor\mod.ff` last.

**Every link was A/B audited with ZERO removals:** 4,829 → 4,860 → 4,919 → 5,003 assets.
🛑 Re-run that audit on any `--load` change; zero-removed is the property that proves nothing was
re-owned.

---

## 5. NEXT, in order

1. 🛑 **The Origins `night_mode 0` bisect** (§1). Two maps are unplayable; nothing else matters more.
2. 🛑 **The Wunderwaffe fx look** (§2). Free, and it decides whether the whole raw-`.efx` route works.
3. Boot v1.94.0: thundergun helmet on Brutus, Titus PaP camo, the QUALITY OF LIFE tab.
4. **Queued, not started:** survival character choice (CDC / CIA) in solo and custom play, the
   user's request 2026-08-14. Also still open from earlier: `wpn_titus_proj_loop` (dart flies
   silently — in no bank on this install), kill-feed icons for the ported weapons, and the
   Vulture Aid icon fallback for users with no custom pack.
