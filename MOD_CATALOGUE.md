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

The mod is exactly **6 top-level files**. Only `mod.iwd`'s raw source folders are hand-edited.

| file | what it is | hand-edited? |
|---|---|---|
| `mod.iwd` | zip of `scripts/ ui_mp/ images/ maps/ weapons/ attachmentunique/`; Plutonium runs raw `.gsc` straight out of it | **yes**, via `pack_iwd.ps1` |
| `mod.ff` | fastfile: assets + the client `.csc` scripts | rebuilt by `build_ff.bat` |
| `mod.json` | name / author / description / version | yes |
| `mod.all.sabl`, `mod.all.sabs` | sound banks | no |
| `deathmachine_zm.all.sabl` | Death Machine fire/spool sounds, referenced independently by the zone. Missing ⇒ the weapon fires silently | no |

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
| `ui_mp/**/*.lua` × 3 | 873 / 591 / 362 | client | whole-file LUI replacements |

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
| `.powerups` | | list every power-up registered on this map |
| `.powerup <name>` / `.drop <name>` | | spawn one. Every power-up is also its own command; short forms `.dm .nuke .maxammo .insta .dp .carp .sale` |

## 2b. Console dvars 📄

`fly` · `night_mode` · `rapid_fire` · `character` ⚠️ *(reported to do nothing)* · `coop_pause` ·
`no_power` · `lod_fix` · `hud_all` · `hud_timer` · `hud_health_bar` · `hud_remaining` ·
`hud_zone` · `hud_round_timer` · `hud_color "1 1 1"` · `hud_color_health` ·
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
| **Death Machine** | power-up + weapon, own sound bank, `sv_deathmachine_duration` / `_powerup`. ❌ no BO1 announcer callout yet |
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
- ❌ **Solo still presents as a custom game** — no intro cutscene, header reads "CUSTOM GAMES". Both
  live in the menu LUI, before the map loads; no GSC hook reaches them.

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
| PhD LUI off-by-one | dormant; real fix is one `else` in `hudperkszombie.lua` |
| Stray 254 MB `cmn_root.all.sabl` in `build\zm_qol\` | not one of the 6 files — do not ship it |

`.agents/QUEUE.md` is the authority on ordering and what is in flight.
