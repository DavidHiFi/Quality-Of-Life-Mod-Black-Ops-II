// ============================================================================
//  quality_of_life.gsc  -  merged root-level QoL/gameplay scripts
// ----------------------------------------------------------------------------
//  Single-file merge of what used to be 17 separate loose root scripts
//  (BO2DD, bo4maxammo, bocw_round, buried_animated_camo + animated_camo,
//  counterszm, custom_summary, deathmachine_powerup, high_round_fix,
//  instant_pap, No_Fog, noperklimit, perkbonuspoints, secretsongsurvival,
//  zm_expanded, zm_hitmarkers, zm_wallbuy_fills_clip,
//  areanotifier) plus the perk pop-up HUD - originally from
//  custom_perkanimuncompiled, REPLACED 2026-07-30 by the "Vanguard Perk
//  Animation" HUD (techboy04gaming / NewMartinLag), which lives in its own
//  section below (search "Vanguard Perk Animation") and no longer hooks
//  give_perk() at all.
//
//  NOTE (2026-07-30): Disable_Fog_Transition was briefly merged into this
//  file, then moved back OUT to the TranZit-scoped script
//  scripts/zm/zm_transit/disable_fog_transition.gsc. Its reference to
//  maps\mp\zm_transit_fx::precache_createfx_fx is resolved by T6 at script
//  LOAD time (not at the replaceFunc call site), so a root script holding it
//  threw "Unresolved external: precache_createfx_fx" on every non-TranZit
//  map even behind an if(mapname == "zm_transit") guard.
//
//  Every function keeps its original body. Only names that collided across
//  files (init, main, onplayerconnect, onplayerspawned, and the two competing
//  get_pack_a_punch_weapon_options overrides) were renamed/merged - see the
//  per-module comments for the mapping back to the original file.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\_demo;
#include maps\mp\_visionset_mgr;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\gametypes_zm\_spectating;
#include maps\mp\gametypes_zm\_weapons;
#include maps\mp\animscripts\zm_death;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zombies\_zm_ai_dogs;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\zombies\_zm_audio_announcer;
#include maps\mp\zombies\_zm_blockers;
#include maps\mp\zombies\_zm_bot;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_clone;
#include maps\mp\zombies\_zm_devgui;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_ffotd;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_gump;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\zombies\_zm_melee_weapon;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_perk_divetonuke;
//  Buried's, but shipped as raw GSC in mod.iwd at maps\mp\zombies\_zm_perk_vulture.gsc
//  so this resolves on every map. Same arrangement as _zm_perk_divetonuke above -
//  see AI_CONTEXT rule 2 on why a map-only path here would crash the other five.
#include maps\mp\zombies\_zm_perk_vulture;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_pers_upgrades;
#include maps\mp\zombies\_zm_pers_upgrades_functions;
#include maps\mp\zombies\_zm_pers_upgrades_system;
#include maps\mp\zombies\_zm_playerhealth;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_sidequests;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_timer;
#include maps\mp\zombies\_zm_tombstone;
#include maps\mp\zombies\_zm_traps;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  main() - combined from: zm_expanded, buried_animated_camo, animated_camo,
//           zm_wallbuy_fills_clip, secretsongsurvival, custom_summary
// ============================================================================
main()
{
    // --- zm_expanded ---
    replaceFunc( maps\mp\zombies\_zm_perks::perks_register_clientfield, ::perks_register_clientfield );
    replaceFunc( maps\mp\zombies\_zm::init_client_flags, ::init_client_flags );
    replaceFunc( maps\mp\zombies\_zm_perks::give_perk, ::give_perk );
    replaceFunc( maps\mp\zombies\_zm_perks::default_vending_precaching, ::default_vending_precaching );

    // --- animated_camo + buried_animated_camo (combined override, see notes on
    //     get_pack_a_punch_weapon_options() below) ---
    replacefunc( maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options, ::get_pack_a_punch_weapon_options );

    // --- zm_wallbuy_fills_clip ---
    replaceFunc( maps\mp\zombies\_zm_weapons::ammo_give, ::new_ammo_give );

    perks();
    zmqol_enable_fire_sale();

    // --- secretsongsurvival ---
    precachemodel( "zombie_teddybear" );

    // --- custom_summary ---
    cs_boot();

    // --- instant_start ---
    // Both hooks are core _zm functions, identical on every map, so this applies
    // to all maps and to solo, custom and co-op games alike.
    replaceFunc( maps\mp\zombies\_zm::onallplayersready, ::onallplayersready_instant );
    replaceFunc( maps\mp\zombies\_zm::fade_out_intro_screen_zm, ::fade_out_intro_screen_zm_instant );

    // --- custom survival start locations (ported from BO2-Reimagined) ---
    // Extends stock struct_class_init() so that, after the map's structs are indexed,
    // any struct_init() registered for the active gametype+location runs. That is how
    // a new start location injects its own player spawns, perk machines and wallbuys
    // into a map that has no map-data for them.
    //
    // Safe from this root script: scripts\zm\replaced\utility only #includes globally
    // available modules (common_scripts\utility, maps\mp\_utility, maps\mp\zombies\_zm*,
    // maps\mp\gametypes_zm\_zm_gametype), so it resolves on every map (AI_CONTEXT rule 2).
    // The per-map hooks that reference map-specific code live in the map subfolder
    // scripts instead. Ordering is safe: stock <map>::main() calls <map>_gamemodes::init()
    // (which registers the locations) before _load::main() calls struct_class_init().
    replaceFunc( common_scripts\utility::struct_class_init, scripts\zm\replaced\utility::struct_class_init );
}

// ============================================================================
//  init() - combined from all 17 modules + the Vanguard Perk Animation
//           connect loop. Each module's original init() body runs from here;
//           per-player connect/spawn loops were renamed with a short module
//           prefix to avoid name collisions (every module used to be its own
//           file, so they could all be called init()/onplayerconnect()/
//           onplayerspawned() without conflict).
// ============================================================================
// ============================================================================
//  zmqol_restore_perk_bottles_on_survival
//
//  🛑 Fixes: drinking a perk from the Wunderfizz on any custom survival location
//     plays no animation and leaves the player permanently unable to sprint,
//     shoot or melee. Reported on Origins/Trenches 2026-08-02.
//
//  THE CHAIN, traced end to end:
//
//  1. maps\mp\zombies\_zm_perks::perk_machine_spawn_init() only spawns a perk
//     machine when a "zm_perk_machine" struct's script_string contains
//     "<ui_gametype>_perks_<start location>". Dumping every shipped mapents with
//     OAT's Unlinker shows NO struct is tagged for any location this mod adds:
//         zm_tomb  - 6 structs, 5 tagged "zclassic_perks_tomb", 1 untagged (the
//                    Pack-a-Punch). Nothing for trenches/excavation_site/church/
//                    crazy_place. (zm_qol ships no zm_tomb mapents at all.)
//         zm_highrise 8/8 tagged, zm_prison 11/11, zm_transit 43/43, zm_buried
//                    14/14 - none tagged for Diner, Tunnel, Power, Docks, or the
//                    three Die Rise locations.
//     So those locations spawn ZERO perk machines.
//
//  2. _zm_perks::init() then does (stock line ~52):
//         vending_triggers = getentarray( "zombie_vending", "targetname" );
//         ...move every "specialty_weapupgrade" trigger OUT of that array...
//         if ( vending_triggers.size < 1 )
//             return;                       <-- BAILS
//     Origins' one untagged machine IS the Pack-a-Punch, so it gets moved out and
//     the array is empty. init() returns early on every custom survival location.
//
//  3. Everything that builds the perk-bottle system lives AFTER that return:
//         level.machine_assets = [];
//         [[ level.custom_vending_precaching ]]();   <- precacheitem() of every
//                                                       "zombie_perk_bottle_*"
//                                                       and the machine_assets
//                                                       lookup table
//
//  4. The Wunderfizz still works and still hands out perks, because
//     _zm_perk_random is a separate system. On grab it calls
//     _zm_perks::perk_give_bottle_begin( perk ), which does:
//         self increment_is_drinking();
//         self disable_player_move_states( 1 );      <- sprint/fire/melee OFF
//         weapon = level.machine_assets["juggernog"].weapon;   <- undefined table
//         self giveweapon( weapon ); self switchtoweapon( weapon );
//     With no weapon to switch to, "weapon_change_complete" never fires, so
//     _zm_perk_random::grab_check() blocks forever on its waittill_any_return and
//     perk_give_bottle_end() - the ONLY caller of enable_player_move_states() -
//     never runs. That is the reported soft-lock exactly.
//
//  THE FIX
//
//  Do what the bail skipped: create level.machine_assets and run the map's own
//  vending precache. custom_vending_precaching touches no entities - it is purely
//  precacheitem/precachemodel/loadfx plus building machine_assets - so calling it
//  without any machines present is safe. Its first block also walks
//  level._custom_perks[*].precache_func, which is what precaches
//  "zombie_perk_bottle_cherry" for Electric Cherry (specialty_grenadepulldeath is
//  in Origins' Wunderfizz rotation but has no case in perk_give_bottle_begin's
//  switch - it resolves through level._custom_perks[perk].perk_bottle instead).
//
//  Root script on purpose: the same bail hits Origins x4, Die Rise x3, Docks,
//  Diner, Tunnel and Power. Nothing referenced here is map-specific -
//  level.custom_vending_precaching is a level var and _zm_perks is globally safe
//  per AI_CONTEXT rule 2 - so this is legal in quality_of_life.gsc.
//
//  Guards:
//    - is_classic() -> never touches a classic map, where init() does not bail.
//    - isdefined( level.machine_assets ) -> no-ops wherever _zm_perks::init()
//      completed normally, so any location that already worked is untouched. This
//      is also what makes it safe if perk machines are ever added to a loc script
//      or the mapents get patched: the fix simply stops applying.
//    - level.custom_vending_precaching is defaulted here because stock only
//      defaults it AFTER the bail; maps that do not set it themselves would
//      otherwise have it undefined. (Origins sets it in zm_tomb::main().)
//
//  Must run in init(): level.custom_vending_precaching and level._custom_perks are
//  populated by the map's main(), which runs after this mod's main(). init() is
//  still inside the precache window - the precacheitem() calls immediately below
//  in this same function have always worked.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_restore_perk_bottles_on_survival()
{
    if ( is_classic() )
        return;

    // _zm_perks::init() got past its bail - nothing to repair.
    if ( isdefined( level.machine_assets ) )
        return;

    level.machine_assets = [];

    if ( !isdefined( level.custom_vending_precaching ) )
        level.custom_vending_precaching = maps\mp\zombies\_zm_perks::default_vending_precaching;

    [[ level.custom_vending_precaching ]]();
}

init()
{
    zmqol_restore_perk_bottles_on_survival();
    zmqol_register_divetonuke_visionset();
    zmqol_register_vulture_visionset();
    zmqol_dev_commands();
    level thread zmqol_credits_banner();

    // --- zm_expanded: weapon precache + weapon-limit monitor hook ---
    precacheitem( "uzi_zm" );
    precacheitem( "uzi_upgraded_zm" );
    precacheitem( "thompson_zm" );
    precacheitem( "thompson_upgraded_zm" );
    precacheitem( "ak47_zm" );
    precacheitem( "ak47_upgraded_zm" );
    precacheitem( "mp40_stalker_zm" );
    precacheitem( "mp40_stalker_upgraded_zm" );
    precacheitem( "scar_zm" );
    precacheitem( "scar_upgraded_zm" );
    precacheitem( "mg08_zm" );
    precacheitem( "mg08_upgraded_zm" );
    precacheitem( "minigun_alcatraz_zm" );
    precacheitem( "minigun_alcatraz_upgraded_zm" );
    precacheitem( "evoskorpion_zm" );
    precacheitem( "evoskorpion_upgraded_zm" );
    precacheitem( "hk416_zm" );
    precacheitem( "hk416_upgraded_zm" );
    precacheitem( "ksg_zm" );
    precacheitem( "ksg_upgraded_zm" );
    precacheitem( "pdw57_zm" );
    precacheitem( "pdw57_upgraded_zm" );
    precacheitem( "mp44_zm" );
    precacheitem( "mp44_upgraded_zm" );
    precacheitem( "ballista_zm" );
    precacheitem( "ballista_upgraded_zm" );
    precacheitem( "rnma_zm" );
    precacheitem( "rnma_upgraded_zm" );
    precacheitem( "an94_zm" );
    precacheitem( "an94_upgraded_zm" );
    precacheitem( "lsat_zm" );
    precacheitem( "lsat_upgraded_zm" );
    precacheitem( "svu_zm" );
    precacheitem( "svu_upgraded_zm" );
    precacheitem( "c96_zm" );
    precacheitem( "c96_upgraded_zm" );

    // Tranzit weapons
    precacheitem( "beretta93r_extclip_zm" );
    precacheitem( "beretta93r_extclip_upgraded_zm" );
    precacheitem( "ak74u_extclip_zm" );
    precacheitem( "ak74u_extclip_upgraded_zm" );
    precacheitem( "qcw05_zm" );
    precacheitem( "qcw05_upgraded_zm" );
    precacheitem( "sf_qcw05_upgraded_zm" );
    precacheitem( "type95_zm" );
    precacheitem( "type95_upgraded_zm" );
    precacheitem( "gl_type95_zm" );
    precacheitem( "xm8_zm" );
    precacheitem( "xm8_upgraded_zm" );
    precacheitem( "gl_xm8_zm" );
    precacheitem( "rpd_zm" );
    precacheitem( "rpd_upgraded_zm" );
    precacheitem( "python_zm" );
    precacheitem( "python_upgraded_zm" );
    precacheitem( "saritch_zm" );
    precacheitem( "saritch_upgraded_zm" );
    precacheitem( "dualoptic_saritch_upgraded_zm" );
    precacheitem( "m16_zm" );
    precacheitem( "m16_gl_upgraded_zm" );
    precacheitem( "gl_m16_upgraded_zm" );
    precacheitem( "srm1216_zm" );
    precacheitem( "srm1216_upgraded_zm" );
    precacheitem( "hamr_zm" );
    precacheitem( "hamr_upgraded_zm" );
    precacheitem( "kard_zm" );
    precacheitem( "kard_upgraded_zm" );
    precacheitem( "m32_zm" );
    precacheitem( "m32_upgraded_zm" );
    precacheitem( "barretm82_zm" );
    precacheitem( "barretm82_upgraded_zm" );
    precacheitem( "m1911_zm" );
    precacheitem( "m1911_upgraded_zm" );
    precacheitem( "m1911lh_upgraded_zm" );
    level.player_too_many_weapons_monitor_func = ::player_too_many_weapons_monitor;

    // --- BO2DD ---
    level thread bo2dd_onplayerconnect();

    // --- bo4maxammo ---
    level thread bo4maxammo_onplayerconnect();

    // --- bocw_round ---
    precacheshader( "hud_chalk_1" );
    precacheshader( "hud_chalk_2" );
    precacheshader( "hud_chalk_3" );
    precacheshader( "hud_chalk_4" );
    precacheshader( "hud_chalk_5" );
    level.round_think_func = ::round_think;
    thread round_hud();

    level thread zmqol_spawn_baseline_probe();   // DIAGNOSTIC - remove once Buried spawns

    // --- counterszm ---
    precacheshader( "specialty_chugabud_zombies" );
    precacheshader( "specialty_electric_cherry_zombie" );
    precacheshader( "specialty_vulture_zombies" );
    precacheshader( "minimap_icon_chugabud" );
    precacheshader( "minimap_icon_electric_cherry" );
    precacheshader( "damage_feedback" );
    precacheshader( "zm_riotshield_tomb_icon" );
    precacheshader( "zm_riotshield_hellcatraz_icon" );
    precacheshader( "menu_mp_fileshare_custom" );
    level.navcards = undefined;
    level thread counters_onplayerconnect();

    // --- deathmachine_powerup ---
    level thread dm_onplayerconnect();
    precachemodel( "zombie_pickup_minigun" );
    precacheitem( "deathmachine_zm" );
    level.deathmachine_weapon = "deathmachine_zm";
    level.deathmachine_duration = getdvarintdefault( "sv_deathmachine_duration", 30 );
    include_zombie_powerup( "deathmachine" );
    add_zombie_powerup( "deathmachine", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", ::drop_deathmachine, 0, 0, 0 );
    powerup_set_can_pick_up_in_last_stand( "deathmachine", 0 );
    maps\mp\zombies\_zm_spawner::register_zombie_damage_callback( ::deathmachine_damage_response );

    // --- high_round_fix ---
    setdvar( "player_backSpeedScale", 1 );
    setdvar( "player_strafeSpeedScale", 1 );
    setdvar( "player_sprintStrafeSpeedScale", 1 );
    level thread zombie_health();
    level thread hrf_onplayerconnect();

    // --- instant_pap ---
    create_dvar( "pap_price", 5000 );
    create_dvar( "repap_price", 2000 );
    level.zombiemode_reusing_pack_a_punch = 1;
    level thread setup_pap_attachments();
    level thread new_pap_trigger();

    // --- No_Fog ---
    // (Disable_Fog_Transition moved OUT of this file on 2026-07-30 - it now
    //  lives at scripts/zm/zm_transit/disable_fog_transition.gsc; see the
    //  note at the top of this file for why a root script can't hold it.)
    level thread nofog_onplayerconnect();

    // --- noperklimit ---
    level thread remove_perk_limit();
    level thread perklimit_onplayerconnect();

    // --- perkbonuspoints (Origins/zm_tomb has this natively; see zm_tomb.gsc) ---
    if ( !isdefined( level.script ) || level.script != "zm_tomb" )
        level thread pbp_onplayerconnect();

    // --- secretsongsurvival ---
    level thread setteddybears();
    level thread sss_onplayerconnect();

    // --- zm_hitmarkers ---
    level thread init_hitmarkers();

    // --- areanotifier ---
    level thread an_onplayerconnect();

    // --- Vanguard Perk Animation (perk pop-up HUD; added 2026-07-30, replaces
    //     the old custom_perkanimuncompiled perkHUD). Icon shaders precached
    //     here because the pop-up now shows an icon + name + description for
    //     every perk; the chugabud / electric cherry / vulture icons are
    //     already precached up in the counterszm block.
    //     (Upstream's init() also printed a "created by techboy04gaming"
    //     iprintln at match start - REMOVED 2026-07-30 per user request;
    //     author credit stays in the source comments at the module below.) ---
    precacheshader( "specialty_juggernaut_zombies" );
    precacheshader( "specialty_quickrevive_zombies" );
    precacheshader( "specialty_fastreload_zombies" );
    precacheshader( "specialty_doubletap_zombies" );
    precacheshader( "specialty_marathon_zombies" );
    precacheshader( "specialty_divetonuke_zombies" );
    precacheshader( "specialty_ads_zombies" );
    precacheshader( "specialty_additionalprimaryweapon_zombies" );
    precacheshader( "specialty_tombstone_zombies" );
    level thread vpa_onplayerconnect();

    // ".dm" used to be its own listener here. It is now one of the power-up chat
    // commands in zmqol_dev_command_listener() - see zmqol_powerup_alias(). Two
    // listeners both consuming "say" would have spawned two Death Machines.
}

// ============================================================================
//  BO2DD  (was BO2DD.gsc)
// ============================================================================
bo2dd_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread bo2dd_onplayerspawned();
        player setclientdvar( "r_lodBiasRigid", "-1000" );
        player setclientdvar( "r_lodBiasSkinned", "-1000" );
        player setclientdvar( "r_dof_enable", "0" );
        player setclientdvar( "r_lodScaleSkinned", "1" );
        player setclientdvar( "r_lodScaleRigid", "1" );
    }
}

bo2dd_onplayerspawned()
{
    self endon( "disconnect" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  bo4maxammo  (was bo4maxammo.gsc)
// ============================================================================
bo4maxammo_onplayerconnect()
{
    level endon("game_ended");
    for(;;)
    {
        level waittill("connected", player);
        player thread bo4maxammo_onplayerspawned();
    }
}

bo4maxammo_onplayerspawned()
{
    self endon("disconnect");
    level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
        if(!isDefined(level.maC1))
        {
            wait 5;
            level.maC1 = "DONE";
    		replaceFunc(maps\mp\zombies\_zm_powerups::full_ammo_powerup,::new_full_ammo_powerup);
        }
    }
}

new_full_ammo_powerup( drop_item, player )
{
    players = get_players( player.team );
    if ( isdefined( level._get_game_module_players ) ){
        players = [[ level._get_game_module_players ]]( player );
    }
    for ( i = 0; i < players.size; i++ )
    {
        if ( players[i] maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
            continue;
        primary_weapons = players[i] getweaponslist( 1 );
        players[i] notify( "zmb_max_ammo" );
        players[i] notify( "zmb_lost_knife" );
        players[i] notify( "zmb_disable_claymore_prompt" );
        players[i] notify( "zmb_disable_spikemore_prompt" );
        for ( x = 0; x < primary_weapons.size; x++ )
        {
        	curWeapon = primary_weapons[x];
            if ( level.headshots_only && is_lethal_grenade(curWeapon) ){
                continue;
            }
            if ( isDefined( level.zombie_include_equipment ) && isDefined( level.zombie_include_equipment[curWeapon] ) ){
                continue;
            }
            if ( isDefined( level.zombie_weapons_no_max_ammo ) && isDefined( level.zombie_weapons_no_max_ammo[curWeapon] ) ){
                continue;
            }
            if ( players[i] hasweapon( curWeapon ) ){
                players[i] givemaxammo( curWeapon );
                players[i] setweaponammoclip( curWeapon, 300);
            }
        }
    }
    level thread full_ammo_on_hud( drop_item, player.team );
}

// ============================================================================
//  bocw_round  (was bocw_round.gsc)
// ============================================================================
round_hud()
{
    level waittill( "start_of_round" );
    switch ( level.round_number )
    {
        case 1:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_1", 50, 50 );
            break;
        case 2:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_2", 50, 50 );
            break;
        case 3:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_3", 50, 50 );
            break;
        case 4:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_4", 50, 50 );
            break;
        case 5:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_5", 50, 50 );
            break;
        default:
            roundcounter destroyelem();
            roundcounter = createserverfontstring( "default", 25 );
            roundcounter setvalue( level.round_number );
            break;
    }
    roundcounter.horzalign = "right";
    roundcounter.vertalign = "top";
    roundcounter.x = 25;
    roundcounter.y = -10;
    roundcounter.alpha = 0;
    roundcounter.color = ( 1, 1, 0.25 );
    roundcounter fadeovertime( 0.5 );
    roundcounter.color = ( 0.75, 0, 0 );
    roundcounter.alpha = 1;
    roundcounter.hidewheninmenu = 1;
    while ( true )
    {
        level waittill( "end_of_round" );
        roundcounter.color = ( 1, 1, 0.25 );
        roundcounter moveovertime( 0.3 );
        roundcounter scaleovertime( 0.3, 80, 80 );
        roundcounter.horzalign = "center";
        if ( level.round_number == 2 || level.round_number == 3 )
            roundcounter.x = 7 + level.round_number;
        else
            roundcounter.x = 0;
        wait 0.3;
        roundcounter fadeovertime( 0.3 );
        roundcounter.alpha = 0;
        wait 0.4;
        switch ( level.round_number )
        {
            case 1:
                roundcounter setshader( "hud_chalk_1", 80, 80 );
                break;
            case 2:
                roundcounter setshader( "hud_chalk_2", 80, 80 );
                break;
            case 3:
                roundcounter setshader( "hud_chalk_3", 80, 80 );
                break;
            case 4:
                roundcounter setshader( "hud_chalk_4", 80, 80 );
                break;
            case 5:
                roundcounter setshader( "hud_chalk_5", 80, 80 );
                break;
            default:
                roundcounter destroyelem();
                roundcounter = createserverfontstring( "default", 25 );
                roundcounter setvalue( level.round_number );
                roundcounter.color = ( 1, 1, 0.25 );
                break;
        }
        roundcounter fadeovertime( 0.8 );
        roundcounter.alpha = 1;
        roundcounter.color = ( 0.75, 0, 0 );
        wait 2.5;
        roundcounter scaleovertime( 0.3, 50, 50 );
        roundcounter moveovertime( 0.3 );
        roundcounter.horzalign = "right";
        roundcounter.x = 25;
        roundcounter.hidewheninmenu = 1;
        level waittill( "between_round_over" );
    }
}

round_think( restart )
{
    if ( !isdefined( restart ) )
        restart = 0;
    level endon( "end_round_think" );
    if ( !is_true( restart ) )
    {
        if ( isdefined( level.initial_round_wait_func ) )
            [[ level.initial_round_wait_func ]]();
        players = get_players();
        foreach ( player in players )
        {
            if ( is_true( player.hostmigrationcontrolsfrozen ) )
                player freezecontrols( 0 );
            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
        }
    }
    for (;;)
    {
        maxreward = 50 * level.round_number;
        if ( maxreward > 500 )
            maxreward = 500;
        level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
        level.pro_tips_start_time = gettime();
        level.zombie_last_run_time = gettime();
        if ( isdefined( level.zombie_round_change_custom ) )
            [[ level.zombie_round_change_custom ]]();
        else
        {
            level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );
            round_one_up();
        }
        maps\mp\zombies\_zm_powerups::powerup_round_start();
        players = get_players();
        array_thread( players, ::rebuild_barrier_reward_reset );
        if ( !is_true( level.headshots_only ) && !restart )
            level thread award_grenades_for_survivors();
        level.round_start_time = gettime();
        while ( level.zombie_spawn_locations.size <= 0 )
            wait 0.1;
        level thread [[ level.round_spawn_func ]]();
        level notify( "start_of_round" );
        recordzombieroundstart();
        players = getplayers();
        for ( index = 0; index < players.size; index++ )
        {
            zonename = players[index] get_current_zone();
            if ( isdefined( zonename ) )
                players[index] recordzombiezone( "startingZone", zonename );
        }
        if ( isdefined( level.round_start_custom_func ) )
            [[ level.round_start_custom_func ]]();
        [[ level.round_wait_func ]]();
        level.first_round = 0;
        level notify( "end_of_round" );
        level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_end" );
        uploadstats();
        if ( isdefined( level.round_end_custom_logic ) )
            [[ level.round_end_custom_logic ]]();
        players = get_players();
        if ( is_true( level.no_end_game_check ) )
        {
            level thread last_stand_revive();
            level thread spectators_respawn();
        }
        else if ( players.size != 1 )
            level thread spectators_respawn();
        players = get_players();
        timer = level.zombie_vars["zombie_spawn_delay"];
        if ( timer > 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
        else if ( timer < 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = 0.08;
        if ( level.gamedifficulty == 0 )
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier_easy"];
        else
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];
        level.round_number++;
        matchutctime = getutc();
        players = get_players();
        foreach ( player in players )
        {
            if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
                player maps\mp\zombies\_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );
            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            player maps\mp\zombies\_zm_stats::update_playing_utc_time( matchutctime );
        }
        check_quickrevive_for_hotjoin();
        level round_over();
        level notify( "between_round_over" );
        restart = 0;
    }
}

// ============================================================================
//  animated_camo + buried_animated_camo  (COMBINED)
// ----------------------------------------------------------------------------
//  Both original files replaced the SAME stock function
//  (_zm_weapons::get_pack_a_punch_weapon_options) with a function of the same
//  name but different bodies. Two replaceFunc calls on one stock target can't
//  both take effect, so only one of the two was ever actually live - this
//  merge combines both authors' intent into a single override instead of
//  silently keeping one and dropping the other:
//    - animated_camo.gsc: camo 40 on zm_prison, zm_buried, or zm_tomb.
//    - buried_animated_camo.gsc: on zm_buried specifically, camo 40 EXCEPT
//      slowgun/rnma stay at 39.
//  Combined below: zm_buried uses the more specific slowgun/rnma exception;
//  zm_prison and zm_tomb keep flat camo 40; every other map is unaffected
//  (camo 39, same as both originals agreed).
// ============================================================================
get_pack_a_punch_weapon_options( weapon )
{
    if ( !isdefined( self.pack_a_punch_weapon_options ) )
        self.pack_a_punch_weapon_options = [];
    if ( !is_weapon_upgraded( weapon ) )
        return self calcweaponoptions( 0, 0, 0, 0 );
    if ( isdefined( self.pack_a_punch_weapon_options[weapon] ) )
        return self.pack_a_punch_weapon_options[weapon];
    smiley_face_reticle_index = 1;
    base = get_base_name( weapon );
    camo_index = 39;

    //  anim_pap_camo_buried / _mob / _origins, all defaulting to 1 so the
    //  behaviour is unchanged unless someone turns one off at the console.
    //  Camo 40 is the animated one, 39 the static default.
    if ( level.script == "zm_buried" )
    {
        if ( base == "slowgun_zm" || base == "slowgun_upgraded_zm" || ( base == "rnma_zm" || base == "rnma_upgraded_zm" ) )
            camo_index = 39;
        else if ( getdvarintdefault( "anim_pap_camo_buried", 1 ) )
            camo_index = 40;
    }
    else if ( level.script == "zm_prison" )
    {
        if ( getdvarintdefault( "anim_pap_camo_mob", 1 ) )
            camo_index = 40;
    }
    else if ( level.script == "zm_tomb" )
    {
        if ( getdvarintdefault( "anim_pap_camo_origins", 1 ) )
            camo_index = 40;
    }
    lens_index = randomintrange( 0, 6 );
    reticle_index = randomintrange( 0, 16 );
    reticle_color_index = randomintrange( 0, 6 );
    plain_reticle_index = 16;
    r = randomint( 10 );
    use_plain = r < 3;
    if ( base == "saritch_upgraded_zm" )
        reticle_index = smiley_face_reticle_index;
    else if ( use_plain )
        reticle_index = plain_reticle_index;
    scary_eyes_reticle_index = 8;
    purple_reticle_color_index = 3;
    if ( reticle_index == scary_eyes_reticle_index )
        reticle_color_index = purple_reticle_color_index;
    letter_a_reticle_index = 2;
    pink_reticle_color_index = 6;
    if ( reticle_index == letter_a_reticle_index )
        reticle_color_index = pink_reticle_color_index;
    letter_e_reticle_index = 7;
    green_reticle_color_index = 1;
    if ( reticle_index == letter_e_reticle_index )
        reticle_color_index = green_reticle_color_index;
    self.pack_a_punch_weapon_options[weapon] = self calcweaponoptions( camo_index, lens_index, reticle_index, reticle_color_index );
    return self.pack_a_punch_weapon_options[weapon];
}

// ============================================================================
//  counterszm  (was counterszm.gsc)
// ============================================================================
counters_onplayerconnect()
{
    while ( true )
    {
        level waittill( "connected", player );
        player thread counters_onplayerspawned();
    }
}

counters_onplayerspawned()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    first_spawn = 1;
    while ( true )
    {
        self waittill( "spawned_player" );
        if ( is_true( first_spawn ) )
        {
            first_spawn = 0;
            self thread timer();
            self thread zombiecounter();
            self thread shield_hud();
            self thread first_spawn();
        }
    }
}

// ============================================================================
//  qol_health_hud_create / _destroy  -  ALLOCATE ON DEMAND
//
//  🛑 THIS IS A CLIENT HUD-ELEMENT BUDGET FIX, not a cosmetic change.
//  A client has a fixed hudelem allowance. These five were created once at
//  spawn and kept FOREVER, with hud_health_bar only ever writing their .alpha -
//  so switching the health bar off hid it but freed nothing, and the documented
//  workaround ("set hud_health_bar 0 to free 5 slots") did not actually work.
//
//  What that budget starves is anything stock creates ON DEMAND. Origins'
//  generator capture ring is the visible case: it is built when you walk up to
//  a generator and silently is not built when the pool is empty, which is why
//  some generators show the ring and others do not - it was never per-generator.
//
//  qol_opt_zone_hud() in qol_options.gsc already worked this way; the health bar
//  simply never got the same treatment. Both helpers are idempotent so the loop
//  can call them every tick without churn.
// ============================================================================
qol_health_hud_create()
{
    if ( isdefined( self.qol_hud_health ) && self.qol_hud_health.size == 5 )
        return;

    healthvalue = self createfontstring( "default", 1 );
    healthvalue setpoint( "RIGHT", "BOTTOM_LEFT", 58, 18 );
    healthvalue.hidewheninmenu = 1;
    healthvalue.sort = -1;
    healthbar_bg = newclienthudelem( self );
    healthbar_bg.x = 0;
    healthbar_bg.y = 0;
    healthbar_bg setshader( "white", 104, 5 );
    healthbar_bg.alignx = "left";
    healthbar_bg.aligny = "middle";
    healthbar_bg.horzalign = "left";
    healthbar_bg.vertalign = "bottom";
    healthbar_bg.x = healthbar_bg.x + -45;
    healthbar_bg.y = healthbar_bg.y + 7;
    healthbar_bg.color = ( 0, 0, 0 );
    healthbar_bg.alpha = 0.5;
    healthbar_bg.hidewheninmenu = 1;
    healthbar_bg.sort = -1;
    healthbar = newclienthudelem( self );
    healthbar.x = 0;
    healthbar.y = 0;
    healthbar setshader( "progress_bar_fill", 100, 3 );
    healthbar.alignx = "left";
    healthbar.aligny = "middle";
    healthbar.horzalign = "left";
    healthbar.vertalign = "bottom";
    healthbar.x = healthbar.x + -43;
    healthbar.y = healthbar.y + 7;
    healthbar.hidewheninmenu = 1;
    healthbar.width = 100;
    healthbar.sort = 0;
    playername = self createfontstring( "default", 1 );
    playername setpoint( "LEFT", "BOTTOM_LEFT", -45, 18 );
    playername settext( self.name );
    playername.hidewheninmenu = 1;
    healthbar_mas = self createfontstring( "default", 1.5 );
    healthbar_mas setpoint( "LEFT", "BOTTOM_LEFT", 12, 17 );
    healthbar_mas settext( "+" );
    healthbar_mas.hidewheninmenu = 1;

    self.qol_hud_health = [];
    self.qol_hud_health[0] = healthvalue;
    self.qol_hud_health[1] = healthbar_bg;
    self.qol_hud_health[2] = healthbar;
    self.qol_hud_health[3] = playername;
    self.qol_hud_health[4] = healthbar_mas;
}

qol_health_hud_destroy()
{
    if ( !isdefined( self.qol_hud_health ) )
        return;

    for ( i = 0; i < self.qol_hud_health.size; i++ )
    {
        if ( isdefined( self.qol_hud_health[i] ) )
            self.qol_hud_health[i] destroy();
    }

    self.qol_hud_health = undefined;
}

first_spawn()
{
    self._health_overlay.color = ( 0.4, 0, 0 );
    self endon( "disconnect" );
    flag_wait( "initial_blackscreen_passed" );

    while ( true )
    {
        //  🛑 hud_health_bar / hud_all are checked HERE, not in qol_options'
        //  watcher. The restore-alpha block below would undo a console toggle
        //  within a frame, which is why there is exactly one owner.
        //
        //  The difference from every version before v1.53.0: when the bar is
        //  off the five elements are DESTROYED, not merely faded, so the slots
        //  go back to the pool for things like Origins' generator ring.
        if ( !( getdvarintdefault( "hud_all", 0 ) || getdvarintdefault( "hud_health_bar", 1 ) ) )
        {
            self qol_health_hud_destroy();
            wait 0.25;
            continue;
        }

        self qol_health_hud_create();

        healthvalue   = self.qol_hud_health[0];
        healthbar_bg  = self.qol_hud_health[1];
        healthbar     = self.qol_hud_health[2];
        playername    = self.qol_hud_health[3];
        healthbar_mas = self.qol_hud_health[4];

        if ( isdefined( self.e_afterlife_corpse ) )
        {
            healthbar.alpha = 0;
            healthvalue.alpha = 0;
            playername.alpha = 0;
            healthbar_bg.alpha = 0;
            healthbar_mas.alpha = 0;
            wait 0.05;
            continue;
        }
        if ( healthbar_mas.alpha == 0 || healthbar_bg.alpha == 0 || ( playername.alpha == 0 || healthvalue.alpha == 0 ) || healthbar.alpha == 0 )
        {
            healthbar.alpha = 1;
            healthvalue.alpha = 1;
            playername.alpha = 1;
            healthbar_bg.alpha = 0.5;
            healthbar_mas.alpha = 1;
        }
        if ( isdefined( self.health ) )
            healthbar setshader( "progress_bar_fill", int( 100 * ( self.health / self.maxhealth ) ), 3 );
        if ( isdefined( self.health ) )
            healthvalue settext( self.health + ( "^8 / " + self.maxhealth ) );
        //  hud_color_health, handled HERE and nowhere else. This loop repaints
        //  the tier colour every 0.1s, so any other thread tinting these
        //  elements loses the race - which is exactly what put a white border on
        //  the bar in v1.37.0.
        //
        //  🛑 healthbar_bg is never recoloured either way. It is the dark
        //  backing plate behind the bar, not a readout.
        str_hc = getdvar( "hud_color_health" );

        if ( str_hc != "1 1 1" && str_hc != "" )
        {
            a_hc = strtok( str_hc, " " );

            if ( isdefined( a_hc ) && a_hc.size == 3 )
            {
                v_hc = ( string_to_float( a_hc[0] ), string_to_float( a_hc[1] ), string_to_float( a_hc[2] ) );
                healthvalue.color = v_hc;
                healthbar_mas.color = v_hc;
                healthbar.color = v_hc;
            }

            wait 0.1;
            continue;
        }
        if ( self.health >= 71 && self.health <= self.maxhealth )
        {
            healthvalue.color = ( 0, 1, 0.5 );
            healthbar_mas.color = ( 0, 1, 0.5 );
            healthbar.color = ( 0, 1, 0.5 );
        }
        else if ( self.health >= 50 && self.health <= 70 )
        {
            healthvalue.color = ( 1, 1, 0 );
            healthbar_mas.color = ( 1, 1, 0 );
            healthbar.color = ( 1, 1, 0 );
        }
        else if ( self.health >= 25 && self.health <= 49 )
        {
            healthvalue.color = ( 1, 0.5, 0 );
            healthbar_mas.color = ( 1, 0.5, 0 );
            healthbar.color = ( 1, 0.5, 0 );
        }
        else if ( self.health >= 0 && self.health <= 24 )
        {
            healthvalue.color = ( 0.5, 0, 0 );
            healthbar_mas.color = ( 0.5, 0, 0 );
            healthbar.color = ( 0.5, 0, 0 );
        }
        wait 0.1;
    }
}

timer()
{
    self endon( "disconnect" );
    timer = newclienthudelem( self );
    timer.alignx = "center";
    timer.aligny = "top";
    timer.horzalign = "center";
    timer.vertalign = "user_top";
    timer.x = timer.x - 1;
    timer.y = timer.y + -2;
    timer.fontscale = 1.4;
    timer.alpha = 0;
    timer.hidewheninmenu = 1;
    flag_wait( "initial_blackscreen_passed" );
    timer.alpha = 1;
    timer settimerup( 0 );

    //  Stashed for qol_options::qol_opt_hud_watcher, which is what hud_timer /
    //  hud_all / hud_color act on. Keeping the element here and only toggling
    //  it from there is deliberate: it means the console options drive the HUD
    //  the user already has rather than drawing a second one over the top.
    self.qol_hud_timer = timer;
}

zombiecounter()
{
    self endon( "disconnect" );
    level endon( "end_game" );
    flag_wait( "initial_blackscreen_passed" );
    self.zombietext = createfontstring( "hudsmall", 1.2 );
    self.zombietext setpoint( "LEFT", "BOTTOM_LEFT", -45, -7 );
    self.zombietext.hidewheninmenu = 1;
    while ( true )
    {
        self.zombietext setvalue( get_round_enemy_array().size + level.zombie_total );
        if ( get_round_enemy_array().size + ( level.zombie_total != 0 ) )
            self.zombietext.label = &"Zombies: ^1";
        else
            self.zombietext.label = &"Zombies: ^1";
        wait 0.25;
    }
}

shield_hud()
{
    self endon( "disconnect" );
    flag_wait( "initial_blackscreen_passed" );
    shield_text = self createprimaryprogressbartext();
    shield_text setpoint( "CENTER", "CENTER", 275, 225 );
    shield_text.hidewheninmenu = 1;
    shield_hud = newclienthudelem( self );
    shield_hud.alignx = 240;
    shield_hud.aligny = 460;
    shield_hud.horzalign = "center";
    shield_hud.vertalign = "center";
    shield_hud.x = 240;
    shield_hud.y = 460;
    shield_hud.alpha = 0;
    shield_hud.hidewheninmenu = 1;
    if ( getdvar( "mapname" ) == "zm_transit" )
        shield_hud setshader( "damage_feedback", 15, 15 );
    if ( getdvar( "mapname" ) == "zm_tomb" )
        shield_hud setshader( "zm_riotshield_tomb_icon", 15, 15 );
    if ( getdvar( "mapname" ) == "zm_prison" )
        shield_hud setshader( "zm_riotshield_hellcatraz_icon", 15, 15 );
    for (;;)
    {
        if ( self hasweapon( "riotshield_zm" ) || self hasweapon( "alcatraz_shield_zm" ) || self hasweapon( "tomb_shield_zm" ) )
        {
            shield_text.alpha = 1;
            shield_hud.alpha = 1;
        }
        else
        {
            shield_text.alpha = 0;
            shield_hud.alpha = 0;
        }
        shield_text setvalue( 2300 - self.shielddamagetaken );
        wait 0.05;
        if ( self.shielddamagetaken >= 2300 )
            shield_text.alpha = 0;
    }
}

// ============================================================================
//  custom_summary  (was custom_summaryuncompiled.gsc, by Astroolean)
// ----------------------------------------------------------------------------
//  Dvars (console / config):
//    set cs_enabled 1          // 1 = enabled, 0 = disabled
//    set cs_x 0                // Horizontal offset from center
//    set cs_y -60              // Vertical offset from center
//    set cs_seconds 10         // How long the summary stays visible (seconds)
//    set cs_cooldown_ms 2500   // Minimum time between summaries (milliseconds)
// ============================================================================
cs_boot()
{
    // One instance only
    if (isDefined(level.cs_loaded) && level.cs_loaded)
        return;
    level.cs_loaded = 1;

    // Try to disable the older "CRS" script if it was installed before
    setDvar("ct_round_summary", "0");
    setDvar("ct_rs_show_session_best", "0");
    setDvar("ct_rs_show_round_pb", "0");

    // Defaults
    if (getDvar("cs_enabled") == "") setDvar("cs_enabled", "1");
    if (getDvar("cs_x") == "") setDvar("cs_x", "0");
    if (getDvar("cs_y") == "") setDvar("cs_y", "-60");
    if (getDvar("cs_seconds") == "") setDvar("cs_seconds", "10");
    if (getDvar("cs_cooldown_ms") == "") setDvar("cs_cooldown_ms", "2500");

    level thread cs_on_connect();
}

cs_on_connect()
{
    for (;;)
    {
        level waittill("connected", player);

        // Best-effort: tell older scripts to stop their popup threads
        player notify("crs_summary_kill");
        player notify("cs_popup_kill");
        player notify("cs_popup_kill2");

        // Best-effort: destroy any old HUD elements the older scripts created
        player thread cs_kill_legacy_hud();
        player thread cs_player_thread();
    }
}

cs_kill_legacy_hud()
{
    self endon("disconnect");

    // Run a few times in case the old popup was mid-fade
    for (i = 0; i < 10; i++)
    {
        if (isDefined(self.crs_title)) self.crs_title destroy();
        if (isDefined(self.crs_line2)) self.crs_line2 destroy();
        if (isDefined(self.crs_line3)) self.crs_line3 destroy();
        if (isDefined(self.crs_line4)) self.crs_line4 destroy();
        if (isDefined(self.cs_title_old)) self.cs_title_old destroy();
        if (isDefined(self.cs_line2_old)) self.cs_line2_old destroy();
        if (isDefined(self.cs_line3_old)) self.cs_line3_old destroy();
        if (isDefined(self.cs_line4_old)) self.cs_line4_old destroy();
        if (isDefined(self.crs_summary)) self.crs_summary destroy();
        wait 0.1;
    }
}

cs_player_thread()
{
    self endon("disconnect");

    if (isDefined(self.cs_running) && self.cs_running)
        return;
    self.cs_running = 1;

    flag_wait("initial_blackscreen_passed");

    while (!isDefined(level.round_number))
        wait 0.1;

    self.cs_last_round = level.round_number;
    self.cs_round_start_time = getTime();
    self.cs_kills_start = cs_get_kills();

    // Prevent instant spam during early init
    self.cs_last_popup_time = getTime();

    cs_hud_create();

    for (;;)
    {
        if (!getDvarInt("cs_enabled"))
        {
            wait 0.5;
            continue;
        }

        r = level.round_number;
        if (r != self.cs_last_round && r > 1)
            cs_on_round_change(r);

        wait 0.2;
    }
}

cs_on_round_change(new_round)
{
    kills_now = cs_get_kills();
    completed_round = self.cs_last_round;
    round_time = int((getTime() - self.cs_round_start_time) / 1000);
    if (round_time < 0) round_time = 0;

    round_kills = kills_now - self.cs_kills_start;
    if (round_kills < 0) round_kills = 0;

    // Personal best per round (persist via seta)
    pb_time_key = "cs_personal_best_time_round_" + completed_round;
    pb_kills_key = "cs_personal_best_kills_round_" + completed_round;

    old_pb_time = getDvarInt(pb_time_key);
    old_pb_kills = getDvarInt(pb_kills_key);

    new_pb_time = 0;
    new_pb_kills = 0;

    if (round_time > 0 && (old_pb_time <= 0 || round_time < old_pb_time))
    {
        old_pb_time = round_time;
        setDvar(pb_time_key, round_time);
        cmdexec("seta " + pb_time_key + " " + round_time + "\n");
        new_pb_time = 1;
    }

    if (round_kills > old_pb_kills)
    {
        old_pb_kills = round_kills;
        setDvar(pb_kills_key, round_kills);
        cmdexec("seta " + pb_kills_key + " " + round_kills + "\n");
        new_pb_kills = 1;
    }

    // Cooldown to stop rapid re-trigger / flicker
    cooldown = getDvarInt("cs_cooldown_ms");
    if (cooldown < 500) cooldown = 500;
    if (cooldown > 10000) cooldown = 10000;

    now = getTime();
    if (isDefined(self.cs_last_popup_time) && (now - self.cs_last_popup_time) < cooldown)
    {
        self.cs_last_round = new_round;
        self.cs_round_start_time = getTime();
        self.cs_kills_start = kills_now;
        return;
    }

    self.cs_last_popup_time = now;

    self notify("cs_popup_kill3");
    self thread cs_popup(completed_round, round_time, round_kills, old_pb_time, old_pb_kills, new_pb_time, new_pb_kills);

    self.cs_last_round = new_round;
    self.cs_round_start_time = getTime();
    self.cs_kills_start = kills_now;
}

cs_popup(round_num, round_time, round_kills, pb_time, pb_kills, new_pb_time, new_pb_kills)
{
    self endon("disconnect");
    self endon("cs_popup_kill3");

    cs_hud_create();

    x = cs_clamp(getDvarInt("cs_x"), -300, 300);
    y = cs_clamp(getDvarInt("cs_y"), -220, 160);

    // Big spacing so it never mashes
    self.cs_title setPoint("CENTER", "CENTER", x, y - 58);
    self.cs_line2 setPoint("CENTER", "CENTER", x, y - 30);
    self.cs_line3 setPoint("CENTER", "CENTER", x, y - 4);
    self.cs_line4 setPoint("CENTER", "CENTER", x, y + 22);

    time_str = cs_time(round_time);
    pb_time_str = "Not Set";
    if (pb_time > 0) pb_time_str = cs_time(pb_time);

    status_str = cs_status(new_pb_time, new_pb_kills);

    self.cs_title setText("^5ROUND " + round_num + " COMPLETE");
    self.cs_line2 setText("^7Eliminations: ^5" + round_kills + " ^7| Round Time: ^5" + time_str);
    self.cs_line3 setText("^7Personal Best Time: ^3" + pb_time_str + " ^7| Personal Best Eliminations: ^3" + pb_kills);
    self.cs_line4 setText("^7Status: " + status_str);

    // Hard reset alpha
    self.cs_title.alpha = 0;
    self.cs_line2.alpha = 0;
    self.cs_line3.alpha = 0;
    self.cs_line4.alpha = 0;

    // Fade in
    self.cs_title fadeOverTime(0.18); self.cs_title.alpha = 0.95;
    self.cs_line2 fadeOverTime(0.18); self.cs_line2.alpha = 0.95;
    self.cs_line3 fadeOverTime(0.18); self.cs_line3.alpha = 0.95;
    self.cs_line4 fadeOverTime(0.18); self.cs_line4.alpha = 0.95;

    show_for = cs_clamp(getDvarInt("cs_seconds"), 3, 30);
    wait show_for;

    // Fade out
    self.cs_title fadeOverTime(0.28); self.cs_title.alpha = 0;
    self.cs_line2 fadeOverTime(0.28); self.cs_line2.alpha = 0;
    self.cs_line3 fadeOverTime(0.28); self.cs_line3.alpha = 0;
    self.cs_line4 fadeOverTime(0.28); self.cs_line4.alpha = 0;

    wait 0.28;
}

cs_hud_create()
{
    if (isDefined(self.cs_title) && isDefined(self.cs_line4))
        return;

    if (isDefined(self.cs_title)) self.cs_title destroy();
    if (isDefined(self.cs_line2)) self.cs_line2 destroy();
    if (isDefined(self.cs_line3)) self.cs_line3 destroy();
    if (isDefined(self.cs_line4)) self.cs_line4 destroy();

    self.cs_title = self createFontString("default", 1.55);
    self.cs_title.sort = 25;
    self.cs_title.alpha = 0;
    self.cs_title.hideWhenInMenu = 1;

    self.cs_line2 = self createFontString("default", 1.25);
    self.cs_line2.sort = 25;
    self.cs_line2.alpha = 0;
    self.cs_line2.hideWhenInMenu = 1;

    self.cs_line3 = self createFontString("default", 1.12);
    self.cs_line3.sort = 25;
    self.cs_line3.alpha = 0;
    self.cs_line3.hideWhenInMenu = 1;

    self.cs_line4 = self createFontString("default", 1.12);
    self.cs_line4.sort = 25;
    self.cs_line4.alpha = 0;
    self.cs_line4.hideWhenInMenu = 1;
}

cs_get_kills()
{
    if (isDefined(self.kills))
        return self.kills;
    if (isDefined(self.pers) && isDefined(self.pers["kills"]))
        return self.pers["kills"];
    return 0;
}

cs_time(total)
{
    if (total < 0) total = 0;
    m = int(total / 60);
    s = int(total % 60);
    if (s < 10)
        return "" + m + ":0" + s;
    return "" + m + ":" + s;
}

cs_status(new_time, new_kills)
{
    if (new_time && new_kills)
        return "^2New Personal Best Time and New Personal Best Eliminations";
    if (new_time)
        return "^2New Personal Best Time";
    if (new_kills)
        return "^2New Personal Best Eliminations";
    return "^7No New Personal Best";
}

cs_clamp(v, mn, mx)
{
    if (v < mn) return mn;
    if (v > mx) return mx;
    return v;
}

// ============================================================================
//  deathmachine_powerup  (was deathmachine_powerup.gsc)
// ============================================================================
dm_onplayerconnect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread dm_onplayerspawned();
    }
}

dm_onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "end_game" );
    for ( ;; )
    {
        self waittill( "spawned_player" );
        deathmachine_clear_powerup_state( self );
        if ( !isDefined( level.deathmachine_powerup_init_done ) )
        {
            wait 2;
            if ( isDefined( level._zombiemode_powerup_grab ) )
            {
                level.original_deathmachine_powerup_grab = level._zombiemode_powerup_grab;
            }
            level._zombiemode_powerup_grab = ::custom_powerup_grab;
            level.deathmachine_powerup_init_done = 1;
        }
        self notify( "restart_deathmachine_test" );
        //self thread powerup_test();
    }
}

drop_deathmachine()
{
    if ( is_true( getdvarintdefault( "sv_deathmachine_powerup", 1 ) ) )
    {
        return 1;
    }
    return 0;
}

deathmachine_damage_response( mod, hit_location, hit_origin, player, amount )
{
    if ( !isDefined( player ) || !isPlayer( player ) )
        return false;
    if ( !isDefined( player.deathmachine_active ) || !player.deathmachine_active )
        return false;
    weapon = get_deathmachine_weapon();
    if ( player getcurrentweapon() != weapon )
        return false;
    if ( !isDefined( amount ) || amount <= 0 )
        return false;
    if ( isDefined( self.deathmachine_forced_kill ) && self.deathmachine_forced_kill )
        return false;
    if ( !isAlive( self ) || !isDefined( self.health ) || self.health <= 0 )
        return false;
    if ( !isDefined( hit_origin ) )
        hit_origin = self.origin;
    if ( deathmachine_during_instakill( player ) )
    {
        final_damage = self.health + 666;
    }
    else
    {
        bonus_damage = self.health * randomfloatrange( 0.34, 0.75 );
        final_damage = amount + bonus_damage;
    }
    self.deathmachine_forced_kill = 1;
    self DoDamage( final_damage, hit_origin, player, player, hit_location, mod, 0, weapon );
    self.deathmachine_forced_kill = undefined;
    return true;
}

deathmachine_during_instakill( player )
{
    if ( !isDefined( player ) || !isPlayer( player ) || !isAlive( player ) )
        return false;
    if ( isDefined( level.zombie_vars ) && isDefined( player.team ) && isDefined( level.zombie_vars[player.team] ) && isDefined( level.zombie_vars[player.team]["zombie_insta_kill"] ) && level.zombie_vars[player.team]["zombie_insta_kill"] )
        return true;
    if ( isDefined( player.personal_instakill ) && player.personal_instakill )
        return true;
    return false;
}

set_powerup_state( player )
{
    if ( !isDefined( player ) || !isPlayer( player ) )
    {
        return;
    }
    player.deathmachine_active = 1;
    player.has_minigun = 1;
    player.has_powerup_weapon = 1;
    player._show_solo_hud = 1;
    player setclientammocounterhide( 1 );
    player setclientdvar( "deathmachine_powerup_state", 1 );
}

deathmachine_clear_powerup_state( player )
{
    if ( !isDefined( player ) || !isPlayer( player ) )
    {
        return;
    }
    player.deathmachine_active = undefined;
    player.has_minigun = 0;
    player.has_powerup_weapon = 0;
    player._show_solo_hud = 0;
    player setclientammocounterhide( 0 );
    player setclientdvar( "deathmachine_powerup_state", 0 );
}

custom_powerup_grab( s_powerup, e_player )
{
    if ( isDefined( s_powerup ) && isDefined( s_powerup.powerup_name ) && s_powerup.powerup_name == "deathmachine" )
    {
        level thread deathmachine_powerup( s_powerup, e_player );
        return;
    }
    if ( isDefined( level.original_deathmachine_powerup_grab ) )
    {
        level thread [[level.original_deathmachine_powerup_grab]]( s_powerup, e_player );
    }
}

deathmachine_powerup( m_powerup, e_player )
{
    if ( !isDefined( e_player ) )
    {
        return;
    }
    if ( e_player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
    {
        return;
    }
    level.deathmachine_duration = getdvarintdefault( "sv_deathmachine_duration", 30 );
    e_player notify( "end_deathmachine" );
    wait 0.05;
    e_player playsound( "death_machine" );
    e_player thread powerup_state_monitor();
    e_player thread start_deathmachine();
    e_player thread notify_deathmachine_end();
}

powerup_state_monitor()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_deathmachine" );
    time_left = getdvarintdefault( "sv_deathmachine_duration", 30 );
    self setclientdvar( "deathmachine_powerup_state", 1 );
    while ( time_left > 10 )
    {
        wait 0.05;
        time_left -= 0.05;
    }
    flash_on = 1;
    while ( time_left > 0 )
    {
        if ( time_left <= 5 )
        {
            blink_time = 0.1;
        }
        else
        {
            blink_time = 0.2;
        }
        if ( flash_on )
        {
            self setclientdvar( "deathmachine_powerup_state", 3 );
        }
        else
        {
            self setclientdvar( "deathmachine_powerup_state", 2 );
        }
        flash_on = !flash_on;
        wait blink_time;
        time_left -= blink_time;
    }
    self setclientdvar( "deathmachine_powerup_state", 0 );
}

start_deathmachine()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_deathmachine" );
    weapon = get_deathmachine_weapon();
    self.weapon_before_deathmachine = self getcurrentweapon();
    self.deathmachine_had_weapon_before = self hasweapon( weapon );
    set_powerup_state( self );
    if ( !self.deathmachine_had_weapon_before )
    {
        self notify( "replace_weapon_powerup" );
        self giveweapon( weapon );
        wait 0.05;
    }
    self setweaponammoclip( weapon, 150 );
    self setweaponammostock( weapon, 300 );
    self switchtoweapon( weapon );
    self thread deathmachine_infinite_ammo();
    self thread end_deathmachine_powerup();
    self thread end_deathmachine_on_weapon_switch( weapon );
}

deathmachine_infinite_ammo()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_deathmachine" );
    weapon = get_deathmachine_weapon();
    for ( ;; )
    {
        if ( self hasweapon( weapon ) )
        {
            self setweaponammoclip( weapon, 150 );
            self setweaponammostock( weapon, 300 );
        }
        wait 0.05;
    }
}

end_deathmachine_powerup()
{
    level endon( "end_game" );
    self waittill_any( "end_deathmachine", "disconnect", "death" );
    weapon = get_deathmachine_weapon();
    if ( !isDefined( self.deathmachine_had_weapon_before ) || !self.deathmachine_had_weapon_before )
    {
        if ( self hasweapon( weapon ) )
        {
            self takeweapon( weapon );
        }
        if ( isDefined( self.weapon_before_deathmachine ) )
        {
            player_weapons = self getweaponslistprimaries();
            for ( i = 0; i < player_weapons.size; i++ )
            {
                if ( player_weapons[i] == self.weapon_before_deathmachine )
                {
                    self switchtoweapon( self.weapon_before_deathmachine );
                    deathmachine_clear_powerup_state( self );
                    clear_deathmachine_vars();
                    return;
                }
            }
        }
        self switch_back_from_deathmachine();
    }
    else if ( self getcurrentweapon() == weapon && isDefined( self.weapon_before_deathmachine ) && self.weapon_before_deathmachine != "none" && self.weapon_before_deathmachine != weapon && self hasweapon( self.weapon_before_deathmachine ) )
    {
        self switchtoweapon( self.weapon_before_deathmachine );
    }
    deathmachine_clear_powerup_state( self );
    clear_deathmachine_vars();
}

end_deathmachine_on_weapon_switch( weapon )
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_deathmachine" );
    for ( ;; )
    {
        if ( self getcurrentweapon() == weapon )
        {
            break;
        }
        wait 0.05;
    }
    wait 0.1;
    for ( ;; )
    {
        if ( !self hasweapon( weapon ) )
        {
            return;
        }
        if ( self getcurrentweapon() != weapon )
        {
            self notify( "end_deathmachine" );
            return;
        }
        wait 0.05;
    }
}

switch_back_from_deathmachine()
{
    wait 0.05;
    if ( isDefined( self.weapon_before_deathmachine ) && self.weapon_before_deathmachine != "none" && self hasweapon( self.weapon_before_deathmachine ) )
    {
        self switchtoweapon( self.weapon_before_deathmachine );
    }
    else
    {
        primaryweapons = self getweaponslistprimaries();
        if ( isDefined( primaryweapons ) && primaryweapons.size > 0 )
        {
            self switchtoweapon( primaryweapons[0] );
        }
        else
        {
            self maps\mp\zombies\_zm_weapons::give_fallback_weapon();
        }
    }
}

notify_deathmachine_end()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_deathmachine" );
    wait getdvarintdefault( "sv_deathmachine_duration", 30 );
    self playsound( "zmb_insta_kill" );
    self notify( "end_deathmachine" );
}

get_deathmachine_weapon()
{
    if ( isDefined( level.deathmachine_weapon ) )
    {
        return level.deathmachine_weapon;
    }
    return "deathmachine_zm";
}

clear_deathmachine_vars()
{
    self.deathmachine_had_weapon_before = undefined;
    self.weapon_before_deathmachine = undefined;
}

// ============================================================================
//  DEBUG: ".dm" chat command (added 2026-07-26, generalised 2026-08-03)
// ----------------------------------------------------------------------------
//  debug_chat_listener() lived here. It was a second "say" listener that only
//  understood the literal ".dm" - no "!"/"/" prefix, no other power-up.
//
//  It is now folded into the single dispatcher: zmqol_dev_command_listener()
//  routes ".dm" through zmqol_powerup_alias() -> zmqol_spawn_powerup(), which
//  is the same code path every other power-up uses. The drop call and the
//  70-unit forward offset are carried over unchanged.
// ============================================================================

// ============================================================================
//  high_round_fix  (was high_round_fix.gsc)
// ----------------------------------------------------------------------------
//  Pre-existing quirk from the original author (not something we introduced):
//  stats() preloads a hardcoded zm_transit weaponLocker weapon
//  (an94_upgraded_zm+reflex, 1023 ammo) plus persistent-stat unlocks, on
//  EVERY map regardless of which one is loaded.
// ============================================================================
hrf_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread hrf_onplayerspawned();
    }
}

hrf_onplayerspawned()
{
    self endon( "disconnect" );
    self.zm_fix = 1;
    for (;;)
    {
        self waittill( "spawned_player" );
        if ( self.zm_fix == 1 )
        {
            self.zm_fix = 0;
            self thread stats();
        }
    }
}

zombie_health()
{
    for (;;)
    {
        level waittill( "start_of_round" );
        if ( level.zombie_health > maps\mp\zombies\_zm::ai_zombie_health( 155 ) )
            level.zombie_health = maps\mp\zombies\_zm::ai_zombie_health( 155 );
    }
}

stats()
{
    flag_wait( "initial_blackscreen_passed" );
    self.account_value = 250;
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "name", "an94_upgraded_zm+reflex" );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "stock", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "lh_clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_stock", 1023 );
    self set_client_stat( "pers_boarding", 74 );
    self set_client_stat( "pers_revivenoperk", 17 );
    self set_client_stat( "pers_multikill_headshots", 5 );
    self set_client_stat( "pers_cash_back_bought", 50 );
    self set_client_stat( "pers_cash_back_prone", 15 );
    self set_client_stat( "pers_insta_kill", 2 );
    self set_client_stat( "pers_jugg", 3 );
    self set_client_stat( "pers_flopper_counter", 1 );
    self set_client_stat( "pers_pistol_points_counter", 1 );
    self set_client_stat( "pers_double_points_counter", 1 );
    self set_client_stat( "pers_perk_lose_counter", 3 );
    self set_client_stat( "pers_sniper_counter", 1 );
    self set_client_stat( "pers_box_weapon_counter", 5 );
    self set_client_stat( "pers_nube_counter", 1 );
}

// ============================================================================
//  instant_pap  (was instant_pap.gsc)
// ============================================================================
setup_pap_attachments()
{
    flag_wait( "initial_blackscreen_passed" );
    if ( !isdefined( level.zombie_weapons ) )
        return;
    keys = getarraykeys( level.zombie_weapons );
    for ( i = 0; i < keys.size; i++ )
    {
        w = level.zombie_weapons[keys[i]];
        // Skip guns without an upgrade, and guns that already have a list
        // (e.g. native Buried built them at registration).
        if ( !isdefined( w.upgrade_name ) || isdefined( w.addon_attachments ) )
            continue;
        maps\mp\zombies\_zm_weapons::add_attachments( keys[i], w.upgrade_name );
    }
}

new_pap_trigger()
{
    level waittill("Pack_A_Punch_on");
    wait 2;
    if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zstandard" )
    {
    }
    else
    {
        level notify("Pack_A_Punch_off");
        level thread pap_off();
    }
    if( getdvar( "mapname" ) == "zm_nuked" )
    {
        level waittill( "Pack_A_Punch_on" );
    }
    perk_machine = getent( "vending_packapunch", "targetname" );
    weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
    weapon_upgrade_trigger[0] trigger_off();
    if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zclassic" )
    {
        if(!level.buildables_built[ "pap" ])
        {
            level waittill("pap_built");
        }
    }
    wait 1;
    self.perk_machine = perk_machine;
    perk_machine_sound = getentarray( "perksacola", "targetname" );
    packa_rollers = spawn( "script_origin", perk_machine.origin );
    packa_timer = spawn( "script_origin", perk_machine.origin );
    packa_rollers linkto( perk_machine );
    packa_timer linkto( perk_machine );
    if( getdvar( "mapname" ) == "zm_highrise" )
    {
        trigger = spawn( "trigger_radius", perk_machine.origin, 1, 60, 80 );
        Trigger enableLinkTo();
        Trigger linkto(self.perk_machine);
    }
    else
    {
        trigger = spawn( "trigger_radius", perk_machine.origin, 1, 35, 80 );
    }
    Trigger SetCursorHint( "HINT_NOICON" );
    Trigger sethintstring( "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + getDvarInt("pap_price") + "]" );
    Trigger usetriggerrequirelookat();
    perk_machine thread maps\mp\zombies\_zm_perks::activate_packapunch();
    for(;;)
    {
        Trigger waittill("trigger", player);
        current_weapon = player getcurrentweapon();
        if ( !can_upgrade_weapon( current_weapon ) )
        {
            Trigger sethintstring( "" );
        }
        else
        {
            is_upgraded = is_weapon_upgraded( current_weapon );
            cost = getDvarInt( "pap_price" );
            if ( is_upgraded )
            {
                cost = getDvarInt( "repap_price" );
                Trigger sethintstring( "			Hold ^3&&1^7 for Repack-a-Punch [Cost: " + cost + "]" );
            }
            else
            {
                Trigger sethintstring( "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + cost + "]" );
            }
        }
        if(player UseButtonPressed() && player.score >= cost && current_weapon != "riotshield_zm" && player can_buy_weapon() && !player.is_drinking && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && can_upgrade_weapon( current_weapon ))
        {
            player.score -= cost;
            player thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
            trigger setinvisibletoall();
            upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
            clip_ammo = player getweaponammoclip( current_weapon );
            stock_ammo = player getweaponammostock( current_weapon );
            wait .1;
            player takeWeapon(current_weapon);
            current_weapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
            self.current_weapon = current_weapon;
            if ( is_upgraded )
            {
                upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, true );
            }
            else
            {
                upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
            }
            player pap_effects( current_weapon, upgrade_name, packa_rollers, perk_machine, self );
            player giveweapon(upgrade_name, 0 , player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_name ));
            if ( is_upgraded )
            {
                new_clip_size = weaponclipsize( upgrade_name );
                if ( clip_ammo > new_clip_size )
                    clip_ammo = new_clip_size;
                player setweaponammoclip( upgrade_name, clip_ammo );
                player setweaponammostock( upgrade_name, stock_ammo );
            }
            player switchtoweapon (upgrade_name);
            self playsound("zmb_perks_packa_upgrade");
            player playsound("zmb_perks_packa_ready");
            player playsound("zmb_cha_ching");
            if ( isDefined( player ) )
            {
                trigger setinvisibletoall();
                trigger setvisibletoplayer( player );
            }
            wait .1;
            self.current_weapon = "";
            trigger setinvisibletoplayer( player );
            wait 1.5;
            trigger setvisibletoall();
            self.pack_player = undefined;
            flag_clear( "pack_machine_in_use" );
        }
        if ( isDefined( player ) )
        {
            current_weapon = player getcurrentweapon();
            if ( !can_upgrade_weapon( current_weapon ) )
            {
                Trigger sethintstring( "" );
            }
            else
            {
                cost = getDvarInt( "pap_price" );
                if ( is_weapon_upgraded( current_weapon ) )
                {
                    cost = getDvarInt( "repap_price" );
                    Trigger sethintstring( "			Hold ^3&&1^7 for Repack-a-Punch [Cost: " + cost + "]" );
                }
                else
                {
                    Trigger sethintstring( "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + cost + "]" );
                }
            }
        }
        wait .1;
    }
}

pap_off()
{
    wait 5;
    for(;;)
    {
        level waittill("Pack_A_Punch_on");
        wait 1;
        level notify("Pack_A_Punch_off");
    }
}

pap_effects( current_weapon, upgrade_weapon, packa_rollers, perk_machine, trigger )
{
    level endon( "Pack_A_Punch_off" );
    trigger endon( "pap_player_disconnected" );
    rel_entity = trigger.perk_machine;
    origin_offset = ( 0, 0, 0 );
    angles_offset = ( 0, 0, 0 );
    origin_base = self.origin;
    angles_base = self.angles;
    if ( isdefined( rel_entity ) )
    {
        if ( isdefined( level.pap_interaction_height ) )
            origin_offset = ( 0, 0, level.pap_interaction_height );
        else
            origin_offset = vectorscale( ( 0, 0, 1 ), 35.0 );
        angles_offset = vectorscale( ( 0, 1, 0 ), 90.0 );
        origin_base = rel_entity.origin;
        angles_base = rel_entity.angles;
    }
    else
        rel_entity = self;
    forward = anglestoforward( angles_base + angles_offset );
    interact_offset = origin_offset + forward * -25;
    if ( !isdefined( perk_machine.fx_ent ) )
    {
        perk_machine.fx_ent = spawn( "script_model", origin_base + origin_offset + ( 0, 1, -34 ) );
        perk_machine.fx_ent.angles = angles_base + angles_offset;
        perk_machine.fx_ent setmodel( "tag_origin" );
        perk_machine.fx_ent linkto( perk_machine );
    }
    if ( isdefined( level._effect["packapunch_fx"] ) )
        fx = playfxontag( level._effect["packapunch_fx"], perk_machine.fx_ent, "tag_origin" );
}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
        setDvar( dvar, set );
}

// ============================================================================
//  No_Fog  (was No_Fog.gsc)
// ----------------------------------------------------------------------------
//  NOTE (2026-07-30): Disable_Fog_Transition was briefly merged in here,
//  then moved back OUT to the TranZit-scoped script
//  scripts/zm/zm_transit/disable_fog_transition.gsc - a root script can't
//  hold its zm_transit_fx reference (see the note at the top of this file).
//  What stays here is No_Fog's client-dvar part (r_fog 0, r_dof_enable 0).
// ============================================================================
nofog_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread nofog_onplayerspawned();
        player setclientdvar( "r_fog", "0" );
        player setclientdvar( "r_dof_enable", "0" );
    }
}

nofog_onplayerspawned()
{
    self endon( "disconnect" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  noperklimit  (was noperklimit.gsc)
// ============================================================================
// 🛑 THIS USED TO HARDCODE 9, IN A FUNCTION CALLED remove_perk_limit().
// Reported in game: spinning the Wunderfizz repeatedly could never yield the
// last perk - it stopped at nine with "You Can Only Hold 9 Perks". The perk
// that went missing (Stamin-Up, in the report) is simply whichever one was not
// rolled first; it was never Stamin-Up-specific, and marathon IS enabled on
// TranZit (see perks() below), so getPerks() was offering it correctly.
//
// The mod has grown past nine perks - wunderfizz::getPerks() can offer twelve
// once Electric Cherry, Vulture Aid, PhD and Deadshot are added to a map - so a
// literal 9 became a cap rather than the removal of one.
//
// Now derived from the same list the Wunderfizz actually offers, so adding a
// perk later cannot silently reintroduce the cap. Both files are ROOT scripts
// that load on every map, so this cross-file call is safe under AI_CONTEXT
// rule 2 (only MAP-SPECIFIC references break other maps).
remove_perk_limit()
{
    level waittill( "start_of_round" );
    wait 0.05;

    // 🛑 THE FLOOR IS 11, NOT 9. User, on Origins: "it says i can only get 9 perks
    // make sure that every map with the real actual wunderfizz machine let's you
    // get all 11 perks in bo2 zombies."
    //
    // Deriving the cap from getPerks().size was supposed to make the cap follow
    // the mod, and it does - on the maps where the mod PLACES a machine. Origins
    // has its own machines and no added one, so nothing here grew past nine and
    // the old floor became the cap again, which is the exact failure this function
    // was rewritten to stop.
    //
    // Eleven is the number of perks Black Ops II Zombies actually has, so it is a
    // floor rather than a guess, and the max() below still lets a map with more
    // than eleven offerings raise it further.
    n_limit = 11;
    a_perks = scripts\zm\wunderfizz::getPerks();

    if ( isdefined( a_perks ) && a_perks.size > n_limit )
        n_limit = a_perks.size;

    level.perk_purchase_limit = n_limit;
}

perklimit_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread perklimit_welcome();
    }
}

perklimit_welcome()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  perkbonuspoints  -  prone in front of a perk machine = bonus points
// ----------------------------------------------------------------------------
//  THE single source of prone-perk points for this mod.
//
//  What it does:
//    Go prone in front of ANY perk machine -> +100 points, ONCE per machine.
//    Machines are found dynamically by their vending targetnames, so it covers
//    every perk zm_expanded loads on every map, and it re-scans each check so
//    it follows MOVING machines (Die Rise elevator perks).
//
//  Origins (zm_tomb):
//    Origins has this feature NATIVELY (the "loose change" easter egg). We do
//    NOT run our detection there (init() skips pbp_onplayerconnect on
//    zm_tomb, above). Bumping that native 25 -> 100 is done in
//    zm_tomb\zm_tomb.gsc, because that Origins-only reference must live in
//    the Origins map script (root scripts load on EVERY map and would throw
//    "unresolved external" elsewhere).
//
//  Tuning: AWARD_RANGE (96) = how close you must be; SAME_MACHINE_DIST (128)
//  = machines whose origins are within this are treated as one machine.
// ============================================================================
pbp_onplayerconnect()
{
    level endon( "end_game" );
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread pbp_onplayerspawned();
    }
}

pbp_onplayerspawned()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "spawned_player" );
        self thread prone_bonus_monitor();
    }
}

prone_bonus_monitor()
{
    // one monitor per player - restart kills any previous instance
    self notify( "prone_bonus_monitor" );
    self endon( "prone_bonus_monitor" );
    self endon( "disconnect" );
    level endon( "end_game" );
    if ( !isdefined( self.perk_prone_claimed ) )
        self.perk_prone_claimed = [];
    if ( !isdefined( self.perk_prone_claimed_origins ) )
        self.perk_prone_claimed_origins = [];
    // give the map + custom perk scripts time to spawn/link their machines
    wait 2;
    for ( ;; )
    {
        if ( isdefined( self.sessionstate ) && self.sessionstate == "spectator" )
        {
            wait 0.25;
            continue;
        }
        if ( self getstance() == "prone" )
        {
            self prone_bonus_try_award();
            wait 0.25;
            continue;
        }
        wait 0.1;
    }
}

// 🛑 THE 128-UNIT DEDUPE USED TO BE GLOBAL, AND THAT IS WHY MULE KICK PAID
// NOTHING. The radius exists so one machine represented by TWO entities (the
// trigger and the model) only pays once. But it was checked against every
// origin claimed so far, regardless of which perk it belonged to - so any
// machine standing within 128 units of one already claimed was silently
// skipped. On maps where the mod packs several perks together (Farm is the
// reported case) that is a normal spacing, so Mule Kick lost its 100 points to
// whichever neighbour the player happened to prone at first.
//
// The dedupe is now PER MACHINE NAME. Mule Kick's trigger and model still
// cancel each other out; an adjacent Tombstone no longer cancels Mule Kick.
prone_bonus_try_award()
{
    names = get_perk_machine_names();

    for ( n = 0; n < names.size; n++ )
    {
        machines = [];
        machines = add_ent_array( machines, getentarray( names[n], "target" ) );
        machines = add_ent_array( machines, getentarray( names[n], "targetname" ) );

        for ( i = 0; i < machines.size; i++ )
        {
            machine = machines[i];
            if ( !isdefined( machine ) || !isdefined( machine.origin ) )
                continue;
            // once-per-machine by entity number (stable even when it moves)...
            claim_key = "machine_" + machine getentitynumber();
            if ( isdefined( self.perk_prone_claimed[claim_key] ) )
                continue;
            // ...and by origin WITHIN THIS PERK, so the trigger and the model of
            // the same machine only pay once.
            if ( self origin_already_claimed( names[n], machine.origin ) )
                continue;
            // 96 = AWARD_RANGE
            if ( distance( self.origin, machine.origin ) > 96 )
                continue;
            self.perk_prone_claimed[claim_key] = 1;
            self mark_origin_claimed( names[n], machine.origin );
            self maps\mp\zombies\_zm_score::add_to_player_score( 100 );
            self playsound( "zmb_cha_ching" );
            return;
        }
    }
}

origin_already_claimed( str_name, check_origin )
{
    if ( !isdefined( self.perk_prone_claimed_origins ) )
        self.perk_prone_claimed_origins = [];
    if ( !isdefined( self.perk_prone_claimed_origins[str_name] ) )
        return 0;

    a_origins = self.perk_prone_claimed_origins[str_name];

    for ( i = 0; i < a_origins.size; i++ )
    {
        // 128 = SAME_MACHINE_DIST, now only ever compared within one perk
        if ( distance( a_origins[i], check_origin ) < 128 )
            return 1;
    }
    return 0;
}

mark_origin_claimed( str_name, check_origin )
{
    if ( !isdefined( self.perk_prone_claimed_origins ) )
        self.perk_prone_claimed_origins = [];
    if ( !isdefined( self.perk_prone_claimed_origins[str_name] ) )
        self.perk_prone_claimed_origins[str_name] = [];

    a_origins = self.perk_prone_claimed_origins[str_name];
    a_origins[a_origins.size] = check_origin;
    self.perk_prone_claimed_origins[str_name] = a_origins;
}

get_perk_machine_names()
{
    // Every perk vending targetname zm_expanded / the maps use.
    // (vending_packapunch is intentionally excluded - it isn't a perk.)
    //
    // 🛑 vending_vulture was MISSING here until v1.13.2, and the reason it never
    // showed up before is worth keeping. _zm_perks::perk_machine_spawn_init tags a
    // machine by switching on the perk name; specialty_nomotionsensor has no case,
    // so before v1.13.0 Vulture Aid fell into `default:` and was tagged
    // "vending_sleight". This list found it under that wrong name, so the prone
    // bonus appeared to work. v1.13.0 fixed the tag to the correct
    // "vending_vulture" (see zm_buried\zm_buried.gsc), which took it straight back
    // out of this list - so Borough's Vulture Aid stopped paying the 100 points.
    // Both halves are needed: the correct tag AND this entry.
    // vending_deadshot_model is stock's OWN tag for Deadshot - _zm_perks.gsc:3051
    // assigns it, not "vending_ads" or "vending_deadshot". Same class of bug as
    // the vending_vulture note above; harmless to list all three.
    return array( "vending_jugg", "vending_sleight", "vending_doubletap", "vending_doubletap2", "vending_revive", "vending_marathon", "vending_three_gun", "vending_additionalprimaryweapon", "vending_ads", "vending_deadshot", "vending_deadshot_model", "vending_nuke", "vending_divetonuke", "vending_tombstone", "vending_chugabud", "vending_vulture" );
}

get_perk_machine_ents()
{
    names = get_perk_machine_names();
    machines = [];
    for ( i = 0; i < names.size; i++ )
    {
        // the "in front of the machine" trigger targets the machine model
        machines = add_ent_array( machines, getentarray( names[i], "target" ) );
        // ...and the machine model itself (fallback / covers odd setups)
        machines = add_ent_array( machines, getentarray( names[i], "targetname" ) );
    }
    return machines;
}

add_ent_array( machines, add_machines )
{
    if ( !isdefined( add_machines ) )
        return machines;
    for ( i = 0; i < add_machines.size; i++ )
        machines[machines.size] = add_machines[i];
    return machines;
}

// ============================================================================
//  secretsongsurvival  (was secretsongsurvival.gsc)
// ============================================================================
sss_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread sss_onplayerspawned();
    }
}

sss_onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
        self waittill( "spawned_player" );
}

// spawnteddybear() / setteddybears() reworked 2026-07-26 against the stock
// zm_transit.gsc reference (maps\mp\zm_transit.gsc :: sndsetupmusiceasteregg /
// sndmusicegg / sndplaymusicegg - the native Tranzit "3 teddy bears -> secret
// song" easter egg, which only ever runs in zclassic mode; this is a
// zstandard-only reimplementation with its own local per-start-zone origins):
//   - teddymodel now plays a "zmb_meteor_loop" beacon so players can hear a
//     bear before they see it (stock does this on its own helper entity).
//   - the 3-bear count is now a LEVEL-scoped counter (level.sss_teddybear_count),
//     not a per-player one - matching stock's level.meteor_counter so co-op
//     players collectively complete it, and so a single player triggering all
//     3 actually reaches 3 (the old i.teddybears was already correct for solo
//     play; the real reason the song never played is the missing loop below).
//   - the secret song now plays via a dedicated threaded function mirroring
//     stock's sndplaymusicegg(), instead of a bare playsound() call inline.
spawnteddybear( x, y, z, angle )
{
    teddytrigger = spawn( "trigger_radius", ( x, y, z ), 1, 50, 50 );
    teddymodel = spawn( "script_model", ( x, y, z ), 1, 50, 50 );
    teddymodel setmodel( "zombie_teddybear" );
    teddymodel rotateto( ( 0, angle, 0 ), 0.1 );
    teddymodel playloopsound( "zmb_meteor_loop" );
    while ( true )
    {
        teddytrigger waittill( "trigger", i );
        if ( i usebuttonpressed() )
        {
            teddymodel stoploopsound( 1 );
            i playsound( "zmb_meteor_activate" );
            if ( !isdefined( level.sss_teddybear_count ) )
                level.sss_teddybear_count = 0;
            level.sss_teddybear_count++;
            if ( level.sss_teddybear_count == 3 )
                level thread play_secret_song( teddymodel );
            break;
        }
    }
}

// Mirrors stock sndplaymusicegg(): plays the secret song on the bear that
// completed the set, then holds the thread open until end_game so stopsounds
// has something to clean up (matches stock's cleanup pattern).
play_secret_song( ent )
{
    level endon( "end_game" );
    wait 1;
    ent playsound( "mus_zmb_secret_song" );
    level waittill( "end_game" );
    ent stopsounds();
}

setteddybears()
{
    level.sss_teddybear_count = 0;
    if ( getdvar( "g_gametype" ) == "zstandard" )
    {
        if ( getdvar( "mapname" ) == "zm_transit" )
        {
            if ( getdvar( "ui_zm_mapstartlocation" ) == "town" )
            {
                thread spawnteddybear( 430, -570, -61, 26 );
                thread spawnteddybear( 2312, 579, -55, -137 );
                thread spawnteddybear( 699, -1387, 128, -48 );
            }
            else if ( getdvar( "ui_zm_mapstartlocation" ) == "transit" )
            {
                thread spawnteddybear( -7645, 5377, -58, -177 );
                thread spawnteddybear( -6656, 4408, -63, -120 );
                thread spawnteddybear( -6380, 5625, -45, -132 );
            }
            else if ( getdvar( "ui_zm_mapstartlocation" ) == "farm" )
            {
                thread spawnteddybear( 8512, -5913, 52, -134 );
                thread spawnteddybear( 8449, -5350, 48, 127 );
                thread spawnteddybear( 8125, -6730, 117, 19 );
            }
        }
    }
}

// ============================================================================
//  zm_expanded  -  perk / clientfield / vending hub
// ============================================================================
player_too_many_weapons_monitor()
{
    if( level.script == "zm_prison" )
    {
        self notify( "stop_player_too_many_weapons_monitor" );
        self endon( "stop_player_too_many_weapons_monitor" );
        self endon( "disconnect" );
        level endon( "end_game" );
        scalar = self.characterindex;
        if ( !isdefined( scalar ) )
            scalar = self getentitynumber();
        wait( 0.15 * scalar );
        while ( true )
        {
            if ( self has_powerup_weapon() || self maps\mp\zombies\_zm_laststand::player_is_in_laststand() || self.sessionstate == "spectator" )
            {
                wait( get_player_too_many_weapons_monitor_wait_time() );
                continue;
            }
            weapon_limit = get_player_weapon_limit( self );
            primaryweapons = self getweaponslistprimaries();
            if ( primaryweapons.size > weapon_limit )
            {
                self maps\mp\zombies\_zm_weapons::take_fallback_weapon();
                primaryweapons = self getweaponslistprimaries();
            }
            primary_weapons_to_take = [];
            for ( i = 0; i < primaryweapons.size; i++ )
            {
                if ( maps\mp\zombies\_zm_weapons::is_weapon_included( primaryweapons[i] ) || maps\mp\zombies\_zm_weapons::is_weapon_upgraded( primaryweapons[i] ) )
                    primary_weapons_to_take[primary_weapons_to_take.size] = primaryweapons[i];
            }
            if ( primary_weapons_to_take.size > weapon_limit )
            {
                if ( !isdefined( level.player_too_many_weapons_monitor_callback ) || self [[ level.player_too_many_weapons_monitor_callback ]]( primary_weapons_to_take ) )
                {
                    self maps\mp\zombies\_zm_stats::increment_map_cheat_stat( "cheat_too_many_weapons" );
                    self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_too_many_weapons", 0 );
                    self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_total", 0 );
                    self takeweapon(primary_weapons_to_take[primary_weapons_to_take.size - 1]);
                    // self thread player_too_many_weapons_monitor_takeaway_sequence( primary_weapons_to_take );
                    // self waittill( "player_too_many_weapons_monitor_takeaway_sequence_done" );
                }
            }
            wait( get_player_too_many_weapons_monitor_wait_time() );
        }
    }
}

// ============================================================================
//  zmqol_dev_commands  -  in-chat developer commands
//
//  Requested 2026-08-02 for dev testing, matching the setup the user's friend
//  runs:
//      !p <amount>   give yourself that many points (default 1000 if the amount
//                    is missing or not a number). Negative values are allowed so
//                    you can take points away too.
//      !god          toggle invulnerability on/off, with feedback either way.
//
//  sv_cheats is forced to 1 here so the commands behave consistently and the
//  usual Plutonium console cheats keep working alongside them.
//
//  Mechanism: T6 fires a level notify "say" carrying the speaker and the raw
//  message. Verified against a known-working release rather than guessed -
//  H:\Claude\BO2-GSC-Releases\Zombies Mods\Give Points Command uses exactly
//  level waittill( "say", player, message ). Builtins used were checked against
//  the stock dump too: enableinvulnerability/disableinvulnerability appear in
//  _hostmigration.gsc and add_to_player_score is _zm_score.gsc:311. iprintlnbold
//  is used for feedback because tell() does not exist in T6.
//
//  This lives in quality_of_life.gsc (a ROOT script) so it is available on every
//  map, and every reference is to a core script, so AI_CONTEXT rule 2 is safe.
// ============================================================================
// ============================================================================
//  zmqol_credits_banner
//
//  Prints the mod's own banner once per player at the start of a game.
//
//  "^5" is BO2's LIGHT blue / cyan (^1 red, ^2 green, ^3 yellow, ^4 blue,
//  ^5 light blue, ^6 pink, ^7 white) - same convention the chat commands below
//  use. It was ^4 (dark blue) up to v1.18.2; the user asked for the lighter one.
//
//  Waits on "initial_blackscreen_passed" for the same reason every other HUD
//  thread in this file does: printing before it puts the line behind the loading
//  screen where nobody sees it. The extra second lets the round-start text clear
//  first. iprintln (bottom-left feed) rather than iprintlnbold, so it does not
//  sit across the middle of the screen while you are playing.
// ============================================================================
zmqol_credits_banner()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_credits_banner_print();
    }
}

zmqol_credits_banner_print()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );
    wait 1;

    self iprintln( "^5Quality Of Life Mod | Credits: DavidHiFi & Synarxis" );
}

zmqol_dev_commands()
{
    setdvar( "sv_cheats", 1 );
    level thread zmqol_dev_command_listener();
}

zmqol_dev_command_listener()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        // 🛑 ARGUMENT ORDER IS ( message, player ) - NOT ( player, message ).
        // v1.5.0 had these the wrong way round, which is why "!p 10000" silently
        // did nothing: strtok() was being handed a player ENTITY. Confirmed
        // against a working Plutonium T6 mod the user already runs,
        // H:\Claude\littlegods-mod\chat.gsc:21 - `level waittill("say", message,
        // player)`. The BO2-GSC-Releases sample has them the other way round and
        // is what led me wrong; trust the mod that actually runs on Plutonium.
        level waittill( "say", message, player );

        if ( !isdefined( player ) || !isdefined( message ) )
            continue;

        if ( isdefined( level.intermission ) && level.intermission )
            continue;

        message = tolower( message );

        // Accept ALL THREE prefixes. The user asked for "!", but Plutonium appears
        // to swallow a leading "!" as a console command - typing "!god" printed
        // "unknown cmd" rather than reaching script - and the reference mod above
        // uses ".". Supporting all of them means whichever survives to GSC works.
        //
        // "/" added 2026-08-03 at the user's request. Same caveat as "!": the
        // client may treat a leading "/" in chat as a console command and never
        // fire the "say" notify. "." is the one prefix proven to reach script, so
        // that is what the help panel leads with.
        if ( message.size < 2 )
            continue;

        if ( message[0] != "!" && message[0] != "." && message[0] != "/" )
            continue;

        tokens = strtok( message, " " );

        if ( !isdefined( tokens ) || tokens.size == 0 )
            continue;

        // Strip the prefix character, leaving the bare command word.
        cmd = getsubstr( tokens[0], 1 );

        if ( cmd == "p" )
        {
            // int() of anything non-numeric is 0, so treat 0 as "no amount given"
            // and fall back to a sensible default rather than doing nothing.
            amount = 1000;

            if ( tokens.size > 1 && int( tokens[1] ) != 0 )
                amount = int( tokens[1] );

            player maps\mp\zombies\_zm_score::add_to_player_score( amount, 1 );
            player iprintln( "^2[zm_qol] ^7points ^2+" + amount );
        }
        else if ( cmd == "god" )
        {
            if ( isdefined( player.zmqol_god ) && player.zmqol_god )
            {
                player.zmqol_god = 0;
                player disableinvulnerability();
                player iprintln( "^1[zm_qol] godmode OFF" );
            }
            else
            {
                player.zmqol_god = 1;
                player enableinvulnerability();
                player iprintln( "^2[zm_qol] godmode ON" );
            }
        }
        else if ( cmd == "ghost" )
        {
            // self.ignoreme is the stock "AI does not target me" flag - it is what
            // maps\mp\zombies\_zm_spawner sets on a fresh zombie and what the
            // afk_on_command_by_THS script uses for the same purpose.
            if ( isdefined( player.zmqol_ghost ) && player.zmqol_ghost )
            {
                player.zmqol_ghost = 0;
                player.ignoreme = 0;
                player iprintln( "^1[zm_qol] ghost OFF ^7- zombies can see you" );
            }
            else
            {
                player.zmqol_ghost = 1;
                player.ignoreme = 1;
                player iprintln( "^2[zm_qol] ghost ON ^7- zombies ignore you" );
            }
        }
        else if ( cmd == "afk" )
        {
            // Ghost + godmode together, which is what the AFK script does. No
            // 5-minute cap or 30-minute cooldown here: that exists upstream to stop
            // abuse in public games, and this is a private-match QoL mod.
            if ( isdefined( player.zmqol_afk ) && player.zmqol_afk )
            {
                player.zmqol_afk = 0;
                player.ignoreme = 0;

                if ( !isdefined( player.zmqol_god ) || !player.zmqol_god )
                    player disableinvulnerability();

                player iprintln( "^1[zm_qol] AFK OFF" );
            }
            else
            {
                player.zmqol_afk = 1;
                player.ignoreme = 1;
                player enableinvulnerability();
                player iprintln( "^2[zm_qol] AFK ON ^7- ignored and invulnerable" );
            }
        }
        else if ( cmd == "fly" )
        {
            if ( isdefined( player.zmqol_fly ) && player.zmqol_fly )
            {
                player.zmqol_fly = 0;
                player notify( "zmqol_fly_off" );
                player iprintln( "^1[zm_qol] fly OFF" );
            }
            else
            {
                player.zmqol_fly = 1;
                player thread zmqol_fly_think();
                player iprintln( "^2[zm_qol] fly ON ^7- WASD to move, JUMP up, STANCE down, SPRINT boost" );
            }
        }
        else if ( cmd == "infiniteammo" || cmd == "infammo" )
        {
            if ( isdefined( player.zmqol_infammo ) && player.zmqol_infammo )
            {
                player.zmqol_infammo = 0;
                player notify( "zmqol_infammo_off" );
                player iprintln( "^1[zm_qol] infinite ammo OFF" );
            }
            else
            {
                player.zmqol_infammo = 1;
                player thread zmqol_infinite_ammo_think();
                player iprintln( "^2[zm_qol] infinite ammo ON" );
            }
        }
        else if ( cmd == "infinitesprint" || cmd == "infsprint" )
        {
            if ( isdefined( player.zmqol_infsprint ) && player.zmqol_infsprint )
            {
                player.zmqol_infsprint = 0;
                player notify( "zmqol_infsprint_off" );
                player unsetperk( "specialty_unlimitedsprint" );
                player iprintln( "^1[zm_qol] infinite sprint OFF" );
            }
            else
            {
                player.zmqol_infsprint = 1;
                player thread zmqol_infinite_sprint_think();
                player iprintln( "^2[zm_qol] infinite sprint ON" );
            }
        }
        else if ( cmd == "reload" )
        {
            player zmqol_fill_all_ammo();
            player iprintln( "^2[zm_qol] ^7all weapons and equipment refilled" );
        }
        else if ( cmd == "nozmspawns" )
        {
            // "spawn_zombies" is the stock flag round_spawning waits on - see
            // _hostmigration.gsc, which clears and re-sets it around a migration.
            if ( isdefined( level.zmqol_nospawns ) && level.zmqol_nospawns )
            {
                level.zmqol_nospawns = 0;
                flag_set( "spawn_zombies" );
                player iprintln( "^1[zm_qol] zombie spawning ON" );
            }
            else
            {
                level.zmqol_nospawns = 1;
                flag_clear( "spawn_zombies" );
                player iprintln( "^2[zm_qol] zombie spawning OFF ^7- existing zombies remain" );
            }
        }
        else if ( cmd == "where" )
        {
            //  v1.40.1: reports YAW as well as position. A coordinate alone is
            //  half an answer when the thing being placed is a machine - it has
            //  to face out of the wall, and "back left corner" in a screenshot
            //  cannot be resolved without knowing which way the camera was
            //  pointing. Stand where you want it, face the way it should face,
            //  and this one line is now the whole spec.
            v_pos = player.origin;
            v_ang = player getplayerangles();
            n_yaw = int( v_ang[1] );

            if ( n_yaw < 0 )
                n_yaw += 360;

            player iprintln( "^2[zm_qol] ^7x " + int( v_pos[0] ) + "  y " + int( v_pos[1] ) + "  z " + int( v_pos[2] ) + "  ^2yaw ^7" + n_yaw );
            println( "[zm_qol] WHERE " + level.script + " (" + v_pos[0] + ", " + v_pos[1] + ", " + v_pos[2] + ") yaw " + n_yaw );
        }
        else if ( cmd == "giveperks" )
        {
            n_given = player zmqol_give_all_perks();
            player iprintln( "^2[zm_qol] ^7gave " + n_given + " perk(s)" );
        }
        else if ( cmd == "removeperks" )
        {
            n_taken = player zmqol_remove_all_perks();
            player iprintln( "^1[zm_qol] ^7removed " + n_taken + " perk(s)" );
        }
        //  🛑 THESE TWO MUST STAY BELOW giveperks / removeperks. "giveperks"
        //  starts with "give", so a prefix test placed above would swallow it
        //  and never reach the all-perks handler. The else-if chain is the
        //  ordering guarantee - do not reorder these four blocks.
        else if ( cmd.size > 4 && getsubstr( cmd, 0, 4 ) == "give" && isdefined( zmqol_perk_from_alias( getsubstr( cmd, 4, cmd.size ) ) ) )
        {
            perk = zmqol_perk_from_alias( getsubstr( cmd, 4, cmd.size ) );
            player zmqol_give_one_perk( perk );
        }
        else if ( cmd.size > 6 && getsubstr( cmd, 0, 6 ) == "remove" && isdefined( zmqol_perk_from_alias( getsubstr( cmd, 6, cmd.size ) ) ) )
        {
            perk = zmqol_perk_from_alias( getsubstr( cmd, 6, cmd.size ) );
            player zmqol_remove_one_perk( perk );
        }
        else if ( cmd == "pack" )
        {
            player zmqol_pack( 1 );
        }
        else if ( cmd == "unpack" )
        {
            player zmqol_pack( 0 );
        }
        else if ( cmd == "help" )
        {
            player thread zmqol_print_help();
        }
        else if ( cmd == "powerups" )
        {
            player thread zmqol_list_powerups();
        }
        else if ( cmd == "powerup" || cmd == "drop" )
        {
            // Bare ".powerup" lists what this map actually registered, which is
            // the only reliable way to know - the set differs per map.
            if ( tokens.size < 2 )
            {
                player thread zmqol_list_powerups();
                continue;
            }

            player zmqol_spawn_powerup( tokens[1] );
        }
        else
        {
            // Fall-through: short forms (".nuke", ".maxammo", ".dm") resolve
            // through the same lookup, so there is exactly one spawn path.
            // Returns undefined for anything that is not a powerup, which is
            // how an unrecognised command still does nothing.
            str_powerup = zmqol_powerup_alias( cmd );

            if ( isdefined( str_powerup ) )
                player zmqol_spawn_powerup( str_powerup );
        }
    }
}

// ============================================================================
//  .giveperks / .removeperks
//
//  🛑 level._custom_perks IS NOT THE PERK LIST. Both commands used to walk only
//  that array, and the user's report shows exactly what that costs:
//  ".removeperks ... said it removed 2 perks but i still have 7". T6 keeps perks
//  in two places and _custom_perks is the smaller one:
//
//    - the NINE core perks are flags:  level.zombiemode_using_<name>_perk.
//      _zm_perks::init() turns each on with its own turn_<name>_on() thread and
//      never puts them in _custom_perks (see _zm_perks.gsc:75-99, where the core
//      perks are nine explicit if-blocks and the _custom_perks loop is separate).
//    - only perks registered through register_perk_basic_info land in
//      _custom_perks: Electric Cherry, PhD Flopper, Vulture Aid.
//
//  So on a map with two customs it removed two and left the seven core ones -
//  precisely what was reported. zmqol_map_perks() below reads BOTH, and is the
//  same enumeration wunderfizz.gsc::getPerks() already uses to decide what the
//  machine may hand out, so the two agree on what "every perk on this map"
//  means.
//
//  give_perk( perk, bought ) is the stock entry point (_zm_perks.gsc:1982), and
//  is also the function this mod already replaceFuncs for the perk pop-up HUD,
//  so perks handed out here animate and count exactly like bought ones.
//
//  🛑 REMOVAL IS A NOTIFY, NOT A CALL. There is no stock "remove a perk"
//  function - unsetperk() sits inside perk_think(), which is a waiting loop:
//        perk_str = perk + "_stop";
//        result = self waittill_any_return( "fake_death", "death",
//                                           "player_downed", perk_str );
//  Notifying "<perk>_stop" is therefore the supported way out, and it runs the
//  whole stock teardown - unsetperk, num_perks--, and the per-perk switch that
//  puts Juggernog's max health back. Calling unsetperk() directly would skip all
//  of that and leave the player on 250 health with no Jugg.
// ============================================================================
//  Every perk this map actually has: the nine core flags plus whatever is in
//  level._custom_perks. Mirrors wunderfizz.gsc::getPerks(), minus its Buried
//  PhD exclusion - that exists because Buried's Wunderfizz must not OFFER a perk
//  the map cannot support, which is not a reason to refuse to strip it if the
//  player somehow has it.
zmqol_map_perks()
{
    a_perks = [];

    if ( isdefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
        a_perks[a_perks.size] = "specialty_armorvest";

    if ( isdefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
        a_perks[a_perks.size] = "specialty_rof";

    if ( isdefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
        a_perks[a_perks.size] = "specialty_longersprint";

    if ( isdefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
        a_perks[a_perks.size] = "specialty_fastreload";

    if ( isdefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
        a_perks[a_perks.size] = "specialty_quickrevive";

    if ( isdefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
        a_perks[a_perks.size] = "specialty_additionalprimaryweapon";

    if ( isdefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
        a_perks[a_perks.size] = "specialty_deadshot";

    if ( isdefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
        a_perks[a_perks.size] = "specialty_scavenger";

    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
        a_perks[a_perks.size] = "specialty_finalstand";

    if ( isdefined( level._custom_perks ) )
    {
        a_keys = getarraykeys( level._custom_perks );

        for ( i = 0; i < a_keys.size; i++ )
        {
            if ( !isinarray( a_perks, a_keys[i] ) )
                a_perks[a_perks.size] = a_keys[i];
        }
    }

    return a_perks;
}

// ============================================================================
//  .give<perk> / .remove<perk>  -  one perk at a time
//
//  Parsed as a PREFIX rather than 24 explicit commands, so ".givejug" and
//  ".removejug" come out of the same two blocks in the chat handler. The alias
//  table below is deliberately generous - the whole point is not having to
//  remember whether it is "stam" or "staminup" mid-round.
//
//  🛑 THE SPECIALTY NAMES ARE THE TRAP, NOT THE ALIASES. Several read like the
//  wrong perk and models routinely guess them backwards, so they are taken from
//  getPerkName() below, which is already the shipped mapping:
//      specialty_armorvest              Jugger-Nog       (NOT flak/armor)
//      specialty_rof                    Double Tap 2.0
//      specialty_longersprint           Stamin-Up        (NOT marathon-the-perk)
//      specialty_additionalprimaryweapon Mule Kick
//      specialty_flakjacket             PhD Flopper      (NOT Jugger-Nog)
//      specialty_scavenger              Tombstone        (NOT a scavenger perk)
//      specialty_finalstand             Who's Who        (NOT last stand)
//      specialty_nomotionsensor         Vulture Aid
//      specialty_grenadepulldeath       Electric Cherry
//
//  Returns undefined for anything unrecognised, which is what lets the chat
//  handler use it as the test for "is this a perk command at all" - so a typo
//  falls through to the normal unknown-command path instead of doing something
//  surprising.
// ============================================================================
zmqol_perk_from_alias( str_alias )
{
    switch ( str_alias )
    {
        case "jug":
        case "jugg":
        case "juggernog":
        case "juggernaut":
            return "specialty_armorvest";
        case "speed":
        case "speedcola":
        case "sleight":
            return "specialty_fastreload";
        case "dtap":
        case "doubletap":
        case "double":
            return "specialty_rof";
        case "stam":
        case "stamin":
        case "staminup":
            return "specialty_longersprint";
        case "mule":
        case "mulekick":
            return "specialty_additionalprimaryweapon";
        case "revive":
        case "quickrevive":
            return "specialty_quickrevive";
        case "deadshot":
        case "ads":
            return "specialty_deadshot";
        case "phd":
        case "flopper":
        case "phdflopper":
            return "specialty_flakjacket";
        case "tombstone":
        case "tomb":
            return "specialty_scavenger";
        case "whoswho":
        case "who":
            return "specialty_finalstand";
        case "cherry":
        case "electriccherry":
            return "specialty_grenadepulldeath";
        case "vulture":
        case "vultureaid":
            return "specialty_nomotionsensor";
    }

    return undefined;
}

//  Give one perk. Refuses perks the MAP does not have, because give_perk() on an
//  unregistered perk sets the specialty without any of the machinery behind it -
//  no clientfield, no perk_think loop - which looks like it worked and is not
//  removable afterwards. zmqol_map_perks() is the same enumeration .giveperks
//  and the Wunderfizz both use, so the three agree on what this map supports.
zmqol_give_one_perk( perk )
{
    str_name = getPerkName( perk );

    if ( self hasperk( perk ) )
    {
        self iprintln( "^3[zm_qol] ^7you already have ^3" + str_name );
        return;
    }

    if ( !zmqol_perk_on_this_map( perk ) )
    {
        self iprintln( "^1[zm_qol] ^3" + str_name + " ^7is not available on this map" );
        return;
    }

    self maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
    self iprintln( "^2[zm_qol] ^7gave ^2" + str_name );
}

//  Remove one perk. Same notify teardown .removeperks uses - see the block above
//  zmqol_map_perks() for why this is a notify and not a call to unsetperk().
zmqol_remove_one_perk( perk )
{
    str_name = getPerkName( perk );

    if ( !self hasperk( perk ) )
    {
        self iprintln( "^3[zm_qol] ^7you do not have ^3" + str_name );
        return;
    }

    self notify( perk + "_stop" );
    self iprintln( "^1[zm_qol] ^7removed ^1" + str_name );
}

//  Is this perk registered on the current map?
zmqol_perk_on_this_map( perk )
{
    a_perks = zmqol_map_perks();

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( a_perks[i] == perk )
            return 1;
    }

    return 0;
}

zmqol_give_all_perks()
{
    a_perks = zmqol_map_perks();
    n_given = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( self hasperk( a_perks[i] ) )
            continue;

        self maps\mp\zombies\_zm_perks::give_perk( a_perks[i], 0 );
        n_given++;
        wait 0.05;
    }

    return n_given;
}

zmqol_remove_all_perks()
{
    a_perks = zmqol_map_perks();
    n_taken = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( !self hasperk( a_perks[i] ) )
            continue;

        self notify( a_perks[i] + "_stop" );
        n_taken++;
        wait 0.05;
    }

    // Anything the map-perk list did not cover - a perk from a source we do not
    // enumerate - would survive the loop above and leave the count wrong again.
    // hasperk() is the ground truth, so sweep whatever is left by the same
    // notify, and report the honest total.
    wait 0.1;

    a_left = zmqol_perks_still_held();

    for ( i = 0; i < a_left.size; i++ )
    {
        self notify( a_left[i] + "_stop" );
        n_taken++;
        wait 0.05;
    }

    return n_taken;
}

//  The full specialty set a T6 zombies player can be holding. Only used as a
//  backstop for .removeperks, so a perk added by some path zmqol_map_perks()
//  does not know about still comes off.
zmqol_perks_still_held()
{
    a_all = [];
    a_all[a_all.size] = "specialty_armorvest";
    a_all[a_all.size] = "specialty_rof";
    a_all[a_all.size] = "specialty_longersprint";
    a_all[a_all.size] = "specialty_fastreload";
    a_all[a_all.size] = "specialty_quickrevive";
    a_all[a_all.size] = "specialty_additionalprimaryweapon";
    a_all[a_all.size] = "specialty_deadshot";
    a_all[a_all.size] = "specialty_scavenger";
    a_all[a_all.size] = "specialty_finalstand";
    a_all[a_all.size] = "specialty_grenadepulldeath";
    a_all[a_all.size] = "specialty_flakjacket";
    a_all[a_all.size] = "specialty_nomotionsensor";

    a_held = [];

    for ( i = 0; i < a_all.size; i++ )
    {
        if ( self hasperk( a_all[i] ) )
            a_held[a_held.size] = a_all[i];
    }

    return a_held;
}

// ============================================================================
//  .help
//
//  🛑 REWRITTEN FROM iprintln TO A HUD PANEL. The old version pushed 14 lines
//  into the bottom-left feed 0.1s apart. The user's report: "it scrolls through
//  all the commands ... so quickly and you can't even read them in time" - the
//  feed is only a few lines deep and expires each line on a timer, so the list
//  was always scrolling itself off before it finished printing. Staggering the
//  writes could never fix that; the feed is the wrong widget.
//
//  This draws a real panel instead: one hud element per line, set ONCE and left
//  alone (per CLAUDE.md section 6 - re-settext every frame floods reliable
//  commands with EXE_SERVERCOMMANDOVERFLOW).
//
//  PURELY TOGGLED - the 20-second auto-close v1.19.1 shipped with is gone, at
//  the user's request: "make the .help command be toggable so when it shows up
//  on screen i have to do .help or !help again to hide it". It now stays until
//  a second .help / !help, and nothing else takes it down.
//
//  🛑 THE LIST IS NOW THE REAL COMMAND SET. The user asked that it show only the
//  dot commands actually added. It had drifted: ".dm  spawn a Death Machine" was
//  listed but has no handler in zmqol_dev_command_listener() - the Death Machine
//  is a power-up, not a chat command - and ".infiniteammo" was the only entry
//  that did not show its short form. Verified against every `cmd == "..."` branch
//  in the listener: p, god, ghost, afk, fly, infiniteammo/infammo, reload,
//  nozmspawns, where, pack, unpack, giveperks, removeperks, help. Fourteen, and
//  fourteen are listed. If a command is added, add it here in the same pass.
// ============================================================================
// ============================================================================
//  .pack / .unpack
//
//  Pack-a-Punch the held weapon, or put it back to stock, with no machine, no
//  cost and no animation.
//
//  Modelled on the instant-Pack-a-Punch path already in this file (see the
//  Trigger loop around line 1760) - same stock calls, minus the trigger, the
//  score deduction and the fx:
//      switch_from_alt_weapon()  first, so packing while holding the alt form of
//                                a dual-mode weapon does not strand you on it
//      get_upgrade_weapon()      base -> upgraded
//      get_base_weapon_name( w, 0 )  upgraded -> base. The second argument is
//                                "return the input if it is NOT upgraded"; we
//                                pass 0 so an un-upgraded weapon comes back
//                                undefined and we can say so instead of
//                                re-giving the same gun.
//      get_pack_a_punch_weapon_options()  the camo/reticle blob, so a packed
//                                gun looks packed. This file overrides that
//                                function (see main()); it is the merged
//                                animated-camo version, which is what we want.
//
//  Ammo is carried across rather than reset, clamped to the new clip size the
//  same way the machine does it.
//
//  can_upgrade_weapon() is the stock gate (_zm_weapons.gsc:1786) and screens out
//  the riotshield, equipment, placeable mines and the revive tool, so those are
//  not re-tested here.
// ============================================================================
zmqol_pack( b_upgrade )
{
    str_weapon = self getcurrentweapon();

    if ( !isdefined( str_weapon ) || str_weapon == "none" || str_weapon == "zombie_fists_zm" )
    {
        self iprintln( "^1[zm_qol] ^7nothing in your hands to do that to" );
        return;
    }

    b_is_upgraded = is_weapon_upgraded( str_weapon );

    // 🛑 can_upgrade_weapon() IS THE WRONG GATE FOR .unpack, and gating both
    //    directions on it is what the user hit: ".unpack ... only seems to be
    //    working for some weapons" - fine on the DSR-50 and the PDW, refused on
    //    Mustang & Sally and Hades.
    //
    //    _zm_weapons.gsc:1786 - for a weapon that is ALREADY upgraded it returns
    //        level.zombiemode_reusing_pack_a_punch && weapon_supports_attachments( w )
    //    i.e. "can this be RE-packed for a different attachment". The DSR-50 and
    //    PDW take attachments so it said yes; Mustang & Sally and Hades are
    //    unique Pack-a-Punch weapons with no attachment options, so it said no
    //    and .unpack refused a weapon it could have reverted perfectly well.
    //
    //    Reverting only needs the upgraded -> base mapping, and every upgraded
    //    weapon has one by construction: add_zombie_weapon() writes
    //    level.zombie_weapons_upgraded[upgrade_name] = weapon_name (:546), which
    //    is the same table is_weapon_upgraded() reads. So .unpack asks only
    //    "is it upgraded", and can_upgrade_weapon() is left to guard .pack,
    //    where it is the correct question.
    if ( b_upgrade )
    {
        if ( b_is_upgraded )
        {
            self iprintln( "^1[zm_qol] ^7already Pack-a-Punched - use ^3.unpack" );
            return;
        }

        if ( !can_upgrade_weapon( str_weapon ) )
        {
            self iprintln( "^1[zm_qol] ^7that weapon cannot be Pack-a-Punched" );
            return;
        }
    }
    else if ( !b_is_upgraded )
    {
        self iprintln( "^1[zm_qol] ^7that weapon is not Pack-a-Punched" );
        return;
    }

    n_clip = self getweaponammoclip( str_weapon );
    n_stock = self getweaponammostock( str_weapon );

    str_weapon = self maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( str_weapon );

    if ( b_upgrade )
        str_new = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( str_weapon, will_upgrade_weapon_as_attachment( str_weapon ) );
    else
        str_new = maps\mp\zombies\_zm_weapons::get_base_weapon_name( str_weapon, 0 );

    if ( !isdefined( str_new ) || str_new == "" || str_new == str_weapon )
    {
        // No ternary in T6 GSC - spell it out.
        if ( b_upgrade )
            self iprintln( "^1[zm_qol] ^7no upgraded version of that weapon exists" );
        else
            self iprintln( "^1[zm_qol] ^7no stock version of that weapon exists" );

        return;
    }

    self takeweapon( str_weapon );

    if ( b_upgrade )
        self giveweapon( str_new, 0, self maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( str_new ) );
    else
        self giveweapon( str_new );

    n_clip_size = weaponclipsize( str_new );

    if ( n_clip > n_clip_size )
        n_clip = n_clip_size;

    self setweaponammoclip( str_new, n_clip );
    self setweaponammostock( str_new, n_stock );
    self switchtoweapon( str_new );

    if ( b_upgrade )
    {
        self playsound( "zmb_perks_packa_ready" );
        self iprintln( "^2[zm_qol] ^7Pack-a-Punched" );
    }
    else
    {
        self iprintln( "^2[zm_qol] ^7back to stock" );
    }
}

zmqol_help_lines()
{
    //  🛑 LINE COUNT IS A HARD BUDGET, NOT A STYLE CHOICE. The user's screenshot
    //  shows this panel stopping dead after ".removeperks" - the 12th line - with
    //  everything below it, power-ups included, simply absent. Nothing errored:
    //  a client has a fixed HUD-element allowance and this mod already spends
    //  ~13 of it on permanent elements (health bar, name, timer, zombie counter,
    //  shield, the perk pop-up's three, the notifier). One createfontstring per
    //  command line ran the budget out mid-list, and every extra command added
    //  since has been invisible.
    //
    //  So commands are GROUPED. Grouping is what keeps the whole list inside the
    //  allowance; do not expand this back to one line per command, and if you
    //  add commands, add them to an existing line.
    a_lines = [];
    a_lines[a_lines.size] = "^5Quality Of Life ^7- chat commands (prefix ^3.^7 ^3!^7 or ^3/^7)";
    a_lines[a_lines.size] = "^3.help ^7show/hide   ^3.p <n> ^7points   ^3.where ^7coords";
    a_lines[a_lines.size] = "^3.god ^7godmode   ^3.ghost ^7ignored   ^3.afk ^7both";
    a_lines[a_lines.size] = "^3.fly ^7noclip (WASD, jump/stance up/down, melee stops)";
    a_lines[a_lines.size] = "^3.infammo ^7never run dry   ^3.infsprint ^7never tire   ^3.reload ^7refill";
    a_lines[a_lines.size] = "^3.pack ^7/ ^3.unpack ^7Pack-a-Punch the held weapon";
    a_lines[a_lines.size] = "^3.giveperks^7/^3.removeperks ^7  ^3.nozmspawns ^7spawns";
    //  One line, not two - see the budget note above. The alias list has to be
    //  discoverable somewhere or the per-perk commands may as well not exist,
    //  so it rides on the same line as the syntax rather than getting its own.
    a_lines[a_lines.size] = "^3.give^7/^3.remove^7 + ^3jug speed dtap stam mule revive deadshot phd tombstone whoswho cherry vulture";
    a_lines[a_lines.size] = "^3.powerups ^7list   ^3.powerup <name> ^7/ ^3.drop <name> ^7spawn one";
    a_lines[a_lines.size] = "^5console: ^3rapid_fire night_mode character coop_pause no_power lod_fix";
    a_lines[a_lines.size] = "^5console: ^3hud_all hud_timer hud_health_bar hud_remaining hud_zone";
    a_lines[a_lines.size] = "^5console: ^3hud_round_timer hud_color ^7\"1 1 1\"  ^3hud_color_health";

    // 🛑 The tail of this panel is GENERATED, not typed - user: "make sure that
    // the .help command always is updated to show all the custom added chat
    // commands that are in my mod". A hand-written list is a second copy of the
    // truth and drifts the moment a command is added; every power-up is its own
    // command, so the hand-written version could never have been complete.
    //
    // level.zombie_powerups is the same runtime source .powerup itself resolves
    // against, and stock only populates it with power-ups the map actually
    // included (_zm_powerups.gsc:419 early-returns otherwise). So this prints
    // exactly the set that will work HERE - Origins shows zombie_blood, Buried
    // does not - and a power-up added later shows up with no edit to this
    // function.
    if ( isdefined( level.zombie_powerups ) )
    {
        a_keys = getarraykeys( level.zombie_powerups );

        if ( isdefined( a_keys ) && a_keys.size > 0 )
        {
            a_lines[a_lines.size] = "^5every power-up is also its own command ^7(" + a_keys.size + " here):";

            //  Six per line, for the budget reason above - at four per line a map
            //  with a dozen power-ups would cost three lines and push the tail of
            //  the list back off the screen, which is the bug this is fixing.
            str_line = "";
            for ( i = 0; i < a_keys.size; i++ )
            {
                if ( str_line != "" )
                    str_line = str_line + "^7 ";

                str_line = str_line + "^3." + a_keys[i];

                if ( ( i % 6 ) == 5 || i == a_keys.size - 1 )
                {
                    a_lines[a_lines.size] = "  " + str_line;
                    str_line = "";
                }
            }

            a_lines[a_lines.size] = "^7short forms: ^3.dm ^3.nuke ^3.maxammo ^3.insta ^3.dp ^3.carp ^3.sale";
        }
    }

    return a_lines;
}

zmqol_print_help()
{
    self endon( "disconnect" );

    if ( isdefined( self.zmqol_help_hud ) )
    {
        self zmqol_help_close();
        return;
    }

    a_lines = zmqol_help_lines();
    self.zmqol_help_hud = [];

    //  🛑 Hard cap. The client HUD-element allowance is what silently ate the
    //  bottom of this panel before (see zmqol_help_lines), and a generated
    //  power-up section means the length now varies by map - so a map with an
    //  unusually long list must drop a line ON PURPOSE and SAY SO, rather than
    //  vanish and look like the earlier bug all over again.
    n_max = 14;

    if ( a_lines.size > n_max )
    {
        n_dropped = a_lines.size - n_max + 1;
        a_trimmed = [];

        for ( i = 0; i < n_max - 1; i++ )
            a_trimmed[a_trimmed.size] = a_lines[i];

        a_trimmed[a_trimmed.size] = "^1...and " + n_dropped + " more - see ^3.powerups";
        a_lines = a_trimmed;
    }

    for ( i = 0; i < a_lines.size; i++ )
    {
        e_line = self createfontstring( "hudsmall", 1.1 );

        //  Tucked into the very top-left, tight line spacing: the user's
        //  screenshot had the chat feed cutting straight through the middle of
        //  the list. Chat sits well below this now.
        e_line setpoint( "TOP_LEFT", "TOP_LEFT", 8, 18 + ( i * 12 ) );
        e_line.hidewheninmenu = 1;
        e_line.foreground = 1;
        e_line settext( a_lines[i] );
        self.zmqol_help_hud[ self.zmqol_help_hud.size ] = e_line;
    }
}

zmqol_help_close()
{
    if ( !isdefined( self.zmqol_help_hud ) )
        return;

    for ( i = 0; i < self.zmqol_help_hud.size; i++ )
    {
        if ( isdefined( self.zmqol_help_hud[i] ) )
            self.zmqol_help_hud[i] destroy();
    }

    self.zmqol_help_hud = undefined;
}

// ============================================================================
//  .powerup / .drop  -  spawn any power-up registered on this map
//  (added 2026-08-03, replaces the standalone ".dm" listener)
// ----------------------------------------------------------------------------
//  🛑 THE LIST IS NOT HARDCODED, ON PURPOSE.
//
//  maps\mp\zombies\_zm_powerups::add_zombie_powerup() early-returns when
//  level.zombie_include_powerups is defined and does not contain the powerup
//  (stock _zm_powerups.gsc:419-420). So level.zombie_powerups ends up holding
//  exactly the set the current map included - no more, no less. Iterating it
//  is therefore the only correct answer to "what can I spawn here", and it
//  picks up:
//    - the per-map ones a fixed list would miss ("zombie_blood" is Origins
//      only, "blue_monkey"/"the_cure" are likewise map-specific),
//    - this mod's own custom "deathmachine", with no special case.
//
//  Spawning goes through the stock specific_powerup_drop( name, origin )
//  (stock _zm_powerups.gsc:545), which is what the game itself calls. That one
//  call does powerup_setup + timeout + wobble + grab + move + emp. Spawning
//  the model directly would give a prop that just sits there.
//
//  The 70-unit forward offset is carried over verbatim from the old ".dm"
//  handler, which came from this file's own powerup_test() debug function.
// ============================================================================
zmqol_spawn_powerup( str_name )
{
    if ( !isdefined( str_name ) || str_name == "" )
        return;

    if ( !isdefined( level.zombie_powerups ) || !isdefined( level.zombie_powerups[ str_name ] ) )
    {
        self iprintln( "^1[zm_qol] ^7no power-up ^3" + str_name + "^7 on this map - try ^3.powerups" );
        return;
    }

    v_drop = self.origin + vectorscale( anglestoforward( self.angles ), 70 );
    level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop( str_name, v_drop );
    self iprintln( "^2[zm_qol] ^7dropped ^3" + str_name );
}

// ----------------------------------------------------------------------------
//  Short forms. A bare command word is checked against the registered keys
//  FIRST, so every real powerup name works as its own command (".nuke",
//  ".carpenter", ".tesla", ".full_ammo") with nothing to maintain. The table
//  below only exists for the names people actually type instead.
//
//  Returns undefined when the word is not a powerup - the listener relies on
//  that to leave unknown commands alone.
// ----------------------------------------------------------------------------
zmqol_powerup_alias( str_cmd )
{
    if ( !isdefined( str_cmd ) || !isdefined( level.zombie_powerups ) )
        return undefined;

    if ( isdefined( level.zombie_powerups[ str_cmd ] ) )
        return str_cmd;

    str_canon = undefined;

    switch ( str_cmd )
    {
        case "dm":
        case "deathmachine":
        case "minigun":          str_canon = "minigun";              break;
        case "ammo":
        case "maxammo":
        case "fullammo":         str_canon = "full_ammo";            break;
        case "ik":
        case "insta":
        case "instakill":        str_canon = "insta_kill";           break;
        case "dp":
        case "x2":
        case "doublepoints":     str_canon = "double_points";        break;
        case "sale":
        case "firesale":         str_canon = "fire_sale";            break;
        case "bonfire":          str_canon = "bonfire_sale";         break;
        case "carp":             str_canon = "carpenter";            break;
        case "perk":
        case "freeperk":         str_canon = "free_perk";            break;
        case "blood":
        case "zombieblood":      str_canon = "zombie_blood";         break;
        case "cure":             str_canon = "the_cure";             break;
        case "monkey":
        case "bluemonkey":       str_canon = "blue_monkey";          break;
        case "gun":
        case "randomgun":
        case "randomweapon":     str_canon = "random_weapon";        break;
        case "meat":
        case "meatstink":        str_canon = "meat_stink";           break;
        case "emptyclip":        str_canon = "empty_clip";           break;
        case "loseperk":         str_canon = "lose_perk";            break;
        case "losepoints":       str_canon = "lose_points_team";     break;
        case "bonuspoints":      str_canon = "bonus_points_player";  break;
        case "teampoints":       str_canon = "bonus_points_team";    break;
        case "teller":
        case "withdrawl":        str_canon = "teller_withdrawl";     break;
        default:
            return undefined;
    }

    // 🛑 "dm" is the interesting case. This mod's custom Death Machine registers
    // as "deathmachine", but stock's own minigun powerup is "minigun" and some
    // maps have that instead. Try the mod's name first, then fall back, so ".dm"
    // does the obvious thing on every map rather than erroring where the custom
    // powerup was never registered.
    if ( str_cmd == "dm" || str_cmd == "deathmachine" )
    {
        if ( isdefined( level.zombie_powerups[ "deathmachine" ] ) )
            return "deathmachine";
    }

    if ( isdefined( level.zombie_powerups[ str_canon ] ) )
        return str_canon;

    // Known short form, but this map did not register it. Return the canonical
    // name anyway so zmqol_spawn_powerup() prints the "not on this map" hint
    // instead of the command silently doing nothing.
    return str_canon;
}

zmqol_list_powerups()
{
    self endon( "disconnect" );

    if ( !isdefined( level.zombie_powerups ) )
    {
        self iprintln( "^1[zm_qol] ^7this map registers no power-ups" );
        return;
    }

    a_keys = getarraykeys( level.zombie_powerups );

    if ( !isdefined( a_keys ) || a_keys.size == 0 )
    {
        self iprintln( "^1[zm_qol] ^7this map registers no power-ups" );
        return;
    }

    self iprintln( "^5[zm_qol] ^3.powerup <name>^7 - " + a_keys.size + " on this map:" );

    // Batched three to a line, with a beat between writes. CLAUDE.md section 6:
    // one iprintln per entry would push ~20 reliable commands in a frame and the
    // feed expires lines on a timer anyway, so the top of the list scrolls off
    // before the bottom arrives - the exact problem the .help panel was built to
    // solve.
    str_line = "";
    n_per_line = 3;

    for ( i = 0; i < a_keys.size; i++ )
    {
        if ( str_line != "" )
            str_line = str_line + "^7, ";

        str_line = str_line + "^3" + a_keys[i];

        if ( ( i % n_per_line ) == ( n_per_line - 1 ) || i == ( a_keys.size - 1 ) )
        {
            self iprintln( str_line );
            str_line = "";
            wait 0.05;
        }
    }
}

// ============================================================================
//  Chat-command helpers
// ============================================================================

//  getweaponslist( 1 ) is what stock Max Ammo uses (_zm_powerups.gsc:1585) and it
//  covers offhand too - the stock code right below it tests is_lethal_grenade()
//  on the results - so grenades, claymores and equipment all refill from this one
//  call. weaponclipsize() returns 0 for weapons with no clip (grenades), so the
//  setweaponammoclip is guarded rather than applied blindly.
zmqol_fill_all_ammo()
{
    a_weapons = self getweaponslist( 1 );

    if ( !isdefined( a_weapons ) )
        return;

    foreach ( str_weapon in a_weapons )
    {
        self givemaxammo( str_weapon );

        n_clip = weaponclipsize( str_weapon );

        if ( n_clip > 0 )
            self setweaponammoclip( str_weapon, n_clip );

        str_alt = weaponaltweaponname( str_weapon );

        if ( isdefined( str_alt ) && str_alt != "none" )
        {
            self givemaxammo( str_alt );

            n_altclip = weaponclipsize( str_alt );

            if ( n_altclip > 0 )
                self setweaponammoclip( str_alt, n_altclip );
        }
    }
}

//  Infinite sprint, for .infsprint / .infinitesprint.
//
//  specialty_unlimitedsprint is the engine's own "the sprint meter never empties"
//  flag, not something scripted on top of the meter, so there is no drain loop to
//  fight and no HUD to hide. It is verified stock and verified ZM-side:
//  _zm_turned.gsc:117 sets it on a turned player and :191 unsets it again, which
//  is also where the clean off-switch comes from.
//
//  🛑 IT IS RE-APPLIED ON EVERY SPAWN rather than set once. A specialty lives on
//  the player entity, and going down and being revived - or bleeding out into a
//  respawn - hands you a player whose specialties have been rebuilt from the perks
//  you actually hold. Set once, the toggle would read ON in the player's own state
//  while the engine had quietly dropped it, which is worse than not having it. The
//  loop costs one notify per spawn.
zmqol_infinite_sprint_think()
{
    self endon( "disconnect" );
    self endon( "zmqol_infsprint_off" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self setperk( "specialty_unlimitedsprint" );
        self waittill( "spawned_player" );
    }
}

zmqol_infinite_ammo_think()
{
    self endon( "disconnect" );
    self endon( "zmqol_infammo_off" );
    level endon( "game_ended" );

    // The half-second sweep keeps stock, alt weapons and equipment topped up.
    self thread zmqol_infinite_ammo_on_fire();

    for ( ;; )
    {
        self zmqol_fill_all_ammo();
        wait 0.5;
    }
}

// ============================================================================
//  zmqol_infinite_ammo_on_fire  -  🛑 A HALF-SECOND SWEEP CANNOT BEAT A 1-ROUND
//  MAGAZINE
//
//  User: "it works but sometimes for some weapons with low magazine counts like
//  a balistic knife which has 1 or an RPG which has 1 it automatically reloads
//  but the whole point of infinite ammo is so there's no reload."
//
//  The sweep refills every 0.5s, which is fine for a 30-round magazine - you
//  cannot empty one between ticks. On a 1-round weapon the magazine is empty the
//  instant you fire, and the engine starts the auto-reload on the NEXT FRAME,
//  long before the sweep comes round. The refill then lands mid-animation and you
//  watch a reload for ammo you already have.
//
//  So the refill has to happen on the SHOT, not on a timer. "weapon_fired" is the
//  notify the engine raises on the firing player, and refilling the clip in that
//  same frame means the magazine is never observed empty and the auto-reload is
//  never triggered at all - rather than being interrupted, which is not something
//  script can do.
//
//  📝 The general shape: a POLLING fix cannot cover an event that resolves faster
//  than the poll. When the thing you are correcting is edge-triggered, subscribe
//  to the edge.
// ============================================================================
zmqol_infinite_ammo_on_fire()
{
    self endon( "disconnect" );
    self endon( "zmqol_infammo_off" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( "weapon_fired" );

        str_weapon = self getcurrentweapon();

        if ( !isdefined( str_weapon ) || str_weapon == "none" )
            continue;

        n_clip = weaponclipsize( str_weapon );

        if ( n_clip > 0 )
            self setweaponammoclip( str_weapon, n_clip );

        self givemaxammo( str_weapon );

        // The alt weapon too, so an underbarrel launcher behaves the same way.
        str_alt = weaponaltweaponname( str_weapon );

        if ( isdefined( str_alt ) && str_alt != "none" )
        {
            n_altclip = weaponclipsize( str_alt );

            if ( n_altclip > 0 )
                self setweaponammoclip( str_alt, n_altclip );

            self givemaxammo( str_alt );
        }
    }
}

//  T6 has no player noclip builtin a script can call - traversemode( "noclip" ) is
//  AI traversal, and the real "noclip"/"ufo" move modes are client debug commands
//  (stock only ever READS them, via player isinmovemode( "ufo", "noclip" ) in
//  _zm_devgui.gsc:1128). So flight has to be hand-rolled.
//
//  🛑 v1.18.2 hand-rolled it with setorigin() every 0.05s and the user reported it
//  "just kinda bugs out my player movement" - correctly. setorigin does not turn
//  off player physics: between our calls the engine still runs gravity, ground
//  trace and world collision on a normal walking player, then we teleport it back.
//  The two fight every frame, which is the stutter, and collision is never
//  disabled, so it is not noclip at all - you cannot pass through geometry.
//
//  The mechanism that DOES work is linking the player to a mover entity.
//  playerlinkto() hands position control to that entity outright: no gravity, no
//  world collision, view left free. Stock precedent, both shapes:
//      _qrdrone.gsc:350-352      spawn( "script_origin" ) -> hide() -> playerlinkto
//      zm_alcatraz_travel.gsc:770-774  the MOTD gondola - players ride a linked
//                                      script_origin and still look around and shoot
//  so a linked player is not a frozen one.
//
//  🛑 v1.22.0 PROBE RESULT - WASD IS NOT READABLE, AND THAT IS SETTLED.
//  v1.21.2 shipped a probe printing getnormalizedmovement() for the first ~3s of a
//  flight. Every single line in console_zm.log came back:
//      [zm_qol] fly: getnormalizedmovement UNDEFINED
//  Not "0 0" - UNDEFINED. The builtin returns nothing at all, so the movement
//  branch guarded on it could never run. That, and not the mover or the link, is
//  why flight was "stuck in place": the link held the player, and nothing ever
//  moved the mover.
//
//  Why: in the ZM script dump getnormalizedmovement() appears ONLY inside /# ... #/
//  developer blocks (_createfx.gsc:1272, 2721). It is a dev-build builtin and is
//  not exposed by the retail/Plutonium ZM build. The starter kit's GSC reference
//  lists it as a normal player function - that entry is wrong for this build, and
//  the runtime is the authority. Do not reintroduce it.
//
//  What every working T6 UFO mod does instead is read BUTTONS, never WASD, and
//  steer with the view. Two independent shipped implementations in this workspace
//  agree, and neither touches getnormalizedmovement:
//      Plutonium-T6-Scripts\chat_commands\chat_command_ufo_mode.gsc:83-117
//          MeleeButtonPressed() -> PlayerLinkTo + MoveTo( ... AnglesToForward ... )
//      littlegods-mod\funciones.gsc:1880-1921
//          fragButtonPressed() -> moveTo( origin + AnglesToForward * 20 )
//  So movement is: hold a button, fly the way you are looking. anglestoforward()
//  carries view PITCH, so looking up and holding forward climbs - jump/stance are
//  only there for fine vertical trim.
// ============================================================================
//  zmqol_fly_bind_wasd  -  REAL WASD, without reading movement state
//
//  getnormalizedmovement() is undefined in this build (see the block above
//  zmqol_fly_think), so WASD cannot be POLLED. But it can be SUBSCRIBED to:
//  notifyonplayercommand( notify, command ) fires a GSC notify when the client
//  issues a console command, and the movement keys are bound to the ordinary
//  console commands +forward / +back / +moveleft / +moveright.
//
//  🛑 The RELEASE form works too, and that is what makes held-state possible -
//  "-forward" fires on key-up. Confirmed in shipped code, not assumed:
//  Plutonium-T6-Scripts uses notifyonplayercommand("close_scores", "-scores")
//  alongside ("open_scores", "+scores"). Other shipped binds in the workspace
//  cover "+attack", "+melee", "+gostand", "+activate", "+speed_throw".
//
//  So each axis gets two one-line watcher threads - one sets the flag on press,
//  one clears it on release. Two separate watchers rather than a single
//  down-then-up loop on purpose: a loop that waits for "down" then "up" can
//  desync permanently if either notify is ever missed, and then the key sticks.
//
//  Bound once per player and guarded, because re-registering the same command
//  on every .fly toggle would stack duplicate notifies.
// ============================================================================
zmqol_fly_bind_wasd()
{
    if ( isdefined( self.zmqol_fly_bound ) )
        return;

    self.zmqol_fly_bound = 1;
    self.zmqol_fly_keys = [];
    self.zmqol_fly_keys["f"] = 0;
    self.zmqol_fly_keys["b"] = 0;
    self.zmqol_fly_keys["l"] = 0;
    self.zmqol_fly_keys["r"] = 0;

    self notifyonplayercommand( "zmqol_fly_f_dn", "+forward" );
    self notifyonplayercommand( "zmqol_fly_f_up", "-forward" );
    self notifyonplayercommand( "zmqol_fly_b_dn", "+back" );
    self notifyonplayercommand( "zmqol_fly_b_up", "-back" );
    self notifyonplayercommand( "zmqol_fly_l_dn", "+moveleft" );
    self notifyonplayercommand( "zmqol_fly_l_up", "-moveleft" );
    self notifyonplayercommand( "zmqol_fly_r_dn", "+moveright" );
    self notifyonplayercommand( "zmqol_fly_r_up", "-moveright" );

    self thread zmqol_fly_key_watch( "zmqol_fly_f_dn", "f", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_f_up", "f", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_b_dn", "b", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_b_up", "b", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_l_dn", "l", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_l_up", "l", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_r_dn", "r", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_r_up", "r", 0 );
}

zmqol_fly_key_watch( str_notify, str_key, n_val )
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( str_notify );
        self.zmqol_fly_keys[str_key] = n_val;
    }
}

// ============================================================================
//  zmqol_fly_clear_keys  -  🛑 THE FIX FOR "IT KEEPS MOVING BY ITSELF"
//
//  User: "the .fly command sometimes is weird sometimes when i do it, it keeps
//  moving by itself but sometimes it works fine".
//
//  The held-key state is built from EDGES, not from polling - +forward sets the
//  flag, -forward clears it, because getnormalizedmovement() does not exist in
//  this build and WASD cannot be read any other way. Edge tracking has one
//  failure mode and this is it: MISS A RELEASE AND THE KEY IS HELD FOREVER.
//
//  And there is a release that is very easy to miss, built into how the command
//  is issued. You type .fly IN CHAT. Opening chat takes keyboard focus away from
//  movement, so a W that was down when the chat box opened can have its key-up
//  swallowed - the client sends +forward and never sends -forward. The flag is
//  now stuck at 1, and it stays stuck for the rest of the match because these
//  watcher threads run whether or not anyone is flying.
//
//  That is exactly the reported shape: intermittent, tied to the moment of
//  toggling, and "sometimes it works fine" - it works whenever you happened to be
//  standing still as you opened chat.
//
//  So the flags are wiped at every takeoff and every landing. A stuck key can no
//  longer outlive one flight, and cannot leak into the next one. If a key really
//  is still physically down after a wipe, the next press re-sets it; the cost of
//  being wrong here is one keystroke, against a permanent drift.
//
//  📝 The general shape, worth keeping: EDGE-DERIVED STATE NEEDS A RESYNC POINT.
//  If you cannot poll the truth, at least re-zero at a moment when you know what
//  the state should be. Takeoff is that moment.
// ============================================================================
// ============================================================================
//  zmqol_fly_install_oopa_veto  -  a STANDING block on the out-of-bounds kill
//
//  Installed once and left in place. For anyone not flying it defers to whatever
//  callback the map had (or to "yes, kill them" if there was none), so stock
//  behaviour is untouched for everyone else - which is why it is safe to leave
//  installed rather than swapping it in and out around each flight and racing
//  every respawn.
//
//  Chained rather than overwritten because a map may install its own: Die Rise
//  does exactly this in setup_zone_monitor(). Clobbering it would break that
//  map's own out-of-bounds handling in a way nothing would report.
// ============================================================================
zmqol_fly_install_oopa_veto()
{
    if ( isdefined( level.zmqol_fly_veto_installed ) )
        return;

    level.zmqol_fly_veto_installed = 1;
    level.zmqol_fly_oopa_prev = level.player_out_of_playable_area_monitor_callback;
    level.player_out_of_playable_area_monitor_callback = ::zmqol_fly_oopa_veto;
}

//  Called ON THE PLAYER. Return false to spare them.
zmqol_fly_oopa_veto()
{
    if ( isdefined( self.zmqol_fly ) && self.zmqol_fly )
        return 0;

    //  Godmode should mean godmode. The stock monitor takes invulnerability off
    //  before it kills, so .god never protected anyone from a death barrier
    //  either - the user hit that too, with godmode visibly ON in the screenshot.
    if ( isdefined( self.zmqol_god ) && self.zmqol_god )
        return 0;

    if ( isdefined( self.zmqol_afk ) && self.zmqol_afk )
        return 0;

    if ( isdefined( level.zmqol_fly_oopa_prev ) )
        return self [[ level.zmqol_fly_oopa_prev ]]();

    return 1;
}

zmqol_fly_clear_keys()
{
    if ( !isdefined( self.zmqol_fly_keys ) )
        return;

    self.zmqol_fly_keys["f"] = 0;
    self.zmqol_fly_keys["b"] = 0;
    self.zmqol_fly_keys["l"] = 0;
    self.zmqol_fly_keys["r"] = 0;
}

zmqol_fly_think()
{
    level endon( "game_ended" );

    e_mover = spawn( "script_origin", self.origin );
    e_mover hide();

    // 🛑 SET THE MOVER'S ANGLES BEFORE LINKING. Stock always does -
    // zm_alcatraz_travel.gsc:770-774 sets e_origin.angles = self.angles on the
    // line before playerlinkto - because the link makes the entity's angles the
    // player's view BASE. Link to an entity still sitting at (0,0,0) and the view
    // is yanked to face world-north the instant you toggle it on, which on its own
    // reads as "the controls broke". v1.19.0 omitted this.
    e_mover.angles = self.angles;

    self zmqol_fly_bind_wasd();

    // Takeoff resync - see zmqol_fly_clear_keys(). Without this a key-up that was
    // swallowed while the chat box had focus leaves you drifting the instant you
    // lift off, which is the whole "it keeps moving by itself" report.
    self zmqol_fly_clear_keys();

    self playerlinkto( e_mover );

    // 🛑 WITHOUT THIS, FLYING KILLS YOU, AND IT READS AS "FLY IS BROKEN".
    // Leaving the playable area in ZM is fatal: _zm.gsc runs a per-player monitor
    // gated on level.player_out_of_playable_area_monitor (set to 1 in
    // _zm.gsc::init(), per-map in zm_highrise.gsc::setup_zone_monitor:571) which
    // kills anyone outside the enabled zones - exactly where flight goes. Stash
    // the old value and clear it for the duration; chat_commands does the same
    // thing at chat_command_ufo_mode.gsc:10-13. Invulnerability + ignoreme cover
    // the rest, mirroring the .afk branch above.
    if ( !isdefined( level.zmqol_fly_oopam ) )
    {
        level.zmqol_fly_oopam = level.player_out_of_playable_area_monitor;
        level.player_out_of_playable_area_monitor = 0;
    }

    // 🛑 AND THE LEVEL FLAG ON ITS OWN DOES NOTHING TO A PLAYER ALREADY IN THE
    // AIR. User: "i keep dying to death barriers... instant game over by mistake
    // when trying to no clip around."
    //
    // Two things were wrong with the block above, and reading the stock function
    // rather than its name settles both:
    //
    // 1. level.player_out_of_playable_area_monitor is only READ AT SPAWN
    //    (_zm.gsc:1335) to decide whether to start the per-player thread. Clearing
    //    it mid-game does not stop a thread that is already running - and for
    //    anyone who has been alive since round 1, it always is. The stash has been
    //    protecting nobody.
    //
    // 2. INVULNERABILITY DOES NOT HELP EITHER, because the monitor takes it off
    //    you first (_zm.gsc:1516-1519):
    //
    //        self disableinvulnerability();
    //        self.lives = 0;
    //        self dodamage( self.health + 1000, self.origin );
    //
    //    That is the instant game over, and it is why .god did not save the user
    //    either. A kill that disables invulnerability cannot be blocked by
    //    enabling invulnerability.
    //
    // The thread endons on "stop_player_out_of_playable_area_monitor" and notifies
    // that itself on entry, so one notify stops it cleanly for THIS player only -
    // stock's own restart mechanism, used exactly as stock uses it. Restarted on
    // landing below.
    //
    // 📝 The general shape: a level flag that GATES thread creation is not a
    // runtime switch. Check whether the thing you are turning off reads the flag
    // continuously or only once, before assuming the flag is a control.
    self notify( "stop_player_out_of_playable_area_monitor" );

    // 🛑 AND THE NOTIFY ALONE IS STILL NOT ENOUGH - v1.51.0 shipped it and the
    // user was "instant killed after a bit when flying around". Killing the
    // thread is a ONE-SHOT act against a thread that can come back: any respawn,
    // revive or host migration runs the spawn path again (_zm.gsc:1335) and
    // starts a fresh copy that has never heard the notify.
    //
    // Stock has a proper veto and it was there the whole time. The monitor asks
    // permission before it kills (_zm.gsc:1495):
    //
    //     if ( !isdefined( level.player_out_of_playable_area_monitor_callback )
    //          || self [[ level.player_out_of_playable_area_monitor_callback ]]() )
    //
    // - a callback returning false skips the kill entirely. That is a STANDING
    // veto rather than a one-off, so it does not care when the thread started or
    // how many times it restarts.
    //
    // 📝 The lesson, and it is the third time this session that reading the stock
    // function paid: when you need to suppress stock behaviour, look for the hook
    // stock already provides before reaching for a notify, a flag or a replaceFunc.
    // Killing the thread was fighting the symptom; the callback is the switch.
    zmqol_fly_install_oopa_veto();

    self.ignoreme = 1;
    self enableinvulnerability();

    self thread zmqol_fly_move( e_mover );

    // 🛑 waittill_any_RETURN, not waittill_any. common_scripts\utility::waittill_any
    // implements notifies 2..n as self endon() - so on death or disconnect this
    // thread would be KILLED and the unlink below would never run, leaving the
    // player welded to a hidden script_origin with no way out. waittill_any_return
    // returns the notify instead, and special-cases "death" so listing it here does
    // not re-introduce the endon.
    self waittill_any_return( "zmqol_fly_off", "disconnect", "death", "player_downed", "bled_out" );

    self notify( "zmqol_fly_move_stop" );

    // Restore the death-barrier monitor for everyone once nobody is flying.
    if ( isdefined( level.zmqol_fly_oopam ) )
    {
        b_anyone_flying = 0;
        a_players = get_players();

        for ( i = 0; i < a_players.size; i++ )
        {
            if ( a_players[i] != self && isdefined( a_players[i].zmqol_fly ) && a_players[i].zmqol_fly )
                b_anyone_flying = 1;
        }

        if ( !b_anyone_flying )
        {
            level.player_out_of_playable_area_monitor = level.zmqol_fly_oopam;
            level.zmqol_fly_oopam = undefined;
        }
    }

    if ( isdefined( self ) )
    {
        self unlink();
        self.zmqol_fly = 0;

        // Landing resync, so nothing left over can leak into the next takeoff.
        self zmqol_fly_clear_keys();

        // Only give back what fly itself turned on - .god / .ghost / .afk own
        // these flags too and must survive a landing.
        if ( ( !isdefined( self.zmqol_ghost ) || !self.zmqol_ghost ) && ( !isdefined( self.zmqol_afk ) || !self.zmqol_afk ) )
            self.ignoreme = 0;

        if ( ( !isdefined( self.zmqol_god ) || !self.zmqol_god ) && ( !isdefined( self.zmqol_afk ) || !self.zmqol_afk ) )
            self disableinvulnerability();

        // Put the death barrier back for this player, unless they are still in a
        // mode that wants it off. Restarting is safe to do twice: the thread's
        // first act is to notify its own endon, so a second copy replaces the
        // first rather than doubling it.
        if ( isdefined( level.zmqol_fly_oopam ) && level.zmqol_fly_oopam )
            self thread maps\mp\zombies\_zm::player_out_of_playable_area_monitor();
        else if ( !isdefined( level.zmqol_fly_oopam ) && isdefined( level.player_out_of_playable_area_monitor ) && level.player_out_of_playable_area_monitor )
            self thread maps\mp\zombies\_zm::player_out_of_playable_area_monitor();
    }

    if ( isdefined( e_mover ) )
        e_mover delete();
}

//  CONTROLS - buttons, not WASD. See the block above zmqol_fly_think() for why
//  WASD cannot be read at all in this build.
//
//      MELEE   fly forward along your view (look down to descend, up to climb)
//      ADS     fly backward
//      JUMP    straight up          STANCE  straight down
//      SPRINT  hold with any of the above for 3x speed
//
//  Melee is the forward key because it is the one button with no meaningful
//  effect while linked - the knife swing is cosmetic - and it is what
//  chat_command_ufo_mode.gsc uses for exactly this reason. Frag (littlegods'
//  choice) would pull a grenade pin every frame, so it is deliberately not used.
//
//  🛑 e_mover.origin, not self.origin. A linked player's origin is driven BY the
//  mover, so feeding self.origin back in makes the step depend on the previous
//  frame's interpolation and the flight drifts and stutters. chat_commands has
//  this bug (it reads self.origin at :112); littlegods reads the mover and is
//  the one to copy.
//
//  🛑 moveto(), never "e_mover.origin = v_pos". A linked player follows the
//  mover's MOVEMENT; a direct origin assignment teleports the parent and the
//  child does not track it. Every stock link target is a real mover. Server tick
//  is 20Hz, so a 0.05s moveto finishes exactly as the next is issued - continuous
//  motion rather than a stutter.
zmqol_fly_move( e_mover )
{
    self endon( "disconnect" );
    self endon( "zmqol_fly_move_stop" );
    level endon( "game_ended" );

    n_speed = 20;

    for ( ;; )
    {
        if ( !isdefined( e_mover ) )
            return;

        v_angles = self getplayerangles();
        v_pos = e_mover.origin;
        b_moved = 0;

        // 🛑 PANIC RELEASE. Melee is the one button with nothing bound to it while
        // linked, and unlike WASD it can be POLLED - so it is the one control that
        // cannot get stuck. Tapping it drops every movement flag.
        //
        // The takeoff resync should mean this is never needed. It is here because
        // the failure it covers is unfalsifiable from script: if the client ever
        // swallows a key-up mid-flight, nothing server-side can tell, and without
        // an escape hatch the only way out is to land and take off again. One
        // pollable button removes that whole class of stuck state.
        if ( self meleebuttonpressed() )
            self zmqol_fly_clear_keys();

        // WASD, from the notifyonplayercommand binds set up in
        // zmqol_fly_bind_wasd(). Mouse buttons are deliberately NOT used any
        // more - the user asked for plain WASD like the console `ufo` command,
        // and driving forward off +attack meant flying and shooting were the
        // same key.
        n_fwd = 0;
        n_rgt = 0;

        if ( self.zmqol_fly_keys["f"] ) n_fwd = n_fwd + 1;
        if ( self.zmqol_fly_keys["b"] ) n_fwd = n_fwd - 1;
        if ( self.zmqol_fly_keys["r"] ) n_rgt = n_rgt + 1;
        if ( self.zmqol_fly_keys["l"] ) n_rgt = n_rgt - 1;

        // Sprint is now a BOOST, not a requirement. Previously forward was
        // OR-ed onto sprint, so flying at all meant holding shift.
        n_step = n_speed;
        if ( self sprintbuttonpressed() )
            n_step = n_speed * 2.5;

        // (The WASD probe that printed a line per tick lived here. It existed to
        // prove notifyonplayercommand reaches a linked player, which it plainly
        // does - the controls work. It was 100 log lines per flight and the file
        // said to delete it once confirmed, so: deleted.)

        if ( n_fwd != 0 )
        {
            v_pos = v_pos + ( anglestoforward( v_angles ) * ( n_fwd * n_step ) );
            b_moved = 1;
        }

        if ( n_rgt != 0 )
        {
            v_pos = v_pos + ( anglestoright( v_angles ) * ( n_rgt * n_step ) );
            b_moved = 1;
        }

        if ( self jumpbuttonpressed() )
        {
            v_pos = v_pos + ( ( 0, 0, 1 ) * n_step );
            b_moved = 1;
        }

        if ( self stancebuttonpressed() )
        {
            v_pos = v_pos - ( ( 0, 0, 1 ) * n_step );
            b_moved = 1;
        }

        // 🛑 AN IDLE TICK ISSUES A STOP, IT DOES NOT JUST SKIP.
        //
        // Previously an idle tick did nothing at all, which quietly assumed the
        // last moveto had already finished. It usually has - 0.05s of travel per
        // 0.05s of wait - but the server tick is not exactly 20Hz, and a frame
        // that runs short leaves the mover still interpolating toward a target
        // nobody is refreshing any more. The player keeps coasting after the key
        // is up.
        //
        // moveto() to the mover's CURRENT origin overrides the one in flight and
        // parks it, so releasing everything stops you on the frame you release.
        // Small on its own; it is the other half of "keeps moving by itself", and
        // the half that survives even a perfectly tracked keyboard.
        if ( b_moved )
            e_mover moveto( v_pos, 0.05 );
        else
            e_mover moveto( e_mover.origin, 0.05 );

        wait 0.05;
    }
}

// ============================================================================
//  zmqol_register_divetonuke_visionset
//
//  🛑 Fixes: EXE_CLIENT_FIELD_MISMATCH on Mob of the Dead survival -
//     "Clientfield 'visionset_lerp' in set [toplayer] is not registered on the
//     server" (console_zm.log 2026-08-02, cellblock run). Cell Block is a STOCK
//     location, so this was breaking stock survival, not just the added ones.
//
//  perks() below calls _zm_perk_divetonuke::enable_divetonuke_perk_for_level()
//  on these five maps, which makes the CLIENT register the PhD visionset:
//  clientscripts\mp\zombies\_zm_perk_divetonuke.csc::init_divetonuke ->
//  vsmgr_register_visionset_info( "zm_perk_divetonuke", ... ), guarded only on
//  level.enable_magic.
//
//  The SERVER half lives in maps\mp\zombies\_zm_perk_divetonuke::init_divetonuke,
//  and the ONLY caller of that is divetonuke_perk_machine_think() - i.e. it runs
//  only once a PhD machine is actually being processed, which is both far too
//  late (vsmgr_register_info asserts on level.vsmgr_initializing, which is only
//  true during the first frame) and does not happen at all on the survival
//  locations. Server ends up with zero registered visionsets while the client
//  has one, so _visionset_mgr never registers visionset_lerp server-side and the
//  client/server clientfield sets disagree -> instant disconnect.
//
//  Registering here in init() puts it inside the legal window, exactly like the
//  Origins fix in zm_tomb.gsc (see zmqol_register_survival_visionset there, and
//  [[t6-visionset-registration-timing]]). zm_tomb is deliberately NOT in this
//  list - it does not call enable_divetonuke_perk_for_level(), and it already
//  registers this visionset itself, so adding it here would double-register.
//
//  Args mirror stock init_divetonuke exactly: version 9000, priority 400,
//  5 lerp steps, activate_per_player 1.
// ============================================================================
zmqol_register_divetonuke_visionset()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && map != "zm_prison" && map != "zm_buried" )
        return;

    // Degrade to "not registered" rather than erroring out of init() if the
    // ordering ever changes and _visionset_mgr::init() has not run yet.
    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr["visionset"] ) )
        return;

    // Don't double-register if something already did it this frame.
    if ( isdefined( level.vsmgr["visionset"].info ) && isdefined( level.vsmgr["visionset"].info["zm_perk_divetonuke"] ) )
        return;

    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 5, 1 );
}

// ============================================================================
//  zmqol_register_vulture_visionset  -  the half of init_vulture() that CANNOT
//  run in main(), and the cause of v1.40.2's EXE_CLIENT_FIELD_MISMATCH
//
//  Town would not launch:
//      Clientfield 'overlay_lerp' in set [toplayer] ... [CLIENT : 12000  SERVER : 1]
//      Clientfield 'overlay_slot' ... bit count [CLIENT: 2  SERVER : 1]
//      Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  Note what mismatched: NOT any vulture_* field. Every one of those matched.
//  overlay_lerp and overlay_slot are the visionset manager's own fields, and
//  their BIT COUNTS are derived from how many overlays are registered. The
//  client had one more than the server, so the two sides sized the same fields
//  differently and the connection was refused.
//
//  🛑 THE CAUSE IS A TIMING RULE THIS PROJECT ALREADY KNEW AND I BROKE ANYWAY:
//  registerclientfield() must run in main(), but vsmgr_register_info() must run
//  in init() - _visionset_mgr has not built level.vsmgr yet during main(), so
//  the call silently does nothing. Stock's init_vulture() does BOTH: seven
//  registerclientfield calls and one vsmgr_register_info. v1.40.2 called it once
//  from perks(), in main(). The clientfields registered; the overlay did not.
//  Meanwhile the client's enable_vulture_perk_for_level() registered its
//  overlay style filter with no such constraint, and the sides diverged.
//
//  Splitting it is exactly what zmqol_register_divetonuke_visionset() above
//  already does for PhD Flopper, for exactly this reason. It is the same
//  function shape on purpose.
//
//  Arguments are copied verbatim from _zm_perk_vulture.gsc's own call so the two
//  cannot disagree: ( "overlay", "vulture_stink_overlay", 12000, 120, 31, 1 ).
//  The version 12000 in the error message is this registration's, which is how
//  it was identified.
// ============================================================================
zmqol_register_vulture_visionset()
{
    //  🛑 THIS MUST USE THE SAME MAP LIST AS zmqol_enable_vulture(), AND v1.49.0
    //  PROVED IT BY NOT DOING SO. That release excluded Origins from the perk on
    //  both server and client but left this function checking only for Buried, so
    //  the SERVER still registered vulture_stink_overlay while the client did not:
    //
    //      Clientfield 'overlay_lerp' in set[toplayer] is not registered with the
    //      same bit count as the server : [CLIENT: 4  SERVER : 5]
    //      Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
    //
    //  overlay_lerp's WIDTH is derived from how many overlays are registered, so
    //  one extra overlay on one side resizes a shared field and the connection is
    //  refused. This is the second time that exact error has come from this exact
    //  cause - the comment above already documents the first.
    //
    //  So the list now lives in ONE place, zmqol_vulture_enabled(), and every
    //  site asks it. A map list copied into three functions will drift; it drifted
    //  the first time it was copied.
    if ( !zmqol_vulture_enabled() )
        return;

    // Degrade to "not registered" rather than erroring out of init() if the
    // ordering ever changes and _visionset_mgr::init() has not run yet.
    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr[ "overlay" ] ) )
        return;

    // Don't double-register if init_vulture()'s own call did land after all.
    if ( isdefined( level.vsmgr[ "overlay" ].info ) && isdefined( level.vsmgr[ "overlay" ].info[ "vulture_stink_overlay" ] ) )
        return;

    maps\mp\_visionset_mgr::vsmgr_register_info( "overlay", "vulture_stink_overlay", 12000, 120, 31, 1 );
}

perks()
{
    if ( getDvar("mapname") == "zm_transit" || getDvar("mapname") == "zm_nuked" || getDvar("mapname") == "zm_highrise" || getDvar("mapname") == "zm_prison" || getDvar("mapname") == "zm_buried" ) //GLOBAL
    {
        level.zombiemode_using_marathon_perk = 1;
        level.zombiemode_using_deadshot_perk = 1;
        level.zombiemode_using_additionalprimaryweapon_perk = 1;
        level.zombiemode_using_divetonuke_perk = 1;
        maps\mp\zombies\_zm_perk_divetonuke::enable_divetonuke_perk_for_level();
    }

    zmqol_enable_electric_cherry();
    zmqol_enable_vulture();
    zmqol_enable_whoswho();
}

// ============================================================================
//  zmqol_enable_fire_sale  -  Fire Sale on the two maps that never had it
//
//  Measured across the stock dump, not assumed. include_powerup( "fire_sale" )
//  is called by zm_nuked (:720), zm_prison (:947), zm_buried (:1279) and
//  zm_tomb (:1173). It is NOT called by zm_transit or zm_highrise - those two
//  are the whole gap.
//
//  🛑 WHY THIS NEEDED AN ASSET AND NOT JUST THE ONE-LINE INCLUDE.
//  _zm_powerups::add_zombie_powerup() precaches the model only for powerups
//  that were included:
//        if ( isdefined( level.zombie_include_powerups ) &&
//             !isdefined( level.zombie_include_powerups[powerup_name] ) )
//            return;
//        precachemodel( model_name );
//  and Unlinker --list shows zombie_firesale is absent from zm_transit.ff and
//  zm_highrise.ff - the same two maps. So including it without shipping the
//  model would precache something the level does not have, which is fatal at
//  load. zone_source\mod_locations.zone now carries it; see the block there.
//
//  🛑 TIMING. include_powerup() only sets level.zombie_include_powerups[name],
//  which _zm_powerups::init() reads later when it calls add_zombie_powerup for
//  each one - so this MUST run before that init. main() is inside Plutonium's
//  precache window and runs ahead of every ::init(), which is the same reason
//  wunderfizz.gsc does its precaching there. It is additive, so a map setting
//  up its own list afterwards cannot clobber this.
//
//  Fire Sale needs a mystery box to be worth anything, and stock already gates
//  the drop on that: func_should_drop_fire_sale() refuses while
//  level.chest_moves < 1. Both maps have a moving box, so nothing else is
//  required - and on any map where that stopped being true, stock declines the
//  drop on its own rather than dropping a dud.
// ============================================================================
zmqol_enable_fire_sale()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_highrise" )
        return;     // the other four include it themselves

    maps\mp\zombies\_zm_utility::include_powerup( "fire_sale" );
}

// ============================================================================
//  zmqol_whoswho_enabled  -  THE ONE map list, asked by both sides
//
//  Who's Who is Die Rise's perk. Stage 1 of putting every BO2 perk on every map.
//
//  📝 IT IS THE CHEAPEST OF THE FOUR REMAINING PERKS - exactly ONE clientfield
//  bit - and that is not luck, it is because stock self-gates:
//      level.whos_who_client_setup            gates the corpse glow shader, and
//                                             clientfield_whos_who_audio/_filter
//      level.vsmgr_prio_visionset_zm_whos_who gates the zm_whos_who visionset
//  BOTH are set ONLY by zm_highrise (zm_highrise.gsc:81 and :133-134). Off Die
//  Rise every one of those code paths is skipped, so enabling the perk costs
//  `perk_chugabud` (1 bit, toplayer) and nothing else. In particular it CANNOT
//  reproduce the Vulture overlay_lerp mismatch, because it registers no overlay
//  and no visionset on either side.
//
//  🛑 MOB OF THE DEAD IS EXCLUDED, AND NOT FOR THE USUAL BUDGET REASON.
//  Stock's Who's Who HUD icon is `specialty_quickrevive_zombies` (the perk is
//  revive-adjacent and reuses it - see _zm_perks.gsc:212 vs :256, the revive
//  block and the chugabud block precaching the same shader). Every map ships
//  that material EXCEPT Mob, which has no Quick Revive at all - confirmed with
//  Unlinker --list over all six map fastfiles plus common_zm.ff, not assumed.
//  Mob therefore needs an asset the other four do not, and it is also the map
//  whose toplayer set is already known full. It comes in at STAGE 2, together
//  with Quick Revive, which needs that same shader - one asset, two perks, one
//  boot test.
//
//  🛑 AND IT LIVES IN ONE FUNCTION FOR A REASON. v1.49.0 wrote the Vulture map
//  list into three places, forgot one, and turned a boot crash into a different
//  boot crash. Same discipline here: this function is the only list, and
//  zm_expanded.csc's twin is the one unavoidable copy (separate compilation
//  unit) - check it first if the sets ever disagree.
// ============================================================================
zmqol_whoswho_enabled()
{
    map = getDvar( "mapname" );

    if ( map == "zm_highrise" )   // ships the perk itself
        return 0;

    if ( map == "zm_prison" )     // no specialty_quickrevive_zombies - stage 2
        return 0;

    return 1;
}

// ============================================================================
//  zmqol_enable_whoswho
//
//  Setting the flag is the whole job. Unlike Electric Cherry and Vulture Aid,
//  Who's Who is NOT a custom perk - it is one of the nine stock
//  level.zombiemode_using_*_perk flags, so _zm_perks::perks_register_clientfield
//  registers its clientfield and _zm_perks::init() threads turn_chugabud_on()
//  off the back of the same flag. There is no _register_undefined_perk() call to
//  make and no perk_machine_thread pointer to clear afterwards.
//
//  turn_chugabud_on() calls _zm_chugabud::init() and then blocks forever on
//  `level waittill( "chugabud_on" )` after finding getentarray("vending_chugabud")
//  empty - which is exactly the harmless idle the Electric Cherry loop settles
//  into. _zm_chugabud::init() is what sets level.chugabud_laststand_func, so it
//  MUST run; letting stock's own thread call it is what gets that for free.
//
//  Called from perks(), which runs in main(). Clientfields have to be registered
//  before the first snapshot, so this cannot move to init().
//
//  🛑 NOT verified in game yet. Requires build.bat AND build_ff.bat (the bottle
//  weapon is a new mod.ff asset).
// ============================================================================
zmqol_enable_whoswho()
{
    if ( !zmqol_whoswho_enabled() )
        return;

    level.zombiemode_using_chugabud_perk = 1;
    level thread zmqol_whoswho_verify();
}

// ============================================================================
//  zmqol_whoswho_verify  -  the perk was given and did nothing
//
//  Reported on Origins: gave Who's Who with the chat command, got run over by
//  the tank, and went straight to game over with no clone and no second life.
//
//  The gate is _zm.gsc:4239, inside player_damage_override:
//
//      if ( self.lives > 0 && self hasperk( "specialty_finalstand" ) )
//      {
//          self.lives--;
//          if ( isdefined( level.chugabud_laststand_func ) )
//          {
//              self thread [[ level.chugabud_laststand_func ]]();
//              return 0;
//          }
//      }
//
//  🛑 Note what happens when that inner isdefined FAILS: self.lives has ALREADY
//  been decremented and there is no else - so the player silently falls through
//  to the ordinary down, one life poorer. "Perk equipped, nothing happened, game
//  over" is precisely the shape of a missing level.chugabud_laststand_func.
//
//  Everything on the give side checks out statically, and was re-read rather
//  than assumed:
//    - give_perk() (our override, line ~4780) does set self.lives = 1 for
//      specialty_finalstand, same as stock.
//    - the .give<perk> command routes through _zm_perks::give_perk, which is
//      the function we replace, so it gets that block.
//    - _zm_perks::init() threads turn_chugabud_on() off
//      level.zombiemode_using_chugabud_perk, which we set in main(), before
//      init() runs.
//    - turn_chugabud_on()'s FIRST statement is _zm_chugabud::init(), and that
//      function's first statement sets level.chugabud_laststand_func - so even
//      a thread that dies on the loadfx calls two lines later should leave the
//      pointer set.
//
//  So the static read says it should work and the game says it does not, which
//  is the point where guessing again would cost another release (checkpoint 18
//  section 1). This verifies instead: it reports the pointer's real state to the
//  log, and if it is genuinely missing it installs it, which is a no-op whenever
//  stock did its job. _zm_chugabud::init() is safe to name from a root script -
//  _zm_perks.gsc calls it on every map, so the file resolves everywhere.
//
//  If the next log says OK and Who's Who still does nothing, the pointer is not
//  the cause and the damage path is - look at the tank first, since
//  zm_tomb_tank::tank_ran_me_over does disableinvulnerability() then
//  dodamage( self.health + 1000 ).
// ============================================================================
zmqol_whoswho_verify()
{
    level endon( "end_game" );

    // Poll rather than flag_wait: stock threads turn_chugabud_on() from
    // _zm_perks::init(), and nothing guarantees which flag it lands behind.
    for ( i = 0; i < 60; i++ )
    {
        if ( isdefined( level.chugabud_laststand_func ) )
        {
            println( "[zm_qol] whoswho: chugabud_laststand_func present after " + i + "s - stock turn_chugabud_on ran" );
            return;
        }

        wait 1;
    }

    println( "[zm_qol] whoswho: chugabud_laststand_func MISSING after 60s - stock turn_chugabud_on did not reach _zm_chugabud::init(). Repairing." );

    maps\mp\zombies\_zm_chugabud::init();

    if ( isdefined( level.chugabud_laststand_func ) )
        println( "[zm_qol] whoswho: repair OK, chugabud_laststand_func now set" );
    else
        println( "[zm_qol] whoswho: repair FAILED, _zm_chugabud::init() did not set the pointer" );
}

// ============================================================================
//  zmqol_enable_vulture  -  the 11th and LAST perk
//
//  Vulture Aid is Buried's, and with it the Wunderfizz can offer every perk
//  Black Ops II Zombies has. Enabled on the five maps that never shipped it;
//  Buried is excluded because it enables the perk itself, and re-running the
//  registration there would fight its own.
//
//  Everything about this mirrors zmqol_enable_electric_cherry() above, on
//  purpose - it is the same problem shape and the same three traps:
//
//  1. 🛑 TEST FOR THE BEHAVIOUR, NOT THE STRUCT. _register_undefined_perk()
//     creates level._custom_perks["specialty_nomotionsensor"] as a bare empty
//     struct the moment anything so much as names the perk, and wunderfizz.gsc's
//     getPerks() names it on every map. Guarding on the struct existing would
//     therefore skip the real registration and leave the perk cosmetic - the
//     exact half-dead state Electric Cherry was in. player_thread_give is the
//     thing register_perk_threads() actually sets, so that is what is checked.
//
//  2. 🛑 init_vulture() MUST RUN EXACTLY ONCE. It calls registerclientfield
//     eight times and a second call is fatal ("already registered"). Stock only
//     ever reaches it through vulture_perk_machine_think(), which _zm_perks::init()
//     threads - so it is called here, once, behind its own flag, and the
//     perk_machine_thread pointer is then cleared so init() cannot call it again.
//     Clearing that costs nothing: the machine loop only drives a physical
//     Vulture Aid machine, and on these five maps there is none - the Wunderfizz
//     is what hands the perk out.
//
//  3. 🛑 THE CLIENT MUST REGISTER THE IDENTICAL SET. Eight clientfields on the
//     server and a different eight on the client is EXE_CLIENT_FIELD_MISMATCH
//     for everyone before the map starts. zm_expanded.csc::zmqol_enable_vulture()
//     is the other half and is deliberately written to the same shape, with the
//     same map list, so the two cannot drift.
//
//  Called from perks(), which runs in main() - clientfields have to be
//  registered before the first snapshot, so this cannot move to init().
//
//  🛑 NOT verified in game yet. Requires build_ff.bat.
// ============================================================================
// ============================================================================
//  zmqol_vulture_enabled  -  THE ONE map list, asked by every site
//
//  🛑 TWO MAPS PHYSICALLY CANNOT TAKE THIS PERK, AND THEY RAN OUT OF DIFFERENT
//  BUDGETS. Both errors are quoted because they look unrelated and are the same
//  problem:
//
//    zm_tomb   Trying to assign 1 bits for netfield zone_capture_zombie
//              but Client Field Set ACTOR is out of space.
//    zm_prison Trying to assign 5 bits for netfield vulture_perk_disease_meter
//              but Client Field Set TOPLAYER is out of space.
//
//  Every clientfield SET has its own fixed bit budget. Vulture Aid registers
//  eight fields spread across four sets, so it can hit the ceiling in more than
//  one place, and which ceiling it hits depends on what the MAP already spends:
//
//    Origins is heavy on ACTOR   - templars, crusaders, capture zones, panzer -
//                                  and vulture_perk_actor is 2 bits.
//    Mob is heavy on TOPLAYER    - afterlife, the plane, the shield, brutus -
//                                  and vulture_perk_disease_meter is 5 bits.
//
//  Neither is fixable by reordering or by a lower version number. The budget is
//  the budget, and the field that errors is whichever one asks LAST - so on both
//  maps the name in the message is the map's own field, not ours. Read those
//  errors as "someone before me used the space", never as "this field is broken".
//
//  There IS a way back for both, and it is the same way: the two expensive fields
//  drive only cosmetics - vulture_perk_actor is the zombie eye glow and stink
//  trail, vulture_perk_disease_meter is the stink meter - so skipping just those
//  on BOTH sides would leave a working perk minus one visual each. The client
//  half lives in clientscripts\mp\zombies\_zm_perk_vulture.csc, which this
//  project ships as COMPILED bytecode; it would have to be decompiled, edited and
//  re-shipped as raw text. A real option and a bigger job than a boot fix.
//
//  📝 A clientfield budget is a shared global resource with no per-mod share.
//  Budget against the FULLEST map, not the emptiest, and expect different maps to
//  run out in different sets.
//
//  🛑 AND IT LIVES IN ONE FUNCTION FOR A REASON. v1.49.0 wrote this list into
//  zmqol_enable_vulture() and its client twin but forgot
//  zmqol_register_vulture_visionset(), which then registered a server-side
//  overlay the client did not have and turned a boot crash into a different boot
//  crash. A list copied into three places drifts; it drifted the first time it
//  was copied.
// ============================================================================
//  ✅ RESOLVED (v1.55.0) - ORIGINS AND MOB ARE NO LONGER EXCLUDED.
//
//  The paragraph above says the way back is to skip just the one expensive
//  cosmetic field on each map, on BOTH sides, and calls the client half "a
//  bigger job than a boot fix" because the client script ships as compiled
//  bytecode. That job is done:
//
//    zm_tomb    drops vulture_perk_actor          (2 bits, actor)   - eye glow
//                                                                     + stink trail
//    zm_prison  drops vulture_perk_disease_meter  (5 bits, toplayer) - stink meter
//
//  Server side: maps\mp\zombies\_zm_perk_vulture.gsc already ships raw, so the
//  two registrations and all seven use sites are gated there directly on
//  zmqol_vulture_has_actor_field() / zmqol_vulture_has_disease_meter().
//
//  Client side: the compiled .csc is NOT replaced. Only init_vulture is
//  re-implemented, in scripts\zm\zm_expanded.csc - read the long comment above
//  zmqol_init_vulture_trimmed() there for why shipping the decompiled .csc raw
//  was tried and rejected (the decompile is lossy, and it would have degraded
//  the three maps where the perk already works).
//
//  Each map loses exactly one visual and keeps the perk.
zmqol_vulture_enabled()
{
    map = getDvar( "mapname" );

    if ( map == "zm_buried" )   // ships the perk itself
        return 0;

    return 1;
}

zmqol_enable_vulture()
{
    if ( !zmqol_vulture_enabled() )
        return;

    if ( !isdefined( level._custom_perks ) )
        level._custom_perks = [];

    if ( isdefined( level._custom_perks[ "specialty_nomotionsensor" ] ) &&
         isdefined( level._custom_perks[ "specialty_nomotionsensor" ].player_thread_give ) )
        return;

    maps\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();

    if ( !isdefined( level.zmqol_vulture_inited ) )
    {
        level.zmqol_vulture_inited = 1;
        maps\mp\zombies\_zm_perk_vulture::init_vulture();
    }

    if ( isdefined( level._custom_perks[ "specialty_nomotionsensor" ] ) )
        level._custom_perks[ "specialty_nomotionsensor" ].perk_machine_thread = undefined;
}

// ============================================================================
//  zmqol_enable_electric_cherry
//
//  Makes Electric Cherry the 9th perk on the maps that never shipped it, which
//  is what stops Wunderfizz at 8 - getPerks() reads level._custom_perks, so a
//  perk the map never registered can never be offered. Reported in game: after
//  eight perks the machine says "You have all 8 perks".
//
//  Stock enables it on Mob of the Dead (zm_prison.gsc:111) and Origins
//  (zm_tomb.gsc:180) only, so those two are EXCLUDED here - registering a perk
//  twice re-registers its clientfields, which is an error in itself.
//
//  maps\mp\zombies\_zm_perk_electric_cherry is a CORE module, so referencing it
//  from this root script is legal under AI_CONTEXT rule 2. Its assets are not
//  core, though - models, fx, the bottle weapon and the client .csc all come
//  from zm_prison(.ff/_patch.ff) via zone_source\mod_locations.zone.
//
//  🛑 WHY init_electric_cherry() IS CALLED HERE AND NOT LEFT ALONE.
//  enable_...for_level() only REGISTERS the perk. The clientfield
//  "electric_cherry_reload_fx" is registered by init_electric_cherry(), while the
//  CLIENT registers that field unconditionally through register_perk_init_thread.
//  Left alone the two sides can disagree by exactly one field and everyone is
//  dropped with EXE_CLIENT_FIELD_MISMATCH. Calling it here puts the server-side
//  registration in the same legal window - identical in shape to
//  zmqol_register_divetonuke_visionset above, and to
//  [[t6-visionset-registration-timing]].
//
//  🛑 AND WHY perk_machine_thread IS THEN CLEARED.
//  v1.18.1 shipped with the call above and nothing else, and every one of these
//  four maps died on load with:
//        COM_ERROR (1) Attempt to register ClientField electric_cherry_reload_fx
//        failed. Client Field set 'allplayers' either already contains a field
//        called electric_cherry_reload_fx, ...
//  The comment that used to sit here claimed the only stock caller of
//  init_electric_cherry() is electric_cherry_perk_machine_think(), which "runs
//  only once an Electric Cherry MACHINE is being processed". That is wrong.
//  _zm_perks::init() lines 101-110 thread EVERY registered custom perk's
//  perk_machine_thread with no check that any machine entity exists:
//        if ( isdefined( level._custom_perks[a_keys[i]].perk_machine_thread ) )
//            level thread [[ level._custom_perks[a_keys[i]].perk_machine_thread ]]();
//  and init_electric_cherry() is that thread's first statement. So it fired a
//  second time and took the server down.
//
//  Clearing the pointer is what stops it: the loop above is guarded on
//  isdefined(). Nothing is lost - the thread's whole body operates on
//  getentarray( "vendingelectric_cherry", ... ), which is empty on these maps,
//  then blocks forever on `level waittill( "electric_cherry_on" )`. The perk's
//  real behaviour (reload attack, perk_lost) is registered separately by
//  register_perk_threads() and is untouched.
//
//  Deleting our own init_electric_cherry() call instead would ALSO fix the crash,
//  but it would make registration depend on _zm_perks::init() reaching that loop -
//  and it does not always: it early-returns when vending_triggers.size < 1. That
//  gate is the documented cause of an earlier mismatch on this project, see
//  zm_qol\scripts\zm\zm_tomb\zm_tomb.gsc:111-124. Registering in main() and
//  removing the duplicate is not exposed to it.
//
//  🛑 The 9-perk result is still NOT verified in game. Needs build_ff.bat - the
//  client half is a .csc.
// ============================================================================
zmqol_enable_electric_cherry()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && map != "zm_buried" )
        return;

    // 🛑 THIS GUARD IS WHY THE PERK WENT HALF-DEAD - user: "with electric cherry
    // I see the visual effects but the sound effects are missing, also the
    // zombies aren't being effected by it".
    //
    // It used to bail whenever level._custom_perks["specialty_grenadepulldeath"]
    // merely EXISTED. But that entry is created by _register_undefined_perk() as
    // a bare empty struct - any code that so much as names the perk brings it
    // into being, with none of its behaviour attached. When that happened first,
    // this returned and enable_electric_cherry_perk_for_level() never ran, so
    // register_perk_threads() never set player_thread_give.
    //
    // The consequence is exactly the reported symptom set, because the perk
    // splits cleanly in two. Everything the user still SEES - the bottle, the
    // icon, the machine, the reload visuals - is clientfield-driven and comes
    // from elsewhere. Everything they LOST lives inside
    // electric_cherry_reload_attack(): the zmb_cherry_explode sound, the stun,
    // the tesla shock fx and the dodamage() call. That one thread is started
    // only by give_perk() doing [[ player_thread_give ]] (_zm_perks.gsc:2042,
    // and our own override at give_perk() below keeps that line) - so with the
    // pointer unset, the perk is cosmetic.
    //
    // So the test is now for the BEHAVIOUR being registered, not for the struct
    // existing. Re-running enable_electric_cherry_perk_for_level() is safe:
    // every register_* it calls is written `if ( !isdefined( ... ) )` and will
    // not overwrite a real registration.
    if ( !isdefined( level._custom_perks ) )
        level._custom_perks = [];

    if ( isdefined( level._custom_perks[ "specialty_grenadepulldeath" ] ) &&
         isdefined( level._custom_perks[ "specialty_grenadepulldeath" ].player_thread_give ) )
        return;

    maps\mp\zombies\_zm_perk_electric_cherry::enable_electric_cherry_perk_for_level();

    // 🛑 init_electric_cherry() must still run exactly ONCE - its
    // registerclientfield( "electric_cherry_reload_fx" ) is fatal on a second
    // call ("Attempt to register ClientField ... already registered"), which is
    // the crash the block above this function documents. Guard it on its own
    // flag rather than on the perk struct, so it stays once-only even though the
    // enable above may now run when it previously did not.
    if ( !isdefined( level.zmqol_ec_inited ) )
    {
        level.zmqol_ec_inited = 1;
        maps\mp\zombies\_zm_perk_electric_cherry::init_electric_cherry();
    }

    // Stop _zm_perks::init() from threading electric_cherry_perk_machine_think(),
    // whose first line calls init_electric_cherry() a second time. See above.
    if ( isdefined( level._custom_perks[ "specialty_grenadepulldeath" ] ) )
        level._custom_perks[ "specialty_grenadepulldeath" ].perk_machine_thread = undefined;
}

perks_register_clientfield()
{
	bits = 1;
	if (isdefined(level.zombie_include_weapons) && isdefined(level.zombie_include_weapons["emp_grenade_zm"]))
	{
		bits = 2;
	}
	if (isdefined(level.zombiemode_using_additionalprimaryweapon_perk) && level.zombiemode_using_additionalprimaryweapon_perk)
	{
		registerclientfield("toplayer", "perk_additional_primary_weapon", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_deadshot_perk) && level.zombiemode_using_deadshot_perk)
	{
		registerclientfield("toplayer", "perk_dead_shot", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_doubletap_perk) && level.zombiemode_using_doubletap_perk)
	{
		registerclientfield("toplayer", "perk_double_tap", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_juggernaut_perk) && level.zombiemode_using_juggernaut_perk)
	{
		registerclientfield("toplayer", "perk_juggernaut", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_marathon_perk) && level.zombiemode_using_marathon_perk)
	{
		registerclientfield("toplayer", "perk_marathon", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_revive_perk) && level.zombiemode_using_revive_perk)
	{
		registerclientfield("toplayer", "perk_quick_revive", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_sleightofhand_perk) && level.zombiemode_using_sleightofhand_perk)
	{
		registerclientfield("toplayer", "perk_sleight_of_hand", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_tombstone_perk) && level.zombiemode_using_tombstone_perk)
	{
		registerclientfield("toplayer", "perk_tombstone", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_perk_intro_fx) && level.zombiemode_using_perk_intro_fx)
	{
		registerclientfield("scriptmover", "clientfield_perk_intro_fx", 1000, 1, "int");
	}
	if (isdefined(level.zombiemode_using_chugabud_perk) && level.zombiemode_using_chugabud_perk)
	{
		registerclientfield("toplayer", "perk_chugabud", 1000, 1, "int");
	}
	if (isdefined(level._custom_perks))
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
}

init_client_flags()
{
	level.disable_deadshot_clientfield = 1;
	if (isdefined(level.use_clientside_board_fx) && level.use_clientside_board_fx)
	{
		level._zombie_scriptmover_flag_board_horizontal_fx = 14;
		level._zombie_scriptmover_flag_board_vertical_fx = 13;
	}
	if (isdefined(level.use_clientside_rock_tearin_fx) && level.use_clientside_rock_tearin_fx)
	{
		level._zombie_scriptmover_flag_rock_fx = 12;
	}
	level._zombie_player_flag_cloak_weapon = 14;
	if (!(isdefined(level.disable_deadshot_clientfield) && level.disable_deadshot_clientfield))
	{
		registerclientfield("toplayer", "deadshot_perk", 1, 1, "int");
	}
	registerclientfield("actor", "zombie_riser_fx", 1, 1, "int");
	if (!(isdefined(level._no_water_risers) && level._no_water_risers))
	{
		registerclientfield("actor", "zombie_riser_fx_water", 1, 1, "int");
	}
	if (isdefined(level._foliage_risers) && level._foliage_risers)
	{
		registerclientfield("actor", "zombie_riser_fx_foliage", 12000, 1, "int");
	}
	if (isdefined(level.risers_use_low_gravity_fx) && level.risers_use_low_gravity_fx)
	{
		registerclientfield("actor", "zombie_riser_fx_lowg", 1, 1, "int");
	}
}

// give_perk() - stock override (originally from zm_expanded.gsc).
// 2026-07-30: the old "self perkHUD(perk);" pop-up call (folded in from
// custom_perkanimuncompiled.gsc, which replaceFunc'd this same stock function)
// was REMOVED from the end of this function. The perk pop-up is now drawn by
// the "Vanguard Perk Animation" module below, which simply listens for the
// "perk_acquired" notify this function already fires - so give_perk() no
// longer contains ANY HUD hook of its own.
// IMPORTANT for the new module: keep appending the perk to self.perks_active
// BEFORE notify("perk_acquired") (as below) - the listener reads the last
// entry of perks_active to work out which perk was just awarded.
give_perk( perk, bought )
{
    self setperk( perk );
    self.num_perks++;
    if ( isdefined( bought ) && bought )
    {
        self maps\mp\zombies\_zm_audio::playerexert( "burp" );
        if ( isdefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
            self maps\mp\zombies\_zm_audio::perk_vox( perk );
        else
            self delay_thread( 1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );
        self setblur( 4, 0.1 );
        wait 0.1;
        self setblur( 0, 0.1 );
        self notify( "perk_bought", perk );
    }

    self perk_set_max_health_if_jugg( perk, 1, 0 );

    if (!(isDefined(level.disable_deadshot_clientfield) && level.disable_deadshot_clientfield))
    {
        if ( perk == "specialty_deadshot" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
        else if ( perk == "specialty_deadshot_upgrade" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
    }

    if ( perk == "specialty_scavenger" )
        self.hasperkspecialtytombstone = 1;

    players = get_players();
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
    {
        self.lives = 1;
        if ( !isdefined( level.solo_lives_given ) )
            level.solo_lives_given = 0;
        if ( isdefined( level.solo_game_free_player_quickrevive ) )
            level.solo_game_free_player_quickrevive = undefined;
        else
            level.solo_lives_given++;
        if ( level.solo_lives_given >= 3 )
            flag_set( "solo_revive" );
        self thread solo_revive_buy_trigger_move( perk );
    }
    if ( perk == "specialty_finalstand" )
    {
        self.lives = 1;
        self.hasperkspecialtychugabud = 1;
        self notify( "perk_chugabud_activated" );
    }

    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
        self thread [[ level._custom_perks[perk].player_thread_give ]]();

    self set_perk_clientfield( perk, 1 );

    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );

    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );

    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];
    self.perk_history = add_to_array( self.perk_history, perk, 0 );

    if ( !isdefined( self.perks_active ) )
        self.perks_active = [];
    self.perks_active[self.perks_active.size] = perk;

    self notify( "perk_acquired" );
    self thread perk_think( perk );
}

default_vending_precaching()
{
    if ( isdefined( level.zombiemode_using_pack_a_punch ) && level.zombiemode_using_pack_a_punch )
    {
        precacheitem( "zombie_knuckle_crack" );
        precachemodel( "p6_anim_zm_buildable_pap" );
        precachemodel( "p6_anim_zm_buildable_pap_on" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
        level._effect["packapunch_fx"] = loadfx( "maps/zombie/fx_zombie_packapunch" );
        level.machine_assets["packapunch"] = spawnstruct();
        level.machine_assets["packapunch"].weapon = "zombie_knuckle_crack";
        level.machine_assets["packapunch"].off_model = "p6_anim_zm_buildable_pap";
        level.machine_assets["packapunch"].on_model = "p6_anim_zm_buildable_pap_on";
    }

    if ( isdefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
    {
        precacheitem( "zombie_perk_bottle_additionalprimaryweapon" );
        precacheshader( "specialty_additionalprimaryweapon_zombies" );
        precachemodel( "zombie_vending_three_gun" );
        precachemodel( "zombie_vending_three_gun_on" );
        precachestring( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
        level._effect["additionalprimaryweapon_light"] = loadfx( "misc/fx_zombie_cola_arsenal_on" );
        level.machine_assets["additionalprimaryweapon"] = spawnstruct();
        level.machine_assets["additionalprimaryweapon"].weapon = "zombie_perk_bottle_additionalprimaryweapon";
        level.machine_assets["additionalprimaryweapon"].off_model = "zombie_vending_three_gun";
        level.machine_assets["additionalprimaryweapon"].on_model = "zombie_vending_three_gun_on";
    }

    if ( isdefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
    {
        precacheitem( "zombie_perk_bottle_deadshot" );
        precacheshader( "specialty_ads_zombies" );
        precachemodel( "p6_zm_al_vending_ads_on" );
        precachestring( &"ZOMBIE_PERK_DEADSHOT" );
        level._effect["deadshot_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["deadshot"] = spawnstruct();
        level.machine_assets["deadshot"].weapon = "zombie_perk_bottle_deadshot";
        level.machine_assets["deadshot"].off_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].on_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].power_on_callback = ::vending_deadshot_power_on;
		level.machine_assets["deadshot"].power_off_callback = ::vending_deadshot_power_off;
    }

    if ( isdefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
    {
        precacheitem( "zombie_perk_bottle_doubletap" );
        precacheshader( "specialty_doubletap_zombies" );
        precachemodel( "zombie_vending_doubletap2" );
        precachemodel( "zombie_vending_doubletap2_on" );
        precachestring( &"ZOMBIE_PERK_DOUBLETAP" );
        level._effect["doubletap_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["doubletap"] = spawnstruct();
        level.machine_assets["doubletap"].weapon = "zombie_perk_bottle_doubletap";
        level.machine_assets["doubletap"].off_model = "zombie_vending_doubletap2";
        level.machine_assets["doubletap"].on_model = "zombie_vending_doubletap2_on";
    }

    if ( isdefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
    {
        precacheitem( "zombie_perk_bottle_jugg" );
        precacheshader( "specialty_juggernaut_zombies" );
        precachemodel( "zombie_vending_jugg" );
        precachemodel( "zombie_vending_jugg_on" );
        precachestring( &"ZOMBIE_PERK_JUGGERNAUT" );
        level._effect["jugger_light"] = loadfx( "misc/fx_zombie_cola_jugg_on" );
        level.machine_assets["juggernog"] = spawnstruct();
        level.machine_assets["juggernog"].weapon = "zombie_perk_bottle_jugg";
        level.machine_assets["juggernog"].off_model = "zombie_vending_jugg";
        level.machine_assets["juggernog"].on_model = "zombie_vending_jugg_on";
    }

    if ( isdefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
    {
        precacheitem( "zombie_perk_bottle_marathon" );
        precacheshader( "specialty_marathon_zombies" );
        precachemodel( "zombie_vending_marathon" );
        precachemodel( "zombie_vending_marathon_on" );
        precachestring( &"ZOMBIE_PERK_MARATHON" );
        level._effect["marathon_light"] = loadfx( "maps/zombie/fx_zmb_cola_staminup_on" );
        level.machine_assets["marathon"] = spawnstruct();
        level.machine_assets["marathon"].weapon = "zombie_perk_bottle_marathon";
        level.machine_assets["marathon"].off_model = "zombie_vending_marathon";
        level.machine_assets["marathon"].on_model = "zombie_vending_marathon_on";
    }

    if ( isdefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
    {
        precacheitem( "zombie_perk_bottle_revive" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachemodel( "zombie_vending_revive" );
        precachemodel( "zombie_vending_revive_on" );
        precachestring( &"ZOMBIE_PERK_QUICKREVIVE" );
        level._effect["revive_light"] = loadfx( "misc/fx_zombie_cola_revive_on" );
        level._effect["revive_light_flicker"] = loadfx( "maps/zombie/fx_zmb_cola_revive_flicker" );
        level.machine_assets["revive"] = spawnstruct();
        level.machine_assets["revive"].weapon = "zombie_perk_bottle_revive";
        level.machine_assets["revive"].off_model = "zombie_vending_revive";
        level.machine_assets["revive"].on_model = "zombie_vending_revive_on";
    }

    if ( isdefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
    {
        precacheitem( "zombie_perk_bottle_sleight" );
        precacheshader( "specialty_fastreload_zombies" );
        precachemodel( "zombie_vending_sleight" );
        precachemodel( "zombie_vending_sleight_on" );
        precachestring( &"ZOMBIE_PERK_FASTRELOAD" );
        level._effect["sleight_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["speedcola"] = spawnstruct();
        level.machine_assets["speedcola"].weapon = "zombie_perk_bottle_sleight";
        level.machine_assets["speedcola"].off_model = "zombie_vending_sleight";
        level.machine_assets["speedcola"].on_model = "zombie_vending_sleight_on";
    }

    if ( isdefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
    {
        precacheitem( "zombie_perk_bottle_tombstone" );
        precacheshader( "specialty_tombstone_zombies" );
        precachemodel( "zombie_vending_tombstone" );
        precachemodel( "zombie_vending_tombstone_on" );
        precachemodel( "ch_tombstone1" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["tombstone"] = spawnstruct();
        level.machine_assets["tombstone"].weapon = "zombie_perk_bottle_tombstone";
        level.machine_assets["tombstone"].off_model = "zombie_vending_tombstone";
        level.machine_assets["tombstone"].on_model = "zombie_vending_tombstone_on";
    }

    //  ------------------------------------------------------------------
    //  WHO'S WHO. Stock's version of this block precaches EIGHT things; off
    //  Die Rise only three of them exist, so it is split in two.
    //
    //  🛑 THREE OF STOCK'S PRECACHES ARE FATAL OFF DIE RISE, and precaching an
    //  absent model/item is a hard load failure, not a warning:
    //      p6_zm_vending_chugabud / _on   the physical MACHINE - zm_highrise.ff
    //                                     only. There is no Who's Who machine
    //                                     anywhere else; the Wunderfizz hands
    //                                     the perk out, so nothing ever
    //                                     setmodel()s these and dropping them
    //                                     costs nothing.
    //      ch_tombstone1                  zm_transit.ff only. Stock precaches it
    //                                     HERE, in the chugabud block, but
    //                                     _zm_chugabud.gsc never references it
    //                                     even once - verified by grep over the
    //                                     whole 785-line module. It is a
    //                                     copy-paste from the tombstone block
    //                                     directly above. Carrying it would make
    //                                     five maps fail to load for an asset
    //                                     the perk does not use. It becomes real
    //                                     work in STAGE 3 (Tombstone).
    //
    //  What IS mandatory is the bottle WEAPON. _zm_perks::perk_give_bottle_begin
    //  does `weapon = level.machine_assets["whoswho"].weapon; self giveweapon(
    //  weapon )`, so without it the GIVE fails, not merely the animation. It now
    //  ships in mod.ff (zone_source\mod_locations.zone), which loads on every
    //  map, alongside its view/world models and the HUD icon material.
    //
    //  off_model/on_model are left UNDEFINED off Die Rise on purpose. Their only
    //  readers are the perk-machine loops, which iterate
    //  getentarray("vending_chugabud", ...) - empty here - so an undefined value
    //  is never dereferenced, whereas a name pointing at an unprecached model is
    //  a live trap for whoever adds a machine later.
    //  ------------------------------------------------------------------
    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
    {
        precacheitem( "zombie_perk_bottle_whoswho" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["whoswho"] = spawnstruct();
        level.machine_assets["whoswho"].weapon = "zombie_perk_bottle_whoswho";

        //  Die Rise owns a real Who's Who machine, so it keeps stock's models.
        if ( level.script == "zm_highrise" )
        {
            precachemodel( "p6_zm_vending_chugabud" );
            precachemodel( "p6_zm_vending_chugabud_on" );
            precachemodel( "ch_tombstone1" );
            level.machine_assets["whoswho"].off_model = "p6_zm_vending_chugabud";
            level.machine_assets["whoswho"].on_model = "p6_zm_vending_chugabud_on";
        }
    }

    if ( level._custom_perks.size > 0 )
    {
        a_keys = getarraykeys( level._custom_perks );
        for ( i = 0; i < a_keys.size; i++ )
        {
            if ( isdefined( level._custom_perks[a_keys[i]].precache_func ) )
                level [[ level._custom_perks[a_keys[i]].precache_func ]]();
        }
    }
}

vending_deadshot_power_on()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 2);
	}
	else
	{
		level thread clientnotifyloop("toggle_vending_deadshot_power_on", "deadshot_off");
	}
}

vending_deadshot_power_off()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 1);
	}
	else
	{
		level thread clientnotifyloop("toggle_vending_deadshot_power_off", "deadshot_on");
	}
}

clientnotifyloop(notify_str, endon_str)
{
	if (isdefined(endon_str))
	{
		level endon(endon_str);
	}
	while (1)
	{
		clientnotify(notify_str);
		level waittill("connected", player);
		wait 0.05;
	}
}

// ============================================================================
//  Vanguard Perk Animation  (perk pop-up HUD with icon + name + description)
//  Original by techboy04gaming
//  Perk names / descriptions added by NewMartinLag
//  Source: https://github.com/NewMartinLag/Vanguard-Perk-HUD-Description
// ----------------------------------------------------------------------------
//  Added 2026-07-30. REPLACES the old custom_perkanimuncompiled "perkHUD()"
//  pop-up, which never reliably showed in-game.
//
//  Key design difference vs. the old one: this does NOT hook give_perk().
//  It listens for the native "perk_acquired" notify, which stock
//  _zm_perks::give_perk (and our give_perk() override above) fires AFTER the
//  perk has actually been awarded - so it can't interfere with the purchase
//  logic, and it also fires for perks granted by other means (digs, easter
//  eggs, rounded rewards), which the old give_perk-hooked version missed or
//  double-handled. The notify carries no parameter, so the perk id is read
//  back from the last entry of self.perks_active (appended by give_perk()
//  right before it notifies).
//
//  Merged-file renames vs. the standalone file:
//    onPlayerConnect()  -> vpa_onplayerconnect()
//    onPlayerSpawned()  -> vpa_onplayerspawned()
//    init()             -> inlined in init() above ("--- Vanguard Perk
//                          Animation ---" block: icon-shader precaches and the
//                          connect-loop thread). Upstream's startup iprintln
//                          credit line was dropped (2026-07-30, user request).
//  The standalone file's end_game() helper was dropped: its body was just
//  `level waittill("game_ended");` with nothing after it, i.e. a no-op.
//  Everything else (listener, HUD builder/animation, shader/name/description
//  tables) is verbatim, only reformatted to match this file's style.
// ============================================================================
vpa_onplayerconnect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread vpa_onplayerspawned();
    }
}

vpa_onplayerspawned()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "spawned_player" );
        self.perkhud = undefined;
        self.perkname_hud = undefined;
        self.perkdesc_hud = undefined;
        self.perkspec_hud = undefined;
        self thread listen_for_perks();
    }
}

listen_for_perks()
{
    self endon( "disconnect" );
    self endon( "spawned_player" );

    for ( ;; )
    {
        self waittill( "perk_acquired" );

        // "perk_acquired" has no parameter (that's how the original game
        // triggers it). The newly awarded perk is the last element of
        // self.perks_active, appended by give_perk() right before the notify.
        if ( !isdefined( self.perks_active ) || self.perks_active.size == 0 )
            continue;

        perk = self.perks_active[self.perks_active.size - 1];
        self thread perk_bought( perk );
    }
}

perk_bought( perk )
{
    self endon( "disconnect" );
    self endon( "game_ended" );

    shader = getperkshader( perk );
    if ( shader == "" )
        return;

    // Destroy the previous HUD if the player quickly purchases another perk
    if ( isdefined( self.perkhud ) )
    {
        self.perkhud destroy();
        self.perkhud = undefined;
    }
    if ( isdefined( self.perkname_hud ) )
    {
        self.perkname_hud destroy();
        self.perkname_hud = undefined;
    }
    if ( isdefined( self.perkdesc_hud ) )
    {
        self.perkdesc_hud destroy();
        self.perkdesc_hud = undefined;
    }
    if ( isdefined( self.perkspec_hud ) )
    {
        self.perkspec_hud destroy();
        self.perkspec_hud = undefined;
    }

    // --- Perk icon ---
    hud = newclienthudelem( self );
    hud.alignx = "center";
    hud.aligny = "middle";
    hud.horzalign = "user_center";
    hud.vertalign = "user_top";
    hud.x = 0;
    hud.y = 55;
    hud.alpha = 0;
    hud.color = ( 1, 1, 1 );
    hud.hidewheninmenu = 1;
    hud.foreground = 1;
    hud setshader( shader, 64, 64 );

    // --- Perk name (line 1, white, larger) ---
    name_hud = newclienthudelem( self );
    name_hud.alignx = "center";
    name_hud.aligny = "middle";
    name_hud.horzalign = "user_center";
    name_hud.vertalign = "user_top";
    name_hud.x = 0;
    name_hud.y = 122;
    name_hud.fontscale = 1.6;
    name_hud.alpha = 0;
    name_hud.color = ( 1, 1, 1 );
    name_hud.hidewheninmenu = 1;
    name_hud.foreground = 1;
    name_hud settext( getPerkName( perk ) );

    // --- Perk description (line 2) ---
    desc_hud = newclienthudelem( self );
    desc_hud.alignx = "center";
    desc_hud.aligny = "middle";
    desc_hud.horzalign = "user_center";
    desc_hud.vertalign = "user_top";
    desc_hud.x = 0;
    desc_hud.y = 147;
    desc_hud.fontscale = 1.3;
    desc_hud.alpha = 0;
    desc_hud.color = ( 1, 1, 1 );
    desc_hud.hidewheninmenu = 1;
    desc_hud.foreground = 1;
    desc_hud settext( getPerkDesc( perk ) );

    // --- Special-ability line (line 3, gold) ---
    //  🛑 REMOVED in v1.53.0. It was kept "in case future text drops in", but it
    //  never received a settext() in any version, so it drew NOTHING while still
    //  consuming a client hudelem for the ~4.5s this popup lives.
    //
    //  That window is the problem. Every perk purchase spiked the popup to FOUR
    //  elements, and on Origins you buy perks from the Wunderfizz and then walk
    //  to a generator - whose capture ring is created ON DEMAND and silently
    //  is not created when the pool is empty. One of those four was pure waste.
    //  Re-add it the day it actually gets text, not before.

    self.perkhud = hud;
    self.perkname_hud = name_hud;
    self.perkdesc_hud = desc_hud;

    // ---- Fade IN ----
    hud scaleovertime( 0.4, 64, 64 );
    hud fadeovertime( 0.4 );
    hud.alpha = 1;

    name_hud fadeovertime( 0.4 );
    name_hud.alpha = 1;

    desc_hud fadeovertime( 0.4 );
    desc_hud.alpha = 1;

    wait 3.5;

    // ---- Fade OUT ----
    hud fadeovertime( 0.5 );
    hud.alpha = 0;

    name_hud fadeovertime( 0.5 );
    name_hud.alpha = 0;

    desc_hud fadeovertime( 0.5 );
    desc_hud.alpha = 0;

    wait 0.55;

    hud destroy();
    name_hud destroy();
    desc_hud destroy();

    self.perkhud = undefined;
    self.perkname_hud = undefined;
    self.perkdesc_hud = undefined;
}

// Shader (icon material) for each perk
getperkshader( perk )
{
    switch ( perk )
    {
        case "specialty_armorvest":
            return "specialty_juggernaut_zombies";
        case "specialty_quickrevive":
            return "specialty_quickrevive_zombies";
        case "specialty_fastreload":
            return "specialty_fastreload_zombies";
        case "specialty_rof":
            return "specialty_doubletap_zombies";
        case "specialty_longersprint":
            return "specialty_marathon_zombies";
        case "specialty_flakjacket":
            return "specialty_divetonuke_zombies";
        case "specialty_deadshot":
            return "specialty_ads_zombies";
        case "specialty_additionalprimaryweapon":
            return "specialty_additionalprimaryweapon_zombies";
        case "specialty_scavenger":
            return "specialty_tombstone_zombies";
        case "specialty_finalstand":
            return "specialty_chugabud_zombies";
        case "specialty_nomotionsensor":
            return "specialty_vulture_zombies";
        case "specialty_grenadepulldeath":
            return "specialty_electric_cherry_zombie";
        default:
            return "";
    }
}

// Display name of each perk.
// (Upstream keeps a Spanish translation in brackets on Tombstone / Who's Who /
// Vulture Aid - left as shipped; trim the parentheses if you want pure English.)
getPerkName( perk )
{
    switch ( perk )
    {
        case "specialty_armorvest":
            return "Jugger-Nog";
        case "specialty_fastreload":
            return "Speed Cola";
        case "specialty_quickrevive":
            return "Quick Revive";
        case "specialty_rof":
            return "Double Tap 2.0";
        case "specialty_longersprint":
            return "Stamin-Up";
        case "specialty_additionalprimaryweapon":
            return "Mule Kick";
        case "specialty_deadshot":
            return "Deadshot Daiquiri";
        case "specialty_flakjacket":
            return "PhD Flopper";
        case "specialty_scavenger":
            return "Tombstone";
        case "specialty_finalstand":
            return "Who's Who";
        case "specialty_nomotionsensor":
            return "Vulture Aid Elixir";
        case "specialty_grenadepulldeath":
            return "Electric Cherry";
        default:
            return "";
    }
}

// Description of each perk
getPerkDesc( perk )
{
    switch ( perk )
    {
        case "specialty_armorvest":
            return "Increase Your Health from 100 to 250";
        case "specialty_fastreload":
            return "Reload Your Weapons Faster";
        case "specialty_quickrevive":
            return "In Solo Mode, You Revive Yourself. In Co-op Mode, You Revive Your Allies Faster";
        case "specialty_rof":
            return "Doubles the fire rate and increases damage";
        case "specialty_longersprint":
            return "You Run Faster";
        case "specialty_additionalprimaryweapon":
            return "Allows You to Carry 3 Weapons Instead of 2";
        case "specialty_deadshot":
            return "Improves Automatic Head Aiming and Reduces Recoil";
        case "specialty_flakjacket":
            return "Immune to Explosive Damage. Creates Explosions When You Throw Yourself to the Ground";
        case "specialty_scavenger":
            return "When You Die, You Leave Behind a Tombstone With Your Weapons and Perks | Co-op Only";
        case "specialty_finalstand":
            return "Create a Clone to Bring Yourself Back to Life—Wait, Why Did You Buy It?";
        case "specialty_nomotionsensor":
            return "Displays Ammo and Money Icons. Creates Green Clouds That Hide You From the Zombies";
        case "specialty_grenadepulldeath":
            return "An Electric Discharge When Recharging That Damages Nearby Zombies";
        default:
            return "";
    }
}

// ============================================================================
//  zm_hitmarkers  (was zm_hitmarkers.gsc)
// ============================================================================
init_hitmarkers()
{
    precacheshader( "damage_feedback" );
    maps\mp\zombies\_zm_spawner::register_zombie_damage_callback( ::do_hitmarker );
    maps\mp\zombies\_zm_spawner::register_zombie_death_event_callback( ::do_hitmarker_death );
    for (;;)
    {
        level waittill( "connected", player );
        player.hud_damagefeedback = newdamageindicatorhudelem( player );
        player.hud_damagefeedback.horzalign = "center";
        player.hud_damagefeedback.vertalign = "middle";
        player.hud_damagefeedback.x = -12;
        player.hud_damagefeedback.y = -12;
        player.hud_damagefeedback.alpha = 0;
        player.hud_damagefeedback.archived = 1;
        player.hud_damagefeedback.color = ( 1, 1, 1 );
        player.hud_damagefeedback setshader( "damage_feedback", 24, 48 );
        player.hud_damagefeedback_red = newdamageindicatorhudelem( player );
        player.hud_damagefeedback_red.horzalign = "center";
        player.hud_damagefeedback_red.vertalign = "middle";
        player.hud_damagefeedback_red.x = -12;
        player.hud_damagefeedback_red.y = -12;
        player.hud_damagefeedback_red.alpha = 0;
        player.hud_damagefeedback_red.archived = 1;
        player.hud_damagefeedback_red.color = ( 1, 0, 0 );
        player.hud_damagefeedback_red setshader( "damage_feedback", 24, 48 );
    }
}

updatedamagefeedback( mod, inflictor, death )
{
    if ( !isplayer( self ) || isdefined( self.disable_hitmarkers ) )
        return;
    if ( isdefined( mod ) && mod != "MOD_CRUSH" && ( mod != "MOD_GRENADE_SPLASH" && mod != "MOD_HIT_BY_OBJECT" ) )
    {
        if ( isdefined( inflictor ) )
            self playlocalsound( "mpl_hit_alert" );
        if ( death && getdvarintdefault( "redhitmarkers", 1 ) )
        {
            self.hud_damagefeedback_red setshader( "damage_feedback", 24, 48 );
            self.hud_damagefeedback_red.alpha = 1;
            self.hud_damagefeedback_red fadeovertime( 1 );
            self.hud_damagefeedback_red.alpha = 0;
        }
        else
        {
            self.hud_damagefeedback setshader( "damage_feedback", 24, 48 );
            self.hud_damagefeedback.alpha = 1;
            self.hud_damagefeedback fadeovertime( 1 );
            self.hud_damagefeedback.alpha = 0;
        }
    }
    return 0;
}

do_hitmarker_death()
{
    if ( isdefined( self.attacker ) && isplayer( self.attacker ) && self.attacker != self )
        self.attacker thread updatedamagefeedback( self.damagemod, self.attacker, 1 );
    return false;
}

do_hitmarker( mod, hitloc, hitorig, player, damage )
{
    if ( isdefined( player ) && isplayer( player ) && player != self )
        player thread updatedamagefeedback( mod, player, 0 );
    return false;
}

// ============================================================================
//  zm_wallbuy_fills_clip  -  wall buys refill the MAGAZINE too
// ============================================================================
new_ammo_give( weapon )
{
	give_ammo = 0;
	fill_clip = 0;
	if ( !is_offhand_weapon( weapon ) )
	{
		weapon = get_weapon_with_attachments( weapon );
		if ( isdefined( weapon ) )
		{
			stockmax = weaponstartammo( weapon );
			clipmax = weaponclipsize( weapon );
			clipcount = self getweaponammoclip( weapon );
			currstock = self getammocount( weapon );
			stockleft = currstock - clipcount;
			if ( stockleft < stockmax )
				give_ammo = 1;
			// fill the mag whenever it isn't already full
			if ( clipcount < clipmax )
				fill_clip = 1;
		}
	}
	else if ( self has_weapon_or_upgrade( weapon ) )
	{
		if ( self getammocount( weapon ) < weaponmaxammo( weapon ) )
			give_ammo = 1;
	}
	if ( give_ammo || fill_clip )
	{
		self play_sound_on_ent( "purchase" );
		if ( give_ammo )
		{
			self givemaxammo( weapon );
			alt_weap = weaponaltweaponname( weapon );
			if ( alt_weap != "none" )
				self givemaxammo( alt_weap );
		}
		if ( fill_clip )
			self setweaponammoclip( weapon, clipmax );
		return 1;
	}
	return 0;
}

// ============================================================================
//  areanotifier  (was areanotifier.gsc)
// ============================================================================
an_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread an_onplayerspawned();
    }
}

an_onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
    {
        self waittill( "spawned_player" );
        self thread zonecheck();
    }
}

zonecheck()
{
    while ( true )
    {
        if ( self.currentzone != self get_zone_name() )
        {
            if ( !issubstr( self get_zone_name(), "_" ) )
            {
                self.currentzone = self get_zone_name();
                grief_reset_message( self get_zone_name(), "" );
            }
        }
        wait 0.2;
    }
}

get_zone_name()
{
    zone = self get_player_zone();
    if ( !isdefined( zone ) )
        return "";
    name = zone;
    if ( level.script == "zm_transit" )
    {
        if ( zone == "zone_pri" )
            name = "Bus Depot";
        else if ( zone == "zone_pri2" )
            name = "Bus Depot";
        else if ( zone == "zone_station_ext" )
            name = "Bus Depot";
        else if ( zone == "zone_trans_2b" )
            name = "Bus Depot";
        else if ( zone == "zone_trans_2" )
            name = "Tunnel";
        else if ( zone == "zone_amb_tunnel" )
            name = "Tunnel";
        else if ( zone == "zone_trans_3" )
            name = "Tunnel";
        else if ( zone == "zone_roadside_west" )
            name = "Diner";
        else if ( zone == "zone_gas" )
            name = "Diner";
        else if ( zone == "zone_roadside_east" )
            name = "Diner";
        else if ( zone == "zone_trans_diner" )
            name = "Diner";
        else if ( zone == "zone_trans_diner2" )
            name = "Diner";
        else if ( zone == "zone_gar" )
            name = "Diner";
        else if ( zone == "zone_din" )
            name = "Diner";
        else if ( zone == "zone_diner_roof" )
            name = "Diner";
        else if ( zone == "zone_trans_4" )
            name = "Diner";
        else if ( zone == "zone_amb_forest" )
            name = "Forest";
        else if ( zone == "zone_trans_10" )
            name = "Church";
        else if ( zone == "zone_town_church" )
            name = "Church";
        else if ( zone == "zone_trans_5" )
            name = "Farm";
        else if ( zone == "zone_far" )
            name = "Farm";
        else if ( zone == "zone_far_ext" )
            name = "Farm";
        else if ( zone == "zone_brn" )
            name = "Farm";
        else if ( zone == "zone_farm_house" )
            name = "Farm";
        else if ( zone == "zone_trans_6" )
            name = "Farm";
        else if ( zone == "zone_cornfield_prototype" )
            name = "Nacht";
        else if ( zone == "zone_trans_pow_ext1" )
            name = "Power Station";
        else if ( zone == "zone_pow" )
            name = "Power Station";
        else if ( zone == "zone_prr" )
            name = "Power Station";
        else if ( zone == "zone_pcr" )
            name = "Power Station";
        else if ( zone == "zone_pow_warehouse" )
            name = "Power Station";
        else if ( zone == "zone_trans_8" )
            name = "Power Station";
        else if ( zone == "zone_amb_power2town" )
            name = "Cabin";
        else if ( zone == "zone_trans_9" )
            name = "Town";
        else if ( zone == "zone_town_north" )
            name = "Town";
        else if ( zone == "zone_tow" )
            name = "Town";
        else if ( zone == "zone_town_east" )
            name = "Town";
        else if ( zone == "zone_town_west" )
            name = "Town";
        else if ( zone == "zone_town_south" )
            name = "Town";
        else if ( zone == "zone_bar" )
            name = "Town";
        else if ( zone == "zone_town_barber" )
            name = "Town";
        else if ( zone == "zone_ban" )
            name = "Town";
        else if ( zone == "zone_ban_vault" )
            name = "Town";
        else if ( zone == "zone_tbu" )
            name = "Town";
        else if ( zone == "zone_trans_11" )
            name = "Town";
        else if ( zone == "zone_trans_1" )
            name = "Bus Depot";
    }
    else if ( level.script == "zm_nuked" )
    {
        if ( zone == "culdesac_yellow_zone" )
            name = "Yellow House";
        else if ( zone == "culdesac_green_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_f1_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_f2_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_backyard_zone" )
            name = "Green House";
        else if ( zone == "openhouse2_f1_zone" )
            name = "Yellow House";
        else if ( zone == "openhouse2_f2_zone" )
            name = "Yellow House";
        else if ( zone == "openhouse2_backyard_zone" )
            name = "Yellow House";
        else if ( zone == "ammo_door_zone" )
            name = "Yellow House";
    }
    else if ( level.script == "zm_highrise" )
    {
        if ( zone == "zone_green_start" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level1" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level2a" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level2b" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3a" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3b" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3c" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3d" )
            name = "Green Highrise";
        else if ( zone == "zone_orange_level1" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level2" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level3a" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level3b" )
            name = "Orange Highrise";
        else if ( zone == "zone_blue_level5" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4c" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2c" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2d" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1c" )
            name = "Blue Highrise";
    }
    else if ( level.script == "zm_prison" )
    {
        if ( zone == "zone_library" )
            name = "Library";
        else if ( zone == "zone_cellblock_west" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_gondola" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_gondola_dock" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_barber" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_east" )
            name = "Cellblock";
        else if ( zone == "zone_cafeteria" )
            name = "Cafeteria";
        else if ( zone == "zone_cafeteria_end" )
            name = "Cafeteria";
        else if ( zone == "zone_infirmary" )
            name = "Infirmary";
        else if ( zone == "zone_infirmary_roof" )
            name = "Infirmary";
        else if ( zone == "zone_roof_infirmary" )
            name = "Roof";
        else if ( zone == "zone_roof" )
            name = "Roof";
        else if ( zone == "zone_cellblock_west_warden" )
            name = "Cellblock";
        else if ( zone == "zone_warden_office" )
            name = "Warden's Office";
        else if ( zone == "cellblock_shower" )
            name = "Cellblock";
        else if ( zone == "zone_citadel_shower" )
            name = "Cellblock";
        else if ( zone == "zone_citadel" )
            name = "Citadel";
        else if ( zone == "zone_citadel_warden" )
            name = "Citadel";
        else if ( zone == "zone_citadel_stairs" )
            name = "Citadel";
        else if ( zone == "zone_citadel_basement" )
            name = "Citadel";
        else if ( zone == "zone_dock" )
            name = "Docks";
        else if ( zone == "zone_dock_puzzle" )
            name = "Docks";
        else if ( zone == "zone_dock_gondola" )
            name = "Docks";
        else if ( zone == "zone_golden_gate_bridge" )
            name = "Golden Gate Bridge";
    }
    else if ( level.script == "zm_buried" )
    {
        if ( zone == "zone_start" )
            name = "Processing";
        else if ( zone == "zone_start_lower" )
            name = "Processing";
        else if ( zone == "zone_tunnels_center" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_north" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_north2" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south2" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south3" )
            name = "Tunnels";
        else if ( zone == "zone_street_lightwest" )
            name = "Underground";
        else if ( zone == "zone_street_lightwest_alley" )
            name = "Underground";
        else if ( zone == "zone_morgue_upstairs" )
            name = "Underground";
        else if ( zone == "zone_stables" )
            name = "Underground";
        else if ( zone == "zone_street_darkwest" )
            name = "Underground";
        else if ( zone == "zone_street_darkwest_nook" )
            name = "Underground";
        else if ( zone == "zone_gun_store" )
            name = "Underground";
        else if ( zone == "zone_bank" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2stables" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2stables2" )
            name = "Underground";
        else if ( zone == "zone_street_darkeast" )
            name = "Underground";
        else if ( zone == "zone_street_darkeast_nook" )
            name = "Underground";
        else if ( zone == "zone_underground_bar" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2saloon" )
            name = "Underground";
        else if ( zone == "zone_toy_store" )
            name = "Underground";
        else if ( zone == "zone_toy_store_floor2" )
            name = "Underground";
        else if ( zone == "zone_toy_store_tunnel" )
            name = "Underground";
        else if ( zone == "zone_candy_store" )
            name = "Underground";
        else if ( zone == "zone_candy_store_floor2" )
            name = "Underground";
        else if ( zone == "zone_street_lighteast" )
            name = "Underground";
        else if ( zone == "zone_underground_courthouse" )
            name = "Underground";
        else if ( zone == "zone_underground_courthouse2" )
            name = "Underground";
        else if ( zone == "zone_street_fountain" )
            name = "Underground";
        else if ( zone == "zone_church_graveyard" )
            name = "Underground";
        else if ( zone == "zone_church_main" )
            name = "Underground";
        else if ( zone == "zone_church_upstairs" )
            name = "Underground";
        else if ( zone == "zone_mansion_lawn" )
            name = "Mansion";
        else if ( zone == "zone_mansion" )
            name = "Mansion";
        else if ( zone == "zone_mansion_backyard" )
            name = "Mansion";
        else if ( zone == "zone_maze" )
            name = "Mansion";
        else if ( zone == "zone_maze_staircase" )
            name = "Mansion";
    }
    else if ( level.script == "zm_tomb" )
    {
        if ( self.teleporting && isdefined( self.teleporting ) )
            return "";
        if ( zone == "zone_start" )
            name = "Laboratory";
        else if ( zone == "zone_start_a" )
            name = "Laboratory";
        else if ( zone == "zone_start_b" )
            name = "Laboratory";
        else if ( zone == "zone_bunker_1a" )
            name = "Bunker";
        else if ( zone == "zone_fire_stairs" )
            name = "Fire Tunnel";
        else if ( zone == "zone_bunker_1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_3a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_3b" )
            name = "Bunker";
        else if ( zone == "zone_bunker_2a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4b" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4c" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4d" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_c" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_c1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4e" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_d" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_d1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4f" )
            name = "Bunker";
        else if ( zone == "zone_bunker_5a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_5b" )
            name = "Bunker";
        else if ( zone == "zone_nml_2a" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_2" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_e" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_e1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_e2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_f" )
            name = "Bunker";
        else if ( zone == "zone_nml_1" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_4" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_0" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_5" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_farm" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_celllar" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_3" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_2b" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_6" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_8" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_10a" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_10" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_7" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_a" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_a1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_a2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_b" )
            name = "Bunker";
        else if ( zone == "zone_nml_9" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_11" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_12" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_16" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_17" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_18" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_19" )
            name = "No Man's Land";
        else if ( zone == "ug_bottom_zone" )
            name = "Excavation Site";
        else if ( zone == "zone_nml_13" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_14" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_15" )
            name = "No Man's Land";
        else if ( zone == "zone_village_0" )
            name = "Village";
        else if ( zone == "zone_village_5" )
            name = "Village";
        else if ( zone == "zone_village_5a" )
            name = "Village";
        else if ( zone == "zone_village_5b" )
            name = "Village";
        else if ( zone == "zone_village_1" )
            name = "Village";
        else if ( zone == "zone_village_4b" )
            name = "Village";
        else if ( zone == "zone_village_4a" )
            name = "Village";
        else if ( zone == "zone_village_4" )
            name = "Village";
        else if ( zone == "zone_village_2" )
            name = "Village";
        else if ( zone == "zone_village_3" )
            name = "Village";
        else if ( zone == "zone_village_3a" )
            name = "Village";
        else if ( zone == "zone_bunker_6" )
            name = "Bunker";
        else if ( zone == "zone_nml_20" )
            name = "No Man's Land";
        else if ( zone == "zone_village_6" )
            name = "Village";
        else if ( zone == "zone_chamber_0" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_1" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_2" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_3" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_4" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_5" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_6" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_7" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_8" )
            name = "The Crazy Place";
        else if ( zone == "zone_robot_head" )
            name = "Robot's Head";
    }
    return name;
}

grief_reset_message( setmsg, sound )
{
    msg = setmsg;
    players = get_players();
    if ( isdefined( level.hostmigrationtimer ) )
    {
        while ( isdefined( level.hostmigrationtimer ) )
            wait 0.05;
        wait 4;
    }
    foreach ( player in players )
        player thread show_grief_hud_msg( msg );
    player playsound( sound );
}

show_grief_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
    self endon( "disconnect" );
    while ( isdefined( level.hostmigrationtimer ) )
        wait 0.05;
    notifier_hudmsg = newclienthudelem( self );
    notifier_hudmsg.alignx = "center";
    notifier_hudmsg.aligny = "middle";
    notifier_hudmsg.horzalign = "center";
    notifier_hudmsg.vertalign = "middle";
    notifier_hudmsg.y = notifier_hudmsg.y - 100;
    if ( self issplitscreen() )
        notifier_hudmsg.y = notifier_hudmsg.y + 70;
    if ( isdefined( offset ) )
        notifier_hudmsg.y = notifier_hudmsg.y + offset;
    notifier_hudmsg.foreground = 1;
    notifier_hudmsg.fontscale = 5;
    notifier_hudmsg.alpha = 0;
    notifier_hudmsg.color = ( 1, 1, 1 );
    notifier_hudmsg.hidewheninmenu = 1;
    notifier_hudmsg.font = "default";
    if ( cleanup_end_game && isdefined( cleanup_end_game ) )
    {
        level endon( "end_game" );
        notifier_hudmsg thread show_grief_hud_msg_cleanup();
    }
    if ( isdefined( msg_parm ) )
        notifier_hudmsg settext( msg, msg_parm );
    else
        notifier_hudmsg settext( msg );
    notifier_hudmsg changefontscaleovertime( 0 );
    notifier_hudmsg fadeovertime( 1 );
    notifier_hudmsg.alpha = 1;
    notifier_hudmsg.fontscale = 2;
    wait 3.25;
    notifier_hudmsg changefontscaleovertime( 0 );
    notifier_hudmsg fadeovertime( 1 );
    notifier_hudmsg.alpha = 0;
    notifier_hudmsg.fontscale = 2;
    wait 1;
    notifier_hudmsg notify( "death" );
    if ( isdefined( notifier_hudmsg ) )
        notifier_hudmsg destroy();
}

show_grief_hud_msg_cleanup()
{
    self endon( "death" );
    level waittill( "end_game" );
    if ( isdefined( self ) )
        self destroy();
}

// ============================================================================
//  instant_start  -  skip the dead time between clicking Start and actually
//  being able to play.
// ----------------------------------------------------------------------------
//  Added 2026-07-31, user request. Rewritten same day after the first version
//  (a "race the flags early + watchdog the black screen" hack) was deployed
//  and tested in-game and had NO effect - stock's original onallplayersready()
//  thread was still running in the background driving the real timing, and
//  the hack never actually stopped it.
//
//  The rewrite replaceFunc's maps\mp\zombies\_zm::onallplayersready() directly
//  instead of racing it. Earlier reasoning (see AI_CONTEXT.md-style failure
//  mode: "unqualified same-file call defeats replaceFunc") assumed this
//  couldn't work, because _zm.gsc's own main() calls it unqualified
//  (`level thread onallplayersready();`). That assumption was wrong for this
//  specific call: BO2-Reimagined (H:\Claude\BO2-Reimagined,
//  scripts/zm/_zm_reimagined.gsc:33) successfully does
//  `replaceFunc(maps\mp\zombies\_zm::onallplayersready, scripts\zm\replaced\_zm::onallplayersready);`
//  in a real, working mod - proving replaceFunc DOES redirect this particular
//  call site. Likely explanation: it's a `thread`-ed call, not a synchronous
//  one, and threaded calls resolve through the redirectable function table
//  even when unqualified, unlike plain synchronous same-file calls.
//
//  onallplayersready_instant() below is a copy of the stock body (verified
//  against both the vanilla dump and BO2-Reimagined's copy, which are
//  otherwise identical) with two numbers changed:
//    - the "wait up to 5000ms to learn how many players are expected" timeout
//      cut to 300ms (the value getnumexpectedplayers() waits on doesn't
//      reliably resolve on Plutonium; no reason to burn the full 5s on it)
//    - fade_out_intro_screen_zm's hold/fade shortened from (5.0, 1.5) to
//      (0.15, 0.3) - still a deliberate, brief fade rather than a jarring
//      instant cut, but no longer a multi-second hold
//  Everything else (connected-player sync, solo lives/pistol setup, bot
//  handling, texture-load wait) is kept faithful to stock for correctness.
//  Since this is a real replaceFunc, stock's original body never runs at all
//  - no background thread left to race or fight.
//
//  NOTE: in-game testing (2026-07-31) confirmed this runs correctly and
//  completes fast, but it turned out NOT to be what the user was actually
//  reporting. The multi-second wait they meant happens BEFORE this point
//  entirely - it's a "match starting in..." countdown in Plutonium's private
//  match lobby UI (the Start/Play button), which typing the console command
//  `xpartygo` manually bypasses. That countdown lives in Plutonium's compiled
//  base-game menu system (CoD.Lobby module) - no loose/raw Lua source for it
//  exists anywhere checked (zm_qol's own ui_mp/, the workspace's
//  raw/ui + raw/ui_mp dump, or BO2-Reimagined), so it isn't something this
//  mod can safely patch. Left in anyway since it's a real, if smaller,
//  improvement to the post-load dead time on every game.
// ============================================================================
onallplayersready_instant()
{
    // Wait briefly for the engine to report an expected player count.
    timeout = gettime() + 1500;

    while ( getnumexpectedplayers() == 0 && gettime() < timeout )
        wait 0.05;

    // 🛑 BOUNDED ON PURPOSE. Stock spins here until connected == expected. When
    // getnumexpectedplayers() never becomes non-zero - which is what happens on
    // solo and custom games launched from the Mods menu, since there is no real
    // party populating it - the condition player_count_actual != 0 stays true
    // forever and the player is left frozen on a black screen. The previous
    // version of this function inherited that unbounded loop and merely cut the
    // FIRST timeout to 300ms, which made reaching that state MORE likely on
    // slower-loading maps (Origins). The second loop now has its own deadline.
    ready_deadline = gettime() + 4000;
    player_count_actual = 0;

    while ( getnumconnectedplayers() < getnumexpectedplayers() || player_count_actual != getnumexpectedplayers() )
    {
        players = get_players();
        player_count_actual = 0;

        for ( i = 0; i < players.size; i++ )
        {
            players[i] freezecontrols( 1 );

            if ( players[i].sessionstate == "playing" )
                player_count_actual++;
        }

        // Everyone we can actually see is in-game and the engine never gave us
        // an expectation to match - stop waiting for a number that will not come.
        if ( player_count_actual > 0 && gettime() > ready_deadline )
            break;

        wait 0.05;
    }

    setinitialplayersconnected();

    if ( 1 == getnumconnectedplayers() && getdvarint( #"scr_zm_enable_bots" ) == 1 )
    {
        level thread add_bots();
        flag_set( "initial_players_connected" );
    }
    else
    {
        players = get_players();

        if ( players.size == 1 && !is_encounter() )
        {
            flag_set( "solo_game" );
            level.solo_lives_given = 0;

            foreach ( player in players )
                player.lives = 0;

            level maps\mp\zombies\_zm::set_default_laststand_pistol( 1 );
        }

        flag_set( "initial_players_connected" );

        while ( !aretexturesloaded() )
            wait 0.05;

        thread start_zombie_logic_in_x_sec( 0.5 );
    }

    // Call our own copy directly rather than relying on the replaceFunc above to
    // redirect this call - same file, so this is unambiguous. The replaceFunc is
    // still registered for any other caller of the stock function.
    fade_out_intro_screen_zm_instant( 0.15, 0.3, 1 );
}

// ============================================================================
//  fade_out_intro_screen_zm_instant  (instant_start, part 2)
//
//  Faithful copy of stock maps\mp\zombies\_zm::fade_out_intro_screen_zm with ONE
//  change: the hardcoded `wait 1.6;` after the fade is cut to 0.05.
//
//  Why this is needed on top of onallplayersready_instant: that 1.6s is a literal
//  inside the function, not one of its arguments, so shortening the arguments
//  could never remove it. It sits directly in front of flag_set(
//  "initial_blackscreen_passed" ), which is the flag maps wait on before they
//  start their own setup - Origins (zm_tomb.gsc) does exactly that. So this delay
//  was being paid on every map, every game, regardless of the argument values.
//
//  Everything else - the introscreen hudelem setup, hud_visible, the
//  level.player_movement_suppressed / hostmigrationcontrolsfrozen unfreeze rules,
//  the destroy, and both flag/state assignments - is stock, unchanged. Getting the
//  unfreeze logic wrong here would leave players unable to move, so it is copied
//  verbatim rather than simplified.
// ============================================================================
fade_out_intro_screen_zm_instant( hold_black_time, fade_out_time, destroyed_afterwards )
{
    if ( !isdefined( level.introscreen ) )
    {
        level.introscreen = newhudelem();
        level.introscreen.x = 0;
        level.introscreen.y = 0;
        level.introscreen.horzalign = "fullscreen";
        level.introscreen.vertalign = "fullscreen";
        level.introscreen.foreground = 0;
        level.introscreen setshader( "black", 640, 480 );
        level.introscreen.immunetodemogamehudsettings = 1;
        level.introscreen.immunetodemofreecamera = 1;
        wait 0.05;
    }

    level.introscreen.alpha = 1;

    if ( isdefined( hold_black_time ) )
        wait( hold_black_time );
    else
        wait 0.2;

    if ( !isdefined( fade_out_time ) )
        fade_out_time = 1.5;

    level.introscreen fadeovertime( fade_out_time );
    level.introscreen.alpha = 0;

    // 🛑 ORIGINS PAYS STOCK'S FULL 1.6s. See zmqol_intro_hold_time() below.
    wait( zmqol_intro_hold_time() );

    level.passed_introscreen = 1;
    players = get_players();

    for ( i = 0; i < players.size; i++ )
    {
        players[i] setclientuivisibilityflag( "hud_visible", 1 );

        if ( !( isdefined( level.host_ended_game ) && level.host_ended_game ) )
        {
            if ( isdefined( level.player_movement_suppressed ) )
            {
                players[i] freezecontrols( level.player_movement_suppressed );
                continue;
            }

            if ( !( isdefined( players[i].hostmigrationcontrolsfrozen ) && players[i].hostmigrationcontrolsfrozen ) )
                players[i] freezecontrols( 0 );
        }
    }

    if ( destroyed_afterwards == 1 )
        level.introscreen destroy();

    flag_set( "initial_blackscreen_passed" );
    println( "[zm_qol] intro: held " + zmqol_intro_hold_time() + "s, passed_introscreen=1, hud_visible set on " + players.size + " player(s)" );
}

// ============================================================================
//  zmqol_intro_hold_time  -  how long to sit on black after the fade
//
//  Stock maps\mp\zombies\_zm::fade_out_intro_screen_zm waits a hardcoded 1.6s
//  here. This mod cut it to 0.05 to kill dead time at the start of every game,
//  and that shortcut is kept - EXCEPT on Origins, which pays stock's full 1.6.
//
//  🛑 WHY ORIGINS IS DIFFERENT, and what is actually known vs suspected.
//
//  KNOWN: the generator capture ring intermittently does not draw. It is NOT a
//  hudelem (checkpoint 17 said so and was wrong) and it is NOT a clientfield -
//  it is the OBJECTIVE/waypoint system, zm_tomb_capture_zones.gsc:1506:
//        objective_setprogress( self.n_objective_index, self.n_current_progress / 100 );
//  all of which is stock code this mod does not replace. The capture itself
//  still completes; only the display is missing. Confirmed by the user
//  2026-08-06: "nothing drew at all".
//
//  KNOWN: no commit has ever successfully targeted this. The one that tried
//  (0aa9f46, "free hudelems for the generator ring") aimed at the hudelem pool,
//  which checkpoint 18 established the ring does not use. So "it worked last
//  release and broke this release" is not a regression - it is the same
//  unfixed intermittent race landing differently on different boots.
//
//  SUSPECTED, and this is the change: these three lines
//        level.passed_introscreen = 1;
//        players[i] setclientuivisibilityflag( "hud_visible", 1 );
//        flag_set( "initial_blackscreen_passed" );
//  all fire 1.55s earlier than Treyarch ever ran them. Origins is the map that
//  hangs the most off that flag - initial_round_wait_func() waits on it, and
//  everything downstream of start_zombie_round_logic (including the per-zone
//  capture threads that own the objective) is sequenced behind it. An
//  intermittent, presentation-only failure on exactly the map with the deepest
//  chain off that flag is the shape of a startup race, and this was already the
//  leading theory in checkpoint 18 - it was simply never acted on.
//
//  🛑 THIS IS A TEST AS MUCH AS A FIX, and it is deliberately falsifiable. The
//  probe in zm_tomb\zm_tomb.gsc now logs whether the SERVER side is advancing
//  while nothing draws. Next boot says which it is:
//    - ring draws          -> the race was real, this is the fix, keep it
//    - progress advances,  -> server fine, purely client-side; the intro timing
//      still no ring          is NOT the cause and this hold should be reverted
//    - progress never      -> server side, and the objective is a red herring
//      advances
//
//  Costs 1.55s of black screen on one map, and nothing anywhere else.
// ============================================================================
zmqol_intro_hold_time()
{
    if ( getdvar( "mapname" ) == "zm_tomb" )
        return 1.6;   // stock

    return 0.05;
}

// ============================================================================
//  zmqol_spawn_baseline_probe   -   DIAGNOSTIC, remove once Buried spawns zombies
//
//  🛑 NO ZOMBIES ON ANY BURIED LOCATION. Confirmed in game 2026-08-02: Borough
//  and Maze both spawn none. This is NOT the Maze zone bug - the A/B run proved
//  that, because Borough never had the zone seal applied (it was gated to
//  location "maze") and fails identically:
//        SPAWNPROBE street t=20 spawners=0 multi=0 groups=0 pool=15 total=6 alive=0 limit=24 flag=1
//        SPAWNPROBE maze   t=20 spawners=0 multi=0 groups=0 pool=3  total=6 alive=0 limit=24 flag=1
//
//  Every gate in _zm.gsc::round_spawning() reads healthy - the spawn pool is
//  populated, "spawn_zombies" is set, zombie_ai_limit is 24, 6 zombies are queued
//  and none are alive. And there is NO script error anywhere in the log.
//
//  That silence is the clue. The spawn block is
//        if ( isdefined( level.zombie_spawners ) )          // _zm.gsc:3037
//        {
//            ...
//            spawner = random( level.zombie_spawners );     // _zm.gsc:3059
//            ai = spawn_zombie( spawner, spawner.targetname, spawn_point );
//        }
//  An EMPTY array is still isdefined, so it would enter, random() would yield
//  undefined, and spawner.targetname would throw a script error every attempt.
//  We see no errors - so the array is more likely UNDEFINED, which skips the whole
//  block silently and leaves ai undefined. That is a perfect match for the symptom.
//
//  🛑 The previous probe could not tell those two apart: it did
//  `if (isdefined(x)) n = x.size;` and printed 0 for both. Same measurement flaw as
//  the zbarrier and MAZEZONE probes - a bare count with no way to read it. So this
//  one reports def and size SEPARATELY.
//
//  Root script on purpose: it has to run on a map that WORKS, to establish what a
//  healthy level.zombie_spawners looks like. Nothing here is map-specific
//  (level vars and _zm_utility only), so it is legal per AI_CONTEXT rule 2.
//
//      [zm_qol] BASE <map>/<loc> t=N spawners def=<0/1> size=<n> multi=<0/1> groups=<n>
//      [zm_qol] BASE <map>/<loc> t=N pool=<n> total=<n> alive=<n> actors=<n> ailim=<n> actlim=<n> flag=<0/1>
// ============================================================================
zmqol_spawn_baseline_probe()
{
    level endon( "end_game" );

    str_where = level.script + "/" + getdvar( "ui_zm_mapstartlocation" );

    flag_wait( "start_zombie_round_logic" );

    for ( i = 0; i < 2; i++ )
    {
        wait 10;

        n_def = 0;
        n_size = 0;

        if ( isdefined( level.zombie_spawners ) )
        {
            n_def = 1;
            n_size = level.zombie_spawners.size;
        }

        n_groups = 0;

        if ( isdefined( level.zombie_spawn ) )
            n_groups = level.zombie_spawn.size;

        // 🛑 live is the whole point of this build. n_size is the array
        // _zm_spawner::init() CACHED at map init; a_live is the same query re-run
        // now. If a_live > 0 while n_size == 0, the entities exist and the cache
        // was simply built too early - which is repairable, and the repair below
        // does it. If a_live is also 0, the spawner entities genuinely are not in
        // the world on this gametype and no script fix can conjure them.
        a_live = getentarray( "zombie_spawner", "script_noteworthy" );

        println( "[zm_qol] BASE " + str_where + " t=" + ( ( i + 1 ) * 10 ) + " spawners def=" + n_def + " size=" + n_size + " live=" + a_live.size + " multi=" + is_true( level.use_multiple_spawns ) + " groups=" + n_groups );

        if ( n_size == 0 && a_live.size > 0 )
        {
            level.zombie_spawners = a_live;
            println( "[zm_qol] BASE " + str_where + " REPAIRED level.zombie_spawners -> " + level.zombie_spawners.size );
        }

        n_pool = 0;

        if ( isdefined( level.zombie_spawn_locations ) )
            n_pool = level.zombie_spawn_locations.size;

        n_total = 0;

        if ( isdefined( level.zombie_total ) )
            n_total = level.zombie_total;

        n_ailim = 0;

        if ( isdefined( level.zombie_ai_limit ) )
            n_ailim = level.zombie_ai_limit;

        n_actlim = 0;

        if ( isdefined( level.zombie_actor_limit ) )
            n_actlim = level.zombie_actor_limit;

        println( "[zm_qol] BASE " + str_where + " t=" + ( ( i + 1 ) * 10 ) + " pool=" + n_pool + " total=" + n_total + " alive=" + get_current_zombie_count() + " actors=" + get_current_actor_count() + " ailim=" + n_ailim + " actlim=" + n_actlim + " flag=" + flag( "spawn_zombies" ) );
    }
}
