# QUEUE.md — one change at a time

**Rule (user, 2026-08-06):** nothing new starts until the item in flight is **confirmed working
in-game by the user**, with no bugs and no compromises. New requests get appended here and
acknowledged, not begun.

**"Deployed" is not "done".** Only a boot moves an item out of §1.

---

## 🛑 STANDING RULE, user 2026-08-09 — A PORTED PERK IS NEVER MODIFIED

> *"don't change how electric cherry behaves because you're not meant to change the perk just leave
> it alone and then port it over to the maps that don't have it already. simple, same logic for
> literally any other perk (eg. who's who). No missing/wrong fx period."*

The job is **porting, not tuning.** The perk already exists and works on the maps that ship it; the
only correct outcome is that the ported copy is indistinguishable from that one. This applies to
Who's Who, Zombie Blood, Blood Money, the wall-buys and everything after them.

- **Fixing a defect in stock's own logic is still a modification.** v1.62.9 deleted stock's
  consecutive-reload throttle and its 0.1s per-zombie stagger. Both were genuine defects by any
  reading. Both were wrong to ship, because they changed the thing being ported.
- **Additive gap-filling is allowed and is the actual work**: registering the perk on a map that
  never had it, shipping the assets its fx/audio need, adding it to the Wunderfizz table. Anything
  that makes the port *reach parity* is in scope. Anything that moves it *past* parity is not.
- **The reference is the map that ships the perk**, not the mod's own idea of correct. Leave those
  maps running zero mod code so they stay a clean A/B baseline.

---

## ✅ SOLO PLAY — TITLE + INTRO CUTSCENES, BOTH CONFIRMED IN GAME 2026-08-11

- **v1.65.6** — the lobby header reads **SOLO PLAY**, not CUSTOM GAMES. User: *"it says solo play
  now, works."* Ships `privateonlinegamelobby.lua` (identical copies under `ui/` and `ui_mp/`).
- **v1.65.8** — the **intro cutscenes play** on Die Rise / Mob / Buried / Origins. User: *"ok it
  works"*. `zmQolForceSoloPartySize()` calls `Engine.PartySetMaxPlayerCount(1)` **and** the dvar,
  from lobby creation and from a wrap around `Button_StartMatch`.

### 🌟 Three findings from this that are worth keeping

1. **`CoD.PrivateGameLobby.ButtonStartGame` IS DEAD CODE.** The string occurs in **no** stock LUI
   file and nowhere in Plutonium's `raw\`. The real handler is `Button_StartMatch`, wired by stock
   `privategamelobby.lua` as `registerEventHandler("button_action", …)`. **So this mod's
   "instant start" override has never run.** Left in place and commented; removing or re-pointing
   it is a separate change — see §NEXT below.
2. **Load order decides where a LUI hook can live.** `privategamelobby.lua` requires
   `…_Project`, so the project file runs FIRST and anything it defines that
   `privategamelobby.lua` also defines is overwritten. `privateonlinegamelobby.lua` requires
   `privategamelobby.lua`, so it runs AFTER — it is the only place a `Button_StartMatch` wrap
   survives.
3. **`Dvar.party_maxplayers` is a mirror, not the authority.** Stock calls
   `Engine.PartySetMaxPlayerCount( GameTypeGroups[gt].maxPlayers )` right after `SetGametype`;
   setting the dvar alone loses. Both are set now.

📝 `zmqol_loadmovie_probe` (LUI dvar + the GSC println) is **scaffolding and should be deleted** now
that the cutscene is confirmed.

---


## 🧸 SHIPPED v1.67.0 — THE THREE TEDDY BEARS ON DINER. DEPLOYED, NOT YET BOOTED.

> *"time to add the 3 teddy bears around the map in Diner survival same as the ones that were
> added to bus depot, farm and town, the sound effect that eminates from them when you're close,
> the sound effect when you interact with them and all, to activate the easter egg song after
> interacting with all 3. This way all the standalone survival maps will have the 3 teddy bear
> interact easter egg song."*

**Built.** The Pack-a-Punch regression it was queued behind is ✅ CONFIRMED FIXED by the user on v1.66.3 ("pack machine is visible again"). Positions are dvar-tunable - see the code comment in `quality_of_life.gsc::setteddybears()`.

### The three placements, from the user's own `.where` lines + screenshots

🛑 These are **PLAYER** positions with the yaw they were facing, not bear origins. Each bear goes
where the red arrow pointed, a short distance ahead along that yaw, sitting on the surface named.

| # | where | player `.where` | facing | surface |
|---|---|---|---|---|
| 1 | diner interior, **on the table** | `-3679 -7392 -58` | yaw 264 | the flat table top ahead |
| 2 | **on the shelf** right by the riot-shield buildable bench | `-4830 -7918 -62` | yaw 270 | the middle shelf, between the two cans |
| 3 | **diner roof**, in the corner | `-5661 -7913 227` | yaw 323 | the roof floor, tucked into the parapet corner |

All three **sitting down**.

### What the port has to include — the completeness audit applies

| | |
|---|---|
| model | the real bear, the same one Bus Depot / Farm / Town use |
| proximity audio | the looping music-box that emanates when you get close |
| interact audio | the sound on use |
| trigger | the use prompt on each bear |
| progression | interacting with all 3 starts the easter-egg song |
| client half | any clientfield the bears' audio/fx needs, twinned in the .csc |

### Where to read the working implementation first

The mod ALREADY ships this for the other survival locations — find `secret song survival` in
`quality_of_life.gsc` (one of the 17 merged modules) and the equivalent in `BO2-Reimagined`. This is
a **placement** job on top of an existing system, not a new feature, IF that system is per-location
data-driven. Confirm which before designing.

📝 The user's framing: *"This way all the standalone survival maps will have the 3 teddy bear
interact easter egg song"* — so Diner is the last one missing it. Check what the other locations
register and mirror it exactly.

---
## 🔴 IN FLIGHT — TWO REQUESTS, user 2026-08-11

> *"the frametime lag from the mod is still weird, fix that. also add the buildable shield to diner,
> it already exists in the tranzit map, just remove the tarp on the buildable table in the building
> and add the 2 parts spawns just like the regular tranzit."*

### 1. FRAMETIME — no code shipped, because there is still no measurement

Checkpoint 32 §1 stands: it was reported fixed once, **the cause was never attributed**, and it is
back. Screenshot 2026-08-11 shows `91 FPS / 30 LOW / 144 AVG / FRAMETIME 12.8` on Diner — real dips.

🛑 **Do not ship a third guess.** `qol_perf_probe` exists for exactly this, is still in the build,
is default-off, and **reads the dvar live so it toggles mid-game with no map reload**. It sleeps
every always-on per-player loop the mod runs (health bar 10Hz, zombie counter 4Hz, shield HUD 20Hz,
perk slots 20Hz, hitmarkers per damage event) and changes nothing else.

- still framey with `qol_perf_probe 1` → the mod's per-frame **scripts** are not the cause; look at
  `mod.ff` (3,870 assets, 776 header-only images) and the 48MB sound bank.
- smooth with it on → it **is** the scripts, and those five loops are the whole suspect list.

Also ask for `developer_script 1` — it was `"0"` all session, so per `ERROR_CATALOGUE.md` §8 every
GSC runtime error is being swallowed, and an error firing every frame inside a loop is invisible.

### 2. DINER BUILDABLE SHIELD — feasible, but it is NOT "just remove the tarp"

**Everything below is measured from the shipped map, not assumed.**

#### What already exists in survival

| thing | state in Diner survival |
|---|---|
| the 3 **dolly** spawn structs `riotshield_zm_t6_wpn_zmb_shield_dolly` at `(-6118.7,-7869.1,0)`, `(-6467,-7727,0)`, `(-5768.9,-7872.6,1.4)` | ✅ **present** — no `script_gameobjectname`, so the filter never touches them |
| the 3 **door** spawn structs `riotshield_zm_t6_wpn_zmb_shield_door` at `(-4486,-7980,-8.5)`, `(-4995,-7824,-42)`, `(-4404.5,-7740.5,-1.4)` | ✅ **present**, same reason |
| core `maps\mp\zombies\_zm_buildables::init()` | ✅ runs — called from core `_zm.gsc:153`, every map, every mode |
| the tarp over the bench | spawned by **this mod**, `zm_transit_loc_diner.gsc:481 generatebuildabletarps()`, at `(-4688,-7974,-64)` |

#### 🛑 What does NOT exist, and why

1. **The trigger and the bench shield model are DELETED in survival.**
   `riotshield_zm_buildable_trigger` (`trigger_use`, `(-4688,-7966,-6)`, `target buildable_riotshield`,
   `zombie_weapon_upgrade riotshield_zm`) and `buildable_riotshield`
   (`script_model t6_wpn_zmb_shield_world`, `(-4680.23,-7977.34,6.63)`) both carry
   **`script_gameobjectname "zclassic"`**, and `_zm_gametype.gsc:110 game_objects_allowed()` calls
   **`entity delete()`** on anything whose mode does not match. It is threaded from
   `_zm_gametype.gsc:429`.
   → Fix shape: re-tag `script_gameobjectname` **before** that thread runs (the same trick
   `loc_common::enable_wallbuys()` already uses for `script_noteworthy`), or spawn replacements.
   **The ordering against `:429` has NOT been established yet — that is the first thing to settle.**
2. **TranZit's buildable registration never runs in survival.**
   `zm_transit_buildables::include_buildables()` and `::init_buildables()` are called from
   **`zm_transit_classic.gsc:33-34` and nowhere else**. So there is no `riotshield_zm` buildable
   defined at all — no pieces, no `triggerthink`, no `onbuyweapon`.
   → Register **only** the riot shield, not the whole list. Calling stock's
   `include_buildables()` would drag in the jetgun, turbine, turret, electric trap, power switch
   and the buildable PaP, all of whose triggers are also `zclassic`-deleted.

#### ⚠️ THE RISK THAT DECIDES WHETHER THIS SHIPS — clientfields

`generate_zombie_buildable_piece(...)` takes a **piece index** (dolly = 2, door = 3) and stock sets
`level.buildable_piece_count = 27`. Buildable state is a clientfield, so adding buildables to a mode
that has none changes the set's width, and **a server-side change with no `.csc` twin is
`EXE_CLIENT_FIELD_MISMATCH` for everyone at load** — the failure this project has hit repeatedly.
**Read `_zm_buildables.gsc`'s registration and mirror it in `zm_expanded.csc` before writing
anything.** Diner survival measured 54/32-set `toplayer` in the v1.63.1 dump, so there is room; the
symmetry is the issue, not the budget.

#### Working precedent to read first

`BO2-Reimagined\scripts\zm\_zm_reimagined.gsc:2698-2703` builds a `level.buildables_available`
array containing `"riotshield_zm"` and calls `buildbuildable("riotshield_zm")`; `:3092` and `:3110`
walk `level.zombie_include_buildables`. Read that before designing.

#### Order of work when it starts

1. settle the ordering against `game_objects_allowed` (`_zm_gametype.gsc:429`)
2. mirror the buildable clientfields into `zm_expanded.csc`
3. register the riot shield buildable only, from the Diner location script (map-scoped, so a
   `maps\mp\zm_transit_buildables::` reference is safe there — **never** from a root script)
4. re-tag / re-spawn the trigger + bench model
5. **delete the tarp last** — a bare bench that does nothing is the half-implementation this
   project does not ship, so the tarp comes off only once the rest works

---

## 🚧 v1.65.0 — ZOMBIE BLOOD + THE THREE ANNOUNCER LINES. DEPLOYED, NOT YET BOOTED.

**User, 2026-08-11:** *"build zombie blood and the three announcer lines."*
The build spec below (§"THE BUILD SPEC") was executed. **This is the item in flight — nothing new
starts until the user boots it.**

### What shipped

| | |
|---|---|
| server | `zmqol_zombie_blood_enabled()` (gate, off `zm_tomb`), `zmqol_enable_zombie_blood()` from `perks()`/`main()`, `zmqol_register_zombie_blood_visionsets()` from `init()`, `zmqol_zb_powerup()` + 5 helpers, `zmqol_register_announcer_vox()` |
| server hook | one `zombie_blood` branch in `custom_powerup_grab()`, **gated** — without the gate it would hijack Origins' own power-up |
| client | `zmqol_enable_zombie_blood()` (include only) from `perks()`, `zmqol_zb_register()` + 7 helpers, all called from `perks_register_clientfield()` |
| `mod.ff` | 6 asset lines → **48 assets added, 0 removed, 0 re-owned** |
| sound | 10 alias rows + 7 payloads + **the first duck this project has ever shipped** |
| build | `build_ff.bat` gained a duck-staging step (`soundbank\<bank>.ducklist.csv` + `soundbank\ducks\*.duk`) |

### 🌟 Four findings that changed the design

1. **Clientfield registration ORDER does not have to match between the sides.** Proven by this
   mod's own Vulture: server registers its eight fields from `main()`, client from
   `_zm_perks::init()`, and it ships on five maps. Only the set of names/versions/sets/widths must
   agree. Visionsets are immune by construction — `_visionset_mgr` sorts names alphabetically
   before assigning `slot_index`.
2. **`level.vsmgr_filter_custom_enable` is WIPED after client `main()`** (`_visionset_mgr.csc:15`,
   reached from `_zm.csc:39`). Setting the red-overlay hook in `main()` would have been erased and
   the filter would silently never fade in. That is one of four independent reasons the whole
   client half lives in `perks_register_clientfield()`.
3. **The character reaction lines must NOT be ported.** `create_and_play_dialog` keys on the
   player's character index, so Origins' twelve would put the Origins cast's voices in Misty's and
   Russman's mouths everywhere. Unregistered is silent, and silent is stock's own path here.
4. **`playsound( "death_machine" )` in `deathmachine_powerup()` matches no alias in any of the
   nine banks dumped.** The Death Machine drop has always been silent; the new announcer line is
   the first sound it makes.

### 🛑 CORRECTION carried out — v1.64.0's Blood Money write-up was wrong

It said the silent announcer was deliberate parity. That was measured on `powerup_vo(
"bonus_points_solo" )`, which really does return without playing — but **Origins reaches its Blood
Money line by a different route entirely**, the dig script's own `leaderdialog( "blood_money" )`
(`zm_tomb_dig.gsc:773`). The line exists. Fixed in the code comment, `MOD_CATALOGUE.md` §7a and
here.

### Everything verified before hand-off, each claim traceable

- both scripts parse (`gsc-tool`, `-i client` for the `.csc`); no duplicate function names on either side
- `mod.ff` links **0 errors, the same 34 pre-existing warnings**; asset list **3818 → 3866,
  additions only, nothing removed**
- **ownership audit clean**: the only new assets that exist in more than one fastfile are
  `mc_sw4_3d_model_unlit_cheap_zombie_eyes_jq3e7eqw`, `gfx_fxt_smk_trail_wisp` and
  `mc/mtl_c_zom_zombie_head_n_therm` — all three **byte-identical** across every map that has them
  (`c4095714…`, `fc4e4623…`, `3e8e1c12…`); the other two shared names are reference-only entries
  (`type,,name`), which carry no data and cannot override anything
- sound bank diffed against the **previously shipped** `mod.ff`, not the donor: **1791 → 1801
  aliases, zero pre-existing rows changed, zero removed**; the duck round-tripped byte-identical
- all six deployed files hash-match source; the new symbols confirmed inside the **deployed**
  `mod.iwd` on both sides and the six Zombie Blood assets inside the **deployed** `mod.ff`

### ⚠️ RESIDUAL RISK, stated not hidden — the `toplayer` budget on CLASSIC

This is the one thing that could not be settled offline, and it is worth naming precisely.

Buried classic stock is 63 `toplayer` bits. Under this mod it computes to **~68-69** (+2
`perk_dead_shot`, +2 `perk_tombstone`, +1 `perk_electric_cherry`, +1 `visionset_slot`), and the
user **booted exactly that and it played** — so the ceiling is ≥ 69. Zombie Blood adds +2
(`powerup_zombie_blood`), +1 (`visionset_lerp` widens 3→4 for its 15 lerp steps) and up to +2 more
if either slot field gains a bit: **~71-73**. The only hard upper bound is checkpoint 17's Mob
crash, whose numbers were themselves an estimate. **So the ceiling is bracketed roughly [69, ?]
and this build may sit above it.**

`allplayers` was measured properly and is fine: Buried classic stock 28, +2
`electric_cherry_reload_fx`, +1 `player_zombie_blood_fx` = **31/32**. One bit spare — worth knowing
before anything else is added to that set.

**If it fails it fails LOUDLY at load**, with `Trying to assign N bits for netfield <x> but Client
Field Set TOPLAYER is out of space` naming whichever field asked last. That costs one boot and
tells us the ceiling exactly, which nothing offline can. The obvious bit to free if it comes to
that is Buried's native 5-bit `vulture_perk_disease_meter`, which this mod already knows how to
drop (`zmqol_vulture_has_disease_meter()`).

🛑 **Zombie Blood is NOT gated to survival modes to dodge this.** A power-up present in one mode of
a map and absent in the other is the half-implementation this project does not ship.

### TEST — boot **BURIED CLASSIC** first

It is the fullest map in the game and the only one at real risk. If it loads, everything else will.

1. **Buried classic** — does it load at all? That is the whole test for the budget.
2. Kill zombies until power-ups drop. A **blood-drop icon** should appear in the rotation. Grab it:
   screen goes red, you turn into an Origins German zombie, **zombies walk straight past you for 30
   seconds**, with a looping sound and everything else ducked down under it.
3. **The announcer should call it** — and should also now call **Blood Money** and the **Death
   Machine**, which have both been silent until now.
4. **Origins must be unchanged** — its own Zombie Blood, its own announcer line, its dig sites.

---

## ✅ v1.64.0 — BLOOD MONEY ON EVERY MAP, DROPPING NATURALLY. DEPLOYED, NOT YET BOOTED.

**User, 2026-08-11:** *"didnt get zombie blood or blood money at all, you need to add these 2 power
ups to all the maps that you can that aren't limited by the game… and also for origins make it so
that blood money can spawn naturally and it doesn't need to be dug up in a dig site."*

### 🌟 BLOOD MONEY IS NOT AN ORIGINS POWERUP — it is core, on every map already

`bonus_points_player`, registered at **`_zm_powerups.gsc:106`** in CORE, which loads on all six maps.
Origins is simply the only map that ever called `include_powerup` for it, and even there stock
produces it from a dig site alone (`zm_tomb_dig.gsc:442`).

🌟 **It costs ZERO clientfield bits, which is why it ships everywhere while Zombie Blood cannot.**
The 7-argument call stops short of `add_zombie_powerup`'s `client_field_name` parameter, so the
`registerclientfield()` at `:449` never runs — on either side (`_zm_powerups.csc:20` likewise passes
no field name). Nothing enters the `toplayer` set, so the budget wall below does not apply.

### What shipped

| | |
|---|---|
| server | `zmqol_enable_blood_money()` — `include_powerup( "bonus_points_player" )`, from `main()`, no map gate |
| server | `zmqol_blood_money_natural_drop()` — re-points `level.zombie_powerups["bonus_points_player"].func_should_drop_with_regular_powerups` from stock's `::func_should_never_drop` to core's own `::func_should_always_drop`, the same function nuke/insta_kill/double_points/full_ammo use |
| client | `zmqol_enable_blood_money()` twin in `zm_expanded.csc` |
| `mod.ff` | `xmodel,zombie_z_money_icon` |

**A pointer re-point, not a `replaceFunc`** — the behaviour is reached through
`level.zombie_powerups[...]`, CLAUDE.md §4 failure mode 2 and its prescribed fix. It polls for the
struct because `_zm_powerups::init()` is reached from the MAP's `main()` and is not ordered against
this mod's `init()`; the poll is capped at 30s.

**Origins keeps its dig sites.** This is purely additive there — the natural drop is the only change.

### Everything checked before shipping, each claim traceable

- **The model had to ship.** `Unlinker --list` over all six map fastfiles + `common_zm` + `patch_zm`:
  `zombie_z_money_icon` → `tra 0  nuk 0  hig 0  pri 0  bur 1  tom 1  com 0`. `add_zombie_powerup`
  precaches the model for every INCLUDED powerup (`:419-422`), so including it on the four maps
  without the model would precache an absent asset — fatal at load, the Fire Sale trap.
- **The ownership trap does not apply.** `zm_tomb.ff`'s and `zm_buried.ff`'s copies were dumped and
  hashed — **byte-identical** (json `a9e3dae5…`, glb `c5c760f5…`, 4364 B), so `mod.ff` owning it
  globally cannot regress the two maps that already had it.
- **Its material was already covered.** The GLB references `mc/mtl_x2icon_gold` (shared with Double
  Points' icon); it is already inside `mod.ff` and also in `common_zm.ff`, which loads everywhere.
- **The "creating the include array flips the filter" trap cannot fire** — all six maps call
  `include_powerups()` from their own `.gsc` AND `.csc` (`zm_transit.csc:239`, `zm_nuked.csc:56`,
  `zm_highrise.csc:94`, `zm_prison.csc:169`, `zm_buried.csc:496`, `zm_tomb.csc:142`), and
  `include_zombie_powerup()` is idempotent, so Origins is a no-op.
- **The grab is entirely core** — `powerup_grab()`'s own `case "bonus_points_player"` (`:1060`) →
  `bonus_points_player_powerup()`, `randomintrange( 1, 25 ) * 100` to the grabber only, skipped in
  last stand/spectator. The glow is `level._effect["powerup_on_solo"]`, loaded by core's client init.
- 🛑 **The announcer VO is deliberately silent, and that is parity.** `powerup_vo("bonus_points_solo")`
  reaches `_zm_audio::create_and_play_dialog()`, which returns immediately when
  `level.vox.speaker[...].alias[category][type]` is undefined. **`createvox( "bonus_points_solo", … )`
  appears NOWHERE in the 2,093-file stock dump** — core's `_zm_audio_announcer.gsc:13-20` registers
  carpenter, insta_kill, double_points, nuke, full_ammo, fire_sale, minigun and zombie_blood, and
  not this. So Blood Money is silent on Origins too; adding audio would make the port LOUDER than
  the original — the v1.62.9 mistake.

Verified: both scripts parse (`gsc-tool`, `-i client` for the `.csc`); `mod.ff` links with **0
errors and the same 34 pre-existing warnings**; asset list **3809 → 3810, the one addition and
nothing else — nothing removed, nothing re-owned**; all deployed files byte-identical to source
(`mod.ff 4a5d016c…`, `mod.iwd eb59d55f…`); both new symbols confirmed inside the **deployed**
`mod.iwd` on both sides, and `zombie_z_money_icon` inside the **deployed** `mod.ff`.

### ⚠️ RESIDUAL RISK, stated not hidden

`add_zombie_powerup` also calls `precachestring( &"ZOMBIE_POWERUP_BONUS_POINTS" )`. That string is
precached in stock **only on Origins**, because no other map includes the powerup, and OAT cannot
list `localize` assets for T6 so its presence off Origins could not be confirmed offline. The failure
mode is **cosmetic** — a missing localized key renders as the raw key, it is not fatal — and the
same shape already shipped safely when Fire Sale's `&"ZOMBIE_POWERUP_MAX_AMMO"` was precached onto
TranZit and Die Rise. **If anything looks wrong, it will be the powerup's hint text, nothing else.**

### TEST

**Play any map and kill zombies until powerups drop.** A gold **"$"** icon should now appear in the
normal rotation alongside Max Ammo / Insta-Kill / Double Points; grabbing it gives 100-2500 points to
you only, with no announcer line. Check **Origins** too: the drop should appear from kills, **and the
dig sites must still work exactly as before**.

---

## 🟢 UNBLOCKED 2026-08-11 — THE CLIENTFIELD CEILING WAS NEVER THE PROBLEM

**The user booted Buried CLASSIC on v1.64.0 and it played fine.** `console_zm.log.004`, 8,567 lines,
`ui_mapname zm_buried` / `g_gametype zclassic` / location `processing` — **zero** matches for
`EXE_CLIENT_FIELD`, `is out of space` or `MISMATCHED CLIENTFIELDS`, and the mod's own Wunderfizz
placement lines and 10-perk list print, so it reached real gameplay. Origins classic
(`console_zm.log`, 2:27 AM) likewise booted clean.

🛑 **So the pessimistic table written on 2026-08-11 is WRONG and is withdrawn.** It put Buried
classic at ~70 `toplayer` against an inferred ceiling of 64 and concluded the map was already broken.
It boots. The ceiling is **≥ the mod's real Buried-classic total**, whatever that is — comfortably
more than the 64 the old ERROR_CATALOGUE note inferred. **Zombie Blood's +4/+5 `toplayer` and +1
`allplayers` are affordable on every map, and it should now be built for all six.**

📝 The lesson worth keeping: the Diner-calibrated model reproduced *Diner* exactly and still
mispredicted Buried, because Buried's inputs (visionset entry counts, whether its native
`perk_dive_to_nuke` re-registers at 1 or 2 bits) were assumptions, not measurements. **One boot beat
a day of arithmetic.**

---

## 🔊 THE ANNOUNCER LINES — ALL THREE MEASURED 2026-08-11, and the answers are surprising

User: *"make sure the announcer lines for them work as well, the ones from origins so even on the
other maps. Also, add a death machine announcer line for the death machine power-up."*

**Method:** the alias tables were dumped straight out of the shipped banks —
`Unlinker --include-assets soundbank --search-path "<BO2>\sound" -o <dir> <en_*.ff>` — for
`zmb_tomb.english` (2,566 aliases), `zmb_alcatraz.english` (2,639), `zmb_buried.english` (2,647),
`zmb_highrise.english` (2,036), `zmb_nuked_real.english` (242), `zmb_classic_transit.english` (2,646)
and `zmb_survival_transit.english` (2,516), plus the 96 base-game identifier files in
`H:\Claude\Black Ops II Audio Dumper v6 by master131\Identifiers\`.

| line | alias that really exists | which bank | who plays it in stock |
|---|---|---|---|
| **Zombie Blood** | `vox_zmba_powerup_zombie_blood_0` | `zmb_tomb.english` — **Origins only** | core `_zm_powerup_zombie_blood.gsc:43`, `powerup_vo( "zombie_blood" )`, and core `_zm_audio_announcer.gsc:20` registers the vox on every map |
| **Blood Money** | `vox_zmba_powerup_blood_money_0` | `zmb_tomb.english` — **Origins only** | **map-specific**: `zm_tomb_dig.gsc:24` `createvox( "blood_money", "powerup_blood_money" )`, played at `:773` by `leaderdialog( "blood_money" )` |
| **Death Machine** | **`zmb_vox_ann_death_machine`** | `zmb_highrise.english` — **Die Rise only** | 🌟 **NOTHING. Zero references across all 2,093 stock scripts.** Treyarch recorded it and never wired it up. |

### 🛑 CORRECTION to v1.64.0's write-up

That build's comment block and commit say Blood Money's announcer is *"deliberately silent, and that
is parity"*. **That was measured on the wrong path and is wrong.** It is true that
`createvox( "bonus_points_solo", … )` appears nowhere, so core's `powerup_vo( "bonus_points_solo" )`
inside `powerup_grab()` really does return without playing — but **Origins reaches the line by a
different route entirely**, its dig script's own `leaderdialog( "blood_money" )`. There IS an Origins
Blood Money announcer line, and porting it is correct, not a tuning change.

### 🛑 `powerup_death_machine` IS A DEAD END — do not use it

Core registers `createvox( "minigun", "powerup_death_machine" )` (`_zm_audio_announcer.gsc:19`), so
the obvious move is `powerup_vo( "minigun" )`. **That resolves to `vox_zmba_powerup_death_machine`,
which exists in NO bank in the game** — checked every table above and all 96 identifier files; the
only `vox_zmba_powerup_*` audio that ships anywhere is carpenter, doublepoints, firesale, instakill,
maxammo, nuke (plus the `sam_` variants, and Origins' two extras). The real Death Machine line is
Die Rise's differently-named `zmb_vox_ann_death_machine`, which is not part of the `zmbdialog`
system at all and has to be played directly.

### The route for all three — the mod's OWN bank, already proven

🛑 **NOT `soundbank,zmb_tomb.all` in the zone.** That was v1.19.0 and it **bricked Origins**:
`COM_ERROR Attempting to override asset 'zmb_tomb.all' from zone 'mod' with zone 'zm_tomb'`. Reverted
in v1.21.2, documented at `zone_source\mod_locations.zone:222-249`. Do not re-attempt.

The working route is `soundbank\mod.all.aliases.additions.csv` + payloads under `sound\`, rebuilt by
`build_ff.bat` — the route already carrying `zmqol_cherry_zap`, `zmqol_ww_activate` and 17 others.
**Rename mod-privately** (`zmqol_*`); defining a stock alias name puts a second definition in front
of the map that owns it.

| new alias | payload source |
|---|---|
| `zmqol_ann_zombie_blood` | `zmb_tomb.english` → `vox_zmba_powerup_zombie_blood_0` |
| `zmqol_ann_blood_money` | `zmb_tomb.english` → `vox_zmba_powerup_blood_money_0` |
| `zmqol_ann_death_machine` | `zmb_highrise.english` → `zmb_vox_ann_death_machine` |

📝 Origins and Die Rise keep their own copies — gate each port so the map that owns the audio plays
Treyarch's alias through Treyarch's path, exactly as it does today. That keeps a clean A/B baseline,
the same discipline used for Electric Cherry.

📝 Zombie Blood also has **character** reaction lines in the same bank —
`vox_plr_0..3_powerup_zombie_blood_0..2`, 12 aliases — which stock plays through
`create_and_play_dialog`. Part of the full port; not the announcer.

---

## 🔨 THE BUILD SPEC — execute this mechanically, every unknown is already settled

**User asked for this build on 2026-08-11: "build zombie blood and the three announcer lines."
Scoping is COMPLETE and every mechanism below is measured. NOTHING IS BUILT YET.**

### 🌟 THE ANNOUNCER MECHANISM — settled, and it dictates the alias names

`_zm_powerups.gsc:1147` plays the announcer **generically**, for every powerup, using the powerup's
own name as the dialog key:
```
level thread _zm_audio_announcer::leaderdialog( self.powerup_name, self.power_up_grab_player.pers["team"] );
```
and `playleaderdialogonplayer()` builds the alias as
`game["zmbdialog"]["prefix"] + "_" + game["zmbdialog"][dialog]`, with prefix `"vox_zmba"`.

🛑 **So a ported announcer alias MUST be named `vox_zmba_*`** — a `zmqol_*` name can never be reached
through this path. Mod-privacy is kept with a `qol_` infix instead, which collides with nothing.

🌟 **And it must end in `_0`.** `getleaderdialogvariant()` calls
`_zm_spawner::get_number_variants()`, which is a `soundexists( prefix + "_" + i )` loop
(`_zm_spawner.gsc`). One variant present → `full_alias = base + "_0"`, exactly stock's shape. Ship the
`_0` row and the base name is what `createvox` takes.

| new alias to ship | payload source | `createvox` call |
|---|---|---|
| `vox_zmba_qol_powerup_zombie_blood_0` | `zmb_tomb.english` → `vox_zmba_powerup_zombie_blood_0` | `createvox( "zombie_blood", "qol_powerup_zombie_blood" )` |
| `vox_zmba_qol_powerup_blood_money_0` | `zmb_tomb.english` → `vox_zmba_powerup_blood_money_0` | `createvox( "bonus_points_player", "qol_powerup_blood_money" )` |
| `vox_zmba_qol_powerup_death_machine_0` | `zmb_highrise.english` → `zmb_vox_ann_death_machine` | `createvox( "<mod's powerup name>", "qol_powerup_death_machine" )` |

📝 **Blood Money's key is `bonus_points_player`, NOT `blood_money`.** `:1147` passes
`self.powerup_name`, so the vox must be registered under the powerup's own name. Origins registers it
as `"blood_money"` and plays it explicitly from the dig script — that is why the generic path is
silent there for natural drops. Registering under `bonus_points_player` makes the drop announce on
every map **including Origins**, and leaves the dig's own `leaderdialog( "blood_money" )` untouched.

📝 **Gate Zombie Blood's and Blood Money's vox off Origins** so `zm_tomb` keeps playing Treyarch's
own alias through Treyarch's path — the clean-A/B discipline used for Electric Cherry. **Death
Machine needs no gate**: no map plays it in stock, so there is no baseline to preserve.

### Sound extraction — the traps are known

```
Unlinker --include-assets soundbank --search-path "<BO2>\sound" -o <dir> <BO2>\zone\english\en_zm_tomb.ff
Unlinker --include-assets soundbank --search-path "<BO2>\sound" -o <dir> <BO2>\zone\english\en_zm_highrise.ff
```
🛑 **Dump CSV and payloads in ONE run per bank** — the Unlinker writes `foo.snd.wav.wav` and rewrites
FileSource to match; mixing runs gives `Unable to find a compatible file for sound`. Do not "fix" the
doubled extension. Copy the 3 payloads + their rows into
`soundbank\mod.all.aliases.additions.csv`, rename the `Name` column only, and put the audio under
`sound\`. `build_ff.bat` does drop-and-append, so an edited row is not a silent no-op.

### Zombie Blood — the port itself

Assets (all in `zm_tomb.ff`, already `--load`ed, **except the `.csc`**):
`xmodel p6_zm_tm_blood_power_up` + `material mc/mtl_p6_zm_tm_blood_power_up`,
`fx maps/zombie_tomb/fx_tomb_pwr_up_zmb_blood`, `fx maps/zombie_tomb/fx_zm_blood_overlay_pclouds`,
`material generic_filter_zombie_blood_b`, `rawfile vision/zm_powerup_zombie_blood.vision`,
`xmodel c_zom_tomb_german_player_fb`.
🛑 `script clientscripts/mp/zombies/_zm_powerup_zombie_blood.csc` lives in **`zm_tomb_patch.ff`**,
which is NOT in `build_ff.bat`'s `--load` list — **append it LAST** so first-load-wins cannot let it
re-donate a shared asset (the v1.62.6 shader bug). **Re-audit the asset list after linking; expect
additions only.**

Sounds: `zmb_zombieblood_start`, `_loop`, `_stop`, `_3rd_loop` — Origins-only, re-ship as `zmqol_*`
(these are played by `playsound`/`playloopat` directly, so they do NOT need the `vox_zmba_` shape).

Server: adapt `_zm_powerup_zombie_blood.gsc` (196 lines, core-safe) into `quality_of_life.gsc`,
`include_powerup( "zombie_blood" )` **on both sides**, and a `powerup_grab` hook.
Client: adapt `_zm_powerup_zombie_blood.csc`. 🛑 Its two `vsmgr_register_*` calls must run inside the
client's visionset window — **the same `perks_register_clientfield()` slot Who's Who uses**, NOT
client `main()`, and NOT a polling thread ([[t6-visionset-registration-timing]], checkpoint 29 §3).

Cost, re-confirmed: **+1 `allplayers`** (`player_zombie_blood_fx`), **+2 `toplayer`**
(`powerup_zombie_blood`, from `add_zombie_powerup`), **+1** `visionset_lerp` (15 steps → 4 bits),
**+0-1** each for `visionset_slot`/`overlay_slot`. Affordable everywhere — Buried classic boots.

📝 `level.a_zombie_blood_entities` stays empty off Origins, so the dig-site reveal code is inert. Not
a missing feature; there is nothing to reveal.
📝 `c_zom_tomb_german_player_fb` is ONE model for all four characters — Origins passes it regardless
of who you are, so the literal port turns you into an Origins German zombie on every map. That is
what the original does; per [[zm-qol-port-never-tune]] that is what ships.

---

## 🔨 TASK 2 BACKGROUND (scoping, still valid)

🛑 **Zombie Blood did NOT ship in v1.64.0, and the reason is a number, not an oversight.** Unlike
Blood Money it costs **+1 `allplayers` and +3 to +5 `toplayer`**, and the measurements below put four
of the six maps' classic modes at or over the ceiling *before* it is added. Shipping it on survival
modes only would be the half-implementation this project does not ship. **One boot of Buried classic
settles it** — see "THE ONE BOOT THAT SETTLES BOTH QUESTIONS" below.

## TASK 2 SCOPING (unchanged, still valid)

**Verdict: it CAN be ported completely.** Every asset exists, every sound has a home, and the
clientfield budget fits on Diner with room. No compromise identified. Nothing is deployed — this
section is the verified plan so the implementation is mechanical.

### What the real thing does (`ZM/Maps/Origins/maps/mp/zombies/_zm_powerup_zombie_blood.gsc`, 196 lines)

30 seconds of `self.ignoreme = 1` — zombies ignore you completely — plus: a red screen overlay that
fades in over 1.2s, the `zm_powerup_zombie_blood` visionset, a first-person particle fx on the
camera, a third-person fx linked to your eyeball tag, **your player model swapped to a zombie**, a
looping sound, announcer VO, and `_show_solo_hud` for the countdown. Ends early if you go down
(`watch_zombie_blood_early_exit`). Cannot be picked up in last stand.

📝 `level.a_zombie_blood_entities` / `make_zombie_blood_entity()` is the Origins-only half — it
reveals hidden dig sites while active. Off Origins that array is simply empty, so the code is inert
and needs no changes. Not a missing feature; there is nothing on other maps for it to reveal.

### Assets — ALL of them exist, all in ONE place

| asset | source |
|---|---|
| `xmodel p6_zm_tm_blood_power_up` + `material mc/mtl_p6_zm_tm_blood_power_up` | `zm_tomb.ff` |
| `fx maps/zombie_tomb/fx_tomb_pwr_up_zmb_blood` (3rd person) | `zm_tomb.ff` |
| `fx maps/zombie_tomb/fx_zm_blood_overlay_pclouds` (1st person) | `zm_tomb.ff` |
| `material generic_filter_zombie_blood_b` (the overlay) | `zm_tomb.ff` |
| `rawfile vision/zm_powerup_zombie_blood.vision` | `zm_tomb.ff` |
| `xmodel c_zom_tomb_german_player_fb` (the player model swap) | `zm_tomb.ff` |
| `script clientscripts/mp/zombies/_zm_powerup_zombie_blood.csc` | 🛑 **`zm_tomb_patch.ff`** |

🛑 **`zm_tomb_patch.ff` is NOT in `build_ff.bat`'s `--load` list.** It has to be added, and
**at the END** — first-load-wins decides the donor for every shared asset, and that is exactly what
shipped the wrong shader in v1.62.6 (see §0aab). Appending it means it can only supply assets no
earlier fastfile has. **Re-audit the full asset list after linking; expect additions only.**

📝 `c_zom_tomb_german_player_fb` is ONE model for all four characters — Origins passes the same
string regardless of who you are. So the literal port turns you into an Origins German soldier
zombie on every map. That is what the original does, so per [[zm-qol-port-never-tune]] that is what
ships; no per-map substitute, no dropping it.

### Sound — 4 aliases, all Origins-only, all portable

`zmb_zombieblood_start`, `zmb_zombieblood_loop`, `zmb_zombieblood_stop`, `zmb_zombieblood_3rd_loop`
— dumped every bank from `zm_tomb`, `zm_transit`, `zm_nuked` and `common_zm`: present **only** in
`zmb_tomb.all`. Re-ship under `zmqol_` names through `soundbank/mod.all.aliases.additions.csv`, the
route already proven by `zmqol_cherry_zap` and `zmqol_ww_activate`.
Also check `powerup_vo( "zombie_blood" )` resolves — `_zm_audio_announcer.gsc` references it.

### Clientfield cost — measured against the mod's REAL runtime totals, not the stock dumps

🌟 Read from the v1.63.1 boot log's own dump (`console_zm.log.009`, the only log with one, because
the field list only prints on a mismatch). **Diner survival, this mod, actual:**

```
world 22   actor 7   allplayers 20   toplayer 53 client / 54 server   scriptmover 11   zbarrier 4
```

Zombie Blood adds:

| field | set | bits |
|---|---|---|
| `player_zombie_blood_fx` | allplayers | +1 |
| `powerup_zombie_blood` (from `add_zombie_powerup`, 2 bits, **auto**) | toplayer | +2 |
| widening from +1 visionset and +1 overlay entry | toplayer | +1 to +3 |

Current widths on Diner: `visionset_slot` 2, `visionset_lerp` 3, `overlay_slot` 2, `overlay_lerp` 5.
Zombie Blood's lerp count is 15 → `visionset_lerp` goes to 4 (+1); `overlay_lerp` is already 5 from
Vulture's 31 steps, so **no change there**. Slots may each gain a bit.

**Diner: toplayer 54 → ~57-59, allplayers 20 → 21. Comfortable.**

### 🛑 SETTLED 2026-08-11, AND THE ANSWER BLOCKS THE FEATURE ON EVERY CLASSIC MAP

**Zombie Blood's exact cost, read from stock source, not inferred:**

| field | set | bits | source |
|---|---|---|---|
| `player_zombie_blood_fx` | allplayers | +1 | `_zm_powerup_zombie_blood.gsc:13` |
| `powerup_zombie_blood` | toplayer | +2 | `_zm_powerups.gsc:449` — `add_zombie_powerup` always registers 2 |
| `visionset_lerp` widening | toplayer | +1 | ZB's lerp_step_count is 15 → `getminbitcountfornum(15)` = 4; current max is 3 |
| `visionset_slot` / `overlay_slot` | toplayer | +0 to +2 | `_visionset_mgr.gsc:210` — `getminbitcountfornum(info.size - 1)` |

**So +1 allplayers and +3 to +5 toplayer, per map.**

### 🌟 THE MODEL IS VALIDATED — it reproduces the one map that has a real measurement

`console_zm.log.009` is the only boot log carrying a field dump (the list prints on a mismatch).
Diner survival, this mod: **toplayer 54 server / 53 client, allplayers 20, actor 7**. Starting from
stock Diner survival (`clientfields_zm_transit_zstandard_diner.txt`, toplayer 27) and applying the
mod's own transformations — `deadshot_perk` dropped by `init_client_flags`, the eight `perk_*` fields
from the replaced `perks_register_clientfield`, Vulture's four, Who's Who's two, Fire Sale, and the
visionset/overlay widenings — lands on **exactly 54**. The method is trustworthy.

### 🛑 THE CEILING, BRACKETED FROM TWO REAL EVENTS

- **≥ 63** — Buried classic stock totals 63 and the retail game runs it.
- **≤ ~67** — checkpoint 17's Mob crash: `Trying to assign 5 bits for netfield
  vulture_perk_disease_meter but Client Field Set TOPLAYER is out of space`. Mob's total under the
  mod at that moment computes to the mid-60s before that 5-bit field was asked for.

So **toplayer ≈ 64**, matching the long-standing inference. Anything computed ≤ 63 is safe; anything
above ~67 is fatal at load.

### 🔴 APPLIED TO EVERY MAP — and Buried classic is ALREADY over, before Zombie Blood

| map / mode | stock | under this mod | + Zombie Blood | verdict |
|---|---|---|---|---|
| Origins (`zm_tomb`) | 61 | — | **ships it natively** | ✅ nothing to do |
| Nuketown | 18 | ~45 | ~50 | ✅ fits easily |
| TranZit **survival** locations (Diner etc.) | 27 | **54 measured** | 57-59 | ✅ fits |
| Mob classic | 50 | ~58-61 | ~63-66 | ⚠️ borderline, not provable |
| TranZit classic | 38 | ~61-62 | ~65-67 | 🛑 over |
| Die Rise classic | 33 | ~62 | ~66-67 | 🛑 over |
| **Buried classic** | **63** | **~68-69** | — | 🛑 **over ALREADY** |

**Buried classic's ~68 is not caused by Zombie Blood.** It is `perk_dead_shot` (+2),
`perk_tombstone` (+2) and `perk_electric_cherry` (+1) landing on a map that stock already fills to
63. `perks()` runs from `main()` on every map with no gametype guard, so classic gets them too.

📝 **The recent logs only ever show `zm_transit` and `zm_tomb` booted with this mod** (10 rotations
checked, `loadmod: loaded mods/zm_qol` + `Loading fastfile zm_*`). Buried classic with this mod
appears never to have been booted. Checkpoint 10's "Buried maze loads and plays" is **survival**
(13 actor / ~24 toplayer stock), not classic.

### ✅ THE ONE BOOT THAT SETTLES BOTH QUESTIONS — ask before building anything

**Boot Buried CLASSIC on the current build.** No code change needed.

- **It fails at load** → the ceiling bracket is right, Buried classic has a real pre-existing bug,
  and Zombie Blood cannot go on any classic mode without dropping something else first.
- **It loads and plays** → the ceiling is above 68, the whole table above is too pessimistic, and
  Zombie Blood ships everywhere with room.

Either outcome is decisive, and no build can be trusted until it is known.

🛑 **Do not ship Zombie Blood on survival modes only.** A power-up present in one mode of a map and
absent in the other is the half-implementation this project does not ship — the same call already
made for Who's Who on Buried.

### Implementation order when it starts

1. `zone_source/mod_locations.zone` + `zm_tomb_patch.ff` appended to `--load`; link; audit asset list
2. the 4 sound aliases + payloads
3. server: adapt `_zm_powerup_zombie_blood.gsc` into `quality_of_life.gsc` (it is core-safe — no
   map-specific references), `include_powerup( "zombie_blood" )`, and a `powerup_grab` hook
   mirroring `tomb_powerup_grab`
4. client: `init()` from a point inside the visionset window — **the same
   `perks_register_clientfield()` slot Who's Who uses**, NOT client `main()`
   ([[t6-visionset-registration-timing]])
5. per-map gate function, one copy each side, exact twins

---

## 🛑 CLOSED FOREVER — ELECTRIC CHERRY IS VANILLA AND STAYS VANILLA (user, 2026-08-09)

**Do not re-open this. Do not "fix" it. Do not instrument it again.** Four rounds went into it; the
answer never changed and the user has now made the call with the numbers in front of them.

**The perk is byte-for-byte stock on every map.** Verified by decompiling
`maps/mp/zombies/_zm_perk_electric_cherry.gsc` **out of the shipped `patch_zm.ff`** — not the
gsc-dump. `BO2-Reimagined` keeps the identical curves too; it only deletes the throttle.

```
radius = linear_map( clip_fraction, 1.0, 0.0,  32, 128 )
dmg    = linear_map( clip_fraction, 1.0, 0.0,   1, 1045 )
round-10 zombie health = 1045   (150, +100 for rounds 2-9 = 950, then 950 + int(95))
```

| clip | radius | damage | round 10 |
|---|---|---|---|
| 8/8 | 32 | 1 | nothing at all |
| **7/8** | **44** | **131** | **8 zaps — this is what the user was doing** |
| 4/8 | 80 | 523 | 2 zaps |
| 0/8 | **128** | **1045** | **one-shots the whole close ring** |

🌟 **The decisive measurement came from the user's own recording**, decoded to 68 frames: the ammo
counter reads `8/49 -> 7/49 -> 8/48 -> 7/48 -> 8/47 -> 7/47 -> 8/46`. **One bullet fired, then
reload, every single time.** A 44-unit radius does not even reach a zombie mid-swing (~50-70 units
origin to origin), so those zaps touched nothing — they were not weak, they were out of range.

**Everything else in the chain was checked and is correct:** `get_round_enemy_array()` (only filters
`ignore_enemy_count`), `get_array_of_closest()` (squares maxdist properly), the mod's damage hooks
(`register_zombie_damage_callback` only — additive, cannot reduce damage), and the whole fx/material
chain (byte-identical to `zm_prison`'s).

**Offered explicitly, with the tables above: raised floor, flat maximum, or vanilla. The user chose
VANILLA.** The stock consecutive-reload throttle (#6+ does literally nothing) stays too.

📝 **How to actually use it:** fire the WHOLE magazine dry, then reload into the horde. Fire-one-and-
reload buys about 12% of the perk. This is Treyarch's design — max damage is tuned to exactly
round-10 health.

---

## ✅ WHO'S WHO — CONFIRMED IN GAME 2026-08-09

**User: "Who's Who seems to be working fine, all effects working good."** The overlay, the visionset,
the audio and the corpse glow all land. Shipped in v1.63.0-v1.63.2; the visionset registration fix
in v1.63.2 is what made it boot. Full write-up below and in checkpoint 28.

---

## ⏳ STILL UNCONFIRMED — the boarded-window fix

Shipped in v1.63.1, booted since, but **the user has not reported on it either way.** Hold a Diner
Survival window and watch: nothing should cross intact boards. Details below.

---

## v1.63.1 — barrier bug fixed, Who's Who visuals ported, EC answered from the clip

**DEPLOYED, NOT YET BOOTED.** `.gsc` + `.csc` + `mod.ff` + both sound banks. Three reports, one build.

---

### 1. ✅ THE BOARDED-WINDOW BUG — root-caused to two spawners, fixed

**User:** *"I just watched a zombie hop over straight through this barrier while all 6 planks were
built"* (Diner Survival, screenshot at `.where` = x -5566 y -7920).

**Every link measured, nothing inferred:**

| # | finding | how it was measured |
|---|---|---|
| 1 | `zone_diner_roof`'s only two REGULAR-zombie spawners sit on the ground at **(-5756.5,-8254)** and **(-6171.5,-8270)** — ~220u SOUTH of the diner window line (barriers at y=-8035) | `Unlinker --include-assets mapents zm_transit.ff` |
| 2 | both carry `script_string "find_flesh"` | same dump |
| 3 | `_zm_spawner::should_skip_teardown()` returns **true** for exactly that string, so `zombie_think()` early-returns and **never calls `tear_into_building()`** — no boards, no attack spot, no teardown | stock source |
| 4 | they free-path with `find_flesh()`, and the diner barrier has a `node_negotiation_begin` with `animscript "zm_mantle_over_40"` — the "hop over" | mapents |
| 5 | 🌟 `_zm_blockers::blocker_disconnect_paths()`, the one thing that would close that path while boards are up, is an **EMPTY STUB** | **decompiled the shipped `patch_zm.ff` copy**, not just the gsc-dump |

So the mantle node is permanently live and the shortest route from spawn to a player inside is
straight over the intact window.

**Why this is ours and not stock's:** Reimagined disables `zone_diner_roof` outright
(`zm_transit_loc_diner.gsc:154`). This project deliberately re-enabled it so the roof is a tracked
zone for the Pack-a-Punch climb — which switched those two spawners back on.

**The fix** — two more origin matches in `disable_zombie_spawn_locations()`, the same mechanism
Reimagined already uses there for four other problem spawners.

🌟 **Complete and side-effect free, and that is measured too:** the zone's other three spawners are
tagged `dog_location` / `avogadro_location`, which `_zm_zonemgr.gsc:227-248` files into
`zone.dog_locations` / `.avogadro_locations` and **never** into `zone.spawn_locations`. This loop
only walks `spawn_locations`, so hellhounds and the Avogadro are untouched and the roof loses
nothing — it never had a regular-zombie spawner on it.

---

### 2. ✅ WHO'S WHO — the visuals ported, and one fatal bug caught before shipping

**User:** *"Who's Who is still missing its visual overlay fx when downed and in the self-revive state."*

**Cause: one level var.** Every effect the perk has lives inside
`_zm_chugabud::activate_chugabud_effects_and_audio()` (:745) and the whole body is wrapped in
`if ( isdefined( level.whos_who_client_setup ) )`. The corpse glow at :71-72 is behind the same flag.
**Only `zm_highrise.gsc:81` ever sets it**, so off Die Rise the perk ran with its functionality
intact and every single effect skipped — silently, because the gate is an `isdefined`, not an error.

**Shipped, both sides symmetric:**
- server: the three stock clientfields (`clientfield_whos_who_clone_glow_shader` actor 1 bit,
  `_audio` and `_filter` toplayer 1 bit each), `level.whos_who_client_setup = 1`,
  `level.vsmgr_prio_visionset_zm_whos_who = 123`
- client: the same three with callbacks — **our own** `zmqol_whoswho_filter` / `zmqol_whoswho_audio`,
  because stock's live in map-specific `zm_highrise_amb.csc` and a `::` reference there resolves at
  load time and would crash every other map (AI_CONTEXT rule 2). `chugabud_whos_who_shader` is core
  and is referenced directly.
- `mod.ff`: `material generic_filter_afterlife` + `rawfile vision/zm_whos_who.vision`, both
  `zm_highrise.ff`-only, both byte-copies
- sound: `evt_ww_activate` / `evt_ww_looper` are **Die Rise-only** (dumped every soundbank from
  zm_highrise/zm_transit/zm_tomb/zm_nuked/common_zm and grepped the alias CSVs), so they are
  re-shipped as `zmqol_ww_activate` / `zmqol_ww_looper` through the mod's own bank — the route
  already proven by `zmqol_cherry_zap`

#### 🛑 THE BUG THE PRE-MORTEM CAUGHT — it would have hard-dropped three maps

The first draft called `vsmgr_register_visionset_info()` inline from `perks()`. **That silently
no-ops.** On the client `level.vsmgr` is created by `_visionset_mgr::init()`, called from
`clientscripts\mp\zombies\_zm.csc:39` — inside the client `_zm::init()`. This mod's `.csc` `main()`
runs **before** that, proven by the fact that the perk flags it sets are read during that same init
and Who's Who's HUD icon works today. The server still registers `zm_whos_who` in
`turn_chugabud_on()`, so the two sides would hold a different visionset **count**, and the count sets
`visionset_slot`'s width (`finalize_type_clientfields` → `getminbitcountfornum(size-1)`) —
`EXE_CLIENT_FIELD_MISMATCH` for everyone at load. Die Rise gets away with the direct call only
because it registers *after* `start_zombie_stuff()` has run `_zm::init()`.

Now polled by `zmqol_whoswho_register_visionset()`, which registers the first frame the manager
exists and while `vsmgr_initializing` is still 1. The window opens at `_zm.csc:39` and closes only at
`finalize_clientfields()` (an `on_finalize_initialization` callback, long after map init), so the
margin is large.

#### 🛑 BURIED IS DROPPED — budget wall, the user's call

`actor` set, counted field by field from the per-map dumps:

| map | stock actor | +1 glow bit |
|---|---|---|
| `zm_transit` | 5/32 classic, 4/32 survival | fits easily |
| `zm_nuked` | 4/32 | fits easily |
| `zm_tomb` | **31/32** | lands on exactly 32/32 — legal, but **zero margin forever** |
| `zm_buried` | **32/32 classic** | would be 33 → fatal at load |

Buried survival is only 13/32, but a perk present in one mode of a map and absent in the other is
the half-implementation this project does not ship. Dropped entirely, as decided.

📝 `level.chugabud_shellshock` is deliberately **not** set — it is assigned nowhere in the 2,093-file
stock dump, so the shellshock never fires in stock either. Adding it would make the port louder than
the original, which is the v1.62.9 mistake.

---

### 3. 📊 ELECTRIC CHERRY — the clip answered it completely. NO CODE CHANGE.

`G:\Clips\NVIDIA\Plutonium\Plutonium 2026.08.09 - 16.40.39.03.DVR.mp4`, decoded to 68 frames.

**The ammo counter across the whole 8.5s: `8/49 → 7/49 → 8/48 → 7/48 → 8/47 → 7/47 → 8/46`.
One bullet fired, then reload. Every single time.** m1911, clip size 8, round 10.

```
fraction = 7/8 = 0.875
radius   = linear_map(0.875, 1.0, 0.0,  32, 128) =  44 units
damage   = linear_map(0.875, 1.0, 0.0,   1, 1045) = 131
round-10 zombie health = 1045   (150, +100 for rounds 2-9 = 950, then 950 + int(95))
1045 / 131 = 8 zaps to kill one zombie
```

**With an EMPTY mag: radius 128, damage 1045 — exactly round-10 health, so it one-shots the whole
close ring.** The user's expectation is precisely right; Treyarch tuned max damage to round 10. It
just needs an empty magazine, and a 7/8 clip buys ~12% of the perk.

*"kept shooting and reloading and it did nothing at all"* is stock's consecutive-reload throttle:
attack #3 caps at 8 zombies, #4 at 4, #5 at 2, **#6+ at ZERO**, reset only after
`reload_time + 3` seconds without reloading.

🛑 Verified against the **shipped bytecode**, not the gsc-dump: decompiled
`maps/mp/zombies/_zm_perk_electric_cherry.gsc` straight out of `patch_zm.ff` — same curves, same
throttle. The perk is running exactly as vanilla, so **nothing was changed** (the user has twice
instructed not to modify it). Any change here is now a balance decision that is theirs to make.

---

### TEST

1. **Diner Survival** — hold a window and watch. Nothing should cross intact boards.
2. **Who's Who** on Diner / Nuketown / Origins — buy it, go down. Expect the blue afterlife screen
   filter + the `zm_whos_who` vision, the sting and looper audio, and a glow on your downed body.
   Log: `[zm_qol] whoswho CLIENT: zm_whos_who visionset registered after Ns`.
   🛑 Boot **Die Rise** too — `mod.ff` now owns two of its assets.
3. **Electric Cherry** — empty the mag completely, then reload into a crowd at round ≤10.

Verified: all four scripts parse (incl. `-i client`); `mod.ff` links with 0 errors and the same 34
pre-existing warnings; asset list 3811 → 3816, **the 5 additions and nothing else, nothing removed,
nothing re-owned**; both new sound aliases and both payloads confirmed inside the built banks with
byte-exact sizes; all 6 deployed files byte-identical to source; the three new client symbols
confirmed inside the **deployed** `mod.ff`.

---

## ✅ v1.62.10 — Electric Cherry REVERTED to stock on every map

**DEPLOYED, NOT YET BOOTED.** `.gsc` only — `mod.ff` md5 `587f2f7c…` unchanged.

**User, 2026-08-09:** *"now the visual effects are overbearing visually to look at in-game, they're
not the original… 90% of the time when reloading and the zapping occurring, zombies remained
untouched by it even when they're up in my face."*

### What shipped: every behaviour change to Electric Cherry is GONE

Deleted outright — the pointer re-point and all five functions behind it
(`zmqol_ec_take_over`, `zmqol_electric_cherry_reload_attack`, `zmqol_ec_check_reload_complete`,
`zmqol_ec_weapon_replaced_monitor`, `zmqol_ec_reload_watchdog`), plus every `[zm_qol] EC:` probe
line. `level._custom_perks[…].player_thread_give` is left where stock's
`register_perk_threads()` put it, so **stock's own `electric_cherry_reload_attack()` runs on every
map.**

🌟 **Mob of the Dead and Origins now run ZERO mod code for this perk** —
`zmqol_enable_electric_cherry()` returns at its first line on any map that is not `zm_transit`,
`zm_nuked`, `zm_highrise` or `zm_buried`, and nothing else touches it. That makes them a clean
reference for the A/B test below.

### 🌟 THE OVERBEARING FX WERE OURS — measured, not inferred

The asset chain was audited end to end first, and it is **already correct**:

| checked | result |
|---|---|
| the 6 lightning/arc materials mod.ff owns | **byte-identical** to `zm_prison`, `zm_tomb`, `zm_transit`, `zm_buried`, `zm_highrise`, `zm_nuked` — every map that has them |
| `rawfile vision/zm_electric_cherry.vision` | `ba7a920e…` in mod.ff, `zm_prison` **and** `zm_tomb` — one file, no per-map variant |
| `script clientscripts/mp/zombies/_zm_perk_electric_cherry.csc` | `198fc38c…`, identical to `zm_prison_patch.ff`, which is the **only** fastfile that carries it |
| the tesla + alcatraz-cherry fx | live in `zm_prison` and `zm_tomb` only; `--load` order takes Mob's, and Mob is the perk's home map |
| tesla textures shipped by this mod | **none** — `images/` and `zone_assets/images/` carry no tesla/lightning file, so the pixels are the game's own |

So the assets are canonical and the intensity had to come from script. It did, and it was v1.62.9's
two deletions:

- **no 0.1s stagger** → every zombie's `tesla_shock` fx started in the **same frame** instead of
  0.1s apart, so the zap read as one bright mass rather than an arc travelling the crowd.
- **no throttle** → reload #3+ played full-strength fx where stock plays a reduced set or none.

That also fits the timeline exactly: v1.62.7 was **confirmed improved** by the user, and the only
thing between it and this report is v1.62.9.

### ⚠️ WHAT THIS DOES *NOT* CHANGE, stated plainly

**"Zombies remained untouched even up in my face" is stock's arithmetic, and it stays.** Measured
from the user's own v1.62.8 log, not asserted: `radius = linear_map( clip_fraction, 1.0, 0.0, 32,
128 )`, so a 39/40 clip gives **radius 34 units** and **27 damage**, and their log line read
`in_radius=1 nearest=31` — the maths reproduced exactly. Power is paid for with the magazine.

Changing that curve is the modification the user has now twice forbidden, so it is not touched.
**Mob and Origins will behave identically** — same core function, `patch_zm.ff` owns
`_zm_perk_electric_cherry.gsc` and loads on every map.

Two stock quirks are therefore **back**, deliberately: a cancelled reload eats the next zap (stock
never releases `self.wait_on_reload`), and reload #5 in quick succession does nothing. Both are
present on Mob and Origins too.

### TEST — an A/B, because it settles the port question by construction

1. **Mob of the Dead**, Electric Cherry, empty a full mag next to a crowd. This is untouched stock.
2. **Diner** (or Nuketown / Die Rise / Buried), same perk, same empty mag, same crowd.

**They must look and behave the same.** If they do, the port is correct and what is left is stock's
design. If they differ, that difference is a real port defect with a concrete target — say which of
the two looks wrong and how.

Verified: parses (`gsc-tool`, all four scripts incl. `-i client`); zero dangling references to the
five removed symbols; deployed `mod.iwd` **byte-identical to source** (`0013564d…`) and carries
**0** occurrences of the removed symbols; `mod.ff` md5 unchanged.

---

## 0aad. SUPERSEDED by v1.62.10 — v1.62.9, Electric Cherry: the probe answered, two defects removed

**Kept for the measurement only. Its two "fixes" were reverted — they modified the perk.**

**DEPLOYED, NOT YET BOOTED.** `.gsc` only — `mod.ff` md5 unchanged from v1.62.7 (`587f2f7c`), so
the shader fix rides along.

### 🌟 THE PROBE ANSWERED THE QUESTION — the perk was stock, and running correctly

v1.62.8's log, 14 reloads, one boot on Diner. **Every reload was at 65–97% clip.** Electric Cherry's
power is bought with the magazine:

```
radius = linear_map( clip_fraction, 1.0, 0.0,  32, 128 )   full clip -> 32 units,  empty -> 128
dmg    = linear_map( clip_fraction, 1.0, 0.0,   1, 1045 )  full clip -> 1 damage,  empty -> 1045
```

| what the user did | radius | dmg | result |
|---|---|---|---|
| clip 39/40 (typical) | 34 | 27 | 1–3 zombies in range, none killed |
| clip 5/8 (their best) | 68 | 392 | still no kills at that round |
| clip 0/40 (never done) | **128** | **1045** | the horde zap they expected |

Every radius/damage pair in the log reproduces stock's formula exactly, so **the mod was running the
genuine perk, unmodified.** Not a defect — the designed mechanic. **To get the horde-wide zap, empty
the mag.** Reimagined, the project's reference, also leaves both curves untouched.

🛑 **User's call, asked directly 2026-08-09: keep stock's curve, fix only the real defects.** Radius
and damage are therefore UNCHANGED. They were offered a raised floor and a flat-max option and
declined both.

### What shipped — three defects out, curves untouched

1. **The consecutive-reload throttle is deleted.** Stock capped attack #3 at 4 zombies, #4 at 2, and
   **#5+ at ZERO** — a reload that costs a magazine and silently does nothing, with no feedback of
   any kind. Reimagined deletes it outright (`_zm_perk_electric_cherry.gsc:66`).
2. **The 0.1s per-zombie damage stagger is deleted.** Stock waited 0.1s before EACH `dodamage`, so a
   crowd of 20 resolved over two full seconds — the zap trickled instead of landing. Reimagined
   damages the whole array in one frame. The loop stays bounded by `a_zombies.size`, so removing its
   only wait carries no unterminated-loop risk, and both fx helpers use Treyarch's own
   `network_safe_play_fx_on_tag` throttle.
3. **The reload latch watchdog** from v1.62.8, kept. (No `SKIPPED` lines appeared in the log, so it
   was not what the user was hitting — but it is still a real defect and stays fixed.)

📝 Also fixed the v1.62.8 log line itself: `n_zombies_hit` was only incremented inside the throttle
branch, so `touched N` always printed **0** once the throttle was inactive. It counts properly now.

### 🛑 A REGRESSION CAUGHT OFFLINE — Origins ships its OWN copy of this function

`zm_tomb.gsc:2003` defines `tomb_custom_electric_cherry_reload_attack` and `:178` registers it in
place of core's. **Owning the perk globally replaces it**, so its two deliberate differences had to
be carried or Origins would have silently regressed:

| difference | why it matters |
|---|---|
| raw `getaispeciesarray( "axis", "all" )`, not `get_round_enemy_array()` | the latter filters `.ignore_enemy_count` actors, and `_zm_ai_mechz.gsc:532` sets that flag on **the Panzer Soldat** — core's array would have dropped the Panzer out of the zap entirely on Origins |
| stun guarded on `.is_mechz`, not `.is_brutus` | without it, owning the perk globally would `animscripted()` a Panzer, which stock deliberately never does |

Both are carried inline, the stun guard as the **union** of the two flags — `is_brutus` exists only
in Mob's `_zm_ai_brutus.gsc` and `is_mechz` only in Origins' scripts, so only one can ever be defined
on a given map and the union is exactly each map's own guard.

Origins is the **only** map that overrides this: three hits for
`register_perk_threads( "specialty_grenadepulldeath" )` across all 2,093 stock scripts — core,
Origins, and TranZit's identical copy of core.

### TEST

**Empty a full magazine, then reload with a crowd on you.** That is the case that was never tried.
Expect radius 128 / damage 1045 — the whole close ring shocked and killed at once, not trickling.

Then **reload-spam five times in a row**; #5 used to do literally nothing and now works.

Log line (throttle field removed, counter now honest):
```
[zm_qol] EC: attack #N wpn=… clip=0/40 radius=128 dmg=1045 zombies_alive=24 in_radius=11 nearest=31
[zm_qol] EC: resolved - touched 11 zombie(s), 11 were under the damage threshold
```

Verified: parses (`gsc-tool`); deployed `mod.iwd` **byte-identical to source** and carries all four
changes (mechz guard, Origins array branch, throttle gone, stagger gone); `mod.ff` md5 unchanged.

---

## 0aac. SUPERSEDED by v1.62.9 — v1.62.8, Electric Cherry's BEHAVIOUR: owned and instrumented

**BOOTED 2026-08-09 — the probe worked and named the cause. See v1.62.9 above; this section is kept
for the ruled-out table only.**

**User, 2026-08-09, rejecting the "it's just stock" answer:** *"i had a crowd of zombies attacking me
and i was in god mode and i had electric cherry, kept activating electric cherry's zap by shooting
and reloading and it did nothing, maybe sometimes it'd hit like one zombie and it wouldn't even kill
it… it's bugged. You need to fix whatever's causing it. Don't halucinate."*

### What is now RULED OUT — do not re-tread

| ruled out | how |
|---|---|
| the fx | all six EC effects in `mod.ff` are **byte-identical to `zm_prison.ff`'s** — each extracted back out of the built `mod.ff` and hashed |
| the mod modifying the perk | no `replaceFunc` touches any `_zm_perk_electric_cherry` function; `give_perk`'s override keeps the `[[ player_thread_give ]]()` line |
| a map-specific script gap | `patch_zm.ff` **owns** `maps/mp/zombies/_zm_perk_electric_cherry.gsc` and loads on every map (`zm_prison_patch.ff` holds only a `script,,` reference) |
| a silent target cap | `get_array_of_closest( org, array, excluders, max, maxdist )` (`maps\mp\_utility.gsc:1773`) — `undefined, undefined, perk_radius` really is max=all, maxdist=radius |

So the code being run **is** stock. What could not be settled from the files is what stock's
arithmetic evaluates to live.

### What shipped — measure, do not guess

`level._custom_perks["specialty_grenadepulldeath"].player_thread_give` is re-pointed at our own copy
of `electric_cherry_reload_attack`. **A pointer re-point, not a `replaceFunc`** — CLAUDE.md §4
failure mode 2's own prescribed fix, and the only route `give_perk` uses. Applies on **every** map
including Mob and Origins.

The copy is line-for-line stock **except one fix**: stock parks the weapon in `self.wait_on_reload`
on `reload_start` and releases it only when the engine fires `"reload"` on completion
(`:332-350`). **A cancelled reload never releases it, so the NEXT reload is skipped entirely** — no
fx, no damage. `zmqol_ec_reload_watchdog()` releases the latch after the weapon's own reload time
+ 2s. That is a defect in any reading and matches *"half of the time it does nothing"*.

🛑 **Radius (32→128), damage (1→1045) and the consecutive-reload throttle (∞, ∞, 8, 4, 2, then
ZERO) are left at stock's numbers** — changing them is a balance call that is the user's, not a bug
fix. Every one of them is now printed.

**New log lines — one boot names the cause:**
```
[zm_qol] EC: took over reload attack on <map> after Ns
[zm_qol] EC: attack #N wpn=… clip=7/30 radius=99 dmg=782 limit=8 zombies_alive=24 in_radius=3 nearest=41
[zm_qol] EC: THROTTLED to zero - stock's consecutive-reload limit …
[zm_qol] EC: SKIPPED - <wpn> still latched from an unfinished reload
[zm_qol] EC: watchdog released <wpn> - that reload was cancelled …
[zm_qol] EC: resolved - touched N zombie(s), M were under the damage threshold
```

**TEST: repeat exactly what you did — crowd of zombies, god mode, shoot and reload — then send the
log.** `in_radius=0` with `zombies_alive` high means the radius curve; `THROTTLED to zero` means the
throttle; anything else is a real bug and the numbers will name it.

Verified: parses (`gsc-tool`); deployed `mod.iwd` carries all four new symbols; `mod.ff` md5
unchanged from v1.62.7.

---

## 0aab. DONE (deployed, fx CONFIRMED IMPROVED) — v1.62.7, mod.ff was shipping the WRONG SHADER

**DEPLOYED, NOT YET BOOTED.** No script changed — this is a `build_ff.bat` `--load` order fix only.

**User, 2026-08-09 (`TASKS_QUEUE_01.txt` task 1):** *"the electrical zapping visual fx that go onto
the Zombies' bodies is really bright, it's like a big circle of effect and it's not the same as the
regular Electric Cherry."* When asked, they confirmed it looks wrong **on Mob of the Dead and
Origins too** — where the perk is stock and this mod adds nothing to it.

🌟 **That answer is what cracked it.** A defect visible on maps the mod does not touch cannot be
map-side; it has to be `mod.ff`, which loads before every map.

### The mechanism, measured end to end

OAT's Linker resolves each asset from the **first `--load`ed fastfile that holds a real definition**
(a `type,,name` entry is a reference and carries no data, so it keeps looking). Two fastfiles can
hold **different bytes under the same name** — stock ships per-map shader permutations. `build_ff.bat`
listed `so_zsurvival_zm_transit.ff` 3rd and `zm_prison.ff` 8th, so `mod.ff` baked TranZit-survival's
copy of `techniqueset effect_zeqqz943` — the shader behind the tesla-shock flare materials — and
**overrode the correct one on every map, Mob and Origins included.**

```
techniqueset effect_zeqqz943, 4928 bytes in every case:
  zm_prison / zm_tomb / zm_highrise   503675916d7525ca   <- all three identical
  so_zsurvival_zm_transit             b6c22239cf5774a5   <- what mod.ff was shipping
```

### The fix

`zm_prison.ff` + `zm_prison_patch.ff` moved ahead of every `so_*.ff`. Mob of the Dead is Electric
Cherry's home map, so the perk's **entire chain now comes from one canonical donor** instead of being
scavenged across four: the 5 alcatraz cherry fx, the 3 tesla fx, the bottle weapon and its two
xmodels, the HUD + minimap icons, `vision/zm_electric_cherry.vision`, and every lightning
material/techset beneath them.

**Verified offline, each claim traceable:**
- built `mod.ff` is **byte-identical** to the audited scratch build (`587f2f7c…`)
- **asset list identical before and after** — 3812 lines, nothing re-owned, nothing dropped
- 0 errors; the same 34 warnings as before, all pre-existing sound sample-rate notices
- 64 assets change donor; **20 actually differ in content**, every one Electric Cherry's own or in
  the tesla chain (each pair byte-compared by linking a one-asset zone from both donors)
- the shipped techset is now byte-identical to `zm_prison.ff`'s, confirmed by extracting it back
  **out of the built `mod.ff`**
- deployed `mod.ff` md5 matches source; v1.62.6's LUI perk fix confirmed still inside the deployed
  `mod.iwd` (`zmqol_lui_perkfix` and `NextPerkWidget = nil` both present)

**TEST: get Electric Cherry, empty a clip, reload next to zombies.** The zap on their bodies should
be lightning arcs, not a bright blob — and it should look the same on Diner as on Mob.

⚠️ **Residual risks, stated not hidden:**
1. **The reload fx that currently looks RIGHT also changed donor.** All four
   `fx_alcatraz_electric_cherry_*` moved Origins→Mob and all four differ in bytes. Mob's are the
   canonical ones, but this is a change to something that was not complained about. Check it still
   looks right.
2. Three generic lit-model techsets (`mc_lit_sm_r0c0d0n0_33ffej1u`, `_r0c0n0x0_q361191u`,
   `_t0c0n0_9qf6e4qj`) differ on **every** map, so no donor is right for all of them. `mod.ff` has
   always overridden them globally; this only changes which map they match. Not introduced here —
   the real repair is to stop owning them, QUEUE §0f item 4.
3. `fxt_fx_emp_ring_wave` improves: Origins' odd-one-out copy → the copy TranZit, Mob and Buried
   all share.

---

## 🆕 THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`, given 2026-08-09

**Do them top to bottom, one at a time.** Standing scope rule the user restated with it: *"if I ask
you to add something don't just consider Diner — add it to all maps unless specified otherwise, or
if you literally can't properly port it due to limitations of the game's engine."*

| # | task | state |
|---|---|---|
| 1 | **Who's Who + Electric Cherry fx must be literal genuine ports.** EC: the zombie-body zap is a bright blob. Who's Who: no screen fx at all in the revive state. | EC half **in flight as v1.62.7**; Who's Who half **scoped, not started** — see §A2 below |
| 2 | **Zombie Blood power-up** from Origins onto every map that can take it. Perfect or not at all. | not started |
| 3 | **Blood Money power-up** from Origins onto every map — and unlike Origins (dig sites) it must **drop from zombie kills** like a normal power-up | not started |
| 4 | **Semtex wall-buy** on Diner (shack wall to the left of the added Juggernog) and Bus Depot (next to the added Speed Cola) | not started |
| 5 | **Galvaknuckles wall-buy** in Bus Depot's Tombstone room, left wall as you come in the outside door | not started — supersedes §2.5, which said the same thing |

**Task 1, Who's Who half — decision taken 2026-08-09:** the user chose **remove Who's Who from
Buried entirely** rather than ship it there without the downed-body glow (Buried's `actor`
clientfield set is 32/32, re-measured today from `clientfields_zm_buried_zclassic_processing.txt`).
So Who's Who ships complete on **TranZit/Diner, Nuketown and Origins**, and is dropped on Buried.

🌟 **The working precedent is `BO2-Reimagined`**, which enables Who's Who on `zm_transit` in a
shipped mod — `_zm_reimagined.gsc:1997-2003` (server) and `_zm_reimagined.csc:85-97` (client).
Two assets have to be shipped in `mod.ff`, both **Die Rise-only** and both with an existing
precedent in this project: `material generic_filter_afterlife` (same shape as the already-shipped
`generic_filter_zombie_perk_vulture`) and `rawfile vision/zm_whos_who.vision` (same shape as the
already-shipped `vision/zm_electric_cherry.vision`).
🛑 `whoswhoaudio`/`whoswhofilter` live in **map-specific** `clientscripts\mp\zm_highrise_amb.csc`
and must NOT be named from a root client script (AI_CONTEXT rule 2) — write our own; they are 6
lines each and everything they call (`enable_filter_afterlife`, `chugabud_whos_who_shader`,
`chugabud_setup_afterlife_filters`) is **core** `_zm_perks.csc` and safe to reference.
📝 `level.chugabud_shellshock` is set **nowhere** in the 2,093-file stock dump, so the shellshock
never fires in stock either — not part of the genuine article, do not add it.

---

## 0aaa. ✅ DONE — CONFIRMED IN GAME 2026-08-09 — v1.62.6, the perk row fixed in the LUI itself

**User: "It seems to be fixed."** 12 perks, went down, the row no longer collapses into copies of
one icon. Full write-up: `MOD_CATALOGUE.md` §3d, `STOCK_REFERENCE.md` §4/§4b.

Fixes stock's `CoD.Perks.RemovePerkIcon` by reassigning that **one function** from
`ui_mp/t6/zombie/hudpowerupszombie.lua` (already a mod override) at the top of
`LUI.createMenu.PowerUpsArea`. Removal **order stops mattering**, so this covers the down,
`.removeperks`, `.remove<perk>` and the friend's Vulture spam in one change.

🛑 Deliberately **not** a whole-file replacement of `hudperkszombie.lua`: stock's `Update` has
`STATE_PAUSED`/`STATE_TBD` branches no readable source carries, and `STATE_PAUSED` is reachable
here (2-bit perk fields wherever `emp_grenade_zm` is included). Reproducing them would be a guess.

**Verified offline, each claim traceable:**
- parses as Lua 5.1 (`luaparse` via node — new capability, see `MOD_CATALOGUE.md` §9d)
- diffed against Reimagined's readable copy: **exactly two lines differ**, the `else` and the `nil`
- `RemovePerkIcon` is looked up at call time and is never captured by `registerEventHandler`
- stock `hud.lua` creates `PerksArea` **then** `PowerUpsArea`, adjacent lines — the hook cannot be
  too early
- the file provably loads from `mod.iwd`: `Loaded menu file:
  ui_mp/t6/zombie/hudpowerupszombie.lua` in the boot log, and it exists in no other search path
- deployed `mod.iwd` entry is byte-identical to source; only `mod.json` + that `.lua` changed,
  `mod.ff` untouched (no `build_ff.bat` needed)
- with any free slot the loop breaks before index 12, so the new branch **cannot** run in ordinary
  ≤11-perk play — no regression surface there

**TEST: get all 12 perks, then go down.** The row must NOT collapse into copies of one icon.
Probe if it still misbehaves: type `zmqol_lui_perkfix` in console — `1` means the patch installed
and the cause is elsewhere.

⚠️ Residual, stated not hidden: perks **retained** through a down (Tombstone / Who's Who /
afterlife) never write their clientfield to 0 (`_zm_perks.gsc:2166-2171`), so those icons legitimately
stay on the row. That is not this bug and is not corruption.

---

## 0A. 🔴 USER REPORT 2026-08-09 — three separate findings, all measured from ONE log

Boot: Diner survival, solo. Log = `console_zm.log` @ 03:35 (one boot, `loadmod: loaded mods/zm_qol`
appears once). Screenshot: **12 identical PhD icons after a down**, player revived, 75080 points.

### A. The down-with-12-perks case REPRODUCED — this is QUEUE §A1, and it was never claimed fixed

User got 12 perks, let a zombie kill them, row collapsed to 12 copies. **Exactly the case v1.62.2
and v1.62.5 both wrote down as NOT covered** (checkpoint 23 §2b: the revive paths clear every perk
field in one loop with no waits, so no script-visible order exists to correct). The user is right
that it is not the chat commands and not specifically PhD — it is whatever landed in slot 12.

🌟 **This confirms the only real fix is the LUI one-liner** (`else NextPerkWidget = nil` in
`CoD.Perks.RemovePerkIcon`). It fixes every variant at once: the down, `.removeperks`,
`.remove<perk>`, and the friend's Vulture Aid spam. **Ships alone** — a bad LUI file hard-crashes.

### B. 🌟 `.giveperks` is NOT broken — the input carried a stray `"`

User: *"the .giveperks command doesn't do anything at all"*. **Correct, and the cause is measurable.**
Every chat line in the log is clean except these two, which are the only ones with a trailing quote:

```
DavidHiFi^7: .giveperks"      <- typed twice, nothing happened either time
DavidHiFi^7: .removeperks     <- no quote, worked: "cleared 12 perk icon(s)"
```

`quality_of_life.gsc:2585` does `cmd = getsubstr( tokens[0], 1 )` and every handler is an **exact**
`cmd == "..."` compare, so `giveperks"` matches nothing and falls through the whole else-if chain
in silence. The `give<perk>` prefix branch below it also fails (`zmqol_perk_from_alias( "perks\"" )`
is undefined).

**Fix: strip quotes from the message before tokenising.** Cheap, and it makes every command
bind-proof — which is the same root as §0B below, because a bound `say` is where stray quotes come
from.

### C. 🔴 NEW DEFECT — v1.62.4's Vulture machine markers match NOTHING on Diner

```
[zm_qol] CLIENT vulture machines: 0 of 43 structs match 'zstandard_perks_diner'
```

**Zero of 43.** The wallbuy filter on the same boot succeeded with the sibling string
(`enable_wallbuys - zstandard_diner: tagged 2 of 2`), so the dvars are right and the **`_perks_`
infix is wrong** — the perk structs' `script_string` is evidently not `<gametype>_perks_<location>`
on this map. Dump the real values with `Unlinker --include-assets mapents` on `zm_transit` before
changing a character. Deployed-but-unverified since v1.62.4; now measured as broken.

## 0B. 🆕 STANDING INSTRUCTION 2026-08-09 — every command must also be a dvar / console command

**User:** *"from here on out make any and all of the chat commands available as console
commands/dvars or whatever that's called, therefore you could bind more stuff, i already got you to
make the `.fly` command a dvar just do the rest for all the commands"*

- **New commands ship with both routes.** Not optional, not a follow-up.
- **Existing commands get back-filled** — that is the work item.
- **The precedent is already in the mod:** `.fly` has `zmqol_fly_dvar_watch()`, and every `.fly`
  toggle also calls `setdvar( "fly", ... )` so the dvar never goes stale and the next poll cannot
  undo the toggle. Copy that two-way shape.
- Chat commands **stay**. This is an extra route, not a replacement.
- 📝 Converges with QUEUE §2.1 (pause-menu options UI). Three routes — chat, dvar, menu — should
  drive **one** implementation function per command, not three copies. Worth doing the refactor
  once, when this lands.

---

## 0aa. ✅ DONE — CONFIRMED IN GAME 2026-08-09 — v1.62.5, `.removeperks` clears the perk icons itself

**User booted Diner survival, solo, `.giveperks` then `.removeperks`. Screenshot: the perk row is
completely EMPTY, feed reads `gave 12 perk(s)` / `removed 12 perk(s)`.** No duplicate icon, no
leftover shader.

📝 One observation, not a defect: the centre-screen "PhD Flopper" perk pop-up was still on screen in
the shot. `.giveperks` fires 12 grants 0.1s apart and each pop-up runs for several seconds, so the
tail of that queue outlives the command. Ask the user if it ever failed to clear on its own before
treating it as anything.

<details><summary>the diagnosis and what shipped</summary>

**User, 2026-08-08 (second report):** the row still collapses to one icon
**sometimes** — the friend's run showed twelve **Vulture Aid**, not PhD. Their
instruction: *"make it so `.removeperks` … also makes sure to remove any and all
of the perk shaders on the hud, because that's what causes that bug."*

Correct diagnosis, and the reason v1.62.2 was not enough is measurable.

### Two defects v1.62.2's notify-ordering could not reach

1. **A notify is not a write.** `"<perk>_stop"` only wakes `perk_think`; the LUI
   reacts to `perk_think`'s `set_perk_clientfield( perk, 0 )` further down
   (`_zm_perks.gsc:2204`). `perk_think` **returns early, before that write**,
   when `self._retain_perks` / `_retain_perks_array[perk]` is set
   (`_zm_perks.gsc:2166-2171`) — the Tombstone / Who's Who / afterlife state. A
   retained perk keeps its icon regardless of removal order.
2. **Twelve writes in one frame have no order.** Clientfields ride one snapshot
   per server frame, so a batch landing in a single frame reaches the LUI in the
   engine's field order, not the script's.

### 🌟 The order source is now stock's own array, not a sampler

`zmqol_perk_slot_watcher()` sampled `hasperk()` every frame, so **two perks
arriving in one frame were appended in scan order** — and Who's Who's revive
(`_zm_chugabud.gsc:295-335`) and Mob's afterlife (`_zm_afterlife.gsc:1327-1345`)
both re-hand the whole loadout through `give_perk()` **in one loop with no
waits**. That is the "sometimes", and it matches *"he died with whos who"*.

`give_perk()` appends `self.perks_active` six lines after
`set_perk_clientfield( perk, 1 )` — same function, no wait between — and
give_perk is the **only** place in the stock dump that drives a perk field 0→1
(`_zm_perks.gsc:2688` is the unpause, on a perk the row already holds). So
`perks_active`' append order **is** the LUI's slot order. A same-frame batch is
now ranked by it.

🛑 **Only the appends are trusted.** `arrayremovevalue( self.perks_active, perk,
0 )`'s third parameter is undocumented — the stock dump has no definition (engine
builtin) and the GSC reference lists only the two-arg form — so whether it
preserves the survivors' order is **unknown**. Nothing depends on it: the ranking
only ever runs on perks appended at the tail moments earlier.

### What shipped

- **Phase 1** — write the clientfields to 0 **ourselves, last slot first, 0.1s
  apart** (the same spacing `.giveperks` uses, the spacing that produced the
  user's confirmed 12-distinct-icon screenshot).
- **Phase 2** — sweep every other perk this map registered. Safe in any order:
  stock's off-by-one needs the row **full**, and phase 1 already freed a slot.
- **Phase 3** — the functional teardown by notify, unchanged; paused perks are
  now notified too (their `perk_think` is still parked).

🛑 **No blind writes.** `set_perk_clientfield` is only called for perks in
`zmqol_map_perks()`, which reads the *same* flags and the *same*
`level._custom_perks` keys as the mod's own replaced `perks_register_clientfield`
(`quality_of_life.gsc:5627`). Independently proven in game: `.giveperks` already
writes all of these fields and all 12 icons appear.

Verified: parses; deployed `mod.iwd` byte-identical to source; both new
`_zm_perks::set_perk_clientfield` call sites confirmed inside the deployed file.

**Test: `.giveperks`, then `.removeperks`. The perk row must end up completely
empty.** New log line: `[zm_qol] removeperks: cleared N perk icon(s)
newest-first, swept M more`.

### ⚠️ Still not covered, and not claimed

- **Going down while holding all twelve.** Who's Who's revive and Mob's afterlife
  clear every perk field in **one frame**, so that batch has no script-visible
  order at all. Only the LUI fix (§A1) repairs it.
- **`.remove<perk>` on a full row** is the same defect, one perk at a time — the
  next item below.

</details>

## 0ab. QUEUED — `.remove<perk>` corrupts a full row too, and the fix is designed

`zmqol_remove_one_perk()` still just notifies. With all 12 held, removing
anything below slot 12 fires the same off-by-one. **The fix does not need to
change what the command does:** clear the newest perk's field, clear the
target's, then write the newest back to 1. `Update()` refills the first free
slot, which is where a correct removal would have left it — same final row, three
writes. Queued rather than shipped so v1.62.5 boots alone.

## 0a. NEXT TWO, both scoped and measured 2026-08-08 (friend's session)

**User's friend played the mod. Report:** PhD icons still spam; *"that bug happened
for him when he died with whos who"*; Who's Who has **no visual fx at all** while
its functionality works normally. User's read: *"it's for sure the chat commands
unless you're certain i'm wrong"*.

🛑 **CONFOUND, note before believing any of it:** the friend's screenshot shows
**Hells Vengeance v2 (AlexibuscusGaming)** — a third-party GSC menu with its own
Perks Menu — running alongside this mod. Any perk it grants or strips takes paths
this mod never sees. Ask for one clean repro without it before treating any
detail as this mod's.

### ⭐ A1. PhD icon spam — the chat commands are NOT the cause

**The user is half right and the half matters.** `.giveperks` creates the 12/12
condition, but the *removal* that corrupts the row is **the down**, not the
command. Evidence:

- `.giveperks` → `.removeperks` was fixed in v1.62.2 and **the user verified it
  themselves**: `tracked=12 held=12`, `clearing last slot first ->
  specialty_flakjacket`, and *"you seemed to have fixed phd with the perks
  commands"*.
- Their own report names the trigger: *"he died with whos who"*.
- A down fires `player_downed` (`_zm_laststand.gsc:215`, at the END of
  `playerlaststand`), every `perk_think` wakes at once and removes its perk **in
  stock's order** — a perk below slot 12 comes off first and the off-by-one fires.
- v1.62.2's commit and QUEUE entry both said in writing: *"Not covered: going
  down while holding all 12."* This is that exact case, reported back.

**So the only real fix is the LUI one-liner** — `else NextPerkWidget = nil` in
`CoD.Perks.RemovePerkIcon`.

#### 🌟 THE LUI BLOCKER IS NOW MOSTLY GONE — measured

The blocker was "Reimagined's copy is stock plus their changes, and stock's
`STATE_PAUSED`/`STATE_TBD` handling in `Update` would have to be reconstructed —
that is a guess." Two measurements shrink it to almost nothing:

1. **`STATE_TBD` (3) is dead.** Across the entire ZM dump the only values ever
   written to a perk clientfield are **0, 1 and 2** (`( perk, 0 )` ×5,
   `( perk, 1 )` ×4, `( perk, 2 )` ×2). Nothing to reconstruct.
2. **`STATE_PAUSED` (2) behaviour is known, not guessed.** Stock's bytecode
   string table carries `STATE_PAUSED` **and** `PausedAlpha`, so a paused perk is
   **dimmed in its slot**; Reimagined's `UpdatePerksPaused` implements exactly
   that visual per widget (pulse + `setAlpha(PausedAlpha)`, glow alpha 0) — it is
   only driven from a different signal.

**Remaining work:** base on Reimagined's readable file; restore stock's
`TopStart` (**-180 on DLC3 maps, -140 otherwise** — read from the bytecode);
add a `STATE_PAUSED` branch to `Update`; apply the one-line fix; confirm nothing
references a Reimagined-only clientfield this mod never registers.

🛑 **Ships ALONE.** `ui_mp/` overrides are whole-file replacements and a bad LUI
file hard-crashes the game.

### ⭐ A2. Who's Who has no visuals — fully mapped, and one map is blocked

`zmqol_enable_whoswho()` sets `level.zombiemode_using_chugabud_perk = 1` and the
client registers `perk_chugabud`. **That is the perk flag and the HUD icon —
nothing else.** Stock's `activate_chugabud_effects_and_audio()`
(`_zm_chugabud.gsc:745`) needs four more things, **every one gated on
`isdefined(...)`, so all of them fail silently**:

| what | stock source |
|---|---|
| `self shellshock( "whoswho", 60 )` | gated on `level.chugabud_shellshock` |
| `vsmgr_activate( "visionset", "zm_whos_who", self )` | gated on `level.vsmgr_prio_visionset_zm_whos_who`; server registers it in **core** `_zm_perks.gsc:1449` |
| `setclientfieldtoplayer( "clientfield_whos_who_audio", 1 )` | `zm_highrise.gsc:79` / `.csc:84` |
| `setclientfieldtoplayer( "clientfield_whos_who_filter", 1 )` | `zm_highrise.gsc:80` / `.csc:85` |
| `corpse setclientfield( "clientfield_whos_who_clone_glow_shader", 1 )` | `zm_highrise.gsc:78` / `.csc:83` (**actor**, 1 bit) |

Client also needs
`vsmgr_register_visionset_info( "zm_whos_who", 5000, 1, "zm_whos_who", "zm_whos_who" )`
(`zm_highrise.csc:86`).

🛑 **Two of stock's client callbacks are MAP-SPECIFIC** —
`clientscripts\mp\zm_highrise_amb::whoswhoaudio` and `::whoswhofilter`. Those
resolve at **load time**, so referencing them from the root client script would
crash every other map (AI_CONTEXT rule 2). We must write our own callbacks.
`_zm_perks::chugabud_whos_who_shader` is core and safe to reference.

#### 🛑 BURIED IS BLOCKED — measured, not assumed

Stock `actor`-set usage, summed from the per-map dumps in
`Black Ops 2 Grand Resources\…\Clientfields\`:

| map | actor bits | room for the 1-bit clone-glow field? |
|---|---|---|
| `zm_transit` | 5 / 32 | yes |
| `zm_prison` | 13 / 32 | n/a (Who's Who is native there? no — excluded, no asset) |
| `zm_tomb` | **31 / 32** | yes, exactly fills it — zero margin |
| `zm_buried` | **32 / 32** | ❌ **no — would overflow** |

Who's Who is enabled on `zm_transit`, `zm_nuked`, `zm_buried`, `zm_tomb`. The
clone-glow shader **cannot** be added on Buried. The screen filter and audio are
`toplayer` and are unaffected, so Buried could still get the screen fx the user
actually reported missing — but the downed-body glow would be absent there,
which is a per-map compromise and needs the user's call before shipping.

📝 The same dump independently reproduces the two numbers this project had
already verified the hard way — Origins `scriptmover` **32/32** and `actor`
**31/32** — so the parse is trustworthy for the `actor` set.

---

## 0a0. DONE (deployed) — v1.62.4, Vulture Aid's perk-machine markers

**User, 2026-08-08:** *"the wunderfizz machine, the perk machines, and the pack
a punch machine all have their fx missing"* — "half-assed", wants Vulture Aid
properly implemented on every map.

### 🌟 First: one third of the report is stock behaviour, not a bug

`vulture_vision_enable` gates each marker on
`perk == "specialty_weapupgrade" || perk == "specialty_nomotionsensor" || !self hasperk( lc, perk )`.
**A perk machine only glows while you do NOT own that perk.** The screenshot had
all 12 perks, so every machine was correctly suppressed. User chose to KEEP this
(asked, 2026-08-08). **Test with few or no perks, not after `.giveperks`.**

### The two real defects, measured

1. **Only one machine per perk type ever glowed.** `vulture_vision_init` does
   `perk_machines[ struct.script_noteworthy ] = struct` — keyed by PERK NAME.
   Buried has 8 structs / 8 distinct perks / one gametype, so Treyarch never saw
   it. **`zm_transit` authors 21 such structs — five Speed Cola and three
   Pack-a-Punch spots** across Diner/Town/Farm/Cornfield. 21 collapse to 8 and
   the survivor is whichever came last.
2. **`script_string` was ignored entirely** — the field naming the
   gametype+location a spot belongs to. So the survivor was frequently a machine
   that never spawned in your session. That is why nothing lit up at the Diner.

### What shipped

Stock's machine loop is **emptied** (`zmqol_vulture_after_connect` clears
`perk_machines` right after stock's `vulture_vision_init` fills it) and replaced
by ours, registered through stock's own published extension point
(`custom_funcs_enable/_disable`). Wallbuys, mystery box, powerups, zombie eyes
and the stink are untouched stock — they were never broken.

🛑 **Why empty rather than fix stock's list:** its key is used for three things
at once — the fx lookup, the `hasperk()` gate and the `fx_list_special` slot.
Re-keying it uniquely so five Speed Colas can coexist breaks the other two, and
every machine would glow even once owned.

- Filter mirrors stock's server-side `perk_machine_spawn_init`
  (`_zm_perks.gsc:2835-2861`) verbatim: `<gametype>_perks_<location>` tokenised
  on spaces, structs with no `script_string` kept. Reads the same two dvars the
  mod's proven `zmqol_wallbuy_match_string()` uses.
- Stock registers glow fx for only **8** perks. Tombstone, Deadshot, Who's Who,
  Electric Cherry and PhD fell through to stock's fallback — the **Speed Cola**
  glow, which actively lies. They now get the neutral "?"
  (`fx_zm_vulture_glow_question`). User's call, asked 2026-08-08.
  🛑 There is no Tombstone/Wunderfizz glow fx in BO2 and **new fx cannot be
  authored** — OAT dumps no `.efx`, so there is no round trip.
- Buying a perk takes its markers down: stock's
  `vulture_global_perk_client_callback` only knows its own one-per-perk fx, so
  ours wraps it and clears every marker we placed for that perk.

Verified: parses (`-i client`); `Loaded script "scripts/zm/zm_expanded.csc"
(src: disk)`; asset list identical, nothing re-owned; all four new symbols
confirmed inside the **deployed** `mod.ff`.

**Test: start a game, buy Vulture Aid FIRST with few other perks, and look
around.** Every machine for a perk you lack should be marked, plus PaP always.
New log line names the count: `[zm_qol] CLIENT vulture machines: N of M structs
match '<gametype>_perks_<location>'`.

### ❌ NOT DONE THIS ROUND — the Wunderfizz marker

Deliberately deferred, not forgotten. Its machines are placed **server-side at
runtime**: coordinates are hardcoded per map (`wunderfizz.gsc:554+`) but a
distance-and-clearance filter picks which survive (`placed 1 of 6 candidate
location(s)`). **The client cannot know which without a new channel**, and both
routes carry real risk:
- a new clientfield — Origins' `scriptmover` set is already 32/32, which is why
  the mod drops `vulture_perk_scriptmover` there. Would be a per-map compromise.
- replicating the placement filter client-side — drift puts a marker where no
  machine is.

Needs the bit budget measured before choosing. Next item after this is verified.

---

## 0a1. DONE (deployed) — v1.62.3, Vulture Aid's through-wall icons were shapeless

**User, 2026-08-08, with a screenshot:** the markers Vulture Aid shows through
walls (mystery box, perk machines, wall buys) are *"just a coloured sort of blur
effect, not the actual icons"*.

**Measured cause.** All 11 `fxt_zmb_*` icon textures shipped as IWI format
`0x02` — **RGB24, no alpha channel** (128×128×3 + 64 = 49216 bytes, exactly the
size on disk). An fx particle carries its silhouette in alpha, so the whole
128×128 quad drew as a solid colour: the blur.

🛑 **The `.dds` dump is the trap.** In `All .DDS Files for Zombies\`, those 11
declare `DDPF_RGB` with `Amask = 0x00000000` — while the 4th byte of every pixel
really does vary 0–255. **The alpha is in the bytes and missing from the
header.** ImageConverter believes the header and discards the shape. The `.png`
copies under `BO2 Files Organized By Volkz\...\Vulture Icons\` are intact, so
they are the source now.

Rebuilt via the project's own `png2dds.ps1` → `ImageConverter --t6` → format
`0x01` (ARGB32, alpha intact — already the most common format in this mod, 30 of
65 images). Alpha rendered out and eyeballed first, per the Tombstone lesson:
correct output is a shape mask (badge silhouette / crossed rifles / skull / "?"),
artwork in RGB.

`build_ff.bat` was mandatory — `mod.ff` held format-`0x02` headers, and header vs
pixel mismatch is the measured purple/green m1911 failure. All 11 relinked
`(src: disk)`; asset list identical at 3813 lines, nothing re-owned; `mod.ff`
`986a498b` → `c0f7371a`.

**Boot and look at a perk machine / the box through a wall with Vulture Aid.**
Icons should have their real shapes.

### ✅ The question-mark marker is covered too — earlier caveat RETRACTED

The user asked for `fxt_zmb_question_mark` to be added "so it's all fixed".
**It did not need adding, and adding it would have been a mistake.**

1. **The Linker resolves fx dependencies itself.** `mod_locations.zone` and
   `mod_base.zone` list **zero** `gfx_fxt_perk_*` materials and **zero**
   `fxt_zmb_*` images (`grep -c` → 0 in both), yet `mod.ff` carries all 11
   images and all 22 materials — they arrive purely as dependencies of the
   `fx,` lines. `fx,maps/zombie/fx_zm_vulture_glow_question` **is** listed
   (`mod_locations.zone:332`), links with 0 errors, and pulls in no
   question_mark. So the vulture "?" fx does not use it.
2. **In `zm_buried.ff` question_mark belongs to a different effect** — its
   image and material sit immediately before
   `fx, maps/zombie/fx_zmb_wall_buy_question`, Buried's own wall-buy marker,
   which `_zm_perk_vulture.csc` never loads.

What the vulture "?" actually draws is `fxt_zmb_perk_magic_box`, whose alpha is
a "?" and a hook (visible in the alpha contact sheet) — one of the 11 rebuilt
above. 📝 Adding question_mark would have made `mod.ff` **own** a Buried asset
it has no use for: the ownership trap that has broken maps here before.

---

## 0a2. ✅ DONE — v1.62.2, `.removeperks` no longer duplicates the PhD icon

**CONFIRMED by the user, 2026-08-08:** *"you seemed to have fixed phd with the
perks commands"* — screenshot shows all 12 icons distinct. Log matches the
prediction exactly:

```
[zm_qol] perk slots: tracked=12 held=12 total=12
[zm_qol] removeperks: clearing last slot first -> specialty_flakjacket
```

🛑 **Took two rounds. v1.62.1 tracked order inside our `give_perk` override and
measured `tracked=0` — that replaceFunc is NOT taking, even for `.giveperks`'
fully qualified call, and presumably never has (the override is byte-equivalent
to stock, so nothing ever noticed). v1.62.2 OBSERVES order with a watcher
instead and never looks at an acquisition path.** Details below.



**User, 2026-08-08, with a screenshot:** `.giveperks` then `.removeperks` strips
every perk's *effect* correctly but leaves the HUD showing **twelve PhD icons**.
User's theory: the chat command causes it. **Half right — it is the trigger, not
the defect.**

### The defect is stock's, and the condition is narrower than checkpoint 22 said

`CoD.Perks.RemovePerkIcon` (readable at
`BO2-Reimagined\ui_mp\t6\zombie\hudperkszombie.lua:170-207`) shifts every icon
down one slot on a removal. `NextPerkWidget` is a **function-local** (line 171),
but on the last index the `elseif` never reassigns it, so slot 12 points at
**itself**, copies itself, and never clears.

🌟 **The new finding that made a GSC fix possible:** it fires **only** when the
row is **12/12 full AND the removed perk sits below slot 12**. One free slot and
the loop reaches it and clears correctly — which is why stock never sees this
and why this mod does (no perk limit). Two consequences:
- removing the perk **in slot 12 is always safe** (fresh-nil local → clear path)
- once slot 12 is empty the row is not full, so **every later removal is safe**

So clearing the **newest** perk first is sufficient. `.removeperks` walked the
perk list front-to-back, i.e. slot 1 first — precisely the poisoned path.

### What shipped

- `give_perk()` now appends to `self.zmqol_perk_slots` beside
  `set_perk_clientfield( perk, 1 )` — the same write that makes the LUI append
  an icon to its first free slot, so the two arrays agree by construction.
  Re-acquired perks move to the end in both.
- `zmqol_perk_slot_order()` filters that on read (an **ordered** delete, which
  is exactly what the LUI's shift-down is). Paused perks are **included**:
  stock's bytecode string table carries `STATE_PAUSED` and `PausedAlpha`, so a
  paused perk is dimmed in its slot, not removed.
- `zmqol_remove_all_perks()` clears the newest perk first, then runs unchanged.

🛑 **Deliberately not load-bearing on the `give_perk` hook.** Machine purchases
reach `give_perk` via stock's `wait_give_perk` (`_zm_perks.gsc:1965`) —
unqualified, same-file, **synchronous**, the shape CLAUDE.md §4 failure mode 1
says cannot be hooked. Any held perk missing from the tracked list is appended
as a backstop, so the list stays complete either way.

### ⚠️ NOT COVERED, and not claimed

**Going down while holding all 12.** That teardown is stock's `player_downed`
notify in stock's order; no GSC ordering reaches it. The real repair is still
the one `else NextPerkWidget = nil` in the LUI — §0c.

### 📝 CORRECTION TO CLAUDE.md §4 — synchronous same-file calls ARE hookable

Reimagined replaceFuncs `give_perk` (`_zm_reimagined.gsc:126`), does **not**
define its own `wait_give_perk`, and its `give_perk` drops stock's drink blur —
visible on every machine purchase in a shipped, working mod. So the hook takes
through a synchronous unqualified same-file call, not just a threaded one.
Strong inference from a shipped mod, **not yet a direct measurement** — the new
log line settles it on the next boot:

```
[zm_qol] perk slots: tracked=N held=N total=N
[zm_qol] removeperks: clearing last slot first -> <perk> (of N held)
```

`tracked == held` proves the hook fires on every path.

**Test: `.giveperks`, then `.removeperks`. The perk row must empty completely.**

---

## 0. ALSO IN FLIGHT, STILL UNBOOTED — v1.62.0, solo play (PART 1 OF 3 shipped)

**User, 2026-08-08:** solo should be solo, not a custom game. Three parts:
(1) the solo **intro cutscene** on classic maps, (2) the menu header saying
**"CUSTOM GAMES"**, (3) **solo gameplay logic** — all Mob plane parts carried
at once. **Keep** instant start and Diner selection exactly as they are.

### ✅ PART 3 SHIPPED — the gameplay half

`qol_check_solo_status` tested `getnumexpectedplayers() == 1`. The engine
reports **0** on Mods-menu launches — this project had already measured that
and written it in `onallplayersready_instant`, but never connected it here. So
`level.is_forever_solo_game` was 0 while playing alone, and
`zm_alcatraz_craftables` gates `is_shared = 1` on all five plane pieces and
five fuel cans behind that flag. Now `<= 1`, in both maps' copies.

Origins looked fine only because its call site (`zm_tomb.gsc:290`) runs later
in the load than Mob's (`zm_prison.gsc:222`), so the count had resolved —
that is why its log said `expected=1`. The replaceFunc always took.

Log line now prints both counts:
`[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N`

📝 Stock's solo gate is **only** these two functions — every
`sessionmodeisonlinegame` / `sessionmodeisprivate` use in the stock dump was
checked; the rest are banking, weapon locker, achievements, leaderboards.

### ❌ PARTS 1 AND 2 NOT STARTED — and they are not GSC

🛑 **There is no cinematic code anywhere in the 2,093-file stock dump** —
grep for `cinematic` / `playbink` / `intro_movie` returns only
`scr_cinematic_autofocus` in `_art.gsc`. The intro plays from the **menu
system**, before the map loads. So no GSC hook can reach it.

Both parts trace to one root: **the mod launches through the private-game
(Custom Games) lobby.** `ui_mp\t6\zombie\selectmaplistzombie.lua`'s own header
says the map/mode pickers are "reachable from the private game lobby" — that
flow is exactly what gives us Diner selection and instant start, which the
user wants kept.

So the work is: keep the private-lobby flow, but make it *present and behave*
as Solo. Unknowns to settle before writing anything:
- where the "CUSTOM GAMES" title is set (not in either LUI file the mod
  ships; likely `patch_ui_zm.ff` or Plutonium's own compiled menus)
- what actually triggers the intro movie on the stock Solo path
- 🛑 `quality_of_life.gsc:6696` records that the lobby countdown lives in
  Plutonium's **compiled** `CoD.Lobby` module with no source found. The same
  may be true here — but `patch_ui_zm.ff` **is** dumpable
  (`Unlinker --include-assets rawfile`, CLAUDE.md §8), which the earlier
  session did not try.

**Next step: dump `patch_ui_zm.ff`'s 48 LUI files and find where the lobby
title and the Solo launch path live.** Same open blocker as the PhD fix — the
files are bytecode and need a decompiler to edit safely. **See §0e.**

---

## 0b. DONE — v1.61.3, Tombstone icon ✅ CONFIRMED
**User: "the tombstone icon looks perfect"**

**User, 2026-08-08, with a screenshot:** stock draws the Tombstone perk icon
with its badge frame **upside down relative to every other perk**. Reimagined
fixes it; import that.

🛑 **The literal request would have looked worse than stock.** The ask was
"flip it 180 degrees". Rotated and rendered out to check: the frame does line
up, but **"RIP" ends up upside down and the skull ends up at the bottom**.
Reimagined did not rotate the art — they re-composited it, frame down, text and
skull upright. **Their asset is what shipped.** Rendering the intermediate
before shipping is what caught this.

`zone_assets\images\specialty_tombstone_zombies.iwi` (64x64 DXT5, Reimagined's,
byte-identical). Same pipeline as the 62 `.iwi` already shipping — including
`specialty_vulture_zombies`, another perk HUD icon that works in game. No zone
edit needed: the material already pulled the image, and a raw file on the
search path makes the Linker compile from disk (`src: disk` in the link log).

🛑 It could **not** just be dropped in `images\` — `mod.ff` owned a **32x32**
header for it, and a loose `.iwi` read through a mismatched header renders
garbage (the measured purple/green m1911). The relink makes header and pixels
come from the same file.

Verified: asset list identical before/after (3813 lines, nothing re-owned);
`mod.ff` hash changed `dd18acf3` → `986a498b`; deployed `mod.iwd` carries the
file at 64x64 DXT5, SHA256-identical to Reimagined's.

📝 64x64 where its 11 neighbours are 32x32 — Reimagined's choice. Slightly
crisper. Downscale on request.

**Boot and look at the Tombstone icon.** Frame should point down like the
others, "RIP" upright, skull on top.

---

## 0c. DONE — v1.61.2, stock perk row restored ✅ CONFIRMED (user: "phd bug seems to be gone")

🛑 CAVEAT: stock's off-by-one is still in the Lua. It only fires after owning
ALL 12 perks and then losing them (.giveperks then a down). Dormant, not fixed.
The root cause and the one-line fix are recorded below.

**User, 2026-08-08:** *"you fucked up the icon size… made them too big, then
too small… the animation is still broken or slow. Revert it but just fix the
PHD being spammed on all the perk slots, that's all I wanted you to fix
originally but you went and changed a bunch of other stuff."*

Fair. v1.61.0 replaced the game's own perk row with a GSC-drawn one — that was
scope the user never asked for, and it cost the icon size and the pulse
animation. **v1.61.2 reverts both perk-HUD commits in full.** `mod.ff` rebuilt
SHA256-identical to `4854411:mod.ff`; 0 `zmqol_perk_hud` in the deployed
`mod.iwd`.

### 🌟 THE PhD ROOT CAUSE — FOUND, and checkpoint 21 §5 was WRONG

Checkpoint 21 concluded the row was drawn by "engine code bound by
`setupclientfieldcodecallbacks`" that "no GSC change can inspect or correct".
**That is false. The row is LUI**, and the file is readable:

| | |
|---|---|
| stock, compiled | `BO2-Raw-files\ui_mp\t6\zombie\hudperkszombie.lua` (Lua 5.1 bytecode) |
| readable source | `BO2-Reimagined\ui_mp\t6\zombie\hudperkszombie.lua` (405 lines, plain text) |

`setupclientfieldcodecallbacks` only makes the engine **dispatch a LUI event**
named after the clientfield. `CoD.Perks.Update` handles it.

**The bug is an off-by-one in `CoD.Perks.RemovePerkIcon`:**

```lua
for PerkIndex = OwnedPerkIndex, #CoD.Perks.ClientFieldNames, 1 do
    PerkWidget = Menu.perks[PerkIndex]
    if not PerkWidget.perkId then break
    elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
        NextPerkWidget = Menu.perks[PerkIndex + 1]
    end                       -- 🛑 no else - NextPerkWidget keeps slot 12
```

Removing a perk **shifts every icon down one slot**. On the last index there is
no next slot, so `NextPerkWidget` still points at slot 12 from the previous
iteration. Slot 12 then copies **itself** and `break`s without ever clearing.

- **Own ≤11 perks** (every stock map): slot 12 is empty, the loop hits
  `elseif not NextPerkWidget.perkId`, clears correctly. **Stock never sees this.**
- **Own all 12** (only this mod): slot 12 never clears. Each removal duplicates
  the tail, so removing all 12 collapses the row to twelve copies of one icon —
  and it is permanent, because with every `perkId` non-nil `Update` can never
  fill a slot again and `RemovePerkIcon` can never empty one.

Which icon? Whatever landed in slot 12 — the **last** perk acquired. The
v1.60 probe recorded `perk_dive_to_nuke registered exactly ONCE and LAST`
and filed it as an exoneration. It was the answer.

Matches the report exactly: `.giveperks` (fills all 12) → down (removes all 12)
→ every icon PhD, permanently.

### THE FIX — one `else` branch, in one LUI file

```lua
elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
    NextPerkWidget = Menu.perks[PerkIndex + 1]
else
    NextPerkWidget = nil          -- <- the whole fix
end
```

🛑 **BLOCKED ON ONE THING: there is no stock-faithful source for this file.**
LUI overrides in `ui_mp\` are **whole-file replacements** — the mod's three
existing ones are full stock copies (873 / 591 / 362 lines). Reimagined's copy
is stock **plus its own changes** (`SpecialtyToClientFieldNames`,
`UpdatePerksPaused`, `UpdatePerkOrder`, a hardcoded `TopStart`, and stock's
`STATE_PAUSED`/`STATE_TBD` handling removed from `Update`). Shipping it as-is
would silently import Reimagined's perk-pause behaviour.

**Decoded from the stock bytecode so far** (4-byte floats, offsets 1585-1650):

| constant | stock value | Reimagined |
|---|---|---|
| `TopStart` | **-180 on DLC3 maps, -140 otherwise** (two constants + an `IsDLCMap(CoD.DLC3Maps)` test) | -140, hardcoded |
| `IconSize` | 36 | 36 ✅ |
| `Spacing` | 8 | 8 ✅ |
| `STATE_NOTOWNED/OWNED/PAUSED/TBD` | 0 / 1 / 2 / 3 | same ✅ |

🛑 `STATE_PAUSED` **is reachable here** — the mod registers perk fields 2 bits
wide when `emp_grenade_zm` is included, and stock `zm_transit.gsc:1926` includes
it. So the pause path cannot just be dropped.

**Next step, before writing any Lua:** get a faithful stock decompile of
`hudperkszombie.lua` (a Lua 5.1 decompiler — unluac/luadec — on
`BO2-Raw-files\ui_mp\t6\zombie\hudperkszombie.lua`), or find whatever stock LUI
source produced this mod's existing `hudpowerupszombie.lua`. **Do not
hand-reconstruct `Update`'s paused branches from constant order — that is a
guess, and a bad LUI file hard-crashes the game.**

## 0e. 🛑 BLOCKER FOR BOTH LUI ITEMS — unluac is installed but CANNOT read T6 Lua

**User, 2026-08-08:** *"yeah go ahead and grab unluac no guesses though make sure it works"*.
Grabbed, verified genuine, verified running — and it **does not work on T6 files**. Said
plainly rather than reported as a win.

`H:Claudeunluac` — official SourceForge build `unluac_2025_12_23.jar`, v1.2.3.569,
SHA256 `98BE0FA8…538FCC`. Runs on the installed JRE 1.8.0_501.

**T6 ships a modified Lua 5.1. Four deviations, all measured, not guessed:**

| # | deviation | evidence |
|---|---|---|
| 1 | header **format byte = 13**, not 0 | unluac throws `non-standard lua format: 13`; `--luaj` does not bypass |
| 2 | a **type table** follows the header, ending at offset 242 | parsed cleanly: `[2b][int32 count=13][4b]` then 13 x `[int32 len][name+NUL][int32 id]` |
| 3 | constant type ids **shifted +1** | TNIL=1, TBOOLEAN=2, TNUMBER=4, TSTRING=5 (stock: 0/1/3/4); adds TIFUNCTION/TCFUNCTION/TUI64/TSTRUCT |
| 4 | numbers are **4-byte floats**, not doubles | header says Number size 4; independently confirmed decoding `IconSize`=36.0f, `Spacing`=8.0f from hudperkszombie |

Stripping the header gets further but not far enough — at the correct offset (246) unluac
reaches the constant pool and dies on `Illegal number`, i.e. deviation 4, with 3 behind it.

**Two routes, both real work:**
- **A (recommended)** — install a JDK (none on this machine, `javac` absent), patch unluac
  for the four deviations, rebuild. Few and well understood.
- **B** — write a full T6→standard-5.1 bytecode transcoder. No downloads, more code, more
  ways to be subtly wrong.

🌟 **Ground truth for verifying either:** the mod's own
`ui_mp	6zombiehudpowerupszombie.lua` is a known-good 591-line decompile of a stock
file that works in game. A correct decompiler must reproduce it.

Full write-up: `H:ClaudeunluacREADME_T6.md`.

---

## 0f. NEXT UP, in the order the user raised them

1. **Solo behaves like a custom game** — no intro cutscene on classic maps,
   and the menu header reads "CUSTOM GAMES". Asked for twice. Only the map
   list (Diner survival) and instant-start should differ from stock solo.
2. **God mode drops after Mob's afterlife** — `.god` still reads ON but the
   player can die. Must survive afterlife in/out. Also confirm death barriers
   behave normally when god is OFF and the player is not flying.
3. ✅ **Mob Wunderfizz overlaps the shield part spawn** — DONE v1.65.5, deployed,
   not yet booted. The docks machine was **11.5 units** from the
   `alcatraz_shield_zm_dolly` struct at `(-831.73, 5587.2, -71.75)`; moved 57
   units west to `(-900, 5585, -72)`, separation now 68.3. Checked ALL six Mob
   machines against ALL ten `alcatraz_shield_zm_*` structs from the mapents dump —
   that was the only pair under 400 units, and there is none under 60 now. It only
   showed up on the games that rolled that one of the three dolly spawns.
4. **Custom texture packs conflict** — `mod.ff` declares 776 header-only
   images and loads before the map, so a player's own `.iwi` is read through
   our header (a tester's m1911 rendered purple/green). 🛑 The v1.59.7
   attempt - rewriting `image,<name>` to `image,,<name>` - FAILED and broke
   textures on two maps; OAT produced an asset literally named `,<name>`.
   Needs a different approach entirely.
5. **Stray 254 MB `cmn_root.all.sabl`** in `build\zm_qol\` — not one of the 6
   mod files. Do not zip it to anyone.

---

## 1. DONE — Origins Wunderfizz replacement (shipped v1.58.x, confirmed)

**User, 2026-08-07:** replace Origins' native Wunderfizz machines with the mod's, keeping the
generator-power gating per location and the moving-location behaviour. "Make it seamlessly
replace the origins ones."

🛑 **This reverses an earlier instruction** recorded in `wunderfizz.gsc` ("NO ADDED MACHINE ON
ORIGINS. User, twice: get rid of them, keep the vanilla ones"). The user has been told; proceed.

### 🌟 THE BLOCKER IS DEAD — measured 2026-08-07

The queue said Origins' `scriptmover` set is 32/32 full, and it is (22 fields, 32 bits, from
`clientfields_zm_tomb_zclassic_tomb.txt`). **That only blocks REGISTERING a new field.** Origins
already registers the six the Wunderfizz needs, in `_zm_perk_random.gsc::init()`:

| field | bits |
|---|---|
| `perk_bottle_cycle_state` | 2 |
| `turn_active_perk_light_red` / `_green` | 1 + 1 |
| `turn_on_location_indicator` | 1 |
| `turn_active_perk_ball_light` | 1 |
| `zone_captured` | 1 |

**Drive those instead of registering `clientfield_perk_intro_fx`, and the wall is gone.**

### 🛑 CORRECTION — the above worried about the wrong thing entirely

**`wunderfizz.gsc` makes ZERO `setclientfield` calls** (`grep -c` → 0). It avoids clientfields on
purpose — see its BALL SPIN + EFFECTS note: five registrations from a root script on six maps is
the fastest route to `EXE_CLIENT_FIELD_MISMATCH`, so the fx are spawned server-side with
`playfx`/`playfxontag` instead.

**So the mod's machine needs no registration at all, and Origins' 32/32 wall does not apply to
it.** The wall only ever blocked driving the *native* machine. Strip-and-replace is the cheap path,
not the expensive one.

### THE PLAN — user's design, 2026-08-07

User: *"whenever you tried to modify the vanilla origins wunderfizz machines you just made them
super buggy — duplicate perk bottles for ones i already owned, perk bottles jumping off to the
left. Why not just strip them from origins entirely, then add the wunderfizz machines that you've
added to other maps… so all wunderfizz machines on any map look the same and give all 12 perks."*

Correct call. The mod's machine already carries relocation (`chooseLocation` /
`currentWunderfizzLocation`), ball behaviour and all 12 perks. Only generator gating is
Origins-specific.

1. **Suppress the native machines** — but 🛑 **DO NOT touch `_zm_perk_random::init()`**. Its six
   `registerclientfield` calls must keep running or the server/client register lists diverge and
   every player eats `EXE_CLIENT_FIELD_MISMATCH`. Suppress `init_machines()` / `machines_setup()`
   and hide the entities instead; leave registration alone.
2. **Place the mod's machines at the native locations** — read them at runtime from
   `getentarray( "random_perk_machine", "targetname" )` (origin + angles) and feed `zmqol_wf_add`.
   Exact, and nothing is guessed or hardcoded.
3. **Generator gating** — the native entities stay alive (hidden, no unitrigger), so
   `zm_tomb_capture_zones.gsc::enable_random_perk_machines_in_zone()` /
   `disable_…()` keep setting `.is_locked` on them exactly as stock does. The mod's machine at each
   location reads its paired native entity's `.is_locked`. **Stock's own capture logic drives the
   gating with no reimplementation.**
4. **Ball / relocation** — already the mod's own; verify the two relocation systems do not both run.

📝 Stock `get_perk_weapon_model()` falls back to `level._custom_perks[perk].perk_bottle`, so custom
bottles were supported natively — that was never the bug the user hit.

---

## 1b. PREVIOUS IN FLIGHT — REVERTED, closed

### Diner fog — **REVERTED at v1.57.7**
User: *"still didn't move... forget it for now, just turn the fog back off entirely."* Both files
restored byte-identical to `d7cb7db` (pre-fog). `r_fog 0` is forced again and `.fog` is gone.
What was learned stands: fog **distance** cannot be changed on this build, and the ring did spawn
correctly (12/12) — it just never looked right. **Do not re-open.**

### Texture pack — **REMOVED at v1.57.7**
2,788 `.iwi` deleted, `mod.iwd` 2,210 MB → 53.9 MB. The mod's own 64 images kept (git-tracked was
the keep-list). Pack still at `H:\Claude\Projects Sources\add textures to mod`. The user loads
textures from `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead. README corrected.

<details><summary>old entry, superseded</summary>

### Diner fog: default OFF + ring stacked two rows high — **v1.57.6**

**Confirmed working already (2026-08-07 boot):** the ring spawns —
`[zm_qol] fog ring: 12 of 12 fog walls spawned around diner`.

Two defects the user's screenshot exposed, both fixed here:

1. **Default was fog ON.** Mode 1 ("pushed back") was the default and is a proven no-op —
   checkpoint 20 §2: fog *distance* cannot be changed on this build, only `r_fog` on/off. So every
   game started on stock fog and the user typed `.fog off` by hand. **Default is now 0 = off.**
   `.fog <number>` no longer claims to have moved anything.
2. **The ring was too short.** 600-tall walls at the boundary hid what sat just past the edge, but
   the distant hillside rose over the top. **Second row stacked at +500 → 24 walls, ~1100 tall.**
   Ring distance deliberately unchanged (user's choice: "raise them where they are").

**What to check:** boot Diner. Fog should be **off from the start with no command typed**, and the
cloud bank should now be tall enough to cover the hillside rather than sitting under it.

**The new log line reports both rows:** `fog ring: 24 of 24 ... (12 per row, 2 rows)`.

Verified offline: both files parse; deployed `mod.iwd` byte-identical to source; vector add and
vector indexing confirmed as stock GSC idioms; stock TranZit already places 587 createfx effects.

Never verified: whether `spawnfx` anchors the effect at its centre or its base.

</details>

---

## 2. QUEUED — in order, not started

1. **Pause-menu UI** — port the Strat Tester options menu (`H:\Claude\Strat-Tester-BO2`), header
   renamed **"Quality Of Life"**, exposing every existing chat command **plus** ones missing from
   the menu (infinite sprint, etc). Chat commands stay. Scoped already: `optionsstrattester.lua`
   881 lines, `options.lua` 560, `menu.gsc` 73; no LUI conflict with this mod's `ui_mp\`.
   🛑 A bad LUI file hard-crashes the game — this one ships alone.
2. **`night_mode 1` is broken** — the screen goes fully black (screenshot 2026-08-06). Came in from
   another script. Either fix it properly or remove it.
3. **`character` command does nothing** — no visible effect at all.
4. ~~Origins Wunderfizz replacement~~ — **moved to §1, in flight.**
5. **Galvaknuckles wallbuy on Bus Depot** — in the Tombstone room. Town, Farm and Diner already
   have one; Bus Depot does not. 🛑 Survival **only** — must NOT appear on TranZit proper, where
   the Diner wallbuy already covers it. Same `!is_classic()` gating as the other survival edits.
6. **Vulture Aid icon on the Wunderfizz** — the machine's perk icon set is missing Vulture.
7. **No prone points at Mob's Electric Cherry machine** — the +100 prone bonus does not fire there.
   Every other machine works, so this is likely a missing `vending_` tag for that machine.
8. **Solo must not behave like a custom game** — two parts:
   - a. Origins first-generator reward chest still gives Zombie Blood instead of double points, on
     the classic maps. NOTE: `qol_check_solo_status` shipped in v1.55.0 and the probe printed
     `expected=1 is_forever_solo_game=1`, so **re-verify before changing anything** — the flag is
     set, so if the chest is still wrong the cause is downstream of it.
   - b. The solo **intro cutscene** does not play — you get the custom-games loading screen instead.
9. **Death Machine pickup voice line** — the BO1 "Death Machine" announcer callout on pickup.
10. **Nuketown perk-machine placement** — Deadshot's icon lands at an angle, Speed Cola drops half
    into the ground in the back yard. Not diagnosed yet.
11. **Diner teddy bears** — the 3-bear secret-song easter egg on Diner survival (garage, diner,
    Juggernog room). **Blocked:** needs three `.where` readings from the user; coordinates will not
    be guessed.
12. **zm_refreshed weapon ports** — MP7 + Vector to all maps, Dragunov + Spas-12 to Nuketown and
    Mob, MGL to Mob, Remington transferable via fridge, B4KED's fixed Jetgun, **Quick Revive on
    Mob** (confirmed absent; `specialty_quickrevive_zombies` is in no zombies fastfile, so it needs
    shipping). ~400 assets into `mod.ff` — do these **one weapon at a time** with an ownership
    audit after each.

---

## 3. PARKED — known-open, not currently requested

- **T5 wonder weapons** (Thundergun / Wunderwaffe / Winter's Howl). Reverted at v1.56.x after three
  byte-identical crashes: `0x80000003` at `0x129F75DB`, an engine assert with no script or asset
  error. Every asset class was checked and resolved. Leading unproven theory: a hard engine ceiling
  — the creators ship **one weapon per mod**, never all three. Work is in git (`bb44073`,
  `0084881`) and reappliable.
- **Vulture on Origins is a compromise** — ships with `vulture_perk_actor` and
  `vulture_perk_scriptmover` dropped, so the stink pile is invisible there (its entity is a bare
  `tag_origin`). Under "perfectly or not at all" this should be revisited: either revert Vulture on
  Origins or free the bits.
- **Origins generator ring** — the v1.55.2 intro-hold change was shipped as a falsifiable test and
  has never been booted. The probe logs objective index / contested state / players-in-zone.
- **Who's Who damage path** — the pointer is fine (probe confirmed). Remaining lead is
  `zm_tomb_tank::tank_ran_me_over` doing `disableinvulnerability()` then `dodamage(health+1000)`,
  which is also the best lead for `.god` dropping out.
- **`.hud` toggles** — `.hud` off/on plus `.hudtimer` / `.hudhealth` / `.hudcounters`. Dvars exist.

---

## 4. DONE — verified in-game by the user

| version | change |
|---|---|
| v1.56.4 | **Wunderfizz: Origins' real FX + bear bottle on every map** — user: *"looks perfect, works perfect, basically identical to the actual wunderfizz in origins"* |
| v1.56.2 | **Tombstone on Nuketown** — all 12 perks confirmed |
| v1.55.x | **Who's Who** confirmed working |
| v1.54.1 | Origins generator progress bar reported fixed |
| — | **Every classic and survival map loads** — confirmed 2026-08-06 |

---

## 0g. 🌟 THE LUI BLOCKER IS MOSTLY DEAD — Reimagined ships readable source

**2026-08-08, after the unluac attempt.** Patching unluac turned out to be far bigger than
"four header deviations": splicing the header and trying **every** offset from 236 to 274
still fails (`Illegal number`, `unmapped type code 146`), so T6's **function and constant
encoding deviate too**, not just the header. Patching it = reverse-engineering Treyarch's Lua
fork, not a small change.

**And it is very likely unnecessary.** `H:\Claude\BO2-Reimagined\` ships **35 LUI files as
plain readable source**, covering both blocked items:

| file | lines | covers |
|---|---|---|
| `ui\t6\menus\privateonlinegamelobby.lua` | 112 | 🌟 **line 10 is `Engine.Localize("MPUI_CUSTOM_GAMES_CAPS")`, passed to `addTitle` on line 16 — this IS the "CUSTOM GAMES" header** |
| `ui_mp\t6\hud\loading.lua` | ~580 | the loading screen (the "stock art while loading" complaint) |
| `ui_mp\t6\zombie\hudperkszombie.lua` | 405 | the perk row with the PhD off-by-one |
| `ui_mp\t6\menus\privategamelobby_project.lua` | — | lobby buttons; **this mod already ships its own copy** |

🛑 **They are stock PLUS Reimagined's own changes** — reconcile against stock before shipping,
do not paste blind. Stock constants are readable straight out of the bytecode without any
decompiler; that is how stock's `TopStart` (-180 DLC3 / -140 otherwise), `IconSize` 36 and
`Spacing` 8 were recovered.

**unluac stays at `H:\Claude\unluac\`** (jar + official hg source + findings) in case a file
turns up that Reimagined does not carry. See `H:\Claude\unluac\README_T6.md`.

### Next concrete step
Reconcile `privateonlinegamelobby.lua` against stock and change the title — **it ships alone**,
because a bad LUI file hard-crashes the game.

---

## 🟡 v1.76.0 — FOUR MORE, 2026-08-12. DEPLOYED, NOT YET BOOTED.

> *"add a command to change the round .round (number) chat command, also don't show the zombie
> spawn on the chat or whatever, also the effects for the winters howl stop working sometimes like
> when i was spam shooting it… Also, the 3 ported wonder weapons still don't have pap camos"*

| item | state |
|---|---|
| `.round <n>` chat command + `set_round` dvar | ✅ built |
| stranded probe no longer draws on screen | ✅ built — `println` only now |
| **PaP camos — REAL cause found, v1.75.0's fix was necessary but not sufficient** | ✅ built |
| Winter's Howl fx dropping under rapid fire | 🛑 **NOT ROOT-CAUSED — nothing shipped** |

### 🌟 THE PaP CAMO CAUSE — a missing SLOT, not a missing field

v1.75.0 filled the empty `camo` field on the three `*_upgraded_zm` defs. Necessary, but the guns
still Packed to stock skin, because the camo **assets themselves** were incomplete.

`_zm_weapons::get_pack_a_punch_weapon_options()` picks a camo **index**:
`camo_index = 39`, except `zm_prison` → 40 and `zm_tomb` → 45 (`:2286-2291`), fed to
`calcweaponoptions()`. Dumping all 50 camo assets out of the built `mod.ff` shows every stock camo
carries entries at exactly slots **{3, 8, 12}** — `camo_mp40` carries *only* those three — matching
the three ZM camo indices one-for-one. **The three ported camos carried {0, 8, 12}: slot 3, the
TranZit/Die Rise/Buried/Nuketown case, was missing entirely.** So the guns had a camo on MotD and
Origins and nothing anywhere else — and Origins has them gated off.

Fixed by adding slot 3 to all three, shape copied verbatim from stock `camo_mp40`'s slot 3
(`shaderConsts [3,3,0,…]`, `useNormalMap true`, cycling
`mtl_weapon_camo_zombies` / `_1` / `_2`). **No new assets were needed** — those materials and their
images were already in `mod.ff`. Needs `build_ff.bat`; link was 0 errors and the rebuilt asset was
dumped back out and confirmed to carry slot 3.

📝 `mtl_weapon_camo_packapunch` sits at slot 0 on thundergun/freezegun and is referenced by **no
stock camo asset at all** — a red herring from whoever authored them. Left alone; slot 0 is not
what ZM asks for.

### 🛑 WINTER'S HOWL fx UNDER RAPID FIRE — deliberately NOT fixed

No guess shipped. What was checked and cleared:

1. **Not the v1.74.1 leak** — that fix is present and correct.
2. **Not a shared-scratch race.** `level.freezegun_enemies` is level-scoped and `freezegun_fired()`
   is threaded, which looked like the answer — but the function contains no `wait` anywhere on that
   path (`freezegun_get_enemies_in_range()` is straight-line), so it runs to completion atomically
   and two shots cannot interleave.
3. **Not a divergence from the port.** Diffed both `.gsc` and `.csc` against the shipped working
   `Wonder_Weapons-T6ZM` build: the only differences are this mod's map gates and the v1.74.1 leak
   fix.

Leading hypothesis, **unverified**: engine fx-pool exhaustion — every shot spawns a
`freezegun_smoke_cloud` world fx on top of the per-zombie looping tag fx, and T6 silently drops
`playfx` calls once the pool is full.

**THE ONE OBSERVATION THAT SPLITS IT** — ask the user next time it happens:
*when the freeze fx stops, does the muzzle/smoke puff at the barrel stop too, or is it only the
frost on the zombies?*
- **both stop** → engine fx budget, and the fix is to throttle/shrink what each shot spawns.
- **only the zombies** → script-side clientfield/handle state, and it is fixable in the `.csc`.

---

## 🟡 ALL FIVE BUILT IN v1.75.0 — DEPLOYED, NOT YET BOOTED (2026-08-12)

**The user explicitly overrode the one-at-a-time rule** ("fix all from the prompt from the
previous session, 1-5"), so all five ship in one build. What that costs is attribution: if this
boot fails, five changes are in flight at once. They touch four independent subsystems (magic
box / AI spawn probe / HUD / weapon defs), so a failure should still be nameable.

| # | item | what shipped | confidence |
|---|---|---|---|
| 1 | Wunderwaffe box drop | **NOT A BUG** — measured symmetric. Shipped a deliberate, bounded pity weighting on Treyarch's own live hook | mechanism verified, effect unverified |
| 2 | stranded zombie | **CAUSE NOT FOUND OFFLINE** — shipped a probe that names the spawner in one boot | probe logic verified |
| 3 | "stray Vulture Aid icon" | **SAME ELEMENT AS #4** — it was `shield_hud()`'s icon drawn with the `damage_feedback` shader | root cause verified |
| 4 | shield bar restack | white bar, dimensions copied from the player bar, y derived from measurement | verified offline |
| 5 | PaP camos | the 3 camo assets were **already in `mod.ff`**; the weapon defs' `camo` field was simply empty | verified in the deployed files |

### 🛑 #1 — THERE WAS NO BUG, AND THAT IS MEASURED

All three guns register identically; the 23:32 boot log shows `Loaded weapon:` and a
`GSC Executed ...::init()` for each with no script error; and **the user pulled two of the three
FROM THE BOX in that same game**. The mod's `_zm_magicbox.gsc` strips the three stock filters, so
selection is a uniform draw over 26 in-box weapons (23 TranZit + 3). A specific gun is 3.8% per
spin; missing it across ~40 spins is **21%** — one game in five looks exactly like this.

What shipped is therefore a **deliberate weighting**, not a fix: `zmqol_box_wonder_weight` (default
2, `0` = stock) adds entries for an unheld wonder weapon from round 10, via
`level.customrandomweaponweights` — the hook Buried itself uses and which this mod's magicbox
override deliberately kept. 📝 `level.weapon_weighting_funcs` is written at `_zm_weapons.gsc:704`
and **read nowhere in the stock dump**, so stock's own `default_tesla_weighting_func()` pity timer
has never run in T6.

### 🛑 #2 — WHAT WAS RULED OUT, so nobody re-treads it

1. Not one of the 8 already-disabled spawners — all 8 origins matched against the mapents dump, and
   `[zm_qol] diner main: DONE` prints AFTER the disable pass, so it completed.
2. Nothing re-enables them: `reinit_zone_spawners()` does force `is_enabled = 1` (`:357-360`) but is
   **called nowhere in the 2,093-file dump**; `zone_init()` early-returns on an existing zone.
3. **No enabled regular spawner is near the reported spot.** Nearest enabled is `(-5718,-7272,-64)`,
   555 units away; nearest of any kind is the already-disabled `(-6462,-7159,-64)` at 198 units.
4. Not the undefined-entrance-node path at `_zm_spawner.gsc:411-425` — `should_skip_teardown()`
   returns true for `"find_flesh"` at `:330`, so the `:383` branch returns at `:409` first.

So the zombie is probably standing where it was **blocked**, not where it spawned.
`zmqol_stranded_probe` (default on) prints its `spawn_point` — assigned in exactly one place in
stock, `_zm_spawner.gsc:2674` — to console and screen after 15s without moving 64 units, only when
≤3 enemies are alive. **One boot names the spawner; the fix is then the same one-line origin match
the other 8 use.**

### 📝 A stale comment found in passing, NOT changed

`teslagun.gsc:21`, `thundergun.gsc:20` and `freeze.gsc:20` all claim *"DEFAULT IS OFF… a normal
launch loads the mod with no wonder weapon code running at all."* **That is wrong.** The gate is
`if ( str_ww != "" && str_ww != "1" && str_ww != "N" ) return;` — unset makes `str_ww != ""` false,
so the guard never fires and the guns are **ON by default**, which is what the boot log shows and
what the user experiences. Left alone deliberately: it is three files outside this change's scope
and the behaviour is correct, only the prose is not.

---

## 🔴 ORIGINAL REQUEST — FIVE ITEMS FROM THE ROUND-32 LEGIT GAME (all now built, see above)

Wonder weapons confirmed working: all three from the box, correct names, correct
weapon count, Winter's Howl frost fx now persist (v1.74.1 confirmed in game).
Listed in the order they were taken.

### 1. 🐛 WUNDERWAFFE NEVER CAME OUT OF THE BOX — round 32, legit game

User got Winter's Howl and the Thundergun but never the DG-2.

📝 **Registration is NOT the cause and that is measured** — all three are identical:
`include_weapon`, `add_limited_weapon( x, 1 )`, `add_zombie_weapon( ..., 10, ... )`,
same weight, same limit (`thundergun.gsc:36-38`, `teslagun.gsc:45-47`,
`freeze.gsc:36-38`). So the next place to look is the box's own exclusion logic:
`_zm_magicbox.gsc` — this mod already ships its own copy at
`maps\mp\zombies\_zm_magicbox.gsc`, so **diff that against stock first**. Check
`treasure_chest_weapon_is_limited`/limited-weapon accounting and whether
`tesla_gun_zm` is being counted as already-taken.

### 2. 🐛 A SPAWN POINT NEAR THE DINER STRANDS THE LAST ZOMBIE OF A ROUND

User's `.where` looking straight at it: **x -6269 y -7206 z -63 yaw 236** (the ground
behind the car, outside). The zombie spawns and stands there without pathing in until
it despawns and re-spawns elsewhere.

This is the SAME CLASS as the boarded-window bug fixed in v1.63.1 — a spawner whose
zone/path setup is wrong. Method that worked there: `Unlinker --include-assets mapents
zm_transit.ff`, find the spawner nearest that origin, read its `script_string` /
`script_noteworthy`, and check it against `disable_zombie_spawn_locations()` in
`zm_transit_loc_diner.gsc`, which already suppresses four problem spawners.

### 3. 🎨 VULTURE AID VISUAL BUG

Screenshot: a stray green Vulture-Aid shield icon drawn low-centre, near the perk row
but detached from it. Looks like an orphaned HUD element or a world icon rendering at
the wrong depth. Start from the mod's Vulture work in
`maps\mp\zombies\_zm_perk_vulture.gsc` / `.csc`.

### 4. 🖥️ SHIELD HEALTH BAR — restack it

> *"move the sheild health counter as another white health bar above the player health
> bar, stacked on top fitting perfectly and the same height and length, literally a
> duplicate bar but white and for the shield not the player."*

Same width and height as the player bar, directly above it, white. The player bar's
own definition is the spec to copy - do not hand-tune dimensions.

### 5. 🎨 PACK-A-PUNCH CAMOS FOR THE THREE WONDER WEAPONS

They Pack fine but keep their base skin. The upgraded weapon defs
(`weapons\zm\*_upgraded_zm`) need the PaP camo applied the way stock upgraded weapons
get theirs. 📝 The pro7 donor `mod.ff` carries **2 `camo` assets** — check those first,
they may already be exactly this.

---

## 📥 QUEUED 2026-08-12 — 15 MP/CAMPAIGN WEAPONS INTO THE BOX (`multiplayer&campaignweaponstozombieslist.txt`)

> *"add the rest of the weapons from multiplayer into zombies into the box… Only add the ones in
> this list that are already apart of existing mods in your workspace (If in order to add any of the
> listed weapons you'd need to do it fresh then don't bother)… i know the bo2 reimagined mod has
> some of these… but some of them replace existing weapons, i want to keep the original weapons but
> just add these new ones to the box… keep the games limitations in mind per map."*

**QUEUED behind v1.76.0's boot. Nothing built. Scoping below is complete and every line is measured.**

### 🌟 THE PIPELINE ALREADY EXISTS — this is an extension, not new machinery

`zm_qol\weapons\` holds **85 full weapon defs** (~21 KB each) plus 6 wonder-weapon defs in
`weapons\zm\`, and the built `mod.ff` carries **99 `weapon` assets**. The mod already ports weapons
across maps through `added_weapons()` in each per-map script (`zm_buried.gsc:79-168` is the model).
📝 An early read of this said "only 6 weapon defs" — that listed `weapons\zm\` and missed the 85 in
`weapons\` root. Corrected.

### THE VERDICT ON ALL 15 — measured, not assumed

**Method:** `Unlinker --list` over all 13 zombies fastfiles → **235 distinct ZM `weapon` assets**;
the same over the built `mod.ff`; then a whole-workspace filename search for the gaps.

| # | user's name | real internal name | verdict |
|---|---|---|---|
| 13 | M16 | `m16_zm` | ✅ **ALREADY SHIPPED** — in `mod.ff`, and `include_weapon("m16_zm")` (in_box defaults to 1) on Mob + Origins |
| 16 | Dragunov | — | ❌ **no such BO2 weapon.** Nearest is the SVU-AS (`svu_zm`), which the mod already ships and boxes |
| 5 | XPR-50 | `xpr50` | ❌ **exists in NO workspace mod** → out by the user's own rule |
| 12 | TAC-45 | `tac45` | ❌ same |
| 1 | SWAT-556 | 🛑 **`sig556_zm`**, NOT `xm8_zm` | 🟡 portable — Reimagined has base + upgraded |
| 2 | FAL-OSW | 🛑 **`sa58_zm`**, NOT `fnfal_zm` | 🟡 portable |
| 3 | MK 48 | `mk48_zm` | 🟡 portable |
| 4 | QBB LSW | `qbb95_zm` | 🟡 portable |
| 6 | MP7 | `mp7_zm` | 🟡 portable |
| 7 | Vector K10 | `vector_zm` + `vector_extclip_zm` | 🟡 portable |
| 8 | MSMC | `insas_zm` | 🟡 portable |
| 14 | Peacekeeper | `peacekeeper_zm` | 🟡 portable |
| 11 | Crossbow | `crossbow_zm` + `crossbow_explosive_bolt_zm` | 🟡 portable |
| 15 | Titus-6 | `titus6_zm` + `titus6_explosive_dart_zm` | 🟡 portable |
| 9 | Bouncing Betty | `bouncingbetty_zm` | ⚠️ portable but it is **equipment, not a box gun** — needs the user's call |

**So: 10 box weapons + Bouncing Betty are in scope. 4 of the 15 are already done or impossible.**

### 🛑 TWO NAME TRAPS THAT WOULD HAVE SHIPPED THE WRONG GUN

Both were caught by dumping the real defs out of `zm_transit.ff`, not by recall.

1. **SWAT-556 is `sig556`, not `xm8`.** `xm8_zm` is the **M8A1** (`gunModel t6_wpn_ar_xm8_view`,
   `displayName WEAPON_XM8`) and the mod already ships it. Reimagined's `sig556_zm` carries
   `ZOMBIE_WEAPON_SIG556` → *"Hold [{+activate}] for SWAT-556"*, PaP name **"FBI-667"**.
2. **The stock zombies FAL is NOT the FAL-OSW.** `fnfal_zm` is `t6_wpn_ar_fal_view` /
   `ZMWEAPON_FNFAL`; the FAL-OSW is `sa58_zm` / `t6_wpn_ar_sa58_view`, PaP **"WN OTW"**. Different
   model, different string. Reimagined declares 130 `viewmodel_sa58_*` anims from MP and **zero**
   `viewmodel_fal_*`, because the FAL's own assets are already in the ZM fastfiles. Two guns.

### 🛑 THE "REPLACES EXISTING WEAPONS" WORRY IS REAL, AND IT IS ONE LINE

`BO2-Reimagined\scripts\zm\_zm_reimagined.gsc:2237-2239`:

    if (isdefined(level.zombie_weapons["fnfal_zm"]))
        level.zombie_weapons["fnfal_zm"].is_in_box = 0;

Reimagined **pulls the stock FAL out of the box** to make room for the FAL-OSW. **Do not port that
line.** Same shape to watch for on `sig556` vs `xm8`. Port the additions, never the removals.

### WHAT EACH WEAPON ACTUALLY COSTS — the recipe is Reimagined's own zone file

🌟 **None of the 11 exist in any zombies fastfile.** Checked every viewmodel
(`t6_wpn_ar_sig556_view`, `t6_wpn_smg_msmc_view`, …) against all 13 ZM lists **and** `mod.ff`:
**zero hits.** So every one needs its MP assets linked into `mod.ff`.

`BO2-Reimagined\zone_source\includes\common_mp.zone` (1,189 lines) is the exact per-weapon asset
list, sourced from `common_mp.ff` / `patch_mp.ff`. MSMC's block (`:178-219`) is representative:
2 view/world xmodels + 2 attachment xmodels + 4 camo materials + ~30 `viewmodel_msmc_*` xanims.
`sa58` needs **130** anims.

**Sound is fully covered and already routed.** `BO2-Reimagined\soundbank\mod.all.aliases.csv`
(1,481 rows) carries **36-49 `wpn_<name>_*` alias rows per weapon** — 49 insas, 49 vector, 49
sig556, 48 sa58, 47 qbb95, 44 crossbow, 41 mk48, 37 peacekeeper, 36 mp7, 14 titus. Rows point at
`raw\sound\wpn\...`, so payloads come out of the MP banks by the same
`Unlinker --include-assets soundbank --search-path "<BO2>\sound"` route already used for
`zmqol_ann_*`. 🛑 Per [[t6-soundbank-facts]] **a missing alias is silent, never an error** — so every
row has to be confirmed present in the rebuilt bank, not assumed.

**Strings are routed too:** `zone_assets\english\localizedstrings\mod.str` already exists.

### ⚠️ THE ONE LIMIT THAT COULD BLOCK THIS — weapon count per map

Native vs. under this mod (`|map ff ∪ mod.ff|`):

| map | native | with mod | +11 weapons (~26 assets) |
|---|---|---|---|
| Nuketown | 100 | 145 | ~171 |
| TranZit | 109 | 156 | ~182 |
| Die Rise | 110 | 151 | ~177 |
| Mob | 88 | 152 | ~178 |
| Buried | 109 | 158 | ~184 |
| **Origins** | **129** | **178** | **~204** |

Stock's own maximum is Origins at 129, and **the mod already runs Origins at 178 and boots**, so the
ceiling is **≥ 178** — but the upper bound is unknown, exactly like the clientfield ceiling was.
**Origins is the map at risk and the one to boot first.** This is the residual risk to state, not
hide.

### ORDER OF WORK WHEN IT STARTS

1. `build_ff.bat` gains `--load` for `common_mp.ff` / `patch_mp.ff` (or `common_patch_mp.ff`).
   🛑 **Append them LAST** — first-load-wins decides the donor for shared assets, the v1.62.6 shader
   bug. Then **re-audit the full asset list: additions only, nothing re-owned**
   ([[t6-oat-load-order-decides-asset-copy]], [[t6-modff-asset-ownership-trap]]).
2. Copy the weapon defs into `weapons\`, **adapted not bulk-copied** — Reimagined carries its own
   balance changes.
3. Declare each weapon's xmodel/material/xanim block in `zone_source\mod_locations.zone`.
4. Dump the MP sound payloads + alias rows into `soundbank\mod.all.aliases.additions.csv`.
5. Add the strings to `mod.str` (display name, PaP name, wallbuy/box hint).
6. `added_weapons()` per map: `include_weapon(x)` + `include_weapon(x_upgraded, 0)` +
   `add_zombie_weapon(...)`, plus the `.csc` twin. **Additions only — never `is_in_box = 0`.**
7. Boot **Origins first** for the weapon-count ceiling.

### 🔮 PRE-MORTEM — three ways this fails, before any of it is written

1. **Silent audio.** An alias row that does not resolve to a payload is silent with no error, so the
   gun fires mute. → Confirm every `wpn_<name>_*` row round-trips through the rebuilt bank.
2. **The ownership trap fires on a shared MP asset.** Loading `common_mp.ff` puts MP copies of
   generic materials/anims in front of the ZM ones for **every** map. → Full asset diff after
   linking; anything re-owned gets hashed against the ZM copy before it ships.
3. **Origins blows the weapon ceiling.** ~204 assets against a bound that is only known to be ≥178.
   → Ship in map order with Origins tested first, and be ready to gate it off Origins.


## 🔴 IN FLIGHT 2026-08-13 — TRANZIT CLASSIC FAILS AT LOAD (toplayer clientfield overflow)

**User:** *"all the survival modes seem to work, but i booted up tranzit and got that error. make sure
all classic maps don't run into any crashes/errors."*

    Trying to assign 1 bits for netfield vulture_perk_toplayer
    but Client Field Set toplayer is out of space.

**NOTHING SHIPPED. No fix guessed.** Everything below is separated into measured / derived / unknown.

### 🛑 THE RULE THAT GOVERNS THIS FIX (user, 2026-08-13)

> *"if you have to make compromises or leave certain elements in a scuffed state then don't even
> bother; either try to find a way to keep something in or if you literally cannot due to limitations
> then don't even dignify asking me questions like that, no scuffed additions or features with
> missing elements, it's either vulture aid with everything working perfectly as intact just like
> normal, or not at all. Period. And this goes for any addition to the mod."*

**A menu of degraded variants is not a question to ask — it is three wrong answers.** Find a way to
keep it whole; if it genuinely cannot be whole, it is absent there and that call is made here, not by
the user. 📝 An earlier draft of this session offered exactly such a menu (keep Vulture but cut the
stink meter / Zombie Blood / Fire Sale). That was wrong and was withdrawn.

### ✅ MEASURED — what the boot log actually proves

`console_zm.log` (copied before reading, per checkpoint 36), 21,515 lines, build **r5344**:

| | |
|---|---|
| map / mode | `ui_mapname zm_transit`, `g_gametype zclassic` |
| where it dies | immediately after `GSC Executed "scripts/zm/zm_transit/zm_transit::init()"` |
| session before it | Diner survival ✅, Town survival ✅, **Nuketown ✅ (twice)**, then TranZit classic ✗ |
| field list in the log | **none** — the table only prints on a MISMATCH, and this is an out-of-space |

🌟 **The error is a precise instrument.** A **1-bit** request failed, so the set had **exactly 0 free
bits** at that instant. Vulture's still-outstanding `toplayer` demand at that point is
`vulture_perk_toplayer` 1 + `sndVultureStink` 1 + `vulture_perk_disease_meter` 5 = **7 bits**
(+2 more for `perk_vulture` if `perks_register_clientfield` had not already run — not established).

**So TranZit classic is short by 7 bits, or 9. This holds no matter what the true ceiling is**, which
is why it is the one number worth trusting here.

### 🛑 THIS KILLS THE OBVIOUS FIX BEFORE IT WAS WRITTEN

The established remedy for this exact error — drop `vulture_perk_disease_meter`, 5 bits, the trick
already used on Mob (`zmqol_vulture_has_disease_meter()` returns 0 for `zm_prison`) — **frees 5 and
the shortfall is 7.** It would not have booted. Worth recording precisely because it is the move any
reading of the code history would have suggested.

### ⚠️ DERIVED, NOT MEASURED — the full accounting, and why it is NOT good enough to rule on

Stock TranZit classic is **38 bits / 19 fields**
(`clientfields_zm_transit_zclassic_transit.txt`). Applying the mod's transformations, each traced to
a line of source:

| change | bits | source |
|---|---|---|
| `deadshot_perk` dropped | **−1** | `init_client_flags()` sets `disable_deadshot_clientfield = 1` |
| `perk_additional_primary_weapon`, `perk_dead_shot` | +4 | `perks_register_clientfield()`, `bits=2` (TranZit has `emp_grenade_zm`) |
| `perk_chugabud` | +1 | same |
| `perk_electric_cherry` | +1 | stock `_zm_perk_electric_cherry.gsc:50` |
| `perk_dive_to_nuke` | +2 | mod's `_zm_perk_divetonuke.gsc:83`, `bits=2` |
| `perk_vulture` + `vulture_perk_toplayer` + `sndVultureStink` + `vulture_perk_disease_meter` | +9 | mod's `_zm_perk_vulture.gsc:99/108/112/255` |
| `clientfield_whos_who_audio` + `_filter` | +2 | `quality_of_life.gsc:7147-7148` |
| `powerup_zombie_blood` | +2 | `add_zombie_powerup` → `_zm_powerups.gsc:449` |
| `powerup_fire_sale` | +2 | `include_powerup( "fire_sale" )`, `quality_of_life.gsc:6270` |
| `visionset_slot` / `visionset_lerp` / `overlay_slot` / `overlay_lerp` widenings | **+2 to +6** | `_visionset_mgr.gsc:221-224`, widths are `getminbitcountfornum(size-1)` |

**Total ≈ 64, with the uncertainty (±2 to ±4) concentrated entirely in the four widening fields** —
and the shortfall being explained is 7. 📝 Blood Money is confirmed **0 bits** (the 7-argument
`add_zombie_powerup` call never reaches `client_field_name`).

🛑 **THE UNCERTAINTY IS LARGER THAN THE THING BEING DECIDED, SO NO VERDICT IS ISSUED HERE.**
Declaring "Vulture cannot be whole on TranZit classic" from an accounting that is ±4 on a 7-bit
question would be the no-guessing rule broken in the other direction. The ceiling itself is
**inferred at 64, never measured** (`ERROR_CATALOGUE.md` §2 says so explicitly).

### ❓ UNKNOWN — the other four classic maps, and this is the cheapest thing to settle

| map | stock classic toplayer | native cover | risk |
|---|---|---|---|
| **Nuketown** | — | — | ✅ **booted clean this session** |
| **TranZit** | 38 | no Vulture, no PhD, no Mule Kick, no Deadshot | 🛑 **CONFIRMED BROKEN** |
| Die Rise | 29 | ships Who's Who | low-moderate |
| Mob | 50 | meter already dropped there | **high** |
| Buried | **63** | ships Vulture natively, so the mod adds none of its 9 bits | **high** — last confirmed on v1.64.0, and Zombie Blood has landed since |
| Origins | 61 | Vulture already off (`zmqol_vulture_enabled()`) | **high** — same caveat |

🌟 **The pattern is not "high stock total" — it is "how much the mod has to ADD".** Buried carries 63
stock bits and boots because it already owns Vulture; TranZit carries 38 and fails because it owns
almost none of what the mod turns on.

### ▶️ NEXT STEP — four boots, no build, no code

Boot **Die Rise, Mob, Buried and Origins in CLASSIC**. Each either loads or prints one line naming a
field and a set. That defines the real scope, and every one of those lines is another exact
0-free-bits measurement like the TranZit one. **Nothing should be designed until that is known** —
a fix aimed only at TranZit is worthless if three other maps need one too.

📝 An exact instrument exists if it comes to it: a dvar-gated dummy `toplayer` field of N bits
registered last on **both** sides, binary-searched per map, gives exact headroom with no feature
loss. It is deliberately not built yet — it can itself cause `EXE_CLIENT_FIELD_MISMATCH` if the two
sides ever disagree, and it is not worth that risk until the scope above is known.


### ✅ SCOPE MEASURED 2026-08-13 (second session) — TRANZIT CLASSIC IS THE ONLY BROKEN MAP

User booted all five classic maps on v1.77.0. **Die Rise ✅, Mob ✅, Buried ✅, Origins ✅
(one cosmetic oddity: dark red box-like textures in the start room — separate item, queued).
TranZit ✗**, identical error, identical build (r5344).

🛑 **THIS DISPROVES THE ACCOUNTING, NOT JUST REFINES IT.** Three independent contradictions:

1. **Buried classic boots.** Stock 63 toplayer bits, and the mod adds at least Zombie Blood
   (`powerup_zombie_blood` 2 + `visionset_lerp` 3→4) plus Deadshot (+2), Tombstone (+2) and
   Electric Cherry (+1) — **≥71 registered bits, successfully**. The `toplayer` ceiling is
   therefore **> 64**, and `ERROR_CATALOGUE.md` §2's "[inferred] 64" is now known WRONG.
   Do not quote 64 again.
2. **Origins classic boots** at ~66-69 by the same method. TranZit's full source-derived
   accounting is **65**. A map at 65 cannot fail while a map at 71 succeeds.
3. Working the ceiling backwards from each failure gives **43** (TranZit, a 1-bit request refused
   ⇒ exactly 0 free) and **~55** (Mob's old `visionset_slot` failure). Mutually inconsistent, and
   both below Buried's stock 63.

⇒ **There is an unaccounted, TranZit-specific consumer of `toplayer` bits, worth roughly 20.**
Searched and NOT found in: the mod's own `registerclientfield` calls (all of `scripts/`, `maps/`,
`clientscripts/` — the full list is short), weapon includes (no Paralyzer / Time Bomb / gas mask),
buildables (the Diner shield is gated on `ui_zm_mapstartlocation == "diner"`, so it is off in
classic), and powerups (`bonus_points_player` is confirmed 0 bits).

### ✅ TWO THINGS THAT *ARE* NOW EXACT

**1. The vsmgr widening on TranZit is exactly +5, not "±2 to ±4".**
The model was validated by reproducing stock TranZit's four dumped widths from source:
visionset info.size 2 (default + `zm_power_high_low`, 7 steps) → slot 1, lerp 3 ✓;
overlay (default + `zm_transit_burn` + `zm_ai_avogadro_electrified` + `zm_ai_screecher_blur`)
→ slot 2, lerp 4 ✓. Mod adds 3 visionsets (divetonuke, zombie blood, whos_who) and 2 overlays
(vulture stink 31 steps, zombie blood 15) ⇒ visionset_slot 1→3, visionset_lerp 3→4,
overlay_slot 2→3, overlay_lerp 4→5. **+5.**

**2. 🌟 THE FOUR VSMGR FIELDS REGISTER *LAST*, SO THE ERROR UNDERSTATES THE HOLE.**
`_visionset_mgr::init()` does `onfinalizeinitialization_callback( ::finalize_clientfields )`
(`_visionset_mgr.gsc:16`) — they land after every other registration. At the instant
`vulture_perk_toplayer` failed, **none of the 15 bits those four fields need was registered yet.**

> **Freeing exactly 7 bits would NOT have booted TranZit.** It would have failed a moment later
> at `visionset_slot` — which is *literally the error Mob gave in v1.65.2*. The requirement at
> that point is **7 + 15 = 22 bits**, not 7.

📝 Corollary for every future "it doesn't fit" call: the field named in the error is whoever asked
last *among those that had already asked*. Everything vsmgr owns asks after all of them.

### ▶️ NEXT — cheapest instrument first, no build

`developer 1` + `developer_script 1`, then boot TranZit classic. Per `ERROR_CATALOGUE.md` §8 every
GSC runtime error is currently swallowed; this has never once been run. If Plutonium prints the
clientfield table or the registration sequence, it hands us the ~20 unaccounted bits directly and
no probe needs building.

📝 If that yields nothing, the probe is justified and now well-scoped: a dvar-gated dummy
`toplayer` field of N bits on **both** sides (both halves read the same dvar in the same process,
so they cannot disagree), default N=0 so shipping behaviour is unchanged, binary-searched on a map
that boots. That gives the exact ceiling; a second dvar taking Vulture off TranZit gives the exact
deficit. **Neither is a fix and neither ships enabled.**

📝 Not yet ruled out as the eventual fix, and it degrades nothing: TranZit's `allplayers` set uses
**25 bits** and the busiest map in all 48 dumps uses 28, so a mod-added field could likely be moved
out of `toplayer` entirely. Behaviour-identical, implementation-relocated. Only worth designing
once the size of the hole is known.

### 📥 QUEUED — ORIGINS MP40 WALLBUY HANDS OUT THE PLAIN GUN (root cause FOUND, not yet fixed)

User, 2026-08-13: *"the mp40 wallbuy doesn't get the adjustable stock now for some reason, that was
working a while ago fine after i requested it."*

**The retag is NOT the problem any more — it is working.** Newest `console_zm.log`:

    [zm_qol] origins mp40: retagged 3 mp40 wallbuy stub(s) to mp40_stalker_zm; 23 wallbuy stub(s)
    total; mp40 at mp40_zm(3237,-424,195) mp40_zm(-517,4498,-285) mp40_zm(-643,695,199)

All three mapents structs found and rewritten. (Older logs `.007`/`.008` show the old `0 of 0`
failure, so v1.59.2/v1.59.3 did fix what they were aimed at.)

### 🌟 ROOT CAUSE — THE STUB IS NOT WHAT THE PURCHASE READS

`zmqol_tomb_mp40_stalker_wallbuys()` rewrites `stub.zombie_weapon_upgrade`. But there are **two
copies of that field**, and the buy path reads the other one:

| reader | field | stock line |
|---|---|---|
| the PROMPT (hint + cost) | `self.stub.zombie_weapon_upgrade` | `_zm_weapons.gsc:1120` |
| **the PURCHASE** | `self.zombie_weapon_upgrade` — **on the TRIGGER** | `_zm_weapons.gsc:1975, 2043` |

The trigger gets its copy **once, at spawn**:

    copy_zombie_keys_onto_trigger( trig, stub )     // _zm_unitrigger.gsc:625
        trig.zombie_weapon_upgrade = stub.zombie_weapon_upgrade;   // :630

🛑 **Unitriggers are proximity-spawned and despawned.** So a wall-buy whose trigger was created
*before* the retag (which runs after a `wait 2`) keeps `mp40_zm` on the trigger for as long as that
trigger lives — while its prompt, read from the stub, correctly says the stalker gun. Buy it and you
get the plain MP40.

⇒ **This is the whole intermittency, and it is why the feature keeps "coming back".** Nothing
regressed between versions. Whether you get the right gun depends on whether that particular
wall-buy's trigger happened to spawn before or after the retag on that boot — i.e. on where you
walked. The three No Man's Land / village wall-buys are the ones most likely to be spawned early.

### ▶️ THE FIX WHEN ITS TURN COMES (do NOT start while TranZit is in flight)

Rewrite **both** copies: after retagging each stub, also walk the live triggers and set
`.zombie_weapon_upgrade` on any whose `.stub` is one of the three, so already-spawned triggers are
corrected too. Then it cannot depend on spawn order.

🔮 Pre-mortem before building it:
1. The trigger list is not `trigger_stubs` — find the real live-trigger array in `_zm_unitrigger`
   and confirm it, do not assume a name.
2. `copy_zombie_keys_onto_trigger` copies **more than one key** (`:625-630` is a block, only the
   relevant line is quoted above) — read all of them and check none of the others also names the
   weapon, or the fix is half done.
3. Triggers respawn on proximity, so a corrected trigger may be destroyed and re-created from the
   stub. That is fine **only because the stub is already correct** — verify that ordering holds
   rather than assuming it.

### 📥 ALSO QUEUED — the generator ring, and what is now known

Origins textures were the user's own images folder ✅ CLOSED — not the mod.

The ring: `Could not load material "waypoint_circle_arrow"` appears on **every** Origins boot in the
retained history (4 of 4) and on **no** non-Origins boot (0 of 7). **The mod does not cause it** —
`Unlinker --list mod.ff` (4,186 assets) owns nothing matching `waypoint` or `faction_cdc`. Lead, not
verdict; the ring may not use that material at all.

📝 The in-code capture probe ran, printed `6 zone(s) registered`, and then logged **nothing** for its
full 5-minute window. Its reads are safe (`ent_flag_init` at `zm_tomb_capture_zones.gsc:530`,
`n_current_progress` at `:521`), so this is real data rather than a silently dead thread — but the
user may simply not have reached a generator inside the window. **Next Origins run: capture a
generator inside the first 5 minutes**, and note whether it completes while the ring is missing.
