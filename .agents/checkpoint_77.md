# Checkpoint 77 — v1.99.53. Backspeed toggle done and closed; a BIG options-menu request is QUEUED, NOT STARTED.

Written 2026-08-18. **Supersedes 76 for status.**

---

## 0. STATE — READ THIS FIRST

🛑 **NOTHING IS IN FLIGHT, AND ONE LARGE REQUEST IS WAITING TO BE STARTED.**

The user stopped work mid-session, deliberately, to wait for their usage limit to reset:

> *"DO NOT start the prompt yet, queue it up ready for the moment i re-open you in my terminal…
> and do the typical `.` full stop to get straight back in, this'll be after my usage/tokens reset…
> Checkpoint then i'll close terminal and open it up and do `.` when the limits reset."*

**So when the next session opens with `.`, the first action is §2 of this file — the queued request.
Do not re-derive it, do not ask what to work on, and do not start anything else first.**

| shipped this session | version | state |
|---|---|---|
| GAME-tab **BACKSPEED PATCH** toggle (queue item 2) | v1.99.51 | 🟢 **CONFIRMED** — *"the option for backspeed works toggling it on or off"* |
| Power-up timer text **white** | v1.99.52 | 🟢 **CONFIRMED** — *"it works fine"* |
| Row renamed **FULL MOVE SPEED → BACKSPEED PATCH** | v1.99.52 | 🟢 **CONFIRMED** — *"I like the name of the option"* |
| Description trimmed to *"Matches the console sideways and backwards movement speeds."* | **v1.99.53** | 🟡 **deployed, not booted.** The user waived testing: *"I won't even bother to test for just that, you can achieve that tiny easy task no problem i trust you."* Verified present in the deployed `mod.iwd`, old text gone. |

The queue is **7 lines** (old 2, the backspeed toggle, was closed on the user's confirmation — see
`QUEUE_LIST.md`'s Closed section, third pass, with the resurface note).

---

## 1. WHAT SHIPPED, AND THE ONE THING WORTH KEEPING

**`player_backSpeedScale` / `player_strafeSpeedScale` / `player_sprintStrafeSpeedScale` now have
exactly ONE writer** — `qol_options::qol_opt_move_speed()`, a change-only watcher on the `move_speed`
dvar. The three unconditional `setdvar` lines that used to sit in `quality_of_life::init()`'s
high_round_fix block are **gone**. If backward movement is ever wrong again, that watcher is the only
place to look. Note `zmqol_minimal 1` skips it, so under the bisect switch the speeds stay stock.

**The OFF values were measured, not guessed** — this install's own boot-time dvar dump in
`console_zm.log`: `player_backSpeedScale "0.7"`, `player_strafeSpeedScale "0.8"`,
`player_sprintStrafeSpeedScale "0.667"`. Later dumps in the same rotations show all three at `"1"`
once the mod loads, which is also the proof a plain `setdvar` reaches them at all.

**The label was renamed and the DVAR deliberately was not.** `move_speed` stays, because it was
already archived into the player's config at v1.99.51 and it is the name the console takes —
renaming it would silently reset everyone's saved setting. Same call as `whoswho_knife` at v1.99.48.

**LUI budget:** the GAME tab had **two consecutive spacers** left over from the removed HOLD TO
SPRINT group. Collapsing them to one paid for the new row. The tab is now **13 rows + 3 half-spacers
= 14.5 pitches**, exactly the proven budget (`optionssettings.lua`'s own header note: never past
14.5, a spacer counts as 0.5).

---

## 2. 🔴 THE QUEUED REQUEST — START HERE ON `.`

User, 2026-08-18, verbatim (lightly split into parts; **nothing below has been started**):

> *"…add those 4 options to the advanced tab in settings (advanced is a stock tab in the base game,
> not an additional tab added by the mod, for context), So Night Mode toggle, Fog toggle, Depth Of
> Field (this option already exists in the advanced tab, just add an extra option to set it to "OFF"
> after "LOW" … the base game already lets you see the option for the amount of DOF in the Advanced
> tab in settings, but the lowest setting you can go is to "LOW", so you'd just add one more option
> after that and it'd be "OFF" or "DISABLED", that way people wouldn't even realise that you couldn't
> turn it fully off to begin with. Again just to be clear you're removing those 4 graphical related
> options added in the custom GAME tab menu in settings and moving them to the existing Advanced tab
> which is a stock/base game tab in settings, here's a screen shot of me in the advanced tab hovering
> over the regular Depth Of Field option. So you're effectively removing/free'ing up 4 slots from the
> game tab, moving 3 of the options that you just removed to the advanced tab which should have
> enough room, and instead of adding a duplicate option called "Depth Of Field" you're just adding a
> new lowest variable for that setting, It'd go from highest amount of DOF to lowest like this:
> High > Medium > Low > Disabled/Off whatever works. Also rename the "MODEL DETAIL FIX" to "HIGHER
> DRAW DISTANCE", and in the description … just say something simple like you already are but make it
> say that prevents texture's popping in and out of the foreground with high fovs. Lastly, after all
> that's done and you've got me a version ready to playtest that you're sure will work as i've
> described, then do this: Move the "INTRO CREDITS" option from the GAME tab to the HUD tab, and also
> add a new toggleable option that also displays a disclaimer at the beginning of the game to help
> guide new players to my mod, place the setting right under or above (it doesn't matter) the INTRO
> CREDITS (Also rename INTRO CREDITS to FLASH INTRO CREDITS) option, and name this new option FLASH
> HELP DISCLAIMER. Essentially it'll just have another textual pop-up at the start of a zombies
> match, same as the intro credits flash, but this one will suggest to do .help/!help in chat to view
> all available chat commands or something like that, thus making it more user friendly."*

### Part A — move three rows GAME → stock ADVANCED
Remove from the GAME tab and re-add on ADVANCED: **NIGHT MODE** (`night_mode`), **FOG** (`r_fog`),
**MODEL DETAIL FIX** (`lod_fix`) — the last **renamed HIGHER DRAW DISTANCE**, description to say it
stops textures popping in and out of the foreground at high FOV.

### Part B — the mod's own DEPTH OF FIELD row is DELETED, and a 4th choice is added to stock's
Stock's row gets a **DISABLED** step below LOW, so the order reads HIGH > MEDIUM > LOW > DISABLED.

### Part C — only after A+B are built and believed correct
**INTRO CREDITS** moves GAME → HUD and is renamed **FLASH INTRO CREDITS**; a new
**FLASH HELP DISCLAIMER** toggle sits beside it and flashes a start-of-match line telling the player
to type `.help` / `!help` for the chat commands.

---

## 3. 🌟 RESEARCH ALREADY DONE ON PART B — do not re-derive this

All in `ui\t6\menus\optionssettings.lua`, which **this mod already fully overrides**, so the stock
ADVANCED tab is editable right there — no fastfile work, no new file.

| fact | where |
|---|---|
| The ADVANCED tab is `CoD.OptionsSettings.CreateAdvancedTab` | `optionssettings.lua:604` |
| Its DOF row is `addHardwareProfileLeftRightSelector( PLATFORM_DEPTH_OF_FIELD_CAPS, **"r_dofHDR"**, … )` | `:625` |
| Its three choices are **LOW=0, MEDIUM=1, HIGH=2**, added in that order by `Button_AddChoices_DepthOfField` | `:489-493` |
| 🌟 **`addChoice` takes a CALLBACK as its 4th argument** — `addChoice(label, value, nil, fn)`. Stock's own `Button_AddChoices_VoiceChat` proves it | `:484-486` |
| The mod's own GAME-tab DOF row is a **different dvar**, `r_dof_enable` (0/1) | `:1002` |
| `ResetDvars()` does `Engine.Exec("reset r_dofHDR")`, so r_dofHDR is a real dvar as well as a profile value | `:182` |
| Plutonium's `dvar_descriptions.json`: `r_dofHDR` = *"dof mode"*; `r_dof_enable` = *"Enable the depth of field effect"*; `r_dof_tweak` = *"…overrides r_dof_enable"* | — |

**The design problem to solve, stated plainly:** the ADVANCED rows are **hardware-profile**
selectors, and the row is bound to `r_dofHDR`, while full-off is a *different* dvar
(`r_dof_enable 0`). So a DISABLED step has to either (a) write an extra `r_dofHDR` value and have
something translate it, or (b) hang a **callback** on each choice that sets `r_dof_enable` — 0 for
DISABLED, 1 for the other three. **(b) is the route with stock precedent** (`VoiceChatCallback`).

🛑 **Unresolved and it must be settled before writing (b):** whether an out-of-range value written
to a hardware profile is **clamped by the engine** — if it is, a `r_dofHDR = 3` DISABLED step would
read back as HIGH the next time the menu opens and look broken. Prefer a design that never writes an
unknown value to `r_dofHDR` at all.

### 🛑 THE OPEN LEAD THAT MUST BE CHECKED BEFORE MOVING THE FOG ROW
`console_zm.log` (live file, ~line 866-886) carries **`r_fog is cheat protected`**, five times.
That was being read when the session stopped — **it is not yet understood**. It may mean the FOG row
only works because something else in the mod grants it, or that it fails in some sessions. **Read
that context before the FOG row is moved anywhere**, or the move will be blamed for a pre-existing
fault. (Related: `t6-filmusetweaks-kills-visionsets`, and the `.fog` failure recorded in `CLAUDE.md`.)

### Layout budget after the move
GAME loses 4 rows and gains nothing: 13 → 9 rows. ADVANCED currently has 11 rows + 4 half-spacers
= 13 pitches, and gains 3 → **16 pitches, which is OVER the proven 14.5.** 🛑 **This must be measured
against a tab that renders correctly before shipping** — ADVANCED is a stock tab and may have its own
budget, but the v1.95.0 overflow bug (rows drawing over the ESC prompt) is exactly what happens when
this is assumed. Part C then moves INTRO CREDITS out of GAME too (9 → 8).

---

## 4. RESIDUAL RISK (carried from 76, unchanged)

1. `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob — **still open, still unworked**, the oldest live
   fault in the project.
2. The LUI `beingAnimation` crash fix (v1.99.24) is **still unconfirmed** — the jet gun has never been
   overheated in a test.
3. Three things survive their closed parent items and are **the user's call, not to-dos**: Who's Who
   on **Origins** (43 absent assets), the Titus's `fly_titus_futz` / `fly_tar21_futz` (defined in no
   bank in the game), and the freezegun's non-lethal hit marker.

## 5. THIS SESSION'S VERSIONS

`v1.99.51` BACKSPEED PATCH toggle · `v1.99.52` white power-up timers + the rename ·
`v1.99.53` description trim. Commits `b5daa58`, `3a5a0b2`, and the v1.99.53 commit below.
