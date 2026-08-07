# Checkpoint 21 — v1.61.1. Origins Wunderfizz replaced; the perk HUD is ours now.

Written 2026-08-08. Supersedes checkpoint 20 (v1.57.5), 25 commits ago.
Keep 20 for §1 (the four working rules) and §2 (engine limits).
Keep 19 for the Plutonium session-mode trap and lossy decompiles.
Keep 18 §5 (Zombie Blood assets). Keep 15 §2 (mod.ff ownership).

**Read §0 and §4. §4 is the one that would have saved this whole session.**

---

## 0. THE SINGLE NEXT ACTION

**Boot Diner and look at the perk icon row.** v1.61.1 resized it from
measurement (20x20 units, 21 spacing, y -72). If it is still wrong, say
bigger/smaller — it is now a one-number change.

Then work `.agents\QUEUE.md` top down.

---

## 1. WHAT SHIPPED AND IS CONFIRMED IN GAME

| version | change | user's words |
|---|---|---|
| v1.58.x | **Origins' Wunderfizz replaced with the mod's** | "looks perfect, works perfect" (of the FX/ball) |
| v1.59.5 | **night_mode works** | "night mode works" |
| v1.59.9 | textures/zombie eyes restored after my regression | "textures seem to be normal and the eyes as well" |
| v1.61.0 | **PhD-icon spam FIXED** — mod draws the perk row | "that issue is solved" |

Also shipped, NOT yet verified: `.nightmode` chat command, `fly` console
dvar (`bind x "toggle fly 0 1"`), fog default ON + `.fog on/off`, fly
chat-resync, MP40 stalker retag, v1.61.1 icon sizing.

---

## 2. THE ORIGINS WUNDERFIZZ — how it works now

Native machines are **suppressed, not deleted**:
`zm_tomb.gsc::main()` replaceFuncs `_zm_perk_random::init_machines` and
`::start_random_machine` to an empty body, and hides the six entities
(`setmodel("tag_origin")` + `hide()`).

🛑 **`_zm_perk_random::init()` MUST keep running** — its six
registerclientfield calls must match the client or every player is dropped.
Only the machine *setup* is suppressed.

🛑 **Never delete those six entities.** `zm_tomb_capture_zones.gsc` builds
per-zone arrays from them and sets `.is_locked` as generators come and go.
That IS the generator gating; the mod's machines read it back through
`zmqol_wf_tomb_locked()`. Delete them and the gating dies.

Positions are read from the map at runtime — **there are SIX**, not four
(a comment in `wunderfizz.gsc` claimed four and was wrong).

---

## 3. 🛑 ORIGINS IS OUT OF CLIENTFIELD SPACE — PROVEN, DO NOT RE-LITIGATE

| set | Origins | consequence |
|---|---|---|
| `scriptmover` | **32/32** — it *sets* the game-wide max | Vulture's 4-bit field cannot fit |
| `actor` | 31/32 | Vulture's 2-bit field cannot fit |
| `toplayer` | 0 free with Vulture in | Tombstone needed 2 bits |

Measured two ways: across **all 48 per-map dumps** nothing exceeds 32 in
actor/scriptmover, and the ceiling was hit for real
(`zone_capture_zombie ... ACTOR is out of space`).

**Vulture Aid is therefore OFF on Origins** (v1.59.0) — it could never be
complete there, and the user's rule is perfectly or not at all. Origins runs
**11 perks, all complete**. Vulture is untouched on the other four maps.

---

## 4. 🌟 THE LESSON OF THIS SESSION — READ THE SHIPPED CODE, NOT THE DOCS

Four features took three or more attempts each, and **every single failure
was the same mistake**: reasoning from what an API *should* do instead of
opening the working example already in the workspace.

- **night_mode** — 3 failed attempts. I inferred from Plutonium's
  `dvar_descriptions.json` that the `vc_*` dvars "do not exist" because they
  were absent from it. That file *documents* dvars; it does not enumerate
  them. The fix was sitting in
  `BO2-GSC-Releases\Zombies Mods\Nightmode\Source Code\_zm_nightmode.gsc`
  the whole time. **The real bug was a duplicated `vc_rgbh` line in Remix**
  that this mod had faithfully copied.
- **the sky balls** — LOD theory shipped and failed; the cause was my own
  `shut_down` animation parking the ball on a bone.
- **the MP40 retag** — shipped against `getstructarray()` in `main()`, where
  the struct list is still empty. Its own probe said `0 of 0`.
- **the m1911 texture fix** — `image,,name` does NOT mean "referenced". OAT
  made an asset literally named `,name`. It broke textures across two maps.

**What worked, every time: measure, then change.** The two perk probes
eliminated the entire server side in two boots after four wrong guesses.

📝 **Absence from a description list is not absence from the engine.**
📝 **A probe that costs one boot beats a fix that costs three.**

---

## 5. THE PERK HUD IS THE MOD'S NOW

The engine's perk row rendered every perk as PhD Flopper. Everything script
controls was verified correct first — 158 logged `set_perk_clientfield`
calls all correct, 12 fields registered with no duplicates, server/client
registration lists diffed identical, `getperkshader()` giving 12 distinct
shaders. The fault was inside engine code bound by
`setupclientfieldcodecallbacks`.

So the engine is no longer told to draw it:
- **client** — `zm_expanded.csc` no longer calls `perk_init_code_callbacks()`.
  🛑 This cannot desync: `registerclientfield` is untouched, and the server
  never calls `setupclientfieldcodecallbacks` either.
- **server** — `zmqol_perk_hud_think()` draws the row from `hasperk()` +
  `getperkshader()`, polled at 0.05s on a signature compare, rebuilt only on
  change, one instance per player.

🛑 **HUD elements use a 640x480 VIRTUAL space, not pixels.** 32 units is
~96 real pixels on 1920. Measured from a screenshot of the engine's own row:
icon ~19 units, spacing ~20, bottom edge ~72 up.

---

## 6. STILL OPEN

`.agents\QUEUE.md` is the authority. Headline items:

- **Solo behaves as a custom game** — no intro cutscene, menu header still
  says "CUSTOM GAMES". User has asked twice.
- **God mode drops after Mob's afterlife**, while the command still reads on.
- **Mob Wunderfizz overlaps the shield part spawn.**
- **Custom texture packs conflict** — `mod.ff` declares 776 header-only
  images and loads before the map, so a player's own `.iwi` is read through
  our header. The m1911 attempt at this FAILED and was reverted; needs a
  different approach.
- Stray **254 MB `cmn_root.all.sabl`** in `build\zm_qol\` — not one of the 6
  mod files, should not be zipped to anyone.

---

## 7. REPO IS PUBLIC NOW

`https://github.com/DavidHiFi/zm_qol` — made public 2026-08-07 for a beta
tester. `mod.iwd` is gitignored, so a clone needs `build.bat` before it is
playable. 174 commit messages contain `claude.ai/code/session_...` trailers,
now publicly visible; the user was told and has not asked for them removed.

---

## 8. USER PREFERENCES SET THIS SESSION

- **Replies must be SHORT** — ADHD; no wall of text, clear "do this next" at
  the end, keep the load-bearing numbers. In memory as `user-summary-style`.
- **Never widen a file operation's scope** — moving `TestCord` unasked broke
  their Discord. In memory as `scope-never-widen-file-operations`.
- Read the logs yourself; never ask them to paste lines.
  `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`, screenshots at
  newest in `G:\Gallery`.
- `developer_script 1` (NOT `developer 1`, which makes stock `/# #/` dev
  blocks execute and stops you testing the shipping build).
