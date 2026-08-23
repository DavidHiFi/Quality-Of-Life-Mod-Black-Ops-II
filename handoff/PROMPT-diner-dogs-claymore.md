# Optimized prompt — Diner dogs, Nuketown hellhounds, Diner claymore

Paste everything between the lines into Claude Code. Written by the Arena agent 2026-08-23.
Findings below are static analysis, never booted.

> **Revised 2026-08-23, later the same day.** When this was first written the clone was v2.2.5
> and v2.2.6 was described as an unpushed local commit, so the prompt opened by telling Claude
> to stop and test v2.2.6 first. **`origin/main` is now v2.2.6 (`6103bb1`), public.** That gate
> is gone and the version section below replaces it. Everything from task 1 onward is unchanged
> except where v2.2.6 already moved the code — flagged inline.

---

**Three bugs from an in-game test, plus a cleanup pass. Do them ONE AT A TIME in this order,
and stop after each for me to boot it. Do not start the next until I confirm.**

**Before anything: confirm which version I actually tested.** `origin/main` is now **v2.2.6**
(`6103bb1`) and it already contains Diner work: the claymore's yaw fix and the dog-containment
changes. Run `git log --oneline -3` and read `mod.json`.

- **If my build was v2.2.5**, the v2.2.6 fixes were never in what I played. Say so and stop —
  I need to build and boot v2.2.6 before you write a line, because tasks 1 and 3 below may
  already be fixed and I would be paying you to re-fix them.
- **If my build was already v2.2.6**, then these bugs survived that fix. Say so and continue,
  treating each existing fix as *insufficient rather than absent*.

🛑 **A repo fact worth knowing before you `git pull`:** `origin/main` at `6103bb1` is a
**single commit with no parents** — the history was replaced, not appended to. It shares no
ancestor with older clones, so a plain `git pull` into a pre-v2.2.6 clone fails with *"refusing
to merge unrelated histories."* Do not force it and do not reset my work away; check with
`git rev-list --parents -n1 origin/main` and ask me how I want to reconcile.

---

### 1. Diner hellhound spawns at the garage door, clips through solid geometry, leaves the map

**Repro, 2026-08-23, Diner survival:** a dog spawned at the mechanic-shop garage door, ran
through the part-open door and the lifted car, ignored me entirely, went through the rear wall
and kept running outside the playable area. The round could not end. I had to cheat-skip it.

This is the same failure reported before and reportedly fixed twice. Treat the existing fix as
insufficient rather than absent — read what is already there first:

Line numbers below are **v2.2.6** (`origin/main`); the v2.2.5 numbers in brackets are what a
pre-pull clone shows. Verify with `grep -n` before trusting either — this file moved a lot.

- `zmqol_dog_spawn_diner_logic( dog_array, favorite_enemy )` — `scripts/zm/locs/zm_transit_loc_diner.gsc:1373` [v2.2.5: 1286]
- `zmqol_diner_dog_init()` — line 1293 [1244]
- `zmqol_diner_dog_watchdog()` — line 1421 [1334]
- `zmqol_disable_out_of_arena_ai_locations( a_locs )` — line 1201 [1152], called three times at 1189-1191
- `level.dog_spawn_func` is assigned at line 1366 [1279]

**Two separate defects, and I want both addressed:**

**(a) The spawn point itself.** Something is still handing out a location at or near the garage
door. Find which one and remove or relocate it. Note the comment at line 1247 (v2.2.6): there is a spawner
with `script_noteworthy "zombie_dog_spawner"` at origin `0 0 0`. A dog placed at the world
origin and then teleported is a different bug from a dog spawned at a bad-but-real location —
establish which one I saw before fixing anything. The `.where` in my screenshot reads
`x −3625 y −7404 z −58`, which is where I was standing, not where the dog was.

**(b) The pathing.** A dog that ignores the player and walks through world geometry is not
merely mispositioned — it has no valid path node, so its AI never engages. Stock
`_zm_ai_dogs.gsc` validates a spawn location before using it. **Read stock's own validation
and match it**, rather than adding another watchdog on top of two that already failed to
catch this. A dog with no path must never spawn; if one does, it must be removed and respawned
at a validated location, not nudged.

The acceptance test is mine to run: a full Diner hellhound round where every dog reaches me
and the round ends on its own.

---

### 2. Nuketown hellhound rounds — audit for completeness

Nuketown hellhounds shipped in v2.2.0 and, per `MOD_CATALOGUE.md`, have **never been
play-tested**. `zone_source/mod_nukeddogs.zone` ships six `fx_zombie_dog_*` effects and
`soundbank/mod.all.aliases.additions.csv` adds 18 alias names / 63 rows.

I have found **no dog or hellhound code in `scripts/zm/zm_nuked/zm_nuked.gsc` or
`zm_nuked.csc`** — grep returns nothing. So the implementation is assets-plus-a-menu-switch,
relying on stock `_zm_ai_dogs` running on a map Treyarch never shipped dogs on.

**Run the six-part completeness audit from `CLAUDE.md` against it** — functionality, visual fx,
sound fx, animations/models, client half, no regressions — by diffing against what stock's own
`_zm_ai_dogs.gsc` does call by call, not against what our implementation does. Specifically
confirm: dog spawn locations exist and are validated on Nuketown, the round-start and
round-end announcer lines resolve to real aliases, the lightning spawn fx plays, and the
`zm_nuked_dog` model and its animations are actually reachable on that map.

**Report what is missing before changing anything.** Under "perfectly, or not at all", if a
part cannot be done, tell me and I decide.

---

### 3. Diner claymore wall buy: wrong position AND cannot be purchased

**Repro:** walked up to it, no purchase prompt at all. Also still too far right — it needs to
move left, toward the window.

The no-prompt half is the real bug and the position is cosmetic. Do the prompt first.

> **Re-checked against v2.2.6.** v2.2.6 rewrote this wall buy: it derives the yaw from the
> model's own mesh axes and now writes **model yaw = wall normal (90)** and **buy yaw = normal
> − 90 (0)**, with the default origin moved to **x −3624**. That fixes the mine looking
> *sideways/clipped*. **It does not add `script_length`, so the lead below still stands** — I
> re-grepped the v2.2.6 file and the only occurrence of `script_length` is inside a comment
> quoting stock. If the prompt is still missing on a v2.2.6 build, start here.

**🌟 Strongest lead, verified statically — check this before anything else.** The buy struct in
`zmqol_add_claymore_wallbuy()` (v2.2.6: `scripts/zm/locs/zm_transit_loc_diner.gsc:926-934`)
sets `targetname`, `origin`, `angles`, `zombie_weapon_upgrade` and `target`. It does **not**
set `script_length` or `script_width`. The file's own comment quotes stock
`_zm_weapons.gsc:931`:

```
origin -= anglestoright( buy.angles ) * ( script_length * 0.4 )
```

If `script_length` is undefined on our struct, that term is undefined. Confirm what stock does
with an undefined `script_length` — whether it defaults, or whether the unitrigger ends up
zero-sized or unplaced. **Grep the eight stock `claymore_purchase` structs in the mapents dumps
and see whether every one of them carries `script_length`/`script_width`.** If they do and ours
does not, that is the bug, and the fix is to copy stock's values rather than invent any.

**Second lead, weaker but cheap:** `include_weapon( "claymore_zm", 0 )` appears at
`scripts/zm/zm_transit/zm_transit.csc:81` — the **client** script. The comment at
`zm_transit_loc_diner.gsc` line ~795 claims "and the server twin", but I can find no
server-side `include_weapon( "claymore_zm" )` anywhere in the tree. Verify whether the server
needs it too; an unincluded weapon cannot be bought.

**Rule out first, so we do not chase the wrong thing:** confirm the struct is reaching the
spawnable list at all. `loc_common.gsc:110` does include `claymore_purchase` in the retag set.
The boot log line `[zm_qol] diner claymore: wallbuy struct at (...)` tells you the struct was
created; it does **not** tell you a trigger exists. Those are different claims.

**Position, only after the prompt works.** Move it left toward the window. It is dvar-driven
and live-nudgeable, so give me the console line to try in game rather than guessing a number
and rebuilding:

```
zmqol_claymore_diner_x <value>
```

🛑 **The dvar defaults exist in TWO files and must move together** —
`zmqol_claymore_wallbuy_origin()` in `scripts/zm/locs/zm_transit_loc_diner.gsc` (v2.2.6: line
850) and its twin in `zm_expanded.csc`. The clientfield name is built from
the origin, so a one-sided change drops every player at load. The client is the half that
spawns the visible model.

🛑 **`zmqol_claymore_diner_x/y/z/yaw` are registered nowhere** — they are read with
`getdvarintdefault()`, which returns the default without creating the dvar. So the console
line above will do nothing until they are registered. See finding H-002 on the Arena branch;
`qol_opt_dvar( "zmqol_claymore_diner_x", "-3624" );` in `qol_options.gsc::init()` is the
pattern. Fix that first or the nudge workflow is unavailable.

---

### 4. Only after 1–3 are confirmed: the known-bugs pass

Do **not** start this until the three above are done and booted. Then work
`MOD_CATALOGUE.md` §10 and the README's Known Issues in this order, one at a time, stopping
after each:

1. Origins / Mob crash ~20–35 s into a match — the only one that makes a map unplayable.
2. `night_mode` — screen goes fully black.
3. `character` command — no visible effect.
4. God mode after Mob's afterlife — `.god` reads ON but the player can die.
5. Prone bonus at Mob's Electric Cherry — no points.

For each: state whether it is reproducible, what the cause is, and whether it is fixable
before writing code. If a fix is not possible, say so and I will decide whether the feature
comes out.

---

### Standing constraints for all of the above

- **Never ship a guess.** Every claim traces to a file you read, a log line, or a dump.
- **Perfectly, or not at all.** A partial fix is a defect — tell me what is missing instead.
- **One change at a time.** Deployed is not done; only my boot moves an item to done.
- **Pre-mortem each fix before handing it over:** three ways it could fail, each checked
  offline against the workspace.
- Pre-flight before every build: `gsc-tool -m parse` (`-i client` for `.csc`), clientfield
  symmetry and per-set bit budget, root-script scope, then `build.bat` — and `build_ff.bat`
  **first** if any `.csc` or asset changed.
- Update `README.md` and `MOD_CATALOGUE.md` in the same commit as any behaviour change.

---

## Notes for Claude, not part of the prompt

Findings H-001..H-003 on `arena/01a02afd-zm-qol` are relevant here. Run `/arena-sync`.
`handoff/preflight.py` catches the unregistered-dvar class that bites #3.
