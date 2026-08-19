# Checkpoint 85 — v1.99.88. The unload freeze is fixed, and seven more queue items shipped.

Written 2026-08-20, during and after an AFK session the user authorised explicitly:
*"do absolutely everything you can in the queue… go for the simpler edits first… make sure I don't
end up coming back to a bunch of half-assed scuffed implementations."*

**Supersedes 84 for status.** Checkpoint 84's open texture question is answered in §5.

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.88 is deployed, hash-verified into Plutonium, and NOT booted.**
Seven versions shipped this session, each committed separately with its evidence.

| version | queue item | what shipped |
|---|---|---|
| 1.99.82 | **26** | 🌟 **the mod-unload freeze** — 6 `mod.ff` assets duplicating live `common_zm` assets removed |
| 1.99.83 | 11, 30, 25 | GAME tab: ANIMATED CAMO PATCH, BOX LIMITS, CUSTOM POWER-UPS |
| 1.99.84 | 24 | silent announcer lines — a Nuketown-only announcer-prefix miss |
| 1.99.85 | 28, 29 | pause menu: INSTANT EXIT, QUIT TO DESKTOP (+ a `build.bat` correctness fix) |
| 1.99.86 | 32 | CHEATS tab: CHANGE ROUND, KILL HORDE, END ROUND (+ 2 real bug fixes) |
| 1.99.87 | 27 | pause menu: RESTART GAME |
| 1.99.88 | 14 | Death Machine ammo counter on Buried / Mob / Origins |

**Also investigated and written up rather than built:** items 13, 15, 16, 17, 18, 21, 34 — §5.

### 🔴 THE FIRST BOOT SHOULD CHECK THESE, IN THIS ORDER

1. **Load the mod, go to the Mods menu, press U.** Does it unload? That is item 26, the thing the
   user demanded be fixed "for good".
2. **Start any map.** Every one of these versions is unbooted, and three of them ship LUI overrides
   — if the game reaches the map and the HUD draws, the risky half is clear.
3. **Esc → the pause menu** should now read RESUME GAME / **RESTART GAME** / OPTIONS / END GAME /
   **INSTANT EXIT** / **QUIT TO DESKTOP**.
4. **Options → GAME** should have 12 rows, **CHEATS** 10.
5. **Nuketown**, grab a Zombie Blood or Blood Money — the announcer line should now play. The log
   prints `[zm_qol] vox: prefix=… exists=…` which confirms it by itself.
6. **Origins/Buried/Mob**, take a Death Machine — the ammo counter should be gone, not flickering.

---

## 1. 🌟 THE UNLOAD FREEZE (item 26) — CAUSE FOUND BY A CONTROL TEST

The user ran the discriminator: **zm_qol → unload → froze. Reimagined → unload → clean**, same boot
session, same machine, same ReShade, and Reimagined's `mod.ff` is the bigger of the two. That ruled
out ReShade, display mode, mod size and Plutonium generally.

**That run also produced the first successful mod unload ever captured**, which is what made the
diagnosis possible — it shows what the engine does next:

```
Unloading fastfile mod
Unloading ipak patch_mp        <- only the ipaks that zone ADDED; "already loaded" ones are skipped
Unloading ipak sp
Could not load image "$lineargray".      <- default assets re-registering
DB_FlushGump 0..3 / Sys_GumpFlushed
Loading fastfile patch_ui_zm / en_ui_zm / ui_zm     <- the UI zone is RELOADED
loadmod: loaded          (empty = no mod)
```

zm_qol died on the **first line** and never reached the ipak step, so the hang is inside the
teardown of the mod zone's own assets.

**The finding.** Indexing both mods' `mod.ff` against the five zones that stay loaded at the menu
(`patch_zm`, `code_post_gfx_zm`, `ui_zm`, `patch_ui_zm`, `common_zm` — 4,100 assets):

| class | zm_qol | Reimagined |
|---|---|---|
| image | 64 | 68 |
| material | 49 | 46 |
| techniqueset | 16 | 13 |
| fx | 5 | 1 |
| physpreset | 1 | 2 |
| **xmodel** | **5** | **0** |
| **script** | **1** | **0** |

Every class Reimagined also collides on is proven survivable by its clean unload. `xmodel` and
`script` are the only two it does not, and they are ours alone — all six owned by `common_zm`, which
never unloads, and all six introduced by the Thundergun/Freezegun port:

```
script,clientscripts/mp/zombies/_zm_weap_thundergun.csc
xmodel,fx_char_gib_chunk_bone03 / _fat / _flesh03 / _meat01 / _meat02
```

**Removed with no regression, and that is measured.** The client script we shipped is *the same
script as stock's* — ours raw source, common_zm's compiled bytecode of the same code; diffed against
the gsc-dump's decompile, the only differences are brace style and `true`/`false` vs `1`/`0`. Its one
caller, `scripts/zm/thundergun.csc:30`, now resolves to common_zm's copy, loaded on every map. The 5
gib xmodels are stock models common_zm owns under the same names; the 4 it does **not** own
(`bone01`, `bone02`, `flesh01`, `flesh02`) are still declared.

**Why the experiment is clean if it works.** Build A (pre-probe, had the six) froze. Build B
(v1.99.81, probe + the six) froze. Build C differs from A by **the six alone**.

🛑 **If it still freezes**, the next step is the ff/iwd split: two mod folders, one with `mod.ff` and
no `mod.iwd`, one the other way round. That halves the remaining search in a single boot.

---

## 2. 🌟 THE ANNOUNCER LINES (item 24) — A NUKETOWN-ONLY PREFIX MISS

`_zm_audio_announcer.gsc:358` builds the alias as
`game["zmbdialog"]["prefix"] + "_" + game["zmbdialog"][dialog]`, and
`_zm_utility::sndswitchannouncervox()` rewrites that prefix — `"sam"` → `vox_zmba_sam`,
`"richtofen"` → `vox_zmba`.

**Exactly one map in the game calls it.** `zm_nuked.gsc:172` threads
`sndswitchannouncervox( "sam" )` at map init and only switches back in
`switch_announcer_to_richtofen()`, which waits on the `moon_transmission_over` easter-egg flag. So
for the whole of a normal Nuketown match the engine asks for
`vox_zmba_sam_qol_powerup_zombie_blood` — an alias this mod never shipped. **A missing alias is
silent, never an error**, and the user reported this on Nuketown.

Confirmed against the banks: `en_zm_nuked.ff` carries 8 `vox_zmba_powerup_*_0` rows **and** 8
`vox_zmba_sam_powerup_*_0` rows, while `en_zm_transit`, `en_zm_highrise`, `en_zm_prison`,
`en_zm_buried` and `en_zm_tomb` ship no `vox_zmba_sam_*` row at all.

Fix: four rows added to `soundbank\mod.all.aliases.additions.csv` — the two lines under the `sam`
prefix, in both bare and `_0` form — pointing at the same payloads. **Voice-correct, not a patch**:
both recordings were dumped from Origins, whose announcer is Samantha.

🛑 **The Death Machine deliberately has no `sam` alias** and stays silent on Nuketown before the
easter egg. Its payload is Die Rise's `zmb_vox_ann_death_machine` and Die Rise's announcer is
Richtofen; **no Samantha Death Machine line exists anywhere in the game**. Richtofen's voice while
Samantha is announcing, or nothing — **the user's call**.

---

## 3. THE THREE PAUSE-MENU ROWS (items 27, 28, 29)

**RESTART GAME turned out to be Treyarch's own feature re-connected.** QUEUE.md's earlier reading —
"one LUI override relaxing the session-mode condition" — was out of date: Plutonium's `class.lua`
has removed stock's entire restart branch *and its handler*. What made it shippable anyway is that
the rest is still in the game: `patch_zm.ff` ships `ui_mp\t6\zombie\restartgamepopupzombie.lua` with
the confirm popup intact, and stock's restart inside it is
`Engine.Exec( controller, "fast_restart" )`. So the button, the popup, the localized strings and the
restart command are all stock. Two lines in the popup had to change — stock gates the restart on
SYSTEMLINK/OFFLINE and Plutonium reports neither, so YES would otherwise have skipped the restart and
landed on the "uploading movie" spinner.

🛑 **Residual risk:** whether Plutonium honours `fast_restart` in a zombies match is unverified. If
it does not, YES closes the popup and nothing happens — it cannot crash, because every other line is
stock's.

🌟 **Why a mod can override `class.lua` at all, measured:** it is loaded at boot *and again* after a
mod loads (log lines 524 and 861, with `loadmod` at 701), and the search path printed after loadmod
puts `mod.iwd` at rank 1 and `storage\t6\raw` at rank 3. It therefore works for downloaders too.

🛑 **`build.bat` was fixed in the same commit.** Step [6] synced ANY `.lua` present in both the
project and `raw\`, on the stated premise that "Plutonium searches raw\ BEFORE mod.iwd" — which the
log disproves. Only the three FRONTEND menus need that sync. The over-broad rule copied `class.lua`
into `raw\`, which would have left the mod's rows in the player's **vanilla** pause menu. It is now
in an explicit skip table, and Plutonium's own copy was restored byte-exactly (9,602 bytes, 220
lines, zero mod traces, parses clean).

---

## 4. THE DEATH MACHINE AMMO COUNTER (item 14)

Two different widgets draw the zombies ammo counter:

| widget | maps | how it hides |
|---|---|---|
| `CoD.AmmoCounter` (`patch_zm`, `ui_mp\t6\hud\ammocounter.lua`) | Green Run, Nuketown, Die Rise | a `hide`/`show` animation state setting **alphaMultiplier**, which propagates to children |
| `CoD.AmmoAreaZombie` (`ui_mp\t6\zombie\ammoareazombie.lua`) | Buried, Mob, Origins | `self:setAlpha(0)` on the container only |

The server half was never at fault. What goes wrong is next: `hud_update_ammo` fires on every ammo
change, `UpdateAmmo` redraws each digit with `setDigit()` and the digits come back on their own,
while `UpdateVisibility` is edge-triggered and never puts them back. That is exactly *"flickers from
150 to 350"*.

Fix: `UpdateAmmoVisibility` caches `BIT_AMMO_COUNTER_HIDE` on the widget, and `UpdateAmmo` and
`UpdateOverheat` honour that flag the way they already honour `hideAmmo`. **The diff against the
stock file removes nothing** — three conditions extended. One file covers all three maps because the
three shipped copies are **byte-identical** (27,792 bytes, diffed).

🌟 **The LUI dump at `H:\Claude\POWER UP TIMERS\black_ops_2_decompiled_lua_dump\` has readable
source for these widgets.** QUEUE.md had recorded this class of file as un-decompilable. It is the
same source the already-shipped, user-confirmed `hudpowerupszombie.lua` override came from.

---

## 5. WRITTEN UP, NOT BUILT — and why each one stopped

- **Item 34, the texture pack.** The v1.99.81 probe fired and answered it: the engine looks for an
  ipak in `<BO2>\zone\all` and `<BO2>\zone\english` **only** — no mod folder — so a mod can never
  ship one. Separately, **all 51 files in the player's own `storage\t6\images\` are ipak-backed
  images**, which is strong evidence that a loose `.iwi` at rank 4 *does* beat an ipak and that the
  mod-side failures were about location. If so the pack is deliverable, but only into the player's
  own folder. **Their decision; the 260 MB pack was not attached to a release unilaterally.**
- **Item 21, Carpenter.** Stock behaviour: `start_carpenter_new()` snaps every barrier more than 750
  units from a player with no animation, by design, and the mod overrides neither `_zm_powerups.gsc`
  nor any carpenter global. The one case that would still be a bug is a barrier *inside* 750 units
  snapping.
- **Item 13, custom camos.** The mod ships 70 `camo_*.iwi` in `mod.iwd`, **64 of them stock
  ipak-backed names**, and `mod.iwd` is rank 1 while the player's folder is rank 4. No script can
  change that. The candidate fix — stop shipping the 64 — rests on one untested assumption and would
  turn every camo black if it is wrong; the cheap test is one file.
- **Items 15–18, the four weapon ports.** 🛑 **There are no campaign fastfiles on this machine**:
  `<BO2>\zone\` holds only `all\` and `english\`. On the way, item 15's question is answered — the
  mod already ships `svu_zm` (`WEAPON_SVU`) and BO2 has no separate "dragunov" anywhere, including
  `t6zm.exe`'s string table.

---

## 6. STILL OPEN, CARRIED FORWARD

- **Deadshot head lock-on** — shipped, unverified, needs a gamepad and the `deadshot cf:` lines.
- **AIM ASSIST row** on CONTROLS > GAMEPAD — built, unbooted, needs a gamepad.
- **The jet gun overheat crash test** — overheat it and let it cool. Untouched this session on
  purpose: items 6/7/8 all sit on top of that unverified fix.
- 🛑 **GitHub release `v1.99.21` cannot start a map** and is still downloadable — the user's call.
- **`mod.iwd`'s 119 dead hash-named images** (416 MB) — still awaiting the user's OK to delete.
