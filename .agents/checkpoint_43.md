# Checkpoint 43 — v1.90.2 shipped; the XPR-50 and the silent guns fully researched, not built.

Written 2026-08-13. **Supersedes 42 for status.** Keep 42 §1 (the stock-globals lesson), §3
(boss-spawn architecture), §5 (the two free questions); 41 §1–§4; 40 §2/§4; 39 §2; 38 §2/§4;
37 §1/§4; 36 §1–§2; 35 §7; 34 §1–§2; 33 §1/§5; 32 §1; 31 §1–§2; 30 §3/§5; 29 §2–§3; 28 §1;
24 §2a/§2c; 23 §2; 22 §4–§6; 21 §2–§3; 20 §1–§2; 19; 18 §5; 15 §2.

---

## 0. STATE

🛑 **FIVE VERSIONS ARE DEPLOYED AND NOT ONE HAS BEEN BOOTED FOR VERIFICATION.**

| version | what | state |
|---|---|---|
| v1.89.8 | Electric Cherry fx — the Wunderwaffe port was writing stock globals | 🟡 **never booted** |
| v1.89.9 | Vulture stink overlay yields to Zombie Blood | 🟡 **never booted** |
| v1.90.0 | Velocity meter — `.velocity on/off` + `velocity` dvar | 🟡 **never booted** |
| v1.90.1 | `.brutus` / `.panzer` / `.jumpingjacks` + `spawn_*` dvars | 🟡 **never booted** |
| **v1.90.2** | **Origins generator capture ring — root-caused and fixed** | 🟡 **never booted** |

### Open work — the harness task list is the authority

| # | item | state |
|---|---|---|
| 1 | Custom perk-icon `.iwi` streaming | blocker measured, not designed |
| 3 | Wunderwaffe vs Brutus | narrowed to ONE question; probe written, not shipped |
| 4 | Titus-6 in the box | authorised (`SynarxisReimagined`), not started |
| 5 | **XPR-50** | **fully researched, every input verified, NOT BUILT** |
| 7 | Black solo loading screens | cause NOT found; four things ruled out |
| 9 | **Missing weapon foley/reload sounds** | **root-caused, source found, NOT BUILT** |

📝 The user asked for #5 and #9 to be done **in one pass** — they share the sound pipeline
entirely, and #9's dump supplies #5's audio.

---

## 1. ✅ THE ORIGINS CAPTURE RING — FIXED (v1.90.2)

🌟 **The probe had already answered it, and 299 of its lines were sitting in the logs unread.**
`zmqol_probe_capture_zones()` had been running for several boots:

```
capture probe: 6 zone(s) registered
zone generator_church progress 5        obj=0 contested=1 inzone=1
zone generator_church progress 13.3333  obj=0 contested=1 inzone=1   ... ramp to 100
```

Progress climbs, zone contested, player detected inside, objective index real. The probe's own
header states the conclusion: **the server did everything right; the failure is client-side.**

**The race.** The ring is the OBJECTIVE system (`zm_tomb_capture_zones.gsc:1506`
`objective_setprogress`; the meter is LUI's `TCZWaypoint`, inheriting `ObjectiveWaypoint`,
selected by objective NAME). The four objectives are created **once, at map init**, by
`declare_objectives()` (`:80`). **`objective_add` reaches only the clients connected at that
instant** — anyone who finishes connecting after never receives it, so every later
`objective_setprogress` updates an objective their client does not have.

🌟 That is exactly the one logged difference between two back-to-back Origins games recorded
weeks earlier in `zmqol_intro_hold_time` and never explained:

| | |
|---|---|
| `solo status: expected=1 connected=0` | **no ring** |
| `solo status: expected=1 connected=1` | **ring** |

A connect race explains an intermittent failure. The startup-hold theory tested before could
not — identical 1.6s hold, opposite outcomes — and was correctly falsified then.

**Fix:** re-issue `declare_objectives()` after players are connected — six passes over the
opening six seconds (covering the host, who is already connected before any mod script runs and
so never fires a `connected` notify), plus once per player connect for co-op. `objective_add`
on an existing index re-defines it and stock updates progress continuously, so a redundant
re-declare cannot lose progress. Origins-only file; the probe is deliberately **left in** as
the verification instrument.

🛑 **A stale comment found and NOT rewritten blind.** `zm_tomb.gsc:70-110` claims the
capture-zone system was "ported verbatim to `scripts\zm\replaced\zm_tomb_capture_zones.gsc`".
**That file does not exist** and no capture-zone function is `replaceFunc`'d. Stock's script
runs unmodified — which is what let this be diagnosed as pure stock behaviour.

---

## 2. 🌟 THE XPR-50 IS NAMED `as50` — AND THAT IS WHY IT KEPT "NOT EXISTING"

`Unlinker --list` over **all 191 fastfiles**: zero weapons named `xpr50`. But `common_mp.ff`'s
172 weapon defs contain `as50_mp`, and dumping it settles it:

```
displayName  WEAPON_AS50
gunModel     t6_wpn_sniper_xpr50_view
             (+ _world, _scope_view, _scope_world)
```

**BO2 shipped the gun under its development name (Barrett AS50) in the DEF while the ART uses
the release name (XPR-50).** Every earlier search matched on the art name and concluded it did
not exist — including the verdict recorded in QUEUE.md:2408 and repeated in checkpoints 38 and
40. **That verdict is now retracted for the second time and for a different reason than the
first.** Its art is already in fastfiles this mod links: 60 in `common_mp.ff`, 16 in
`patch_mp.ff`, 46 in `common_patch_mp.ff`.

**A ZM port is not a rename** — the shipped `mk48_zm` differs from `mk48_mp` in damage, ranges,
aim assist, move speed and reload timing. So the conversion was **derived from Treyarch**, not
authored: task #5 carries both tables, measured from stock `dsr50_mp` → `dsr50_zm` →
`dsr50_upgraded_zm`.

**Both known traps checked, both clear:** eleven `au_as50_*` attachmentunique records exist in
the linked fastfiles (the v1.89.5 PaP-crash class — they must be **declared**, never dropped in
the raw folder), and the audio exists (see §3).

📝 Parsing note for any weapon-def work:
`tr '\\' '\n' < <def> | awk 'NR==1{next} NR%2==0{k=$0; next} {print k"\t"$0}'`

---

## 3. 🌟 WHY THE GUNS RELOAD IN SILENCE — AND WHY THE SOURCE IS STOCK, NOT REIMAGINED

User: *"some of the guns dont have reload sound fx like the swat."*

**Reload sounds are FOLEY aliases with the `fly_` prefix**, fired from notetracks in the reload
animation. They are **not** `wpn_*_reload*` — no bank anywhere uses that naming. **Do not retry
that.** The mod's rebuilt bank has **zero** `fly_` aliases for every ported weapon, so every
reload notetrack resolves to nothing — and a missing alias is **silent, never an error**, which
is why this passed every build check.

**Source: the game's own MP bank.**
`Unlinker --include-assets soundbank --search-path "<BO2>\sound" -o snd <BO2>\zone\all\common_mp.ff`
→ `snd/soundbank/mpl_common.all.aliases.csv`, **3,833 rows**.

| weapon | stock `fly_` rows |
|---|---|
| insas 5 · sa58 6 · mk48 10 · qbb95 7 | |
| mp7 4 · vector 6 · crossbow 11 · **as50 7** | |
| **peacekeeper 0** | DLC — look in `common_patch_mp.ff`, same as its materials |

🌟 **A concern I raised and then disproved against the authoritative source.** Reimagined's
`fly_insas_mag_out` points at the **Kiparis** payload, which looked like a substitute — the
lookalike the standing rules forbid. **It is not.** The stock bank maps it identically:
Treyarch reused the Kiparis foley for the SWAT-556. Row counts match stock for every weapon,
confirming Reimagined copied stock verbatim. **Using stock means importing from no other mod at
all.**

**The gap is wider than reload.** The mod imported only the **fire** aliases — 8 for insas
where stock has 49. Also missing: `_1straise`, `_raise`, `_pickup`, `_dryfire`, `_flux_*_pap`,
`_silencer_*`, `_fire_plr_lh/_rh`. Raise, pickup and dryfire are silent too.

🛑 **The gate when this is built:** a CSV row whose payload is missing is **still silent**.
Dump the REBUILT bank and confirm every new alias resolves to real audio; the build currently
prints 34 sound warnings — diff that list before and after.

---

## 4. 🛑 THE BLACK SOLO LOADING SCREENS — CAUSE NOT FOUND

Four things ruled out, all measured. **No fix shipped, and none should be until the scope
question is answered.**

1. 🌟 **This session did not change `mod.ff` at all.** `--list` of the current fastfile vs the
   v1.89.7 one (`git show 5c5b578:mod.ff`, extracted into a folder where it is still **named**
   `mod.ff`) is **identical** apart from the Unlinker's own log lines. Both relinks cleared.
2. The loadscreen material set is unchanged — 10 in both builds, of which only **two** are
   loadscreens: `loadscreen_zm_transit_zstandard_diner`, `loadscreen_zm_prison_zclassic_prison`.
3. Both loadscreen images `mod.ff` owns carry **real pixel data**, so this is not the
   header-without-pixels black.
4. All 8 loose `loadscreen_*.iwi` are structurally valid (`IWi` magic + version `0x1b`).
5. The newest `console_zm.log` reports **no** loadscreen failure at all.

**Next, in order:** (a) **scope** — is it every map or only those two? Those are the only
loadscreens `mod.ff` owns and it loads ahead of every map, so if the black screens are exactly
those two the mod's copies are the cause. (b) 🛑 **the user's own image pack** —
`storage\t6\images\` holds **1,908** hash-named `.iwi`; a streamed texture read through a
mismatched header renders black/garbage. Move the folder aside and boot once. (c) a clean A/B,
same map and gametype, with and without the mod.

📝 Separately true: the comment at `privategamelobby_project.lua:864-891` claims "all 30
materials are built into `mod.ff`". **Only 10 are.** Every custom survival location except
Diner therefore has no `menu_`/`loadscreen_` material. Overclaiming comment; real missing-art
bug for those locations; not this bug.

---

## 5. BRUTUS — STILL ONE QUESTION, STILL NO FIX

Four causes eliminated (targeting; the magic-bullet-shield skip — `magic_bullet_shield` has
**zero** hits in the entire Mob dump; the death-anim gate; `setcandamage(0)`). The arc reaches
`DoDamage( self.health + 666, ... )` and he survives.

Remaining suspect: `actor_damage_func = ::brutus_damage_override` returning `damage * 0.1`.
**But `_zm.gsc:4429` short-circuits on `meansofdeath == ""` and the mod's call passes only
three arguments.** If a 3-arg `DoDamage` yields an empty meansofdeath the override never runs
and the theory is wrong. 🛑 **Do not "fix" this by multiplying the damage.** Task #3 carries the
three-line probe that separates the outcomes.

---

## 6. NEXT

1. 🛑 **BOOT.** Five unbooted versions. Checkpoint 42 §0 has the five-step plan; add Origins
   with a generator capture for §1, and the loading-screen scope question from §4.
2. #5 + #9 together — the XPR-50 and the weapon foley, one sound pass.
3. #3 Brutus probe · #4 Titus-6 · #1 perk-icon streaming · #7 loading screens.
4. Then the ESC-menu / main-menu options tab.
