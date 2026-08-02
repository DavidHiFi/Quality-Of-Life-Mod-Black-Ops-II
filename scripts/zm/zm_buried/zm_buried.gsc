#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_buried;

// main() runs before the map threads its own init, which is where replaceFunc has to
// happen for a hook on a map-init function to take (CLAUDE.md §4, failure mode 4).
// This file previously had no main() - it was added for the survival-locations port.
main()
{
    // zm_qol TEMPORARY narrowing markers for the Maze failure (2026-08-02).
    // Symptom: 2 script errors at load, "Unresolved external: precache / main
    // with 0 parameters in maps/mp/zm_buried.gsc". In that run NEITHER
    // scripts/zm/replaced/zm_buried_gamemodes.gsc NOR scripts/zm/locs/
    // zm_buried_loc_maze.gsc ever appears as "loaded successfully" in the log,
    // so the chain dies somewhere at/after this file. Every qualified reference
    // and unqualified call in all three files has been audited against the
    // SHIPPED bytecode and they all resolve, so these markers say which half
    // of that is wrong:
    //   BOTH print   -> main() ran and the replaceFunc resolved; look downstream.
    //   only A       -> resolving scripts\zm\replaced\zm_buried_gamemodes::init
    //                   is what fails.
    //   neither      -> zm_buried/zm_buried.gsc::main() itself is never called.
    println( "[zm_qol] MAZE marker A - zm_buried::main entered" );

    // --- custom survival start locations: adds Maze (alongside stock Borough/street) ---
    replaceFunc( maps\mp\zm_buried_gamemodes::init, scripts\zm\replaced\zm_buried_gamemodes::init );

    zmqol_enable_vulture_on_borough();

    // 🛑 REMOVED 2026-08-02: replaceFunc on maps\mp\zm_buried::buried_zone_init,
    // along with scripts\zm\replaced\zm_buried.gsc.
    //
    // It existed to zone_init/enable_zone zone_maze, zone_maze_staircase and
    // zone_mansion_backyard, on the reasoning that zone_maze is absent from
    // Buried's init_zones and is the SOURCE of both its adjacency edges, so
    // nothing would ever enable it.
    //
    // That reasoning was wrong. _zm_zonemgr::manage_zones enables the SOURCE zone,
    // not just the destination (_zm_zonemgr.gsc:586-591):
    //        if ( flags_set )
    //        {
    //            enable_zone( zkeys[z] );            <-- zone_maze itself
    //            azone.is_connected = 1;
    //            if ( !level.zones[azkeys[az]].is_enabled )
    //                enable_zone( azkeys[az] );
    //        }
    // so zm_buried_loc_maze::main()'s own flag_set("mansion_door1") is already
    // sufficient to bring all three zones up through stock adjacency.
    //
    // Confirmed against BO2-Reimagined, which is the reference for this location
    // and whose Maze spawns zombies correctly: its buried_zone_init differs from
    // stock by ONE unrelated line (zone_toy_store -> zone_candy_store) and it does
    // no maze zone work at all. Deliberately not taking that line - it changes
    // classic Buried connectivity and has nothing to do with the maze.
    //
    // With this gone, stock buried_zone_init runs unmodified.
}

// ============================================================================
//  zmqol_enable_vulture_on_borough
//
//  🛑 Fixes: "where the Vulture Aid machine is meant to be, a Speed Cola machine
//  is there instead" - reported in game on Borough survival, 2026-08-02.
//
//  The struct is NOT wrong. Our street_struct_init registers
//  specialty_nomotionsensor with model p6_zm_vending_vultureaid at
//  (1450.33, 2302.68, 12), which matches the zm_buried mapents byte for byte, and
//  the vultureaid xmodels are in the BASE zm_buried.ff (Unlinker: 7 assets), which
//  every gametype loads. Nothing is missing and nothing is mispaired.
//
//  What actually happens is in _zm_perks::perk_machine_spawn_init. It switches on
//  the perk name to tag the machine, and specialty_nomotionsensor - a DLC perk -
//  has no case, so it falls into `default:` at _zm_perks.gsc:3057:
//        use_trigger.script_string  = "speedcola_perk";
//        perk_machine.script_string = "speedcola_perk";
//        perk_machine.targetname    = "vending_sleight";
//  The escape hatch for DLC perks is the very next statement (:3071):
//        if ( isdefined( level._custom_perks[perk].perk_machine_set_kvps ) )
//            [[ ... ]]( use_trigger, perk_machine, bump_trigger, collision );
//  which for Vulture Aid is _zm_perk_vulture::vulture_perk_machine_setup, and it
//  re-tags the machine "vending_vulture".
//
//  That hook is only populated by enable_vulture_perk_for_level(), and stock
//  zm_buried.gsc:263 calls it inside `if ( is_gametype_active( "zclassic" ) )`.
//  Borough is zstandard, so on survival the perk is never registered, the default
//  branch stands, and Speed Cola's own machine thread then finds our machine by
//  getentarray( "vending_sleight", "targetname" ) and setmodels it to
//  zombie_vending_sleight. Hence a Speed Cola machine in the Vulture Aid spot -
//  and buying it would have handed out Speed Cola, not Vulture Aid.
//
//  main() is early enough and is not destructive: initialize_custom_perk_arrays()
//  and _register_undefined_perk() both only create when undefined, so registering
//  ahead of _zm_perks::init survives it.
//
//  🛑 The client half is MANDATORY. register_perk_clientfields() registers a
//  clientfield server-side; clientscripts\mp\zm_buried.csc:49 has the identical
//  zclassic-only gate, so doing this on the server alone produces
//  EXE_CLIENT_FIELD_MISMATCH. See zm_buried.csc for the matching call.
//
//  Scoped to Borough only: it is the one location whose perk set contains Vulture
//  Aid. Maze registers no vulture struct, and classic is left completely alone.
//
//  🛑 NOT verified in game yet. Needs build_ff.bat for the .csc half.
// ============================================================================
zmqol_enable_vulture_on_borough()
{
    if ( getdvar( "g_gametype" ) != "zstandard" )
        return;

    if ( getdvar( "ui_zm_mapstartlocation" ) != "street" )
        return;

    maps\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();
}

init()
{
    zmqol_precache_survival_characters();
    added_weapons();
    move_divetonuke_collision();
    level thread zmqol_spawner_probe();   // DIAGNOSTIC - remove once Maze spawns
    level thread zmqol_stuck_zombie_probe();   // DIAGNOSTIC - remove once Borough zombies move
    level thread zmqol_flopper_probe();        // DIAGNOSTIC - remove once Perma-Flopper works
}

// ============================================================================
//  zmqol_flopper_probe   -   DIAGNOSTIC. Remove once Perma-Flopper works.
//
//  Reported twice: dolphin diving from height in CLASSIC Buried produces no
//  explosion. Nothing this session touched it - ridgelandproject.gsc, where all
//  the persistent-upgrade code lives, has not been modified - so this is
//  pre-existing, but it is real and worth fixing.
//
//  The full chain, read out of stock, is three conditions and the probe splits
//  them so we stop guessing which one fails:
//
//   1. AWARDED. _zm.gsc:4168 only consults the perma path when
//      level.pers_upgrade_flopper is set (zm_buried::init_persistent_abilities,
//      is_classic only), and pers_upgrade_flopper_damage_check then requires
//      self.pers_upgrades_awarded["flopper"]. ridgelandproject.gsc:1683 does
//      `set_client_stat( "pers_flopper_counter", 1 )` and stock's required
//      value IS 1 (_zm_pers_upgrades.gsc:147) - but stats() does not run until
//      flag_wait( "initial_blackscreen_passed" ), and the award watcher only
//      re-tests an upgrade when that stat shows up in self.stats_this_frame.
//      So "granted the stat but never awarded the upgrade" is a live theory.
//
//   2. ACTIVE. pers_upgrade_flopper_watcher sets self.pers_flopper_active on
//      "dtp_start" and clears it on "dtp_end". No dive-to-prone notify, no
//      explosion, even when awarded.
//
//   3. DAMAGE. The explosion notify only fires from
//      pers_upgrade_flopper_damage_check, which is reached solely via
//      smeansofdeath == "MOD_FALLING" and then needs idamage > 0. A dive that
//      does no fall damage can never explode - which would make this not a bug
//      at all, just a shorter drop than it looks.
//
//      [zm_qol] FLOPPER t=N lvl_enabled=<0/1> awarded=<...> active=<...> falls=<n>
// ============================================================================
zmqol_flopper_probe()
{
    level endon( "end_game" );

    if ( !is_classic() )
        return;

    flag_wait( "initial_blackscreen_passed" );

    for ( i = 0; i < 3; i++ )
    {
        wait 10;

        a_players = get_players();

        if ( !isdefined( a_players ) || a_players.size == 0 )
            continue;

        player = a_players[0];

        str_lvl = "0";

        if ( isdefined( level.pers_upgrade_flopper ) && level.pers_upgrade_flopper )
            str_lvl = "1";

        str_awarded = "undef";

        if ( isdefined( player.pers_upgrades_awarded ) && isdefined( player.pers_upgrades_awarded["flopper"] ) )
            str_awarded = "" + player.pers_upgrades_awarded["flopper"];

        str_active = "undef";

        if ( isdefined( player.pers_flopper_active ) )
            str_active = "" + player.pers_flopper_active;

        n_falls = 0;

        if ( isdefined( player.pers_num_flopper_damages ) )
            n_falls = player.pers_num_flopper_damages;

        println( "[zm_qol] FLOPPER t=" + ( ( i + 1 ) * 10 ) + " lvl_enabled=" + str_lvl + " awarded=" + str_awarded + " active=" + str_active + " falls=" + n_falls );
    }
}

// ============================================================================
//  zmqol_stuck_zombie_probe   -   DIAGNOSTIC. Remove once Borough zombies move.
//
//  v1.13.1 got zombies SPAWNING on Borough (probe: size=9 live=9 pool=9 alive=6,
//  no errors). They do not MOVE. Reported in game: they play animations on the
//  spot, and the player can walk right up to them and hear them go to attack.
//
//  🛑 That last detail is the important one and it kills the obvious theory.
//  "Wrong zones enabled, zombies spawn across the map" cannot be it - if they
//  were spawning in zone_start you could not walk up to them, because
//  zone_start's four spawn points sit at z 1180..1278 (the Processing cave)
//  while the whole Borough arena is z -122..490. They are near the player.
//
//  What I could establish offline, and what I could not:
//    - 34 structs carry script_noteworthy "spawn_location"; only 7 of them are
//      barricade-linked (script_string "barricade_start_1" etc).
//    - NOTHING in the base mapents has a targetname beginning "barricade", and
//      neither addon mapents (so_zclassic / so_zencounter) contains one either.
//      So where Buried's zbarriers come from is unresolved - and if a zombie
//      spawns at a barricade whose boards never come off it stands there
//      playing the tear-down animation forever, which is EXACTLY the symptom.
//      That is the same failure documented for Origins in checkpoint 13 3a:
//      zone.zbarriers empty -> drop_all_barriers() is a no-op.
//
//  Rather than guess a third time (the project has paid for that twice on this
//  map already), this measures all three candidates at once:
//
//    dist       - small => near the player, so it is NOT a zone/geography
//                 problem. large => they are spawning somewhere unreachable.
//    zbarriers  - per enabled zone. 0 across the board => barrier theory.
//    speed      - if zombie_move_speed is undefined or 0 they were never told
//                 to move at all, which points at spawn init, not pathing.
//
//      [zm_qol] STUCK t=N player @ (x y z)
//      [zm_qol] STUCK t=N zone <name> spawn_locs=<n> zbarriers=<n>
//      [zm_qol] STUCK t=N zombie @ (x y z) dist=<n> speed=<s>
// ============================================================================
zmqol_stuck_zombie_probe()
{
    level endon( "end_game" );

    // Runs on EVERY Buried gametype now, deliberately - this round is an A/B
    // against classic, which demonstrably works, so classic has to be measured
    // too. Rule 17: comparing to a working case in the same build beat four
    // rounds of single-case probing last time.
    flag_wait( "start_zombie_round_logic" );

    str_where = getdvar( "g_gametype" ) + "/" + getdvar( "ui_zm_mapstartlocation" );

    for ( i = 0; i < 3; i++ )
    {
        wait 10;

        n = ( i + 1 ) * 10;
        a_players = get_players();

        if ( !isdefined( a_players ) || a_players.size == 0 )
            continue;

        player = a_players[0];

        // Totals, not a line per zone: 39 enabled zones made the last dump
        // unreadable, and the only number that matters is whether ANY zone
        // has zbarriers.
        n_zones = 0;
        n_spots = 0;
        n_barriers = 0;
        n_zones_with_barriers = 0;

        if ( isdefined( level.zones ) )
        {
            foreach ( str_zone, zone in level.zones )
            {
                if ( !isdefined( zone.is_enabled ) || !zone.is_enabled )
                    continue;

                n_zones++;

                if ( isdefined( zone.spawn_locations ) )
                    n_spots = n_spots + zone.spawn_locations.size;

                if ( isdefined( zone.zbarriers ) && zone.zbarriers.size > 0 )
                {
                    n_barriers = n_barriers + zone.zbarriers.size;
                    n_zones_with_barriers++;
                }
            }
        }

        println( "[zm_qol] STUCK " + str_where + " t=" + n + " zones=" + n_zones + " spawn_locs=" + n_spots + " zbarriers=" + n_barriers + " zones_with_barriers=" + n_zones_with_barriers );

        a_zombies = get_round_enemy_array();

        foreach ( zombie in a_zombies )
        {
            if ( !isdefined( zombie ) )
                continue;

            str_speed = "undef";

            if ( isdefined( zombie.zombie_move_speed ) )
                str_speed = "" + zombie.zombie_move_speed;

            // ignoreall is THE field. zombie_spawn_init sets it to 1 and only
            // zombie_setup_attack_properties clears it - and that call sits
            // immediately after the animscripted() on first_node.zbarrier at
            // _zm_spawner.gsc:537. If the zbarrier is undefined that line
            // throws, the thread dies silently, and ignoreall stays 1 forever:
            // the zombie stands still and cannot attack. Exactly the symptom.
            str_ignore = "undef";

            if ( isdefined( zombie.ignoreall ) )
                str_ignore = "" + zombie.ignoreall;

            str_zb = "no_first_node";

            if ( isdefined( zombie.first_node ) )
            {
                if ( isdefined( zombie.first_node.zbarrier ) )
                    str_zb = "yes";
                else
                    str_zb = "NO_ZBARRIER";
            }

            println( "[zm_qol] STUCK " + str_where + " t=" + n + " zombie dist=" + int( distance( zombie.origin, player.origin ) ) + " speed=" + str_speed + " ignoreall=" + str_ignore + " first_node.zbarrier=" + str_zb );
        }
    }
}

// ============================================================================
//  zmqol_spawner_probe   -   DIAGNOSTIC, A/B. Remove once Maze spawns zombies.
//
//  Where the Maze investigation actually stands, so this is not re-derived:
//
//  The zone seal is PROVEN GOOD. The 09:56 run reported, at t=30s:
//      player @ (4746, 594, 4.1) in_zone=zone_maze
//      zone_maze             en=1 act=1 occ=1 spawn=1 spots=8/8
//      zone_mansion_backyard en=1 act=1 occ=0 spawn=1 spots=3/3
//      zone_maze_staircase   en=1 act=1 occ=0 spawn=1 spots=7/7
//      POOL=18 spawners=0 zombie_total=6
//  Every condition create_spawner_list tests (_zm_zonemgr.gsc:959 - is_enabled &&
//  is_active && is_spawning_allowed, then per-spot is_enabled) is satisfied, the
//  pool is full at 18, and 6 zombies are queued. Zones are not the problem any more.
//
//  The one anomaly is level.zombie_spawners.size == 0. _zm.gsc:3059 does
//  `spawner = random( level.zombie_spawners )` and then dereferences
//  spawner.targetname, so an empty array cannot spawn anything.
//
//  🛑 WHY THAT IS NOT YET A DIAGNOSIS. _zm_spawner::init() builds that array with
//  a flat, gametype-independent getentarray("zombie_spawner","script_noteworthy"),
//  so it should hold the SAME value on Borough - which spawns zombies fine - as on
//  Maze. Either that assumption is wrong, or something on the Maze path empties it.
//  Nothing in the ZM dump registers a custom_ai_spawn_check, and Buried does not
//  set level.ignore_spawner_func (only TranZit does), so neither of the two stock
//  mechanisms that mutate the array is in play. The archived mapents cannot settle
//  it either - they contain no actor/spawner entities at all.
//
//  So this runs on EVERY Buried location and prints the same fields, to be read as
//  an A/B: load a location that works, then Maze, and diff the two lines. Whichever
//  field differs is the cause, with no further guessing.
//
//      [zm_qol] SPAWNPROBE <loc> t=N spawners=<n> multi=<0/1> groups=<n>
//      [zm_qol] SPAWNPROBE <loc> t=N pool=<n> total=<n> alive=<n> limit=<n> flag=<0/1>
// ============================================================================
zmqol_spawner_probe()
{
    level endon( "end_game" );

    str_loc = getdvar( "ui_zm_mapstartlocation" );

    flag_wait( "start_zombie_round_logic" );

    for ( i = 0; i < 2; i++ )
    {
        wait 10;

        n_spawners = 0;

        if ( isdefined( level.zombie_spawners ) )
            n_spawners = level.zombie_spawners.size;

        n_groups = 0;

        if ( isdefined( level.zombie_spawn ) )
            n_groups = level.zombie_spawn.size;

        println( "[zm_qol] SPAWNPROBE " + str_loc + " t=" + ( ( i + 1 ) * 10 ) + " spawners=" + n_spawners + " multi=" + is_true( level.use_multiple_spawns ) + " groups=" + n_groups );

        n_pool = 0;

        if ( isdefined( level.zombie_spawn_locations ) )
            n_pool = level.zombie_spawn_locations.size;

        n_total = 0;

        if ( isdefined( level.zombie_total ) )
            n_total = level.zombie_total;

        n_limit = 0;

        if ( isdefined( level.zombie_ai_limit ) )
            n_limit = level.zombie_ai_limit;

        println( "[zm_qol] SPAWNPROBE " + str_loc + " t=" + ( ( i + 1 ) * 10 ) + " pool=" + n_pool + " total=" + n_total + " alive=" + maps\mp\zombies\_zm_utility::get_current_zombie_count() + " limit=" + n_limit + " flag=" + flag( "spawn_zombies" ) );
    }
}

// ============================================================================
//  zmqol_precache_survival_characters
//
//  Pre-empts, on Buried, the exact bug that made Docks and Cell Block spawn you
//  with an invisible body, invisible view arms and an invisible weapon (and made
//  zombies unable to damage you, because a player with no model has no hit
//  geometry). Fixed for Alcatraz in v1.1.4; Buried is in the same position and
//  would have shown it the moment Maze/Borough survival got far enough to spawn
//  a player.
//
//  Cause: scripts\zm\replaced\zm_buried_gamemodes::survival_init sets
//  level.precachecustomcharacters = ::precache_team_characters, but that pointer
//  is consumed EARLY, in _zm_gametype::rungametypeprecache during
//  onprecachegametype, and preinit is not guaranteed to have run by then. On maps
//  that ship a so_zsurvival_*.ff the characters get precached through stock paths
//  anyway - but TranZit is the only map in the game that has one (verified with
//  the OAT Unlinker across every map), so on Buried nothing precaches them.
//  setmodel on a never-precached xmodel still sets the .model script field, which
//  is why the v1.1.2 probe looked healthy, but renders nothing.
//
//  maps\mp\zm_buried::precache_team_characters precaches exactly the four models
//  give_team_characters assigns: c_zom_player_cdc_dlc1_fb, c_zom_hazmat_viewhands,
//  c_zom_player_cia_dlc1_fb, c_zom_suit_viewhands. Symbol verified present in the
//  SHIPPED zm_buried.gsc bytecode out of zm_buried_patch.ff, not just the dump.
//
//  init() is a valid precache window and precaching is idempotent, so this is
//  harmless if the normal path also runs.
// ============================================================================
zmqol_precache_survival_characters()
{
    if ( is_classic() )
        return;

    maps\mp\zm_buried::precache_team_characters();
}

added_weapons()
{
    if (level.script == "zm_buried")
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

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "qcw05_zm" );
        include_weapon( "qcw05_upgraded_zm", 0 );
        add_zombie_weapon( "qcw05_zm", "qcw05_upgraded_zm", &"ZOMBIE_WEAPON_QCW05", 50, "wpck_chicom", "", undefined, 1 );

        include_weapon( "type95_zm" );
        include_weapon( "type95_upgraded_zm", 0 );
        add_zombie_weapon( "type95_zm", "type95_upgraded_zm", &"ZOMBIE_WEAPON_TYPE95", 50, "wpck_type25", "", undefined, 1 );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "python_zm" );
        include_weapon( "python_upgraded_zm", 0 );
        add_zombie_weapon( "python_zm", "python_upgraded_zm", &"ZOMBIE_WEAPON_PYTHON", 50, "wpck_python", "", undefined, 1 );

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

move_divetonuke_collision()
{
	if (!is_gametype_active("zclassic"))
	{
		return;
	}

	trigs = getentarray("vending_divetonuke", "target");

	if (!isdefined(trigs))
	{
		return;
	}

	foreach (trig in trigs)
	{
		if (isdefined(trig.clip))
		{
			trig.clip.origin += (0, 0, -128);
		}
	}
}

