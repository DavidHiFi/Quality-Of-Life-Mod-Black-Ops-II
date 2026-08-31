// ============================================================================
//  _zm_perk_divetonuke.csc  -  PhD Flopper's client half          (v2.9.16)
// ----------------------------------------------------------------------------
//  🛑 NEW FILE, and until this version the SHIPPED copy was the donor mod.ff's
//  day-one bake, which nothing in the tree could edit. build_ff.bat stages every
//  .csc under scripts\ AND clientscripts\ into zone_assets before linking, so
//  this file now supplies the `script,clientscripts/mp/zombies/
//  _zm_perk_divetonuke.csc` asset mod_base.zone declares - confirm with
//  `Loaded script ... (src: disk)` in the link output. The body below is the
//  donor's copy verbatim except where marked.
//
//  🛑 TWO NUMBERS HERE ARE WIDTH CONTRACTS WITH THE SERVER, AND BOTH HALVES
//  MUST MOVE TOGETHER OR THE MAP DIES AT LOAD WITH EXE_CLIENT_FIELD_MISMATCH:
//    - the visionset lerp step count (1) pairs with
//      maps\mp\zombies\_zm_perk_divetonuke.gsc and quality_of_life.gsc's
//      zmqol_register_divetonuke_visionset();
//    - the `bits` computation pairs with divetonuke_register_clientfield() in
//      the server module - both derive it from whether the EMP grenade is in
//      the weapon include list, and both lists are filled by this mod on every
//      map, so they agree by construction.
// ============================================================================
#include clientscripts\mp\zombies\_zm_perks;
#include clientscripts\mp\_visionset_mgr;

enable_divetonuke_perk_for_level()
{
    clientscripts\mp\zombies\_zm_perks::register_perk_clientfields( "specialty_flakjacket", ::divetonuke_client_field_func, ::divetonuke_code_callback_func );
    clientscripts\mp\zombies\_zm_perks::register_perk_init_thread( "specialty_flakjacket", ::init_divetonuke );
}

init_divetonuke()
{
    if ( isdefined( level.enable_magic ) && level.enable_magic )
    {
        //  🛑 v2.9.16 - lerp steps 5 -> 1, in step with the server (see the
        //  banner in quality_of_life.gsc over zmqol_register_divetonuke_
        //  visionset). With every mod-registered visionset at 1 step,
        //  visionset_lerp is skipped on the maps stock never paid for it on -
        //  Mob of the Dead failed to load asking for exactly those 3 bits.
        clientscripts\mp\_visionset_mgr::vsmgr_register_visionset_info( "zm_perk_divetonuke", 9000, 1, "zombie_cosmodrome_divetonuke", "zombie_cosmodrome_divetonuke" );
    }

    level._effect["divetonuke_groundhit"] = loadfx( "maps/zombie/fx_zmb_phdflopper_exp" );
}

divetonuke_client_field_func()
{
	bits = 1;
	if (clientscripts\mp\zombies\_zm_weapons::is_weapon_included("emp_grenade_zm"))
	{
		bits = 2;
	}
	registerclientfield("toplayer", "perk_dive_to_nuke", 9000, bits, "int", undefined, 0, 1);
}

divetonuke_code_callback_func()
{
    setupclientfieldcodecallbacks( "toplayer", 1, "perk_dive_to_nuke" );
}
