# QUEUE.md — one change at a time

**Rule (user, 2026-08-06):** nothing new starts until the item in flight is **confirmed working
in-game by the user**, with no bugs and no compromises. New requests get appended here and
acknowledged, not begun.

**"Deployed" is not "done".** Only a boot moves an item out of §1.

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
3. **Mob Wunderfizz overlaps the shield part spawn** — move that machine.
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
