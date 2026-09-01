#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_prison;

main()
{
	replaceFunc( maps\mp\zm_prison::delete_perk_machine_clip, ::delete_perk_machine_clip );
	replaceFunc( maps\mp\zm_alcatraz_utility::check_solo_status, ::qol_check_solo_status ); // 1 player = solo rules

	// --- custom survival start location: CELL BLOCK (stock Grief arena on zstandard) ---
	replaceFunc( maps\mp\zm_alcatraz_gamemodes::init, scripts\zm\replaced\zm_alcatraz_gamemodes::init );

	// 🛑 Cell Block survival killed the player on spawn. This project ships
	// Reimagined's maps\mp\zm_prison.d3dbsp mapents override but never ported the
	// working_zone_init that matches it, so the playable-area volumes and the
	// enabled zones disagreed and in_enabled_playable_area() was false at spawn.
	// See the long comment in scripts\zm\replaced\zm_prison.gsc.
	replaceFunc( maps\mp\zm_prison::working_zone_init, scripts\zm\replaced\zm_prison::working_zone_init );
}

init()
{
    precacheModel("collision_clip_32x32x128");
    zmqol_precache_survival_characters();
    added_weapons();
    level thread zmqol_prison_spawn_probe();   // TEMPORARY - see below

    //  .brutus (amount) / spawn_brutus <n>. The root script parses and clamps;
    //  the pointer is installed HERE because maps\mp\zombies\_zm_ai_brutus is a
    //  Mob-only script and a qualified reference to it from a root file would
    //  crash every other map at load. See zmqol_boss_spawn_request().
    level.zmqol_boss_name = "brutus";
    level.zmqol_boss_spawn_func = ::zmqol_spawn_brutus;

    //  v1.93.0 - the three BO1 wonder weapons vs Brutus. Installed here for the
    //  SAME reason as the spawn pointer above: this function makes a qualified
    //  call into maps\mp\zombies\_zm_ai_brutus, which is a Mob-only script, and
    //  a root file referencing it would be an unresolved external on every other
    //  map AT LOAD - a runtime guard does not help. AI_CONTEXT rule 2.
    level.zmqol_ww_boss_hit = ::zmqol_brutus_ww_hit;

    //  v1.99.62 - the Death Machine must not survive an afterlife trip.
    //  Installed from a thread rather than straight from init() because the
    //  pointer it chains is published by maps\mp\zombies\_zm_afterlife::init()
    //  and our init()'s position relative to that is not something to bet on.
    level thread zmqol_install_afterlife_loadout_hook();
}

// ============================================================================
//  zmqol_brutus_ww_hit  -  Thundergun / Wunderwaffe / Winter's Howl vs Brutus.
//
//  User, 2026-08-14: "when i shoot hit with the wunderwaffe it had no effect,
//  make it first take his helmet off with the first shot so he like pulls the
//  grenades typical brutus, second shot kills him... right now the thundergun
//  just sends brutus flying it doesnt even take his helmet off and i dont think
//  you even get a power up because of him dying incorrectly".
//
//  WHY IT BEHAVED THAT WAY - measured, not inferred:
//
//  All three guns damage through DoDamage(), which routes to Brutus's own
//  self.actor_damage_func = ::brutus_damage_override (_zm_ai_brutus.gsc:338).
//  That function only ever pops the helmet on a "head"/"helmet" hit location or
//  on accumulated EXPLOSIVE damage. DoDamage() passes neither a hit location nor
//  a means-of-death, so every wonder-weapon hit fell through to
//      return damage * n_brutus_damage_percent
//  with level.brutus_damage_percent = 0.1. So: the helmet could never come off,
//  and the tesla's health+666 became (health+666)*0.1, nowhere near lethal -
//  exactly "no effect". The thundergun's knockdown damage got the same 10%,
//  which is why it only launched him.
//
//  WHAT THIS DOES INSTEAD - two shots, as asked:
//
//    shot 1, helmet on   -> stock's own brutus_remove_helmet( vdir ). Using the
//                           real function is the point: it detaches the model,
//                           plays evt_brutus_helmet, launches the helmet as a
//                           dynent AND threads brutus_fire_teargas_when_possible(),
//                           which is the grenade-pulling reaction the user
//                           described. No lookalike.
//                           Points and the "brutus_helmet_removed" notify are
//                           awarded exactly as scale_helmet_damage() does them.
//    shot 2, helmet off  -> lethal DoDamage through the NORMAL path, so the
//                           "death" notify fires, brutus_death() runs and its
//                           powerup_drop() happens. That is the missing powerup.
//
//  🛑 THE KILL IS DELIBERATELY DoDamage AND NOT self Kill()/delete. brutus_death()
//  is a thread waiting on self waittill( "death" ) - it is what decrements
//  level.brutus_count, plays the death fx and stinger, and drops the powerup.
//  Anything that removes the entity instead of killing it skips all of that.
//
//  Damage is health*20 + 100000 so the 10% scaler cannot leave him alive at any
//  round; brutus_damage_percent is read from level rather than hardcoded in case
//  a future map or mod changes it.
//
//  Returns true when it handled the hit, so the calling gun skips its own
//  damage. Returns false for anything that is not a Brutus.
// ============================================================================
zmqol_brutus_ww_hit( player )
{
    if ( !isdefined( self ) || !isalive( self ) )
        return false;

    if ( !isdefined( self.animname ) || self.animname != "brutus_zombie" )
        return false;

    if ( !isdefined( player ) )
        return true;

    v_dir = vectornormalize( self.origin - player.origin );

    if ( isdefined( self.has_helmet ) && self.has_helmet )
    {
        self thread maps\mp\zombies\_zm_ai_brutus::brutus_remove_helmet( v_dir );

        if ( isplayer( player ) )
        {
            if ( isdefined( level.brutus_in_grief ) && level.brutus_in_grief )
                n_points = level.brutus_points_for_helmet;
            else
            {
                n_mult = maps\mp\zombies\_zm_score::get_points_multiplier( self );
                n_points = n_mult * round_up_score( level.brutus_points_for_helmet, 5 );
            }

            player maps\mp\zombies\_zm_score::add_to_player_score( n_points );
            player.pers["score"] = player.score;
            level notify( "brutus_helmet_removed", player );
        }

        return true;
    }

    self DoDamage( self.health * 20 + 100000, player.origin, player );
    return true;
}

// ============================================================================
//  zmqol_spawn_brutus  -  the real Brutus, through stock's own spawner.
//
//  brutus_spawning_logic() (_zm_ai_brutus.gsc:830) is already threaded by the
//  map and sits on `level waittill( "spawn_brutus", num )`; for each one it does
//  spawn_zombie( level.brutus_spawners[0] ) + brutus_spawn() and plays
//  zmb_ai_brutus_spawn_2d. So going through it means the alarm behaviour, the
//  zone logic, the helmet, the spawn sound and the count are all stock's - none
//  of it re-implemented here.
//
//  🛑 STOCK CAPS IT AT ONE. attempt_brutus_spawn() (:858) refuses outright when
//  level.brutus_count + n > level.brutus_max_count, and init sets
//  brutus_max_count = 1 (:79). So `.brutus 3` needs the CEILING raised, not the
//  check bypassed - raising it and then going through stock's own wrapper keeps
//  every invariant that check exists to protect, where a bare
//  `level notify( "spawn_brutus", n )` would desync level.brutus_count.
// ============================================================================
zmqol_spawn_brutus( n_amount )
{
    //  Grief and some survival variants never start the Brutus logic, so the
    //  spawner array is the honest test for "is this reachable here".
    if ( !isdefined( level.brutus_spawners ) || !isdefined( level.brutus_max_count ) )
        return 0;

    if ( !isdefined( level.brutus_count ) )
        level.brutus_count = 0;

    n_ceiling = level.brutus_count + n_amount;

    if ( level.brutus_max_count < n_ceiling )
        level.brutus_max_count = n_ceiling;

    if ( maps\mp\zombies\_zm_ai_brutus::attempt_brutus_spawn( n_amount ) )
        return n_amount;

    return 0;
}

// ============================================================================
//  zm_qol TEMPORARY DIAGNOSTIC - Cell Block instant death on spawn.
//
//  Runs on EVERY Alcatraz location (Cell Block uses the stock grief script, so
//  scripts\zm\locs\loc_common::init never runs there and the Docks probe could
//  not see it). Samples fast and early because the death is immediate.
//
//  What has already been ruled out, statically, from the shipped mapents
//  override in mod.iwd (maps\mp\zm_prison.d3dbsp, which is plain text):
//    - Spawn points exist. Of 27 player_respawn_point structs only 2 carry a
//      script_string ("zgrief_cellblock", "zclassic_prison"); the other 25 have
//      none, and _zm_gametype::get_player_spawns_for_gametype always includes
//      structs without a script_string. All four non-classic init zones
//      (zone_cellblock_east / _west / _west_barber / _west_warden) have a
//      matching player_respawn_point, so enable_zone unlocks them.
//    - Playable-area volumes exist for all four of those zones, and the ONLY
//      player_volume tagged "classic_only" is zone_cellblock_west_gondola_dock,
//      so the v1.1.5 working_zone_init port is not deleting the cellblock area.
//
//  So the remaining question is purely positional: where does the player
//  actually end up, and is _zm::in_enabled_playable_area() true there. That is
//  what this prints. The kill path is
//  _zm::player_out_of_playable_area_monitor -> MotD's
//  _zm_afterlife::player_out_of_playable_area, which returns true (i.e. KILL)
//  for anyone not in afterlife.
// ============================================================================
zmqol_prison_spawn_probe()
{
    level endon( "end_game" );

    for ( i = 0; i < 24; i++ )
    {
        wait 0.5;

        foreach ( player in getplayers() )
        {
            s = "[zm_qol] PRISON t=" + ( ( i + 1 ) * 0.5 );
            s += " loc=" + getdvar( "ui_zm_mapstartlocation" );
            s += " org=" + player.origin;
            s += " health=" + player.health;
            s += " inarea=" + player maps\mp\zombies\_zm::in_enabled_playable_area();

            if ( isdefined( player.model ) )
                s += " model=" + player.model;
            else
                s += " model=UNDEF";

            println( s );
        }
    }
}

// ============================================================================
//  zmqol_precache_survival_characters
//
//  🛑 Fixes: DOCKS/CELL BLOCK SURVIVAL - INVISIBLE BODY, VIEW ARMS AND WEAPON,
//     and zombies unable to damage you.
//
//  v1.1.3 changed which characters survival uses and did NOT fix it: the probe
//  still reported a correctly assigned model (model=c_zom_player_handsome_fb,
//  weap=m1911_zm, health=100). The character set was never the problem -
//  PRECACHING was.
//
//  level.precachecustomcharacters is consumed early, in
//  _zm_gametype::rungametypeprecache() during onprecachegametype. Our
//  zstandard_preinit assigns it, but preinit is not guaranteed to have run by
//  then, so on these locations nothing ever precaches the player xmodels.
//  setmodel/setviewmodel on an xmodel that was never precached still sets the
//  .model script field - which is why the probe looked healthy - but renders
//  nothing: no body, no view arms, and no weapon (it hangs off the viewhands
//  tag). A player entity with no model also has no hit geometry, which is why
//  zombie melee could never connect. One cause, all three symptoms.
//
//  Why TranZit's added locations never showed this: TranZit is the ONLY map in
//  the game that ships a so_zsurvival_*.ff (verified with the OAT Unlinker
//  across every map), so its survival characters get precached through stock
//  paths. Alcatraz has only so_zclassic/so_zencounter, and a zstandard game
//  loads neither - just zm_prison_patch + zm_prison.
//
//  init() is a valid precache window (the precacheModel above already relies on
//  that). Precaching is idempotent, so this is harmless if the normal path also
//  runs. Covers Cell Block as well as Docks, since both are zstandard here.
// ============================================================================
zmqol_precache_survival_characters()
{
    if ( is_classic() )
        return;

    maps\mp\zm_prison::precache_personality_characters();
}

delete_perk_machine_clip()
{
	perk_machines = getentarray("zombie_vending", "targetname");

	foreach (perk_machine in perk_machines)
	{
		if (isdefined(perk_machine.clip))
		{
			perk_machine.clip delete();
		}

		if (isdefined(perk_machine.target) && perk_machine.target == "vending_divetonuke" || perk_machine.target == "vending_additionalprimaryweapon")
		{
			spawn_custom_perk_collision(perk_machine);
		}
	}
}

spawn_custom_perk_collision(perk_machine)
{
	collision = spawn("script_model", perk_machine.origin + (0, 0, 64), 1);
	collision.angles = perk_machine.angles;

	collision setmodel("collision_clip_32x32x128");
	collision disconnectpaths();
}

added_weapons()
{
    if (level.script == "zm_prison")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon_prison( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon_prison( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon_prison( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon_prison( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon_prison( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon_prison( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon_prison( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined, 1 );
        
        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon_prison( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "qcw05_zm" );
        include_weapon( "qcw05_upgraded_zm", 0 );
        add_zombie_weapon_prison( "qcw05_zm", "qcw05_upgraded_zm", &"ZOMBIE_WEAPON_QCW05", 50, "wpck_chicom", "", undefined, 1 );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74_extclip_upgraded_zm", 0 );
        add_zombie_weapon_prison( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon_prison( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 900, "wpck_pistol", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "saritch_zm" );
        include_weapon( "saritch_upgraded_zm", 0 );
        add_zombie_weapon_prison( "saritch_zm", "saritch_upgraded_zm", &"ZOMBIE_WEAPON_SARITCH", 50, "wpck_sidr", "", undefined, 1 );

        include_weapon( "m16_zm" );
        include_weapon( "m16_gl_upgraded_zm", 0 );
        add_zombie_weapon_prison( "m16_zm", "m16_gl_upgraded_zm", &"ZOMBIE_WEAPON_M16", 1200, "burstrifle", "", undefined );

        include_weapon( "type95_zm" );
        include_weapon( "type95_upgraded_zm", 0 );
        add_zombie_weapon_prison( "type95_zm", "type95_upgraded_zm", &"ZOMBIE_WEAPON_TYPE95", 50, "wpck_type25", "", undefined, 1 );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon_prison( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "srm1216_zm" );
        include_weapon( "srm1216_upgraded_zm", 0 );
        add_zombie_weapon_prison( "srm1216_zm", "srm1216_upgraded_zm", &"ZOMBIE_WEAPON_SRM1216", 50, "wpck_m1216", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon_prison( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

        include_weapon( "hamr_zm" );
        include_weapon( "hamr_upgraded_zm", 0 );
        add_zombie_weapon_prison( "hamr_zm", "hamr_upgraded_zm", &"ZOMBIE_WEAPON_HAMR", 50, "wpck_hamr", "", undefined, 1 );

        include_weapon( "python_zm" );
        include_weapon( "python_upgraded_zm", 0 );
        add_zombie_weapon_prison( "python_zm", "python_upgraded_zm", &"ZOMBIE_WEAPON_PYTHON", 50, "wpck_python", "", undefined, 1 );

        include_weapon( "kard_zm" );
        include_weapon( "kard_upgraded_zm", 0 );
        add_zombie_weapon_prison( "kard_zm", "kard_upgraded_zm", &"ZOMBIE_WEAPON_KARD", 50, "wpck_kap", "", undefined, 1 );

        include_weapon( "m32_zm" );
        include_weapon( "m32_upgraded_zm", 0 );
        add_zombie_weapon_prison( "m32_zm", "m32_upgraded_zm", &"ZOMBIE_WEAPON_M32", 50, "wpck_m32", "", undefined, 1 );
    }
}

// ============================================================================
//  qol_check_solo_status  (replaces maps\mp\zm_alcatraz_utility::check_solo_status)
//
//  🛑 Same defect as Origins - see the long comment on the twin function in
//  scripts\zm\zm_tomb\zm_tomb.gsc for the full reasoning. Short version: stock
//  requires ( !sessionmodeisonlinegame() || !sessionmodeisprivate() ) on top of
//  the player count, and Plutonium runs every game as an online private match,
//  so level.is_forever_solo_game was stuck at 0 even playing alone.
//
//  On Mob that is what forces the plane parts to be carried ONE AT A TIME:
//  zm_alcatraz_craftables::init sets is_shared = 1 on all five plane pieces
//  (and all five fuel cans) only inside `if ( level.is_forever_solo_game )`.
//  It also costs the solo Brutus behaviour (_zm_ai_brutus, rounds < 9), the
//  solo afterlife timings (_zm_afterlife), and the solo side-quest gate
//  (zm_alcatraz_sq).
//
//  Stock threads this from zm_prison::main(), before craftables init reads the
//  flag unguarded - the replacement keeps that slot and adds no wait, so the
//  ordering is unchanged.
// ============================================================================
//  🛑 v1.62.0 - `== 1` WAS NOT ENOUGH, AND THIS PROJECT ALREADY KNEW WHY.
//
//  quality_of_life.gsc::onallplayersready_instant carries this measured note:
//      "getnumexpectedplayers() never becomes non-zero - which is what happens
//       on solo and custom games launched from the Mods menu, since there is no
//       real party populating it"
//  Nobody connected that to this function. `getnumexpectedplayers() == 1` is
//  FALSE when the engine reports 0, so this set is_forever_solo_game = 0 and Mob
//  kept its co-op rules while playing alone - one plane part at a time.
//
//  Origins escapes it: its call site (zm_tomb.gsc:290) runs later in the load
//  than Mob's (zm_prison.gsc:222), and by then the count has resolved - which is
//  exactly why the Origins log line reads `expected=1` while Mob misbehaves.
//
//  So the test is now `<= 1`. It differs from `== 1` ONLY when the engine says
//  0, which is precisely the broken case, so it cannot regress a game that was
//  already working.
//
//  📝 Trade-off, stated rather than hidden: a genuine 2-player co-op game whose
//  count has not resolved at this point would also read as solo. Both counts are
//  logged below so a single boot shows exactly what the engine reported.
qol_check_solo_status()
{
    n_expected = getnumexpectedplayers();

    if ( n_expected <= 1 )
        level.is_forever_solo_game = 1;
    else
        level.is_forever_solo_game = 0;

    println( "[zm_qol] solo status: expected=" + n_expected + " connected=" + getnumconnectedplayers() + " is_forever_solo_game=" + level.is_forever_solo_game );
}


// ============================================================================
//  DEATH MACHINE vs THE AFTERLIFE  (v1.99.62)
// ----------------------------------------------------------------------------
//  Reported by a player: "in mob of the dead if i get the death machine and then
//  die with it i keep it for infinity".
//
//  WHY - measured in the stock scripts, not inferred:
//
//  Going down in Mob is NOT last stand. maps\mp\zombies\_zm_afterlife.gsc:347-355,
//  inside afterlife_player_damage_callback(), intercepts the lethal hit, sets
//  self.afterlife = 1 and threads afterlife_laststand(). No "death" notify fires
//  and player_is_in_laststand() stays false.
//
//  afterlife_laststand() (:491) then calls [[ level.afterlife_save_loadout ]]()
//  as its third statement, and afterlife_save_loadout() (:1182) snapshots
//  getweaponslistprimaries() wholesale into self.loadout.weapons. The Death
//  Machine is in the player's hands at that moment, so it goes into the
//  snapshot. On revive, afterlife_laststand_cleanup() -> afterlife_give_loadout()
//  (:1251) re-gives every weapon in that snapshot - and re-gives it PERMANENTLY,
//  with no timer, because by then the mod's own end_deathmachine threads have
//  long since fired and cleared their state. Hence "for infinity".
//
//  🛑 It is specific to Mob. On every other map a down is real last stand: the
//  laststand pistol swap changes the current weapon, end_deathmachine_on_weapon_switch()
//  sees that and ends the power-up on the spot, and nothing snapshots a weapon
//  list. Nothing here is needed - or wanted - anywhere else, which is why it
//  lives in the map script.
//
//  WHAT THIS DOES: chains level.afterlife_save_loadout and blanks the Death
//  Machine out of the snapshot AFTER stock has taken it.
//
//  🌟 The blanking token is stock's own. afterlife_give_loadout() skips any entry
//  equal to "none" (:1268), right beside the isdefined() skip at :1266. So the
//  entry is set to "none" rather than removed - no array is re-indexed, no
//  ammo/alt-weapon parallel array falls out of step, and every other reader of
//  self.loadout.weapons in the map (zm_alcatraz_utility.gsc:1247/1255 and
//  _zm_afterlife.gsc:800) only ever string-compares it, so "none" is inert there.
//
//  The scrub runs AFTER the snapshot, deliberately. Taking the gun off the player
//  BEFORE it would also work only if takeweapon() updates getweaponslistprimaries()
//  in the same frame, and that is an engine timing assumption this project has no
//  measurement for. Editing the array afterwards is pure script data and cannot
//  race anything.
//
//  The power-up still ENDS the way it always did - end_deathmachine_on_weapon_switch()
//  fires when the afterlife hands the player lightning hands. This changes only
//  what comes back afterwards.
// ============================================================================
zmqol_install_afterlife_loadout_hook()
{
    level endon( "end_game" );

    //  _zm_afterlife::init() (:74) is the ONLY place in the map that assigns this
    //  pointer - zm_prison_ffotd.gsc:46 re-points give_loadout, never save_loadout
    //  - so once it is defined it is safe to chain. Wait up to 3s for it.
    n_tries = 0;
    while ( !isDefined( level.afterlife_save_loadout ) && n_tries < 60 )
    {
        wait 0.05;
        n_tries++;
    }

    if ( !isDefined( level.afterlife_save_loadout ) )
    {
        println( "[zm_qol] afterlife loadout hook NOT installed - level.afterlife_save_loadout never appeared" );
        return;
    }

    if ( isDefined( level.zmqol_orig_afterlife_save_loadout ) )
        return;   //  already installed

    level.zmqol_orig_afterlife_save_loadout = level.afterlife_save_loadout;
    level.afterlife_save_loadout = ::zmqol_afterlife_save_loadout;
    println( "[zm_qol] afterlife loadout hook installed (death machine scrub)" );
}

zmqol_afterlife_save_loadout()
{
    //  self = the player entering the afterlife.
    if ( isDefined( level.zmqol_orig_afterlife_save_loadout ) )
        self [[ level.zmqol_orig_afterlife_save_loadout ]]();
    else
        self maps\mp\zombies\_zm_afterlife::afterlife_save_loadout();

    self zmqol_scrub_deathmachine_from_loadout();
}

zmqol_scrub_deathmachine_from_loadout()
{
    if ( !isDefined( self.loadout ) || !isDefined( self.loadout.weapons ) )
        return;

    //  Only the power-up gun. minigun_alcatraz_zm is a real box weapon this mod
    //  adds elsewhere and must be kept.
    weapon = "deathmachine_zm";
    if ( isDefined( level.deathmachine_weapon ) )
        weapon = level.deathmachine_weapon;

    n_found = 0;
    n_kept = 0;
    for ( i = 0; i < self.loadout.weapons.size; i++ )
    {
        if ( !isDefined( self.loadout.weapons[i] ) )
            continue;

        if ( self.loadout.weapons[i] == weapon )
        {
            self.loadout.weapons[i] = "none";
            n_found++;
            continue;
        }

        if ( self.loadout.weapons[i] != "none" )
            n_kept++;
    }

    if ( n_found == 0 )
        return;

    //  🛑 Safety valve. If the Death Machine were somehow the player's only
    //  weapon, blanking it would leave give_loadout() calling setspawnweapon on
    //  an empty entry. Put it back and take the old behaviour rather than risk
    //  reviving someone weaponless - it cannot happen in normal play (Mob starts
    //  everyone on m1911_zm and zombies cannot drop weapons), so this is a guard,
    //  not a path.
    if ( n_kept == 0 )
    {
        for ( i = 0; i < self.loadout.weapons.size; i++ )
        {
            if ( isDefined( self.loadout.weapons[i] ) && self.loadout.weapons[i] == "none" )
                self.loadout.weapons[i] = weapon;
        }
        println( "[zm_qol] death machine scrub SKIPPED - it was the only saved weapon" );
        return;
    }

    //  current_weapon points at whatever the player was holding, which is the
    //  entry just blanked. Repoint it at the first real weapon so
    //  afterlife_give_loadout()'s setspawnweapon/switchtoweaponimmediate (:1297)
    //  get a valid name.
    if ( isDefined( self.loadout.current_weapon ) &&
         isDefined( self.loadout.weapons[self.loadout.current_weapon] ) &&
         self.loadout.weapons[self.loadout.current_weapon] == "none" )
    {
        for ( i = 0; i < self.loadout.weapons.size; i++ )
        {
            if ( isDefined( self.loadout.weapons[i] ) && self.loadout.weapons[i] != "none" )
            {
                self.loadout.current_weapon = i;
                break;
            }
        }
    }

    println( "[zm_qol] death machine scrubbed from afterlife loadout (" + n_found + " entry, " + n_kept + " kept)" );
}
