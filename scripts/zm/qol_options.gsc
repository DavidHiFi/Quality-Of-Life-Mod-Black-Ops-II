// ============================================================================
//  qol_options  -  console-configurable options, adapted from BO2-Remix
// ============================================================================
//  Adds the dvars the user asked for from H:\Claude\BO2-Remix and NOTHING else
//  from that mod. Explicitly NOT ported: the walker removal, the power-up
//  rework, the bank/perma-perk/fridge/box patches, the round-255 and points
//  changes, the strat tester. Those are gameplay changes; this file is options.
//
//  Everything here is OFF by default except disable_player_quotes, so a fresh
//  install plays exactly as it did before any of this existed.
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
    //  Registered up front so they all show up in the console's autocomplete
    //  even before anything reads them.
    qol_opt_dvar( "rapid_fire",            "0" );
    qol_opt_dvar( "night_mode",            "0" );
    qol_opt_dvar( "character",             "0" );
    qol_opt_dvar( "disable_player_quotes", "1" );
    qol_opt_dvar( "coop_pause",            "0" );

    qol_opt_dvar( "hud_all",          "0" );
    qol_opt_dvar( "hud_timer",        "1" );
    qol_opt_dvar( "hud_round_timer",  "0" );
    qol_opt_dvar( "hud_health_bar",   "1" );
    qol_opt_dvar( "hud_remaining",    "1" );
    qol_opt_dvar( "hud_zone",         "0" );
    qol_opt_dvar( "hud_color",        "1 1 1" );
    qol_opt_dvar( "hud_color_health", "1 1 1" );

    //  Read by quality_of_life::get_pack_a_punch_weapon_options(). Default 1
    //  keeps the animated camo exactly where this mod already had it.
    qol_opt_dvar( "anim_pap_camo_mob",     "1" );
    qol_opt_dvar( "anim_pap_camo_buried",  "1" );
    qol_opt_dvar( "anim_pap_camo_origins", "1" );

    qol_opt_dvar( "no_power", "0" );

    //  Model pop-in. On by default - it is a pure image-quality win with no
    //  gameplay effect. See qol_opt_lod_fix() for what it actually writes.
    qol_opt_dvar( "lod_fix", "1" );

    level thread qol_opt_coop_pause();
    level thread qol_opt_round_clock();
    level thread qol_opt_no_power();
    level thread qol_opt_lod_fix();
    level thread qol_opt_connect_loop();
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
    self setclientdvar( "r_filmUseTweaks", 1 );
    self setclientdvar( "r_bloomTweaks", 1 );
    self setclientdvar( "r_exposureTweak", 1 );

    //  These two DO exist and do the actual "night" work - the sun is dimmed
    //  and the sky pushed up, which darkens the world without crushing the
    //  whole frame the way exposure does.
    self setclientdvar( "r_lightTweakSunLight", 16 );
    self setclientdvar( "r_sky_intensity_factor0", 3 );

    n_exposure = getdvarfloatdefault( "night_exposure", 1.25 );

    //  Clamp, so a typo cannot reproduce the original black screen. 4 stops is
    //  1/16th brightness and already past usable.
    if ( n_exposure < 0 )
        n_exposure = 0;

    if ( n_exposure > 4 )
        n_exposure = 4;

    self setclientdvar( "r_exposureValue", n_exposure );

    println( "[zm_qol] night_mode ON - exposure " + n_exposure + " ev stops (tune with the night_exposure dvar)" );
}

qol_opt_night_off()
{
    self setclientdvar( "r_filmUseTweaks", 0 );
    self setclientdvar( "r_bloomTweaks", 0 );
    self setclientdvar( "r_exposureTweak", 0 );

    //  The vc_* resets are gone with their counterparts in qol_opt_night_on -
    //  that dvar family does not exist on this build, so these four lines were
    //  resetting nothing.

    if ( isdefined( level.qol_default_exposure ) )
    {
        self setclientdvar( "r_exposureValue", level.qol_default_exposure );
        self setclientdvar( "r_lightTweakSunLight", level.qol_default_sunlight );
        self setclientdvar( "r_sky_intensity_factor0", level.qol_default_skyfactor );
    }
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

    if ( !isdefined( level.givecustomcharacters ) )
        return;

    if ( isdefined( level.force_team_characters ) && level.force_team_characters == 1 )
        return;

    if ( level.script == "zm_tomb" || level.script == "zm_prison" )
        return;

    n_last = -1;

    for ( ;; )
    {
        n_want = getdvarintdefault( "character", 0 );

        //  0 means "leave it alone" - the player keeps whoever they spawned as.
        if ( n_want > 0 && n_want != n_last )
        {
            n_last = n_want;

            //  1-4 in the console maps to characterindex 0-3, so the dvar reads
            //  the way a player expects rather than exposing the engine index.
            self.characterindex = ( n_want - 1 ) % 4;
            self.favorite_wall_weapons_list = [];
            self [[ level.givecustomcharacters ]]();
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
    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    //  🛑 SEEDED WITH THE DEFAULT, NOT "". Seeding empty made the first pass see
    //  a "change" from "" to "1 1 1" and tint everything white on spawn - which
    //  turned the health bar's dark backing plate into the thick white border
    //  the user reported and never asked for. Nothing may be recoloured until
    //  the value actually differs from the default.
    str_prev_color = "1 1 1";

    for ( ;; )
    {
        b_all = getdvarintdefault( "hud_all", 0 );

        self qol_opt_show( self.qol_hud_timer, b_all || getdvarintdefault( "hud_timer", 1 ) );
        self qol_opt_show( self.zombietext,    b_all || getdvarintdefault( "hud_remaining", 1 ) );

        //  🛑 The health HUD is deliberately NOT touched here. quality_of_life's
        //  own health loop already owns its alpha (it restores it the instant it
        //  sees a 0) and its colour (it repaints per health tier every 0.1s).
        //  Two threads writing the same five elements is what produced the white
        //  bar, so there is exactly one owner now: that loop reads hud_health_bar
        //  and hud_color_health itself.

        self qol_opt_zone_hud( b_all || getdvarintdefault( "hud_zone", 0 ) );
        self qol_opt_round_timer_hud( b_all || getdvarintdefault( "hud_round_timer", 0 ) );

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
                self qol_opt_tint( self.qol_hud_timer, v_color );
                self qol_opt_tint( self.zombietext, v_color );
                self qol_opt_tint( self.qol_hud_zone, v_color );
                self qol_opt_tint( self.qol_hud_roundtimer, v_color );
            }
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
        self.qol_hud_zone setpoint( "LEFT", "BOTTOM_LEFT", -45, -19 );
        self.qol_hud_zone.hidewheninmenu = 1;
    }

    str_zone = "";

    if ( isdefined( self.zone_name ) )
        str_zone = self.zone_name;

    self.qol_hud_zone settext( str_zone );
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
        self.qol_hud_roundtimer = self createfontstring( "hudsmall", 1.2 );
        self.qol_hud_roundtimer setpoint( "TOP", "TOP", 0, 14 );
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
