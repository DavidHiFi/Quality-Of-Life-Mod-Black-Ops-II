#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_buried;

// main() runs before the map threads its own init, which is where replaceFunc has to
// happen for a hook on a map-init function to take (CLAUDE.md §4, failure mode 4).
// This file previously had no main() - it was added for the survival-locations port.
main()
{
    // zm_qol TEMPORARY narrowing markers for the Maze failure (2026-08-02).
    // Symptom: 2 script errors at load, "Unresolved external: precache / main
    // with 0 parameters in maps/mp/zm_buried.gsc". In that run NEITHER
    // scripts/zm/replaced/zm_buried_gamemodes.gsc NOR scripts/zm/locs/
    // zm_buried_loc_maze.gsc ever appears as "loaded successfully" in the log,
    // so the chain dies somewhere at/after this file. Every qualified reference
    // and unqualified call in all three files has been audited against the
    // SHIPPED bytecode and they all resolve, so these markers say which half
    // of that is wrong:
    //   BOTH print   -> main() ran and the replaceFunc resolved; look downstream.
    //   only A       -> resolving scripts\zm\replaced\zm_buried_gamemodes::init
    //                   is what fails.
    //   neither      -> zm_buried/zm_buried.gsc::main() itself is never called.
    println( "[zm_qol] MAZE marker A - zm_buried::main entered" );

    // --- custom survival start locations: adds Maze (alongside stock Borough/street) ---
    replaceFunc( maps\mp\zm_buried_gamemodes::init, scripts\zm\replaced\zm_buried_gamemodes::init );

    // 🛑 REMOVED 2026-08-02: replaceFunc on maps\mp\zm_buried::buried_zone_init,
    // along with scripts\zm\replaced\zm_buried.gsc.
    //
    // It existed to zone_init/enable_zone zone_maze, zone_maze_staircase and
    // zone_mansion_backyard, on the reasoning that zone_maze is absent from
    // Buried's init_zones and is the SOURCE of both its adjacency edges, so
    // nothing would ever enable it.
    //
    // That reasoning was wrong. _zm_zonemgr::manage_zones enables the SOURCE zone,
    // not just the destination (_zm_zonemgr.gsc:586-591):
    //        if ( flags_set )
    //        {
    //            enable_zone( zkeys[z] );            <-- zone_maze itself
    //            azone.is_connected = 1;
    //            if ( !level.zones[azkeys[az]].is_enabled )
    //                enable_zone( azkeys[az] );
    //        }
    // so zm_buried_loc_maze::main()'s own flag_set("mansion_door1") is already
    // sufficient to bring all three zones up through stock adjacency.
    //
    // Confirmed against BO2-Reimagined, which is the reference for this location
    // and whose Maze spawns zombies correctly: its buried_zone_init differs from
    // stock by ONE unrelated line (zone_toy_store -> zone_candy_store) and it does
    // no maze zone work at all. Deliberately not taking that line - it changes
    // classic Buried connectivity and has nothing to do with the maze.
    //
    // With this gone, stock buried_zone_init runs unmodified.
}

init()
{
    zmqol_precache_survival_characters();
    added_weapons();
    move_divetonuke_collision();
    level thread zmqol_spawner_probe();   // DIAGNOSTIC - remove once Maze spawns
}

// ============================================================================
//  zmqol_spawner_probe   -   DIAGNOSTIC, A/B. Remove once Maze spawns zombies.
//
//  Where the Maze investigation actually stands, so this is not re-derived:
//
//  The zone seal is PROVEN GOOD. The 09:56 run reported, at t=30s:
//      player @ (4746, 594, 4.1) in_zone=zone_maze
//      zone_maze             en=1 act=1 occ=1 spawn=1 spots=8/8
//      zone_mansion_backyard en=1 act=1 occ=0 spawn=1 spots=3/3
//      zone_maze_staircase   en=1 act=1 occ=0 spawn=1 spots=7/7
//      POOL=18 spawners=0 zombie_total=6
//  Every condition create_spawner_list tests (_zm_zonemgr.gsc:959 - is_enabled &&
//  is_active && is_spawning_allowed, then per-spot is_enabled) is satisfied, the
//  pool is full at 18, and 6 zombies are queued. Zones are not the problem any more.
//
//  The one anomaly is level.zombie_spawners.size == 0. _zm.gsc:3059 does
//  `spawner = random( level.zombie_spawners )` and then dereferences
//  spawner.targetname, so an empty array cannot spawn anything.
//
//  🛑 WHY THAT IS NOT YET A DIAGNOSIS. _zm_spawner::init() builds that array with
//  a flat, gametype-independent getentarray("zombie_spawner","script_noteworthy"),
//  so it should hold the SAME value on Borough - which spawns zombies fine - as on
//  Maze. Either that assumption is wrong, or something on the Maze path empties it.
//  Nothing in the ZM dump registers a custom_ai_spawn_check, and Buried does not
//  set level.ignore_spawner_func (only TranZit does), so neither of the two stock
//  mechanisms that mutate the array is in play. The archived mapents cannot settle
//  it either - they contain no actor/spawner entities at all.
//
//  So this runs on EVERY Buried location and prints the same fields, to be read as
//  an A/B: load a location that works, then Maze, and diff the two lines. Whichever
//  field differs is the cause, with no further guessing.
//
//      [zm_qol] SPAWNPROBE <loc> t=N spawners=<n> multi=<0/1> groups=<n>
//      [zm_qol] SPAWNPROBE <loc> t=N pool=<n> total=<n> alive=<n> limit=<n> flag=<0/1>
// ============================================================================
zmqol_spawner_probe()
{
    level endon( "end_game" );

    str_loc = getdvar( "ui_zm_mapstartlocation" );

    flag_wait( "start_zombie_round_logic" );

    for ( i = 0; i < 2; i++ )
    {
        wait 10;

        n_spawners = 0;

        if ( isdefined( level.zombie_spawners ) )
            n_spawners = level.zombie_spawners.size;

        n_groups = 0;

        if ( isdefined( level.zombie_spawn ) )
            n_groups = level.zombie_spawn.size;

        println( "[zm_qol] SPAWNPROBE " + str_loc + " t=" + ( ( i + 1 ) * 10 ) + " spawners=" + n_spawners + " multi=" + is_true( level.use_multiple_spawns ) + " groups=" + n_groups );

        n_pool = 0;

        if ( isdefined( level.zombie_spawn_locations ) )
            n_pool = level.zombie_spawn_locations.size;

        n_total = 0;

        if ( isdefined( level.zombie_total ) )
            n_total = level.zombie_total;

        n_limit = 0;

        if ( isdefined( level.zombie_ai_limit ) )
            n_limit = level.zombie_ai_limit;

        println( "[zm_qol] SPAWNPROBE " + str_loc + " t=" + ( ( i + 1 ) * 10 ) + " pool=" + n_pool + " total=" + n_total + " alive=" + maps\mp\zombies\_zm_utility::get_current_zombie_count() + " limit=" + n_limit + " flag=" + flag( "spawn_zombies" ) );
    }
}

// ============================================================================
//  zmqol_precache_survival_characters
//
//  Pre-empts, on Buried, the exact bug that made Docks and Cell Block spawn you
//  with an invisible body, invisible view arms and an invisible weapon (and made
//  zombies unable to damage you, because a player with no model has no hit
//  geometry). Fixed for Alcatraz in v1.1.4; Buried is in the same position and
//  would have shown it the moment Maze/Borough survival got far enough to spawn
//  a player.
//
//  Cause: scripts\zm\replaced\zm_buried_gamemodes::survival_init sets
//  level.precachecustomcharacters = ::precache_team_characters, but that pointer
//  is consumed EARLY, in _zm_gametype::rungametypeprecache during
//  onprecachegametype, and preinit is not guaranteed to have run by then. On maps
//  that ship a so_zsurvival_*.ff the characters get precached through stock paths
//  anyway - but TranZit is the only map in the game that has one (verified with
//  the OAT Unlinker across every map), so on Buried nothing precaches them.
//  setmodel on a never-precached xmodel still sets the .model script field, which
//  is why the v1.1.2 probe looked healthy, but renders nothing.
//
//  maps\mp\zm_buried::precache_team_characters precaches exactly the four models
//  give_team_characters assigns: c_zom_player_cdc_dlc1_fb, c_zom_hazmat_viewhands,
//  c_zom_player_cia_dlc1_fb, c_zom_suit_viewhands. Symbol verified present in the
//  SHIPPED zm_buried.gsc bytecode out of zm_buried_patch.ff, not just the dump.
//
//  init() is a valid precache window and precaching is idempotent, so this is
//  harmless if the normal path also runs.
// ============================================================================
zmqol_precache_survival_characters()
{
    if ( is_classic() )
        return;

    maps\mp\zm_buried::precache_team_characters();
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

