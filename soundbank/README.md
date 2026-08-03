# Adding a sound to this mod

**This is a solved problem as of v1.39.0.** It is a normal build step now — edit a CSV, drop an
audio file, run `build_ff.bat`. No GUI, no Sound Studio, no manual step.

Everything this file used to say is superseded. It described a hand import in **Black Ops II Sound
Studio Extended** as the one thing that could not be automated. That was wrong twice over: Sound
Studio cannot create aliases at all (it is a payload replacer), and the tool that *can* was already
in the build.

---

## The mechanism

**OpenAssetTools reads and writes soundbanks.** That is the whole answer, and it went unnoticed for
six releases while the mod shipped substitute sounds.

A T6 sound is two halves, in two files:

| half | what it is | where it ships |
|---|---|---|
| the **alias** | name, volume, bus, distance curve, looping, ~60 fields | the `soundbank` asset inside `mod.ff` |
| the **payload** | the actual audio | `mod.all.sabl` (loaded) / `mod.all.sabs` (streamed) |

Both are generated from the same two inputs, and `build_ff.bat` keeps all of it in step:

```
zone_assets\soundbank\mod.all.aliases.csv   the full alias table
zone_assets\sound\**                        the audio each row's FileSource names
```

Neither is checked in. `build_ff.bat` regenerates them from `zone_source\base\` on first run — the
donor's 1,691 rows and 249 payloads come straight back out with

```
Unlinker --include-assets soundbank --search-path zone_source\base -o <dir> zone_source\base\mod.ff
```

then overlays this project's own additions on top, every build.

## What IS source, and all you edit

| | |
|---|---|
| `soundbank\mod.all.aliases.additions.csv` | the rows this mod adds |
| `sound\**` | the audio those rows point at |

## To add a sound

1. **Find it in a real bank** and take Treyarch's own row and audio — never invent field values:
   ```
   Unlinker --include-assets soundbank --search-path "<BO2>\sound" -o dump "<BO2>\zone\all\zm_tomb.ff"
   grep "^<alias>," dump\soundbank\*.aliases.csv
   ```
   The payloads land under `dump\sound\...` at the exact path the CSV's `FileSource` names.
2. **Copy the row into `mod.all.aliases.additions.csv` and rename the `Name` column** to `zmqol_*`.
3. **Copy the payload into `sound\`**, at its `FileSource` path minus the `raw\` prefix.
4. `build_ff.bat`, then `build.bat`.

### 🛑 Rename every alias `zmqol_*`

Shipping `zmb_rand_perk_loop` under its own name would put a second definition of a live alias in
front of Origins, which ships its own in `zmb_tomb.all` — the duplicate-asset shape that made Origins
unbootable in v1.19.0. A mod-private name cannot collide on any map. Same rule as the `qolwf_*`
xmodel/material rename in v1.23.0.

### 🛑 Check an alias exists before you use it

A missing alias is **silent, never an error** — nothing in any log will tell you. Two releases were
lost to aliases that were described as verified and did not exist anywhere: `zmb_tombstone_looper`
(v1.32.0) and `zmb_hellhound_bolt` (v1.38.0). One command settles it:

```
Unlinker --include-assets soundbank -o dump <map>.ff   &&   grep "^<alias>," dump\soundbank\*.csv
```

**`BO2-Reimagined\soundbank\mod.all.aliases.csv` cannot confirm a stock alias** — it is the alias
table of Reimagined's *own* bank. It is still an excellent source of realistic field values.

### 🛑 Dump the CSV and the payloads in one Unlinker run

It writes files as `foo.snd.wav.wav` — its own extension on top of the `FileSource` name — and
rewrites the CSV's `FileSource` column to match. Mix a CSV from one run with audio from another and
the link fails with `Unable to find a compatible file for sound ...`. Do not "fix" the doubled
extension; the CSV expects it.

### `Storage` decides which bank it lands in

`loaded` → `mod.all.sabl`, `streamed` → `mod.all.sabs`. Both are rebuilt and both must deploy.
**`build.bat` has printed `[ok]` for a bank it did not actually copy** — verify the deployed file
sizes afterwards, or a streamed sound is silent while everything looks fine.

---

## What ships today

| alias | source | storage |
|---|---|---|
| `zmqol_wf_start` | Origins `zmb_rand_perk_start` | streamed |
| `zmqol_wf_loop` | Origins `zmb_rand_perk_loop` (looping) | streamed |
| `zmqol_wf_stop` | Origins `zmb_rand_perk_stop` | streamed |
| `zmqol_wf_leave` | Origins `zmb_rand_perk_leave` | streamed |
| `zmqol_cherry_zap` | Alcatraz `zmb_cherry_explode` | loaded |

All five carry Treyarch's own 60 field values; only `Name` (and, for the zap, `FileSource`) differs.

## Still true, and still the reason all this was needed

**`soundbank,<stock name>` in the zone is fatal.** `zmb_tomb.all` there made Origins unbootable:
`COM_ERROR Attempting to override asset 'zmb_tomb.all' from zone 'mod' with zone 'zm_tomb'`.
**And a mod-folder file does not override a stock bank** — a bank loads from the folder of the zone
that declared it, proven across three staged locations and three logs with `cmn_root.all.sabl`.
The mod's own `mod.all` was always the only channel. It just turned out to be a fully usable one.
