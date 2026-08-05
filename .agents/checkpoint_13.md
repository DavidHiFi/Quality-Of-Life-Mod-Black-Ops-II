# Checkpoint 13 — v1.12.4. One open bug: NO ZOMBIES ON ANY BURIED LOCATION.

Written 2026-08-02, end of session. Supersedes checkpoint 12 (keep 12 for its §2
root causes, 11 for its §3 rules, 10 for the gamemode recipe in §8).
**Read §0, then §1. §1 is the whole session.**

---

## 0. THE SINGLE NEXT ACTION

**Load Borough. ~25 seconds. Read one log line.**

```
[zm_qol] BASE zm_buried/street t=10 spawners def=1 size=0 live=? multi=0 groups=0
```

| `live` | meaning | next step |
|---|---|---|
| **> 0** | entities exist; `_zm_spawner::init()` cached too early | a `REPAIRED` line follows and **zombies should appear in that same run**. Make the repair permanent, drop the probe. |
| **0** | spawner entities are not in the world under `zstandard` on Buried | no script fix is possible. Two options, **both need the user's decision** — see §1.4. |

Everything else in the mod is either verified working or shipped-and-untested.
This one bug is the only thing known to be broken.

---

## 1. THE BURIED "NO ZOMBIES" BUG — full state

### 1.1 Symptom
Borough **and** Maze spawn zero zombies. Round starts, HUD counts 6, none appear,
no script error anywhere in the log.

### 1.2 The measurement that matters
```
BASE zm_transit/town   t=20  spawners def=1 size=3   pool=4  total=0 alive=4   <- healthy
BASE zm_buried/street  t=20  spawners def=1 size=0   pool=17 total=6 alive=0   <- dead
```
`level.zombie_spawners` is **defined but empty** on Buried. `_zm.gsc:3059` does
`spawner = random( level.zombie_spawners )` then dereferences `spawner.targetname`,
so `round_spawning` dies on its first iteration. **Silently** — Plutonium does not
surface script runtime errors without `developer 1`. That silence is why this took
so long; it is not evidence of health.

Every other gate is provably fine: pool 17, `flag("spawn_zombies")=1`,
`zombie_ai_limit=24`, `zombie_actor_limit=31`, actors 0, total 6.

### 1.3 🛑 THREE THEORIES CHASED AND KILLED — do not pay for these again
1. **Not the Maze zone seal.** Borough never had it (gated to `location == "maze"`)
   and fails identically. The seal itself was *correct* — it produced `enabled=3`,
   pool 18, player in `zone_maze` — it just was never the cause. A background agent
   reverted it in `9c91ca3` on the premise that it was; that premise is disproved,
   but the revert is harmless and was left in place to avoid stacking changes.
2. **Not a missing survival fastfile.** `so_zsurvival_zm_buried.ff` genuinely does
   not exist (only TranZit ships one) — but `so_zencounter_zm_buried.ff` and
   `so_zsurvival_zm_transit.ff` contain **no mapents at all**, only xanim/material/
   xmodel/script. They cannot be the source of spawner entities.
3. **Not answerable offline.** OAT's Unlinker exports **zero `actor_*` entities from
   every map**, TranZit included. Mapents can never say where spawners live. Stop
   trying; use runtime probes.

### 1.4 If `live=0`, the two remaining options (USER'S CALL)
- **Build a `so_zsurvival_zm_buried.ff`** with OAT. Feasible in principle — §8 of
  `CLAUDE.md` — but the addon fastfiles hold no entity data, so it is unproven that
  this is even where spawners come from.
- **Run Borough/Maze as `zgrief` instead of `zstandard`.** Buried ships a real grief
  mode whose spawners demonstrably work. Costs the survival ruleset.

---

## 2. WHAT SHIPPED THIS SESSION (v1.9.2 → v1.12.4)

All **unverified in game** unless marked.

| area | change |
|---|---|
| perk bottles | `_zm_perks::init` bails on every custom survival location; `level.machine_assets` rebuilt in `quality_of_life.gsc` |
| Origins | generators force-captured; robots ghosted; dig sites hidden; staff relay switches unregistered |
| Origins EE | one-inch-punch prompts, quadrotor medallions, wagon fire, wall poster, light show, jump scare removed. **Kept**: radio song, loose-change prone reward |
| Origins barriers | `zmqol_open_stock_barriers` — see §3a |
| Trenches | lone barricade at `(-749, 2820, -112)` given its missing collision |
| Origins tank | deletion re-ordered onto `level.vh_tank` instead of `start_zombie_round_logic` |
| Borough | `subwoofer_flings_zombie` registered client-side (**needs `build_ff`**) |
| Borough | six perk machines re-registered for `zstandard`/`street` — see §3b |

---

## 3. ROOT CAUSES WORTH KEEPING

**a. Origins never zone-tags its zbarriers.** `script_string` present on **38/38**
TranZit, **22/22** Alcatraz, **0/12** Origins. So `zone.zbarriers` is empty for every
zone, `drop_all_barriers()` is a complete no-op, boards never come off, and zombies
mantle through intact boards on the co-located `node_negotiation_begin`
(`zm_mantle_over_40`) node.

**b. Perk machines are gametype+location tagged.** `perk_machine_spawn_init` needs a
struct whose `script_string` contains `<gametype>_perks_<location>`. Buried's eight
structs are **all** `zclassic_perks_processing`; Origins tags none for its survival
locations. Symptom is missing machines *and* the Wunderfizz drink soft-lock.
`turnperkon()` cannot help — it is only `level notify(perk + "_on")`.

**c. A one-shot zone disable cannot beat `manage_zones`.** `enable_zone` restores
`is_enabled` **and** `is_spawning_allowed`; adjacency is re-walked continuously; and
loc scripts run from `_zm::init`, *before* `manage_zones(init_zones)` at the end of
the map's `main()`.

**d. The clientfield dump is authoritative.** `*****CLIENTFIELD SETS FOR
[Client]/[Server]*****` lists both sides with counts. Read it before theorising.

---

## 4. RULES ADDED THIS SESSION

14. **🛑 Plutonium hides script runtime errors** without `developer 1`. A clean log
    does **not** mean no error. A thread can die on line one and leave no trace.
15. **Never print a bare count.** Three probes in a row were unreadable because they
    printed `0` with no denominator and no way to tell "empty" from "undefined"
    (`if (isdefined(x)) n = x.size;` yields 0 for both). Print the denominator, print
    `def` and `size` separately, and sample over time.
16. **`git add -p` hangs** — interactive, no stdin. Use `git add <path>` + `-F`.
17. **A/B against a working case.** Comparing Buried to TranZit/Town in the *same
    build* did in one run what four Maze-only probes could not.
18. **OAT exports no actor entities.** Mapents settle structs, volumes, triggers and
    models — never AI spawners.

---

## 5. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`; `-i client` for `.csc`.
- OAT — `H:\Claude\oat-windows\Unlinker.exe`; real map entities via
  `--include-assets mapents -o <dir> <zone.ff>` (the game's own `.ff`, **not** the
  T6-Data-Archive copy, which omits entities OAT does export).
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- GitHub: `github.com/DavidHiFi/zm_qol`, private, tagged **v1.1.1 → v1.12.4**.

---

## 6. STILL OPEN BESIDES BURIED

- Custom gamemodes missing from the menu; survival locations show the parent map
  name — checkpoint 10 §8.
- Prone lock — diagnosis only, checkpoint 12 §3. **Test: try crouching.**
- Maze zone flooding will return if spawning is ever fixed — the seal was reverted in
  `9c91ca3` and was, on its own terms, correct.
- Docks and Cell Block untested since v1.9.2.
