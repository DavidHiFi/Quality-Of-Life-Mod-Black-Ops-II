# Checkpoint 75 — v1.99.43. The Who's Who ballistic knife works; its revive did not, and why.

Written 2026-08-18. **Supersedes 74 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | **Who's Who PaP'd ballistic knife — the GUN** | 🟢 **CONFIRMED IN GAME** on TranZit. Log: `whoswho knife: gave knife_ballistic_upgraded_zm in place of m1911_zm` |
| 2 | **Who's Who corpse glow** | 🟢 **CONFIRMED IN GAME** on TranZit (user screenshot). Working as designed. |
| 3 | **Knife revive-on-hit** (shoot your own corpse) | 🔴 **was broken everywhere but Die Rise — fixed at v1.99.43, deployed, UNBOOTED.** §1 |
| 4 | **Knife option live toggle mid-down** | 🔴 fixed at v1.99.43, deployed, **UNBOOTED.** §2 |
| 5 | Knife on **Origins** | ⚫ **BLOCKED on assets, fully accounted.** §3. Awaiting the user's go/no-go on a mod.ff weapon port. |
| 6 | Who's Who **glow on Origins** | ⚫ **BLOCKED, two-deep, measured.** §4 |
| 7 | BO4 MAX AMMO toggle · Awful Lawton bolts | 🔴 still **unbooted** — never triggered in either session |
| 8 | LUI `beingAnimation` crash fix (v1.99.24) | 🟡 still unconfirmed — jet gun never overheated |
| 9 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) | 🔴 not built |
| 10 | `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins / Mob | 🔴 open, unworked |

🛑 **Next boot answers items 3, 4, 7.** TranZit exercises all of them.

---

## 1. 🌟 `actor_damage_func` IS ACTOR-ONLY — the whole bug in one line

`_zm_clone::spawn_player_clone()` ends with `clone.actor_damage_func = ::clone_damage_func`, and
`clone_damage_func` (`_zm_clone.gsc:65-73`) is what notifies `player_revived` for the four upgraded
ballistic-knife names. **But `.actor_damage_func` is read in exactly one place in the entire 2,093-file
stock dump** — `_zm.gsc:4435`, inside `actor_damage_override()`, reached only through
`level.callbackactordamage` (`_zm.gsc:976`). That is the engine's **actor** damage callback; a
`script_model` never enters it.

And the corpse is a `script_model` on every map but Die Rise. Re-dumped `mapents`,
`fake_player_spawner` census:

| zm_highrise | zm_transit | zm_nuked | zm_buried | zm_tomb |
|---|---|---|---|---|
| **1** → actor | 0 | 0 | 0 | 0 |

Corroborated live: this session's log printed `whoswho: clone glow set on a script_model corpse` on
TranZit — a branch that only runs when `corpse.isactor` is false.

**So the ballistic-knife revive has never worked outside Die Rise, in stock either.** This is the
identical root cause as the clone-glow `actor`-clientfield bug from checkpoint 67, one layer down.

**The fix is parity, not a feature.** On a non-actor corpse: `setcandamage(1)` + the `"damage"`
notify, then re-emit stock's own `corpse notify( "player_revived", e_attacker )`.
`_zm_chugabud.gsc:89` waits on exactly that, and `:91-92` has a dedicated self-revive branch
(`if ( e_reviver == self ) self notify( "whos_who_self_revive" )`) — Treyarch wrote for the player
shooting their **own** body. Die Rise is skipped; its corpse is an actor and stock already fires.

Shape copied from stock's two script_model damage watchers, `_zm_equipment.gsc:1377-1387` and
`_weaponobjects.gsc:495-502`. 🌟 **`weaponname` is argument 9** — corroborated by both
`_weaponobjects.gsc:502` and `_zm_ai_basic.gsc:462`, which disagree about slots 6/7 and agree on 9.
Health is restored on every hit to mirror `clone_damage_func`'s `idamage = 0`.

📝 `setcandamage()` makes the corpse stop bullets. **Not a regression** — the Die Rise corpse already
does, being an actor. This moves the other maps toward Die Rise, not away.

Saved as memory `t6-actor-damage-func-actor-only`.

## 2. The toggle was read ONCE

`whoswho_knife` was tested at the single instant of the `"fake_revive"` notify; by the time the pause
menu opened the swap had happened. The dvar was never at fault — the screenshot showed DISABLED and
the log showed the value it was given the knife under.

Now watched for the lifetime of the down. **Lifetime = `self.e_chugabud_corpse`**, set at
`_zm_chugabud.gsc:68` **before** `:75` calls `chugabud_fake_revive()` (so no polling race), cleared at
`:183` in `chugabud_corpse_cleanup()`, which every exit from the state passes through. Giving the
pistol back goes through stock's `_zm_utility::give_start_weapon( 1 )`.

## 3. ORIGINS + THE KNIFE — the accounting is complete, and it is 43 assets

Built a full `Unlinker --list` index of **297 fastfiles** (incl. Plutonium's `plutonium_zm`,
`ffotd_tu17_zm_147`). Cross-checked against the 20 fastfiles Origins actually loads — the other 5 in
its load list (`so_zclassic_zm_tomb`, `dlc0_load_zm`, `dlc0dd_load_zm`, `seasonpass_load_zm`) **do not
exist on disk**, so coverage is total.

**All 43 required assets absent:** 6 weapon defs, 6 xmodels, 17 xanims (`viewmodel_b_knife_*`),
5 materials, 6 images, 2 fx, 1 camo. Present only in `zm_transit/nuked/highrise/buried.ff`.

🌟 **But it is doable, and the precedent is this project's own:** 9 MP weapons (511 assets) are
already baked into `mod.ff` and register on Origins today, and `mod.all.sabl` is already rebuilt with
custom aliases (as50 fire, the SOUND packs). Stock raw defs for all six knife variants exist at
`Black Ops 2 Grand Resources\T6-Data-Archive-main\ZM\Weapons\WEAPONS\`. **Awaiting the user's
go/no-go** — it is a real asset port touching `mod.ff`, which every map loads.

## 4. ORIGINS + THE GLOW — blocked twice, both measured

1. Sweep of all 297 fastfiles: every `mc/mtl_c_zom_player_*_g` glow-capable material lives in
   `zm_highrise.ff` **and nowhere else**, covering the Victis crew only. The Origins crew and
   Nuketown's agents have **no `_g` material anywhere in the game**. A shader constant does nothing
   without one.
2. Origins' `scriptmover` clientfield set sums to **32/32** (stock dump). No bit for the field even
   if the material existed. v1.99.17 shipped that registration and it was a boot crash.

Only route is authoring new Origins character models + materials + shipping the glow techset. Stated,
not started.

## 5. RESIDUAL RISK

1. 🛑 **The one thing not settleable offline: does a ballistic-knife bolt raise a `"damage"` notify
   on a `script_model` at all?** The watcher prints the weapon name of the first **12** hits, capped
   so a zombie chewing the body cannot flood the log. One game distinguishes "the bolt never reaches
   the corpse" from "it reaches it under a different name".
2. Items 3, 4 and 7 are all unbooted at once again. Each prints a distinct named line.
3. `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob remains open.

## 6. SHIPPED IN v1.99.43

`quality_of_life.gsc` only — `zmqol_whoswho_corpse_revive_arm()`,
`zmqol_whoswho_corpse_damage_watch()`, `zmqol_whoswho_knife_toggle_watch()`, plus the arm/re-arm in
`zmqol_whoswho_overlay_watch()`. `gsc-tool -m parse` clean; all three symbols verified inside the
deployed `mod.iwd`. **No `.csc` touched → `mod.ff` unchanged, `build_ff.bat` not needed.**
`README.md` corrected: the gun is confirmed, the revive is "repaired in v1.99.43, not yet confirmed",
and the Origins exclusion now cites the 43-asset count. Commit `a950008`.
