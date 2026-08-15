# Checkpoint 51 — v1.98.0. Perk pop-up toggle, Who's Who text, the box audit, and the wonder-weapon rarity reversed.

Written 2026-08-16. **Supersedes 50 for status only** — 50 §1–§4 are all still unbooted and still
the priority. 48 §1–§4 likewise.

---

## 0. STATE — v1.98.0 deployed, hash-verified, never booted

| # | change | state |
|---|---|---|
| 1 | **`hud_perk_popup`** — toggle for the perk-buy pop-up, plus a PERK POP-UP row in the HUD tab | 🟡 never booted |
| 2 | **Who's Who description** — the "—Wait, Why Did You Buy It?" gag removed | 🟡 never booted |
| 3 | **Mystery-box audit** — nothing is replaced; proven name by name | ✅ measurement, no code change |
| 4 | **Wonder-weapon box odds REVERSED** — `zmqol_box_ww_rarity`, default 4 | 🟡 never booted |

🛑 **v1.97.0's four items are still unverified** and this build carries them: the LF-restored `.efx`
(Winter's Howl fx), `.infammo`/`.infsprint`, the random Wunderfizz start, and instant start.

---

## 1. 🌟 THE BOX AUDIT — NOTHING IS REPLACED. The cause is dilution.

Reported via the user's friend: *"he couldn't get a python or executioner, he thinks it's replaced
by the Buried-exclusive Remington New Model Army which was added to all maps."*

**Method:** every `add_zombie_weapon` name the mod registers, per map and globally, diffed against
that map's own stock registrations from the 2,093-file dump — **with comment lines excluded**.
📝 A first pass that did NOT exclude comments reported `mp40_zm` / `mp40_stalker_zm` colliding on
Origins; both were commented-out lines in `zm_tomb.gsc:972-976` describing stock. Always strip
comments before an audit like this.

| result | |
|---|---|
| collisions on transit / nuked / highrise / prison / tomb | **none** |
| collisions on Buried | **`qcw05_zm` only** — and it is a FIX: stock registers it with `upgrade_name` **undefined** (`zm_buried.gsc:1128`); the mod supplies `qcw05_upgraded_zm`. |
| the 3 wonder weapons vs any map's stock list | **none** |
| `python_zm` in the box | **all six maps** |
| `judge_zm` in the box | **all six maps** |

**The real cause is dilution, and it is arithmetic.** ~75 in-box names per map now (stock's ~40 +
cross-map additions + 11 ported MP guns + 3 wonder weapons). A named gun is ~1.3% per spin, so
missing one across a 40-spin game is **~59% likely**. The friend's experience is the expected one.

▶️ If the user wants that improved, it is a separate design question (a "seen it already" pity
weight, or trimming the cross-map additions). Not shipped — not asked for.

---

## 2. 🛑 THE RAY GUN MARK 2 IS NOT RARE IN BO2, AND THE WEIGHTING WAS POINTING THE WRONG WAY

User asked for the three wonder weapons to have *"the same chance as the raygun mark 2, which is a
lot lower than other weapons"*.

**Measured: BO2 has no box weighting of any kind.**
- `treasure_chest_chooseweightedrandomweapon` (`_zm_magicbox.gsc:911`) is a flat `array_randomize`,
  then the first key that passes the filter. Stock's copy and ours are identical here.
- `level.customrandomweaponweights` is the only weighting hook. **One** stock map sets it —
  `zm_buried.gsc:375` — and it points at `buried_custom_weapon_weights( keys ) { return keys; }`,
  a no-op stub (`:452`).
- `add_limited_weapon( "raygun_mark2_zm", 4 )` is a per-PLAYER quota of 4 — never binds in a
  4-player game, never in solo. The genuinely capped guns are the map wonder weapons:
  `slowgun_zm` and `slipgun_zm` are `add_limited_weapon( x, 1 )`.
- `special_weapon_magicbox_check` only stops Ray Gun and Mark 2 dropping for the same player.

So "match the Mark 2" and "much rarer than other guns" are **two different requests**.

🛑 **And the mod was doing the opposite of both.** `zmqol_box_wonder_weight` defaulted to **2** and
appended two extra entries per unheld wonder weapon from round 10 — a deliberate BOOST, on by
default. That dvar is **gone**.

**Replacement:** `zmqol_box_ww_rarity`, read in `zmqol_box_wonder_weapon_weights()`:

| value | effect |
|---|---|
| `1` | same chance as any other gun — i.e. literally the real Mark 2's treatment |
| `4` | **default** — a quarter as likely as an ordinary gun |
| `0` | never from the box (the `.thundergun` / `.wunderwaffe` / `.wintershowl` commands still work) |

The mechanism is deletion, not appending: the box returns the first key from a shuffled list, so
dropping a name on 3 spins in 4 scales exactly that name's share to a quarter. **No other weapon is
touched** — the "standard chances" half of the request is satisfied by doing nothing.

📝 At the default and ~75 in-box names, each wonder weapon is ~0.33% per spin and the three together
~1%. That is deliberately rare. **If it feels too rare, `zmqol_box_ww_rarity 2` at the console needs
no rebuild.**

---

## 3. THE PERK POP-UP TOGGLE

`hud_perk_popup`, default **1** (existing behaviour — a new toggle must not silently change what the
mod already does). Registered in `qol_options::init()`; read in exactly ONE place, the top of
`perk_bought()`, before the first `newclienthudelem`.

Gated there rather than by fading, for two reasons already learned the hard way:
- the four hudelems are never created while it is off, handing those slots back to the pool Origins'
  capture ring allocates from (the v1.53.0 health-bar lesson);
- one owner only, so it cannot fight an alpha loop the way the zombie counter did in v1.87.1.

It reads `hud_master` and `hud_all` in the same order the health bar does, so `.hud off` hides it
and `hud_all 1` forces it on. Menu row **PERK POP-UP** added to the HUD tab, now 10 rows — still
inside the proven 14.5 budget.

---

## 4. NEXT, in order

1. **Diner** — the Winter's Howl fx (50 §1), and the two riser questions in 50 §4.
2. `.infammo` with the CHEATS row set to DISABLED (50 §2); the perk pop-up toggle; the Who's Who
   description; a few box spins for the new rarity.
3. **A multi-machine map** for the random Wunderfizz start (50 §3) — Diner has only one machine.
4. **Origins** — the ring (48 §1) and Who's Who's overlay (48 §3), both still unbooted.
5. 🛑 **Origins with the mod OFF** — the crash (48 §2). Still never run.
