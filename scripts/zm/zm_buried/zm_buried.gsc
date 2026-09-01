#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_buried;

// main() runs before the map threads its own init, which is where replaceFunc has to
// happen for a hook on a map-init function to take (CLAUDE.md §4, failure mode 4).
// This file previously had no main() - it was added for the survival-locations port.

// zm_qol: Buried map hooks.
//
// v1.15.0 stripped this file back; 2026-09-02 restored the BOROUGH ("street")
// survival registration at the user's request. Maze stays out (excluded from
// the restoration). The suspected missing piece from the pre-strip attempt -
// the buried zombie xanims - is now declared in zone_source\
// mod_locations.zone; see scripts\zm\replaced\zm_buried_gamemodes.gsc.

main()
{
    // --- custom survival start location: BOROUGH ("street" on zstandard) ---
    replaceFunc( maps\mp\zm_buried_gamemodes::init, scripts\zm\replaced\zm_buried_gamemodes::init );

    zmqol_enable_vulture_on_borough();
}

// ============================================================================
//  zmqol_enable_vulture_on_borough
//
//  🛑 Fixes: "where the Vulture Aid machine is meant to be, a Speed Cola machine
//  is there instead" - reported in game on Borough survival, 2026-08-02.
//
//  The struct is NOT wrong. street_struct_init registers specialty_nomotionsensor
//  with model p6_zm_vending_vultureaid at (1450.33, 2302.68, 12), matching the
//  zm_buried mapents byte for byte, and the vultureaid xmodels are in the BASE
//  zm_buried.ff (Unlinker: 7 assets), which every gametype loads.
//
//  What actually happens is in _zm_perks::perk_machine_spawn_init. It switches on
//  the perk name to tag the machine, and specialty_nomotionsensor - a DLC perk -
//  has no case, so it falls into `default:` at _zm_perks.gsc:3057 and is tagged
//  as Speed Cola. The escape hatch (:3071) reads
//  level._custom_perks[perk].perk_machine_set_kvps, which for Vulture Aid is
//  populated only by enable_vulture_perk_for_level() - and stock zm_buried.gsc:263
//  calls that inside `if ( is_gametype_active( "zclassic" ) )`. Borough is
//  zstandard, so on survival the perk is never registered.
//
//  main() is early enough and is not destructive: initialize_custom_perk_arrays()
//  and _register_undefined_perk() both only create when undefined, so registering
//  ahead of _zm_perks::init survives it.
//
//  🛑 The client half is MANDATORY. register_perk_clientfields() registers a
//  clientfield server-side; clientscripts\mp\zm_buried.csc:49 has the identical
//  zclassic-only gate, so doing this on the server alone produces
//  EXE_CLIENT_FIELD_MISMATCH. See zm_buried.csc for the matching call.
//
//  Scoped to Borough only: it is the one location whose perk set contains Vulture
//  Aid. Classic is left completely alone.
// ============================================================================
zmqol_enable_vulture_on_borough()
{
    if ( getdvar( "g_gametype" ) != "zstandard" )
        return;

    if ( getdvar( "ui_zm_mapstartlocation" ) != "street" )
        return;

    maps\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();
}

// Borough survival players are the CDC/CIA teams (replaced\zm_buried_gamemodes::
// survival_init assigns give_team_characters); their models have to be precached
// before use. Stock only precaches them on the gametypes that use them.
zmqol_precache_survival_characters()
{
    if ( is_classic() )
        return;

    maps\mp\zm_buried::precache_team_characters();
}

init()
{
    zmqol_precache_survival_characters();
    added_weapons();
    move_divetonuke_collision();

    // DIAGNOSTIC, still open: Perma-Flopper does not explode in classic Buried.
    // Unrelated to the survival locations - it is a classic-only feature and the
    // bug predates all of that work - so the probe stays until it is read.
    level thread zmqol_flopper_probe();
}

zmqol_flopper_probe()
{
    level endon( "end_game" );

    if ( !is_classic() )
        return;

    flag_wait( "initial_blackscreen_passed" );

    for ( i = 0; i < 3; i++ )
    {
        wait 10;

        a_players = get_players();

        if ( !isdefined( a_players ) || a_players.size == 0 )
            continue;

        player = a_players[0];

        str_lvl = "0";

        if ( isdefined( level.pers_upgrade_flopper ) && level.pers_upgrade_flopper )
            str_lvl = "1";

        str_awarded = "undef";

        if ( isdefined( player.pers_upgrades_awarded ) && isdefined( player.pers_upgrades_awarded["flopper"] ) )
            str_awarded = "" + player.pers_upgrades_awarded["flopper"];

        str_active = "undef";

        if ( isdefined( player.pers_flopper_active ) )
            str_active = "" + player.pers_flopper_active;

        n_falls = 0;

        if ( isdefined( player.pers_num_flopper_damages ) )
            n_falls = player.pers_num_flopper_damages;

        println( "[zm_qol] FLOPPER t=" + ( ( i + 1 ) * 10 ) + " lvl_enabled=" + str_lvl + " awarded=" + str_awarded + " active=" + str_active + " falls=" + n_falls );
    }
}

added_weapons()
{
    if (level.script == "zm_buried")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "qcw05_zm" );
        include_weapon( "qcw05_upgraded_zm", 0 );
        add_zombie_weapon( "qcw05_zm", "qcw05_upgraded_zm", &"ZOMBIE_WEAPON_QCW05", 50, "wpck_chicom", "", undefined, 1 );

        include_weapon( "type95_zm" );
        include_weapon( "type95_upgraded_zm", 0 );
        add_zombie_weapon( "type95_zm", "type95_upgraded_zm", &"ZOMBIE_WEAPON_TYPE95", 50, "wpck_type25", "", undefined, 1 );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "python_zm" );
        include_weapon( "python_upgraded_zm", 0 );
        add_zombie_weapon( "python_zm", "python_upgraded_zm", &"ZOMBIE_WEAPON_PYTHON", 50, "wpck_python", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );
    }
}

move_divetonuke_collision()
{
	if (!is_gametype_active("zclassic"))
	{
		return;
	}

	trigs = getentarray("vending_divetonuke", "target");

	if (!isdefined(trigs))
	{
		return;
	}

	foreach (trig in trigs)
	{
		if (isdefined(trig.clip))
		{
			trig.clip.origin += (0, 0, -128);
		}
	}
}

