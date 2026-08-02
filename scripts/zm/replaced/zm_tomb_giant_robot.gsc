#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

// ============================================================================
//  zm_tomb_giant_robot :: robot_cycling  -  zm_qol replacement
// ----------------------------------------------------------------------------
//  WHY THIS EXISTS
//
//  Stock maps\mp\zm_tomb.gsc::main() calls maps\mp\zm_tomb_giant_robot::init_giant_robot()
//  unconditionally - there is no is_classic() guard anywhere in that chain. So on the
//  standalone Origins SURVIVAL arenas the three giant robots spawn, the intro walk plays,
//  and robot_cycling() keeps marching them across the whole map forever. Their foot soles
//  stay shootable and their head hatches stay enterable, which on a locked-down survival
//  arena is both nonsense (the wind-staff quest it feeds is unreachable) and an
//  out-of-bounds route.
//
//  WHAT THIS CHANGES
//
//  On !is_classic() the cycle simply never starts. The robots are still SPAWNED by
//  maps\mp\zm_tomb_giant_robot::giant_robot_initial_spawns() - deliberately, see below -
//  but that function leaves every robot ghost()ed, setcandamage(0), magic_bullet_shield()'d
//  and parked at its spawn point. Nothing shows them or arms them except
//  giant_robot_start_walk(), which is only ever reached from here. Result: no robot walks,
//  no foot sole is damageable (m_sole setcandamage(1) lives inside start_walk), no head
//  hatch opens.
//
//  🛑 DO NOT "improve" this by skipping giant_robot_initial_spawns() instead.
//  maps\mp\zombies\_zm_weap_beacon.gsc:600-638 indexes level.a_giant_robots[i] directly and
//  only guards the .is_walking FIELD, not the array element - with the robots never spawned
//  that array is empty and the beacon would read a field off undefined. Leaving them
//  spawned-but-inert keeps a_giant_robots populated and .is_walking undefined, which is
//  exactly the state that guard expects.
//
//  Hookability: stock giant_robot_initial_spawns() ends with `level thread robot_cycling();`
//  - an unqualified same-file call, but THREADED, which is the case replaceFunc does
//  redirect (see the memory note on threaded same-file calls; BO2-Reimagined replaces this
//  same function for the same reason).
//
//  The is_classic() path below is stock robot_cycling() verbatim, with the two same-file
//  calls qualified so they reach the real maps\mp\zm_tomb_giant_robot copies rather than
//  looking for functions in this file. Dev-only /# #/ blocks are dropped. CLASSIC ORIGINS
//  BEHAVIOUR IS UNCHANGED.
//
//  Reimagined's own version keeps ONE robot walking per survival location instead of none.
//  That is deliberately not copied: the user's instruction for this project is to remove
//  the robots outright.
// ============================================================================
robot_cycling()
{
	if ( !is_classic() )
		return;

	three_robot_round = 0;
	last_robot = -1;
	level thread maps\mp\zm_tomb_giant_robot::giant_robot_intro_walk( 1 );
	level waittill( "giant_robot_intro_complete" );

	while ( true )
	{
		if ( !( level.round_number % 4 ) && three_robot_round != level.round_number )
			flag_set( "three_robot_round" );

		if ( flag( "ee_all_staffs_placed" ) && !flag( "ee_mech_zombie_hole_opened" ) )
			flag_set( "three_robot_round" );

		if ( flag( "three_robot_round" ) )
		{
			level.zombie_ai_limit = 22;
			random_number = randomint( 3 );

			if ( random_number == 2 )
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 2 );
			else
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 2, 0 );

			wait 5;

			if ( random_number == 0 )
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 0 );
			else
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 0, 0 );

			wait 5;

			if ( random_number == 1 )
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 1 );
			else
				level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( 1, 0 );

			level waittill( "giant_robot_walk_cycle_complete" );
			level waittill( "giant_robot_walk_cycle_complete" );
			level waittill( "giant_robot_walk_cycle_complete" );
			wait 5;
			level.zombie_ai_limit = 24;
			three_robot_round = level.round_number;
			last_robot = -1;
			flag_clear( "three_robot_round" );
		}
		else
		{
			if ( !flag( "activate_zone_nml" ) )
				random_number = randomint( 2 );
			else
			{
				do
					random_number = randomint( 3 );
				while ( random_number == last_robot );
			}

			last_robot = random_number;
			level thread maps\mp\zm_tomb_giant_robot::giant_robot_start_walk( random_number );
			level waittill( "giant_robot_walk_cycle_complete" );
			wait 5;
		}
	}
}
