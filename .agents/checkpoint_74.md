# Checkpoint 74 — v1.99.42. Three boots spent removing a stock wall-buy, then reverted.

Written 2026-08-18. **Supersedes 73 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | **Origins Five-seven wall-buy removal (v1.99.39–41)** | ⚫ **REVERTED at v1.99.42.** It is genuine stock Origins content; the user confirmed after looking it up and asked for vanilla behaviour back. Both Origins scripts restored byte-for-byte to their v1.99.38 state and hash-verified in the deployed files. **Closed — do not re-open.** |
| 2 | **Who's Who gives a PaP'd ballistic knife** (GAME tab) | 🔴 built, deployed, **unbooted**. Not on Origins — checkpoint 73 §3 |
| 3 | **BO4 MAX AMMO toggle** (GAME tab) | 🔴 built, deployed, **unbooted** |
| 4 | **Awful Lawton bolts distract zombies** | 🔴 built, deployed, **unbooted** |
| 5 | SOUND tab hit/kill/crit/downed packs · custom title screen | 🟢 confirmed in game 2026-08-17 (checkpoint 73 §1) |
| 6 | LUI `beingAnimation` crash fix (v1.99.24) | 🟡 still unconfirmed — nothing proves the jet gun was ever overheated |
| 7 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) | 🔴 not built |

🛑 **The next boot has to answer items 2, 3 and 4** — three unverified changes in flight at once,
which is why each is independently switchable (`bo4_max_ammo 0`, `whoswho_knife 0`) and each prints a
named line to the log. TranZit exercises all three.

🛑 Still outstanding, unchanged since 70: overheat the jet gun on TranZit and hold through the
cooldown.

---

## 1. 🛑 THE PROCESS FAILURE, WRITTEN DOWN FIRST BECAUSE IT COST MORE THAN THE BUG

The user reported the Origins bunker Five-seven wall-buy as *"not normal and not apart of origins,
and is being added via my mod"*. **Checkpoint 73 §1 already contained three independent proofs that
it is stock Origins content** — the retail `mapents` structs with no `script_noteworthy`, stock
`zm_tomb.gsc:1025`'s `add_zombie_weapon( "fiveseven_zm", … 1100 … )` matching the cost in the user's
own screenshot, and a runtime clientfield dump of an unmodded Origins registering both wall-buys.

That evidence was written into a **code comment** and the removal was built anyway, under the heading
*"Removed regardless — it is the user's mod"*. Three builds and three boots followed. The user's
correction, in their words:

> *"you should've made sure to verify whether I was being truthful or not… if I am genuinely just
> wrong about something, and you have hard empirical objective proof/logic and you can explain it to
> me, then do that instead of making me waste my time trying to fix something that was never
> broken… I made it clear that my goal was for the original vanilla functionality."*

**The rule now, saved to memory as `zm-qol-challenge-wrong-premises`:** when a request rests on a
factual claim about the game, check the claim **before** designing anything. If it is disproven, put
the proof in chat and stop. Reaffirmation after seeing the proof is consent; reaffirmation of a
request made on bad information is not. The stated goal is nearly always *"behave like the real base
game"*, so implementing the literal ask can work directly against it.

---

## 2. 🌟 ORIGINS DRAWS WALL-BUY CHALK AS MAP ART — the fact that would have ended this on move one

Every other zombies map plays a per-weapon chalk **fx** from
`clientscripts\mp\zombies\_zm_weapons::wallbuy_player_connect()`. Origins sets
`level._uses_default_wallbuy_fx = 0` (`zm_tomb.csc:79`, `zm_tomb.gsc:121`), skipping that entire
`loadfx` block (`_zm.csc:307`, `_zm.gsc:1211`), and **paints each chalk into the level as a decal**.

| evidence | result |
|---|---|
| `Unlinker --list` on retail `zm_tomb.ff`, filtered to wall-buy assets | **one** wall-buy fx in the whole map (`maps/zombie/fx_zmb_wall_buy_rifle`), and a `wpc/` **decal material per wall weapon**: `zm_tm_wallbuy_01/02/03`, `_ballista`, `_five_seven`, `_mp40`, `_stg44`, each with its own `~-gfxt_zmb_wep_wallbuy_*_tomb` image |
| the dumped material JSON | `cameraRegion litTrans`, `polygonOffset offset1`, `sortKey 12`, `techniqueSet wpc_sw4_3d_unlit_1layer_…` — a decal surface, not an fx |
| 🌟 **the decider** — `--list` over every `zone\all\*.ff` | `wpc/zm_tm_wallbuy_five_seven` exists in **`zm_tomb.ff` and nowhere else in the game** |

**Two consequences, both reusable:**

1. **No GSC can remove an Origins wall-buy chalk.** Everything below was done, every step confirmed
   from the log, and the chalk never moved: unitrigger unregistered, world clientfield forced to 0,
   weapon model hidden, `stopfx`, `deletefx`, and finally the struct unlisted from
   `level._active_wallbuys` *before* `wallbuy_player_connect` ran. The only route left is shipping a
   blanked `wpc/` material through `mod.ff`, which is per-material and so blanks **every placement of
   that weapon's chalk** on the map.
2. **A chalk drawing on an Origins wall is evidence the wall-buy is stock**, because the art is baked
   into the map. One `Unlinker --list` answers "mine or Treyarch's" without a boot.

Saved as memory `t6-origins-wallbuy-chalk-is-map-art`.

---

## 3. TWO FX FACTS EARNED ALONG THE WAY

- **`stopfx` only ends the emitter.** Particles already spawned live out their lifespan, so it never
  clears a long-lived sprite. v1.99.39 printed success while the chalk sat on the wall.
- 🛑 **`deletefx( localclientnum, handle, 1 )` — the three-argument form — kills the client thread
  silently.** v1.99.40 printed *nothing at all* on either branch while the server half printed
  normally, which is what a thread dying on the statement before a `println` looks like under
  Plutonium. The 3-arg form came from the `_zm.csc:659` decompile; only the 2-arg form is
  corroborated by more than one stock file (`_fx.csc:137`, `_zm_equipment.csc:30`, `zmeat.csc:49`).
  **A decompiled argument list is not evidence.**

Also fixed while there: a diagnostic that lied. The server half printed the stub origin **after**
`unregister_unitrigger` had already `arrayremovevalue`'d it, so later entries slid down and the log
named `(802,-2883,104)` — a position the 64-unit distance test it had just passed makes impossible.
It cost a wrong theory. **Capture what you are going to print before the call that mutates it.**

One thing verified in passing and worth keeping: **`array[key] = undefined` really does remove the
key in T6.** `_globallogic_player.gsc:509-519` shifts every later element of `level.players` down and
assigns undefined to the last index, then iterates `.size` expecting it to have shrunk.

---

## 4. WHAT SHIPPED IN v1.99.42

- `scripts\zm\zm_tomb\zm_tomb.gsc` and `zm_tomb.csc` restored from `2052a44` (v1.99.38). Zero
  occurrences of `fiveseven_wallbuy` / `_zmqol_fiveseven` remain in source, in the deployed `mod.ff`
  (`Unlinker --include-assets script`) or in the deployed `mod.iwd`.
- `README.md`: the Who's Who ballistic knife and Awful Lawton bullets now carry **"deployed, not yet
  confirmed in game"**. Nothing in the README ever claimed the Five-seven removal, so there was
  nothing to retract.
- `gsc-tool -m parse` clean on both files; `build_ff.bat` reported `(src: disk)`; deployed `mod.ff`
  and `mod.iwd` hash-match source.

## 5. RESIDUAL RISK

1. Items 2–4 in §0 have never been played. A bad boot cannot name its own cause; the two dvars and
   the named log lines are the mitigation.
2. The `"missile_fire"` notify in the Awful Lawton chain is still the one thing that could not be
   settled offline (checkpoint 73 §7.2). A one-shot `println` fires on the first bolt POI created.
3. `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob remains open and unworked.
