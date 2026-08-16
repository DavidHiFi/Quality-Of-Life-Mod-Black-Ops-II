# Checkpoint 58 — v1.99.9. The Winter's Howl flash is CONFIRMED. The riser bug is answered. And a verdict of mine was retracted.

Written 2026-08-16. **Supersedes 57 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.9 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Who's Who description | 🟡 built v1.98.0, never booted |
| 2 | Wunderfizz random first location (B-WF) | 🟡 built v1.97.0, never booted — needs a **multi-machine** map |
| 3 | **Riser sound** (B-RISERSOUND) | 🔴 **ANSWERED, not fixed** — the alias produces no audio. §2 |
| 4 | **Winter's Howl fx** (B-WHOWL) | 🟢 **flash CONFIRMED IN GAME**; the wind removed in v1.99.9, unbooted. §1 |
| 5 | **Titus-6 reload** (B-TITUSRELOAD) | 🔴 **my "impossible" verdict RETRACTED** — it is a bank job. §3 |
| 6 | Who's Who screen fx (B-WHOSWHO2) | 🔴 leading theory disproven in checkpoint 57; night mode is the suspect |
| 7–14 | `mod.ff` stale script · `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

🛑 **The queue was renumbered again** — the user removed eight items (old 1, 2, 4, 10, 13, 14, 18,
22). `QUEUE_LIST.md`'s Closed section carries the old→new map **and three resurfacing warnings**,
the most important being that **old 13 was the Origins/Mob crash and removing the line did not fix
it**.

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, power-up timers, the bleedout bar **and its live mid-down toggle**, and now **the Winter's
Howl muzzle flash**.

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
Fire the Winter's Howl. **Is the wind gone with the frost burst still intact?** That is all.

---

## 1. 🌟 B-WHOWL — THE MECHANISM IS PROVEN, AND THE SECOND HALF WAS MEASURED THE SAME WAY

**v1.99.7 worked.** *"the winters howl now has the correct shot fx"*, with a screenshot. So
`drawWithViewModel` **is** the gate for a `viewFlashEffect` element — checkpoint 56 shipped that as a
correlation across three guns plus a mechanism, explicitly flagged as unconfirmed from a stock file.
The boot confirmed it. 📝 **Worth keeping as a pattern: the experiment WAS the fix, so one boot both
settled the question and delivered the feature.**

The user then reported the wind was still there and was the Thundergun's effect. They were right, and
it took a diff of the two element blocks to show it:

| | |
|---|---|
| `fx_freezegun_view.efx` `wraith_looping_def0` | 195 lines |
| `fx_thundergun_view.efx` `wraith_looping_def1` | 195 lines |
| **differing lines** | **2** — `sizeGraph0` / `sizeGraph1`, `100` vs `600` |

Same material (`gfx_fxt_fx_distortion_heat`), same 50 particles, same ranges, same lifetime. It is
the Thundergun's element scaled down. **Control for the method:** the same diff against the
freezegun's own `light_flare_star` element gives **73** differing lines, so it is not matching
everything.

**v1.99.9** sets `spawnLooping 0 0` / `spawnOneShot 0 0` on that element in both view files — the
file's own idiom for a dead element (`wraith_oneshot_def1/2/3` already ship that way). −2 bytes each;
11 elements, braces 428/428, LF, `drawWithViewModel` still ×7. Reversible by restoring `50 3`.

🟡 **Left alone, deliberately, for the user's call:** `wraith_looping_def1`
(`gfx_fxt_lensflare_diamond`) is **also** a near-copy of the thundergun's — 195 lines, **3**
differing. Not disabled, because it is a small glint that reads as part of the flash they just
approved and they named the *wind*. Removing more than was reported risks degrading a good result.

---

## 2. 🌟 B-RISERSOUND — `.testsound` DID ITS JOB. The alias produces no audio.

All three plays are in the log, so the instrument worked end to end:

```
[zm_qol] TESTSOUND 1/3  2D       'zmb_zombie_spawn'
[zm_qol] TESTSOUND 2/3  3D@you   'zmb_zombie_spawn'
[zm_qol] TESTSOUND 3/3  CONTROL  'zmb_powerup_grabbed'
```

User: *"i heard some other effect entirely unrelated to the dirt sort of sound."* — the **control**,
and only the control.

🌟 **So `zmb_zombie_spawn` is silent played 2D at point blank with no distance model at all, while a
matched alias from the same bank, same bus, same `Storage` and the same payload `.sabl` is audible in
the same second.** Wiring, origin, distance curve and mix are all eliminated. The fault is
alias→payload resolution itself.

📝 The riser origin probe fired again at **dist=324** — closer than the 513 that already killed the
origin theory. Dead twice.

📝 **The control is what made this readable.** A bare "does this alias play" probe would have returned
"I heard nothing" and settled nothing. Matching the control on bank, bus, Storage, DistMin and
payload `.sabl` is what turned one boot into a verdict.

▶️ **NEXT — the payload bytes.** Both hashes sit in `zmb_common.all.sabl`'s index, so the *entry*
exists; whether the data behind it is real is unverified. Extract `dirt_00` / `dirt_01` with the
audio dumper, check length and format, compare against `powerup\grab\grab_00` from the same bank. If
the entry is empty or malformed, ship the sound in `mod.all` under a **mod-private** alias and play
that instead of the stock name.

---

## 3. 🛑 B-TITUSRELOAD — I WAS WRONG, AND THE MISTAKE WAS ONE THIS PROJECT HAD ALREADY WRITTEN DOWN

I told the user the Titus-6 reload audio *cannot* be added. They pushed back — *"that's bullcrap, my
friend Synarxis has it in his mod, fully working"* — and they are right.

**The error:** I searched the audio dumper's identifier files for payload **paths containing
`titus`**, found four, and concluded the audio does not exist. **A payload's filename says nothing
about which alias uses it** — and this project's own riser entry says exactly that, because
`zmb_zombie_spawn` resolves to `spawn\dirt\dirt_00` with no "riser" anywhere in the path. I recorded
that lesson and repeated the mistake a day later.

**What is true**, measured against `BO2-Reimagined\soundbank\mod.all.aliases.csv`: Reimagined defines
**16** `*titus*` aliases, two of which are exactly this pattern — `fly_titus_slide_back` and
`fly_titus_slide_forward` both point at the **toggle-flip** payloads. Treyarch does the same: every
`wpn_titus_*_pap` row points at the shared `raw\sound\wpn\pap\pap_shot_st`.

🌟 **Mapping a missing alias onto an existing stock payload is Treyarch's convention and Reimagined's
— not a lookalike.** [[t6-soundbank-facts]] already said so about the `_pap` family.

**What IS solid from that round, and is the useful half:** the reload audio comes from the
animations' `sndnt#` notetracks, extracted from the xanims in `mod.ff`:

| animation | `sndnt#` notetracks |
|---|---|
| `viewmodel_titus_mk_reload` | `fly_tar21_futz`, `fly_tar21_mag_in`, `fly_tar21_mag_out` |
| `viewmodel_titus_mk_reload_empty` | `fly_titus_bolt_back`, `_bolt_release`, `_futz`, `_mag_in`, `_mag_out` |
| `viewmodel_titus_gl_reload_empty` | the same five **plus** `fly_titus_tap` |

Of those nine, only `fly_tar21_mag_in` / `_mag_out` resolve today. 📝 The masterkey reload asking for
**TAR-21** sounds is Treyarch's own copy-paste inside the animation, not a porting error.

▶️ **THE JOB, its own round:** define the seven missing aliases in
`soundbank\mod.all.aliases.additions.csv` against suitable stock payloads, take the **transitive
closure over the `Secondary` column** ([[t6-soundbank-facts]] — 51 aliases became 100 last time),
then `build_ff.bat` → `build.bat`. **The same pass must cover the box pickup/raise sound** the user
also reported, and audit every ported weapon for the same class of gap.

---

## 4. WHAT THIS SESSION CHANGED, in order

| version | change | state |
|---|---|---|
| 1.99.7 | Winter's Howl muzzle flash — `drawWithViewModel` on the six live elements | ✅ **confirmed in game** |
| 1.99.8 | `.testsound` (client dvar + chat), B-RISERSOUND instrument | ✅ **ran, answered** |
| 1.99.9 | Winter's Howl — the Thundergun's distortion element disabled | 🟡 **unbooted** |

Plus: eight queue items removed and renumbered, with resurfacing warnings recorded in the file; the
Who's Who filter-collision theory disproven from stock source (checkpoint 57 §equivalent, and in
`QUEUE.md`); and two memories written — queue auto-removal, and the raw-`.efx` facts.

## 5. THE STANDING LESSON FROM THIS SESSION

**Two verdicts of mine were overturned by the user, both because a search did not cover where the
answer lived** — the Titus payload search, and (earlier) the `--list | head` that hid a `soundbank`
row. `CLAUDE.md` §2 corollary 3 is the rule and it keeps being the rule: *"not found" is a lead,
never a verdict.* Before saying something is impossible, say instead which search would prove it and
whether that search was actually run.
