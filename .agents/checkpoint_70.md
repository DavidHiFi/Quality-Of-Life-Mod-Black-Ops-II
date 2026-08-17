# Checkpoint 70 — v1.99.29. Seven versions in one session; four confirmed, five still unbooted.

Written 2026-08-17. **Supersedes 69 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | ~~stale `mod.ff` scripts~~ · ~~`clientnotifyloop`~~ · ~~jet gun is stock~~ · ~~PERK LIMIT~~ | ✅ **CONFIRMED IN GAME** |
| 2 | Jet gun **never breaks** + Paralyzer cooldown (v1.99.23) | 🟡 partly seen — it survived, then the game crashed. Crash fixed in v1.99.24, **the retest never happened** |
| 3 | **LUI `beingAnimation` crash fix** (v1.99.24) | 🔴 **UNBOOTED — this is the one that matters** |
| 4 | Six chat commands (v1.99.25) | 🔴 unbooted |
| 5 | INSTANT PAP toggle · COMPASS (v1.99.26) | 🔴 unbooted |
| 6 | Who's Who description · Wunderfizz first location · kill-feed icons | 🔴 unbooted, older builds |
| 7 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) · 19 (sound options) | 🔴 not built |

🛑 **The single most important outstanding test:** build the jet gun on TranZit, hold the trigger
until it overheats, **and keep holding while it cools**. That exact moment closed the game on
v1.99.23 and is what v1.99.24 fixes. Nothing else in this checkpoint is a crash.

---

## 1. 🌟 THE FIND OF THE SESSION — a Treyarch typo that closes the game

`ui_mp/t6/zombie/otherammocounters.lua` calls **`beingAnimation`**, misspelled, in the branch that
restores the ammo counter to its normal colour **after an overheating weapon finishes cooling**.
A string sweep of every shipped LUI file finds it in **exactly one file, once**, against
`beginAnimation` in dozens including 7 in `ui/lui/luielement.lua`. A LUI error in T6 is **fatal**.

Nobody has hit it since 2012 because only the jet gun and the Paralyzer raise the event, the jet
gun's counter is normally hidden (hence the well-known glitch to reveal it), and **the stock jet gun
explodes on overheat** — so it is gone before it can cool back down.

Making it never break (v1.99.23) walked straight into it. 🌟 **The user's report named the branch
before the code did:** *"it stopped shooting… then after a few more seconds my game crashed."*

Fixed by **aliasing** `beingAnimation` → `beginAnimation` on the LUI classes, so stock's own
function runs complete and nothing of Treyarch's logic is reconstructed. Plus a `pcall` — a cosmetic
HUD repaint must never close the game. → [[t6-lui-beinganimation-typo]]

## 2. THE JET GUN, IN ORDER

| queue | finding |
|---|---|
| 15 ✅ | **Not a bug.** It is *equipment*; only `equipment_give` binds action slot 1, and a console `give` binds nothing. Built at the bench it works — user confirmed. |
| 17 | Paralyzer parity is **three fields**, measured by dumping both defs and diffing all 1,027 of each: `overheatRate 17→10`, `cooldownRate 1→3`, `overheatEndVal 77→87`. Shipped raw in `weapons\zm\`. |
| 16 | "Never breaks" is **one flag** — `zm_transit.gsc:1638 level.explode_overheated_jetgun = 1`, the only assignment in the game. Done. The **weapon-slot half is NOT done**: it needs `inventoryType item→primary`, which reroutes give/drop/pickup. |

🛑 **Still unsettled: does a raw def in `weapons\zm\` OVERRIDE a def that also exists in a fastfile?**
All 40 raw defs shipping today are weapons absent from every zombies fastfile, so they only prove a
raw def can *supply* a missing weapon. `jetgun_zm` is inside `zm_transit.ff`. The v1.99.23 probe
printed `inventorytype=item clipsize=500` — useless, because clipSize was not a field I changed.
📝 **Next probe must change a GSC-readable field.** `weaponinventorytype()` is the one, which means
queue 16's own change is the test.

## 3. 🌟 LUI POSITIONING IS RELATIVE TO THE PARENT, AND THE OFFSET HERE IS +21.5

Three measured rounds to seat the lobby map preview, each from a screenshot rather than by eye
(2000×1125 against LUI 1280×720 = **exactly 1.5625 px per unit**):

| | panel | hint text |
|---|---|---|
| v1.99.26 | 451.2 – 627.8 | 460.2 – 470.4 — **18 units inside** |
| v1.99.27 | unchanged | 442.2 – 455.7 — spacer zeroed, 4.5 inside |
| v1.99.28 | 484.5 – 659.8 | bottom border onto the ESC row |
| **v1.99.29** | **469.5 – 646.5** ✅ | 8.7 clear above, 25.5 clear below |

🛑 **v1.99.28 asked for top 463 and got 484.5** — a constant **+21.5**. `setTopBottom` on
`body.mapInfoImage` is parent-relative, not screen-relative; the requested *height* was honoured
exactly. **Pass (target − 21.5).** Only learnable by shipping once and measuring.

🛑 **And I twice wrote that the panel could not be moved from our files.** Wrong both times. A string
sweep of stock `ui/t6/menus/privategamelobby.lua` shows it as
`PrivateGameLobbyButtonPane.body.mapInfoImage` — on the pane `PopulateButtons_Project` already
receives. It is created *after* that function returns, hence the one-shot timer.

📝 Also corrected: the mod does **not own** the SOUND tab. It ships a full replacement of
`optionssettings.lua`, which draws every tab, so `CreateSoundTab` is editable — but SOUND is stock.
Only GAME, HUD and CHEATS are the mod's own.

## 4. QUEUE 19 — WHY THE SOUND OPTIONS ARE NOT IN THIS BUILD

They are not on/off. Each picks between sound packs: 9 for hit, 9 for kill, 4 for downed, 3 for
crits — **20 aliases that exist in 0 of the 2,093 stock scripts**. TechnoOps ships the audio itself
(`sound/custom/`, 104 files, plus its own alias CSV).

**The user authorised using that audio, explicitly overriding `AI_CONTEXT.md` rule 7 for this case.**
Recorded here because it is a standing rule being set aside, not a default.

🛑 Held back deliberately: it needs a **sound-bank rebuild**, and `mod.all.sabl` is **62 MB of all
this mod's audio**. A botched rebuild silences everything, and **a missing alias is silent, never an
error** — it would look fine until you shot something. It gets its own pass with nothing else in
flight. Placement is already settled: appended inside `CreateSoundTab` after SYSTEM TEST, behind a
spacer; that tab goes 10 → 14 pitches against a ~14.5 ceiling.

## 5. ALSO IN THIS BUILD

- **Six chat commands** ported from the ezz_server release — `.pay .bring .killall .shield .staff
  .movespeed` — only the ones the mod did not already have. Six *weapon* commands became rows in
  `zmqol_weapon_give_table()` instead, so `pap` works on them for free.
  🌟 **A bug in the donor, fixed here:** `minus_to_player_score( points )` runs the amount through
  the persistent Double Points multiplier (`_zm_score.gsc:333-337`), so its `!pay` overcharges the
  sender. Passing `ignore_double_points_upgrade = 1` makes the transfer exact.
  🛑 `!speed` is **not** ported under that name — `.speed` already means the velocity HUD here.
- **INSTANT PAP** toggle (GAME tab) and **COMPASS** (HUD tab). The compass is written against this
  mod's own zone HUD, **not** copied: theirs `settext`s every loop pass, which is the unbounded
  reliable-command emitter in `ERROR_CATALOGUE` §7b. Here it writes only on change.
- **The user's own `menu_zm_title_screen.iwi`** — "Quality Of Life" in Agency FB.
  🛑 `.gitignore:77` excludes `images/*.iwi`, so it ships in the release but a **fresh clone will not
  have it**. Their call whether to force-add.

## 6. OUTSTANDING DECISIONS

1. 🛑 **The published release `v1.99.21` cannot start a map.** Still downloadable. Not touched.
2. The title-screen `.iwi` is not in git (above).
3. Queue **7** (GAME-tab 4-perk toggle) is superseded by **22**; flagged, not merged.

---

## 7. CHECKPOINT + RELEASE — done 2026-08-17

On the user's *"checkpoint and release"*:

- **Tag `v1.99.29`** (annotated) created and pushed with the session's commits. `origin/main` level
  with local, 0 unpushed. Previous tag `v1.99.22`.
- **Release published:** https://github.com/DavidHiFi/zm_qol/releases/tag/v1.99.29 — **Latest**, not
  a draft, not a prerelease, asset `state=uploaded`.
- **Asset:** `zm_qol-v1.99.29.zip`, 137,530,469 bytes (131.2 MB). Top-level folder `zm_qol/`,
  entry count verified as **6**, sourced from the deployed folder after a 6/6 SHA256 check, and
  🛑 `cmn_root.all.sabl` confirmed **absent**.
- **README truth pass in the same round:** "27 toggles" → **29** (counted 9 + 13 + 7, not
  estimated), and the perk line no longer claims "no perk limit" now that PERK LIMIT is selectable.
  Compass, the switchable instant PaP and the six new commands added. The ⚠️ WORK IN PROGRESS notice
  is still at README.md:7 and opens the release notes; the GitHub description still opens with
  `WORK IN PROGRESS` and remains accurate.
- **The notes say plainly what is and is not tested:** PERK LIMIT and the lobby layout are confirmed
  in game; the crash fix, chat commands, INSTANT PAP and COMPASS are built and byte-verified but
  unplayed.

🛑 **v1.99.21 is still published and still cannot start a map.** No longer Latest, and both v1.99.22
and v1.99.29 open by telling people to replace it — but it remains downloadable. Untouched, because
changing a published release is outward-facing and is the user's call. §6 item 1.
