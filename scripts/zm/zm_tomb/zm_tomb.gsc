#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_tomb;
#include maps\mp\zm_tomb_utility;

main()
{
    // These hook Origins-only functions. Safe here because this map script only
    // loads on Origins (so the references resolve), and done in main() so they're
    // in place before the map threads the native code. Matches zm_highrise.gsc.
    replaceFunc( maps\mp\zm_tomb_dig::swap_weapon, ::custom_swap_weapon );            // weapon-dig fix
    replaceFunc( maps\mp\zm_tomb_ee_side::check_for_change, ::origins_change_patch ); // prone "loose change" -> 100
    replaceFunc( maps\mp\zm_tomb_utility::check_solo_status, ::qol_check_solo_status ); // 1 player = solo rules

    // ========================================================================
    //  v1.58.0 - STRIP ORIGINS' NATIVE WUNDERFIZZ. The mod's own machines take
    //  their place, so every map has the same machine. User, 2026-08-07:
    //  "get rid of the actual pre-existing wunderfizz machines from origins,
    //  and just put the custom ones that are already good and working."
    //
    //  Why the native ones had to go rather than be improved: the mod fed its
    //  perk list into stock's rotation, and stock's cycling code was never
    //  written for a list that size. The user got duplicate bottles for perks
    //  already owned (get_weighted_random_perk falls through to keys[0] once
    //  everything is owned) and bottles landing off to the left - which is
    //  stock's perk_bottle_motion() reading .origin off an entity that is
    //  still mid-moveto. wunderfizz.gsc ALREADY fixes that exact bug; see the
    //  comment block above its own perk_bottle_motion(). Replacing is
    //  therefore strictly less work than patching, and lands on code the user
    //  has already confirmed working on five other maps.
    //
    //  🛑 BOTH of these are suppressed, and NEITHER is _zm_perk_random::init().
    //  init() must keep running: it performs six registerclientfield calls,
    //  and the matching .csc registers the same six. Skip them server-side and
    //  the register lists diverge -> EXE_CLIENT_FIELD_MISMATCH drops every
    //  player at load. Only the MACHINE SETUP is suppressed.
    //
    //      init_machines()        builds the unitriggers (the buy prompt)
    //      start_random_machine() threads machines_setup + machine_selector
    //                             (the ball, the animtree, the relocation)
    //
    //  init_machines is reached as `level thread init_machines()` from init()
    //  - an unqualified same-file call, hookable BECAUSE it is threaded.
    //  start_random_machine is called qualified from stock zm_tomb.gsc:256.
    //  Both are registered here in main(), not init(), because both are
    //  threaded at map-init and a replaceFunc registered in init() would land
    //  after they had already run.
    // ========================================================================
    replaceFunc( maps\mp\zombies\_zm_perk_random::init_machines,        ::zmqol_tomb_no_native_wunderfizz );
    replaceFunc( maps\mp\zombies\_zm_perk_random::start_random_machine, ::zmqol_tomb_no_native_wunderfizz );

    //  v1.59.2 - MP40 wall-buys hand out the ADJUSTABLE STOCK version.
    //  THREADED, and it waits for the wall-buy stubs to exist - the v1.59.1
    //  version ran inline here and found zero structs. See the function.
    level thread zmqol_tomb_mp40_stalker_wallbuys();

    // --- custom survival start locations: Trenches, Excavation Site, Church, The Crazy Place ---

    // ========================================================================
    //  ORIGINS SURVIVAL - the zone-capture / generator system.
    //
    //  Fixes, reported on Trenches:
    //    - Speed Cola machine missing, with part of it still poking through the
    //      wall where the robot steps
    //    - mystery box refusing to open, demanding the generator be powered
    //    - starting a generator giving no capture progress ring, and spawning
    //      Templars as if it were classic Origins
    //    - dig sites visible where no shovel can be obtained
    //
    //  These are all one subsystem. Stock zm_tomb_capture_zones assumes classic
    //  Origins: perk machines and mystery boxes are OWNED by generator zones and
    //  gated behind capturing them. A standalone survival arena has no generator
    //  to capture, so the machine never finishes spawning and the box never
    //  unlocks.
    //
    //  BO2-Reimagined already solves this and its version is explicitly
    //  location-aware - it branches on ui_zm_mapstartlocation == trenches /
    //  excavation_site / church as well as is_classic(), so classic Origins keeps
    //  stock behaviour. That matters here: the standing instruction is to add the
    //  survival locations WITHOUT altering the base maps.
    //
    //  Ported verbatim to scripts\zm\replaced\zm_tomb_capture_zones.gsc. Its 21
    //  #includes are all stock maps\mp\ scripts, so it drags in no other
    //  Reimagined file, and all 18 hooked functions were verified present in the
    //  ported copy before wiring these up.
    // ========================================================================

    // 🛑 Dig sites appearing on survival, where no shovel can be obtained.
    // Reimagined's init_shovel returns early on !is_classic() before precaching
    // and placing the dig mounds, so the sites simply do not exist outside
    // classic Origins. Our copy has the two
    // scripts\zm\reimagined\_zm_weap_bouncingbetty calls stripped out of
    // swap_weapon (a function we do not hook - ::custom_swap_weapon above
    // replaces it): they are the file's only references to a Reimagined-only
    // script and would have been unresolved externals that killed the load.

    // 🛑 Giant robots walking through the survival arenas. Stock zm_tomb::main()
    // calls init_giant_robot() with no gametype guard at all, so all three robots
    // cycle across every survival location with shootable foot soles and enterable
    // head hatches. Our robot_cycling() returns immediately on !is_classic(), which
    // leaves them spawned but ghosted/inert. See the file header for why they are
    // still spawned rather than skipped outright (_zm_weap_beacon indexes them).

    // 🛑 Side easter eggs (one inch punch prompts, quadrotor medallions, the
    // wagon fire challenge, the wall poster, the light show) running on survival
    // arenas that can never reach the quest they belong to. The replacement keeps
    // the radio song and the loose-change perk-machine reward - see that file's
    // header for the full inventory and for why it MUST register light_show.
    // zm_tomb::main() does `level thread maps\mp\zm_tomb_ee_side::init()`, a
    // qualified threaded cross-file call, so this hook is the reliable kind.

    // Must run in main(), before the map registers its own clientfields.
    zmqol_register_survival_clientfields();
}

// ============================================================================
//  zmqol_register_survival_clientfields
//
//  🛑 Fixes a HARD CRASH on every non-classic Origins start location:
//        Clientfield 'element_glow_fx' in set [scriptmover] is not registered on the server
//        Clientfield 'switch_spark'    in set [scriptmover] is not registered on the server
//        COM_ERROR (3) Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  This is a latent asymmetry in STOCK Origins, not something the port introduced:
//    * the CLIENT registers these unconditionally -
//        element_glow_fx / bryce_cake / switch_spark  in clientscripts/mp/zm_tomb.csc:46-48
//        sndMudSlow                                   in clientscripts/mp/zm_tomb_amb.csc:203
//    * the SERVER only registers them inside
//        maps\mp\zm_tomb_craftables::register_clientfields()  (zm_tomb_craftables.gsc:364-377)
//      which is reached solely from maps\mp\zm_tomb_classic::main() -> init_craftables().
//
//  Stock Origins is zclassic-only, so that path always ran and nobody ever hit it.
//  The moment Origins is played as zstandard/zgrief, the craftables path is skipped,
//  the server registers nothing, client and server disagree, and the engine drops the
//  connection. Registering the same four fields here restores parity.
//
//  Guarded by is_classic() so zclassic still gets them from stock's craftables path -
//  registering the same field twice would itself be an error.
//
//  Verified against BO2-Reimagined, which fixes this identically in
//  scripts/zm/zm_tomb/zm_tomb_reimagined.gsc:191-202 (same four fields, same guard,
//  also called from the end of main()).
//
//  ---------------------------------------------------------------------------
//  2026-07-31: TWO MORE FIELDS, same root cause, different stock code path.
//
//  Crazy Place / zstandard still dropped with EXE_CLIENT_FIELD_MISMATCH:
//        Clientfield 'electric_cherry_reload_fx' in set [allplayers] is not registered on the server
//        Clientfield 'visionset_slot' in set[toplayer] not the same bit count : [CLIENT: 2 SERVER: 1]
//
//  The gate is maps\mp\zombies\_zm_perks::init() line 52:
//
//        vending_triggers = getentarray( "zombie_vending", "targetname" );
//        ...
//        if ( vending_triggers.size < 1 )
//            return;              <-- returns BEFORE the _custom_perks loop at 101-110
//
//  perk_machine_spawn_init() only spawns machines whose struct script_string
//  contains "<gametype>_perks_<location>". No Origins struct is tagged for the
//  survival locations, so zero "zombie_vending" triggers exist, _zm_perks::init()
//  bails at line 52, and the per-perk machine_thread loop never runs. Those threads
//  are the ONLY server-side callers of:
//        _zm_perk_electric_cherry::init_electric_cherry()  -> registers electric_cherry_reload_fx
//        _zm_perk_divetonuke::init_divetonuke()            -> registers the zm_perk_divetonuke visionset
//
//  The client has no such gate - _zm_perks.csc::init_perk_custom_threads() runs
//  every registered perk's init thread unconditionally - so the client registers
//  both and the server neither. The visionset count is what drives visionset_slot's
//  bit width (_visionset_mgr::finalize_type_clientfields ->
//  getminbitcountfornum( info.size - 1 )), which is why the second mismatch rides
//  along with the first:
//        server: default + zombie_blood                     = 2 -> 1 bit
//        client: default + zombie_blood + zm_perk_divetonuke = 3 -> 2 bits
//  Both log lines follow exactly.
//
//  Registering here restores parity. Safe against double-registration: if a perk
//  machine ever DID spawn on a survival location, _zm_perks::init() would not bail,
//  init_electric_cherry/init_divetonuke would run, and these two lines would become
//  duplicates - but that is also precisely the case where the mismatch would not
//  occur, so the guard to revisit is "did we add perk machines to a loc script?".
//
//  VERIFIED IN GAME 2026-07-31 (14:07 run, Excavation Site / zstandard): the four
//  original fields and electric_cherry_reload_fx are all absent from the mismatch
//  list. Only visionset_slot still mismatched, which is the split-out half below.
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "toplayer",    "sndMudSlow",      14000, 1, "int" );
    registerclientfield( "scriptmover", "element_glow_fx", 14000, 4, "int", undefined, 0 );
    registerclientfield( "scriptmover", "bryce_cake",      14000, 2, "int", undefined, 0 );
    registerclientfield( "scriptmover", "switch_spark",    14000, 1, "int", undefined, 0 );

    // Mirror of _zm_perk_electric_cherry::init_electric_cherry (stock signature).
    registerclientfield( "allplayers", "electric_cherry_reload_fx", 9000, 2, "int" );

    // The divetonuke visionset cannot be registered from here - see
    // zmqol_register_survival_visionset() below.
}

// ============================================================================
//  zmqol_register_survival_visionset
//
//  The second half of the fix above, split out because it CANNOT run in main().
//
//  2026-08-01: the 11:59 run proved the electric_cherry_reload_fx half worked -
//  that field is gone from the mismatch list - but Origins still dropped on:
//        Clientfield 'visionset_slot' in set[toplayer] is not registered with the
//        same bit count as the server : [CLIENT: 2  SERVER : 1]
//  i.e. the vsmgr_register_info call that used to sit at the end of
//  zmqol_register_survival_clientfields() never took.
//
//  Why: registerclientfield is a plain engine builtin with no state behind it,
//  so it works from main(). vsmgr_register_info is not - stock
//  maps\mp\_visionset_mgr.gsc:21-35 reads level.vsmgr[type] and asserts on
//  level.vsmgr_initializing, and BOTH are set up by _visionset_mgr::init(),
//  which runs out of _load::main() - AFTER this mod's main(). The call landed on
//  an undefined level.vsmgr and did nothing.
//
//  init() is inside the legal window: _visionset_mgr::init() has run by then, and
//  level.vsmgr_initializing is only cleared by finalize_clientfields(), which the
//  engine invokes later still via codecallback_finalizeinitialization ->
//  callback( "on_finalize_initialization" ) (_callbacksetup.gsc:19-21).
//
//  Guarded on isdefined so that if that ordering ever changes this degrades to
//  "visionset not registered" rather than a script error that takes out init().
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_register_survival_visionset()
{
    if ( is_classic() )
        return;

    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr["visionset"] ) )
        return;

    // Mirror of _zm_perk_divetonuke::init_divetonuke (stock args: version 9000,
    // priority 400, 5 lerp steps, activate_per_player 1).
    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 5, 1 );
}

init()
{
    level thread zmqol_hide_native_wunderfizz();
    level thread zmqol_probe_capture_zones();
    zmqol_register_survival_visionset();
    level thread zmqol_power_up_all_generators();
    level thread zmqol_disable_staff_relay_switches();
    level thread zmqol_remove_survival_ee_props();
    level thread zmqol_open_stock_barriers();
    level thread zmqol_wunderfizz_all_perks();
    added_weapons();
}

// ============================================================================
//  zmqol_wunderfizz_all_perks  -  the mod's perks, out of ORIGINS' OWN machines
//
//  User: "get rid of them keep the vanilla ones and just add all perks to the
//  machine like the other maps with the added machine... make sure that every map
//  with the real actual wunderfizz machine let's you get all 11 perks."
//
//  So the split on Origins is now: STOCK OWNS THE MACHINE, THE MOD OWNS WHAT
//  COMES OUT OF IT. The added machine is gone from wunderfizz.gsc; this puts the
//  extra perks into the rotation the map's own four machines already draw from.
//
//  level._random_perk_machine_perk_list is that rotation, and
//  _zm_perk_random::include_perk_in_random_rotation() is stock's own way to add to
//  it (_zm_perk_random.gsc:485) - so nothing here overrides a stock function or
//  reimplements one. get_weighted_random_perk() then skips whatever the player
//  already holds, exactly as before.
//
//  ⚠️ WHY THIS IS NOT ELEVEN ON ORIGINS. Vulture Aid cannot be enabled here at
//  all - Origins' ACTOR clientfield set has no room for vulture_perk_actor, which
//  is what made Classic Origins refuse to boot; see zmqol_vulture_enabled() in
//  quality_of_life.gsc. Every OTHER perk the mod can enable is added below, and
//  the purchase cap is no longer the thing standing in the way. Getting the
//  eleventh onto this map means freeing those two bits, which needs the client
//  script shipped as raw text instead of compiled bytecode.
//
//  🛑 This file is map-specific, which is the only reason the qualified reference
//  to _zm_perk_random is legal - that module ships in zm_tomb.ff and nowhere
//  else, so the same line in a root script would throw "Unresolved external" on
//  the other five maps. AI_CONTEXT rule 2.
// ============================================================================
zmqol_wunderfizz_all_perks()
{
    level waittill( "start_of_round" );
    wait 0.05;

    a_perks = scripts\zm\wunderfizz::getPerks();

    if ( !isdefined( a_perks ) || a_perks.size < 1 )
        return;

    if ( !isdefined( level._random_perk_machine_perk_list ) )
        level._random_perk_machine_perk_list = [];

    n_added = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        str_perk = a_perks[i];

        // Only perks the level actually registered - offering one the map never
        // set up hands out a bottle that does nothing, which is the half-dead
        // state Electric Cherry was in before v1.36.0.
        if ( !isdefined( level._custom_perks ) || !isdefined( level._custom_perks[ str_perk ] ) ||
             !isdefined( level._custom_perks[ str_perk ].player_thread_give ) )
        {
            if ( !zmqol_tomb_perk_is_stock( str_perk ) )
                continue;
        }

        if ( isinarray( level._random_perk_machine_perk_list, str_perk ) )
            continue;

        maps\mp\zombies\_zm_perk_random::include_perk_in_random_rotation( str_perk );
        n_added++;
    }

    println( "[zm_qol] origins: added " + n_added + " perk(s) to the native Wunderfizz rotation, list is now " + level._random_perk_machine_perk_list.size );

    //  And make a repeat impossible - see zmqol_tomb_perk_weights() below.
    if ( isdefined( level.custom_random_perk_weights ) && !isdefined( level.zmqol_tomb_weights_prev ) )
    {
        level.zmqol_tomb_weights_prev = level.custom_random_perk_weights;
        level.custom_random_perk_weights = ::zmqol_tomb_perk_weights;
    }
}

// ============================================================================
//  zmqol_tomb_perk_weights  -  never hand out a perk the player already holds
//
//  User: "when i got to mule kick and spun the machine again i got mule kick
//  again when i already had it, spun it a 3rd time and got mule kick again."
//
//  🛑 STOCK HAS EXACTLY ONE PATH THAT CAN RETURN A HELD PERK, and it is the last
//  line of get_weighted_random_perk() (_zm_perk_random.gsc:516):
//
//      for ( i = 0; i < keys.size; i++ )
//          if ( player hasperk( list[keys[i]] ) ) continue;
//          else return list[keys[i]];
//
//      return list[keys[0]];          <- the fallback
//
//  The loop is correct and skips everything you hold. The fallback underneath it
//  returns keys[0] unconditionally - it is stock's "you already own everything,
//  have something anyway" case. Whatever is putting the player down that path,
//  keys[0] is what comes back, and Mule Kick three times in a row is keys[0]
//  being stable across spins.
//
//  Why it is stable, and why Mule Kick specifically: Origins' own weighting
//  function (zm_tomb.gsc::tomb_random_perk_weights) appends up to five BONUS
//  entries every single spin with arraycombine( ..., keepdupes = 1 ) - among them
//  specialty_additionalprimaryweapon. That is how stock weights the draw: more
//  copies, more likely. It also means the list grows without bound as you spin,
//  and the more you spin the more of it is those five perks.
//
//  So rather than guess which condition sends the draw to the fallback, this
//  removes the fallback's ability to be wrong: the key order handed back has
//  every perk the player LACKS first, so keys[0] is always something they can
//  use. Perks they hold are kept on the end so the fallback still has something
//  to return in the genuine "owns everything" case.
//
//  Stock's weighting is preserved exactly - this calls Origins' own function and
//  only reorders what it returns, so the duplicate-weighted draw still works as
//  Treyarch tuned it.
//
//  📝 Worth keeping: when a bug is "sometimes returns the wrong thing" and the
//  code has a fallback branch, check the FALLBACK before the main path. The main
//  path here was right all along and reads like the suspect.
//
//  Called ON THE PLAYER - get_weighted_random_perk does
//  `keys = player [[ level.custom_random_perk_weights ]]();`
// ============================================================================
zmqol_tomb_perk_weights()
{
    a_keys = self [[ level.zmqol_tomb_weights_prev ]]();

    if ( !isdefined( a_keys ) || a_keys.size < 1 )
        return a_keys;

    a_want = [];
    a_have = [];

    for ( i = 0; i < a_keys.size; i++ )
    {
        str_perk = level._random_perk_machine_perk_list[ a_keys[i] ];

        if ( !isdefined( str_perk ) )
            continue;

        if ( self hasperk( str_perk ) )
            a_have[ a_have.size ] = a_keys[i];
        else
            a_want[ a_want.size ] = a_keys[i];
    }

    //  Everything they lack, in stock's own weighted order, then the rest.
    for ( i = 0; i < a_have.size; i++ )
        a_want[ a_want.size ] = a_have[i];

    return a_want;
}

//  The perks Origins registers itself, which do not appear in level._custom_perks
//  because they are core rather than custom.
zmqol_tomb_perk_is_stock( str_perk )
{
    a_stock = array( "specialty_armorvest", "specialty_quickrevive", "specialty_fastreload",
                     "specialty_rof", "specialty_longersprint", "specialty_additionalprimaryweapon",
                     "specialty_deadshot", "specialty_flakjacket", "specialty_scavenger" );

    return isinarray( a_stock, str_perk );
}

// ============================================================================
//  zmqol_power_up_all_generators
//
//  🛑 Origins survival should not have generators at all.
//
//  Stock maps\mp\zm_tomb_capture_zones::init_capture_zones() runs on EVERY gametype -
//  it flag_wait("start_zombie_round_logic")s and then threads init_capture_zone() on
//  every s_generator struct in the map, regardless of start location. So on Trenches /
//  Excavation Site / Church / Crazy Place you get the full classic-Origins economy:
//    - a "Hold [F] to activate generator" unitrigger on each generator
//    - the mystery box locked behind "turn on the power"
//    - perk machines that belong to an uncaptured generator zone never finishing their
//      spawn (this is the real reason Speed Cola was missing on Trenches - its machine
//      is owned by generator_mid_trench)
//    - Pack-a-Punch gated behind all_zones_captured
//  ...on an arena where no generator can be captured, so none of it is ever obtainable.
//
//  This is BO2-Reimagined's fix, ported: scripts/zm/zm_tomb/zm_tomb_reimagined.gsc::
//  power_up_all_generators(). It marks every capture zone player-controlled at round
//  start, which is the single lever that resolves all four symptoms at once, because
//  stock set_player_controlled_zone() (zm_tomb_capture_zones.gsc:1410) does:
//        ent_flag_set("player_controlled")   -> generator_trigger_prompt_and_visibility()
//                                               returns 0, so the prompt disappears
//        enable_perk_machines_in_zone()      -> the perk machines actually spawn
//        enable_random_perk_machines_in_zone()
//        enable_mystery_boxes_in_zone()      -> box unlocks, no power prompt
//        update_captured_zone_count()        -> all 6 captured -> flag "all_zones_captured"
//                                               -> pack_a_punch_think() -> pack_a_punch_enable()
//                                               -> flag_set("power_on")
//
//  Threaded from init() (Reimagined calls it synchronously, which would block everything
//  after it on the flag_wait; threading is the safe form).
//
//  is_classic() gated: CLASSIC ORIGINS STILL REQUIRES POWERING THE GENERATORS BY HAND.
//
//  The wait: init_capture_zones() populates level.zone_capture.zones from inside the same
//  flag_wait, so we take one network frame after the flag before reading it, then guard on
//  isdefined rather than assuming.
//
//  🛑 NOT verified in game yet.
// ============================================================================
// ============================================================================
//  zmqol_probe_capture_zones  -  CLASSIC ORIGINS ONLY, diagnostic, remove later
//
//  Reported: starting generator 1 in the spawn area shows no progress indicator.
//  The user's read was that leftover custom-survival code is still interfering.
//  That is not supported by anything I can check offline, and the checks were
//  not cheap, so they are recorded here rather than repeated:
//
//    - every Origins-specific function this file adds returns immediately on
//      is_classic() - power_up_all_generators, disable_staff_relay_switches,
//      remove_survival_ee_props, open_stock_barriers, and both clientfield
//      registrations. None of them execute in classic.
//    - the capture HUD is driven by WORLD-scope clientfields
//      (zone_capture_hud_generator_N, zc_change_progress_bar_color, via
//      setupclientfieldcodecallbacks in zm_tomb_capture_zones.csc:17-32). The
//      mod registers no world-scope clientfield anywhere, so it cannot be
//      shifting that layout.
//    - the HUD's LUI is ui_mp\t6\zombie\tombcapturezonedisplay.lua and
//      capturezonewheeltombdisplay.lua, both in zm_tomb_patch.ff. mod.ff
//      contains no .lua at all, so nothing is shadowing them. The one in-game
//      LUI this mod does override, hudpowerupszombie.lua, has no capture or
//      generator symbols in either the stock or the modded copy.
//    - our zm_tomb.csc replaces only include_weapons; the stock client-side
//      capture init (init_cz_animtree / init_structs / init_custom_pap,
//      zm_tomb.csc:103-126) is untouched.
//
//  So this prints whether the SERVER half is running, which splits the problem
//  in half: if progress climbs here while nothing draws, it is client/LUI; if
//  progress never moves, it is server-side and the zone objects are the place to
//  look.
// ============================================================================
// ============================================================================
//  zmqol_tomb_mp40_stalker_wallbuys  -  Origins' MP40 wall-buys give the same
//  adjustable-stock MP40 the mystery box gives.
//
//  User, 2026-08-07: "make sure that the mp40 wallbuys give you the mp40
//  adjustable stock just like my friend did, the same mp40 adjustable stock
//  that you get if you get the mp40 out of the mystery box."
//
//  🌟 THIS NEEDS NO NEW ASSET AND NO WEAPON REGISTRATION. Stock Origins already
//  ships both guns and already registers the stalker one (zm_tomb.gsc):
//
//      add_zombie_weapon( "mp40_zm",         "mp40_upgraded_zm",         ... 1300 ... )
//      add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", ... 1300 ... )
//      include_weapon( "mp40_zm", 0 )          <- buyable, NOT in the box
//      include_weapon( "mp40_stalker_zm" )     <- in the box
//      add_shared_ammo_weapon( "mp40_stalker_zm", "mp40_zm" )
//
//  Both are registered at the same 1300 cost and already share ammo, so
//  pointing the wall-buys at the stalker variant changes which of two
//  already-present weapons is handed over. Nothing is precached, nothing is
//  added to the box, and the cost does not move.
//
//  🛑 TIMING: this MUST run in main(). maps\mp\zombies\_zm_weapons::
//  init_spawnable_weapon_upgrade() reads .zombie_weapon_upgrade off these
//  structs during init and builds the trigger and its hint string from it.
//  Editing them afterwards would change nothing.
//
//  📝 It also prints every MP40 wall-buy it finds, which is the probe for the
//  second half of the same report: the wall-buy by the mound in No Man's Land
//  shows its chalk but offers no buy prompt. The mapents dump of zm_tomb.ff has
//  THREE structs, all identical in shape:
//        (3237, -429, 195)   (-517, 4503, -285)   (-640, 693, 199)
//  If this line reports 3, all three structs exist and the missing prompt is
//  downstream in trigger creation. If it reports fewer, the struct itself is
//  not reaching the game and that is a different problem entirely. Either way
//  the next boot answers it without another round trip.
// ============================================================================
zmqol_tomb_mp40_stalker_wallbuys()
{
    level endon( "end_game" );

    //  🛑 v1.59.2 - THE v1.59.1 VERSION RAN IN main() AND DID NOTHING. Its own
    //  probe said so: "retagged 0 of 0 weapon_upgrade struct(s)".
    //  getstructarray() reads level.struct, which is built by the MAP's main()
    //  from the mapents - and this mod's main() runs BEFORE the map's (proven by
    //  the animtree ordering documented in zm_expanded.csc). So at main() there
    //  are literally no structs to retag yet. Retagging structs is the wrong
    //  lever anyway; see below.
    //
    //  🌟 THE RIGHT LEVER IS THE UNITRIGGER STUB, and it is timing-proof.
    //  _zm_weapons.gsc:1120 reads the weapon LIVE at purchase:
    //        weapon = self.stub.zombie_weapon_upgrade;
    //  so rewriting the stub after the wall-buys are built is enough, and does
    //  not race init_spawnable_weapon_upgrade() at all. Stock keeps every stub
    //  in level._unitriggers.trigger_stubs (_zm_unitrigger.gsc:123).
    //
    //  The hint needs no repair: get_weapon_hint() returns &"ZOMBIE_WEAPON_MP40"
    //  for BOTH variants and both cost 1300, so the prompt is identical either
    //  way. hint_string and cost are refreshed regardless, using stock's own
    //  idiom from _zm_weapons.gsc:1261, so nothing can drift.
    n_wait = 0;

    while ( !isdefined( level._unitriggers ) || !isdefined( level._unitriggers.trigger_stubs ) || level._unitriggers.trigger_stubs.size == 0 )
    {
        wait 0.5;
        n_wait += 0.5;

        if ( n_wait > 30 )
        {
            println( "[zm_qol] origins mp40: no unitrigger stubs after 30s - wallbuys never registered" );
            return;
        }
    }

    //  Let every wall-buy finish registering before walking the list.
    wait 2;

    //  🛑 v1.59.3 - REFUSE TO TOUCH ANYTHING UNLESS THE REPLACEMENT WEAPON IS
    //  REALLY REGISTERED. v1.59.2 retagged all three wallbuys and KILLED THE BUY
    //  PROMPT on every one of them - chalk still drawn, no prompt, unbuyable.
    //
    //  The mechanism, from stock (_zm_weapons.gsc):
    //      get_weapon_hint( w ) { return level.zombie_weapons[w].hint; }
    //      get_weapon_cost( w ) { return level.zombie_weapons[w].cost; }
    //  Both index level.zombie_weapons directly. If "mp40_stalker_zm" is not in
    //  that table at the moment this runs, BOTH return undefined - and the
    //  prompt is built from them, so an undefined hint is exactly a wallbuy with
    //  no prompt. Worse, the trigger re-derives the hint from
    //  .zombie_weapon_upgrade later (line 1218), so even leaving hint_string
    //  alone would not have saved it.
    //
    //  So the whole change is now gated on the table entry existing. If it does
    //  not, nothing is touched and the wallbuys keep working exactly as stock -
    //  a missing feature instead of a broken wallbuy. The log says which
    //  happened, so this cannot fail silently again.
    if ( !isdefined( level.zombie_weapons ) || !isdefined( level.zombie_weapons[ "mp40_stalker_zm" ] ) )
    {
        println( "[zm_qol] origins mp40: mp40_stalker_zm is NOT in level.zombie_weapons - RETAG SKIPPED, wallbuys left stock" );
        return;
    }

    //  And never write an undefined into the stub, even now.
    str_hint = maps\mp\zombies\_zm_weapons::get_weapon_hint( "mp40_stalker_zm" );
    n_cost   = maps\mp\zombies\_zm_weapons::get_weapon_cost( "mp40_stalker_zm" );

    if ( !isdefined( str_hint ) || !isdefined( n_cost ) )
    {
        println( "[zm_qol] origins mp40: hint or cost undefined for mp40_stalker_zm - RETAG SKIPPED, wallbuys left stock" );
        return;
    }

    a_stubs   = level._unitriggers.trigger_stubs;
    n_mp40    = 0;
    n_wb      = 0;
    str_where = "";

    for ( i = 0; i < a_stubs.size; i++ )
    {
        if ( !isdefined( a_stubs[i] ) || !isdefined( a_stubs[i].zombie_weapon_upgrade ) )
            continue;

        n_wb++;

        //  DIAGNOSTIC for the second half of the report: the wall-buy by the
        //  mound in No Man's Land shows chalk but offers no buy prompt. Every
        //  wall-buy stub that exists is printed with its weapon and position, so
        //  the log says outright whether that one was ever built. The mapents
        //  dump has three mp40 structs, at (3237,-429,195), (-517,4503,-285) and
        //  (-640,693,199) - if fewer than three appear here, the trigger is not
        //  being created and that is a separate fault from the weapon it hands
        //  out.
        if ( a_stubs[i].zombie_weapon_upgrade == "mp40_zm" || a_stubs[i].zombie_weapon_upgrade == "mp40_stalker_zm" )
        {
            if ( isdefined( a_stubs[i].origin ) )
            {
                str_where = str_where + a_stubs[i].zombie_weapon_upgrade + "("
                          + int( a_stubs[i].origin[0] ) + "," + int( a_stubs[i].origin[1] ) + "," + int( a_stubs[i].origin[2] ) + ") ";
            }
        }

        if ( a_stubs[i].zombie_weapon_upgrade != "mp40_zm" )
            continue;

        a_stubs[i].zombie_weapon_upgrade = "mp40_stalker_zm";

        //  .weapon_upgrade is set alongside it at _zm_weapons.gsc:957; keep the
        //  pair consistent rather than leaving one naming the old gun.
        if ( isdefined( a_stubs[i].weapon_upgrade ) )
            a_stubs[i].weapon_upgrade = "mp40_stalker_zm";

        a_stubs[i].hint_string = str_hint;
        a_stubs[i].cost        = n_cost;

        n_mp40++;
    }

    println( "[zm_qol] origins mp40: retagged " + n_mp40 + " mp40 wallbuy stub(s) to mp40_stalker_zm; " + n_wb + " wallbuy stub(s) total; mp40 at " + str_where );
}

zmqol_tomb_no_native_wunderfizz()
{
    //  Deliberately empty - the replacement for BOTH
    //  _zm_perk_random::init_machines and ::start_random_machine.
    //
    //  Both are reached with `level thread ...`, so an empty body just ends
    //  that thread and nothing downstream runs: no unitriggers (no buy
    //  prompt), no ball, no animtree use, no machine_selector, no
    //  machine_think. The six map entities themselves are left alone - see
    //  zmqol_hide_native_wunderfizz for why they must survive.
}

// ============================================================================
//  zmqol_hide_native_wunderfizz  -  make the six vanilla machines invisible
//  WITHOUT deleting them.
//
//  🛑 DO NOT DELETE THESE ENTITIES. zm_tomb_capture_zones.gsc builds a
//  per-zone array out of them (`...zones[str_zone_name].perk_machines_random`,
//  lines 369-377) and sets `.is_locked` on each member as generators come and
//  go:
//
//      enable_random_perk_machines_in_zone()   ->  .is_locked = 0
//      disable_random_perk_machines_in_zone()  ->  .is_locked = 1
//
//  That IS the generator gating the user asked to keep, and the mod's own
//  machines read it back via zmqol_wf_tomb_native_for() in wunderfizz.gsc.
//  Delete these and the gating dies with them - and stock would be iterating
//  an array of deleted entities on every zone change.
//
//  Hidden two ways on purpose: setmodel( "tag_origin" ) is the technique this
//  project has already proven (wunderfizz.gsc uses it on the perk bottle), and
//  hide() is belt and braces so invisibility does not rest on either alone.
//  Verified from the zm_tomb.ff mapents dump: all six are classname
//  "script_model", targetname "random_perk_machine" - both calls are valid.
// ============================================================================
zmqol_hide_native_wunderfizz()
{
    level endon( "end_game" );

    //  Map-placed, so they exist from load - but give the map's own init a
    //  frame to finish before touching them.
    wait 0.05;

    a_native = getentarray( "random_perk_machine", "targetname" );
    n_hidden = 0;

    for ( i = 0; i < a_native.size; i++ )
    {
        if ( !isdefined( a_native[i] ) )
            continue;

        a_native[i] setmodel( "tag_origin" );
        a_native[i] hide();
        n_hidden++;
    }

    println( "[zm_qol] origins wunderfizz: hid " + n_hidden + " of " + a_native.size + " native machine(s) - the mod's own replace them" );
}

zmqol_probe_capture_zones()
{
    if ( !is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    if ( !isdefined( level.zone_capture ) || !isdefined( level.zone_capture.zones ) )
    {
        println( "[zm_qol] capture probe: level.zone_capture MISSING - server side never initialised" );
        return;
    }

    println( "[zm_qol] capture probe: " + level.zone_capture.zones.size + " zone(s) registered" );

    a_last = [];
    n_ticks = 0;

    while ( n_ticks < 600 )
    {
        for ( i = 0; i < level.zone_capture.zones.size; i++ )
        {
            zone = level.zone_capture.zones[i];

            if ( !isdefined( zone ) || !isdefined( zone.n_current_progress ) )
                continue;

            if ( !isdefined( a_last[i] ) || a_last[i] != zone.n_current_progress )
            {
                str_name = "?";

                if ( isdefined( zone.script_noteworthy ) )
                    str_name = zone.script_noteworthy;

                // The objective index IS the ring. If progress is climbing and
                // obj is a real index with the zone contested, the server has
                // done everything it is supposed to and a missing ring is
                // purely client-side - which falsifies the intro-timing fix in
                // quality_of_life.gsc::zmqol_intro_hold_time().
                str_obj = "unset";

                if ( isdefined( zone.n_objective_index ) )
                    str_obj = "" + zone.n_objective_index;

                println( "[zm_qol] capture probe: zone " + i + " (" + str_name + ") progress " + zone.n_current_progress + " obj=" + str_obj + " contested=" + zone ent_flag( "zone_contested" ) + " inzone=" + zone maps\mp\zm_tomb_capture_zones::get_players_in_capture_zone().size );
                a_last[i] = zone.n_current_progress;
            }
        }

        wait 0.5;
        n_ticks++;
    }
}

zmqol_power_up_all_generators()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    if ( !isdefined( level.zone_capture ) || !isdefined( level.zone_capture.zones ) )
        return;

    foreach ( zone in level.zone_capture.zones )
    {
        zone maps\mp\zm_tomb_capture_zones::set_player_controlled_area();
        zone.n_current_progress = 100;
        zone maps\mp\zm_tomb_capture_zones::generator_state_power_up();
        level setclientfield( zone.script_noteworthy, zone.n_current_progress / 100 );
        wait_network_frame();
    }
}

// ============================================================================
//  zmqol_disable_staff_relay_switches
//
//  🛑 The lightning-staff switches stay interactable on survival.
//
//  Reported on Trenches: the switch in the tank-station building by generator 2 still
//  takes input. That is one of the eight elemental-staff relay switches
//  (maps\mp\zm_tomb_quest_elec::electric_puzzle_2_init - relays "bunker",
//  "tank_platform", "start", "elec", "ruins", "air", "ice", "village", built from the
//  map's "puzzle_relay_switch" entities).
//
//  They exist on survival because stock maps\mp\zm_tomb.gsc::main() threads
//  main_quest_init() with no gametype guard, and that threads zm_tomb_quest_elec::main(),
//  which registers a unitrigger per relay in relay_switch_run(). The puzzle they feed is
//  unreachable on a locked-down arena, so the switch is pure noise.
//
//  Why unregister the triggers instead of replaceFunc'ing electric_puzzle_2_init:
//    1. That function is called SYNCHRONOUSLY and UNQUALIFIED from its own file's main()
//       (`electric_puzzle_2_init();`). Threaded same-file calls are reliably redirected by
//       replaceFunc; plain synchronous ones are the case that is still in doubt. No reason
//       to bet a fix on it.
//    2. Skipping the init outright would leave level.electric_relays undefined, and
//       electric_puzzle_2_run/cleanup foreach over it.
//  unregister_unitrigger (maps\mp\zombies\_zm_unitrigger.gsc:133) is the stock teardown:
//  it kills the per-player trigger ents and drops the stub from level._unitriggers, and it
//  no-ops safely on an undefined stub. relay_switch_run() is left blocked forever on a
//  waittill that can no longer fire, which is harmless.
//
//  Deliberately does NOT touch the rest of the staff quest - deleting main_quest_init would
//  leave level.a_elemental_staffs undefined, which maps\mp\zm_tomb_ffotd.gsc:26
//  (update_charger_position, threaded from main_end on every gametype) foreachs over.
//
//  is_classic() gated, so the classic Origins puzzle is untouched.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_disable_staff_relay_switches()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    if ( !isdefined( level.electric_relays ) )
        return;

    foreach ( s_relay in level.electric_relays )
    {
        if ( isdefined( s_relay.trigger_stub ) )
            maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( s_relay.trigger_stub );
    }
}

// ============================================================================
//  zmqol_remove_survival_ee_props
//
//  🛑 The two remaining bits of full-map Origins furniture that are physically
//  standing inside the survival arenas.
//
//  1. THE TANK. maps\mp\zm_tomb_tank::init() runs on every gametype and sets the
//     vehicle up unconditionally. The tank parks at the tank station, which is
//     generator 2 - i.e. inside the TRENCHES arena - and its route crosses NO
//     MAN'S LAND. Its two call boxes (verified in the shipped mapents) are
//         trig_tank_station_call  ( 377, -2985,   95)  script_noteworthy call_box_village
//         trig_tank_station_call  (-273,  4537, -254)  script_noteworthy call_box_bunkers
//     the first of which is inside the CHURCH arena, where buying it drove the
//     tank straight through the barricade that fences the location off.
//
//     🛑 Why here and not in the loc script, where zm_tomb_loc_church::disable_tank
//     used to do it: the loc scripts run out of zm_tomb_gamemodes::init, which is
//     reached from maps\mp\zombies\_zm::init() - line ~218 of zm_tomb::main(),
//     ELEVEN LINES BEFORE maps\mp\zm_tomb_tank::init() at ~229. Deleting the tank
//     there means tank::init then runs
//         level.vh_tank = getent( "tank", "targetname" );   // undefined
//         level.vh_tank tank_setup();                       // method on undefined
//     Church has been shipping that ordering, which is very likely a silent script
//     error every round. Waiting for start_zombie_round_logic puts us safely after
//     tank::init and after players_on_tank_update/tank_disconnect_paths have taken
//     their path snapshot. Deleting an entity terminates the threads that hold it
//     as self, so tank_setup/tankuseanimtree/tank_discovery_vo all go with it.
//
//     Safe to leave level.enemy_location_override_func pointing at the tank code:
//     enemy_location_override() only dereferences level.vh_tank underneath
//     `if ( isdefined( self.tank_state ) )`, and nothing sets tank_state once the
//     tank is gone.
//
//  2. THE SOUL BOXES. maps\mp\zm_tomb_challenges::init_box_footprints() threads
//     box_footprint_think on all four "foot_box" script_models regardless of
//     gametype - they glow, they open, they absorb souls. Two of the four sit in
//     the EXCAVATION SITE arena (-2138,-300,176) and (667, 640, 66), a third at
//     (2752,-88,151) also in no man's land, the fourth (1324,-3712,302) by the
//     church. The challenge they feed rewards the one inch punch, which is the
//     quest weapon we are removing everywhere else.
//
//     Deleted rather than replaceFunc'd on purpose: init_box_footprints is reached
//     ONLY as a ::function pointer handed to add_stat() inside
//     tomb_challenges_add_stats, which is CLAUDE.md §4 failure mode 3 (pointer
//     bound at registration). Deleting the entities kills the box_footprint_think
//     threads with them and needs no hook at all.
//
//  is_classic() gated - classic Origins keeps its tank and its soul boxes.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_remove_survival_ee_props()
{
    if ( is_classic() )
        return;

    // ------------------------------------------------------------------------
    //  🛑 ORDERING. This used to wait on start_zombie_round_logic, which was two
    //  frames TOO LATE. maps\mp\zm_tomb_tank::players_on_tank_update() - threaded
    //  on the tank by tank_setup() - opens with exactly that flag_wait and then
    //  immediately does `self thread tank_disconnect_paths()`. The matching
    //  connectpaths() lives on the tank's own thread, so deleting the vehicle
    //  afterwards stranded a disconnected region in the AI path graph with nothing
    //  left alive to reconnect it. The tank is parked off-map at (-8192, -4096, 0)
    //  so it probably severed nothing real, but "probably" is not good enough next
    //  to a reported zombie-pathing bug.
    //
    //  Waiting on level.vh_tank instead lands the deletion in the correct window:
    //  AFTER maps\mp\zm_tomb_tank::init() has run (it is what assigns the var, so
    //  tank_setup() never sees an undefined self - the ordering trap that made this
    //  wrong in zm_tomb_loc_church) and BEFORE start_zombie_round_logic releases
    //  players_on_tank_update. Deleting an entity terminates the threads holding it
    //  as self, so that thread dies still parked on its flag_wait and
    //  tank_disconnect_paths() is never reached.
    //
    //  The timeout keeps this from spinning forever if tank::init is ever skipped;
    //  the getent() calls below are all isdefined-guarded, so giving up early
    //  degrades to "nothing to remove".
    // ------------------------------------------------------------------------
    n_waited = 0;

    while ( !isdefined( level.vh_tank ) && n_waited < 200 )
    {
        n_waited++;
        wait 0.05;
    }

    a_call_boxes = getentarray( "trig_tank_station_call", "targetname" );

    foreach ( trigger in a_call_boxes )
    {
        if ( isdefined( trigger ) )
            trigger delete();
    }

    // The ride-on trigger. It ships parked off-map at (-8192, -4240, 164) with the
    // tank and is carried along with it, so it has to go too or it rides to the
    // station with a vehicle that no longer exists.
    t_use_tank = getent( "trig_use_tank", "targetname" );

    if ( isdefined( t_use_tank ) )
        t_use_tank delete();

    e_tank = getent( "tank", "targetname" );

    if ( isdefined( e_tank ) )
        e_tank delete();

    level.vh_tank = undefined;

    a_boxes = getentarray( "foot_box", "script_noteworthy" );

    foreach ( box in a_boxes )
    {
        if ( isdefined( box ) )
            box delete();
    }
}

// ============================================================================
//  zmqol_open_stock_barriers
//
//  🛑 Zombies walk through Origins' wooden window barriers WITHOUT tearing the
//  boards. Reported at generator 3 on Trenches, 2026-08-02.
//
//  ROOT CAUSE - Origins is the only map that never zone-tags its zbarriers.
//
//  maps\mp\zombies\_zm_zonemgr.gsc:317 only adds a barrier to a zone:
//        if ( targets[j] iszbarrier() && isdefined( targets[j].script_string )
//             && targets[j].script_string == zone_name )
//            zone.zbarriers[zone.zbarriers.size] = targets[j];
//
//  Counted over the shipped mapents (T6-Data-Archive):
//        zm_transit   38 of 38 zbarriers carry script_string
//        zm_prison    22 of 22
//        zm_tomb       0 of 12          <-- every one of them untagged
//
//  So on Origins `zone.zbarriers` is empty for EVERY zone, forever. Three
//  consequences, and the third is the bug:
//    1. maps\mp\zm_tomb.gsc::drop_all_barriers() iterates zone.zbarriers, so on
//       this map it is a COMPLETE NO-OP. Treyarch clearly meant every barrier to
//       be open - Origins has no board-repair minigame - but the code never
//       reaches a single one, which is why the boards are still standing.
//    2. The barrier attack/repair system never engages with them either, so no
//       zombie ever plays a tear animation on one.
//    3. Each barrier ships with a node_negotiation_begin entity at the SAME
//       origin carrying animscript "zm_mantle_over_40" - an ordinary path node,
//       always live, owned by nobody. Zombies mantle straight through six intact
//       boards. Verified on the one 394 units from generator_mid_trench:
//         (696, 1985, -97)  zbarrier_zmcore_BasicWoodBarrier, zbarriernumboards 6
//
//  THE FIX - finish what drop_all_barriers() was trying to do.
//
//  Same two calls stock uses, same 0.05s pacing, but the barriers are reached via
//  the "exterior_goal" structs (which DO target them correctly) instead of the
//  permanently-empty zone arrays. The window then reads as an open hole, matching
//  both Treyarch's evident intent and what the zombies actually do.
//
//  is_classic() gated, so classic Origins is untouched - and note this changes
//  nothing there anyway, since stock already intends all barriers open.
//
//  🛑 THE OTHER OPTION, NOT TAKEN. The barriers could instead be made REAL on
//  survival - assign each one a script_string naming the zone it sits in, before
//  _zm_zonemgr builds its arrays, and Origins survival would get Town/Farm-style
//  boards that zombies tear and players rebuild for points. That is a bigger
//  change: zone membership has to be resolved at runtime by volume containment
//  (the volumes are brush models, so it cannot be tabulated offline), barriers sit
//  on zone boundaries where containment is ambiguous, and registering them alters
//  zombie spawn/goal selection on all four arenas. Worth doing deliberately, not
//  as a side effect of a bug fix.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_open_stock_barriers()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    a_goals = getstructarray( "exterior_goal", "targetname" );
    n_opened = 0;

    foreach ( s_goal in a_goals )
    {
        if ( !isdefined( s_goal.target ) )
            continue;

        a_targets = getentarray( s_goal.target, "targetname" );

        foreach ( e_barrier in a_targets )
        {
            if ( !isdefined( e_barrier ) || !e_barrier iszbarrier() )
                continue;

            n_pieces = e_barrier getnumzbarrierpieces();

            for ( i = 0; i < n_pieces; i++ )
            {
                e_barrier hidezbarrierpiece( i );
                e_barrier setzbarrierpiecestate( i, "open" );
            }

            n_opened++;
            wait 0.05;
        }
    }

    println( "[zm_qol] BARRIERS opened " + n_opened + " stock zbarriers" );
}

added_weapons()
{
    if (level.script == "zm_tomb")
	{
        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "saritch_zm" );
        include_weapon( "saritch_upgraded_zm", 0 );
        add_zombie_weapon( "saritch_zm", "saritch_upgraded_zm", &"ZOMBIE_WEAPON_SARITCH", 50, "wpck_sidr", "", undefined, 1 );

        include_weapon( "m16_zm" );
        include_weapon( "m16_gl_upgraded_zm", 0 );
        add_zombie_weapon( "m16_zm", "m16_gl_upgraded_zm", &"ZOMBIE_WEAPON_M16", 1200, "burstrifle", "", undefined );

        include_weapon( "barretm82_zm" );
        include_weapon( "barretm82_upgraded_zm", 0);
        add_zombie_weapon( "barretm82_zm", "barretm82_upgraded_zm", &"ZOMBIE_WEAPON_BARRETM82", 50, "sniper", "", undefined );

        include_weapon( "mp5k_zm" );
        include_weapon( "mp5k_upgraded_zm", 0);
        add_zombie_weapon( "mp5k_zm", "mp5k_upgraded_zm", &"ZOMBIE_WEAPON_MP5K", 1000, "smg", "", undefined );

        include_weapon( "tar21_zm" );
        include_weapon( "tar21_upgraded_zm", 0);
        add_zombie_weapon( "tar21_zm", "tar21_upgraded_zm", &"ZOMBIE_WEAPON_TAR21", 50, "wpck_x95l", "", undefined, 1 );

        include_weapon( "rottweil72_zm" );
        include_weapon( "rottweil72_upgraded_zm", 0 );
        add_zombie_weapon( "rottweil72_zm", "rottweil72_upgraded_zm", &"ZOMBIE_WEAPON_ROTTWEIL72", 500, "shotgun", "", undefined );

        include_weapon( "saiga12_zm" );
        include_weapon( "saiga12_upgraded_zm", 0);
        add_zombie_weapon( "saiga12_zm", "saiga12_upgraded_zm", &"ZOMBIE_WEAPON_SAIGA12", 50, "wpck_saiga12", "", undefined, 1 );

        include_weapon( "m1911_zm" );
        include_weapon( "m1911_upgraded_zm", 0);
        add_zombie_weapon( "m1911_zm", "m1911_upgraded_zm", &"ZOMBIE_WEAPON_M1911", 50, "", "", undefined );

        include_weapon( "judge_zm" );
        include_weapon( "judge_upgraded_zm", 0);
        add_zombie_weapon( "judge_zm", "judge_upgraded_zm", &"ZOMBIE_WEAPON_JUDGE", 50, "wpck_judge", "", undefined, 1 );

        include_weapon( "usrpg_zm" );
        include_weapon( "usrpg_upgraded_zm", 0);
        add_zombie_weapon( "usrpg_zm", "usrpg_upgraded_zm", &"ZOMBIE_WEAPON_USRPG", 50, "wpck_rpg", "", undefined, 1 );
    }
}

// Origins weapon-dig fix: if you dig up a weapon whose Pack-a-Punched version
// you already hold, give max ammo instead of swapping. (Merged from the old
// standalone Originspatch2.0.gsc so it only loads on Origins - no unresolved
// externals on other maps.)
custom_swap_weapon( str_weapon, e_player )
{
    if ( isdefined( level.zombie_weapons[str_weapon] ) && isdefined( level.zombie_weapons[str_weapon].upgrade_name ) )
    {
        upgraded_weapon = level.zombie_weapons[str_weapon].upgrade_name;

        if ( e_player hasweapon( upgraded_weapon ) )
        {
            e_player givemaxammo( upgraded_weapon );
            return;
        }
    }

    str_current_weapon = e_player getcurrentweapon();

    if ( str_weapon == "claymore_zm" )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player thread maps\mp\zombies\_zm_weap_claymore::show_claymore_hint( "claymore_purchased" );
            e_player thread maps\mp\zombies\_zm_weap_claymore::claymore_setup();
            e_player thread maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", "grenade" );
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }

        return;
    }

    if ( is_player_valid( e_player ) && !e_player.is_drinking && !is_placeable_mine( str_current_weapon ) && !is_equipment( str_current_weapon ) && level.revive_tool != str_current_weapon && str_current_weapon != "none" && !e_player hacker_active() )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player maps\mp\zm_tomb_dig::take_old_weapon_and_give_new( str_current_weapon, str_weapon );
            return;
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }
    }
}

// Origins native "loose change" reward (prone at a perk machine): exact copy of
// maps\mp\zm_tomb_ee_side::check_for_change but pays 100 instead of the stock 25.
// (Moved here from perkbonuspoints.gsc - it must live in this Origins-only map
// script or the zm_tomb_ee_side reference is unresolved on other maps.)
origins_change_patch()
{
    while ( true )
    {
        self waittill( "trigger", e_player );

        if ( e_player getstance() == "prone" )
        {
            e_player maps\mp\zombies\_zm_score::add_to_player_score( 100 );
            play_sound_at_pos( "purchase", e_player.origin );
            break;
        }

        wait 0.1;
    }
}

// ============================================================================
//  qol_check_solo_status  (replaces maps\mp\zm_tomb_utility::check_solo_status)
//
//  🛑 A one-player game on Plutonium was getting CO-OP rules. Stock:
//
//      if ( getnumexpectedplayers() == 1 && ( !sessionmodeisonlinegame() || !sessionmodeisprivate() ) )
//          level.is_forever_solo_game = 1;
//
//  On retail the session clause is what separates "alone on the couch" from
//  "online private lobby my friends can still join". Plutonium runs EVERY game
//  - including the Solo entry - as an online private match, so both builtins
//  return true, the OR is false, and the flag is never set no matter how the
//  game was started. Origins then ran the whole map on co-op rules.
//
//  What that actually broke, all from stock (nothing here is a guess):
//    - zm_tomb_utility::zone_capture_powerup - the start-bunker reward chest
//      after the first generator gives reward_powerup_double_points in solo and
//      reward_powerup_zombie_blood in co-op. The zombie blood the user got IS
//      this branch.
//    - zm_tomb_utility::adjustments_for_solo - the solo door/debris price cut
//      and the 750-point Beretta/870 never applied.
//    - zm_tomb_capture_zones::get_recapture_zombies_needed - 6 instead of 4.
//    - zm_tomb_capture_zones::get_capture_rate - the slower co-op rate, scaled
//      by (players in zone / players total), instead of rate_capture_solo.
//    - _zm_ai_mechz - solo has its own Mechz behaviour.
//
//  Fix: keep stock's player-count test exactly, drop only the session-mode
//  clause that Plutonium always fails. getnumexpectedplayers() is valid at this
//  call site - stock reads it here itself. Evaluated once, never re-checked,
//  which is what "forever solo" means in stock too.
// ============================================================================
//  v1.62.0: `<= 1`, matching zm_prison's copy. Origins already reported
//  expected=1 in a real boot log, so this changes nothing here today - it is
//  kept identical to Mob's on purpose, so the two cannot drift and so Origins
//  is covered if its call site ever resolves the count as late as Mob's does.
//  See the long note above zm_prison.gsc::qol_check_solo_status.
qol_check_solo_status()
{
    n_expected = getnumexpectedplayers();

    if ( n_expected <= 1 )
        level.is_forever_solo_game = 1;
    else
        level.is_forever_solo_game = 0;

    println( "[zm_qol] solo status: expected=" + n_expected + " connected=" + getnumconnectedplayers() + " is_forever_solo_game=" + level.is_forever_solo_game );
}
