# Checkpoint 5 — art fixed and confirmed in game. Clientfield crash fixed twice; second fix UNTESTED.

**Supersedes checkpoint 4's items 1-6.** Written 2026-07-31 across two in-game test rounds.
**Read §0 first — it is the only part you need to resume.**

---

## 0. STATE AT END OF SESSION — START HERE

### Confirmed working in game (user-verified, not just built)
- **All lobby previews and loading screens load.** The black/dark art is gone. (§2)
- **The client-side script runs.** `[zm_qol] CLIENT enable_wallbuys` appears in the log, which it
  never did before — proof the `.csc` `replaceFunc` takes and that `mod.ff` now ships the current
  client script. (§3, §4)

### Built + deployed, NOT yet run in game
- **Clientfield fix, attempt 2** — per-location gating. Attempt 1 was wrong in a new way (§3).
  This is the one thing that decides whether Diner launches at all.
- **LUI hint spacer at 0.5** (§6). Geometry inferred from screenshots, not measured.

### The single next action
Launch Diner. Both of these must appear with **equal counts**:
```
[zm_qol] enable_wallbuys        - zstandard_diner: tagged 2 of 2 requested   <- server
[zm_qol] CLIENT enable_wallbuys - zstandard_diner: tagged 2 of 2 requested   <- client
```
Unequal, or one missing → it drops again with `EXE_CLIENT_FIELD_MISMATCH`, and the log's
`*****MISMATCHED CLIENTFIELDS*****` block names the exact clientfield and which side lacks it.
That block is the whole diagnosis; read it before theorising.

**Then do test 1 in §5 — the 5-map boot test is STILL unrun after four `mod.ff` relinks.**

### Reading the log
Newest log is not always the mod folder — the last run wrote to
`%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log`, not `...\mods\zm_qol\console_zm.log`.
**Sort both by mtime and take the newest**, and check it is newer than `mod.iwd`'s mtime, or you are
reading a run from before the build.

---

## 1. WHAT THE TWO TESTS SHOWED

**Round 1** (the checkpoint 4 build):
- Previews were no longer checkerboards, but the Diner **loading screen was solid black** and the
  lobby preview showed the wrong/dark art.
- Diner **would not launch at all**: `Server Disconnected - EXE_CLIENT_FIELD_MISMATCH`.

**Round 2** (after the §2/§3 fixes):
- ✅ Art fixed — everything loaded.
- ❌ Still `EXE_CLIENT_FIELD_MISMATCH`, but for the **opposite reason** — see §3.

Both rounds were diagnosed from the log, not guessed.

---

## 2. 🛑 THE MISTAKE: A MATERIAL IS ONLY HALF AN ASSET

Checkpoint 4 added 30 materials + 14 images to `mod.ff` and called the art done. It wasn't.

**T6 does not store image pixel data in a fastfile.** `mod.ff` carries the material and an image
*header*; the actual pixels are loaded at runtime from a loose `.iwi`. The 13 `.iwi` files were put
in `zone_assets\images\` — which is only the **link-time** asset search path — and never into
`images\`, which is what `pack_iwd.ps1` packs into `mod.iwd`. Result: material resolves, image asset
exists, nothing behind it → **draws black**.

Proof, and the check to repeat if this ever recurs:

```
Unlinker.exe --include-assets image -o <dir> mod.ff
    ERROR: Could not find data for image "<every image, including stock ones>"
```
That error on *stock* images is the tell that fastfiles never hold pixels.

Reimagined does it right, and its build.bat is the one-line proof:
```
Compress-Archive -Force -Path attachmentunique,images,maps,scripts,ui,ui_mp,weapons -DestinationPath mod.iwd
```
`images` goes in the iwd.

### Fixed
- All 15 required `.iwi` copied from `BO2-Reimagined` into `images\` → packed into `mod.iwd`
  (verified: 16 `images/` entries in the deployed iwd, was 1).
- **`build.bat` step [1/6] now syncs `zone_assets\images\` → `images\`** so the link-time and
  runtime copies cannot drift again. Steps renumbered to /6.
- Added the 31st material, `loadscreen_zm_prison_zclassic_prison` (+ `loadscreen_zm_hellcatraz_zclassic`),
  which Reimagined ships and we lacked — MOTD played as *classic* had no loading screen either.
- Our 30 material→image mappings were already identical to Reimagined's, and all 13 shipped `.iwi`
  were already byte-identical to Reimagined's. The mapping was never the bug.

---

## 3. 🛑 THE OTHER MISTAKE: THE WALLBUY RE-TAG WAS SERVER-ONLY

`_zm_weapons` registers one `world` clientfield per matching wallbuy, named `<weapon>_<origin>` —
**on both sides**: `_zm_weapons.gsc::init_spawnable_weapon_upgrade()` and `_zm_weapons.csc::init()`.
Both walk the same structs with the same match string, so stock they always agree.

`loc_common::enable_wallbuys()` is a `.gsc`, so it only re-tagged on the server → server 15,
client 13 → engine drops the connection:

```
Clientfield mp5k_zm_(-5489, -7982.7, 62) in set [world] is not registered on the client
Clientfield tazer_knuckles_zm_(-6399.2, -7938.5, 207.25) ... not registered on the client
```

Those two are exactly the Diner wallbuys the fix enabled. **The wallbuy fix worked; enabling the
wallbuys is what broke the connection.** Tunnel and Borough would have failed the same way.

### Fixed (second attempt — the first was wrong)
`scripts\zm\zm_expanded.csc` now replaces `clientscripts\mp\_utility_code::struct_class_init` and
mirrors the re-tag.

🛑 **The first attempt gated the origin list on the MAP and broke it the other way.** On Diner it
tagged Diner's 2 *and* Tunnel's 1, so the client had one clientfield MORE than the server:

```
[zm_qol] enable_wallbuys - zstandard_diner: tagged 2 of 2 requested        <- server
[zm_qol] CLIENT enable_wallbuys - zstandard_diner: tagged 3               <- client
Clientfield 'm16_zm_(-11839, -1695.1, 287)' in set [world] is not registered on the server
CLIENTFIELD SET [world] COUNT : 16 (client) / 15 (server)
```

Only the **active location's** `struct_init()` runs on the server, so the gate must be on
`ui_zm_mapstartlocation`, not `mapname`. **The two sides must tag the SAME set, not overlapping
sets.** Per-location gating now mirrors the server's registrations exactly:

| location | server registers for | client tags when |
|---|---|---|
| diner  | zstandard + zgrief | location == diner |
| tunnel | zstandard + zgrief | location == tunnel |
| street | **zstandard only** (grief already matches natively) | location == street **and** gametype == zstandard |

Other notes:
- It copies the **client's** stock `struct_class_init` body, which indexes `script_label` and
  `classname` — the server's replaced version indexes `script_linkname` and
  `script_unitrigger_type`. Copying the wrong one breaks struct lookups confusingly.
- It reads `getdvar("ui_gametype")` / `("ui_zm_mapstartlocation")` rather than
  `level.scr_zm_ui_gametype`, because `_zm.csc::init()` has not assigned those yet at
  `struct_class_init` time — it reads the very same two dvars later (`_zm.csc:32-33`).
- **The six origins are duplicated** between the `.gsc` locations and the `.csc`. A `.csc` cannot
  `#include` a `.gsc`. Both sides now carry a 🛑 comment saying so. Drift = this crash returns.

---

## 4. 🛑 mod.ff WAS SHIPPING STALE CLIENT SCRIPTS

Found while verifying the above. `mod_base.zone` declares `script,scripts/zm/zm_expanded.csc` and
the six per-map `.csc`. **T6 stores scripts in a fastfile as raw text**, and the Linker resolves a
declared asset from the asset search path *first*, falling back to a `--load`ed fastfile. Nothing
was staged, so every relink copied the **donor's original** `.csc` back in — `mod.ff` had been
shipping whatever those files looked like the day the mod was first built, regardless of edits.
(Confirmed: extracted copy was byte-identical to the pre-edit working file, 7,366 vs 15,892 bytes.)

`build_ff.bat` now stages `scripts\**\*.csc` into `zone_assets\` before linking; the log shows
`Loaded script "scripts/zm/zm_expanded.csc" (src: disk)`. This sidesteps the open question of
whether Plutonium's Mods menu runs raw `.csc` out of `mod.iwd` the way it does `.gsc` — both copies
are now current, so it does not matter.

Also: `build.bat` was **entirely LF**, which is starter-kit trap #6. It only survived because its
`^` characters are escaped `>`, not line continuations. Both `.bat` files are CRLF now.

---

## 5. ⏳ TEST BACKLOG

1. 🛑 **Does each map still boot?** `mod.ff` has now been relinked **four times** and this has never
   been checked. Highest-risk item in the project. Boot a stock location on each of the 5 maps.
   Rollback is unchanged: restore `zone_source\base\mod.ff` over `mod.ff`, run `build.bat`.
2. **Diner launches at all** — see §0 for the two log lines and what they must say. Then Tunnel
   (1 of 1) and Borough (3 of 3, zstandard only — under grief the client must tag 0, that is
   correct, not a bug).
3. ✅ **Loading screens + previews** — DONE, confirmed in game round 2.
4. Diner wallbuys actually present: MP5K inside, Galvaknuckles on the roof. (Blocked on 2.)
5. Origins as Survival (checkpoint 4 item 2, still never tested).
6. Docks / Excavation Site load; Cornfield's boundary wall is back.
7. LUI hint text clears the preview panel (§6).
8. Regression: checkpoint 1 (perk descriptions after several revives), checkpoint 2 (instant start).

## 6. LUI HINT TEXT OVERLAPPING THE PREVIEW PANEL — fixed, needs a visual check

The custom-game settings hint wrapped onto a second line that was drawn inside the map preview
panel. Screenshot showed line 1 ("Change the game mode to a traditional or") clearing the panel and
only line 2 ("custom rule set.") intruding — **the wrap was the problem, not the position.**

Cause: the hint sits under the settings list, so its Y follows the row count. This mod's
`CoD.PrivateGameLobby.Dvars` has two rows (TARGET ASSIST, CHEATS) where Reimagined's has one
(`ui_gametype_pro`), so the hint starts one row below what the stock layout allows.

Fix, in two parts — the first alone was not enough:
1. `buttonList.hintText:setLeftRight(true, false, 0, 800)` — stops the two-line wrap. Same call and
   width Reimagined uses at `ui/t6/options.lua:431`. **Verified deployed**, and it did remove the
   second line, but the remaining single line still sat on the panel's top border.
2. The nav/settings spacer dropped from `CoD.CoD9Button.Height * 1` to `* 0.5`, lifting everything
   below it by half a row. 🛑 **Do not take this to 0** — a full row up puts the hint into the
   CHEATS row. Half a row is the only clearance that fits between the two.

**Both numbers are geometry inferred from screenshots, not measured. Confirm visually.**

🛑 Do NOT try to move the preview panel. It is stock LUI, compiled LuaJIT **bytecode**, and lives in
`patch_ui_zm.ff` (48 `.lua` rawfiles — dump with
`Unlinker --include-assets rawfile -o <dir> patch_ui_zm.ff`). Not editable without a decompiler.
Note `ui_zm.ff` contains **no** LUI at all; `patch_ui_zm.ff` is the one that does.

---

## 7. WORKING WITH THIS USER — practical notes

### Screenshots
The terminal does **not** forward Ctrl+V images to Claude Code on this machine — the clipboard holds
the image fine, the terminal just never hands it over. ShareX is configured clipboard-only and
writes nothing to disk, and Ditto (clipboard manager) pushes the image down its history as soon as
anything else is copied.

Working route: user re-copies the image in Ditto and says "grab it", then run
```
powershell.exe -NoProfile -STA -File <scratchpad>\grab_clip.ps1
```
It saves the clipboard image to the scratchpad as PNG and prints the path; then Read that path.
**-STA is required** — clipboard access fails from PowerShell's default MTA apartment.
If it prints `NO IMAGE IN CLIPBOARD`, the image has been bumped; ask for a re-copy rather than
guessing at what the screenshot showed.

### Reference material added to the workspace 2026-07-31
Cloned/added by the user for use on this project — all read-only reference:

| path | what |
|---|---|
| `H:\Claude\BO2-Reimagined\` | **full source** clone of `github.com/Jbleezy/BO2-Reimagined`. The upstream of most ported code here. Authoritative for previews/loadscreens, LUI patterns, and its `build.bat` for how a working T6 mod packs assets. |
| `H:\Claude\Black Ops 2 Grand Resources\` | dumps: DVARs, FX, fonts, models, shaders, sounds, weapons, IPAK dump, `T6-Data-Archive-main` (mapents, clientfields, scripts). **No LUI.** |
| `H:\Claude\BO2-Cold-War-Mod\`, `BO2-Remix\`, `BO2-GSC-Releases\`, `BO2-No-Box-Limits\`, `Black-Ops-II-Wunderfizz\`, `BO2-City-Of-Mars-2021-Source-Codes\`, `t6-scripts\` | other mod sources, not yet used |

🛑 **`AI_CONTEXT.md` rule 7 says "don't import code/files from other mods."** The user explicitly
and repeatedly authorised importing the preview/loadscreen art from BO2-Reimagined
("make sure the previews and all that are the same from the reimagined mod imported to my mod"),
so §2's import is sanctioned. **The rule still stands for everything else** — do not treat this as
a general licence to copy from the other repos above.
