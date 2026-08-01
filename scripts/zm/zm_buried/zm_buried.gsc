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

    // 🛑 Maze survival had no zombies at all - zone_maze is not in Buried's
    // init_zones and is the SOURCE of both its adjacency edges, so on the
    // standalone location nothing ever enables it and its spawn locations never
    // activate. See scripts\zm\replaced\zm_buried.gsc.
    replaceFunc( maps\mp\zm_buried::buried_zone_init, scripts\zm\replaced\zm_buried::buried_zone_init );

    println( "[zm_qol] MAZE marker B - zm_buried_gamemodes::init replaceFunc done" );
}

init()
{
    zmqol_precache_survival_characters();
    added_weapons();
    move_divetonuke_collision();
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

