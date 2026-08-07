// ============================================================================
//  disable_fog_transition.gsc  -  TranZit "transition fog" remover
//  (was Disable_Fog_Transition.gsc; body verbatim from that source script)
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_transit/disable_fog_transition.gsc
//
//  It MUST live in the zm_transit map folder, not in the root scripts/zm
//  folder: the replaceFunc below references maps\mp\zm_transit_fx, and T6
//  resolves external references when a script is LOADED. Scripts under
//  scripts/zm/zm_transit/ only load on zm_transit (TranZit AND all its
//  survival/grief modes - Bus Depot, Town, Farm, Diner), where zm_transit_fx
//  is guaranteed to exist, so the reference always resolves. The root
//  quality_of_life.gsc briefly carried this code on 2026-07-30 and threw
//  "Unresolved external: precache_createfx_fx" on every non-TranZit map,
//  even behind an if(mapname) guard, which is why it moved here.
//
//  What it does: replaces Tranzit's stock FX precache with a copy in which
//  the 3 "transition" fog effect loads are commented out - the thick
//  background fog walls between zones are never registered, so they never
//  spawn. (No_Fog's r_fog / r_dof client dvars stay in the root script.)
// ============================================================================

#include maps\mp\_utility;

main()
{
    replaceFunc( maps\mp\zm_transit_fx::precache_createfx_fx, ::Transition_Disabled );
}

Transition_Disabled()
{
    level._effect["fx_insects_swarm_md_light"] = loadfx( "bio/insects/fx_insects_swarm_md_light" );
    level._effect["fx_zmb_tranzit_flourescent_flicker"] = loadfx( "maps/zombie/fx_zmb_tranzit_flourescent_flicker" );
    level._effect["fx_zmb_tranzit_flourescent_glow"] = loadfx( "maps/zombie/fx_zmb_tranzit_flourescent_glow" );
    level._effect["fx_zmb_tranzit_flourescent_glow_lg"] = loadfx( "maps/zombie/fx_zmb_tranzit_flourescent_glow_lg" );
    level._effect["fx_zmb_tranzit_flourescent_dbl_glow"] = loadfx( "maps/zombie/fx_zmb_tranzit_flourescent_dbl_glow" );
    level._effect["fx_zmb_tranzit_depot_map_flicker"] = loadfx( "maps/zombie/fx_zmb_tranzit_depot_map_flicker" );
    level._effect["fx_zmb_tranzit_light_bulb_xsm"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_bulb_xsm" );
    level._effect["fx_zmb_tranzit_light_glow"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_glow" );
    level._effect["fx_zmb_tranzit_light_glow_xsm"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_glow_xsm" );
    level._effect["fx_zmb_tranzit_light_glow_fog"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_glow_fog" );
    level._effect["fx_zmb_tranzit_light_depot_cans"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_depot_cans" );
    level._effect["fx_zmb_tranzit_light_desklamp"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_desklamp" );
    level._effect["fx_zmb_tranzit_light_town_cans"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_town_cans" );
    level._effect["fx_zmb_tranzit_light_town_cans_sm"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_town_cans_sm" );
    level._effect["fx_zmb_tranzit_light_street_tinhat"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_street_tinhat" );
    level._effect["fx_zmb_tranzit_street_lamp"] = loadfx( "maps/zombie/fx_zmb_tranzit_street_lamp" );
    level._effect["fx_zmb_tranzit_truck_light"] = loadfx( "maps/zombie/fx_zmb_tranzit_truck_light" );
    level._effect["fx_zmb_tranzit_spark_int_runner"] = loadfx( "maps/zombie/fx_zmb_tranzit_spark_int_runner" );
    level._effect["fx_zmb_tranzit_spark_ext_runner"] = loadfx( "maps/zombie/fx_zmb_tranzit_spark_ext_runner" );
    level._effect["fx_zmb_tranzit_spark_blue_lg_loop"] = loadfx( "maps/zombie/fx_zmb_tranzit_spark_blue_lg_loop" );
    level._effect["fx_zmb_tranzit_spark_blue_sm_loop"] = loadfx( "maps/zombie/fx_zmb_tranzit_spark_blue_sm_loop" );
    level._effect["fx_zmb_tranzit_bar_glow"] = loadfx( "maps/zombie/fx_zmb_tranzit_bar_glow" );
    level._effect["fx_zmb_tranzit_transformer_on"] = loadfx( "maps/zombie/fx_zmb_tranzit_transformer_on" );
    level._effect["fx_zmb_fog_closet"] = loadfx( "fog/fx_zmb_fog_closet" );
    level._effect["fx_zmb_fog_low_300x300"] = loadfx( "fog/fx_zmb_fog_low_300x300" );
    level._effect["fx_zmb_fog_thick_600x600"] = loadfx( "fog/fx_zmb_fog_thick_600x600" );
    level._effect["fx_zmb_fog_thick_1200x600"] = loadfx( "fog/fx_zmb_fog_thick_1200x600" );
    //level._effect["fx_zmb_fog_transition_600x600"] = loadfx( "fog/fx_zmb_fog_transition_600x600" );
    //level._effect["fx_zmb_fog_transition_1200x600"] = loadfx( "fog/fx_zmb_fog_transition_1200x600" );
    //level._effect["fx_zmb_fog_transition_right_border"] = loadfx( "fog/fx_zmb_fog_transition_right_border" );
    level._effect["fx_zmb_tranzit_smk_interior_md"] = loadfx( "maps/zombie/fx_zmb_tranzit_smk_interior_md" );
    level._effect["fx_zmb_tranzit_smk_interior_heavy"] = loadfx( "maps/zombie/fx_zmb_tranzit_smk_interior_heavy" );
    level._effect["fx_zmb_ash_ember_1000x1000"] = loadfx( "maps/zombie/fx_zmb_ash_ember_1000x1000" );
    level._effect["fx_zmb_ash_ember_2000x1000"] = loadfx( "maps/zombie/fx_zmb_ash_ember_2000x1000" );
    level._effect["fx_zmb_ash_rising_md"] = loadfx( "maps/zombie/fx_zmb_ash_rising_md" );
    level._effect["fx_zmb_ash_windy_heavy_sm"] = loadfx( "maps/zombie/fx_zmb_ash_windy_heavy_sm" );
    level._effect["fx_zmb_ash_windy_heavy_md"] = loadfx( "maps/zombie/fx_zmb_ash_windy_heavy_md" );
    level._effect["fx_zmb_lava_detail"] = loadfx( "maps/zombie/fx_zmb_lava_detail" );
    level._effect["fx_zmb_lava_edge_100"] = loadfx( "maps/zombie/fx_zmb_lava_edge_100" );
    level._effect["fx_zmb_lava_50x50_sm"] = loadfx( "maps/zombie/fx_zmb_lava_50x50_sm" );
    level._effect["fx_zmb_lava_100x100"] = loadfx( "maps/zombie/fx_zmb_lava_100x100" );
    level._effect["fx_zmb_lava_river"] = loadfx( "maps/zombie/fx_zmb_lava_river" );
    level._effect["fx_zmb_lava_creek"] = loadfx( "maps/zombie/fx_zmb_lava_creek" );
    level._effect["fx_zmb_lava_crevice_glow_50"] = loadfx( "maps/zombie/fx_zmb_lava_crevice_glow_50" );
    level._effect["fx_zmb_lava_crevice_glow_100"] = loadfx( "maps/zombie/fx_zmb_lava_crevice_glow_100" );
    level._effect["fx_zmb_lava_crevice_smoke_100"] = loadfx( "maps/zombie/fx_zmb_lava_crevice_smoke_100" );
    level._effect["fx_zmb_lava_smoke_tall"] = loadfx( "maps/zombie/fx_zmb_lava_smoke_tall" );
    level._effect["fx_zmb_lava_smoke_pit"] = loadfx( "maps/zombie/fx_zmb_lava_smoke_pit" );
    level._effect["fx_zmb_tranzit_bowling_sign_fog"] = loadfx( "maps/zombie/fx_zmb_tranzit_bowling_sign_fog" );
    level._effect["fx_zmb_tranzit_lava_distort"] = loadfx( "maps/zombie/fx_zmb_tranzit_lava_distort" );
    level._effect["fx_zmb_tranzit_lava_distort_sm"] = loadfx( "maps/zombie/fx_zmb_tranzit_lava_distort_sm" );
    level._effect["fx_zmb_tranzit_lava_distort_detail"] = loadfx( "maps/zombie/fx_zmb_tranzit_lava_distort_detail" );
    level._effect["fx_zmb_tranzit_fire_med"] = loadfx( "maps/zombie/fx_zmb_tranzit_fire_med" );
    level._effect["fx_zmb_tranzit_fire_lrg"] = loadfx( "maps/zombie/fx_zmb_tranzit_fire_lrg" );
    level._effect["fx_zmb_tranzit_smk_column_lrg"] = loadfx( "maps/zombie/fx_zmb_tranzit_smk_column_lrg" );
    level._effect["fx_zmb_papers_windy_slow"] = loadfx( "maps/zombie/fx_zmb_papers_windy_slow" );
    level._effect["fx_zmb_tranzit_god_ray_short_warm"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_short_warm" );
    level._effect["fx_zmb_tranzit_god_ray_vault"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_vault" );
    level._effect["fx_zmb_tranzit_key_glint"] = loadfx( "maps/zombie/fx_zmb_tranzit_key_glint" );
    level._effect["fx_zmb_tranzit_god_ray_interior_med"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_interior_med" );
    level._effect["fx_zmb_tranzit_god_ray_interior_long"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_interior_long" );
    level._effect["fx_zmb_tranzit_god_ray_depot_cool"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_depot_cool" );
    level._effect["fx_zmb_tranzit_god_ray_depot_warm"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_depot_warm" );
    level._effect["fx_zmb_tranzit_god_ray_tunnel_warm"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_tunnel_warm" );
    level._effect["fx_zmb_tranzit_god_ray_pwr_station"] = loadfx( "maps/zombie/fx_zmb_tranzit_god_ray_pwr_station" );
    level._effect["fx_zmb_tranzit_light_safety"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_safety" );
    level._effect["fx_zmb_tranzit_light_safety_off"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_safety_off" );
    level._effect["fx_zmb_tranzit_light_safety_max"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_safety_max" );
    level._effect["fx_zmb_tranzit_light_safety_ric"] = loadfx( "maps/zombie/fx_zmb_tranzit_light_safety_ric" );
    level._effect["fx_zmb_tranzit_bridge_dest"] = loadfx( "maps/zombie/fx_zmb_tranzit_bridge_dest" );
    level._effect["fx_zmb_tranzit_power_pulse"] = loadfx( "maps/zombie/fx_zmb_tranzit_power_pulse" );
    level._effect["fx_zmb_tranzit_power_on"] = loadfx( "maps/zombie/fx_zmb_tranzit_power_on" );
    level._effect["fx_zmb_tranzit_power_rising"] = loadfx( "maps/zombie/fx_zmb_tranzit_power_rising" );
    level._effect["fx_zmb_avog_storm"] = loadfx( "maps/zombie/fx_zmb_avog_storm" );
    level._effect["fx_zmb_avog_storm_low"] = loadfx( "maps/zombie/fx_zmb_avog_storm_low" );
    level._effect["glass_impact"] = loadfx( "maps/zombie/fx_zmb_tranzit_window_dest_lg" );
    level._effect["fx_zmb_tranzit_spark_blue_lg_os"] = loadfx( "maps/zombie/fx_zmb_tranzit_spark_blue_lg_os" );
    level._effect["spawn_cloud"] = loadfx( "maps/zombie/fx_zmb_race_zombie_spawn_cloud" );
}
