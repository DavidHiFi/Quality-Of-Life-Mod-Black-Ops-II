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
// ============================================================================
//  zmqol_zone_flag   -   the Maze seal
//
//  🛑 SECOND FIX, 2026-08-02. Enabling zone_maze (below) was necessary but NOT
//  sufficient - the probe shipped in v1.6.4 finally ran and reported FOURTEEN
//  zones enabled with spawning on: the streets, the gun store, the church, the
//  mansion lawn, the underground jail. Zombies were spawning across the whole of
//  Buried and could not path into a walled-off maze. Checkpoint 11 §3.6, second
//  failure mode.
//
//  Why zm_buried_loc_maze::disable_zones() could never hold it:
//    1. _zm_zonemgr::enable_zone() (line 434) sets is_enabled = 1 AND
//       is_spawning_allowed = 1. It undoes both of the fields disable_zones
//       clears.
//    2. manage_zones() re-walks the adjacency table continuously - `if (flags_set)
//       enable_zone(...)`. The Maze loc calls powerswitchstate(1),
//       deleteslothbarricades() and flag_set("mansion_door1"), so the door flags
//       stay set for the whole game and every reachable zone is re-enabled on the
//       next pass. A one-shot write cannot beat a loop that re-derives state.
//    3. Ordering makes it moot anyway: the loc's main() runs from _zm::init, while
//       `level thread manage_zones(init_zones)` is at the END of zm_buried::main().
//       So disable_zones() ran, and only then did manage_zones zone_init +
//       enable_zone all 22 init_zones on top of it.
//
//  So the lever has to be the adjacency table itself, which is this function.
//  On the Maze arena every edge is re-pointed at "zmqol_zone_sealed", a flag that
//  is initialised and never set. add_adjacent_zone() still calls zone_init() on
//  both endpoints, so EVERY zone is created exactly as stock - nothing that
//  dereferences level.zones[...] elsewhere in Buried can hit an undefined - but
//  manage_zones' flags_set test can never pass, so it can never enable one.
//
//  The two zone_maze edges deliberately keep their real "mansion_door1" flag, so
//  the arena itself still connects to zone_mansion_backyard and
//  zone_maze_staircase.
//
//  That leaves the 22 init_zones, which manage_zones enables DIRECTLY rather than
//  through adjacency. Those are handled on the other side, by
//  zm_buried_loc_maze::zmqol_seal_zones_after_manager() - it waits for
//  level.zone_keys (assigned immediately after that init pass) and only then
//  disables them. With the table sealed here, nothing re-enables them afterwards,
//  which is exactly what made the old one-shot fail. The two halves have to stay
//  in step.
//
//  Reads the dvar per call rather than caching, so classic Buried and Borough
//  survival take the stock path with zero behaviour change.
// ============================================================================
zmqol_zone_flag( str_flag )
{
    if ( getdvar( "ui_zm_mapstartlocation" ) == "maze" )
        return "zmqol_zone_sealed";

    return str_flag;
}

buried_zone_init()
{
    flag_init( "always_on" );
    flag_set( "always_on" );
    flag_init( "zmqol_zone_sealed" );   // deliberately never set - see above
    add_adjacent_zone( "zone_tunnels_center", "zone_tunnels_north", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_tunnels_north", "zone_tunnels_north2", zmqol_zone_flag( "tunnels2courthouse" ));
    add_adjacent_zone( "zone_tunnels_south", "zone_tunnels_south2", zmqol_zone_flag( "tunnel2saloon" ));
    add_adjacent_zone( "zone_tunnels_south3", "zone_tunnels_south2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_tunnels_center", "zone_tunnels_south", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_lightwest", "zone_general_store", zmqol_zone_flag( "general_store_door1" ));
    add_adjacent_zone( "zone_street_lighteast", "zone_general_store", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_darkwest", "zone_general_store", zmqol_zone_flag( "general_store_door2" ));
    add_adjacent_zone( "zone_street_lightwest", "zone_morgue_upstairs", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_fountain", "zone_mansion_lawn", zmqol_zone_flag( "mansion_lawn_door1" ));
    add_adjacent_zone( "zone_street_darkwest", "zone_gun_store", zmqol_zone_flag( "gun_store_door1" ));
    add_adjacent_zone( "zone_stables", "zone_street_lightwest", zmqol_zone_flag( "always_on" ), 1 );
    add_adjacent_zone( "zone_street_darkwest", "zone_street_darkwest_nook", zmqol_zone_flag( "darkwest_nook_door1" ));
    add_adjacent_zone( "zone_street_darkwest", "zone_general_store", zmqol_zone_flag( "general_store_door3" ));
    add_adjacent_zone( "zone_street_darkwest_nook", "zone_stables", zmqol_zone_flag( "stables_door2" ));
    add_adjacent_zone( "zone_street_darkeast", "zone_underground_bar", zmqol_zone_flag( "bar_door1" ));
    add_adjacent_zone( "zone_street_darkeast", "zone_street_darkeast_nook", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_underground_courthouse2", "zone_underground_courthouse", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_lighteast", "zone_underground_courthouse", zmqol_zone_flag( "courthouse_door1" ));
    add_adjacent_zone( "zone_street_lightwest", "zone_underground_jail", zmqol_zone_flag( "jail_door1" ));
    add_adjacent_zone( "zone_street_lightwest", "zone_street_lightwest_alley", zmqol_zone_flag( "jail_jugg" ));
    add_adjacent_zone( "zone_underground_jail", "zone_underground_jail2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_underground_jail2", "zone_street_lightwest", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_lighteast", "zone_candy_store", zmqol_zone_flag( "candy_store_door1" ));
    add_adjacent_zone( "zone_candy_store", "zone_candy_store_floor2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_toy_store_floor2", "zone_candy_store_floor2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_toy_store", "zone_toy_store_floor2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_darkeast", "zone_toy_store_floor2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_darkeast", "zone_toy_store", zmqol_zone_flag( "candy_store_door2" ));
    add_adjacent_zone( "zone_street_lighteast", "zone_candy_store_floor2", zmqol_zone_flag( "candy2lighteast" ), 1 );
    add_adjacent_zone( "zone_street_darkeast", "zone_candy_store_floor2", zmqol_zone_flag( "always_on" ), 1 );
    add_adjacent_zone( "zone_toy_store_tunnel", "zone_toy_store_floor2", zmqol_zone_flag( "always_on" ), 1 );
    add_adjacent_zone( "zone_street_lighteast", "zone_street_fountain", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_street_fountain", "zone_church_graveyard", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_church_graveyard", "zone_church_main", zmqol_zone_flag( "church_door1" ));
    add_adjacent_zone( "zone_church_main", "zone_church_upstairs", zmqol_zone_flag( "church_door1" ));
    add_adjacent_zone( "zone_gun_store", "zone_tunnel_gun2stables", zmqol_zone_flag( "gunshop2tunnel" ));
    add_adjacent_zone( "zone_tunnel_gun2saloon", "zone_underground_bar", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_maze", "zone_mansion_backyard", "mansion_door1", 1 );
    add_adjacent_zone( "zone_maze", "zone_maze_staircase", "mansion_door1", 1 );
    add_adjacent_zone( "zone_stables", "zone_tunnel_gun2stables2", zmqol_zone_flag( "always_on" ));
    add_adjacent_zone( "zone_tunnel_gun2stables2", "zone_tunnel_gun2stables", zmqol_zone_flag( "always_on" ));

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
