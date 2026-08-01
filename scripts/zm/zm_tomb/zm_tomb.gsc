#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_tomb;
#include maps\mp\zm_tomb_utility;

main()
{
    // These hook Origins-only functions. Safe here because this map script only
    // loads on Origins (so the references resolve), and done in main() so they're
    // in place before the map threads the native code. Matches zm_highrise.gsc.
    replaceFunc( maps\mp\zm_tomb_dig::swap_weapon, ::custom_swap_weapon );            // weapon-dig fix
    replaceFunc( maps\mp\zm_tomb_ee_side::check_for_change, ::origins_change_patch ); // prone "loose change" -> 100

    // --- custom survival start locations: Trenches, Excavation Site, Church, The Crazy Place ---
    replaceFunc( maps\mp\zm_tomb_gamemodes::init, scripts\zm\replaced\zm_tomb_gamemodes::init );

    // ========================================================================
    //  ORIGINS SURVIVAL - the zone-capture / generator system.
    //
    //  Fixes, reported on Trenches:
    //    - Speed Cola machine missing, with part of it still poking through the
    //      wall where the robot steps
    //    - mystery box refusing to open, demanding the generator be powered
    //    - starting a generator giving no capture progress ring, and spawning
    //      Templars as if it were classic Origins
    //    - dig sites visible where no shovel can be obtained
    //
    //  These are all one subsystem. Stock zm_tomb_capture_zones assumes classic
    //  Origins: perk machines and mystery boxes are OWNED by generator zones and
    //  gated behind capturing them. A standalone survival arena has no generator
    //  to capture, so the machine never finishes spawning and the box never
    //  unlocks.
    //
    //  BO2-Reimagined already solves this and its version is explicitly
    //  location-aware - it branches on ui_zm_mapstartlocation == trenches /
    //  excavation_site / church as well as is_classic(), so classic Origins keeps
    //  stock behaviour. That matters here: the standing instruction is to add the
    //  survival locations WITHOUT altering the base maps.
    //
    //  Ported verbatim to scripts\zm\replaced\zm_tomb_capture_zones.gsc. Its 21
    //  #includes are all stock maps\mp\ scripts, so it drags in no other
    //  Reimagined file, and all 18 hooked functions were verified present in the
    //  ported copy before wiring these up.
    // ========================================================================
    replaceFunc(maps\mp\zm_tomb_capture_zones::precache_everything, scripts\zm\replaced\zm_tomb_capture_zones::precache_everything);
    replaceFunc(maps\mp\zm_tomb_capture_zones::declare_objectives, scripts\zm\replaced\zm_tomb_capture_zones::declare_objectives);
    replaceFunc(maps\mp\zm_tomb_capture_zones::init_capture_zone, scripts\zm\replaced\zm_tomb_capture_zones::init_capture_zone);
    replaceFunc(maps\mp\zm_tomb_capture_zones::register_elements_powered_by_zone_capture_generators, scripts\zm\replaced\zm_tomb_capture_zones::register_elements_powered_by_zone_capture_generators);
    replaceFunc(maps\mp\zm_tomb_capture_zones::enable_mystery_boxes_in_zone, scripts\zm\replaced\zm_tomb_capture_zones::enable_mystery_boxes_in_zone);
    replaceFunc(maps\mp\zm_tomb_capture_zones::disable_mystery_boxes_in_zone, scripts\zm\replaced\zm_tomb_capture_zones::disable_mystery_boxes_in_zone);
    replaceFunc(maps\mp\zm_tomb_capture_zones::pack_a_punch_init, scripts\zm\replaced\zm_tomb_capture_zones::pack_a_punch_init);
    replaceFunc(maps\mp\zm_tomb_capture_zones::pack_a_punch_enable, scripts\zm\replaced\zm_tomb_capture_zones::pack_a_punch_enable);
    replaceFunc(maps\mp\zm_tomb_capture_zones::setup_perk_machines_not_controlled_by_zone_capture, scripts\zm\replaced\zm_tomb_capture_zones::setup_perk_machines_not_controlled_by_zone_capture);
    replaceFunc(maps\mp\zm_tomb_capture_zones::check_perk_machine_valid, scripts\zm\replaced\zm_tomb_capture_zones::check_perk_machine_valid);
    replaceFunc(maps\mp\zm_tomb_capture_zones::all_zones_captured_vo, scripts\zm\replaced\zm_tomb_capture_zones::all_zones_captured_vo);
    replaceFunc(maps\mp\zm_tomb_capture_zones::init_recapture_zombie, scripts\zm\replaced\zm_tomb_capture_zones::init_recapture_zombie);
    replaceFunc(maps\mp\zm_tomb_capture_zones::recapture_zombie_death_func, scripts\zm\replaced\zm_tomb_capture_zones::recapture_zombie_death_func);
    replaceFunc(maps\mp\zm_tomb_capture_zones::recapture_round_tracker, scripts\zm\replaced\zm_tomb_capture_zones::recapture_round_tracker);
    replaceFunc(maps\mp\zm_tomb_capture_zones::recapture_zombie_icon_think, scripts\zm\replaced\zm_tomb_capture_zones::recapture_zombie_icon_think);
    replaceFunc(maps\mp\zm_tomb_capture_zones::get_zone_objective_index, scripts\zm\replaced\zm_tomb_capture_zones::get_zone_objective_index);
    replaceFunc(maps\mp\zm_tomb_capture_zones::get_generator_capture_start_cost, scripts\zm\replaced\zm_tomb_capture_zones::get_generator_capture_start_cost);
    replaceFunc(maps\mp\zm_tomb_capture_zones::magic_box_stub_update_prompt, scripts\zm\replaced\zm_tomb_capture_zones::magic_box_stub_update_prompt);

    // Must run in main(), before the map registers its own clientfields.
    zmqol_register_survival_clientfields();
}

// ============================================================================
//  zmqol_register_survival_clientfields
//
//  🛑 Fixes a HARD CRASH on every non-classic Origins start location:
//        Clientfield 'element_glow_fx' in set [scriptmover] is not registered on the server
//        Clientfield 'switch_spark'    in set [scriptmover] is not registered on the server
//        COM_ERROR (3) Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  This is a latent asymmetry in STOCK Origins, not something the port introduced:
//    * the CLIENT registers these unconditionally -
//        element_glow_fx / bryce_cake / switch_spark  in clientscripts/mp/zm_tomb.csc:46-48
//        sndMudSlow                                   in clientscripts/mp/zm_tomb_amb.csc:203
//    * the SERVER only registers them inside
//        maps\mp\zm_tomb_craftables::register_clientfields()  (zm_tomb_craftables.gsc:364-377)
//      which is reached solely from maps\mp\zm_tomb_classic::main() -> init_craftables().
//
//  Stock Origins is zclassic-only, so that path always ran and nobody ever hit it.
//  The moment Origins is played as zstandard/zgrief, the craftables path is skipped,
//  the server registers nothing, client and server disagree, and the engine drops the
//  connection. Registering the same four fields here restores parity.
//
//  Guarded by is_classic() so zclassic still gets them from stock's craftables path -
//  registering the same field twice would itself be an error.
//
//  Verified against BO2-Reimagined, which fixes this identically in
//  scripts/zm/zm_tomb/zm_tomb_reimagined.gsc:191-202 (same four fields, same guard,
//  also called from the end of main()).
//
//  ---------------------------------------------------------------------------
//  2026-07-31: TWO MORE FIELDS, same root cause, different stock code path.
//
//  Crazy Place / zstandard still dropped with EXE_CLIENT_FIELD_MISMATCH:
//        Clientfield 'electric_cherry_reload_fx' in set [allplayers] is not registered on the server
//        Clientfield 'visionset_slot' in set[toplayer] not the same bit count : [CLIENT: 2 SERVER: 1]
//
//  The gate is maps\mp\zombies\_zm_perks::init() line 52:
//
//        vending_triggers = getentarray( "zombie_vending", "targetname" );
//        ...
//        if ( vending_triggers.size < 1 )
//            return;              <-- returns BEFORE the _custom_perks loop at 101-110
//
//  perk_machine_spawn_init() only spawns machines whose struct script_string
//  contains "<gametype>_perks_<location>". No Origins struct is tagged for the
//  survival locations, so zero "zombie_vending" triggers exist, _zm_perks::init()
//  bails at line 52, and the per-perk machine_thread loop never runs. Those threads
//  are the ONLY server-side callers of:
//        _zm_perk_electric_cherry::init_electric_cherry()  -> registers electric_cherry_reload_fx
//        _zm_perk_divetonuke::init_divetonuke()            -> registers the zm_perk_divetonuke visionset
//
//  The client has no such gate - _zm_perks.csc::init_perk_custom_threads() runs
//  every registered perk's init thread unconditionally - so the client registers
//  both and the server neither. The visionset count is what drives visionset_slot's
//  bit width (_visionset_mgr::finalize_type_clientfields ->
//  getminbitcountfornum( info.size - 1 )), which is why the second mismatch rides
//  along with the first:
//        server: default + zombie_blood                     = 2 -> 1 bit
//        client: default + zombie_blood + zm_perk_divetonuke = 3 -> 2 bits
//  Both log lines follow exactly.
//
//  Registering here restores parity. Safe against double-registration: if a perk
//  machine ever DID spawn on a survival location, _zm_perks::init() would not bail,
//  init_electric_cherry/init_divetonuke would run, and these two lines would become
//  duplicates - but that is also precisely the case where the mismatch would not
//  occur, so the guard to revisit is "did we add perk machines to a loc script?".
//
//  VERIFIED IN GAME 2026-07-31 (14:07 run, Excavation Site / zstandard): the four
//  original fields and electric_cherry_reload_fx are all absent from the mismatch
//  list. Only visionset_slot still mismatched, which is the split-out half below.
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "toplayer",    "sndMudSlow",      14000, 1, "int" );
    registerclientfield( "scriptmover", "element_glow_fx", 14000, 4, "int", undefined, 0 );
    registerclientfield( "scriptmover", "bryce_cake",      14000, 2, "int", undefined, 0 );
    registerclientfield( "scriptmover", "switch_spark",    14000, 1, "int", undefined, 0 );

    // Mirror of _zm_perk_electric_cherry::init_electric_cherry (stock signature).
    registerclientfield( "allplayers", "electric_cherry_reload_fx", 9000, 2, "int" );

    // The divetonuke visionset cannot be registered from here - see
    // zmqol_register_survival_visionset() below.
}

// ============================================================================
//  zmqol_register_survival_visionset
//
//  The second half of the fix above, split out because it CANNOT run in main().
//
//  2026-08-01: the 11:59 run proved the electric_cherry_reload_fx half worked -
//  that field is gone from the mismatch list - but Origins still dropped on:
//        Clientfield 'visionset_slot' in set[toplayer] is not registered with the
//        same bit count as the server : [CLIENT: 2  SERVER : 1]
//  i.e. the vsmgr_register_info call that used to sit at the end of
//  zmqol_register_survival_clientfields() never took.
//
//  Why: registerclientfield is a plain engine builtin with no state behind it,
//  so it works from main(). vsmgr_register_info is not - stock
//  maps\mp\_visionset_mgr.gsc:21-35 reads level.vsmgr[type] and asserts on
//  level.vsmgr_initializing, and BOTH are set up by _visionset_mgr::init(),
//  which runs out of _load::main() - AFTER this mod's main(). The call landed on
//  an undefined level.vsmgr and did nothing.
//
//  init() is inside the legal window: _visionset_mgr::init() has run by then, and
//  level.vsmgr_initializing is only cleared by finalize_clientfields(), which the
//  engine invokes later still via codecallback_finalizeinitialization ->
//  callback( "on_finalize_initialization" ) (_callbacksetup.gsc:19-21).
//
//  Guarded on isdefined so that if that ordering ever changes this degrades to
//  "visionset not registered" rather than a script error that takes out init().
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_register_survival_visionset()
{
    if ( is_classic() )
        return;

    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr["visionset"] ) )
        return;

    // Mirror of _zm_perk_divetonuke::init_divetonuke (stock args: version 9000,
    // priority 400, 5 lerp steps, activate_per_player 1).
    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 5, 1 );
}

init()
{
    zmqol_register_survival_visionset();
    added_weapons();
}

added_weapons()
{
    if (level.script == "zm_tomb")
	{
        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "saritch_zm" );
        include_weapon( "saritch_upgraded_zm", 0 );
        add_zombie_weapon( "saritch_zm", "saritch_upgraded_zm", &"ZOMBIE_WEAPON_SARITCH", 50, "wpck_sidr", "", undefined, 1 );

        include_weapon( "m16_zm" );
        include_weapon( "m16_gl_upgraded_zm", 0 );
        add_zombie_weapon( "m16_zm", "m16_gl_upgraded_zm", &"ZOMBIE_WEAPON_M16", 1200, "burstrifle", "", undefined );

        include_weapon( "barretm82_zm" );
        include_weapon( "barretm82_upgraded_zm", 0);
        add_zombie_weapon( "barretm82_zm", "barretm82_upgraded_zm", &"ZOMBIE_WEAPON_BARRETM82", 50, "sniper", "", undefined );

        include_weapon( "mp5k_zm" );
        include_weapon( "mp5k_upgraded_zm", 0);
        add_zombie_weapon( "mp5k_zm", "mp5k_upgraded_zm", &"ZOMBIE_WEAPON_MP5K", 1000, "smg", "", undefined );

        include_weapon( "tar21_zm" );
        include_weapon( "tar21_upgraded_zm", 0);
        add_zombie_weapon( "tar21_zm", "tar21_upgraded_zm", &"ZOMBIE_WEAPON_TAR21", 50, "wpck_x95l", "", undefined, 1 );

        include_weapon( "rottweil72_zm" );
        include_weapon( "rottweil72_upgraded_zm", 0 );
        add_zombie_weapon( "rottweil72_zm", "rottweil72_upgraded_zm", &"ZOMBIE_WEAPON_ROTTWEIL72", 500, "shotgun", "", undefined );

        include_weapon( "saiga12_zm" );
        include_weapon( "saiga12_upgraded_zm", 0);
        add_zombie_weapon( "saiga12_zm", "saiga12_upgraded_zm", &"ZOMBIE_WEAPON_SAIGA12", 50, "wpck_saiga12", "", undefined, 1 );

        include_weapon( "m1911_zm" );
        include_weapon( "m1911_upgraded_zm", 0);
        add_zombie_weapon( "m1911_zm", "m1911_upgraded_zm", &"ZOMBIE_WEAPON_M1911", 50, "", "", undefined );

        include_weapon( "judge_zm" );
        include_weapon( "judge_upgraded_zm", 0);
        add_zombie_weapon( "judge_zm", "judge_upgraded_zm", &"ZOMBIE_WEAPON_JUDGE", 50, "wpck_judge", "", undefined, 1 );

        include_weapon( "usrpg_zm" );
        include_weapon( "usrpg_upgraded_zm", 0);
        add_zombie_weapon( "usrpg_zm", "usrpg_upgraded_zm", &"ZOMBIE_WEAPON_USRPG", 50, "wpck_rpg", "", undefined, 1 );
    }
}

// Origins weapon-dig fix: if you dig up a weapon whose Pack-a-Punched version
// you already hold, give max ammo instead of swapping. (Merged from the old
// standalone Originspatch2.0.gsc so it only loads on Origins - no unresolved
// externals on other maps.)
custom_swap_weapon( str_weapon, e_player )
{
    if ( isdefined( level.zombie_weapons[str_weapon] ) && isdefined( level.zombie_weapons[str_weapon].upgrade_name ) )
    {
        upgraded_weapon = level.zombie_weapons[str_weapon].upgrade_name;

        if ( e_player hasweapon( upgraded_weapon ) )
        {
            e_player givemaxammo( upgraded_weapon );
            return;
        }
    }

    str_current_weapon = e_player getcurrentweapon();

    if ( str_weapon == "claymore_zm" )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player thread maps\mp\zombies\_zm_weap_claymore::show_claymore_hint( "claymore_purchased" );
            e_player thread maps\mp\zombies\_zm_weap_claymore::claymore_setup();
            e_player thread maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", "grenade" );
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }

        return;
    }

    if ( is_player_valid( e_player ) && !e_player.is_drinking && !is_placeable_mine( str_current_weapon ) && !is_equipment( str_current_weapon ) && level.revive_tool != str_current_weapon && str_current_weapon != "none" && !e_player hacker_active() )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player maps\mp\zm_tomb_dig::take_old_weapon_and_give_new( str_current_weapon, str_weapon );
            return;
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }
    }
}

// Origins native "loose change" reward (prone at a perk machine): exact copy of
// maps\mp\zm_tomb_ee_side::check_for_change but pays 100 instead of the stock 25.
// (Moved here from perkbonuspoints.gsc - it must live in this Origins-only map
// script or the zm_tomb_ee_side reference is unresolved on other maps.)
origins_change_patch()
{
    while ( true )
    {
        self waittill( "trigger", e_player );

        if ( e_player getstance() == "prone" )
        {
            e_player maps\mp\zombies\_zm_score::add_to_player_score( 100 );
            play_sound_at_pos( "purchase", e_player.origin );
            break;
        }

        wait 0.1;
    }
}
