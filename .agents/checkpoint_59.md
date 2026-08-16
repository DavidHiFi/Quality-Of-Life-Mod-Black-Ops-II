# Checkpoint 59 — v1.99.10. v1.99.9 reverted; the Winter's Howl "wind" is named and removed.

Written 2026-08-16. **Supersedes 58 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.10 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Who's Who description | 🟡 built v1.98.0, never booted |
| 2 | Wunderfizz random first location (B-WF) | 🟡 built v1.97.0, never booted — needs a **multi-machine** map |
| 3 | **Riser sound** (B-RISERSOUND) | 🔴 **re-reported by the user on the v1.99.9 boot.** Still open, still at the payload-bytes step. §3 |
| 4 | **Winter's Howl fx** (B-WHOWL) | 🟡 flash confirmed ✅; v1.99.9 reverted; the wind removed in v1.99.10, **unbooted**. §1–§2 |
| 5 | Titus-6 reload (B-TITUSRELOAD) | 🔴 a bank job, not started — checkpoint 58 §3 has the full spec |
| 6 | Who's Who screen fx (B-WHOSWHO2) | 🔴 leading theory disproven in 57; night mode is the suspect |
| 7–14 | `mod.ff` stale script · `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers, the bleedout bar **and its live mid-down toggle**, and the **Winter's
Howl muzzle flash**.

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
Fire the Winter's Howl. **Two questions: is the frost burst back, and is the lingering cloud gone?**

---

## 1. 🛑 B-WHOWL — I REMOVED THE WRONG ELEMENT, AND THE REASONING THAT LED THERE IS THE LESSON

User, on the v1.99.9 boot: *"you got rid of the right effects for shots for the winters howl and the
incorrect wind blow effects are still there, so you got rid of the wrong effect and kept the wrong
one in."*

`wraith_looping_def0` (`gfx_fxt_fx_distortion_heat`) is **part of the correct shot fx**. Reverted to
`spawnLooping 50 3` / `spawnOneShot 50 3` in both view files. Both now differ from the reference port
by exactly **12 lines** — the six v1.99.7 `drawWithViewModel` flags, nothing else. That is the state
the user approved.

📝 **The boot is trustworthy, and that was checked rather than assumed:** `console_zm.log:4540` prints
`Loaded fx: weapon/muzzleflashes/fx_freezegun_view` on that session, and the deployed `mod.iwd`
carried `spawnLooping 0 0`. The edit did not corrupt the file — the change really was tested.

### 🌟 THE STANDING LESSON: "the only visible element" is not "the element they mean"

Checkpoint 56 argued: def0 is 2 lines off the Thundergun's element, and it was the only element
flagged `drawWithViewModel` before v1.99.7, so it was the only thing visible when the flash was
missing — therefore it is the "weird wind". **Every premise is true and the conclusion is false.**
Being the only visible thing explains why they saw *something*; it never identified *what*. The same
evidence fit equally well with def0 being a correct-but-lonely piece of the flash, which is what it
was. A block diff proves shared ancestry, never that the element is unwanted — the user's own verdict
on def0 proves a Thundergun-derived element can be exactly what they want.

---

## 2. ✅ THE WIND, NAMED — and the audit the user asked for came back clean

Their instruction was *"make sure the winters howl is using only its effects not other weapons' fx."*
That audit was run in full and **found no foreign fx**: the weapon defs reference only
`fx_freezegun_*view`; the GSC's nine `level._effect` entries are all `freeze_gun/` or
`maps/zombie/fx_zombie_freeze_*`; the CSC loads but never plays the cloud; the Thundergun's own fire
hook is correctly gated on `thundergun_zm`; and `fx_trail_freezegun_ring_emit` / `_geotail` are
zone-declared but referenced by nothing. So the wind had to be one of the gun's own elements.

Exactly two things spawn on a shot — `fx_freezegun_view` (8 live elements) and
`fx_freezegun_smoke_cloud`. Instead of spending a boot on an isolation probe, all three plausible
candidates were **described from their own measured parameters** and the user picked. They chose the
**big soft cloud that lingers**:

| | `fx_freezegun_smoke_cloud` |
|---|---|
| what | 10 × `gfx_fxt_smk_spiral`, size **400**, life **1000 ms** |
| where | world space at the player, **every shot**, `_zm_weap_freezegun.gsc:151` |
| scale | 4× larger and 10× longer-lived than anything in the muzzle flash |
| origin | structurally the Thundergun's smoke cloud scaled down — same 3 materials, same flags, same lifespans; only counts/sizes/curves differ (400 vs 1200, 10 vs 25) |

Rejected, for the record: `wraith_looping_def1` (`gfx_fxt_lensflare_diamond` — the *other* Thundergun
near-copy, a static muzzle glint) and `wraith_looping_def2` (`gfx_fxt_smk_whisp_spiral`, 40 fast
forward streaks, 500 ms — the gun's own).

**The change:** three lines commented at `_zm_weap_freezegun.gsc:149-151` with a one-step restore
note; `loadfx` left in place.

🛑 **PARITY NOTE.** All three freezegun ports in the workspace play this cloud and the file is
freezegun-tuned rather than a raw copy, so it is very likely authentic T5 content —
[[zm-qol-port-never-tune]] would normally forbid removing it. It goes because the user identified it
specifically. One uncommented line restores it. **If they later miss it, that is the fix.**

📝 **Asking beat probing here.** The ambiguity was *perceptual*, not technical — no file could say
which effect a person is looking at. Three options described in plain visual terms, measured out of
the `.efx`, settled in seconds what a probe would have cost a boot. [[prefers-evidence-over-questions]]
still holds: the descriptions came from measurement, and the question was only asked once the
offline audit had narrowed the field to three.

### Pre-mortem, checked offline

1. **Something else draws the cloud** — one play site across every `.gsc`/`.csc`. ✅
2. **The edit never reaches the game** — 🛑 `_zm_weap_freezegun.gsc` **is** zone-declared
   (`mod_wonderweapons.zone:150`) and the `zone_assets` copy **already differs** (it lacks the
   v1.93.0 boss-hit hook). `console_zm.log:1299` reads `(raw (source))` and the boss-hit feature
   works in game, so the raw copy wins and `build.bat` alone is right. The `.csc` loads
   `from fastfile` — remember that asymmetry. ✅
3. **Removing it degrades the gun** — no gameplay role; flash, impact, shatter, crumple and damage fx
   all untouched. ✅

---

## 3. B-RISERSOUND — re-reported, unchanged, and deliberately not touched this round

The user reported the riser sound again with this boot's screenshot. Nothing has changed since
checkpoint 58 §2: `zmb_zombie_spawn` is silent played 2D at point blank while a matched control from
the same bank is audible. It was left alone on purpose — B-WHOWL was the item in flight and
[[zm-qol-one-at-a-time]] applies.

▶️ **NEXT for it, unchanged:** extract `dirt_00` / `dirt_01` from `zmb_common.all.sabl` with the audio
dumper, check length and format against `powerup\grab\grab_00` from the same bank. If the entry is
empty or malformed, ship the sound in `mod.all` under a **mod-private** alias.

---

## 4. WHAT THIS SESSION CHANGED

| version | change | state |
|---|---|---|
| 1.99.10 | Winter's Howl — v1.99.9 reverted (def0 restored) **and** `fx_freezegun_smoke_cloud` no longer played on fire | 🟡 **unbooted** |

Plus: the README known-issues row for the Winter's Howl rewritten — it still carried the disproven
def0 theory, and [[zm-qol-docs-must-be-accurate]] makes that part of the change, not a follow-up.
