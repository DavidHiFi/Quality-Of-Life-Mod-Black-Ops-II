#include maps\mp\zm_buried;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  buried_zone_init   -   replaces maps\mp\zm_buried::buried_zone_init
//
//  🛑 Fixes: MAZE SURVIVAL HAS NO ZOMBIES AT ALL (the HUD counts them, none ever
//     appear).
//
//  Body is STOCK, verbatim, with ONE addition at the end. Everything else is
//  unchanged so classic Buried and Borough behave exactly as before.
//
//  --- WHY -------------------------------------------------------------------
//  A zone only spawns zombies once it is ENABLED. Buried's init_zones
//  (zm_buried.gsc:325-346) is a flat list of 22 zones and zone_maze is NOT in it.
//  Stock only ever reaches the maze through adjacency:
//
//      add_adjacent_zone( "zone_maze", "zone_mansion_backyard", "mansion_door1", 1 );
//      add_adjacent_zone( "zone_maze", "zone_maze_staircase",   "mansion_door1", 1 );
//
//  but zone_maze is the SOURCE of both edges, so it has to already be enabled for
//  them to lead anywhere. In classic you arrive there from the mansion; on the
//  standalone Maze location there is no such route, so zone_maze is never enabled,
//  its spawn locations never activate, and the arena stays empty.
//
//  This is the same defect that made Tunnel, Cornfield and Power Station
//  unplayable - see scripts\zm\replaced\zm_transit.gsc for the long write-up.
//
//  Gated on the location so classic Buried and Borough survival keep exactly the
//  zone set they already work with; enabling a zone also opens it to zombie
//  spawning, which is precisely what we want here and precisely what we do not
//  want anywhere else.
//
//  zone_init() is idempotent and enable_zone() no-ops on an already-enabled zone.
//
//  Hooked from scripts\zm\zm_buried\zm_buried.gsc::main(). It has to be a whole
//  function replacement rather than re-pointing level.zone_manager_init_func,
//  because that var is assigned inside maps\mp\zm_buried::main() (zm_buried.gsc:324),
//  which runs AFTER our main().
//
//  Every unqualified call resolves through the five #includes above: flag_init /
//  flag_set (common_scripts\utility), add_adjacent_zone / zone_init / enable_zone
//  (maps\mp\zombies\_zm_zonemgr), getdvar is an engine builtin. Audited
//  deliberately - a missing #include here is what broke every TranZit location in
//  v1.1.1.
// ============================================================================
buried_zone_init()
{
    flag_init( "always_on" );
    flag_set( "always_on" );
    add_adjacent_zone( "zone_tunnels_center", "zone_tunnels_north", "always_on" );
    add_adjacent_zone( "zone_tunnels_north", "zone_tunnels_north2", "tunnels2courthouse" );
    add_adjacent_zone( "zone_tunnels_south", "zone_tunnels_south2", "tunnel2saloon" );
    add_adjacent_zone( "zone_tunnels_south3", "zone_tunnels_south2", "always_on" );
    add_adjacent_zone( "zone_tunnels_center", "zone_tunnels_south", "always_on" );
    add_adjacent_zone( "zone_street_lightwest", "zone_general_store", "general_store_door1" );
    add_adjacent_zone( "zone_street_lighteast", "zone_general_store", "always_on" );
    add_adjacent_zone( "zone_street_darkwest", "zone_general_store", "general_store_door2" );
    add_adjacent_zone( "zone_street_lightwest", "zone_morgue_upstairs", "always_on" );
    add_adjacent_zone( "zone_street_fountain", "zone_mansion_lawn", "mansion_lawn_door1" );
    add_adjacent_zone( "zone_street_darkwest", "zone_gun_store", "gun_store_door1" );
    add_adjacent_zone( "zone_stables", "zone_street_lightwest", "always_on", 1 );
    add_adjacent_zone( "zone_street_darkwest", "zone_street_darkwest_nook", "darkwest_nook_door1" );
    add_adjacent_zone( "zone_street_darkwest", "zone_general_store", "general_store_door3" );
    add_adjacent_zone( "zone_street_darkwest_nook", "zone_stables", "stables_door2" );
    add_adjacent_zone( "zone_street_darkeast", "zone_underground_bar", "bar_door1" );
    add_adjacent_zone( "zone_street_darkeast", "zone_street_darkeast_nook", "always_on" );
    add_adjacent_zone( "zone_underground_courthouse2", "zone_underground_courthouse", "always_on" );
    add_adjacent_zone( "zone_street_lighteast", "zone_underground_courthouse", "courthouse_door1" );
    add_adjacent_zone( "zone_street_lightwest", "zone_underground_jail", "jail_door1" );
    add_adjacent_zone( "zone_street_lightwest", "zone_street_lightwest_alley", "jail_jugg" );
    add_adjacent_zone( "zone_underground_jail", "zone_underground_jail2", "always_on" );
    add_adjacent_zone( "zone_underground_jail2", "zone_street_lightwest", "always_on" );
    add_adjacent_zone( "zone_street_lighteast", "zone_candy_store", "candy_store_door1" );
    add_adjacent_zone( "zone_candy_store", "zone_candy_store_floor2", "always_on" );
    add_adjacent_zone( "zone_toy_store_floor2", "zone_candy_store_floor2", "always_on" );
    add_adjacent_zone( "zone_toy_store", "zone_toy_store_floor2", "always_on" );
    add_adjacent_zone( "zone_street_darkeast", "zone_toy_store_floor2", "always_on" );
    add_adjacent_zone( "zone_street_darkeast", "zone_toy_store", "candy_store_door2" );
    add_adjacent_zone( "zone_street_lighteast", "zone_candy_store_floor2", "candy2lighteast", 1 );
    add_adjacent_zone( "zone_street_darkeast", "zone_candy_store_floor2", "always_on", 1 );
    add_adjacent_zone( "zone_toy_store_tunnel", "zone_toy_store_floor2", "always_on", 1 );
    add_adjacent_zone( "zone_street_lighteast", "zone_street_fountain", "always_on" );
    add_adjacent_zone( "zone_street_fountain", "zone_church_graveyard", "always_on" );
    add_adjacent_zone( "zone_church_graveyard", "zone_church_main", "church_door1" );
    add_adjacent_zone( "zone_church_main", "zone_church_upstairs", "church_door1" );
    add_adjacent_zone( "zone_gun_store", "zone_tunnel_gun2stables", "gunshop2tunnel" );
    add_adjacent_zone( "zone_tunnel_gun2saloon", "zone_underground_bar", "always_on" );
    add_adjacent_zone( "zone_maze", "zone_mansion_backyard", "mansion_door1", 1 );
    add_adjacent_zone( "zone_maze", "zone_maze_staircase", "mansion_door1", 1 );
    add_adjacent_zone( "zone_stables", "zone_tunnel_gun2stables2", "always_on" );
    add_adjacent_zone( "zone_tunnel_gun2stables2", "zone_tunnel_gun2stables", "always_on" );

    // ---- zm_qol addition: everything above this line is stock ---------------
    if ( getdvar( "ui_zm_mapstartlocation" ) == "maze" )
    {
        zone_init( "zone_maze" );
        enable_zone( "zone_maze" );

        zone_init( "zone_maze_staircase" );
        enable_zone( "zone_maze_staircase" );

        zone_init( "zone_mansion_backyard" );
        enable_zone( "zone_mansion_backyard" );
    }
}
