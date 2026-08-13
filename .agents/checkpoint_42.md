# Checkpoint 42 — v1.89.7 → v1.90.1. Four fixes shipped, none booted.

Written 2026-08-13. **Supersedes 41 for status.** Keep 41 §1–§4; 40 §2/§4; 39 §2; 38 §2/§4;
37 §1/§4; 36 §1–§2; 35 §7; 34 §1–§2; 33 §1/§5; 32 §1; 31 §1–§2; 30 §3/§5; 29 §2–§3; 28 §1;
24 §2a/§2c; 23 §2; 22 §4–§6; 21 §2–§3; 20 §1–§2; 19; 18 §5; 15 §2.

---

## 0. STATE

🛑 **FOUR VERSIONS ARE DEPLOYED AND NOT ONE HAS BEEN BOOTED.** Everything below is verified
offline only.

| version | what | state |
|---|---|---|
| **v1.89.8** | Electric Cherry fx — the Wunderwaffe port was re-tuning it | 🟡 deployed, **never booted** |
| **v1.89.9** | Vulture stink overlay now yields to Zombie Blood | 🟡 deployed, **never booted** |
| **v1.90.0** | Velocity meter — `.velocity on/off` + the `velocity` dvar | 🟡 deployed, **never booted** |
| **v1.90.1** | `.brutus` / `.panzer` / `.jumpingjacks` + console dvars | 🟡 deployed, **never booted** |
| v1.89.7 backlog | white Peacekeeper, SIG556 GL, SA58 select-fire | 🟡 still never re-verified |
| The whole v1.82–v1.88 backlog | timers, `.hud on/off`, TranZit classic, Origins dial | 🛑 still never booted |
| `qol_perf_probe 1` | | 🛑 still never run |

### 🌟 The cheapest boot plan — these are unrelated subsystems, so one session attributes cleanly

1. **Anywhere** — `.velocity on`, then `velocity 0` at the console. Meter appears/disappears.
2. **TranZit** — Electric Cherry, kill with a reload zap. Should look plain vanilla now: **no
   bright flash at the zombie's eyes.**
3. **TranZit** — stand in a Vulture stink cloud and pick up Zombie Blood. The Zombie Blood
   overlay should now show; the stink overlay should come back when it expires.
4. **Mob** — `.brutus 2`. **Origins** — `.panzer 2`. **Die Rise** — `.jumpingjacks 3`.
5. **Buried** — look for the **HK416** in the box. See §5; it is a one-look answer to a real
   open question.

---

## 1. 🌟 ELECTRIC CHERRY — THE PERK WAS NEVER THE BUG (v1.89.8)

User: *"the electric cherry fx are just a bit too bright and don't look quite vanilla."*

**The ported Wunderwaffe script was writing two STOCK globals**, and it ships raw in `mod.iwd`
so it loads on **every map**:

```
level._effect["tesla_shock_eyes"] = loadfx(...)      _zm_weap_tesla.gsc:26
set_zombie_var( "tesla_head_gib_chance", 75 )        :43   (stock is 50)
```

The chain, all stock:

| | |
|---|---|
| `_zm_spawner.gsc:261` | every zombie gets `.tesla_head_gib_func = ::zombie_tesla_head_gib` |
| `_zm_perk_electric_cherry.gsc:170` | **a cherry kill calls it** |
| `_zm_spawner.gsc:2976` | it rolls `tesla_head_gib_chance`; on the **else** branch it plays `level._effect["tesla_shock_eyes"]` on `J_Eyeball_LE` |

🌟 **In stock BO2 that effect is loaded by exactly ONE script — Origins'
`_zm_weap_staff_lightning.gsc:19`.** On every other map the key is **undefined and the else
branch draws nothing.** Defining it globally *added* a bright eye burst to every Electric
Cherry kill on five maps that vanilla never shows there.

**Fix:** both names are mod-private (`zmqol_tesla_shock_eyes`,
`level.zmqol_tesla_head_gib_chance`) and the gun routes through `zmqol_tesla_head_gib()`, a
private copy of stock's function. The Wunderwaffe keeps its eye fx and its 75% rate; Electric
Cherry gets stock's undefined key and stock's 50 back. Applied to **both** copies of
`_zm_weap_tesla.gsc`. Now **ERROR_CATALOGUE §12**.

### 🛑 The shape to remember: a wrong OWNER, not a wrong value

The port was faithful to its source. Its source just assumed it was the only user of those
globals. **A ported feature that writes a stock `level._effect[...]` key, a stock `zombie_vars`
entry or a stock `level.*` pointer re-tunes every stock system that reads it, on every map the
script loads on, with no error and no log line.** And `isdefined`-gated stock code is the trap:
stock deliberately leaves keys undefined so a branch does nothing. **Absence can be the vanilla
behaviour.**

### 📝 Three theories measured and DISPROVEN on the way — do not re-tread

| theory | measurement |
|---|---|
| the arc materials / techset differ | `gfx_fxt_env_electric_arc*`, `effect_8e1qf0qq` in the built `mod.ff` are **byte-identical** to `common_zm`'s |
| the arc textures are wrong | they ARE re-encodes (DXT5 over stock DXT1 / uncompressed) but decode to the **same pixels** — mean luminance 8.8/6.4/7.6 vs 8.8/6.4/7.5 |
| a raw `.efx` shadows the cherry zap | no; v1.73.0 already removed those three |

**Still true and still worth fixing one day (NOT the cause of anything reported):** the
wonder-weapons import staged **29 stock textures that every zombies map already loads** into
`zone_assets\images\`, and the asset search path beats every `--load`, so `mod.ff` ships lossy
DXT5 re-encodes of them globally — including the flare/glow family, which stock ships
**uncompressed**. All 29 came from `bb44073`. See task #1.

---

## 2. VULTURE STINK vs ZOMBIE BLOOD (v1.89.9)

The visionset manager's `"overlay"` type is **winner-take-all per player** —
`get_first_active_name()` (`_visionset_mgr.gsc:361`) returns the highest-priority active entry
and only that slot is sent. Stink is **120**, Zombie Blood is **16**, so Zombie Blood's overlay
was never sent.

**Both numbers are stock.** Vulture Aid is Buried-only and Zombie Blood is Origins-only, so
**vanilla never pairs them** — the mod created the pairing by putting both on every map.
Resolving it is not re-tuning a ported perk.

Fix: the stink overlay stands down while Zombie Blood is active, re-asserting within a tick in
both directions. **Deliberately NOT done:** raising Zombie Blood's priority, which would also
lift it over the afterlife filter, the avogadro electrocution and both trap overlays — trading
a cosmetic bug for a damage-feedback one.

---

## 3. THE TWO NEW COMMAND SETS (v1.90.0, v1.90.1)

### The velocity meter

**🛑 It is NOT in `H:\Claude\T6-B2OP-PATCH`,** which is where the user pointed. `b2op.gsc` has
no meter; `README.md:922` only documents the stat slot that toggles **B2FR's** one, and B2FR is
a separate repo not in this workspace. Written, not ported. B2OP did supply the HUD shape — its
coordinates readout (`b2op.gsc:5279-5301`) drives a numeric hudelem with `setvalue()`.

🌟 **`getvelocity()` on a PLAYER is verified, not assumed** — worth checking, because this
engine already hides `getnormalizedmovement()`. Confirmed in BO2-Reimagined
(`_zm_reimagined.gsc:3783`) and, more importantly, in **stock MP** (`_spawning.gsc:178`,
`_straferun.gsc:663`) — Treyarch's own code reading a player.

### The boss spawns

🛑 **The root script may not name a boss function.** `_zm_ai_brutus`, `_zm_ai_mechz` and
`_zm_ai_leaper` are map-specific; a qualified reference resolves at **load** time and would
crash every other map. `quality_of_life.gsc` holds parsing/clamping/dispatch only, through
`level.zmqol_boss_spawn_func`, which each map's script installs in `init()`. **Verified in the
deployed `mod.iwd`: the root file contains zero occurrences of any `zmqol_spawn_<boss>` name.**

🌟 **And the gameplay GSC is NOT in the map fastfile.** `zm_prison.ff` carries 15 script assets
and they are all aitype/character/xmodelalias. All three bosses live in the map's **PATCH**
fastfile:

```
maps/mp/zombies/_zm_ai_brutus.gsc   zm_prison_patch.ff
maps/mp/zombies/_zm_ai_mechz.gsc    zm_tomb_patch.ff
maps/mp/zombies/_zm_ai_leaper.gsc   zm_highrise_patch.ff
```

Each command uses that map's own stock spawner. Brutus needed his **ceiling** raised
(`brutus_max_count = 1`) rather than the check bypassed, or `level.brutus_count` desyncs. The
Panzer line is Treyarch's own dev spawner with `+=` instead of `=`. The leaper has **no notify
hook** — `leaper_round_spawning()` is a whole round that never returns — so its per-spawn step
is replicated with stock's three helpers, deliberately not touching the round's bookkeeping.

---

## 4. 🛑 BRUTUS vs THE WUNDERWAFFE — NARROWED TO ONE QUESTION, NOT FIXED

**Four causes eliminated by measurement.** Do not re-tread:

1. Targeting — a previous probe reported him **already-in-list** on the first arc.
2. The magic-bullet-shield skip — `grep -rn magic_bullet_shield` over the **entire** Mob dump
   returns **zero hits**. Brutus never used it; the relaxation in the code was never needed.
3. The death-anim gate — his `.asd` has no `zm_death_tesla_t5`, so `b_no_death_anim = true` and
   the damage-first branch runs.
4. `setcandamage(0)` — the Panzer does it, Brutus does not.

**So the arc reaches `DoDamage( self.health + 666, ... )` and he survives it.**

The remaining suspect: `self.actor_damage_func = ::brutus_damage_override`
(`_zm_ai_brutus.gsc:338`), consumed at `_zm.gsc:4435`, returning `damage * 0.1`
(`brutus_damage_percent`, `:80`). 10% of health+666 < health → survives every arc.

🛑 **But `_zm.gsc:4429` short-circuits on `meansofdeath == ""`, and the mod's call passes only
THREE arguments.** If a 3-arg `DoDamage` yields an empty meansofdeath the override never runs
and the theory is wrong. Stock's Electric Cherry passes it explicitly:
`dodamage( 1000, self.origin, self, self, "none" )`.

**DO NOT fix this by multiplying the damage** — that presumes the scaler is running, and if it
is not, nothing changes while looking like it should have worked. Task #3 carries the three-line
probe that separates the outcomes.

---

## 5. TWO OPEN QUESTIONS THE USER'S NEXT BOOT CAN ANSWER FOR FREE

**The HK416, in Buried's box.** 85 weapon files sit directly in `weapons\` (not `weapons\zm\`)
and **83 use stock zombies weapon names**. They arrived in the **initial commit** — inherited,
not from any recent weapon work. BO2-Reimagined puts all 208 of its defs in `weapons\zm\` and
**zero** at the top level, which suggests the bare path is dead — but `hk416_zm`, the one
non-stock name among them, **is** wired up (precached, `include_weapon`'d on Buried). So: **if
the HK416 appears, that path loads and those 83 files are overriding stock weapon definitions on
every map.** If it never appears, they are inert.

**`msmc_zm` has no def file anywhere** — not in `weapons\zm\`, not in `weapons\` — despite the
MSMC being named in the set of nine MP weapons. Settle before claiming that set is complete.

📝 **The nine MP weapons are clean ADDITIONS** (user asked): all 30 defs in `weapons\zm\` were
checked against every weapon asset in eight zombies fastfiles (237 names) — **zero collisions**.
The FAL-OSW is `sa58_zm`; there is no stock `sa58_zm` in zombies to replace.

---

## 6. NEXT — in this order

1. 🛑 **BOOT.** §0's five-step plan. Four unbooted versions is the largest unverified stack this
   project has carried.
2. **Task #3** — ship the Brutus probe on that same boot.
3. **Task #5 — the XPR-50.** 🌟 The old *"exists in no workspace mod → out"* verdict is
   **OBSOLETE**: it predates v1.88.0 linking the MP fastfiles. Measured now — the XPR-50's
   assets are in fastfiles this mod **already links**: 60 in `common_mp.ff` (view/world xmodels,
   scope, mag, materials, images), 16 in `patch_mp.ff`, 46 in `common_patch_mp.ff`. Same shape
   as the nine that shipped; no new donor needed.
4. **Task #4 — the Titus-6.** User authorised `SynarxisReimagined` as the donor, 2026-08-13
   (*"yeah use SynarxisReimagined, just get it working"*).
5. **Task #1 — custom perk-icon streaming.** Measured blocker: `mod.ff` bakes **pixel data** for
   208 images, and `specialty_tombstone_zombies`, `specialty_vulture_zombies` and
   `specialty_vulture_zombies_glow` are three of them, so a user's pack can never win. 862 other
   images are header-only. Three things must be settled by measurement before designing:
   Plutonium's lookup order between `storage\t6\images\<hash>.iwi`, `mod.iwd\images\` and the
   fastfile; what the hash is derived from; and the header trap (`mod.ff` owns the dimensions —
   a 64×64 pack read through a 32×32 header renders garbage, the measured purple/green m1911).
6. Then: the ESC-menu / main-menu options tab the user has said is next after these.

---

## 7. WORKFLOW NOTES FROM THIS SESSION

- **A background agent committed into this repo mid-session** (v1.89.9) and bumped `mod.json`.
  If more than one thing is in flight, sequence the version bump — it is a shared file.
- `build_ff.bat` must be run as `cmd /c ".\build_ff.bat"` from this harness; a bare
  `build_ff.bat` is not found.
- A relink with no zone change is deterministic and provable: **`Unlinker --list` before and
  after was identical, 4,837 both ways.** Run that A/B every time `mod.ff` is rebuilt.
- `Unlinker --include-assets fx` dumps **nothing** — fx cannot be byte-diffed with OAT. Plan
  around it rather than rediscovering it.
