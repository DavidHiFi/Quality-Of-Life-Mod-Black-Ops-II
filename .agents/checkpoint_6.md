# Checkpoint 6 — the custom-location failures are ONE client-side gap. Fixes built, NONE tested.

Written 2026-07-31. **Supersedes the earlier draft of this file**, whose Origins diagnosis (§2 of
that draft: "the zstandard_preinit stub skips Electric Cherry") was **wrong** — see §2 below for
what actually happens and how the draft was disproved.

**Read §0 first.**

---

## 0. STATE — START HERE

### Confirmed working in game
- **Diner survival** launches, wallbuys tag `2 of 2` on both sides. (11:59 log)
- **Tunnel** wallbuys tag `1 of 1` both sides — Tunnel's failure is not clientfields.
- **Cornfield (TranZit)** and **Docks (Alcatraz)** boot at engine level; client connects.
- Loading screens / previews (checkpoint 5).

### Broken, as reported by the user
| location | symptom | status |
|---|---|---|
| Origins (crazy_place, zstandard) | `EXE_CLIENT_FIELD_MISMATCH` | ✅ root-caused, fix built (§2 + §3) |
| Docks (Mob of the Dead) | black screen, no input, force-quit | ✅ root-caused, fix built (§3) |
| Tunnel (TranZit) | instant death on spawn, twice | ❌ **no evidence yet** — probe added (§4) |

### 🛑 EVERYTHING BELOW IS BUILT AND DEPLOYED BUT COMPLETELY UNTESTED
`build_ff.bat` (5th relink) + `build.bat` both run clean. Not one line has been run in game.

### The single next action
Launch, in this order, and keep the log:
1. **Docks** — expect no black screen. This is the cleanest test of §3.
2. **Origins / Crazy Place** — expect no `EXE_CLIENT_FIELD_MISMATCH` and no black screen.
   Both fixes must work together; §2 alone only gets past the drop.
3. **Tunnel** — read the `[zm_qol] PROBE` lines (§4). They are the whole point of the run.
4. **The 5-map stock-location boot test is STILL unrun after five relinks.** Highest-risk item.

---

## 1. 🛑 THE STRUCTURAL FINDING — the port took the server half only

zm_qol replaced each map's **server** `<map>_gamemodes.gsc::init` to add `zstandard`/`zgrief` and
the new locations. It never replaced the matching **client** `clientscripts\mp\<map>::init_gamemodes`.
BO2-Reimagined ships a `replaced/<map>.csc` for exactly this; zm_qol's per-map `.csc` files only
replaced `include_weapons`.

**Why that is fatal**, `clientscripts\mp\zombies\_zm.csc`:

```gsc
start_zombie_gametype()                 // _zm.csc:132
    gamemode = getdvar( #"ui_gametype" );                       // "zstandard"
    if ( !isdefined( level.gamemode_map_location_main[gamemode] ) )
        return;                          // <-- also skips level._zombie_gamemodemain
```
`zombe_gametype_premain()` (:107) and the precache path (:181) have the same guard.
`level._zombie_gamemodemain` is what ends the client's loading state → **black screen the server
never releases**.

Stock client registrations, verified in the gsc-dump:

| map | client `init_gamemodes` registers | zm_qol server adds | gap |
|---|---|---|---|
| zm_transit | zclassic, zgrief, **zstandard** (transit/farm/town) | zstandard diner/tunnel/cornfield/power | none — works |
| zm_prison | zclassic, zgrief | **zstandard** + docks | 🛑 no zstandard |
| zm_tomb | zclassic **only** | **zstandard + zgrief** ×4 locations | 🛑 neither |
| zm_highrise | zclassic **only** | **zstandard + zgrief** ×3 locations | 🛑 neither |
| zm_buried | zclassic, zgrief, zcleansed | **zstandard** + maze | 🛑 no zstandard |
| zm_nuked | zstandard/nuked | — | none |

**A missing *location* is harmless; a missing *gamemode* is fatal.** Proof: Diner and Cornfield have
no client location entry either and both work — the per-location main is guarded separately at
`_zm.csc:153`. That single distinction explains why TranZit's added locations work and every other
map's do not.

---

## 2. ORIGINS' CLIENTFIELD MISMATCH — the real mechanism

Log (11:59, crazy_place / zstandard):
```
Clientfield 'electric_cherry_reload_fx' in set [allplayers] is not registered on the server
Clientfield 'visionset_slot' in set[toplayer] not the same bit count : [CLIENT: 2  SERVER : 1]
CLIENTFIELD SET [allplayers] COUNT : 15 (client) / 14 (server)
```

**The gate is `maps\mp\zombies\_zm_perks::init()` line 52:**
```gsc
vending_triggers = getentarray( "zombie_vending", "targetname" );
...
if ( vending_triggers.size < 1 )
    return;                     // returns BEFORE the _custom_perks loop at 101-110
```
`perk_machine_spawn_init()` only spawns machines whose struct `script_string` contains
`"<gametype>_perks_<location>"`. No Origins struct is tagged for the survival locations → zero
`zombie_vending` triggers → `init()` bails → the per-perk `machine_thread` loop never runs. Those
threads are the **only** server-side callers of:
- `_zm_perk_electric_cherry::init_electric_cherry()` → registers `electric_cherry_reload_fx`
- `_zm_perk_divetonuke::init_divetonuke()` → registers the `zm_perk_divetonuke` visionset

The client has no such gate — `_zm_perks.csc::init_perk_custom_threads()` runs every registered
perk's init thread unconditionally. Visionset count drives `visionset_slot`'s width
(`_visionset_mgr::finalize_type_clientfields` → `getminbitcountfornum( info.size - 1 )`):

| | visionsets | bits |
|---|---|---|
| server | default + zombie_blood | 2 → **1** |
| client | default + zombie_blood + zm_perk_divetonuke | 3 → **2** |

Both log lines follow exactly. This is the same *class* of bug as the `element_glow_fx` /
`switch_spark` fix already in `zm_tomb.gsc` (client registers unconditionally, server only down a
path survival never takes) — just a different stock code path.

### 🛑 How the earlier draft of this checkpoint was wrong
It claimed the `zstandard_preinit` stub in `replaced/zm_tomb_gamemodes.gsc` skipped
`enable_electric_cherry_perk_for_level()`. Disproved directly in the dump:
- stock `maps\mp\zm_tomb::zstandard_preinit()` is **empty** (`zm_tomb.gsc:82-85`);
- **both** server `main()` (`zm_tomb.gsc:180`) and client `main()` (`zm_tomb.csc:95`) call
  `enable_electric_cherry_perk_for_level()` **unconditionally**;
- the client call at :95 happens **before** `init_gamemodes()` at :109, so replacing
  `init_gamemodes` could not have suppressed it anyway.

`enable_..._for_level()` only *registers* the perk. The clientfield is registered later, by
`init_*`, and that is what the early return kills.

---

## 3. WHAT WAS CHANGED

| file | change |
|---|---|
| `scripts\zm\zm_tomb\zm_tomb.gsc` | `zmqol_register_survival_clientfields()` also registers `electric_cherry_reload_fx` and the `zm_perk_divetonuke` visionset (still gated `!is_classic()`) |
| `scripts\zm\zm_tomb\zm_tomb.csc` | **new** `replaceFunc` of `init_gamemodes` — adds zstandard + zgrief |
| `scripts\zm\zm_prison\zm_prison.csc` | **new** `replaceFunc` of `init_gamemodes` — adds zstandard (+ cellblock) |
| `scripts\zm\zm_highrise\zm_highrise.csc` | **new** `replaceFunc` of `init_gamemodes` — adds zstandard + zgrief |
| `scripts\zm\zm_buried\zm_buried.csc` | **new** `replaceFunc` of `init_gamemodes` — adds zstandard (+ street) |
| `scripts\zm\locs\zm_transit_loc_tunnel.gsc` | **temporary** `zmqol_tunnel_death_probe()` (§4) |

Every custom location gets **no** client-side location funcs — matching Diner, which works with none.
zclassic/zgrief/zcleansed entries are copied verbatim from stock so existing modes are unchanged.

`replaceFunc` on `init_gamemodes` works even though stock `main()` calls it **unqualified and
same-file** — BO2-Reimagined installs all four of its own identically
(`scripts/zm/<map>/<map>_reimagined.csc:6`) and works. Worth remembering: it contradicts the
starter kit's blanket "unqualified same-file calls can't be hooked" rule.

### 🛑 `mod.ff`'s `.gsc` copies are inert — proved, don't re-litigate
`build_ff.bat` stages `.csc` but not `.gsc`, so `mod.ff` still ships the donor's day-one `.gsc`
(link log: `scripts/zm/zm_tomb/zm_tomb.gsc (src: mod)`). That copy is **4,622 bytes and does not
contain `zmqol_register_survival_clientfields`** — yet that fix demonstrably works in game (its four
clientfields are absent from the mismatch list). **Therefore raw `.gsc` from `mod.iwd` is what
executes and the fastfile's `.gsc` are dead weight.** Editing `.gsc` needs only `build.bat`.
`.csc` still needs `build_ff.bat` first.

The pre-merge `scripts/zm/zm_expanded.gsc` is a separate matter — it is declared at
`mod_base.zone:14`, has no source in the project, and *does* execute (log: `GSC Executed
"scripts/zm/zm_expanded::init()"` plus four `overriding server replaced func` warnings where
`quality_of_life` wins). Bodies are equivalent so nothing is broken today. Left alone deliberately:
removing a zone script declaration is not worth the risk while five relinks remain untested.

---

## 4. TUNNEL — still no diagnosis, probe added

The 11:59 log has nothing: Tunnel initialises cleanly, wallbuy tags 1 of 1 both sides, then
`Writing stats...` → shutdown. No script error, no damage record. `games_mp.log` has no `D;` lines.

Ruled out: the clientfield fix (a mismatch drops you *before* spawn); the wallbuy re-tag (Diner uses
the identical mechanism and is fine); the §1 client gap (TranZit registers zstandard, and Diner
proves the path); lava (`player_lava_damage` is 15 dmg/tick — nowhere near a one-shot).

`zmqol_tunnel_death_probe()` in `zm_transit_loc_tunnel.gsc` watches `self.health` passively — it
overrides nothing and changes no gameplay. Read from the log:
```
[zm_qol] PROBE spawn  x y z  health=N
[zm_qol] PROBE damage N -> M  at x y z  stance=...
```
- one drop straight to 0 → `trigger_hurt` or spawned inside geometry (crush)
- repeated small drops → damage over time
- **no damage line at all** → not damage; a laststand/downed-state bug

🛑 **Delete the probe once diagnosed.**

---

## 5. TEST BACKLOG

1. 🛑 **5-map stock-location boot test** — 2 of 5 (zm_transit ✅, zm_prison ✅). Unrun: zm_buried,
   zm_highrise, zm_nuked. Five relinks deep. Rollback: restore `zone_source\base\mod.ff` over
   `mod.ff`, run `build.bat`.
2. Docks (§3), Origins survival (§2+§3), Tunnel probe (§4) — **all untested**.
3. Die Rise (shopping_mall / dragon_rooftop / sweatshop) and Buried (maze) — never tested at all;
   §1 predicts they were black-screening too.
4. Borough/street wallbuys (3 of 3, zstandard only; under grief client tags 0 — correct).
5. Diner wallbuys physically present: MP5K inside, Galvaknuckles on the roof.
6. Excavation Site loads; Cornfield's boundary wall is back.
7. LUI hint text clears the preview panel (checkpoint 5 §6).
8. Regression: perk descriptions after several revives; instant start.

**Open gameplay question, not a crash:** on Origins survival `_zm_perks::init()` bails at line 52,
so no perk machinery initialises at all — yet `random_perk_machine_init()` (Wunderfizz) is set up by
the loc scripts and Origins includes Electric Cherry and PhD in its random rotation. Worth checking
whether Wunderfizz can hand out a perk whose FX were never loaded.
