#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_highrise;

main()
{
    replaceFunc( maps\mp\zm_highrise::custom_vending_precaching, ::custom_vending_precaching );
    replaceFunc( maps\mp\zm_highrise_elevators::init_elevator_perks, ::init_elevator_perks );

    //  v1.99.96 - SLIQUIFIER PRE-NERF, row 3. Installed unconditionally because
    //  replaceFunc cannot be conditional; the override is stock plus one line and
    //  the row is read by the death callback, not here. maps\mp\zombies\_zm_weap_slipgun
    //  ships in zm_highrise_patch.ff and NOWHERE else, so this reference is legal
    //  only from this file - a root script would fail to load on every other map.
    replaceFunc( maps\mp\zombies\_zm_weap_slipgun::explode_to_near_zombies, ::zmqol_explode_to_near_zombies );

    // --- custom survival start locations: adds Shopping Mall, Dragon Rooftop, Sweatshop ---

    zmqol_register_survival_clientfields();
}

// ============================================================================
//  zmqol_register_survival_clientfields
//
//  🛑 Fixes part of: DIE RISE SURVIVAL DISCONNECTS WITH EXE_CLIENT_FIELD_MISMATCH
//     on every location (dragon_rooftop, shopping_mall, rooftop).
//
//  maps\mp\zm_highrise::zclassic_preinit (zm_highrise.gsc:70-82) registers these
//  seven clientfields and then calls zm_highrise_sq::sq_highrise_clientfield_init
//  for an eighth. That function runs ONLY for zclassic. A zstandard game runs
//  zstandard_preinit instead and registers none of them - but the CLIENT
//  registers them unconditionally, so the two sets disagree and the engine drops
//  the player. Exactly the same shape as the MotD visionset_lerp bug fixed in
//  v1.1.4, just a different set of fields.
//
//  registerclientfield is a bare engine builtin with no state behind it, so
//  main() is a legal place for it (see the note in zm_tomb.gsc). Guarded on
//  !is_classic() so classic Die Rise still registers them exactly once via
//  zclassic_preinit and we do not double-register.
//
//  Versions/bit counts/types copied verbatim from the stock registrations -
//  they MUST match the client exactly or the mismatch simply changes shape.
//
//  🛑 KNOWN INCOMPLETE: the log also reports
//      Clientfield buildable in set [toplayer] is not registered on the client
//  which is the opposite direction (server has it, client does not) and is NOT
//  fixed here. Server and client both pick between a per-slot registration and a
//  single "buildable" field based on level.buildable_slot_count
//  (_zm_buildables.gsc:170-180 vs _zm_buildables.csc:40-50); on Die Rise survival
//  those two counts disagree. Until that is resolved Die Rise may still mismatch.
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "scriptmover", "clientfield_escape_pod_tell_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_sparks_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_impact_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_light_fx", 5000, 1, "int" );
    registerclientfield( "actor", "clientfield_whos_who_clone_glow_shader", 5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_audio", 5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_filter", 5000, 1, "int" );

    // The eighth one, plus the VO index table it drives.
    maps\mp\zm_highrise_sq::sq_highrise_clientfield_init();
}

init()
{
    added_weapons();
    move_marathon_origins();

    //  .jumpingjacks (amount) / spawn_jumpingjacks <n>. Installed here, not in
    //  the root script - maps\mp\zombies\_zm_ai_leaper is Die Rise-only and a
    //  qualified reference to it from a root file crashes every other map at load.
    level.zmqol_boss_name = "jumpingjacks";
    level.zmqol_boss_spawn_func = ::zmqol_spawn_jumpingjacks;

    //  ========================================================================
    //  v1.99.96 - DIE RISE WEAPONS. See the big banner at the bottom of this
    //  file for what each of these does and what it was checked against.
    //
    //  precachemodel HERE, not in the wall-buy thread. init() is inside the
    //  precache window - added_weapons() above it calls include_weapon, which is
    //  the same window - whereas the wall buy itself has to wait for the
    //  blackscreen. One model, already resident in zm_highrise.ff, so this costs
    //  nothing when the row is off.
    //  ========================================================================
    precachemodel( "t6_wpn_grenade_semtex_world" );

    //  Appended AFTER stock's own slipgun death callback ( _zm_weap_slipgun.gsc:49 ),
    //  so stock keeps first refusal and ours only sees corpses it declined.
    maps\mp\zombies\_zm_spawner::register_zombie_death_animscript_callback( ::zmqol_slipgun_death_response );

    level thread zmqol_slipgun_prenerf_watch();
    level thread zmqol_semtex_wallbuy();
}

// ============================================================================
//  zmqol_spawn_jumpingjacks  -  the real leaper, one leaper round's spawn step.
//
//  🛑 UNLIKE BRUTUS AND THE PANZER, THE LEAPER HAS NO NOTIFY HOOK. Its spawns
//  happen inline inside leaper_round_spawning() (_zm_ai_leaper.gsc:570), which is
//  a whole round - it plays the dog-round vo, sets level.zombie_total, threads
//  the accuracy tracking and the aftermath, and does not return until the round
//  ends. Calling that would start a leaper ROUND, not spawn a leaper.
//
//  So this replicates its per-spawn step and nothing else. Straight out of :644,
//  in the same order, with the same three helpers:
//      favorite_enemy = get_favorite_enemy()                             (:733)
//      spawn_point    = leaper_spawn_logic( level.enemy_dog_spawns, ... ) (:800)
//      ai             = spawn_zombie( level.leaper_spawners[0] )
//      ai.favoriteenemy / ai.spawn_point, then leaper_spawn_fx()         (:924)
//  get_favorite_enemy() is safe to call outside a leaper round: it calls
//  getplayers() itself and defaults .hunted_by, so it depends on nothing the
//  round sets up. spawn_zombie is _zm_utility, already included above.
//
//  📝 level.zombie_total and level.leaper_count are deliberately NOT touched.
//  Those are the ROUND's bookkeeping - decrementing zombie_total outside a leaper
//  round would tell the round system a zombie it never counted has been used up.
//  These are extra AI on top of the round, which is what the command is for.
// ============================================================================
//  ============================================================================
//  🛑 v1.90.4 - THE GUARD WAS GATING ON A VARIABLE THE SPAWN PATH NEVER READS.
//
//  User, 2026-08-14, on Die Rise: ".jumpingjacks didn't work" ->
//  "[zm_qol] the jumpingjacks spawner is not running on this map".
//
//  That message is the else branch of quality_of_life.gsc:5483, i.e. this
//  function returned 0. It was the level.enemy_dog_spawns half of the guard.
//
//  🌟 THAT ARRAY IS ONLY EVER SET BY THE zstandard GAMETYPE.
//      _zm_ai_dogs.gsc:83   level.enemy_dog_spawns = getentarray( "zombie_spawner_dog_init", ... )
//  and the only caller of _zm_ai_dogs::init() is gametypes_zm\zstandard.gsc:27.
//  zclassic never calls it, so on a classic game the array is undefined and the
//  command refused to run - on the map whose boss it is.
//
//  🌟 AND THE ARRAY IS IRRELEVANT ANYWAY: leaper_spawn_logic( leaper_array,
//  favorite_enemy ) (_zm_ai_leaper.gsc:800) NEVER READS ITS FIRST PARAMETER. It
//  builds its candidates from level.zones[zone].leaper_locations. So does the
//  older leaper_spawn_logic_old(), which reads a getstructarray() instead. Stock
//  passes level.enemy_dog_spawns at :645 purely as a leftover. The call below
//  keeps passing it for exact parity with stock's line - it is inert either way,
//  and an unread parameter is not worth deviating from the port over.
//
//  WHAT THE PATH ACTUALLY NEEDS, and what is guarded now instead:
//      level.leaper_spawners     - spawn_zombie( level.leaper_spawners[0] )
//      level.active_zone_names   - leaper_spawn_logic foreaches it; foreach over
//                                  an undefined array is a script error, and
//                                  Plutonium swallows those silently.
//  Both are populated by core, gametype-independent code: leaper_spawner_init()
//  from _zm_ai_leaper::init() (registered into level.custom_ai_type by
//  zm_highrise.gsc:182, every gametype), and _zm_zonemgr.gsc:798/936. Verified
//  against the stock dump, not assumed - which is also why jumping-jack ROUNDS
//  work in classic while this command did not.
//  ============================================================================
zmqol_spawn_jumpingjacks( n_amount )
{
    if ( !isdefined( level.leaper_spawners ) )
        return 0;

    if ( !level.leaper_spawners.size )
        return 0;

    if ( !isdefined( level.active_zone_names ) )
        return 0;

    level thread zmqol_spawn_jumpingjacks_think( n_amount );

    return n_amount;
}

zmqol_spawn_jumpingjacks_think( n_amount )
{
    level endon( "intermission" );
    level endon( "end_game" );

    for ( i = 0; i < n_amount; i++ )
    {
        favorite_enemy = maps\mp\zombies\_zm_ai_leaper::get_favorite_enemy();
        spawn_point = maps\mp\zombies\_zm_ai_leaper::leaper_spawn_logic( level.enemy_dog_spawns, favorite_enemy );
        ai = spawn_zombie( level.leaper_spawners[0] );

        if ( isdefined( ai ) )
        {
            ai.favoriteenemy = favorite_enemy;
            ai.spawn_point = spawn_point;

            //  Stock passes spawn_point as both the caller and the argument; it
            //  can be undefined if every spawn node is occupied, and playing the
            //  fx on an undefined ent is a script error, so gate on it. The
            //  leaper itself is already spawned and functional either way.
            if ( isdefined( spawn_point ) )
                spawn_point thread maps\mp\zombies\_zm_ai_leaper::leaper_spawn_fx( ai, spawn_point );
        }

        //  Stagger, so a request for several does not put them all through the
        //  same spawn node in one frame.
        wait 0.5;
    }
}

custom_vending_precaching()
{
    if ( isdefined( level.zombiemode_using_pack_a_punch ) && level.zombiemode_using_pack_a_punch )
    {
        precacheitem( "zombie_knuckle_crack" );
        precachemodel( "p6_anim_zm_buildable_pap" );
        precachemodel( "p6_anim_zm_buildable_pap_on" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
        level._effect["packapunch_fx"] = loadfx( "maps/zombie/fx_zmb_highrise_packapunch" );
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
        //  v2.8.1 - WAS zombie_vending_ads / _ads_on. Those two names are stock
        //  Treyarch's and they resolve to NOTHING: neither is an xmodel in any of
        //  the 132 retail fastfiles, nor in mod.ff (measured with Unlinker --list
        //  over the whole zone\all set). Stock never noticed because stock never
        //  sets level.zombiemode_using_deadshot_perk on Die Rise - quality_of_life
        //  .gsc::perks() does, so this branch runs here and only here. The mod's
        //  own default_vending_precaching() has always used the real Alcatraz
        //  cabinet, and so does stock Mob of the Dead; Die Rise was the one copy
        //  that never got the correction.
        precachemodel( "p6_zm_al_vending_ads_on" );
        precachestring( &"ZOMBIE_PERK_DEADSHOT" );
        level._effect["deadshot_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["deadshot"] = spawnstruct();
        level.machine_assets["deadshot"].weapon = "zombie_perk_bottle_deadshot";
        level.machine_assets["deadshot"].off_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].on_model = "p6_zm_al_vending_ads_on";
        //  🛑 NOT ADDED, DELIBERATELY. default_vending_precaching() also sets
        //  .power_on_callback / .power_off_callback here (the machine's neon
        //  toggle). Those two functions live in scripts\zm\quality_of_life.gsc,
        //  and this file has no precedent anywhere in the mod for a
        //  scripts\zm\...:: qualified reference. Qualified refs resolve at SCRIPT
        //  LOAD, so getting the form wrong does not misbehave - it stops Die Rise
        //  loading at all. Left for a deliberate, booted change rather than
        //  smuggled in with an asset fix. See the sweep report, finding #4b.
    }

    if ( isdefined( level.zombiemode_using_divetonuke_perk ) && level.zombiemode_using_divetonuke_perk )
    {
        precacheitem( "zombie_perk_bottle_nuke" );
        precacheshader( "specialty_divetonuke_zombies" );
        //  v2.8.1 - WAS zombie_vending_nuke / _nuke_on; same measurement, same
        //  cause as the deadshot block above. Neither name exists in any fastfile.
        precachemodel( "p6_zm_al_vending_nuke_on" );
        precachestring( &"ZOMBIE_PERK_DIVETONUKE" );
        level._effect["divetonuke_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["divetonuke"] = spawnstruct();
        level.machine_assets["divetonuke"].weapon = "zombie_perk_bottle_nuke";
        level.machine_assets["divetonuke"].off_model = "p6_zm_al_vending_nuke_on";
        level.machine_assets["divetonuke"].on_model = "p6_zm_al_vending_nuke_on";
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

    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
    {
        precacheitem( "zombie_perk_bottle_whoswho" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachemodel( "p6_zm_vending_chugabud" );
        precachemodel( "p6_zm_vending_chugabud_on" );
        precachemodel( "ch_tombstone1" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["whoswho"] = spawnstruct();
        level.machine_assets["whoswho"].weapon = "zombie_perk_bottle_whoswho";
        level.machine_assets["whoswho"].off_model = "p6_zm_vending_chugabud";
        level.machine_assets["whoswho"].on_model = "p6_zm_vending_chugabud_on";
	}
	if (level._custom_perks.size > 0)
	{
		a_keys = getarraykeys(level._custom_perks);
		for (i = 0; i < a_keys.size; i++)
		{
			if (isdefined(level._custom_perks[a_keys[i]].precache_func))
			{
				level [[level._custom_perks[a_keys[i]].precache_func]]();
			}
		}
	}
}

init_elevator_perks()
{
    level.elevator_perks = [];
    level.elevator_perks_building = [];
    level.elevator_perks_building["green"] = [];
    level.elevator_perks_building["blue"] = [];
    level.elevator_perks_building["green"][0] = spawnstruct();
    level.elevator_perks_building["green"][0].model = "zombie_vending_revive";
    level.elevator_perks_building["green"][0].script_noteworthy = "specialty_quickrevive";
    level.elevator_perks_building["green"][0].turn_on_notify = "revive_on";
    a = 1;
    b = 2;

    if ( randomint( 100 ) > 50 )
    {
        a = 2;
        b = 1;
    }

    level.elevator_perks_building["green"][a] = spawnstruct();
    level.elevator_perks_building["green"][a].model = "p6_zm_vending_chugabud";
    level.elevator_perks_building["green"][a].script_noteworthy = "specialty_finalstand";
    level.elevator_perks_building["green"][a].turn_on_notify = "chugabud_on";
    level.elevator_perks_building["green"][b] = spawnstruct();
    level.elevator_perks_building["green"][b].model = "zombie_vending_sleight";
    level.elevator_perks_building["green"][b].script_noteworthy = "specialty_fastreload";
    level.elevator_perks_building["green"][b].turn_on_notify = "sleight_on";
    level.elevator_perks_building["blue"][0] = spawnstruct();
    level.elevator_perks_building["blue"][0].model = "zombie_vending_three_gun";
    level.elevator_perks_building["blue"][0].script_noteworthy = "specialty_additionalprimaryweapon";
    level.elevator_perks_building["blue"][0].turn_on_notify = "specialty_additionalprimaryweapon_power_on";
    level.elevator_perks_building["blue"][1] = spawnstruct();
    level.elevator_perks_building["blue"][1].model = "zombie_vending_jugg";
    level.elevator_perks_building["blue"][1].script_noteworthy = "specialty_armorvest";
    level.elevator_perks_building["blue"][1].turn_on_notify = "juggernog_on";
    level.elevator_perks_building["blue"][2] = spawnstruct();
    level.elevator_perks_building["blue"][2].model = "zombie_vending_doubletap2";
    level.elevator_perks_building["blue"][2].script_noteworthy = "specialty_rof";
    level.elevator_perks_building["blue"][2].turn_on_notify = "doubletap_on";
    level.elevator_perks_building["blue"][3] = spawnstruct();
    level.elevator_perks_building["blue"][3].model = "p6_anim_zm_buildable_pap";
    level.elevator_perks_building["blue"][3].script_noteworthy = "specialty_weapupgrade";
    level.elevator_perks_building["blue"][3].turn_on_notify = "Pack_A_Punch_on";
    players_expected = getnumexpectedplayers();
    level.override_perk_targetname = "zm_perk_machine_override";
    level.elevator_perks_building["blue"] = array_randomize( level.elevator_perks_building["blue"] );
    level.elevator_perks = arraycombine( level.elevator_perks_building["green"], level.elevator_perks_building["blue"], 0, 0 );
    random_perk_structs = [];
    revive_perk_struct = getstruct( "force_quick_revive", "targetname" );
    revive_perk_struct = getstruct( revive_perk_struct.target, "targetname" );
    perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );

    for ( i = 0; i < perk_structs.size; i++ )
    {
        random_perk_structs[i] = getstruct( perk_structs[i].target, "targetname" );
        random_perk_structs[i].script_parameters = perk_structs[i].script_parameters;
        random_perk_structs[i].script_linkent = getent( "elevator_" + perk_structs[i].script_parameters + "_body", "targetname" );
    }

    green_structs = [];
    blue_structs = [];

    foreach ( perk_struct in random_perk_structs )
    {
        if ( isdefined( perk_struct.script_parameters ) )
        {
            if ( issubstr( perk_struct.script_parameters, "bldg1" ) )
            {
                green_structs[green_structs.size] = perk_struct;
                continue;
            }

            blue_structs[blue_structs.size] = perk_struct;
        }
    }

    green_structs = array_exclude( green_structs, revive_perk_struct );
    green_structs = array_randomize( green_structs );
    blue_structs = array_randomize( blue_structs );
    level.random_perk_structs = array( revive_perk_struct );
    level.random_perk_structs = arraycombine( level.random_perk_structs, green_structs, 0, 0 );
    level.random_perk_structs = arraycombine( level.random_perk_structs, blue_structs, 0, 0 );

    for ( i = 0; i < level.elevator_perks.size; i++ )
    {
        if ( !isdefined( level.random_perk_structs[i] ) )
            continue;

        level.random_perk_structs[i].targetname = "zm_perk_machine_override";
        level.random_perk_structs[i].model = level.elevator_perks[i].model;
        level.random_perk_structs[i].script_noteworthy = level.elevator_perks[i].script_noteworthy;
        level.random_perk_structs[i].turn_on_notify = level.elevator_perks[i].turn_on_notify;

        if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
            level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];

        level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_perk_structs[i];
	}

	static_perk_structs = getstructarray("zm_perk_machine", "targetname");

	foreach (static_perk_struct in static_perk_structs)
	{
		if (static_perk_struct.script_noteworthy == "specialty_longersprint" || static_perk_struct.script_noteworthy == "specialty_flakjacket")
		{
			level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = static_perk_struct;
		}
	}
}

added_weapons()
{
    if (level.script == "zm_highrise")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );
    }
}

move_marathon_origins()
{
	if (!is_gametype_active("zclassic"))
	{
		return;
	}

	trigs = getentarray("vending_marathon", "target");

	if (!isdefined(trigs))
	{
		return;
	}

	foreach (trig in trigs)
	{
		if (!isdefined(trig.machine))
		{
			continue;
		}

		if (isdefined(trig.clip))
		{
			trig.clip.origin += anglestoup(trig.machine.angles) * 32;
		}

		if (isdefined(trig.bump))
		{
			trig.bump.origin += anglestoup(trig.machine.angles) * 96;
		}

		trig.origin += anglestoup(trig.machine.angles) * 96;
	}
}
// ============================================================================
// ============================================================================
//  DIE RISE WEAPONS  -  SLIQUIFIER PRE-NERF + SEMTEX WALL BUY      (v1.99.96)
//
//  User, 2026-08-20, after hunting online for a pre-patch Die Rise fastfile and
//  finding something better - BO2-Remix, whose source is already in the
//  workspace and whose feature list has, under Die Rise / Weapons:
//      "Semtex wallbuy added by b23r"
//      "Sliquifier kills till round 255"
//      "Sliquifier continues to chain while put away"
//      "Sliquifier no longer drops extra goo"
//  *"all 4 of these options implement them into my mod ... get that done"*
//
//  THIS UNBLOCKS THE SLIQUIFIER ROW THAT WAS HELD BACK IN v1.99.93. That row was
//  refused because the only reference then available - the "legacy" mod - sets
//  slipgun_reslip_rate = 0 and slipgun_max_kill_round = undefined, and both lines
//  do the OPPOSITE of the label on this build ( see the note over the patches
//  create_dvar block in quality_of_life.gsc ). Remix's version is a different
//  implementation and it is correct, which is why the row ships now: it sets
//  max_kill_round to 255 rather than undefined, and it treats reslip = 0 as the
//  FEATURE ( "no longer drops extra goo" ) rather than as a buff.
//
//  Everything below was checked against the shipped stock script before being
//  written, per the standing rule - Remix was the lead, not the authority:
//
//  1. KILLS TILL 255.  _zm_weap_slipgun.gsc:42 sets slipgun_max_kill_round to
//     100, and :65 turns it into level.slipgun_damage exactly once, via
//     _zm::ai_zombie_health( that round ). So the number that matters at runtime
//     is level.slipgun_damage, and setting the zombie_var alone after init would
//     do NOTHING. Both are written here. ai_zombie_health( 255 ) saturates
//     ( :3605 returns old_health the moment the +10% wraps ), so it returns the
//     largest health the curve ever reaches - the goo one-shots for good.
//
//  2. NO EXTRA GOO.  :741 and :745 gate every re-slip pool on
//     slipgun_reslip_max_spots ( stock 8 ) and on
//     `slipgun_reslip_rate > 0 && randomint( rate ) == 0` ( stock 6 ). Zeroing
//     both closes that branch and nothing else: the pool the BOLT itself lays
//     down comes from slip_bolt -> add_slippery_spot ( :645 ) and is untouched,
//     so the weapon still slicks the floor where you shot it. Only the extra
//     pools that spawn under chained corpses stop.
//
//  3. CHAINS WHILE PUT AWAY.  Stock registers ONE zombie-death animscript
//     callback for the slipgun ( :49 ), and it returns false unless
//     self.damageweapon is one of four slipgun names ( :802-809, :812 ). The
//     chain applies its damage as `dodamage( ..., "slip_goo_zm" )` ( :738 ), so
//     when that weapon name survives on the corpse the chain continues by
//     itself - and when it does not, the chain stops dead. Remix's fix does not
//     argue with damageweapon at all: it MARKS each zombie the chain lights up,
//     and registers a SECOND death callback that fires on the mark plus the
//     damage MOD, which is set from the `mod` argument and is reliable.
//     check_zombie_death_animscript_callbacks ( _zm_spawner.gsc:1840 ) walks the
//     array in registration order and stops at the first true, so stock's runs
//     first and ours is a pure fallback - it can only ADD kills stock dropped.
//
//  4. SEMTEX WALL BUY.  Die Rise already has everything it needs and none of it
//     had to be shipped:
//       - zm_highrise.gsc:848 `add_zombie_weapon( "sticky_grenade_zm", ...,
//         &"ZOMBIE_WEAPON_STICKY_GRENADE", 250, "grenade", "", 250 )` - the
//         weapon, its hint string and its 250 cost are all registered already,
//         and :870 `include_weapon( "sticky_grenade_zm", 0 )` keeps it OUT of
//         the box, so this wall buy is the only way to get it on the map.
//       - _zm.gsc:1227 loads level._effect["sticky_grenade_zm_fx"] on every map
//         that does not clear level._uses_sticky_grenades. Die Rise does not.
//       - _zm_weapons.gsc:1975 weapon_spawn_think has an explicit
//         `weapontype( ... ) == "grenade"` branch, so a grenade wall buy is a
//         stock-supported path, not a stretch.
//
//  ONE DELIBERATE DEPARTURE FROM REMIX, AND IT IS THE COMPLETENESS AUDIT.
//  Remix draws this wall buy with `t6_wpn_claymore_world` - a CLAYMORE on the
//  wall where a semtex should be. Measured with Unlinker over the real
//  fastfiles: `t6_wpn_grenade_semtex_world` IS in zm_highrise.ff, and it is the
//  only model on the map that follows the t6_wpn_*_world convention every other
//  wall buy uses. ( The name Remix's own commented-out Buried line reaches for,
//  t6_wpn_grenade_sticky_grenade_world, exists in NO zombies fastfile at all -
//  that line would have failed. ) So this ships the real semtex model.
//  CONFIRMED A SECOND WAY, from the weapon def itself: stock's own wall-buy
//  placer ( _zm_weapons.gsc:1025 ) picks its model with
//  `getweaponmodel( weapon )`, which returns the def's worldModel field. The
//  shipped def for sticky_grenade_zm ( T6-Data-Archive ZM/Weapons/WEAPONS )
//  has worldModel = t6_wpn_grenade_semtex_world - byte-for-byte the literal
//  below. The literal is kept because precachemodel() needs a name at init
//  anyway, and it is now the game's own answer, not a choice.
// ============================================================================

// ----------------------------------------------------------------------------
//  zmqol_slipgun_prenerf_watch  -  rows 1 and 2, live and reversible.
//
//  The OFF position restores the values THE GAME SHIPPED WITH, cached before
//  anything is written, rather than numbers this file invented. Stock sets
//  level.slipgun_damage from its own thread after a wait ( :60-66 ), so the
//  cache waits for it to exist instead of assuming the blackscreen was enough.
// ----------------------------------------------------------------------------
zmqol_slipgun_prenerf_watch()
{
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    while ( !isdefined( level.slipgun_damage ) )
        wait 0.05;

    n_damage_stock     = level.slipgun_damage;
    n_kill_round_stock = level.zombie_vars[ "slipgun_max_kill_round" ];
    n_rate_stock       = level.zombie_vars[ "slipgun_reslip_rate" ];
    n_spots_stock      = level.zombie_vars[ "slipgun_reslip_max_spots" ];

    b_last = -1;

    for ( ;; )
    {
        b_on = getdvarintdefault( "sliquifier_prenerf", 0 ) != 0;

        if ( b_on != b_last )
        {
            b_last = b_on;

            if ( b_on )
            {
                level.zombie_vars[ "slipgun_max_kill_round" ]   = 255;
                level.slipgun_damage = maps\mp\zombies\_zm::ai_zombie_health( 255 );
                level.zombie_vars[ "slipgun_reslip_rate" ]      = 0;
                level.zombie_vars[ "slipgun_reslip_max_spots" ] = 0;
            }
            else
            {
                level.zombie_vars[ "slipgun_max_kill_round" ]   = n_kill_round_stock;
                level.slipgun_damage                            = n_damage_stock;
                level.zombie_vars[ "slipgun_reslip_rate" ]      = n_rate_stock;
                level.zombie_vars[ "slipgun_reslip_max_spots" ] = n_spots_stock;
            }
        }

        wait 0.5;
    }
}

// ----------------------------------------------------------------------------
//  zmqol_explode_to_near_zombies  -  replaceFunc'd in main().
//
//  BYTE-FOR-BYTE STOCK ( _zm_weap_slipgun.gsc:683-757 ) PLUS ONE LINE. It is
//  installed unconditionally, so with the row OFF it has to behave exactly like
//  the function it replaced. The added line only writes a flag nothing else in
//  the 2,093-file dump reads, and the death callback that reads it checks the
//  dvar itself - so OFF is stock.
//
//  Stock's re-slip guard is `( !isdefined( enemy.slick_count ) ||
//  enemy.slick_count == 0 )`. Remix wrote `isDefined( ... ) && ... == 0`, which
//  is the opposite for an undefined count. That is invisible in Remix because it
//  zeroes the reslip rate anyway, but this mod's rows are independent, so stock's
//  condition is what ships here.
// ----------------------------------------------------------------------------
zmqol_explode_to_near_zombies( player, origin, radius, chain_depth )
{
    if ( level.zombie_vars[ "slipgun_max_kill_chain_depth" ] > 0 && chain_depth > level.zombie_vars[ "slipgun_max_kill_chain_depth" ] )
        return;

    enemies = get_round_enemy_array();
    enemies = get_array_of_closest( origin, enemies );
    minchainwait = level.zombie_vars[ "slipgun_chain_wait_min" ];
    maxchainwait = level.zombie_vars[ "slipgun_chain_wait_max" ];
    rsquared = radius * radius;
    tag = "J_Head";
    marked_zombies = [];

    if ( isdefined( enemies ) && enemies.size )
    {
        index = 0;
        enemy = enemies[ index ];

        while ( distancesquared( enemy.origin, origin ) < rsquared )
        {
            if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) && !isdefined( enemy.slipgun_sizzle ) )
            {
                trace = bullettrace( origin + vectorscale( ( 0, 0, 1 ), 50.0 ), enemy.origin + vectorscale( ( 0, 0, 1 ), 50.0 ), 0, undefined, 1 );

                if ( isdefined( trace[ "fraction" ] ) && trace[ "fraction" ] == 1 )
                {
                    enemy.slipgun_sizzle = playfxontag( level._effect[ "slipgun_simmer" ], enemy, tag );

                    //  THE ONE ADDED LINE. See row 3 in the banner above.
                    enemy.slipgun_marked = 1;

                    marked_zombies[ marked_zombies.size ] = enemy;
                }
            }

            index++;

            if ( index >= enemies.size )
                break;

            enemy = enemies[ index ];
        }
    }

    if ( isdefined( marked_zombies ) && marked_zombies.size )
    {
        foreach ( enemy in marked_zombies )
        {
            if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) )
            {
                wait( randomfloatrange( minchainwait, maxchainwait ) );

                if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) )
                {
                    if ( !isdefined( enemy.goo_chain_depth ) )
                        enemy.goo_chain_depth = chain_depth;

                    if ( enemy.health > 0 )
                    {
                        if ( player maps\mp\zombies\_zm_powerups::is_insta_kill_active() )
                            enemy.health = 1;

                        enemy dodamage( level.slipgun_damage, origin, player, player, "none", level.slipgun_damage_mod, 0, "slip_goo_zm" );
                    }

                    if ( level.slippery_spot_count < level.zombie_vars[ "slipgun_reslip_max_spots" ] )
                    {
                        if ( ( !isdefined( enemy.slick_count ) || enemy.slick_count == 0 ) && enemy.health <= 0 )
                        {
                            if ( level.zombie_vars[ "slipgun_reslip_rate" ] > 0 && randomint( level.zombie_vars[ "slipgun_reslip_rate" ] ) == 0 )
                            {
                                startpos = origin;
                                duration = 24;
                                thread maps\mp\zombies\_zm_weap_slipgun::add_slippery_spot( enemy.origin, duration, startpos );
                            }
                        }
                    }
                }
            }
        }
    }
}

// ----------------------------------------------------------------------------
//  zmqol_slipgun_death_response  -  row 3, the fallback death callback.
//
//  Registered AFTER stock's, so stock's runs first and this only sees corpses
//  stock's returned false on. Gated on the dvar, so OFF is stock.
// ----------------------------------------------------------------------------
zmqol_slipgun_death_response()
{
    if ( !getdvarintdefault( "sliquifier_prenerf", 0 ) )
        return false;

    if ( !is_true( self.slipgun_marked ) )
        return false;

    if ( !isdefined( self.damagemod ) || self.damagemod != "MOD_PROJECTILE_SPLASH" )
        return false;

    level maps\mp\zombies\_zm_spawner::zombie_death_points( self.origin, self.damagemod, self.damagelocation, self.attacker, self );
    self maps\mp\zombies\_zm_weap_slipgun::explode_into_goo( self.attacker, 0 );
    return true;
}

// ----------------------------------------------------------------------------
//  zmqol_semtex_wallbuy  -  row 4.
//
//  🛑 v2.0.2 - NOT A TOGGLE ANY MORE. User, 2026-08-20: *"this semtex wall buy
//  should just be apart of the mod not an option you can toggle on or off, so
//  get rid of that option and just keep the added wallbuys i told you to add
//  earlier."*  The `semtex_wallbuy` dvar, its create_dvar() in
//  quality_of_life.gsc and its PATCHES row in optionssettings.lua are all gone;
//  the wall buy itself is unchanged and now always spawns.
//
//  The flag_wait below STAYS. It was there so the dvar read could not race the
//  root script's create_dvar(), but it is load-bearing for a second reason as
//  well: zmqol_spawn_wallbuy_weapon() registers a static unitrigger and plays
//  the chalk fx, and both want the map fully up. Removing it would be an
//  unrelated change riding on this one.
//
//  Angle, position and the "weapon_upgrade" targetname are Remix's, which is the
//  tested placement; the MODEL is not - see the banner.
// ----------------------------------------------------------------------------
zmqol_semtex_wallbuy()
{
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    zmqol_spawn_wallbuy_weapon( ( 0, 270, 0 ), ( 2119, 1826, 3115 ), "sticky_grenade_zm_fx", "sticky_grenade_zm", "t6_wpn_grenade_semtex_world" );
}

// ----------------------------------------------------------------------------
//  zmqol_spawn_wallbuy_weapon  -  a script-placed wall buy.
//
//  Adapted from BO2-Remix's spawn_wallbuy_weapon: the melee-weapon and claymore
//  branches are dropped ( neither can be reached from here ), and the bounds are
//  measured off a throwaway script_model exactly as the original does, because
//  the trigger box has to match the model that is actually drawn.
//
//  Every helper it calls is stock: get_weapon_cost / get_weapon_hint /
//  get_weapon_display_name / wall_weapon_update_prompt / weapon_spawn_think all
//  come from maps\mp\zombies\_zm_weapons, which this file already includes, and
//  the two unitrigger calls are reached qualified.
// ----------------------------------------------------------------------------
zmqol_spawn_wallbuy_weapon( weapon_angles, weapon_coordinates, chalk_fx, weapon_name, weapon_model )
{
    tempmodel = spawn( "script_model", ( 0, 0, 0 ) );
    tempmodel.origin = weapon_coordinates;
    tempmodel.angles = weapon_angles;
    tempmodel setmodel( weapon_model );
    tempmodel useweaponhidetags( weapon_name );

    absmins = tempmodel getabsmins();
    absmaxs = tempmodel getabsmaxs();
    bounds  = absmaxs - absmins;

    stub = spawnstruct();
    stub.origin = weapon_coordinates;
    stub.angles = weapon_angles;
    stub.script_length = bounds[ 0 ] * 0.25;
    stub.script_width  = bounds[ 1 ];
    stub.script_height = bounds[ 2 ];
    stub.origin -= anglestoright( stub.angles ) * ( stub.script_length * 0.4 );
    stub.target     = weapon_name;
    stub.targetname = "weapon_upgrade";
    stub.cursor_hint = "HINT_NOICON";
    stub.cost = get_weapon_cost( weapon_name );

    if ( !is_true( level.monolingustic_prompt_format ) )
    {
        stub.hint_string = get_weapon_hint( weapon_name );
        stub.hint_parm1  = stub.cost;
    }
    else
    {
        stub.hint_parm1 = get_weapon_display_name( weapon_name );

        if ( !isdefined( stub.hint_parm1 ) || stub.hint_parm1 == "" || stub.hint_parm1 == "none" )
            stub.hint_parm1 = "missing weapon name " + weapon_name;

        stub.hint_parm2 = stub.cost;
        stub.hint_string = &"ZOMBIE_WEAPONCOSTONLY";
    }

    stub.weapon_upgrade = weapon_name;
    stub.zombie_weapon_upgrade = weapon_name;
    stub.script_unitrigger_type = "unitrigger_box_use";
    stub.require_look_at  = 1;
    stub.require_look_from = 0;
    stub.prompt_and_visibility_func = ::wall_weapon_update_prompt;

    maps\mp\zombies\_zm_unitrigger::unitrigger_force_per_player_triggers( stub, 1 );
    maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( stub, ::weapon_spawn_think );

    tempmodel delete();

    level thread zmqol_play_chalk_fx( chalk_fx, weapon_coordinates, weapon_angles );
}

// ----------------------------------------------------------------------------
//  zmqol_play_chalk_fx  -  the wall chalk.
//
//  Remix's shape: spawn it, trigger it, and respawn it whenever someone else
//  connects so a late joiner sees it too. spawnfx + triggerfx is stock's own
//  pattern for a script-placed looping effect ( maps\mp\_fx.gsc:248-256 ).
// ----------------------------------------------------------------------------
zmqol_play_chalk_fx( effect, origin, angles )
{
    level endon( "end_game" );

    if ( !isdefined( level._effect[ effect ] ) )
        return;

    for ( ;; )
    {
        fx = spawnfx( level._effect[ effect ], origin, anglestoforward( angles ), anglestoup( angles ) );
        triggerfx( fx );

        level waittill( "connected", player );

        fx delete();
    }
}
