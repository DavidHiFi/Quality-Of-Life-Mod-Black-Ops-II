# Checkpoint 26 — v1.62.9. Electric Cherry: the probe answered. Deployed, NOT booted.

Written 2026-08-09. Supersedes checkpoint 25 (v1.62.7, fx **confirmed improved** in game).
Keep 24 §2a (you can patch ONE LUI function) and §2c (offline Lua validation).
Keep 23 §2, 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

**Read §0, §2 and §3.**

---

## 0. THE SINGLE NEXT ACTION

**Get Electric Cherry, EMPTY A FULL MAGAZINE, then reload with a crowd on you.**

That is the case that was never tried in three rounds of reports. Expect radius 128 / damage 1045 —
the whole close ring shocked and killed at once, landing together rather than trickling.

Then **reload-spam five times in a row**: attack #5 used to do literally nothing and now works.

Nothing else starts until that is confirmed — [[zm-qol-one-at-a-time]].

**Still deployed and NEVER booted, from earlier rounds:**

| version | how to test |
|---|---|
| v1.62.0 | Boot **Mob**, carry two plane parts at once. Log: `[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N` |
| v1.62.3 | Vulture's through-wall icons should have real shapes, not colour blurs |

🛑 v1.62.4 (Vulture perk-machine markers) is **measured broken** — `0 of 43 structs match`. See
checkpoint 24 §4.

---

## 1. WHAT HAPPENED THIS SESSION

1. **v1.62.7 CONFIRMED** — the zombie-body zap fx is right now. The `--load`-order fix held.
2. **v1.62.8's probe was booted and answered the question outright** (§2). The perk was stock and
   running correctly; the user's play pattern was getting ~3% of its power.
3. **v1.62.9 shipped** — stock's curves kept at the user's explicit instruction, two genuine defects
   removed, and one Origins regression caught offline before it shipped (§3).

---

## 2. 🌟 THE FINDING — INSTRUMENT THE ARITHMETIC, NOT THE CODE PATH

Three rounds had been spent asking *"is our code stock?"* and answering it from the files — correctly,
every time, and it never moved the user. What settled it was **printing the numbers stock computes at
runtime** and letting one boot speak.

### Electric Cherry's power is bought with the magazine

```
radius = linear_map( clip_fraction, 1.0, 0.0,  32, 128 )   full clip -> 32 units,  empty -> 128
dmg    = linear_map( clip_fraction, 1.0, 0.0,   1, 1045 )  full clip -> 1 damage,  empty -> 1045
```
(`_zm_perk_electric_cherry.gsc:238-239`. 📝 `linear_map` is
`clamp( (num-min_a)/(max_a-min_a)*(max_b-min_b)+min_b, min_b, max_b )`,
`common_scripts\utility.gsc:1503` — with `min_a=1.0, max_a=0.0` a FULL clip gives the LOW end.)

**All 14 reloads in the user's session were at 65–97% clip.**

| their reload | radius | dmg | outcome |
|---|---|---|---|
| clip 39/40 (typical) | 34 | 27 | 1–3 zombies in range, none killed |
| clip 5/8 (their best) | 68 | 392 | still no kills at that round |
| clip 0/40 (**never done**) | **128** | **1045** | the horde zap they expected |

Radius 34 units means a zombie must be *touching* the player. Every radius/damage pair in the log
reproduces the formula exactly — so the mod was running the genuine perk, unmodified, and the report
*"only 1 or 2 got shocked and they didn't even die"* is that arithmetic, not a defect.

### 🔎 The method, worth reusing verbatim

1. **When "is it stock?" keeps being answered yes and the user keeps disagreeing, stop re-answering
   it.** Ship a probe that prints what stock *computes*, not what it *is*. Both sides then read the
   same numbers and there is nothing left to argue about.
2. **Print every input to the disputed behaviour in one line**, not the one you suspect —
   `clip`, `radius`, `dmg`, `limit`, `zombies_alive`, `in_radius`, `nearest`. The cause was `clip`,
   which was not the suspected field.
3. **A probe's own counters are code and can be wrong.** `n_zombies_hit` was only incremented inside
   stock's throttle branch, so `touched N` printed **0** whenever the throttle was inactive — which
   nearly manufactured a second phantom bug. Read what a counter is gated on before believing it.
4. **Offer the balance decision as numbers, not prose.** Three concrete curve tables let the user
   pick in one message. They chose stock's, and that closed a question that had run for three rounds.

---

## 3. WHAT SHIPPED — v1.62.9

🛑 **Radius and damage are UNCHANGED.** The user was asked directly and chose stock's curve over a
raised floor and over flat-max. Reimagined leaves both curves untouched too. **To get the horde-wide
zap, empty the mag** — that is the perk, not a compromise.

### Three defects out

1. **The consecutive-reload throttle is deleted.** Stock capped attack #3 at 4 zombies, #4 at 2 and
   **#5+ at ZERO** — a reload that costs a magazine and silently does nothing, with no feedback of
   any kind. Reimagined deletes it outright (`_zm_perk_electric_cherry.gsc:66`).
2. **The 0.1s per-zombie damage stagger is deleted.** Stock waited before EACH `dodamage`, so a crowd
   of 20 resolved over two seconds and the zap visibly trickled. The loop stays bounded by
   `a_zombies.size`, so removing its only wait carries no unterminated-loop risk, and both fx helpers
   already use Treyarch's own `network_safe_play_fx_on_tag` throttle — built for exactly this.
3. **The reload latch watchdog** (v1.62.8) kept. No `SKIPPED` lines appeared in the log, so it was
   not what the user was hitting, but it is a real defect and stays fixed.

### 🛑 A REGRESSION CAUGHT OFFLINE — ORIGINS SHIPS ITS OWN COPY OF THE FUNCTION

**Generalise this: owning a perk globally silently overwrites any map that overrides it.**

`zm_tomb.gsc:2003` defines `tomb_custom_electric_cherry_reload_attack`, registered at `:178` in place
of core's. The pointer re-point replaces it. Its two deliberate differences are now carried inline,
both guarded on `level.script`:

| difference | why it matters |
|---|---|
| raw `getaispeciesarray( "axis", "all" )` instead of `get_round_enemy_array()` | the latter filters `.ignore_enemy_count` actors, and `_zm_ai_mechz.gsc:532` sets that flag on **the Panzer Soldat** — core's array drops the Panzer out of the zap entirely on Origins |
| stun guarded on `.is_mechz`, not `.is_brutus` | without it, the global version would `animscripted()` a Panzer, which stock deliberately never does |

The stun guard ships as the **union** of both flags: `is_brutus` exists only in Mob's
`_zm_ai_brutus.gsc` and `is_mechz` only in Origins' scripts, so only one can ever be defined on a
given map and the union is exactly each map's own guard. It cannot over-exclude anywhere.

**Origins is the only map that overrides this** — three hits for
`register_perk_threads( "specialty_grenadepulldeath" )` across all 2,093 stock scripts: core,
Origins, and TranZit's byte-identical copy of core. Run that grep before owning any other perk.

### Verified before hand-off

- parses (`gsc-tool -m parse -g t6 -s pc -y`)
- deployed `mod.iwd` **byte-identical to source**, and carries all four changes individually
  confirmed (mechz guard present, Origins array branch present, throttle switch absent, stagger absent)
- `mod.ff` md5 `587f2f7c…` **unchanged** from v1.62.7's audited build — `.gsc`-only round, no
  `build_ff.bat` needed, and the shader fix rides along untouched
- `README.md` makes no Electric Cherry claim, so no doc correction was owed

---

## 4. THE USER'S TASK LIST — `H:\Claude\TASKS_QUEUE_01.txt`

Top to bottom, one at a time. Scope rule: *"if I ask you to add something don't just consider Diner —
add it to all maps unless specified otherwise."*

| # | task | state |
|---|---|---|
| 1 | Who's Who + Electric Cherry as literal genuine ports | **EC half done pending this boot**; Who's Who half scoped, not started — QUEUE §A2 |
| 2 | Zombie Blood power-up from Origins onto every map | not started |
| 3 | Blood Money power-up, dropping from kills rather than dig sites | not started |
| 4 | Semtex wall-buy on Diner and Bus Depot | not started |
| 5 | Galvaknuckles wall-buy in Bus Depot's Tombstone room | not started |

**Who's Who is next once EC is confirmed.** It is fully mapped in QUEUE §A2 — five stock calls the
mod never makes, all `isdefined`-gated so they fail silently, plus two `mod.ff` assets and the
decision already taken to drop the perk on Buried (its `actor` clientfield set is 32/32).

Also outstanding and unstarted: QUEUE §0B, **every chat command must also be a dvar/console command**
— [[zm-qol-commands-as-dvars]].
