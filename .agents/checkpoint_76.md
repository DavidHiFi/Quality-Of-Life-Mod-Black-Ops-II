# Checkpoint 76 — v1.99.50. Seven releases, six items confirmed in game, the queue cut 29 → 8.

Written 2026-08-18. **Supersedes 75 for status.**

---

## 0. STATE

🛑 **NOTHING IS IN FLIGHT.** Every item shipped since checkpoint 75 has been confirmed in game by the
user, and the last unverified one was closed by their instruction. A new request can start
immediately — the one-at-a-time rule is not holding anything back.

| # | shipped | state |
|---|---|---|
| 1 | **Who's Who knife revive** (v1.99.44) | 🟢 **CONFIRMED** — *"it worked, i shot my body and got revived"* |
| 2 | **Settings survive a restart** (v1.99.45) | 🟢 **CONFIRMED** twice: the user's word, and the config file itself |
| 3 | **Hitmarker sounds off the gunfire bus** (v1.99.46) | 🟢 **CONFIRMED** — *"it's good"* |
| 4 | **Wonder-weapon hitmarkers** (v1.99.47) | 🟡 measured working on 5 of 6 paths, then **closed by the user** |
| 5 | **INSTANT NUKE + the GAME-tab rename** (v1.99.48) | 🟢 **CONFIRMED** — *"works perfectly toggled it on or off"* |
| 6 | **Crossbow fuse +3 s** (v1.99.49) | 🟢 **CONFIRMED** |
| 7 | **Titus-6 reload + first-raise sounds** (v1.99.50) | 🟢 **CONFIRMED** — *"all sound fx are working all 3 of them"* |

**The queue is 8 lines**, down from 29. Twenty-one items were removed across two passes on
2026-08-18, both fully recorded in `QUEUE_LIST.md`'s Closed section with old numbers, per-item state
and the old→new maps.

🛑 **Three things survive their closed parent items. They are the user's call, NOT to-dos:**
1. **Who's Who on Origins** — 43 absent assets (checkpoint 75 §3). Awaiting a go/no-go on a `mod.ff`
   weapon port.
2. **`fly_titus_futz` / `fly_tar21_futz`** — defined in no bank in the game, so silent in stock too.
   Offered as a one-line mapping onto the generic assault futz; not taken.
3. **The freezegun's non-lethal hit marker** — never exercised in the one session that had the probe.

---

## 1. 🌟 THE FINDINGS WORTH KEEPING

**A character xmodel has no collision, so `setcandamage()` cannot make a body shootable.**
v1.99.43's Who's Who corpse watcher was armed and logged nothing across repeated point-blank
ballistic-knife hits. The fix was to stop watching the target and watch the **weapon**: stock's
`_zm_weap_ballistic_knife::on_spawn` notifies the player `"ballistic_knife_stationary"` with the
model marking exactly where the bolt stopped — the same path that puts the pick-it-back-up prompt in
the world, so it is provably live. Hit test is the thundergun's own
`pointonsegmentnearesttopoint` cylinder at the revive staff's 32-unit radius. Saved as
`t6-character-model-no-collision`.

**Plutonium only writes ARCHIVE-flagged dvars to its config.** Of ~35 option rows the mod's own
config carried exactly three names — `hud_enable`, `night_mode`, `velocity` — all archived by other
software. That is the whole of "sometimes they work, sometimes they don't". Each row now `seta`s its
own dvar as it is built. The CHEATS tab is deliberately excluded (an archived `fly 1` would spawn the
player in noclip).

**`check_zombie_damage_callbacks()` is a short-circuit loop, not a broadcast.** The first callback
returning true ends it. Three of this mod's four damage callbacks claim their own damage that way, so
the hitmarker was never guaranteed a turn; it is now prepended at index 0. The Death Machine is
deliberately exempt — it converts the same event into a kill, so marking ahead of it would double the
feedback on every lethal minigun round.

**A weapon's reload sounds are in the ANIMATION NOTETRACKS, not the weapon def.** The Titus's 19
`*Sound*` fields all resolved while the gun reloaded in silence. Dumping all 45 `*titus*` xanims and
scanning for `(fly|wpn)_[a-z0-9_]+` gave the real list — and showed the pickup complaint and the
reload complaint were **one bug**, because `_first_raise` calls two of the same missing aliases.
Appended to `t6-weapon-asset-enumeration`.

**A raw weapon def in `mod.iwd` is what the game reads.** Proven for the crossbow rather than
assumed: `mod.ff` carries 99 `weapon` assets and no crossbow, and no stock zombies zone contains a
`weapon, crossbow*` line — yet a TranZit log carries `Loaded weapon: crossbow_explosive_bolt_zm`.

---

## 2. WHAT THE PROBES BOUGHT

Two of this round's fixes shipped with a **named, capped probe** rather than a promise, and both paid
for themselves without costing the user a description:

- `[zm_qol] ww marker: <path> path fired for <weapon>` — 12 lines max, and it answered queue 19 out
  of the log alone. It also **corrected my own claim**: the thundergun does reach the hit path (its
  knockdown branch is non-lethal), which I had said was impossible by construction.
- `[zm_qol] whoswho knife: bolt at rest, path N rest N from corpse` — would have given the numbers to
  retune the radius had the first attempt missed.

📝 The settings fix was self-verifying in a third way: reading the user's own config file after one
clean exit proved the mechanism, not just one good run.

---

## 3. RESIDUAL RISK

1. `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob — **still open, still unworked**, the oldest live
   fault in the project.
2. The LUI `beingAnimation` crash fix (v1.99.24) is **still unconfirmed** — the jet gun has never been
   overheated in a test.
3. The queue's remaining 8 lines are largely the jet-gun family (three of them) plus the Death
   Machine sound work; none has been started.

## 4. THIS SESSION'S VERSIONS

`v1.99.44` knife revive · `v1.99.45` settings persistence · `v1.99.46` hitmarker mix + the silent
DEFAULT · `v1.99.47` hitmarker callback order · `v1.99.48` INSTANT NUKE + rename · `v1.99.49`
crossbow fuse · `v1.99.50` Titus sounds. Commits `d9f711c` … `5cb4a37`.
