# Checkpoint 4 — real fastfile builds are possible. Location art + wallbuys fixed, UNTESTED.

**Supersedes checkpoint 3 entirely.** Checkpoint 3 has been deleted: its durable findings are in
`CLAUDE.md` §8 and `AI_CONTEXT.md`, and its central premise was wrong (below). Its one still-open
item — the Origins clientfield fix — is carried into §4 here.

**Written 2026-07-31.** Built and deployed (`build_ff.bat` then `build.bat`). **Nothing below has
been run in game.**

---

## 1. 🛑 THE PREMISE THAT WAS WRONG

Every earlier checkpoint said *"zm_qol has no linker and cannot add an asset."* **False.**
**OpenAssetTools is installed at `H:\Claude\oat-windows`** (`Linker.exe`, `Unlinker.exe`,
`ImageConverter.exe`).

Two conclusions built on that premise are now reversed:

- The lobby/loadscreen art did not need a LUI workaround. It needed 30 materials.
- `zm_collision_transit_cornfield_survival` was recorded as "proven absent from the stock
  zm_transit fastfile". It was never absent — it is in `so_zsurvival_zm_transit.ff`. Cornfield's
  boundary wall had been deleted for no reason and is now restored.

The mistake in both cases was the same: concluding "the asset doesn't exist" after searching only
the fastfiles I expected it to be in. `CLAUDE.md` §2 Corollary 3 again.

---

## 2. WHAT'S DONE

### Checkered previews and loading screens — fixed at the source
- `build_ff.bat` added. Relinks `mod.ff` from `zone_source\base\mod.ff` (pristine donor) +
  `mod_base.zone` (Unlinker-generated inventory) + `mod_locations.zone` (our additions).
  Round-trip with no additions verified asset-for-asset identical. See `CLAUDE.md` §8 for the traps.
- **30 materials + 14 images** added: `menu_<map>_zsurvival_<loc>` and
  `loadscreen_<map>_zstandard_<loc>` for all 15 locations the list menu offers.
  Stock only ever shipped these for transit/farm/town/nuked — verified by unlinking `ui_zm.ff`,
  `patch_ui_zm.ff`, `frontend.ff`, `common_zm.ff`, `code_post_gfx_zm.ff` and the five
  `dlc*_load_zm.ff`. Both name-deriving LUI functions normalise any non-zclassic gametype, so
  zgrief resolves to the same names — 15+15 covers every case.
- The LUI remap in `privategamelobby_project.lua` is **removed**, not just bypassed. It was a
  partial fix that still left Die Rise, Buried and Mob checkered, because the "stock" materials it
  redirected to (`menu_zm_highrise_zsurvival_rooftop` etc.) do not exist either.

### Wallbuys — root cause found and fixed
Stock `_zm_weapons::init_spawnable_weapon_upgrade()` keeps a wallbuy struct only if its
`script_noteworthy` contains `<ui_gametype>_<location>`, or if it has no `script_noteworthy` at all.
No stock map tags any location this mod adds. Full detail in `AI_CONTEXT.md`.

- `loc_common::enable_wallbuys( a_origins )` re-tags structs by origin, from `struct_init()`.
- Diner: MP5K + Galvaknuckles (were `zclassic_transit` only) → Diner had **zero** wallbuys.
- Tunnel: M16.
- Borough/`street` at zstandard: 3 wallbuys (were `zgrief_street` only). Note stock Buried
  registers no zstandard gamemode at all — Borough survival is entirely this mod's addition.
- Die Rise, Mob, Origins: every wallbuy is untagged, so all 8 locations there were always fine.
- Power: its AK74u is untagged, already worked.

### Missing models — 6 added to `mod.ff`
Established by dumping the xmodel list of **all 191 fastfiles** in `zone/all`:
`p6_zm_buildable_bench_tarp`, `p6_zm_al_shock_box_on`,
`zm_collision_transit_{cornfield,diner}_survival` (all from `so_*` fastfiles), plus
`p6_pak_old_plywood_small` and `p6_zm_tm_wood_post_thin_01_tall`, which exist in **no** fastfile —
Reimagined authored them, so they are built here from its GLB exports.

Without these, `zm_prison_loc_docks::precache()` was precaching two models that do not exist on
MOTD, and `zm_tomb_loc_excavation_site::precache()` two that exist nowhere.
**Every model used by all 14 location scripts now resolves** against its map's fastfiles + `mod.ff`.
Diner's empty `precache()` is populated; Cornfield's boundary wall is restored.

### Build pipeline
`build.bat` gained step 5: it refreshes any `.lua` that exists in **both** the project and
Plutonium's `raw\`. `raw\` is searched before `mod.iwd`, and its copy of
`privategamelobby_project.lua` was found stale — every LUI edit made this session would otherwise
have been silently shadowed.

---

## 3. 🛑 WHAT NOT TO TRY AGAIN

- **Don't rename a fastfile.** A T6 zone's name is bound to its filename; `mod.ff` copied to
  `mod_base.ff` fails to load with `inflate of stream N failed`. Cost an hour.
- **Don't conclude an asset is missing from a partial search.** Dump all of `zone/all`.
- **Don't reintroduce a LUI override for `GetMapMaterialName` / `GetMapLoadscreenName`.** The
  materials exist now; an override can only make it worse.
- **Don't delete `zone_source\base\mod.ff`.** It is the only copy of 3,510 assets with no source.
- Other Linker traps (`--add-asset-search-path` at the project root; `//` in asset names;
  `keyvaluepairs,mod`) are in `CLAUDE.md` §8.

---

## 4. ⏳ TEST BACKLOG — nothing here has been run

1. **Does each map still boot?** `mod.ff` was rebuilt — the single riskiest change. Boot a stock
   location on each of the 5 maps first. If a map fails where it used to work, restore
   `zone_source\base\mod.ff` over `mod.ff`, run `build.bat`, and the fastfile change is undone.
2. **Origins clientfield fix** (`zmqol_register_survival_clientfields`, from checkpoint 3, deployed
   07:32 and never tested). Origins as Survival used to die with `EXE_CLIENT_FIELD_MISMATCH`.
3. **Preview + loading screen for all 15 locations** — no checkerboards anywhere.
4. **Diner wallbuys**: MP5K in the diner, Galvaknuckles on the roof. This is the specific thing
   reported broken. Console prints `[zm_qol] enable_wallbuys - zstandard_diner: tagged 2 of 2`.
   Then Tunnel (M16, 1 of 1) and Borough (3 of 3).
5. **Docks and Excavation Site** — they precached non-existent models before; confirm they load.
6. Cornfield's restored boundary wall — you should no longer be able to walk out of the play area.
7. Regression: checkpoint 1 (perk descriptions after several revives) and checkpoint 2 (instant
   start), both still unverified from earlier sessions.

---

## 5. NEXT, in order

1. Boot each of the 5 maps on a stock location. Go/no-go on the `mod.ff` rebuild.
2. Origins → Survival (test 2), then the four Origins locations.
3. Diner → check the two wallbuys, then Tunnel and Borough.
4. Walk the rest of the locations, watching for a missing `[zm_qol] loc_common::init reached` line.
5. Once stable: delete this checkpoint, having folded anything durable into `AI_CONTEXT.md`.

**If a crash hunt is needed:** `seta logfile "2"` and `seta r_fullscreen "0"` are already set in both
`players\plutonium_zm.cfg` files, and `save_crash_log.bat` works (its first version used WMIC, which
Windows 11 removed, and silently saved nothing).
