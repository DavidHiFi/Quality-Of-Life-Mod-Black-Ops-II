# Checkpoint 12 — v1.12.0. Every known bug has a shipped fix; none are verified in game.

Written 2026-08-02. Supersedes checkpoint 11 (keep 11 for its §3 hard-won rules,
and 10 for the gamemode recipe in its §8 and the asset-chain pattern in its §2).
**Read §0 first.**

---

## 0. STATE — START HERE

### The single next action
**Load Borough, then Maze.** Both carry a shipped fix that has never run:

| load | what to look for |
|---|---|
| **Borough** | does it still drop with `EXE_CLIENT_FIELD_MISMATCH`? |
| **Maze** | the log line `[zm_qol] MAZEZONE sealed - enabled=N spawn_pool=N`. **Expect `enabled=3`.** Then: do zombies actually reach you? |
| **Trenches** | `[zm_qol] BARRIERS opened N stock zbarriers` — **expect 12**. And do zombies still reach the arena, or did the new collision wall at `(-749, 2820, -48)` cut them off? |

### Confirmed working in game (user-verified 2026-08-02)
Every map launches without a script error. The 09:25 session covered **cornfield,
dragon_rooftop, maze, sweatshop, trenches, tunnel** with **zero** mismatches,
unresolved externals or script errors.

Earlier-verified: TranZit Diner/Tunnel/Cornfield/Power/classic; Origins Excavation
Site, Crazy Place, Church, Trenches; Docks; Cell Block; Die Rise ×3; Nuketown;
`.p`/`.god` chat commands.

### 🛑 EVERYTHING SHIPPED THIS ROUND IS UNVERIFIED
v1.9.2 → v1.12.0 is eight fixes, **none of them tested in game**. That is the whole
risk surface right now. See §1.

### Still open
| # | item | status |
|---|---|---|
| 1 | Custom gamemodes missing from menu + survival locations show the parent map name | ❌ not started — checkpoint 10 §8 |
| 2 | Prone lock (reported, cause not confirmed) | ⚠️ see §3 |
| 3 | `zm_prison` never loaded in the 09:25 session | Docks and Cell Block untested this round |

---

## 1. WHAT v1.9.2 → v1.12.0 CHANGED (all unverified)

1. **Perk-bottle soft-lock**, all custom survival locations. `_zm_perks::init` bails
   (`vending_triggers.size < 1`) because no `zm_perk_machine` struct is tagged for
   these locations, so `level.machine_assets` never exists and a Wunderfizz drink
   locks sprint/fire/melee forever. Rebuilt in `ridgelandproject.gsc`.
2. **Origins economy** — `zmqol_power_up_all_generators` force-captures every zone.
3. **Origins robots** ghosted; **dig sites** hidden (v1.8.1); **staff relay switches**
   unregistered.
4. **Origins easter-egg furniture** removed — see §2.
5. **Trenches barricade** at `(-749, 2820, -112)` given its missing collision.
6. **Origins zbarriers** force-opened — see §2.
7. **Maze zone seal** — see §2.
8. **Borough clientfield** — see §2.

---

## 2. THE FOUR ROOT CAUSES WORTH REMEMBERING

**a. Origins never zone-tags its zbarriers.** `_zm_zonemgr` only adds a barrier to
`zone.zbarriers` if `isdefined(script_string) && script_string == zone_name`.
Counted over the shipped mapents: **TranZit 38/38, Alcatraz 22/22, Origins 0/12.**
So on Origins every zone's `zbarriers` array is permanently empty, which makes
`zm_tomb::drop_all_barriers()` a **complete no-op** — the boards never come off and
zombies mantle through six intact boards on the `node_negotiation_begin` node
(`animscript zm_mantle_over_40`) sitting at the same origin.
`zmqol_open_stock_barriers` reaches them via the `exterior_goal` structs instead.

**b. A one-shot zone disable cannot beat `manage_zones`.** `enable_zone` restores
`is_enabled` AND `is_spawning_allowed`; `manage_zones` re-walks adjacency
continuously; and the loc scripts run from `_zm::init`, which is *before*
`level thread manage_zones(init_zones)` at the end of the map's `main()`. On Buried
that meant 14 zones live. Fix = seal the adjacency table (re-point every non-arena
edge at a never-set flag, keeping `zone_init` so all zones still exist) **and**
re-disable after `level.zone_keys` appears.

**c. Clientfield mismatches have a direction, and the log proves it.**
`*****CLIENTFIELD SETS FOR [Client]/[Server]*****` dumps both sides with counts.
Read it before theorising — it showed Borough's `[actor]` 7-vs-8 gap was the
subwoofer alone, and that the `buildable` mismatch in the same log was a *different
map* (sweatshop) and already fixed.

**d. Loc scripts run before the map's own subsystem inits.** ~11 lines of
`zm_tomb::main` separate the loc script from `zm_tomb_tank::init`. Deleting the tank
in the loc left `tank_setup()` running on an undefined `level.vh_tank`. Wait on
`level.vh_tank` instead — that lands after `tank::init` and before
`start_zombie_round_logic` releases `players_on_tank_update`.

---

## 3. THE PRONE REPORT — diagnosis only, nothing changed

zm_qol never calls `allowprone` anywhere. Four stock paths can hold the lock, and
**what else is broken identifies which**:

| path | what else breaks |
|---|---|
| `disable_player_move_states` (perk bottle) | sprint, ADS, melee — crouch still works |
| `_zm_ai_mechz_claw` (Panzer grab) | **crouch** |
| `zm_tomb_tank::players_on_tank_update` | nothing — prone only |
| `giant_robot_head_player_eject_thread` | crouch, weapons |

The tank path was **ruled out**. Panzer claw is the leading candidate — a Panzer
dying mid-grab skips `mechz_claw_release()`, and it clears `allowcrouch` too.
**Test: try crouching.** Note fix 1 above may have removed this symptom already.

---

## 4. RULES CARRIED FORWARD

Checkpoint 11 §3 still applies in full. Additions:

10. **`git add -p` hangs** — it is interactive and the Bash tool has no stdin.
    Use `git add <path>` and heredoc commit messages via `-F`.
11. **A `.csc` change needs `build_ff.bat` then `build.bat`.** Confirm the relink
    used your copy: `Loaded script "..." (src: disk)`, not `(src: mod)`.
12. **The mapents are the arbiter.** `H:\Claude\Black Ops 2 Grand Resources\
    T6-Data-Archive-main\ZM\Mapents\<map>.d3dbsp` is plain text — entity origins and
    keys settle "is this thing in the arena?" offline, no game run needed. Zone
    *volumes* are brush models and cannot be read this way.
13. **Settle competing theories from shipped data before asking the user.**

---

## 5. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`; `-i client` for `.csc`.
  All **42** scripts parse clean as of v1.12.0.
- OAT — `H:\Claude\oat-windows\Unlinker.exe`.
- Logs — newest is `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- GitHub: `github.com/ridgelanded/zm_qol`, private, tagged **v1.1.1 → v1.12.0**.
