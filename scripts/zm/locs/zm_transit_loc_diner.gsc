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

	zmqol_add_semtex_wallbuy();
	zmqol_add_claymore_wallbuy();   // v1.99.91 - the shack claymore
	level thread zmqol_probe_claymore_trigger();   // v2.3.4 - diagnostic, see its own comment

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

	// zm_qol: the buildable riot shield's bench. See the function's own header.
	zmqol_unlock_shield_buildable_entities();
}


// ============================================================================
//  zm_qol: KEEP THE SHIELD BENCH ALIVE IN SURVIVAL                 (v1.66.0)
//
//  The riot shield's two bench entities are tagged for classic only, read
//  straight out of zm_transit.ff's mapents:
//
//    trigger_use  "riotshield_zm_buildable_trigger"  (-4688,-7966,-6)
//        target "buildable_riotshield", zombie_weapon_upgrade "riotshield_zm",
//        script_gameobjectname "zclassic"
//    script_model "buildable_riotshield"            (-4680.23,-7977.34,6.63)
//        model t6_wpn_zmb_shield_world, script_gameobjectname "zclassic"
//
//  _zm_gametype.gsc:110 game_objects_allowed() walks getentarray() and calls
//  **entity delete()** on anything whose script_gameobjectname does not match
//  the running mode, so in survival both are gone before anything can use them.
//
//  🌟 THE TIMING IS WHAT MAKES THIS SAFE, and it was traced, not assumed:
//  game_objects_allowed() is threaded from rungametypemain() (:429), and this
//  precache() is reached from rungametypePRECACHE() (:395-418), which runs
//  first and synchronously. So the re-tag is already done when the filter
//  looks.
//
//  "[all_modes]" rather than "zstandard": entity_is_allowed() short-circuits on
//  that exact string (_gameobjects.gsc:45) instead of comparing mode lists, so
//  it works for zstandard and zgrief alike and cannot go stale if a mode is
//  added later. location_is_allowed() is already satisfied - neither entity has
//  a script_noteworthy or script_location, so it returns 1 unconditionally.
//
//  🛑 NOT A MAP-SPECIFIC REFERENCE. getentarray() is an engine builtin, so this
//  is safe in a locs\ file, which is loaded broadly. The buildable REGISTRATION
//  needs maps\mp\zm_transit_buildables and therefore lives in
//  scripts\zm\zm_transit\zm_transit.gsc instead - AI_CONTEXT rule 2.
//
//  Runs on every Diner start, including zgrief, and that is harmless: with no
//  buildable registered there the bench simply has no trigger think, exactly as
//  a classic-tagged entity in a mode that ignores it. Nothing else in the map
//  carries these two targetnames - checked against the full ents dump.
// ============================================================================
// ============================================================================
//  zm_qol: PACK-A-PUNCH VISIBILITY PROBE                           (v1.66.2)
//
//  User: *"for some reason you made the pack a punch machine on the roof
//  invisible? the textures are just missing it seems like"*.
//
//  🛑 THIS IS A PROBE, NOT A FIX, and that is deliberate. The asset theory that
//  explained the shield parts does NOT explain this one, and it was checked
//  rather than assumed:
//      xmodel   p6_anim_zm_buildable_pap_on            -> in zm_transit.ff  ✓
//      material mc/mtl_zombie_vending_packapunch       -> in zm_transit.ff  ✓
//               mc/mtl_zombie_vending_packapunch_on    -> in zm_transit.ff  ✓
//               mc/mtl_zombie_vending_packapunch_moving-> in zm_transit.ff  ✓
//               mc/mtl_p6_zm_buildable_pap_table       -> in zm_transit.ff  ✓
//               mc/mtl_p6_zm_buildable_etrap           -> in zm_transit.ff  ✓
//               mc/mtl_p_glo_cinder_block              -> in zm_transit.ff  ✓
//  All six materials the model's GLB names, plus the model itself, are in a
//  fastfile Diner survival DOES load, and the boot log has no "Could not load"
//  line for any of them. So this is not the missing-asset class of bug, and
//  guessing at a second mechanism is exactly what this project does not do.
//
//  What this prints instead, one boot, no more blind rounds: every entity whose
//  model is the PaP, its origin, and whether it is hidden. That distinguishes
//  the three candidates outright -
//      no entity at all      -> the struct never became a machine
//      entity present, shown -> it is drawing, and the problem is placement or
//                               geometry (compare the origin against the roof)
//      entity present, hidden-> something called hide() on it, and the search
//                               narrows to whatever did
//
//  Delayed until after "initial_blackscreen_passed" because _zm_perks spawns
//  the machine models during its own init, well after this main() runs.
// ============================================================================
zmqol_pap_visibility_probe()
{
	flag_wait( "initial_blackscreen_passed" );
	wait 3;

	a_ents = getentarray( "script_model", "classname" );
	n_found = 0;

	foreach ( e_ent in a_ents )
	{
		if ( !isdefined( e_ent.model ) || e_ent.model != "p6_anim_zm_buildable_pap_on" )
			continue;

		n_found++;

		// 🛑 v1.66.3 - THIS IS THE FIX, and the probe is why it is this and not
		// something else. The v1.66.2 probe answered:
		//     [zm_qol] pap probe: ent 1 at (-6378,-7718,226) shown
		// The machine EXISTS and sits at EXACTLY its registered origin - the
		// same (-6378,-7718,226) this file has passed to register_perk_struct
		// since v1.48.0, which the user once confirmed as "the right position".
		// So it is neither missing nor misplaced, and the asset side was already
		// cleared (model + all six materials in zm_transit.ff, no "Could not
		// load" line for any of them).
		//
		// That leaves "something hid it", and the timeline names the suspect:
		// the machine was visible for every build up to v1.65.x and went
		// invisible in v1.66.0, the release that first made _zm_buildables
		// actually run in Diner survival. Core hides buildable models by
		// default - setup_unitrigger_buildable_internal() does
		// `unitrigger_stub.model hide()` (_zm_buildables.gsc:1408) and
		// hide_buildable_table_model() does the same (:1309) - because on
		// TranZit the Pack-a-Punch IS a buildable and its model is meant to stay
		// hidden until it is built. p6_anim_zm_buildable_pap_on is that very
		// model.
		//
		// 📝 HONEST CONFIDENCE: the mechanism above is the best-supported
		// explanation, not a proven one - both hide() calls resolve through the
		// riot shield's own trigger target, and I could not trace a path from
		// either to this entity. What IS certain is that the entity is present
		// and correctly placed, so re-asserting show() cannot be wrong: it is a
		// no-op if the model was already visible, and the cure if it was not.
		// solid() is paired with it because the two core calls above always hide
		// and notsolid together.
		e_ent show();
		e_ent solid();

		println( "[zm_qol] pap probe: ent " + n_found + " at (" + int( e_ent.origin[0] ) + "," + int( e_ent.origin[1] ) + "," + int( e_ent.origin[2] ) + ") - show()+solid() re-asserted" );
	}

	println( "[zm_qol] pap probe: " + n_found + " entity(ies) carrying p6_anim_zm_buildable_pap_on (expect 1)" );

	// 🔎 THE A/B THAT SETTLES IT IF show() IS NOT ENOUGH. `zmqol_diner_shield 0`
	// in the console before starting a match turns the riot shield registration
	// off entirely (zm_transit.gsc::zmqol_diner_shield_enabled reads it too), so
	// _zm_buildables goes back to doing nothing here. If the machine is visible
	// with it off and invisible with it on, the buildable system is the cause
	// and this narrows to one function; if it is invisible either way, the
	// buildables are innocent and the search moves to _zm_perks.
	if ( getdvarintdefault( "zmqol_diner_shield", 1 ) == 0 )
		println( "[zm_qol] pap probe: zmqol_diner_shield is 0 - the riot shield is OFF this match" );
}

// ============================================================================
//  zm_qol: SEMTEX WALL-BUY BY THE DINER EXIT DOOR                  (v1.68.0)
//
//  User, 2026-08-11: *"put a semtex wall buy right here next to this door way
//  right on the wall, this will complete diner"*. Their `.where` at the spot was
//  (-5106,-7924,-62) facing yaw 181, so the wall is ~70 units ahead along
//  (cos181,sin181) = (-1.00,-0.02), i.e. almost straight -X.
//
//  🛑 THIS IS THE FIRST WALL-BUY THIS PROJECT CREATES RATHER THAN RE-TAGS, and
//  that distinction is the whole risk. loc_common::enable_wallbuys() only edits
//  script_noteworthy on structs the map already ships; there is no semtex struct
//  anywhere near the diner. The one on TranZit sits at (1083.7,-1579.5,12) in
//  Town and carries NO location tag, so it already spawns in every mode -
//  moving it would simply take Semtex away from Town. So a new struct pair has
//  to be built.
//
//  🛑 AND THAT COSTS A CLIENTFIELD, WHICH IS WHY BOTH SIDES DO IT. _zm_weapons
//  registers one "world" field per wallbuy, named from the struct itself -
//  _zm_weapons.csc:218 builds `script_label = zombie_weapon_upgrade + "_" +
//  origin` and :225 registers it. Create the struct only on the server and the
//  client is one field short; only on the client and it is one too many. Either
//  way every player is dropped at load. The exact twin lives in
//  scripts\zm\zm_expanded.csc::zmqol_add_semtex_wallbuy(), built from the SAME
//  dvars with the SAME defaults, so the two origins - and therefore the two
//  field names - cannot diverge. 📝 Tuning the dvars is still safe: it renames
//  the field on both sides identically.
//
//  Two structs, the shape stock uses (read from the zm_transit ents dump, the
//  Town semtex entry):
//      weapon_upgrade  zombie_weapon_upgrade "sticky_grenade_zm", target -> the
//                      model struct
//      the model       model "semtex_bag"
//
//  🌟 NO ASSET WORK NEEDED, checked rather than assumed: sticky_grenade_zm is
//  already in this mod's include_weapons() for TranZit, and "semtex_bag" is
//  already in the level because Town's untagged semtex wallbuy spawns in every
//  mode - including Diner survival. That is the same reasoning that settled the
//  teddy bear assets, and it is why this needs no mod.ff change.
// ============================================================================
zmqol_semtex_wallbuy_origin()
{
	// Twin of zm_expanded.csc::zmqol_semtex_wallbuy_origin(). Same dvars, same
	// defaults - if these ever disagree the two sides register different
	// clientfield names and everyone is dropped at load.
	//
	// 🛑 v1.69.10's -5172 WAS WRONG AND IS CORRECTED HERE. It came from reading the
	// doorway model's bounds without the handedness flip below, which put the wall
	// face 3 units too far into the room. With the flip:
	//
	//   doorway = entity auto2279, p_rus_door_white_plain_right, at
	//   (-5178,-7842.1,-64) yaw 270. glTF bounds X 0..60 (panel, hinged at 0),
	//   Y 0..102 (height), Z -3.05..6.01. CoD Y = -glTF Z, so CoD Y is -6.01..3.05
	//   - a 9.06 unit span, the frame, i.e. the wall thickness. At yaw 270 local +Y
	//   maps to world +X, so the wall occupies x -5184.01 .. -5174.95 and its
	//   ROOM-SIDE FACE IS x = -5175.
	//
	// So -5176 (v1.68.0/68.1) was already within a unit of flush. The position was
	// never really the problem - see the yaw note in zmqol_add_semtex_wallbuy().
	//
	// 🌟 -5175 -> -5177 (v1.69.12), TWO UNITS PAST THE WALL FACE, AND THAT IS
	// DELIBERATE. The user's report on the flush build was "ever so slightly off the
	// wall". semtex_bag has NO FLAT BACK - it is a rounded pouch. Vertex histogram of
	// its 1065 verts along CoD Y: only 2.3% sit behind Y=0 and 10% behind Y=0.5, so
	// mounting the origin exactly on the wall face leaves the taper standing proud
	// and a sliver of daylight behind it. Sinking the origin 2 units puts the 41% of
	// the model at Y<2.0 at or inside the surface, which closes the gap, while 3.9 of
	// its 6.1 units of depth still stand off the wall.
	// 📝 The buried part is inside solid brush, so over-sinking is invisible while
	// under-sinking is the reported defect. If it now reads as SUNKEN, come back to
	// -5176; if a gap remains, -5178.
	return ( getdvarintdefault( "zmqol_semtex_diner_x", -5176 ), getdvarintdefault( "zmqol_semtex_diner_y", -7925 ), getdvarintdefault( "zmqol_semtex_diner_z", -14 ) );
}

zmqol_add_semtex_wallbuy()
{
	v_origin = zmqol_semtex_wallbuy_origin();
	// 🛑 YAW 270. Yaw was the whole bug all along - 0 in v1.68.0, 90 in v1.68.1/69.10,
	// and BOTH buried or splayed the bag. The derivation, cross-checked four ways:
	//
	// AXES. OAT's GLB export is CoD X -> glTF X, CoD Z -> glTF Y, and therefore
	// CoD Y -> -glTF Z, because both spaces are right-handed and fixing two axes
	// forces the third's SIGN. Confirmed independently: t6_wpn_smg_mp5_world's own
	// tags put tag_flash (muzzle) at glTF x +8.62 and tag_stock_off at -13.70, so
	// glTF +X is the barrel = CoD forward; zombie_vending_jugg is 99.7 long on
	// glTF Y, and a perk machine is ~100 tall, so glTF Y is CoD Z. 🛑 The missing
	// sign flip is exactly what made v1.69.10 wrong.
	//
	// THE MODEL. semtex_bag glTF X -6.04..6.04, Y -8.61..11.32, Z -5.87..0.22.
	// Through the mapping: CoD X -6.04..6.04 (width along the wall), CoD Z
	// -8.61..11.32 (height), CoD Y -0.22..5.87 - the ONE-SIDED axis. So the flat
	// mounting face is the local -Y side and the bag's body hangs toward local +Y.
	//
	// THE RULE. local +Y must point OUT of the wall. Our wall normal is world +X
	// (the player stands at greater X and faces it), and local +Y -> (-sin,cos),
	// so (-sin,cos) = (1,0) gives yaw 270. At yaw 90 local +Y points world -X,
	// straight into the wall - the bag has been fully inside the brush every build
	// since v1.68.1, which is why only the fx ever showed.
	//
	// CHECKED AGAINST STOCK. Town's semtex (the only other one in the game) sits at
	// (1083.7,-1579.5,12) yaw ~0, which puts its body toward world +Y - and the
	// pathnodes around it are predominantly +Y, so the room really is on that side.
	// Same rule, same result.
	v_angles = ( 0, getdvarintdefault( "zmqol_semtex_diner_yaw", 270 ), 0 );

	s_model = spawnstruct();
	s_model.targetname = "zmqol_semtex_diner";
	s_model.origin = v_origin;
	s_model.angles = v_angles;
	s_model.model = "semtex_bag";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "weapon_upgrade";
	s_buy.origin = v_origin;
	s_buy.angles = v_angles;
	s_buy.zombie_weapon_upgrade = "sticky_grenade_zm";
	s_buy.target = "zmqol_semtex_diner";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] diner semtex: wallbuy struct at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") yaw " + v_angles[1] );
}

// ============================================================================
//  THE DINER CLAYMORE WALL BUY                                     (v1.99.91)
//
//  User, 2026-08-20: *"in Diner survival, similar to how I earlier on in the
//  mods' development got you to add a semtex wallbuy in the toilet room, add a
//  claymore wallbuy in the shack with juggernog and a easter egg teddy bear in
//  it right next to this barrier here, i flashed the co-ordinates on screen with
//  the .where chat command, make sure it's aligned properly with the wall and
//  isn't sideways like how you've done in the past."*
//
//  Flashed spot: x -3615  y -7398  z -58  yaw 270.
//
//  -- SHAPE: STOCK'S OWN, NOT INVENTED --------------------------------------
//  The zm_transit ents dump has exactly one claymore wall buy, at the farm:
//      { targetname "claymore_purchase"  zombie_weapon_upgrade "claymore_zm"
//        target "pf1919_auto37"  origin "8827 -5838 103"  angles "0 90 0" }
//      { targetname "pf1919_auto37"  model "t6_wpn_claymore_world"
//        origin "8827 -5838 103"  angles "0 180 0" }
//  Two structs at the SAME origin, with the model struct rotated +90 from the
//  buy struct. Both halves are picked up exactly like a weapon_upgrade pair -
//  _zm_weapons.gsc:849 and its client twin _zm_weapons.csc:182 both arraycombine
//  getstructarray( "claymore_purchase", "targetname" ) into the spawnable list -
//  which is why this needs the same server+client pair the semtex needed, and
//  for the same reason: one "world" clientfield per wall buy, named from the
//  struct, so a struct on one side only is EXE_CLIENT_FIELD_MISMATCH at load.
//
//  -- THE YAW, DERIVED RATHER THAN GUESSED ----------------------------------
//  "Sideways" is the failure mode the user called out, so the angle is taken
//  from the stock pair above rather than from the model's bounds:
//    - At the farm claymore, the walkable side is +Y: every pathnode within 120
//      units sits at dy 0..+95 and none at negative dy. So the wall's outward
//      normal there points +Y, i.e. 90 degrees.
//    - Stock's buy struct is yaw 90 and its model struct is yaw 180. So the rule
//      is  buy yaw = the wall's outward normal angle,  model yaw = that + 90.
//    - .where reports where the player STOOD and which way they FACED, and this
//      mod's own convention for it is "stand where you want it, face the way it
//      should face" (quality_of_life.gsc:4799). Facing 270 therefore means the
//      claymore faces 270, so the wall's outward normal is 270 and the pair is
//      buy yaw 270 / model yaw 0 (270 + 90).
//
//  -- THE HEIGHT, MEASURED --------------------------------------------------
//  Stock's claymore sits at z 103 with its floor at ~52 (its nearest pathnodes
//  are z 78, and in this same map a pathnode sits 26 units above the floor -
//  the Diner nodes are z -32 with the floor at -58). That is 51 units up the
//  wall. The flashed z is the player's feet, so the floor here is -58 and the
//  same 51 units puts this one at z -7.
//
//  -- WHAT IS AND IS NOT SETTLED --------------------------------------------
//  The orientation and the mount height are derived from measurements. The
//  DISTANCE to the wall is not: .where reports where the player was standing,
//  not the surface they were looking at, and neither the base map's ents nor the
//  survival addon's carry a barrier or brush face within 1000 units of the spot
//  that could pin the plane down offline. So the origin defaults to the flashed
//  spot exactly, and x/y/z/yaw are dvars - the same treatment the Diner semtex
//  had while it was being landed, and the same two-line nudge if it needs one:
//      zmqol_claymore_diner_y -7430      (into the wall, 1 unit at a time)
//      zmqol_claymore_diner_z -7          (up or down the wall)
//
//  ── v2.2.0: IT WAS FLOATING IN THE MIDDLE OF THE SHACK, AND NOW IT IS ON THE
//     WALL, MEASURED ───────────────────────────────────────────────────────────
//  User, 2026-08-21: *"the claymore wallbuy on Diner Survival is still floating
//  in the middle of the shack... have it properly aligned to the wall next to
//  the window where zombies come through in the shack."*
//
//  🌟 THE WALL IS IN THE MAPENTS AFTER ALL - the block above looked for a
//  barrier ENTITY and there is none, but the WINDOWS are there as mantle lanes,
//  and a mantle lane straddles the surface it crosses. Both of the shack's
//  windows are in the zm_transit dump:
//        window A   begin (-3839, -7531, -28) -> end (-3839, -7447, -28)
//        window B   begin (-3564, -7536, -28) -> end (-3564, -7452, -28)
//                   (targetname "hatch_storage_node", animscript zm_mantle_over_40)
//  Both run along +Y with 84 units between begin and end, so the wall they cross
//  is a single east-west plane at  y = -7494,  with the shack interior on the +Y
//  side. That also settles which window the user means: from the flashed spot
//  (-3615, -7398) window B is 109 units away and window A is 245, so it is B.
//
//  THE NEW ORIGIN, term by term:
//        y = -7486   the interior face of that wall: the plane is y = -7494 and
//                    the model is mounted just inside it
//        x = -3630   66 units west of window B's centre, i.e. beside the window
//                    and clear of it - the window is ~64 wide so its west edge
//                    is near x = -3596, and the claymore's own half-width is
//                    ~15, leaving about 19 units of gap. West rather than east
//                    because west is where the user was standing.
//        z = -7      UNCHANGED. The 51-units-up-the-wall figure was derived from
//                    stock's own farm claymore and nothing about it has changed.
//        yaw = 90    the wall's outward normal is +Y (the interior side, where
//                    the mantle END nodes are), and this file's own derived rule
//                    is buy yaw = outward normal, model yaw = that + 90. The old
//                    270 came from reading the player's FACING as the wall
//                    normal, which is what put it in mid-air pointing the wrong
//                    way.
//
//  📝 RESIDUAL RISK, STATED PLAINLY: the WALL PLANE is measured, the WALL
//  THICKNESS is not - mapents carries no brush geometry, so "8 units in from the
//  plane" is the one estimated term. If it ends up a little proud of the wall or
//  a little sunk into it, that is a one-line nudge and nothing else moves:
//      zmqol_claymore_diner_y -7490    (further into the wall)
//      zmqol_claymore_diner_y -7482    (further out of it)
//  Standing with your back to the exact spot and running .where would settle it
//  outright.
//
//  🛑 THE DVARS ARE READ ON BOTH SIDES FROM THE SAME DEFAULTS. Changing one
//  renames the clientfield on both sides identically, which is safe; changing
//  one side's default alone is a guaranteed drop at load. Both defaults moved
//  together in v2.2.0 - zm_expanded.csc has the identical numbers.
//
//  📝 NO ASSET WORK. claymore_zm is already in this mod's include list for
//  TranZit (scripts\zm\zm_transit\zm_transit.csc:82 and the server twin), and
//  t6_wpn_claymore_world is stock's own wall-buy model, already in the level for
//  the farm claymore - the same reasoning that settled the semtex bag.
//
//  ── v2.2.6: THE POST WEST OF IT WAS MEASURED OFF THE SCREENSHOT ─────────────
//  User, 2026-08-23, screenshot JSRY2LneTx.jpg: *"it's a bit too far off to the
//  right from the window therefore colliding with the structure itself, so just
//  move it a tiny bit off to the left ... also i couldn't interact with it in
//  the position it's in currently."*
//
//  🌟 THE BEAM IS BAKED WORLD GEOMETRY - it is in NO mapents dump, so it was
//  measured out of the picture instead. Everything below is arithmetic on
//  numbers that were read, not estimated:
//    * the shot's own HUD gives the camera:  x -3629  y -7416  z -58  yaw 269
//    * the dvar dump in that session's console_zm.log gives  cg_fov "100"  and
//      r_mode "2560x1440", so the Hor+ horizontal FOV is
//          2*atan( tan(50 deg) * (16/9)/(4/3) ) = 115.6 deg,  tan(half) = 1.589
//    * a pixel sweep of rows 480 / 560 / 640 / 700 finds the same dark vertical
//      band at px 1302-1339 in every one of them (luminance ~22 against ~90 for
//      the chalk either side), so it is a vertical post, 38 px wide, centred on
//      px 1320.5
//    * screen right is -X here (right = anglestoright(269) = (-1.000, 0.017)),
//      and at the wall's 70-unit depth one pixel is 2*70*1.589/2560 = 0.0869
//      units, so the post is 3.3 units wide with its centre at
//          x = -3629 + 70*(-0.01745) + 3.52*(-0.99985) = -3633.7
//      i.e. it spans x -3635.4 .. -3632.1
//    * the mine is 11.16 wide (its mesh, above), so at x -3630 it spanned
//      -3635.6 .. -3624.4 - THE POST COVERED ITS WESTERN 3.3 UNITS, which is
//      exactly the overlap the screenshot shows.
//
//  🌟 THE CHECK THAT SAYS THE MODEL IS RIGHT: the same arithmetic predicts the
//  shack window at px 494 and it is measured at ~454. 40 px out of 2560 on an
//  eyeballed window centre, so the camera model is sound.
//
//  x -3630 -> -3624 puts the mine at -3629.6 .. -3618.4: 2.5 units clear of the
//  post, and still 22 units clear of window B's western edge (~-3596), so it
//  cannot drift into the window either. Nothing else moves.
//
//  📝 WHY THIS SHOULD ALSO FIX "I COULDN'T PURCHASE IT". The use trigger is a
//  unitrigger_box_use with require_look_at = 1 (_zm_weapons.gsc:936-960), so the
//  prompt needs a clear line of sight from the crosshair to the trigger. With a
//  solid post standing in front of the mine's western third that trace lands on
//  the post. This is the likeliest cause and it is NOT proven - the post is not
//  in any dump, so its depth cannot be confirmed offline.
//
//  🛑 RESIDUAL RISK AND THE ONE-LINE NUDGE. If it is still fouled, or still not
//  buyable, the origin is dvar-driven and nothing needs rebuilding:
//      zmqol_claymore_diner_x -3618     (further east, away from the post)
//      zmqol_claymore_diner_x -3630     (back to where v2.2.5 had it)
//  🛑 BOTH SIDES CARRY THE SAME DEFAULT. zm_expanded.csc:429 was changed in the
//  same edit; the client is what spawns the visible model, so changing one alone
//  moves the trigger and leaves the mine behind.
// ============================================================================
zmqol_claymore_wallbuy_origin()
{
	// Twin of zm_expanded.csc::zmqol_claymore_wallbuy_origin(). Same dvars, same
	// defaults - if these ever disagree the two sides register different
	// clientfield names and everyone is dropped at load.
	return ( getdvarintdefault( "zmqol_claymore_diner_x", -3624 ), getdvarintdefault( "zmqol_claymore_diner_y", -7486 ), getdvarintdefault( "zmqol_claymore_diner_z", -7 ) );
}

zmqol_add_claymore_wallbuy()
{
	// ========================================================================
	//  🌟 v2.3.2 - MEASURED AND ON. zmqol_probe_shack_wall() (v2.2.7) fanned
	//  bullettraces at the shack from inside the room. Real results, read
	//  straight from console_zm.log:
	//    WALLX  flat hit at y -7486 across x -3628..-3592 (the flat run this
	//           wall buy sits inside), normal (0,100,0)/100 = outward +Y - the
	//           yaw 90 already coded is exactly that normal.
	//    WALLZ  flat at y -7486 from z -56 to z 44 at x -3624 - no post, no
	//           step, in the whole free-standing height the mine could use.
	//    FLOOR  x -3624 y -7440: z -58, so mount height z -7 is 51 units up -
	//           the intended offset, now confirmed against a real floor
	//           instead of an assumed one.
	//    OUT    trace from the current origin (-3624,-7486,-7) into the room:
	//           fraction 1000/1000 - clear, so the mine is NOT embedded in the
	//           brush (the failure mode that made it unbuyable three times).
	//  Every existing default (x -3624, y -7486, z -7, yaw 90) already matched
	//  the measured geometry - three prior placement rounds (v2.2.0, v2.2.5,
	//  v2.2.6) had converged on the right numbers without ever being able to
	//  prove it. The probe function and its main() call are removed per its
	//  own instruction now that the wall buy is landed.
	//
	//  🛑 THE GATE IS SYMMETRIC OR IT IS FATAL. zm_expanded.csc reads the same
	//  dvar with the same default. Registering this pair on one side only is
	//  EXE_CLIENT_FIELD_MISMATCH at load, because _zm_weapons names the wall
	//  buy's "world" clientfield from the struct (:889 server, :218 client).
	//  If you flip this default, flip the client's in the same edit.
	// ========================================================================
	if ( getdvarintdefault( "zmqol_claymore_diner_enabled", 1 ) == 0 )
	{
		println( "[zm_qol] diner claymore: DISABLED (zmqol_claymore_diner_enabled 0)" );
		return;
	}

	v_origin = zmqol_claymore_wallbuy_origin();
	n_yaw    = getdvarintdefault( "zmqol_claymore_diner_yaw", 90 );

	// ========================================================================
	//  🛑 v2.2.5 - THE PAIR WAS 90 DEGREES OUT AND THE MINE WAS EDGE-ON IN THE
	//  WALL. THE ROLES OF THE TWO YAWS WERE SWAPPED.               (measured)
	//
	//  User, 2026-08-22, with a screenshot: *"the claymore wallbuy in diner
	//  survival is facing the wrong way, thus colliding into the wall and
	//  looking scuffed."* The screenshot shows the mine almost entirely inside
	//  the wall with only its glowing edge past a vertical beam - which is what
	//  you get when the model's WIDTH axis points into the wall instead of
	//  along it.
	//
	//  -- THE MODEL'S OWN AXES, FROM ITS MESH --------------------------------
	//  t6_wpn_claymore_world_LOD_0.XMODEL_EXPORT, 1058 verts, in game axes:
	//        X (forward)  -2.51 .. 1.63    span  4.14   <- the THIN axis
	//        Y (left)     -5.57 .. 5.59    span 11.16   <- the mine's width
	//        Z (up)       -2.34 .. 9.67    span 12.01   <- height, legs below
	//  A claymore is ~11 wide, ~4 thick and ~12 tall on its stand, so local X
	//  is the front-to-back axis and local +X is the face - confirmed by the
	//  model's only other tag, tag_fx, at OFFSET (1.603, 0, 8.638), i.e. sat on
	//  the +X surface where the blast fx belongs.
	//
	//  An entity's yaw points local +X at that world angle. So for the mine to
	//  lie flat on a wall, MODEL YAW MUST EQUAL THE WALL'S OUTWARD NORMAL.
	//  The old code used normal + 90, which pointed the face along the wall and
	//  drove the 11-unit width straight through it.
	//
	//  -- WHAT THE BUY STRUCT'S YAW REALLY IS --------------------------------
	//  Not the wall normal. _zm_weapons.gsc:931 places the use trigger with
	//        origin -= anglestoright( buy.angles ) * ( script_length * 0.4 )
	//  and anglestoright( yaw ) is the direction yaw-90. Stock wants that
	//  trigger pushed OFF the wall into the room, and that only happens when
	//  buy yaw = normal - 90. So the pair is:
	//        buy yaw   = wall outward normal - 90
	//        model yaw = wall outward normal
	//  which reproduces stock's own constant +90 gap between the two.
	//
	//  -- CHECKED AGAINST ALL EIGHT STOCK CLAYMORE WALL BUYS -----------------
	//  Every claymore_purchase / t6_wpn_claymore_world pair in the game, read
	//  out of the mapents dumps - buy yaw -> model yaw:
	//        transit farm  90 -> 180     buried street  90 -> 180
	//        highrise      60 -> 150     nuketown      285 ->  15
	//        prison        90 -> 180     tomb A        180 -> 270
	//        tomb B         0 ->  90     tomb C        180 -> 270
	//  Model = buy + 90 in all eight. 🌟 zm_tomb's pf2209 pair is buy 0 /
	//  model 90 - the exact pair this file now writes - so this is a shipped
	//  stock configuration, not an invention.
	//
	//  -- THE WALL, UNCHANGED FROM v2.2.0 ------------------------------------
	//  The shack's south wall is the plane through both of its mantle lanes,
	//  y = -7494, and the interior is the +Y side: both node_negotiation_begin
	//  nodes sit at y -7531 / -7536 with angles "0 90 0", so the AI mantles
	//  from outside toward +Y. Outward normal = +Y = 90. The origin does not
	//  move; at model yaw 90 only the mine's 2.51-unit back sits toward the
	//  wall, so it can no longer clip it.
	//
	//  🛑 BOTH SIDES CHANGED TOGETHER. zm_expanded.csc's twin carries the same
	//  two expressions. The clientfield name is built from the ORIGIN only
	//  (_zm_weapons.gsc:889), so angles cannot desync it - but the client is
	//  what actually spawns the visible model (_zm_weapons.csc:268 uses
	//  target_struct.angles), so a change here alone would do nothing at all.
	// ========================================================================
	s_model = spawnstruct();
	s_model.targetname = "zmqol_claymore_diner";
	s_model.origin = v_origin;
	s_model.angles = ( 0, n_yaw, 0 );
	s_model.model = "t6_wpn_claymore_world";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "claymore_purchase";
	s_buy.origin = v_origin;
	// normal - 90, so the use trigger is pushed off the wall into the room.
	// See the derivation above; this is stock's own relationship.
	s_buy.angles = ( 0, n_yaw - 90, 0 );
	s_buy.zombie_weapon_upgrade = "claymore_zm";
	s_buy.target = "zmqol_claymore_diner";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] diner claymore: wallbuy struct at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") wall normal " + n_yaw + " (model yaw " + n_yaw + ", buy yaw " + ( n_yaw - 90 ) + ")" );
}

// ============================================================================
//  🌟 v2.3.4 - ONE-SHOT DIAGNOSTIC. The claymore model shows (client-side,
//  clientfield-driven, independent of the server trigger) but the user
//  reports NO purchase prompt at all when looking directly at it, on a fresh
//  spawn with a full score. Static reading of _zm_weapons.gsc / _zm_unitrigger
//  .gsc / _zm_weap_claymore.gsc could not settle which of several candidate
//  points in that chain is actually failing without seeing real state, so
//  this prints it instead of guessing a fix. Same practice as the removed
//  zmqol_probe_shack_wall() - print once, read console_zm.log, then delete.
//
//  init_spawnable_weapon_upgrade() (_zm_weapons.gsc:839, called from
//  _zm_weapons::init() at map load) is what turns the injected
//  "claymore_purchase" struct into a live unitrigger_stub and stores it in
//  level._spawned_wallbuys - well before this probe's 3-second wait expires.
//  This reads that array read-only; it cannot affect gameplay.
// ============================================================================
zmqol_probe_claymore_trigger()
{
	wait 3;

	if ( !isdefined( level._spawned_wallbuys ) )
	{
		println( "[zm_qol] CLAYMORE PROBE: level._spawned_wallbuys is undefined - init_spawnable_weapon_upgrade() never ran or hasn't yet" );
		return;
	}

	n_found = 0;

	for ( i = 0; i < level._spawned_wallbuys.size; i++ )
	{
		e = level._spawned_wallbuys[i];

		if ( !isdefined( e.targetname ) || e.targetname != "claymore_purchase" )
			continue;

		n_found++;
		str = "[zm_qol] CLAYMORE PROBE: spawn_list entry - zombie_weapon_upgrade=" + e.zombie_weapon_upgrade + " target=" + e.target;

		if ( !isdefined( e.trigger_stub ) )
		{
			str += " | trigger_stub=UNDEFINED (never reached the unitrigger registration call)";
			println( str );
			continue;
		}

		stub = e.trigger_stub;
		str += " | trigger_stub=OK";
		str += " prompt_and_visibility_func_bound=" + isdefined( stub.prompt_and_visibility_func );
		str += " require_look_at=" + stub.require_look_at;

		if ( isdefined( stub.registered ) )
			str += " registered=" + stub.registered;
		else
			str += " registered=UNDEFINED";

		if ( isdefined( stub.in_zone ) )
			str += " in_zone=" + stub.in_zone;
		else
			str += " in_zone=UNDEFINED";

		if ( isdefined( stub.trigger ) )
			str += " trigger_ent=SPAWNED";
		else if ( isdefined( stub.playertrigger ) )
			str += " trigger_ent=PER-PLAYER(" + stub.playertrigger.size + ")";
		else
			str += " trigger_ent=NOT SPAWNED YET";

		println( str );
	}

	println( "[zm_qol] CLAYMORE PROBE: " + n_found + " spawn_list entr" + ( n_found == 1 ? "y" : "ies" ) + " with targetname claymore_purchase (expect 1)" );

	players = get_players();

	if ( players.size > 0 )
	{
		p = players[0];
		println( "[zm_qol] CLAYMORE PROBE: " + p.name + " current_placeable_mine=" + p.current_placeable_mine + " score=" + p.score );
	}
}

zmqol_unlock_shield_buildable_entities()
{
	a_targetnames = [];
	a_targetnames[a_targetnames.size] = "riotshield_zm_buildable_trigger";
	a_targetnames[a_targetnames.size] = "buildable_riotshield";

	n_freed = 0;

	foreach ( str_targetname in a_targetnames )
	{
		a_ents = getentarray( str_targetname, "targetname" );

		if ( !isdefined( a_ents ) )
			continue;

		foreach ( e_ent in a_ents )
		{
			if ( !isdefined( e_ent.script_gameobjectname ) )
				continue;

			e_ent.script_gameobjectname = "[all_modes]";
			n_freed++;
		}
	}

	println( "[zm_qol] diner shield: freed " + n_freed + " bench entities from the gamemode filter (expect 2)" );
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

	level thread zmqol_pap_visibility_probe();

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

// ============================================================================
//  zm_qol: THE TARP IS NOW CONDITIONAL                             (v1.66.0)
//
//  Its origin (-4688,-7974,-64) is the shield bench - the same spot as
//  riotshield_zm_buildable_trigger at (-4688,-7966,-6). Reimagined covers the
//  bench because in survival there is nothing to build on it; now that the riot
//  shield is registered here, the cover has to come off or the bench is hidden
//  under a sheet you can still use.
//
//  Kept for the case where the shield is NOT enabled - zgrief - so that mode
//  still gets Reimagined's covered bench rather than a bare one that does
//  nothing.
//
//  🛑 THE GATE IS RE-STATED HERE, NOT CALLED. Calling
//  scripts\zm\zm_transit\zm_transit::zmqol_diner_shield_enabled() would be a
//  reference from a locs\ file - which is loaded broadly - into a map-scoped
//  one, and GSC resolves that at SCRIPT LOAD time: "Unresolved external" on
//  every map that is not TranZit, with no runtime guard able to prevent it
//  (AI_CONTEXT rule 2). It reads the same two dvars in the same order, and both
//  copies carry this note so a change to one is a change to both.
//
//  Only ONE tarp is spawned in this whole file, so there is nothing else this
//  affects.
// ============================================================================
generatebuildabletarps()
{
	// twin of zm_transit.gsc / zm_transit.csc :: zmqol_diner_shield_enabled()
	if ( getdvar( "ui_zm_mapstartlocation" ) == "diner" && getdvar( "ui_gametype" ) != "zgrief" )
		return;

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

		// ====================================================================
		//  zm_qol v1.99.90 - HELLHOUNDS SPAWNED OUTSIDE THE ARENA (queue: user,
		//  2026-08-20, screenshot: a dog on the wrecked truck north of the diner,
		//  player at (-4935,-6885)).
		//
		//  🛑 THE LOOP ABOVE IS ONLY HALF THE JOB, and the comment further up this
		//  file says so without following it through: _zm_zonemgr.gsc:214-248 files
		//  a struct tagged "dog_location" / "screecher_location" /
		//  "avogadro_location" into zone.dog_locations / .screecher_locations /
		//  .avogadro_locations and NEVER into zone.spawn_locations. So every
		//  spawner this location script disabled above stayed live for hellhounds.
		//
		//  The path, verified end to end:
		//    1. _zm_zonemgr::create_spawner_list() (:944-976) rebuilds
		//       level.enemy_dog_locations EVERY SECOND from zone.dog_locations of
		//       every zone that is enabled + active + spawning_allowed, honouring
		//       each struct's own .is_enabled - the same flag this loop writes.
		//    2. zm_transit.gsc:96 sets level.dog_spawn_func = dog_spawn_transit_logic,
		//       which picks a location 400-1150 units from EVERY player and, when
		//       none qualifies, falls back to dog_locs[0] with NO distance check.
		//    3. transit_zone_init() connects zone_trans_diner to zone_roadside_west
		//       and zone_gas on flag "always_on" (:1571-1573), so in Diner survival
		//       that zone is enabled and goes active the moment a player stands in
		//       the arena - handing 6 dog locations 1,000-1,400 units up the road.
		//
		//  Which structs come off, and why each one is out of the arena:
		//    - the whole zone_trans_diner / zone_trans_diner2 groups: this same
		//      function already declares them out of bounds for regular zombies by
		//      disabling every spawn/riser struct they own. Nothing else in the
		//      arena spawns there.
		//    - three dog structs sitting on top of a riser this function disables
		//      by origin. MEASURED, not assumed - each is 127-196 units from its
		//      disabled riser, while the next nearest disabled riser is >500:
		//        (-5272,-6400,-35.4)  is 181u from (-5130,-6512,-35.4)
		//        (-4013,-6521,-41.9)  is 196u from (-3825,-6576,-52.7)
		//        (-6550,-7250,-36)    is 127u from (-6462,-7159,-64)
		//
		//  🌟 12 dog locations remain enabled across zone_din, zone_diner_roof,
		//  zone_gar, zone_gas, zone_roadside_east and zone_roadside_west, so the
		//  list can never empty out - an empty level.enemy_dog_locations would make
		//  dog_spawn_transit_logic return undefined and hang the dog round.
		//
		//  🛑 DELIBERATELY DINER-ONLY. The obvious general rule - "a zone with no
		//  enabled zombie spawners may not spawn dogs" - was checked against the
		//  mapents of every dog-capable map and it is WRONG: 8 of Nuketown's 16
		//  zones (garage, alleys, truck, start) carry dog locations and no regular
		//  spawner at all, by design. Applying it globally would have deleted most
		//  of Nuketown's hellhound spawns.
		// ====================================================================
		zmqol_disable_out_of_arena_ai_locations( zone.dog_locations );
		zmqol_disable_out_of_arena_ai_locations( zone.screecher_locations );
		zmqol_disable_out_of_arena_ai_locations( zone.avogadro_locations );
	}

	//  v2.2.0 - AFTER the pruning above, so the snapshot it takes can only hold
	//  in-arena locations. See the banner over zmqol_diner_dog_init().
	zmqol_diner_dog_init();
}

//  Structs are references in GSC, so writing .is_enabled through a copied array
//  still flags the one struct create_spawner_list() reads.
zmqol_disable_out_of_arena_ai_locations( a_locs )
{
	if ( !isdefined( a_locs ) )
		return;

	for ( i = 0; i < a_locs.size; i++ )
	{
		if ( a_locs[i].targetname == "zone_trans_diner_spawners" )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].targetname == "zone_trans_diner2_spawners" )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-5272, -6400, -35.4) )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-4013, -6521, -41.9) )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-6550, -7250, -36) )
		{
			a_locs[i].is_enabled = false;
		}
	}
}

// ============================================================================
//  DINER HELLHOUNDS  -  A DOG THAT NEVER ARRIVES                    (v2.2.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-21, round 19 of Diner survival: *"the final hell hound spawned
//  god knows where, outside of the playable map of Diner obviously, couldn't
//  even hear the sound of it or anything... make sure that the spawns of the
//  hell hounds aren't bugged at all and work properly for Diner Survival, and
//  they spawn in the map all the time."*
//
//  🛑 v1.99.90 PRUNED THE SPAWN LIST AND THAT WAS ONLY HALF THE STORY. The dog
//  the user could not find was almost certainly not at a bad LOCATION - it was
//  at the world origin, hidden, with ignoreme still set. Here is the whole
//  chain, every link read out of the stock dump:
//
//    1. Diner survival has exactly ONE dog spawner and it is at (0, 0, 0).
//       `so_zsurvival_zm_transit.addonmapents` carries one actor_zombie_dog with
//       script_noteworthy "zombie_dog_spawner" at origin "0 0 0", and the BASE
//       zm_transit mapents carries NONE - grep returns zero. So
//       level.dog_spawners has one entry, sitting at the map origin.
//
//    2. Stock spawns every dog THERE and teleports it afterwards.
//       _zm_ai_dogs::dog_round_spawning() (:135-141):
//             spawn_loc = [[ level.dog_spawn_func ]]( ... );
//             ai        = spawn_zombie( level.dog_spawners[0] );      <- at 0,0,0
//             spawn_loc thread dog_spawn_fx( ai, spawn_loc );
//       and dog_spawn_fx() is what does `ai forceteleport( ent.origin, angles )`,
//       `ai show()` and `ai.ignoreme = 0` - in that order, at the END.
//
//    3. So if dog_spawn_fx never completes, the dog stays at (0, 0, 0), STILL
//       HIDDEN and STILL ignoring the player. Invisible, silent, unkillable,
//       and the round can never end. That is exactly what was reported.
//
//    4. The way it fails is stock's own fallback. dog_spawn_transit_logic()
//       (zm_transit.gsc:2906) ends with `return dog_locs[0]` where dog_locs is
//       level.enemy_dog_locations - and that list is REBUILT EVERY SECOND by
//       _zm_zonemgr::create_spawner_list() from the zones that are enabled AND
//       active AND spawning_allowed. If it is momentarily empty, dog_locs[0] is
//       undefined, `spawn_loc thread dog_spawn_fx(...)` throws on an undefined
//       entity, and the thread dies before the teleport.
//
//  🌟 THE FIX IS IN TWO PARTS, AND THE SECOND ONE IS THE POINT.
//    (a) level.dog_spawn_func is a POINTER, so this location script simply owns
//        it. zmqol_dog_spawn_diner_logic() is stock's own transit logic with the
//        one hole closed: it can never return undefined, because it falls back
//        to a snapshot of the arena's dog locations taken at init.
//    (b) A per-dog WATCHDOG, because (a) only fixes the failure mode that can be
//        named. Anything else inside dog_spawn_fx - a missing fx handle, an
//        undefined favoriteenemy at the wrong moment - lands the dog in the same
//        state, and the watchdog does not care which: if a dog is still sitting
//        within 64 units of its spawner 4 seconds after it spawned, it is put
//        where it should have gone, shown, and un-ignored.
//
//  🛑 DELIBERATELY DINER-ONLY, like the v1.99.90 pruning above it. This is
//  called from this location script and nothing else, so no other map's dog
//  rounds are touched.
//
//  📝 The roof spawns are LEFT ALONE. Two of the arena's dog locations sit on
//  the diner roof at z 242.3 (zone_diner_roof_spawners); they are Treyarch's
//  own, they are inside the arena, and there is no evidence they are bad. If a
//  dog ever does get stuck up there the watchdog will not catch it - it only
//  catches dogs that never left the spawner - so that would be a separate fix.
// ============================================================================
zmqol_diner_dog_init()
{
    //  Snapshot the arena's dog locations AFTER the pruning pass above has run,
    //  so the fallback list can only contain in-arena spots.
    level.zmqol_diner_dog_locs = [];

    for ( z = 0; z < level.zone_keys.size; z++ )
    {
        zone = level.zones[level.zone_keys[z]];

        if ( !isdefined( zone ) || !isdefined( zone.dog_locations ) )
            continue;

        //  ====================================================================
        //  🛑 v2.2.6 - THE SNAPSHOT WAS NOT AN ARENA SNAPSHOT AT ALL, AND THE
        //  LOG SAID SO IN ONE NUMBER.
        //
        //  The banner above claims "12 dog locations remain enabled". The
        //  user's console_zm.log from the 49-minute Diner run prints
        //        [zm_qol] diner dogs: 97 in-arena dog location(s) snapshotted
        //  Ninety-seven, out of the 162 dog_location structs in the whole of
        //  zm_transit's mapents. So this loop was collecting dog locations from
        //  EVERY zone in TranZit - the town, the farm, the power station - and
        //  calling them "in-arena".
        //
        //  🌟 THE CAUSE IS ONE MISSING TEST, AND STOCK SPELLS OUT WHICH.
        //  _zm_zonemgr::create_spawner_list() builds level.enemy_dog_locations
        //  with TWO gates:
        //        if ( zone.is_enabled && zone.is_active && zone.is_spawning_allowed )
        //            ... if ( zone.dog_locations[x].is_enabled )
        //  This loop only ever applied the second one. zone.is_enabled is what
        //  says a zone is part of the arena, and it was never read - so
        //  zmqol_disable_out_of_arena_ai_locations()'s per-struct flags were
        //  doing all the work, and they only cover five specific entries.
        //
        //  The fallback below is used whenever level.enemy_dog_locations is
        //  momentarily empty, and it picks from this list AT RANDOM. With 97
        //  entries spread across the whole map, that fallback could teleport a
        //  hellhound a mile up the road, outside the Diner arena, with no
        //  player anywhere near it - which is the shape of every "the dog
        //  spawned god knows where" report this file already carries.
        //
        //  📝 is_active / is_spawning_allowed are deliberately NOT part of the
        //  test here. They are per-round state that flips while the match runs;
        //  this snapshot is taken once at init and is a LAST-RESORT list, so it
        //  must not be empty just because a zone happened to be quiet at init.
        //  is_enabled is the one that means "part of this arena", and it is the
        //  one this was missing.
        //  ====================================================================
        if ( isdefined( zone.is_enabled ) && !zone.is_enabled )
            continue;
        for ( i = 0; i < zone.dog_locations.size; i++ )
        {
            s_loc = zone.dog_locations[i];

            if ( !isdefined( s_loc ) || !isdefined( s_loc.origin ) )
                continue;

            //  is_enabled is what the pruning pass writes; honour it here so a
            //  struct this file just switched off cannot come back as a
            //  fallback.
            if ( isdefined( s_loc.is_enabled ) && !s_loc.is_enabled )
                continue;

            level.zmqol_diner_dog_locs[level.zmqol_diner_dog_locs.size] = s_loc;
        }
    }

    println( "[zm_qol] diner dogs: " + level.zmqol_diner_dog_locs.size + " in-arena dog location(s) snapshotted" );

    //  🛑 ONLY TAKE THE POINTER IF THERE IS SOMETHING TO FALL BACK ON. With an
    //  empty snapshot this function would be strictly worse than stock's.
    if ( level.zmqol_diner_dog_locs.size > 0 )
        level.dog_spawn_func = ::zmqol_dog_spawn_diner_logic;

    level thread zmqol_diner_dog_watchdog();
    level thread zmqol_diner_dog_garage_watchdog();
}

//  Stock's dog_spawn_transit_logic(), with the undefined return closed off.
//  The 160000 / 1322500 bounds are stock's own (400 and 1150 units squared).
zmqol_dog_spawn_diner_logic( dog_array, favorite_enemy )
{
    dog_locs = array_randomize( level.enemy_dog_locations );

    for ( i = 0; i < dog_locs.size; i++ )
    {
        if ( isdefined( level.old_dog_spawn ) && level.old_dog_spawn == dog_locs[i] )
            continue;

        canuse = 1;
        players = get_players();

        foreach ( player in players )
        {
            if ( !canuse )
                continue;

            dist_squared = distancesquared( dog_locs[i].origin, player.origin );

            if ( dist_squared < 160000 || dist_squared > 1322500 )
                canuse = 0;
        }

        if ( canuse )
        {
            level.old_dog_spawn = dog_locs[i];
            return dog_locs[i];
        }
    }

    //  Stock's own fallback, guarded.
    if ( dog_locs.size > 0 && isdefined( dog_locs[0] ) )
    {
        level.old_dog_spawn = dog_locs[0];
        return dog_locs[0];
    }

    //  🛑 THE HOLE STOCK LEAVES OPEN. Reached when level.enemy_dog_locations is
    //  momentarily empty; stock returns undefined here and the dog is stranded
    //  at the spawner. The snapshot is built from the same structs, so this is
    //  still a real in-arena spot.
    s_fallback = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];
    level.old_dog_spawn = s_fallback;
    println( "[zm_qol] diner dogs: enemy_dog_locations was EMPTY - used the snapshot fallback" );
    return s_fallback;
}

//  Catches a dog that never got teleported, whatever the reason.
zmqol_diner_dog_watchdog()
{
    level endon( "end_game" );
    level endon( "intermission" );

    v_spawner = ( 0, 0, 0 );

    if ( isdefined( level.dog_spawners ) && level.dog_spawners.size > 0 && isdefined( level.dog_spawners[0] ) )
        v_spawner = level.dog_spawners[0].origin;

    for ( ;; )
    {
        wait 1;

        if ( !isdefined( level.zmqol_diner_dog_locs ) || level.zmqol_diner_dog_locs.size == 0 )
            continue;

        a_ai = getaiarray( level.zombie_team );

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            //  First sighting: remember when, and move on. dog_spawn_fx takes
            //  1.5s of its own before it teleports, so nothing is judged early.
            if ( !isdefined( ai.zmqol_dog_seen ) )
            {
                ai.zmqol_dog_seen = gettime();
                continue;
            }

            if ( gettime() - ai.zmqol_dog_seen < 4000 )
                continue;

            //  ================================================================
            //  🌟 v2.2.5 - THE DOG THAT COULD NOT BE KILLED AND IGNORED THE
            //  PLAYER. This runs BEFORE the stranded check below, because the
            //  dog it is for is not stranded - it is up and running around.
            //
            //  User, 2026-08-22, Diner survival round 7: *"one of the dogs was
            //  running through the lifted up car in the garage and through
            //  building, and it kinda just ignored me... I just now killed all
            //  the dogs except that one dog that ran through the wall outside
            //  the map, unable to progress the game now without the use of
            //  cheats."*
            //
            //  🛑 STOCK'S OWN SPAWN THREAD HAS NO ERROR PATH, AND ITS FIRST
            //  LINE IS THE ONE THAT THROWS. _zm_ai_dogs::dog_spawn_fx() runs,
            //  in this exact order (:197-222):
            //        angle = vectortoangles( ai.favoriteenemy.origin - ... )
            //        ai forceteleport( ent.origin, angles )
            //        ai zombie_setup_attack_properties_dog()
            //        ai stop_magic_bullet_shield()
            //        ai show()
            //        ai setfreecameralockonallowed( 1 )
            //        ai.ignoreme = 0
            //  Every dog is spawned WITH a magic bullet shield - i.e. immune to
            //  damage - and with ignoreme set, and that thread is the only
            //  thing that takes either off. Plutonium kills a GSC thread that
            //  throws in silence, so if ANY line above fails, whatever came
            //  after it never runs and the dog keeps the state it was born
            //  with: invulnerable, uninterested in the player, and with none of
            //  its attack properties set. That is the whole of the user's
            //  report - a dog that runs about, ignores you and cannot be shot.
            //
            //  🌟 THE WATCHDOG DOES NOT CARE WHICH LINE FAILED. It re-asserts
            //  the end state stock was trying to reach, field for field, and it
            //  only touches what is actually still wrong.
            //
            //  📝 THE FIVE ATTACK-PROPERTY FIELDS ARE SET INLINE RATHER THAN BY
            //  CALLING zombie_setup_attack_properties_dog(), because they are
            //  the whole of its body (_zm_ai_dogs.gsc:532-540) minus a
            //  developer-only history ring. dog_behind_audio() - the dog's
            //  growl loop, and the reason an earlier stranded dog could not be
            //  heard - IS started, by name, because it has no inline
            //  equivalent.
            //  🛑 THE CROSS-FILE REFERENCE IS SAFE FROM THIS FILE, CHECKED NOT
            //  ASSUMED: locs\ scripts load on EVERY map, so an external here
            //  must resolve everywhere or every other map dies at load
            //  (AI_CONTEXT rule 2). console_zm.log's script list reports
            //  "_zm_ai_dogs.gsc (patch_zm)" - patch_zm is the global zombies
            //  patch, loaded on all six maps, same as _zm_utility.
            //  ================================================================
            if ( !isdefined( ai.zmqol_dog_state_fixed ) )
            {
                ai.zmqol_dog_state_fixed = 1;
                str_fixed = "";

                //  is_magic_bullet_shield_enabled() is exactly this test
                //  (_zm_utility.gsc:2784), inlined for the same reason.
                if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                {
                    ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();
                    str_fixed = str_fixed + " unkillable";
                }

                if ( isdefined( ai.ignoreme ) && ai.ignoreme )
                {
                    ai.ignoreme = 0;
                    str_fixed = str_fixed + " ignoreme";
                }

                //  🛑 THE PROPERTIES AND THE AUDIO ARE ONLY TOUCHED IF
                //  zombie_setup_attack_properties_dog() PROVABLY DID NOT RUN.
                //  Its last two writes are disablearrivals/disableexits = 1,
                //  and nothing else in the dog path sets them, so
                //  disablearrivals is a reliable "did that function complete"
                //  flag. This test is the whole reason the growl thread cannot
                //  be started twice: starting a second dog_behind_audio() on a
                //  healthy dog would double every growl it makes, which is a
                //  worse bug than the one being fixed.
                if ( !( isdefined( ai.disablearrivals ) && ai.disablearrivals ) )
                {
                    //  zombie_setup_attack_properties_dog(), inline.
                    ai.ignoreall          = 0;
                    ai.pathenemyfightdist = 64;
                    ai.meleeattackdist    = 64;
                    ai.disablearrivals    = 1;
                    ai.disableexits       = 1;

                    ai thread maps\mp\zombies\_zm_ai_dogs::dog_behind_audio();
                    str_fixed = str_fixed + " attack-properties+audio";
                }

                ai show();
                ai setfreecameralockonallowed( 1 );

                if ( str_fixed != "" )
                    println( "[zm_qol] diner dogs: a dog was still in its pre-spawn state after 4s -" + str_fixed + " - stock's dog_spawn_fx did not finish. Repaired." );
            }

            //  ================================================================
            //  🌟 v2.3.2 - THE LAST-ZOMBIE TIMEOUT. THE ROUND CAN NO LONGER HANG
            //  ON ONE UNREACHABLE DOG, WHATEVER THE REASON.
            //
            //  User, 2026-08-25, Diner survival round 7: the last hellhound of a
            //  dog round ran outside the map and the round could not progress -
            //  the exact class of failure the v2.2.6 containment below was built
            //  for, except this time it never fired. Read from that session's own
            //  console_zm.log, not guessed: "[zm_qol] diner dogs: 71 in-arena dog
            //  location(s) snapshotted" is the ONLY diner-dogs line in the whole
            //  log - neither "RUNAWAY DOG" nor "STRANDED DOG" ever printed, so
            //  whatever went wrong was invisible to both existing tests. Two ways
            //  that happens without contradicting either one: the dog stayed
            //  within the containment check's 2500-unit straight-line distance of
            //  a player despite being behind unreachable geometry (b_far below
            //  never goes 1), or it ended up standing in a zone
            //  _zm_zonemgr still calls "enabled" even though it is not part of
            //  this arena's walkable space (that check's definition of "in
            //  bounds" is broader than "reachable").
            //
            //  🌟 THIS DOES NOT TRY TO NAME WHICH. It is a hard backstop on the
            //  one fact that is always true when the round is hung: exactly one
            //  zombie-team AI is left and it has stayed that way, alive, for a
            //  long time. Nothing about a healthy dog round holds "1 AI left" for
            //  20+ seconds - the player kills it in a few seconds, or the
            //  containment/rescue logic already catches it. Past that timeout
            //  this fires unconditionally, no distance test and no zone test,
            //  because both are exactly what already failed to catch this once.
            //  a_ai is this tick's own getaiarray( level.zombie_team ) snapshot,
            //  so its size needs no extra call.
            //  ================================================================
            if ( a_ai.size == 1 )
            {
                if ( !isdefined( ai.zmqol_dog_lastone_since ) )
                    ai.zmqol_dog_lastone_since = gettime();

                if ( !isdefined( ai.zmqol_dog_lastone_rescued ) && gettime() - ai.zmqol_dog_lastone_since >= 20000 )
                {
                    ai.zmqol_dog_lastone_rescued = 1;

                    s_home   = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];
                    players  = get_players();
                    v_angles = ai.angles;

                    if ( players.size > 0 )
                    {
                        e_target = players[randomint( players.size )];

                        if ( isdefined( e_target ) )
                        {
                            v_face   = vectortoangles( e_target.origin - s_home.origin );
                            v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
                        }
                    }

                    ai forceteleport( s_home.origin, v_angles );

                    //  Re-assert the whole of dog_spawn_fx()'s end state, same as
                    //  the two rescues below - it may be stuck for the same
                    //  reason it never finished spawning correctly.
                    if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                        ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

                    ai show();
                    ai setfreecameralockonallowed( 1 );
                    ai.ignoreme            = 0;
                    ai.ignoreall           = 0;
                    ai.zmqol_dog_far_ticks = 0;
                    ai notify( "visible" );

                    println( "[zm_qol] diner dogs: LAST ZOMBIE TIMEOUT - sole remaining dog had not ended the round in 20s, force-returned to (" + int( s_home.origin[0] ) + "," + int( s_home.origin[1] ) + "," + int( s_home.origin[2] ) + ")" );
                }
            }
            else
            {
                ai.zmqol_dog_lastone_since   = undefined;
                ai.zmqol_dog_lastone_rescued = undefined;
            }

            //  ================================================================
            //  🌟 v2.2.6 - CONTAINMENT: A DOG THAT LEAVES THE ARENA IS BROUGHT
            //  BACK. THE ROUND CAN NO LONGER BE LOST TO ONE RUNAWAY.
            //
            //  User, 2026-08-23, Diner survival: *"it spawned in front of the
            //  slightly open garage door where the zombies and the player can
            //  crawl/prone under, and the dog just went straight through the
            //  door and then continued to go through the lifted car itself as
            //  well, totally glitched and then it ignored me (the player) and
            //  then went through the back wall out of the map, running
            //  indefinitely outside of the map/playable area causing that match
            //  to be ruined."*
            //
            //  🛑 WHY THE v2.2.5 REPAIR ABOVE DID NOT COVER THIS, STATED
            //  HONESTLY. That repair fixes a dog whose dog_spawn_fx() thread
            //  died - unkillable, ignoreme, no attack properties. It printed
            //  NOTHING in the 49-minute run's console_zm.log, so on the
            //  evidence available every dog in that match reached its correct
            //  end state and this was a different fault. Walking through a
            //  closed garage door, through a car and out through a wall is what
            //  a T6 actor does when it has no usable path and simply steers at
            //  its goal: actors are moved by the path graph, not by brush
            //  collision. Which node graph failed, and why, is NOT established
            //  offline - the garage door is a crawl-under traverse that dogs do
            //  not use, which is a plausible cause and is not proof.
            //
            //  🌟 SO THIS DOES NOT TRY TO NAME THE CAUSE. It catches the state:
            //  a dog that is nowhere near a player AND is standing in no
            //  enabled zone is, by the game's own definition of the arena, out
            //  of the map. It gets put back on a real dog location with its
            //  full spawn state re-asserted, and the round can finish.
            //
            //  -- THE TWO TESTS, AND WHY THOSE TESTS --------------------------
            //    1. distance. Stock's own dog_spawn_transit_logic() refuses any
            //       spawn location further than 1150 units from a player
            //       (dist_squared > 1322500). A dog more than 2500 units from
            //       EVERY player is therefore far outside anything stock would
            //       ever have placed it in, with generous headroom for a chase.
            //       This is only a cheap pre-filter so the zone test below runs
            //       on almost nothing.
            //    2. the zone. _zm_zonemgr::get_zone_from_position() returns
            //       undefined when a position is inside no ENABLED zone - it is
            //       stock's own "is this spot part of the arena" question, and
            //       it is what actually authorises the teleport. It spawns and
            //       deletes a script_origin per call, which is why it is gated
            //       behind test 1 and behind five consecutive seconds.
            //
            //  📝 FIVE CONSECUTIVE SECONDS, not one. A dog crossing a gap
            //  between zone volumes for a frame must never be teleported; the
            //  counter is reset the moment the dog is near a player again.
            //  📝 maps\mp\zombies\_zm_zonemgr is core zombies and loads on every
            //  map, so referencing it from locs\ - which loads everywhere - is
            //  safe (AI_CONTEXT rule 2).
            //  ================================================================
            b_far = 1;

            foreach ( player in get_players() )
            {
                if ( isdefined( player ) && distancesquared( ai.origin, player.origin ) < 6250000 )   //  2500 units
                    b_far = 0;
            }

            if ( !b_far )
            {
                ai.zmqol_dog_far_ticks = 0;
            }
            else
            {
                if ( !isdefined( ai.zmqol_dog_far_ticks ) )
                    ai.zmqol_dog_far_ticks = 0;

                ai.zmqol_dog_far_ticks++;

                if ( ai.zmqol_dog_far_ticks >= 5 )
                {
                    ai.zmqol_dog_far_ticks = 0;

                    if ( !isdefined( maps\mp\zombies\_zm_zonemgr::get_zone_from_position( ai.origin ) ) )
                    {
                        s_home = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];

                        v_angles = ai.angles;

                        if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
                        {
                            v_face   = vectortoangles( ai.favoriteenemy.origin - s_home.origin );
                            v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
                        }

                        ai forceteleport( s_home.origin, v_angles );

                        //  Re-assert the whole of dog_spawn_fx()'s end state, in
                        //  stock's order, because a dog that got out there may
                        //  have got out there BECAUSE part of it never ran.
                        if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                            ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

                        ai show();
                        ai setfreecameralockonallowed( 1 );
                        ai.ignoreme  = 0;
                        ai.ignoreall = 0;
                        ai notify( "visible" );

                        println( "[zm_qol] diner dogs: RUNAWAY DOG was in no enabled zone and " + int( distance( ai.origin, s_home.origin ) ) + " units out - returned to (" + int( s_home.origin[0] ) + "," + int( s_home.origin[1] ) + "," + int( s_home.origin[2] ) + ")" );
                    }
                }
            }
            //  Already rescued once - do not fight the stock thread if it is
            //  simply slow.
            if ( isdefined( ai.zmqol_dog_rescued ) )
                continue;

            if ( distancesquared( ai.origin, v_spawner ) > 4096 )     //  64 units
                continue;

            ai.zmqol_dog_rescued = 1;

            s_loc = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];

            //  The tail of stock's own dog_spawn_fx(), in stock's order.
            v_angles = ai.angles;

            if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
            {
                v_face = vectortoangles( ai.favoriteenemy.origin - s_loc.origin );
                v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
            }

            ai forceteleport( s_loc.origin, v_angles );
            ai show();
            ai.ignoreme = 0;
            ai notify( "visible" );

            println( "[zm_qol] diner dogs: STRANDED DOG rescued to (" + int( s_loc.origin[0] ) + "," + int( s_loc.origin[1] ) + "," + int( s_loc.origin[2] ) + ")" );
        }
    }
}

// ============================================================================
//  🌟 v2.3.2 - THE GARAGE DOOR CHOKE POINT, CLOSED AT THE ACTUAL SPOT NOW.
//
//  User, 2026-08-25, with a screenshot pinpointing it: hellhounds on Diner
//  keep going "straight through the garage door" and out of the map, on every
//  dog round, not as a one-off. The v2.2.6 containment above (§ this file)
//  only rescues a dog AFTER it is 2500+ units from every player and standing
//  in no enabled zone for 5 straight seconds - it was never meant to, and
//  cannot, stop the glitch from starting, only clean up after it.
//
//  🌟 THE EXACT SPOT IS MEASURED, NOT GUESSED. Dumped `zm_transit.d3dbsp`'s
//  mapents with the Unlinker and grepped for the garage: TWO
//  `node_negotiation_begin`/`_end` pairs sit right where the screenshot
//  points -
//    `animscript "zm_traverse_garage_door"` - (-4468.7,-7453.4,-36) to
//        (-4469,-7523.5,-36), and the reverse pair back
//    `animscript "zm_traverse_car_reverse"` (the "lifted car" from the
//        2026-08-23 report, same garage) - (-4556.32,-7347.42,-36) to
//        (-4695.84,-7345,-36)
//  Both are humanoid crawl/mantle animations. Hellhounds run `zm_dog_move` /
//  `dog_move`, which has no such animation - so when a dog's pathing solver
//  picks one of these nodes anyway, there is nothing to play, and the actor
//  just keeps travelling along the path spline in a straight line with no
//  animation asserting the crouch, straight through the closed brush. This
//  confirms, rather than merely suspects, what the v2.2.6 comment already
//  flagged as "a plausible cause, not proof" for the door - and the
//  car-reverse node explains the OLDER "through the lifted car" report the
//  same way.
//
//  🛑 THERE IS NO CONFIRMED GSC-LEVEL WAY TO EXCLUDE ONE NEGOTIATION NODE
//  PER ACTOR TYPE. `_zm_blockers::blocker_disconnect_paths()` - the stock
//  function that would normally take a node pair out of the graph - is an
//  EMPTY STUB in this build (confirmed by decompiling patch_zm.ff, see the
//  zone_diner_roof comment earlier in this file), so there is no working
//  stock lever to pull here either.
//
//  🌟 SO THIS CATCHES THE ACTOR INSTEAD OF THE NODE. A dog's last known-good
//  position is tracked every tick it is OUTSIDE both corridors; the instant
//  one is found INSIDE either, it is forceteleported straight back to that
//  last-good spot with its spawn state re-asserted (same tail as the other
//  two rescues in this file), before it can finish crossing into the brush.
//  The box for each corridor is the two nodes' span plus 25-30 units of
//  padding on every side, so a dog is caught approaching, not just mid-clip.
//  Runs at 0.25s, faster than the 1s main watchdog above, because a
//  sprinting hellhound can cross either ~60-90 unit corridor in well under a
//  second.
// ============================================================================
zmqol_diner_pos_in_box( v_pos, v_min, v_max )
{
    return ( v_pos[0] >= v_min[0] && v_pos[0] <= v_max[0]
        && v_pos[1] >= v_min[1] && v_pos[1] <= v_max[1]
        && v_pos[2] >= v_min[2] && v_pos[2] <= v_max[2] );
}

zmqol_diner_dog_garage_watchdog()
{
    level endon( "end_game" );
    level endon( "intermission" );

    //  Car-reverse traverse span (-4556..-4696, -7290..-7347) padded 30 units.
    v_car_min = ( -4726, -7377, -80 );
    v_car_max = ( -4526, -7260,  40 );

    //  Garage-door traverse span (-4411..-4469, -7453..-7525) padded 30 units.
    v_door_min = ( -4499, -7555, -80 );
    v_door_max = ( -4381, -7423,  40 );

    for ( ;; )
    {
        wait 0.25;

        a_ai = getaiarray( level.zombie_team );

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            b_inside = zmqol_diner_pos_in_box( ai.origin, v_car_min, v_car_max )
                || zmqol_diner_pos_in_box( ai.origin, v_door_min, v_door_max );

            if ( !b_inside )
            {
                ai.zmqol_dog_garage_safe_pos = ai.origin;
                continue;
            }

            if ( !isdefined( ai.zmqol_dog_garage_safe_pos ) )
            {
                //  Caught with no recorded safe spot (rescued or spawned
                //  straight into the corridor) - fall back to a real dog
                //  location rather than leaving it inside the box.
                ai.zmqol_dog_garage_safe_pos = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )].origin;
            }

            v_angles = ai.angles;

            if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
            {
                v_face   = vectortoangles( ai.favoriteenemy.origin - ai.zmqol_dog_garage_safe_pos );
                v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
            }

            ai forceteleport( ai.zmqol_dog_garage_safe_pos, v_angles );

            if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

            ai show();
            ai.ignoreme  = 0;
            ai.ignoreall = 0;
            ai notify( "visible" );

            println( "[zm_qol] diner dogs: GARAGE CHOKE POINT - dog turned back before it cleared (" + int( ai.origin[0] ) + "," + int( ai.origin[1] ) + "," + int( ai.origin[2] ) + ")" );
        }
    }
}

