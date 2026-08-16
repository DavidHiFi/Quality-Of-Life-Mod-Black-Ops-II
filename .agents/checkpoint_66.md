# Checkpoint 66 — v1.99.20. The grade is applied directly now, and a wrong inference from checkpoint 65 is corrected.

Written 2026-08-16. **Supersedes 65 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.20 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | ~~Tac-45~~ · ~~Winter's Howl fx~~ · ~~Riser sound~~ · ~~Origins boot crash~~ · ~~invisible corpse~~ · ~~clone glow~~ | ✅ **CONFIRMED AND CLOSED.** 🛑 Do not re-open. |
| 2 | **Who's Who — the red screen grade** | 🟡 **fourth attempt.** Now applied directly, and instrumented on both sides. **Unbooted.** §1–§3 |
| 3 | **`mod.ff` stale server scripts** | 🔴 **next in line** once §2 closes. Evidence in checkpoint 63 §3. |
| 4 | Who's Who description | 🟡 built v1.98.0, never booted |
| 5 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 6 | Kill-feed icons | 🟡 fixed v1.99.14, unbooted |
| 7 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 8–14 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 THE NEXT BOOT
TranZit / Diner, type **`.wwfx`** — the screen should go red at once, `.wwfx` again clears it.
Whatever happens, the log now answers the open question by itself. Grep for `whoswho`:

```
[zm_qol] whoswho visionset: registered, slot_index N, total visionsets M          <- server
[zm_qol] CLIENT whoswho visionset: registered, slot_index N, total visionsets M   <- client
[zm_qol] CLIENT whoswho: vision -> zm_whos_who (was '...')                        <- the apply
```

- **Both slot/total lines identical** → the manager was fine and the fault is elsewhere.
- **They differ, or the CLIENT line says NOT REGISTERED** → §2 was the bug, confirmed.
- **No `CLIENT whoswho: vision ->` line at all** → the filter clientfield never reached the client,
  which is a different and much narrower problem.

---

## 1. WHAT v1.99.19 ESTABLISHED

Its own probe did the work:

```
[zm_qol] whoswho visionset: registered, slot_index 3, total visionsets 4
```

and the session's dvar dump records **`night_mode "0"`** throughout. So:

- the server registered the visionset and picked a slot ✅
- night mode was not overriding the renderer ✅
- `activate_chugabud_effects_and_audio()` ran (the overlay ON line printed, the clone glow printed) ✅
- **and the screen did not change.**

That leaves the **routing between server and client**. Measured, the screenshot went from R/G 1.13 to
1.37 and mean brightness 32.7 → 51.8 against the reference's R/G 2.06 / R 90.1 — brighter, because
night mode was off, but still nothing like the grade.

## 2. 🛑 CORRECTING CHECKPOINT 65: "IT BOOTS, SO BOTH SIDES AGREE" IS FALSE

Checkpoint 65 §1 claimed the map booting **proves** server and client registered the same visionsets,
because `finalize_type_clientfields()` derives `visionset_slot`'s width from the count. That is wrong,
and it is wrong in exactly the range this map sits in:

| visionsets | `getminbitcountfornum( n-1 )` |
|---|---|
| 2 | 1 |
| **3** | **2** |
| **4** | **2** |
| 5–8 | 3 |

**3 and 4 are both 2 bits.** A client one registration short produces no width mismatch, no error, a
clean boot — and the server then sends **slot 3** to a client whose `sorted_name_keys` stops at index
2. `get_info()` returns undefined and nothing is applied, silently, forever.

And the client has its own silent drop: `_visionset_mgr.csc::validate_info()` returns **false** when
`version > getserverhighestclientfieldversion()`, and `vsmgr_register_visionset_info()` throws that
`false` away without a word. (Measured on this map, the highest stock clientfield version is 12000 and
we register at 5000, so *that* gate passes here — but it is a live trap on any map whose highest
version is lower.)

🌟 **The lesson is about the inference, not the API.** "No error" is not evidence of agreement unless
you have checked that disagreement would have produced an error. I asserted the stronger claim from
the weaker fact, and it cost a boot.

## 3. THE FIX — APPLY THE VISION FILE DIRECTLY

`visionsetnaked( localclientnum, name, transition )` applies a `.vision` to a local client with no
slot table involved. It is not a workaround around Treyarch's system — **it is what that system ends
up calling** (`_visionset_mgr.csc:375`, and `visionsetnakedlerp` in `visionset_update_cb`), and the
save/restore shape is stock's own from `clientscripts\mp\_proximity_grenade.csc:170-199`:

```
saved = getvisionsetnaked( localclientnum );
visionsetnaked( localclientnum, "zm_whos_who", 0.5 );
...
visionsetnaked( localclientnum, saved, 0.5 );     // fallback getdvar("mapname")
```

Same asset, same engine call, one less thing between them.

**It runs from `zmqol_whoswho_filter()`, and that is the correct home rather than a convenient one:**
stock writes `clientfield_whos_who_filter` and activates the visionset from the **same four
consecutive lines** of `activate_chugabud_effects_and_audio()` (:753-760), so the filter going on *is*
the visionset going on — they cannot drift apart. The audio sibling of those same lines is confirmed
working in game, which is the evidence that the callback fires.

📝 The grade is applied **before** `enable_filter_afterlife()`, so a fault in the filter (which
depends on `level.filter_matid`, set up by a separate thread) cannot block the thing the user is
waiting on. The two effects are independent, so the order between them is free.

### Verified before hand-off
`vision/zm_whos_who.vision` inside the **deployed** `mod.ff` is byte-identical to `zm_highrise.ff`'s
copy (`diff`, not eyeballed). The `.csc` linked `(src: disk)`. Six files hash-identical source ↔
Plutonium. `visionsetnaked` present in the shipped `.csc`. `gsc-tool` parsed both files.

## 4. METHOD NOTES WORTH KEEPING

- 🌟 **Print from BOTH sides.** Client `println` reaches `console_zm.log` — proven by the mod's own
  `[zm_qol] CLIENT ...` lines. A server-only probe answered half a question and left the other half to
  inference, which is where this went wrong.
- 🌟 **Check that the failure would have been loud before treating silence as proof.** The whole
  §2 error is one step of that check, skipped.
- 🌟 **When a stock subsystem's bookkeeping is the suspect, call the thing it calls.** The engine
  primitive underneath a manager is usually public, and using it keeps the real asset.
- **Ship instruments that split the remaining possibilities**, not just a fix — three log lines now
  distinguish "manager desync", "callback never fired" and "vision file not applied".
