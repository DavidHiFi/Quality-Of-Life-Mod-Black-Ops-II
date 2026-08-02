#include maps\mp\zm_transit_gamemodes;
#include maps\mp\zm_transit_grief_town;
#include maps\mp\zm_transit_grief_farm;
#include maps\mp\zm_transit_grief_station;
#include maps\mp\zm_transit_standard_town;
#include maps\mp\zm_transit_standard_farm;
#include maps\mp\zm_transit_standard_station;
#include maps\mp\zm_transit_classic;
#include maps\mp\zm_transit;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zm_transit_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;

// ============================================================================
//  Everything here except the four DINER lines is a verbatim copy of stock
//  maps\mp\zm_transit_gamemodes::init. Diner is the only added location this
//  mod still ships - Power Station, Tunnel and Cornfield were removed in
//  v1.15.0 along with the Die Rise, Buried, Alcatraz and Origins locations.
//
//  Diner is registered for BOTH zstandard and zgrief because stock registers
//  it for NEITHER: the stock dump's zm_transit_gamemodes has only transit,
//  farm and town on each mode. Diner is entirely an addition here.
//
//  Diner is also the one location that never needed the transit_zone_init
//  override - its zones (zone_gas / zone_roadside_east / zone_roadside_west)
//  all have stock adjacency edges, so they come up on their own. That override
//  existed only for Tunnel and Cornfield and is gone with them.
// ============================================================================
init()
{
	add_map_gamemode("zclassic", maps\mp\zm_transit::zclassic_preinit, undefined, undefined);
	add_map_gamemode("zgrief", maps\mp\zm_transit::zgrief_preinit, undefined, undefined);
	add_map_gamemode("zstandard", maps\mp\zm_transit::zstandard_preinit, undefined, undefined);

	add_map_location_gamemode("zclassic", "transit", maps\mp\zm_transit_classic::precache, maps\mp\zm_transit_classic::main);

	add_map_location_gamemode("zstandard", "transit", maps\mp\zm_transit_standard_station::precache, maps\mp\zm_transit_standard_station::main);
	add_map_location_gamemode("zstandard", "farm", maps\mp\zm_transit_standard_farm::precache, maps\mp\zm_transit_standard_farm::main);
	add_map_location_gamemode("zstandard", "town", maps\mp\zm_transit_standard_town::precache, maps\mp\zm_transit_standard_town::main);
	add_map_location_gamemode("zstandard", "diner", scripts\zm\locs\zm_transit_loc_diner::precache, scripts\zm\locs\zm_transit_loc_diner::main);

	add_map_location_gamemode("zgrief", "transit", maps\mp\zm_transit_grief_station::precache, maps\mp\zm_transit_grief_station::main);
	add_map_location_gamemode("zgrief", "farm", maps\mp\zm_transit_grief_farm::precache, maps\mp\zm_transit_grief_farm::main);
	add_map_location_gamemode("zgrief", "town", maps\mp\zm_transit_grief_town::precache, maps\mp\zm_transit_grief_town::main);
	add_map_location_gamemode("zgrief", "diner", scripts\zm\locs\zm_transit_loc_diner::precache, scripts\zm\locs\zm_transit_loc_diner::main);

	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "diner", scripts\zm\locs\zm_transit_loc_diner::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "diner", scripts\zm\locs\zm_transit_loc_diner::struct_init);
}