#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;

struct_init()
{
	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (-3522, -7198, -59), (0, -45, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_quickrevive", "zombie_vending_quickrevive", (-6207, -6541, -46), (0, 60, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_fastreload", "zombie_vending_sleight", (-5470, -7859.5, 0), (0, 270, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_rof", "zombie_vending_doubletap2", (-4170, -7592, -63), (0, 270, 0));

	// zm_qol: PACK-A-PUNCH, on the diner roof. Diner was the only survival
	// location without one - Reimagined gives Tunnel, Cornfield, Power and Docks
	// theirs the same way, one register_perk_struct line each, and simply never
	// wrote Diner's.
	//
	// p6_anim_zm_buildable_pap_on is what every other zm_transit location uses -
	// TranZit's PaP is the buildable one. register_perk_struct() spawns the
	// "please wait" flag with it and the perk system precaches the model, which
	// is why the other locations' precache() bodies are empty.
	//
	// The position is where the user stood in the screenshot; the machine faces
	// back down their line of sight so its front greets you on arrival. Left as
	// dvars because a roof is exactly the sort of place a machine ends up half
	// inside a vent housing, and these apply on a map restart rather than a
	// rebuild.
	v_pap = ( getdvarintdefault( "zmqol_pap_diner_x", -6207 ), getdvarintdefault( "zmqol_pap_diner_y", -7708 ), getdvarintdefault( "zmqol_pap_diner_z", 228 ) );
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", v_pap, (0, getdvarintdefault( "zmqol_pap_diner_yaw", 2 ), 0));

	restore_diner_hatch();

	structs = getstructarray("player_respawn_point", "targetname");
	respawn_point = [];
	zone = "zone_gas";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone)
		{
			respawn_point = struct;
			break;
		}
	}

	if (isdefined(respawn_point))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point.origin, zone, respawn_point.script_int);

		respawn_array = getstructarray(respawn_point.target, "targetname");

		foreach (respawn in respawn_array)
		{
			angles = respawn.angles;

			if (respawn.script_int == 2)
			{
				angles += (0, 180, 0);
			}

			scripts\zm\replaced\utility::register_map_spawn(respawn.origin, angles, zone, respawn.script_int);
		}
	}

	zone = "zone_roadside_east";
	scripts\zm\replaced\utility::register_map_spawn_group((-4173, -7095, -35), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((-4031, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4106, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4181, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4256, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4031, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4106, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4181, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4256, -7326, -35), (0, 180, 0), zone);

	zone = "zone_roadside_west";
	scripts\zm\replaced\utility::register_map_spawn_group((-5799, -6839, -30), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((-6120, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6045, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5970, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5895, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6120, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6045, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5970, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5895, -6984, -30), (0, 0, 0), zone);

	// zm_qol: the diner's own two wallbuys. Both are tagged "zclassic_transit"
	// in the stock map, so without this Diner survival/grief spawns none at all.
	// Origins verified against the zm_transit mapents dump - see the block
	// comment on loc_common::enable_wallbuys.
	a_wallbuys = [];
	a_wallbuys[a_wallbuys.size] = ( -5489, -7982.7, 62 );        // mp5k_zm, inside the diner
	a_wallbuys[a_wallbuys.size] = ( -6399.2, -7938.5, 207.25 );  // tazer_knuckles_zm (Galvaknuckles), diner roof
	scripts\zm\locs\loc_common::enable_wallbuys( a_wallbuys );

	gameObjects = getEntArray("script_model", "classname");

	foreach (object in gameObjects)
	{
		if (isDefined(object.script_noteworthy) && object.script_noteworthy == getDvar("ui_zm_mapstartlocation"))
		{
			if (isDefined(object.script_gameobjectname) && object.script_gameobjectname == "zcleansed zturned")
			{
				object.script_gameobjectname = "zstandard zgrief";

				if (object.origin == (-6460.7, -7115, 6.8))
				{
					object setModel("veh_t6_civ_microbus_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 100;
					object.angles += (0, 180, 0);
				}
				else if (object.origin == (-6550.5, -6901.7, 6.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 160;
					object.origin += anglesToRight(object.angles) * 10;
					object.angles += (0, -90, 0);
				}
				else if (object.origin == (-6251.1, -6449.4, 20.8))
				{
					object setModel("veh_t6_civ_60s_coupe_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 90;
					object.origin += anglesToRight(object.angles) * 25;
				}
				else if (object.origin == (-5822.9, -6434.6, 20.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 200;
					object.angles += (0, 120, 0);
				}
				else if (object.origin == (-5589.5, -6310.3, 24.8))
				{
					object2 = spawn("script_model", object.origin);
					object2.angles = object.angles;
					object2 setModel("p6_zm_rocks_medium_05");
					object2.origin += anglesToUp(object2.angles) * -80;
					object2.origin += anglesToForward(object2.angles) * 215;
					object2.origin += anglesToRight(object2.angles) * 215;
					object2.angles += (0, 90, 0);

					object setModel("p6_zm_rocks_medium_05");
					object.origin += anglesToUp(object.angles) * -80;
					object.origin += anglesToForward(object.angles) * 125;
					object.origin += anglesToRight(object.angles) * 125;
				}
				else if (object.origin == (-4813, -6665.3, 0.8))
				{
					object setModel("veh_t6_civ_60s_coupe_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 100;
				}
				else if (object.origin == (-3978.4, -6484.9, 0.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 125;
				}
				else if (object.origin == (-3902.4, -6884.9, 0.8))
				{
					object setModel("veh_t6_civ_microbus_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 50;
				}
			}
		}
	}
}

// ============================================================================
//  restore_diner_hatch  -  climb onto the roof the way you do in TranZit
//
//  User: "make the roof of the diner on the diner survival map open like how you
//  can do it in the tranzit map... i had to use the .fly cmd to get up there...
//  the zombies climb up through the gate already".
//
//  🛑 NOTHING WAS BLOCKING IT. TWO ENTITIES WERE BEING DELETED.
//
//  Straight out of the zm_transit mapents dump, the hatch is four entities:
//
//      diner_hatch             script_model      (-6295.5,-7948.5,147.5)  "zclassic"
//      diner_hatch_mantle      script_brushmodel (-6296,  -7948,  145)    "zclassic"
//      diner_hatch_collision   script_brushmodel (-6295,  -7948,  135)    (none)
//      diner_hatch_trigger     trigger_multiple  (-6288,  -7948,  104)    (none)
//
//  script_gameobjectname is a space-separated list of the game modes an entity
//  is allowed in, and _zm_gametype::game_objects_allowed() DELETES every entity
//  whose list does not contain the current mode. Survival is "zstandard", so the
//  two marked "zclassic" - the hatch itself and, fatally, the MANTLE you pull
//  yourself up on - are deleted before the round starts. The collision and the
//  trigger have no list at all, so they survive in every mode and the loop never
//  even looks at them.
//
//  That is the whole difference between TranZit and Diner survival at this spot,
//  and it explains every symptom at once: the opening looks open (the lid model
//  is gone), zombies still come up (they use a node_negotiation traversal,
//  zm_traverse_diner_roof_hatch_up, which is pathing data and not a game object),
//  and the player cannot follow (no mantle).
//
//  "[all_modes]" is entity_is_allowed()'s own early-out, so this is not a
//  workaround - it is the value the function is written to accept. The same
//  rewrite-before-the-filter trick is already used further down this file to
//  convert the "zcleansed zturned" cars into survival props; it works because
//  struct_init() runs out of struct_class_init() during _load::main(), and
//  game_objects_allowed() is not threaded until rungametypemain() later.
//
//  📝 The reusable rule: when something works in one game mode and not another on
//  the SAME map, diff script_gameobjectname before looking at script at all. The
//  map is one map; the modes are subtractive.
// ============================================================================
restore_diner_hatch()
{
	a_names = array( "diner_hatch", "diner_hatch_mantle" );

	for ( i = 0; i < a_names.size; i++ )
	{
		a_ents = getentarray( a_names[i], "targetname" );

		for ( j = 0; j < a_ents.size; j++ )
			a_ents[j].script_gameobjectname = "[all_modes]";

		println( "[zm_qol] diner hatch: kept " + a_ents.size + " x " + a_names[i] );
	}
}

// zm_qol: stock T6 always precaches before setmodel. Every model below was
// checked against the xmodel inventory of all 191 fastfiles in zone/all - the
// first six ship in zm_transit/common_zm, and the last two only in
// so_zsurvival_zm_transit, so mod.ff now carries those two (see
// zone_source/mod_locations.zone) and they are safe to precache in every mode.
precache()
{
	precachemodel( "afr_barrel_biohazard_white_rust" );
	precachemodel( "collision_wall_64x64x10_standard" );
	precachemodel( "p6_zm_rocks_medium_05" );
	precachemodel( "veh_t6_civ_60s_coupe_dead" );
	precachemodel( "veh_t6_civ_microbus_dead" );
	precachemodel( "veh_t6_civ_smallwagon_dead" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "zm_collision_transit_diner_survival" );

	// zm_qol: 🛑 loc_common::increase_pap_collision() setmodel's this, and NOTHING
	// IN THIS PROJECT PRECACHED IT. Reimagined gets away without a precache here
	// because its replaced\_zm_perks.gsc does it for every map; that file was
	// never ported, so calling increase_pap_collision() from Diner without this
	// line would have silently left the collision entity on its spawn model - the
	// same silent-setmodel failure that once left a perk bottle where the
	// Wunderfizz bear should have been.
	//
	// Safe on every map, not just this one: it lives in common_zm.ff, which every
	// zombies map loads. Checked, because precaching a model the level does not
	// have is fatal at load rather than silent.
	precachemodel( "zm_collision_perks1" );

	// The Pack-a-Punch and its "please wait" flag. Both are in zm_transit.ff, so
	// they are there in survival as much as in TranZit - the fastfile does not
	// care about game mode, only the entity filter does.
	precachemodel( "p6_anim_zm_buildable_pap_on" );
	precachemodel( "zombie_sign_please_wait" );
}

main()
{
	// zm_qol: guarded. Writing a field on an undefined array entry is fatal in GSC and
	// these two zone names are hardcoded rather than iterated. Everything else in this
	// file is Reimagined's original - the props, barriers and re-modelling were briefly
	// stripped while chasing a crash that turned out to be an unrelated duplicate
	// #include in zm_transit.gsc, and have been restored in full.
	// zm_qol: 🛑 zone_diner_roof IS NO LONGER DISABLED. Reimagined turned it off,
	// which was right when the roof was unreachable - a zone nobody can stand in
	// is dead weight, and this project's own notes record what an unmanaged zone
	// costs. Now that restore_diner_hatch() puts the climb back and Pack-a-Punch
	// is up there, the roof is somewhere players will spend rounds, so it has to
	// be a live zone: that is what makes zombies path to it and what stops a
	// player standing in an area the zone manager is not tracking.
	//
	// Only this one zone, and only because it is the diner's own roof. Enabling
	// zones speculatively is the other half of this project's zone problem -
	// too few and you get a death barrier, too many and the horde scatters
	// across the map instead of coming to the arena.
	//
	// zone_trans_diner2 stays off - it is a separate area, nothing here reaches it.
	if ( isdefined( level.zones ) && isdefined( level.zones["zone_trans_diner2"] ) )
		level.zones["zone_trans_diner2"].is_enabled = 0;

	treasure_chest_init();
	init_barriers();
	generatebuildabletarps();
	disable_zombie_spawn_locations();

	// zm_qol: Diner has a Pack-a-Punch now, so it wants the same collision pass
	// every other PaP location gets - Reimagined calls this from tunnel, power,
	// cornfield and docks main(). It pushes the machine's clip back so you cannot
	// get wedged between it and the wall behind it.
	scripts\zm\locs\loc_common::increase_pap_collision();

	level thread scripts\zm\locs\loc_common::init();
	println( "[zm_qol] diner main: DONE" );
}

treasure_chest_init()
{
	chest = getstruct("start_chest", "script_noteworthy");
	level.chests = [];
	level.chests[0] = chest;
	maps\mp\zombies\_zm_magicbox::treasure_chest_init("start_chest");
}

init_barriers()
{
	collision = spawn("script_model", (-5000, -6700, 0), 1);
	collision setmodel("zm_collision_transit_diner_survival");
	collision disconnectpaths();

	origin = (-6350, -7046, -60);
	angles = (0, 165, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_64x64x10_standard", origin + (anglesToUp(angles) * 32), angles, 1);
	scripts\zm\locs\loc_common::barrier("collision_wall_64x64x10_standard", origin + (anglesToUp(angles) * 96), angles, 1);
	scripts\zm\locs\loc_common::barrier("afr_barrel_biohazard_white_rust", origin + (anglesToForward(angles) * -24) + (anglesToRight(angles) * -16) + (anglesToUp(angles) * 14), angles + (0, 90, 90));
}

generatebuildabletarps()
{
	tarp = spawn("script_model", (-4688, -7974, -64));
	tarp.angles = (0, 0, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

disable_zombie_spawn_locations()
{
	for (z = 0; z < level.zone_keys.size; z++)
	{
		zone = level.zones[level.zone_keys[z]];

		i = 0;

		while (i < zone.spawn_locations.size)
		{
			if (zone.spawn_locations[i].targetname == "zone_trans_diner_spawners")
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].targetname == "zone_trans_diner2_spawners")
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-3825, -6576, -52.7))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-5130, -6512, -35.4))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6462, -7159, -64))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6531, -6613, -54.4))
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}
	}
}