# Checkpoint 30 — Zombie Blood + the three announcer lines built and deployed. v1.65.0, NOT booted.

Written 2026-08-11. Supersedes checkpoint 29 for status only — 29's §2 (decode the user's recording)
and §3 (the visionset window) are still the useful parts and should be kept.
Keep 28 §1, 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **Zombie Blood (5 maps) + 3 announcer lines** | 🚧 **v1.65.0 DEPLOYED, NOT YET BOOTED** — the item in flight |
| Blood Money everywhere (v1.64.0) | 🚧 deployed, not reported on |
| Buried CLASSIC boots under this mod | ✅ confirmed by the user 2026-08-11 — this is what unblocked Zombie Blood |
| Who's Who visuals | ✅ confirmed in game |
| Electric Cherry | 🛑 CLOSED. Vanilla by the user's decision. Do not re-open. |
| Boarded-window fix (v1.63.1) | ⏳ booted since, never reported on either way |
| v1.62.3 Vulture icon shapes | ⏳ still never tested |
| v1.62.4 Vulture machine markers | 🛑 measured broken (`0 of 43 structs match`) |

**Next action: wait for the user to boot BURIED CLASSIC.** Nothing new starts until they do
([[zm-qol-one-at-a-time]]). Buried classic is named specifically because it is the only map at real
risk — see §2.

---

## 1. WHAT SHIPPED — v1.65.0, commit `bac7149`

**Zombie Blood**, ported asset-for-asset from Origins onto the other five maps, **gated off
`zm_tomb`** so that map keeps running Treyarch's copy as a clean A/B baseline (the Electric Cherry
discipline).

| | |
|---|---|
| server | `zmqol_zombie_blood_enabled()` gate · `zmqol_enable_zombie_blood()` from `perks()`/`main()` · `zmqol_register_zombie_blood_visionsets()` from `init()` · `zmqol_zb_powerup()` + 5 helpers · `zmqol_register_announcer_vox()` |
| server hook | one `zombie_blood` branch in `custom_powerup_grab()`, **gated** |
| client | `zmqol_enable_zombie_blood()` (include only) from `perks()` · `zmqol_zb_register()` + 7 helpers, all from `perks_register_clientfield()` |
| `mod.ff` | 6 asset lines → **48 assets added, 0 removed, 0 re-owned** |
| sound | 10 alias rows + 7 payloads + **the first duck this project has ever shipped** |
| `build_ff.bat` | gained a duck-staging step |

**The three announcer lines**, all reached through the generic
`_zm_powerups.gsc:1147 leaderdialog( self.powerup_name )`:

| `createvox` key | alias | payload source | gate |
|---|---|---|---|
| `zombie_blood` | `vox_zmba_qol_powerup_zombie_blood` | `zmb_tomb.english` | off `zm_tomb` |
| `bonus_points_player` | `vox_zmba_qol_powerup_blood_money` | `zmb_tomb.english` | none |
| `deathmachine` | `vox_zmba_qol_powerup_death_machine` | `zmb_highrise.english` | none |

---

## 2. ⚠️ THE ONE THING THAT COULD NOT BE SETTLED OFFLINE — the `toplayer` budget

Buried classic stock is **63** `toplayer` bits. Under this mod it computes to **~68-69**
(+2 `perk_dead_shot`, +2 `perk_tombstone`, +1 `perk_electric_cherry`, +1 `visionset_slot`), and the
user **booted exactly that on v1.64.0 and it played** — so the ceiling is **≥ 69**.

Zombie Blood adds **+2** (`powerup_zombie_blood`), **+1** (`visionset_lerp` widens 3→4 for its 15
lerp steps) and up to **+2** more if either slot field gains a bit → **~71-73**.

The only hard upper bound is checkpoint 17's Mob crash, whose numbers were themselves an estimate.
**So the ceiling is bracketed roughly [69, ?] and this build may sit above it.**

`allplayers` WAS measured properly and is fine: Buried classic stock 28, +2
`electric_cherry_reload_fx`, +1 `player_zombie_blood_fx` = **31/32**. 🛑 **One bit spare — know that
before adding anything else to that set.**

**If it fails it fails loudly at load**, `Trying to assign N bits for netfield <x> but Client Field
Set TOPLAYER is out of space`, naming whichever field asked last (which will probably be a *stock*
field — read it as "someone before me used the space"). That costs one boot and pins the ceiling
exactly, which nothing offline can do.

**If it comes to that, the bit to free is Buried's native 5-bit `vulture_perk_disease_meter`** —
this mod already knows how to drop it (`zmqol_vulture_has_disease_meter()`).

🛑 **Zombie Blood is NOT gated to survival modes to dodge this.** A power-up present in one mode of a
map and absent in the other is the half-implementation this project does not ship.

---

## 3. 🌟 FOUR FINDINGS WORTH KEEPING — each changed the design

### 3a. Clientfield registration ORDER does not have to match between the sides

Only the **set** of names, versions, sets and bit widths must agree. Proven by this mod's own
Vulture: the server registers its eight fields from `main()`, the client from `_zm_perks::init()`,
and it ships and boots on five maps. Visionsets are immune by construction anyway —
`_visionset_mgr::add_sorted_name_key()` sorts names **alphabetically** before
`finalize_type_clientfields()` assigns `slot_index`, so both sides land on the same slots regardless
of call order.

This is what let Zombie Blood register from `main()` on the server and from
`perks_register_clientfield()` on the client.

### 3b. 🛑 `level.vsmgr_filter_custom_enable` is WIPED after client `main()`

`clientscripts\mp\_visionset_mgr.csc:15` does `level.vsmgr_filter_custom_enable = []`, and it is
reached from `_zm.csc:39` — **later than this mod's client `main()`**. Setting the red-overlay hook
there would have been silently erased, the overlay would have fallen through to the generic branch
(`_visionset_mgr.csc:527`) and the filter would never have faded in. No error anywhere.

**Four independent timing constraints all land on `perks_register_clientfield()`**, which is why the
entire client half lives there:

1. the wipe above (needs to be after `_zm.csc:39`)
2. `level.vsmgr` does not exist during `main()` at all — [[t6-visionset-registration-timing]]
3. `onplayerconnect_callback` must precede `level._customplayerconnectfuncs` being armed at
   `_zm.csc:96`
4. `add_zombie_powerup` must precede `_zm_powerups.csc::init()` threading
   `set_clientfield_code_callbacks()` at `_zm.csc:63`

### 3c. 🛑 The 12 character reaction lines must NOT be ported

Origins records `vox_plr_0..3_powerup_zombie_blood_0..2`, and `_zm_audio::create_and_play_dialog()`
picks by **the player's character index**. Shipping them would put the Origins cast's voices in
Misty's, Marlton's, Russman's and Stuhlinger's mouths on every other map — not the original
behaviour, a new and worse one. With no vox registered the call returns silently, which is exactly
stock's own path for an unregistered dialog type.

📝 **The contrast that makes this the right call:** `c_zom_tomb_german_player_fb` IS ported, because
Origins passes that one model regardless of who you are — it is character-*neutral*. The VO is
character-*keyed*. Same feature, opposite answers, and the deciding question is the same one:
*does the original vary this per character?*

### 3d. The announcer alias shape is dictated by the engine, not chosen

`_zm_powerups.gsc:1147` announces every power-up via `leaderdialog( self.powerup_name )`, and
`playleaderdialogonplayer()` builds the alias as
`game["zmbdialog"]["prefix"] + "_" + game["zmbdialog"][dialog]` with prefix `vox_zmba`.

🛑 **So a ported announcer alias MUST be named `vox_zmba_*`** — a `zmqol_*` name can never be reached
down that path. Mod-privacy is kept with a `qol_` infix instead.

🌟 **And each line ships TWICE, with and without the `_0` suffix.** `getleaderdialogvariant()` calls
`get_number_variants()`, a `soundexists( base + "_" + i )` loop; whether `soundexists()` can see an
alias in a **mod's own** bank is not answerable from any dump or log in this workspace. If it can,
the engine plays `<base>_0`; if it cannot, `playleaderdialogonplayer` falls back to `<base>` verbatim.
Shipping both names means either branch lands on a real alias, and only one is ever played. A
missing alias is SILENT, never an error — which is exactly why the belt and braces is worth three
spare rows.

---

## 4. 🛑 A CORRECTION CARRIED OUT — v1.64.0's Blood Money write-up was WRONG

It claimed the silent announcer was deliberate parity. **That was measured on the wrong path.**

It is true that `createvox( "bonus_points_solo", … )` appears nowhere in the 2,093-file stock dump,
so `powerup_grab()`'s `powerup_vo( "bonus_points_solo" )` really does return without playing. But
**Origins reaches its Blood Money line by a different route entirely** — its dig script's own
`leaderdialog( "blood_money" )` at `zm_tomb_dig.gsc:773`. The line exists, and porting it is correct,
not a tuning change.

Fixed in the code comment, `MOD_CATALOGUE.md` §7a, `QUEUE.md` and here.

📝 **The general lesson**: "grep found no `createvox` for this key" proved only that ONE path was
silent. Before concluding a feature has no audio, find every route that reaches it.

---

## 5. NEW FACTS ABOUT THE PIPELINE

- **OAT's Linker supports sound-bank DUCKS**, and this project now ships one. Confirmed from its own
  format strings: `soundbank/{bank}.ducklist.csv` and `soundbank/ducks/{name}.duk`. An alias naming a
  duck the bank cannot supply is a **hard link error**, not a silent no-op:
  `Unable to find .duk file for {} in ducklist for sound bank {}`. `build_ff.bat` now stages both from
  `soundbank\` at the project root. The donor `mod.all` had **zero** ducks, so this is new ground —
  verified by dumping the built bank and confirming the duck round-trips byte-identical.
- **The right baseline for a sound-bank diff is the PREVIOUSLY SHIPPED `mod.ff`, not the donor.**
  Diffing against the donor showed 104 spurious "new" aliases (rows added in earlier releases, which
  live in the `zone_assets` cache) plus a `.wav.wav` → `.wav.wav.wav` shift that is purely the
  Unlinker adding one extension per dump. `git show HEAD:mod.ff` into a temp folder and dump that
  instead — it gave a clean **1791 → 1801, zero pre-existing rows changed**.
- **`playsound( "death_machine" )` in `deathmachine_powerup()` matches no alias in any of the nine
  banks dumped** (`zmb_tomb.all/.english`, `zmb_highrise.english`, `zmb_common.all`, `zmb_patch.all`,
  `mod.all`, `deathmachine_zm.all`, …). The Death Machine drop has always been silent. The new
  announcer line is the first sound it makes.
- **Origins' `_zm_powerup_zombie_blood.csc` was deliberately NOT shipped.** It lives in
  `zm_tomb_patch.ff`, and adding a fastfile to `build_ff.bat`'s `--load` list risks re-donating a
  shared asset (the v1.62.6 blown-out-shader bug). Porting the ~90 lines inline cost nothing because
  every function it uses is core client code.

---

## 6. THE TEST TO ASK FOR — Buried classic FIRST

1. **Buried classic — does it load at all?** That is the whole budget test (§2). It is the fullest
   map in the game; if it loads, every other map will.
2. Kill zombies until power-ups drop. A **blood-drop icon** should appear in the rotation. Grab it:
   screen goes red, player becomes an Origins German zombie, **zombies walk straight past for 30
   seconds**, looping sound with everything else ducked under it.
3. **The announcer should call it** — and should now also call **Blood Money** and the **Death
   Machine**, both of which have been silent until now.
4. **Origins must be unchanged** — its own Zombie Blood, its own announcer line, its dig sites.

---

## 7. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | ✅ DONE |
| 2 | Zombie Blood power-up from Origins onto every map | 🚧 **built v1.65.0, awaiting boot** |
| 3 | Blood Money power-up, dropping from kills rather than dig sites | 🚧 built v1.64.0, awaiting boot |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command must also be a dvar — [[zm-qol-commands-as-dvars]].
Governing rule for all of them: **port it, never tune it** — [[zm-qol-port-never-tune]].
