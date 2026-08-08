# Checkpoint 25 — v1.62.7. Electric Cherry's zap: mod.ff shipped the wrong shader. Deployed, NOT booted.

Written 2026-08-09. Supersedes checkpoint 24 (v1.62.6, now CONFIRMED in game).
Keep 24 §2a (you can patch ONE LUI function) and §2c (offline Lua validation).
Keep 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

**Read §0, §2 and §3.**

---

## 0. THE SINGLE NEXT ACTION

**Get Electric Cherry, empty a clip, reload with zombies close.** The zap on their bodies must be
lightning arcs, not a bright blob — and it must look the same on Diner as it does on Mob.

Nothing else starts until that is confirmed — [[zm-qol-one-at-a-time]]. No script changed this
round, so a bad boot has exactly one possible cause.

⚠️ **Also glance at the reload burst around your own body.** That fx changed donor too (Origins →
Mob) even though it was never complained about. It should still look right; if it does not, that is
this change and it is a one-line revert.

**Still deployed and NEVER booted, from earlier rounds:**

| version | how to test |
|---|---|
| v1.62.0 | Boot **Mob**, carry two plane parts at once. Log: `[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N` |
| v1.62.3 | Vulture's through-wall icons should have real shapes, not colour blurs |

🛑 v1.62.4 (Vulture perk-machine markers) is **measured broken** — `0 of 43 structs match`. See
checkpoint 24 §4.

---

## 1. WHAT HAPPENED THIS SESSION

1. **v1.62.6 CONFIRMED.** User: *"It seems to be fixed."* The perk row survives a down with 12 perks.
2. The user handed over **`H:\Claude\TASKS_QUEUE_01.txt`** — five numbered tasks, to be done top to
   bottom, one at a time. Copied into `QUEUE.md` under "THE USER'S TASK LIST".
3. Task 1 is Who's Who + Electric Cherry visuals. **The Electric Cherry half shipped as v1.62.7.**

---

## 2. 🌟 THE FINDING THAT MATTERS FAR BEYOND THIS BUG

### `--load` ORDER IN `build_ff.bat` DECIDES WHICH COPY OF A STOCK ASSET THE MOD SHIPS

OAT's Linker resolves each declared asset from the **first `--load`ed fastfile that holds a real
definition**. A `type,,name` entry is a *reference* and carries no data, so the Linker keeps looking
past it. Crucially, **two stock fastfiles can hold different bytes under the same name** — Treyarch
ships per-map shader permutations and per-map fx rebuilds.

`mod.ff` loads **before every map**, so whichever copy it happens to bake in becomes the version the
game uses **on every map, including the ones the asset is native to**.

That is how a mod that adds nothing to Mob of the Dead broke Mob of the Dead's Electric Cherry.

```
techniqueset effect_zeqqz943 — the shader behind the tesla-shock flare materials
  zm_prison / zm_tomb / zm_highrise   503675916d7525ca   4928 bytes   <- all identical
  so_zsurvival_zm_transit             b6c22239cf5774a5   4928 bytes   <- what shipped
```

`so_zsurvival_zm_transit.ff` was `--load`ed 3rd, `zm_prison.ff` 8th.

### 🔎 The diagnostic route, worth reusing verbatim

1. **The user's answer split the search space in half.** "Is it wrong on Mob and Origins too?" —
   yes. A defect on maps the mod does not touch cannot be map-side. That one question was worth
   more than every theory tried before it. [[prefers-evidence-over-questions]] still holds: ask only
   after the shipped data is exhausted, and ask something that *discriminates*.
2. **Enumerate an fx's real dependencies by linking a one-asset zone.** Write
   `>game,T6` + `fx,maps/zombie/fx_zombie_tesla_shock` into a scratch `.zone`, link it against one
   fastfile, then `Unlinker --list` the result. That prints the exact material/image/techset closure
   — no guessing about what an effect uses.
3. **Compare two donors' copies of ONE asset by hashing two one-asset fastfiles.** Same zone, two
   different `--load`s, `sha256sum` both. Identical hash = the donors agree and the choice is a
   no-op. This is how 64 changed assets were reduced to the 20 that actually matter.
4. **`grep -oE 'Loaded [a-z]+ "[^"]+" \(src: [a-z0-9_]+\)'` over the link log** gives a full
   asset→donor attribution table. Diff two orders' tables to see exactly what a reorder moves.

### What shipped

`zm_prison.ff` + `zm_prison_patch.ff` moved ahead of every `so_*.ff`. Electric Cherry's whole chain
now comes from **one** canonical donor — its home map — instead of four: 5 alcatraz cherry fx,
3 tesla fx, the bottle weapon + 2 xmodels, HUD and minimap icons, the vision file, and every
lightning material/techset under them.

**Verified before hand-off:** built `mod.ff` byte-identical to the audited scratch build
(`587f2f7c…`) · **asset list identical before and after, 3812 lines, nothing re-owned or dropped** ·
0 errors, same 34 pre-existing sound warnings · the shipped techset extracted back *out of the built
`mod.ff`* and byte-matched against `zm_prison.ff` · deployed md5 matches source · v1.62.6's LUI fix
confirmed still present inside the deployed `mod.iwd`.

### ⚠️ Residual, stated not hidden

- The four `fx_alcatraz_electric_cherry_*` reload effects changed donor too and all four differ in
  bytes. They were not complained about. Mob's are canonical, but this is a change to something that
  worked.
- `mc_lit_sm_r0c0d0n0_33ffej1u`, `_r0c0n0x0_q361191u`, `_t0c0n0_9qf6e4qj` differ on **every** map,
  so no donor is right for all. `mod.ff` has always overridden them globally; this only changes which
  map they match. Pre-existing — the real repair is to stop owning them (QUEUE §0f item 4).
- `fxt_fx_emp_ring_wave` improves: Origins' odd-one-out copy → the one TranZit/Mob/Buried share.

---

## 3. NEXT: TASK 1'S OTHER HALF — WHO'S WHO VISUALS. Scoped, not started.

**User's decision, 2026-08-09: remove Who's Who from Buried entirely** rather than ship it there
without the downed-body glow. Buried's `actor` clientfield set is **32/32** — re-measured this
session from `clientfields_zm_buried_zclassic_processing.txt`, summing all 21 actor fields. So
Who's Who ships complete on **TranZit/Diner, Nuketown and Origins** and is dropped on Buried.

### The working precedent — `BO2-Reimagined`, a shipped mod that does exactly this on `zm_transit`

| | |
|---|---|
| server | `_zm_reimagined.gsc:1997-2003` — sets `level.whos_who_client_setup = 1`, `level.vsmgr_prio_visionset_zm_whos_who = 123`, registers the three clientfields |
| client | `_zm_reimagined.csc:85-97` — same three fields **with callbacks**, plus `register_perk_init_thread("specialty_finalstand", ::init_chugabud)`; `init_chugabud` does `vsmgr_register_visionset_info("zm_whos_who", 5000, 1, "zm_whos_who", "zm_whos_who")` and threads `chugabud_setup_afterlife_filters()` |

The three fields, symmetric on both sides:
`actor clientfield_whos_who_clone_glow_shader 5000 1 int` ·
`toplayer clientfield_whos_who_audio 5000 1 int` ·
`toplayer clientfield_whos_who_filter 5000 1 int`

### Assets that must go into `mod.ff` — both Die Rise-only, both with a precedent here

| asset | precedent already shipping |
|---|---|
| `material generic_filter_afterlife` | `generic_filter_zombie_perk_vulture` |
| `rawfile vision/zm_whos_who.vision` | `rawfile vision/zm_electric_cherry.vision` |

Confirmed by `Unlinker --list`: neither exists in `common_zm.ff`, `patch_zm.ff`, or any map fastfile
except `zm_highrise.ff`.

### 🛑 Traps found while scoping

- **`whoswhoaudio` / `whoswhofilter` are MAP-SPECIFIC** (`clientscripts\mp\zm_highrise_amb.csc`).
  Naming them from a root client script resolves at load time and kills every other map —
  AI_CONTEXT rule 2. Write our own; they are 6 lines each. Everything underneath them —
  `enable_filter_afterlife`, `disable_filter_afterlife`, `chugabud_whos_who_shader`,
  `chugabud_setup_afterlife_filters` — is **core** `_zm_perks.csc` and safe to reference.
  Reimagined violates this and gets away with it; do not copy that part.
- **The audio needs aliases** `evt_ww_activate`, `evt_ww_looper`, `evt_ww_deactivate` and snapshot
  `zmb_duck_ww`. Not yet checked for existence off Die Rise. A missing alias is **silent, never an
  error** — [[t6-soundbank-facts]] — so this must be confirmed, not assumed.
- **The corpse glow needs per-character `_fb` models.** Die Rise sets
  `self.whos_who_shader = "c_zom_player_<char>_dlc1_fb"` (`zm_highrise.gsc:1185-1213`) and only
  `zm_highrise.ff` carries those four xmodels. Off Die Rise `self.whos_who_shader` is undefined, so
  `spawn_player_clone` makes an ordinary corpse and the glow field drives nothing. **This is the
  part that still needs solving for TranZit/Nuketown/Origins**, not just Buried.
- **`level.chugabud_shellshock` is set nowhere in the 2,093-file stock dump.** The shellshock never
  fires in stock either — it is not part of the genuine article. Do not add it.

---

## 4. STILL OPEN, in the user's stated order

- **`TASKS_QUEUE_01.txt` 2** — Zombie Blood power-up on every map. 📝 `generic_filter_zombie_blood_b`
  is in `zm_tomb.ff` only; same shipping shape as the two Who's Who assets above.
- **`TASKS_QUEUE_01.txt` 3** — Blood Money, and it must drop from **kills**, not dig sites.
- **`TASKS_QUEUE_01.txt` 4/5** — Semtex wall-buys (Diner + Bus Depot), Galvaknuckles (Bus Depot).
- **QUEUE §0B** — every chat command as a dvar/console command, plus stripping stray quotes from
  chat input (`.giveperks"` fell through the dispatcher in silence).
- **QUEUE §0A-C** — the Vulture marker filter matching 0 of 43 structs on Diner.
- **QUEUE §0f** — solo intro/"CUSTOM GAMES" header; god mode after Mob's afterlife; Mob Wunderfizz
  overlapping the shield part; custom texture packs; the stray 254 MB `cmn_root.all.sabl`.
