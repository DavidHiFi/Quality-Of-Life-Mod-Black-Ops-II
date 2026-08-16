# Checkpoint 65 — v1.99.19. Origins, the corpse and the clone glow are CONFIRMED. The grade was being suppressed by our own code.

Written 2026-08-16. **Supersedes 64 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.19 deployed, bytes verified, never booted

User on v1.99.18: *"ok it all works, the only thing is who's who doesn't show the red screen when i
go down, but everything else works fine."*

| # | item | state |
|---|---|---|
| 1 | ~~Tac-45~~ · ~~Winter's Howl fx~~ · ~~Riser sound~~ | ✅ **CONFIRMED AND CLOSED.** 🛑 Do not re-open. |
| 2 | ~~Origins boot crash~~ | ✅ **CONFIRMED FIXED** (v1.99.18). 🛑 Do not re-open. |
| 3 | ~~Who's Who invisible corpse~~ | ✅ **CONFIRMED FIXED** (v1.99.18). 🛑 Do not re-open. |
| 4 | ~~Who's Who clone glow~~ | ✅ **CONFIRMED WORKING** (v1.99.18, TranZit). 🛑 Do not re-open. |
| 5 | **Who's Who — the red screen grade** | 🟡 root cause found in our OWN code, rewritten to stock's path, **unbooted.** §1 |
| 6 | **`mod.ff` stale server scripts** | 🔴 **next in line** once §1 closes. Evidence in checkpoint 63 §3. |
| 7 | Who's Who description | 🟡 built v1.98.0, never booted |
| 8 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 9 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 10 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 11–17 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 THE NEXT BOOT IS ONE CHAT COMMAND
On TranZit / Diner, type **`.wwfx`**. The screen should go red immediately; `.wwfx` again clears it.
No dying, no perk needed. Then check the console log for
`[zm_qol] whoswho visionset: registered, slot_index N` — that line now prints at every map load.

---

## 1. 🌟 WE HAD BEEN SWITCHING OFF THE THING THAT WORKS, SINCE v1.99.14

v1.99.18 removed night mode's exposure crush and the red still did not show. That ruled out
brightness and left one candidate, and it was the **first line of the function whose whole job is to
show the grade**:

```
zmqol_whoswho_overlay_on()
{
    self setclientdvar( "r_filmUseTweaks", 1 );     <-- since v1.99.14
```

🛑 `r_filmUseTweaks` is *"Overide film effects with tweak dvar values"*. Setting it to **1** makes the
renderer **ignore every visionset** — including stock's own `zm_whos_who`, the exact effect this
function exists to produce.

**The shape of the mistake:** the `vc_*` copy was invented to survive night mode, which does hold
`r_filmUseTweaks 1`. But the copy was applied **unconditionally**, so on every map and in every
session — night mode on or off — the mod turned the real mechanism off and then tried to
hand-reproduce it. The reproduction never landed, and it was covering for a mechanism that did not
need covering.

### The real path, verified before the rewrite rather than assumed

| half | where | evidence |
|---|---|---|
| server registration | stock `_zm_perks::turn_chugabud_on()` :1448, gated on `level.vsmgr_prio_visionset_zm_whos_who` | `zmqol_enable_whoswho()` sets that var |
| client registration | `zm_expanded.csc::perks_register_clientfield()` (v1.63.1), inside the visionset manager's window | present in source and in the shipped `mod.ff` |
| **they agree** | — | 🌟 **the map booting is the proof.** `finalize_type_clientfields()` derives `visionset_slot`'s bit width from each side's visionset count, so one side short is a load-time `visionset_slot ... [CLIENT: 1 SERVER: 2]`. That is the error v1.63.1 hit and fixed; no error now means symmetric now. |
| the asset | `vision/zm_whos_who.vision` | inside the **deployed** `mod.ff` (`Unlinker --list`) |
| activation | `activate_chugabud_effects_and_audio()` calls `vsmgr_activate()` | same four consecutive lines as the audio, and the audio is confirmed working in game |

**So `zmqol_whoswho_overlay_on()` now does exactly one thing: get night mode out of the way** —
`r_filmUseTweaks 0`, `r_exposureTweak 0`, `r_bloomTweaks 0` — and `overlay_off()` puts those three
back. The 23 copied values are **deleted**, not kept as a fallback: two mechanisms fighting over one
screen is what caused this.

🟡 While the ghost state is up **night mode is suspended**, so the world brightens and loses its blue
tint for those ~30 seconds. That is inherent — a visionset and a film-tweak grade cannot both own the
screen — and the user has been told rather than surprised.

## 2. TWO INSTRUMENTS ADDED, BOTH TO AVOID SPENDING A BOOT ON THE NEXT GUESS

- **`.wwfx` now drives the real mechanism** (`vsmgr_activate` / `vsmgr_deactivate`) instead of the
  dvar copy. Before, it exercised only the copy — so it could not have distinguished "the visionset
  is broken" from "the copy is broken", and **the copy was the broken half**. It prints the slot
  index too.
- **`zmqol_whoswho_visionset_probe()`** prints at every map load: registered / not registered /
  registered-but-`slot_index`-unassigned, plus the total visionset count. If the grade still does not
  show, the next log names which half is wrong.

## 3. METHOD NOTES WORTH KEEPING

- 🌟 **Suspect your own workaround before the engine.** Three rounds went into making a
  reproduction land; the reproduction was never needed, and the line that installed it was also the
  line that broke the original. When a hand-built substitute for a stock mechanism does not work,
  check whether the substitute is what is disabling the stock mechanism.
- 🌟 **"It boots" is evidence, not just relief.** Clientfield symmetry is enforced at load, so a
  clean boot *proves* both sides registered the same visionsets — that settled offline what would
  otherwise have been a guess about the client half.
- 🌟 **A test aid that exercises the workaround instead of the mechanism is worse than none** — it
  produces confident wrong conclusions. `.wwfx` was that for four versions.
- **Fix the diagnosis in the README in the same commit.** It has now carried three different
  explanations of this one effect; each was corrected as it was superseded, not left to rot.
