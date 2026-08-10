# Checkpoint 32 — frametimes reported FIXED, but the cause was never established.

Written 2026-08-11, same session as 30 and 31. Supersedes 31 for status.
**Keep 31 §1 (the `*_lerp` trap) and §2 (the LUI blind spot) — they are the durable findings.**
Keep 30 §3 and §5, 29 §2–§3, 28 §1, 24 §2a/§2c, 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **Frametimes / latency** | ✅ **user: "its fixed"** — but 🛑 **cause NOT attributed, see §1** |
| **Zombie Blood** (TranZit, Nuketown, Die Rise, Buried) | ✅ confirmed on TranZit |
| **Mob of the Dead boots** | ✅ confirmed, v1.65.2 |
| **Wunderfizz docks machine** | ✅ **placement confirmed from the log** — landed clear of the shield spawn (§2). User has not said it *looks* right |
| Power-up icons (Zombie Blood + Fire Sale) | 🚧 v1.65.1, never visually confirmed |
| The three announcer lines | 🚧 shipped, **user has never said whether they hear them** |
| Buried classic with Zombie Blood | ⏳ never booted — the remaining budget risk |
| Die Rise / Nuketown with Zombie Blood | ⏳ never booted |
| `qol_perf_probe` scaffolding | ⚠️ **still in the build, still inert. KEEP IT** — see §1 |

**Next action: ask what is actually worth confirming** — the announcer lines and the two icons are
the only parts of this session's work never eyeballed, and Buried classic is the only untested
budget. Then TASKS_QUEUE_01 #4 (Semtex wall-buy).

---

## 1. 🛑 THE FRAMETIME BUG IS "FIXED" AND I CANNOT SAY WHY — read this before touching perf again

The user reported it fixed after v1.65.5. **Do not record this as a solved problem, and do not
credit any of the three changes below**, because the evidence does not support any of them.

### What the logs establish

- **`qol_perf_probe` was NEVER USED.** Zero occurrences in any log, and it never appears in a dvar
  dump. The diagnostic that was built to answer this question was not run, so it answered nothing.
- **No engine or graphics dvar changed** between the framey session and the fixed one. Joining the
  two logs' dvar dumps on name and comparing values, the *only* difference in the entire set is
  `demo_currentDemo`. `com_maxfps` is still `"90"` in both.
- **The code delta between "still framey" and "its fixed" is v1.65.4 + v1.65.5**, i.e. an inert
  default-off dvar and a Wunderfizz *coordinate*. **Neither can plausibly affect frame pacing.**

| log | time | build | hitches |
|---|---|---|---|
| `.009` | 05:36 | v1.65.3 — user said "still framey as hell" after this | 9 |
| `.000` | 06:08 | v1.65.4 | 10 |
| current | 06:16 | v1.65.5 — user said "its fixed" | 7 |

Hitch counts are flat across all three, which is consistent with the earlier finding that hitch
warnings are **load-time and long-standing** and were never the thing the user was feeling.

### The honest conclusion

The most likely explanations, none confirmed: v1.65.3's HUD fixes did help but the "still framey"
report was made from memory or a short session; or something outside the game changed (background
process, driver overlay, thermals); or it was transient.

🛑 **SO IT MAY COME BACK.** If it does:

1. **`qol_perf_probe 1` FIRST.** It is still in the build, still default-off, and still splits the
   problem cleanly — scripts vs assets. That is why it has NOT been removed despite checkpoint 31
   saying to remove it "once the cause is known". The cause is not known.
2. **`developer_script 1`** — it was `"0"` all session, so per ERROR_CATALOGUE §8 every GSC runtime
   error was being swallowed. An error firing each frame inside a loop is invisible right now.
3. Do **not** re-derive §3 of checkpoint 31: `com_maxfps` is 90 so the FPS reading is a cap;
   `logfile` is already `2`; hitching predates all of this work.

📝 The v1.65.3 HUD changes stay regardless — they are strictly less work for identical behaviour
and fix a defect class this project has documented (`settext` per tick = reliable-command flood).
They are just not *proven* to have fixed anything.

---

## 2. ✅ THE WUNDERFIZZ DOCKS MOVE LANDED — confirmed from the log, not assumed

The source now says `(-900, 5585, -72)`; the log's own placement print for the newest session reads:

```
[zm_qol] wf parts: machine(-897,5573,-72)
```

So `zmqol_wf_unclip()` found geometry behind it and nudged it ~12 units forward at runtime — the
safety net working exactly as designed. Final separation from the
`alcatraz_shield_zm_dolly` struct at `(-831.73, 5587.2, -71.75)`: **66.8 units, from 11.5.**

🌟 **The reusable method** (checkpoint 31 §4): dump `mapents`, extract every candidate and every
part struct with its origin, and check ALL of one against ALL of the other programmatically. Six Mob
machines × ten `alcatraz_shield_zm_*` structs found exactly one pair under 400 units.

⚠️ Still true: **mapents cannot see static BSP geometry**, so a world-brush crate appears in none of
those checks. If a placement ever looks wrong, ask the user to stand where it should go and send a
`.where`.

---

## 3. WHAT THIS SESSION SHIPPED — v1.65.0 → v1.65.5

| ver | change |
|---|---|
| 1.65.0 | Zombie Blood ported to five maps + the three announcer lines + the first sound-bank duck this project ships |
| 1.65.1 | the Zombie Blood power-up icon, **and Fire Sale's**, which had been a checkerboard on TranZit/Die Rise since v1.55.x |
| 1.65.2 | Zombie Blood off Mob — its `toplayer` set is full (the `*_lerp` trap, 31 §1) |
| 1.65.3 | three always-on HUD loops stopped rewriting unchanged values |
| 1.65.4 | `qol_perf_probe` diagnostic |
| 1.65.5 | Wunderfizz docks machine moved off the shield-part spawn |

Zombie Blood ships on **four** maps, not five — README and MOD_CATALOGUE §7a corrected to match.

---

## 4. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | ✅ DONE |
| 2 | Zombie Blood onto every map | ✅ **DONE**, confirmed on TranZit; Mob excluded on measured budget grounds |
| 3 | Blood Money dropping from kills rather than dig sites | 🚧 shipped v1.64.0, **still never confirmed** |
| 4 | Semtex wall-buy on Diner and Bus Depot | **NEXT**, not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

Also outstanding: QUEUE §0B, every chat command must also be a dvar — [[zm-qol-commands-as-dvars]].
Governing rule: **port it, never tune it** — [[zm-qol-port-never-tune]].
