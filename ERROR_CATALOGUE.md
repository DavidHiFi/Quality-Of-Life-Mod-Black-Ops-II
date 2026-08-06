# ERROR_CATALOGUE.md — every failure class this project has actually hit

Written 2026-08-06 at the user's instruction: *"make sure to understand any of the errors I've ever
gotten for BO2 on Plutonium T6 client and to check if I would ever get any of those errors with what
you give me."*

**Walk this list before every build.** Each entry is an error the user has really seen, with the
mechanism and the specific pre-flight check that catches it offline. Nothing here is hypothetical.

Confidence is marked per claim: **[measured]** = read out of a dump, log, or game file;
**[inferred]** = consistent with all evidence but not directly proven. Never promote an inferred
claim to a measured one.

---

## 1. `Server Disconnected — EXE_CLIENT_FIELD_MISMATCH` 🛑 FATAL AT LOAD, MOST FREQUENT

The server and client must register **the same clientfields, with the same bit widths**. Any
divergence drops the connection before the map starts. The log names the field and the direction:

```
*****MISMATCHED CLIENTFIELDS*****
Clientfield <name> in set [<set>] is not registered on the client
```

**Direction tells you which side to edit** — "not registered on the client" is a `.csc` fix, "not
registered on the server" is a `.gsc` fix. A bit-width disagreement prints instead as
`[CLIENT: 4 SERVER: 5]`.

### Known sub-causes, all of which have happened here

| # | cause | example |
|---|---|---|
| 1a | **A feature added server-side with no client half.** | Fire Sale, v1.54.0 → v1.55.3. `powerup_fire_sale` |
| 1b | **List-driven registration.** The field is never named — it is a side effect of `level.zombie_include_powerups`, which is **per-VM**. Adding to the server's list alone registers on one side only. | same |
| 1c | **A map list copied into three places drifts.** v1.49.0 put Vulture's map list in the enable function and its client twin but missed the visionset registration → one boot crash became a different boot crash. | `overlay_lerp [CLIENT: 4 SERVER: 5]` |
| 1d | **Registering MORE on the client than the server.** The wallbuy re-tag keyed off the map instead of the location and tagged Diner *and* Tunnel. | `m16_zm_(-11839, -1695.1, 287)` in `[world]` "not registered on the server" |
| 1e | **A visionset count difference.** `visionset_slot`'s width is derived from how many visionsets are registered (`getminbitcountfornum(size-1)`), so one extra visionset on one side silently widens the field. | `visionset_slot [CLIENT: 2 SERVER: 1]` |
| 1f | **Server-only gating of a stock field.** Survival locations spawn no perk machines, so `_zm_perks::init()` bailed and never registered two fields the client registers unconditionally. | `electric_cherry_reload_fx` |

### ✅ Pre-flight check

- For **every** clientfield the mod registers server-side, confirm a matching client registration —
  either in `scripts\zm\zm_expanded.csc` or in a **stock** `.csc` (check the dump; most of the
  mod's server registrations are deliberate mirrors of unconditional stock client ones).
- Confirm **identical set, name, version and bit width** on both sides.
- Any registration behind an `if` must have the **identical condition** on both sides. The three
  Vulture guards (`zmqol_vulture_has_actor_field`, `..._has_disease_meter`,
  `..._has_scriptmover_field`) exist in **two files** — server `maps\mp\zombies\_zm_perk_vulture.gsc`
  and client `scripts\zm\zm_expanded.csc`. **Six functions must agree.**
- If the feature is **list-driven** (powerups, weapons, equipment, visionsets), the *list* is the
  thing that must match, not a registration call.

---

## 2. `Trying to assign N bits for netfield <x> but Client Field Set <SET> is out of space` 🛑 FATAL

### 🌟 Every clientfield set is 32 bits wide

**[measured]** for `scriptmover` and `actor`, two independent confirmations from
`Black Ops 2 Grand Resources\T6-Data-Archive-main\ZM\Clientfields\` (per-map runtime dumps of every
registered field and its width — total them with `awk '$1=="<set>"{s+=$4}'`):

| set | Origins classic stock | what happened |
|---|---|---|
| `scriptmover` | **32 / 32** — zero free | +4 for `vulture_perk_scriptmover` failed instantly |
| `actor` | **31 / 32** — one free | +2 for `vulture_perk_actor` filled it, so stock's 1-bit `zone_capture_zombie` errored |

**[inferred]** `toplayer` is 64. Max stock observed is 63 (Buried classic). Mob classic stock is
only **50**, so the Mob overflow was caused by the mod's own toplayer additions on top — not by
stock being near a 64 ceiling. Do not quote 64 as measured.

### 📝 The field named in the error is whichever asks LAST

It is often a *stock* field, not yours. Read it as "someone before me used the space", never "this
field is broken". Time has been lost twice assuming otherwise.

### 📝 Treyarch hit this wall too

Origins is the only map in the game that sets `level._no_equipment_activated_clientfield`
(`zm_tomb.gsc:100`), suppressing the 4-bit `equipment_activated` every other zombies map registers.
Without that cut Origins would be at 36/32 on its own.

### ✅ Pre-flight check

Before adding **any** clientfield, total that set for the **fullest map it will run on** using the
dumps above, and confirm `stock + mod additions + new field <= 32`. Zero free bits means no
narrower encoding rescues it.

---

## 3. `Unresolved external` — crashes **every other map** 🛑 FATAL

A qualified reference like `maps\mp\zm_tomb_dig::swap_weapon` resolves at **script load time**, not
when the line runs. A map-specific reference sitting in a **root** script (`scripts\zm\*.gsc`, which
loads on every map) throws on every other map. **A runtime `if (level.script == "...")` guard does
NOT prevent this.**

### ✅ Pre-flight check

Map-specific `::` references belong only in `scripts\zm\<map>\<map>.gsc`. Globally safe from root:
`maps\mp\_utility`, `common_scripts\utility`, `maps\mp\zombies\_zm*`, `maps\mp\gametypes_zm\_*`.

---

## 4. `script mover animtrees registered in different order` 🛑 FATAL, KILLS EVERY MAP

```
server <qolwf_perk_random> client <zombie_bus>     (TranZit)
server <qolwf_perk_random> client <zm_tomb_tank>   (Origins)
```

`scriptmodelsuseanimtree()` appends to an **ordered list**, and server and client must match
**index for index**. Registering on one side alone puts your tree at index 0 on that side only.

### ✅ Pre-flight check

Never add a `scriptmodelsuseanimtree()` without the matching call on the other side, at the same
position. In `zm_expanded.csc` it must stay the **first** statement in `main()`.

---

## 5. Missing assets — usually silent, sometimes fatal

| symptom | cause |
|---|---|
| `Could not load material "x"` / `fx` | the asset is not in `mod.ff`; declare it in `zone_source\mod_locations.zone` and run `build_ff.bat` |
| an image draws **black** | **[measured]** a fastfile holds only the image *header*; the pixels come from a loose `.iwi` that must also be in `images\` inside `mod.iwd` |
| `Could not load rawfile "…"` | **`mod.iwd` serves scripts but NOT rawfiles** (`.txt`/`.atr`/`.asd`) — those must be linked into `mod.ff` |
| a sound plays nothing, **no error at all** | the alias does not exist. Always confirm an alias exists before using it |
| an xmodel renders nothing while every probe looks healthy | only TranZit ships `so_zsurvival_*.ff` |
| `precachemodel` on a model the level lacks | **fatal at load.** Including a powerup whose model is absent from that map's `.ff` will kill it — this is why Fire Sale needed `zombie_firesale` shipped in `mod.ff` |

### ✅ Pre-flight check

`Unlinker.exe --list <map>.ff` tells you whether a map already has an asset. If not, it must ship in
`mod.ff` — **and then `build_ff.bat` is required, not just `build.bat`.**

---

## 6. `inflate of stream N failed: invalid block type` (OAT, not in-game)

**A T6 fastfile's filename must match its internal zone name.** Copying `mod.ff` to `mod_base.ff`
makes it unloadable — same bytes, different name. That is why the donor lives in its own folder
still called `mod.ff`.

---

## 7. `EXE_SERVERCOMMANDOVERFLOW`

`settext()` every tick floods reliable commands. Use `settimer` / `setvalue` for changing numeric
HUD values instead of re-`settext`-ing.

---

## 8. Silent failures — no error line at all 🛑 THE DANGEROUS CLASS

These produce **no log output**, so a clean log proves nothing.

| symptom | cause |
|---|---|
| a feature simply does not happen | **Plutonium swallows GSC runtime errors.** Threads die silently without `developer 1` / `developer_script 1` |
| a HUD element does not draw | the client hudelem allowance is exhausted. This mod holds ~12 permanently, per player |
| a `replaceFunc` never takes | four known modes: unqualified same-file call; behaviour reached via a `level.*` pointer; a `::fn` bound before your replace; registered in `init()` when the target is threaded at map-init |
| instant death / death barrier on spawn | too **few** zones enabled — respawn points stay locked |
| zombies spawn map-wide and never arrive | too **many** zones enabled |
| stock solo behaviour never fires | **Plutonium runs every game as an online private match**, so `sessionmodeisonlinegame()` / `sessionmodeisprivate()` are both always true |
| the build "didn't take" | `build.bat` prints `[ok]` and still may not deploy if Plutonium holds the files open. **Always verify deployed size + timestamp** |

---

## 9. Half-implementations — the failure class with no error message

The user's explicit standard: **perfectly, or not at all.** Precedents to avoid repeating:

- **The Wunderfizz.** Shipped as a separate lookalike machine with wrong visuals and sound, when
  Origins' real base-game machine (`_zm_perk_random`) was available to port. Use the real asset.
- **Bulk-copying Reimagined's mapents** silently turned Die Rise's Olympia wallbuy into a Ballista.
  **Adapt, never bulk-copy** — it carries its own balance changes.
- **Lifting a stock restriction creates cases stock never had to handle.** Removing
  `has_weapon_or_upgrade` from the magic box created the PaP-downgrade bug that could not previously
  exist.

---

## 10. 🛑 A RAW-LOADED ASSET CLASS LEFT OUT OF `mod.iwd` — HARD CRASH ON MAP LOAD

**v1.56.0 crashed Plutonium outright.** The wonder weapons' modified animtrees
(`animtrees/zm_<map>_basic.atr`) shipped inside `mod.ff` and referenced 18
`ai_zombie_thundergun_*` animations that existed **nowhere the game could reach** — not in
`mod.ff`, not in `zm_transit.ff`, not in `mod.iwd`.

**Two asset classes travel RAW inside `mod.iwd`, never in the fastfile:**

| class | folder | why it cannot be linked |
|---|---|---|
| effects | `fx\**.efx` | OAT cannot link an `FxEffectDef` at all |
| animations | `xanim\*` | nothing in the zone declares them — see below |

🛑 **The trap that produced it.** The upstream README says the per-map
`scripts\zm\<map>\anims_*.gsc` files make the Linker pull each xanim in as a dependency of that
map's animtree. **That is only true of a pipeline that COMPILES scripts.** OAT stores a T6
script as raw text and never parses it, so nothing is extracted — **the zone links with 0
errors and the game still crashes.** A clean link is not evidence the animations arrived.

### ✅ Pre-flight check — run before shipping any animtree

For every `.atr` the mod ships, confirm each animation it names is reachable:

```bash
for a in $(grep -oE "ai_zombie_[a-z_0-9]*" zone_assets/animtrees/<map>_basic.atr | sort -u); do
    [ -f "xanim/$a" ] || echo "MISSING $a"
done
```

Then confirm `pack_iwd.ps1`'s `$folders` list contains **both** `fx` and `xanim`, and that the
deployed `mod.iwd` actually holds them.

📝 The same omission hit the effects. The merge package shipped only `fx/maps/zombie/**` and
none of the 21 under `fx/weapon/{thunder_gun,freeze_gun,muzzleflashes}/**`. **Diff the log's
"Could not load fx" lines against a previous boot rather than counting them** — this project's
logs carry ~90 normally, so the count is meaningless; only the *set difference* shows what you
broke. That diff is what turned this crash from "somewhere in 684 changed files" into 21 named
effects in one step.

---

## The pre-flight sequence, in order

1. `gsc-tool -m parse -g t6 -s pc -y <file>` (`-i client` for `.csc`) — syntax only; it will happily
   parse something semantically wrong.
2. Clientfield symmetry audit (§1) and per-set bit budget (§2).
3. Root-script scope check (§3).
4. Assets: does the map already have it? (§5) → decides whether `build_ff.bat` is needed.
5. `build.bat`; `build_ff.bat` too if `zone_source\`/`zone_assets\` changed.
6. **Verify the deployed bytes**, not the `[ok]` line — compare size and timestamp, and for a
   script change confirm the new symbol is actually inside the deployed `mod.iwd`.
7. Say plainly what is deployed but **not yet booted**.
