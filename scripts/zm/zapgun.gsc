// ============================================================================
//  zapgun.gsc  -  THE WAVE GUN / ZAP GUNS, COMPLETE                (v2.10.14)
// ----------------------------------------------------------------------------
//  v2.9.18-v2.10.13 shipped the split Zap Guns alone, on the zm_ezz3.0
//  package's converted models, because the combined Wave Gun existed only in T5
//  form and nothing on this machine could compile a T6 xmodel. The user's
//  directive of 2026-09-03 delivered the missing half: Zombies Declassified
//  BETA 1 (Logo2K's PC port of the cancelled BO2 DLC5) ships Moon as a native
//  T6 zone, and that zone carries Treyarch's ENTIRE Wave Gun package in T6
//  form - the six weapon defs, the six models, 49 view anims, all 28 effects,
//  the sound bank, and this very script's T6 original,
//  maps\mp\zombies\_zm_weap_microwavegun.gsc. Nothing below is a lookalike.
//
//  THIS FILE IS THAT T6 ORIGINAL, PORTED. It was carved out of the DLC5
//  zm_moon.ff and decompiled with gsc-tool (scratchpad gsc_carve\, checkpoint
//  201); every function keeps its original name and order so a diff against
//  the decompile reads line for line. Every stock API it leans on was
//  grep-verified in the gsc-dump on 2026-09-03: register_zombie_damage_callback
//  and register_zombie_death_animscript_callback (_zm_spawner core - the older
//  banner here that claimed T6 lacked them was wrong), get_round_enemy_array,
//  get_array_of_closest, pointonsegmentnearesttopoint, damageconetrace,
//  network_safe_play_fx_on_tag, hasanimstatefromasd, "thundergun_fling" score.
//  Stock's own core already knows these weapon names: _zm_magicbox draws the
//  second gun in the box, _zm_perks upgrades the dual pair when you Pack-a-Punch
//  holding the combined gun, _zm_audio excludes microwave kills from the kill
//  counter, _zm.gsc lists the pair as pistols.
//
//  WHAT DIFFERS FROM THE ORIGINAL, AND WHY (each one measured, none guessed):
//   1. NO CLIENTFIELDS. Moon registers two 1-bit "actor" fields for the client
//      sizzle visuals; this mod's actor set stands at 31/32 (ERROR_CATALOGUE
//      §2). On every map this mod runs on, only the instant-pop branch of
//      microwavegun_sizzle_zombie is reachable (see 2), and that branch's whole
//      client job is one fx + one sound at the zombie - so the pop is
//      broadcast from the server here (zmqol_mgun_pop), like every other
//      broadcast effect in this mod. zapgun.csc carries the include_weapon
//      mirror only.
//   2. THE SWELL IS UNREACHABLE. The zm_death_sizzle / zm_death_zap animstates
//      live in Moon's aitypes; a stock aitype's compiled anim list cannot take
//      them (§45), so hasanimstatefromasd() is false everywhere here and the
//      original's own fallbacks run: the Wave Gun pops the zombie at once, the
//      Zap Guns kill with the normal death animation. The animstate code is
//      kept verbatim so the diff stays honest, not because it can fire.
//   3. NO VOICE LINES. Moon's kill/pickup vox ("micro_single", "micro_dual",
//      "wpck_microwave") are Moon-character aliases no stock map carries, so the
//      create_and_play_dialog calls are out and the pickup vox category is "".
//   4. THE BOSS HOOK AND THE SHIELD GUARD, like the three sibling guns: on Mob
//      the first hit takes Brutus's helmet, the second kills
//      (zm_prison.gsc zmqol_brutus_ww_hit); magic-bullet-shielded zombies are
//      left to their scripts.
//   5. THE DAMAGE-MOD TEST IS WIDER. Moon accepts the zap only as MOD_IMPACT.
//      Nothing here could measure what mod a retail projectile impact reports,
//      so any non-melee damage from a zap-gun def counts - the def cannot deal
//      any other kind, so the wider test cannot misfire.
//   6. The dev-only debug prints and the never-threaded microwavegun_sound_thread
//      are dropped.
//
//  🛑 MAP GATE: off on Buried and Origins, exactly like its three siblings
//  (teslagun.gsc's banner: those two sit at engine ceilings and adding more
//  crashes them). The gate MUST stay identical to zapgun.csc - a box weapon
//  included on one side only is the EXE_CLIENT_FIELD_MISMATCH class.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_score;

init()
{
    //  Same kill switch as the other three wonder weapons, same reason
    //  ("" or "1" = on, "5" = this gun alone; teslagun.gsc:26).
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW_UPGRADED" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUN" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUN_UPGRADED" );

    //  Moon's own registration (zm_moon.gsc decompile :897-898, :906, :1416):
    //  the box weapon is the dual pair; the left-hand halves come off the defs'
    //  DualWieldWeapon field and the combined gun off altWeapon, so neither is
    //  included on its own. The left-hand models are precached explicitly
    //  because _zm_magicbox::get_left_hand_weapon_model_name asks for them.
    include_weapon( "microwavegundw_zm" );
    include_weapon( "microwavegundw_upgraded_zm", 0 );
    add_limited_weapon( "microwavegundw_zm", 1 );   // lifted by NO BOX LIMITS like its siblings
    add_zombie_weapon( "microwavegundw_zm", "microwavegundw_upgraded_zm", &"ZOMBIE_WEAPON_MICROWAVEGUNDW", 10, "", "", undefined );

    precachemodel( getweaponmodel( "microwavegunlh_zm" ) );
    precachemodel( getweaponmodel( "microwavegunlh_upgraded_zm" ) );

    maps\mp\zombies\_zm_spawner::register_zombie_damage_callback( ::microwavegun_zombie_damage_response );
    maps\mp\zombies\_zm_spawner::register_zombie_death_animscript_callback( ::microwavegun_zombie_death_response );

    set_zombie_var( "microwavegun_cylinder_radius", 180 );
    set_zombie_var( "microwavegun_sizzle_range", 480 );

    //  The nine effects the server plays. All 28 of the family are mod.ff assets
    //  copied out of the DLC5 zone (zone_source\mod_wavegun.zone).
    level._effect["microwavegun_zap_shock_dw"]         = loadfx( "weapon/microwavegun/fx_zap_shock_dw" );
    level._effect["microwavegun_zap_shock_eyes_dw"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_dw" );
    level._effect["microwavegun_zap_shock_lh"]         = loadfx( "weapon/microwavegun/fx_zap_shock_lh" );
    level._effect["microwavegun_zap_shock_eyes_lh"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_lh" );
    level._effect["microwavegun_zap_shock_ug"]         = loadfx( "weapon/microwavegun/fx_zap_shock_ug" );
    level._effect["microwavegun_zap_shock_eyes_ug"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_ug" );
    level._effect["microwavegun_sizzle_blood_eyes"]    = loadfx( "weapon/microwavegun/fx_sizzle_blood_eyes" );
    level._effect["microwavegun_sizzle_death_mist"]    = loadfx( "weapon/microwavegun/fx_sizzle_mist" );
    level._effect["microwavegun_sizzle_death_mist_low_g"] = loadfx( "weapon/microwavegun/fx_sizzle_mist_low_g" );

    level._microwaveable_objects = [];

    //  Host sweep + connect loop, the bouncingbetty.gsc lesson: the host is
    //  "connected" before a root script's init() runs. Moon waits on
    //  "connecting" from its own map script, which runs earlier than we do.
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
        a_players[i] thread wait_for_microwavegun_fired();

    level thread microwavegun_on_player_connect();
}

add_microwaveable_object( ent )
{
    level._microwaveable_objects = add_to_array( level._microwaveable_objects, ent, 0 );
}

remove_microwaveable_object( ent )
{
    arrayremovevalue( level._microwaveable_objects, ent );
}

microwavegun_on_player_connect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread wait_for_microwavegun_fired();
    }
}

wait_for_microwavegun_fired()
{
    self endon( "disconnect" );
    self notify( "zmqol_wait_for_microwavegun_fired" );
    self endon( "zmqol_wait_for_microwavegun_fired" );
    self waittill( "spawned_player" );

    for ( ;; )
    {
        self waittill( "weapon_fired" );
        currentweapon = self getcurrentweapon();

        if ( currentweapon == "microwavegun_zm" || currentweapon == "microwavegun_upgraded_zm" )
            self thread microwavegun_fired( currentweapon == "microwavegun_upgraded_zm" );
    }
}

microwavegun_network_choke()
{
    level.microwavegun_network_choke_count++;

    if ( !( level.microwavegun_network_choke_count % 10 ) )
    {
        wait_network_frame();
        wait_network_frame();
        wait_network_frame();
    }
}

microwavegun_fired( upgraded )
{
    if ( !isdefined( level.microwavegun_sizzle_enemies ) )
    {
        level.microwavegun_sizzle_enemies = [];
        level.microwavegun_sizzle_vecs = [];
    }

    self microwavegun_get_enemies_in_range( upgraded, 0 );
    self microwavegun_get_enemies_in_range( upgraded, 1 );
    level.microwavegun_network_choke_count = 0;

    for ( i = 0; i < level.microwavegun_sizzle_enemies.size; i++ )
    {
        microwavegun_network_choke();
        level.microwavegun_sizzle_enemies[i] thread microwavegun_sizzle_zombie( self, level.microwavegun_sizzle_vecs[i], i );
    }

    level.microwavegun_sizzle_enemies = [];
    level.microwavegun_sizzle_vecs = [];
}

microwavegun_get_enemies_in_range( upgraded, microwaveable_objects )
{
    view_pos = self getweaponmuzzlepoint();
    test_list = undefined;
    range = level.zombie_vars["microwavegun_sizzle_range"];
    cylinder_radius = level.zombie_vars["microwavegun_cylinder_radius"];

    if ( microwaveable_objects )
    {
        test_list = level._microwaveable_objects;
        range = range * 10;
        cylinder_radius = cylinder_radius * 10;
    }
    else
        test_list = get_round_enemy_array();

    zombies = get_array_of_closest( view_pos, test_list, undefined, undefined, range );

    if ( !isdefined( zombies ) )
        return;

    sizzle_range_squared = range * range;
    cylinder_radius_squared = cylinder_radius * cylinder_radius;
    forward_view_angles = self getweaponforwarddir();
    end_pos = view_pos + vectorscale( forward_view_angles, range );

    for ( i = 0; i < zombies.size; i++ )
    {
        if ( !isdefined( zombies[i] ) || isai( zombies[i] ) && !isalive( zombies[i] ) )
            continue;

        test_origin = zombies[i] getcentroid();
        test_range_squared = distancesquared( view_pos, test_origin );

        //  The list is sorted nearest-first, so the first one out of range
        //  ends the walk - the original returns here too.
        if ( test_range_squared > sizzle_range_squared )
            return;

        normal = vectornormalize( test_origin - view_pos );
        dot = vectordot( forward_view_angles, normal );

        if ( 0 > dot )
            continue;

        radial_origin = pointonsegmentnearesttopoint( view_pos, end_pos, test_origin );

        if ( distancesquared( test_origin, radial_origin ) > cylinder_radius_squared )
            continue;

        if ( 0 == zombies[i] damageconetrace( view_pos, self ) )
            continue;

        if ( isai( zombies[i] ) )
        {
            level.microwavegun_sizzle_enemies[level.microwavegun_sizzle_enemies.size] = zombies[i];
            dist_mult = ( sizzle_range_squared - test_range_squared ) / sizzle_range_squared;
            sizzle_vec = vectornormalize( test_origin - view_pos );

            if ( 5000 < test_range_squared )
                sizzle_vec = sizzle_vec + vectornormalize( test_origin - radial_origin );

            sizzle_vec = ( sizzle_vec[0], sizzle_vec[1], abs( sizzle_vec[2] ) );
            sizzle_vec = vectorscale( sizzle_vec, 100 + 100 * dist_mult );
            level.microwavegun_sizzle_vecs[level.microwavegun_sizzle_vecs.size] = sizzle_vec;
            continue;
        }

        zombies[i] notify( "microwaved", self );
    }
}

microwavegun_sizzle_zombie( player, sizzle_vec, index )
{
    if ( !isdefined( self ) || !isalive( self ) )
        return;

    //  The boss hook first, exactly like the other three guns: on Mob the
    //  first hit takes Brutus's helmet, the second kills.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        if ( self [[ level.zmqol_ww_boss_hit ]]( player ) )
            return;
    }

    //  Scripted/shielded zombies are left to their scripts - same protection
    //  as the nuke, the kill-horde command and the Betty.
    if ( is_magic_bullet_shield_enabled( self ) )
        return;

    if ( isdefined( self.microwavegun_sizzle_func ) )
    {
        self [[ self.microwavegun_sizzle_func ]]( player );
        return;
    }

    self.no_gib = 1;
    self.gibbed = 1;
    self dodamage( self.health + 666, player.origin, player );

    if ( self.health <= 0 )
    {
        points = 10;

        if ( !index )
            points = maps\mp\zombies\_zm_score::get_zombie_death_player_points();
        else if ( 1 == index )
            points = 30;

        player maps\mp\zombies\_zm_score::player_add_points( "thundergun_fling", points );
        self.microwavegun_death = 1;
        instant_explode = 0;

        //  Kept verbatim from Moon. On this mod's maps no aitype knows
        //  zm_death_sizzle (§45), so every branch lands on instant_explode.
        if ( !self.isdog )
        {
            if ( self.has_legs )
            {
                if ( self hasanimstatefromasd( "zm_death_sizzle" ) )
                    self.deathanim = "zm_death_sizzle";
                else
                {
                    self.a.nodeath = undefined;
                    instant_explode = 1;
                }
            }
            else if ( self hasanimstatefromasd( "zm_death_sizzle_crawl" ) )
                self.deathanim = "zm_death_sizzle_crawl";
            else
            {
                self.a.nodeath = undefined;
                instant_explode = 1;
            }
        }
        else
        {
            self.a.nodeath = undefined;
            instant_explode = 1;
        }

        if ( is_true( self.is_traversing ) || is_true( self.in_the_ceiling ) )
        {
            self.deathanim = undefined;
            instant_explode = 1;
        }

        if ( instant_explode )
        {
            //  Moon: setclientfield( "zombie_actor_flag_microwavegun_expand_response", 1 )
            //  -> the client plays the mist at the spine and wpn_mgun_explode_zombie.
            //  Broadcast from here instead (banner point 1).
            self zmqol_mgun_pop();
            self thread microwavegun_sizzle_death_ending();
        }
        else
        {
            //  Moon: the initial-hit clientfield (eye fx + wpn_mgun_impact_zombie,
            //  which has no payload in any bank) and the swell driven by the
            //  death anim's notetracks. Unreachable here; the pop is served from
            //  the "explode" notetrack the same way for parity.
            self.nodeathragdoll = 1;
            self.handle_death_notetracks = ::microwavegun_handle_death_notetracks;
        }
    }
}

//  The server-side twin of Moon's client expand response: the sizzle mist at
//  J_SpineLower (J_Spine1 when the rig has no lower spine) and the pop sound.
//  Threaded fx call through the choke-safe helper; a rig missing both tags can
//  cost the garnish but never the kill above.
zmqol_mgun_pop()
{
    fx = level._effect["microwavegun_sizzle_death_mist"];

    if ( isdefined( self.in_low_g ) && self.in_low_g )
        fx = level._effect["microwavegun_sizzle_death_mist_low_g"];

    str_tag = "J_SpineLower";
    v_pos = self gettagorigin( str_tag );

    if ( !isdefined( v_pos ) )
    {
        str_tag = "J_Spine1";
        v_pos = self gettagorigin( str_tag );
    }

    if ( !isdefined( v_pos ) )
        v_pos = self getcentroid();

    playfx( fx, v_pos );
    self playsound( "wpn_mgun_explode_zombie" );
}

microwavegun_handle_death_notetracks( note )
{
    if ( note == "explode" )
    {
        self zmqol_mgun_pop();
        self thread microwavegun_sizzle_death_ending();
    }
}

microwavegun_sizzle_death_ending()
{
    if ( !isdefined( self ) )
        return;

    self ghost();
    wait 0.1;
    self self_delete();
}

microwavegun_dw_zombie_hit_response_internal( mod, damageweapon, player )
{
    player endon( "disconnect" );

    if ( !isdefined( self ) || !isalive( self ) )
        return;

    //  Boss hook and shield guard, as in the sizzle above.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        if ( self [[ level.zmqol_ww_boss_hit ]]( player ) )
            return;
    }

    if ( is_magic_bullet_shield_enabled( self ) )
        return;

    //  Kept verbatim from Moon; zm_death_zap is Moon-aitype only (§45), so on
    //  this mod's maps the zombie dies with its normal death animation.
    if ( !self.isdog )
    {
        if ( self.has_legs )
        {
            if ( self hasanimstatefromasd( "zm_death_zap" ) )
                self.deathanim = "zm_death_zap";
            else
                self.a.nodeath = undefined;
        }
        else if ( self hasanimstatefromasd( "zm_death_zap_crawl" ) )
            self.deathanim = "zm_death_zap_crawl";
        else
            self.a.nodeath = undefined;
    }
    else
        self.a.nodeath = undefined;

    if ( is_true( self.is_traversing ) )
        self.deathanim = undefined;

    self.microwavegun_dw_death = 1;
    self thread microwavegun_zap_death_fx( damageweapon );

    if ( isdefined( self.microwavegun_zap_damage_func ) )
    {
        self [[ self.microwavegun_zap_damage_func ]]( player );
        return;
    }
    else
        self dodamage( self.health + 666, self.origin, player );

    player maps\mp\zombies\_zm_score::player_add_points( "death", "", "" );
}

microwavegun_zap_get_shock_fx( weapon )
{
    if ( weapon == "microwavegundw_zm" )
        return level._effect["microwavegun_zap_shock_dw"];
    else if ( weapon == "microwavegunlh_zm" )
        return level._effect["microwavegun_zap_shock_lh"];
    else
        return level._effect["microwavegun_zap_shock_ug"];
}

microwavegun_zap_get_shock_eyes_fx( weapon )
{
    if ( weapon == "microwavegundw_zm" )
        return level._effect["microwavegun_zap_shock_eyes_dw"];
    else if ( weapon == "microwavegunlh_zm" )
        return level._effect["microwavegun_zap_shock_eyes_lh"];
    else
        return level._effect["microwavegun_zap_shock_eyes_ug"];
}

microwavegun_zap_head_gib( weapon )
{
    self endon( "death" );
    network_safe_play_fx_on_tag( "microwavegun_zap_death_fx", 2, microwavegun_zap_get_shock_eyes_fx( weapon ), self, "J_Eyeball_LE" );
}

microwavegun_zap_death_fx( weapon )
{
    tag = "J_SpineUpper";

    if ( self.isdog )
        tag = "J_Spine1";

    network_safe_play_fx_on_tag( "microwavegun_zap_death_fx", 2, microwavegun_zap_get_shock_fx( weapon ), self, tag );
    self playsound( "wpn_imp_tesla" );

    if ( is_true( self.head_gibbed ) )
        return;

    if ( isdefined( self.microwavegun_zap_head_gib_func ) )
        self thread [[ self.microwavegun_zap_head_gib_func ]]( weapon );
    else if ( "quad_zombie" != self.animname )
        self thread microwavegun_zap_head_gib( weapon );
}

microwavegun_zombie_damage_response( mod, hit_location, hit_origin, player, amount )
{
    if ( self is_microwavegun_dw_damage() )
    {
        self thread microwavegun_dw_zombie_hit_response_internal( mod, self.damageweapon, player );
        return true;
    }

    return false;
}

microwavegun_zombie_death_response()
{
    if ( self enemy_killed_by_dw_microwavegun() )
        return true;
    else if ( self enemy_killed_by_microwavegun() )
        return true;

    return false;
}

//  Banner point 5: Moon tests self.damagemod == "MOD_IMPACT"; any non-melee
//  damage from a zap-gun def counts here.
is_microwavegun_dw_damage()
{
    return isdefined( self.damageweapon ) && ( self.damageweapon == "microwavegundw_zm" || self.damageweapon == "microwavegundw_upgraded_zm" || self.damageweapon == "microwavegunlh_zm" || self.damageweapon == "microwavegunlh_upgraded_zm" ) && ( !isdefined( self.damagemod ) || self.damagemod != "MOD_MELEE" );
}

enemy_killed_by_dw_microwavegun()
{
    return is_true( self.microwavegun_dw_death );
}

is_microwavegun_damage()
{
    return isdefined( self.damageweapon ) && ( self.damageweapon == "microwavegun_zm" || self.damageweapon == "microwavegun_upgraded_zm" ) && ( self.damagemod != "MOD_GRENADE" && self.damagemod != "MOD_GRENADE_SPLASH" );
}

enemy_killed_by_microwavegun()
{
    return is_true( self.microwavegun_death );
}
