# Checkpoint 38 — TranZit classic is broken, HUD fixed, weapons scoped. v1.76.0 → v1.77.0.

Written 2026-08-13. **Supersedes 37 for status.** Keep 37 §1 (two of the five items were not what
they looked like) and §4; 36 §1–§2; 35 §7; 34 §1–§2; 33 §1/§5; 32 §1; 31 §1–§2; 30 §3/§5;
29 §2–§3; 28 §1; 24 §2a/§2c; 23 §2; 22 §4–§5; 21 §2–§3; 20 §1–§2; 19; 18 §5; 15 §2.

---

## 0. STATE

| item | state |
|---|---|
| **TranZit CLASSIC** | 🛑 **BROKEN — fails at load.** Cause measured, no fix shipped, scope unknown |
| Die Rise / Mob / Buried / Origins **classic** | ❓ **untested on this build** — the next thing to do |
| Nuketown | ✅ booted clean 2026-08-12 |
| All survival modes | ✅ user: *"all the survival modes seem to work"* |
| v1.75.0 shield bar | ✅ **confirmed in game** — visible in the user's screenshot |
| v1.76.0 `.round` | 🟡 used twice in a real game (`games_mp.log`), effect not reported |
| v1.77.0 HUD fixes | 🟡 **DEPLOYED, NOT YET BOOTED** |
| 15 MP/campaign weapons | 📥 queued, scoped completely, **nothing built** |
| Frametimes | 🛑 still open, `qol_perf_probe` **still never run** |

---

## 1. 🛑 THE BIG ONE — TRANZIT CLASSIC OVERFLOWS `toplayer`

    Trying to assign 1 bits for netfield vulture_perk_toplayer
    but Client Field Set toplayer is out of space.

Full working in `QUEUE.md`. The three things worth carrying:

1. **The shortfall is exactly 7 bits (or 9), and that number is ceiling-independent.** A **1-bit**
   request failed ⇒ **0 free bits** at that instant. Vulture's outstanding demand at that point is
   `vulture_perk_toplayer` 1 + `sndVultureStink` 1 + `vulture_perk_disease_meter` 5 = 7.
2. 🌟 **THIS KILLS THE OBVIOUS FIX.** Dropping the 5-bit disease meter — the remedy already used on
   Mob via `zmqol_vulture_has_disease_meter()` — **frees 5 against a 7-bit shortfall.** It would not
   have booted. Any future reader will reach for it; it does not work.
3. 🛑 **NO VERDICT WAS ISSUED, deliberately.** The full source accounting lands near 64 but carries
   ±2 to ±4 of uncertainty, all in the four visionset/overlay widening fields, and the ceiling itself
   is *inferred* at 64 (`ERROR_CATALOGUE.md` §2 says so). **The uncertainty is larger than the
   7-bit question.** Declaring "Vulture cannot be whole here" off that is the no-guessing rule broken
   backwards.

### 🌟 THE RISK MODEL WAS WRONG AND IS NOW RIGHT

It is **not** "high stock total ⇒ high risk". It is **how much the mod has to ADD**:

> **Buried carries 63 stock `toplayer` bits and boots. TranZit carries 38 and dies.**
> Buried already owns Vulture natively, so the mod adds none of those 9 bits. TranZit owns almost
> nothing the mod turns on, so it pays full price for all of it.

---

## 2. 🛑 THE RULE THAT NOW GOVERNS EVERY "IT DOESN'T FIT" DECISION (user, 2026-08-13)

> *"if you have to make compromises or leave certain elements in a scuffed state then don't even
> bother; either try to find a way to keep something in or if you literally cannot due to limitations
> then don't even dignify asking me questions like that, no scuffed additions or features with
> missing elements, it's either vulture aid with everything working perfectly as intended just like
> normal, or not at all. Period. And this goes for any addition to the mod."*

This session offered a menu of degraded Vulture variants (cut the meter / cut Zombie Blood / cut Fire
Sale). **That was wrong and was withdrawn.** A menu whose every entry ships something scuffed is not
a question, it is three wrong answers.

**The procedure, and it is yours to execute, not the user's:**
1. Exhaust "find a way to keep it whole" — genuinely.
2. If it truly cannot be whole, **it is absent there, and you make that call**, stating the evidence.
3. Never present a degraded variant as an option.

They also asked for *"as long as you need to... as unbiased and as knowledgeable, factual as
possible"* before any final verdict. Long rigorous analysis is wanted.

---

## 3. WHAT SHIPPED — v1.77.0, `build.bat` only

| # | change | file |
|---|---|---|
| 1 | zombie counter y **−7 → −12** | `quality_of_life.gsc::zombiecounter()` |
| 2 | optional zone readout y **−19 → −24**, in lockstep | `qol_options.gsc::qol_opt_zone_hud()` |
| 3 | `qol_zone_notifier_clear()` — one notifier alive per player | `quality_of_life.gsc` |
| 4 | `zonecheck()` — one loop per player, ends on disconnect/end_game | `quality_of_life.gsc` |
| 5 | `grief_reset_message()` — per-player, not broadcast to everyone | `quality_of_life.gsc` |

**The counter move is derived, not eyeballed:** 5 units is the shield bar background's own height
(`setshader( "white", 104, 5 )`). Shifting everything above the bars by exactly that preserves every
pre-existing gap regardless of the font's true pixel height.

**The notifier overlap cause is certain from the code:** an unconditional `newclienthudelem()` held
for 3.25s + 1s of fade, with nothing referencing the element already on screen. Two zone changes
inside 4.25s ⇒ two elements at the identical centre position.

**Fixed by retirement, not a cooldown, and that is a reasoned choice.** The message states where you
ARE; a cooldown would leave the *previous* zone's name up while you stand somewhere else — a worse
bug than the overlap.

📝 Two further defects found in the same chain and fixed: `zonecheck()` was re-threaded on **every**
respawn with no guard and no endon (N spawns ⇒ N immortal loops), and `grief_reset_message()` walked
`get_players()` so one player crossing a border announced their zone on all four screens.

⚠️ **Known consequence, stated not hidden:** the shield bar is allocate-on-demand, so with no shield
carried there is now a 5-unit gap between counter and player bar. Deliberate — a reserved slot that
does not reflow beats a counter that jumps whenever a shield is picked up or lost.

---

## 4. THE 15-WEAPON REQUEST — SCOPED, QUEUED, NOTHING BUILT

Full detail in `QUEUE.md`. Headlines:

- **2 already done** (M16 ships and is boxed; "Dragunov" is not a BO2 weapon — nearest is the SVU-AS,
  already shipped). **2 impossible** (XPR-50, TAC-45 exist in no workspace mod). **10 + Bouncing
  Betty portable** from `BO2-Reimagined\weapons\zm\`.
- 🛑 **Two name traps, caught by dumping the real defs out of `zm_transit.ff`:** SWAT-556 is
  **`sig556_zm`**, not `xm8_zm` (`xm8` is the M8A1, already shipped); and the stock zombies FAL
  (`fnfal_zm`, `t6_wpn_ar_fal_view`) is **not** the FAL-OSW (`sa58_zm`, `t6_wpn_ar_sa58_view`).
- 🛑 Reimagined **removes** the stock FAL from the box to make room (`_zm_reimagined.gsc:2237-2239`).
  **Do not port that line.**
- ⚠️ The real risk is the **weapon-count ceiling**: Origins runs 178 weapon assets under this mod
  today and boots, so the bound is ≥178; +11 weapons lands near 204.

---

## 5. NEXT — in this order

1. 🛑 **Boot Die Rise, Mob, Buried and Origins in CLASSIC.** No build needed. Each either loads or
   prints one line naming a field and a set — and every such line is another exact zero-free-bits
   measurement like TranZit's. **Nothing should be designed until the scope is known**: a fix aimed
   only at TranZit is worthless if three other maps need one too.
2. Boot v1.77.0 and check the counter clears the shield bar, and that spamming a zone border in
   Origins no longer stacks the notifier text.
3. 🛑 **Run `qol_perf_probe 1` mid-game**, still never once done, plus `developer_script 1` — per
   `ERROR_CATALOGUE.md` §8 every GSC runtime error is currently swallowed.

📝 An exact instrument exists if it comes to it: a dvar-gated dummy `toplayer` field of N bits
registered last on **both** sides, binary-searched per map, gives exact headroom with no feature
loss. Deliberately not built — it can itself cause `EXE_CLIENT_FIELD_MISMATCH` if the sides ever
disagree, and that risk is not worth taking before the scope in step 1 is known.
