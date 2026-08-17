#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_tomb;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zm_tomb_classic;

main()
{
    replaceFunc(clientscripts\mp\zm_tomb::include_weapons, ::include_weapons);

    //  v1.99.39 - the client half of removing the bunker Five-seven wall-buy.
    //  The server kills the buy trigger; the chalk fx and the gun model are
    //  spawned CLIENT-side by clientscripts\mp\zombies\_zm_weapons::
    //  wallbuy_player_connect(), so only this VM can take them away. Without
    //  this half the result is chalk with no prompt - the exact bug this map
    //  has already shipped once.
    //  v1.99.41 - registered HERE, in main(), on purpose: callbacks are
    //  dispatched in the order they were added, and main() runs before
    //  _zm_weapons.csc::init() adds stock's own. So ours unlists the wall-buy
    //  before stock's wallbuy_player_connect() can draw its chalk. See the long
    //  block below. The same registration slot is already used by
    //  zm_expanded.csc (zmqol_zb_init_filter, zmqol_vulture_after_connect).
    onplayerconnect_callback( ::zmqol_tomb_fiveseven_connect );

    level thread zmqol_tomb_remove_fiveseven_wallbuy();
}

// ============================================================================
//  zmqol_tomb_remove_fiveseven_wallbuy  (CLIENT)
//
//  See the long block above the server twin in zm_tomb.gsc for the CLIENTFIELD
//  REGISTRATION rule this obeys. Nothing here registers, unregisters or
//  re-orders a clientfield: both VMs still register exactly what stock
//  registers, so the load-time symmetry check is untouched.
//
//  🛑 v1.99.41 - THIRD ATTEMPT, AND THE FIRST ONE THAT DOES NOT TRY TO ERASE AN
//  FX THAT IS ALREADY ON THE WALL. What the two failures taught, both measured
//  in game rather than reasoned about:
//
//    v1.99.39  stopfx( c, handle ) - the client printed SUCCESS and the chalk
//              was still there. stopfx ends the emitter; particles already
//              spawned live out their lifespan, and a chalk sprite's lifespan
//              is effectively forever.
//    v1.99.40  deletefx( c, handle, 1 ) - the client printed NOTHING AT ALL
//              this time, on either branch, while the server half printed
//              normally. A thread that reaches a println and does not print it
//              died on the statement before it, silently, the way Plutonium
//              always kills GSC runtime errors. The three-argument form comes
//              from a DECOMPILE (_zm.csc:659) and decompiled arg lists are not
//              evidence - [[t6-decompiles-are-lossy]]. Only the two-argument
//              form is corroborated by more than one stock file (_fx.csc:137,
//              _zm_equipment.csc:30, zmeat.csc:49).
//
//  🌟 SO THE FX IS NEVER CREATED IN THE FIRST PLACE. Stock draws the chalk in
//  clientscripts\mp\zombies\_zm_weapons::wallbuy_player_connect(), which walks
//  getarraykeys( level._active_wallbuys ) and calls playfx once per entry. An
//  entry that is not in that array when the callback runs gets no fx and no
//  weapon model - there is nothing to remove afterwards and no fx-removal
//  builtin in the path at all.
//
//  Winning that race is safe to rely on, not a bet:
//    - this file's main() runs at script load, before ANY level init;
//    - level._active_wallbuys is built in _zm_weapons.csc::init(), and
//      onplayerconnect_callback( ::wallbuy_player_connect ) is the LAST line of
//      that same init(), so the callback cannot fire before the array exists;
//    - so the array appearing is the starting gun, and this polls for it every
//      0.05s (one frame) instead of every 0.5s. zm_expanded.csc's own
//      zmqol_enable_wallbuys() depends on exactly this ordering and has worked
//      since v1.71.0.
//
//  Removing the key is stock-compatible. wallbuy_callback() looks its struct up
//  by field name and, on an initial snapshot, waits for the key with
//    while ( !isdefined( level._active_wallbuys[fieldname] ) ) wait 0.05;
//  so a missing key parks that one callback thread harmlessly instead of
//  faulting. Nothing else on the client reads the array.
//
//  The late branch is kept as a fallback for the case where the array somehow
//  appears with the fx already drawn, and it now uses the two-argument
//  deletefx. It prints before it calls, so a repeat of the v1.99.40 silence
//  identifies the builtin rather than hiding behind it.
// ============================================================================
//  Takes the wall-buy out of level._active_wallbuys and keeps a reference to the
//  struct. Returns 1 only on the call that actually did it, so the connect
//  callback and the poll below can both call it and only one can win.
//
//  🌟 `array[key] = undefined` really does REMOVE the key in T6, and that is
//  verified from stock rather than assumed - it has to be, because if it left a
//  hole instead then stock's connect loop would read an undefined entry and
//  fault, and every wall-buy after it in the list would lose its chalk AND its
//  weapon model. _globallogic_player.gsc:509-519 shifts every later element of
//  level.players down by one and then assigns undefined to the last index, and
//  the very next loop iterates level.players.size expecting it to have shrunk.
//  That code only works if the assignment deletes the key and decrements size.
zmqol_tomb_unlist_fiveseven_wallbuy()
{
    if ( is_true( level._zmqol_fiveseven_unlisted ) )
        return 0;

    if ( !isdefined( level._active_wallbuys ) )
        return 0;

    //  The struct origin, straight out of the retail mapents dump. Re-confirmed
    //  at v1.99.40: within 200 units of it the map has exactly two entities,
    //  this struct and its t6_wpn_pistol_fiveseven_world model struct, and no
    //  editor-placed fx - so the chalk can only be the wallbuy playfx.
    v_target = ( -927.75, 3036, -52 );

    keys = getarraykeys( level._active_wallbuys );

    for ( i = 0; i < keys.size; i++ )
    {
        wallbuy = level._active_wallbuys[ keys[i] ];

        if ( !isdefined( wallbuy ) || !isdefined( wallbuy.zombie_weapon_upgrade ) )
            continue;

        if ( wallbuy.zombie_weapon_upgrade != "fiveseven_zm" )
            continue;

        if ( !isdefined( wallbuy.origin ) || distancesquared( wallbuy.origin, v_target ) > 4096 )
            continue;

        //  Hold the struct itself - it is a reference, so the watchdog can still
        //  see its .fx after it is out of the array.
        level._zmqol_fiveseven_struct   = wallbuy;
        level._zmqol_fiveseven_key      = keys[i];
        level._zmqol_fiveseven_unlisted = 1;

        level._active_wallbuys[ keys[i] ] = undefined;
        return 1;
    }

    return 0;
}

//  Dispatched before stock's wallbuy_player_connect - see main().
zmqol_tomb_fiveseven_connect( localclientnum )
{
    if ( zmqol_tomb_unlist_fiveseven_wallbuy() )
    {
        println( "[zm_qol] CLIENT origins fiveseven: unlisted " + level._zmqol_fiveseven_key
               + " AT CONNECT (client " + localclientnum + ") - no chalk can be drawn" );
    }
}

zmqol_tomb_remove_fiveseven_wallbuy()
{
    level endon( "end_game" );

    //  BACKSTOP 1 - if the connect callback somehow ran before the array was
    //  built, catch it here. One frame per pass, 2400 passes = 120s.
    n_frames = 0;

    while ( n_frames < 2400 && !is_true( level._zmqol_fiveseven_unlisted ) )
    {
        n_frames++;

        if ( zmqol_tomb_unlist_fiveseven_wallbuy() )
        {
            println( "[zm_qol] CLIENT origins fiveseven: unlisted " + level._zmqol_fiveseven_key
                   + " BY POLL on frame " + n_frames + " (the connect callback did not get there first)" );
        }

        wait 0.05;
    }

    if ( !isdefined( level._zmqol_fiveseven_struct ) )
    {
        println( "[zm_qol] CLIENT origins fiveseven: NEVER FOUND the wall-buy in level._active_wallbuys in 120s - chalk untouched" );
        return;
    }

    s_wallbuy = level._zmqol_fiveseven_struct;

    //  BACKSTOP 2 - only reachable if the chalk got drawn before we unlisted.
    //  40 passes = 20s. It prints BEFORE it calls deletefx so that a repeat of
    //  the v1.99.40 silence names the builtin instead of hiding behind it.
    n_passes = 0;
    n_killed = 0;

    while ( n_passes < 40 )
    {
        n_passes++;

        for ( c = 0; c < 4; c++ )
        {
            if ( isdefined( s_wallbuy.fx ) && isdefined( s_wallbuy.fx[c] ) )
            {
                println( "[zm_qol] CLIENT origins fiveseven: LATE fx on client " + c
                       + " (pass " + n_passes + ") - calling deletefx( c, handle )" );

                deletefx( c, s_wallbuy.fx[c] );
                s_wallbuy.fx[c] = undefined;
                n_killed++;

                println( "[zm_qol] CLIENT origins fiveseven: deletefx returned on client " + c );
            }

            if ( isdefined( s_wallbuy.models ) && isdefined( s_wallbuy.models[c] ) )
                s_wallbuy.models[c] hide();
        }

        wait 0.5;
    }

    println( "[zm_qol] CLIENT origins fiveseven: done - late fx killed: " + n_killed );
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  Same defect as zm_prison\zm_prison.csc - see the long comment there for the
//  mechanism and the _zm.csc line numbers.
//
//  Origins is worse than Mob of the Dead: stock
//  clientscripts\mp\zm_tomb::init_gamemodes registers ONLY zclassic, while
//  scripts\zm\replaced\zm_tomb_gamemodes.gsc adds zstandard AND zgrief on the
//  server (Trenches, Excavation Site, Church, Crazy Place).
//
//  This was masked until now: Origins survival was dropping at the clientfield
//  check (EXE_CLIENT_FIELD_MISMATCH) before it could ever reach the client's
//  gametype startup. With that fixed in zm_tomb.gsc, this gap becomes the next
//  thing in the way - so the two changes have to ship together.
//
//  The four custom locations get no client-side location funcs, matching the
//  server (which routes them to scripts\zm\locs\*) and matching TranZit's Diner,
//  which works with none.
//
//  🛑 NOT verified in game yet.
// ============================================================================
init_gamemodes()
{
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );

    add_map_location_gamemode( "zclassic", "tomb", clientscripts\mp\zm_tomb_classic::precache, clientscripts\mp\zm_tomb_classic::premain, clientscripts\mp\zm_tomb_classic::main );
}

include_weapons()
{
    include_weapon( "hamr_zm" );
    include_weapon( "hamr_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "type95_zm", 0 ); //
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm", 0 ); //
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "mp44_zm", 0 );
    include_weapon( "mp44_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "ksg_zm", 0 ); //
    include_weapon( "ksg_upgraded_zm", 0 );
    include_weapon( "srm1216_zm", 0  ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 ); //
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "pdw57_zm", 0 ); //
    include_weapon( "pdw57_upgraded_zm", 0 );
    include_weapon( "thompson_zm" );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "qcw05_zm", 0 ); //
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "mp40_zm", 0 );
    include_weapon( "mp40_upgraded_zm", 0 );
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "evoskorpion_zm" );
    include_weapon( "evoskorpion_upgraded_zm", 0 );
    include_weapon( "ballista_zm", 0 );
    include_weapon( "ballista_upgraded_zm", 0 );
    include_weapon( "dsr50_zm", 0 ); //
    include_weapon( "dsr50_upgraded_zm", 0 );
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    include_weapon( "beretta93r_extclip_zm", 0 ); //
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    include_weapon( "fiveseven_zm", 0 );
    include_weapon( "fiveseven_upgraded_zm", 0 );
    include_weapon( "python_zm", 0 ); //
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "c96_zm", 0 );
    include_weapon( "c96_upgraded_zm", 0 );
    include_weapon( "fivesevendw_zm" );
    include_weapon( "fivesevendw_upgraded_zm", 0 );
    include_weapon( "m32_zm" );
    include_weapon( "m32_upgraded_zm", 0 );
    include_weapon( "beacon_zm", 0 );
    include_weapon( "tomb_shield_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "knife_zm", 0 );
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "sticky_grenade_zm", 0 );
    include_weapon( "staff_air_zm", 0 );
    include_weapon( "staff_air_upgraded_zm", 0 );
    include_weapon( "staff_fire_zm", 0 );
    include_weapon( "staff_fire_upgraded_zm", 0 );
    include_weapon( "staff_lightning_zm", 0 );
    include_weapon( "staff_lightning_upgraded_zm", 0 );
    include_weapon( "staff_water_zm", 0 );
    include_weapon( "staff_water_zm_cheap", 0 );
    include_weapon( "staff_water_upgraded_zm", 0 );
    include_weapon( "staff_revive_zm", 0 );
    // Added weapons
    include_weapon( "uzi_zm" );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
    include_weapon( "hk416_zm" );
    include_weapon( "hk416_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "an94_zm" ); 
    include_weapon( "an94_upgraded_zm", 0 );
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0 );
    include_weapon( "svu_zm" );
    include_weapon( "svu_upgraded_zm", 0 );
    // Tranzit weapons
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "rpd_zm" );
    include_weapon( "rpd_upgraded_zm", 0 );
    include_weapon( "saritch_zm" );
    include_weapon( "saritch_upgraded_zm", 0 );
    include_weapon( "m16_zm" );
    include_weapon( "m16_gl_upgraded_zm", 0 );
    include_weapon( "barretm82_zm" );
    include_weapon( "barretm82_upgraded_zm", 0);
    include_weapon( "mp5k_zm" );
    include_weapon( "mp5k_upgraded_zm", 0);
    include_weapon( "tar21_zm" );
    include_weapon( "tar21_upgraded_zm", 0);
    include_weapon( "rottweil72_zm" );
    include_weapon( "rottweil72_upgraded_zm", 0 );
    include_weapon( "saiga12_zm" );
    include_weapon( "saiga12_upgraded_zm", 0);
    include_weapon( "m1911_zm" );
    include_weapon( "m1911_upgraded_zm", 0);
    include_weapon( "judge_zm" );
    include_weapon( "judge_upgraded_zm", 0);
    include_weapon( "usrpg_zm" );
    include_weapon( "usrpg_upgraded_zm", 0);


    if ( is_true( level.raygun2_included ) && !isdemoplaying() )
    {
        include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
        include_weapon( "raygun_mark2_upgraded_zm", 0 );
    }
}