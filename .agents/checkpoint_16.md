# Checkpoint 16 — v1.32.0. The Wunderfizz rebuilt, and sound is the wall.

Written 2026-08-03. Supersedes checkpoint 15. Keep 15 for its §2 (the
asset-ownership trap) — that diagnosis still stands and is now *acted on*
rather than merely avoided.

**Read §0, then §3 — §3 is the live blocker and the user's stated next
ambition.**

---

## 0. THE SINGLE NEXT ACTION

**Find out where Plutonium searches for soundbank FILES.** Everything the user
wants next depends on it, and the last command of the session was cut off
mid-answer.

The breakthrough, one line from `console_zm.log`:

```
SOUND Header load success for F:\SteamLibrary\...\sound\cmn_root.all.sabl : d6970e932b2bef5b4ded5948bcdc31fe
```

**The log prints the FULL PATH and an MD5 for every bank it loads.** That is
the diagnostic that had been missing all along — no more guessing whether an
override took.

It proves the v1.25.0 experiment FAILED: `cmn_root.all.sabl` sits in the mod
folder (267 MB, deployed, confirmed on disk) and the game loaded Steam's copy
anyway. **A mod folder is not searched for stock bank names.** The user
confirmed independently: "the gun mod sound effects don't seem to be taking
place, all the gun sounds seem to be regular."

The unfinished command was:

```bash
grep -ao "SOUND Header load success for [^:]*" console_zm.log | sed 's/SOUND Header load success for //' | sort -u
```

Run that. It lists every path the engine actually loaded, which reveals the
search order — including where `mod.all.sabl` and `deathmachine_zm.all.sabl`
come from, and that is the one place a mod-supplied bank is known to work.

---

## 1. WHAT SHIPPED — v1.22.0 → v1.32.0

| ver | change |
|---|---|
| 1.23/1.24 | **Wunderfizz model rebuilt under mod-private names** — the big one, see §2 |
| 1.25.0 | Carbon `cmn_root.all.sabl` as an optional mod-folder file — **now known not to work** |
| 1.26.0 | ball spin (animtree + 4 xanims) — **broke every map** |
| 1.26.1 | animtree registered on the CLIENT too — the fix |
| 1.27.0 | `mod.json` colours: name `^5`, author/version `^3`, description `^9`/`^8` |
| 1.28.0 | `.fly` horizontal via buttons; fx rescale |
| 1.29.0 | Wunderfizz substitute sounds off Origins |
| 1.30.0 | **Mule Kick prone bonus**; fx retrigger |
| 1.31.0 | **`.fly` real WASD** via `notifyonplayercommand`; fx dialled down |
| 1.32.0 | **9-perk cap removed**; spin sound; spin fx |

---

## 2. ✅ THE ASSET-RENAME PIPELINE WORKS — this is the reusable win

Checkpoint 15 said shipping a map-owned asset globally needed "mod-private
names" and left it as theory. It is now built and shipped:

```
xmodel    qolwf_vending_diesel_magic
material  mc/mtl_qolwf_*                     (7)
image     qolwf_*                            (23)
rawfile   animtrees/qolwf_perk_random.atr
xanim     qolwf_diesel_{turn_on,turn_off,on_idle,ballspin_loop}
```

Audited every build: **119 added, 53 colliding, ZERO of the collisions ours.**
Origins is untouched. Full recipe in `[[t6-oat-asset-rename-pipeline]]`; the
three traps that each cost a cycle:

- **The mesh must be GLB.** The Linker cannot compile `.xmodel_bin` *or*
  `.XMODEL_EXPORT` — even an untouched dump of a stock model fails.
- **GLB material renames must be byte-length-identical** (`p6_zm_tm_` →
  `qolwf_tm_`); a glTF chunk stores its own length.
- **DDS must be A8B8G8R8, not A8R8G8B8.** The latter converts *without error*
  to IWI format 0, which the Linker later rejects. Pixels come from the
  workspace texture dumps — a `.ff` holds headers only and OAT cannot read
  ipaks.

**xanims and animtrees rename trivially** (a xanim's identity is its filename;
`.atr` is plain text). **fx cannot be renamed at all** — see §3.

---

## 3. 🛑 SOUND — THE WALL, AND THE USER'S NEXT PROJECT

The user's closing message: they want to be able to ship replacement game
sounds **inside the mod**, so unloading the mod restores vanilla. They
explicitly asked to build up real expertise here. Treat this as the main
thread of the next session.

### What is established

- **`soundbank,<stock name>` in the zone is fatal.** `code_post_gfx_zm.ff`
  owns `soundbank,cmn_root.all` and loads on every map →
  `COM_ERROR Attempting to override asset ... from zone 'mod'`. Same mechanism
  that made Origins unbootable in v1.21.2 with `zmb_tomb.all`.
- **A mod-folder file does NOT override a stock bank** — §0.
- **Black Ops II Sound Studio Extended is a payload REPLACER, not an alias
  editor.** Its table is Name/Offset/Size/Format/Hash/Replaced with a Replace
  Manager. It **cannot create** an alias. Two commits were written on the wrong
  assumption before the user's screenshot settled it. It shows a custom bank's
  entries as "Sound #1.flac" because it has no identifier file for it.
- **The audio dumper** (`H:\Claude\Black Ops II Audio Dumper v6`) is
  effectively CLI — it dumps every `.sabl`/`.sabs` in its working directory —
  and ships `Identifiers\*.txt` mapping hash → **source file path** (not alias
  name).
- **`mod.all.sabl` / `.sabs` / `deathmachine_zm.all.sabl` DO load from the mod
  folder**, because `mod_base.zone` declares them. That is the one proven
  channel for mod-supplied audio.

### 🛑 A correction to trust levels

`BO2-Reimagined\soundbank\mod.all.aliases.csv` was treated as a dictionary of
valid stock aliases. **It is not** — it is the alias table of *Reimagined's own
bank*, so an entry there does not prove the alias exists in a stock bank.
`zmb_tombstone_looper` was picked from it for the v1.32.0 spin loop and the
user reports **no sound at all**. It is still an excellent source for the
**field schema** and for realistic per-field values.

Aliases that ARE proven to work off Origins (played by this mod, heard in
game): `zmb_cha_ching`, `zmb_perks_packa_upgrade`, `zmb_perks_packa_ready`,
`zmb_perks_packa_ticktock`.

### The staging that is already done

`soundbank\` holds the 4 Wunderfizz WAVs, the extracted FLACs, an alias CSV,
and a README. `sound\zmb\level\zm_tomb\random_perk_machine\*.wav` mirrors the
verified `FileSource` convention (`raw\sound\...` → `<project>\sound\...`,
confirmed against Reimagined). All still valid — only the "import it in Sound
Studio" instruction was wrong.

---

## 4. STILL OPEN — user-reported, in their words

1. **"no sound effect when you spin a perk"** — v1.32.0 regressed it by
   switching to `zmb_tombstone_looper`. Revert to `zmb_perks_packa_ticktock`
   (proven audible) unless a better *proven* alias is found.
2. **"the electric fx when you spin also absent"** — the retrigger thread
   `zmqol_wf_spin_fx()` did not draw. Suspect
   `fx_alcatraz_electric_cherry_trail` renders nothing static (a *trail* fx may
   need motion).
3. **"it's gotta look just like the real origins wunderfizz"** — ⚠️ **This is
   not achievable and the user has not been told plainly enough.** OAT can
   neither dump nor compile an `FxEffectDef`; the only way to satisfy an fx is
   to `--load` the zone that owns it, which is the collision that breaks
   Origins. Everything shipped is a stand-in. **Recommend offering: drop the fx
   entirely** (real model + real ball spin + sound) rather than a fifth guess.
4. **Gun sounds** — §0.
5. **`.fly` WASD (v1.31.0) — never tested.** Probe prints
   `[zm_qol] fly wasd: f=..`. If the flags stay 0 while keys are held, the
   client does not emit `+forward` while `playerlinkto`'d and the only
   remaining answer is `t6-gsc-utils.dll` → `storage\t6\plugins\` (still not
   installed), which gives native `ufo()`/`noclip()`.
6. **Mule Kick prone fix and the 12-perk cap — untested.**
   🛑 `remove_perk_limit()` now calls `scripts\zm\wunderfizz::getPerks()`
   cross-file; `gsc-tool` cannot verify that. If a map dies at
   `start_of_round`, that call is the suspect — revert to a literal `12`.

---

## 5. THE FX ONE-SHOT / LOOPING TABLE — hard-won, do not re-derive

An fx cannot be previewed offline, so trial results are the only documentation.

| effect | nature | result |
|---|---|---|
| `fx_zombie_cola_arsenal_on` | **looping**, cabinet-scale | played once on a tag → pink cloud swallowing the machine |
| `fx_alcatraz_electric_cherry_sm` | **one-shot**, large | played once → invisible; every 0.5s → blinding blob |
| `fx_alcatraz_electric_cherry_trail` | unknown | appears to draw nothing static |

**Rule:** a one-shot must be *retriggered* to persist; retriggering a looping
effect stacks it into a blob. Anything named `*_cola_*_on` or `*_lg` is
cabinet-scale — never `playfxontag()` those.

---

## 6. METHOD NOTES

- **The user's screenshots settle things instantly.** The pink cloud, the bare
  machine, the blinding blob and the Sound Studio window each ended a wrong
  theory in one look. `G:\Gallery`, newest file.
- **Three claims were asserted across multiple commits without checking the
  artefact**: that Sound Studio could build aliases, that Reimagined's CSV was
  a stock-alias dictionary, and that a mod-folder bank would override a stock
  one. Each cost a release. The pattern: *verify the tool/file does what you
  need before writing instructions that depend on it.*
- `console_zm.log` is richer than assumed — it prints bank load **paths and
  MD5s**. Check it before theorising about what loaded.

---

## 7. TOOLING

- `gsc-tool` 1.4.10 — `H:\Claude\gsc-tool-bo2\gsc-tool.exe`, `-m parse -g t6
  -s pc -y <file>` (`-i client` for `.csc`). Cannot resolve cross-file calls.
- OAT — `H:\Claude\oat-windows\`. `--list <ff>` is the asset audit;
  `--model-format GLB` for meshes; `ImageConverter --t6` for DDS→IWI.
- Audio dumper — `H:\Claude\Black Ops II Audio Dumper v6 by master131\`.
- Sound Studio Extended — `C:\Program Files\BlackOpsII SoundStudio Extended`,
  GUI, **replacer only**.
- `build.bat` for `.gsc`; `build_ff.bat` also when `zone_source`/`.csc` changes.
- Logs — `%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`.
- Screenshots — newest in `G:\Gallery`.
- GitHub `github.com/ridgelanded/zm_qol`, private, tags v1.1.1 → **v1.32.0**.
