# STOCK_REFERENCE.md — what unmodified Black Ops II Zombies actually does

**This file describes the VANILLA game only.** No zm_qol behaviour belongs here. Its companion,
[`MOD_CATALOGUE.md`](MOD_CATALOGUE.md), records what the mod changes. Read this one first when
asking "is this a bug we introduced, or is it just how the game is?" — that question has now been
answered wrongly twice, in both directions.

| | |
|---|---|
| Written | 2026-08-08, alongside zm_qol v1.62.4 |
| Sources | the shipped game, read directly — see §0 |

## 0. Where these facts come from, and how to add more

Every entry cites a file you can re-open. **Nothing here may be written from memory or inference.**

| resource | path | answers |
|---|---|---|
| Stock GSC dump — 2,093 scripts | `H:\Claude\t6 modding starter kit\reference\gsc-dump\` | what stock code does |
| Stock client scripts `.csc` | same, under `.../clientscripts/` | client-side behaviour |
| OpenAssetTools | `H:\Claude\oat-windows\` | what a fastfile contains |
| Per-map clientfield dumps | `Black Ops 2 Grand Resources\T6-Data-Archive-main\ZM\Clientfields\` | every registered field and its bit width, per map |
| Compiled LUI | `BO2-Raw-files\ui_mp\**\*.lua` | menu/HUD layout (bytecode — strings and numbers readable) |
| Readable LUI | `BO2-Reimagined\ui_mp\**\*.lua` (35 files) | 🛑 stock **plus** Reimagined's changes — reconcile, never paste |
| Plutonium dvars | `H:\Claude\Projects\Plutonium\storage\t6\plutonium\dvar_descriptions.json` | dvar names |
| A boot's log | `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log` | real runtime dvar values |

**Useful commands**

```
Unlinker.exe --list <zone.ff>                          # every asset in a fastfile
Unlinker.exe --include-assets mapents -o <dir> <ff>    # a map's entities/structs as text
Unlinker.exe --include-assets material -o <dir> <ff>   # material definitions as JSON
Unlinker.exe --include-assets script  -o <dir> <ff>    # scripts (.csc) - NOT "rawfile"
```

🛑 **`--include-assets fx` produces no fx files.** There is no fx dumper and no fx authoring.
🛑 **A fastfile's filename must match its internal zone name** or OAT fails with
`inflate of stream N failed: invalid block type` — same bytes, different name, unloadable.

---

# 1. Perks

## 1a. The nine core perks are flags, not a list 📄

`level._custom_perks` is **not** the perk list. T6 keeps perks in two places:

- **Nine core perks** are flags: `level.zombiemode_using_<name>_perk`. `_zm_perks::init()` turns each
  on with its own `turn_<name>_on()` thread and never puts them in `_custom_perks`
  (`_zm_perks.gsc:75-99`).
- **Only perks registered through `register_perk_basic_info`** land in `_custom_perks` — Electric
  Cherry, PhD Flopper, Vulture Aid.

Walking only `_custom_perks` therefore finds 2–3 perks on a map that has 12.

## 1b. Specialty names do not match the perk names 📄

Models routinely guess these backwards.

| specialty | perk |
|---|---|
| `specialty_armorvest` | **Jugger-Nog** (not flak/armor) |
| `specialty_rof` | Double Tap 2.0 |
| `specialty_longersprint` | **Stamin-Up** (not "marathon the perk") |
| `specialty_fastreload` | Speed Cola |
| `specialty_quickrevive` | Quick Revive |
| `specialty_additionalprimaryweapon` | Mule Kick |
| `specialty_deadshot` | Deadshot Daiquiri |
| `specialty_flakjacket` | **PhD Flopper** (not Jugger-Nog) |
| `specialty_scavenger` | **Tombstone** (not a scavenger perk) |
| `specialty_finalstand` | **Who's Who** (not last stand) |
| `specialty_nomotionsensor` | Vulture Aid |
| `specialty_grenadepulldeath` | Electric Cherry |
| `specialty_weapupgrade` | Pack-a-Punch (as a machine `script_noteworthy`) |

## 1c. Giving a perk 📄

`_zm_perks::give_perk( perk, bought )` (`_zm_perks.gsc:1982`) is the single entry point. In order it:
`setperk` → `num_perks++` → burp/vox/blur if bought → `perk_set_max_health_if_jugg` → deadshot
clientfield → tombstone flag → solo-revive lives → chugabud lives → `player_thread_give` →
**`set_perk_clientfield( perk, 1 )`** → demo bookmark → stats → `perk_history` → append to
`self.perks_active` → **`notify("perk_acquired")`** → `thread perk_think( perk )`.

🛑 **Stock itself fires `perk_acquired`.** A pop-up HUD listening for it works whether or not your
`give_perk` override runs — so it is *not* evidence that a hook took.

**Only two places write a perk clientfield to 1** (verified by grep across the whole ZM dump):
`give_perk` and `perk_unpause`. So `give_perk` is the sole path that creates a HUD perk slot.

## 1d. Removing a perk is a NOTIFY, not a call 📄

There is no "remove a perk" function. `unsetperk()` sits inside `perk_think()`, which is a waiting
loop:

```gsc
perk_str = perk + "_stop";
result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );
```

Notifying `"<perk>_stop"` is the supported way out and runs the whole stock teardown — `unsetperk`,
`num_perks--`, and the per-perk switch that restores Jugger-Nog's max health. Calling `unsetperk()`
directly skips all of that and leaves the player on 250 health with no Jugg.

`perk_think` also does `set_perk_clientfield( perk, 0 )` and
`arrayremovevalue( self.perks_active, perk, 0 )` (`_zm_perks.gsc:2210`).
⚠️ The ordering guarantee of that third argument is **not documented anywhere in this workspace** —
do not rely on `perks_active` preserving order after a mid-array removal.

## 1e. Pausing a perk 📄

`perk_pause( perk )` calls `unsetperk()` and writes **`set_perk_clientfield( perk, 2 )`**
(`_zm_perks.gsc:2650`). So a paused perk reads `hasperk() == false` while its icon is still on
screen. `has_perk_paused( perk )` (`_zm_perks.gsc:2721`) is the correct test.
`perk_pause_all_perks()` runs on power loss (`_zm_power.gsc:633`), on every map — not just TranZit
EMPs.

## 1f. Perk machine entities 📄

- trigger volume: `getentarray( "vending_X", "target" )`
- model: `getentarray( "vending_X", "targetname" )`
- stock use-trigger targetname: `zombie_vending`

where X ∈ `jugg, sleight, doubletap, revive, marathon, three_gun, ads, deadshot, nuke, tombstone,
chugabud, …`

---

# 2. Which perk machines spawn — `script_string` 📄

`_zm_perks::perk_machine_spawn_init()` decides. **This is the authority on which machines exist.**

```gsc
location = level.scr_zm_map_start_location;
if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
    location = level.default_start_location;

match_string = level.scr_zm_ui_gametype + "_perks_" + location;

structs = getstructarray( "zm_perk_machine", "targetname" );
foreach ( struct in structs )
{
    if ( isdefined( struct.script_string ) )
    {
        foreach ( token in strtok( struct.script_string, " " ) )
            if ( token == match_string ) pos[pos.size] = struct;
        continue;
    }
    pos[pos.size] = struct;      // no script_string -> spawns everywhere
}
```

A `zm_perk_machine` struct carries `origin`, `angles`, `model`, `script_noteworthy` (the specialty)
and `script_string` (a space-separated list of `<gametype>_perks_<location>` tokens).

**Client-side equivalent of the two dvars:** `getdvar("ui_gametype")` and
`getdvar("ui_zm_mapstartlocation")` — the same two `clientscripts\mp\zombies\_zm.csc:32-33` reads.
`level.scr_zm_*` are not yet assigned at `struct_class_init` time.

## 2a. Measured struct counts ✅

| map | `zm_perk_machine` structs | note |
|---|---|---|
| `zm_buried` | **8** | 8 distinct perks, one gametype — no duplicates at all |
| `zm_transit` | **21** | incl. **5 × Speed Cola** and **3 × Pack-a-Punch** across Diner / Town / Farm / Cornfield |

This asymmetry is the reason several Buried-authored systems break elsewhere (§5).

---

# 3. Clientfields

- **Every clientfield set is 32 bits.** Measured across all 48 per-map dumps: no map exceeds 32 in
  any set.
- Sets seen in zombies: `toplayer`, `actor`, `scriptmover`, `zbarrier`, `world`, `vehicle`.
- **Origins (`zm_tomb`) is the tightest map**: `scriptmover` **32/32**, `actor` 31/32. Its 32
  scriptmover bits are `element_glow_fx` (4), `staff_charger` (3), `powerup_fx` (3),
  `play_artillery_barrage` (2), `perk_bottle_cycle_state` (2), `bryce_cake` (2) and the rest — the
  staffs, generators and tank.
- Overflow is a hard failure at load:
  `Trying to assign 1 bits for netfield <name> but Client Field Set ACTOR is out of space`.
- Server and client registration lists must agree exactly in **count, order and width**, or every
  player is dropped with `EXE_CLIENT_FIELD_MISMATCH`.
- `registerclientfield` works in `main()`; `vsmgr_register_info` needs `init()`.
- `setupclientfieldcodecallbacks` does **not** run engine drawing code — it makes the engine
  **dispatch a LUI event** named after the clientfield.

---

# 4. The perk row HUD is LUI, and it has a real bug ✅

**File:** `ui_mp/t6/zombie/hudperkszombie.lua` (compiled). Readable equivalent:
`BO2-Reimagined/ui_mp/t6/zombie/hudperkszombie.lua:170-207` — for `RemovePerkIcon` the two match.

**Structure:** `CoD.Perks.ClientFieldNames[1..12]` — **12 slots**. `CoD.Perks.Update` puts a newly
owned perk in the **first free slot**, so the slot array is "perks owned, in acquisition order".
`RemovePerkIcon` shifts every icon **down one slot**.

**Stock constants**, read straight out of the shipped bytecode (no decompiler needed):

| constant | value |
|---|---|
| `TopStart` | **-180 on DLC3 maps, -140 otherwise** (two constants + an `IsDLCMap(CoD.DLC3Maps)` test) |
| `IconSize` | 36 |
| `Spacing` | 8 |
| `STATE_NOTOWNED / OWNED / PAUSED / TBD` | 0 / 1 / 2 / 3 |

Stock's string table also contains `STATE_PAUSED` and `PausedAlpha` — so **a paused perk is dimmed
in its slot, not removed from the row.**

## 4a. 🛑 The off-by-one

```lua
local PerkWidget, NextPerkWidget = nil, nil
for PerkIndex = OwnedPerkIndex, #CoD.Perks.ClientFieldNames, 1 do
    PerkWidget = Menu.perks[PerkIndex]
    if not PerkWidget.perkId then break
    elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
        NextPerkWidget = Menu.perks[PerkIndex + 1]
    end                        -- no else: on slot 12 this is still slot 12
```

On the last slot there is no next slot, so `NextPerkWidget` still points at slot 12 from the
previous pass — slot 12 copies **itself** and never clears.

**It fires ONLY when the row is 12/12 full AND the removed perk is below slot 12.** With even one
slot free the loop reaches the empty slot and clears correctly, which is why stock never sees it:
no unmodified map lets you hold 12 perks. Removing the perk *in* slot 12 is always safe, because
`NextPerkWidget` is a fresh function-local.

**zm_qol patches this** as of v1.62.6 — see `MOD_CATALOGUE.md` §3d. The whole fix is the missing
`else NextPerkWidget = nil`, which routes slot 12 down stock's own "no next widget" branch: the
same branch stock already takes when you remove the perk sitting *in* slot 12. It is installed by
reassigning `CoD.Perks.RemovePerkIcon` from a file the mod already overrides, **not** by replacing
`hudperkszombie.lua` — see §4b for why that file cannot be reproduced faithfully.

## 4b. 🛑 `hudperkszombie.lua` cannot be reproduced from any readable source

`CoD.Perks.Update`'s own constant list contains `STATE_PAUSED`, `PausedAlpha` **and** `STATE_TBD`,
so stock handles both states inside `Update`. No readable source carries those branches:
Reimagined's copy removed them and drives pausing from its own `perks_paused` event instead.

Confirmed Reimagined-only, by searching stock's bytecode (0 hits each): `UpdatePerksPaused`,
`UpdatePerkOrder`, `SpecialtyToClientFieldNames`, `perks_paused`, `hud_update_perk_order`,
`perk_order`, `DvarString`.

`STATE_PAUSED` is **reachable in this mod**, not theoretical — perk clientfields are 2 bits wide
wherever `emp_grenade_zm` is included, e.g. stock `zm_transit.gsc:1926`. So shipping Reimagined's
file would silently stop EMP-paused perks dimming in their slots. Stock's functions, in definition
order, are exactly: `UpdateVisibility`, `GetMaterial`, `GetGlowMaterial`, `RemovePerkIcon`,
`Update`, `IconPulseFinish`, `AddGlowIcon`, `AddVultureMeter`, `UpdateVultureDiseaseMeter`.

**Fix would be one line** — `else NextPerkWidget = nil` — but `ui_mp/` overrides are whole-file
replacements and no stock-faithful source of this file exists.

---

# 5. Vulture Aid — stock implementation and its Buried-only assumptions

**Server:** `ZM/Maps/Buried/maps/mp/zombies/_zm_perk_vulture.gsc`
**Client:** `.../clientscripts/mp/zombies/_zm_perk_vulture.csc` — this is where the markers live.

## 5a. Setup chain 📄

`enable_vulture_perk_for_level()` registers the perk, its init thread, **and**
`onplayerconnect_callback( ::vulture_setup_on_player_connect )`. That connect callback is what calls
`vulture_vision_init()` — **`vulture_toggle` never does.**

## 5b. The marker list — keyed by perk name, `script_string` ignored 🛑

```gsc
a_perk_machines = getstructarray( "zm_perk_machine", "targetname" );
foreach ( struct in a_perk_machines )
    level.perk_vulture.vulture_vision.perk_machines[ struct.script_noteworthy ] = struct;
```

Keyed by **perk name**, so duplicates overwrite; and `script_string` is never consulted. On Buried
(8 structs, 8 distinct perks, one gametype) this is harmless. On `zm_transit` its 21 structs collapse
to 8 and the survivor is whichever came last — frequently a machine belonging to a gametype or
location that never spawned.

## 5c. The visibility gate 📄

```gsc
if ( a_keys[i] == "specialty_weapupgrade" || a_keys[i] == "specialty_nomotionsensor"
     || !self hasperk( localclientnumber, a_keys[i] ) )
```

**A perk machine only glows while you do NOT own that perk.** Pack-a-Punch and Vulture Aid always
glow. Quick Revive additionally obeys `level.perk_vulture.disable_solo_quick_revive_glow`.
✅ This is why nothing lights up when you hold all 12 perks — correct behaviour, not a fault.

`vulture_global_perk_client_callback` deletes `fx_list_special[perk]` when you acquire that perk.

## 5d. Only 8 perks have a glow effect 📄

`setup_perk_machine_fx()` registers Jugger-Nog, Double Tap, Quick Revive, Speed Cola,
Pack-a-Punch, Stamin-Up, Mule Kick, Vulture Aid. **Anything else falls back to the Speed Cola
glow** (with a dev-only `println`). There is **no** Tombstone, Deadshot, Who's Who, Electric Cherry,
PhD or Wunderfizz glow effect anywhere in BO2.

## 5e. The 16 vulture fx 📄

`fx_zm_vulture_perk_stink`, `_stink_trail`, `fx_zombie_powerup_vulture`,
`fx_zm_vulture_wallbuy_rifle`, `..._glow_question`, `_dbltap`, `_jugg`, `_revive`, `_speed`,
`_pap`, `_mule`, `_marathon`, `_vulture`, `_mystery_box`, `_powerup`, `fx_zombie_eye_vulture`.

🛑 `fxt_zmb_question_mark` / `gfx_fxt_zmb_question_mark` belong to **`fx_zmb_wall_buy_question`** —
Buried's own wall-buy marker — **not** to any Vulture effect. The Vulture "?" draws
`fxt_zmb_perk_magic_box`, whose alpha is a "?" and a hook.

---

# 6. Assets and fastfiles

- **A fastfile stores image *headers*, not pixels.** T6 loads pixels at runtime from a loose `.iwi`.
  A header with no `.iwi` draws a **blue/grey checkerboard**; a header that *disagrees* with its
  `.iwi` renders garbage (the measured purple/green m1911).
- **IWI format byte** (offset 4): `0x01` ARGB32 · `0x02` RGB24 (**no alpha**) · `0x0b` DXT1 ·
  `0x0c` DXT3 · `0x0d` DXT5. Header: `IWi` magic, version `0x1b`, width/height at offsets 6/8.
- **The Linker resolves fx → material → image dependencies by itself.** Listing `fx,<name>` in a
  zone file pulls in everything that fx needs; those materials never appear in the zone source.
- **Pulling a stock map's asset into a mod fastfile makes the mod OWN it**, and the mod loads
  first — which can break the map that owns it natively. Audit with `Unlinker --list` before and
  after every relink.
- `mod.ff` stores scripts as **raw text** and will silently re-ship the donor's originals unless
  they are staged; the proof is `(src: disk)` rather than `(src: mod)` in the link log.
- **Only TranZit ships `so_zsurvival`** — missing xmodels on other maps render nothing while probes
  look healthy.

---

# 7. Scripting model and engine limits

| fact | consequence |
|---|---|
| No C preprocessor in GSC | no `#define`, no macros, no `#ifdef`. `#include` exists; `#using` does not |
| References resolve at **script load time** | a map-specific `::` reference in a root script crashes every *other* map; a runtime `if (level.script == …)` guard does **not** help |
| Globally safe to reference from a root script | `maps\mp\_utility`, `common_scripts\utility`, `maps\mp\zombies\_zm*`, `maps\mp\gametypes_zm\_*` |
| `getnormalizedmovement()` | **undefined** on this build — read buttons instead |
| `getnumexpectedplayers()` | returns **0** on Mods-menu launches, not the player count |
| Plutonium session mode | every game looks "online private", so stock solo detection never fires |
| `settext()` per tick | floods reliable commands → `EXE_SERVERCOMMANDOVERFLOW`. Use `settimer`/`setvalue` |
| `scriptmodelsuseanimtree()` | an ordered server/client contract; a server-only call kills every map on load |
| Plutonium hides script errors | a clean console log does **not** mean no GSC runtime error — threads die silently without `developer 1` |
| Decompiles are lossy | `BO2-Raw-files\*.txt` drops loops and branches and still parses clean. Trust them in inverse proportion to control flow |

## 7a. `replaceFunc` failure modes

| # | mode | note |
|---|---|---|
| 1 | unqualified same-file call | ⚠️ the starter kit says unhookable; **measured false for threaded calls** |
| 2 | behaviour reached via a `level.*` pointer | re-point the pointer instead |
| 3 | `::fn` captured before your replace | re-point, don't `replaceFunc` |
| 4 | registered in `init()` when the target is threaded at map-init | move it to `main()` |

🛑 **And sometimes it simply does not take.** Measured 2026-08-08: `replaceFunc` on
`_zm_perks::give_perk` did not fire even for a fully qualified external call. **Prove a hook runs
before building on it** — a debug print in the replacement is the only proof.

---

# 8. Solo

Stock's solo gate is **only** `check_solo_status` on Mob (`zm_alcatraz_utility`) and Origins
(`zm_tomb_utility`). Every other `sessionmodeisonlinegame` / `sessionmodeisprivate` use in the stock
dump is banking, weapon locker, achievements or leaderboards. `zm_alcatraz_craftables` gates
`is_shared = 1` on all five plane pieces and five fuel cans behind `level.is_forever_solo_game`.

🛑 **There is no cinematic code anywhere in the 2,093-file stock dump** — grepping `cinematic` /
`playbink` / `intro_movie` returns only `scr_cinematic_autofocus` in `_art.gsc`. The solo intro plays
from the **menu system, before the map loads**, so no GSC hook can reach it.

---

# 9. LUI

- `ui_zm.ff` contains **no** `.lua`. **`patch_ui_zm.ff` holds all 48 LUI files.**
- T6 ships a **modified Lua 5.1**: header format byte **13**; a 13-entry type table ending at offset
  **242**; constant type ids shifted **+1** (TSTRING=5 not 4); numbers are **4-byte floats**, not
  doubles. unluac (at `H:\Claude\unluac\`) cannot read it, and patching it means reverse-engineering
  Treyarch's fork — the function and constant encodings deviate too.
- Numeric and string constants are readable straight out of the bytecode with no decompiler.
- `ui_mp/` overrides are **whole-file replacements**; a bad LUI file **hard-crashes** the game.
- The Zombies lobby countdown lives in Plutonium's **compiled** `CoD.Lobby` module, no source found.
- `ui\t6\menus\privateonlinegamelobby.lua` line 10 is
  `Engine.Localize("MPUI_CUSTOM_GAMES_CAPS")` — that is the "CUSTOM GAMES" header.

---

# 10. Verified stock function signatures 📄

Safe to reuse; do not re-derive.

```gsc
maps\mp\zombies\_zm_weapons::ammo_give                    // wall-buy ammo
maps\mp\zombies\_zm_score::add_to_player_score( n )
maps\mp\zombies\_zm_perks::give_perk( perk, bought )
maps\mp\zombies\_zm_perks::has_perk_paused( perk )
maps\mp\zombies\_zm_perks::perk_pause( perk ) / perk_unpause( perk )
maps\mp\zm_tomb_ee_side::check_for_change                 // Origins prone-at-machine EE
self getstance()                                          // "prone" / "crouch" / "stand"
weaponclipsize(w) getweaponammoclip(w) getweaponammostock(w)
setweaponammoclip(w,n) givemaxammo(w) getcurrentweapon()
```
