#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;

init()
{
	// zm_qol diagnostic marker. Every ported location script threads this from its
	// main(), so this line appearing in console_zm.log proves the location's precache
	// and main both completed. If a location crashes, the ABSENCE of this line is the
	// signal that it died earlier (precache / struct_init / main).
	println( "[zm_qol] loc_common::init reached - location=" + getdvar( "ui_zm_mapstartlocation" ) );

	level.enemy_location_override_func = ::enemy_location_override;
	flag_wait("initial_blackscreen_passed");
	maps\mp\zombies\_zm_game_module::turn_power_on_and_open_doors();
	flag_wait("start_zombie_round_logic");
	wait 1;
	level notify("revive_on");
	wait_network_frame();
	level notify("doubletap_on");
	wait_network_frame();
	level notify("marathon_on");
	wait_network_frame();
	level notify("juggernog_on");
	wait_network_frame();
	level notify("sleight_on");
	wait_network_frame();
	level notify("tombstone_on");
	wait_network_frame();
	level notify("additionalprimaryweapon_on");
	wait_network_frame();
	level notify("Pack_A_Punch_on");
}

enemy_location_override(zombie, enemy)
{
	location = enemy.origin;

	if (is_true(self.reroute))
	{
		if (isDefined(self.reroute_origin))
		{
			location = self.reroute_origin;
		}
	}

	return location;
}

// ============================================================================
//  WALLBUYS ON NON-STOCK START LOCATIONS
// ----------------------------------------------------------------------------
//  Stock maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade() decides
//  which wallbuys exist by string-matching each wallbuy struct's
//  script_noteworthy against "<ui_gametype>_<start location>". A struct with NO
//  script_noteworthy always spawns; a tagged one spawns ONLY for the pairs it
//  lists.
//
//  Nothing in the stock maps tags the locations this mod adds, so a tagged
//  wallbuy standing in a new location's play area silently never appears. That
//  is the whole reason Diner survival had no wallbuys: the two that stand in the
//  diner - MP5K inside, Galvaknuckles on the roof - are tagged
//  "zclassic_transit" and nothing else.
//
//  Which maps this actually affects was checked, not assumed, by dumping every
//  map's entity list with OAT's Unlinker
//  (Unlinker.exe --include-assets mapents <map>.ff) and reading the
//  weapon_upgrade / bowie_upgrade / sickle_upgrade / tazer_upgrade /
//  claymore_purchase / buildable_wallbuy structs:
//
//    zm_highrise, zm_prison, zm_tomb - EVERY wallbuy is untagged, so Shopping
//        Mall, Dragon Rooftop, Sweatshop, Docks, Trenches, Excavation Site,
//        Church and The Crazy Place already get all of them. Nothing to do.
//    zm_transit - almost all tagged. Diner and Tunnel each have wallbuys of
//        their own that need re-tagging (below). Power's AK74u is untagged and
//        already works.
//    zm_buried - all tagged. Borough/street needs re-tagging.
//
//  Cornfield (TranZit) and Maze (Buried) have NO wallbuy struct anywhere in
//  their play area in the stock map, so there is nothing to enable - they are
//  magic-box-only by design. Reimagined does not add any there either.
//
//  ORDERING: this must be called from a location's struct_init(), which runs
//  inside struct_class_init() in _load::main(). _zm_weapons::init() runs later,
//  from _zm::main(). Re-tagging any later than struct_init is too late - the
//  spawn list has already been built and level._spawned_wallbuys is fixed.
// ============================================================================
enable_wallbuys( a_origins )
{
	str_match = wallbuy_match_string();

	// The same set init_spawnable_weapon_upgrade() gathers. Walked one
	// targetname at a time rather than arraycombine'd: arraycombine is not
	// defined in any stock script in the reference dump, so it is an engine
	// builtin, and there is no reason to depend on that here.
	a_targetnames = [];
	a_targetnames[a_targetnames.size] = "weapon_upgrade";
	a_targetnames[a_targetnames.size] = "bowie_upgrade";
	a_targetnames[a_targetnames.size] = "sickle_upgrade";
	a_targetnames[a_targetnames.size] = "tazer_upgrade";
	a_targetnames[a_targetnames.size] = "claymore_purchase";
	a_targetnames[a_targetnames.size] = "buildable_wallbuy";

	n_tagged = 0;

	foreach ( str_targetname in a_targetnames )
	{
		a_structs = getstructarray( str_targetname, "targetname" );

		if ( !isdefined( a_structs ) )
			continue;

		foreach ( s_struct in a_structs )
		{
			if ( !isdefined( s_struct.origin ) )
				continue;

			foreach ( v_origin in a_origins )
			{
				// 16 units. The origins passed in are copied verbatim out of
				// the map ents dump, so this only has to absorb float printing
				// error, never "near enough" guessing.
				if ( distancesquared( s_struct.origin, v_origin ) > 256 )
					continue;

				// No tag already means "spawns everywhere" - leave it alone
				// rather than narrowing it.
				if ( isdefined( s_struct.script_noteworthy ) && s_struct.script_noteworthy != "" )
				{
					s_struct.script_noteworthy = s_struct.script_noteworthy + "," + str_match;
					n_tagged++;
				}

				break;
			}
		}
	}

	println( "[zm_qol] enable_wallbuys - " + str_match + ": tagged " + n_tagged + " of " + a_origins.size + " requested" );
}

// Rebuilds the exact match string init_spawnable_weapon_upgrade() will use.
// It reads level.scr_zm_ui_gametype / level.scr_zm_map_start_location, but
// _zm::main() has NOT assigned those yet when struct_init runs, so read the two
// dvars they are initialised from instead - same values, available earlier.
wallbuy_match_string()
{
	str_gametype = getdvar( "ui_gametype" );
	str_location = getdvar( "ui_zm_mapstartlocation" );

	if ( ( str_location == "default" || str_location == "" ) && isdefined( level.default_start_location ) )
		str_location = level.default_start_location;

	if ( str_location == "" )
		return str_gametype;

	return str_gametype + "_" + str_location;
}

increase_pap_collision()
{
	pap_triggers = getentarray("specialty_weapupgrade", "script_noteworthy");

	foreach (pap_trigger in pap_triggers)
	{
		if (isdefined(pap_trigger.clip))
		{
			move_amount = 8;

			if (isdefined(pap_trigger.machine) && pap_trigger.machine.model == "p6_zm_tm_packapunch")
			{
				move_amount = 12;
			}

			collision = spawn("script_model", pap_trigger.clip.origin + anglestoforward(pap_trigger.clip.angles) * move_amount * -1, 1);
			collision.angles = pap_trigger.clip.angles;
			collision setmodel("zm_collision_perks1");
			collision.script_noteworthy = "clip";
			collision disconnectpaths();
			pap_trigger.clip2 = collision;

			pap_trigger.clip.origin += anglestoforward(pap_trigger.clip.angles) * move_amount;
		}
	}
}

barrier(model, origin, angles, disconnect_paths = 0)
{
	barrier = undefined;

	if (disconnect_paths)
	{
		barrier = spawn("script_model", origin, 1);
	}
	else
	{
		barrier = spawn("script_model", origin);
	}

	barrier.angles = angles;
	barrier setModel(model);

	if (disconnect_paths)
	{
		barrier disconnectPaths();
	}
}
// ============================================================================
//  Buildable-stub swapping - used by zm_highrise_loc_sweatshop.
// ----------------------------------------------------------------------------
//  🛑 WHY THESE LIVE HERE instead of being called from the stock script:
//  Reimagined calls scripts\zm\replaced\_zm_buildables_pooled::swap_buildable_fields.
//  zm_qol does not port that file, because it #includes the stock module
//  maps\mp\zombies\_zm_buildables_pooled - and that module ships ONLY in Buried's
//  fastfile. Referencing it from a Die Rise script would be an unresolved
//  external and would crash the map (AI_CONTEXT rule 2).
//
//  Pointing at the stock function directly has the same problem, and stock's
//  version also does not swap .cost. So the three functions are carried here
//  verbatim from Reimagined instead. They call only engine builtins (getent,
//  anglesTo*, worldtolocalcoords, localtoworldcoords), so this file stays safe
//  to load on every map.
// ============================================================================
find_bench(bench_name)
{
	return getent(bench_name, "targetname");
}

swap_buildable_fields(stub1, stub2)
{
	temp = stub2.buildablezone;
	stub2.buildablezone = stub1.buildablezone;
	stub2.buildablezone.stub = stub2;
	stub1.buildablezone = temp;
	stub1.buildablezone.stub = stub1;
	temp = stub2.buildablestruct;
	stub2.buildablestruct = stub1.buildablestruct;
	stub1.buildablestruct = temp;
	temp = stub2.equipname;
	stub2.equipname = stub1.equipname;
	stub1.equipname = temp;
	temp = stub2.hint_string;
	stub2.hint_string = stub1.hint_string;
	stub1.hint_string = temp;
	temp = stub2.trigger_hintstring;
	stub2.trigger_hintstring = stub1.trigger_hintstring;
	stub1.trigger_hintstring = temp;
	temp = stub2.persistent;
	stub2.persistent = stub1.persistent;
	stub1.persistent = temp;
	temp = stub2.onbeginuse;
	stub2.onbeginuse = stub1.onbeginuse;
	stub1.onbeginuse = temp;
	temp = stub2.oncantuse;
	stub2.oncantuse = stub1.oncantuse;
	stub1.oncantuse = temp;
	temp = stub2.onenduse;
	stub2.onenduse = stub1.onenduse;
	stub1.onenduse = temp;
	temp = stub2.target;
	stub2.target = stub1.target;
	stub1.target = temp;
	temp = stub2.targetname;
	stub2.targetname = stub1.targetname;
	stub1.targetname = temp;
	temp = stub2.weaponname;
	stub2.weaponname = stub1.weaponname;
	stub1.weaponname = temp;
	temp = stub2.cost;
	stub2.cost = stub1.cost;
	stub1.cost = temp;
	temp = stub2.original_prompt_and_visibility_func;
	stub2.original_prompt_and_visibility_func = stub1.original_prompt_and_visibility_func;
	stub1.original_prompt_and_visibility_func = temp;
	bench1 = undefined;
	bench2 = undefined;
	transfer_pos_as_is = 1;

	if (isdefined(stub1.model.target) && isdefined(stub2.model.target))
	{
		bench1 = find_bench(stub1.model.target);
		bench2 = find_bench(stub2.model.target);

		if (isdefined(bench1) && isdefined(bench2))
		{
			transfer_pos_as_is = 0;
			temp = [];
			temp[0] = bench1 worldtolocalcoords(stub1.model.origin);
			temp[1] = stub1.model.angles - bench1.angles;
			temp[2] = bench2 worldtolocalcoords(stub2.model.origin);
			temp[3] = stub2.model.angles - bench2.angles;
			stub1.model.origin = bench2 localtoworldcoords(temp[0]);
			stub1.model.angles = bench2.angles + temp[1];
			stub2.model.origin = bench1 localtoworldcoords(temp[2]);
			stub2.model.angles = bench1.angles + temp[3];
		}

		temp = stub2.model.target;
		stub2.model.target = stub1.model.target;
		stub1.model.target = temp;
	}

	temp = stub2.model;
	stub2.model = stub1.model;
	stub1.model = temp;

	if (transfer_pos_as_is)
	{
		temp = [];
		temp[0] = stub2.model.origin;
		temp[1] = stub2.model.angles;
		stub2.model.origin = stub1.model.origin;
		stub2.model.angles = stub1.model.angles;
		stub1.model.origin = temp[0];
		stub1.model.angles = temp[1];

		swap_buildable_fields_model_offset(stub1, stub2);
	}
}

swap_buildable_fields_model_offset(stub1, stub2)
{
	origin_offset = (0, 0, 0);
	angle_offset = (0, 0, 0);

	if (stub1.weaponname == "equip_turbine_zm")
	{
		if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (6, -6, -27);
			angle_offset = (0, -180, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-7, -5, 0);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (-2, 8, 0);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-3, -4, -24);
			angle_offset = (0, -90, 0);
		}
	}
	else if (stub1.weaponname == "riotshield_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (-6, 6, 27);
			angle_offset = (0, 180, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-1, 1, 27);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (2, -4, 27);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-2, 5, 3);
			angle_offset = (0, 90, 0);
		}
	}
	else if (stub1.weaponname == "equip_turret_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (7, 5, 0);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (1, -1, -27);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (2, -2, 0);
			angle_offset = (0, -180, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (4, 0, -24);
			angle_offset = (0, 0, 0);
		}
	}
	else if (stub1.weaponname == "equip_electrictrap_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (2, -8, 0);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (-2, 4, -27);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-2, 2, 0);
			angle_offset = (0, 180, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-6, 3, -24);
			angle_offset = (0, 180, 0);
		}
	}
	else if (stub1.weaponname == "jetgun_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (3, 4, 24);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (2, -5, -3);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-4, 0, 24);
			angle_offset = (0, 0, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (6, -3, 24);
			angle_offset = (0, -180, 0);
		}
	}
	else if (stub1.weaponname == "equip_springpad_zm")
	{
		if (stub2.weaponname == "slipgun_zm")
		{
			origin_offset = (-14, 2, -2);
			angle_offset = (64.2, 90, 0);
		}
	}
	else if (stub1.weaponname == "slipgun_zm")
	{
		if (stub2.weaponname == "equip_springpad_zm")
		{
			origin_offset = (14, -2, 2);
			angle_offset = (-64.2, -90, 0);
		}
	}

	stub1.model.angles += angle_offset;
	stub2.model.angles -= angle_offset;

	model1_angle = (0, stub1.model.angles[1], 0);
	model2_angle = (0, stub2.model.angles[1], 0);

	if (angle_offset[1] < 0)
	{
		model1_angle -= (0, angle_offset[1], 0);
	}
	else
	{
		model2_angle += (0, angle_offset[1], 0);
	}

	stub1.model.origin += (anglesToForward(model1_angle) * origin_offset[0]) + (anglesToRight(model1_angle) * origin_offset[1]) + (anglesToUp(model1_angle) * origin_offset[2]);
	stub2.model.origin -= (anglesToForward(model2_angle) * origin_offset[0]) + (anglesToRight(model2_angle) * origin_offset[1]) + (anglesToUp(model2_angle) * origin_offset[2]);
}


// ============================================================================
//  spawn_wallbuy_plywood - used by zm_tomb_loc_excavation_site.
//
//  zm_qol: carried here from Reimagined's scripts\zm\zm_tomb\zm_tomb_reimagined,
//  which this project does not port. Self-contained (spawn/setmodel and vector
//  builtins only); the models it uses are Origins assets, so it is only ever
//  called from the Origins location scripts.
// ============================================================================
spawn_wallbuy_plywood(origin, angles)
{
	model1 = spawn("script_model", origin);
	model1.angles = angles + (-90, 0, 0);
	model1 setmodel("p6_pak_old_plywood_small");

	model2 = spawn("script_model", origin + anglestoforward(angles) * 2 + anglestoup(angles) * -15);
	model2.angles = angles + (0, 90, 0);
	model2 setmodel("p6_zm_tm_wood_post_thin_01_tall");

	model3 = spawn("script_model", origin + anglestoforward(angles) * 1 + anglestoright(angles) * -25 + anglestoup(angles) * -15);
	model3.angles = angles;
	model3 setmodel("p6_zm_tm_wood_post_thin_01_tall");

	model4 = spawn("script_model", origin + anglestoforward(angles) * 1 + anglestoright(angles) * 25 + anglestoup(angles) * -15);
	model4.angles = angles + (0, 180, 0);
	model4 setmodel("p6_zm_tm_wood_post_thin_01_tall");
}
