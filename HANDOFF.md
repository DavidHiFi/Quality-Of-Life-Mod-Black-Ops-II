# HANDOFF — Arena agent → Claude Code

**This file lives only on `arena/01a02afd-zm-qol`. It is never merged into `main`.**

It is a mailbox. The Arena agent (cloud sandbox, no access to the user's PC) writes
deliverables and intent here. Claude Code (the user's PC, full system access) reads it,
decides whether to apply, and does the parts that need a real machine.

---

## Roles — why this split exists

| | Arena agent | Claude Code |
|---|---|---|
| Runs on | Cloud sandbox, clone of this repo | The user's Windows 11 PC |
| Can do | Read/write repo files, web research, push to its own branch | Everything, plus `build.bat`, Plutonium, the game, real logs |
| Cost to user | Free | Pro 5-hour usage window |
| Cannot do | Touch the PC, run the game, run a build, see a crash log unless pasted | — |

**The point of the split: the Arena agent does the token-expensive work (reading 15,000-line
files, drafting, research) so Claude Code spends its window on execution and testing.**

---

## Protocol

### Claude Code — how to check the mailbox

```bash
git fetch origin arena/01a02afd-zm-qol
git show origin/arena/01a02afd-zm-qol:HANDOFF.md
```

Read the **Inbox** below. Each entry states what it is, why, and exactly what you should do.
If Inbox is empty, say so and stop — do not go looking for work.

### Rules for Claude Code

1. **Never `git merge` this branch into `main`.** It carries scaffolding (this file included)
   that must not reach `main`. Copy out the specific files an entry names, or cherry-pick a
   named commit. Nothing else.
2. **Never commit `HANDOFF.md` or `handoff/` to `main`.** They are branch-local by design.
   The repo is the mod's own source only — see `.gitignore`, the 2026-08-20 note.
3. **You are the reviewer, not a courier.** Arena cannot boot the game, so nothing here has
   been run. Treat every deliverable as untested. If an entry is wrong for reasons only
   visible on the real machine, say so and do not apply it.
4. **Verify before applying.** Anything touching `.gsc`/`.csc` gets a gsc-tool parse check.
   Anything touching the build gets a real `build.bat` run.
5. **Report back by pushing to `main`** with a normal commit message. Arena reads
   `origin/main`, so that is how it learns what happened.

### Arena agent — how to post

Add an entry to Inbox. Keep it short: Claude Code reading this file costs the user tokens,
so the manifest stays a manifest. Detail belongs in the delivered file, not here.

Entry format:

```
### [ID] Title
- **Files:** paths added/changed on this branch
- **Intent:** one or two lines on what problem it solves
- **Action for Claude:** the literal steps to take
- **Tested:** no — Arena cannot boot the game. What needs checking on the real machine.
- **Status:** PENDING | APPLIED | REJECTED
```

---

## Inbox

### [H-000] Protocol bootstrap — no deliverable
- **Files:** `HANDOFF.md`, `handoff/arena-sync.md`
- **Intent:** Establish the mailbox and the `/arena-sync` command. Nothing to apply to the
  mod itself.
- **Action for Claude:** None. If the user has not installed the slash command yet, offer to
  copy `handoff/arena-sync.md` to `~/.claude/commands/arena-sync.md` — **personal scope, not
  the repo**, so the repo stays mod-source-only.
- **Tested:** n/a
- **Status:** PENDING

---

### [H-001] `preflight.py` — offline checks for what gsc-tool cannot see
- **Files:** `handoff/preflight.py`, `handoff/test_preflight.py`
- **Intent:** `gsc-tool -m parse` is syntax only; it passes files that kill every map at load.
  This checks six things decidable from source text alone. It is a **supplement to** the
  pre-flight sequence in `ERROR_CATALOGUE`, not a replacement for any step of it.
- **Action for Claude:**
  1. `python handoff\preflight.py --root "H:\Claude\Projects Sources\zm_qol"`
  2. `python handoff\test_preflight.py` — must print `10 passed, 0 failed`.
  3. Review the findings below with the user. **Do not apply any fix yet** — [H-002] is the
     only actionable one and it needs a decision first.
  4. If it earns its place, wire it into `build.bat` before the pack step. Suggested, not done:
     a non-zero exit should stop the build. That is the user's call, not mine.
- **Tested:** Runs clean under Python 3.11 in the Arena sandbox against this repo. Self-test
  10/10. **Never run on Windows, never run under the real `build.bat`.** Pure stdlib
  (`argparse`, `os`, `re`, `sys`), no third-party imports, `os.path` throughout, no shell
  calls — so it should be portable, but "should be" is not "verified". Step 1 above is the
  verification.
- **Status:** PENDING

#### What it found on this tree (0 errors, 20 warnings)

| check | result |
|---|---|
| `font-name` | ✅ clean — 5 × `small`, 2 × `default`. The `hudsmall` class is gone. |
| `efx-crlf` | ✅ clean — 64/64 CRLF, all `iwfx 2`. `ERROR_CATALOGUE` §22's sweep is holding. |
| `fake-builtin` | ✅ clean — no `array_slice` or relatives. |
| `root-scope` | ✅ clean — see the false-positive note below. |
| `clientfield` | ✅ no width disagreement between any `.gsc`/`.csc` pair in this repo. |
| `dvar-undocumented-silent` | ⚠️ **20 findings — see [H-002].** |

🛑 **A false positive I hit and removed, recorded so nobody re-adds it.** A first pass that did
not strip comments reported `scripts/zm/replaced/_zm.gsc` and
`scripts/zm/replaced/_zm_buildables_pooled.gsc` as referenced files. **Neither file exists** —
both hits were inside `//` comments (one an example line, one describing Reimagined). It also
flagged the 17 map-scoped refs in `replaced/zm_transit_gamemodes.gsc`, which are legal: that
file is reached only via `replaceFunc` from the TranZit-only `zm_transit/zm_transit.gsc`, and
`pack_iwd.ps1` packs `scripts/` recursively. The checker now strips comments and treats only
files **directly in** `scripts/zm/` as root scripts.

⚠️ **One assumption in `root-scope` I could not verify from a clone:** that a script in a
subfolder is loaded only when something on that map's path references it. That is what the
project's docs say and what the shipped build's behaviour is consistent with, but I cannot boot
the game. If subfolder scripts are in fact auto-run, this check is scoped too narrowly and
`locs/` + `replaced/` would need including.

---

### [H-002] 20 documented console dvars are registered nowhere
- **Files:** none changed — this is a finding, not a patch.
- **Intent:** `MOD_CATALOGUE.md` §2b/§11b document these as console-settable. Each is read with
  `getdvar*default()`, which **returns the default without creating the dvar**, and none has a
  LUI row to create it. So a user following the project's own documentation types the name and
  gets an unknown command — the exact `zmqol_minimal` failure recorded in `qol_options.gsc`'s
  header, which cost two boots on a switch that could not be thrown.

```
redhitmarkers              sv_deathmachine_duration   sv_deathmachine_powerup
zmqol_ring_hud_hide        zmqol_ring_hud_delay       zmqol_mp_weapons
zmqol_ww                   zmqol_box_ww_rarity        zmqol_wf_fx
zmqol_wf_fx_ug             zmqol_wf_fx_range          zmqol_wf_yaw_off
zmqol_wf_wall_gap          zmqol_wf_axis_snap         zmqol_diner_hatch_clip
zmqol_diner_hatch_ladder   zmqol_pap_diner_x          zmqol_pap_diner_y
zmqol_pap_diner_z          zmqol_pap_diner_yaw
```

- **Action for Claude:**
  1. **Confirm the mechanism on the real machine before changing anything.** Boot any map, open
     the console, type `redhitmarkers` with no value. `Unknown cmd` ⇒ confirmed. A printed
     value ⇒ I am wrong and this entry should be REJECTED. One boot settles all 20.
  2. If confirmed, the fix is one line each in `qol_options.gsc::init()`, matching the existing
     pattern: `qol_opt_dvar( "redhitmarkers", "0" );`
  3. 🛑 **Each default must equal that call site's current `getdvar*default()` fallback**, or
     behaviour changes for existing players. The fallbacks are at the line numbers `preflight.py`
     prints. `qol_opt_dvar` only writes when the dvar is empty, so a value already in a player's
     config survives.
  4. 🛑 **`zmqol_ww` is read 8× starting in `scripts/zm/Freeze.csc:18` — a CLIENT script.** If
     the registration is server-side only, the client read still returns the default. Check both
     halves before calling it fixed. This one is not the same shape as the other 19.
  5. Under **one change at a time**, this is one item, not twenty. It also touches
     `MOD_CATALOGUE.md` §2b if any dvar turns out not to be real.
- **Tested:** no. Static analysis of the source text only. Step 1 is the falsifying test.
- **Status:** PENDING

---

### [H-003] `MOD_CATALOGUE.md` §1a line counts are stale by ~2×
- **Files:** none — doc correction for the private dev folder, which I cannot reach.
- **Intent:** §1a's script inventory understates the tree badly. Measured in the clone at
  `cb6776c`:

| file | §1a says | actual | ratio |
|---|---|---|---|
| `quality_of_life.gsc` | 7,264 | **15,743** | 2.17× |
| `wunderfizz.gsc` | 2,475 | **2,993** | 1.21× |
| `zm_expanded.csc` | 1,119 | **2,891** | 2.58× |
| `qol_options.gsc` | 864 | **2,171** | 2.51× |
| `zm_tomb/zm_tomb.gsc` | 1,257 | **1,947** | 1.55× |
| **total, `scripts/zm/`** | 19,540 / 26 files | **33,022 / 28 files** | 1.69× |

  Whole repo including `maps/`, `clientscripts/`, `character/`, `zone_assets/`: **43,832 lines
  across 46 files.** Also `H:\Claude\CLAUDE.md` describes `quality_of_life.gsc` as "~3500
  lines" — that is off by 4.5× and appears in the file auto-loaded into every session.
- **Why it matters beyond tidiness:** these numbers are how a session budgets a read.
  `quality_of_life.gsc` is a 15.7k-line file being planned for as a 3.5k-line one, which is a
  direct and repeated cost to the user's Pro window.
- **Action for Claude:** update §1a and the `CLAUDE.md` line, using `wc -l` output rather than
  these figures if the tree has moved since `cb6776c`.
- **Tested:** n/a — `wc -l` on the clone, reproducible with the commands above.
- **Status:** PENDING

---

## Outbox — questions for Claude Code / the user

Things Arena cannot determine from a clone and would otherwise guess at. Answers can come
back as a commit to `main` touching this file, or just pasted into the Arena chat.

1. Confirm the local repo path on the Windows machine, and whether it is the same clone that
   pushes to `origin`.
2. Does gsc-tool run from a fixed path on that machine? A pre-flight linter would want to
   shell out to it.
3. Are `CLAUDE.md` / `AI_CONTEXT.md` still at `Projects Sources\zm_qol - dev\`, and does the
   `AI_CONTEXT` rule numbering cited in ~20 GSC comments still match that file?
