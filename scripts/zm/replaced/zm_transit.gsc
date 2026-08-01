#include maps\mp\zm_transit;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_zonemgr;
// 🛑 REQUIRED: the stock body below calls disconnect_door_zones() unqualified.
// That function lives in maps\mp\zm_transit_utility, and stock zm_transit.gsc
// only gets it via its own #include of that file. Copying the body without this
// line throws "Unresolved external: disconnect_door_zones with 3 parameters" at
// SCRIPT LOAD, which kills every TranZit location (Tunnel, Diner, classic) with
// a COM_ERROR before the map starts. Confirmed in console_zm.log 2026-08-02.
#include maps\mp\zm_transit_utility;

// ============================================================================
//  transit_zone_init   -   replaces maps\mp\zm_transit::transit_zone_init
//
//  🛑 Fixes: TUNNEL SURVIVAL KILLS THE PLAYER THE INSTANT THE MAP LOADS.
//
//  The body below is STOCK, verbatim, with ONE addition at the end (the
//  zone_init/enable_zone block). Everything else is unchanged so classic
//  TranZit, Diner, Power and the stock locations behave exactly as before.
//
//  --- WHY -------------------------------------------------------------------
//  maps\mp\zombies\_zm_zonemgr::manage_zones() runs in this order:
//
//      1. spawn_points = _zm_gametype::get_player_spawns_for_gametype();
//         for each: spawn_points[i].locked = 1;        <-- ALL respawns locked
//      2. [[ level.zone_manager_init_func ]]();        <-- this function
//      3. for each initial zone: zone_init(); enable_zone();
//
//  and enable_zone( name ) is the ONLY thing that unlocks a respawn point:
//
//      if ( spawn_points[i].script_noteworthy == zone_name )
//          spawn_points[i].locked = 0;
//
//  Tunnel registers its whole respawn group under script_noteworthy
//  "zone_amb_tunnel" (scripts\zm\locs\zm_transit_loc_tunnel::struct_init, via
//  scripts\zm\replaced\utility::register_map_spawn_group). But stock TranZit
//  only puts zone_amb_tunnel in init_zones INSIDE `if ( is_classic() )`
//  (zm_transit.gsc:371-390) - in zstandard/zgrief the zone is never created,
//  never enabled, and it has no add_adjacent_zone edge anywhere in this
//  function, so no door-opening can ever reach it either.
//
//  Result on Tunnel survival: every tunnel respawn point stays locked forever,
//  _zm_gametype::onspawnplayer finds no usable spawn and falls through to
//  `getstructarray( "initial_spawn_points", "targetname" )` - the map default,
//  back at the Bus Depot, where the non-classic pass has already deleted the
//  "classic_only" player_volume areas. The player is dumped outside the
//  playable area and dies at once. That is the "death barrier".
//
//  This is also exactly why Diner works and Tunnel does not: Diner's zones
//  (zone_gas / zone_roadside_east / zone_roadside_west) all have adjacency
//  edges below, so they get created and reached normally.
//
//  --- WHY THIS FUNCTION AND NOT SOMEWHERE CHEAPER ---------------------------
//  The enable has to land between steps 1 and 3 above. level.zone_manager_init_func
//  is only assigned inside maps\mp\zm_transit::main(), which runs AFTER our
//  main() - so re-pointing the level var (CLAUDE.md section 4, failure mode 2)
//  is not available here and the function itself has to be replaced.
//
//  Verified against BO2-Reimagined, which fixes this identically:
//  scripts\zm\replaced\zm_transit.gsc:228-235 - same three zones, same place,
//  hooked from scripts\zm\zm_transit\zm_transit_reimagined.gsc:24.
//  Reimagined applies it unconditionally; it is gated on !is_classic() here so
//  classic TranZit's round-one zone set is untouched.
// ============================================================================
transit_zone_init()
{
    flag_init( "always_on" );
    flag_init( "init_classic_adjacencies" );
    flag_set( "always_on" );

    if ( is_classic() )
    {
        flag_set( "init_classic_adjacencies" );
        add_adjacent_zone( "zone_trans_2", "zone_trans_2b", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_station_ext", "zone_trans_2b", "init_classic_adjacencies", 1 );
        add_adjacent_zone( "zone_town_west2", "zone_town_west", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_town_south", "zone_town_church", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_trans_pow_ext1", "zone_trans_7", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_far", "zone_far_ext", "OnFarm_enter" );
    }
    else
    {
        playable_area = getentarray( "player_volume", "script_noteworthy" );

        foreach ( area in playable_area )
        {
            add_adjacent_zone( "zone_station_ext", "zone_trans_2b", "always_on" );

            if ( isdefined( area.script_parameters ) && area.script_parameters == "classic_only" )
                area delete();
        }
    }

    add_adjacent_zone( "zone_pri2", "zone_station_ext", "OnPriDoorYar", 1 );
    add_adjacent_zone( "zone_pri2", "zone_pri", "OnPriDoorYar3", 1 );

    if ( getdvar( "ui_zm_mapstartlocation" ) == "transit" )
    {
        level thread disconnect_door_zones( "zone_pri2", "zone_station_ext", "OnPriDoorYar" );
        level thread disconnect_door_zones( "zone_pri2", "zone_pri", "OnPriDoorYar3" );
    }

    add_adjacent_zone( "zone_station_ext", "zone_pri", "OnPriDoorYar2" );
    add_adjacent_zone( "zone_roadside_west", "zone_din", "OnGasDoorDin" );
    add_adjacent_zone( "zone_roadside_west", "zone_gas", "always_on" );
    add_adjacent_zone( "zone_roadside_east", "zone_gas", "always_on" );
    add_adjacent_zone( "zone_roadside_east", "zone_gar", "OnGasDoorGar" );
    add_adjacent_zone( "zone_trans_diner", "zone_roadside_west", "always_on", 1 );
    add_adjacent_zone( "zone_trans_diner", "zone_gas", "always_on", 1 );
    add_adjacent_zone( "zone_trans_diner2", "zone_roadside_east", "always_on", 1 );
    add_adjacent_zone( "zone_gas", "zone_din", "OnGasDoorDin" );
    add_adjacent_zone( "zone_gas", "zone_gar", "OnGasDoorGar" );
    add_adjacent_zone( "zone_diner_roof", "zone_din", "OnGasDoorDin", 1 );
    add_adjacent_zone( "zone_amb_cornfield", "zone_cornfield_prototype", "always_on" );
    add_adjacent_zone( "zone_tow", "zone_bar", "always_on", 1 );
    add_adjacent_zone( "zone_bar", "zone_tow", "OnTowDoorBar", 1 );
    add_adjacent_zone( "zone_tow", "zone_ban", "OnTowDoorBan" );
    add_adjacent_zone( "zone_ban", "zone_ban_vault", "OnTowBanVault" );
    add_adjacent_zone( "zone_tow", "zone_town_north", "always_on" );
    add_adjacent_zone( "zone_town_north", "zone_ban", "OnTowDoorBan" );
    add_adjacent_zone( "zone_tow", "zone_town_west", "always_on" );
    add_adjacent_zone( "zone_tow", "zone_town_south", "always_on" );
    add_adjacent_zone( "zone_town_south", "zone_town_barber", "always_on", 1 );
    add_adjacent_zone( "zone_tow", "zone_town_east", "always_on" );
    add_adjacent_zone( "zone_town_east", "zone_bar", "OnTowDoorBar" );
    add_adjacent_zone( "zone_tow", "zone_town_barber", "always_on", 1 );
    add_adjacent_zone( "zone_town_barber", "zone_tow", "OnTowDoorBarber", 1 );
    add_adjacent_zone( "zone_town_barber", "zone_town_west", "OnTowDoorBarber" );
    add_adjacent_zone( "zone_far_ext", "zone_brn", "OnFarm_enter" );
    add_adjacent_zone( "zone_far_ext", "zone_farm_house", "open_farmhouse" );
    add_adjacent_zone( "zone_prr", "zone_pow", "OnPowDoorRR", 1 );
    add_adjacent_zone( "zone_pcr", "zone_prr", "OnPowDoorRR" );
    add_adjacent_zone( "zone_pcr", "zone_pow_warehouse", "OnPowDoorWH" );
    add_adjacent_zone( "zone_pow", "zone_pow_warehouse", "OnPowDoorWH" );
    add_adjacent_zone( "zone_tbu", "zone_tow", "vault_opened", 1 );

    // ---- zm_qol addition: everything above this line is stock ----------------
    // zone_init() is idempotent (it returns early if the zone already exists) and
    // enable_zone() no-ops on an already-enabled zone, so this is safe even if a
    // future stock path starts creating them.
    if ( !is_classic() )
    {
        zone_init( "zone_amb_tunnel" );
        enable_zone( "zone_amb_tunnel" );

        // Cornfield has the same shape of problem: its two zones are adjacent to
        // each other but to nothing else, so the pair is an island the enabled
        // set can never reach.
        zone_init( "zone_amb_cornfield" );
        enable_zone( "zone_amb_cornfield" );

        zone_init( "zone_cornfield_prototype" );
        enable_zone( "zone_cornfield_prototype" );
    }
}
