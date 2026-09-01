#include maps\mp\zm_prison;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  working_zone_init   -   replaces maps\mp\zm_prison::working_zone_init
//
//  Ported from BO2-Reimagined scripts\zm\replaced\zm_prison.gsc:39-152, which is
//  the implementation the custom survival locations were built against.
//
//  🛑 Fixes: CELL BLOCK SURVIVAL KILLS YOU THE INSTANT YOU SPAWN (and the same
//     defect underlies Docks).
//
//  --- WHY --------------------------------------------------------------------
//  _zm::player_out_of_playable_area_monitor kills a player when
//  in_enabled_playable_area() is false, and that function requires the player to
//  be touching a "player_volume" entity whose TARGETNAME IS A ZONE THAT IS
//  ENABLED (_zm.gsc:1442-1456). On Mob of the Dead the kill is unconditional:
//  _zm_afterlife::player_out_of_playable_area returns true for anyone not in
//  afterlife and not on the plane.
//
//  This project ships a custom maps\mp\zm_prison.d3dbsp mapents override taken
//  from Reimagined (see mod.iwd), but never ported the working_zone_init that
//  goes with it, so the entity data and the zone setup disagreed.
//
//  --- WHAT DIFFERS FROM STOCK (diffed, not assumed) ---------------------------
//  1. Stock gates BOTH the cellblock-west roof spawner filter and the
//     "classic_only" player_volume deletion on is_gametype_active( "zgrief" ).
//     Reimagined gates them on !is_classic(), so they also apply to zstandard -
//     which is the mode every custom survival location runs in.
//  2. The spawner filter rebuilds level.struct_class_names[...] instead of
//     calling structdelete(), because Reimagined's struct system (already ported
//     here as scripts\zm\replaced\utility.gsc) owns that array.
//  3. 📝 2026-09-02, restoration: the pre-strip copy replaced stock's
//     classic-only `zone_dock_puzzle -> zone_dock_puzzle` self-edge with an
//     unconditional `zone_dock -> zone_dock_puzzle` edge on the flag
//     "docks_inner_gate_unlocked" - set only by the DOCKS loc script, which is
//     EXCLUDED from this restoration. With nothing ever setting that flag,
//     classic Mob's dock-puzzle zone would never have been created: its
//     respawn points stay locked and the area stops counting as playable -
//     the out-of-area kill class. So this copy keeps stock's classic line
//     verbatim (diffed against the stock dump, zm_prison.gsc:1067-1068) and
//     drops the Docks edge outright.
//
//  Hooked from scripts\zm\zm_prison\zm_prison.gsc::main(). It has to be a whole
//  function replacement rather than re-pointing level.zone_manager_init_func,
//  because that var is assigned inside maps\mp\zm_prison::main() (zm_prison.gsc:192),
//  which runs AFTER our main() - same reasoning as the TranZit fix in
//  scripts\zm\replaced\zm_transit.gsc.
//
//  Every unqualified call below resolves through the five #includes above:
//  flag_init/flag_set (common_scripts\utility), is_classic
//  (maps\mp\zombies\_zm_utility), add_adjacent_zone (maps\mp\zombies\_zm_zonemgr);
//  getstructarray/getentarray/delete are engine builtins. Audited deliberately -
//  a missing #include here is exactly what broke every TranZit location in v1.1.1.
// ============================================================================
working_zone_init()
{
	flag_init("always_on");
	flag_set("always_on");

	if (!is_classic())
	{
		a_s_spawner = getstructarray("zone_cellblock_west_roof_spawner", "targetname");
		spawners_to_keep = [];

		foreach (spawner in a_s_spawner)
		{
			if (isdefined(spawner.script_parameters) && spawner.script_parameters == "zclassic_prison")
			{
				continue;
			}

			spawners_to_keep[spawners_to_keep.size] = spawner;
		}

		level.struct_class_names["targetname"]["zone_cellblock_west_roof_spawner"] = spawners_to_keep;
	}

	if (is_classic())
	{
		add_adjacent_zone("zone_library", "zone_start", "always_on");
	}
	else
	{
		add_adjacent_zone("zone_library", "zone_cellblock_west", "activate_cellblock_west");
		add_adjacent_zone("zone_library", "zone_start", "activate_cellblock_west");
		add_adjacent_zone("zone_cellblock_east", "zone_start", "activate_cellblock_east");
		add_adjacent_zone("zone_library", "zone_start", "activate_cellblock_east");
	}

	add_adjacent_zone("zone_library", "zone_cellblock_west", "activate_cellblock_west");
	add_adjacent_zone("zone_cellblock_west", "zone_cellblock_west_barber", "activate_cellblock_barber");
	add_adjacent_zone("zone_cellblock_west_warden", "zone_cellblock_west_barber", "activate_cellblock_barber");
	add_adjacent_zone("zone_cellblock_west_warden", "zone_cellblock_west_barber", "activate_cellblock_gondola");
	add_adjacent_zone("zone_cellblock_west", "zone_cellblock_west_gondola", "activate_cellblock_gondola");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_west_gondola", "activate_cellblock_gondola");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west_barber", "activate_cellblock_gondola");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_east", "activate_cellblock_gondola");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_infirmary", "activate_cellblock_infirmary");
	add_adjacent_zone("zone_infirmary_roof", "zone_infirmary", "activate_cellblock_infirmary");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west_barber", "activate_cellblock_infirmary");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west", "activate_cellblock_infirmary");
	add_adjacent_zone("zone_start", "zone_cellblock_east", "activate_cellblock_east");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_west_warden", "activate_cellblock_infirmary");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_east", "activate_cellblock_east_west");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_west_warden", "activate_cellblock_east_west");
	add_adjacent_zone("zone_cellblock_west_warden", "zone_warden_office", "activate_warden_office");
	add_adjacent_zone("zone_cellblock_west_warden", "zone_citadel_warden", "activate_cellblock_citadel");
	add_adjacent_zone("zone_cellblock_west_warden", "zone_cellblock_west_barber", "activate_cellblock_citadel");
	add_adjacent_zone("zone_citadel", "zone_citadel_warden", "activate_cellblock_citadel");
	add_adjacent_zone("zone_citadel", "zone_citadel_shower", "activate_cellblock_citadel");
	add_adjacent_zone("zone_cellblock_east", "zone_cafeteria", "activate_cafeteria");
	add_adjacent_zone("zone_cafeteria", "zone_cafeteria_end", "activate_cafeteria");
	add_adjacent_zone("zone_cellblock_east", "cellblock_shower", "activate_shower_room");
	add_adjacent_zone("cellblock_shower", "zone_citadel_shower", "activate_shower_citadel");
	add_adjacent_zone("zone_citadel_shower", "zone_citadel", "activate_shower_citadel");
	add_adjacent_zone("zone_citadel", "zone_citadel_warden", "activate_shower_citadel");
	add_adjacent_zone("zone_cafeteria", "zone_infirmary", "activate_infirmary");
	add_adjacent_zone("zone_cafeteria", "zone_cafeteria_end", "activate_infirmary");
	add_adjacent_zone("zone_infirmary_roof", "zone_infirmary", "activate_infirmary");
	add_adjacent_zone("zone_roof", "zone_roof_infirmary", "activate_roof");
	add_adjacent_zone("zone_roof_infirmary", "zone_infirmary_roof", "activate_roof");
	add_adjacent_zone("zone_citadel", "zone_citadel_stairs", "activate_citadel_stair");
	add_adjacent_zone("zone_citadel", "zone_citadel_shower", "activate_citadel_stair");
	add_adjacent_zone("zone_citadel", "zone_citadel_warden", "activate_citadel_stair");
	add_adjacent_zone("zone_citadel_stairs", "zone_citadel_basement", "activate_citadel_basement");
	add_adjacent_zone("zone_citadel_basement", "zone_citadel_basement_building", "activate_citadel_basement");
	add_adjacent_zone("zone_citadel_basement", "zone_citadel_basement_building", "activate_basement_building");
	add_adjacent_zone("zone_citadel_basement_building", "zone_studio", "activate_basement_building");
	add_adjacent_zone("zone_citadel_basement", "zone_studio", "activate_basement_building");
	add_adjacent_zone("zone_citadel_basement_building", "zone_dock_gondola", "activate_basement_gondola");
	add_adjacent_zone("zone_citadel_basement", "zone_citadel_basement_building", "activate_basement_gondola");
	add_adjacent_zone("zone_dock", "zone_dock_gondola", "activate_basement_gondola");
	add_adjacent_zone("zone_studio", "zone_dock", "activate_dock_sally");
	add_adjacent_zone("zone_dock_gondola", "zone_dock", "activate_dock_sally");
	add_adjacent_zone("zone_dock", "zone_dock_gondola", "gondola_roof_to_dock");
	add_adjacent_zone("zone_cellblock_west", "zone_cellblock_west_gondola", "gondola_dock_to_roof");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_west_gondola", "gondola_dock_to_roof");
	add_adjacent_zone("zone_cellblock_west_barber", "zone_cellblock_west_warden", "gondola_dock_to_roof");
	add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_east", "gondola_dock_to_roof");

	if (is_classic())
	{
		add_adjacent_zone("zone_gondola_ride", "zone_gondola_ride", "gondola_ride_zone_enabled");
	}

	if (is_classic())
	{
		add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west_gondola_dock", "activate_cellblock_infirmary");
		add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west_gondola_dock", "activate_cellblock_gondola");
		add_adjacent_zone("zone_cellblock_west_gondola", "zone_cellblock_west_gondola_dock", "gondola_dock_to_roof");
	}
	else
	{
		playable_area = getentarray("player_volume", "script_noteworthy");

		foreach (area in playable_area)
		{
			if (isdefined(area.script_parameters) && area.script_parameters == "classic_only")
			{
				area delete();
			}
		}
	}

	add_adjacent_zone("zone_golden_gate_bridge", "zone_golden_gate_bridge", "activate_player_zone_bridge");

	if (is_classic())
	{
		add_adjacent_zone("zone_dock_puzzle", "zone_dock_puzzle", "always_on");
	}
}
