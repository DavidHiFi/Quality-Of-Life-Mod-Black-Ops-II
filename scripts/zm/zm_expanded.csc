#include common_scripts\utility;
#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_perks;
#include clientscripts\mp\zombies\_zm_perk_divetonuke;
//  Buried's; mod.ff carries it now (zone_source\mod_locations.zone) so it
//  resolves on every map, same as _zm_perk_electric_cherry.csc.
#include clientscripts\mp\zombies\_zm_perk_vulture;
#include clientscripts\mp\_visionset_mgr;
#include clientscripts\mp\_ambientpackage;
#include clientscripts\mp\_music;
#include clientscripts\mp\_audio;
#include clientscripts\mp\_fx;
#include clientscripts\mp\_filter;
#include clientscripts\mp\zombies\_zm;

//  CLIENT HALF OF THE WUNDERFIZZ BALL SPIN. Must mirror wunderfizz.gsc exactly.
#using_animtree("qolwf_perk_random");

main()
{
	// 🛑 THIS IS NOT OPTIONAL AND ITS POSITION MATTERS. v1.26.0 registered this
	// tree on the SERVER only and every map died on load with:
	//
	//   Error - script mover animtrees registered in different order
	//           server <qolwf_perk_random> client <zombie_bus>      (TranZit)
	//           server <qolwf_perk_random> client <zm_tomb_tank>    (Origins)
	//
	// scriptmodelsuseanimtree() does not just register a tree - it appends to an
	// ORDERED list, and the server's list and the client's must match INDEX FOR
	// INDEX. The v1.21.1 commit message called it "cumulative" and stopped there;
	// that was the missing half. Registering server-side alone puts our tree at
	// server[0] while client[0] is whatever tree the map registers first, and the
	// engine drops the client before the map starts.
	//
	// Stock does it in exactly this pair - _zm_perk_random.gsc:176 registers
	// zm_perk_random on the server and _zm_perk_random.csc:24 registers it on the
	// client. This is the same pairing for the mod's own renamed copy.
	//
	// It sits FIRST in main() because the mod's root scripts run before the map's
	// on both sides: the server crash proved our tree lands at index 0 there, so
	// the client call has to be equally early to land at index 0 too. Do not move
	// it below the replaceFuncs, and do not add another scriptmodelsuseanimtree()
	// anywhere in this mod without adding the matching call on the other side.
	scriptmodelsuseanimtree( #animtree );

	replaceFunc( clientscripts\mp\zombies\_zm_perks::perks_register_clientfield, ::perks_register_clientfield );
	replaceFunc( clientscripts\mp\zombies\_zm::init_client_flag_callback_funcs, ::init_client_flag_callback_funcs);

	// CLIENT HALF OF THE WALLBUY RE-TAG - see the block comment on
	// zmqol_enable_wallbuys() below. Without this the client registers fewer
	// world clientfields than the server and the connection is dropped with
	// EXE_CLIENT_FIELD_MISMATCH before the map starts.
	replaceFunc( clientscripts\mp\_utility_code::struct_class_init, ::struct_class_init );

	perks();
}

// ============================================================================
//  WALLBUY RE-TAG, CLIENT SIDE
// ----------------------------------------------------------------------------
//  _zm_weapons registers ONE "world" clientfield per wallbuy that matches the
//  active <ui_gametype>_<location>, named "<weapon>_<origin>". It does this
//  TWICE - once server-side in maps\mp\zombies\_zm_weapons::
//  init_spawnable_weapon_upgrade(), once client-side in
//  clientscripts\mp\zombies\_zm_weapons::init(). Both walk the same structs
//  with the same match string, so stock they always agree.
//
//  scripts\zm\locs\loc_common::enable_wallbuys() re-tags structs so wallbuys
//  standing in an added start location match. That is a .gsc, so it only ran
//  on the SERVER: the server registered 15 world clientfields, the client 13,
//  and the engine dropped the connection:
//
//      ERROR: Client and server clientfield registrations don't match.
//      Clientfield mp5k_zm_(-5489, -7982.7, 62) in set [world]
//          is not registered on the client
//      Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  So the re-tag has to happen identically on both sides. A .csc cannot
//  #include a .gsc - they are separate script systems - so the origin lists
//  below are a DUPLICATE of the ones in the .gsc location scripts.
//
//  🛑 KEEP THESE TWO LISTS IN SYNC. Any origin added to (or removed from) an
//  enable_wallbuys() call in scripts\zm\locs\ or scripts\zm\replaced\ must be
//  mirrored here, or the map stops loading with the error above. The .gsc side:
//      scripts\zm\locs\zm_transit_loc_diner.gsc       (2 origins)
//      scripts\zm\locs\zm_transit_loc_tunnel.gsc      (1 origin)
//      scripts\zm\replaced\zm_buried_gamemodes.gsc    (3 origins)
//
//  ORDERING: this replaces _utility_code::struct_class_init, called from
//  clientscripts\mp\zombies\_load::main(). _zm_weapons::init() runs later, from
//  _zm::init(), so the tags are in place before the spawn list is built. This
//  mirrors the server, where the same work happens in a struct_init() called
//  from the replaced common_scripts\utility::struct_class_init.
// ============================================================================
struct_class_init()
{
	// Stock clientscripts\mp\_utility_code::struct_class_init body. NOTE this is
	// the CLIENT's version - it indexes script_label and classname, where the
	// server's indexes script_linkname and script_unitrigger_type. Copying the
	// server's here would break client struct lookups in confusing ways.
	level.struct_class_names = [];
	level.struct_class_names["target"] = [];
	level.struct_class_names["targetname"] = [];
	level.struct_class_names["script_noteworthy"] = [];
	level.struct_class_names["script_label"] = [];
	level.struct_class_names["classname"] = [];

	for ( i = 0; i < level.struct.size; i++ )
	{
		if ( isdefined( level.struct[i].targetname ) )
		{
			if ( !isdefined( level.struct_class_names["targetname"][level.struct[i].targetname] ) )
				level.struct_class_names["targetname"][level.struct[i].targetname] = [];

			size = level.struct_class_names["targetname"][level.struct[i].targetname].size;
			level.struct_class_names["targetname"][level.struct[i].targetname][size] = level.struct[i];
		}

		if ( isdefined( level.struct[i].target ) )
		{
			if ( !isdefined( level.struct_class_names["target"][level.struct[i].target] ) )
				level.struct_class_names["target"][level.struct[i].target] = [];

			size = level.struct_class_names["target"][level.struct[i].target].size;
			level.struct_class_names["target"][level.struct[i].target][size] = level.struct[i];
		}

		if ( isdefined( level.struct[i].script_noteworthy ) )
		{
			if ( !isdefined( level.struct_class_names["script_noteworthy"][level.struct[i].script_noteworthy] ) )
				level.struct_class_names["script_noteworthy"][level.struct[i].script_noteworthy] = [];

			size = level.struct_class_names["script_noteworthy"][level.struct[i].script_noteworthy].size;
			level.struct_class_names["script_noteworthy"][level.struct[i].script_noteworthy][size] = level.struct[i];
		}

		if ( isdefined( level.struct[i].script_label ) )
		{
			if ( !isdefined( level.struct_class_names["script_label"][level.struct[i].script_label] ) )
				level.struct_class_names["script_label"][level.struct[i].script_label] = [];

			size = level.struct_class_names["script_label"][level.struct[i].script_label].size;
			level.struct_class_names["script_label"][level.struct[i].script_label][size] = level.struct[i];
		}

		if ( isdefined( level.struct[i].classname ) )
		{
			if ( !isdefined( level.struct_class_names["classname"][level.struct[i].classname] ) )
				level.struct_class_names["classname"][level.struct[i].classname] = [];

			size = level.struct_class_names["classname"][level.struct[i].classname].size;
			level.struct_class_names["classname"][level.struct[i].classname][size] = level.struct[i];
		}
	}

	// The index has to exist before getstructarray() works, so the re-tag runs
	// after the loop - exactly as the server's struct_init() does.
	zmqol_enable_wallbuys();
}

zmqol_enable_wallbuys()
{
	str_map      = getdvar( "mapname" );
	str_gametype = getdvar( "ui_gametype" );
	str_location = getdvar( "ui_zm_mapstartlocation" );

	// 🛑 GATE ON THE LOCATION, NOT THE MAP. On the server only the ACTIVE
	// location's struct_init() runs, so only that location's wallbuys get
	// re-tagged. An earlier version of this function keyed off the map and
	// tagged every location on it, which on Diner tagged the Tunnel M16 as well
	// - the client then had one clientfield MORE than the server and the
	// connection was dropped just the same, only in the other direction:
	//     Clientfield 'm16_zm_(-11839, -1695.1, 287)' in set [world]
	//         is not registered on the server
	// The two sides have to tag the SAME set, not merely overlapping sets.
	a_origins = [];

	if ( str_map == "zm_transit" && str_location == "diner" )
	{
		// zm_transit_loc_diner.gsc - registered for zstandard AND zgrief
		a_origins[a_origins.size] = ( -5489, -7982.7, 62 );        // mp5k_zm
		a_origins[a_origins.size] = ( -6399.2, -7938.5, 207.25 );  // tazer_knuckles_zm
	}
	else if ( str_map == "zm_transit" && str_location == "tunnel" )
	{
		// zm_transit_loc_tunnel.gsc - registered for zstandard AND zgrief
		a_origins[a_origins.size] = ( -11839, -1695.1, 287 );      // m16_zm
	}
	else if ( str_map == "zm_buried" && str_location == "street" && str_gametype == "zstandard" )
	{
		// zm_buried_gamemodes.gsc - street_struct_init is registered for
		// zstandard ONLY. Under zgrief the stock structs already carry
		// "zgrief_street", so the server does not re-tag and neither may we.
		a_origins[a_origins.size] = ( -926.25, 510.5, 68 );        // rottweil72_zm
		a_origins[a_origins.size] = ( 609.5, 772.75, 54 );         // m14_zm
		a_origins[a_origins.size] = ( 1.1, 1201.9, 68 );           // mp5k_zm
	}
	else
		return;

	str_match = zmqol_wallbuy_match_string();

	// Same struct set init_spawnable_weapon_upgrade() gathers, walked one
	// targetname at a time to avoid depending on the arraycombine builtin.
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
				// 16 units - absorbs float printing error only, not guesswork.
				if ( distancesquared( s_struct.origin, v_origin ) > 256 )
					continue;

				// No tag already means "spawns everywhere" - leave it alone.
				if ( isdefined( s_struct.script_noteworthy ) && s_struct.script_noteworthy != "" )
				{
					s_struct.script_noteworthy = s_struct.script_noteworthy + "," + str_match;
					n_tagged++;
				}

				break;
			}
		}
	}

	// Print the same shape as the server's line so the two counts can be compared
	// at a glance - they MUST be equal or the map will not load.
	println( "[zm_qol] CLIENT enable_wallbuys - " + str_match + ": tagged " + n_tagged + " of " + a_origins.size + " requested" );
}

// Mirror of scripts\zm\locs\loc_common::wallbuy_match_string(). Reads the dvars
// rather than level.scr_zm_ui_gametype / level.scr_zm_map_start_location because
// _zm::init() has not assigned those yet at struct_class_init time - it reads
// the very same two dvars later (clientscripts\mp\zombies\_zm.csc:32-33), so
// both sides always agree on the string.
zmqol_wallbuy_match_string()
{
	str_gametype = getdvar( "ui_gametype" );
	str_location = getdvar( "ui_zm_mapstartlocation" );

	if ( ( str_location == "default" || str_location == "" ) && isdefined( level.default_start_location ) )
		str_location = level.default_start_location;

	if ( str_location == "" )
		return str_gametype;

	return str_gametype + "_" + str_location;
}

perks()
{
	if ( getDvar("mapname") == "zm_transit" || getDvar("mapname") == "zm_nuked" || getDvar("mapname") == "zm_highrise" || getDvar("mapname") == "zm_prison" || getDvar("mapname") == "zm_buried" ) //GLOBAL
    {
		level.zombiemode_using_marathon_perk = 1;
		level.zombiemode_using_deadshot_perk = 1;
		level.zombiemode_using_additionalprimaryweapon_perk = 1;
		level.zombiemode_using_divetonuke_perk = 1;
        clientscripts\mp\zombies\_zm_perk_divetonuke::enable_divetonuke_perk_for_level();

		level thread toggle_vending_deadshot_power_on_think();
		level thread toggle_vending_deadshot_power_off_think();
		level thread toggle_vending_divetonuke_power_on_think();
		level thread toggle_vending_divetonuke_power_off_think();
	}

	zmqol_enable_electric_cherry();
	zmqol_enable_vulture();
}

// ============================================================================
//  zmqol_enable_vulture  (CLIENT)
//
//  The mandatory other half of zmqol_enable_vulture() in
//  scripts\zm\quality_of_life.gsc - read the full reasoning there.
//
//  The server registers eight clientfields for Vulture Aid on these five maps so
//  the Wunderfizz can hand out the 11th perk. If the client does not register the
//  identical eight, the sets disagree and everyone is dropped with
//  EXE_CLIENT_FIELD_MISMATCH before the map even starts.
//
//  The map list and the guard are deliberately the same shape as the server's so
//  the two cannot drift apart. Buried is excluded on both sides because it
//  enables the perk itself.
//
//  clientscripts\mp\zombies\_zm_perk_vulture.csc is not present on these maps in
//  stock - it ships in zm_buried_patch.ff - so mod.ff carries it now, declared in
//  zone_source\mod_locations.zone.
//
//  🛑 NOT verified in game yet. Requires build_ff.bat.
// ============================================================================
//  🛑 THIS LIST MUST MATCH quality_of_life.gsc::zmqol_vulture_enabled() EXACTLY.
//  It cannot literally share the function - server GSC and client CSC are separate
//  compilation units - so it is the one place a copy is unavoidable, and it is
//  therefore the one place to check first when a clientfield error appears.
//
//    zm_buried  ships the perk itself
//    zm_tomb    actor set full     (zone_capture_zombie cannot fit)
//    zm_prison  toplayer set full  (vulture_perk_disease_meter cannot fit)
//
//  The full reasoning, including why two different maps run out of two different
//  budgets, is in quality_of_life.gsc above zmqol_vulture_enabled().
zmqol_vulture_enabled()
{
	map = getDvar( "mapname" );

	if ( map == "zm_buried" )
		return 0;

	if ( map == "zm_tomb" )
		return 0;

	if ( map == "zm_prison" )
		return 0;

	return 1;
}

zmqol_enable_vulture()
{
	if ( !zmqol_vulture_enabled() )
		return;

	if ( isDefined( level._custom_perks ) && isDefined( level._custom_perks[ "specialty_nomotionsensor" ] ) )
		return;

	clientscripts\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();
}

// ============================================================================
//  zmqol_enable_electric_cherry  (CLIENT)
//
//  The mandatory other half of zmqol_enable_electric_cherry() in
//  scripts\zm\quality_of_life.gsc - read the full reasoning there.
//
//  The server registers perk_electric_cherry (and electric_cherry_reload_fx) on
//  these four maps so Wunderfizz can hand out the 9th perk. If the client does
//  not register the identical pair the sets disagree and everyone is dropped
//  with EXE_CLIENT_FIELD_MISMATCH before the map even starts.
//
//  The map list and the already-registered guard are deliberately the same shape
//  as the server's, so the two cannot drift apart. Mob of the Dead and Origins
//  are excluded on both sides because they enable the perk themselves.
//
//  clientscripts\mp\zombies\_zm_perk_electric_cherry.csc is not present on these
//  maps in stock - it ships in zm_prison_patch.ff - so mod.ff carries it now,
//  declared in zone_source\mod_locations.zone.
//
//  🛑 NOT verified in game yet. Requires build_ff.bat.
// ============================================================================
zmqol_enable_electric_cherry()
{
	map = getDvar( "mapname" );

	if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && map != "zm_buried" )
		return;

	if ( isDefined( level._custom_perks ) && isDefined( level._custom_perks[ "specialty_grenadepulldeath" ] ) )
		return;

	clientscripts\mp\zombies\_zm_perk_electric_cherry::enable_electric_cherry_perk_for_level();
}

toggle_vending_deadshot_power_on_think()
{
	while (1)
	{
		level waittill("toggle_vending_deadshot_power_on");
		ents = getentarray(0);
		foreach (ent in ents)
		{
			if (isdefined(ent.model) && ent.model == "p6_zm_al_vending_ads_on")
			{
				ent mapshaderconstant(0, 1, "ScriptVector0");
				ent setshaderconstant(0, 1, 0, 0.5, 0, 0);
			}
		}
	}
}
toggle_vending_deadshot_power_off_think()
{
	while (1)
	{
		level waittill("toggle_vending_deadshot_power_off");
		ents = getentarray(0);
		foreach (ent in ents)
		{
			if (isdefined(ent.model) && ent.model == "p6_zm_al_vending_ads_on")
			{
				ent mapshaderconstant(0, 1, "ScriptVector0");
				ent setshaderconstant(0, 1, 0, 0, 0, 0);
			}
		}
	}
}

toggle_vending_divetonuke_power_on_think()
{
	while (1)
	{
		level waittill("toggle_vending_divetonuke_power_on");

		ents = getentarray(0);

		foreach (ent in ents)
		{
			if (isdefined(ent.model) && ent.model == "p6_zm_al_vending_nuke_on")
			{
				ent mapshaderconstant(0, 1, "ScriptVector0");
				ent setshaderconstant(0, 1, 0, 0.5, 0, 0);
			}
		}
	}
}

toggle_vending_divetonuke_power_off_think()
{
	while (1)
	{
		level waittill("toggle_vending_divetonuke_power_off");

		ents = getentarray(0);

		foreach (ent in ents)
		{
			if (isdefined(ent.model) && ent.model == "p6_zm_al_vending_nuke_on")
			{
				ent mapshaderconstant(0, 1, "ScriptVector0");
				ent setshaderconstant(0, 1, 0, 0, 0, 0);
			}
		}
	}
}

perks_register_clientfield()
{
	bits = 1;
	if (clientscripts\mp\zombies\_zm_weapons::is_weapon_included("emp_grenade_zm"))
	{
		bits = 2;
	}
	if (is_true(level.zombiemode_using_additionalprimaryweapon_perk))
	{
		registerclientfield("toplayer", "perk_additional_primary_weapon", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_deadshot_perk))
	{
		registerclientfield("toplayer", "perk_dead_shot", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_doubletap_perk))
	{
		registerclientfield("toplayer", "perk_double_tap", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_juggernaut_perk))
	{
		registerclientfield("toplayer", "perk_juggernaut", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_marathon_perk))
	{
		registerclientfield("toplayer", "perk_marathon", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_revive_perk))
	{
		registerclientfield("toplayer", "perk_quick_revive", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_sleightofhand_perk))
	{
		registerclientfield("toplayer", "perk_sleight_of_hand", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_tombstone_perk))
	{
		registerclientfield("toplayer", "perk_tombstone", 1, bits, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (is_true(level.zombiemode_using_perk_intro_fx))
	{
		registerclientfield("scriptmover", "clientfield_perk_intro_fx", 1000, 1, "int", ::perk_meteor_fx, 0);
	}
	if (is_true(level.zombiemode_using_chugabud_perk))
	{
		registerclientfield("toplayer", "perk_chugabud", 1000, 1, "int", level.zombies_global_perk_client_callback, 0, 1);
	}
	if (level._custom_perks.size > 0)
	{
		a_keys = getarraykeys(level._custom_perks);
		for (i = 0; i < a_keys.size; i++)
		{
			if (isdefined(level._custom_perks[a_keys[i]].clientfield_register))
			{
				level [[level._custom_perks[a_keys[i]].clientfield_register]]();
			}
		}
	}
	level thread perk_init_code_callbacks();
}

init_client_flag_callback_funcs()
{
	level.disable_deadshot_clientfield = 1;
	level._client_flag_callbacks = [];
	level._client_flag_callbacks["vehicle"] = [];
	level._client_flag_callbacks["player"] = [];
	level._client_flag_callbacks["actor"] = [];
	level._client_flag_callbacks["scriptmover"] = [];
	if (isdefined(level.use_clientside_board_fx) && level.use_clientside_board_fx)
	{
		register_clientflag_callback("scriptmover", level._zombie_scriptmover_flag_board_vertical_fx, ::handle_vertical_board_clientside_fx);
		register_clientflag_callback("scriptmover", level._zombie_scriptmover_flag_board_horizontal_fx, ::handle_horizontal_board_clientside_fx);
	}
	if (isdefined(level.use_clientside_rock_tearin_fx) && level.use_clientside_rock_tearin_fx)
	{
		register_clientflag_callback("scriptmover", level._zombie_scriptmover_flag_rock_fx, ::handle_rock_clientside_fx);
	}
	register_clientflag_callback("scriptmover", level._zombie_scriptmover_flag_box_random, clientscripts\mp\zombies\_zm_weapons::weapon_box_callback);
	if (!is_true(level.disable_deadshot_clientfield))
	{
		registerclientfield("toplayer", "deadshot_perk", 1, 1, "int", ::player_deadshot_perk_handler, 0, 1);
	}
	if (!is_true(level._no_navcards))
	{
		if (level.scr_zm_ui_gametype == "zclassic" && !level.createfx_enabled)
		{
			registerclientfield("allplayers", "navcard_held", 1, 4, "int", undefined, 0, 1);
			level thread set_clientfield_navcard_code_callback("navcard_held");
		}
	}
	if (!is_true(level._no_water_risers))
	{
		registerclientfield("actor", "zombie_riser_fx_water", 1, 1, "int", ::handle_zombie_risers_water, 1);
	}
	if (is_true(level._foliage_risers))
	{
		registerclientfield("actor", "zombie_riser_fx_foliage", 12000, 1, "int", ::handle_zombie_risers_foliage, 1);
	}
	registerclientfield("actor", "zombie_riser_fx", 1, 1, "int", ::handle_zombie_risers, 1);
	if (is_true(level.risers_use_low_gravity_fx))
	{
		registerclientfield("actor", "zombie_riser_fx_lowg", 1, 1, "int", ::handle_zombie_risers_lowg, 1);
	}
}