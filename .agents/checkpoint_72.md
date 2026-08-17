# Checkpoint 72 — v1.99.32. The SOUND rows were only ever built in the PAUSE menu, and the marker switch was silencing them.

Written 2026-08-17. **Supersedes 71 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | **INSTANT PAP is a live switch** (v1.99.30) | 🟢 **CONFIRMED IN GAME by the user**, 2026-08-17: *"the instant pap toggle option works fine so another task completed"*. Queue 20 struck. |
| 2 | **SOUND tab: HIT / KILL / CRITS / DOWNED packs** | 🔴 v1.99.31 shipped them **invisible**; v1.99.32 fixes that and decouples them from HITMARKERS. Built, byte-verified deployed, **unbooted** |
| 3 | LUI `beingAnimation` crash fix (v1.99.24) | 🟡 still unconfirmed — nothing proves the jet gun was ever overheated in a session |
| 4 | Six chat commands · COMPASS (v1.99.25/26) | 🟢 user reports the HUD-tab toggles behave |
| 5 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) | 🔴 not built |

🛑 **Still outstanding, unchanged from 70/71:** overheat the jet gun on TranZit and hold through the
cooldown. That is the one crash test.

---

## 1. WHAT THE USER REPORTED

*"the sound settings are still vanilla and don't have the toggable options for the hitmarker and
other sound effects from the technops collection mod that i requested, all the other option you
added to other menus work fine tho."*

Checkpoint 71 had called this feature verified — but every verification was of **files**: the aliases
were in `mod.ff`, the payloads in `mod.all.sabl`, the four rows in the deployed `optionssettings.lua`.
None of that tests whether the rows are ever *built*.

## 2. THE FIRST FAULT — `if InGame then`

The four rows sat behind `if InGame then` in `CreateSoundTab`, so they existed **only in the pause
menu**. The main-menu SOUND tab was untouched stock, which is exactly what "still vanilla" describes.

**The gate itself works** — that was checked rather than assumed. `UIExpression.IsInGame() == 1` is
load-bearing in this same LUI environment: it is what `LUI.createMenu.OptionsSettingsMenu` (this
file, line 1019) and stock's `OptionsMenu` use to decide between `CoD.InGameMenu.New` and
`CoD.Menu.New`, and the user's pause menu does render as an in-game menu. So this is not a broken
API; it is a feature that was deliberately shipped in half the places it belongs.

🌟 **The row-budget reason given for the gate was wrong, and measuring killed it.** The old comment
treated 14.5 row-pitches as a ceiling. That was only the largest tab *known* to render — a lower
bound. The real box, read out of the decompiled stock LUI in
`H:\Claude\POWER UP TIMERS\black_ops_2_decompiled_lua_dump\` (English, non-SP):

| constant | value | file |
|---|---|---|
| `CoD.Menu.Height` = `CoD.SDSafeHeight` | 648 | `codbase.lua:489` |
| `CoD.Menu.TitleHeight` = `textSize.Big` | 48 | `codmenu.lua:9`, `codbase.lua:153` |
| `MFTabManager.TabHeight` = `textSize.Default` | 25 | `mftabmanager.lua:6` |
| `CoD.ButtonPrompt.Height` (the ESC prompt) | 25 | `buttonprompt.lua:7` |
| `CoD.CoD9Button.Height` (one row pitch) | 30 | `cod9button.lua:3` |
| `CoD.HintText.Height` = `textSize.Default` | 25 | `hinttext.lua:5` |

`SetupTabManager` puts the content widget at `48 + 25 + 15 = 88` and stops it 25 short of the bottom;
`CreateButtonList` insets 20 more. The list is **108..623 = 515 units = 17.1 pitches**, ~16.3 once
the hint line is allowed for. The out-of-game SOUND tab with the mod's rows is 15.5 pitches = 465
units — inside the box with a full row to spare. (`CoD.InGameMenu.New` is `CoD.Menu.New` plus a
title, so both menus have the identical box.) The v1.94.0 fault the old note cited was **23.5**
pitches = 705 units, over by 190 — a different order of problem.

## 3. THE SECOND FAULT — the user's own dvar dump named it

`updatedamagefeedback()` opened with `if ( !getdvarintdefault( "hitmarkers", 1 ) ) return;` — above
the pack playback. So with the visual marker off, **every pack is silent**.

🌟 **That is this user's configuration.** `console_zm.log`'s map-load dvar dump for the 2026-08-17
session reads `hitmarkers "0"`. Shipping the menu fix alone would have produced rows that visibly
change and make no sound, and cost another boot.

v1.99.32 splits the switch:

- the packs (choice 1..8) play whether or not the marker is drawn;
- **choice 0 = DEFAULT is still gated on `hitmarkers`**, because that `mpl_hit_alert` *is* the
  hitmarker's own sound — anyone who used that switch to kill both still gets silence;
- `zmqol_perf_probe()` moved above the read so the diagnostic still kills the whole per-bullet path.

## 4. HOW THE DVAR DUMP WAS READ — reusable

`console_zm.log` carries a full **client** dvar dump at every map load. Only dvars that exist
client-side appear: `hitmarkers`, `instant_pap`, `hud_*` are there (a menu row creates them),
while `anim_pap_camo_*` and `hud_color_timer` — registered by `qol_opt_dvar()` and having no row —
are not. So the dump answers *"has this menu row ever been built on this machine?"*

🌟 **That makes the next boot self-diagnosing.** With the gate gone, the main-menu SOUND tab builds
the rows at startup, which creates the four dvars. If `hit_sound` / `kill_sound` / `crit_sound` /
`downed_sound` are **still absent** from the next dump, the block never executed and the cause is
something other than the gate. If they are present but nothing is audible, the alias table is not
the suspect (it is verified in `mod.ff`) — the payload format is.

## 5. VERIFICATION DONE (all offline)

- `gsc-tool -m parse -g t6 -s pc -y quality_of_life.gsc` → parsed clean.
- `luaparse` (5.1) on `optionssettings.lua` → clean.
- `build.bat` → 574 files packed, all 6 files deployed, LUI synced to Plutonium's `raw\`.
- Deployed `optionssettings.lua` and `mod.json` SHA256-match source; the deployed `mod.iwd` contains
  `b_markers` ×2 and no `if InGame then` around the sound block.
- No `zone_source\` / `zone_assets\` change, so `build_ff.bat` was **not** needed — `mod.ff`,
  `mod.all.sabl` and the 22 aliases are untouched from v1.99.31.

## 6. RESIDUAL RISK

1. Nothing here has been played.
2. The packs have still never been *heard*. A missing or unplayable alias is silent, never an error.
   The console (`hit_sound 3`) sets the same dvar the row does, so it separates a menu problem from
   an audio problem in one step.
3. The 15.5-pitch layout in the main-menu SOUND tab is computed, not observed. A glance at that tab
   confirms or refutes it.

---

## 7. v1.99.33 — the rows appeared, and the hint line touched the ESC prompt

The user booted v1.99.32 and the four rows are **in the main-menu SOUND tab** (SYSTEM TEST is
visible in their screenshot, so that shot is out of game). So the `if InGame then` gate was the whole
of the "still vanilla" report, and `UIExpression.IsInGame()` was never at fault.

They reported a slight collision at the bottom. **Measured off their screenshot** rather than
eyeballed — 2000×1125, so 1.5625 px per LUI unit, scanning the label column for text bands:

| element | px band |
|---|---|
| DOWNED SOUND (last row) | 964 – 993 |
| hint line, descenders included | 1023 – **1045** |
| ESC Back | **1046** – 1059 |

A one-pixel touch. Row pitch measures **50 px** and every spacer in the tab **26 px** (so the live
pitch is ~32 units, not the 30 the constants imply — the screenshot is the authority here, not the
arithmetic).

**Fix: the mod's own separator spacer is dropped.** Everything from HITMARKER HIT SOUND down lifts
26 px, leaving ~27 px of clear air under the hint line — more than the 22 px between two ordinary
rows. In game there is a further 50 px because SYSTEM TEST is absent. Cost: the four rows no longer
sit in their own visual block.

Deployed and hash-verified (source == Plutonium `raw\`, and the new copy is inside `mod.iwd`).
**Not yet re-checked in game.**
