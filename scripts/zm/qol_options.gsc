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
    //  Registered up front so they all show up in the console's autocomplete
    //  even before anything reads them.
    qol_opt_dvar( "rapid_fire",            "0" );
    qol_opt_dvar( "night_mode",            "0" );
    qol_opt_dvar( "character",             "0" );
    qol_opt_dvar( "disable_player_quotes", "1" );
    qol_opt_dvar( "coop_pause",            "0" );

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
    qol_opt_dvar( "hud_remaining",    "1" );
    qol_opt_dvar( "hud_zone",         "0" );
    qol_opt_dvar( "hud_color",        "1 1 1" );
    qol_opt_dvar( "hud_color_health", "1 1 1" );
    //  v1.90.6 - the two stacked top-left timers get their own colours, user
    //  2026-08-14: game time yellow, round timer light blue.
    //
    //  🛑 They had to come OUT of the shared hud_color tint list to do this.
    //  qol_opt_hud_watcher() repaints from one dvar on change, so a colour set
    //  at creation was guaranteed to be flattened back to white on the very
    //  first pass - the same single-owner rule as the health bar above.
    //  hud_color still owns zombietext and the zone name.
    qol_opt_dvar( "hud_color_timer",       "1 1 0" );
    qol_opt_dvar( "hud_color_round_timer", "0.4 0.75 1" );

    //  Read by quality_of_life::get_pack_a_punch_weapon_options(). Default 1
    //  keeps the animated camo exactly where this mod already had it.
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
    qol_opt_dvar( "round_summary", "1" );
    qol_opt_dvar( "intro_credits", "1" );

    qol_opt_dvar( "no_power", "0" );

    //  Model pop-in. On by default - it is a pure image-quality win with no
    //  gameplay effect. See qol_opt_lod_fix() for what it actually writes.
    qol_opt_dvar( "lod_fix", "1" );

    level thread qol_opt_coop_pause();
    level thread qol_opt_round_clock();
    level thread qol_opt_no_power();
    level thread qol_opt_lod_fix();
    level thread qol_opt_roundcounter_master();
    level thread qol_opt_connect_loop();
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
    //  v1.90.6 - same contract as str_prev_color: seeded to the dvar default so
    //  the first pass is a no-op. The elements are created already carrying
    //  these colours (timer() in quality_of_life.gsc and qol_opt_round_timer_hud
    //  below), so the watcher only ever has to act on a real console change.
    str_prev_color_timer = "1 1 0";
    str_prev_color_round = "0.4 0.75 1";

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
        //  Two threads writing the same five elements is what produced the white
        //  bar, so there is exactly one owner now: that loop reads hud_health_bar
        //  and hud_color_health itself.

        self qol_opt_zone_hud( b_master && ( b_all || getdvarintdefault( "hud_zone", 0 ) ) );
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

        //  The two stacked top-left timers, each with its own colour dvar.
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
        //  v1.84.0 - SITS DIRECTLY UNDER THE GAME TIMER, TOP-LEFT.
        //
        //  🛑 EVERY FIELD BELOW MIRRORS quality_of_life.gsc::timer() ON PURPOSE.
        //  This used to be setpoint( "TOP", "TOP", 0, 14 ), which resolves y
        //  against vertalign "top" while the game timer resolves against
        //  "user_top" - two different origins, so the two elements were never
        //  actually 14 apart and would drift with the safe-area setting. Same
        //  horzalign, same vertalign, same x; only y differs, by one row.
        self.qol_hud_roundtimer = self createfontstring( "hudsmall", 1.2 );
        self.qol_hud_roundtimer.alignx = "left";
        self.qol_hud_roundtimer.aligny = "top";
        self.qol_hud_roundtimer.horzalign = "left";
        self.qol_hud_roundtimer.vertalign = "user_top";
        //  v1.90.12 - moved with the game timer (-64 -> -45, +10 on y). Both
        //  numbers are derived in quality_of_life.gsc::timer(); read the note
        //  there before touching either. The 14-unit row gap is unchanged.
        self.qol_hud_roundtimer.x = -45;    // == timer.x, see the note there
        self.qol_hud_roundtimer.y = 22;     // == timer.y (8) + one 14px row
        //  v1.90.6 - light blue, user 2026-08-14. Set at creation for the same
        //  reason as the game timer's yellow: the watcher no-ops on its first
        //  pass. Console override: hud_color_round_timer "r g b".
        self.qol_hud_roundtimer.color = ( 0.4, 0.75, 1 );
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
