# Checkpoint 64 — v1.99.18. Origins boot crash fixed, invisible corpse fixed, and the red screen was an EXPOSURE problem.

Written 2026-08-16. **Supersedes 63 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.18 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | ~~Tac-45~~ · ~~Winter's Howl fx~~ · ~~Riser sound~~ | ✅ **CONFIRMED IN GAME AND CLOSED.** 🛑 Do not re-open. |
| 2 | **Origins boot crash** | 🟡 **my regression, v1.99.17.** Root-caused to a 33rd `scriptmover` bit, fixed, **unbooted.** §1 |
| 3 | **Who's Who — invisible corpse** | 🟡 **my regression, v1.99.17.** Forced model, never precached. Fixed, **unbooted.** §2 |
| 4 | **Who's Who — no red screen** | 🟡 root-caused to night mode's EXPOSURE, not the colour. Fixed, **unbooted.** §3 |
| 5 | **Who's Who — clone glow** | 🟡 unchanged mechanism, now precached so it can actually draw. TranZit only. §2 |
| 6 | **`mod.ff` stale server scripts** | 🔴 next in line after Who's Who closes. Evidence in checkpoint 63 §3. |
| 7 | Who's Who description | 🟡 built v1.98.0, never booted |
| 8 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 9 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 10 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 11–17 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 WHAT TO CHECK ON THE NEXT BOOT
1. **Origins loads at all.** That is the whole test for §1.
2. On **TranZit / Diner**, go down with Who's Who and look for, in order:
   a. the screen going **bright red** as the ghost stands up,
   b. **a body on the ground** where you fell,
   c. that body **glowing orange**.
   `.wwfx` toggles the screen effect without going down — quickest way to test (a) alone.

---

## 1. ORIGINS — A 33rd `scriptmover` BIT, AND THE BUDGET WAS DUMPABLE ALL ALONG

`Trying to assign 1 bits for netfield zone_captured but Client Field Set scriptmover is out of space.`

v1.99.17 registered `zmqol_whoswho_clone_glow` on every Who's Who map. Counted from
`Black Ops 2 Grand Resources\...\Clientfields\`, field by field:

| mode | stock `scriptmover` | this mod adds | total |
|---|---|---|---|
| `zm_tomb` zclassic_tomb | **32** (19 fields) | 0 | 32/32 |
| `zm_tomb` survival | 25 | **7** (`element_glow_fx` 4 + `bryce_cake` 2 + `switch_spark` 1, re-registered for client/server parity) | 32/32 |

Both were already **exactly full**. One more bit is fatal at load.

**Fix:** one predicate, `zmqol_whoswho_clone_glow_enabled()` — `zm_transit` only — asked by the
server registration, the precache, the model watcher **and** the `.csc` twin. Nothing is lost: the
glow needs the `_g` materials and those exist for the Victis crew alone.

📝 Origins' `actor` set is 31 stock + this mod's 1 = **32/32**. Still true, still no margin left.

## 2. THE INVISIBLE CORPSE — DECLARED IS NOT PRECACHED

v1.99.17 set `self.whos_who_shader` to Die Rise's `_dlc1_fb` models and **never precached them**.
`zm_highrise.gsc:673-676` precaches all four before it ever assigns that var.

🌟 **Declaring a model in `mod.ff`'s zone makes it LOADABLE. Only `precachemodel()` makes it
USABLE.** `setmodel()` with an unprecached model draws nothing and logs nothing — which is exactly
what the user saw: revive prompt, revive icon, revive trigger, no body.

Everything else about the transplant was verified good before concluding this:
`Unlinker --list` on the **deployed** `mod.ff` shows all four xmodels, their `_g` materials, their
images and the two techsets those materials use (`mc_sw4_3d_char_skin_outline_*`,
`mc_sw4_3d_char_cloth_outline_*`); a GLB dump of `c_zom_player_reporter_dlc1_fb` out of `mod.ff` has
full geometry at all four LODs; and every `dlczm*.ipak` is mounted at startup, so the pixels are
there on every map.

🟡 **Still true and still the user's call:** on TranZit the clone wears the **Die Rise outfit**,
because that is the only glow-capable version of these four characters in the game.

## 3. 🌟 THE RED SCREEN WAS NEVER A COLOUR PROBLEM — IT WAS EXPOSURE

**(a) v1.99.17's third state could never fire, and the log says so** — not one
`[zm_qol] whoswho overlay: LAST STAND` line across two full downs on Diner.

With Who's Who **the player never enters last stand at all**. `_zm.gsc:4239`:

```
if ( self.lives > 0 && self hasperk( "specialty_finalstand" ) )
{
    self.lives--;
    if ( isdefined( level.chugabud_laststand_func ) )
    {
        self thread [[ level.chugabud_laststand_func ]]();
        return 0;                       <-- before player_laststand()
    }
}
```

So `visionsetlaststand( "zombie_last_stand", 1 )` (`_zm.gsc:2022`) never runs and
`player_is_in_laststand()` is never true. The three seconds on the floor are
`chugabud_fake_death()` — a freeze, not a last stand. Stock has **one** grade here. Two states again,
and the dead `zombie_last_stand` block is deleted.

**(b) The remaining grade WAS landing.** Screenshots are measurable — mean channel over every
non-black pixel:

| | R | G | B | R/G |
|---|---|---|---|---|
| Die Rise, the real thing | 90.1 | 43.8 | 34.1 | **2.06** |
| ours | 32.7 | 28.9 | 31.0 | 1.13 |

Ours is not just less red, it is **2.7× darker overall**. Night mode sets `r_exposureTweak 1` +
`r_exposureValue 3.9`, and every EV stop halves the picture — about **1/15 brightness**. That crushes
the whole image into the shadow end, where this vision file is near-neutral; `vc_HMR`'s 7.15× red
boost lives in the **highlight** matrix and there were no highlights left to boost.

🌟 **A colour grade cannot colour light that is not there.** The faint 1.13 tilt in the measurement
is the 23 values working correctly on a black picture.

**Fix:** drop `r_exposureTweak` for the duration of the effect and restore night mode's own value on
the way out. `qol_opt_night_on()` stashes it as `self.qol_night_exposure` so the per-map exposure
table stays in exactly one place.

🟡 **Expect the world to get brighter for the ~30s of the ghost state while night mode is on.** That
is inherent — Die Rise's Who's Who is a bright blowout and cannot read at 1/15 brightness — but the
user should be told rather than surprised.

## 4. THE AUTHENTIC PATH, AND WHY IT IS STILL NOT USED

Worth recording, because it looks like the obvious "do it properly" move and it carries a real risk.

The client registers the `zm_whos_who` visionset in **`zm_highrise.csc:86` and nowhere else**, so off
Die Rise `vsmgr_activate()` on the server points at a slot the client does not have. Registering it
client-side would fix that — **but** `_visionset_mgr::finalize_type_clientfields()` assigns slot
indices from a *sorted list of every registered visionset* and derives `visionset_slot`'s bit width
from its size. Both sides must end up with the same list, not merely the same count, and the two
sides register different sets on survival locations. That is the Vulture `overlay_lerp` failure
shape. The `vc_*` route cannot desync anything, and it is proven to reach the renderer.

## 5. METHOD NOTES WORTH KEEPING

- 🌟 **Measure the screenshot.** Two `GetPixel` sweeps turned "there's no red" into "the grade is
  fine and the picture is 2.7× too dark", which is a different bug with a different fix.
- 🌟 **A stock function's `return` is as load-bearing as its calls.** One `return 0` at `_zm.gsc:4239`
  invalidated a whole feature built the round before.
- 🌟 **`precachemodel` is not implied by anything.** Not by the zone file, not by `--list`, not by a
  clean link. Grep the owning map for what it precaches before transplanting an asset.
- **Copy the log before reading it, and grep it before theorising** — the missing `LAST STAND` line
  settled §3(a) in one command.
