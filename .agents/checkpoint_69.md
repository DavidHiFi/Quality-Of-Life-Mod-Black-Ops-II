# Checkpoint 69 — v1.99.22. v1.99.21 was fatal on EVERY map. One dead reference, now fixed.

Written 2026-08-17. **Supersedes 68 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.22 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | ~~Who's Who~~ · ~~Tac-45~~ · ~~Winter's Howl~~ · ~~Riser sound~~ · ~~Origins crash~~ · ~~invisible corpse~~ · ~~clone glow~~ | ✅ **CLOSED.** 🛑 Do not re-open. |
| 2 | **`clientnotifyloop` unresolved external** | ✅ **CONFIRMED IN GAME 2026-08-17.** §1–§3, §6 |
| 3 | `mod.ff` stale scripts (checkpoint 68) | ✅ **CONFIRMED IN GAME 2026-08-17.** §6 |
| 4 | Who's Who **description** | 🟡 built v1.98.0, never booted |
| 5 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 6 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 7 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 8–14 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### THE VERIFICATION IS STILL A GREP
Boot **any** map, quit, then search `console_zm.log` for `WARNING` — checkpoint 68's four
`replaceFunc` collision lines must be gone. That verification is now **stacked behind** this fix,
because v1.99.21 never reached a map.

---

## 1. WHAT BROKE

```
**** Unresolved external : "clientnotifyloop" with 2 parameters
     in "maps/mp/zombies/_zm_perk_divetonuke.gsc" at lines 1,1
```

`_zm_perk_divetonuke.gsc:60,71` called `scripts\zm\zm_expanded::clientnotifyloop`.
`zm_expanded.gsc` is the pre-merge module that became `quality_of_life.gsc`. It was deleted from the
project months ago — but it survived **baked inside `mod.ff`**, which is exactly what checkpoint 68
removed. The moment the fastfile stopped shipping it, the namespace ceased to exist and this became
a **load-time** link failure.

🛑 **Not Origins-specific, and the user's report should not be read as map-specific.**
`quality_of_life.gsc:57` has `#include maps\mp\zombies\_zm_perk_divetonuke;` and
`quality_of_life.gsc` is a **root** script — so `_zm_perk_divetonuke.gsc` is loaded on **every** map,
and so was the error. Origins is simply the map that was tried. **v1.99.21 could not start any map,
and it is a published GitHub release.**

## 2. 🌟 THE LESSON — checkpoint 68 audited the wrong direction

Checkpoint 68 §2 is a careful audit of **what `zm_expanded.gsc` did** — 4 hooks, 82 `precacheitem`,
`perks()`, the weapon monitor — and every finding in it is correct. It concluded "nothing is lost".

**It never asked what referenced `zm_expanded`.** Deleting a script needs both:

| direction | question | checkpoint 68 |
|---|---|---|
| outbound | what does this script *do* that would be lost? | ✅ done thoroughly |
| **inbound** | **what *calls into* this script and would dangle?** | ❌ **never asked** |

One `grep -rn "zm_expanded::"` over the tree — two seconds — would have caught it before the release.
📝 A sweep tool now exists for this: it maps every shipped `.gsc` to the functions it defines, then
checks every qualified `a\b\c::func` reference against that map. It reported **2 before / 0 after**.
Worth keeping for any future script removal.

## 3. THE FIX, AND WHY EACH HALF IS PROVEN AND NOT ASSUMED

Both calls now read `scripts\zm\quality_of_life::clientnotifyloop`.

| doubt | how it was settled, offline |
|---|---|
| Is `quality_of_life`'s copy the *same* function? | Dumped the donor `zone_source\base\mod.ff` with `Unlinker --include-assets script` and read the real deleted `zm_expanded.gsc:527`. Body is identical to `quality_of_life.gsc:10250` — blank lines only. |
| Does a `maps\…` script resolve a `scripts\zm\…` target? | **This exact file did it for months.** Same shape, same folder. |
| Does a target that lives only in raw `mod.iwd` (no fastfile copy) resolve? | Yes — `scripts\zm\wunderfizz`, `scripts\zm\replaced\utility`, `scripts\zm\locs\loc_common` are raw-only and are called this way today. |
| Does the include **cycle** matter? (`quality_of_life` includes divetonuke; divetonuke now references `quality_of_life`) | The deleted `zm_expanded.gsc:6` **also** `#include`d `_zm_perk_divetonuke` while divetonuke referenced `zm_expanded::`. Identical cycle, already shipped. |
| Do the `::` references in my new **comment** re-break it? | No. `quality_of_life.gsc:11434` has carried `scripts\zm\replaced\_zm::onallplayersready` in a comment for ages and that script does not exist — comments are provably inert. |
| Is the client half still there? | `zm_expanded.csc:1681/1700` still `waittill` both notifies. `.csc` was never touched — checkpoint 68 removed only `.gsc`. |

## 4. VERIFIED BEFORE HAND-OFF

- `gsc-tool -m parse` clean on `_zm_perk_divetonuke.gsc` and `quality_of_life.gsc`.
- Sweep of all **25** shipped `.gsc` namespaces: **0** dangling functions, **0** missing scripts.
- All 6 files SHA256-match `…\storage\t6\mods\zm_qol\`; deployed `mod.json` reads `1.99.22`.
- Opened the **deployed** `mod.iwd` as a zip and read
  `maps/mp/zombies/_zm_perk_divetonuke.gsc` out of it — both call sites say `quality_of_life`.
- No `build_ff.bat` run: nothing under `zone_source\` or `zone_assets\` changed.

🛑 **Deployed, NOT yet verified in game.**

## 6. ✅ VERIFIED IN GAME — Origins boot, 2026-08-17 12:44

The user booted `zm_tomb` on v1.99.22 with no error box. `console_zm.log` (copied live before
reading; all 11 rotations compared) settles **both** open items at once:

| check | result |
|---|---|
| `replaceFunc` collision `WARNING`s (checkpoint 68's four) | **0** — gone |
| `scripts/zm/zm_expanded.gsc` mentioned anywhere in the log | **0**, against **2 in every prior session** |
| script source of every mod `.gsc` | **all `from raw`**, none `from fastfile` |
| `_zm_perk_divetonuke.gsc` | loaded `from raw`, no unresolved external |
| `quality_of_life::main()` / `::init()` | both `GSC Executed` |
| any script error / clientfield mismatch | none |

🌟 **`zm_expanded.gsc` going from 2 mentions to 0 is the cleanest possible proof** — better than the
absence of a warning, because it is a positive count that changed.

### Two log lines that are NOT regressions — checked against all 11 rotations before saying so
- `Could not load material "specialty_divetonuke_zombies"` — **2 per session, in every session,
  unchanged**. Alongside ~300 stock materials logging the same line, so it is not by itself evidence
  the PhD Flopper icon is broken. → queue **12**.
- `Warning - re-registration of animtree fxanim_props(_dlc4)` — present yesterday on Mob (5) and
  TranZit (4) under v1.99.20, so it **pre-dates** both changes. Origins' pair is symmetric
  (server + client), which is the safe shape per [[t6-animtree-registration-order]]; Mob's was not.
  → queue **13**.
- `scripts/zm/ranked.gsc` loads on every map — **Plutonium's own**, present in all sessions, not the
  mod's. Not a finding.

## 5. OUTSTANDING DECISION FOR THE USER

**The published GitHub release `v1.99.21` cannot start a map.** v1.99.22 has taken over as *Latest*,
so `/releases/latest` now serves the working build — but **v1.99.21 is still downloadable** from the
releases page and anyone who took it has a mod that boots to an error box. Deleting it, or editing
its notes to warn, is an outward-facing change and has **not** been done without the user's say-so.
v1.99.22's own notes open with a warning to replace it.

---

## 7. CHECKPOINT + RELEASE — done 2026-08-17

On the user's *"checkpoint and release"*:

- **Tag `v1.99.22`** (annotated) created and pushed, with **4 commits** (`ffe1398..0c6c7b0`).
  Previous tag was `v1.99.21`. `origin/main` is level with local — 0 unpushed.
- **GitHub release published:** https://github.com/DavidHiFi/zm_qol/releases/tag/v1.99.22 —
  **Latest**, not a draft, not a prerelease, asset `state=uploaded`.
- **Asset:** `zm_qol-v1.99.22.zip`, 137,499,560 bytes (131.1 MB). Top-level folder `zm_qol/`, so it
  drag-and-drops straight into `…\storage\t6\mods\`. Entry count verified as **6**, sourced from the
  deployed folder **after** a 6/6 SHA256 check against source, and
  🛑 `cmn_root.all.sabl` confirmed **absent** ([[zm-qol-github-release-workflow]]).
- 🌟 **This is the first release in a while that is not shipping an unbooted build** — the notes lead
  with what was confirmed in game and how, and they tell anyone on v1.99.21 to replace it.
- **README truth pass done in the same round** (see the commit): two stale claims corrected —
  Who's Who now reads as finished and confirmed with its accepted limits, and the Origins/Mob crash
  as open but not being worked on. The ⚠️ WORK IN PROGRESS notice is still at README.md:7 and opens
  the release notes; the GitHub repo description still opens with `WORK IN PROGRESS` and is accurate.
