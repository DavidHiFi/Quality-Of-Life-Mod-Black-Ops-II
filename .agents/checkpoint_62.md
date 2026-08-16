# Checkpoint 62 — v1.99.14. All three v1.99.13 items failed in game; all three re-diagnosed from the log, plus the first full weapon-asset audit.

Written 2026-08-16. **Supersedes 61 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

🛑 **The user's verdict on v1.99.13: all three failed, and the Tac-45's Pack-a-Punch was a
regression I introduced.** New standing instruction recorded: [[zm-qol-revise-and-no-broken-features]]
— "revise" means audit the whole mod, never ship a broken or partial addition, and a long session
must end in working progress.

---

## 0. STATE — v1.99.14 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Who's Who description | 🟡 built v1.98.0, never booted |
| 2 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 3 | **Tac-45 base gun** | ✅ **confirmed working in game by the user** ("seemed to be working fine") |
| 4 | **Tac-45 Pack-a-Punch** | 🟡 five missing left-hand anims found and fixed, **unbooted**. §1 |
| 5 | **Winter's Howl fx** | 🟡 real cause found (no `projTrailEffect`), **unbooted**. §2 |
| 6 | **Who's Who overlay** | 🟡 real cause found (night mode overrides the visionset), **unbooted**. §3 |
| 7 | **Kill-feed icons** | 🟡 cause found by the audit, fixed, **unbooted**. §4 |
| 8 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 9–15 | `mod.ff` stale script · `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 THE THREE THINGS TO DO ON THE NEXT BOOT
1. `.give tac45` then `.pack` — **are the arms and both guns correct now?**
2. `.wintershowl`, fire it — **is there a visible blast travelling forward?**
3. Go down with Who's Who — **is the screen tinted?** (night mode on or off, both should work)

---

## 1. 🛑 THE TAC-45 REGRESSION — ENUMERATE BY VALUE, NEVER BY FIELD NAME

The packed gun drew enormous and misplaced: a viewmodel with **no animation to play** renders at
bind pose. Five left-hand dual-wield anims plus one melee anim were referenced by the defs and
declared nowhere.

**Why they were missed:** the first pass matched the FIELD NAME suffix (`*Anim`, `*_in`, `*_loop`,
`*_out`). The dual-wield fields are `idleAnimLeft`, `emptyIdleAnimLeft`, `fireAnimLeft`,
`lastShotAnimLeft`, `reloadAnimLeft`, `reloadEmptyAnimLeft` — ending in **Left** — and
`meleeAnimEmpty` ends in **Empty**.

🌟 **THE RULE: enumerate by VALUE.** Every value starting with `viewmodel_` is an xanim whatever the
field is called. Encoded in `.agents\audit_weapon_assets.js` so it cannot recur.

## 2. 🌟 THE WINTER'S HOWL WAS NEVER A MUZZLE-FLASH PROBLEM

Four rounds went into `viewFlashEffect` / `worldFlashEffect`. The gun is **`weaponType projectile`,
`projectileSpeed 2000`, with no `projTrailEffect` and no `projExplosionEffect` at all** — it fires an
invisible projectile. The Wunderwaffe (which the user likes) has both.

And `fx_trail_freezegun_geotail` + `fx_trail_freezegun_ring_emit` have shipped with the mod the whole
time — declared, **confirmed loading in this session's log**, referenced by nothing. `geotail`'s
`emission` field names `ring_emit`; together they are a smoke-wisp trail with dust motes, water
droplets and light flares travelling with the shot.

📝 **The lesson to keep:** checkpoint 60 already listed those two unused effects as "the obvious next
lead" and the next round went back to the muzzle flash anyway. **When a previous checkpoint names an
unchased lead, chase it before re-opening the one that has already failed.** Same for night mode
below — checkpoint 60 named it as the Who's Who suspect and it was not chased either.

## 3. 🌟 WHO'S WHO — THIS MOD'S OWN NIGHT MODE OVERRIDES EVERY VISIONSET

`qol_opt_night_on()` sets `r_filmUseTweaks 1` plus `vc_rgbh / vc_yl / vc_yh / vc_rgbl / vc_fsm /
vc_fbm`. **Those are the same colour-grade parameters a `.vision` file carries** — `zm_whos_who.vision`
is literally a list of `vc_*` values. `r_filmUseTweaks 1` makes the renderer use the **dvars instead
of the active visionset**, so `vsmgr_activate()` succeeded and was ignored. Silently.

v1.99.13's five shipped assets were necessary and **not sufficient** — they are kept.

**Fix:** `zmqol_whoswho_overlay_watch()` polls stock's `self.whos_who_effects_active` (the call that
sets it is unqualified and same-file, so `replaceFunc` cannot reach it) and drives the six vc_* dvars
with the values read out of `zm_whos_who.vision`, restoring night-mode or neutral values on revive.

🛑 **Generalise this:** any mod feature that sets `r_filmUseTweaks` or a `vc_*` dvar silently defeats
every visionset in the game. Check that before diagnosing any missing colour-grade effect.

## 4. 🌟 THE FIRST "REVISE" — 112 FINDINGS, NOW 1

`.agents\audit_weapon_assets.js` resolves every asset every added weapon references against `mod.ff`
plus the fastfiles each map really loads (from the log's `Loading fastfile` lines). Highlights:

- **The README's "kill-feed icons missing" bug is solved**: the nine `menu_mp_weapons_*` materials
  ship only in `code_post_gfx_mp.ff` / `frontend.ff`, which no zombies map loads.
- Six Titus-6 dive-to-prone anims declared nowhere → bind pose on a dive.
- `fx_saw` absent on Mob; the packed XPR-50's muzzle flash absent on Origins; the Titus dart reticle
  absent on five maps.
- 🟡 **`viewmodel_base_viewhands` (Thundergun `handModel`) left alone deliberately** — it resolves
  nowhere, but the Thundergun is confirmed working and the user is happy with it. Reported, not
  touched.

**Run it every time a weapon changes.** It needs the fastfile index — [[t6-fastfile-full-index]].
