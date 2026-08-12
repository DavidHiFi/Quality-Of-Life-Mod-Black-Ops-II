# zm_qol — agent operating manual

This file adapts `H:\Claude\t6 modding starter kit\CLAUDE.md` (the general T6/BO2 modding kit) to
**this specific project**. Read `AI_CONTEXT.md` alongside this file — it has the verified stock
function names, dvars, and hard rules specific to `zm_qol`; this file has the *working practice*
(how to reason about the domain, how to survive interrupted sessions) generalized from other T6 mod
projects. Where the two overlap, `AI_CONTEXT.md` wins on project-specific facts.

**Base kit:** `H:\Claude\t6 modding starter kit\` — treat it as the source of general T6/BO2 modding
methodology. Its `reference/gsc-dump/` (2,093 decompiled stock scripts) and `reference/docs/` are
used **in place**, not copied into this project (29 MB, would just go stale as a second copy). When
you learn something here that's true for T6 modding generally (not just zm_qol), it belongs back in
the kit, not duplicated into this file.

---

## 0. FIRST ACTION EVERY SESSION

**Read the newest `.agents/checkpoint_*.md`** in this project, if one exists. It carries live state
and the next concrete step. If none exists, start from this file + `AI_CONTEXT.md`.

Two rules that apply to every session:

- **Track what is deployed but unverified in game, separately from what is built.** A clean build is
  compatible with a feature never having run — see §3. Say plainly what is untested. (Live example:
  the perk-description HUD fix discussed 2026-07-31 was diagnosed but not yet verified in-game at
  time of writing.)
- **When a doc claim turns out wrong, correcting it is part of the fix, not a follow-up.**

---

## 1. Environment

| | |
|---|---|
| Project root | `H:\Claude\Projects Sources\zm_qol\` |
| Repo | **Git repo**, branch `main`, backed up to the private `github.com/DavidHiFi/zm_qol`. Binaries tracked on purpose — see §5. |
| Toolchain | Windows + PowerShell for the normal loop; **OpenAssetTools at `H:\Claude\oat-windows`** (`Linker.exe`, `Unlinker.exe`, `ImageConverter.exe`) when an asset has to go into `mod.ff`. |
| Build (scripts) | `build.bat` — re-zips the raw folders into `mod.iwd`, deploys, and refreshes any `.lua` that Plutonium's `raw\` is shadowing. This is all a GSC/LUI change needs. |
| Build (assets) | `build_ff.bat` — relinks `mod.ff`. Only needed after editing `zone_source\` or `zone_assets\`. |
| Build | `zm_qol\build.bat` → runs `pack_iwd.ps1` → verifies the 6 mod files → copies to `build\zm_qol\` and `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\` |
| Plutonium storage | `%LOCALAPPDATA%\Plutonium\storage\t6\` |
| Launch | Plutonium T6 → Zombies → **Mods** → `Quality Of Life` |
| GSC decompiler | `xensik/gsc-tool` (`gsc-tool -m decomp -g t6 -s pc --t6fixup <file>`) — for inspecting `*-compiled.gsc` only; not part of the normal dev loop |
| Starter kit reference | `H:\Claude\t6 modding starter kit\reference\gsc-dump\` (stock T6 scripts) and `...\reference\docs\` (GSC language ref, perk/specialty tables, shader IDs, MOTD custom-perk guide) |
| Sibling project (reference only) | `H:\Claude\Projects Sources\zm_refreshed\` — a **third-party mod's build output**, no source. Do not import from it (per `AI_CONTEXT.md`). |

---

## 2. 🔬 THE PROTOCOL — check the mechanism before theorising about it

Carried over verbatim from the base kit; it's domain-general and has already paid off once in this
project (see §3).

**Before forming a second theory, run the check** — a log grep, a file read, a grep for how a
function is actually *called* — rather than reasoning from what "should" be true.

### Corollary 1 — a clean build proves nothing

`build.bat` succeeding tells you the zip repacked. It does not tell you a `replaceFunc` took, that a
notify fires when you think it does, or that a feature is reachable on the map you're testing.

### Corollary 2 — comments and headers lie

Trust the code over the prose next to it — including prose in this file and in `AI_CONTEXT.md`. Both
have been wrong before and been fixed; both will be wrong again.

### Corollary 3 — "not found" is a lead, never a verdict

A grep with the wrong pattern, or a search scoped to the wrong file, manufactures false absence.
Before concluding a function/asset doesn't exist, confirm the search actually covered where it would
be — `quality_of_life.gsc` is ~3500 lines merged from 17 modules; a narrow grep can miss it.

---

## 3. 🛑 THE SCRIPT EXECUTION MODEL — verified for THIS project, differs from the base kit

**The base kit's §3 describes the OpenAssetTools / dedicated-server pipeline, where raw `.gsc` inside
a mod's `mod.iwd` does NOT execute unless it's also compiled into `mod.ff`'s zone or dropped loose
into a server's `raw/scripts/` folder.** `zm_qol`'s `mod.zone` is in fact empty — zero scripts
declared — which by the base kit's own warning table would normally mean "every server-side thing is
inert."

**That warning does not apply here**, and this has been re-verified, not just assumed: `zm_qol` ships
through Plutonium's built-in **Zombies → Mods** menu, not a dedicated multiplayer server. That loader
reads raw `.gsc` directly out of a mod's `mod.iwd` at runtime and executes it — no OAT, no linker, no
zone entry required. This is corroborated by observed behavior: the Vanguard Perk Animation module's
`give_perk()` override and `perk_acquired` listener visibly run in-game (icon + name pop-up show on
purchase) — this is server-authored GSC only reachable if the raw script executed.

**Practical upshot:**

- There is no GSC compile step for this project. Edit `.gsc` → `build.bat` → launch via the Mods
  menu. `AI_CONTEXT.md` §"Read this first" already states this; treat it as confirmed, not merely
  claimed.
- **If this project is ever redistributed as a dedicated-server mod** (not the Mods-menu path), the
  base kit's §3 becomes fully relevant again — scripts would need zone entries or loose-file
  placement, and this section would need updating. Don't assume that migration is free.
- The base kit's "loose scripts shadow `mod.ff`" trap is still worth knowing: a stale copy in
  `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\` from a previous `build.bat` run can mask a fix
  you just made in source. If a fix "isn't taking," diff timestamps/contents there before re-editing
  code that's already correct.

---

## 4. `replaceFunc` — it fails silently, in four known ways

Carried over from the base kit — this project uses `replaceFunc` extensively (rule 3 in
`AI_CONTEXT.md`) and these failure modes are real risks here, not hypothetical:

| # | failure mode | fix |
|---|---|---|
| 1 | **Unqualified same-file call** — caller invokes `foo()` not `file::foo()` | can't hook it; edit differently |
| 2 | **`level.*` pointer** — behaviour reached via `level.some_func` | re-point the pointer |
| 3 | **`::fn` bound at registration** — pointer captured before your replace | re-point, don't `replaceFunc` |
| 4 | **Wrong entry point** — registered in `init()` when the target is threaded at map-init | move it to `main()` |

Before any `replaceFunc` or qualified `::` reference from a **root** script (`quality_of_life.gsc`),
re-check `AI_CONTEXT.md` rule 2 — a map-specific target resolved at load time crashes every *other*
map, silently, regardless of runtime guards.

---

## 5. Working practice — git, as of 2026-07-31

This project **is** a git repo now (local only, branch `main`, no remote). It was initialised at the
user's request as a rollback point.

- **The binaries are tracked on purpose.** `mod.ff`, `mod.all.sabl`, `mod.all.sabs`,
  `deathmachine_zm.all.sabl` and `zone_source/base/mod.ff` have no source in this project and cannot
  be regenerated from anything in it. A checkpoint you can't restore from isn't a checkpoint. `.git`
  is ~86 MB as a result; that is the intended trade.
- **`.gitattributes` sets `* -text`** — no line-ending translation, so any checkout is byte-exact.
  Do not "fix" this: several tracked files are binary with no extension (`attachmentunique/au_*`).
- **Ignored:** `crashlogs/`, `zone_out/`, `*.bak*`. Everything else is history.
- **Checkpoints** (`.agents/checkpoint_N.md`) still carry live state and the next step — git records
  *what changed*, the checkpoint records *what is untested and why*. Keep writing them.
- **"Deployed but unverified in game"** is not something a commit proves. Say it explicitly, in the
  commit message and the checkpoint both.

---

## 6. Where to look for what

| question | where |
|---|---|
| zm_qol-specific verified facts, hard rules, dvars | `AI_CONTEXT.md` (this project) |
| how does stock BO2 do X? | `H:\Claude\t6 modding starter kit\reference\gsc-dump\` — see its `NAVIGATION.md` |
| GSC language / engine builtins | `...\reference\docs\GSC Documentation.md` |
| perk specialty names / extended list | `...\reference\docs\bo2_perk_specialties_reference.txt`, `extra specialties.txt` |
| HUD shader / material IDs | `...\reference\docs\BO2 SHADERS ID.txt` |
| porting/adding a perk or machine to a map that lacks it | `...\reference\docs\MOTD Custom Perks Guide.md` |
| merging two mod trees (this project's own history is exactly this — 17 modules merged into `quality_of_life.gsc`) | `...\reference\docs\Combining Two Mods Guide.md` |
| build/asset pipeline gotchas (OAT) — now relevant, see §8 | `...\reference\docs\OAT_Linker_Build_Knowledge.md` |

### Other traps worth knowing (from the base kit, still relevant)

- **Per-map folder scripts aren't global** — `scripts/zm/<mapname>/` runs only on that map. Already
  covered as a hard rule in `AI_CONTEXT.md`.
- **File names can lie about ownership/scope.** Don't assume what a script does from its name alone;
  read it or grep how it's invoked.
- **`settext()` per tick floods reliable commands** (`EXE_SERVERCOMMANDOVERFLOW`). Use `settimer` /
  `setvalue` for changing numeric HUD values instead of re-`settext`-ing every frame.

---

## 7. Working rules

- **Verify in game.** A rebuild is not a test. Say plainly what is untested.
- **Don't import code/files from other mods** (`AI_CONTEXT.md` rule 7) — including this starter kit's
  reference dump; that's stock Treyarch script for *reading*, not for copy-pasting into `zm_qol`
  without adaptation.
- **Report faithfully.** If a step was skipped or untested, say so.

---

## 8. 🔧 THE FASTFILE PIPELINE — this project CAN add assets

**Correcting this file's own earlier claim.** Sections above used to say zm_qol has "no compiler, no
OpenAssetTools, no linker", and checkpoint 3 built several decisions on top of that. It was
wrong: **OpenAssetTools is installed at `H:\Claude\oat-windows`.** Anything that has to be a real
asset — materials, images, xmodels, stringtables — can be built into `mod.ff`.

### How `build_ff.bat` works

`mod.zone` is only two `include` lines:

| file | what it is |
|---|---|
| `zone_source\base\mod.ff` | the pristine fastfile this project shipped with. The **donor** for the 3,510 assets already in `mod.ff`. There is no source for those, so the Linker copies them out of this file. **Irreplaceable — do not delete.** |
| `zone_source\mod_base.zone` | that donor's asset inventory, generated by the Unlinker. Regenerate with `build_ff.bat regen`. Do not hand-edit. |
| `zone_source\mod_locations.zone` | what this project adds. Hand-edited. |
| `zone_assets\` | the sources for those additions — `materials\*.json`, `images\*.iwi`, `xmodel\*.json`, `model_export\*.glb`. Not packed into `mod.iwd`. |

The build always links from the donor, never from the live `mod.ff`, so repeat runs are deterministic
and cannot compound. A round-trip with no additions was verified asset-for-asset identical to the
original (3,511 assets in, 3,511 out).

### 🛑 A fastfile does NOT contain image pixels, and its scripts go stale

Two traps that cost a full round of in-game testing each (checkpoint 5 §2, §4):

- **An image asset in `mod.ff` is only a header.** T6 loads the actual pixels at runtime from a
  loose `.iwi`. Adding a material + image to `zone_source\`/`zone_assets\` gets you a material that
  resolves and an image that **draws black**. The `.iwi` must ALSO be in `images\`, which
  `pack_iwd.ps1` packs into `mod.iwd`. `build.bat` step [1/6] now copies
  `zone_assets\images\*.iwi` → `images\` so the two cannot drift. The tell:
  `Unlinker --include-assets image` reports `Could not find data for image` for **every** image,
  stock ones included.
- **`mod.ff` silently re-ships the donor's original scripts.** T6 stores scripts in a fastfile as
  **raw text**, and `mod_base.zone` declares `scripts/zm/zm_expanded.csc` + the six per-map `.csc`.
  The Linker resolves a declared asset from the asset search path first and falls back to a
  `--load`ed fastfile — so with nothing staged it copied the donor's day-one copies back in every
  time. `build_ff.bat` now stages `scripts\**\*.csc` into `zone_assets\` before linking; confirm
  with `Loaded script "..." (src: disk)` (not `(src: mod)`) in the link output.
  Note `.gsc` is unaffected in practice — Plutonium's Mods menu runs raw `.gsc` straight out of
  `mod.iwd` (§3), which is how `quality_of_life.gsc` works while being declared in no zone file.

### Where the stock LUI actually lives

🛑 **This section used to say "`patch_ui_zm.ff` holds all 48 LUI files". That is WRONG and it cost a
wrong verdict** — checkpoint 39 §6 declared the Origins generator dial engine-drawn and unmovable
after searching only that fastfile. `patch_ui_zm.ff` holds **50 rawfiles and they are all lobby and
menu screens** (`privategamelobby`, `selectmapzombie`, …). **There is no in-game HUD LUI in it.**

The real map, all via `Unlinker --include-assets rawfile -o <dir> <ff>`:

| fastfile | what it holds |
|---|---|
| `patch_ui_zm.ff` | lobby / menu screens only — **not** the HUD |
| `patch_zm.ff` | the bulk of the in-game HUD: `ui_mp/t6/hud/*`, `ui_mp/t6/zombie/*` (round status, perks, powerups, dpad, objectivewaypoint …) |
| `common_zm.ff` | a handful more |
| **`<map>_patch.ff`** | 🌟 **map-specific HUD LUI.** `zm_tomb_patch.ff` owns the Origins capture wheel (`capturezonewheeltombdisplay.lua`), the widget that positions it (`hudcraftablestombzombie.lua`) and the mid-screen capture meter (`tombcapturezonedisplay.lua`). **Always check the map's own patch fastfile before concluding something is engine-drawn.** |
| `ui_zm.ff` | no `.lua` at all ✅ (that part was right) |

They ship as compiled **modified Lua 5.1** bytecode — `unluac` cannot read it — so grep only matches
constant tables. But the game **does** load raw `.lua` source out of `mod.iwd`'s `ui_mp\`, which is
how the Death Machine powerup icon works today, so a stock LUI file *can* be overridden.

**How to override one safely** (the method used for the dial, 2026-08-13):
1. Get a decompile from `BO2-Reimagined` if it ships that file — but it carries **their** layout
   edits, so it is a starting point, not the answer.
2. Dump the shipped bytecode and decode its **constant table** — type `04` = string
   (`int32` length, then bytes), type `03` = **4-byte float**, type `01` = bool. Constants appear in
   order of first use, so they pin down every literal in the file.
3. Check each number in the decompile against that table, and byte-scan for any literal you doubt
   (a float that is absent from the file was never in stock).
4. `luaparse` (npm, `luaVersion: '5.1'`) parse-checks the result offline.
5. Confirm the file landed **inside** the deployed `mod.iwd`, and that nothing in
   `%LOCALAPPDATA%\Plutonium\storage\t6\raw\ui_mp\` shadows it.

### Traps, all of them found the hard way

- **🛑 A T6 fastfile's filename must match its internal zone name.** Copy `mod.ff` to `mod_base.ff`
  and OAT fails with `inflate of stream N failed: invalid block type` — same bytes, different name,
  unloadable. That is why the donor lives in its own folder still called `mod.ff`.
- **Don't point `--add-asset-search-path` at the project root.** It contains `weapons\`, so the
  Linker tries to rebuild every weapon from source and dies on missing accuracy tables. Point it at
  `zone_assets\` only, so everything else resolves from the loaded donor.
- **`//` inside an asset name is a zone-file comment.** `fx,weapon//grenade/fx_trail_grenade`
  parses as an fx called `weapon`. The Unlinker emits such names quoted — another reason to let it
  generate `mod_base.zone` rather than writing one by hand.
- **Don't list `keyvaluepairs,mod`.** The Linker generates it; listing it explicitly fails the build.

### The Unlinker is also the best answer to "what does the stock game actually contain?"

```
Unlinker.exe --list <zone.ff>                        # every asset in a fastfile
Unlinker.exe --include-assets mapents -o <dir> <ff>   # a map's entities/structs as text
```
`mapents` is the ground truth for wallbuy structs, perk machines, spawn points and their
`script_noteworthy` tags — it settles questions that are otherwise pure guesswork. See
`AI_CONTEXT.md` for the two facts this produced.

**Corollary to §2's protocol: the game files are readable. Prefer dumping them over reasoning about
what Treyarch "must" have shipped.**
