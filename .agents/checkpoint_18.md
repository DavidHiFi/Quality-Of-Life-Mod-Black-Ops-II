# Checkpoint 18 — v1.54.1. The ring is an OBJECTIVE, and the workspace ended the guessing.

Written 2026-08-06. Supersedes checkpoint 17 (v1.51.2), 12 commits ago.
Keep 17 for §1 (measure-don't-estimate), §2 (sound) and §3 (clientfield
budgets per set). **Its §4 is WRONG and this checkpoint replaces it — read §1
below before touching the generator ring.**
Keep 15 for §2 (the mod.ff asset-ownership trap). Keep 10 for §8 (custom
gamemodes).

**Read §0, then §1. §1 is a correction, and it cost two releases.**

---

## 0. THE SINGLE NEXT ACTION

**Get a `developer 1` log from the user, then do Vulture-everywhere.**

Nothing about the generator ring, `.god`/`.ghost` dropping out, or the
surviving Templar should be touched until that log exists. All three present
as "works sometimes", which is the signature of a **thread dying silently** —
and Plutonium swallows GSC runtime errors unless `developer 1` is set
([[t6-plutonium-hides-script-errors]]). The user's current log is clean for
exactly that reason, not because nothing is failing.

Ask for:
```
developer 1
developer_script 1
```
set in console BEFORE loading Origins, then one game: capture a generator or
two, toggle `.god` and `.ghost`. One log probably settles all three.

Meanwhile the safe, unblocked work is **Vulture Aid on Origins and Mob** —
see §2, it is no longer gated on a decompile.

---

## 1. 🛑 THE CORRECTION: THE GENERATOR RING IS AN OBJECTIVE

Checkpoint 17 §4 said Origins' generator capture ring fails because the
client's **hudelem allowance** is exhausted. **That is wrong.** I inherited it,
built v1.53.0 on it, and shipped a fix aimed at a subsystem the ring does not
use. The user reported it still broken, twice.

What the ring actually is, from `zm_tomb_capture_zones.gsc:1506`:

```gsc
objective_setprogress( self.n_objective_index, self.n_current_progress / 100 );
objective_setplayerusing( self.n_objective_index, player );
```

It is drawn by the **objective / waypoint system**. Not `newclienthudelem`. Not
the `world` clientfield — that one (`zone_capture_hud_generator_N`, 2 bits)
drives the generator's own model state, and the 7-bit float
`struct.script_noteworthy` drives progress. Origins declares four objectives
(0-3) in `declare_objectives()`, called unconditionally from
`init_capture_zones()`.

Ruled out **with evidence**, not reasoning:
- No `netfield` / "Client Field Set … out of space" anywhere in the log
- The mod registers **zero** `world` clientfields and **zero** objectives
- All 48 LUI files in `patch_ui_zm.ff` are menus — none draws the ring

Two leads left, both unproven:
- `lui checksum: 0xE4DF1718` vs `server lui checksum: 0xE98F0677` in the log —
  the client's LUI checksum changes after connect and stops matching.
- The mod replaces `fade_out_intro_screen_zm` with a version whose only change
  is `wait 1.6` → `wait 0.05`, immediately before
  `setclientuivisibilityflag( "hud_visible", 1 )`. The user's own description —
  "for a little while at the start of the game it doesn't show it, but after
  some point the progress indicators start working" — fits a startup-timing
  problem far better than any budget.

📝 **The lesson, and it is the expensive one: read the mechanism before writing
the fix.** "It's intermittent" felt like a budget and was not. A diagnosis you
cannot show from the dump, the game files or a log is a guess, and shipping on
it costs a release plus the un-picking.

**v1.53.0's HUD work is still worth keeping** — it fixed two real wastes (the
health bar never freed anything; the perk popup held an element that drew
nothing). It was simply never going to fix the ring.

---

## 2. 📚 THE WORKSPACE IS THE SOURCE OF TRUTH — AND IT GREW

The user spent an hour+ stocking `H:\Claude` specifically so nothing has to be
guessed, and made it a standing instruction:
[[workspace-is-the-source-of-truth]], [[zm_qol-change-discipline]].

**`BO2-Raw-files/` is the significant addition** (~6,800 files, Treyarch-style
raw tree). **Every compiled `.csc` has a readable `.txt` decompile beside it.**

🌟 **This unblocks Vulture Aid on Origins and Mob.**
`clientscripts/mp/zombies/_zm_perk_vulture.txt` is readable source listing all
eight registrations:

| set | field | bits |
|---|---|---|
| toplayer | `vulture_perk_toplayer` | 1 |
| **actor** | **`vulture_perk_actor`** | **2**  ← the Origins blocker |
| scriptmover | `vulture_perk_scriptmover` | 4 |
| zbarrier | `vulture_perk_zbarrier` | 1 |
| toplayer | `sndVultureStink` | 1 |
| world | `vulture_perk_disable_solo_...` | 1 |
| **toplayer** | **`vulture_perk_disease_meter`** | **5**  ← the Mob blocker |
| toplayer | `perk_vulture` | 2 |

Those two are the cosmetic fields (zombie eye glow, stink meter). Drop them on
BOTH sides and the perk works minus one visual each. The decompile step that
checkpoint 17 §3 called "a bigger job than a boot fix" is simply gone.

It also carries readable LUI source — `ui/t6/hud.lua` and
**`ui/t6/hud/objectiveinfomenu.lua`**, the first readable material on the
objective system, i.e. §1.

⚠️ Third-party repo, not an official release: its `.txt` files are someone's
tool output. Cross-check bit counts against the shipped `.ff` before writing.

Also present: `Black Ops 2 Grand Resources\BO2 Detailed DVARS.txt` — Treyarch's
own dvar descriptions, which is what verified the LOD dvars in §3.

---

## 3. WHAT SHIPPED — v1.51.3 → v1.54.1

| ver | change |
|---|---|
| 1.51.3 | rebrand: `ridgelandproject.gsc` → `quality_of_life.gsc`, author → DavidHiFi (GitHub account renamed `ridgelanded` → `DavidHiFi`, same id 106938608) |
| 1.52.0 | **Who's Who on TranZit, Nuketown, Buried, Origins** + the bottle chain in mod.ff |
| 1.53.0 | health bar allocates on demand; the perk popup's dead 4th element removed; **`.give<perk>` / `.remove<perk>`** |
| 1.53.1 | Wunderfizz paused-perk guard asked the MACHINE, not the player |
| 1.54.0 | **Fire Sale on TranZit and Die Rise** + `zombie_firesale` in mod.ff |
| 1.54.1 | **`lod_fix`** — model pop-in pinned to full detail |

🛑 **Also fixed: `build_ff.bat` was unrunnable.** The rename commit rewrote it
LF-only, and cmd.exe cannot parse an LF-only batch file with `if (` blocks and
caret continuations. Traced by counting CR bytes per revision (239 at HEAD~1,
0 after). `wunderfizz.gsc` and `zm_expanded.csc` lost theirs too.
**`.gitattributes` sets `* -text` precisely so checkouts stay byte-exact — and
a gsc-tool parse check validates syntax, not bytes, so it will not catch this.**

**None of v1.52.0 → v1.54.1 has been confirmed working in game.** Who's Who and
Fire Sale in particular have never been booted.

---

## 4. STILL OPEN — user-reported, in their words

1. **"the generator progress bar is missing again"** — §1. Needs the log.
2. **"i want all perks available on ALL maps"** — Vulture on Origins + Mob is
   the last gap and is now unblocked (§2). Tombstone is missing on 5 maps and
   needs `ch_tombstone1` (zm_transit.ff only) shipped; Who's Who + Quick Revive
   on Mob need `specialty_quickrevive_zombies`, which Mob alone lacks.
3. **"add zombie blood power up to all the maps"** — NOT STARTED. Full verified
   asset list in §5. The user believed this was already done; it was not.
4. **".ghost is still kinda inconsistent"** and **"god and ghost mode were both
   not working"** — both drop out unprompted. Suspect stock calling
   `disableinvulnerability()` / resetting `ignoreme`; the out-of-bounds monitor
   already does exactly that (ckpt 17 §7). Wants a re-assert watchdog, but see §0.
5. **"one of the templar zombies was still there"** after a generator — user
   noticed it only in ghost mode. Probably the same cause as 4.
6. **"the bottle is off to the left sometimes still after spinning"** — a real
   defect was fixed in v1.53.0 (retract computed from a mid-`moveto` `.origin`);
   still reported after, so either not deployed when tested or not the whole cause.
7. **"i already have mule kick"** — v1.53.1 fixed the paused-perk half only.
8. **MP40 wallbuy → adjustable-stock variant on Origins** (it is the box version).
9. **Python: always the 6-round speed reload**, not only when Pack-a-Punched.
10. **Box: getting a weapon you already hold Pack-a-Punched should keep the PaP
    and refill ammo**, matching what the mod already does for the Mauser/dig-site.
11. **`.hud` to toggle all HUD off, plus per-element `.hudtimer` / `.hudhealth` /
    `.hudcounters`** — the dvars already exist, so this is thin.

---

## 5. ZOMBIE BLOOD — the verified inventory (nothing written yet)

Both script halves are in **`zm_tomb_patch.ff`**; every asset is Origins-only.

| asset | source |
|---|---|
| `script, clientscripts/mp/zombies/_zm_powerup_zombie_blood.csc` | `zm_tomb_patch.ff` |
| `maps/mp/zombies/_zm_powerup_zombie_blood.gsc` | ship raw in `mod.iwd` |
| `xmodel, p6_zm_tm_blood_power_up` | `zm_tomb.ff` |
| `xmodel, c_zom_tomb_german_player_fb` | `zm_tomb.ff` |
| `fx, maps/zombie_tomb/fx_tomb_pwr_up_zmb_blood` | `zm_tomb.ff` |
| `fx, maps/zombie_tomb/fx_zm_blood_overlay_pclouds` | `zm_tomb.ff` |
| `rawfile, vision/zm_powerup_zombie_blood.vision` | `zm_tomb.ff` |
| `material, generic_filter_zombie_blood_b` | `zm_tomb.ff` |

The server half shipping as raw GSC is a **proven pattern** — `mod.iwd` already
carries `maps/mp/zombies/_zm_perk_vulture.gsc`, `_zm_perk_divetonuke.gsc` and
`_zm_magicbox.gsc`.

🛑 `init()` calls `vsmgr_register_info` for **both a visionset and an overlay**.
Registering an overlay server-side that the client does not widens
`overlay_lerp` — that is exactly the `[CLIENT: 4 SERVER: 5]` boot crash Vulture
caused twice. **Ship the `.csc` and invoke it in lockstep, then boot alone.**

Also: `include_powerup()` only sets `level.zombie_include_powerups[name]`;
`add_zombie_powerup()` precaches the model **only for included powerups**
(`_zm_powerups.gsc:419-422`). So the include must run before `_zm_powerups::init()`
— `main()` is the window — and any map missing the model needs it in `mod.ff`
first, or it is **fatal at load**. That is what made Fire Sale two changes
rather than one line.

---

## 6. METHOD NOTES

- **Read the mechanism before writing the fix.** §1. The single most expensive
  lesson of this session.
- **A `[ok]` build and a clean parse prove nothing about bytes.** gsc-tool
  validates syntax; it passed a `build_ff.bat` that cmd.exe could not run at all.
- **When the user says a thing regressed, check git before agreeing or denying.**
  The generator ring was never fixed — checkpoint 17 recorded it as "untouched
  so far" — so nothing had regressed. Saying so once is useful; saying it three
  times is not, and the fix is what they wanted.
- **Correct the user's premise when it is wrong, early.** They believed Zombie
  Blood was implemented and were about to test it. It did not exist.
- **Asset availability is the hidden cost of every "just enable it" request.**
  Who's Who, Fire Sale and Zombie Blood all looked like one-line includes and
  all needed `mod.ff` work, because precaching an absent asset is fatal at load.
  `Unlinker --list` across all six maps + `common_zm.ff` is the first check now.
- **Audit `mod.ff` after every zone change** — diff `Unlinker --list` before and
  after. Who's Who added exactly 8 assets, Fire Sale exactly 1, both with zero
  shared-texture drag. That is the standard to hold.

---

## 7. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`,
  `-m parse -g t6 -s pc -y <file>` (`-i client` for `.csc`).
- OAT — `H:\Claude\oat-windows\`. **Pass fastfiles as fully-quoted absolute
  paths** — invoking from inside the zone folder made Windows throw
  "choose an app to open .ff" dialogs at the user.
- `build.bat` for `.gsc`/`.csc` (Plutonium loads client scripts from `mod.iwd`
  as raw — the log says `loaded successfully from raw`). `build_ff.bat` only
  for `zone_source`/`zone_assets`. **Verify deployed byte sizes afterwards.**
- From PowerShell both need `dangerouslyDisableSandbox` and a full path:
  `& "H:\Claude\Projects Sources\zm_qol\build.bat"`.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- Screenshots — newest in `G:\Gallery`.
- GitHub **`github.com/DavidHiFi/zm_qol`** (renamed), private, tags v1.1.1 →
  **v1.54.1**. `gh auth status` still prints the old name from its cache;
  cosmetic, corrects itself on next `gh auth login`.
