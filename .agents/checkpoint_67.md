# Checkpoint 67 — v1.99.20. Who's Who is CLOSED by the user. Next: the stale `mod.ff` scripts.

Written 2026-08-16. **Supersedes 66 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.20, in game, Who's Who closed

*"ok forget the blood overlay fx it all works, whos who is done remove it from the queue, it's fine
as is im happy with it."*

| # | item | state |
|---|---|---|
| 1 | ~~Who's Who — the whole perk~~ | ✅ **CLOSED BY THE USER, v1.99.20.** 🛑 Do not re-open, re-probe or "improve" it. §1 |
| 2 | ~~Tac-45~~ · ~~Winter's Howl fx~~ · ~~Riser sound~~ · ~~Origins boot crash~~ · ~~invisible corpse~~ · ~~clone glow~~ | ✅ **CONFIRMED AND CLOSED.** 🛑 Do not re-open. |
| 3 | **`mod.ff` runs stale pre-merge scripts** | 🔴 **NEXT.** Evidence in checkpoint 63 §3, plan in §3 below. Nothing started. |
| 4 | Who's Who **description** | 🟡 built v1.98.0, never booted. **Still on the list** — a separate entry from the screen fx, flagged to the user. |
| 5 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 6 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 7 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 8–14 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

🛑 **Nothing is in flight.** The next change starts only when the user picks one.

---

## 1. WHO'S WHO — WHAT SHIPPED, AND THE ONE THING STILL UNEXPLAINED

**Closed on the user's decision, not on a claim that every mechanism is understood.** Recording the
difference because the difference matters.

### The completeness audit, all six parts

| | |
|---|---|
| functionality | stock `_zm_chugabud` throughout — clone, revive trigger, bleedout, self-revive, loadout restore. Nothing reimplemented. |
| visual fx | ghost-state colour grade (`vision/zm_whos_who.vision`), `generic_filter_afterlife` screen filter, corpse glow shader |
| sound fx | sting, looper and mixer snapshot — confirmed in game |
| animations / models | stock clone via `spawn_player_clone`; on TranZit the `_dlc1_fb` bodies, the only glow-capable version of those characters that exists |
| client half | `clientfield_whos_who_audio` / `_filter` / `_clone_glow_shader` + the `scriptmover` twin, every one registered on both sides |
| no regressions | Origins boot crash and the invisible corpse were **caused** by this work and are both fixed and confirmed |

**Known and accepted limits, all reported at the time, none hidden:**
- clone glow is **zm_transit only** — the `_g` materials cover the Victis crew and nobody else
- on TranZit the clone wears the **Die Rise outfit** for the same reason
- **Buried** and **Mob** do not get the perk (32/32 `actor` bits; Mob has no `specialty_quickrevive_zombies`)
- no shellshock — stock gates it on `level.chugabud_shellshock`, which stock never sets
- no red last-stand screen — stock skips last stand entirely with this perk ([[t6-whos-who-no-laststand]])

### 🛑 THE UNEXPLAINED PART, AND MY CHECKPOINT 66 THEORY WAS WRONG

v1.99.20 shipped probes on both sides. They came back **identical**:

```
[zm_qol] whoswho visionset: registered, slot_index 3, total visionsets 4          <- server
[zm_qol] CLIENT whoswho visionset: registered, slot_index 3, total visionsets 4   <- client
[zm_qol] CLIENT whoswho: vision -> zm_whos_who (was 'zm_transit')                 <- the direct apply
```

**So the visionset manager was symmetric all along.** Checkpoint 66 §2 suspected the client was one
registration short and resolving a slot that did not exist — *that is disproved*. Both sides had 4
visionsets and both put `zm_whos_who` at slot 3.

Which means: under v1.99.19 the manager path had matching slots, night mode was off, the server
activated the visionset — **and the grade still did not reach the screen.** Why the manager's
`visionsetnakedlerp` did not take when the direct `visionsetnaked` does is **still unknown**. The
working difference is the direct call, and that is what ships.

🌟 **The bit-width trap in checkpoint 66 §2 is still a real trap** — 3 and 4 visionsets genuinely are
both 2 bits, and a desync there genuinely would be silent. It just was not what was happening here.
A correct general fact, wrongly applied to this case. [[t6-visionset-slot-silent-desync]] is written
that way.

📝 If Who's Who is ever touched again — **and it should not be** — the open question is the
`state.curr_lerp` value the manager passes to `visionsetnakedlerp`, since `zm_whos_who` registers
`lerp_step_count 1` while a sibling on this map (`zm_powerup_zombie_blood_visionset`) registers 15,
so the shared `visionset_lerp` field is 4 bits wide and its value for a 1-step info is not obviously
"fully applied". That is a hypothesis, not a finding.

## 2. WHAT THIS RUN COST, AND WHAT WOULD HAVE CUT IT SHORT

Seven versions and four boots on one screen effect. Two of those boots were spent on causes I had
reasoned to rather than measured:

- **v1.99.17's three-state red** — built on the belief that Who's Who goes through last stand. One
  `return 0` at `_zm.gsc:4239` says it does not. **Reading the early exits first would have cost
  five minutes.**
- **v1.99.18's exposure fix** — real (the picture *was* 2.7× too dark) but not the blocker.
- **v1.99.19** — found the actual self-inflicted bug (`r_filmUseTweaks 1` in our own overlay), which
  had been suppressing the stock mechanism since v1.99.14.

🌟 **The instrument that ended it was a print on each side.** It should have been the *first* move
after "the effect does not appear", not the fifth. Client `println` reaches `console_zm.log` — the
mod had been doing it for other features the whole time.

## 3. NEXT: THE STALE `mod.ff` SCRIPTS — SCOPED, NOT STARTED

Evidence is in checkpoint 63 §3: `console_zm.log` shows **four** `replaceFunc` collisions on the perk
path (`perks_register_clientfield`, `init_client_flags`, `give_perk`,
`default_vending_precaching`) between the **day-one `scripts/zm/zm_expanded.gsc` baked into
`mod.ff`** and the live `quality_of_life.gsc`. `quality_of_life` wins all four, so this is not
breaking anything today — but the stale script's `main()` and `init()` still run and do duplicate
work, and `mod.ff` also carries day-one copies of every per-map `.gsc`.

**The plan:** strip the stale `.gsc` declarations from `zone_source\mod_base.zone`, keep **every**
`.csc` (client scripts only load from a fastfile). Full inventory from
`Unlinker --include-assets script`: `zm_expanded.gsc`, the six `zm_<map>/zm_<map>.gsc`,
`freeze/teslagun/thundergun.gsc`, and the three `maps/mp/zombies/_zm_weap_*.gsc`.

🛑 **`mod_base.zone` is generated, not hand-written** (`build_ff.bat regen`). Removing lines by hand
is exactly the kind of edit a regen silently undoes — settle that before editing anything.
[[t6-modff-runs-stale-gsc]]
