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
	// Yaw 2 -> 270 -> 90, and y -7708 -> -7668. "It's facing the complete opposite
	// direction and it's too far away from the wall."
	//
	// The angle history is worth one paragraph because each wrong answer came from
	// a different mistake, and only the last one is about this machine:
	//
	//   2    v1.44.0 faced it back down the user's line of sight. That is the
	//        WUNDERFIZZ convention, and it does not transfer - that machine is
	//        positioned by tracing a wall, so its seed yaw and the wall are
	//        related. Here the seed was just where someone happened to stand, and
	//        2 degrees is not parallel to anything.
	//   270  v1.45.0 fixed the axis (the roof is axis-aligned; its pathnodes box in
	//        at x -6364..-5878, y -7829..-7656, so every parapet runs due N/S or
	//        E/W and only multiples of 90 can look deliberate) and then guessed the
	//        SIGN, assuming this model's front is its +X like most props.
	//   90   it is not. This landed on the right answer and recorded the WRONG
	//        REASON for it: "front = placement + 180". One observation cannot
	//        distinguish +180 from -90 when the alternative you are testing is
	//        180 degrees away, and that unearned conclusion is what sent v1.48.0
	//        back to 180. The real relation is front = placement - 90; see the
	//        block below.
	//
	// 🛑 THE MODEL'S FRONT IS NOT ITS +X, AND THIS IS THE SECOND TIME THAT HAS COST
	// A BUILD - the Wunderfizz needed the same correction (see wunderfizz.gsc's
	// zmqol_wf_yaw_off), and it turns out to be the SAME OFFSET. Neither model
	// announces it and neither can be inspected offline. For a T6 machine prop,
	// try front = placement - 90 first.
	//
	// ✅ v1.48.0 - MEASURED, NOT ESTIMATED. The user stood on the spot, facing the
	// way the machine should face, and ran .where:
	//
	//     x -6384   y -7718   z 226   yaw 3
	//
	// That one line is the whole specification and it replaces four
	// screenshot-derived guesses. A photograph carries direction but not distance,
	// so "over there" always resolved to a band a couple of hundred units wide.
	// A .where line has no band.
	//
	// Two corrections on top, both measured rather than felt:
	//
	// 1. YAW 3 -> 90. The roof is axis-aligned, so a hand-aimed 3 means 0: the
	//    FRONT should point at world +X, away from the west parapet.
	//
	//    🛑 FRONT = PLACEMENT - 90. v1.48.0 used "front = placement + 180" and got
	//    yaw 180, which the user called "sideways" - 90 degrees off, exactly the
	//    error that relation carries.
	//
	//    The right relation was recoverable from the reports alone, and I did not
	//    read them as a set. Laid out together they are unambiguous:
	//
	//        yaw   2   "sideways"
	//        yaw 270   "facing the complete opposite direction"
	//        yaw  90   no facing complaint, twice
	//        yaw 180   "sideways"
	//
	//    90 accepted and 270 its exact opposite; 2 and 180 both wrong by a quarter
	//    turn. That is a complete, self-consistent picture of the convention, and
	//    it was available before v1.48.0 shipped - I re-derived the offset from a
	//    single new screenshot instead of checking it against the four readings
	//    already in hand.
	//
	//    📝 WHEN A VALUE HAS BEEN WRONG SEVERAL TIMES, THE HISTORY IS THE DATASET.
	//    Every past attempt is a labelled sample; a new observation is one more.
	//    Fit the rule to all of them.
	//
	//    And the answer is the same convention as the Wunderfizz - see
	//    wunderfizz.gsc, "front direction = placement yaw - 90". Two T6 machine
	//    props now share it, which makes it the thing to try FIRST rather than a
	//    quirk of one model.
	//
	// 2. X -6384 -> -6378, for the difference between a player's box and a
	//    cabinet. 🛑 THE DEPTH IS NOW KNOWN RATHER THAN ASSUMED. Dumped the model,
	//        Unlinker --include-assets xmodel --model-format GLB <map>.ff
	//    and read the POSITION accessor bounds straight out of the GLB's JSON
	//    chunk:
	//
	//        85.7 wide    47.5 deep    92.9 tall
	//
	//    and the depth is ASYMMETRIC about the origin - it runs -27.2 to +20.3 on
	//    the front-back axis. The back face is only 20.3 units behind the origin
	//    while the front sticks out 27.2. A player's box is 30 wide, so someone
	//    standing with their back to a wall has their origin ~15 units off it and
	//    this cabinet needs ~20. Six units further from the wall puts the
	//    machine's back exactly where the user's back was.
	//
	// 📝 AN XMODEL'S REAL BOUNDING BOX IS READABLE OFFLINE - every GLB carries
	// min/max per accessor. Model dimensions never have to be estimated again, and
	// "how far off the wall" stops being a matter of taste. This is the same class
	// of win as the mapents dump: the game files answer it, so do not reason about
	// it.
	// The POSITION is confirmed good by the user ("it's the right position almost")
	// and is left exactly as v1.48.0 placed it - only the yaw was wrong.
	v_pap = ( getdvarintdefault( "zmqol_pap_diner_x", -6378 ), getdvarintdefault( "zmqol_pap_diner_y", -7718 ), getdvarintdefault( "zmqol_pap_diner_z", 226 ) );
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", v_pap, (0, getdvarintdefault( "zmqol_pap_diner_yaw", 90 ), 0));

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
//  That is the whole difference between TranZit and Diner survival at this spot.
//  Zombies still come up regardless - they use a node_negotiation traversal,
//  zm_traverse_diner_roof_hatch_up, which is pathing data and not a game object -
//  and the player cannot follow, because the ladder and the mantle are both gone.
//
//  (This paragraph used to add "the opening looks open, the lid model is gone".
//  It is not open and diner_hatch is not a lid; see the correction below.)
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
//
// ----------------------------------------------------------------------------
//  🛑 WHICH ENTITY IS WHICH - SETTLED ON THE THIRD TRY, AND THE MISTAKE IS THE
//  INTERESTING PART.
//
//  Two wrong guesses were made about the four entities above, and both came from
//  reading their NAMES instead of their types:
//
//    v1.44.0  restored diner_hatch + diner_hatch_mantle. Report: "the roof is
//             still blocked off by the hatch but the ladder is there and when i
//             get close to it i see the prompt climb or mount". Read as "the lid
//             I restored is in the way".
//    v1.45.0  dropped diner_hatch again, keeping only the mantle. Report: "the
//             hatch is still there and now the little ladder is missing".
//
//  The second report is the one that decides it, because it separates the two
//  things. The blocker survived the deletion of diner_hatch, and the LADDER
//  disappeared with it. So:
//
//    diner_hatch            the ladder / step you climb. NOT the lid.
//    diner_hatch_collision  the closed panel. THE BLOCKER.
//
//  And the reason that was ever in doubt: a script_brushmodel is not invisible.
//  It carries a brush model index ("*302") and RENDERS like any other geometry.
//  "collision" in a targetname is a level designer's label, not a statement that
//  the thing has no faces. Both wrong guesses assumed a name ending in _collision
//  must be an invisible clip and a thing called _hatch must be the lid.
//
//  🛑 THE RULE: an entity's CLASSNAME tells you what it is; its TARGETNAME tells
//  you what someone called it. When they disagree, the classname wins. Two builds
//  went on trusting the label over the type.
//
//  So the shape that is actually wanted, and none of it matches "reproduce stock":
//  keep both zclassic entities so the ladder and the mantle exist, and DELETE the
//  all-modes collision panel that neither mode ever opens.
// ----------------------------------------------------------------------------
restore_diner_hatch()
{
	//  The ladder and the mantle - the climb itself. Both are zclassic-only, so in
	//  survival both are deleted before the round starts and there is nothing to
	//  climb even when the way is clear.
	a_names = array( "diner_hatch", "diner_hatch_mantle" );

	for ( i = 0; i < a_names.size; i++ )
	{
		if ( i == 0 && !getdvarintdefault( "zmqol_diner_hatch_ladder", 1 ) )
			continue;

		a_ents = getentarray( a_names[i], "targetname" );

		for ( j = 0; j < a_ents.size; j++ )
			a_ents[j].script_gameobjectname = "[all_modes]";

		println( "[zm_qol] diner hatch: kept " + a_ents.size + " x " + a_names[i] );
	}

	//  The panel over the hole. Deleted, which is the only part of this that is a
	//  genuine departure from stock - TranZit keeps it too, and TranZit players get
	//  onto that roof some other way. Nothing in the 2,093-file stock dump ever
	//  touches this targetname, so there is no "open the hatch" behaviour being
	//  bypassed here; the panel is simply shut in both modes and the user wants it
	//  gone in this one.
	//
	//  connectpaths() before delete() because a solid brushmodel may be holding a
	//  path connection closed - stock's own game_objects_allowed() does exactly
	//  this pairing before deleting an entity it has filtered out.
	if ( getdvarintdefault( "zmqol_diner_hatch_clip", 0 ) == 0 )
	{
		a_ents = getentarray( "diner_hatch_collision", "targetname" );

		for ( i = 0; i < a_ents.size; i++ )
		{
			a_ents[i] connectpaths();
			a_ents[i] delete();
		}

		println( "[zm_qol] diner hatch: DELETED " + a_ents.size + " x diner_hatch_collision" );
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
			// zm_qol 2026-08-09: 🛑 THE "ZOMBIE HOPS THROUGH A FULLY BOARDED WINDOW" BUG.
			//
			// These two are zone_diner_roof's ONLY regular-zombie spawners, and both sit
			// on the GROUND ~220 units SOUTH of the diner's window line (the barriers are
			// at y = -8035; the diner interior is north of them). Reimagined never hit
			// this because it disables zone_diner_roof outright; this project deliberately
			// keeps that zone enabled so the roof is tracked for the Pack-a-Punch climb
			// (see main() above), which switched these two back on.
			//
			// Why they let a zombie walk through six intact planks - every link measured,
			// not inferred:
			//   1. both carry script_string "find_flesh"  (zm_transit mapents)
			//   2. _zm_spawner::should_skip_teardown() returns TRUE for exactly that
			//      string, so zombie_think() takes the early-return branch and NEVER
			//      calls tear_into_building() - no boards, no attack spot, no teardown
			//   3. they free-path with find_flesh() instead, and the diner barrier carries
			//      a node_negotiation_begin with animscript "zm_mantle_over_40"
			//   4. _zm_blockers::blocker_disconnect_paths() - the one thing that would
			//      close that path while boards are up - is an EMPTY STUB. Confirmed by
			//      decompiling the shipped patch_zm.ff copy, not just the gsc-dump.
			// So the mantle node is always live and the shortest route from spawn to a
			// player inside is straight over the window. Exactly "hopped over straight
			// through this barrier while all 6 planks were built".
			//
			// 🌟 Disabling these two is complete and side-effect free: the zone's other
			// three spawners are tagged dog_location / avogadro_location, which
			// _zm_zonemgr.gsc:227-248 files into zone.dog_locations / .avogadro_locations
			// and NEVER into zone.spawn_locations. This loop only walks spawn_locations,
			// so hellhounds and the Avogadro are untouched and the roof loses nothing -
			// it never had a regular-zombie spawner up there to begin with.
			else if (zone.spawn_locations[i].origin == (-5756.5, -8254, -0.86))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6171.5, -8270, -4.39))
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}
	}
}