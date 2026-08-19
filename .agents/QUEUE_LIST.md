# QUEUE_LIST.md — the queue
**This is the list `/queue` prints.** One flat numbered list, in the order the items were set.
`QUEUE.md` stays the long write-up with the evidence; this is only the index.
**A ~~struck-through~~ line is FINISHED** — the user confirmed it in game — and is not being worked
on. Everything not struck through is still open. Nothing else is marked, on purpose: the user asked
(2026-08-16) for a plain list with no other differentiation.
When the user says an item is **resolved and can come off the list**, delete its line, renumber the
rest, and move it to *Closed* at the bottom of this file — never lose it, just stop printing it.
- SYNCED TO: checkpoint **84** · mod version **1.99.81**
- LAST VERIFIED: 2026-08-18 — **twenty-one items were removed across two passes this day** and the
  list renumbered twice, 29 → 19 → 8. Both passes are recorded in full at the bottom with old
  numbers, per-item detail and the old→new maps. Nothing was lost; the list stops printing them.
- ✅ **v1.99.72 ACCEPTED BY THE USER 2026-08-19** - all Vulture Aid marker icons; see the Vulture Aid entry in *Closed*.
- **BUILT, AWAITING THE USER’S BOOT: v1.99.81** - a `>level.ipak_read,zm_qol_hd` probe in `mod.zone` (a deliberately missing ipak, so the engine logs every directory it will accept an ipak from) plus ONE pack texture (Speed Cola, 4096²) in the player's global `images\` folder with the rank-2 duplicate parked. Those two answer the last unmeasured question in item 34. See checkpoint 84 §4. 🛑 **The v1.99.79 `<decimal ipak name-hash>` theory is DISPROVEN** - checkpoint 84 §2. `mod.iwd` still carries its 119 dead hash-named files (416 MB), awaiting the user's OK to delete.
- **HISTORIC: v1.99.80** - the texture pack shipped as **119 `<decimal ipak name-hash>.iwi`** files plus 2 by name (item 34); booted, did nothing. 🛑 **v1.99.78 fixed a LOAD-TIME CRASH** - `is_headshot` / `get_base_weapon_name` had lost their backslashes in the v1.99.75 BETTER DEADSHOT probe, so no map could start. The v1.99.76 search-order probe was **deleted in v1.99.80**: its target `xenonbutton_a` is itself an ipak image, so a by-name file could never have overridden it and the probe could not answer anything.
- **v1.99.75** - AIM ASSIST moved directly under TARGET ASSIST, plus TWO print-only probes. ✅ **BETTER DEADSHOT IS CONFIRMED WORKING BY THE USER 2026-08-19** — *"it does more damage when set to enabled"*. It is DONE; the v1.99.75 probe for it can come out. 🛑 **The Deadshot head lock-on is still NOT WORKING** and its probe is still unread — needs a controller, Deadshot bought, ~10 headshots, then the `deadshot cf:` lines. See checkpoint 82 §3 - do not change it before reading those lines.
- 🛑 **IN FLIGHT: item 34.** The source folder is now **131 files** (the user added 10 reticles on 2026-08-19). **129 of the 131 are inside a stock `.ipak`**, and that is the whole problem: measured this session, a fastfile carries **no image pixels at all** (192-byte fastfile for a 4 MB texture, from disk or from stock), loose `.iwi` reach the renderer **only for images in no ipak** (the mod's own Thundergun/Wunderwaffe skins prove it), and every mod-side placement — `mod.iwd` by name, `mod.iwd` by hash, rank-2 `storage\t6\mods\zm_qol\images\`, rank-6 `<BO2>\mods\zm_qol\images\` — has now been booted and does nothing. 🌟 **Rank 6 is worth remembering**: Plutonium puts `<BO2>\mods\<modname>` on the search path whether or not it exists, and it is the only mod-shipped placement that sits BELOW the player's own `images\` folder — exactly the user's requirement, and worthless only because the ipak beats it too. **One cell remains unmeasured** (an ipak texture at rank 4, in a match) and the user has asked that impossibility not be declared until it is. Checkpoint 84. Vulture Aid (old items 24 and 25) was closed by the user 2026-08-19: *"im ok with the state of vulture aid so close any tasks related to it, everything works fine."*
- ✅ **v1.99.54 PARTS A+B CONFIRMED IN GAME 2026-08-18** (user screenshot). Item 1 is now Part C only: INTRO CREDITS → HUD as FLASH INTRO CREDITS, plus a new FLASH HELP DISCLAIMER pop-up.
- ✅ **v1.99.55 CONFIRMED 2026-08-18** — *"the sound effects seem to be no longer chopping/cutting out for brief moments any more"*. 🛑 One good session is not proof of a mechanism: say "not reproduced since the merge", not "fixed".
- The list is **34 items** (5 struck through). Item 34 was added 2026-08-19 (the 121-file upscaled texture pack). Items 24-33 were all added 2026-08-19 (they were 26-35 before Vulture Aid was closed): 24-26 from the Nuketown test report, 27-29 from the friend's screen-share, 30-32 from the Strat Tester comparison, 33 from the gamepad-menu request. 🛑 **Item 18, the M14, is OPEN even though the user asked for it to be crossed off** - it did not ship; the reason is assets, not registration. See the v1.99.60 note in QUEUE.md.
- 🛑 Three things survive their closed parent items and are **the user's call, not to-dos**:
  Who's Who on **Origins** (43 absent assets, checkpoint 75 §3), the Titus's `fly_titus_futz` /
  `fly_tar21_futz` (defined in no bank in the game), and the freezegun's non-lethal hit marker
  (measured firing on 5 of 6 paths; the 6th was never exercised).

### v1.99.61 — 2026-08-18, deployed unbooted
Five of the day's seven requests. **Item 3 is folded into the perk-bonus rewrite** (Mob's Electric
Cherry now pays, so item 3 can close with it once booted).
- **3 + 19** prone perk bonus rewritten off `zombie_vending`; PERK BONUS POINTS row added
- **1 (Part C)** FLASH CREDITS moved to HUD, FLASH HELP added
- **20** Deadshot controller aim — driven off `perk_dead_shot`, zero new clientfield bits
- **22** scoreboard CDC/CIA emblem
- **23** Nuketown sunken drop pad, raised to z -66.16 (measured from mapents)

🛑 **21 (Carpenter) IS NOT FIXED AND WAS NOT ATTEMPTED.** No mechanism found: the mod does not
`replaceFunc` `_zm_powerups::init`, `start_carpenter`, `start_carpenter_new` or
`_zm_blockers::replace_chunk`, does not touch `level.use_new_carpenter_func`, and does not touch
`level.board_repair_distance_squared` (562500 = 750 units). Stock's own `repair_far_boards()` snaps
every barrier further than 750 units from a player with NO animation, by design. Needs from the
user: which map, and roughly how far the barriers were.
<!-- LIST -->
1. **Intro Credits → HUD tab as FLASH INTRO CREDITS, plus a new FLASH HELP DISCLAIMER** pop-up
   pointing at `.help` — this is Part C of the graphics-options request; **Parts A and B are DONE and
   CONFIRMED in game 2026-08-18** (v1.99.54, screenshot: ADVANCED shows Night Mode / Fog / Higher
   Draw Distance and Depth Of Field reaches DISABLED)
2. ~~**Map-aware character picker in the pre-game lobby**~~ — CONFIRMED in game 2026-08-18 on every crew and survival (v1.99.58 + the v1.99.59 should_use_cia fix); the non-default cross added v1.99.60
3. **Prone at Mob's Electric Cherry machine gives no +100**
4. **Death Machine pickup voice line** — the BO1 announcer callout
5. ~~**Drop `deathmachine_zm.all.sabl`**~~ — done v1.99.55, merged into `mod.all`, deployed unbooted
6. **Jet gun in a real weapon slot**, and it never breaks
7. **Jet gun gets the Paralyzer's cooldown** so it cannot be fired forever
8. **Ammo counter for the jet gun** in the bottom right
9. ~~**Death Machine fire sound skips**~~ — not reproduced since the v1.99.55 bank merge (user, 2026-08-18)
10. **Winter's Howl freeze/ice fx fire only sometimes** — make them behave exactly like BO1's
11. **ANIMATED CAMO PATCH toggle** on the GAME tab — the three `anim_pap_camo_*` dvars already exist
12. **Animated camos on all maps** incl. survival — 🛑 mechanism not yet understood, may not be possible
13. **Custom animated camos from `plutonium/t6/images` are ignored**, and a cycle between them and the
    mod's own — strong lead: `mod.ff` owns 154 camo images
14. **Death Machine ammo counter shows on Buried / Mob / Origins** — those three ship their own ammo
    widget with a weapon-based hide path that ignores the hide bit; `hideAmmo`'s source still unknown
15. **Dragunov (campaign)** into the box — 🛑 confirm first whether the already-shipped `svu_zm` is
    the same weapon under another name
16. **MM1 grenade launcher (campaign)** into the box — search the workspace mods for an existing port
17. **Bouncing Betties (multiplayer)** into the box — 🛑 NOT the M16 case, it is the M14 case. There
    is **no `bouncingbetty_zm`** anywhere in the T6 zombies scripts (only `bouncingbetty_mp`), the mod
    ships no def, and `mod.ff` declares no such weapon. Needs an asset port PLUS lethal-slot work,
    because it is equipment and not a gun
18. **M14 into the box** — 🛑 STILL OPEN. The user believed this shipped with the Olympia/M1911 on
    2026-08-18; it did not, and they were told so at the time. Unlike those three this is an ASSET
    job: `grep -E '^weapon,' zone_source\mod_base.zone` has no `m14_zm` row and there is no m14
    xmodel or xanim anywhere in it, so the def and its animation set must be dumped from a stock
    fastfile and shipped in `mod.ff` first. Registration alone cannot work.
19. **PERK BONUS POINTS toggle** on the GAME tab (user, 2026-08-18) — enabled/disabled. ON = +100 per
    machine from proning; OFF = **no prone points at all**, including Origins' stock 25 (the native
    "loose change" easter egg must be suppressed too, not just left at 25)
20. **Deadshot head aim-assist is dead on controller** — 🛑 **THE FIX ALREADY SHIPPED, IN v1.99.61, AND THIS ENTRY WAS STALE.** `zm_expanded.csc::zmqol_deadshot_perk_callback()` is registered on the ALREADY-PAID-FOR `perk_dead_shot` clientfield and makes stock's `usealternateaimparams()` call, so the bit-budget worry below never applied and no bit was spent. Live via `replaceFunc(...perks_register_clientfield)`. **Still unverified in game** - it needs a gamepad, so the user cannot test it alone. Original report: (user's friend, gamepad, 2026-08-18) — it locks
    to the upper torso instead of the head. 🛑 CAUSE ALREADY MEASURED: `init_client_flags()` in
    `quality_of_life.gsc` sets `level.disable_deadshot_clientfield = 1` on **every** map (stock sets it
    only on Buried), so the `deadshot_perk` clientfield never registers and
    `_zm.csc::player_deadshot_perk_handler`'s `usealternateaimparams()` never runs. Restoring it costs
    1 toplayer bit per map — **Mob of the Dead's budget must be measured before it goes back**
21. **Carpenter power-up snaps the barriers up** instead of playing the stock rebuild animation
    (user's friend, 2026-08-18) — must be bit-for-bit stock behaviour
22. **Scoreboard shows the CDC emblem while playing as CIA** on Nuketown (user screenshot
    `Q00Mg0zQSi.jpg`, 2026-08-18) — the v1.99.58 character picker sets the model but not whatever the
    scoreboard reads. Must be correct for both CDC and CIA
23. **A Nuketown perk drop location is sunk into the ground** (user screenshot `TNl6kvDWyc.jpg`,
    2026-08-18) — Mule Kick, on the rock slope near the crater, player at x 1511 y 889 z -60
24. **Power-up announcer voice lines are missing** — 🛑 **RE-REPORTED 2026-08-19 and NARROWED to exactly two: Blood Money and Zombie Blood.** Every stock power-up announces correctly, so the shared announcer path is ruled out (checkpoint 81 §3). The v1.99.70 probe returned `stock_maxammo_0=1 qol_zblood=1 qol_bmoney=1` — **`soundexists()` is TRUE for the mod's aliases**, so the rows shipped and the engine sees them by name. That leaves the payload or the play routing, not registration. Original report: (user, 2026-08-19, Nuketown survival) — no
    Samantha callout on pickup: they named Zombie Blood and Blood Money, and said the same for
    "other typical power-up drops". 🛑 **DISCRIMINATOR NEEDED BEFORE ANY BUILD:** were the STOCK
    power-ups (Max Ammo / Insta-Kill / Double Points / Nuke / Carpenter) silent too, or only the
    mod's three? The two answers lead to completely different work — see QUEUE.md.
    Overlaps item 4 (Death Machine pickup voice line), which is the same path.
25. **CUSTOM POWER-UPS toggle on the GAME tab** (user, 2026-08-19) — ON = the mod's added drops
    (Zombie Blood, Blood Money, Death Machine); OFF = stock power-up table only. 🛑 **Origins keeps
    Zombie Blood either way** — it is that map's stock drop, so OFF must mean "vanilla for this
    map", not "no Zombie Blood anywhere". Dvar name must be chosen once and never renamed.
26. **Switching to another mod while zm_qol is loaded freezes the game** (user screenshot, 2026-08-19)
    — the Load Mod? prompt accepts, the screen holds, then goes fully black with the zombies menu
    music still playing. 🌟 **MEASURED:** `console_zm.log` ends on the literal last line
    `Unloading fastfile mod`, immediately after Plutonium had already rebuilt the search path for
    `mods/zm_technoopscollection`. So the hang is in the unload of zm_qol's own `mod.ff`, not in the
    other mod's load. Prime suspect is the asset-ownership trap: `mod.ff` owns materials/images that
    the frontend still has resolved. Not yet designed.
27. **Pause menu: RESTART GAME** (user, 2026-08-19, friend's screenshot) — wanted as the **second**
    option, under RESUME GAME. 🌟 **IT IS ALREADY STOCK AND THE SCREENSHOT PROVES WHY IT IS MISSING** —
    see QUEUE.md. No new asset needed: the string `MENU_RESTART_LEVEL_CAPS` and the action
    `openRestartGamePopup` both already exist. The work is one LUI override.
28. **Pause menu: INSTANT EXIT** (user, 2026-08-19) — under the existing END GAME, straight to the
    lobby with no game-over music and no scoreboard. Same effect as the `disconnect` console command
    the user already has bound. END GAME must stay exactly as it is.
29. **Pause menu: QUIT TO DESKTOP** (user, 2026-08-19) — runs the `quit` console command, closes the
    game instantly.
30. **BOX LIMITS toggle on the GAME tab** (user, 2026-08-19) — ON = vanilla box limits; OFF = the
    no-limits behaviour (both Ray Guns at once, duplicates, per-player). 🌟 **THE FEATURE IS ALREADY
    SHIPPED AND ALWAYS-ON** — `maps\mp\zombies\_zm_magicbox.gsc:24` prints *"_zm_magicbox override
    ACTIVE (double_weapons + no_limits)"*. So this is a gate on existing code, not a new feature.
    The work is the OFF path: the override fully shadows stock, so disabled must reproduce stock's
    own `treasure_chest_canplayerreceiveweapon` / `limited_weapon_below_quota`, both of which are in
    the gsc-dump.
31. **TP DESTINATION + EXECUTE TELEPORT on the CHEATS tab** (user, 2026-08-19, from Strat Tester) —
    a left/right destination selector plus an execute row. 🛑 **THE DESTINATIONS ARE HAND-AUTHORED
    PER MAP AND NUKETOWN HAS NONE** — see QUEUE.md. Mechanism itself is trivial (`setOrigin` +
    `setPlayerAngles`); the work is the coordinate table, and `.where` already prints what is needed.
32. **CHANGE ROUND, KILL HORDE and END ROUND on the CHEATS tab** (user, 2026-08-19, from Strat
    Tester) — three rows. Mechanism is short and readable; the traps are the magic-bullet-shield
    skip, Die Rise's negative-health zombies, and re-deriving the spawn rate after a round jump.
    All three are in QUEUE.md.
33. **Split TARGET ASSIST into two rows on CONTROLS > GAMEPAD** — ✅ **ROW SHIPPED v1.99.74 (`aim_assist`), after the user reaffirmed the request having been shown the evidence below.** It drives `disableaimassist()` on zombies, which is the only script-reachable aim-assist lever, so it can switch assist OFF independently of TARGET ASSIST but cannot switch it ON when TARGET ASSIST is off. 🛑 **VERIFYING IT NEEDS A GAMEPAD** - the user plays mouse and keyboard and cannot see the effect themselves. 🛑 **THE ORIGINAL GOAL IS STILL NOT MET AND WAS NEVER REACHABLE THIS WAY:** The retail build registers only **9** `aim_*` dvars (`aim_accel_turnrate_*`, `aim_input_graph_*`, `aim_scale_view_axis`, `aim_turnrate_*`) - read straight out of the user's own `console_zm.log` dvar dump, 3080 total dvars. `aim_lockon_enabled`, `aim_slowdown_enabled`, `aim_autoaim_enabled`, `aim_automelee_enabled` and the whole `aim_alternate_lockon_*` block are STRINGS IN `t6zm.exe` BUT NOT REGISTERED DVARS, so a second menu row would have nothing to write to. `input_targetAssist` is a PROFILE var (no `input_*` dvar appears in the dump at all) and is the single retail switch. `enableaimassist()`/`disableaimassist()` are per-TARGET-ENTITY calls (stock uses them on zombies, the Ghost, the quadrotor), not a player-side switch. 📝 **The v1.99.73 BETTER DEADSHOT toggle addresses the actual goal from the other side** - it makes the perk worth buying with target assist off and on mouse and keyboard alike. ⚠️ One caveat kept honest: the dvar dump was taken in a MOUSE-AND-KEYBOARD session; if those dvars are registered lazily when a controller is connected, this verdict changes. A gamepad session's log settles it. Original request: (user, 2026-08-19) — so Deadshot
    Daiquiri's head lock-on does not depend on general aim assist being switched on. 🌟 **T6
    ALREADY SEPARATES THEM AT THE ENGINE LEVEL** — grepped out of `t6zm.exe`'s string table:
    `aim_lockon_enabled`, `aim_slowdown_enabled`, `aim_autoaim_enabled` and `aim_automelee_enabled`
    are four independent switches, and there is a whole `aim_alternate_lockon_*` parameter set
    (`_strength`, `_pitch_strength`, `_region_height`, `_region_width`, `_deflection`) which is what
    Deadshot's `usealternateaimparams()` swaps to. So the split is real, not invented.
    🛑 **FIRST CHECK, BEFORE ANY BUILD: does `usealternateaimparams()` actually need
    `input_targetAssist` on?** The request assumes it does. If the alternate params ride on
    `aim_lockon_enabled` rather than the profile var, the menu row is not the blocker and the whole
    design changes. 🛑 Also note "so Deadshot works as vanilla" is not quite right: in vanilla BO2
    Deadshot is equally dead with target assist off, because it redirects aim assist rather than
    creating it. Decoupling is an improvement ON vanilla, not a restoration of it — worth confirming
    with the user that this is what they want.
    📝 Depends on item 20 — the head lock-on is currently dead on every map anyway
    (`level.disable_deadshot_clientfield = 1`), so 20 must land first or this cannot be tested.
34. **Ship the 121 upscaled `.iwi` textures WITH the mod, but let a player's own
    `storage\t6\images\` copies win by filename** (user, 2026-08-19) — *"i simply want my mod to
    come with the .iwi textures as apart of my mod ... but if someone who's using my mod has their
    own custom textures in the images folder for plutonium for the same .iwi filenames it uses
    their custom textures instead of mine."* Source folder: `H:\Claude\ship these to the images of
    my mod claude` — 121 files, **259 MB**, valid T6 IWIs (`IWi` + `0x1b`, DXT1/DXT5): scope
    overlays and reticles at 1024², loadscreens at 1024², perk icons at 64², vending-machine
    textures upscaled to **2048²** (16 MB each). **20 of the names are already declared in
    `mod.ff`** (`side_small`, 4 `mtl_t6_attach_optic_*`, 5 `scope_overlay_*`, 5
    `specialty_*_zombies`, `zombie_vending_marathon_n`, 4 `~-g`/`~~-g` vending images) — for those
    the header dimensions come from `mod.ff`, so a 2048² file read through a stock-size header
    renders garbage unless checked first.
    🛑 **MEASURED BLOCKER, from the user's own `console_zm.log` (`Current search path:` block,
    printed in priority order):** `storage\t6\mods\zm_qol\mod.iwd` is **rank 1** and the
    `storage\t6\` root that holds `images\` is **rank 4**. So anything the mod ships in
    `mod.iwd\images\` is found FIRST and beats the player's own copy — the exact forcing v1.93.0
    had to undo. Nothing the mod ships can rank below the player's folder: ranks 1-2 are the mod
    folder. The lowest-ranked writable slots are `storage\t6\main` (rank 8) and `<BO2>\mods\zm_qol`
    (rank 6), both of which ARE below the images folder — an optional add-on `.iwd` dropped there
    would behave exactly as asked, but is a manual install, not one of the 5 mod files.
    ⚠️ **ONE RESIDUAL HYPOTHESIS, being tested at v1.99.76:** Plutonium's own
    `images/{}.iwi` loader could special-case the images folder ahead of the file system, in which
    case the request works as stated. Probe shipped: `images\xenonbutton_a.iwi` in `mod.iwd` is a
    byte copy of the user's own `xenonbutton_y.iwi` (both 32×32 DXT5, `code_post_gfx_zm.ff` owns
    image+material for both). On a controller, a **Y** glyph where **A** belongs = mod.iwd wins and
    the request is impossible as stated; the user's own **A** glyph = the images folder wins and all
    121 can ship in `mod.iwd`. 🛑 **THE PROBE MUST BE DELETED EITHER WAY BEFORE ANY RELEASE.**

<!-- /LIST -->
---
## Closed — off the list, kept for the record
### Closed 2026-08-19 (Vulture Aid) — two, by the user's word
*"im ok with the state of vulture aid so close any tasks related to it, everything works fine."*

| old # | item | shipped as |
|---|---|---|
| **24** | Wunderfizz has no Vulture Aid see-through icon | v1.99.68 marker rewrite → v1.99.72 white/blue mystery-box `?` |
| **25** | Zombie eyes should glow brighter with Vulture Aid | stock `misc/fx_zombie_eye_vulture`, already live |

**Renumbering map (old → new):** 26→24 · 27→25 · 28→26 · 29→27 · 30→28 · 31→29 · 32→30 ·
33→31 · 34→32 · 35→33. Everything 1–23 is unchanged.

🛑 **COULD RESURFACE — what was closed WITHOUT a confirmed boot.** The user closed these while
**v1.99.72 was deployed and never reported as booted**. That version is where PhD Flopper's radiation
trefoil, Deadshot's reticle, the shared skull for Tombstone / Electric Cherry / Who's Who, and the
Wunderfizz `?` first actually *drew* — v1.99.71's icons never loaded at all (LF line endings in the
raw `.efx`; the engine only loads CRLF). So "everything works fine" may describe v1.99.71 or
v1.99.72. If a wrong or missing marker icon is ever reported again, **start here**, not from scratch.


### Closed 2026-08-18 (third pass) — one, confirmed in game
Old **2** of the 8-line list → the list is now 7, old 3-8 become 1-7 (old 1 keeps its number).
| old # | item | state when it was closed |
|---|---|---|
| 2 | **GAME-tab toggle for the backspeed fix** | shipped v1.99.51 and **confirmed by the user in game** — *"the option for backspeed works toggling it on or off"*. Renamed to **BACKSPEED PATCH** in v1.99.52 at their request, dvar still `move_speed`. |
🛑 **Can it resurface?** One thing to know, so it is not debugged from scratch later: the three
movement dvars (`player_backSpeedScale` / `player_strafeSpeedScale` /
`player_sprintStrafeSpeedScale`) now have exactly ONE writer, `qol_options::qol_opt_move_speed()`.
The old unconditional `setdvar` lines in `quality_of_life::init()`'s high_round_fix block are gone.
If backward movement ever feels wrong again, that watcher is the only place to look — and note that
`zmqol_minimal 1` (the Origins bisect switch) now skips it, so under minimal the speeds stay at
stock PC values instead of being forced to 1.
### Closed 2026-08-18 (second pass) — eleven more, by the user's instruction
*"get rid of 19, 18, 17, 16, 12, 10, 11, 5, 4, 1, 2. remove all those from the queue as they are
already dealt with or i no longer require their addition to the mod."*
🛑 **The user gave a combined reason for the batch, not per item, and none was inferred.** Some of
these are built and shipping, some were never started; which is which is recorded below as fact, but
**why each was dropped is not guessed at**. Old numbers are from the 19-line list.
| old # | item | state when it was dropped |
|---|---|---|
| 1 | **Who's Who description** — joke line removed | shipped v1.98.0; verified present in the deployed `mod.iwd` 2026-08-18, never booted |
| 2 | **Wunderfizz first location is random** by default | built, never booted |
| 4 | **Galvaknuckles wall-buy in Bus Depot's Tombstone room** | never started |
| 5 | **GAME-tab toggle for the 4-perk limit** | never started |
| 10 | **PhD Flopper's HUD icon may be missing** | never confirmed to be a defect — `Could not load material` appears for ~300 stock materials, so it may never have been one |
| 11 | **`fxanim_props` animtree re-registration warning** | pre-dates v1.99.21, symmetric on Origins; a warning, not a fault |
| 12 | **Kill-feed icons missing** for the ported weapons | fixed v1.99.14 — the nine `menu_mp_weapons_*` materials ship in `mod.ff`; never booted |
| 16 | **Compass** in the HUD tab | shipped v1.99.26, never booted |
| 17 | **Five-seven wall-buy removed from Origins** | shipped v1.99.39, never booted. 🛑 It is **stock Origins**, not something this mod added — removed anyway because that is what was asked |
| 18 | **BO4 MAX AMMO toggle** in the GAME tab | shipped v1.99.39, never booted; off is exact vanilla |
| 19 | **Hitmarker / crit feedback on the three BO1 wonder weapons** | fixed v1.99.47 and **measured working on 5 of 6 paths** from the log — thundergun hit+kill, tesla hit+kill, freezegun kill. The freezegun non-lethal hit was never exercised |
**Renumbering that came with it** — 19 lines to 8, no gaps:
`3→1` · `6→2` · `7→3` · `8→4` · `9→5` · `13→6` · `14→7` · `15→8`.
Old 1, 2, 4, 5, 10, 11, 12, 16, 17, 18 and 19 are gone.
### Closed 2026-08-18 (first pass) — every confirmed item, removed together
*"remove anything from the queue that is already completed and/or i've given confirmation that it's
ticked off the list because i confirmed it working."*
All ten were struck through **because the user confirmed them in game**; this pass only stops the
list printing them. Every one traces to a dated entry in `QUEUE.md`.
| old # | item | shipped | confirmed |
|---|---|---|---|
| 3 | **Titus-6 has no reload sound** — reload, empty reload, masterkey reload, and the first-raise cue when it leaves the box. Five aliases defined from the campaign's own `spl_monsoon.all` rows | v1.99.50 | 2026-08-18 *"all sound fx are working all 3 of them"* |
| 4 | **`mod.ff` ran a pre-merge copy of the mod's own script**, on every map | v1.99.22 | 2026-08-17, checkpoint 69 §6 — the 4 `replaceFunc` collision warnings gone |
| 15 | **Jet gun behaves as stock when built at the bench** | — | 2026-08-16 |
| 19 | **INSTANT PAP toggle** in the GAME tab | v1.99.30 | 2026-08-17 |
| 21 | **PERK LIMIT selector** in the pre-game lobby | v1.99.29 | 2026-08-17 |
| 23 | **Who's Who gives a Pack-a-Punched ballistic knife**, GAME-tab toggle | gun v1.99.39 · mid-down toggle v1.99.43 · revive v1.99.44 | 2026-08-18 *"that works exactly how i want it"* |
| 25 | **Awful Lawton bolts distract zombies** like a monkey bomb | v1.99.39 | 2026-08-18 *"works perfectly as expected"* |
| 26 | **The mod's own menu settings did not survive a restart** — every option row now marks its dvar archived as it is built | v1.99.45 | 2026-08-18, and by the config file itself carrying the user's own values as `seta` lines |
| 27 | **Hitmarker sounds far quieter than gunfire** — the feedback aliases were on the same compressed bus as gunfire; rerouted to stock's own hitmarker routing | v1.99.46 | 2026-08-18 *"it's good"* |
| 29 | **INSTANT NUKE toggle** in the GAME tab | v1.99.48 | 2026-08-18 *"works perfectly toggled it on or off"* |
**Renumbering that came with it** — 29 lines to 19, no gaps:
`1→1` · `2→2` · `5→3` · `6→4` · `7→5` · `8→6` · `9→7` · `10→8` · `11→9` · `12→10` · `13→11` ·
`14→12` · `16→13` · `17→14` · `18→15` · `20→16` · `22→17` · `24→18` · `28→19`.
Old 3, 4, 15, 19, 21, 23, 25, 26, 27 and 29 are gone.
📝 Two things that were part of these items and are **not** closed with them: Who's Who on **Origins**
(43 absent assets — the user's decision to make, checkpoint 75 §3), and `fly_titus_futz` /
`fly_tar21_futz`, which exist in no bank in the game and were offered and not taken.
### Closed 2026-08-17 — confirmed in game, then taken off the list
*"both the sounds & my custom menu texture i gave for you both work no problems at least not from
what i could tell. Cross them off the list."*
| old # | item |
|---|---|
| 19 | **Hitmarker hit/kill, downed and crits sound options** in the SOUND tab — shipped v1.99.31, made visible v1.99.32, spacing corrected v1.99.33. Confirmed in game at v1.99.38 |
📝 The **custom title-screen texture** (v1.99.35–38) was confirmed in the same message. It was never
a numbered line — it came in as a direct request — so there is nothing to remove for it.
**Renumbering that came with it:** `20→19` · `21→20` · `22→21`. Lines 1–18 did not move.
🛑 **This section is history, not a to-do.** These are not printed by `/queue` and are not to be
worked on, re-probed or "improved" unless the user asks for that item by name. Touching a closed
item is exactly the "don't touch it when you don't need to" the user asked to prevent.
### Closed 2026-08-16 — the user reviewed the list and called these resolved
They are either already in the mod and the user is satisfied, or no longer needed. The user did not
give a per-item reason and none was inferred; the old number is kept so older notes cross-read.
| old # | old ID | item |
|---|---|---|
| 7 | — | **Instant start** (49 §1) — the Linux half stays unverified, that is accepted |
| 20 | B-CROSSHAIR | **HUD-tab toggle for the crosshair** |
| 22 | B-ROUND | **Mob round 1: the round counter is missing** from the top right |
| 24 | §2.6 | **Vulture Aid icon missing from the Wunderfizz** perk icon set |
| 26 | §2.10 | **Nuketown perk-machine placement** — Deadshot's icon at an angle, Speed Cola sunk into the back-yard ground |
| 27 | §2.8a | **Solo: Origins' first-generator chest gives Zombie Blood** instead of double points, on the classic maps |
| 28 | §2.2 | **`night_mode 1` blacks the screen out** |
| 29 | — | **Diner buildable shield** (asked 2026-08-11) |
| 30 | — | **Frametime lag from the mod** (asked 2026-08-11) |
| 32 | — | **Vulture on Origins is a compromise** — the stink pile is invisible there |
| 34 | §2.12 | **`zm_refreshed` weapon ports** (MP7, Vector, Spas-12, MGL, Jetgun, Quick Revive on Mob…) — this also settles the standing question; the answer is **no** |
**Renumbering that came with it**, so older references still resolve:
`8→7` · `9→8` · `10→9` · `11→10` · `12→11` · `13→12` · `14→13` · `15→14` · `16→15` · `17→16` ·
`18→17` · `19→18` · `21→19` · `23→20` · `25→21` · `31→22` · `33→23`. Lines 1–6 did not move.
### Closed 2026-08-16 (later the same day) — confirmed in game, then taken off the list
| old # | old ID | item |
|---|---|---|
| 1 | — | **Power-up timers** — countdown above the power-up icons, Death Machine included. Confirmed in game at v1.99.3 (*"ok it works now"*); the user's own icon artwork shipped at v1.99.4. Struck through first, then removed on their instruction |
**Renumbering that came with it:** every line moved up by one —
`2→1` · `3→2` · `4→3` · `5→4` · `6→5` · `7→6` · `8→7` · `9→8` · `10→9` · `11→10` · `12→11` ·
`13→12` · `14→13` · `15→14` · `16→15` · `17→16` · `18→17` · `19→18` · `20→19` · `21→20` ·
`22→21` · `23→22`.
### Closed 2026-08-16 (fourth pass) — Who's Who, plus two that were confirmed earlier and never taken off
*"whos who is done remove it from the queue, it's fine as is im happy with it."*
| old # | item |
|---|---|
| 6 | **Who's Who has no screen fx on a down** — closed **by the user's decision**, v1.99.20. The log proves the grade is applied client-side (`CLIENT whoswho: vision -> zm_whos_who (was 'zm_transit')`); see checkpoint 67 for the one thing about it that is still unexplained and for the rest of the perk's audit, which is complete |
| 3 | **Zombie riser / dig-out sound** — confirmed in game at checkpoint 60 and never removed from the list |
| 4 | **Winter's Howl firing fx** — confirmed in game at checkpoint 63 (*"the fx are correct"*) and never removed from the list |
🛑 **3 and 4 were already closed in the checkpoints; this pass only corrects the list to match.** They
were not re-tested and must not be re-opened.
**Renumbering that came with it:**
`1→1` · `2→2` · `5→3` · `7→4` · `8→5` · `9→6` · `10→7` · `11→8` · `12→9` · `13→10` · `14→11`.
Old 3, 4 and 6 are gone.
📝 **Item 1, "Who's Who description", is deliberately still on the list.** It is a separate entry
about the perk's description text (built v1.98.0, never booted), not about the screen fx. Say the
word and it comes off too.
### Closed 2026-08-16 (third pass) — the user removed eight more
*"remove 1, 2, 4, 10, 13, 14, 18, 22 get rid of all these from the queue, it's dealt with and/or
uneeded right now"*.
| old # | old ID | item |
|---|---|---|
| 1 | — | **Bleedout bar toggle** — confirmed in game at v1.99.6 |
| 2 | — | **Origins Death Machine ammo counter** — ⚠️ built v1.99.0, **never booted** |
| 4 | — | **Wonder-weapon box odds reversed** (`zmqol_box_ww_rarity`) — ⚠️ built v1.98.0, **never booted** |
| 10 | B-VIEWMODEL | **Arms and gun vanish when a horde gets close** — Origins, round 100+ |
| 13 | — | 🛑 **Origins / Mob `EXE_ERR_RELIABLE_CYCLED_OUT` crash** — see the warning below |
| 14 | T4 | **Semtex wall-buy on Bus Depot survival** — never built |
| 18 | B-CONTROLS | **Three Plutonium rows missing from CONTROLS → LOOK** — not this mod's code |
| 22 | T5 | **T5 wonder weapons** — reverted at v1.56.x, work is in git and reappliable |
**Renumbering that came with it:** `3→1` · `5→2` · `6→3` · `7→4` · `8→5` · `9→6` · `11→7` ·
`12→8` · `15→9` · `16→10` · `17→11` · `19→12` · `20→13` · `21→14`.
🛑 **FLAGGED AT REMOVAL, as the user asked — these three can resurface:**
1. **Old 13 is a CRASH, and removing the line does not fix it.** Origins and Mob of the Dead can
   still `EXE_ERR_RELIABLE_CYCLED_OUT` roughly 20–35 s into a match. It is off the list, not solved.
   If a future session sees Origins or Mob die early, this is the first thing to read — checkpoint 48
   §2 and `ERROR_CATALOGUE` §7b, **not** a fresh investigation.
2. **Old 2 and old 4 were closed having NEVER RUN.** Both ship live code (`zmqol_box_ww_rarity`, the
   Origins Death Machine ammo counter). Closed means "stop asking about it", not "verified" — if
   either misbehaves later it will look like a brand-new bug.
3. **Old 10** is a real rendering fault at Origins round 100+, never investigated. It will still
   happen; it is simply no longer tracked.
---
## Bookkeeping — not printed by `/queue`
### IDs, by current number
Kept here instead of on the lines so the printed list stays clean.
🛑 **Rewritten 2026-08-17.** This block had never been put through the fourth-pass renumbering
(`1→1 · 2→2 · 5→3 · 7→4 · 8→5 · 9→6 · 10→7 · 11→8 · 12→9 · 13→10 · 14→11`), so every ID below it
pointed at the wrong line. Mapped through, with the three closed IDs (`B-RISERSOUND`, `B-WHOWL`,
`B-WHOSWHO2`) dropped:
`2` B-WF · `3` B-TITUSRELOAD · `4` B-STALEGSC · `5` B-CHARACTER · `6` T5 · `7` B-PERKLIMIT ·
`8` B-BACKSPEED · `9` B-CHERRY · `10` §2.9 · `11` B-DMBANK · `12` B-PHDICON · `13` B-ANIMTREE ·
`14` B-KILLFEED
Bugs filed twice under different IDs are ONE line. Current aliases:
`B-DIG` / `B-RISERSND` / `B-TOWN` = `B-RISERSOUND` · `B-WFHOWL` = `B-WHOWL` ·
`B-CDC` = `B-CHARACTER`.
### Extra detail, by current number
Short enough to stay out of the list, useful enough to keep somewhere:
- **Built and deployed, waiting on a boot:** 1 (v1.98.0) · 2 (v1.97.0) · 14 (v1.99.14).
- **2** — needs a map with more than one Wunderfizz location to show anything.
- **4** — confirmed in game 2026-08-17, checkpoint 69 §6: the 4 `replaceFunc` collision `WARNING`s
  are gone and `zm_expanded.gsc` is mentioned 0 times in the log, against 2 in every prior session.
  🛑 Removing that script broke **every** map until v1.99.22 repointed the one call still reaching
  into it — checkpoint 69 §1–§3.
- **6** — left wall as you come in the outside door.
- **11** — measured redundant 2026-08-16.
- **12** — `Could not load material "specialty_divetonuke_zombies"`, twice a session, in **every**
  session including before v1.99.21, so not a regression. ~300 stock materials log the same line, so
  it is **not yet proven to be a defect** — one look at the PhD Flopper icon in game settles it.
- **13** — `Warning - re-registration of animtree fxanim_props / fxanim_props_dlc4`, server and
  client. Pre-dates v1.99.21 (yesterday's Mob and TranZit logs carry it under v1.99.20). Origins'
  pair is symmetric, which is the safe shape; Mob logged the server half without the client half.
- **14** — fixed v1.99.14: the nine `menu_mp_weapons_*` materials ship only in `code_post_gfx_mp.ff`
  and `frontend.ff`, which no zombies map loads, so nine of them now ship in `mod.ff`. Never booted.
### How to keep this file honest
1. **Only the user booting the game finishes an item.** "Built", "deployed", "hash-verified" all
   mean **not done** — leave those lines unstruck.
2. When the user confirms an item in game → **strike its line through in place** (`~~like this~~`)
   and note the version in `QUEUE.md`. Do not renumber for a strikethrough.
   🛑 Strike the **text only**, leaving the number outside: `1. ~~item~~`, never `~~1. item~~` —
   the second form stops the line being a list item and markdown then renumbers everything below it.
3. When the user says an item is **resolved / no longer needed** → cut it from the list, renumber
   the rest, add it to *Closed* above with its old number, and record the renumbering map.
4. When the user asks for something new → **append it at the end** with the next number.
5. Every line traces to a user request in `QUEUE.md`, `TASKS_QUEUE_01.txt`, or a checkpoint. Do not
   invent lines and do not quietly drop them.
6. Bump `SYNCED TO` when a checkpoint is written or the version changes; re-verify before printing
   if it does not match.
