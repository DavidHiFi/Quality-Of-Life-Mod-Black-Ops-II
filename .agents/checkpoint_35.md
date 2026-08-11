# Checkpoint 35 — the wonder-weapon crash, root-caused. v1.69.9.

Written 2026-08-11, after the default-off boot. **Supersedes 34 §3 entirely.**
Keep 34 §1 (Plutonium's loose `scripts\` folder), §2, §4, §5. Keep 33 §1 and §5.

---

## 0. STATE

| item | state |
|---|---|
| **Wonder-weapon crash** | ✅ **FIXED AND CONFIRMED IN GAME** on v1.69.9 — the user booted, no crash |
| **Zombie Blood ignoreme hold** (v1.68.1) | 🚧 deployed, never booted |
| **Semtex wall buy position** (v1.69.10) | 🚧 deployed, not yet booted — 3rd attempt, but the 1st measured. See §5 |
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

---

## 5. THE DINER SEMTEX — two wrong guesses, then a measurement

| version | what shipped | what the user saw |
|---|---|---|
| v1.68.0 | x -5176, yaw **0** | *"wrong angle but seem to be in the right position"* |
| v1.68.1 | x -5176, yaw **90** | *"literally inside the wall"* |
| v1.69.10 | x **-5172**, yaw 90 | 🚧 not yet booted |

**Both earlier attempts changed the yaw and never questioned the position.** v1.68.1's reasoning was
explicitly *"measured from a wall-buy already on a diner wall"* — but what it measured was the MP5K's
yaw, and then **assumed** which way that wall ran. The assumption was the error.

### 🌟 The two measurements that settled it

**1. The model's own bounds say the yaw.** `semtex_bag` local X -6.04..6.04 (width), local Z
-8.61..11.32 (height), local Y **-5.87..0.22** — the one-sided axis. So its flat mounting face is
local +Y ≈ 0 and the body hangs toward local -Y. For a wall whose normal is world +X, local -Y must
point +X: **yaw 90**. It was already right.

**2. The doorway model says the wall plane.** Entity `auto2279`,
`p_rus_door_white_plain_right`, at `(-5178,-7842.1,-64)` yaw 270. Bounds: local X 0..60 (panel,
hinged at 0), local Z 0..102 (height), local Y **-3.05..6.01** — a 9.06-unit span, the frame, i.e.
the wall thickness. At yaw 270 local +Y → world +X, so the wall occupies **x -5181.05 .. -5171.99**
and its room-side face is **x = -5172**.

x -5176 was **4 units inside that face**, and the bag stands only 5.87 units off its own back plane,
so ~1.9 units showed. That is exactly the sliver in the screenshot.

### 📝 The axis convention, worth keeping — OAT's GLB export is `glTF X,Y,Z = CoD X, Z, Y`

Confirmed off two models whose real shape is known: `zombie_vending_jugg` is 99.7 long on glTF Y (a
perk machine is ~100 tall → glTF Y is CoD Z, up), and `t6_wpn_smg_mp5_world` is 31.9 long on glTF X
(the barrel → glTF X is CoD X, forward). **Any placement question is now measurable**: dump the
xmodel, read the accessor min/max, map through that.

### 📝 Why this could not be tuned live

`zmqol_semtex_diner_x` is read on both sides to build the wallbuy's clientfield NAME
(`_zm_weapons.csc:218`). Changing it mid-game desynchronises the two sides. It is a restart-only
dvar, which is exactly why measuring beat nudging here.

### ⚠️ Residual risk

The 9.06-unit local-Y span is read as frame-and-wall-thickness. If part of it is really a door knob
protruding into the room, the true face is nearer -5178 and the bag will now float ~4-6 units proud.
The observed symptom rules the face out at -5178 (at -5176 the bag would have stood 2 units proud and
been plainly visible), so -5172 is the consistent reading — but a small float is the failure mode to
look for, not a re-bury.

---

## 6. THE SEMTEX, PART 2 — the yaw was always the bug, and my v1.69.10 note was wrong

**Correction to §5.** §5 said the position was 4 units inside the wall and the yaw was already right.
**Both halves were wrong**, and one bad assumption caused it: the glTF→CoD axis mapping was read
without its **handedness sign flip**.

### The mapping, now derived rather than pattern-matched

CoD X → glTF X and CoD Z → glTF Y (both measured). Both spaces are right-handed, so fixing two axes
**forces the third's sign**: **CoD Y → −glTF Z.** §5 dropped that minus.

Independent confirmations: `t6_wpn_smg_mp5_world`'s own tag nodes put `tag_flash` (muzzle) at
glTF x **+8.62** and `tag_stock_off` at **−13.70**, so glTF +X is the barrel = CoD forward; and
`zombie_vending_jugg` is 99.7 long on glTF Y against a ~100-tall machine.

### What that changes

| | §5 (wrong) | corrected |
|---|---|---|
| `semtex_bag` one-sided axis | CoD Y −5.87..0.22, face at **+Y** | CoD Y **−0.22..5.87**, face at **−Y**, body toward **+Y** |
| required yaw | 90 | **270** |
| wall room-side face | x −5172 | x **−5175** |

At yaw 90 local +Y points world **−X — straight into the wall.** The bag has been **completely inside
the brush since v1.68.1**, which is why only the fx ever rendered. At yaw 0 (v1.68.0) the body pointed
world +Y, along the wall — the user's *"wrong angle but right position"*. **Every report is explained
by the same model**, which is the check §5 never had.

### 🌟 Cross-checked against stock

Town's semtex — the only other one in the game — is at `(1083.7,−1579.5,12)` yaw ~0, so its body
points world **+Y**, and the pathnodes within 160 units of it are predominantly **+Y**. Same rule,
independent map, agrees.

📝 Method note: pathnode positions are a cheap, reliable way to find which side of a prop is walkable
when there is no brush data. `awk` over the `mapents` dump, filter `node_pathnode`, look at the sign.

### v1.69.11 ships x −5175, yaw 270

Both sides identical; verified in the deployed `mod.iwd` and in the loose `scripts\` shadow.

---

## 7. 🌟 A WALLBUY'S MODEL IS HIDDEN UNTIL THE FIRST PURCHASE — stock, not a bug

Worth keeping, because it will otherwise be mistaken for a broken port again.

`_zm_weapons::init_spawnable_weapon_upgrade()` (the STATIC wallbuy path, :839) **registers** the
world clientfield and never sets it. The client's `wallbuy_player_connect()`
(`_zm_weapons.csc:268-270`) spawns the model and immediately calls **`target_model hide()`**. The only
thing that sets the field to 1 is **`show_all_weapon_buys()`** (`:2186`), reached from
`weapon_spawn_think()` at `:2066`/`:2139` — **on purchase**.

So before the first buy a wallbuy is *supposed* to be nothing but its glowing chalk fx. For this one
that fx is `sticky_grenade_zm_fx` = `maps/zombie/fx_zmb_wall_buy_semtex`, a real semtex-specific
effect (`_zm.gsc:1227`, `_zm.csc:323`) — and it is what the user has been seeing and describing as
"the semtex". It was correct all along.

📝 `add_dynamic_wallbuy()` (:993) is a different path that *does* set the field immediately and keeps
a server-side `wallmodel`. Static wallbuys keep no server model at all — `init_spawnable_weapon_upgrade`
uses a `tempmodel` only to measure bounds and then deletes it.
