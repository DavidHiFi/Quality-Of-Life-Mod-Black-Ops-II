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

	// CLIENT HALF OF THE 9 PORTED MULTIPLAYER WEAPONS - see the block below.
	zmqol_mp_weapons_init();

	// CLIENT HALF OF THE WALL-BUY GUNS GOING IN THE BOX - see the block below.
	zmqol_wallbuy_box_init();

	perks();

	//  B-RISERSOUND instrument (v1.99.8). Idle until the zmqol_testsound dvar
	//  changes; see the block comment at the bottom of this file. Threaded last
	//  so nothing above it can be delayed by it.
	level thread zmqol_testsound_watch();
}

// ============================================================================
//  zmqol_mp_weapons_init  (CLIENT)  -  EXACT TWIN of the same function in
//                                      scripts\zm\quality_of_life.gsc
//
//  🛑 THE LIST MUST MATCH THE SERVER'S EXACTLY, including the in_box flags. The
//  client's include_weapon (clientscripts\mp\zombies\_zm_weapons.csc:138) builds
//  level._included_weapons and level._display_box_weapons, which is what the
//  client uses to decide what to draw over the magic box. A weapon the server
//  can hand out but the client never included shows as a box result the client
//  cannot render.
//
//  📝 The client half takes NO cost, hint or vox pack - those are server-only
//  concepts (add_zombie_weapon does not exist client-side). Only the name and
//  the in_box flag cross the boundary, which is why this is a shorter list
//  rather than a different one.
//
//  Same dvar gate as the server, same default, for the same reason the Vulture
//  pair reads one dvar on both halves: the two must never disagree.
// ============================================================================
zmqol_mp_weapons_init()
{
	if ( !getdvarintdefault( "zmqol_mp_weapons", 1 ) )
		return;

	// the ten that go in the box
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "sig556_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "sa58_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mk48_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "qbb95_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mp7_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "vector_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "insas_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "peacekeeper_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "crossbow_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "as50_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "titus6_zm" );

	// their upgraded halves - included, but never a box result
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "sig556_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "sa58_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mk48_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "qbb95_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mp7_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "vector_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "insas_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "peacekeeper_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "crossbow_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "as50_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "titus6_upgraded_zm", 0 );

	// attachment and projectile variants - same six as the server half
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "vector_extclip_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "vector_extclip_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "gl_sig556_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "sf_sa58_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "crossbow_explosive_bolt_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "crossbow_explosive_bolt_upgraded_zm", 0 );

	// v1.93.0 - the Titus-6's alt-fire half and its two dart projectiles.
	// Must mirror the server list in quality_of_life.gsc exactly.
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mk_titus6_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "mk_titus6_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "titus6_explosive_dart_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "titus6_explosive_dart_upgraded_zm", 0 );
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
	return ( getdvarintdefault( "zmqol_semtex_diner_x", -5176 ), getdvarintdefault( "zmqol_semtex_diner_y", -7925 ), getdvarintdefault( "zmqol_semtex_diner_z", -14 ) );
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

// 🛑 EXACT TWIN of quality_of_life.gsc::zmqol_whoswho_clone_glow_enabled().
// The corpse-glow scriptmover field only exists on the maps this returns 1 for:
// the `_g` glow-capable materials cover the Victis crew only, and Origins has no
// free scriptmover bit for the field even if it could use one. Read the server
// copy for the counts.
zmqol_whoswho_clone_glow_enabled()
{
	if ( !zmqol_whoswho_enabled() )
		return 0;

	return getDvar( "mapname" ) == "zm_transit";
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

	//  v1.99.16 - THE SCRIPTMOVER TWIN, and the reason the clone never glowed off
	//  Die Rise. _zm_clone.gsc:27-38 spawns the corpse as an ACTOR only when the
	//  map ships a `fake_player_spawner` entity, and a `mapents` dump counts
	//  1 on zm_highrise, 0 on zm_transit, 0 on zm_tomb. Everywhere else the corpse
	//  is a script_model, so the actor field above is delivered to nothing.
	//  🛑 EXACT TWIN of the server registration in quality_of_life.gsc.
	//  📝 The callback is stock's OWN chugabud_whos_who_shader - core client code,
	//  safe to name from a root script, and nothing is reimplemented.
	//
	//  🛑 v1.99.18 - GATED TO zm_transit, AND UNGATED IT KILLED ORIGINS AT THE
	//  LOADING SCREEN: "Trying to assign 1 bits for netfield zone_captured but
	//  Client Field Set scriptmover is out of space." Origins sits at exactly
	//  32/32 on `scriptmover` in both classic and survival - the per-map runtime
	//  dumps have the field-by-field counts, and the server copy of this comment
	//  reproduces them. EXACT TWIN of
	//  quality_of_life.gsc::zmqol_whoswho_clone_glow_enabled(): if the two lists
	//  ever disagree the set is one bit wider on one side, which is
	//  EXE_CLIENT_FIELD_MISMATCH before the map starts.
	if ( zmqol_whoswho_clone_glow_enabled() )
		registerclientfield( "scriptmover", "zmqol_whoswho_clone_glow", 5000, 1, "int", clientscripts\mp\zombies\_zm_perks::chugabud_whos_who_shader, 0 );

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
//
//  ============================================================================
//  🌟 v1.99.20 - AND THE COLOUR GRADE IS APPLIED FROM HERE TOO, DIRECTLY.
//
//  v1.99.19 handed the grade back to stock's visionset manager and the screen
//  still did not go red. The server-side probe it shipped says the server half
//  is perfect:
//        [zm_qol] whoswho visionset: registered, slot_index 3, total visionsets 4
//  and the session's dvar dump says night_mode was "0" throughout, so nothing
//  was overriding the renderer either. The server picked slot 3 and the screen
//  did not change - which puts the fault in the ROUTING between the two sides.
//
//  🛑 AND THE ROUTING CAN BREAK IN COMPLETE SILENCE. I claimed last round that a
//  clean boot proves both sides registered the same visionsets, because
//  finalize_type_clientfields() derives visionset_slot's width from the count.
//  THAT INFERENCE IS WRONG and this is the counter-example:
//        getminbitcountfornum( 3 - 1 ) = 2 bits      <- client, 3 visionsets
//        getminbitcountfornum( 4 - 1 ) = 2 bits      <- server, 4 visionsets
//  Identical width, no mismatch, no error - and the server then sends slot 3 to
//  a client whose sorted list stops at index 2. get_info() returns undefined and
//  nothing is applied, forever, without a single line in any log.
//  The client can drop a registration silently too: _visionset_mgr.csc's
//  validate_info() returns false whenever version > getserverhighestclientfieldversion(),
//  and vsmgr_register_visionset_info() discards that false without a word.
//
//  THE FIX IS TO STOP DEPENDING ON THE ROUTING. visionsetnaked() applies a
//  .vision file to a local client directly - it is what the manager itself ends
//  up calling (_visionset_mgr.csc:375, and visionsetnakedlerp in
//  visionset_update_cb) - and the save/restore shape here is stock's own, from
//  clientscripts\mp\_proximity_grenade.csc:170-189:
//        saved = getvisionsetnaked( localclientnum );
//        visionsetnaked( localclientnum, "taser_mine_shock", transition );
//        ... visionsetnaked( localclientnum, saved, transition );
//  Same asset, same engine call, no slot table in between.
//
//  📝 THIS IS THE RIGHT CALLBACK TO DO IT FROM, not a convenience. Stock writes
//  clientfield_whos_who_filter and activates the visionset from the SAME four
//  consecutive lines of _zm_chugabud::activate_chugabud_effects_and_audio()
//  (:753-760), so the filter going on IS the visionset going on. They cannot
//  drift apart.
//
//  📝 The transition time is Die Rise's own filter timing (5), kept for both.
//  ============================================================================
zmqol_whoswho_filter( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	player = getlocalplayers()[localclientnum];

	if ( !isdefined( player ) )
		return;

	if ( newval == 1 )
	{
		//  Save what the map is currently showing so the restore is exact rather
		//  than a guess at what this map's default vision is called.
		if ( !isdefined( level.zmqol_whoswho_saved_vision ) )
			level.zmqol_whoswho_saved_vision = [];

		level.zmqol_whoswho_saved_vision[ localclientnum ] = getvisionsetnaked( localclientnum );

		//  🛑 THE GRADE GOES FIRST, DELIBERATELY. enable_filter_afterlife()
		//  depends on level.filter_matid, which is set up by a separate thread;
		//  if it ever faults, a call placed after it would never run. The two are
		//  independent effects, so the order between them is free - and this
		//  ordering means the thing the user is waiting on cannot be blocked by
		//  the thing that already works.
		visionsetnaked( localclientnum, "zm_whos_who", 0.5 );

		println( "[zm_qol] CLIENT whoswho: vision -> zm_whos_who (was '" +
		         level.zmqol_whoswho_saved_vision[ localclientnum ] + "')" );

		clientscripts\mp\zombies\_zm_perks::enable_filter_afterlife( player, 5 );
	}
	else
	{
		clientscripts\mp\zombies\_zm_perks::disable_filter_afterlife( player, 5 );

		//  Fall back to the map name, which IS the name of a map's own visionset -
		//  the same fallback _proximity_grenade.csc:199 uses.
		str_restore = undefined;

		if ( isdefined( level.zmqol_whoswho_saved_vision ) )
			str_restore = level.zmqol_whoswho_saved_vision[ localclientnum ];

		if ( !isdefined( str_restore ) || str_restore == "" || str_restore == "undefined" )
			str_restore = getdvar( "mapname" );

		visionsetnaked( localclientnum, str_restore, 0.5 );

		println( "[zm_qol] CLIENT whoswho: filter OFF, vision -> '" + str_restore + "'" );
	}
}

// ============================================================================
//  zmqol_whoswho_visionset_probe  (CLIENT)  -  v1.99.20
//
//  The server prints its own half of this at map load. This is the other half,
//  and together they settle the routing question for good: if the two counts or
//  the two slot indices disagree, the manager was never going to deliver the
//  grade and the direct visionsetnaked() above is not a workaround but the only
//  route there was.
//
//  Threaded with a wait so it reads the table AFTER finalize_type_clientfields()
//  has assigned slot_index - registration itself happens much earlier, inside
//  perks_register_clientfield().
// ============================================================================
zmqol_whoswho_visionset_probe()
{
	wait 1;

	if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr[ "visionset" ] ) )
	{
		println( "[zm_qol] CLIENT whoswho visionset: no manager" );
		return;
	}

	if ( !isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ] ) )
	{
		println( "[zm_qol] CLIENT whoswho visionset: NOT REGISTERED - total visionsets " +
		         level.vsmgr[ "visionset" ].info.size );
		return;
	}

	str_slot = "UNASSIGNED";

	if ( isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index ) )
		str_slot = "" + level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index;

	println( "[zm_qol] CLIENT whoswho visionset: registered, slot_index " + str_slot +
	         ", total visionsets " + level.vsmgr[ "visionset" ].info.size );
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

	//  🔬 MEASUREMENT DVAR, v1.78.0 - EXACT TWIN of the line in
	//  quality_of_life.gsc::zmqol_vulture_enabled(), same dvar, same default of
	//  1, so shipped behaviour is unchanged. The full reasoning for why this
	//  probe exists lives there. Both halves run in one process, so they read
	//  one value - but they must be changed together regardless, because a
	//  disagreement here is EXE_CLIENT_FIELD_MISMATCH on every map.
	if ( !getdvarintdefault( "zmqol_vulture", 1 ) )
		return 0;

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

	//  🛑 EXACT TWIN of the zm_transit branch in
	//  quality_of_life.gsc::zmqol_vulture_enabled() - the full reasoning lives
	//  there. v1.83.0: Vulture is OFF on TranZit because its toplayer set is out
	//  of space, which is the error that stopped TranZit classic booting at all:
	//
	//      Trying to assign 1 bits for netfield vulture_perk_toplayer
	//      but Client Field Set toplayer is out of space.
	//
	//  Bits are assigned at finalize in registration order, so the field named
	//  in the error is exactly where the total crosses the ceiling. Dropping
	//  Vulture here returns 10 toplayer bits (1 + 1 + 5 + 2, plus overlay_lerp
	//  narrowing 5 -> 4 once the 31-step vulture_stink_overlay is gone).
	//
	//  If this and the server twin ever disagree, the sets differ in width
	//  between server and client and every player is dropped with
	//  EXE_CLIENT_FIELD_MISMATCH before the map starts.
	//  v1.84.0 - CLASSIC ONLY. EXACT TWIN of the server test; the survival and
	//  grief locations are also `zm_transit` and they have room for the perk.
	//  Stock toplayer bits, measured per configuration: zclassic+transit 38,
	//  zgrief 28, zstandard 27. Classic has 11 fewer spare bits than any
	//  survival location and Vulture needs 10.
	//
	//  🛑 ui_zm_mapstartlocation, not g_gametype: that one is a server dvar and
	//  this must give the identical answer on both halves. This file already
	//  reads ui_zm_mapstartlocation in four places - see the comment above
	//  zmqol_wallbuy_match_string() for why it is the dvar that is safe this
	//  early. If the two halves ever disagree here, every player is dropped
	//  with EXE_CLIENT_FIELD_MISMATCH before the map starts.
	//  v1.89.0 - AND THE GAMETYPE TOO. EXACT TWIN of the server test; the full
	//  reasoning lives in quality_of_life.gsc::zmqol_vulture_enabled().
	//
	//  🛑 v1.84.0's comment claimed zstandard/zgrief at location "transit" were
	//  not reachable from the menus. FALSE - **Bus Depot is `zstandard` at
	//  location `transit`**, and the location-only test took a perk it had room
	//  for (27 stock toplayer bits vs classic's 38; Vulture needs 10).
	//
	//  ui_gametype is as safe as the dvar beside it: zmqol_wallbuy_match_string()
	//  in THIS file (line ~439) already reads both together at struct_class_init
	//  time, strictly earlier than this, and its wallbuys work.
	//
	//  If this and the server twin ever disagree, the sets differ in width
	//  between server and client and every player is dropped with
	//  EXE_CLIENT_FIELD_MISMATCH before the map starts.
	//  🛑 INVERTED ON PURPOSE - EXACT TWIN of the server test. Asking "is this
	//  NOT survival/grief" instead of "is this classic" means an unreadable
	//  ui_gametype leaves Vulture OFF on classic (boots, Bus Depot loses a perk)
	//  rather than ON (will not boot at all). Err toward the map that boots.
	str_gametype = getdvar( "ui_gametype" );

	if ( map == "zm_transit" &&
	     getdvar( "ui_zm_mapstartlocation" ) == "transit" &&
	     str_gametype != "zstandard" && str_gametype != "zgrief" )
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


// ============================================================================
//  zmqol_deadshot_perk_callback  (CLIENT)                          (v1.99.61)
//
//  🛑 THE BUG: DEADSHOT'S HEAD LOCK-ON WAS DEAD ON CONTROLLER, ON EVERY MAP.
//  Reported 2026-08-18 by the user's friend, who plays on a gamepad: the aim
//  assist pulled to the upper torso instead of the head. The user plays mouse
//  and keyboard, where Deadshot's aim assist does nothing at all, which is why
//  it survived this long unnoticed.
//
//  🌟 THE MECHANISM, READ OUT OF STOCK, NOT GUESSED. Deadshot's head snap is
//  ONE engine call made client-side: `self usealternateaimparams()`. Stock
//  makes it in exactly one place - `_zm.csc:611 player_deadshot_perk_handler`,
//  the handler on the `deadshot_perk` clientfield - and undoes it with
//  `clearalternateaimparams()`.
//
//  🛑 AND THIS MOD HAD DELETED THAT CLIENTFIELD EVERYWHERE. init_client_flags()
//  in quality_of_life.gsc and init_client_flag_callback_funcs() here both set
//  `level.disable_deadshot_clientfield = 1` unconditionally. STOCK SETS IT ON
//  BURIED ALONE (zm_buried.gsc:222 / zm_buried.csc:40), where there is no
//  Deadshot machine, to free a bit. Set globally it is symmetric, so nothing
//  ever errored - the field simply never registered, the handler never ran, and
//  the perk shipped with its headline effect missing on every map.
//
//  🌟 WHY THE FIX DOES NOT PUT THE FIELD BACK. Restoring `deadshot_perk` costs
//  one `toplayer` bit on every map, and Mob of the Dead's toplayer set is the
//  tightest this mod touches (checkpoint 17 and v1.65.2 both had to free bits
//  there, and its true headroom has never been measured). Spending a bit on a
//  second field is unnecessary, because a field carrying exactly the same
//  information is ALREADY registered and already paid for:
//
//      perk_dead_shot   <- _zm_perks.gsc:2224, set_perk_clientfield()
//
//  set_perk_clientfield( "specialty_deadshot", 1 ) runs from give_perk() and
//  ( ..., 0 ) from perk_think()'s take path - the SAME two functions that used
//  to drive deadshot_perk, in the same frames. So the trigger points are
//  identical and this costs nothing.
//
//  📝 It also fixes BURIED, which stock never could: the mod adds Deadshot
//  there and stock's own wiring is switched off on that map by design.
//
//  The body below is `player_deadshot_perk_handler` verbatim, guard included -
//  the guard matters, because a toplayer field also fires on spectated players.
//  The chain to level.zombies_global_perk_client_callback keeps Vulture Aid's
//  machine-hiding fx working: that is what this row's callback used to be, and
//  it is read at CALL time rather than captured at registration, so it does not
//  matter that Vulture assigns it later.
// ============================================================================
zmqol_deadshot_perk_callback( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	if ( isdefined( level.zombies_global_perk_client_callback ) )
		self [[ level.zombies_global_perk_client_callback ]]( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump );

	if ( !self islocalplayer() || isspectating( localclientnum, 0 ) || isdefined( level.localplayers[localclientnum] ) && self getentitynumber() != level.localplayers[localclientnum] getentitynumber() )
		return;

	if ( newval )
		self usealternateaimparams();
	else
		self clearalternateaimparams();
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
		//  🛑 v1.99.61 - THIS ONE ROW TAKES A MOD CALLBACK, AND IT IS THE
		//  DEADSHOT AIM-ASSIST FIX. See zmqol_deadshot_perk_callback() below.
		registerclientfield("toplayer", "perk_dead_shot", 1, bits, "int", ::zmqol_deadshot_perk_callback, 0, 1);
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
	{
		clientscripts\mp\_visionset_mgr::vsmgr_register_visionset_info( "zm_whos_who", 5000, 1, "zm_whos_who", "zm_whos_who" );

		//  v1.99.20 - report what the table actually ended up holding. The server
		//  prints its own half; the pair of them is what proves or disproves that
		//  the slot the server sends is the slot this client resolves.
		level thread zmqol_whoswho_visionset_probe();
	}

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
	// ====================================================================
	//  🛑 v1.99.0 - THE RISER SOUND. THIS IS A PROBE AS WELL AS A FIX, and it
	//  is deliberately BOTH because three rounds of theorising did not settle
	//  it and the user has now reported it silent twice.
	//
	//  What is meant to happen: the server sets this clientfield in
	//  _zm_spawner::zombie_rise_burst_fx, and stock's
	//  _zm.csc::handle_zombie_risers plays "zmb_zombie_spawn" and the dirt
	//  burst/billow fx. ONE trigger drives both halves.
	//
	//  What has been RULED OUT, each measured (see QUEUE.md B-RISERSND):
	//    - the audio is unreachable   ❌ zmb_common.all.sabl, which owns the
	//      dirt_00/dirt_01 payloads, loads at frontend start (console_zm.log:363)
	//      and the alias is defined in zmb_survival_transit.all.
	//    - the mod permutes the actor clientfield order ❌ stock registers
	//      zombie_riser_fx first server-side (_zm.gsc:1161) and THIRD
	//      client-side (_zm.csc:419); this file mirrors stock exactly.
	//    - the mod touches the riser path anywhere else ❌ grepped scripts/,
	//      maps/ and clientscripts/.
	//
	//  So the remaining question is simply WHETHER THE HANDLER RUNS AT ALL, and
	//  the only way left to answer it is from inside the handler. This wrapper
	//  prints one line the first time it fires and then calls stock's handler
	//  unchanged - so if the log shows the line, the trigger works and the
	//  fault is in audio; if it never appears, the clientfield is not arriving
	//  and the spawner path is where to look next.
	//
	//  It also plays the alias itself, which is the fix IF the cause is that
	//  stock's own playsound is being lost. Harmless if not: a second playsound
	//  of the same one-shot alias at the same origin is at worst inaudible
	//  doubling, and a missing alias is silent rather than an error.
	//
	//  🛑 ONE PRINT PER MATCH, NOT PER ZOMBIE. level.zmqol_riser_logged gates
	//  it; at round 10 this fires dozens of times a minute and an unbounded
	//  println is its own problem.
	// ====================================================================
	registerclientfield("actor", "zombie_riser_fx", 1, 1, "int", ::zmqol_handle_zombie_risers, 1);
	if (is_true(level.risers_use_low_gravity_fx))
	{
		registerclientfield("actor", "zombie_riser_fx_lowg", 1, 1, "int", ::handle_zombie_risers_lowg, 1);
	}
}
// ============================================================================
//  zmqol_handle_zombie_risers  -  probe + belt-and-braces sound   (v1.99.0)
//
//  Wraps stock's handler rather than replacing it, so the dirt burst, the
//  billow, the snow/low-gravity variants and the demo-jump guards all stay
//  exactly as Treyarch wrote them. See the long note at the registration.
//
//  The alias name is stock's own, read out of
//  _zm.csc::handle_zombie_risers - "zmb_zombie_spawn", or
//  "zmb_zombie_spawn_snow" when level.riser_type is "snow". It is NOT invented;
//  both are defined in zmb_survival_transit.all and their payloads live in
//  zmb_common.all, which is loaded.
// ============================================================================
zmqol_handle_zombie_risers( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
	if ( !oldval && newval )
	{
		//  ----------------------------------------------------------------
		//  v1.99.5 ORIGIN PROBE - B-RISERSOUND.
		//
		//  Everything else is eliminated by measurement (see QUEUE.md): the
		//  alias exists, its bank is loaded, its payload is in zmb_common.all,
		//  our registration is line-for-line stock, the clientfield fires and
		//  this handler runs. The sound is played twice and is still inaudible.
		//
		//  The one mechanism left is WHERE it is played. playsound() takes a
		//  world position, and zmb_zombie_spawn's curve is DistMin 250 /
		//  DistMaxDry 1000 - so anything emitted past ~1000 units from the
		//  listener is silent by design. If the actor's CLIENT-side origin is
		//  not populated yet when its clientfield arrives (the bnewent /
		//  initial-snapshot case), the sound is thrown somewhere far away and
		//  cannot be heard, with no error anywhere.
		//
		//  This prints, and only prints. It changes no behaviour, so a boot
		//  with it in cannot regress anything - it just makes the next step
		//  decidable instead of arguable:
		//    dist well under 1000  -> the origin theory is DEAD, look elsewhere
		//    dist huge, or origin (0,0,0)/undefined -> theory CONFIRMED, and
		//    the fix is to emit once the origin is valid, not to move the
		//    sound to the player.
		//  ----------------------------------------------------------------
		if ( !isdefined( level.zmqol_riser_logged ) )
		{
			level.zmqol_riser_logged = 1;

			str_org = "UNDEFINED";
			str_ply = "UNDEFINED";
			str_dist = "n/a";

			player = getlocalplayer( localclientnum );

			if ( isdefined( self.origin ) )
				str_org = "" + self.origin;

			if ( isdefined( player ) && isdefined( player.origin ) )
			{
				str_ply = "" + player.origin;

				if ( isdefined( self.origin ) )
					str_dist = "" + int( distance( self.origin, player.origin ) );
			}

			println( "[zm_qol] RISER PROBE  riser=" + str_org + "  player=" + str_ply +
			         "  dist=" + str_dist + "  (alias goes silent past ~1000)" +
			         "  bnewent=" + bnewent + "  binitialsnap=" + binitialsnap );
		}

		//  v1.99.11 - ROOT CAUSE FOUND, and it is not the wiring.
		//  Stock "zmb_zombie_spawn" names payloads dirt_00/dirt_01 ".LN55.pc.snd" with
		//  Storage=loaded, and that audio data ships in NO bank - OAT reports
		//  'Could not find data for sound' for both, in every bank that defines the
		//  alias (zmb_survival_transit.all and zmb_tomb.all). The alias resolves and
		//  plays silence, which is exactly what .testsound measured in v1.99.8.
		//  The SAME dirt audio does ship, STREAMED, as dirt_00/01 ".SN50.pc.snd.flac"
		//  under Origins' own alias evt_zombie_dig_dirt. zmqol_zombie_riser is
		//  zmb_zombie_spawn's own row verbatim - bus_hdrfx, VolMin/Max 88, DistMin 250,
		//  DistMaxDry 1000 - repointed at that working payload, shipped in mod.all.
		str_snd = "zmqol_zombie_riser";

		if ( isdefined( level.riser_type ) && level.riser_type == "snow" )
			str_snd = "zmb_zombie_spawn_snow";

		playsound( 0, str_snd, self.origin );
	}

	self clientscripts\mp\zombies\_zm::handle_zombie_risers( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump );
}

// ============================================================================
//  zmqol_testsound_watch  (CLIENT)  -  B-RISERSOUND instrument            v1.99.8
//
//  WHY THIS EXISTS. The riser sound is silent and EVERY link in the chain is
//  now verified by measurement, so there is nothing left to read off disk:
//
//    server sets zombie_riser_fx          -> the clientfield arrives (probe line)
//    this file's handler runs             -> confirmed, v1.99.0 probe
//    the actor origin is valid            -> 513 units from the player, v1.99.5 probe
//    "zmb_zombie_spawn" is defined        -> 2 rows in zmb_survival_transit.all, LOADED
//    the alias row is ordinary            -> vol 86, probability 1, 3d, DistMin 250 /
//                                            DistMaxDry 1000, bus_hdrfx like 3,130 others
//    its payload is present               -> hashes AAF96C0F / 77818910 found in
//                                            zmb_common.all.SABL (the loaded bank the
//                                            alias's Storage=loaded demands), and NOT in
//                                            the .sabs. That bank loads at console_zm.log:349
//    mod.all does not shadow it           -> 0 rows in the BUILT 2,280-row alias table
//    the sound is played TWICE            -> ours, then stock's
//
//  ...and it is still inaudible. The one question no file can answer is whether
//  the alias produces audio AT ALL when played point blank. This answers it.
//
//  HOW TO USE - either route, they end at the same dvar:
//      console :  zmqol_testsound zmb_zombie_spawn
//      chat    :  .testsound zmb_zombie_spawn        (or bare .testsound)
//
//  It plays THREE things, spaced, and prints each one:
//      1/3  2D          playsound( 0, alias )            - no distance model at all
//      2/3  3D          playsound( 0, alias, player )    - at your own feet, distance 0
//      3/3  CONTROL     zmb_powerup_grabbed at the player
//
//  🌟 THE CONTROL IS NOT ARBITRARY. zmb_powerup_grabbed sits in the SAME alias
//  bank, on the SAME bus (bus_hdrfx), with the SAME Storage (loaded) and the SAME
//  DistMin (250), and its payload is in the SAME .sabl (zmb_common.all). It is
//  the closest matched pair in the game, and the user hears it every match.
//
//  READING THE RESULT:
//      all three audible      -> the alias is fine; the fault is the riser wiring
//                                or its timing, not the audio asset
//      control only           -> this alias produces no audio, full stop
//      2D yes, 3D no          -> positional attenuation, not the asset
//      nothing at all         -> the probe never reached audio; say so, do not
//                                read it as "the alias is dead"
//
//  🛑 COSTS NOTHING WHEN UNUSED. One getdvar every 0.25s on the client, which is
//  a local hash lookup - no reliable commands, no clientfields, no server work.
//  It plays only when the dvar CHANGES, so it cannot loop or spam.
// ============================================================================
zmqol_testsound_watch()
{
	str_last = "";

	for ( ;; )
	{
		wait 0.25;

		str_now = getdvar( "zmqol_testsound" );

		if ( !isdefined( str_now ) || str_now == "" || str_now == str_last )
			continue;

		str_last = str_now;

		//  The server route appends a counter ("zmb_zombie_spawn 3") so that asking
		//  for the SAME alias twice still changes the dvar and still fires. Take the
		//  first token and ignore the rest.
		tokens = strtok( str_now, " " );

		if ( !isdefined( tokens ) || tokens.size == 0 )
			continue;

		str_alias = tokens[0];

		player = getlocalplayer( 0 );

		if ( !isdefined( player ) || !isdefined( player.origin ) )
		{
			println( "[zm_qol] TESTSOUND: no local player yet, ignored" );
			continue;
		}

		println( "[zm_qol] TESTSOUND 1/3  2D       '" + str_alias + "'" );
		playsound( 0, str_alias );

		wait 1.2;

		player = getlocalplayer( 0 );

		if ( !isdefined( player ) || !isdefined( player.origin ) )
			continue;

		println( "[zm_qol] TESTSOUND 2/3  3D@you   '" + str_alias + "'" );
		playsound( 0, str_alias, player.origin );

		wait 1.2;

		player = getlocalplayer( 0 );

		if ( !isdefined( player ) || !isdefined( player.origin ) )
			continue;

		//  zmb_powerup_grabbed - same bank, same bus, same Storage, same DistMin,
		//  same payload .sabl as zmb_zombie_spawn. If THIS is silent too, the probe
		//  itself never reached audio and nothing above it can be concluded.
		println( "[zm_qol] TESTSOUND 3/3  CONTROL  'zmb_powerup_grabbed'" );
		playsound( 0, "zmb_powerup_grabbed", player.origin );
	}
}

// ============================================================================
//  zmqol_wallbuy_box_init  (CLIENT)  -  EXACT TWIN of the same function in
//  quality_of_life.gsc. v1.99.56 (M16) / v1.99.58 (Olympia + M1911).
//
//  The client half of include_weapon (clientscripts\mp\zombies\_zm_weapons.csc)
//  builds level._included_weapons / _display_box_weapons, which is what draws
//  the gun floating above the mystery box. A server-side registration with no
//  client twin gives a box that hands out a weapon while showing nothing, so the
//  two lists must stay identical - same names, same in_box flags, same dvar.
//
//  rottweil72_zm is the OLYMPIA. The weapon is named for the Rottweil 72 and its
//  art for the Olympia; see the long note on the server half.
// ============================================================================
zmqol_wallbuy_box_init()
{
	if ( !getdvarintdefault( "zmqol_wallbuy_box", 1 ) )
		return;

	// the three that go in the box
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "m16_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "rottweil72_zm" );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "m1911_zm" );

	// their Pack-a-Punch halves - included, but never a box result
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "m16_gl_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "rottweil72_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "m1911_upgraded_zm", 0 );

	// alt-weapon halves - the M16's grenade launcher and Mustang & Sally's
	// left-hand gun
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "gl_m16_upgraded_zm", 0 );
	clientscripts\mp\zombies\_zm_weapons::include_weapon( "m1911lh_upgraded_zm", 0 );
}
