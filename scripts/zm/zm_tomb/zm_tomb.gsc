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

    // --- custom survival start locations: Trenches, Excavation Site, Church, The Crazy Place ---
    replaceFunc( maps\mp\zm_tomb_gamemodes::init, scripts\zm\replaced\zm_tomb_gamemodes::init );

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
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "toplayer",    "sndMudSlow",      14000, 1, "int" );
    registerclientfield( "scriptmover", "element_glow_fx", 14000, 4, "int", undefined, 0 );
    registerclientfield( "scriptmover", "bryce_cake",      14000, 2, "int", undefined, 0 );
    registerclientfield( "scriptmover", "switch_spark",    14000, 1, "int", undefined, 0 );
}

init()
{
    added_weapons();
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