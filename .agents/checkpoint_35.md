# Checkpoint 35 — the wonder-weapon crash, root-caused. v1.69.9.

Written 2026-08-11, after the default-off boot. **Supersedes 34 §3 entirely.**
Keep 34 §1 (Plutonium's loose `scripts\` folder), §2, §4, §5. Keep 33 §1 and §5.

---

## 0. STATE

| item | state |
|---|---|
| **Wonder-weapon crash** | ✅ **root-caused** — the raw `.efx`. Fix shipped v1.69.9, 🚧 not yet booted |
| **Zombie Blood ignoreme hold** (v1.68.1) | 🚧 deployed, never booted |
| **Semtex wall buy angle** (v1.68.1) | 🚧 deployed, never booted |
| **Frametimes** | 🛑 still open, `qol_perf_probe` still never run |

---

## 1. 🛑 THE CAUSE — a raw `.efx` shipped under a STOCK fx name

**The gate could never have worked, and the reason is one line of stock code.**

`maps\mp\zombies\_zm.gsc:1193` (CORE, so every map, every mode):

```gsc
if ( !( isdefined( level.fx_exclude_tesla_head_light ) && level.fx_exclude_tesla_head_light ) )
    level._effect["tesla_head_light"] = loadfx( "maps/zombie/fx_zombie_tesla_neck_spurt" );
```

The wonder-weapon package ships `fx\maps\zombie\fx_zombie_tesla_neck_spurt.efx`. Plutonium loads raw
`.efx` out of `mod.iwd`, so **stock's own `loadfx` picked up our file**. `zmqol_ww` gates GSC the mod
wrote; it cannot gate a stock core script.

### The evidence, five boot logs, perfectly split

| log | that fx | outcome |
|---|---|---|
| `console_zm.log.005` | `Could not load fx "maps/zombie/fx_zombie_tesla_neck_spurt".` | ✅ **reached gameplay** — box opens, `.pack` typed, 5013 lines |
| `.000`, `.006`, `.007`, `.008`, `console_zm.log` | `Loaded fx: maps/zombie/fx_zombie_tesla_neck_spurt` | 🛑 **crash within two log lines**, every time |

🌟 **Stock BO2 does not contain that fx.** The working boot fails to load it and plays fine — 50
`Could not load fx` lines is a normal boot. The mod did not fix a gap; it filled one with a bad file.

### 📝 Suspected, not proven — the format version

The 27 shipped `.efx` are **`iwfx 2`**. The only other raw fx in the workspace, the BO3 library, is
**`iwfx 3`**. T5 is the port's origin, so `iwfx 2` is very likely T5's format and not T6's. No T6 raw
`.efx` exists anywhere to compare against (fastfiles store FxEffectDef as binary and OAT cannot read
it), so this stays **suspected**. It does not matter for the fix — the name collision alone is
disqualifying.

### Three of the 27 collide with stock fx names

`fx_zombie_tesla_neck_spurt` (2 stock refs), `fx_zombie_tesla_shock` (4), `fx_zombie_tesla_bolt_secondary` (1).

---

## 2. THE FIX — v1.69.9, one move

`fx\` → **`disabled_fx\`**, and `fx` dropped from `pack_iwd.ps1`'s `$folders`. Nothing else changed.

- deployed `mod.iwd`: **0 `.efx` entries**, 445 total; source and deployed hash-match
- nothing in the mod's live code referenced those fx — the only hits in `scripts\` are two **comments**
  in `wunderfizz.gsc:214,254`
- the files are kept and tracked in git, so re-adding them is a `git mv`

---

## 3. IF IT STILL CRASHES — the next single change is one line

Delete `include,mod_wonderweapons` from `zone_source\mod.zone` and run `build_ff.bat`. That strips the
~312 `mod.ff` assets the port added and leaves nothing of it in the build.

📝 **One loose end either way:** `fx_zombie_tesla_shock_ground` logged `Loaded fx:` at line 741, during
**zone load**, long before any map script. Its requester was never identified — most likely one of the
6 weapon defs in `mod.iwd\weapons\`. It will now simply fail to load, which is non-fatal.

---

## 4. WHAT THIS COST, and the check that would have caught it

Seven boots. The audit this project mandates for `mod.ff` — *does this asset name already exist in the
game, and who owns it?* — was **never run against the raw `.efx`**, because they are not `mod.ff`
assets and the ownership rule was filed under fastfiles.

🌟 **The rule is about NAMES, not about fastfiles.** Any asset a mod ships under a stock name is
claimed globally, whatever the container. Grep the stock gsc-dump for every asset name a port
introduces, before the first boot.
