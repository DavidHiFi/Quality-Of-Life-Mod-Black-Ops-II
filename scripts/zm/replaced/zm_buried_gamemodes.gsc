#include maps\mp\zm_buried_gamemodes;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zm_buried;
#include maps\mp\zm_buried_classic;
#include maps\mp\zm_buried_turned_street;
#include maps\mp\zm_buried_grief_street;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_unitrigger;

init()
{
	println( "[zm_qol] zm_buried_gamemodes::init - location=" + getdvar( "ui_zm_mapstartlocation" ) );
	add_map_gamemode("zclassic", maps\mp\zm_buried::zclassic_preinit, undefined, undefined);
	add_map_gamemode("zstandard", ::zstandard_preinit, undefined, undefined);
	add_map_gamemode("zgrief", maps\mp\zm_buried::zgrief_preinit, undefined, undefined);
	add_map_gamemode("zcleansed", maps\mp\zm_buried::zcleansed_preinit, undefined, undefined);

	add_map_location_gamemode("zclassic", "processing", maps\mp\zm_buried_classic::precache, maps\mp\zm_buried_classic::main);

	add_map_location_gamemode("zstandard", "street", maps\mp\zm_buried_grief_street::precache, maps\mp\zm_buried_grief_street::main);
	add_map_location_gamemode("zstandard", "maze", scripts\zm\locs\zm_buried_loc_maze::precache, scripts\zm\locs\zm_buried_loc_maze::main);

	add_map_location_gamemode("zgrief", "street", maps\mp\zm_buried_grief_street::precache, maps\mp\zm_buried_grief_street::main);
	add_map_location_gamemode("zgrief", "maze", scripts\zm\locs\zm_buried_loc_maze::precache, scripts\zm\locs\zm_buried_loc_maze::main);

	add_map_location_gamemode("zcleansed", "street", maps\mp\zm_buried_turned_street::precache, maps\mp\zm_buried_turned_street::main);

	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "maze", scripts\zm\locs\zm_buried_loc_maze::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "maze", scripts\zm\locs\zm_buried_loc_maze::struct_init);

	// zm_qol: Borough's wallbuys. Stock Buried registers NO zstandard gamemode at
	// all (verified against the stock zm_buried_gamemodes dump: only zclassic,
	// zcleansed and zgrief), so survival on Borough is entirely an addition here -
	// and the three wallbuys standing in the street are tagged "zgrief_street"
	// only, which never matches "zstandard_street". Without this, Borough
	// survival has no wallbuys. Grief is untouched: it already matches.
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "street", ::street_struct_init);
}

// See loc_common::enable_wallbuys for why re-tagging has to happen here, in a
// struct_init, rather than later. Origins copied verbatim from the zm_buried
// mapents dump.
street_struct_init()
{
	a_wallbuys = [];
	a_wallbuys[a_wallbuys.size] = ( -926.25, 510.5, 68 );   // rottweil72_zm
	a_wallbuys[a_wallbuys.size] = ( 609.5, 772.75, 54 );    // m14_zm
	a_wallbuys[a_wallbuys.size] = ( 1.1, 1201.9, 68 );      // mp5k_zm
	scripts\zm\locs\loc_common::enable_wallbuys( a_wallbuys );

	// ========================================================================
	//  🛑 BOROUGH HAS NO PERK MACHINES. Reported in game 2026-08-02: no Vulture
	//  Aid in the church.
	//
	//  Same root cause as the Origins perk-bottle soft-lock fixed in v1.9.2.
	//  maps\mp\zombies\_zm_perks::perk_machine_spawn_init only spawns a machine
	//  for a "zm_perk_machine" struct whose script_string contains
	//  "<ui_gametype>_perks_<start location>". Dumping the REAL Buried entities
	//  with OAT's Unlinker (the T6-Data-Archive copy omits them) shows all EIGHT
	//  of Buried's perk structs carry exactly one tag:
	//        "script_string" "zclassic_perks_processing"   x8
	//  Nothing for street, nothing for grief, nothing for zstandard. So Borough
	//  matches none of them and spawns zero machines.
	//
	//  zm_buried_grief_street::main's turnperkon() calls do NOT help - turnperkon
	//  is just `level notify( perk + "_on" )` (zm_buried_gamemodes.gsc:111). It
	//  powers on machines that already exist; it cannot create one.
	//
	//  Fix is the same one this project already uses for the Maze: re-register the
	//  structs for this gametype/location in a struct_init, which is the only
	//  window early enough. Origins and angles copied from the Unlinker dump.
	//
	//  Six of the eight are inside Borough's play area. Deliberately EXCLUDED:
	//        specialty_longersprint  (7017, 370, 108)   mansion/maze side
	//        specialty_weapupgrade   (6269, 889, -139)  mansion/maze side, and
	//                                Pack-a-Punch is buildable here anyway -
	//                                main() already sets buildables_built["pap"].
	//
	//  🛑 NOT verified in game yet.
	// ========================================================================
	scripts\zm\replaced\utility::register_perk_struct( "specialty_armorvest", "zombie_vending_jugg", ( -665.13, 1069.13, 8 ), ( 0, 0, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_quickrevive", "zombie_vending_revive", ( -926.31, -216.76, 288 ), ( 0, 0.599965, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_fastreload", "zombie_vending_sleight", ( 141.25, 598, 175.75 ), ( 0, 180, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_rof", "zombie_vending_doubletap2", ( 2423, 10, 88 ), ( 0, 180, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_additionalprimaryweapon", "zombie_vending_three_gun", ( -711, -1249.5, 140.5 ), ( 0, 180, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_nomotionsensor", "p6_zm_vending_vultureaid", ( 1450.33, 2302.68, 12 ), ( 0, 340.2, 0 ) );
}

zstandard_preinit()
{
	survival_init();
}

survival_init()
{
	level.force_team_characters = 1;
	level.should_use_cia = 0;

	if (randomint(100) >= 50)
	{
		level.should_use_cia = 1;
	}

	level.precachecustomcharacters = ::precache_team_characters;
	level.givecustomcharacters = ::give_team_characters;
	zm_buried_common_init();
	flag_wait("start_zombie_round_logic");
	trig_removal = getentarray("zombie_door", "targetname");

	foreach (trig in trig_removal)
	{
		if (isdefined(trig.script_parameters) && trig.script_parameters == "grief_remove")
		{
			trig delete();
		}
	}
}

// zm_qol note: Reimagined's buildbuildable() and builddynamicwallbuy() were dropped here.
// They are not part of the survival-location feature (nothing in scripts\zm\locs\ calls them),
// and buildbuildable() referenced scripts\zm\replaced\_zm_buildables, which this project does
// not port. Only ::init above is replaceFunc'd, so their absence changes nothing.
