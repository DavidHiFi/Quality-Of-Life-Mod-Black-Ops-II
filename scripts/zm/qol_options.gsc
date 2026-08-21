// ============================================================================
//  qol_options  -  console-configurable options, adapted from BO2-Remix
// ============================================================================
//  Adds the dvars the user asked for from H:\Claude\BO2-Remix and NOTHING else
//  from that mod. Explicitly NOT ported: the walker removal, the power-up
//  rework, the bank/perma-perk/fridge/box patches, the round-255 and points
//  changes, the strat tester. Those are gameplay changes; this file is options.
//
//  Every GAMEPLAY option here is OFF by default, so a fresh install plays
//  exactly as it did before any of this existed. The HUD readouts are the
//  exception and always were: hud_timer, hud_health_bar and hud_remaining ship
//  on, and hud_round_timer joined them in v1.84.0 at the user's request.
//
//  🛑 THREE THINGS WERE VERIFIED AGAINST THE SHIPPED GAME BEFORE BEING WRITTEN,
//  because each is the class of bug that has already cost this project a
//  release apiece - a name that reads fine and resolves to nothing:
//
//    1. strTok, string_to_float, getdvarintdefault are all real T6 builtins
//       (113 / 4 / 120 uses in the stock dump). array_slice, which an earlier
//       draft of the .help fix used, is NOT - it has zero uses and would have
//       failed at runtime.
//    2. The character models Remix hardcodes DO NOT EXIST on every map.
//       Unlinker --list across Farm's loaded zones finds only
//       c_zom_player_cdc_fb and c_zom_player_cia_fb - survival uses the CDC/CIA
//       teams, not the TranZit crew - so Remix's setmodel( "c_zom_player_
//       oldman_fb" ) would give an INVISIBLE PLAYER there. See qol_opt_character.
//    3. A client's HUD-element allowance is finite and this mod already spends
//       ~13 of it. That is what silently truncated the .help panel. So the two
//       NEW hud elements here are created only when their dvar is on, and never
//       on a player who has not asked for them.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;

init()
{
    //  ========================================================================
    //  🛑 v1.95.5 - THE BISECT SWITCH WAS UNUSABLE AND THAT IS WHY IT HAS NEVER
    //  PRODUCED AN ANSWER.
    //
    //  zmqol_minimal shipped in v1.95.1 as a plain getdvarintdefault() read with
    //  no registration anywhere. An UNREGISTERED dvar does not exist until
    //  something creates it, so typing `zmqol_minimal 1` at the console is not a
    //  dvar assignment - it is an unknown command, and it silently does nothing.
    //
    //  🌟 MEASURED, not assumed: the 2026-08-14 Origins crash log's dvar dump
    //  lists `zmqol_loadmovie_probe` and every other zmqol_* the mod creates, and
    //  contains NO `zmqol_minimal` line at all. The user set it and it never
    //  existed. Two boots were spent on a switch that could not be thrown.
    //
    //  Registering it here fixes that: it is created at 0 on the first load, and
    //  qol_opt_dvar only writes when the value is empty, so a console `1` set
    //  afterwards survives into the next map. The print below then puts the
    //  answer in the log, so "was it actually on?" is never a guess again.
    //  ========================================================================
    qol_opt_dvar( "zmqol_minimal",         "0" );
    println( "[zm_qol] minimal mode: " + zmqol_minimal() + "  (1 = all 18 periodic threads disabled)" );

    //  Registered up front so they all show up in the console's autocomplete
    //  even before anything reads them.
    qol_opt_dvar( "rapid_fire",            "0" );
    qol_opt_dvar( "night_mode",            "0" );
    qol_opt_dvar( "character",             "0" );
    //  v1.99.68 - which eye effect Vulture Aid puts on zombies. See the long
    //  note over zm_expanded.csc::zmqol_vulture_brighter_eyes(). Registered here
    //  so it shows in console autocomplete; the CLIENT reads it, and both halves
    //  run in one process on this platform.
    qol_opt_dvar( "disable_player_quotes", "1" );
    qol_opt_dvar( "coop_pause",            "0" );
    //  v1.99.91 - the ADVANCED tab's FOG row and the .fog command both write
    //  this; quality_of_life::zmqol_fog_dvar_watch() carries it to r_fog. It
    //  exists because r_fog is cheat-protected and therefore never archived,
    //  which is why FOG was the one menu row that did not survive a restart.
    qol_opt_dvar( "fog_enabled",           "1" );

    //  v1.85.0 - THE MASTER SWITCH, driven by ".hud on" / ".hud off".
    //  hud_all forces the individual hud_* options ON; hud_master overrides the
    //  lot in the other direction, including the game's OWN LUI hud (points,
    //  ammo, round, perk icons) which no hud_* dvar has ever reached. 1 = normal.
    qol_opt_dvar( "hud_master",       "1" );
    qol_opt_dvar( "hud_all",          "0" );
    qol_opt_dvar( "hud_timer",        "1" );
    //  v1.84.0 - ON by default. The user asked for the round timer to be shown
    //  under the game counter, not left behind a switch they have to find.
    qol_opt_dvar( "hud_round_timer",  "1" );
    qol_opt_dvar( "hud_health_bar",   "1" );
    //  v1.99.1 - the red "Bleeding out in: N" bar shown while you are downed
    //  (scripts\zm\bleedout_bar.gsc, imported from Nathan3197's mod). User asked
    //  for a switch, 2026-08-16. ON by default - it is existing behaviour, and a
    //  new toggle must not silently change what the mod already does.
    //  Read in ONE place, inside bleedout_bar()'s loop.
    //  v1.99.6 - that read moved INTO the loop, so the row is live: flip it
    //  while you are already downed and the bar appears or disappears at once.
    //  v1.99.1 read it once at creation and the user reported exactly that gap.
    qol_opt_dvar( "hud_bleedout_bar", "1" );
    qol_opt_dvar( "hud_remaining",    "1" );
    qol_opt_dvar( "hud_zone",         "0" );
    //  v1.99.26 - compass, user request 2026-08-17 from the TechnoOps mod. OFF by
    //  default: it is a NEW element, and a new toggle must not change what the
    //  mod already draws for someone who never asked for it.
    qol_opt_dvar( "hud_compass",      "0" );
    //  v1.98.0 - the icon + name + description pop-up shown when you buy a perk
    //  (the Vanguard Perk Animation module in quality_of_life.gsc). User asked
    //  for a switch, 2026-08-16. ON by default - it is existing behaviour, and a
    //  new toggle must not silently change what the mod already does.
    //  Read in ONE place, at the top of perk_bought(), so the toggle takes
    //  effect on the very next perk with no respawn.
    qol_opt_dvar( "hud_perk_popup",   "1" );
    //  v1.99.0 - seconds remaining under each power-up icon. ON by default:
    //  the user asked for the feature, not merely for a switch.
    //  🛑 The dvar is read SERVER-side, in zmqol_powerup_timer_think(), so
    //  switching it off stops the reliable-command traffic entirely rather than
    //  just hiding the text. See the long note there.
    qol_opt_dvar( "hud_powerup_timers", "1" );
    qol_opt_dvar( "hud_color",        "1 1 1" );
    qol_opt_dvar( "hud_color_health", "1 1 1" );
    //  v1.90.6 - the two stacked timers get their own colours, kept out of the
    //  shared hud_color tint list.
    //
    //  v1.95.3 - both are now the SAME dull navy blue, user 2026-08-14 (was
    //  yellow / light blue). Two dvars are kept rather than one so either row can
    //  still be re-coloured on its own from the console.
    //
    //  🛑 They had to come OUT of the shared hud_color tint list to do this.
    //  qol_opt_hud_watcher() repaints from one dvar on change, so a colour set
    //  at creation was guaranteed to be flattened back to white on the very
    //  first pass - the same single-owner rule as the health bar above.
    //  hud_color still owns zombietext and the zone name.
    //
    //  🛑 The watcher's str_prev_color_timer / _round seeds MUST match these two
    //  strings exactly, or the first pass sees a change and repaints on spawn.
    qol_opt_dvar( "hud_color_timer",       "0.3 0.45 0.9" );
    qol_opt_dvar( "hud_color_round_timer", "0.3 0.45 0.9" );

    //  Read by quality_of_life::get_pack_a_punch_weapon_options(). Default 1
    //  keeps the animated camo exactly where this mod already had it.
    //
    //  v1.99.83, queue item 11 - anim_pap_camo is the MASTER row on the GAME
    //  tab. The three per-map dvars below stay, unchanged and still readable
    //  from the console, because they are already archived in players' configs
    //  and removing them would silently reset anyone who had set one. The
    //  master is ANDed with them: OFF means camo 39 (stock) on all three maps
    //  whatever the per-map dvars say, ON leaves the per-map behaviour exactly
    //  as it has always been.
    qol_opt_dvar( "anim_pap_camo",         "1" );
    qol_opt_dvar( "anim_pap_camo_mob",     "1" );
    qol_opt_dvar( "anim_pap_camo_buried",  "1" );
    qol_opt_dvar( "anim_pap_camo_origins", "1" );

    //  v1.95.0 - three new rows for the QUALITY OF LIFE menu, user 2026-08-14.
    //  All default ON, so the mod behaves exactly as before unless switched off.
    //  Read in quality_of_life.gsc by updatedamagefeedback(), the custom-summary
    //  popup and zmqol_credits_banner_print() respectively. Registered here with
    //  the rest so they appear in console autocomplete and so the menu row reads
    //  a real value instead of an empty string on the first open.
    qol_opt_dvar( "hitmarkers",    "1" );

    //  v1.99.31 - the SOUND tab's four feedback packs, user request 2026-08-17.
    //  All default "0", which for hit/kill means the alert this mod has always
    //  played and for downed/crit means silence - so nothing changes for anyone
    //  who does not go looking. The numbering and the alias tables live in
    //  quality_of_life.gsc's zmqol_init_feedback_sounds(); registered here with
    //  the rest so the console autocompletes them and the menu row reads a real
    //  value the first time it is opened instead of an empty string.
    qol_opt_dvar( "hit_sound",     "0" );
    qol_opt_dvar( "kill_sound",    "0" );
    qol_opt_dvar( "downed_sound",  "0" );
    qol_opt_dvar( "crit_sound",    "0" );
    qol_opt_dvar( "round_summary", "1" );
    qol_opt_dvar( "intro_credits", "1" );

    //  v1.99.61 - PERK BONUS POINTS, user request 2026-08-18. ON by default:
    //  the +100 for proning at a perk machine is behaviour this mod has always
    //  had, so the switch must change nothing until it is thrown. OFF means NO
    //  prone points at all - the mod's own detector stops paying AND Origins'
    //  native 25-point "loose change" easter egg is suppressed, which is the
    //  two-state behaviour the user asked for ("either the effect is on with 100
    //  points prone per machine, or not points at all from proning"). Read live
    //  in quality_of_life.gsc's prone_bonus_monitor() and in zm_tomb.gsc's
    //  origins_change_patch(), so it takes effect mid-match both ways.
    qol_opt_dvar( "perk_bonus_points", "1" );

    //  v1.99.61 - FLASH HELP, user request 2026-08-18. The HUD tab's second
    //  match-start flash line: it tells players how to open chat and reach
    //  .help. ON by default - the user asked for the feature, not merely for a
    //  switch. Printed by zmqol_credits_banner_print() in quality_of_life.gsc,
    //  gated separately from intro_credits so either can be silenced alone.
    qol_opt_dvar( "flash_help", "1" );

    qol_opt_dvar( "no_power", "0" );

    //  v1.99.48 - INSTANT NUKE, user request 2026-08-18. Read once per nuke in
    //  quality_of_life.gsc's zmqol_nuke_powerup(), which is stock's own
    //  nuke_powerup() with the per-zombie stagger wait gated on this and nothing
    //  else changed. ON by default: the user asked for the feature, not merely
    //  for a switch (the same call as the power-up timers in v1.99.0). "0" is
    //  exact vanilla, down to the same random 0.1-0.7s wait stock takes.
    qol_opt_dvar( "instant_nuke", "1" );

    //  v1.99.73 - BETTER DEADSHOT, user request 2026-08-19. OFF by default: a
    //  doubled headshot is new behaviour and a new switch must not change what
    //  the mod already does until it is thrown. Registered here so the console
    //  autocompletes it; quality_of_life.gsc::zmqol_better_deadshot_scale()
    //  reads it on every bullet, so it is live both ways mid-game.
    qol_opt_dvar( "better_deadshot", "0" );

    // ------------------------------------------------------------------------
    //  v1.99.91 - NO BOX LIMITS (was BOX LIMITS, v1.99.83, queue item 30).
    //
    //  ON (1) by default: the unlocked box - duplicates, both Ray Guns, no
    //  per-map wonder-weapon cap - which is what this mod has always shipped.
    //  OFF puts stock's three checks back, in stock's own order, inside
    //  maps\mp\zombies\_zm_magicbox::treasure_chest_canplayerreceiveweapon().
    //  Read per candidate weapon inside the spin loop, so the row is live: flip
    //  it and the very next spin obeys it.
    //
    //  🛑 THE MIGRATION IS THE POINT OF THESE FOUR LINES. The meaning is
    //  inverted from the old row, so carrying the old dvar name across would
    //  have flipped the setting of anyone who had already saved one. Their
    //  archived box_limits is read ONCE, inverted into the new name, and never
    //  read again. A player who never saw the old row gets the default.
    // ------------------------------------------------------------------------
    if ( getdvar( "no_box_limits" ) == "" && getdvar( "box_limits" ) != "" )
        setdvar( "no_box_limits", "" + ( !getdvarintdefault( "box_limits", 0 ) ) );

    qol_opt_dvar( "no_box_limits", "1" );

    //  v1.99.83 - CUSTOM POWER-UPS, queue item 25. ON (1) by default: Zombie
    //  Blood, Blood Money and the Death Machine are drops this mod already ships
    //  on every map, so the switch changes nothing until it is thrown. OFF puts
    //  the drop table back to stock. It gates ONLY the drop-table registration -
    //  never a clientfield, visionset or precache - so the per-map bit budget is
    //  identical either way and the row cannot break a map load. Read once at
    //  map load, so it takes effect on the next map. See
    //  quality_of_life::zmqol_custom_powerups_enabled().
    qol_opt_dvar( "custom_powerups", "1" );

    //  v1.99.74 - AIM ASSIST, its own row on CONTROLS > GAMEPAD. Default 1 =
    //  stock. 🛑 It can only take assist AWAY - see the banner over
    //  quality_of_life.gsc::zmqol_aim_assist_watch() for the measurement behind
    //  that, and do not widen the label without re-reading it.
    qol_opt_dvar( "aim_assist", "1" );

    //  Model pop-in. On by default - it is a pure image-quality win with no
    //  gameplay effect. See qol_opt_lod_fix() for what it actually writes.
    qol_opt_dvar( "lod_fix", "1" );

    //  v1.99.51 - BACKSPEED PATCH, user request (queue item 2). ON by default,
    //  because forcing these three to 1 is what this mod has always done - the
    //  switch must not change anyone's game until it is thrown. See
    //  qol_opt_move_speed() for the values and where they came from.
    qol_opt_dvar( "move_speed", "1" );

    //  v2.0.6 - NETWORK FRAME PATCH, user request. OFF by default: with it off
    //  quality_of_life::zmqol_wait_network_frame() is byte-exact stock, so the
    //  row changes nothing until it is thrown. See the header above that
    //  function for the console figures and why B2OP disables its own copy on
    //  modern Plutonium.
    qol_opt_dvar( "network_frame_patch", "0" );

    //  v2.0.7 - GRAPHICS BOOST, user request (REZ's "Vanilla+" config). OFF by
    //  default: REZ's own documentation targets modern dedicated GPUs with
    //  1.5-2 GB of VRAM headroom, so it must not be forced on everyone who
    //  updates. See qol_opt_graphics_boost() for what was taken, what was
    //  dropped, and the four dvars in that config that do not exist.
    qol_opt_dvar( "graphics_boost", "0" );

    //  v2.0.8 - ROUND COUNTER LEFT (HUD tab). 0 = top right, the Cold War
    //  placement the mod has always shipped, so nobody's HUD moves on update.
    qol_opt_dvar( "hud_round_left", "0" );

    level thread qol_opt_graphics_boost();
    level thread qol_opt_coop_pause();
    level thread qol_opt_round_clock();
    level thread qol_opt_no_power();
    level thread qol_opt_lod_fix();
    level thread qol_opt_move_speed();
    level thread qol_opt_roundcounter_master();
    level thread qol_opt_connect_loop();

    //  ------------------------------------------------------------------
    //  TARGET ASSIST - v1.99.34, user request 2026-08-17. The lobby's TARGET
    //  ASSIST row is gone (see the long note in ui_mp\t6\menus\
    //  privategamelobby_project.lua), so CONTROLS > GAMEPAD > TARGET ASSIST is
    //  the only switch a player touches. That row writes the PROFILE var
    //  input_targetAssist; THIS dvar is the separate server-side PERMISSION,
    //  and Plutonium's optionscontrols.lua LOCKS the row in game whenever it is
    //  0. Granting it here keeps the one remaining switch always usable.
    //
    //  🛑 setdvar, not qol_opt_dvar. qol_opt_dvar only writes an EMPTY dvar and
    //  this one always has a value - the engine registers it - so the
    //  conditional form would never do anything at all.
    //
    //  📝 The default is already 1 (Plutonium's own DvarDefaults table, and the
    //  lobby row drew no ⭐ beside ENABLED in the user's screenshot), so on a
    //  normal solo or private match this changes nothing. It is written anyway
    //  so the feature does not rest on a default this project does not own. On
    //  a dedicated server that deliberately forbids aim assist this does
    //  re-permit it - zm_qol is a Mods-menu solo/private mod, and that trade is
    //  recorded here rather than left to be discovered.
    //
    //  🛑 LAST in init() on purpose, after every thread above is already
    //  running. A protected dvar prints "Cannot set cheat dvar X" rather than
    //  crashing (console_zm.log does exactly that for r_fog), but if this one
    //  ever did fail hard, being last means it can only cost itself - not the
    //  coop pause, the round clock, no_power, lod_fix or the connect loop.
    setdvar( "sv_allowAimAssist", 1 );
}

// ============================================================================
//  qol_opt_roundcounter_master  -  ".hud off" reaches the round chalk too
//
//  v1.87.1. The BOCW round counter (quality_of_life.gsc::round_hud()) was the
//  one HUD element ".hud off" did not hide - it is still visible as the chalk
//  mark in the top right of the user's screenshot.
//
//  🛑 IT CANNOT BE DRIVEN FROM qol_opt_hud_watcher(). Two reasons:
//    1. It is a SERVER hudelem (createservericon / createserverfontstring),
//       one shared element rather than one per player, so a per-player watcher
//       would have every player writing the same element.
//    2. It is ANIMATION-driven, not tick-driven - round_hud() runs
//       fadeovertime / scaleovertime / moveovertime sequences at each round
//       change. Writing its alpha on a timer would fight those animations.
//
//  So this only ever writes while the HUD is switched OFF, plus exactly once on
//  the off->on edge to put it back. While the HUD is on it never touches the
//  element, and the round animation is left completely alone.
// ============================================================================
qol_opt_roundcounter_master()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = 1;

    for ( ;; )
    {
        wait 0.25;

        n_on = getdvarintdefault( "hud_master", 1 );

        if ( !isdefined( level.zmqol_roundcounter ) )
        {
            n_prev = n_on;
            continue;
        }

        if ( !n_on )
        {
            //  Re-asserted every pass, not once: round_hud() sets alpha back to
            //  1 at every round transition, so a single write would be undone
            //  by the next round.
            level.zmqol_roundcounter.alpha = 0;
        }
        else if ( !n_prev )
        {
            level.zmqol_roundcounter.alpha = 1;
        }

        n_prev = n_on;
    }
}

// ============================================================================
//  qol_opt_lod_fix  -  stop models popping in at distance
//
//  What the user sees as "texture pop-in" on BO2 is LOD swapping: the renderer
//  drops rigid (world/prop) and skinned (character) models to lower detail
//  levels past a distance threshold. Treyarch tuned that for 2012 consoles, and
//  the fog exists partly to hide it.
//
//  📝 THE FOUR DVARS ARE REAL AND VERIFIED, not taken on trust from the forum
//  post they came from. All four appear in this install's own dvar dump
//  (console_zm.log) with these stock defaults:
//        r_lodBiasRigid    "0"
//        r_lodBiasSkinned  "0"
//        r_lodScaleRigid   "1"
//        r_lodScaleSkinned "1"
//  and Treyarch's own descriptions (BO2 Detailed DVARS.txt) give the direction:
//        r_lodBias*   "Bias the level of detail distance ... negative INCREASES detail"
//        r_lodScale*  "Scale the level of detail distance ... larger REDUCES detail"
//
//  🛑 SO ONLY TWO OF THE FOUR ACTUALLY DO ANYTHING HERE. r_lodScaleRigid and
//  r_lodScaleSkinned already sit at 1, which is the neutral value the advice
//  asks for - writing 1 over 1 is a no-op on a stock config. They are still
//  written, deliberately: this mod ships to other people, and a config that has
//  raised either of them (larger = less detail) would otherwise keep popping
//  models regardless of the bias. Writing them makes the result independent of
//  whatever is in the user's config, which is the whole point.
//
//  🛑 THESE ARE CLIENT RENDERER DVARS. Setting them from GSC works because this
//  mod runs through Plutonium's Mods menu, where the host IS the client - one
//  process. They are NOT networked, so on a dedicated server this would change
//  nothing for remote players. That is a limitation of the approach, not a bug.
//
//  Written only when the setting CHANGES, not on a timer - same discipline as
//  the hud_color watcher above, which exists because writing dvars every tick
//  is a lot of work for a value that changes when someone types at the console.
// ============================================================================
qol_opt_lod_fix()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = -1;

    for ( ;; )
    {
        n_on = getdvarintdefault( "lod_fix", 1 );

        if ( n_on != n_prev )
        {
            n_prev = n_on;

            if ( n_on )
            {
                setdvar( "r_lodBiasRigid",   "-1000" );
                setdvar( "r_lodBiasSkinned", "-1000" );
            }
            else
            {
                //  Back to the stock values read out of this install's dvar
                //  dump, so switching the option off is a real restore rather
                //  than a guess at what BO2 shipped with.
                setdvar( "r_lodBiasRigid",   "0" );
                setdvar( "r_lodBiasSkinned", "0" );
            }

            //  Neutral either way - see the note above on why these are written
            //  at all rather than assumed.
            setdvar( "r_lodScaleRigid",   "1" );
            setdvar( "r_lodScaleSkinned", "1" );
        }

        wait 1;
    }
}

// ============================================================================
//  qol_opt_move_speed  -  full speed backwards and sideways        (v1.99.51)
//
//  BO2 slows you down whenever you are not running forwards. The mod has
//  always cancelled that by forcing three scales to 1, on this line inside
//  quality_of_life::init()'s high_round_fix block:
//
//      setdvar( "player_backSpeedScale", 1 );
//      setdvar( "player_strafeSpeedScale", 1 );
//      setdvar( "player_sprintStrafeSpeedScale", 1 );
//
//  Those three lines are GONE from there now; this is the only writer, so the
//  GAME > BACKSPEED PATCH row can put the game back to stock live and have it
//  stay that way across a map change.
//
//  📝 THE OFF VALUES ARE MEASURED, NOT GUESSED. They are this install's own
//  boot-time dvar dump (console_zm.log), read before the mod's init runs:
//        player_backSpeedScale        "0.7"
//        player_strafeSpeedScale      "0.8"
//        player_sprintStrafeSpeedScale "0.667"
//  The same file's later dumps show all three at "1" once the mod has loaded,
//  which is also the proof that a plain setdvar reaches them at all - they are
//  not write-protected here. (T6-B2OP-PATCH independently registers
//  player_backSpeedScale with a "0.7" default, which agrees.)
//
//  🛑 These are movement dvars read by the client's own prediction, and this
//  mod runs through Plutonium's Mods menu where the host IS the client, one
//  process - the same standing limitation qol_opt_lod_fix() carries. On a
//  dedicated server this would not reach a remote player.
//
//  Written only when the setting CHANGES, same discipline as the lod watcher
//  above, so flipping the row costs three setdvars and nothing per tick.
// ============================================================================
qol_opt_move_speed()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = -1;

    for ( ;; )
    {
        n_on = getdvarintdefault( "move_speed", 1 );

        if ( n_on != n_prev )
        {
            n_prev = n_on;

            if ( n_on )
            {
                setdvar( "player_backSpeedScale",         "1" );
                setdvar( "player_strafeSpeedScale",       "1" );
                setdvar( "player_sprintStrafeSpeedScale", "1" );
            }
            else
            {
                setdvar( "player_backSpeedScale",         "0.7" );
                setdvar( "player_strafeSpeedScale",       "0.8" );
                setdvar( "player_sprintStrafeSpeedScale", "0.667" );
            }
        }

        wait 1;
    }
}


// ============================================================================
//  qol_opt_graphics_boost  -  GRAPHICS BOOST                        (v2.0.7)
//
//  User, 2026-08-21, pointing at "T6-BO2 Vanilla+ by REZ": *"what I mainly want
//  you to include is the cfg optimizations ... so the game has the best
//  graphical fidelity possible, best anti-aliasing that you can achieve better
//  than using the games' txaa x4 and fxaa with the best sharpness or whatever,
//  and best optimization for performance in general."*
//
//  🛑 REZ's plutonium_zm.cfg WAS NOT APPLIED WHOLESALE, AND IT MUST NOT BE. It
//  is a complete 230-line config, not a list of optimisations: it also carries
//  cg_fov 110, the aim_turnrate_* curve, every HUD element size,
//  snd_speakerConfiguration "5.1 No Center 3D", and the display block
//  ( r_mode "1920x1080", r_fullscreen, r_monitor, r_aspectRatio, r_customMode,
//  r_resolution ). Shipping those would silently overwrite the player's own
//  resolution, monitor, audio layout and field of view. Only the rendering
//  dvars were taken, and every one below is verified to EXIST in t6zm.exe's
//  string table before being written.
//
//  🛑 FOUR OF REZ's DVARS DO NOT EXIST IN THIS GAME. Checked against both
//  t6zm.exe's string table and Plutonium's dvar_descriptions.json, neither of
//  which contains:
//        r_aaalpha            <- REZ's claimed "Alpha-to-Coverage (A2C)"
//        com_busyWait         <- part of the "smoothness" claim
//        r_fog_settings
//        r_skinnedCacheScale
//  setdvar on any of them creates a user dvar nothing reads - a dead switch -
//  so all four are dropped. The A2C anti-aliasing feature in particular does
//  not exist on T6 at all.
//
//  🛑 cl_maxppf IS NOT A PERFORMANCE DVAR. Plutonium's own description reads
//  "Maximum servers to ping per frame in server browser". Dropped.
//
//  🛑 r_bloomTweaks IS DELIBERATELY NOT SET. Its description is "enbale bloom
//  tweaks" [sic] and it is the same family as r_filmUseTweaks, whose
//  description is "Overide film effects with tweak dvar values" - the dvar this
//  project has already documented as making the renderer ignore every
//  visionset. Overriding bloom from tweak dvars would fight every map's own
//  grade and this mod's visionsets. Not worth the risk for a bloom nudge.
//
//  🛑 r_lodBiasRigid / r_lodBiasSkinned ARE NOT TOUCHED HERE. The LOD FIX row
//  above already owns them and already writes -1000, which holds full model
//  detail at every distance - strictly better than REZ's 0. Two writers on one
//  dvar is how a setting starts flickering between two owners. The other four
//  LOD dvars are unowned and are set here.
//
//  🌟 THE ANTI-ALIASING FIGURE IS READ OUT OF THE GAME'S OWN MENU, NOT GUESSED.
//  ui\t6\menus\optionssettings.lua's AntiAliasingChangeCallback accepts
//  `AntiAliasingChosen.value <= 16` straight into r_aaSamples, and its choices
//  17 and 18 are the TXAA pair ( r_aaSamples 2 or 4 with r_txaa 1 ). So 16 is a
//  real MSAA level, and it is above anything the TXAA rows can reach - which is
//  exactly what the user asked for. r_txaa and r_fxaa go to 0 with it, the same
//  pairing that callback does.
//
//  🛑 TWO OF THESE ARE LATCHED AND CANNOT APPLY MID-GAME. The console log for
//  this install prints "r_aaSamples will be changed upon restarting." and
//  "r_texFilterQuality will be changed upon restarting.", and the game's own
//  menu flags exactly those two with NeedVidRestart. They are still written -
//  they simply take effect the next time the game starts. Everything else in
//  the list applies immediately. This is the engine's behaviour, not a
//  shortcut: the stock menu shows an Apply prompt for the same two.
//
//  🛑 OFF IS A REAL RESTORE, NOT A GUESS. Every value is read ONCE before
//  anything is written and put back verbatim when the row is switched off -
//  the same discipline qol_opt_move_speed() uses. Nothing here invents a
//  "default".
//
//  📝 OFF BY DEFAULT. REZ's own documentation targets "Modern Dedicated
//  Graphics (AMD RX / NVIDIA RTX)" with "~1.5 GB - 2 GB Peak" VRAM overhead and
//  a 144Hz+ monitor. Forcing 16x MSAA, 16x anisotropic and full shadow maps on
//  every player who updates the mod would make the game slower for anyone below
//  that, so the row ships off and changes nothing until it is thrown.
// ============================================================================
qol_opt_graphics_boost()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    //  Cached before the first write, so OFF restores this install's real
    //  values rather than a number this file invented.
    a_keys = [];
    a_keys[ a_keys.size ] = "r_aaSamples";
    a_keys[ a_keys.size ] = "r_txaa";
    a_keys[ a_keys.size ] = "r_fxaa";
    a_keys[ a_keys.size ] = "r_texFilterQuality";
    a_keys[ a_keys.size ] = "r_texFilterAnisoMin";
    a_keys[ a_keys.size ] = "r_texFilterAnisoMax";
    a_keys[ a_keys.size ] = "r_texFilterMipMode";
    a_keys[ a_keys.size ] = "r_picmip_manual";
    a_keys[ a_keys.size ] = "r_picmip";
    a_keys[ a_keys.size ] = "r_picmip_bump";
    a_keys[ a_keys.size ] = "r_picmip_spec";
    a_keys[ a_keys.size ] = "r_ssao";
    a_keys[ a_keys.size ] = "sm_enable";
    a_keys[ a_keys.size ] = "sm_maxLights";
    a_keys[ a_keys.size ] = "sm_spotQuality";
    a_keys[ a_keys.size ] = "sm_sunQuality";
    a_keys[ a_keys.size ] = "r_bloomHiQuality";
    a_keys[ a_keys.size ] = "r_autoLodScale";
    a_keys[ a_keys.size ] = "r_lodScaleRigid";
    a_keys[ a_keys.size ] = "r_lodScaleSkinned";
    a_keys[ a_keys.size ] = "com_maxfps";

    a_on = [];
    a_on[ "r_aaSamples" ]          = "16";   // latched - next launch
    a_on[ "r_txaa" ]               = "0";
    a_on[ "r_fxaa" ]               = "0";
    a_on[ "r_texFilterQuality" ]   = "0";    // latched - next launch
    a_on[ "r_texFilterAnisoMin" ]  = "16";
    a_on[ "r_texFilterAnisoMax" ]  = "16";
    a_on[ "r_texFilterMipMode" ]   = "Force Trilinear";
    //  🛑 REZ set r_picmip_manual 0, which is "picmip is set automatically" -
    //  so their four r_picmip 0 lines did nothing at all. 1 is what makes them
    //  count, and it is the whole reason the texture lines are worth setting.
    a_on[ "r_picmip_manual" ]      = "1";
    a_on[ "r_picmip" ]             = "0";
    a_on[ "r_picmip_bump" ]        = "0";
    a_on[ "r_picmip_spec" ]        = "0";
    a_on[ "r_ssao" ]               = "3";
    a_on[ "sm_enable" ]            = "1";
    a_on[ "sm_maxLights" ]         = "4";
    a_on[ "sm_spotQuality" ]       = "2";
    a_on[ "sm_sunQuality" ]        = "2";
    a_on[ "r_bloomHiQuality" ]     = "1";
    a_on[ "r_autoLodScale" ]       = "0";
    a_on[ "r_lodScaleRigid" ]      = "1";
    a_on[ "r_lodScaleSkinned" ]    = "1";
    a_on[ "com_maxfps" ]           = "250";

    a_off = [];
    for ( i = 0; i < a_keys.size; i++ )
        a_off[ a_keys[i] ] = getdvar( a_keys[i] );

    n_prev = -1;

    for ( ;; )
    {
        n_on = getdvarintdefault( "graphics_boost", 0 );

        if ( n_on != n_prev )
        {
            n_prev = n_on;

            for ( i = 0; i < a_keys.size; i++ )
            {
                str_key = a_keys[i];

                if ( n_on )
                    setdvar( str_key, a_on[ str_key ] );
                else if ( a_off[ str_key ] != "" )
                    setdvar( str_key, a_off[ str_key ] );
            }

            if ( n_on )
                println( "[zm_qol] GRAPHICS BOOST on  - " + a_keys.size + " render dvars set (r_aaSamples/r_texFilterQuality apply next launch)" );
            else
                println( "[zm_qol] GRAPHICS BOOST off - restored" );
        }

        wait 0.5;
    }
}
//  setdvar only when the dvar has never been set, so a value already in the
//  user's config or typed at the console survives a map change. Remix's
//  create_dvar(), same idea.
qol_opt_dvar( str_dvar, str_default )
{
    if ( getdvar( str_dvar ) == "" )
        setdvar( str_dvar, str_default );
}

qol_opt_connect_loop()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread qol_opt_player_init();
    }
}

qol_opt_player_init()
{
    self endon( "disconnect" );

    b_first = 1;

    for ( ;; )
    {
        self waittill( "spawned_player" );

        if ( !b_first )
            continue;

        b_first = 0;

        self thread qol_opt_cherry_sound();
        self thread qol_opt_rapid_fire();
        self thread qol_opt_player_quotes();
        self thread qol_opt_night_mode();
        self thread qol_opt_character();
        self thread qol_opt_hud_watcher();
    }
}

// ----------------------------------------------------------------------------
//  rapid_fire
// ----------------------------------------------------------------------------
//  The "fast ray" trick: switching weapon and back cancels the fire animation,
//  so the next shot can start immediately. Adapted from Remix _players.gsc:139.
//
//  🛑 IT NEEDS A SECOND PRIMARY - Mule Kick, or any two-weapon loadout - because
//  the cancel IS the weapon switch. With one gun there is nothing to switch to
//  and this does nothing at all. That is inherent to the technique, not a bug
//  here, and it is why the loop checks primaries.size before doing anything.
// ----------------------------------------------------------------------------
qol_opt_rapid_fire()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for ( ;; )
    {
        if ( !getdvarintdefault( "rapid_fire", 0 ) )
        {
            wait 0.25;
            continue;
        }

        self waittill( "weapon_fired", str_fired );

        if ( !getdvarintdefault( "rapid_fire", 0 ) )
            continue;

        a_primaries = self getweaponslistprimaries();

        if ( !isdefined( a_primaries ) || a_primaries.size < 2 )
            continue;

        foreach ( str_weapon in a_primaries )
        {
            if ( str_weapon == str_fired )
                continue;

            self switchtoweapon( str_weapon );
            wait 0.05;
            self switchtoweapon( str_fired );
            self setspawnweapon( str_fired );
            break;
        }
    }
}

// ----------------------------------------------------------------------------
//  Electric Cherry's missing zap
// ----------------------------------------------------------------------------
//  v1.35.0 fixed the perk's DAMAGE - the guard bug that left player_thread_give
//  unset, so electric_cherry_reload_attack() never started. The sound did not
//  come back with it, and this is why: that function plays
//  "zmb_cherry_explode", and Electric Cherry is a Mob of the Dead perk, so its
//  aliases live in Mob of the Dead's soundbank. On Farm the loaded banks are
//  cmn_root, zmb_common, zmb_patch and zmb_survival_transit - none of them
//  Alcatraz's - so the alias resolves to nothing and the perk fires silently.
//  Exactly the wall the Wunderfizz spin sound is stuck behind, and it cannot be
//  fixed by script: a bank loads from the folder of the zone that declared it.
//
//  ✅ v1.39.0 — IT NOW PLAYS THE REAL SOUND, not a substitute. The mod builds
//  its own soundbank (see build_ff.bat), so zmb_cherry_explode's actual audio -
//  raw\sound\wpn\grenade\taser_mine\explode\tazer_mine, with Alcatraz's own
//  volume, bus and 125/625/750 distance curve - ships inside mod.all under the
//  mod-private name zmqol_cherry_zap and resolves on every map.
//
//  🛑 v1.38.0's substitute was zmb_hellhound_bolt, and the reason the user still
//  heard nothing is that THERE IS NO SUCH ALIAS. Dumping every bank a zombies
//  map can load (cmn_root, zmb_common, zmb_code_post_gfx, and the per-map banks)
//  and searching all of them finds it in none. It was never verified, only
//  described as verified. So was zmb_tombstone_looper in v1.32.0, which produced
//  the same silence for the same reason.
//
//  The check that settles this in seconds, for any alias, before shipping it:
//      Unlinker --include-assets soundbank -o <dir> <map>.ff
//      grep "^<alias>," <dir>\soundbank\*.aliases.csv
//  A missing alias is SILENT, never an error, so nothing in any log will tell
//  you. Look it up.
//
//  The listener itself is unchanged and was always right: stock notifies
//  "electric_cherry_start" on the player one line before its own playsound
//  (_zm_perk_electric_cherry.gsc:271).
//
//  Skipped on the two maps that own the perk, where stock's own alias resolves
//  and playing ours as well would just double the zap.
// ----------------------------------------------------------------------------
qol_opt_cherry_sound()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    if ( level.script == "zm_prison" || level.script == "zm_tomb" )
        return;

    for ( ;; )
    {
        self waittill( "electric_cherry_start" );
        self playsound( "zmqol_cherry_zap" );
    }
}

// ----------------------------------------------------------------------------
//  disable_player_quotes  -  hold the "already speaking" flag so VO is skipped.
// ----------------------------------------------------------------------------
qol_opt_player_quotes()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for ( ;; )
    {
        if ( getdvarintdefault( "disable_player_quotes", 1 ) )
            self.isspeaking = 1;

        wait 0.5;
    }
}

// ----------------------------------------------------------------------------
//  night_mode  -  client-side visual dvars only. Nothing server-authoritative
//  changes, so this cannot desync anything.
// ----------------------------------------------------------------------------
qol_opt_night_mode()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    if ( !isdefined( level.qol_default_exposure ) )
    {
        level.qol_default_exposure = getdvar( "r_exposureValue" );
        level.qol_default_sunlight = getdvar( "r_lightTweakSunLight" );
        level.qol_default_skyfactor = getdvar( "r_sky_intensity_factor0" );
    }

    b_on = 0;

    for ( ;; )
    {
        b_want = getdvarintdefault( "night_mode", 0 );

        if ( b_want && !b_on )
        {
            b_on = 1;
            self qol_opt_night_on();
        }
        else if ( !b_want && b_on )
        {
            b_on = 0;
            self qol_opt_night_off();
        }

        wait 0.25;
    }
}

qol_opt_night_on()
{
    if ( zmqol_minimal() )
        return;

    //  ========================================================================
    //  v1.59.3 - WHY THIS USED TO RENDER A BLACK SCREEN.
    //
    //  User, twice: "the night mode toggle command in console still is scuffed
    //  as hell, when i enable it the screen seems to go just black."
    //
    //  Two findings, both from Plutonium's own dvar_descriptions.json rather
    //  than from reasoning:
    //
    //  1. "r_exposureValue": "exposure ev stops". It is an EV OFFSET, and every
    //     stop HALVES the image. The old values came from Remix - 3.9 by
    //     default, up to 5.6 on Nuketown - which is between 1/15th and 1/48th
    //     brightness. That is the black screen, on its own, with nothing else
    //     wrong.
    //
    //  2. 🛑 THE ENTIRE vc_* FAMILY DOES NOT EXIST ON THIS BUILD. vc_yl, vc_yh,
    //     vc_rgbl and vc_rgbh return ZERO matches in dvar_descriptions.json,
    //     while r_exposureValue and r_filmUseTweaks are both present. Those four
    //     lines were the half that tinted the picture blue and lifted it back
    //     up - so only the darkening half ever applied. They are deleted rather
    //     than left in: a setclientdvar to a non-existent dvar is silent, and
    //     four silent lines are exactly what made this look like a colour
    //     problem instead of an exposure one.
    //
    //  The port was faithful to Remix. Remix simply targets a build where the
    //  other half of it works.
    //
    //  📝 TUNABLE, because the RIGHT number needs eyes and this has already
    //  cost boots. Default 1.25 stops - a bit over half brightness, which reads
    //  as dusk rather than a blackout. Change it live with:
    //        night_exposure 2      (darker)
    //        night_exposure 0.75   (lighter)
    //  then tell me the value that looks right and it becomes the default.
    //  ========================================================================
    //  ========================================================================
    //  v1.59.5 - PORTED FROM THE WORKING MOD, after three failed attempts at
    //  reasoning it out from dvar descriptions.
    //
    //  Source: BO2-GSC-Releases\Zombies Mods\Nightmode\Source Code\
    //          _zm_nightmode.gsc  - a dedicated, shipped night-mode mod.
    //
    //  🛑 THE BLACK SCREEN WAS A DUPLICATED LINE IN REMIX. This mod's values
    //  came from BO2-Remix\src\scripts\zm\remix\_visual.gsc, which sets vc_rgbh
    //  TWICE:
    //        line 86:  vc_rgbh  "0.07 0 0.25 0"      <- the real value
    //        line 90:  vc_rgbh  "0.015 0 0.07 0"     <- overwrites it
    //  vc_rgbh is the HIGHLIGHT end of the grade. Capped at 0.015 the brightest
    //  the picture can ever be is ~1.5%, which is a black screen. The working
    //  mod sets it ONCE, to "0.1 0 0.3 0". Remix's second line is a bug that
    //  was faithfully copied in.
    //
    //  Two more values were wrong in the same way, and both push the same
    //  direction:
    //        r_lightTweakSunLight      zm_qol 16  ->  working mod 1
    //        r_sky_intensity_factor0   zm_qol 3   ->  working mod 0
    //
    //  📝 AND I WAS WRONG ABOUT vc_* NOT EXISTING (v1.59.3/v1.59.4). They are
    //  absent from Plutonium's dvar_descriptions.json, and I read that as "not
    //  on this build". That file documents dvars; it does not enumerate every
    //  tweak dvar. A shipped mod depends on these and works. Absence from a
    //  description list is not absence from the engine - do not repeat that
    //  inference.
    //
    //  vc_fbm / vc_fsm are the baseline the working mod sets before any of the
    //  tweaks; they were never ported and are included now.
    //
    //  Deliberately NOT ported: r_lodBiasRigid / r_lodBiasSkinned at -1000.
    //  They force maximum model detail - a performance change, unrelated to
    //  darkness, and not something to inflict as a side effect of a light
    //  toggle.
    //  ========================================================================
    self setclientdvar( "r_dof_enable", 0 );
    self setclientdvar( "r_enablePlayerShadow", 1 );
    self setclientdvar( "r_skyTransition", 1 );
    self setclientdvar( "sm_sunquality", 2 );
    self setclientdvar( "vc_fbm", "0 0 0 0" );
    self setclientdvar( "vc_fsm", "1 1 1 1" );

    self setclientdvar( "r_filmUseTweaks", 1 );
    self setclientdvar( "r_bloomTweaks", 1 );
    self setclientdvar( "r_exposureTweak", 1 );
    self setclientdvar( "vc_rgbh", "0.1 0 0.3 0" );
    self setclientdvar( "vc_yl", "0 0 0.25 0" );
    self setclientdvar( "vc_yh", "0.02 0 0.1 0" );
    self setclientdvar( "vc_rgbl", "0.02 0 0.1 0" );
    self setclientdvar( "r_lightTweakSunLight", 1 );
    self setclientdvar( "r_sky_intensity_factor0", 0 );

    n_exposure = 3.9;

    if ( level.script == "zm_buried" )
        n_exposure = 3.5;
    else if ( level.script == "zm_tomb" )
        n_exposure = 4;
    else if ( level.script == "zm_nuked" )
        n_exposure = 5.6;
    else if ( level.script == "zm_highrise" )
        n_exposure = 3.9;

    self setclientdvar( "r_exposureValue", n_exposure );

    //  v1.99.18 - stashed so anything that has to SUSPEND night mode for a
    //  moment can put it back exactly, without a second copy of the table
    //  above. Who's Who is the first caller: its screen effect is a bright
    //  blowout and cannot read at 1/15 brightness, so it drops
    //  r_exposureTweak while the ghost state is up and restores from here.
    //  quality_of_life.gsc::zmqol_whoswho_overlay_off().
    self.qol_night_exposure = n_exposure;

    //  Buried, Mob and Origins actively re-assert their own lighting, so the
    //  working mod holds the values down in a loop. Ported with it.
    self thread qol_opt_night_visual_fix();

    println( "[zm_qol] night_mode ON - ported from _zm_nightmode.gsc, exposure " + n_exposure );
}

// ----------------------------------------------------------------------------
//  qol_opt_night_visual_fix  -  straight port of visual_fix() from
//  BO2-GSC-Releases\Zombies Mods\Nightmode\Source Code\_zm_nightmode.gsc
//
//  Three maps fight the settings back after they are applied - Buried re-raises
//  the sky, Mob and Origins re-raise the sun - so the values are re-asserted
//  until they stick. Without this those maps look untouched, which is exactly
//  the "does nothing at all" failure mode to avoid.
//
//  float() around the getdvar reads: getdvar returns a STRING, and the upstream
//  loop compares and decrements it directly. That is the one place this port
//  deviates, and only to make the comparison numeric rather than relying on
//  string coercion.
//
//  ========================================================================
//  🛑 v1.90.3 - THIS LOOP WAS KILLING ORIGINS, MOB AND BURIED AT 0:06.
//
//  User, 2026-08-14: Origins, Mob and Buried all failed to reach the game
//  with "CL_CGameNeedsServerCommand: A reliable command was cycled out."
//  TranZit and Die Rise were fine. All three died at exactly 0:06 server
//  time (games_mp.log), which is a threshold, not a race.
//
//  🌟 setclientdvar IS A RELIABLE SERVER COMMAND, and this function emitted
//  20 (prison/tomb) to 40 (buried) of them PER SECOND, from spawn, forever.
//  Six seconds of that is ~120-240 queued commands; the client's reliable
//  ring holds 128, so the oldest was overwritten before the client - still
//  loading, not yet acking - had read it. That is the error, verbatim.
//
//  🛑 AND THE EXIT CONDITION COULD NEVER BE TRUE. setclientdvar does not
//  write back into the value the SERVER's getdvar() returns. Measured, not
//  assumed: across 13 logged games the load-time dvar dump reports
//  r_exposureValue "3" and r_sky_intensity_factor0 "1" every single time,
//  including immediately after night mode set them to 3.5/3.9/4 and 0. So
//  `while ( getdvar(...) != 0 )` was always an infinite loop - here AND in
//  the source mod, where the same line compares a string to an int. It is
//  written as for(;;) now because that is what it always was; pretending
//  otherwise hid the real cost of the wait.
//
//  📝 WHY IT ONLY SURFACED NOW. It needs a second per-frame consumer to tip
//  it over: every one of these maps booted fine yesterday with night mode
//  ON and the velocity meter OFF, and died today with both ON. Nine games,
//  no counterexample. The meter is not the bug - it is one hudelem on
//  setvalue() - it is simply the load that exposed this one.
//
//  THE FIX IS A RATE CUT, NOT A RETUNE. The prison/tomb ramp keeps its
//  exact trajectory: it was 0.05 units per 0.05s and is now 0.2 per 0.2s -
//  the same 1.0 units/second, from the same start value to the same 0.
//  Buried's clamp is unchanged except that it re-asserts every 0.2s rather
//  than every 0.05s. Worst case over the first six seconds drops from
//  120-240 commands to 30-60, comfortably inside the ring.
//  ========================================================================
// ----------------------------------------------------------------------------
qol_opt_night_visual_fix()
{
    level endon( "game_ended" );
    self endon( "disconnect" );
    self endon( "disable_nightmode" );

    //  ========================================================================
    //  🛑 v1.93.1 - THIS RAN FOREVER AND IT IS WHY MOB OF THE DEAD DIED AT ~12s
    //  WITH CL_CGameNeedsServerCommand: EXE_ERR_RELIABLE_CYCLED_OUT.
    //
    //  Read the ORIGINAL, _zm_nightmode.gsc::visual_fix(), before changing this
    //  again. It is:
    //
    //      while( getDvar( "r_lightTweakSunLight" ) != 0 )
    //      {
    //          for( i = getDvar( "r_lightTweakSunLight" ); i >= 0; i -= 0.05 )
    //          { self setclientdvar( "r_lightTweakSunLight", i ); wait 0.05; }
    //          wait 0.05;
    //      }
    //
    //  That `while` is the author's own stop condition: ramp until the value is
    //  0, then stop. 🌟 IT CAN NEVER BE SATISFIED - setclientdvar does NOT write
    //  back into what the SERVER's getdvar() returns (proven in this project
    //  from 13 games of dvar dumps, see [[t6-plutonium-...]] and checkpoint 43).
    //  So the source mod's loop is infinite too; it is a latent bug there.
    //
    //  This port then dropped the `while` entirely for a bare for(;;), and
    //  v1.90.3 "fixed" the resulting flood by cutting the rate 4x (0.05 -> 0.2).
    //  🛑 A RATE CUT IS THE WRONG SHAPE. An unbounded stream fills the client's
    //  128-entry reliable ring eventually no matter how slow it is - the cut
    //  only moved the crash from 0:06 to 0:12, which is exactly what the
    //  2026-08-14 Mob log shows.
    //
    //  So: ramp ONCE and stop, which is what the original's `while` was written
    //  to do. That is parity with the author's intent, not a re-tune. Total
    //  cost is ~22 reliable commands on Mob/Origins and 2 on Buried, once, on a
    //  ring that holds 128 - instead of a permanent 5/sec.
    //
    //  📝 The step is back to the original's 0.05 because the ramp is now a
    //  one-shot: 0.2 was only ever there to slow the flood, and it made the
    //  fade visibly chunky.
    //  ========================================================================
    if ( level.script == "zm_buried" )
    {
        self setclientdvar( "r_lightTweakSunLight", 1 );
        self setclientdvar( "r_sky_intensity_factor0", 0 );
        return;
    }

    if ( level.script == "zm_prison" || level.script == "zm_tomb" )
    {
        n_start = float( getdvar( "r_lightTweakSunLight" ) );

        //  🛑 THE RAMP IS BOUNDED ON PURPOSE. Every step is one reliable
        //  command and the client's ring holds 128. The measured live value on
        //  Mob is exactly 1 ("r_lightTweakSunLight \"1\"" in the 2026-08-14
        //  dvar dump), i.e. 21 steps - but a map, a config or a user setting it
        //  higher must not be able to turn this back into the flood it just
        //  stopped being. Capping at 2 keeps the worst case at 41 commands,
        //  under a third of the ring.
        if ( n_start > 2 )
            n_start = 2;

        for ( i = n_start; i >= 0; i = ( i - 0.05 ) )
        {
            self setclientdvar( "r_lightTweakSunLight", i );
            wait 0.05;
        }

        //  Land exactly on 0 rather than on whatever the last step happened to
        //  be - the loop exits on i < 0, so the final written value could be a
        //  small positive number if the starting value is not a multiple of the
        //  step. One extra command, and it removes the doubt.
        self setclientdvar( "r_lightTweakSunLight", 0 );
    }
}

qol_opt_night_off()
{
    //  Undo the light grid, and explicitly clear the three overrides older
    //  builds switched on - anyone toggling night mode after running v1.59.3 or
    //  earlier may still have r_filmUseTweaks stuck at 1 from that session, and
    //  that alone is the black screen. Clearing them here makes turning night
    //  mode OFF a way out of it rather than a no-op.
    //  🛑 FIRST, and it is still not optional even though the reason changed in
    //  v1.93.1. qol_opt_night_visual_fix() endons on this notify. It used to run
    //  forever, so without the notify the restore below was overwritten within
    //  0.05s; it now ramps once and returns, so the only window is the ~1s the
    //  Mob/Origins ramp is still stepping - toggle night mode off inside that
    //  window without this notify and the ramp would fight the restore.
    //  disable_night_mode() in the source mod opens with the same notify.
    self notify( "disable_nightmode" );

    //  v1.99.18 - night mode is no longer applied, so there is nothing for a
    //  suspend/restore caller to put back. Cleared here so it cannot restore a
    //  stale value from an earlier toggle.
    self.qol_night_exposure = undefined;

    self setclientdvar( "r_lightGridEnableTweaks", 0 );
    self setclientdvar( "r_lightGridIntensity", 1 );
    self setclientdvar( "r_filmUseTweaks", 0 );
    self setclientdvar( "r_bloomTweaks", 0 );
    self setclientdvar( "r_exposureTweak", 0 );

    //  The grade itself, cleared exactly as the source mod's
    //  disable_night_mode() does. Without these the blue tint survives the
    //  toggle even with the film override off.
    self setclientdvar( "vc_rgbh", "0 0 0 0" );
    self setclientdvar( "vc_yl",   "0 0 0 0" );
    self setclientdvar( "vc_yh",   "0 0 0 0" );
    self setclientdvar( "vc_rgbl", "0 0 0 0" );

    if ( isdefined( level.qol_default_exposure ) )
    {
        self setclientdvar( "r_exposureValue", level.qol_default_exposure );
        self setclientdvar( "r_lightTweakSunLight", level.qol_default_sunlight );
        self setclientdvar( "r_sky_intensity_factor0", level.qol_default_skyfactor );
    }

    //  ========================================================================
    //  🛑 v1.99.54 - PUT DEPTH OF FIELD BACK THE WAY THE ADVANCED TAB HAS IT.
    //
    //  qol_opt_night_on() sets r_dof_enable 0 as part of the ported night look
    //  (it is one of the donor mod's own lines and it stays), but the donor's
    //  disable_night_mode() never puts it back - it had no depth-of-field
    //  option to put back. From v1.99.54 this mod does: stock's ADVANCED tab
    //  DEPTH OF FIELD row is HIGH / MEDIUM / LOW / DISABLED and it owns
    //  r_dof_enable. Without this line, one trip through night mode leaves the
    //  row reading HIGH while nothing is drawn, for the rest of the session.
    //
    //  dof_quality is that row's own dvar: 0 = DISABLED, 1 / 2 / 3 = LOW /
    //  MEDIUM / HIGH. Read rather than remembered on purpose - a value saved on
    //  the way in would be stale if the row were changed while night mode was
    //  on, and would then overwrite the player's newer choice.
    //  ========================================================================
    if ( getdvarintdefault( "dof_quality", 0 ) > 0 )
        self setclientdvar( "r_dof_enable", "1" );

}

// ----------------------------------------------------------------------------
//  character
// ----------------------------------------------------------------------------
//  🛑 DELIBERATELY NOT A COPY OF REMIX'S VERSION, AND THIS IS THE IMPORTANT
//  COMMENT IN THIS FILE.
//
//  Remix hardcodes the models: setmodel( "c_zom_player_oldman_fb" ),
//  setviewmodel( "c_zom_oldman_viewhands" ), and so on for the TranZit crew.
//  Those models are NOT on every map. Unlinker --list over every fastfile a
//  Farm survival game loads finds exactly two player bodies -
//  c_zom_player_cdc_fb and c_zom_player_cia_fb - because survival uses the
//  CDC/CIA teams rather than the crew. Setting a model the level never shipped
//  gives an invisible player, the same failure that made the Wunderfizz bottle
//  vanish.
//
//  So this sets characterindex and calls the LEVEL'S OWN character function
//  instead. Stock give_personality_characters() already switches on exactly
//  that variable (zm_transit.gsc:1153) and stock even has a dev-only force_char
//  dvar doing this very thing at :1149 - but inside a /# #/ block, so it is
//  stripped from the release build and unreachable from the console. This is
//  that, made available.
//
//  Because the level picks the model, it can only ever pick one the level has.
//  On Farm you get the CDC/CIA variants, on TranZit proper the crew - and on
//  Origins and Mob of the Dead nothing happens, which is correct: their
//  characters are story-fixed and stock guards them the same way.
// ----------------------------------------------------------------------------
qol_opt_character()
{
    self endon( "disconnect" );

    //  🛑 v1.99.65 - NOT AN EARLY RETURN ANY MORE. level.givecustomcharacters is
    //  assigned during the map's own main()/preinit, and a player thread can
    //  start before that; returning here killed the picker for the whole match.
    //  The loop below tests it every pass instead.

    //  ========================================================================
    //  🛑 v1.99.58 - TWO EARLY RETURNS REMOVED, AND BOTH WERE WRONG.
    //
    //  This function used to refuse to run in two cases. The comment above
    //  claimed *"on Origins and Mob of the Dead nothing happens, which is
    //  correct: their characters are story-fixed and stock guards them the same
    //  way."* That is FALSE, and the stock dump says so plainly:
    //
    //      zm_prison.gsc:51   level.givecustomcharacters = ::give_personality_characters;
    //      zm_tomb.gsc:156    level.givecustomcharacters = ::give_personality_characters;
    //
    //  Both switch on self.characterindex exactly the way TranZit does - Origins
    //  cycles Dempsey / Nikolai / Richtofen / Takeo and Mob cycles Finn / Sal /
    //  Billy / Arlington. Neither is story-fixed in classic, so the map gate was
    //  blocking two maps that work perfectly.
    //
    //      if ( level.script == "zm_tomb" || level.script == "zm_prison" ) return;
    //
    //  The second refusal was force_team_characters, which zm_tomb.gsc:71 sets
    //  in survival_init() - i.e. exactly the SURVIVAL case the new lobby row is
    //  for. And give_team_characters() (zm_buried.gsc) honours characterindex
    //  too: 0 and 2 give the CIA model, 1 and 3 the CDC one. So that guard was
    //  refusing the one path it was supposed to protect.
    //
    //  What still stops it is the real precondition, checked above: a map with
    //  no level.givecustomcharacters at all cannot switch anybody, and that is
    //  the only condition that actually matters.
    //  ========================================================================

    n_last = -1;
    b_last_saw_cia_flag = 0;
    b_seen_once = 0;

    for ( ;; )
    {
        if ( !isdefined( level.givecustomcharacters ) )
        {
            wait 0.5;
            continue;
        }

        n_want = getdvarintdefault( "character", 0 );
        b_sees_cia_flag = isdefined( level.should_use_cia );

        //  ====================================================================
        //  🛑 v1.99.65 - THIS USED TO FIRE ONCE AND LATCH, AND ON A CDC/CIA MAP
        //  THAT MADE THE LOBBY PICKER PICK THE WRONG TEAM.
        //
        //  User, 2026-08-19: *"in the pre-game menu i set the character override
        //  to CIA and started the match with the CDC viewarm/player model"* -
        //  while `character 1` typed at the console MID-GAME worked. Those two
        //  facts together name the cause exactly.
        //
        //  level.should_use_cia is set by the map's survival_init()
        //  (zm_nuked.gsc:41-44, zm_transit.gsc:88-92, zm_tomb.gsc:72-75), but
        //  level.givecustomcharacters is set earlier, in main() (zm_nuked.gsc:98).
        //  So there is a window where this loop can run with the character
        //  function available and the team flag NOT yet defined. In that window
        //  the block below skips the should_use_cia write, give_team_characters()
        //  reads whatever the random roll left, and the player is dressed as the
        //  wrong team - and because n_last was already set, it never tried again.
        //  Typing the dvar later lands outside the window, which is exactly why
        //  the console worked and the lobby did not.
        //
        //  🌟 THE FIX IS TO RE-APPLY WHEN THE FLAG TURNS UP. One extra condition:
        //  the choice changed, OR should_use_cia has appeared since the last
        //  application. It can fire at most twice per choice and it is the same
        //  code path both times.
        //  ====================================================================
        if ( n_want > 0 && ( n_want != n_last || ( b_sees_cia_flag && !b_last_saw_cia_flag ) ) )
        {
            n_last = n_want;
            b_last_saw_cia_flag = b_sees_cia_flag;
            //  1-4 in the console maps to characterindex 0-3, so the dvar reads
            //  the way a player expects rather than exposing the engine index.
            self.characterindex = ( n_want - 1 ) % 4;

            //  ================================================================
            //  🛑 v1.99.59 - ON THE TEAM MAPS, characterindex IS IGNORED, AND
            //  THAT IS WHY THE LOBBY PICKER DID NOTHING ON DINER SURVIVAL.
            //
            //  The two give_team_characters() implementations are NOT the same
            //  function, and v1.99.58 was written against the wrong one:
            //
            //    zm_buried.gsc   switches on self.characterindex - 0 and 2 give
            //                    the CIA model, 1 and 3 the CDC one.
            //    zm_transit.gsc:1076  checks level.should_use_cia FIRST, and if
            //                    it is defined it uses that ALONE, sets the
            //                    model from it and then OVERWRITES
            //                    self.characterindex with 0 or 1 on the way out.
            //                    The characterindex switch is only the `else`.
            //
            //  zm_transit's survival init defines should_use_cia every time
            //  (:88-92, `should_use_cia = 0; if ( randomint( 100 ) > 50 )
            //  should_use_cia = 1;`), so on Diner/Farm/Town the else branch is
            //  unreachable and setting characterindex could never have worked.
            //  Origins' survival_init() does the same thing (zm_tomb.gsc:72-75).
            //
            //  So on those maps the team is chosen through should_use_cia, and
            //  it has to be set BEFORE givecustomcharacters is called. CIA is
            //  characterindex 0 in both implementations, which is what keeps the
            //  lobby's ordering (1 = CIA, 2 = CDC) true on every map.
            //
            //  📝 It is a LEVEL variable, so in coop it is the whole team's
            //  model, not one player's - the same host-scoped limitation the
            //  lobby row already carries. Nothing else in either map reads it:
            //  zm_transit uses it only at :88-92 and inside
            //  give_team_characters().
            //  ================================================================
            if ( isdefined( level.should_use_cia ) )
            {
                if ( self.characterindex == 0 || self.characterindex == 2 )
                    level.should_use_cia = 1;
                else
                    level.should_use_cia = 0;
            }

            self.favorite_wall_weapons_list = [];
            self [[ level.givecustomcharacters ]]();

            //  ================================================================
            //  🛑 v1.99.66 - THE SCOREBOARD BADGE CANNOT FOLLOW A MID-MATCH
            //  SWITCH, AND THAT IS MEASURED, NOT ASSUMED.
            //
            //  The emblem watcher logs every write. On the user's 2026-08-19
            //  test the log reads:
            //      [zm_qol] scoreboard emblem -> faction_cia (should_use_cia=1)
            //      [zm_qol] scoreboard emblem -> faction_cdc (should_use_cia=0)
            //  so g_TeamIcon_Allies WAS changed to faction_cdc the moment
            //  `character 2` ran - and the scoreboard still drew CIA. The icon is
            //  therefore resolved when the scoreboard is built, not when it is
            //  opened, and setdvar is the only lever GSC has (_scoreboard.gsc is
            //  four setdvar calls and nothing else).
            //
            //  So the pre-game pick is correct - the user confirmed it - and the
            //  console path says so rather than pretending. Say it once, and only
            //  for a change made after the first application, so the normal
            //  spawn-time pick stays silent.
            //  ================================================================
            if ( b_seen_once && isdefined( level.should_use_cia ) )
                self iprintln( "^3[zm_qol] ^7character changed ^3- the scoreboard badge is fixed when the match starts and cannot follow" );

            b_seen_once = 1;
        }

        wait 0.5;
    }
}

// ----------------------------------------------------------------------------
//  coop_pause  -  freeze zombie spawning between rounds. Solo games ignore it,
//  same as Remix, because a solo player can just pause the game.
// ----------------------------------------------------------------------------
qol_opt_coop_pause()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    b_paused = 0;

    for ( ;; )
    {
        wait 0.5;

        b_want = getdvarintdefault( "coop_pause", 0 );

        if ( b_want == b_paused )
            continue;

        a_players = get_players();

        if ( a_players.size < 2 )
            continue;

        if ( b_want )
        {
            //  Wait for the round to end first - pausing mid-round would strand
            //  whatever is already alive and read as a freeze.
            if ( get_round_enemy_array().size + level.zombie_total != 0 )
            {
                level iprintln( "^3[zm_qol] ^7pausing at the start of the next round" );
                level waittill( "end_of_round" );
            }

            b_paused = 1;
            level iprintln( "^3[zm_qol] ^7PAUSED - coop_pause 0 to resume" );
        }
        else
        {
            b_paused = 0;
            level iprintln( "^3[zm_qol] ^7resumed" );
        }

        foreach ( player in a_players )
            player setclientdvar( "ai_disableSpawn", b_paused );
    }
}

// ----------------------------------------------------------------------------
//  no_power  -  TranZit's power-free challenge: no turbine, no jet gun.
// ----------------------------------------------------------------------------
//  🛑 This lives in a ROOT script even though it is TranZit-only, and that is
//  safe BECAUSE it touches no map-specific FUNCTION. It reads
//  level.zombie_include_buildables, a core variable, and points triggerthink at
//  a local stub. AI_CONTEXT rule 2 is about `maps\mp\zm_transit::foo`-style
//  references, which resolve at script LOAD time and crash every other map -
//  a runtime level.script guard does not save those. A level variable is fine.
//
//  Read once at setup rather than watched: the buildables are wired up during
//  level init, so flipping this mid-game would do nothing and pretending
//  otherwise would just be confusing.
// ----------------------------------------------------------------------------
qol_opt_no_power()
{
    if ( level.script != "zm_transit" )
        return;

    if ( !getdvarintdefault( "no_power", 0 ) )
        return;

    flag_wait( "start_zombie_round_logic" );

    if ( !isdefined( level.zombie_include_buildables ) )
        return;

    if ( isdefined( level.zombie_include_buildables[ "turbine" ] ) )
        level.zombie_include_buildables[ "turbine" ].triggerthink = ::qol_opt_nullptr;

    if ( isdefined( level.zombie_include_buildables[ "jetgun_zm" ] ) )
        level.zombie_include_buildables[ "jetgun_zm" ].triggerthink = ::qol_opt_nullptr;

    level iprintln( "^3[zm_qol] ^7no_power - turbine and jet gun disabled" );
}

qol_opt_nullptr()
{
}

// ----------------------------------------------------------------------------
//  The HUD dvars
// ----------------------------------------------------------------------------
//  These drive the HUD THIS MOD ALREADY DRAWS rather than adding a second one
//  next to it - the user asked to "keep my current hud for my health hud and
//  timer at the top of the screen". quality_of_life's timer(), zombiecounter()
//  and first_spawn() now stash their elements on self for this to find.
//
//  hud_all is an override, not a master switch: 0 leaves each hud_* dvar to
//  decide for itself, 1 forces everything on. That way turning it on to see
//  everything does not wipe out the individual settings underneath.
//
//  🛑 Only hud_zone and hud_round_timer create anything, and only while their
//  dvar is on - see the HUD allowance note at the top of this file.
// ----------------------------------------------------------------------------
qol_opt_hud_watcher()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    //  🛑 SEEDED WITH THE DEFAULT, NOT "". Seeding empty made the first pass see
    //  a "change" from "" to "1 1 1" and tint everything white on spawn - which
    //  turned the health bar's dark backing plate into the thick white border
    //  the user reported and never asked for. Nothing may be recoloured until
    //  the value actually differs from the default.
    str_prev_color = "1 1 1";
    //  v1.90.6 - same contract as str_prev_color: seeded to the dvar default so
    //  the first pass is a no-op. The elements are created already carrying
    //  these colours (timer() in quality_of_life.gsc and qol_opt_round_timer_hud
    //  below), so the watcher only ever has to act on a real console change.
    //  v1.95.3 - both are the same dull navy now; these MUST track the two
    //  qol_opt_dvar defaults above or the first pass repaints on spawn.
    str_prev_color_timer = "0.3 0.45 0.9";
    str_prev_color_round = "0.3 0.45 0.9";

    //  -1 so the first pass always writes the LUI flag once, whatever hud_master
    //  says. Seeding it to 1 would leave the flag unset on a player who joined
    //  with hud_master already 0.
    n_prev_master = -1;
    n_tick = 0;

    for ( ;; )
    {
        b_all = getdvarintdefault( "hud_all", 0 );

        // ====================================================================
        //  v1.85.0 - hud_master, the ".hud off" switch.
        //
        //  🛑 IT MUST BEAT hud_all, so it is applied as a multiplier on every
        //  branch below rather than as another `||` term. ".hud off" means off.
        //
        //  🌟 setclientuivisibilityflag( "hud_visible", 0 ) is what actually
        //  takes the GAME's hud down - points, ammo, round, perk icons, the
        //  power-up row. None of those are hudelems this mod owns, so no hud_*
        //  dvar has ever been able to touch them. This is not a guess: it is the
        //  exact call stock uses to hide the hud behind the intro screen, and
        //  quality_of_life.gsc::fade_out_intro_screen_zm_instant() sets the very
        //  same flag back to 1 when the blackscreen lifts.
        //
        //  Written ONLY on change. It is a reliable client command, and firing
        //  one every 0.25s is how you earn EXE_SERVERCOMMANDOVERFLOW.
        // ====================================================================
        //  🛑 AND IT HAS TO BE RE-ASSERTED, not just written once. Stock sets
        //  "hud_visible" back to 1 from several places during normal play -
        //  _globallogic_player.gsc:79, _globallogic.gsc:1197 and _zm.gsc:5300 -
        //  so a spawn or a round transition would quietly undo ".hud off".
        //  Re-written every 2s, and ONLY while the switch is off, which is a
        //  state the user asked for explicitly. At the normal setting this costs
        //  exactly one write, on the first pass.
        b_master = getdvarintdefault( "hud_master", 1 );
        n_tick++;

        if ( b_master != n_prev_master || ( !b_master && n_tick % 8 == 0 ) )
        {
            n_prev_master = b_master;
            self setclientuivisibilityflag( "hud_visible", b_master );

            // ================================================================
            //  🌟 v1.99.91 - THE SESSION WATERMARK GOES WITH IT.
            //
            //  User, 2026-08-20: *"same with the draw identifier ... make sure
            //  when HUD is set to Disabled the hud is really disabled, not just
            //  some hud elements."*
            //
            //  cg_drawIdentifier is the Plutonium dvar behind the GAME tab's
            //  DRAW IDENTIFIER row (ui/t6/menus/optionssettings.lua:1267) - the
            //  "*1787171762-0fe7-..." line across the top of the screen. It is
            //  drawn by the client, not by any hudelem or LUI widget this mod
            //  owns, so neither hud_visible nor any hud_* dvar could reach it.
            //
            //  🛑 THE USER'S OWN SETTING IS PRESERVED, NOT OVERWRITTEN. The
            //  value is stashed on the first switch-off and put back verbatim on
            //  switch-on, so a player who had it off keeps it off, and a player
            //  who had it on gets it back. Writing a hardcoded 1 on restore
            //  would quietly turn the watermark on for everyone who had it off.
            // ================================================================
            if ( !b_master )
            {
                if ( !isdefined( self.qol_drawid_saved ) )
                    self.qol_drawid_saved = getdvarintdefault( "cg_drawIdentifier", 1 );

                setdvar( "cg_drawIdentifier", 0 );
            }
            else if ( isdefined( self.qol_drawid_saved ) )
            {
                setdvar( "cg_drawIdentifier", self.qol_drawid_saved );
                self.qol_drawid_saved = undefined;
            }
        }

        // ====================================================================
        //  v2.0.8 - ROUND COUNTER LEFT, applied live.
        //
        //  The round counter re-anchors itself every round (round_hud() calls
        //  the same helper on its fly-back), but the two timers are created
        //  ONCE, so without this a mid-game flip would leave them behind on the
        //  other side of the screen. Written only when the row CHANGES.
        //
        //  🛑 level.zmqol_roundcounter is a SERVER hudelem shared by everyone,
        //  so it is moved once at level scope rather than once per player -
        //  writing it inside this per-player loop would still be correct but
        //  would do it N times for no reason. It is guarded because the default
        //  branch of round_hud() destroys and re-creates it every round.
        // ====================================================================
        b_round_left = getdvarintdefault( "hud_round_left", 0 ) != 0;

        if ( !isdefined( self.qol_round_left_last ) || self.qol_round_left_last != b_round_left )
        {
            self.qol_round_left_last = b_round_left;

            zmqol_hud_round_anchor( self.qol_hud_timer );
            zmqol_hud_round_anchor( self.qol_hud_roundtimer );

            if ( isdefined( level.zmqol_roundcounter ) )
                zmqol_hud_round_anchor( level.zmqol_roundcounter );
        }

        self qol_opt_show( self.qol_hud_timer, b_master && ( b_all || getdvarintdefault( "hud_timer", 1 ) ) );

        // ====================================================================
        //  🛑 TWO ELEMENTS ARE DELIBERATELY NOT TOUCHED HERE, AND v1.85.0 GOT
        //  BOTH WRONG. Same rule as the health HUD below: whatever repaints an
        //  element every tick is the ONLY thing allowed to write its alpha.
        //
        //  self.zombietext - quality_of_life.gsc::zombiecounter() writes
        //  `alpha = 1` four times a second. Writing 0 from here made the counter
        //  visibly flash on and off, which is what the user reported. That loop
        //  now reads hud_master / hud_all / hud_remaining itself.
        //
        //  self.qol_hud_shield - shield_hud() CREATES AND DESTROYS its two
        //  elements rather than fading them, and its background is deliberately
        //  alpha 0.5. qol_opt_show() only knows 0 and 1, so restoring it from
        //  here would have turned that dark backing plate fully opaque - the
        //  exact "thick white border" bug this file already documents for the
        //  health bar. shield_hud() takes its own destroy path on hud_master 0.
        // ====================================================================

        //  🛑 The health HUD is deliberately NOT touched here. quality_of_life's
        //  own health loop already owns its alpha (it restores it the instant it
        //  sees a 0) and its colour (it repaints per health tier every 0.1s).
        //  Two threads writing the same health elements is what produced the white
        //  bar, so there is exactly one owner now: that loop reads hud_health_bar
        //  and hud_color_health itself.

        self qol_opt_zone_hud( b_master && ( b_all || getdvarintdefault( "hud_zone", 0 ) ) );
        self qol_opt_compass_hud( b_master && ( b_all || getdvarintdefault( "hud_compass", 0 ) ) );
        self qol_opt_round_timer_hud( b_master && ( b_all || getdvarintdefault( "hud_round_timer", 1 ) ) );

        //  Colour is only re-applied when the string actually changes. Writing
        //  .color every tick on every element would be a lot of needless work
        //  for a value that changes when someone types at the console.
        str_color = getdvar( "hud_color" );

        if ( str_color != str_prev_color )
        {
            str_prev_color = str_color;
            v_color = qol_opt_parse_color( str_color );

            if ( isdefined( v_color ) )
            {
                //  v1.90.6 - qol_hud_timer and qol_hud_roundtimer are NO LONGER
                //  tinted from hud_color; they have their own dvars below so the
                //  user's yellow / light blue survive a hud_color change.
                self qol_opt_tint( self.zombietext, v_color );
                self qol_opt_tint( self.qol_hud_zone, v_color );
            }
        }

        //  The two stacked top-right timers, each with its own colour dvar.
        str_color_timer = getdvar( "hud_color_timer" );

        if ( str_color_timer != str_prev_color_timer )
        {
            str_prev_color_timer = str_color_timer;
            v_color = qol_opt_parse_color( str_color_timer );

            if ( isdefined( v_color ) )
                self qol_opt_tint( self.qol_hud_timer, v_color );
        }

        str_color_round = getdvar( "hud_color_round_timer" );

        if ( str_color_round != str_prev_color_round )
        {
            str_prev_color_round = str_color_round;
            v_color = qol_opt_parse_color( str_color_round );

            if ( isdefined( v_color ) )
                self qol_opt_tint( self.qol_hud_roundtimer, v_color );
        }

        wait 0.25;
    }
}

//  "1 0.5 0" -> ( 1, 0.5, 0 ). Undefined on anything that is not three numbers,
//  so a typo at the console leaves the HUD alone instead of blanking it.
qol_opt_parse_color( str_color )
{
    if ( !isdefined( str_color ) || str_color == "" )
        return undefined;

    a_parts = strtok( str_color, " " );

    if ( !isdefined( a_parts ) || a_parts.size != 3 )
        return undefined;

    return ( string_to_float( a_parts[0] ), string_to_float( a_parts[1] ), string_to_float( a_parts[2] ) );
}

qol_opt_show( e_hud, b_visible )
{
    if ( !isdefined( e_hud ) )
        return;

    if ( b_visible )
        e_hud.alpha = 1;
    else
        e_hud.alpha = 0;
}

qol_opt_tint( e_hud, v_color )
{
    if ( !isdefined( e_hud ) )
        return;

    e_hud.color = v_color;
}

//  Current zone name. Built on level.zones / self.zone_name, which _zm_zonemgr
//  maintains on every map, so there is no map-specific reference here.
qol_opt_zone_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_zone ) )
        {
            self.qol_hud_zone destroy();
            self.qol_hud_zone = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_zone ) )
    {
        self.qol_hud_zone = self createfontstring( "hudsmall", 1.2 );

        //  -19 -> -24, v1.77.0. Moves in lockstep with the zombie counter
        //  (quality_of_life.gsc::zombiecounter(), -7 -> -12) so the 12-unit gap
        //  between the two is unchanged. Both shifted up by 5, the height of the
        //  shield bar that now sits below them. Move one without the other and
        //  they overlap.
        self.qol_hud_zone setpoint( "LEFT", "BOTTOM_LEFT", -45, -24 );
        self.qol_hud_zone.hidewheninmenu = 1;
    }

    str_zone = "";

    if ( isdefined( self.zone_name ) )
        str_zone = self.zone_name;

    //  🛑 v1.95.1 - WRITTEN ONLY ON CHANGE. This is called from
    //  qol_opt_hud_watcher()'s permanent 0.25s loop, and settext() is ONE
    //  RELIABLE SERVER COMMAND PER CALL - so with hud_zone on this was a
    //  permanent 4/sec stream against a 128-entry ring, which is the exact
    //  defect ERROR_CATALOGUE section 7b is about and the exact thing the health
    //  HUD was fixed for in v1.65.3. A player standing in one zone was sending
    //  four commands a second to report that nothing had changed.
    //
    //  📝 This is NOT claimed to be the Origins crash. The dvar dump from that
    //  session reads hud_zone "0", so this loop was not running there. It is a
    //  real unbounded emitter found while looking for that one, and it is fixed
    //  on its own merits.
    //
    //  🌟 THE CACHE LIVES ON THE HUDELEM, for the same reason the health one
    //  does: the block above destroys and re-creates this element whenever
    //  hud_zone is toggled, and a local would survive that and leave the fresh
    //  element permanently blank. A new element carries no .qol_last_zone, so
    //  the first pass after any re-create writes the text again.
    if ( !isdefined( self.qol_hud_zone.qol_last_zone ) || self.qol_hud_zone.qol_last_zone != str_zone )
    {
        self.qol_hud_zone settext( str_zone );
        self.qol_hud_zone.qol_last_zone = str_zone;
    }
}

// ----------------------------------------------------------------------------
//  COMPASS  -  the heading you are facing, top centre.          (v1.99.26)
// ----------------------------------------------------------------------------
//  User request 2026-08-17, from the TechnoOps collection. Their version is in
//  their pre-game lobby; the user asked for it on the HUD tab instead.
//
//  🌟 NOTHING IS IMPORTED. Theirs is three text hudelems and an angle lookup -
//  a technique, not an asset - so this is written against this file's own zone
//  HUD rather than copied. No shader, no material, no rule-7 question.
//
//  🛑 AND IT IS DELIBERATELY NOT A COPY OF THEIRS, because theirs would crash
//  this mod. `compassHud()` (their main.gsc:1926) calls settext() every pass of
//  a permanent loop. settext() is ONE RELIABLE SERVER COMMAND PER CALL against
//  a 128-entry ring - the exact unbounded emitter ERROR_CATALOGUE section 7b is
//  about, and the one that was fixed out of the zone HUD directly above in
//  v1.95.1. Here the heading is one of EIGHT strings and is written only when
//  it actually changes, so standing still or turning slowly costs nothing.
//
//  📝 Only the heading is drawn. Their version stacks a numeric angle and the
//  zone name under it; this mod already has a zone-name row (hud_zone), and a
//  raw yaw number is not something a player reads mid-round.
qol_opt_compass_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_compass ) )
        {
            self.qol_hud_compass destroy();
            self.qol_hud_compass = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_compass ) )
    {
        self.qol_hud_compass = self createfontstring( "hudsmall", 1.4 );
        //  Top centre. Clear of the round counter (top right) and of the
        //  power-up row, which is centred lower down.
        self.qol_hud_compass setpoint( "TOP", "TOP", 0, 10 );
        self.qol_hud_compass.hidewheninmenu = 1;
    }

    str_heading = qol_opt_heading_text( self getplayerangles() );

    //  🌟 The cache lives ON THE HUDELEM, not in a local - same reason as the
    //  zone HUD above. Toggling hud_compass destroys and re-creates the element,
    //  and a local would survive that and leave the new element permanently
    //  blank. A fresh element carries no .qol_last_heading, so the first pass
    //  after any re-create writes the text again.
    if ( !isdefined( self.qol_hud_compass.qol_last_heading ) || self.qol_hud_compass.qol_last_heading != str_heading )
    {
        self.qol_hud_compass settext( str_heading );
        self.qol_hud_compass.qol_last_heading = str_heading;
    }
}

//  Yaw -> compass point. getplayerangles()[1] is the yaw, 0 = +X = East in this
//  engine, increasing anticlockwise; the +22.5 rounds to the nearest of eight
//  rather than truncating, so each label owns a 45-degree arc centred on it.
qol_opt_heading_text( v_angles )
{
    n_yaw = v_angles[1];

    while ( n_yaw < 0 )
        n_yaw = n_yaw + 360;
    while ( n_yaw >= 360 )
        n_yaw = n_yaw - 360;

    n_index = int( ( n_yaw + 22.5 ) / 45 );

    if ( n_index >= 8 )
        n_index = 0;

    if ( n_index == 0 ) return "E";
    if ( n_index == 1 ) return "NE";
    if ( n_index == 2 ) return "N";
    if ( n_index == 3 ) return "NW";
    if ( n_index == 4 ) return "W";
    if ( n_index == 5 ) return "SW";
    if ( n_index == 6 ) return "S";

    return "SE";
}

//  Time since the current round started, next to the game timer.
qol_opt_round_timer_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_roundtimer ) )
        {
            self.qol_hud_roundtimer destroy();
            self.qol_hud_roundtimer = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_roundtimer ) )
    {
        //  v1.95.3 - SITS DIRECTLY UNDER THE GAME TIMER, TOP-RIGHT, and the pair
        //  now sits under the round counter instead of on Mob's key icon.
        //
        //  🛑 EVERY FIELD BELOW MIRRORS quality_of_life.gsc::timer() ON PURPOSE,
        //  and the derivation of all four numbers lives in that function's
        //  comment - read it before touching either element. Same alignx, same
        //  horzalign, same vertalign, same x; only y differs, by one 14-unit row.
        //  (Both keep vertalign "user_top" rather than round_hud()'s "top": the y
        //  values are measured in the "user_top" frame, so that offset is already
        //  accounted for.)
        self.qol_hud_roundtimer = self createfontstring( "hudsmall", 1.2 );
        self.qol_hud_roundtimer.alignx = "center";
        self.qol_hud_roundtimer.aligny = "top";
        self.qol_hud_roundtimer.vertalign = "user_top";
        //  v2.0.8 - side comes from the shared anchor so this stays glued to the
        //  round counter when ROUND COUNTER LEFT is thrown. y is untouched.
        zmqol_hud_round_anchor( self.qol_hud_roundtimer );
        self.qol_hud_roundtimer.y = 94;     // == timer.y (80) + one 14-unit row
        //  v1.95.3 - dull navy blue, same value as the game timer above, user
        //  2026-08-14. Set at creation for the same reason: the watcher no-ops on
        //  its first pass. Console override: hud_color_round_timer "r g b".
        self.qol_hud_roundtimer.color = ( 0.3, 0.45, 0.9 );
        self.qol_hud_roundtimer.hidewheninmenu = 1;

        if ( isdefined( level.qol_round_start_time ) )
            self.qol_hud_roundtimer settimerup( ( gettime() - level.qol_round_start_time ) / 1000 );
        else
            self.qol_hud_roundtimer settimerup( 0 );
    }
}

//  level.qol_round_start_time is what the round timer counts from. Threaded
//  from init() rather than hooked into the round logic so nothing stock has to
//  be replaced for a cosmetic readout.
qol_opt_round_clock()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "start_of_round" );
        level.qol_round_start_time = gettime();

        foreach ( player in get_players() )
        {
            if ( isdefined( player.qol_hud_roundtimer ) )
                player.qol_hud_roundtimer settimerup( 0 );
        }
    }
}

zmqol_minimal()
{
    //  Twin of the one in quality_of_life.gsc - see the long note there. GSC
    //  scopes function names per file, so each file that needs the gate carries
    //  its own two-line copy rather than reaching across with a qualified call.
    return getdvarintdefault( "zmqol_minimal", 0 );
}

// ============================================================================
//  zmqol_hud_round_anchor  -  ROUND COUNTER LEFT                     (v2.0.8)
//
//  User, 2026-08-21: *"my mod has the round counter at the top right of the
//  screen like cold war zombies ... it'd be cool to have an option in the hud
//  tab ... to be able to have it on the top left (same vertical y coords, just
//  on the top left instead of top right, same as bo4 zombies)."*
//
//  🌟 THE MIRROR IS DERIVED FROM TWO SHIPPED ELEMENTS, NOT GUESSED. T6 hudelem
//  x is measured from the SAFE-AREA edge named by horzalign, and it grows
//  OUTWARD from that edge into the margin. Both directions are already in this
//  file with working values:
//        round_hud()   horzalign "right", x = +25   (top right, 25 into the margin)
//        healthbar     horzalign "left",  x = -45   (bottom left, 45 into the margin)
//  So the exact mirror of the round counter's +25 on the right is -25 on the
//  left, and it lands the same distance in from the screen edge.
//
//  🛑 THE WHOLE STACK MOVES, NOT JUST THE NUMBER. timer() and
//  qol_options.gsc::qol_opt_round_timer_hud() are calibrated to sit directly
//  under the round counter and both carried its x = 25 verbatim - the comment
//  above timer() says so and warns that changing one without the other splits
//  the stack. All three now read this one anchor. Only the SIDE changes; every
//  y is untouched, which is exactly what the user asked for.
//
//  📝 Twin of quality_of_life.gsc::zmqol_hud_round_anchor(). Same shape as
//  zmqol_minimal(), which is duplicated across these two root scripts for the
//  same reason - neither file references the other, and adding a cross-file
//  call would be a new load-order dependency for six lines.
// ============================================================================
zmqol_hud_round_anchor( elem )
{
    if ( !isdefined( elem ) )
        return;

    if ( getdvarintdefault( "hud_round_left", 0 ) )
    {
        elem.horzalign = "left";
        elem.x = -25;
    }
    else
    {
        elem.horzalign = "right";
        elem.x = 25;
    }
}
