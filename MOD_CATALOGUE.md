# MOD_CATALOGUE.md — everything Quality Of Life changes and adds

**Companion file: [`STOCK_REFERENCE.md`](STOCK_REFERENCE.md)** — what the *unmodified* game does.
Keep the two apart: this file is "what we changed", that file is "what it was". When a claim here
depends on stock behaviour, the stock side belongs over there, not duplicated here.

| | |
|---|---|
| Catalogue accurate as of | **v1.62.4**, 2026-08-08 |
| Source of truth | the files in this repo, read directly. Nothing here is from memory |
| Maps | `zm_transit`, `zm_nuked`, `zm_highrise`, `zm_prison`, `zm_buried`, `zm_tomb` |

## 🛑 Rules for maintaining this file

1. **Verify before writing.** Count the files, grep the registration, read the function. "It was in
   the plan" is not "it shipped" — the README once claimed seven survival locations when one
   existed.
2. **Update it in the same change that alters behaviour**, exactly like `README.md`.
3. **Mark confidence.** ✅ verified this session · 📄 read from source · ⚠️ believed, not proven ·
   ❌ known missing. Never promote ⚠️ to ✅ without doing the check.
4. **Deployed ≠ done.** Anything not yet confirmed in game by the user says so.

---

# 1. Shipped files and what each one is

The mod is exactly **5 top-level files**. Only `mod.iwd`'s raw source folders are hand-edited.

| file | what it is | hand-edited? |
|---|---|---|
| `mod.iwd` | zip of `scripts/ ui_mp/ images/ maps/ weapons/ attachmentunique/`; Plutonium runs raw `.gsc` straight out of it | **yes**, via `pack_iwd.ps1` |
| `mod.ff` | fastfile: assets + the client `.csc` scripts | rebuilt by `build_ff.bat` |
| `mod.json` | name / author / description / version | yes |
| `mod.all.sabl`, `mod.all.sabs` | sound banks | no |
| ~~`deathmachine_zm.all.sabl`~~ | **Gone at v1.99.55** — merged into `mod.all`. It was a pure duplicate: same 18 alias names, and the 11 audio files it held total 2,320,478 bytes against a 2,322,480-byte bank, the difference being the header. Its authoritative `Pan` / `Duck` / `RandomizeType` values (which the `mod.all` copies had lost) are now in `soundbank\mod.all.aliases.additions.csv` | — |

## 1a. Script inventory 📄

19,540 lines total across 26 files.

| file | lines | scope | role |
|---|---|---|---|
| `scripts/zm/quality_of_life.gsc` | 7264 | every map | main merge — 17 former root scripts + later additions |
| `scripts/zm/wunderfizz.gsc` | 2475 | every map | the mod's own Wunderfizz (renamed copy of Origins' `zm_perk_random` tree) |
| `scripts/zm/zm_expanded.csc` | 1119 | every map | client half — clientfields, perk enables, Vulture markers |
| `scripts/zm/zm_tomb/zm_tomb.gsc` | 1257 | Origins | |
| `scripts/zm/qol_options.gsc` | 864 | every map | console dvar options, adapted from BO2-Remix (options only) |
| `scripts/zm/locs/zm_transit_loc_diner.gsc` | 525 | TranZit | the Diner survival location |
| `scripts/zm/locs/loc_common.gsc` | 512 | TranZit | shared survival-location plumbing |
| `scripts/zm/zm_nuked/zm_nuked.gsc` | 491 | Nuketown | |
| `scripts/zm/zm_highrise/zm_highrise.gsc` | 464 | Die Rise | |
| `scripts/zm/zm_transit/zm_transit.gsc` | 361 | TranZit | |
| `scripts/zm/zm_prison/zm_prison.gsc` | 309 | Mob | |
| `scripts/zm/replaced/utility.gsc` | 242 | every map | `struct_class_init` replacement |
| `scripts/zm/zm_buried/zm_buried.gsc` | 193 | Buried | |
| `scripts/zm/bleedout_bar.gsc` | 150 | every map | bleedout bar, imported from Nathan3197 / Stick Gaming |
| `scripts/zm/zm_transit/disable_fog_transition.gsc` | 111 | TranZit only | 🛑 lives here, not in the root script — see §9 |
| `scripts/zm/replaced/zm_transit_gamemodes.gsc` | 51 | TranZit | gamemode init replacement |
| per-map `.csc` × 6 | 128–252 | one map each | client halves |
| `clientscripts/mp/zombies/_zm_perk_vulture.csc` | — | — | **stock compiled bytecode**, shipped unmodified so it resolves off Buried |
| `ui_mp/**/*.lua` × 3 | 873 / 714 / 362 | client | whole-file LUI replacements. The powerups file also carries the perk-row fix — §3d |
| `privateonlinegamelobby.lua` × 2 | 63 each | client | solo-lobby title — §8. **Identical copies under `ui/` and `ui_mp/`**; T6 resolves `T6.Menus.X` against both roots and the search order is unmeasured |

---

# 2. Chat commands ✅

Prefix `.` `!` or `/`. Verified against every `cmd == "…"` branch in
`zmqol_dev_command_listener()` and against the in-game `.help` panel, which are kept in sync.

## 2a. Core commands

| command | short | effect |
|---|---|---|
| `.help` | | toggle the on-screen command panel (stays until toggled off) |
| `.p <n>` | | add `n` points |
| `.where` | | print x/y/z **and yaw** to chat and console |
| `.god` | | invulnerability |
| `.ghost` | | zombies ignore you (`self.ignoreme`) |
| `.afk` | | god + ghost together |
| `.fly` | | noclip with real WASD, jump/stance, melee to stop |
| `.fog` | | fog on/off |
| `.nightmode` | `.night` | night mode ⚠️ **known broken — screen goes fully black** |
| `.infammo` | `.infiniteammo` | never run dry |
| `.infsprint` | `.infinitesprint` | never tire |
| `.reload` | | refill current weapon |
| `.pack` / `.unpack` | | Pack-a-Punch the held weapon, no machine/cost/animation |
| `.nozmspawns` | | stop zombie spawning; existing zombies remain |
| `.giveperks` / `.removeperks` | | all perks on this map, on or off |
| `.give<perk>` / `.remove<perk>` | | one perk — `jug speed dtap stam mule revive deadshot phd tombstone whoswho cherry vulture` |
| `.hud on` / `.hud off` | | master HUD switch - also hides the GAME's own hud (points, ammo, round, perks) via `setclientuivisibilityflag( "hud_visible" )`. Console twin `hud_master` |
| `.powerups` | | list every power-up registered on this map |
| `.powerup <name>` / `.drop <name>` | | spawn one. Every power-up is also its own command; short forms `.dm .nuke .maxammo .insta .dp .carp .sale` |
| `.testsound [alias]` | v1.99.8 | 🔬 **diagnostic.** Plays a sound alias three ways so you can hear which part is broken: **2D** (no distance model), **3D at your own feet**, then a fixed **control** (`zmb_powerup_grabbed`). Defaults to `zmb_zombie_spawn`, the riser sound. Console twin `zmqol_testsound <alias>` works on its own — it is a CLIENT dvar the client script polls, so it does not need the server. Built for B-RISERSOUND |

## 2b. Console dvars 📄

🌟 **Every chat command is also a dvar** (v1.86.0) — same name, no `.` prefix, and ANY non-empty
value fires it: `round 100`, `p 5000`, `pack 1`. A value is required, because GSC can only register
a dvar, never a real console command — bare `pack` just prints the dvar. `qol "<line>"` takes a whole
command line and so covers the alias families: `qol "givejug"`, `qol "maxammo"`.
⚠️ A name that is already an ENGINE console command (`god`, `drop`, `reload`) runs the engine's
version instead of the mod's — the console resolves commands before dvars.

`fly` · `night_mode` · `rapid_fire` · `character` ⚠️ *(reported to do nothing)* · `coop_pause` ·
`no_power` · `lod_fix` · `hud_master` · `hud_all` · `hud_timer` · `hud_health_bar` · `hud_remaining` ·
`hud_zone` · `hud_round_timer` · `hud_color "1 1 1"` · `hud_color_health` ·
`hud_color_timer "0.2 0.3 0.6"` · `hud_color_round_timer "0.2 0.3 0.6"` *(the two top-right
timers, dull navy since v1.95.3)* · `zmqol_ring_hud_hide` / `zmqol_ring_hud_delay "0.5"`
*(Origins only — the generator-ring visibility fix, v1.95.4; raise the delay if the ring is still
missing, set `zmqol_ring_hud_hide 0` to disable)* ·
`sv_deathmachine_duration` · `sv_deathmachine_powerup` · `redhitmarkers` ·
`disable_player_quotes` · `r_sky_intensity_factor0` · `anim_pap_camo_buried` /
`_mob` / `_origins` · Wunderfizz tuning (`zmqol_wf_fx`, `zmqol_wf_fx_ug`, `zmqol_wf_fx_range`,
`zmqol_wf_yaw_off`, `zmqol_wf_wall_gap`, `zmqol_wf_axis_snap`) · Diner tuning
(`zmqol_pap_diner_x/y/z/yaw`, `zmqol_diner_hatch_clip`, `zmqol_diner_hatch_ladder`)

---

# 3. Perks

## 3a. Perks added to maps that never had them ✅

Each list lives in **exactly one function**, asked by every call site, and has an **exact twin in
the client script**. If the two disagree the server and client clientfield sets differ in width and
every player is dropped with `EXE_CLIENT_FIELD_MISMATCH`.

| perk | added on | excluded on | why excluded |
|---|---|---|---|
| **Electric Cherry** | `zm_transit`, `zm_nuked`, `zm_highrise`, `zm_buried` | `zm_prison`, `zm_tomb` | stock already enables it there; registering twice re-registers its clientfields |
| **Who's Who** | `zm_transit`, `zm_nuked`, `zm_buried`, `zm_tomb` | `zm_highrise` (native), `zm_prison` | Mob has no `specialty_quickrevive_zombies` asset |
| **Vulture Aid** | `zm_transit`, `zm_nuked`, `zm_highrise`, `zm_prison` | `zm_buried` (native), **`zm_tomb`** | ❌ **proven impossible on Origins** — see below |

### 🛑 Vulture Aid is OFF on Origins, and that is a measured limit not a preference

Vulture needs bits in two clientfield sets Origins has none of:

| field | bits | set | Origins usage |
|---|---|---|---|
| `vulture_perk_scriptmover` | 4 | scriptmover | **32/32** |
| `vulture_perk_actor` | 2 | actor | 31/32 |

The 32-bit ceiling is measured across all 48 per-map dumps in
`Black Ops 2 Grand Resources\…\Clientfields\` — no map exceeds 32 in either set, and the map that
reaches exactly 32 in scriptmover *is* Origins. It was also hit for real:
`zm_tomb: Trying to assign 1 bits for netfield zone_capture_zombie but Client Field Set ACTOR is
out of space`. v1.55.0 shipped it anyway with both fields dropped; Origins then lost the eye glow,
stink trail, stink pile and meter. Reverted under "perfectly or not at all".

## 3b. Perk system changes 📄

- **No perk limit** — all 12 perks holdable at once.
- **Perk pop-up HUD** ("Vanguard Perk Animation", techboy04gaming / NewMartinLag) — listens for the
  stock `perk_acquired` notify; icon + name + description on purchase.
- **Prone-at-a-perk-machine bonus** — +100 points. Origins has this natively, so the module is
  skipped there and Origins' own `zm_tomb_ee_side::check_for_change` is patched instead.
  ❌ Known gap: does not fire at **Mob's Electric Cherry** machine.
- **Perk bottles restored on survival maps**.

## 3c. `.removeperks` icon-duplication fix ✅ *(v1.62.2, confirmed in game)*

Stock's `CoD.Perks.RemovePerkIcon` has an off-by-one that only fires at **12/12 perks** — which
only this mod can reach. Detail of the stock bug is in `STOCK_REFERENCE.md` §4.

**Implementation:** `zmqol_perk_slot_watcher()` samples held perks every 0.05s per player and
maintains an acquisition-ordered list — append what appeared, ordered-delete what left, which are
exactly the two operations the game's LUI performs on its own icon row. `.removeperks` then clears
the **newest** perk first, emptying the last slot so every later removal is safe.

🛑 It deliberately **observes** rather than hooking `give_perk`: measured `tracked=0` proves that
`replaceFunc` is not taking (§9c). ❌ Not covered: going down while holding all 12 — that teardown
is stock's own, in stock's order.

## 3d. The perk-row off-by-one, fixed at the source 🚧 *(v1.62.6, deployed — NOT yet booted)*

§3c and v1.62.5 both fixed the *chat-command* path by controlling removal order. **They could not
reach a down**, and the user reproduced exactly that on 2026-08-09: twelve perks, killed by a
zombie, row collapsed to twelve identical icons. Who's Who's revive and Mob's afterlife re-hand the
whole loadout in **one frame with no waits**, so no script-visible order exists to correct.

**This fixes the LUI defect itself, so removal order stops mattering anywhere** — the down,
`.removeperks`, `.remove<perk>`, and the friend's Vulture Aid spam are one bug with one cause.

**Implementation — one function replaced, not one file.** `ui_mp/t6/zombie/hudpowerupszombie.lua`
(already a mod override) defines `CoD.PowerUps.ZmqolFixedRemovePerkIcon` and installs it over
`CoD.Perks.RemovePerkIcon` from the top of `LUI.createMenu.PowerUpsArea`.

Why that works, each part verified rather than assumed:

| | |
|---|---|
| the field is looked up at call time | `RemovePerkIcon` is its own constant inside stock `Update`'s constant list ⇒ runtime `GETTABLE`, and it is never captured by `registerEventHandler` |
| the hook is guaranteed to be late enough | stock `hud.lua` creates `PerksArea` then `PowerUpsArea` on **adjacent lines**, PerksArea first |
| the file really does load from `mod.iwd` | `Loaded menu file: ui_mp/t6/zombie/hudpowerupszombie.lua` in the boot log, while the file exists in no other search path |
| the body is stock's | diffed against `BO2-Reimagined`'s readable copy: **exactly two lines differ**, the added `else` and `NextPerkWidget = nil` |

🌟 **Why not ship `hudperkszombie.lua` as a whole-file override:** stock's `Update` has
`STATE_PAUSED` and `STATE_TBD` branches (proved by its bytecode constants) that no readable source
carries — Reimagined dropped them. Perk fields are 2 bits wide wherever `emp_grenade_zm` is
included (stock `zm_transit.gsc:1926`), so `STATE_PAUSED` is reachable and dropping it would stop
EMP-paused perks dimming. Replacing one function leaves every branch we cannot read untouched.

📝 **Zero regression surface for normal play:** with any free slot the loop breaks before it ever
reaches index 12, so the new `else` cannot execute. It only changes the 12/12 case.

🔎 Probe: console `zmqol_lui_perkfix` reads `1` once the patch has installed.

---

# 4. Wunderfizz — the mod's own machine 📄

`wunderfizz.gsc`, a **renamed copy** of Origins' `zm_perk_random` tree so `mod.ff` owns no Origins
asset (four anims ship as `zone_assets\xanim\qolwf_diesel_*`).

- Placed on every map from **hardcoded per-map coordinate candidates**, filtered at runtime by
  distance-from-spawn and clearance from real perk machines. Log: `placed N of M candidate
  location(s)`.
- Dispenses **all 12 perks** (11 where Vulture is off — the list gates on `level._custom_perks`,
  so it drops by itself).
- **On Origins the native machines are suppressed and replaced** by the mod's, so every map's
  Wunderfizz looks and behaves identically. `_zm_perk_random::init_machines` and
  `start_random_machine` are replaced with a no-op; 🛑 `_zm_perk_random::init()` is deliberately
  left alone so its six `registerclientfield` calls still run.
- 🛑 **Makes zero `setclientfield` calls** — fx are spawned server-side with `playfx`/`playfxontag`
  on purpose, because five registrations from a root script across six maps is the fastest route to
  `EXE_CLIENT_FIELD_MISMATCH`.
- ❌ **No Vulture Aid marker** — the client cannot know which runtime-chosen candidate won. See §5c.

---

# 5. Vulture Aid implementation

## 5a. Icon textures rebuilt ✅ *(v1.62.3)*

All 11 `fxt_zmb_*` icon textures shipped as IWI format `0x02` (RGB24, **no alpha**), so each fx drew
its whole 128×128 quad as a flat colour — the reported "coloured blur". Cause: the `.dds` files in
`All .DDS Files for Zombies\` declare `DDPF_RGB` with `Amask = 0x00000000` while the 4th byte of
every pixel really varies 0–255. Rebuilt from the intact `.png` dump via `png2dds.ps1` →
`ImageConverter --t6` → format `0x01` (ARGB32). `build_ff.bat` mandatory: header and pixels must
come from one file.

## 5b. Perk-machine markers rewritten ✅ *(v1.62.4, deployed — not yet verified)*

Two measured defects in stock, detailed in `STOCK_REFERENCE.md` §5: the machine list is keyed by
perk name (so duplicates overwrite) and `script_string` is ignored.

**Implementation:** `zmqol_vulture_after_connect()` empties stock's list right after its
`vulture_vision_init()` fills it, and the mod draws every machine itself through stock's published
`custom_funcs_enable` / `_disable` extension point. The filter mirrors the server's own
`perk_machine_spawn_init` verbatim — `<gametype>_perks_<location>` tokenised on spaces, structs
without `script_string` kept.

🛑 Emptied rather than corrected because stock's key does three jobs at once (fx lookup,
`hasperk()` gate, `fx_list_special` slot); re-keying it uniquely breaks the gate.

Stock registers glow fx for only 8 perks, so **Tombstone, Deadshot, Who's Who, Electric Cherry and
PhD** fell through to stock's fallback — the *Speed Cola* glow. They now get the neutral "?"
(`fx_zm_vulture_glow_question`). Buying a perk removes its markers via a wrapper around stock's
global perk callback. Wallbuys, mystery box, powerups, zombie eyes and the stink are untouched.

🛑 **New fx cannot be authored** — OpenAssetTools dumps no `.efx`, so there is no round trip. There
is no Tombstone or Wunderfizz glow anywhere in BO2.

## 5c. ❌ Not done — the Wunderfizz marker

Positions are chosen server-side at runtime, so the client cannot know them. Both routes carry
unmeasured risk: a new clientfield (Origins' scriptmover set is 32/32) or client-side replication of
the placement filter (drift puts a marker where no machine is).

---

# 6. Survival locations and gamemodes

- **Diner survival on TranZit** — `locs/zm_transit_loc_diner.gsc` + `locs/loc_common.gsc`.
  ✅ **Exactly one location ships.** Ported from `BO2-Reimagined`, adapted not bulk-copied.
- Gated on `!is_classic()` — **the base maps are never altered**.
- `replaced/zm_transit_gamemodes.gsc` replaces `zm_transit_gamemodes::init`.
- 🛑 A never-enabled zone leaves respawn points locked, dumping the player at the map default spawn
  and killing them — the failure mode that cost a round on Tunnel.

---

# 7. Weapons, power-ups, HUD

| area | change |
|---|---|
| **Death Machine** | power-up + weapon, own sound bank, `sv_deathmachine_duration` / `_powerup`. ✅ announcer callout added v1.65.0 — see §7a |
| **Zombie Blood** 🚧 | Origins' power-up on four more maps, full port. v1.65.0. 🛑 **Not on Mob** — its `toplayer` set is out of space, measured from a boot failure. See §7a |
| **BO4 Max Ammo** | replaces `_zm_powerups::full_ammo_powerup` |
| **Wall buys refill the magazine** | replaces `_zm_weapons::ammo_give` |
| **Instant Pack-a-Punch** | no wait |
| **Animated camos** | combined override of `get_pack_a_punch_weapon_options` merging two former modules' intent; `anim_pap_camo_*` dvars |
| **Fire Sale** | enabled on the two maps that never had it |
| **High-round fix** | |
| **Hitmarkers + counters** | `redhitmarkers` |
| **Custom summary HUD** | by Astroolean |
| **Cold War round HUD** | |
| **Area notifier** | zone name on entry |
| **Bleedout bar** | imported from Nathan3197 / Stick Gaming |
| **Secret song** | on survival |
| **Health HUD** | allocated on demand |

## 7a. Zombie Blood + the three announcer lines 🚧 *(v1.65.0, deployed — NOT yet booted)*

**Zombie Blood**, ported from `_zm_powerup_zombie_blood.gsc`/`.csc` into `quality_of_life.gsc`
and `zm_expanded.csc`, gated off `zm_tomb` (Origins keeps running Treyarch's copy) and off
`zm_prison` (no room — see the budget note below).

### 🌟 The `*_lerp` trap — 8 bits that appear out of nowhere *(v1.65.2)*

Mob failed to boot on v1.65.1 with `Trying to assign 3 bits for netfield visionset_slot but
Client Field Set toplayer is out of space`. **`visionset_slot` is not the culprit** — it is
registered last, by `finalize_type_clientfields()`, so it is merely whoever asked when the space
had gone (§9b, ERROR_CATALOGUE §2).

The real cost is invisible in any per-map clientfield dump: **stock Mob has no `visionset_lerp`
and no `overlay_lerp` field at all**, because every one of its own visionsets and overlays has
`lerp_step_count 1` and `finalize_type_clientfields()` only registers the lerp field when the
max needs more than 1 bit. PhD's 5-step visionset creates `visionset_lerp` at 3 bits and
Vulture's 31-step stink overlay creates `overlay_lerp` at 5 — **8 bits from two features that
each looked like they cost 1**.

🛑 **Before adding a visionset or overlay to a map, check the map's existing max
`lerp_step_count`, not just the bit count of the field you meant to add.**

Zombie Blood's own share on Mob was only 3 (`powerup_zombie_blood` 2, plus widening
`visionset_lerp` 3→4 for its 15 steps). ⚠️ Removing it returns Mob to its **v1.64.0 state, which
has never been booted** — Mob appears in exactly one of the eleven kept console logs, the failed
boot itself. If it still fails, the next lever is Vulture, which already ships incomplete there
(`zmqol_vulture_has_disease_meter()` returns 0 for `zm_prison`) and would free 7 more bits.

| part | where |
|---|---|
| `player_zombie_blood_fx` (allplayers, 1) | server `main()`, client `perks_register_clientfield()` |
| `powerup_zombie_blood` (toplayer, 2) | both sides via `add_zombie_powerup` |
| visionset + overlay, prio 15/16, lerp 15 | server `init()`, client `perks_register_clientfield()` |
| 6 assets, all `zm_tomb.ff`-only | `zone_source\mod_locations.zone` |
| 4 sounds + Origins' duck | `soundbank\mod.all.aliases.additions.csv` + `soundbank\ducks\` |

🌟 **The client half is entirely in `perks_register_clientfield()` for FOUR independent
reasons**, any one of which fails silently on its own: `level.vsmgr_filter_custom_enable` is
wiped by `_visionset_mgr.csc::init()` after client `main()`; `level.vsmgr` does not exist
during `main()`; the connect callback must precede `level._customplayerconnectfuncs`
(`_zm.csc:96`); and `add_zombie_powerup` must precede `set_clientfield_code_callbacks()`.

🛑 **The 12 character reaction lines are deliberately NOT ported.** `create_and_play_dialog`
picks by the player's character index, so shipping Origins' would put the Origins cast's
voices in Misty's and Russman's mouths on every other map. Unregistered = silent, which is
stock's own path for an unregistered dialog type.

**The three announcer lines.** All reached through the generic
`_zm_powerups.gsc:1147 leaderdialog( self.powerup_name )`, so the aliases must be `vox_zmba_*`:

| `createvox` key | alias | payload source | gate |
|---|---|---|---|
| `zombie_blood` | `vox_zmba_qol_powerup_zombie_blood` | `zmb_tomb.english` | off `zm_tomb` |
| `bonus_points_player` | `vox_zmba_qol_powerup_blood_money` | `zmb_tomb.english` | none |
| `deathmachine` | `vox_zmba_qol_powerup_death_machine` | `zmb_highrise.english` | none |

Each ships **twice**, with and without the `_0` suffix, because whether `soundexists()` can see
a mod-bank alias is not answerable offline and the two branches of `getleaderdialogvariant()`
land on different names. Only one is ever played.

🛑 **Corrects v1.64.0's claim** that Blood Money's silence was parity — that was measured on
`powerup_vo( "bonus_points_solo" )`, but Origins reaches its line through the dig script's own
`leaderdialog( "blood_money" )` instead. The line exists.

📝 `playsound( "death_machine" )` in `deathmachine_powerup()` resolves to **no alias in any of
the nine banks dumped** (`zmb_tomb`, `zmb_highrise`, `zmb_common`, `zmb_patch`, `mod.all`,
`deathmachine_zm.all`, …), so the Death Machine drop has always been silent. This is the first
sound it makes.

---

# 8. Menu / startup

- **Instant start** — replaces `_zm::onallplayersready` and `_zm::fade_out_intro_screen_zm`; skips
  the dead time between Start and the game. `zmqol_intro_hold_time` controls the black hold.
- **Map list** — `ui_mp/t6/zombie/selectmaplistzombie.lua` (whole-file replacement) adds the
  survival location.
- **Solo gameplay flag** ✅ *(v1.62.0, deployed — never booted)* — `qol_check_solo_status` replaces
  `check_solo_status` on Mob and Origins. Stock tested `getnumexpectedplayers() == 1`; the engine
  reports **0** on Mods-menu launches, so `level.is_forever_solo_game` was never set and Mob's plane
  parts would not all be carried. Now `<= 1`.
- **Solo lobby header** ✅ *(v1.65.6, confirmed in game 2026-08-11)* — the Solo Play and Custom Games
  lobbies are the SAME menu (`PrivateOnlineGameLobby`), and stock titles it `MPUI_CUSTOM_GAMES_CAPS`
  unconditionally, so Solo Play read "CUSTOM GAMES". The mod now ships that menu file with one
  branch added: `ZMUI_SOLO_PLAY_CAPS` when `CoD.isZombie` and `party_solo == 1`.
  - It has to be a **separate file**, not a patch inside `privategamelobby_project.lua`:
    `privategamelobby.lua` requires `T6.Menus.PrivateGameLobby_Project`, and
    `privateonlinegamelobby.lua` requires `T6.Menus.PrivateGameLobby` — so the project file runs
    **first** and any `LUI.createMenu.PrivateOnlineGameLobby` set there is overwritten afterwards.
    The title is applied after `New()` returns, so no `_Project` hook runs late enough either.
  - The body is a faithful reconstruction of stock, checked against the constant table of the
    shipped bytecode (`BO2-Raw-files\ui\t6\menus\privateonlinegamelobby.lua`) — every constant
    accounted for, in order, nothing left over.
  - `party_solo` is set by this mod's own `OpenSoloLobby_Zombie` (1) / `OpenCustomGamesLobby` (0)
    immediately before `openMenu`, so Custom Games keeps its title and MP is untouched.
  - `ZMUI_SOLO_PLAY_CAPS` is a **stock** key — Plutonium's own `ui/t6/mainlobby.lua:446` uses it for
    the SOLO PLAY button.
  - 🛑 `pack_iwd.ps1` did not pack `ui/` and `build.bat`'s raw-shadow sync only walked `ui_mp/`;
    both were extended, or the file would never have reached the game.
- **Solo intro cutscenes** ✅ *(v1.65.8, confirmed in game 2026-08-11)* — `ui_mp/t6/hud/loading.lua:229`
  plays `video/<map>_load.webm` only when **not theater** AND `party_maxplayers == 1` AND the map is
  `zm_highrise` / `zm_prison` / `zm_buried` / `zm_tomb` AND gametype is `zclassic`. Three of the four
  already held in solo; **`party_maxplayers` was the one that failed**, measured at `"4"` in the dvar
  dump of every solo boot (`console_zm.log.000/.001`: `zm_prison`, `zclassic`, `party_solo "1"`,
  `party_maxplayers "4"`, `ui_zm_useloadingmovie "0"`).
  - Cause: `OpenSoloLobby_Zombie` sets it to 1 and then calls `InitMapDvars`, which ends in
    `Engine.SetGametype()` — that puts it back to the gametype cap. The in-lobby game-mode picker
    calls `SetGametype` too (`selectmaplistzombie.lua:180`), so a lobby-time set alone is not enough.
  - Fix: re-assert after `InitMapDvars`, **and** in `ButtonStartGame` immediately before `xpartygo` —
    the last point before launch. Gated on `party_solo`, so Custom Games keeps its own cap.
  - No gameplay side-effect: `party_maxplayers` appears **nowhere** in the 2,093-file stock GSC dump.
    The only other LUI reader is `scoreboard.lua:277`, where `== 1` leaves `CoD.Zombie.SoloQuestMode`
    true — correct for solo.
  - 📝 **Only four maps have an intro** — `video/` holds `zm_highrise_load.webm`,
    `zm_prison_load.webm`, `zm_buried_load.webm`, `zm_tomb_load.webm` and nothing else. TranZit and
    Nuketown never shipped one, which is why stock's gate lists exactly those four.
  - `material webm_720p` (the render target) ships in `code_post_gfx.ff` and `patch_zm.ff`, so it is
    loaded on every map.

---

# 9. Engine constraints this mod lives inside

*(These are properties of T6/Plutonium. The full explanations belong in `STOCK_REFERENCE.md`.)*

## 9a. Script load scope
`scripts/zm/NAME.gsc` loads on **every** map; `scripts/zm/<map>/<map>.gsc` only on that map. A
map-specific `::` reference resolves at **load time**, so one sitting in a root script crashes every
*other* map — and a runtime `if (level.script == …)` guard does **not** prevent it. This is why
`disable_fog_transition.gsc` lives under `zm_transit/`.

## 9b. Clientfields
Every set is 32 bits. Server and client registration lists must match exactly in count, order and
width, or every player is dropped with `EXE_CLIENT_FIELD_MISMATCH`. Hence the "exact twin" map-list
functions in §3a.

## 9c. `replaceFunc` is not reliable ✅ *measured 2026-08-08*
`replaceFunc( _zm_perks::give_perk, ::give_perk )` in `main()` **is not taking**, even for
`.giveperks`' fully qualified call — probe measured `tracked=0`. It presumably never has; nothing
noticed because that override is byte-equivalent to stock's. **Do not assume a hook fires — prove
it.** Most of the mod's other hooks are relied upon and appear to work, but only the ones with
observable behaviour are confirmed.

## 9d. No new fx or LUI source
OAT dumps no `.efx` (no fx authoring). `ui_mp/` overrides are **whole-file replacements** and a bad
LUI file hard-crashes the game, so any LUI change ships alone. T6 LUI is a modified Lua 5.1 that
unluac cannot read; `BO2-Reimagined` ships 35 readable LUI files, but they are stock **plus** their
own changes.

🌟 **The way around the whole-file problem: patch one function from a file you already override.**
LUI globals are plain tables and most handlers are looked up at call time, so
`CoD.<Thing>.<Func> = <ours>` from any file that runs later replaces just that function and leaves
the rest of the stock file — including branches no decompiler can read — completely untouched.
§3d does this to fix the perk row. Two things must be checked first: that the target is **not**
captured by `registerEventHandler` (a captured handler keeps the old reference), and that the
patching file's entry point provably runs **after** the target file has loaded.

🔧 **Lua syntax can be validated offline**, which removes most of the hard-crash risk:
`npm install luaparse`, then `luaparse.parse(src, { luaVersion: '5.1' })`. It parses all four of
this project's LUI files. Node is installed; there is no Lua interpreter on this machine.

---

# 10. Known-broken and not-yet-done ❌

| item | state |
|---|---|
| `night_mode` | screen goes fully black |
| `character` command | no visible effect |
| God mode after Mob's afterlife | `.god` reads ON but the player can die |
| Mob Wunderfizz placement | overlaps the shield part spawn |
| Custom texture packs conflict | `mod.ff` declares 776 header-only images and loads before the map, so a player's own `.iwi` is read through our header |
| Vulture marker on Wunderfizz | §5c |
| Solo intro cutscene / "CUSTOM GAMES" header | §8 |
| Prone bonus at Mob's Electric Cherry | no points |
| PhD LUI off-by-one | **fix deployed v1.62.6, NOT yet confirmed in game** — §3d |
| Stray 254 MB `cmn_root.all.sabl` in `build\zm_qol\` | not one of the 6 files — do not ship it |

`.agents/QUEUE.md` is the authority on ordering and what is in flight.

---

# 11. Long-form notes moved out of `README.md` *(v1.96.0, 2026-08-16)*

User, 2026-08-16: *"fix the GitHub page because right now it's very cluttered and not very user
friendly ... make the readme as simple as possible so anyone can check out all the features of my
mod without having to read a bunch of uneeded stuff ... keep them to your other .md files for the
mods' source so that way you can still access the information and knowledge required in the
future."*

Nothing below was deleted from the project — it was moved here. The README is now a player-facing
page: what the mod is, how to install it, what it does, what is broken.

## 11a. Textures — the disclaimer that was cut

The mod **no longer ships an upscaled texture pack**. Removed in v1.57.7: loose `.iwi` in
`mod.iwd` did not reliably override the stock art, and it cost 2 GB for no visible result. A
player's own pack goes in `%LOCALAPPDATA%\Plutonium\storage\t6\images\`, which does work.

v1.93.0 removed two perk icons the mod still shipped — `specialty_vulture_zombies.iwi` and
`specialty_tombstone_zombies.iwi` — because `mod.iwd\images\` beats `storage\t6\images\` and they
were overriding custom packs. 🛑 **Consequence:** with no pack installed, the Vulture Aid icon
falls back to the game's own copy, which only Buried owns, so it may not draw elsewhere. Tombstone
is safe either way (its pixels are in the base pak).
`specialty_vulture_zombies_glow.iwi` is deliberately still shipped — no known pack replaces it.

## 11b. Weapon detail

- **XPR-50** is stored under its development name `as50` — the defs are `as50_*`, the art is
  `xpr50_*`. It was twice reported absent because of this.
- **Titus-6** is dual-mode: explosive-dart launcher with a buckshot masterkey on alt-fire, both
  dart projectiles included. Its Pack-a-Punch camo is compiled from source (the game ships no
  `camo_titus6`); all three of its effects are baked into `mod.ff` from the campaign fastfile that
  owns them. Its PaP camo was missing on Mob, Buried and Origins until v1.95.2 — those three use
  camo index **40** where every other map uses 39, and `camo_titus6` had real materials at slot 3
  (index 39) but an empty filler at slot 8 (index 40). It now carries slots 3, 8, 11 and 12.
- **Tac-45** (v1.99.13, weapon 12) is stored under its development name `fnp45` — the same trap the
  XPR-50 sprang. **Three defs ship**, because it becomes dual-wield when Pack-a-Punched:
  `fnp45_zm`, `fnp45_upgraded_zm` and `fnp45lh_upgraded_zm`, the last two naming each other through
  `DualWieldWeapon`. Only the base may be a box result; the left-hand half is a variant, the shape
  stock uses for Mustang & Sally. No `pap_attach` row and no `attachmentunique`: all three defs
  carry an empty `attachments` field, identical to mk48 / insas / crossbow / titus6. Cost 500 and
  an empty vox pack are BO2-Reimagined's own values for this gun — the pistol class maps to
  `wpck_crappy`, which is in no zombies sound bank, so naming it would be silence. Its 54 sound
  aliases and 15 payloads ship in `mod.all`; the fire payload was confirmed present in the built
  bank rather than assumed. 🟡 The knife-bash whoosh is silent, because `wpn_tac_knife_whoosh_*`
  exists in no zombies bank — stock's own Executioner (`judge_zm`) has the identical gap.
- **Reload sounds** work on all twelve as of v1.93.0. SWAT-556 and Peacekeeper shipped with no
  foley aliases at all (six each); the other nine matched their source one for one, and the Tac-45
  brought its five (`fly_fnp45_hammer` / `_mag_in` / `_mag_out` / `_slide_back` / `_slide_forward`).
- **`zmqol_mp_weapons 0`** turns all twelve off; **`zmqol_ww 0`** turns the three wonder weapons off.

## 11c. Wonder-weapon detail

- **Brutus** was effectively immune before v1.94.1: all three guns damaged him through `DoDamage`,
  which carries no hit location, so his own damage override scaled every hit to 10% and could never
  pop the helmet. The fix went into `zombie_knockdown()` (v1.93.0 — Brutus never reaches it), then
  `thundergun_knockdown_zombie()` (v1.94.0 — only covers 480–1200 units), then
  `thundergun_fling_zombie()` as well (v1.94.1 — the branch every target inside 480 units takes,
  i.e. the range he is actually fought at). Thundergun confirmed in game v1.94.1.
- **The Wunderwaffe needed a second, unrelated fix in v1.95.2**: a *direct* hit on Brutus did
  nothing, and only the arc chaining off a nearby zombie hurt him. `tesla_damage_init()`
  early-returns on any target still carrying `zombie_tesla_hit`, and the loop meant to clear that
  flag was gated on `tesla_damage_func` — a field **nothing in the game, this mod, or either donor
  mod ever assigns**, so it never ran and Brutus stayed flagged forever after his first arc.
- **Winter's Howl fx, the open bug.** v1.91.0 claimed to fix it with 19 materials and 12 textures
  in `mod.ff`; the user booted it and the effects were still missing, and a re-measurement
  **disproved that explanation** — all six materials `fx_freezegun_view.efx` names are reachable at
  runtime (four in `mod.ff`, two in `common_zm`/`patch_zm`) and the `.efx` itself is inside the
  shipped `mod.iwd`. The remaining untested assumption is whether T6 loads a raw `.efx` out of
  `mod.iwd\fx\` at all. The 19 materials were left in place — harmless and genuinely absent, but
  not the cause.
- **The DG-2 "never appears from the box" report was measured and is not a bug**: all three
  register identically, and with stock's box filters removed a specific gun is a flat share of the
  in-box list.
  🛑 **v1.98.0 reversed the weighting.** `zmqol_box_wonder_weight` (default 2) used to make the
  three wonder weapons *more* common from round 10; the user asked for the opposite. It is replaced
  by **`zmqol_box_ww_rarity`** — `4` (default) = a quarter as likely as an ordinary gun, `1` = the
  same as any other gun, `0` = never from the box. Only those three names are touched, so every
  other weapon keeps exactly the share it had.
  📝 **Stock BO2 has no box weighting at all** — measured, not assumed. The chooser is a flat
  `array_randomize` (`_zm_magicbox.gsc:911`); the only weighting hook is set by one map and points
  at a no-op stub (`zm_buried.gsc:452`); `add_limited_weapon( "raygun_mark2_zm", 4 )` is a
  per-player quota that never binds; and `special_weapon_magicbox_check` is mutual exclusion with
  the Ray Gun, not rarity. **The Ray Gun Mark 2 is exactly as likely as any other box weapon.**

## 7c. The box is diluted, and nothing is replaced ✅ *audited v1.98.0*

Reported via a friend: *"he couldn't get a python or executioner, he thinks it's replaced by the
Buried-exclusive Remington New Model Army."*

**Nothing is replaced.** Every `add_zombie_weapon` name the mod registers was diffed against that
map's own stock registrations (comment lines excluded). Across all six maps there is exactly **one**
name that the mod re-registers over a stock entry:

| map | name | effect |
|---|---|---|
| Buried | `qcw05_zm` | stock registers it with `upgrade_name` **undefined**; the mod supplies `qcw05_upgraded_zm`. A fix, not a loss. |

The three wonder weapons collide with nothing on any map. **`python_zm` and `judge_zm` are
registered and in the box on all six maps** — verified by unioning each map's stock list with the
mod's additions.

**The real cause is dilution.** The box holds roughly 75 in-box names per map now, so a named gun is
~1.3% per spin and missing one across a 40-spin game is ~59% likely. That is arithmetic, not a bug —
but it is the honest answer to "why can't I get the Python".
- The Wunderwaffe's **view-model lights are still too bright**.

## 11d. Round jumping

`.round 30` drives stock's normal round-end path. Stock's own `zombie_devgui_goto_round()` cannot
be used — its whole body, *and* every `endon( "kill_round" )` it relies on, sit inside `/# #/`
developer blocks, so neither exists in a retail game.

## 11e. The options menu, and why it is three tabs

`CoD.ButtonList` neither clips nor scrolls, and stock's largest tab is 14.5 row-pitches. The
v1.94.0 single tab was 23.5 pitches and drew straight over the tab strip and the ESC prompt. The
split into GAME / HUD (v1.95.0–v1.95.1, confirmed in game 2026-08-14) and then GAME / HUD / CHEATS
(v1.96.0) keeps every tab under the stock budget. See the header comments in
`ui/t6/menus/optionssettings.lua` for the pixel measurements behind the tab-strip width.

📝 Two requested entries are **deliberately absent**: **"reduce engine sleeps"**, because no dvar of
that name exists in this build and inventing one would be a guess, and **perma-perks**, because this
mod has no perma-perk system to toggle.

📝 There was never a GAME tab for the mod to hide: the `optionssettings.lua` this project is built
on registers exactly four tabs unconditionally. This **adds** tabs.

📝 **v1.99.54 — three rows left the GAME tab for the stock ADVANCED tab**, at the user's request:
NIGHT MODE (`night_mode`), FOG (`r_fog`) and MODEL DETAIL FIX, renamed **HIGHER DRAW DISTANCE**
(`lod_fix`, dvar deliberately unchanged). The mod's own DEPTH OF FIELD row was **deleted** rather
than moved — stock's ADVANCED row now carries a fourth step, **DISABLED**, so there is one DOF
control instead of two. That row is bound to the mod's `dof_quality` dvar (0 DISABLED / 1 LOW /
2 MEDIUM / 3 HIGH) rather than to `r_dofHDR`, because a fourth `r_dofHDR` value might be clamped by
the hardware-profile writer and nothing in the workspace settles whether it is; the row's callback
drives `r_dof_enable` and `r_dofHDR` itself. GAME is now 10.0 pitches and ADVANCED 15.0 — the
number the SOUND tab was measured good at in v1.99.33.

🛑 **FOG only applies from the in-game pause menu, and that is pre-existing.** `r_fog` is cheat
protected: this install's logs carry "Cannot set cheat dvar r_fog" 22 times, every one in a rotation
where no map was ever loaded. The mod's GSC sets `sv_cheats 1` once a map runs, which is what lets
the same row through in the pause menu, and `.fog` works a different way entirely — the server
pushes it with `setclientdvar`, which no cheat check applies to.

## 11f. Diner's Survival build-out

Diner is the only added location — `scripts\zm\locs\` holds exactly one location script. Treyarch
left the map data in the game but never shipped it as a Survival start. What had to be added:

- **Pack-a-Punch** on the roof, reachable by the restored hatch climb.
- **Its wall buys turned back on** — the MP5K inside and the Galvaknuckles on the roof are tagged
  `zclassic_transit` in the stock map, so Survival spawned neither.
- **A Semtex wall buy** by the exit door. The map ships exactly one Semtex struct and it lives in
  Town, so this one is *created*, on both the server and the client — a wall buy is a clientfield,
  and a one-sided one drops every player at load.
- **The buildable riot shield.** The parts and spawns were always in the map; TranZit only registers
  buildables in Classic. Its part models, HUD icons and craft sounds ship in `mod.ff` — all of them
  live in the *Classic-only* fastfile that Survival never loads.
- **The three teddy bears and the secret song**, matching Bus Depot, Farm and Town.

## 11g. Blood Money and Zombie Blood, in full

- **Blood Money** (`bonus_points_player`, 1–2500 points to whoever grabs it) is registered in core
  BO2 on all six maps but switched on only by Origins, which hands it out from a dig site alone. It
  is now in the ordinary drop rotation on every map — Origins' dig sites keep working unchanged.
  Costs no clientfield bits; the icon model ships in `mod.ff` for the four maps that lack it.
- **Zombie Blood** on TranZit, Nuketown, Die Rise and Buried: 30 seconds during which every zombie
  ignores you, with the red screen filter, the visionset, the first- and third-person effects, the
  player-model swap and the looping audio — ported asset for asset from `zm_tomb.ff`. Origins keeps
  its own copy. **Not on Mob of the Dead**: that map's `toplayer` clientfield set is out of space,
  measured from a real boot failure.
- **Three announcer lines.** Zombie Blood's and Blood Money's exist only in Origins' sound bank, so
  both drops were silent everywhere else; the Death Machine's (`zmb_vox_ann_death_machine`, Die
  Rise's bank) was recorded by Treyarch and **never wired up anywhere in the game** — zero
  references across all 2,093 stock scripts.
