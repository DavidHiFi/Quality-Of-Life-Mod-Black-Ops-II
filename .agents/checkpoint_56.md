# Checkpoint 56 — v1.99.7. Bleedout toggle CONFIRMED. The Winter's Howl fx are ROOT-CAUSED, and the cause was in the effect file all along.

Written 2026-08-16. **Supersedes 55 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.7 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | **Bleedout bar — live toggle** (queue #1) | ✅ **CONFIRMED IN GAME** at v1.99.6 — *"i tried it, it works fine, task finished"*. Struck through on the list, kept there until they say to remove it |
| 2 | **Winter's Howl firing fx** (queue #7, B-WHOWL) | 🟡 **ROOT-CAUSED AND FIXED IN v1.99.7 — never booted.** See §1 |
| 3 | Origins Death Machine ammo counter (queue #2) | 🔴 still never booted |
| 4 | Riser sound · Titus-6 reload · `.character` · `mod.ff` stale script | 🔴 unchanged — queue #6, #8, #12, #11 |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers with the Death Machine and the user's own icon artwork, the bleedout bar
**and its live mid-down toggle**.

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
Diner survival, `.wintershowl`, **fire it and look at the muzzle**. Expect a bright flash — star
flares, a spiral of frost, a lens flare — instead of the heat-shimmer smear that has been showing.
Then `.wintershowl` again after a Pack-a-Punch for the upgraded one, which got the identical fix.

---

## 1. 🌟 B-WHOWL — SOLVED ON PAPER. THE FLASH WAS DRAWING IN THE WRONG RENDER PASS.

Checkpoint 52 declared the offline checks exhausted. They were not — the audits had all been at the
level of *names* (does the effect load, does the material resolve, does the def match), and never at
the level of the **element flags inside the effect**. That is where it was.

### The measurement

`fx_freezegun_view.efx` has 11 elements. Counting `drawWithViewModel` on each, and doing the same
for the two guns that work:

| gun | elements flagged `drawWithViewModel` | what the user reports |
|---|---|---|
| Wunderwaffe (`fx_tesla_view`) | **14 of 14** | *"the tesla LOOKS FINE"* |
| Thundergun (`fx_thundergun_view`) | **8 of 14** — and all 8 are `gfx_fxt_fx_distortion_heat` | visible, distortion-heavy |
| **Winter's Howl** (`fx_freezegun_view`) | **1 of 11** | *"no shooting visual fx"* |

🌟 **And the single flagged element on the Winter's Howl is `gfx_fxt_fx_distortion_heat` — a
heat-shimmer distortion.** That is, precisely and in their own words, *"some weird looking wind
effects"*.

The ten unflagged elements are the flash itself: four `gfx_fxt_light_flare_star` sprites, a
`gfx_fxt_smk_whisp_spiral`, a `gfx_fxt_lensflare_diamond`, a light, and three that never spawn
(`spawnOneShot 0 0`).

### Why unflagged elements are invisible here

`viewFlashEffect` is spawned at the **viewmodel's** `tag_flash`. An element without
`drawWithViewModel` renders in the world pass, at what is effectively the camera origin — inside the
near plane. It exists and it is not visible. The correlation across all three guns is monotonic and
the mechanism predicts the *specific* wrong appearance in the failing case, which is the part that
makes it more than a coincidence.

🛑 **Stated honestly: the mechanism is NOT confirmed from a stock T6 file.** The workspace has no
stock BO2 `.efx` — `hb21_black_ops_3_fx_library`'s `_t6` folder looked promising and turned out to be
BO3-format (`extraFlags`, `spawnLoopingSpawnCount`, `atlasBehavior`), so it cannot settle a T6 flag
convention. This is the strongest offline case available; the boot settles it.

### The change (v1.99.7)

`drawWithViewModel` added to the **six live visual elements that lacked it**, in
`fx_freezegun_view.efx` and `fx_freezegun_ug_view.efx`. Nothing else in either file.

- Inserted immediately after the `runRelTo*` token, which is where the tesla and thundergun files put
  it — 7 distinct `flags` lines were dumped from those two to establish the convention.
- **Left alone deliberately:** the `light` element (the thundergun leaves its light unflagged) and
  the three `spawnOneShot 0 0` elements (they never spawn, so flagging them changes nothing).
- Per file: 6 lines changed, **+108 bytes exactly** (6 × 18), line count 2677 → 2677, braces
  428/428, elements 11, LF preserved, zero CR. Verified against the reference build line by line —
  six differing lines, each one the added keyword.
- `viewFlashEffect` / `worldFlashEffect` in the weapon defs are **untouched**, so no asset name the
  loader has never resolved is introduced. mod.ff owns no `weapon, freezegun_zm`, so the raw def in
  `mod.iwd` is the only copy either way.

### What this session ELIMINATED by measurement, so nobody re-checks it

| check | result |
|---|---|
| all 60 `.efx` vs the shipped working build | ✅ **60/60 byte-identical** (25 legitimately contain CR and so does the reference — checkpoint 50's prose had the 25/35 split backwards, the end state was right) |
| `.efx` vs a **third** source (`T6-Declassified` module) | ✅ identical md5 to ours and to Wonder_Weapons |
| raw `.efx` load at all? | ✅ **PROVEN.** `fx_zombie_tesla_tube_view` exists in no retail fastfile and not in `mod.ff`, and the log shows `Loaded fx:` for it. This was the "free discriminator" open since checkpoint 47 — **it is now answered and closed** |
| every material of all 60 `.efx` vs the real Diner fastfile set | ✅ 18 effects have gaps, **not one of them a freezegun effect** |
| the engine's own material errors | ✅ the log prints `Could not load material` (it did for `gfx_fxt_fx_distortion_water` and `menu_mp_weapons_sig556`) and says **nothing** about the freezegun's six |
| weapon def vs both reference ports | ✅ 326/326 keys, only `camo` cleared on purpose |
| viewmodel has `tag_flash`? | ✅ dumped the GLB from `mod.ff` |
| a compiled `fx` in `mod.ff` shadowing a raw `.efx`? | ✅ **zero name collisions** across 60 raw vs 151 compiled |
| `.iwi` pixels for the flash materials | ✅ all valid `IWi` v27 DXT5 with real data |
| `_zm_weap_freezegun.csc` staged, not the donor's? | ✅ `build_ff.bat` line 84 stages `clientscripts` too; `mod.ff`'s copy is 15,621 bytes = source |

### Pre-mortem — four ways the boot still fails

1. **Still no flash.** Then the flag is not the gate and the three-gun correlation was coincidence.
   Next probe, already designed: point the freezegun's `viewFlashEffect` at `fx_tesla_view` for one
   boot. Tesla flash appears on the Winter's Howl → the wiring is fine and the file is at fault;
   nothing appears → the wiring is at fault. Not checkable offline, which is why it is a boot.
2. **Flash appears but wrong** — too big, clipping the gun, mispositioned. That **confirms** the
   mechanism and turns this into a `spawnOrg*` / `spawnRange` job. Progress, not a reset.
3. **The gun stops working entirely** — would mean the `.efx` no longer parses. Guarded: identical
   line count, brace count and element count to the reference; six flag lines gained one keyword that
   already exists elsewhere in the same file; LF preserved.
4. **Base gun fixed, upgraded one not.** Both files took the identical six-line edit, so a split
   result would itself be a new and useful asymmetry.

### 🟡 Known, NOT fixed this round, stated rather than quietly shipped

`worldFlashEffect` on both freezegun defs points at the **view** effect, while the properly authored
`fx_freezegun_world.efx` (14 elements, real element names, 40,084 bytes) ships and is referenced by
nothing — it never appears in the log's `Loaded fx:` list. The tesla and thundergun both point at
their own `_world` twins. **Both reference ports have the identical defect**, so this is the port's,
not ours. It affects only what *other players* see of your muzzle flash, is invisible in solo and
therefore unverifiable in solo, and repointing it would introduce an asset name the loader has never
resolved. Deferred on purpose; it is not part of what the user reported.

---

## 2. DEPLOYMENT

`mod.json` 1.99.7. `build.bat` only — no `zone_source` / `zone_assets` change, so `mod.ff` was not
relinked. Confirmed **inside the deployed `mod.iwd`**: both files 46,883 bytes, `drawWithViewModel`
×7, 11 elements each; deployed `mod.json` reads 1.99.7.

🛑 **Deployed, NOT yet verified in game.**
