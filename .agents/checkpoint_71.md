# Checkpoint 71 — v1.99.31. The INSTANT PAP switch actually switches, and the SOUND tab gets four packs.

Written 2026-08-17. **Supersedes 70 for status.**

---

## 0. STATE

| # | item | state |
|---|---|---|
| 1 | **INSTANT PAP is a live switch** (v1.99.30) | 🔴 built, byte-verified deployed, **unbooted** |
| 2 | **SOUND tab: HIT / KILL / CRITS / DOWNED packs** (v1.99.31) | 🔴 built, aliases + payloads verified inside `mod.ff` / `mod.all.sabl`, **unbooted** |
| 3 | LUI `beingAnimation` crash fix (v1.99.24) | 🟡 **the 25-minute TranZit session at 16:36 today ended in a clean `ShutdownGame:` with no `COM_ERROR`** — but nothing proves the jet gun was overheated in it, so the fix is still unconfirmed |
| 4 | Six chat commands · COMPASS (v1.99.25/26) | 🟢 the user reports the HUD-tab toggles behave; `.p .pack .reload .infammo .ghost .round .giveperks .god .help` all appear in `games_mp.log` |
| 5 | Queue 16 (jet gun weapon slot) · 18 (its ammo counter) | 🔴 not built |

🛑 **Still outstanding, unchanged from 70:** overheat the jet gun on TranZit and keep holding
through the cooldown. That is the one crash test.

---

## 1. THE INSTANT PAP BUG — the switch had nothing to switch back to

User, 2026-08-17: *"i set instant pap to disabled here in the game tab, pack a punched a weapon and
it still had instant pap … so if players want to use the default pack a punch where you have to put
it in the machine (stock game) they can choose between that or instant pap"*.

`new_pap_trigger()` opened by killing stock outright:

```gsc
level notify( "Pack_A_Punch_off" );   level thread pap_off();
```

`maps\mp\zombies\_zm_perks::vending_weapon_upgrade()` carries `level endon( "Pack_A_Punch_off" )` on
its **first line**, so that notify ends stock's Pack-a-Punch thread for the match, and `pap_off()`
re-killed it every time power came back. Nothing was left to hand the machine back to, so the dvar
could only ever be read once, at map load — which is exactly what the note in `init()` claimed was
unavoidable.

**The note was wrong on two of its three points**, and measuring settled both:

- `level.zombiemode_reusing_pack_a_punch` is read at USE time (`_zm_weapons.gsc:1771/1797/1814`,
  `_zm_perks.gsc:653/691/700`) — and 🌟 **every retail map sets it to 1 itself**: `zm_transit.gsc:286`,
  `zm_buried:254`, `zm_highrise:164`, `zm_prison:101`, `zm_nuked:109`, `zm_tomb:167`. The mod's copy
  never changed anything on a stock map.
- `setup_pap_attachments()` skips weapons that already have a list, so it is idempotent and safe to
  run at any moment.

Only the machine takeover was real.

## 2. WHAT SHIPPED — one trigger standing at a time

Stock's thread now stays **alive** and parks on `self waittill( "trigger", player )`, which cannot
fire while its trigger is sunk. `qol_pap_mode_watch()` polls the dvar at 2 Hz and hands the machine
over.

🌟 **This is not new ground and that is why it was chosen.** TranZit **survival** has always run this
exact arrangement — the old code deliberately skipped the kill for `zm_transit`/`zstandard`, and
instant PaP works there. v1.99.30 applies the shipped, working case to every map.

Three things the watcher gets right, each from a checkable failure:

| | |
|---|---|
| **state-based, not edge-based** | it compares the switch against what the triggers ACTUALLY are. On TranZit **classic** stock calls `self trigger_on()` the moment the PaP is built, within a second of this thread's own setup — an edge-based watcher would leave both triggers standing. |
| **raises only what it sank** (`level.qol_pap_sank_stock`) | a blind `trigger_on()` would open Pack-a-Punch on TranZit classic *before the machine is built*, because stock keeps that trigger off until then. |
| **never switches mid-upgrade** | `trigger_on/off` (`realorigin`) and `enable/disable_trigger` (`.disabled`) BOTH move a trigger 10000 units, through different fields. Switching while stock has its trigger sunk would make `trigger_off()` record the sunken origin as `realorigin`, and the next `trigger_on()` would restore it underground — dead for the match. Guarded on `level.qol_pap_busy`, `flag( "pack_machine_in_use" )` and `.disabled`. |

🛑 **One deliberate exception.** `_zm_perks::init()` reaches `if ( vending_triggers.size < 1 ) return;`
**before** its `array_thread( …, ::vending_weapon_upgrade )`, so on the custom survival locations
(Origins ×4, Die Rise ×3, Docks, Diner, Tunnel, Power) stock's Pack-a-Punch thread was never started
and the mod's trigger is the only Pack-a-Punch those locations have ever had. The switch stays on
instant there — `zmqol_restore_perk_bottles_on_survival()` now records
`level.qol_pap_stock_missing`. Turning it off would otherwise leave the location with no machine.

📝 **A stock behaviour returns with stock's thread: the Pack-a-Punch keeps its
`zmb_perks_packa_loop` hum.** The `Pack_A_Punch_off` notify used to reach stock's
`shutoffpapsounds()` and silence the machine for the rest of the match.

## 3. THE SOUND PACKS

22 aliases, all renamed **`zmqol_*`**, audio under `sound\zmqol\`, rows appended to
`soundbank\mod.all.aliases.additions.csv`. 🛑 The audio is imported from `TechnoOps-Collection`
**with the user's explicit authorisation**, overriding `AI_CONTEXT.md` rule 7 for these files —
recorded because it is a standing rule being set aside.

| dvar | 0 | 1..n |
|---|---|---|
| `hit_sound` | DEFAULT = `mpl_hit_alert`, what the mod always played | 1–8 packs, 9 = NO SOUND |
| `kill_sound` | same | 1–8 packs, 9 = NO SOUND |
| `crit_sound` | NO SOUND | 1 BO7, 2 MW |
| `downed_sound` | NO SOUND | 1 BO4, 2 CW, 3 MW |

1..8 keep the donor's own numbering so the two orders cannot drift. **Every default is 0**, so a
player who never opens the menu hears exactly what the mod played before.

- **Crit = stock's own `_zm_utility::is_headshot()`**, or a melee kill — not a re-invented test.
- **Downed plays for every player** (squad alert), with a 1 s cooldown because `_zm_laststand`
  raises `player_downed` a second time at line 228 when the player had perks, and
  `entering_last_stand` fires on the same event.
- 🛑 **Row budget: the four rows are IN-GAME ONLY.** SOUND is 9 rows + 2 spacers = 10 pitches in
  game, 11 out of it (SYSTEM TEST is out-of-game only), against the proven 14.5 ceiling.
  10 + 0.5 + 4 = **14.5 exactly**; 11 + 4.5 = 15.5 would collide with the ESC prompt — the precise
  fault the user reported against the v1.94.0 menu. The pause menu is where they were asked for.
- 📝 The hit/kill/crit sounds ride the **HITMARKERS** funnel (`updatedamagefeedback`), so switching
  HITMARKERS off on the HUD tab silences them too. That is the pre-existing behaviour of
  `mpl_hit_alert`, not new.

### Build verification (all offline, all done)

- `build_ff.bat`: **0 errors**, the same 34 baseline sound warnings.
- `mod.all.sabl` **62,646,912 → 64,546,416** (+1,899,504 ≈ the 22 `.wav` payloads).
- `Unlinker --include-assets soundbank` on the built `mod.ff`: **2,358 rows, all 22 present**, up
  from 2,336 with none lost. (The `.wav.wav` in the dump is the Unlinker's own extra extension.)
- All 6 files SHA256-match the deployed folder; the new GSC symbols are inside the deployed
  `mod.iwd` and the four rows are in the deployed `optionssettings.lua`.

## 4. WHAT IS STILL UNKNOWN — read before the next hand-off

1. **Nothing here has been played.** Both features are built and verified as *files*.
2. The sound packs' remaining risk is entirely runtime: **a missing or unplayable alias is silent,
   never an error.** If a pack is chosen and nothing plays, the alias table is not the suspect (it
   is verified) — the payload format is.
3. The instant-PaP watcher has never run against a real machine. First thing to watch: switch it off
   at the machine and confirm the **stock** prompt appears and the gun goes in.
