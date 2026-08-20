# Checkpoint 90 — v1.99.95. The recoil patch is measured and reversed; the Sliquifier waits on a file.

Written 2026-08-20. **Supersedes 89 for status.** Checkpoint 89 held both pre-nerf rows back for the
user's decision. They chose: complete the recoil restoration, and go looking for a launch-era Die
Rise fastfile themselves.

---

## 0. STATE — READ THIS FIRST

**Deployed, committed, NONE OF IT BOOTED: v1.99.93, v1.99.94, v1.99.95.**

| version | what |
|---|---|
| 1.99.93 | PATCHES tab (5 rows + 2 moved), SET POINTS, TELEPORT — see checkpoint 89 |
| 1.99.94 | PERK LIMIT draws the red cross unless it is on the vanilla 4 |
| 1.99.95 | launch-day recoil finished: the DSR 50 and the Five-Seven |

All three are `.gsc` / LUI / raw-file changes: **`build.bat` only, no `build_ff.bat`.** Each was
verified out of the deployed `mod.iwd`, not off the `[ok]` line.

### THE NEXT ACTION

Wait for the user. Two things are theirs: **a boot**, and **a pre-patch `zm_highrise_patch.ff`**.

---

## 1. 🌟 THE RECOIL PATCH, MEASURED — and the mod already had most of it

**The method, which is reusable for any "what did the TU change" question.** Every zombies map ships
its weapon defs twice: the original inside `<map>.ff`, and Treyarch's updated copy inside
`<map>_patch.ff`. Dump both with `Unlinker --include-assets weapon` and diff field by field (the
defs are single-line `\key\value\` blobs, so a plain `diff` is useless — the parser used for this is
in the scratchpad as `wdiff.pl`).

**What the patch actually did.** Exactly eight gun families, base and Pack-a-Punched — 16 defs:
`barretm82`, `dsr50`, `fiveseven`, `hamr`, `rpd`, `tar21`, `type95`, `xm8` — and only in
recoil / spread fields. The largest moves:

| def | field | launch | patched |
|---|---|---|---|
| hamr_zm | adsViewKickCenterSpeed | 1575 | 550 |
| type95_zm | hipViewKickCenterSpeed | 1650 | 300 |
| dsr50_zm | adsViewKickCenterSpeed | 750 | 300 |
| xm8_zm | adsViewKickCenterSpeed | 2500 | 1500 |
| tar21_zm | adsViewKickYawMax | 45 | 100 |

📝 Not every `<map>_patch.ff` weapon entry is recoil: Mob's six are HUD-icon fixes plus a Thompson
damage change, TranZit's include the Five-Seven-LH ammo fix (225 → 15) and the M1911 empty-hands
animations. **Those are left alone** — this restores recoil, not bugs.

🛑 **Which base copy is "launch" depends on the map's release date.** `zm_transit`, `zm_highrise` and
`zm_nuked` carry the ORIGINAL values in their base `.ff`; `zm_prison`, `zm_buried` and `zm_tomb`
were built after the TU, and their base copies already equal the patched ones (verified by hash —
the six maps fall into exactly two groups). Take launch values from **`zm_transit.ff`**.

**The finding.** zm_qol was ALREADY shipping the launch copies of **12 of the 16** — byte-identical
to the base fastfiles, in both `mod.iwd` and `mod.ff`, inherited from whatever dump the donor was
built from. Only the DSR 50 and the Five-Seven were missing, so those two used the nerfed values.
v1.99.95 adds those four defs; a field diff confirms they differ from the TU copies **only** in
`adsSpread` and `viewKick` fields.

### Why `weapons/zm/` and not a zone declaration

`weapons/zm/<name>` is proven to load: the 43 defs already there (`as50`, `freezegun`, `crossbow`,
`fnp45` …) exist in **no** fastfile — not in `mod.ff` either — and those weapons work in game. The
other raw folder, `weapons/<name>`, holds 85 files that are *all* also in `mod.ff`, so it proves
nothing on its own.

A zone declaration was rejected on purpose: it would make `mod.ff` own the DSR 50's art, which lives
only in `zm_highrise.ff` — [[t6-modff-asset-ownership-trap]], the way Origins broke for four
releases.

### 🛑 It is not a toggle and it cannot be one

Recoil lives in the weapon file. No GSC call and no dvar changes a weapon's recoil at runtime; the
only global levers (`bg_viewKickScale`, `bg_viewKickMin/Max/Random`) are one scale for every gun,
and the patch moved different fields in different directions, so they cannot reproduce it. The only
honest alternative — cloning all 16 defs under new names and swapping the player's weapon — would
break Pack-a-Punch, the box, wall-buys and every stock `get_base_weapon_name` check. The README says
plainly that there is no switch.

### Residual risk

This is the first raw weapon def in this mod that **competes with a map's own fastfile copy**. If
the fastfile wins, the DSR 50 and Five-Seven simply keep patched recoil and nothing else changes.
There is no offline test for it — GSC has no recoil getter, and Plutonium logs nothing about weapon
loads. The tell in game is the DSR 50: launch recentres at 750 against the patch's 300, so the
scope settles back roughly twice as fast between shots.

---

## 2. THE SLIQUIFIER IS BLOCKED ON ONE FILE

Die Rise's gameplay scripts ship in **`zm_highrise_patch.ff` and nowhere else** — the base
`zm_highrise.ff` was dumped this session and holds 37 scripts, every one an `aitype` `.csc`. Steam
keeps that patch fastfile at the final TU, so the launch Sliquifier script is not on this machine.

Every copy in the workspace was checked and they are all the same version: `BO2-Raw-files`'
compiled copy decompiles byte-for-byte identical to the `gsc-dump` one; `bo2_gsc_rip_alldlc`,
`t6-scripts`, `Grand Resources` and `COD-GSC-Source` all carry `reslip_rate 6` / `max_kill_round
100`. The one file that looked different —
`t6-map-templates\zm_templates\zm_frontend\frontend\maps\mp\zombies\_zm_weap_slipgun.gsc` — is
JezuzLizard's hand-edited custom-map template: it has a **commented-out** `//thread
add_slippery_spot(...)`, and decompilers do not emit comments.

**What is needed:** any early-2013 `zm_highrise_patch.ff` (console DLC dump, or a PC backup from
before the nerf). With it the port is exact and takes an afternoon. Without it, anything shipped
would be a reconstruction, which the user declined.

---

## 3. FIRST BOOT — the whole backlog, in order

1. Checkpoint 89 §4's list for v1.99.93 (PATCHES tab, round cap, barrier attacks, Double Tap, solo
   cap, SET POINTS, TELEPORT).
2. **PERK LIMIT** in the pre-game lobby: MAP MAX should now carry the red ⨯, and setting the row to
   **4** should clear it.
3. **DSR 50 / Five-Seven recoil** — see the tell above.
4. Still outstanding from before: the jet-gun overheat crash test, the Deadshot head lock-on probe,
   and everything in checkpoint 87 §0 that has not been booted.
