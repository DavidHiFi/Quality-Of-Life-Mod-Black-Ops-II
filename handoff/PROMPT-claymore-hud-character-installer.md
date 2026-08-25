# Optimized prompt — claymore, round counter, character icon, chat key, installer, hellhounds

Paste everything between the two rulers into Claude Code. Keep your screenshots where the
`[Image #N]` markers are — re-paste each one with Alt+V at that point so Claude sees the
evidence next to the task it belongs to.

Written by the Arena agent 2026-08-25 against `origin/main` @ `eab09e2` (**v2.3.1**). Every
file path and line number below was read out of that tree. Static analysis — nothing was booted.

> ⚠️ **`main` moved twice while this was being written** (v2.2.5 → v2.2.6 → v2.3.1). Line
> numbers drift fast in this repo. **Every reference below is v2.3.1 — verify with `grep -n`
> before trusting any of them**, and if one is wrong, say so instead of editing the wrong line.

---

**Seven separate jobs. Do them ONE AT A TIME, in this order, and STOP after each one so I can
build and boot it. Do not start the next until I say it works.**

**Ground rules for this whole session:**

- **Never guess a value, a path or an API.** If you cannot verify something from the source in
  front of you, say so and ask. A wrong guess costs me a full rebuild and a boot to discover.
- **Read before you write.** Every item below names the exact function and line. Open it first.
- **If you find my description doesn't match the code, stop and tell me** rather than
  implementing what I said. I'm describing symptoms, not diagnoses.
- **Two-file rule:** several of these live in a server/client or GSC/Lua pair. Where I've
  flagged one, changing a single side is a load-time mismatch or a silent no-op. Both or
  neither.
- Confirm you're on **v2.3.1 (`eab09e2`)** before starting: `git log --oneline -1` and `mod.json`.

---

### 1. [Image #4] Diner claymore wallbuy — no purchase prompt, and nudge it left

🛑 **READ THIS BEFORE YOU DO ANYTHING — v2.3.1 already changed this and my screenshot may be
from an older build.**

In v2.3.1 the claymore wallbuy is **deliberately switched OFF**. `zmqol_add_claymore_wallbuy()`
(`scripts/zm/locs/zm_transit_loc_diner.gsc:853`) now early-returns at **line 899**:

```
if ( getdvarintdefault( "zmqol_claymore_diner_enabled", 0 ) == 0 )
```

and prints `diner claymore: DISABLED ... - awaiting the wall probe's numbers`. The comment
block at lines 858-898 says three previous attempts all derived the wall from something that
is not the wall, that the shack walls are BSP brushes which cannot be measured offline, and
that it stays off rather than shipping a fourth guess.

**It also already explains the exact bug I reported.** Lines 871-880: stock sizes the use
trigger from the model's own bounds — `script_length = bounds[0] * 0.25` = 2.79 units deep —
pushes it only `script_length * 0.4` = 1.1 units off the wall, and sets `require_look_at = 1`
(`_zm_weapons.gsc:924-931`, `:959`). Mount the mine a few units too deep and that whole box is
inside the brush, the look-at trace hits the wall, and **no prompt ever appears** — "I can see
it but can't buy it", exactly.

**So the answer is a measurement, not a code change.** v2.2.7 added
`zmqol_probe_shack_wall()` at **line 1785**, threaded from **line 1042**. It is print-only: it
fires a fan of bullettraces at the shack from inside the room and prints the real brush face,
the post's X span and the free wall height.

**What I want you to do, in this order:**

1. **Tell me which build my screenshot is from.** If the claymore is visible in-game then I was
   NOT on v2.3.1 (on v2.3.1 it does not spawn at all). Say so and stop — everything below
   depends on it.
2. **Have me boot v2.3.1 on Diner survival and send you the probe output.** Tell me exactly
   what console/log line to look for.
3. **Only then** set the origin from the probe's real numbers and flip
   `zmqol_claymore_diner_enabled` to 1.

🛑 **The enable flag is a SYMMETRIC PAIR — flipping one side is fatal.** Both
`scripts/zm/locs/zm_transit_loc_diner.gsc:899` and `scripts/zm/zm_expanded.csc:444` read
`zmqol_claymore_diner_enabled` with the same default. The comment at diner line 1780 is
explicit: set it to 1 **in the same edit on both sides**, or it is
`EXE_CLIENT_FIELD_MISMATCH` at load, because `_zm_weapons` names the wall buy's "world"
clientfield from the struct (`:889` server, `:218` client).

🛑 **Do not re-guess the origin.** The standing rule quoted in that comment is "perfect
implementation with no compromises, or don't add it at all". If the probe hasn't run, the
correct action is to wait for it — not to nudge `zmqol_claymore_diner_x` by eye. **If you are
about to pick a coordinate without probe data, stop and ask me instead.**

**Once it is measured and back on, the position ask still stands:** it needs to sit slightly
further left, toward the window. Give me the live console line rather than a rebuild:

```
zmqol_claymore_diner_x <value>
```

…but note `zmqol_claymore_diner_x/y/z/yaw` are read with `getdvarintdefault()` and **registered
nowhere**, so that console line silently does nothing today. Register them alongside the other
options (`qol_opt_dvar( "zmqol_claymore_diner_x", "-3624" );` in `qol_options.gsc::init()`) if
you want the nudge workflow to work at all. The defaults live in `zmqol_claymore_wallbuy_origin()`
at **line 845** and its twin in `zm_expanded.csc` — same two-file rule.

**Second lead, only if the probe route somehow clears:** `include_weapon( "claymore_zm", 0 )`
exists at `scripts/zm/zm_transit/zm_transit.csc:81` — the **client** script. I found no
server-side twin. An unincluded weapon cannot be bought; verify whether the server needs it.

---

### 2. [Image #5] Round counter is cut off at 4+ digits

My mod removes the round 255 cap, so I command-set the round to **10000** and the number runs
off the right edge of the screen.

**The fix site — and it is duplicated, both copies must change:**

- `zmqol_hud_round_anchor( elem )` — `scripts/zm/qol_options.gsc:2155`
- `zmqol_hud_round_anchor( elem )` — `scripts/zm/quality_of_life.gsc:15471`

They are twins by design (the comments at `qol_options.gsc:2150` and
`quality_of_life.gsc:15466` say so). The right-hand branch is:

```
elem.horzalign = "right";
elem.x = 25;
```

`x = 25` is a fixed inset that assumed a 1-2 digit round number. **Make the inset account for
the width of the string being drawn**, so a 5-digit round sits fully on screen.

**Requirements:**
- Only the **right-anchored** case needs it. `hud_round_left == 1` anchors left and grows
  inward, so it is already safe — don't touch that branch.
- **The two timers underneath must move with it.** `qol_options.gsc:1785-1789` passes
  `self.qol_hud_timer`, `self.qol_hud_roundtimer` and `level.zmqol_roundcounter` through this
  same function. If the round number shifts and the timers don't, they'll be misaligned — I
  want the column to stay visually aligned at every digit count.
- **Don't add a second writer.** `qol_opt_roundcounter_master()` (`qol_options.gsc:366`)
  documents that `round_hud()` re-anchors this element every round transition and that a
  single write gets undone. Whatever you do must survive a round change. Re-read that comment
  before choosing where the code goes.
- Tell me how you're measuring text width, and whether that's a real T6 builtin you've
  confirmed exists — **do not invent a function name.** If there's no way to measure it, say
  so and use a digit-count-based inset instead, and tell me that's what you did.

**Acceptance:** round 9, round 100, round 10000 — all fully visible, timers aligned under each.

---

### 3. [Image #6] [Image #7] Scoreboard shows CDC when I picked CIA — but only after RESTART LEVEL

**Repro, exactly:** pre-game lobby → character = **CIA** → start Diner Survival → pause menu →
**RESTART LEVEL** → open scoreboard → it shows **CDC**. [Image #6]

Then: pause → **instant exit** → start Diner again → scoreboard correctly shows **CIA**.
[Image #7]

So a fresh map load is right and a *restart* is wrong. I know the icon can't change mid-game;
I'm not asking for that. I'm asking that **RESTART LEVEL preserve the lobby choice.**

**What I found, so you don't start from zero — the two halves disagree:**

- The scoreboard icon is chosen in Lua: `ui_mp/t6/hud/scoreboard.lua:629` reads
  **`CoD.Zombie.IsSurvivalUsingCIAModel`** and picks `"cia"` (or `"inmates"` on prison/tomb).
- The mod's character picker is GSC: `qol_opt_character()` at `scripts/zm/qol_options.gsc:1396`
  reads the **`character`** dvar (registered at `qol_options.gsc:67`), sets
  `self.characterindex` (line 1480) and drives `level.should_use_cia` at lines 1514-1519.

**`IsSurvivalUsingCIAModel` is read by the scoreboard but is never set anywhere in this mod** —
I grepped all of `ui_mp/`. So the scoreboard is reading a stock value while the player model is
driven by the mod's own dvar. On a fresh load those happen to agree; across a restart they
don't.

**Find out why the restart path diverges** — likely the level-scope state (`level.should_use_cia`
and/or whatever feeds the Lua value) survives or resets differently on RESTART LEVEL than on a
full load. **Diagnose before fixing, and tell me the mechanism you found.**

**Requirement — the DEFAULT option must stay random.** `character 0` is "default" and that
means the stock/vanilla randomised behaviour. Only an explicit CIA/CDC pick should be pinned
across a restart. Don't make default deterministic as a side effect.

---

### 4. Add `.endround` as a chat command

I want to open chat, type `.endround`, and have the current round end and advance to the next.
Prefixes `.` `!` `/` all work in this mod already.

**Where it goes:** the dispatch chain in `scripts/zm/quality_of_life.gsc`, which is a
`cmd == "..."` / `else if` ladder running from **line 4361 to about line 4970** (38 commands).

**🌟 Reuse what's already there — do not write a new round system.** `.round <n>` at
**line 4373** already does the hard part:

```
else if ( cmd == "round" || cmd == "setround" )
    ...
    level thread zmqol_goto_round( int( tokens[1] ), player );
```

`.endround` is almost certainly `zmqol_goto_round( level.round_number + 1, player )`. **Read
`zmqol_goto_round()` first** and confirm it's the right entry point and that it handles the
current round's zombies correctly — if ending a round has to kill remaining zombies or fire a
round-end notify to be clean, say so and do it properly. I'd rather it be right than quick.

**Also update `.help`** — the user-facing list is `zmqol_help_lines()` at
`scripts/zm/quality_of_life.gsc:5902`.

🛑 **The help panel has a HARD LINE BUDGET and has silently truncated before.** The comment at
the top of that function explains it: one `createfontstring` per line, a fixed client HUD
allowance, and the panel once cut off dead at the 12th line with everything below it invisible.
**Commands are grouped deliberately — add `.endround` to an EXISTING line, do not add a new
one.** The `.round` entry isn't currently listed on its own, so put them together sensibly.

---

### 5. [Image #8] The help text names MY keybind — globalise it

The flash-help line says **"Press `;`"**. That's *my* personal chat bind. Anyone else running
this mod with a different bind gets told the wrong key, which is confusing and looks broken.

**Where:** `zmqol_credits_banner_print()` at `scripts/zm/quality_of_life.gsc:4129`; the line
itself is at **4175**:

```
self iprintln( "^5Press ^3; ^5(default chat key) and type ^3.help ^5or ^3!help" );
```

⚠️ **Read the comment block at lines 4154-4165 before you change this — it contradicts me and
you need to tell me who's right.** It claims semicolon was read out of
`%LOCALAPPDATA%\Plutonium\storage\t6\players\bindings_zm.bdg` (`bind SEMICOLON "chatmodepublic"`)
and that this is **BO2's stock PC layout**, not a personal choice. It also states GSC cannot
read a client's binds, which is why it says "default".

**So establish the fact first:**
- If `;` genuinely is BO2's stock default chat key, then the line is *correct* and my complaint
  is that it's fragile for rebinders — in that case **reword it so it never names a key that
  might be wrong**, e.g. point at the chat key generically plus the console route (`help 1`),
  which cannot be rebound.
- If it is *not* stock and was taken from my machine, then it's exactly the bug I described —
  remove it.

Either way the outcome I want is the same: **no text in this mod may ever display a keybind
read from my machine.**

**This is a general rule, not a one-off — apply it across the whole mod and remember it:**
this is a public mod, anyone can install it. Sweep for any other place that hardcodes a key,
a path, a username, a drive letter or anything else specific to my PC, and report what you
find. Add the rule to `CLAUDE.md` (or whichever context doc you keep) so it doesn't recur.

---

### 6. [Image #9] [Image #10] Installer — add a LAN launch option, rename ReShade, cut the bloat

Three changes to `installer/Mod Files/qol-installer.ps1`. The main menu is the `$items` array
at **line 2822**, and the dispatch `switch` immediately below it at ~line 2854.

**6a. New option: launch BO2 straight into zombies with the mod loaded.**

I have a script that already does this — it boots Plutonium T6 in **LAN/offline mode with the
mod already running**, no manual mod loading:

```
H:\Claude\Play BO2 with mod (LAN, offline).bat
```

**Read that file first and base the option on what it actually does** — don't reimplement it
from my description.

It should be an option in the list that then offers **sub-choices**, so people can pick what
they want:
1. **LAN mode with the mod** — one click, straight into zombies.
2. **LAN mode with the mod + ReShade watchdog** — same, plus the watchdog running.

Model it on the existing ReShade row, which already deploys a `.bat` helper next to the
installer: see `Act-InstallReShade` and how `installer/Play BO2 with ReShade.bat` is shipped
and referenced. Follow that same pattern — a deployed, double-clickable `.bat` — rather than
inventing a new mechanism.

🛑 `H:\Claude\...` is **my** path. Whatever ships must resolve its own location relative to the
installer (the existing `.bat` uses `cd /d "%~dp0"`), so it works on someone else's PC. Same
rule as item 5.

**6b. Rename the ReShade option.** [Image #9]

Currently: `Label='ReShade + BO2 preset'` (line 2831). **Make it just `ReShade`.** The ReShade
install works for **all** Plutonium games — BO1, MW3, WaW, BO2 — and the file list at line 934
confirms it ships `BO1.ini`, `MW3.ini`, `WAW.ini` and `BO2.ini`. Calling it "+ BO2" makes it
look BO2-only, which is wrong and undersells it.

**6c. Cut the description bloat — across the ENTIRE installer.** [Image #10]

The hint text is overloaded. Current ReShade hint (line 2832):

> `Post-processing that sharpens the picture and lifts the colour. Needs a small helper left running - see Play BO2 with ReShade.bat.`

That's two sentences of implementation detail in a menu. It should be one plain line about what
the user *gets* — something like *"Improves the visuals for Call of Duty games on Plutonium."*

**Apply that standard to every hint and intro block in the installer**, not just this one.
Rules:
- One short line. What it does for the player, in their words.
- No implementation detail, no file names, no caveats in the hint — those belong on the screen
  *after* they choose, where several already correctly live.
- A newcomer must never be confused or misinformed by it.

**Show me the full before/after list of every hint you rewrite before applying it** — this is
the user-facing text of my mod and I want to approve the wording.

---

### 7. Remove the hellhound option from Diner and Nuketown survival

Hellhounds on these two maps have been too much trouble. **Drop the feature.** Leave the stock
game's own hellhound maps (Bus Depot, Farm, Town) exactly as they are — those work in the base
game with no mod and must not be touched.

**What to remove — I've traced it, verify before deleting:**

The lobby row is `CoD.PrivateGameLobby.GameTypeSettings[5]` (`id = "allowdogs"`) at
`ui_mp/t6/menus/privategamelobby_project.lua:221`. Its map whitelist is:

```
GameTypeSettings[5].maps[1] = "zm_transit"
if ZmQolLobbyModLoaded() then
    GameTypeSettings[5].maps[2] = "zm_nuked"      -- line 271
end
```

- **Nuketown:** remove the `maps[2] = "zm_nuked"` line and its `ZmQolLobbyModLoaded()` wrapper.
- **`maps[1] = "zm_transit"` is STOCK — do not remove it.** That's Treyarch's own TranZit
  hellhound row and it covers Bus Depot / Farm / Town, which I want kept.
- **Diner:** I could not find a Diner-specific entry in this whitelist at all. **Work out how
  the option was appearing on Diner survival before you remove anything** — if it's inherited
  from the `zm_transit` entry then removing it would also kill Bus Depot/Farm/Town, which is
  NOT what I want. Report what you find first.

🛑 **The lobby row count is load-bearing and it has broken twice already.** The comment at
`privategamelobby_project.lua:261-266` says the Nuketown row makes Nuketown survival the only
**nine-row** lobby in the game, and that the preview panel had to be moved to fit it. Line 488
warns about bugs "caused by this number being wrong (nine on Origins, eleven at the Diner…)".
**Removing a row changes that count — undo the layout compensation added for it, or the panel
will be misaligned in the other direction.** There are THREE places to check, not one:

- **line 128** — a `zm_nuked` + `zsurvival` special case that hardcodes the preview panel to
  `Width = 242, Height = 112`. This one is easy to miss.
- **~line 1035** — `mapInfoImage:setTopBottom()`, "a ninth row pushes the hint down exactly
  one pitch".
- **~line 1061** — the size wrapper described as the working fix for the nine-row case.

**Then clean up what becomes dead:** the Diner dog code in
`scripts/zm/locs/zm_transit_loc_diner.gsc` — `zmqol_diner_dog_init()` (**line 1344**),
`zmqol_dog_spawn_diner_logic()` (**1424**), `zmqol_diner_dog_watchdog()` (**1472**), the
`level.dog_spawn_func` assignment (**1417**) — and the Nuketown dog assets
(`zone_source/mod_nukeddogs.zone`, the six `fx_zombie_dog_*` entries, and the dog rows in
`soundbank/mod.all.aliases.additions.csv`).

⚠️ **Do the script removal and the asset/zone removal as two separate steps with a boot in
between.** Pulling zone entries and fastfile assets is the riskiest part of this whole list —
if a `.zone` still references something that's gone, or something still precaches a removed
asset, the map won't load. **Tell me before you touch the zone files**, and if removing them
saves nothing meaningful, leaving the assets in place while removing the option is an
acceptable outcome. I'd rather a few unused KB than a map that won't boot.

**Acceptance:** Diner and Nuketown lobbies show no hellhound row and their panels look right;
Bus Depot / Farm / Town still offer hellhounds and still play them normally.

---

**Reminder: stop after each numbered item and let me boot it.**
