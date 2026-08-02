#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

// ============================================================================
//  zm_tomb_ee_side::init  -  replacement
//
//  🛑 Origins' SIDE easter eggs run on every gametype. Stock
//  maps\mp\zm_tomb.gsc::main() does `level thread maps\mp\zm_tomb_ee_side::init();`
//  with no guard at all, so a standalone survival arena gets the full set of
//  quest furniture for a quest it can never reach:
//
//    one inch punch   two "trigger_use" prompts. Verified in the shipped mapents
//                     (T6-Data-Archive zm_tomb.d3dbsp):
//                       trigger_oneinchpunch_church_birdbath  ( 920, -2640, 357)
//                         -> inside the CHURCH arena (zone_village_*)
//                       trigger_oneinchpunch_bunker_table     (-141,  4467, -324)
//                         -> start bunker, walled off on Trenches
//    quadrotor        4 "quad_special_item" medallions, incl. one at
//    medallions       (10344, -7906, -248) which is directly over the CRAZY PLACE
//                     spawn ring, and (-438, -62, 454) inside NO MAN'S LAND.
//                     Collecting all 4 spawns an upgraded MG08 - a full-map hunt.
//    wagon fire       sets wagon_1/2/3_fire clientfields at round start and
//    challenge        re-lights them on a 30s loop forever. Burning props and a
//                     zombie_blood drop for a challenge that needs the fire staff.
//    wall hole        a shootable "hole_poster" prop in the bunker.
//    poster
//    ee lights        the morse-code light show; gated on ee_all_staffs_upgraded,
//                     so it is pure background load on survival.
//    jump scare       the zm_tm_wth_dog per-player scare.
//
//  WHAT IS DELIBERATELY KEPT ON SURVIVAL
//
//    radio_ee_song()  the SONG easter egg. Kept by explicit instruction: song
//                     easter eggs stay. Reimagined deletes this; we do not.
//                     Note only one of the three "ee_radio_pos" structs
//                     (9589, -8114, -463) sits in an arena (Crazy Place), so the
//                     song cannot actually be completed there - the radio is
//                     flavour, not a quest.
//
//    check_for_change the "prone at a perk machine" loose-change reward. This is
//                     NOT an easter egg we want gone - zm_qol replaceFunc's it to
//                     pay 100 instead of 25 (zm_tomb\zm_tomb.gsc::
//                     origins_change_patch) and it is a listed mod feature.
//                     Called QUALIFIED below so the replaceFunc is guaranteed to
//                     be the thing that runs.
//
//  🛑 registerclientfield("world","light_show") IS REQUIRED in the survival
//  branch. clientscripts\mp\zm_tomb_ee_lights.csc:10 registers it on the client
//  unconditionally, but the only server-side registration is the first line of
//  maps\mp\zm_tomb_ee_lights::main() - which this branch no longer threads.
//  Dropping it would be an EXE_CLIENT_FIELD_MISMATCH disconnect, the exact
//  failure already fixed four times over in zm_tomb\zm_tomb.gsc. Registering it
//  here keeps it inside the same window stock used (this init is threaded from
//  zm_tomb::main, before clientfield finalisation).
//
//  Structure follows BO2-Reimagined's scripts\zm\replaced\zm_tomb_ee_side.gsc
//  (same guard, same three deletions, same light_show registration); the two
//  keeps above are zm_qol's deviation from it. Every call below is fully
//  qualified into maps\mp\zm_tomb_ee_side so this file carries no copied logic -
//  the classic path is stock behaviour, re-expressed.
// ============================================================================
init()
{
	precacheshader( "zm_tm_wth_dog" );
	precachemodel( "p6_zm_tm_tablet" );
	precachemodel( "p6_zm_tm_tablet_muddy" );
	precachemodel( "p6_zm_tm_radio_01" );
	precachemodel( "p6_zm_tm_radio_01_panel2_blood" );
	registerclientfield( "world", "wagon_1_fire", 14000, 1, "int" );
	registerclientfield( "world", "wagon_2_fire", 14000, 1, "int" );
	registerclientfield( "world", "wagon_3_fire", 14000, 1, "int" );
	registerclientfield( "actor", "ee_zombie_tablet_fx", 14000, 1, "int" );
	registerclientfield( "toplayer", "ee_beacon_reward", 14000, 1, "int" );

	if ( !is_classic() )
	{
		// Stand-in for the registration inside zm_tomb_ee_lights::main(), which
		// this branch does not thread. See the header - this is not optional.
		registerclientfield( "world", "light_show", 14000, 2, "int" );

		t_bunker = getent( "trigger_oneinchpunch_bunker_table", "targetname" );

		if ( isdefined( t_bunker ) )
			t_bunker delete();

		t_birdbath = getent( "trigger_oneinchpunch_church_birdbath", "targetname" );

		if ( isdefined( t_birdbath ) )
			t_birdbath delete();

		// getentarray, not getstructarray - the "ee_cam" script_struct also
		// carries script_noteworthy "quad_special_item" and must survive, because
		// zm_tomb_loc_crazy_place::set_ee_ending() re-aims it for the intermission
		// camera.
		a_special_items = getentarray( "quad_special_item", "script_noteworthy" );

		foreach ( e_special_item in a_special_items )
		{
			if ( isdefined( e_special_item ) )
				e_special_item delete();
		}

		zmqol_thread_loose_change();
		level thread maps\mp\zm_tomb_ee_side::radio_ee_song();
		return;
	}

	onplayerconnect_callback( maps\mp\zm_tomb_ee_side::onplayerconnect_ee_jump_scare );
	onplayerconnect_callback( maps\mp\zm_tomb_ee_side::onplayerconnect_ee_oneinchpunch );
	maps\mp\zm_tomb_ee_side::sq_one_inch_punch();
	zmqol_thread_loose_change();
	level thread maps\mp\zm_tomb_ee_side::wagon_fire_challenge();
	level thread maps\mp\zm_tomb_ee_side::wall_hole_poster();
	level thread maps\mp\zm_tomb_ee_side::quadrotor_medallions();
	level thread maps\mp\zm_tomb_ee_lights::main();
	level thread maps\mp\zm_tomb_ee_side::radio_ee_song();
}

// The stock loop out of zm_tomb_ee_side::init, lifted so both branches share it.
// check_for_change is replaceFunc'd by zm_tomb\zm_tomb.gsc::origins_change_patch
// (prone at a perk machine -> 100 points); the qualified call guarantees the
// replacement is what gets threaded.
zmqol_thread_loose_change()
{
	a_triggers = getentarray( "audio_bump_trigger", "targetname" );

	foreach ( trigger in a_triggers )
	{
		if ( isdefined( trigger.script_sound ) && trigger.script_sound == "zmb_perks_bump_bottle" )
			trigger thread maps\mp\zm_tomb_ee_side::check_for_change();
	}
}
