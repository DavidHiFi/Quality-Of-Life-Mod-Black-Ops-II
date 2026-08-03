# Wunderfizz sound — the one job that needs Sound Studio

**Goal:** make the Wunderfizz machine audible on all six maps. It is silent everywhere except
Origins today, and no amount of GSC or zone work can fix that — see "Why" below.

**Who does what:** everything that can be done offline is done. What is left is a GUI import in
**Black Ops II Sound Studio Extended**, which has no CLI, so it has to be you.

---

## What is already done

| | |
|---|---|
| Source audio | `source\*.flac` — already extracted, you do **not** need to pull it out of a `.sabs` yourself |
| WAVs, in place | `<project>\sound\zmb\level\zm_tomb\random_perk_machine\*.wav` — the exact tree `FileSource` points at |
| Alias rows | `mod.all.aliases.additions.csv` — 4 rows, 60 columns, ready to import |
| Field values | copied verbatim from a **known-good shipping alias**, not invented (see below) |

## The folder layout (verified against BO2-Reimagined)

This mod now mirrors Reimagined's, because Reimagined is the working reference for exactly this job:

```
soundbank\   the alias CSVs        - what Sound Studio imports
sound\       the raw WAV tree      - what FileSource resolves against
```

**`FileSource` drops the `raw\` prefix and resolves from the project root.** Confirmed by example:
Reimagined's `zmb_perks_packa_ticktock` has
`FileSource = raw\sound\evt\zombie_global\pap\loop.LL55.pc.snd.wav`, and the file sits at
`BO2-Reimagined\sound\evt\zombie_global\pap\loop.LL55.pc.snd.wav`. So `raw\sound\...` → `<project>\sound\...`.

**Neither folder ships.** Reimagined's `build.bat` copies only `ff, iwd, sabs, sabl, json`, and this
project's `pack_iwd.ps1` packs only `attachmentunique, character, images, maps, scripts, ui_mp,
weapons`. They are build-time source, like `zone_assets\`. Importing a WAV into `sound\` therefore
does **not** by itself put the sound in the game — Sound Studio still has to build it into
`mod.all.sabl`. That is the step that cannot be automated.

---

## Why this is needed at all

`wunderfizz.gsc::wunderfizzSounds()` plays `zmb_rand_perk_start` / `_loop` / `_stop`. Those aliases
live **only in `zmb_tomb.all`**, which is Origins' bank and is not loaded on any other map.
`console_zm.log` confirms it: a Nuketown run loads `zmb_patch.all`, `cmn_root.all`,
`zmb_code_post_gfx.all`, `zmb_patch_ui.all`, `zmb_common.all`, `zmb_nuked_real.all`, `mod.all`,
`deathmachine_zm.all` — and nothing else.

**🛑 Declaring `soundbank,zmb_tomb.all` in the zone does NOT work.** That was tried in v1.19.0 and it
made Origins unbootable:

```
COM_ERROR (1) Attempting to override asset 'zmb_tomb.all'
              from zone 'mod' with zone 'zm_tomb'
```

`mod.ff` loads first, so the map's own copy is refused, and T6 treats a duplicate soundbank asset as
fatal. Reverted in v1.21.2. There is no conditional form — one `mod.ff`, every map.

The remaining route is the mod's own `mod.all`, which already loads on every map and collides with
nothing.

### This is the EASY case, and that matters

The open question in `.agents\sound_work_notes.md` was whether a mod bank's alias can **override** a
stock one. **That question does not apply here.** `zmb_rand_perk_*` does not exist in any bank loaded
off Origins, so we are **adding** an alias, not shadowing one — exactly what
`deathmachine_zm.all` already proves works (it is how the Death Machine gets its firing sound).

So this should work. If it does, it also settles the shadowing question separately later.

---

## The aliases

| alias | source file | looping | used by |
|---|---|---|---|
| `zmb_rand_perk_start` | `rand_perk_mach_start.flac` | nonlooping | `wunderfizzSounds()` |
| `zmb_rand_perk_loop` | `rand_perk_mach_loop.flac` | **looping** | `wunderfizzSounds()` |
| `zmb_rand_perk_stop` | `rand_perk_mach_stop.flac` | nonlooping | `wunderfizzSounds()` |
| `zmb_rand_perk_leave` | `rand_perk_mach_leave.flac` | nonlooping | stock only — optional, include for completeness |

All four are small (105–704 KB), so they are set `Storage=loaded` and go in **`mod.all.sabl`** only.
`mod.all.sabs` does not need rebuilding.

### Where the field values came from

Every column except `Name`, `FileSource` and `Looping` is copied **byte-for-byte** from
`zmb_perks_packa_ticktock` in `BO2-Reimagined\soundbank\mod.all.aliases.csv` — a *looping
perk-machine* sound in a shipping mod. Verified by diff: only those three fields differ.

That means the distances, bus, volume group, ducking and priority are all values Treyarch actually
uses for a perk machine, not guesses. Relevant ones:

```
Storage=loaded   Bus=bus_fx        VolumeGroup=grp_ambience   DuckGroup=snp_ambience
VolMin/Max=75    DistMin=75        DistMaxDry=250             DistMaxWet=325
PanType=3d       Looping=looping   Pauseable=yes              Timescale=yes
```

`DistMaxDry=250` means audible within ~250 units — same as the Pack-a-Punch tick. If the Wunderfizz
turns out too quiet from across a room, raise `DistMaxDry`/`DistMaxWet` and rebuild; nothing else
depends on those numbers.

---

## Steps

1. ~~Convert the FLACs to WAV~~ — **done**, and the WAVs are already sitting at
   `<project>\sound\zmb\level\zm_tomb\random_perk_machine\`, which is exactly where the CSV's
   `FileSource` column points. Nothing to move.

2. **🛑 Open `mod.all.sabl`, NOT `mod.all.sabs`.** The CSV sets `Storage=loaded`, and loaded aliases
   live in the `.sabl`. The mod ships both banks and the game loads both — the log shows
   `Soundbank mod.all has load asset bank mod.all.sabl` *and* `stream asset bank mod.all.sabs` — so
   either would work, but the file has to match the field.
   If you would rather use the `.sabs`, that is fine: change `Storage` from `loaded` to `streamed`
   in all four rows and use `mod.all.sabs` instead. That single field is the only edit needed.
   Work on a copy either way.

3. **Import `mod.all.aliases.additions.csv`.** These are *additions* — do not replace the existing
   alias table or you will lose the Death Machine and every other sound the mod already ships.

4. **Rebuild the bank** and put it back at the project root, overwriting the old one.

5. **`build.bat`** — it copies the bank to `build\zm_qol\` and the Plutonium mods folder. No
   `build_ff.bat` needed; the zone already declares `soundbank,mod.all` and that line does not change.

---

## Verifying it worked

1. Load **Farm** (not Origins — Origins has the sounds natively and proves nothing).
2. Buy from the Wunderfizz. You should hear the spin start, loop while it cycles, and stop.
3. If silent, check `console_zm.log`:
   - `Attempting to load soundbank mod.all` should be present (it always is).
   - A missing alias is silent, not an error, so absence of errors means nothing here.

If it is still silent, the likely causes in order: the alias name is misspelled, the WAV was not
found at import time so the alias has no payload, or `Storage` was left `streamed` (it must be
`loaded` for `mod.all.sabl`).

---

## While you are in there — two other things

Both are separate from the Wunderfizz and neither is set up yet; mentioned so one GUI session can
cover them if you want.

- **`zmb_cherry_explode`** — Electric Cherry's reload sound, same problem, same fix. Source:
  `BO2 Files Organized By Volkz\Sounds\zmb_alcatraz.all.sabs\...\cherry_jingle.flac`. Nothing in
  this mod's GSC plays it directly (stock's Electric Cherry code does), so it only matters on the
  maps where we add that perk.
- **Menu music looping** — a *different* class of problem. Looping is an **alias field** (`Looping`,
  column 32), not a property of the audio, so replacing a `.snd` payload never makes a track loop.
  That one needs an alias edit, which is also Extended-only. See `.agents\sound_work_notes.md` §2 —
  and note its open question: a Plutonium mod loads when a match starts, so it may not be able to
  touch front-end music at all.
