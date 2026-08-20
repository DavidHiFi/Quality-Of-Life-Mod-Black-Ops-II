# Checkpoint 91 — restart checkpoint. v1.99.95 stands; next action is the Sliquifier, if a file arrives.

Written 2026-08-20, immediately after checkpoint 90, because the user is restarting for a system
update. **Checkpoint 90 is the substance — read it.** This one only names the state and the queued
next action.

---

## 0. STATE — READ THIS FIRST

**Deployed, committed, NONE OF IT BOOTED: v1.99.93, v1.99.94, v1.99.95.** Working tree clean, tag
`checkpoint-91` pushed.

| version | what | verified |
|---|---|---|
| 1.99.93 | PATCHES tab (5 rows + BACKSPEED / ANIMATED CAMO moved off GAME), SET POINTS, TELEPORT | symbols read back out of the deployed `mod.iwd` |
| 1.99.94 | PERK LIMIT draws the red ⨯ unless the row is on the vanilla 4 | deployed `mod.iwd` + Plutonium's `raw\` shadow copy |
| 1.99.95 | launch-day recoil finished — DSR 50 and Five-Seven added to `weapons/zm/` | the four defs read back out of the deployed `mod.iwd`, launch values confirmed |

All three are `.gsc` / LUI / raw-file changes: **`build.bat` only. No `build_ff.bat` was run and none
is needed** unless a `.csc` or `zone_assets\` changes.

### 🛑 THE NEXT ACTION WHEN THE USER TYPES `.`

They said, verbatim, 2026-08-20: *"expect me to hunt for the sliquifier launch code or something
along those lines so you can implement it correctly."*

**So `.` means: they are back, probably with a file. Ask for nothing else — take whatever they
brought and work the Sliquifier.**

- If they hand over an **early-2013 `zm_highrise_patch.ff`**: dump it with
  `Unlinker.exe -o <out> --include-assets script <file>`, decompile
  `maps/mp/zombies/_zm_weap_slipgun.gsc` with
  `gsc-tool.exe -m decomp -g t6 -s pc --t6fixup`, and **diff it against the shipped copy**
  (`t6 modding starter kit\reference\gsc-dump\ZM\Maps\Die Rise\maps\mp\zombies\_zm_weap_slipgun.gsc`).
  The port is then whatever that diff says — and only that.
- If they hand over **source or a decompile from somewhere else**: check its provenance FIRST.
  Checkpoint 90 §2 records how the last promising copy failed that test (a hand-edited custom-map
  template — it carried a `//` comment, and decompilers do not write comments).
- If they found **nothing**: the row stays out. They already declined a reconstruction.

Everything else — including a boot of the three unbooted versions — is behind that.

---

## 1. WHY THE SLIQUIFIER NEEDS A FILE AT ALL

One paragraph so it is not re-derived: Die Rise's gameplay scripts ship in **`zm_highrise_patch.ff`
and nowhere else** (the base `zm_highrise.ff` was dumped and holds 37 scripts, every one an `aitype`
`.csc`), and Steam keeps that fastfile at the final TU. Every copy of the script in the workspace is
that same TU version — checked, byte for byte. Legacy's own two lines do the OPPOSITE of the row's
label on this build. Full evidence: checkpoint 90 §2 and checkpoint 89 §2.

---

## 2. FIRST BOOT, WHENEVER IT HAPPENS

Unchanged from checkpoint 90 §3:

1. Checkpoint 89 §4's list for v1.99.93 — PATCHES tab, round cap (`.round 300` with REMOVE ROUND CAP
   off should land on 255), NO BARRIER ATTACKS, DOUBLE TAP 1.0, 24 ZOMBIE SOLO CAP, SET POINTS,
   TELEPORT.
2. **PERK LIMIT** in the pre-game lobby: MAP MAX now carries the red ⨯; setting the row to 4 clears
   it.
3. **DSR 50 recoil** — the one tell for v1.99.95. Launch recentres at 750 against the patch's 300,
   so the scope should settle back roughly twice as fast between shots. 🛑 Residual risk stated in
   checkpoint 90 §1: this is the first raw weapon def in this mod that competes with a map's own
   fastfile copy, and there is no offline test for which one wins.
4. Older backlog: the jet-gun overheat crash test, the Deadshot head lock-on probe, and everything
   in checkpoint 87 §0.
