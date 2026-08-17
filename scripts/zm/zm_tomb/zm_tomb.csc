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
    level thread zmqol_tomb_remove_fiveseven_wallbuy();
}

// ============================================================================
//  zmqol_tomb_remove_fiveseven_wallbuy  (CLIENT)
//
//  See the long block above the server twin in zm_tomb.gsc for the evidence
//  that this wall-buy is stock Origins content and for why its CLIENTFIELD
//  REGISTRATION IS LEFT COMPLETELY ALONE. Nothing here registers, unregisters
//  or re-orders a clientfield: both VMs still register exactly what stock
//  registers, so the load-time symmetry check is untouched.
//
//  🌟 THE TWO CALLS ARE STOCK'S OWN, not invented. _zm_weapons.csc:384-387 does
//  precisely this pair when a buildable wall-buy changes weapon:
//        stopfx( localclientnum, struct.fx[localclientnum] );
//        struct.fx[localclientnum] = undefined;
//  and it hides the weapon model with target_model hide() two lines above.
//
//  📝 POLLED FROM main() RATHER THAN onplayerconnect_callback ON PURPOSE. The
//  fx and the model are created inside stock's own connect callback, so ours
//  would have to be ordered after it; zm_expanded.csc's header records that
//  those callbacks are armed at a specific point in _zm.csc and that getting
//  the order wrong is silent. A poll cannot be mis-ordered. It walks the four
//  possible local clients so splitscreen is covered.
// ============================================================================
zmqol_tomb_remove_fiveseven_wallbuy()
{
    level endon( "end_game" );

    //  The struct origin, straight out of the retail mapents dump. The fx and
    //  the model are placed on this exact struct, so this is the one to match.
    v_target = ( -927.75, 3036, -52 );

    n_passes     = 0;
    n_found      = 0;
    n_found_pass = 0;

    //  Up to 120 passes (60s) to find it, then 20 more to keep it gone through
    //  a late clientfield snap. Re-hiding an already hidden model is a no-op.
    while ( n_passes < 120 || ( n_found > 0 && n_passes < n_found_pass + 20 ) )
    {
        n_passes++;

        if ( isdefined( level._active_wallbuys ) )
        {
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

                for ( c = 0; c < 4; c++ )
                {
                    if ( isdefined( wallbuy.fx ) && isdefined( wallbuy.fx[c] ) )
                    {
                        //  v1.99.40 - deletefx, NOT stopfx. v1.99.39 used stopfx
                        //  and the client printed success while the chalk was
                        //  still on the wall in game. stopfx ends the emitter and
                        //  lets already-spawned particles live out their lifespan;
                        //  the chalk sprite's lifespan is effectively forever, so
                        //  nothing visible changed. deletefx with the third arg
                        //  set is stock's own call for removing a persistent
                        //  looping fx immediately - _zm.csc:659 kills zombie eyes
                        //  with exactly deletefx( localclientnum, handle, 1 ).
                        deletefx( c, wallbuy.fx[c], 1 );
                        wallbuy.fx[c] = undefined;
                        n_found++;

                        if ( n_found_pass == 0 )
                            n_found_pass = n_passes;
                    }

                    if ( isdefined( wallbuy.models ) && isdefined( wallbuy.models[c] ) )
                        wallbuy.models[c] hide();
                }
            }
        }

        wait 0.5;
    }

    if ( n_found == 0 )
        println( "[zm_qol] CLIENT origins fiveseven: never found the bunker wall-buy fx - the chalk is still drawn" );
    else
        println( "[zm_qol] CLIENT origins fiveseven: chalk fx stopped and wall model hidden" );
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