# Checkpoint 73 — v1.99.39. Four changes in one pass, at the user's explicit instruction.

Written 2026-08-17. **Supersedes 72 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | SOUND tab hit/kill/crit/downed packs · custom title screen | 🟢 **CONFIRMED IN GAME**, 2026-08-17: *"both the sounds & my custom menu texture i gave for you both work no problems"*. Queue 19 closed and removed |
| 2 | **Origins bunker Five-seven wall-buy removed** | 🔴 built, byte-verified deployed, **unbooted** |
| 3 | **Who's Who gives a PaP'd ballistic knife** (GAME tab) | 🔴 built, deployed, **unbooted**. Not on Origins — §3 |
| 4 | **BO4 MAX AMMO toggle** (GAME tab) | 🔴 built, deployed, **unbooted** |
| 5 | **Awful Lawton bolts distract zombies** | 🔴 built, deployed, **unbooted** |
| 6 | LUI `beingAnimation` crash fix (v1.99.24) | 🟡 still unconfirmed — nothing proves the jet gun was ever overheated |
| 7 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) | 🔴 not built |

🛑 **The ONE-CHANGE-AT-A-TIME rule was set aside deliberately**, on the user's instruction
(*"do this all right now and don't miss anything"*). Four unverified changes are in flight at once,
so a bad boot does **not** name its own cause. Each one is independently switchable, which is the
mitigation: `bo4_max_ammo 0`, `whoswho_knife 0` turn two of them off from the console, and the other
two print a named line to the log.

🛑 Still outstanding, unchanged since 70: overheat the jet gun on TranZit and hold through the
cooldown.

---

## 1. THE FIVE-SEVEN WALL-BUY IS STOCK ORIGINS — and it was removed anyway

The user reported it as *"not normal and not apart of origins, and is being added via my mod"*, and
guessed it was a leftover of the BO2-Reimagined survival-location port. It is neither.

**Three independent reads of the retail game, before a line was written:**

| evidence | result |
|---|---|
| `Unlinker --include-assets mapents` on retail `zone\all\zm_tomb.ff` | **two** `zombie_weapon_upgrade "fiveseven_zm"` structs, `(1270.64, -2593.29, 146.5)` and `(-927.75, 3036, -52)`, **neither with a `script_noteworthy`** — and `_zm_weapons.gsc:872` spawns every wall-buy struct that has none, in every gametype |
| stock `zm_tomb.gsc:1025` | `add_zombie_weapon( "fiveseven_zm", ... 1100 ... )` — **1100 is the cost in the user's own screenshot** |
| 🌟 **the decider** — `Black Ops 2 Grand Resources\T6-Data-Archive-main\ZM\Clientfields\Standard Gametype\Standard Location\clientfields_zm_tomb_zclassic_tomb.txt` lines 55–56 | a **runtime dump of an unmodded Origins** registers `world fiveseven_zm_(1270.64, -2593.29, 146.5)` and `world fiveseven_zm_(-927.75, 3036, -52)`. A wall-buy only gets a clientfield if the game actually built it |

The mod's own wall-buy code was checked too and exonerated: `zm_expanded.csc::enable_wallbuys` only
re-tags **transit** and **buried** survival structs, and never touches Origins.

**Removed regardless — it is the user's mod and it is what they asked for.** Only the bunker one, per
*"simply remove that wallbuy only"*; the other Five-seven is still there and comes out on one word.

### 🛑 Why the clientfield registration was deliberately left alone

The obvious fix — set `script_noteworthy` so stock's own gametype filter skips the struct — is
**unavailable twice over**, and both reasons are already written into this project in blood:

1. Server and client each build the spawn list from **their own copy** of the structs
   (`_zm_weapons.gsc:842`, `_zm_weapons.csc:175`) and each registers the clientfield from it. Tagging
   one VM and not the other is `EXE_CLIENT_FIELD_MISMATCH` at load — the exact failure
   `zm_expanded.csc`'s own header records (*"the two sides have to tag the SAME set"*).
2. This mod's `main()` runs **before the map's**, so `level.struct` is still empty. Not a guess:
   v1.59.1 tried it for the MP40 and its own probe printed *"retagged 0 of 0 weapon_upgrade
   struct(s)"*.

So both sides still register **exactly** what stock registers — symmetry untouched, worst case is a
feature that does nothing rather than a dead boot — and the wall-buy is dismantled afterwards:

| part | where | how |
|---|---|---|
| buy trigger | `zm_tomb.gsc` | `_zm_unitrigger::unregister_unitrigger` (removes the stub *and* every per-player trigger) |
| wall model | both | world clientfield forced to 0 server-side; `hide()` client-side |
| chalk fx | `zm_tomb.csc` | 🌟 `stopfx` — **stock's own call**, `_zm_weapons.csc:384-387` does this same pair when a buildable wall-buy changes weapon |

All three, because two out of three is the *"chalk with no prompt"* bug this map has already shipped
once. Both halves poll rather than bet on a window — the MP40 lesson (checkpoint at v1.80.0).

---

## 2. WHO'S WHO — the revive half already existed and nobody had noticed

User: *"the pap'd ballistic knife in bo2 zombies acts as an instant revive if you shoot a downed
player with its projectile"*.

🌟 **Treyarch wired that to the Who's Who corpse specifically, and it has never been reachable.**
`_zm_clone::clone_damage_func()` — the damage callback `spawn_player_clone()` puts on every clone
(`:60`) — reads:

```
if ( sweapon == "knife_ballistic_upgraded_zm" || ..._bowie_... || ..._no_melee_... || ..._sickle_... )
    self notify( "player_revived", eattacker );
```

and `_zm_chugabud::chugabud_spawn_corpse()` (`:196`) builds the Who's Who corpse with that exact
function. The perk simply never hands you a gun that can trigger it. **So this feature is one
`giveweapon`, not a revive implementation.**

- Hooked on `self waittill( "fake_revive" )`. 🌟 **Checked for collisions**: grepping the whole ZM
  dump, `"fake_revive"` is emitted by **`_zm_chugabud.gsc:393` and nowhere else** — Mob's Afterlife
  emits `fake_death` but never `fake_revive`, so nothing else on any map can trip this.
- Replaces `level.start_weapon` (m1911_zm classic / c96_zm Origins), which is what stock's
  `give_start_weapon(1)` at `_zm_chugabud.gsc:427` hands over.
- 🛑 **Polls for the pistol instead of waiting a fixed frame.** The notify is 35 lines above the
  `giveweapon`, with a spawn-point search in between; "one frame later" bets on that search never
  yielding. If the pistol never arrives, nothing is taken and the perk stays stock.
- The variant is chosen by stock's own `_zm_melee_weapon::give_ballistic_knife( name, 1 )`, then
  **re-checked against `level.zombie_include_weapons`** — Die Rise ships the Sickle but does *not*
  include `knife_ballistic_sickle_upgraded_zm`, so that path would otherwise hand over a weapon that
  was never precached. Falls back to the plain upgraded knife.

---

## 3. 📝 ORIGINS CANNOT HAVE THE KNIFE — stated, not hidden

`Unlinker --list` over retail `zm_tomb.ff` and `zm_prison.ff` finds **no `knife_ballistic` asset of
any kind** — no weapon, no fx, no reticle — while `zm_transit.ff` carries all six variants. Stock
`zm_tomb.gsc` and `zm_prison.gsc` contain zero `include_weapon( "knife_ballistic..." )` lines.

Cross-referenced against where the perk runs (`zmqol_whoswho_enabled()`: not Die Rise — native
there — not Mob, not Buried):

| map | Who's Who | PaP'd ballistic knife | feature |
|---|---|---|---|
| zm_transit | mod | ✅ | ✅ |
| zm_nuked | mod | ✅ | ✅ |
| zm_highrise | native | ✅ | ✅ |
| **zm_tomb** | mod | **❌ not in the fastfile** | **stays stock** |
| zm_prison / zm_buried | no perk | — | n/a |

The guard in code is `level.zombie_include_weapons[...]`, the real precondition
(`include_weapon()` is what calls `precacheitem`, `_zm_weapons.gsc:700-701`), **not** a hard-coded
map list that could go stale. Closing the Origins gap means shipping a whole weapon — def, xmodels,
anims, sounds, fx — through `mod.ff`, which carries the asset-ownership trap. **The user's call.**

---

## 4. BO4 MAX AMMO — the toggle is one line, and "off" is not an approximation

Diffed the mod's `new_full_ammo_powerup()` against stock
`_zm_powerups::full_ammo_powerup()` line by line: same player loop, same three skip tests, same four
notifies, same `full_ammo_on_hud()` tail. **The entire difference is one statement**,
`setweaponammoclip( curWeapon, 300 )` — `givemaxammo()` alone refills reserves only, which is why
vanilla makes you reload first.

So the dvar gates that one line and `bo4_max_ammo 0` **is** vanilla, not a reimplementation of it. No
copy of stock is kept anywhere to drift, and the `replaceFunc` stays in place either way — calling
stock's function back would re-enter the replacement.

---

## 5. AWFUL LAWTON — the name was already right, and the bolt is not the projectile

📝 **Nothing to do for the name.** `crossbow_upgraded_zm`'s `displayName` is
`ZOMBIE_CROSSBOW_EXPLOSIVE_UPGRADED`, and `mod.str`'s own v1.89.0 note lists "Awful Lawton" among the
eleven refs that already resolve on a zombies map and must not be re-declared.

🌟 **No monkey is created.** Stock's cymbal monkey does the attraction with two `_zm_utility` calls
(`_zm_weap_cymbal_monkey.gsc:331-334`); the model, animtree, glow fx, music, player clone and
`resetmissiledetonationtime()` are the toy, not the mechanism. Zombies find these purely by the
`script_noteworthy = "zombie_poi"` that `create_zombie_point_of_interest` sets
(`_zm_ai_basic.gsc:42` → `getentarray( "zombie_poi", "script_noteworthy" )`), so **the bolt itself
becomes the point of interest and drops out of that array when it explodes** — no cleanup to get
wrong. Numbers are the monkey's own defaults: 1536 / 96 / 4 rings 45 apart.

🛑 **The trap that would have cost a boot:** firing `crossbow_upgraded_zm` produces **two** entities —
the missile handed to `"missile_fire"`, and a separate `grenade`-classname entity (its
`grenadeWeapon`, `crossbow_explosive_bolt_upgraded_zm`: `weaponType grenade`, `fuseTime 3`,
`stickiness "Stick to all"`) which is what actually sticks and explodes. The POI must go on the
**grenade**. Both that split and the `"missile_fire"` notify name come from BO2-Reimagined's
`scripts\zm\reimagined\_zm_weap_crossbow.gsc` — same engine, same weapon, same problem.

They are told apart by model, settled from the two weapon files:
`crossbow_upgraded_zm` → `t5_weapon_crossbow_bolt_exp`, the bolt → `t5_weapon_crossbow_bolt`.

**Three deliberate narrowings away from Reimagined**, because *"adapt, don't bulk-copy"*:
1. Their `zm_electric_stun` animation on the struck zombie is a Reimagined balance change, not BO1
   behaviour. Dropped — the request was *"same as bo1"*.
2. They delete the missile entity. This mod's crossbow already works without that; deleting an entity
   the mod has never deleted is a change outside the request. Left alone.
3. They take the *first* unmarked bolt; this takes the **closest** one to where the shot landed, so a
   base-crossbow bolt (never marked by this code) cannot be picked up by mistake.

---

## 6. VERIFICATION DONE (all offline)

- `gsc-tool -m parse` clean on `quality_of_life.gsc` and `zm_tomb.gsc`; `-i client` clean on
  `zm_tomb.csc`. `luaparse` (5.1) clean on `optionssettings.lua`.
- `build_ff.bat` → **`Loaded script "scripts/zm/zm_tomb/zm_tomb.csc" (src: disk)`**, not `(src: mod)`,
  so the edited client script shipped rather than the donor's stale copy. Then `build.bat`.
- Deployed `mod.json` and `raw\ui\t6\menus\optionssettings.lua` SHA256-**match** source.
- The new symbols are **inside the deployed `mod.iwd`** (`zmqol_whoswho_knife_watch`,
  `zmqol_awful_lawton_bolt`, `bo4_max_ammo`, `zmqol_tomb_remove_fiveseven_wallbuy`), and
  `zmqol_tomb_remove_fiveseven_wallbuy` is **inside the deployed `mod.ff`**
  (`Unlinker --include-assets script`).
- 🌟 **The "default ON" was proven, not assumed.** Both new rows default to 1, which only holds if a
  menu row does not create its dvar at 0. Read Plutonium's own
  `storage\t6\raw\ui\t6\dvarleftrightselector.lua`: the only `Engine.SetDvar` call is inside
  `DvarSelectorSetDvarFunc`, the **choice callback**. Building a row only *reads*
  (`UIExpression.DvarString`). So the dvar stays empty until the user picks something, `create_dvar`
  fills it with 1, and `getdvarintdefault( ..., 1 )` covers it even if it never runs.
- GAME tab is now **13.5 row-pitches**, against the conservatively proven 14.5 (and the measured
  ~16.3 box of checkpoint 72 §2).

## 7. RESIDUAL RISK — what the next boot has to answer

1. **Nothing here has been played.** Four changes at once; see §0.
2. 🛑 **`"missile_fire"` is the one thing that cannot be settled offline.** Reimagined's evidence is
   theirs, not a test of this build. A one-shot `println` fires on the first bolt POI created —
   *"[zm_qol] awful lawton: bolt POI created at (x,y,z)"*. Present = the whole chain worked. Absent
   with the feature dead = the notify name is where to start.
3. The Five-seven halves each print a named line, including on failure
   (*"NO matching wall-buy stub found in 60s"* / *"never found the bunker wall-buy fx"*), so a partial
   removal — trigger gone but chalk still drawn, or the reverse — is readable in the log rather than
   guessable from a screenshot.
4. The Who's Who swap prints what it gave and what it replaced, and prints if the pistol never came.
