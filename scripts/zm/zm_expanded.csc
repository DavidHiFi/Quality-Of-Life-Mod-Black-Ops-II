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

	// CLIENT HALF OF FIRE SALE. Missing since v1.54.0 - see the block below.
	zmqol_enable_fire_sale();

	// CLIENT HALF OF BLOOD MONEY - see the block below.
	zmqol_enable_blood_money();

	perks();
}

// ============================================================================
//  zmqol_enable_blood_money  (CLIENT)  -  EXACT TWIN of the same function in
//                                         scripts\zm\quality_of_life.gsc
//
//  📝 THIS ONE CANNOT CAUSE A MISMATCH, unlike the fire-sale twin below, and it
//  is worth knowing why rather than assuming the two are the same shape.
//  Blood Money is `bonus_points_player`, and NEITHER side passes a
//  client_field_name to add_zombie_powerup:
//      server  _zm_powerups.gsc:106   add_zombie_powerup( "bonus_points_player",
//                                       "zombie_z_money_icon", &"...", ::func_should_never_drop, 1, 0, 0 );
//      client  _zm_powerups.csc:20    add_zombie_powerup( "bonus_points_player" );
//  Both sides' add_zombie_powerup only reach their registerclientfield() inside
//  `if ( isdefined( client_field_name ) )`, so this powerup registers NOTHING in
//  the toplayer set on either side. The include list can therefore never fall out
//  of symmetry the way fire_sale's did in v1.54.0.
//
//  🌟 IT IS STILL ADDED, for two reasons. It keeps the two include lists identical
//  - the discipline the fire-sale bug taught - and it creates
//  level.zombie_powerups["bonus_points_player"] on the client, which is what
//  set_clientfield_code_callbacks() (_zm_powerups.csc:72-77) walks. That loop
//  reads .client_field_name and skips entries without one, so today it is inert;
//  keeping the struct present means it stays correct if that ever changes.
//
//  🛑 THE MAP GATE IS OMITTED DELIBERATELY, and the trap called out in the
//  fire-sale block below was checked before doing so. That trap - creating
//  level.zombie_include_powerups on a map whose client never populates it would
//  flip the gate and filter EVERY powerup down to ours - cannot fire here,
//  because all six maps call include_powerups() from their own .csc:
//      zm_transit.csc:239  zm_nuked.csc:56    zm_highrise.csc:94
//      zm_prison.csc:169   zm_buried.csc:496  zm_tomb.csc:142
//  and include_zombie_powerup() is idempotent, so Origins - which already
//  includes it at zm_tomb.csc:416 - is a no-op.
// ============================================================================
zmqol_enable_blood_money()
{
	clientscripts\mp\zombies\_zm_utility::include_powerup( "bonus_points_player" );
}

// ============================================================================
//  zmqol_enable_fire_sale  (CLIENT)  -  EXACT TWIN of the same function in
//                                       scripts\zm\quality_of_life.gsc
//
//  🛑 THE BUG THIS FIXES, and it was fatal, not cosmetic:
//        *****MISMATCHED CLIENTFIELDS*****
//        Clientfield powerup_fire_sale in set [toplayer] is not registered on the client
//        Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//  on TranZit (any location, reported on Diner) and Die Rise. Latent since
//  v1.54.0 shipped Fire Sale server-side with no client half; it only surfaced
//  now because those two maps had not been booted since.
//
//  🌟 WHY A ONE-LINE SERVER CHANGE NEEDED A CLIENT TWIN AT ALL. The powerup
//  clientfield is not registered by name anywhere - it is registered as a side
//  effect of a LIST. Both sides run their own add_zombie_powerup(), and both
//  open with the same gate:
//        if ( isdefined( level.zombie_include_powerups ) &&
//             !isdefined( level.zombie_include_powerups[powerup_name] ) )
//            return;
//  level.zombie_include_powerups is per-VM. Adding "fire_sale" to the SERVER's
//  list made the server register toplayer/powerup_fire_sale; the client's list
//  was untouched, so the client skipped it, and the sets came out one field
//  apart. Stock's own lists disagree the same way - zm_transit.csc:335 and
//  zm_highrise.csc:198 both omit fire_sale, matching their server halves
//  exactly. That symmetry is the thing v1.54.0 broke.
//
//  📝 Both sides register IDENTICALLY - ("toplayer", "powerup_fire_sale", 1, 2,
//  "int") - because both derive it from the same add_zombie_powerup arguments.
//  Server _zm_powerups.gsc:100 passes client_field_name "powerup_fire_sale" and
//  no clientfield_version, so both default to version 1 and 2 bits. Nothing has
//  to be kept in sync by hand beyond the map list in these two functions.
//
//  🛑 ORDERING, verified rather than assumed. Both maps' client scripts do:
//        start_zombie_stuff() { ... include_powerups();
//                                   clientscripts\mp\zombies\_zm::init(); ... }
//  and _zm.csc:63 is where _zm_powerups::init() runs. So the list must be
//  complete before _zm::init(). This main() runs before the map's - proven by
//  the animtree crash documented at the top of this file, where our
//  scriptmodelsuseanimtree() landed at client index 0 ahead of the map's - and
//  include_zombie_powerup() is purely additive (it creates the array only if
//  undefined and never clears it), so writing early cannot lose the map's own
//  entries when include_powerups() runs afterwards.
//
//  🛑 THE MAP GATE IS NOT COSMETIC. On a map whose client never calls
//  include_powerups() at all, level.zombie_include_powerups stays undefined and
//  the gate above lets EVERY powerup through. Creating the array there would
//  flip that gate and filter every powerup down to fire_sale alone. Both maps
//  named here do populate it (zm_transit.csc:335, zm_highrise.csc:198), which
//  is exactly why the list must stay these two and must match the server's.
//
//  The client's add_zombie_powerup precaches NOTHING - unlike the server's,
//  which precaches the zombie_firesale model (already shipped in
//  zone_source\mod_locations.zone). So this half needs no asset and no mod.ff
//  relink.
// ============================================================================
zmqol_enable_fire_sale()
{
	map = getDvar( "mapname" );

	if ( map != "zm_transit" && map != "zm_highrise" )
		return;     // the other four include it themselves, on both sides

	clientscripts\mp\zombies\_zm_utility::include_powerup( "fire_sale" );
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
	zmqol_add_semtex_wallbuy();
}

// ============================================================================
//  zm_qol: SEMTEX WALL-BUY BY THE DINER EXIT DOOR - CLIENT HALF     (v1.68.0)
//
//  🛑 EXACT TWIN of scripts\zm\locs\zm_transit_loc_diner.gsc::
//  zmqol_add_semtex_wallbuy(). This is not optional and it is not cosmetic.
//  _zm_weapons registers one "world" clientfield per wallbuy struct, named from
//  the struct itself - _zm_weapons.csc:218 builds
//      script_label = zombie_weapon_upgrade + "_" + origin
//  and :225 registers it. So a struct that exists on only one side makes the two
//  sets differ by one field and every player is dropped at load, exactly like
//  the Tunnel M16 incident recorded in zmqol_enable_wallbuys() above.
//
//  Both halves read the SAME dvars with the SAME defaults, so the origin - and
//  therefore the field name - cannot diverge, and tuning the placement stays
//  safe because it renames the field identically on both sides.
//
//  The gate is the one enable_wallbuys() already uses for this location: map
//  zm_transit, start location diner. The server's struct_init() for diner is
//  registered for zstandard AND zgrief, and this matches that by not testing
//  gametype at all.
//
//  Appends straight into level.struct_class_names["targetname"], which is what
//  getstructarray() reads and what the loop above has just built - the client
//  has no add_struct() helper, so this does that one job inline.
// ============================================================================
zmqol_semtex_wallbuy_origin()
{
	// Twin of zm_transit_loc_diner.gsc::zmqol_semtex_wallbuy_origin(). x = -5175 is
	// the wall's room-side face, measured from the doorway model - see the server
	// copy for the full derivation and for why v1.69.10's -5172 was 3 units out.
	// These two MUST stay identical: the clientfield name is built from the origin.
	return ( getdvarintdefault( "zmqol_semtex_diner_x", -5177 ), getdvarintdefault( "zmqol_semtex_diner_y", -7925 ), getdvarintdefault( "zmqol_semtex_diner_z", -14 ) );
}

zmqol_client_add_struct( s_struct )
{
	if ( !isdefined( level.struct_class_names["targetname"][s_struct.targetname] ) )
		level.struct_class_names["targetname"][s_struct.targetname] = [];

	n_size = level.struct_class_names["targetname"][s_struct.targetname].size;
	level.struct_class_names["targetname"][s_struct.targetname][n_size] = s_struct;
}

zmqol_add_semtex_wallbuy()
{
	if ( getdvar( "mapname" ) != "zm_transit" || getdvar( "ui_zm_mapstartlocation" ) != "diner" )
		return;

	v_origin = zmqol_semtex_wallbuy_origin();
	// 270, not 90 - see the server copy. At 90 the bag's body points world -X,
	// i.e. straight into the wall, which is why only the wallbuy fx ever showed.
	v_angles = ( 0, getdvarintdefault( "zmqol_semtex_diner_yaw", 270 ), 0 );

	s_model = spawnstruct();
	s_model.targetname = "zmqol_semtex_diner";
	s_model.origin = v_origin;
	s_model.angles = v_angles;
	s_model.model = "semtex_bag";
	zmqol_client_add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "weapon_upgrade";
	s_buy.origin = v_origin;
	s_buy.angles = v_angles;
	s_buy.zombie_weapon_upgrade = "sticky_grenade_zm";
	s_buy.target = "zmqol_semtex_diner";
	zmqol_client_add_struct( s_buy );

	println( "[zm_qol] CLIENT diner semtex: wallbuy struct at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ")" );
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

		//  🛑 EXACT TWIN of the same line in quality_of_life.gsc::perks().
		//  perks_register_clientfield gates registerclientfield("toplayer",
		//  "perk_tombstone", ...) on this flag on BOTH sides, so if these two
		//  functions ever disagree the toplayer set is one field wider on one
		//  side and everyone is dropped with EXE_CLIENT_FIELD_MISMATCH before
		//  the map starts. Change one, change the other.
		level.zombiemode_using_tombstone_perk = 1;

		level thread toggle_vending_deadshot_power_on_think();
		level thread toggle_vending_deadshot_power_off_think();
		level thread toggle_vending_divetonuke_power_on_think();
		level thread toggle_vending_divetonuke_power_off_think();
	}

	//  🛑 EXACT TWIN of the zm_tomb block in quality_of_life.gsc::perks().
	//  v1.58.4 - Origins gets Tombstone, paid for by dropping the Vulture
	//  disease meter there (5 bits freed, 2 spent). The v1.58.2 attempt failed
	//  because nothing was freed first.
	//
	//  Both sides gate registerclientfield( "toplayer", "perk_tombstone" ) on
	//  this flag. Disagree and the set is one field wider on one side and every
	//  player is dropped with EXE_CLIENT_FIELD_MISMATCH before the map starts.
	//
	//  Only the flag - NOT the divetonuke enable or the vending threads above.
	//  Origins already has dive-to-nuke, marathon, deadshot and
	//  additional-primary natively; Tombstone is its only real gap.
	if ( getDvar( "mapname" ) == "zm_tomb" )
	{
		level.zombiemode_using_tombstone_perk = 1;
	}

	zmqol_enable_electric_cherry();
	zmqol_enable_vulture();
	zmqol_enable_whoswho();

	//  🛑 EXACT TWIN of the call at the end of quality_of_life.gsc::perks().
	//  Only the include list is done here; every registration Zombie Blood needs
	//  on the client happens later, in perks_register_clientfield() - see the
	//  long block on zmqol_enable_zombie_blood() below for why it has to.
	zmqol_enable_zombie_blood();
}

// ============================================================================
//  ZOMBIE BLOOD  (CLIENT)  -  the mandatory other half of
//  quality_of_life.gsc::zmqol_enable_zombie_blood()          (v1.65.0)
//
//  Ported from Origins' clientscripts\mp\zombies\_zm_powerup_zombie_blood.csc
//  rather than shipping that file, because it lives in zm_tomb_patch.ff and
//  adding a fastfile to build_ff.bat's --load list risks re-donating a shared
//  asset (the v1.62.6 blown-out-shader bug). Every function it uses is core
//  client code, so the port costs nothing - the same call already made for
//  Who's Who.
//
//  🛑 THIS MAP LIST MUST MATCH quality_of_life.gsc::zmqol_zombie_blood_enabled()
//  EXACTLY. Two clientfields are at stake - player_zombie_blood_fx (allplayers,
//  1 bit) and powerup_zombie_blood (toplayer, 2 bits, registered as a side effect
//  of add_zombie_powerup) - plus the two visionset-manager entries, whose count
//  sets visionset_slot's and overlay_slot's bit widths. Disagree on any of it and
//  every player is dropped with EXE_CLIENT_FIELD_MISMATCH before the map starts.
//
//  🛑 EVERYTHING EXCEPT THE INCLUDE RUNS IN perks_register_clientfield(), NOT
//  HERE, and each of the four reasons is a separate silent failure:
//
//    1. level.vsmgr_filter_custom_enable IS WIPED AFTER main(). _visionset_mgr.csc
//       :15 does `level.vsmgr_filter_custom_enable = []` and it is reached from
//       _zm.csc:39 - later than this script's main(). Setting our entry here
//       would be erased, the overlay would fall through to the generic branch
//       (_visionset_mgr.csc:527) and the red screen filter would never fade in.
//       No error, anywhere.
//    2. The two vsmgr_register_* calls need level.vsmgr, which does not exist
//       during main() at all - [[t6-visionset-registration-timing]], and the same
//       reason the Who's Who visionset sits in that function.
//    3. onplayerconnect_callback needs to be registered before
//       level._customplayerconnectfuncs is armed at _zm.csc:96 - which is after
//       _zm_perks::init() at :62, so that slot is comfortably early enough.
//    4. add_zombie_powerup() must land before _zm_powerups.csc::init() threads
//       set_clientfield_code_callbacks() at :63 (it walks level.zombie_powerups
//       after a 0.1s wait). :62 is before :63.
//
//  📝 include_powerup() DOES belong here in main(), like Fire Sale's and Blood
//  Money's twins above: it only writes level.zombie_include_powerups, which
//  add_zombie_powerup reads as its own gate, and writing it early cannot lose the
//  map's own entries (include_zombie_powerup is purely additive).
// ============================================================================
zmqol_zombie_blood_enabled()
{
	// 🛑 EXACT TWIN of quality_of_life.gsc::zmqol_zombie_blood_enabled() —
	// read the long block there. Origins ships the power-up itself.
	if ( getDvar( "mapname" ) == "zm_tomb" )
		return 0;

	// 🛑 v1.65.2 — Mob of the Dead's toplayer set is out of space. Measured from
	// the user's failed boot: "Trying to assign 3 bits for netfield
	// visionset_slot but Client Field Set toplayer is out of space." The two
	// *_lerp fields are the expensive part and neither exists in stock Mob —
	// full accounting in the server twin.
	if ( getDvar( "mapname" ) == "zm_prison" )
		return 0;

	return 1;
}

zmqol_enable_zombie_blood()
{
	if ( !zmqol_zombie_blood_enabled() )
		return;

	clientscripts\mp\zombies\_zm_utility::include_powerup( "zombie_blood" );
}

// ============================================================================
//  zmqol_zb_register  -  called from perks_register_clientfield(), see above
//
//  Line for line clientscripts\mp\zombies\_zm_powerup_zombie_blood::init(),
//  minus the priority level-vars (server-side only) and with the sound aliases
//  repointed at this mod's own copies.
// ============================================================================
zmqol_zb_register()
{
	if ( !zmqol_zombie_blood_enabled() )
		return;

	onplayerconnect_callback( ::zmqol_zb_init_filter );
	level.vsmgr_filter_custom_enable[ "generic_filter_zombie_blood_b" ] = ::zmqol_zb_vsmgr_enable_filter;
	registerclientfield( "allplayers", "player_zombie_blood_fx", 14000, 1, "int", ::zmqol_zb_toggle_fx, 0, 1 );
	level._effect[ "zombie_blood" ]     = loadfx( "maps/zombie_tomb/fx_tomb_pwr_up_zmb_blood" );
	level._effect[ "zombie_blood_1st" ] = loadfx( "maps/zombie_tomb/fx_zm_blood_overlay_pclouds" );
	clientscripts\mp\zombies\_zm_powerups::add_zombie_powerup( "zombie_blood", "powerup_zombie_blood" );

	//  Guarded on the manager being present so that if this ordering ever changes
	//  it degrades to "visionset not registered" instead of erroring out of the
	//  whole clientfield pass - the same guard the Who's Who registration uses.
	if ( isdefined( level.vsmgr ) && isdefined( level.vsmgr[ "visionset" ] ) )
	{
		clientscripts\mp\_visionset_mgr::vsmgr_register_visionset_info( "zm_powerup_zombie_blood_visionset",
			14000, 15, "zm_powerup_zombie_blood", "zm_powerup_zombie_blood" );
	}

	//  filter_index 1, pass_index 0 are Origins' own and collide with nothing
	//  this mod uses - Vulture's overlay is filter 0, Who's Who's afterlife
	//  filter is 5.
	if ( isdefined( level.vsmgr ) && isdefined( level.vsmgr[ "overlay" ] ) )
	{
		clientscripts\mp\_visionset_mgr::vsmgr_register_overlay_info_style_filter( "zm_powerup_zombie_blood_overlay",
			14000, 15, 1, 0, "generic_filter_zombie_blood_b" );
	}
}

zmqol_zb_vsmgr_enable_filter( curr_info )
{
	zmqol_zb_enable_filter( self, curr_info.filter_index, 0.0 );
}

zmqol_zb_init_filter( localclientnum )
{
	player = getlocalplayer( localclientnum );
	clientscripts\mp\_filter::init_filter_indices();
	clientscripts\mp\_filter::map_material_helper( player, "generic_filter_zombie_blood_b" );
}

zmqol_zb_set_overlay_amount( player, filterid, amount )
{
	player set_filter_pass_constant( filterid, 0, 0, amount );
}

zmqol_zb_enable_filter( player, filterid, zombie_blood_warp_shift_enabled )
{
	player set_filter_pass_material( filterid, 0, level.filter_matid[ "generic_filter_zombie_blood_b" ] );
	player set_filter_pass_enabled( filterid, 0, 1 );
	self thread zmqol_zb_overlay_fade_in();
}

zmqol_zb_overlay_fade_in()
{
	self endon( "entity_shutdown" );
	zmqol_zb_overlay_lerp( 1.0, 0.2, 0.3 );
	wait 0.2;
	zmqol_zb_overlay_lerp( 0.2, 0.8, 1.0 );
}

zmqol_zb_overlay_lerp( n_fraction_start, n_fraction_end, n_trans_time )
{
	n_fraction_delta = n_fraction_end - n_fraction_start;
	zmqol_zb_set_overlay_amount( self, 1, n_fraction_start );

	for ( n_time = 0.0; n_time < n_trans_time; n_time = n_time + 0.0166667 )
	{
		n_fraction = n_fraction_start + n_fraction_delta * n_time / n_trans_time;
		zmqol_zb_set_overlay_amount( self, 1, n_fraction );
		wait 0.0166667;
	}

	zmqol_zb_set_overlay_amount( self, 1, n_fraction_end );
}

// ============================================================================
//  zmqol_zb_toggle_fx  -  the player_zombie_blood_fx clientfield callback
//
//  🛑 THE THREE SOUND ALIASES ARE ORIGINS-ONLY - measured, not assumed. The
//  alias tables of zmb_tomb, zmb_highrise, zmb_alcatraz, zmb_buried,
//  zmb_nuked_real, zmb_classic_transit and zmb_survival_transit were dumped with
//  Unlinker --include-assets soundbank: zmb_zombieblood_start / _loop / _stop
//  appear ONLY in zmb_tomb.all. A missing alias is SILENT, never an error, so
//  calling Origins' names here would have shipped a mute power-up with nothing in
//  any log. They are re-shipped under zmqol_ names through this mod's own bank
//  (soundbank\mod.all.aliases.additions.csv), the route already proven by
//  zmqol_cherry_zap and zmqol_ww_activate.
//
//  📝 zmqol_zombieblood_loop keeps Origins' duck, zmb_tomb_zombieblood, re-shipped
//  as zmqol_zombieblood - it drops ambience to 25% and weapons/impacts to 50% for
//  the whole 30 seconds, and that muffling IS the zombie-blood soundscape. See
//  build_ff.bat's duck-staging block.
// ============================================================================
zmqol_zb_toggle_fx( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	if ( isspectating( localclientnum, 0 ) || isdemoplaying() )
		return;

	if ( newval == 1 )
	{
		if ( self islocalplayer() && self getlocalclientnumber() == localclientnum )
		{
			if ( !isdefined( self.zombie_blood_fx ) )
			{
				self.zombie_blood_fx = playviewmodelfx( localclientnum, level._effect[ "zombie_blood_1st" ], "tag_camera" );
				playsound( localclientnum, "zmqol_zombieblood_start", ( 0, 0, 0 ) );
				playloopat( "zmqol_zombieblood_loop", ( 0, 0, 0 ) );
			}
		}
	}
	else if ( isdefined( self.zombie_blood_fx ) )
	{
		stopfx( localclientnum, self.zombie_blood_fx );
		playsound( localclientnum, "zmqol_zombieblood_stop", ( 0, 0, 0 ) );
		stoploopat( "zmqol_zombieblood_loop", ( 0, 0, 0 ) );
		self.zombie_blood_fx = undefined;
	}
}

// ============================================================================
//  zmqol_enable_whoswho  (CLIENT)
//
//  The mandatory other half of zmqol_enable_whoswho() in
//  scripts\zm\quality_of_life.gsc - read the full reasoning there.
//
//  🛑 THIS LIST MUST MATCH quality_of_life.gsc::zmqol_whoswho_enabled() EXACTLY.
//  Both perks_register_clientfield() implementations - stock's and this mod's
//  override below - gate `perk_chugabud` on level.zombiemode_using_chugabud_perk,
//  and the client cannot read the server's copy. Set it on one side only and the
//  toplayer set is one bit wider on that side, which is
//  EXE_CLIENT_FIELD_MISMATCH for everyone before the map starts.
//
//  Only ONE field is at stake here, unlike Vulture's eight: the audio/filter
//  fields and the zm_whos_who visionset are all behind Die Rise-only level vars
//  (whos_who_client_setup, vsmgr_prio_visionset_zm_whos_who), so neither side
//  registers them off Die Rise.
// ============================================================================
zmqol_whoswho_enabled()
{
	map = getDvar( "mapname" );

	if ( map == "zm_highrise" )   // ships the perk itself
		return 0;

	if ( map == "zm_prison" )     // no specialty_quickrevive_zombies - stage 2
		return 0;

	// 🛑 EXACT TWIN of quality_of_life.gsc::zmqol_whoswho_enabled(). Buried is
	// dropped because its classic-mode `actor` clientfield set is 32/32 and the
	// corpse-glow field needs one more bit. Full counts in the server copy.
	if ( map == "zm_buried" )
		return 0;

	return 1;
}

zmqol_enable_whoswho()
{
	if ( !zmqol_whoswho_enabled() )
		return;

	level.zombiemode_using_chugabud_perk = 1;

	// ========================================================================
	//  THE CLIENT HALF OF WHO'S WHO'S VISUALS - the mandatory twin of
	//  quality_of_life.gsc::zmqol_enable_whoswho(). Read the long block there
	//  first; this comment only covers what is client-specific.
	//
	//  Names, versions, bit counts and types are copied verbatim from Die Rise's
	//  own registrations (zm_highrise.csc:83-86) and MUST stay byte-identical to
	//  the server's three or the engine drops every player at load.
	//
	//  🛑 TWO OF STOCK'S THREE CALLBACKS CANNOT BE NAMED FROM HERE.
	//  clientscripts\mp\zm_highrise_amb::whoswhoaudio and ::whoswhofilter are
	//  MAP-SPECIFIC. A `::` reference resolves at script LOAD time, not when the
	//  line runs, so naming them from this root client script would throw
	//  "Unresolved external" on every map that is not Die Rise - AI_CONTEXT rule
	//  2, and a runtime `if ( level.script == ... )` guard does not help. So the
	//  two callbacks below are ours, and they are line-for-line what Die Rise's
	//  do. The third, _zm_perks::chugabud_whos_who_shader, is CORE and safe to
	//  name directly.
	// ========================================================================
	registerclientfield( "actor", "clientfield_whos_who_clone_glow_shader", 5000, 1, "int", clientscripts\mp\zombies\_zm_perks::chugabud_whos_who_shader, 0 );
	registerclientfield( "toplayer", "clientfield_whos_who_audio", 5000, 1, "int", ::zmqol_whoswho_audio, 0 );
	registerclientfield( "toplayer", "clientfield_whos_who_filter", 5000, 1, "int", ::zmqol_whoswho_filter, 0 );

	// 🛑 THE zm_whos_who VISIONSET IS NOT REGISTERED HERE. It cannot be - see the
	// long block at the end of perks_register_clientfield() below, which is the
	// one place in this script that runs inside the visionset manager's window.

	// Maps generic_filter_afterlife into level.filter_matid so that
	// enable_filter_afterlife() has a material id to hand the filter pass. Die
	// Rise threads this from its client main() behind the same perk flag
	// (zm_highrise.csc:62-63); it waits for all clients itself before touching
	// any player, so threading it from here is the same shape.
	level thread clientscripts\mp\zombies\_zm_perks::chugabud_setup_afterlife_filters();
}

// ============================================================================
//  zmqol_whoswho_filter  -  THE OVERLAY THE USER REPORTED MISSING
//
//  Line-for-line clientscripts\mp\zm_highrise_amb::whoswhofilter (:152-164),
//  rewritten here only because that file is map-specific (see above). Filter
//  slot 5 is Die Rise's own choice and is kept.
// ============================================================================
zmqol_whoswho_filter( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	player = getlocalplayers()[localclientnum];

	if ( !isdefined( player ) )
		return;

	if ( newval == 1 )
		clientscripts\mp\zombies\_zm_perks::enable_filter_afterlife( player, 5 );
	else
		clientscripts\mp\zombies\_zm_perks::disable_filter_afterlife( player, 5 );
}

// ============================================================================
//  zmqol_whoswho_audio
//
//  Die Rise's ::whoswhoaudio calls activatewwaudio()/deactivatewwaudio()
//  (zm_highrise_amb.csc:166-183), which do three things: a one-shot sting
//  (evt_ww_activate), a looper on a spawned script_origin (evt_ww_looper), and
//  the zmb_duck_ww mixer snapshot.
//
//  🛑 THE TWO ALIASES ARE DIE RISE-ONLY - measured, not assumed. Dumped every
//  soundbank from zm_highrise, zm_transit, zm_tomb, zm_nuked and common_zm with
//  Unlinker --include-assets soundbank and grepped the alias CSVs: both names
//  appear ONLY in zmb_highrise.all. A missing alias is SILENT, never an error,
//  so this would have shipped as a dead call with nothing in any log.
//  They are therefore re-shipped under mod-private names in this mod's own
//  soundbank (soundbank\mod.all.aliases.additions.csv), the same route already
//  proven by zmqol_cherry_zap.
// ============================================================================
zmqol_whoswho_audio( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	if ( newval == 1 )
	{
		if ( !isdefined( level.zmqol_ww_sndent ) )
			level.zmqol_ww_sndent = spawn( localclientnum, ( 0, 0, 0 ), "script_origin" );

		playsound( localclientnum, "zmqol_ww_activate", ( 0, 0, 0 ) );
		level.zmqol_ww_sndent playloopsound( "zmqol_ww_looper", 3 );
	}
	else
	{
		if ( isdefined( level.zmqol_ww_sndent ) )
		{
			level.zmqol_ww_sndent stoploopsound( 1 );
			level.zmqol_ww_sndent delete();
			level.zmqol_ww_sndent = undefined;
		}
	}
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
//
//  Origins and Mob USED to be excluded here as well. They are not any more - see
//  zmqol_init_vulture_trimmed() below.
//
//  The full reasoning is in quality_of_life.gsc above zmqol_vulture_enabled().
zmqol_vulture_enabled()
{
	map = getDvar( "mapname" );

	if ( map == "zm_buried" )
		return 0;

	//  🛑 EXACT TWIN of zmqol_vulture_enabled() in quality_of_life.gsc - the
	//  full reasoning lives there. v1.59.0: Vulture is OFF on Origins because it
	//  cannot be complete there. It needs 4 scriptmover bits on a map that is
	//  32/32 and 2 actor bits on a map that is 31/32, the 32 ceiling is measured
	//  across all 48 map dumps AND was hit for real by this project, and every
	//  one of Origins' 32 scriptmover bits belongs to the map's own systems.
	//
	//  If this and the server twin ever disagree, the sets differ in width
	//  between server and client and every player is dropped with
	//  EXE_CLIENT_FIELD_MISMATCH before the map starts.
	if ( map == "zm_tomb" )
		return 0;

	return 1;
}

// ============================================================================
//  zm_qol: THE THREE FIELDS ORIGINS AND MOB CANNOT AFFORD  (CLIENT)
//
//  🛑 EXACT TWINS of the same three functions in
//  maps\mp\zombies\_zm_perk_vulture.gsc - the full reasoning lives there,
//  including the measured proof that every clientfield set is 32 bits wide and
//  that Origins classic already spends 32 of 32 on scriptmover. Drop a field on
//  one side only and that set is one width wider on that side, which is
//  EXE_CLIENT_FIELD_MISMATCH for everyone before the map starts. If a
//  clientfield error ever appears for Vulture, compare these SIX functions FIRST.
// ============================================================================
zmqol_vulture_has_actor_field()
{
	return getDvar( "mapname" ) != "zm_tomb";
}

//  🛑 EXACT TWIN of zmqol_vulture_has_disease_meter() in
//  maps\mp\zombies\_zm_perk_vulture.gsc - read the reasoning there.
//
//  v1.58.4 - zm_tomb added. The 5 bits this frees on Origins' toplayer pay for
//  perk_tombstone (2 bits), which failed to fit on 2026-08-07 and took the map
//  down at the menu. Origins keeps Vulture and loses the stink meter, the same
//  deal Mob has had since v1.55.0.
//
//  If these two functions ever disagree, the toplayer set is 5 bits wider on
//  one side and every player is dropped with EXE_CLIENT_FIELD_MISMATCH before
//  the map starts.
//  📝 zm_tomb briefly appeared here in v1.58.4 and is gone again in v1.59.0 -
//  Vulture is off on Origins entirely now, so this never runs there. Mob stays.
zmqol_vulture_has_disease_meter()
{
	return getDvar( "mapname" ) != "zm_prison";
}

zmqol_vulture_has_scriptmover_field()
{
	return getDvar( "mapname" ) != "zm_tomb";
}

// ============================================================================
//  zmqol_init_vulture_trimmed  -  Vulture Aid on Origins and Mob at last
//
//  Origins and Mob were the last two maps without the 11th perk, each blocked by
//  clientfields it had no room for: actor AND scriptmover on Origins, toplayer
//  on Mob. The perk itself, its drops, its wallbuy/machine/box glows and its
//  mystery-box vision all live on other fields and work everywhere. What Origins
//  gives up is the FX layer on the stink pile and the drops - see the server
//  file for exactly what that looks like in play.
//
//  🛑 WHY THIS IS A COPY OF init_vulture AND NOT AN EDIT OF THE REAL FILE.
//  The obvious move is to ship clientscripts\mp\zombies\_zm_perk_vulture.csc as
//  raw text (this project already does exactly that with the SERVER half, and
//  Plutonium loads raw .csc happily - the log says "loaded successfully from
//  raw"). It was tried and rejected, for a concrete reason:
//
//  the only available source for that file is a DECOMPILE, and the decompile is
//  LOSSY. Two proofs, both in BO2-Raw-files\clientscripts\mp\zombies:
//      _zm_perk_vulture.txt  _zombie_eye_glow_enable() decompiles to three
//                            assignments to n_fx_id in a row - an if/else chain
//                            whose branches were flattened, so only the last
//                            survives.
//      _zm_perks.txt         init_perk_custom_threads() decompiles to
//                            `i = 0; ...[i]...; i++;` with the loop gone.
//  It parses cleanly under gsc-tool - syntax was never the question - and it
//  would still have quietly degraded Vulture on TranZit, Die Rise and Nuketown,
//  where the perk already works, to buy it on two maps. Not a trade worth making.
//
//  So the compiled stock .csc stays exactly as it is, and only init_vulture is
//  re-implemented here. That function is the safe one to copy: it is 50 lines of
//  straight-line assignment with NO control flow at all, which is precisely the
//  shape a decompiler cannot get wrong. Every other function - including the
//  lossy ones - still runs as original bytecode.
//
//  Stock reaches init_vulture through
//      register_perk_init_thread( "specialty_nomotionsensor", ::init_vulture )
//  inside enable_vulture_perk_for_level(), which is a plain assignment to
//  level._custom_perks[perk].init_thread (_zm_perks.csc). So calling stock's
//  enable first and then re-pointing that one field swaps in this version and
//  changes nothing else. init_perk_custom_threads() later threads whatever is
//  stored there.
//
//  📝 The `::name` references below all resolve into the stock file rather than
//  this one, so they must stay fully qualified. An unqualified ::vulture_toggle
//  here would silently look for a function in zm_expanded.csc.
// ============================================================================
zmqol_init_vulture_trimmed()
{
	registerclientfield( "toplayer", "vulture_perk_toplayer", 12000, 1, "int", clientscripts\mp\zombies\_zm_perk_vulture::vulture_callback_toplayer, 0, 1 );

	if ( zmqol_vulture_has_actor_field() )
		registerclientfield( "actor", "vulture_perk_actor", 12000, 2, "int", clientscripts\mp\zombies\_zm_perk_vulture::vulture_callback_actor, 0, 0 );

	if ( zmqol_vulture_has_scriptmover_field() )
		registerclientfield( "scriptmover", "vulture_perk_scriptmover", 12000, 4, "int", clientscripts\mp\zombies\_zm_perk_vulture::vulture_callback_scriptmover, 0, 0 );

	registerclientfield( "zbarrier", "vulture_perk_zbarrier", 12000, 1, "int", clientscripts\mp\zombies\_zm_perk_vulture::vulture_vision_mystery_box, 0, 0 );
	registerclientfield( "toplayer", "sndVultureStink", 12000, 1, "int", clientscripts\mp\zombies\_zm_perk_vulture::sndvulturestink );
	registerclientfield( "world", "vulture_perk_disable_solo_quick_revive_glow", 12000, 1, "int", clientscripts\mp\zombies\_zm_perk_vulture::vulture_disable_solo_quick_revive_glow, 0, 0 );

	if ( zmqol_vulture_has_disease_meter() )
	{
		registerclientfield( "toplayer", "vulture_perk_disease_meter", 12000, 5, "float", clientscripts\mp\zombies\_zm_perk_vulture::vulture_callback_stink_active, 0, 1 );
		setupclientfieldcodecallbacks( "toplayer", 1, "vulture_perk_disease_meter" );
	}

	// The overlay is registered on BOTH sides unconditionally, exactly as stock
	// does - it is a visionset-manager overlay, not one of the eight fields, and
	// the server half registers it unconditionally too. Dropping it on one side
	// only is what widened overlay_lerp and produced the [CLIENT: 4 SERVER: 5]
	// boot crash Vulture caused twice before.
	clientscripts\mp\_visionset_mgr::vsmgr_register_overlay_info_style_filter( "vulture_stink_overlay", 12000, 31, 0, 0, "generic_filter_zombie_perk_vulture", 0 );

	level._effect["vulture_perk_zombie_stink"] = loadfx( "maps/zombie/fx_zm_vulture_perk_stink" );
	level._effect["vulture_perk_zombie_stink_trail"] = loadfx( "maps/zombie/fx_zm_vulture_perk_stink_trail" );
	level._effect["vulture_perk_bonus_drop"] = loadfx( "misc/fx_zombie_powerup_vulture" );
	level._effect["vulture_drop_picked_up"] = loadfx( "misc/fx_zombie_powerup_grab" );
	level._effect["vulture_perk_wallbuy_static"] = loadfx( "maps/zombie/fx_zm_vulture_wallbuy_rifle" );
	level._effect["vulture_perk_wallbuy_dynamic"] = loadfx( "maps/zombie/fx_zm_vulture_glow_question" );
	level._effect["vulture_perk_machine_glow_doubletap"] = loadfx( "maps/zombie/fx_zm_vulture_glow_dbltap" );
	level._effect["vulture_perk_machine_glow_juggernog"] = loadfx( "maps/zombie/fx_zm_vulture_glow_jugg" );
	level._effect["vulture_perk_machine_glow_revive"] = loadfx( "maps/zombie/fx_zm_vulture_glow_revive" );
	level._effect["vulture_perk_machine_glow_speed"] = loadfx( "maps/zombie/fx_zm_vulture_glow_speed" );
	level._effect["vulture_perk_machine_glow_marathon"] = loadfx( "maps/zombie/fx_zm_vulture_glow_marathon" );
	level._effect["vulture_perk_machine_glow_mule_kick"] = loadfx( "maps/zombie/fx_zm_vulture_glow_mule" );
	level._effect["vulture_perk_machine_glow_pack_a_punch"] = loadfx( "maps/zombie/fx_zm_vulture_glow_pap" );
	level._effect["vulture_perk_machine_glow_vulture"] = loadfx( "maps/zombie/fx_zm_vulture_glow_vulture" );
	level._effect["vulture_perk_mystery_box_glow"] = loadfx( "maps/zombie/fx_zm_vulture_glow_mystery_box" );
	level._effect["vulture_perk_powerup_drop"] = loadfx( "maps/zombie/fx_zm_vulture_glow_powerup" );
	level._effect["vulture_perk_zombie_eye_glow"] = loadfx( "misc/fx_zombie_eye_vulture" );

	level.perk_vulture = spawnstruct();
	level.perk_vulture.array_stink_zombies = [];
	level.perk_vulture.array_stink_drop_locations = [];
	level.perk_vulture.players_with_vulture_perk = [];
	level.perk_vulture.vulture_vision_fx_list = [];
	level.perk_vulture.clientfields = spawnstruct();
	level.perk_vulture.clientfields.scriptmovers = [];
	level.perk_vulture.clientfields.scriptmovers[0] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_stink_fx;
	level.perk_vulture.clientfields.scriptmovers[1] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_drop_fx;
	level.perk_vulture.clientfields.scriptmovers[2] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_drop_pickup;
	level.perk_vulture.clientfields.scriptmovers[3] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_powerup_drop;
	level.perk_vulture.clientfields.actors = [];
	level.perk_vulture.clientfields.actors[1] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_eye_glow;
	level.perk_vulture.clientfields.actors[0] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_stink_trail_fx;
	level.perk_vulture.clientfields.toplayer = [];
	level.perk_vulture.clientfields.toplayer[0] = clientscripts\mp\zombies\_zm_perk_vulture::vulture_toggle;
	level.perk_vulture.disable_solo_quick_revive_glow = 0;
	level.perk_vulture.custom_funcs_enable = [];
	level.perk_vulture.custom_funcs_disable = [];

	//  Our perk-machine markers replace stock's entirely - see the banner over
	//  zmqol_vulture_machines_build(). custom_funcs_enable / _disable are stock's
	//  own published extension point (vulture_add_custom_func_on_enable,
	//  _zm_perk_vulture.csc:98/106); assigning the slots directly is the same
	//  thing without needing level.perk_vulture to already exist.
	level.perk_vulture.custom_funcs_enable[0]  = ::zmqol_vulture_machines_enable;
	level.perk_vulture.custom_funcs_disable[0] = ::zmqol_vulture_machines_disable;

	level.zombie_eyes_clientfield_cb_additional = clientscripts\mp\zombies\_zm_perk_vulture::vulture_eye_glow_callback_from_system;
}

// ============================================================================
//  zmqol_vulture_machines_*  (CLIENT)  -  Vulture Aid's perk-machine markers
//
//  🛑 STOCK'S VERSION ONLY EVER WORKED ON BURIED. vulture_vision_init() does:
//
//      foreach ( struct in getstructarray( "zm_perk_machine", "targetname" ) )
//          level.perk_vulture.vulture_vision.perk_machines[ struct.script_noteworthy ] = struct;
//
//  keyed by PERK NAME, and it never reads script_string. On Buried that is
//  harmless - 8 structs, 8 distinct perks, one gametype. Measured anywhere else
//  it falls apart: zm_transit authors 21 of these structs, among them FIVE
//  Speed Cola spots and THREE Pack-a-Punch spots spread over Diner, Town, Farm
//  and Cornfield. Keyed by perk name those 21 collapse to 8, and the survivor is
//  merely whichever came last - very often a machine belonging to a gametype or
//  location that never spawned. That is the reported bug: no marker on the
//  machine standing in front of you.
//
//  🌟 script_string IS the field that says which gametype+location a spot
//  belongs to, and stock's own server-side perk_machine_spawn_init
//  (_zm_perks.gsc:2835-2861) selects machines with exactly
//  "<gametype>_perks_<location>" tokenised on spaces. This mirrors that test
//  verbatim, so the markers cannot disagree with the machines that really spawn.
//  A struct with no script_string spawns everywhere - stock's else branch - and
//  is kept here for the same reason.
//
//  🛑 WHY STOCK'S LOOP IS EMPTIED RATHER THAN CORRECTED. Its array is keyed by
//  perk name and that key is used for THREE things at once: the fx lookup, the
//  hasperk() gate, and the fx_list_special slot. Re-keying it uniquely (so that
//  five Speed Colas can coexist) breaks the other two - hasperk() would stop
//  matching and every machine would glow even once owned. So the whole loop is
//  ours: zmqol_vulture_after_connect() empties stock's list the moment its
//  vulture_vision_init() has finished, and nothing of stock's machine path runs.
//  Wallbuys, the mystery box, powerups, zombie eyes and the stink are all
//  untouched stock - they were never broken.
// ============================================================================
zmqol_vulture_perks_match_string()
{
	//  Same two dvars as zmqol_wallbuy_match_string() above, and for the same
	//  reason: _zm::init() has not assigned level.scr_zm_* yet this early, and
	//  clientscripts\mp\zombies\_zm.csc:32-33 reads these very dvars.
	str_gametype = getdvar( "ui_gametype" );
	str_location = getdvar( "ui_zm_mapstartlocation" );

	if ( ( str_location == "default" || str_location == "" ) && isDefined( level.default_start_location ) )
		str_location = level.default_start_location;

	if ( !isDefined( str_location ) || str_location == "" || str_gametype == "" )
		return "";

	return str_gametype + "_perks_" + str_location;
}

zmqol_vulture_machines_build()
{
	a_out = [];
	a_structs = getstructarray( "zm_perk_machine", "targetname" );

	if ( !isDefined( a_structs ) || a_structs.size < 1 )
		return a_out;

	str_match = zmqol_vulture_perks_match_string();

	for ( i = 0; i < a_structs.size; i++ )
	{
		s_spot = a_structs[i];

		if ( !isDefined( s_spot.origin ) || !isDefined( s_spot.script_noteworthy ) )
			continue;

		if ( isDefined( s_spot.script_string ) )
		{
			//  Empty match string means the location could not be resolved. Take
			//  nothing rather than guess - a marker in the wrong place is worse
			//  than no marker, and the log line below says so out loud.
			if ( str_match == "" )
				continue;

			b_match = 0;
			a_tokens = strtok( s_spot.script_string, " " );

			for ( t = 0; t < a_tokens.size; t++ )
			{
				if ( a_tokens[t] == str_match )
					b_match = 1;
			}

			if ( !b_match )
				continue;
		}

		a_out[a_out.size] = s_spot;
	}

	println( "[zm_qol] CLIENT vulture machines: " + a_out.size + " of " + a_structs.size + " structs match '" + str_match + "'" );

	return a_out;
}

//  Stock registers glow fx for only EIGHT perks (setup_perk_machine_fx), because
//  Buried has only those eight machines. Every other machine falls through to
//  stock's fallback, which is the SPEED COLA glow - actively wrong on the perks
//  this mod adds to maps. There is no Tombstone / Deadshot / Who's Who /
//  Electric Cherry / PhD glow effect anywhere in BO2 and new fx cannot be
//  authored (OpenAssetTools dumps no .efx, so there is no round trip), so those
//  five get the neutral "?" - level._effect["vulture_perk_wallbuy_dynamic"],
//  which is maps/zombie/fx_zm_vulture_glow_question, already loaded above.
//  It reads as "a machine is here" instead of naming the wrong perk.
zmqol_vulture_machine_fx( str_perk )
{
	switch ( str_perk )
	{
		case "specialty_armorvest":               return "vulture_perk_machine_glow_juggernog";
		case "specialty_rof":                     return "vulture_perk_machine_glow_doubletap";
		case "specialty_quickrevive":             return "vulture_perk_machine_glow_revive";
		case "specialty_fastreload":              return "vulture_perk_machine_glow_speed";
		case "specialty_weapupgrade":             return "vulture_perk_machine_glow_pack_a_punch";
		case "specialty_longersprint":            return "vulture_perk_machine_glow_marathon";
		case "specialty_additionalprimaryweapon": return "vulture_perk_machine_glow_mule_kick";
		case "specialty_nomotionsensor":          return "vulture_perk_machine_glow_vulture";
	}

	return "vulture_perk_wallbuy_dynamic";
}

//  Stock's gate, kept exactly: Pack-a-Punch and Vulture Aid always show, every
//  other machine only while the player does NOT hold that perk - the point of
//  the perk being to find what you still need. Solo Quick Revive obeys the same
//  disable_solo_quick_revive_glow flag stock honours.
zmqol_vulture_machine_should_show( localclientnumber, str_perk )
{
	if ( str_perk == "specialty_quickrevive" && isDefined( level.perk_vulture.disable_solo_quick_revive_glow ) && level.perk_vulture.disable_solo_quick_revive_glow )
		return 0;

	if ( str_perk == "specialty_weapupgrade" || str_perk == "specialty_nomotionsensor" )
		return 1;

	return !( self hasperk( localclientnumber, str_perk ) );
}

zmqol_vulture_machines_enable( localclientnumber )
{
	if ( !isDefined( level.zmqol_vulture_machines ) )
		level.zmqol_vulture_machines = zmqol_vulture_machines_build();

	//  Never stack a second set - vulture_toggle can fire again on a new-entity
	//  snapshot with the markers already up.
	self zmqol_vulture_machines_disable( localclientnumber );

	a_ids = [];
	a_perks = [];

	for ( i = 0; i < level.zmqol_vulture_machines.size; i++ )
	{
		s_spot = level.zmqol_vulture_machines[i];
		str_perk = s_spot.script_noteworthy;

		if ( !( self zmqol_vulture_machine_should_show( localclientnumber, str_perk ) ) )
			continue;

		str_fx = zmqol_vulture_machine_fx( str_perk );

		if ( !isDefined( level._effect[ str_fx ] ) )
			continue;

		v_angles = ( 0, 0, 0 );

		if ( isDefined( s_spot.angles ) )
			v_angles = s_spot.angles;

		a_ids[ a_ids.size ] = playfx( localclientnumber, level._effect[ str_fx ], s_spot.origin, anglestoforward( v_angles ), anglestoup( v_angles ) );
		a_perks[ a_perks.size ] = str_perk;
	}

	if ( !isDefined( level.zmqol_vulture_fx ) )
		level.zmqol_vulture_fx = [];

	level.zmqol_vulture_fx[ localclientnumber ] = spawnstruct();
	level.zmqol_vulture_fx[ localclientnumber ].ids = a_ids;
	level.zmqol_vulture_fx[ localclientnumber ].perks = a_perks;
}

zmqol_vulture_machines_disable( localclientnumber )
{
	if ( !isDefined( level.zmqol_vulture_fx ) || !isDefined( level.zmqol_vulture_fx[ localclientnumber ] ) )
		return;

	s_fx = level.zmqol_vulture_fx[ localclientnumber ];

	for ( i = 0; i < s_fx.ids.size; i++ )
	{
		if ( isDefined( s_fx.ids[i] ) )
			deletefx( localclientnumber, s_fx.ids[i], 1 );
	}

	level.zmqol_vulture_fx[ localclientnumber ] = undefined;
}

//  Buying a perk must take that machine's marker down. Stock does this in
//  vulture_global_perk_client_callback by deleting fx_list_special[perk] - which
//  only knows about stock's own one-per-perk fx, not ours. This runs stock's
//  version first (the mystery box and the rest still depend on it) and then
//  removes every marker we placed for that perk, of which there can be several.
zmqol_vulture_global_perk_callback( localclientnumber, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	self clientscripts\mp\zombies\_zm_perk_vulture::vulture_global_perk_client_callback( localclientnumber, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump );

	if ( !isDefined( level.perk_vulture ) || !( newval & 1 ) )
		return;

	if ( !isDefined( level.zmqol_vulture_fx ) || !isDefined( level.zmqol_vulture_fx[ localclientnumber ] ) )
		return;

	if ( !isDefined( level.perk_vulture.vulture_vision ) || !isDefined( level.perk_vulture.vulture_vision.perk_clientfields ) )
		return;

	if ( !isDefined( level.perk_vulture.vulture_vision.perk_clientfields[ fieldname ] ) )
		return;

	str_perk = level.perk_vulture.vulture_vision.perk_clientfields[ fieldname ];

	if ( self zmqol_vulture_machine_should_show( localclientnumber, str_perk ) )
		return;

	s_fx = level.zmqol_vulture_fx[ localclientnumber ];

	for ( i = 0; i < s_fx.perks.size; i++ )
	{
		if ( s_fx.perks[i] != str_perk || !isDefined( s_fx.ids[i] ) )
			continue;

		deletefx( localclientnumber, s_fx.ids[i], 1 );
		s_fx.ids[i] = undefined;
	}
}

//  Runs after stock's vulture_setup_on_player_connect, because that one is
//  registered first (inside enable_vulture_perk_for_level, which
//  zmqol_enable_vulture calls before registering this). By now stock's
//  vulture_vision_init has built its broken one-per-perk list; empty it so its
//  loop in vulture_vision_enable is a no-op and only ours draws.
zmqol_vulture_after_connect( localclientnumber )
{
	if ( isDefined( level.perk_vulture ) && isDefined( level.perk_vulture.vulture_vision ) )
		level.perk_vulture.vulture_vision.perk_machines = [];
}

zmqol_enable_vulture()
{
	if ( !zmqol_vulture_enabled() )
		return;

	if ( isDefined( level._custom_perks ) && isDefined( level._custom_perks[ "specialty_nomotionsensor" ] ) )
		return;

	clientscripts\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();

	// Re-point the perk's init thread at the trimmed copy. Stock stored
	// ::init_vulture there one line ago; this is a plain field assignment on
	// both sides, so nothing else about the perk's setup changes.
	level._custom_perks[ "specialty_nomotionsensor" ].init_thread = ::zmqol_init_vulture_trimmed;

	// Registered AFTER stock's own vulture_setup_on_player_connect (the line
	// above put it there), so it runs second and can empty the perk-machine list
	// stock's vulture_vision_init has just filled. See the banner over
	// zmqol_vulture_machines_build() for why that list is unusable off Buried.
	onplayerconnect_callback( ::zmqol_vulture_after_connect );

	// Stock set this to its own callback one line ago; ours calls that and then
	// clears the markers WE placed for the perk just acquired.
	level.zombies_global_perk_client_callback = ::zmqol_vulture_global_perk_callback;
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
	// ========================================================================
	//  🛑 THE zm_whos_who VISIONSET IS REGISTERED HERE, AND ONLY HERE.
	//
	//  v1.63.1 booted to:
	//      Clientfield 'visionset_slot' in set[toplayer] is not registered with
	//      the same bit count as the server : [CLIENT: 1  SERVER : 2]
	//  The server registered one visionset more than the client, so the slot
	//  field came out 2 bits server-side and 1 bit client-side and every player
	//  was dropped at load.
	//
	//  TWO earlier placements were wrong, and the second one is the lesson:
	//    1. inline in perks() (main()) - level.vsmgr does not exist yet, because
	//       clientscripts\mp\_visionset_mgr::init() is only reached at
	//       clientscripts\mp\zombies\_zm.csc:39, and this script's main() runs
	//       before that.
	//    2. a `wait 0.05` poller waiting for the manager to appear - ALSO WRONG.
	//       🌟 THE ENTIRE CLIENT INIT IS SYNCHRONOUS. _zm.csc::init() runs
	//       _visionset_mgr::init() and everything after it without ever yielding,
	//       and the engine fires finalize_clientfields() through
	//       on_finalize_initialization_callback in that same unbroken sequence.
	//       A thread that waits even one frame wakes with vsmgr_initializing
	//       already 0 - the window has closed. It registered nothing and, being a
	//       client script, printed nothing either. Do not "just poll for it".
	//
	//  This function is the correct home purely because of WHERE stock calls it:
	//      _zm.csc:39   clientscripts\mp\_visionset_mgr::init()      <- opens
	//      _zm.csc:~63  clientscripts\mp\zombies\_zm_perks::init()
	//                     -> perks_register_clientfield()            <- HERE
	//                   ... on_finalize_initialization                <- closes
	//  Same synchronous run, strictly after the manager exists and strictly
	//  before finalize. It is also a function this mod already owns by
	//  replaceFunc (line 47), so it costs no new hook.
	//
	//  The server's half is stock's own, in _zm_perks::turn_chugabud_on() (:1448),
	//  gated on level.vsmgr_prio_visionset_zm_whos_who - which
	//  quality_of_life.gsc::zmqol_enable_whoswho() sets on exactly the same map
	//  list zmqol_whoswho_enabled() returns here. Both sides must agree or the
	//  bit count diverges again.
	//
	//  Guarded on the manager being present so that if this ordering ever changes
	//  it degrades to "visionset not registered" instead of erroring out of the
	//  whole clientfield pass, which would break far more than Who's Who.
	// ========================================================================
	if ( zmqol_whoswho_enabled() && isdefined( level.vsmgr ) && isdefined( level.vsmgr[ "visionset" ] ) )
		clientscripts\mp\_visionset_mgr::vsmgr_register_visionset_info( "zm_whos_who", 5000, 1, "zm_whos_who", "zm_whos_who" );

	//  ZOMBIE BLOOD'S ENTIRE CLIENT REGISTRATION, v1.65.0, and it is here for the
	//  same reason the Who's Who visionset above is: this function is the one
	//  place in this script that runs inside _visionset_mgr's window, strictly
	//  after _visionset_mgr::init() (_zm.csc:39) and strictly before finalize.
	//  It ALSO has to be after :39 for a second, unrelated reason - that init
	//  wipes level.vsmgr_filter_custom_enable, which the red overlay depends on.
	//  Four separate timing constraints, all satisfied by this one slot; the full
	//  list is on zmqol_enable_zombie_blood() above.
	zmqol_zb_register();

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