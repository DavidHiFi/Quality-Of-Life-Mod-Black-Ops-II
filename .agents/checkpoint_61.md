# Checkpoint 61 — v1.99.13. Three requests done in one round on the user's instruction. Winter's Howl re-diagnosed, Tac-45 ported, Who's Who solved.

Written 2026-08-16. **Supersedes 60 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

🛑 **The user explicitly suspended the one-at-a-time rule for this round** — *"Do all of this all at
once, right now no queue additions."* It was stated back to them that a bad boot will not name its
own cause with three changes in flight. Their call, taken.

---

## 0. STATE — v1.99.13 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Who's Who description | 🟡 built v1.98.0, never booted |
| 2 | Wunderfizz random first location (B-WF) | 🟡 built v1.97.0, never booted — needs a **multi-machine** map |
| 3 | ~~Riser sound~~ | ✅ CONFIRMED AND CLOSED (checkpoint 60 §2). 🛑 Do not re-open. |
| 4 | **Winter's Howl fx** (B-WHOWL) | 🟡 re-diagnosed and fixed in v1.99.13, **unbooted**. §1 |
| 5 | **Tac-45** (B-TAC45) | 🟡 full port shipped in v1.99.13, **unbooted**. §2 |
| 6 | **Who's Who screen fx** (B-WHOSWHO2) | 🟡 SOLVED — five Die-Rise-only assets now ship. **unbooted**. §3 |
| 7 | Titus-6 reload (B-TITUSRELOAD) | 🔴 a bank job — checkpoint 58 §3 has the spec; the method is proven twice over now |
| 8–15 | `mod.ff` stale script · `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers, the bleedout bar and its live mid-down toggle, the Winter's Howl muzzle
flash rendering at all, and the zombie riser dirt sound.

### 🌟 THE THREE THINGS TO DO ON THE NEXT BOOT
1. `.wintershowl`, fire it — **is there snow now, and is the flash back to the v1.99.7 look?**
2. `.give tac45` and `.give tac45 pap` — **does it fire with sound, reload with sound, and does the
   packed one come up as a dual-wield pair with a camo?**
3. Go down with Who's Who on any map that is not Die Rise — **is the screen overlay there?**

---

## 1. 🌟 B-WHOWL — v1.99.12 WAS WRONG AND THE LESSON IS ABOUT READING FIELD SEMANTICS

v1.99.12 pointed **both** flash fields at `fx_freezegun_world`. Half right (that file *is* the real
effect), half wrong (the first-person field must not be aimed at it).

🌟 **`spawnOneShot` is the count that matters for a muzzle flash; `spawnLooping` is an interval.**
Proven from Treyarch's own `fx_muz_sm_gas_flash_1p.efx`, which carries an explicit
`spawnLoopingSpawnCount 1` next to `spawnLooping 200` — the two fields are different quantities, and
the T6 format simply omits the third one.

| file | spawnOneShot per element | viewmodel-drawn total |
|---|---|---|
| `fx_freezegun_view.efx` | 50, 5, 40, 10, 20, 100, 40 | ~265 particles |
| `fx_freezegun_world.efx` | 1, 2, 4, 1, 4, 4, 0, 5, 4, 0, 1, 1, 0, 1 | **8 particles** |

v1.99.12 therefore swapped a 265-particle first-person flash for an 8-particle one. Exactly the
report.

📝 **`_view` is a lossy re-save of `_world`.** Element bodies match on every spawn range, cull
radius, lifespan and origin; the apparent 5,352-line diff was float formatting (`0.000000` vs `0`).
The converter renamed elements to editor defaults, dropped three (both snow emitters and
`smoke_rings_large_in`) and set `spawnOneShot = spawnLooping` everywhere.

🛑 **Checkpoint 60's premise is retired.** "Hand-authored element names = the real file, generic
`wraith_*_def*` = a junk template" is false — `wraith_oneshot_def*` naming appears in Treyarch's own
shipped muzzle flashes. Two checkpoints in a row built confident conclusions on that reading.

**The change:** the two defs back to the `view→_view` / `world→_world` convention both other wonder
weapons use, and the two `gfx_fxt_env_snow_flakes` elements copied **verbatim** (201 lines each) into
`fx_freezegun_view.efx`, `fx_freezegun_ug_view.efx` and `fx_freezegun_ug_world.efx`. Both already
carry `drawWithViewModel`. This also closes the PaP asymmetry checkpoint 60 flagged.

**Verbatim was checked, not assumed.** The three freezegun effects the user has confirmed seeing —
shatter, impact, crumple — all use single-digit `spawnOneShot` on their large elements (1, 3, 4, 6 at
size 145–370). The snow elements are 1 and 5 at size 200. Same range.

### 🌟 THE STANDING LESSON FROM FOUR ROUNDS ON ONE GUN
Round 1 audited the wrong file's contents. Round 2 deleted from the wrong file. Round 3 fixed the
assignment but got the direction wrong. Round 4 read what the numbers in the file actually *mean*.
**"Which file?" was the right question and was still not the last one — "what unit is this field?"
was.** A field name that looks self-explanatory (`spawnLooping`, `spawnOneShot`) is worth one lookup
in a file the engine authors wrote.

---

## 2. 🌟 B-TAC45 — the twelfth box weapon, and the port is complete

**The def is `fnp45`.** BO2 ships the Tac-45 under its development name in the def, the art, the
camo, the HUD material and every sound alias — the release name exists only in the localized string.
Same trap as the XPR-50's `as50`. [[t6-asset-vs-def-name-mismatch]]

**It is dual-wield when Pack-a-Punched**, so three defs ship (`fnp45_zm`, `fnp45_upgraded_zm`,
`fnp45lh_upgraded_zm`), the upgraded pair naming each other through `DualWieldWeapon` — the shape
stock uses for Mustang & Sally, checked against `m1911_upgraded_zm` rather than assumed.

Everything was verified inside the built artefacts:

| part | check |
|---|---|
| 4 xmodels, 71 xanims, camo, HUD material | present in the deployed `mod.ff` (5,090 assets), all out of `common_mp.ff` which was **already** `--load`ed — the load order is untouched |
| 54 sound aliases, 15 payloads | in `mod.all`; `wpn_fnp45_fire_plr`'s audio dumped back out at 176,750 bytes and **no `Could not find data for sound`** for any fnp45 row |
| strings | `ZMWEAPON_FNP45_UPGRADED` = "Toughguy & Crybaby" ours; `WEAPON_FNP45` = "Tac-45" already in `en_code_post_gfx_zm.ff` |
| PaP safety | all three defs have an **empty** `attachments` field, identical to mk48 / insas / crossbow / titus6 — the four that already ship with no `pap_attach_qol.csv` row. The v1.89.3 freeze cannot apply. |
| PaP camo | `camo_fnp45`'s `camoMaterials[3]` already maps to `mtl_weapon_camo_zombies` — no Titus-style repair needed |

Cost 500 and an **empty** vox pack are BO2-Reimagined's own values for this gun
(`_zm_reimagined.gsc:2038`). The empty vox is correct, not an omission: the pistol class maps to
`wpck_crappy` (`_zm_audio.gsc:123`) and that alias is in **no** zombies bank — dumped
`zmb_survival_transit`, `zmb_tomb` and `zmb_buried`. Stock passes `""` for `m1911_zm` too.

🟡 **The one thing reported rather than shipped:** the knife-bash whoosh is silent.
`wpn_tac_knife_whoosh_npc/plr` exists in no zombies sound bank; neither Reimagined nor stock's own
`judge_zm` ships it, so the Tac-45 behaves exactly like the stock Executioner. Adding it would also
change the Executioner's melee audio, which is outside the request. **The user's call.**

---

## 3. 🌟 B-WHOSWHO2 — SOLVED, AND THE USER'S OWN OBSERVATION IS WHAT SOLVED IT

*"the audio fx are still working ... like the guy saying 'who's who' subtly."*

That single detail eliminated every remaining script theory. `activate_chugabud_effects_and_audio()`
(`_zm_chugabud.gsc:745-762`) activates the visionset and writes **both** clientfields from four
consecutive lines. Audible sting and looper ⇒ the function ran, the gate was set, `create_corpse`
was 1, and the filter clientfield went out in the same breath.

**Five assets ship in `zm_highrise.ff` and nowhere else**, measured against an index of all 191
fastfiles in `zone\all` plus `zone\english`:

```
rawfile,      vision/zm_whos_who.vision
techniqueset, sw4_2d_afterlife_q51e4w21
image,        zm_whoswho_warpblur
image,        zm_whoswho_mask
material,     generic_filter_afterlife
```

Off Die Rise the client handed filter pass 5 a material that was not loaded and activated a visionset
that did not exist. **In T6 neither is an error** — the pass draws nothing, the visionset is a no-op.

📝 *"It worked at some point"* is consistent: `zmqol_whoswho_enabled()` returns 0 on Die Rise because
the map ships the perk, so there the overlay has always been stock's with all five assets present.
Every other map has never had them.

**The fix is `zone_source\mod_whoswho.zone`.** No new `--load` (`zm_highrise.ff` was already at line
332). The techset came along transitively — checked in the built `mod.ff`, not assumed. The two
images were rebuilt from Treyarch's own source PNGs (`BlackOps3Shaders\source_data\shader_templates\
_images\`, dimensions cross-checked against the dlczm1 IPAK dump) through `png2dds.ps1` →
`ImageConverter`, and land in `images\` too so their pixels travel.

🛑 **The pre-mortem that mattered:** does `mod.ff` owning a Die Rise asset break Die Rise? Measured,
not feared — the built `mod.ff` **already shares 2,546 asset names with `zm_highrise.ff`** and
1,801–2,422 with every other map, and boots on all of them. The recorded `Attempting to override
asset` failure was a `soundbank`, a different class entirely.

---

## 4. NEW REUSABLE FACTS

- 🌟 **A full index of every fastfile is cheap and settles asset questions in one grep.**
  `Unlinker --list` over all 191 `zone\all` + `zone\english` fastfiles took a few minutes and
  answered three separate questions this round: where the Who's Who assets live, that every Tac-45
  effect is already on every zombies map, and where `WEAPON_FNP45` resolves.
- 🌟 **`spawnOneShot` vs `spawnLooping` in a `.efx`** — see §1. The BO3 fx library's explicit
  `spawnLoopingSpawnCount` is what proves the distinction.
- 🌟 **Duplicate asset NAMES between `mod.ff` and a map are normal and safe** (thousands already),
  except for `soundbank`.
- 📝 **A converted `.efx` can be diffed against its source only after normalising float formatting** —
  `0.000000` vs `0` inflated a 6-line difference into 5,352.
