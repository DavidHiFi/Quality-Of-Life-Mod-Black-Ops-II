#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_prison;

main()
{
	replaceFunc( maps\mp\zm_prison::delete_perk_machine_clip, ::delete_perk_machine_clip );

	// --- custom survival start locations: adds Docks (alongside stock Cell Block) ---
	replaceFunc( maps\mp\zm_alcatraz_gamemodes::init, scripts\zm\replaced\zm_alcatraz_gamemodes::init );

	// 🛑 Cell Block survival killed the player on spawn. This project ships
	// Reimagined's maps\mp\zm_prison.d3dbsp mapents override but never ported the
	// working_zone_init that matches it, so the playable-area volumes and the
	// enabled zones disagreed and in_enabled_playable_area() was false at spawn.
	// See the long comment in scripts\zm\replaced\zm_prison.gsc.
	replaceFunc( maps\mp\zm_prison::working_zone_init, scripts\zm\replaced\zm_prison::working_zone_init );
}

init()
{
    precacheModel("collision_clip_32x32x128");
    zmqol_precache_survival_characters();
    added_weapons();
}

// ============================================================================
//  zmqol_precache_survival_characters
//
//  🛑 Fixes: DOCKS/CELL BLOCK SURVIVAL - INVISIBLE BODY, VIEW ARMS AND WEAPON,
//     and zombies unable to damage you.
//
//  v1.1.3 changed which characters survival uses and did NOT fix it: the probe
//  still reported a correctly assigned model (model=c_zom_player_handsome_fb,
//  weap=m1911_zm, health=100). The character set was never the problem -
//  PRECACHING was.
//
//  level.precachecustomcharacters is consumed early, in
//  _zm_gametype::rungametypeprecache() during onprecachegametype. Our
//  zstandard_preinit assigns it, but preinit is not guaranteed to have run by
//  then, so on these locations nothing ever precaches the player xmodels.
//  setmodel/setviewmodel on an xmodel that was never precached still sets the
//  .model script field - which is why the probe looked healthy - but renders
//  nothing: no body, no view arms, and no weapon (it hangs off the viewhands
//  tag). A player entity with no model also has no hit geometry, which is why
//  zombie melee could never connect. One cause, all three symptoms.
//
//  Why TranZit's added locations never showed this: TranZit is the ONLY map in
//  the game that ships a so_zsurvival_*.ff (verified with the OAT Unlinker
//  across every map), so its survival characters get precached through stock
//  paths. Alcatraz has only so_zclassic/so_zencounter, and a zstandard game
//  loads neither - just zm_prison_patch + zm_prison.
//
//  init() is a valid precache window (the precacheModel above already relies on
//  that). Precaching is idempotent, so this is harmless if the normal path also
//  runs. Covers Cell Block as well as Docks, since both are zstandard here.
// ============================================================================
zmqol_precache_survival_characters()
{
    if ( is_classic() )
        return;

    maps\mp\zm_prison::precache_personality_characters();
}

delete_perk_machine_clip()
{
	perk_machines = getentarray("zombie_vending", "targetname");

	foreach (perk_machine in perk_machines)
	{
		if (isdefined(perk_machine.clip))
		{
			perk_machine.clip delete();
		}

		if (isdefined(perk_machine.target) && perk_machine.target == "vending_divetonuke" || perk_machine.target == "vending_additionalprimaryweapon")
		{
			spawn_custom_perk_collision(perk_machine);
		}
	}
}

spawn_custom_perk_collision(perk_machine)
{
	collision = spawn("script_model", perk_machine.origin + (0, 0, 64), 1);
	collision.angles = perk_machine.angles;

	collision setmodel("collision_clip_32x32x128");
	collision disconnectpaths();
}

added_weapons()
{
    if (level.script == "zm_prison")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon_prison( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon_prison( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon_prison( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon_prison( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon_prison( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon_prison( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined, 1 );
        
        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon_prison( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "qcw05_zm" );
        include_weapon( "qcw05_upgraded_zm", 0 );
        add_zombie_weapon_prison( "qcw05_zm", "qcw05_upgraded_zm", &"ZOMBIE_WEAPON_QCW05", 50, "wpck_chicom", "", undefined, 1 );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74_extclip_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon_prison( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 900, "wpck_pistol", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "saritch_zm" );
        include_weapon( "saritch_upgraded_zm", 0 );
        add_zombie_weapon_prison( "saritch_zm", "saritch_upgraded_zm", &"ZOMBIE_WEAPON_SARITCH", 50, "wpck_sidr", "", undefined, 1 );

        include_weapon( "m16_zm" );
        include_weapon( "m16_gl_upgraded_zm", 0 );
        add_zombie_weapon_prison( "m16_zm", "m16_gl_upgraded_zm", &"ZOMBIE_WEAPON_M16", 1200, "burstrifle", "", undefined );

        include_weapon( "type95_zm" );
        include_weapon( "type95_upgraded_zm", 0 );
        add_zombie_weapon_prison( "type95_zm", "type95_upgraded_zm", &"ZOMBIE_WEAPON_TYPE95", 50, "wpck_type25", "", undefined, 1 );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon_prison( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "srm1216_zm" );
        include_weapon( "srm1216_upgraded_zm", 0 );
        add_zombie_weapon_prison( "srm1216_zm", "srm1216_upgraded_zm", &"ZOMBIE_WEAPON_SRM1216", 50, "wpck_m1216", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon_prison( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "hamr_zm" );
        include_weapon( "hamr_upgraded_zm", 0 );
        add_zombie_weapon_prison( "hamr_zm", "hamr_upgraded_zm", &"ZOMBIE_WEAPON_HAMR", 50, "wpck_hamr", "", undefined, 1 );

        include_weapon( "python_zm" );
        include_weapon( "python_upgraded_zm", 0 );
        add_zombie_weapon_prison( "python_zm", "python_upgraded_zm", &"ZOMBIE_WEAPON_PYTHON", 50, "wpck_python", "", undefined, 1 );

        include_weapon( "kard_zm" );
        include_weapon( "kard_upgraded_zm", 0 );
        add_zombie_weapon_prison( "kard_zm", "kard_upgraded_zm", &"ZOMBIE_WEAPON_KARD", 50, "wpck_kap", "", undefined, 1 );

        include_weapon( "m32_zm" );
        include_weapon( "m32_upgraded_zm", 0 );
        add_zombie_weapon_prison( "m32_zm", "m32_upgraded_zm", &"ZOMBIE_WEAPON_M32", 50, "wpck_m32", "", undefined, 1 );
    }
}

