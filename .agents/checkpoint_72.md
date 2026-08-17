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

---

## 8. v1.99.34 — TARGET ASSIST: two switches in series became one

User, 2026-08-17: the lobby's TARGET ASSIST row is redundant against CONTROLS > GAMEPAD > TARGET
ASSIST, *"and make the other option in controls > gamepad toggle both those options' states … or
just simply remove the option from the pre-game lobby menu."*

**They are not duplicates — they are a permission and a setting, wired in series.**

| where | writes | what it means |
|---|---|---|
| lobby row | `sv_allowAimAssist` (dvar) | may controller players use aim assist in this match |
| CONTROLS > GAMEPAD | `input_targetAssist` (profile) | this player's own switch |

🌟 **Plutonium's own file proves the dependency the user suspected.** `optionscontrols.lua.aside`
line 389: `if UIExpression.IsInGame() == 1 and UIExpression.DvarBool(nil, "sv_allowAimAssist") == 0`
→ the GAMEPAD row is replaced by a **locked** row reading *"Target Assist is disabled on this
server."* So with the permission off, the real setting cannot be reached in game at all.

🛑 **The obvious implementation was rejected.** Making the GAMEPAD row write both dvars means
shipping this mod's own `optionscontrols.lua`, and a shipped copy **shadows** Plutonium's patched
one — the exact mechanism that deleted RAW INPUT, MOUSE ACCELERATION and FIX HIGH POLL RATE LAG from
the user's CONTROLS menu once already (checkpoint 48 §4), and it would go stale on their next
update. Three working rows for one is a straight loss.

**What shipped instead:** the lobby row is removed and the permission is simply always granted, so
`input_targetAssist` is the only switch left standing — same end result, nothing shadowed.

- `privategamelobby_project.lua`: `Dvars[1]` (sv_allowAimAssist) deleted; `sv_cheats` and
  `perk_limit` renumbered to 1 and 2. 🛑 `AddGameOptionsButtons()` walks the table with
  `for i = 1, #GameOptions`, so deleting without renumbering would have truncated the list at the
  hole. `DvarDefaults["sv_allowAimAssist"] = 1` is **kept** — `dvarleftrightselector.lua` reads it
  only to decide whether to draw the ⭐ "differs from default" icon, never to write the dvar.
- `qol_options.gsc::init()`: `setdvar( "sv_allowAimAssist", 1 )`, **last in the function** so a hard
  failure could only cost itself, not the five threads above it.

🌟 **The default was confirmed to be 1 two ways** before relying on it: Plutonium's own
`DvarDefaults` table, and the user's lobby screenshot showing TARGET ASSIST **ENABLED with no star**
beside it. It is written explicitly anyway rather than resting on a default this project does not own.

📝 Cost, recorded rather than hidden: on a dedicated server that deliberately forbids aim assist,
this re-permits it. zm_qol ships through the Mods menu as a solo/private mod.

📝 The lobby list is now one row shorter, which is what the user wanted the room for.

**Verified:** `gsc-tool` and `luaparse` clean; no `Dvars[3]` and no `sv_allowAimAssist` row survive
in the deployed `mod.iwd`; the lobby LUI hash-matches Plutonium's `raw\` copy. **Unbooted.**

---

## 9. v1.99.35 — the custom title screen: the file was broken, not the shipping

User: *"menu_zm_title_screen.iwi … i don't see the texture streamed at all, make sure you're shipping
that texture .iwi file into the mod as well."*

**It was already shipping.** The `.iwi` was in `images\` and inside the deployed `mod.iwd` the whole
time. The file itself was invalid — which is also why their DDS converter answered `fatal error -8`.

🌟 **The IWi v27 header layout, settled by arithmetic rather than by a spec sheet.** Reading byte 4
as flags and byte 5 as format gives `format 0` for files that demonstrably work, so the order is the
other way round: **byte 4 = format, byte 5 = flags**. Confirmed on `camo_off_solid.iwi` — 16×16
DXT5 with mips is 256+64+16+16+16 = 368 bytes of payload, and the file is 432, i.e. exactly a
**64-byte header**. Every working `.iwi` in this project fits that.

| file | format | size | |
|---|---|---|---|
| the user's copy (from `TechnoOps-Collection\menu_zm_title_screen.iwi`) | **0** — invalid | 524,372 | 20 stray header bytes |
| `BO2-Reimagined\images\menu_zm_title_screen.iwi` | 13 = DXT5 | 524,352 | works |
| stock `.dds` dump | DXT5 1024×512, no mips | 524,416 | the spec |

🌟 **A loose `.iwi` in `images\` IS enough to replace a stock texture — no fastfile entry.**
BO2-Reimagined ships this exact file that way and declares nothing in its zone (checked: no
`menu_zm_title_screen` in any `.zone` in the workspace). So `mod.ff` was left alone.

**The conversion route, now known to work end to end:**

1. `ImageConverter.exe --t6 <file>.dds` → `.iwi`. It takes **DDS only** (`ERROR: Unsupported
   extension .png`), and on the stock DDS it produced exactly 524,352 bytes — the same size as
   Reimagined's working file.
2. Nothing on this machine compresses PNG → DXT5 (no texconv, nvcompress or ImageMagick; the
   `convert` on PATH is Windows' filesystem tool). So `.agents\..\scratchpad\dxt5.js` does it:
   bounding-box endpoints, 8-value alpha, and the **128-byte DDS header copied from the stock
   file**, whose dimensions and format are identical — so only the payload is ours.
3. 🛑 **The encode was measured, not trusted.** `verify.js` decodes the DXT5 back and diffs it
   against the source PNG: **mean RGB error 0.000/255, worst 0.0, mean alpha error 0.053**. A bad
   encoder is otherwise silent — the `.iwi` would be the right size and the wrong picture.

Result: `ver=27 fmt=13 flags=2 1024×512 size=524,352`, header-identical to Reimagined's working
file, byte-identical between source and the deployed `mod.iwd`.

📝 **Residual risk, stated rather than discovered:** the ZM main-menu background is drawn by stock
`ui_mp\t6\mainmenu.lua:104` (`RegisterMaterial("menu_zm_title_screen")`) — a file this mod does not
ship. If the image is loaded once at startup, before the mod's `mod.iwd` joins the search path, it
may only appear after the mod is loaded rather than on the very first frame of the front end. If it
never appears, the next step is making `mod.ff` own `material,menu_zm_title_screen` (the stock
material JSON can be dumped from `ui_zm.ff`, which owns both the image and the material).

---

## 10. v1.99.36 — the corrected title screen (and how the artwork was checked)

v1.99.35 proved the pipeline: the user confirmed the texture streams in the ZM main menu with the
mod loaded, so **a loose `.iwi` in `images\` really does replace a stock texture, no fastfile entry**
— and it appears without a restart once the mod is loaded. Their first edit simply replaced the
whole logo with "QUALITY OF LIFE"; the intent was a subtitle under the stock BLACK OPS II ZOMBIES,
the way Reimagined does it.

**The stock artwork was handed back as an editable PNG.** `scratchpad\dds2png.js` decodes the DXT5
dump to RGBA. 🛑 It reads alpha out of the **DXT5 alpha block**, not from the DDS pixel-format flags
— the workspace dump declares no alpha while carrying a full 0..255 range ([[t6-dds-dump-undeclared-alpha]]),
so a normal converter would have flattened the logo onto an opaque brown rectangle. Measured layout
handed over with it: solid lettering x 15..1008, y 117..431, leaving 80 px clear below ZOMBIES.

**The returned art was verified before it was shipped, not after.**

| check | result |
|---|---|
| geometry / format | 1024×512, PNG colour type 6 (RGBA), alpha 0..255 ✅ |
| opaque blue rectangle behind the subtitle? | **0.0%** of pixels are opaque *and* blue |
| visible blue tint | 22,026 px at alpha ≥ 80, all inside rows 384..511 — the subtitle's own navy (30,30,46) anti-aliasing, not a backdrop |
| what the game will actually draw | composited over a simulated menu background to a preview PNG and looked at: logo intact, orange II intact, subtitle reads like Reimagined's |

🌟 **The DXT5 encode was baselined, not just measured.** On the user's art: mean RGB error
**1.690/255**, alpha 0.325. On the *stock* artwork through the same encoder: **0.757/255**. Same
order — the loss is ordinary DXT5 on grungy 1024×512 art, not an encoder fault. (The worst-block
error of 74 sits on a hard colour edge, which is what DXT5 does everywhere.)

Deployed `.iwi`: `ver=27 fmt=13 flags=2 1024×512 524,352` — header-identical to Reimagined's working
file — and byte-identical between source and the deployed `mod.iwd`.

📝 **Reusable route, now proven end to end:** PNG → `scratchpad\dxt5.js` (DXT5 payload under the
stock file's own 128-byte DDS header) → `ImageConverter.exe --t6` → `.iwi` → `images\` →
`build.bat`. `verify.js` decodes the result back and diffs it against the source PNG; `dds2png.js`
goes the other way for editing.

---

## 11. v1.99.37 — the glow WAS the encoder, and the fix is measured

User: the outer glow under QUALITY OF LIFE is deliberate, and in game it came out *"a blocky mess"*.

🛑 **It was mine, not theirs.** Decoding v1.99.36's own `.dds` back and cropping the subtitle band
against the source PNG showed textbook 4×4 blocking in the glow while the source was smooth. The v1
encoder picked colour endpoints from the **per-channel bounding box**, which invents a corner colour
no pixel in the block actually has — fine on grungy logo art, visibly wrong on a soft low-contrast
gradient.

🌟 **The flat error metric hid it, and would have hidden the fix too.** Unweighted mean RGB error
called v2 *worse* than v1 (1.973 vs 1.690) because it counts fully transparent pixels, whose colour
nobody can see, exactly as much as the glow. Re-scoring **weighted by alpha** — error where it is
actually visible — inverted the ranking and is what the encoders were then tuned against.

| encoder | visible-weighted RGB err | subtitle band |
|---|---|---|
| v1 bounding box (shipped in .35/.36) | 1.700 | 1.611 |
| v2 + PCA axis, alpha-weighted, least-squares refine | 1.561 | 1.527 |
| **v3 + ±1 endpoint local search in 565 space** | **0.919** | **0.634** |

The last step is the one that mattered: least squares finds the right colour **axis**, but rounding
the endpoints to 5/6/5 bits is what bands a gradient, and a one-step search over each endpoint
channel recovers most of it — 2.5× better where the glow lives. Confirmed by eye as well as by
number: the crop of v3 is indistinguishable from the source, v1 is blotchy.

Alpha was never the problem (0.40/255 through the glow in every version) and the alpha block is
unchanged.

📝 **The three tools now live with the project** rather than in a scratch folder, because this will
come up again:

| `.agents\tools_dxt5_encode.js` | PNG → DXT5 DDS (PCA + LSQ + local search, alpha-weighted) |
| `.agents\tools_dds2png.js` | DDS → editable RGBA PNG, alpha read from the DXT5 block |
| `.agents\tools_dxt5_verify.js` | decodes a DDS back and scores it **alpha-weighted** against the source |

Route: PNG → `tools_dxt5_encode.js` (payload under the stock file's own 128-byte DDS header) →
`ImageConverter.exe --t6` → `.iwi` → `images\` → `build.bat`. Needs `pngjs` (`npm install pngjs`).

Deployed `.iwi`: `ver=27 fmt=13 flags=2 1024×512 524,352`, byte-identical to source inside `mod.iwd`.
