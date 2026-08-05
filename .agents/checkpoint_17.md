# Checkpoint 17 — v1.51.2. Sound solved, measurement beat guessing, budgets are the wall.

Written 2026-08-05. Supersedes checkpoint 16, which stopped at v1.32.0 — **19
releases and 49 commits ago**. Keep 16 for its §2 (the asset-rename pipeline) and
§5 (the fx one-shot/looping table). Keep 15 for its §2 (the asset-ownership trap);
that diagnosis is still the reason the Wunderfizz model cannot be shipped under
its stock name, and the user asked about it again this session.

**Read §0, then §1. §1 is the method change and it is worth more than any
individual fix in here.**

---

## 0. THE SINGLE NEXT ACTION

**Enable Who's Who on Origins.** It is worth ~10 minutes and it closes two open
reports at once.

The user's last report: the Wunderfizz on Origins gives 9 perks and repeats Mule
Kick. Both are the same cause. `wunderfizz::getPerks()` builds its list from the
`level.zombiemode_using_*_perk` flags, and `ridgelandproject::perks()` sets the
extra flags only for

```gsc
if ( map == "zm_transit" || "zm_nuked" || "zm_highrise" || "zm_prison" || "zm_buried" )
```

**Origins is not in that list.** So on Origins `getPerks()` returns exactly the 9
perks the map already has, `zm_tomb.gsc::zmqol_wunderfizz_all_perks()` finds all 9
already in the rotation and adds nothing, and with all 9 held
`get_weighted_random_perk()` falls through its loop to `return list[keys[0]]` —
which is the Mule Kick repeat. Fill the rotation and the repeat disappears on its
own; it is stock's "you own everything" branch, not a bug.

The missing two, and they cost very different things:

| perk | what it needs | risk |
|---|---|---|
| **Who's Who** (`specialty_finalstand`) | `level.zombiemode_using_chugabud_perk = 1` on Origins + its `perk_chugabud` **toplayer** clientfield | Origins' toplayer set is the one with room — it was `actor` that overflowed. Probably fine. **Boot Classic Origins immediately after.** |
| **Vulture Aid** | 2 bits on Origins' **actor** set, which is full | Needs `clientscripts\mp\zombies\_zm_perk_vulture.csc` decompiled and re-shipped as raw text so `vulture_perk_actor` can be skipped. See §3. |

🛑 Enabling a perk on a new map is the exact change that produced two boot crashes
this session (§3). Do it alone, build, and boot Origins before touching anything
else.

---

## 1. 📐 THE METHOD CHANGE: MEASURE, DO NOT ESTIMATE

This is the most valuable thing in this checkpoint. Placement questions in this
project were being answered from screenshots, and it failed **five times in a row**
on one machine. A photograph carries direction but not distance, so "over there"
resolves to a band a couple of hundred units wide, and picking a point in that
band is a coin toss dressed up as geometry.

Three techniques replaced it, all offline, all exact:

**An xmodel's real bounding box is readable.**
```
Unlinker.exe --include-assets xmodel --model-format GLB <map>.ff
```
then read the POSITION accessor `min`/`max` out of the GLB's JSON chunk (12-byte
header, `int32` length at offset 12, JSON at 20). Measured this way:

```
p6_anim_zm_buildable_pap_on   85.7 wide   47.5 deep   92.9 tall   (depth -20.3..+27.2, ASYMMETRIC)
qolwf_vending_diesel_magic    74   wide   55.8 deep  108   tall   (depth -28.8..+27.1, ASYMMETRIC)
```

The Wunderfizz number independently confirmed `zmqol_wf_wall_gap`'s 30, which had
taken two rounds of trial and error against the user's eye. **The answer was
readable the whole time.**

**Map geometry is readable.** `Unlinker --include-assets mapents` gives every
entity with its origin, targetname, classname and `script_gameobjectname`. The
diner roof's extent, the hatch's four entities and the parapet positions all came
from there.

**`.where` is the specification.** Standing on the spot, facing the way the thing
should face, and reading off position + yaw ends the guessing in one round trip.
It is what finally placed the Diner Pack-a-Punch after four wrong attempts.

📝 And one hard-won corollary: **when a value has been wrong several times, the
history is the dataset.** Each past attempt is a labelled sample. The PaP yaw took
four builds because I kept re-deriving the offset from one new screenshot while
four labelled readings sat in the conversation:

```
yaw   2   "sideways"
yaw 270   "facing the complete opposite direction"
yaw  90   no complaint, twice
yaw 180   "sideways"
```

That is a complete, self-consistent picture of the convention. **Front = placement
yaw − 90**, which is the SAME offset the Wunderfizz needs (`zmqol_wf_yaw_off`). Two
T6 machine props share it; try it first.

---

## 2. 🔊 SOUND IS SOLVED, AND THE LAST TRAP WAS NOT IN A SCRIPT

Checkpoint 16 §3 called sound "the wall". It is not any more. The pipeline works
(edit `soundbank\mod.all.aliases.additions.csv`, drop the audio in `sound\`, run
`build_ff.bat`), and this session shipped Origins' own Wunderfizz electricity and
Buried's Vulture pickup chime through it.

**🛑 THE SET OF SOUNDS A MAP PLAYS IS NOT THE SET ITS SCRIPTS NAME.**
`zmb_rand_perk_sparks_top`, `_bolt`, `_strike` and `_hit` are all in `zmb_tomb.all`
and **not one is referenced by any script in the 2,093-file stock dump** — not the
`.gsc`, not the `.csc`. A T6 **FxEffectDef can carry sound elements**, and Origins'
`fx_tomb_dieselmagic_*` carry these. That is why the user described the idle zap as
"lining up with the visual effect": on Origins it does not line up with the effect,
**it is the effect**.

So when a stock machine makes a noise no script accounts for: dump the bank and
look for aliases that obviously belong to it and that nothing calls. That is the
signature of a sound living inside an fx. It is the third place assets hide, after
the zone and the LUI.

**And the alias table is ~60 columns.** The Vulture pickup "wrong sound" was one of
them: `Secondary`. Buried's `zmb_vulture_drop_pickup_ammo` carries
`zmb_vulture_drop_pickup` in that column, so one `playsoundtoplayer` fires both
layers. The mod's copy inherited the column verbatim, pointing at a Buried-only
alias. Payloads, volumes and curves were byte-identical to Treyarch's; the whole
bug was column 3. **Diff your row against the stock row field by field.**

**Build trap, now fixed but worth knowing:** `build_ff.bat`'s alias overlay was
append-only, so editing an already-shipped row was a silent no-op — 0 warnings, 0
errors, same byte count, stale table. It now drops every cached row whose name the
additions file mentions and re-appends the group (drop-and-append, not
replace-by-name, because `zmb_rand_perk_sparks_top` is THREE rows sharing one name
— that is how T6 does randomised one-shots, and a name-keyed replace collapses
them).

---

## 3. 🛑 CLIENTFIELD BUDGETS ARE THE WALL, AND EACH SET IS SEPARATE

Two boot crashes this session, and they look unrelated until you see the shape:

```
zm_tomb    Trying to assign 1 bits for netfield zone_capture_zombie
           but Client Field Set ACTOR is out of space.
zm_prison  Trying to assign 5 bits for netfield vulture_perk_disease_meter
           but Client Field Set TOPLAYER is out of space.
```

Every clientfield **set** has its own fixed budget. Vulture Aid registers eight
fields across four sets, so it can hit a ceiling in more than one place, and which
one depends on what the MAP already spends — Origins is heavy on `actor` (templars,
crusaders, capture zones, panzer), Mob on `toplayer` (afterlife, plane, shield,
brutus).

**📝 THE FIELD THAT ERRORS IS WHICHEVER ASKS LAST.** On Origins the name in the
message was the map's own field; on Mob it was ours. The name tells you nothing
about the cause. Read it as "someone before me used the space", never "this field
is broken" — time was lost on Origins assuming `zone_capture_zombie` was implicated.

Vulture now runs on TranZit, Nuketown, Die Rise and Buried only, gated by ONE
function, `zmqol_vulture_enabled()`, which every site asks. That matters: v1.49.0
wrote the map list into the enable function and its client twin but forgot
`zmqol_register_vulture_visionset()`, so the server registered an overlay the
client did not and turned a boot crash into a *different* boot crash
(`overlay_lerp [CLIENT: 4 SERVER: 5]`). **A list copied into three places drifts;
it drifted the first time it was copied.** The client half in `zm_expanded.csc` is
the one unavoidable copy — separate compilation unit — so check it first.

**The route back for both maps** is the same: `vulture_perk_actor` and
`vulture_perk_disease_meter` drive only cosmetics (zombie eye glow, stink meter),
so skipping just those on both sides leaves a working perk minus one visual. The
client half is `clientscripts\mp\zombies\_zm_perk_vulture.csc`, shipped as
**compiled bytecode** (`\x80GSC`); it needs decompiling (`gsc-tool -m decomp -g t6
-s pc --t6fixup`) and re-shipping as raw text, which `mod.ff` supports.

---

## 4. 🖥️ THE OTHER BUDGET: CLIENT HUD ELEMENTS

**Root-caused and confirmed by an A/B test the user ran** (mod off: generator ring
draws; mod on: it does not).

A client has a fixed hudelem allowance. This mod holds ~12 **permanently, per
player**:

| count | element | source |
|---|---|---|
| 5 | health value, bar bg, bar, player name, label | `ridgelandproject.gsc:812-847` |
| 1 | round timer | `:959` |
| 1 | zombie counter | `:985` |
| 1 | shield meter | `:1006` |
| 1 | notifier | `:5656` |
| 2 | zone name, round timer text | `qol_options.gsc:583,612` |
| 1 | bleedout text | `bleedout_bar.gsc:126` |

Origins' generator capture ring is created **on demand** when you approach a
generator, so it gets whatever is left — and when nothing is left it silently is
not created. **That is why some generators worked and others did not**: it was
never per-generator, it was whatever the pool looked like at that moment.

The same budget already truncated `.help` (see the comment above
`zmqol_help_lines()`, which documents it from the other side and is why commands
are grouped onto shared lines).

**Workaround the user has now**: `hud_health_bar 0` frees 5 slots on its own.
**The fix**: reduce the permanent footprint — the health bar's 5 elements could be
2–3 with no visible difference. Untouched so far; it is a refactor across three
files and wants a session with room to verify.

---

## 5. WHAT SHIPPED — v1.33.0 → v1.51.2

| ver | change |
|---|---|
| 1.33 | chat commands to spawn every power-up |
| 1.34-1.41 | Wunderfizz fx/sound hunt; **Vulture Aid on five maps**; the mod's own soundbank; `.where` reports yaw |
| 1.41.1 | the stink HUD (found by grepping compiled LUI); the real Vulture pickup chime; `png2dds.ps1` |
| 1.42.0 | Wunderfizz squared to the wall's **normal**; fx distance gate (`zmqol_wf_fx_range`); Vulture Secondary alias; `.infsprint`; build_ff overlay updates rows |
| 1.43.0 | idle electricity (Origins' own sparks); ball returns to idle after a spin; wall gap 30 |
| 1.44-1.45 | Diner roof hatch; **Pack-a-Punch on the Diner roof** |
| 1.46-1.48.1 | the PaP placed from a `.where` line + measured model bounds |
| 1.49.0 | Vulture off Origins; **every Wunderfizz traced out of its wall, on every map** |
| 1.50.0 | one Vulture map list; Mob excluded; **per-map blue electrical fx**; arcs on the cycling bottle |
| 1.51.0 | **Origins: added machines removed, native ones get the mod's perk list**; perk cap floor 11; `.infammo` refills on `weapon_fired`; `.fly` death barrier |
| 1.51.1 | `.fly` uses stock's out-of-bounds **callback veto** |
| 1.51.2 | Origins perk rotation reordered so the fallback cannot repeat |

---

## 6. STILL OPEN — user-reported, in their words

1. **"only giving me 9 perks... gave me mule kick twice"** — §0. One fix.
2. **"when the zombies come out of the ground there's no sound effect"** — NOT the
   soundbank (`zmb_zombie_spawn` is not in `mod.all`, so nothing of ours shadows
   it) and NOT a changed handler (the mod uses stock `handle_zombie_risers` via
   `#include`, and stock plays the sound *before* the fx, so missing fx cannot
   silence it). Undiagnosed. Next suspect: whether the `zombie_riser_fx` actor
   clientfield is registering at all given §3.
3. **The generator ring** — root-caused (§4), workaround available, fix not done.
4. **"the idle zapping sound fx are okay but not quite origins"** — the audio is
   Origins' own now; what differs is the beat (`zmqol_wf_idle_arcs`, 1.1-2.2s) and
   that on Origins picture and sound are one effect.
5. **Vulture on Origins and Mob** — §3.
6. **The user's custom reskin does not affect the added machines.** Correct and
   unavoidable: the machine ships under `qolwf_*` names precisely so `mod.ff` does
   not own Origins' assets (checkpoint 15 §2). Loose `.iwi` files override by NAME,
   so their reskin must be duplicated under the 23 `qolwf_*` names — offered to
   automate as a build step; they have not said which stock files they replaced.

---

## 7. METHOD NOTES FROM THIS SESSION

- **Read the stock function, not its name.** Three bugs in one session were "the
  mechanism is not what it is called": a level flag that only gated **thread
  creation** (`player_out_of_playable_area_monitor`), a `_collision` brushmodel
  that **renders** (`diner_hatch_collision` — an entity's CLASSNAME says what it
  is, its TARGETNAME says what someone called it), and a "sideways" model whose
  forward axis is not +X. In each case the answer was ten lines of stock away.
- **When suppressing stock behaviour, look for the hook stock already provides.**
  The death barrier took three attempts — level flag, then notify, then finally
  `level.player_out_of_playable_area_monitor_callback`, which is a standing veto
  and the only one of the three that was actually a switch. Note also that the
  monitor calls `disableinvulnerability()` **before** it kills, so `.god` never
  protected anyone from it.
- **A polling fix cannot cover an edge that resolves faster than the poll.**
  `.infammo`'s 0.5s sweep could not beat a 1-round magazine; the refill had to move
  onto the `weapon_fired` notify.
- **Edge-derived state needs a resync point.** `.fly`'s WASD flags come from
  `+forward`/`-forward` notifies; a key-up swallowed by the chat box stuck a key
  for the rest of the match. Re-zeroed at every takeoff and landing.
- **Check the FALLBACK before the main path** when a bug is "sometimes returns the
  wrong thing".
- **Restricting a search to the intersection of all six maps can exclude the
  answer.** The 224-effect global set contains no blue electrical effect, so every
  "pick a better one" round was drawing from a set that could not contain it. The
  machine needs the best effect ON EACH MAP.
- **The user's A/B tests settle things instantly.** Mod-off vs mod-on on one
  generator ended a diagnosis that had survived two rounds of theorising. Ask for
  one.

---

## 8. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`, `-m parse -g t6 -s pc
  -y <file>` (`-i client` for `.csc`). Also `-m decomp ... --t6fixup` for compiled
  `.csc`.
- OAT — `H:\Claude\oat-windows\`. `--list`, `--include-assets mapents|xmodel|
  soundbank|rawfile`, `--model-format GLB`, `ImageConverter --t6`.
- `png2dds.ps1` (project root) — PNG → A8B8G8R8 DDS, the missing link before
  `ImageConverter`.
- `build.bat` for `.gsc`; `build_ff.bat` also when `zone_source`/`zone_assets`/
  `.csc` changes. **Verify deployed file sizes and timestamps afterwards.**
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- Screenshots — newest in `G:\Gallery`.
- GitHub `github.com/ridgelanded/zm_qol`, private, tags v1.1.1 → **v1.51.2**.
