// ============================================================================
//  zapgun.gsc  -  THE BO1 ZAP GUNS (DUAL-WIELD), IN THE BOX      (v2.9.18)
// ----------------------------------------------------------------------------
//  Queue item 35, approved by the user 2026-08-31 after the audit in
//  .agents\WAVEGUN_TARGET_INVENTORY.md. The COMBINED Wave Gun is not buildable
//  on this machine - its model exists only in T5 form, OAT links no raw xmodel
//  and takes no T5 donor (both measured, checkpoint 173 §4) - so per the
//  "perfectly or not at all" rule the split Zap Guns ship as a complete
//  feature in themselves and nothing pretends to be the combined gun.
//
//  WHAT EACH PIECE IS AND WHERE IT CAME FROM (nothing invented):
//    defs      weapons\zm\zapgun_{dw,le}[_upgraded]_zm - the zm_ezz3.0
//              package's converted defs, re-tuned to BO1's OWN numbers read
//              out of zombie_moon.ff's microwavegundw defs: clip 8 / 64 ammo,
//              12 / 100 upgraded, fireTime 0.32. Dual-wield is stock T6
//              plumbing (DualWieldWeapon\zapgun_le_zm, the fivesevendw shape).
//              All four measured under the 20,480 B raw-def loader ceiling.
//    models    the donor's 4 converted xmodels via zone_source\zapgun_donor
//              (19-asset minimal fastfile - see mod_zapgun.zone for why the
//              full donor is untouchable).
//    anims     15 raw xanims in xanim\, the exact set the defs reference -
//              raw xanims load from a mod's iwd (proven by the ezz package).
//    fx        the donor's muzzle flashes and impacts as raw .efx, plus BO1's
//              own tesla shock-eyes effect for the kill, which this mod
//              already ships (fx\maps\zombie\fx_zombie_tesla_shock_eyes.efx).
//              BO1's zap_shock_eyes_* effects exist nowhere obtainable - OAT
//              is blind to fx in both directions - and the tesla shock-eyes is
//              the same BO1 electric-kill family the zap deaths share their
//              animations with, so it is the closest genuine asset, not a
//              fabrication.
//    sounds    the donor's own aliases and payloads (zapgun_fire_* etc.),
//              measured to collide with NOTHING - zero hits across the full
//              alias universe - so mod.all carrying them obeys the sound
//              rules (mod-added gun, no bank covers it).
//    names     BO1's own localize keys, read from its defs
//              (ZOMBIE_WEAPON_MICROWAVEGUNDW / _UPGRADED); strings in mod.str.
//
//  THE KILL LOGIC IS BO1'S OWN, PORTED. maps\_zombiemode_weap_microwavegun.gsc
//  (BO1 raw, readable on this machine) kills each zap hit outright:
//  tesla-family death anim, shock fx on the zombie, DoDamage(health + 666).
//  T6 has no register_zombie_damage_callback, so the hit is caught the way
//  BO2's own Origins staffs catch theirs: the PLAYER's "projectile_impact"
//  notify (verified: _zm_weap_staff_air.gsc:77 binds weapon name + explode
//  point from it), then the nearest zombie to the bolt takes BO1's response.
//
//  🛑 MAP GATE: off on Buried and Origins, exactly like its three siblings
//  (teslagun.gsc's banner: those two sit at engine ceilings and adding more
//  crashes them). The gate MUST stay identical to the client include in
//  zm_expanded.csc - a box weapon included on one side only is the
//  EXE_CLIENT_FIELD_MISMATCH class.
// ============================================================================
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
//  network_safe_play_fx_on_tag - the choke-safe fx call BO1's own zap death
//  dressing uses (its T6 home is _zm_net). Globally safe per hard rule 2.
#include maps\mp\zombies\_zm_net;
// common_scripts\utility supplies get_players() and is_true() - without it the
// load-time resolver threw 'Unresolved external' on every map (caught on the
// first v2.9.20 boot, Mob of the Dead, 2026-08-31). Globally safe per hard
// rule 2; the three sibling gun files simply never call these two helpers.
#include common_scripts\utility;

init()
{
    //  Same kill switch as the other three wonder weapons, same reason.
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW_UPGRADED" );

    precacheitem( "zapgun_dw_zm" );
    precacheitem( "zapgun_dw_upgraded_zm" );
    precacheitem( "zapgun_le_zm" );
    precacheitem( "zapgun_le_upgraded_zm" );

    include_weapon( "zapgun_dw_zm" );
    add_limited_weapon( "zapgun_dw_zm", 1 );   // lifted by NO BOX LIMITS like its siblings
    add_zombie_weapon( "zapgun_dw_zm", "zapgun_dw_upgraded_zm", &"ZOMBIE_WEAPON_MICROWAVEGUNDW", 10, "", "", undefined );

    //  The left-hand halves exist but are never a box result themselves -
    //  the engine hands them out through DualWieldWeapon. Same include shape
    //  the box uses for every non-box variant.
    include_weapon( "zapgun_le_zm", 0 );
    include_weapon( "zapgun_le_upgraded_zm", 0 );

    level._effect["zapgun_impact"]     = loadfx( "misc/fx_exp_zapgun_impact" );
    level._effect["zapgun_shock_eyes"] = loadfx( "maps/zombie/fx_zombie_tesla_shock_eyes" );
    //  The body-arc shock, loaded by this module itself (v2.9.28) so the death
    //  dressing no longer depends on the Wunderwaffe module having run - the
    //  fx asset is mod.ff-owned, resident on every map this script allows.
    level._effect["zapgun_shock"]      = loadfx( "maps/zombie/fx_zombie_tesla_shock" );

    //  Host sweep + connect loop, the bouncingbetty.gsc lesson: the host is
    //  "connected" before a root script's init() runs.
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
        a_players[i] thread zmqol_zapgun_impact_watch();

    level thread zmqol_zapgun_onplayerconnect();
}

zmqol_zapgun_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_zapgun_impact_watch();
    }
}

zmqol_is_zapgun( str_weapon )
{
    return isdefined( str_weapon ) &&
           ( str_weapon == "zapgun_dw_zm" || str_weapon == "zapgun_dw_upgraded_zm" ||
             str_weapon == "zapgun_le_zm" || str_weapon == "zapgun_le_upgraded_zm" );
}

zmqol_zapgun_impact_watch()
{
    self endon( "disconnect" );
    self notify( "zmqol_zapgun_impact_watch" );
    self endon( "zmqol_zapgun_impact_watch" );

    for (;;)
    {
        self waittill( "projectile_impact", str_weapon, v_point );

        if ( !zmqol_is_zapgun( str_weapon ) )
            continue;

        self thread zmqol_zapgun_zap( v_point, str_weapon );
    }
}

//  One bolt, one kill: the nearest live reachable zombie to the impact point.
//  120 units - between the staffs' blast radii and BO1's own melee-ish arc -
//  is deliberately tight: the zap guns are precision wonder weapons, not the
//  thundergun.
zmqol_zapgun_zap( v_point, str_weapon )
{
    a_zombies = getaispeciesarray( level.zombie_team, "all" );

    if ( !isdefined( a_zombies ) )
        return;

    e_best = undefined;
    n_best = 120 * 120;

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isdefined( a_zombies[i] ) || !isalive( a_zombies[i] ) )
            continue;

        n_d = distancesquared( a_zombies[i] getcentroid(), v_point );

        if ( n_d < n_best )
        {
            n_best = n_d;
            e_best = a_zombies[i];
        }
    }

    if ( !isdefined( e_best ) )
        return;

    e_best thread zmqol_zapgun_kill( self, str_weapon );
}

//  BO1's microwavegun_dw_zombie_hit_response_internal, in T6 terms.
zmqol_zapgun_kill( e_player, str_weapon )
{
    if ( !isdefined( self ) || !isalive( self ) )
        return;

    //  The boss hook first, exactly like the other three guns: on Mob the
    //  first hit takes Brutus's helmet, the second kills.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        if ( self [[ level.zmqol_ww_boss_hit ]]( e_player ) )
            return;
    }

    //  Scripted/shielded zombies are left to their scripts - same protection
    //  as the nuke, the kill-horde command and the Betty.
    if ( is_magic_bullet_shield_enabled( self ) )
        return;

    //  BO1 picks from the tesla death anim family; the T6 port of that family
    //  is the zm_death_tesla_t5 state the wonder-weapon package put on the
    //  per-map basic ASDs, and the same degrade rule as the Wunderwaffe
    //  applies: an AI whose rig lacks the state just dies normally.
    if ( !( isdefined( self.isdog ) && self.isdog ) &&
         isdefined( self.has_legs ) && self.has_legs &&
         self hasanimstatefromasd( "zm_death_tesla_t5" ) &&
         !is_true( self.is_traversing ) )
        self.deathanim = "zm_death_tesla_t5";

    self.microwavegun_dw_death = 1;

    //  v2.9.28 - BO1'S OWN DEATH SEQUENCE, re-measured from BO1 raw this
    //  session (_zombiemode_weap_microwavegun.gsc:522-547) instead of
    //  inherited from the Wunderwaffe port: body shock on J_SpineUpper
    //  (J_Spine1 for dogs) + "wpn_imp_tesla" + the shock-eyes fx on EVERY
    //  non-quad that still has its head. 🌟 BO1's "microwavegun_zap_head_gib"
    //  only plays the eyes fx - it never gibs the model - so the waffe's 75%
    //  head-gib roll was the waffe's own dressing, not the zap guns', and the
    //  delegation to tesla_play_death_fx is gone. The literal Moon fx
    //  (fx_zap_shock_dw / _eyes_dw) are unobtainable on this machine, all
    //  three routes measured 2026-09-01: OAT dumps no T5 fx from
    //  zombie_moon.ff, BO1's raw\fx ships no weapon\microwavegun folder, and
    //  the ezz package carries only the tesla-family shocks. The body arc is
    //  therefore BO1's tesla shock - the family Moon shares its zap death
    //  anims with - which is the closest genuine asset, not a fabrication.
    //  Threaded exactly like BO1 threads its dressing, so a rig missing a tag
    //  can cost the garnish but never the kill below.
    self thread zmqol_zapgun_death_dressing();

    if ( isdefined( e_player ) && isalive( e_player ) )
        self dodamage( self.health + 666, self.origin, e_player );
    else
        self dodamage( self.health + 666, self.origin );
}

//  BO1's microwavegun_zap_death_fx + microwavegun_zap_head_gib, in T6 terms.
zmqol_zapgun_death_dressing()
{
    self endon( "death" );

    str_tag = "J_SpineUpper";

    if ( isdefined( self.isdog ) && self.isdog )
        str_tag = "J_Spine1";

    network_safe_play_fx_on_tag( "zapgun_death_fx", 2, level._effect["zapgun_shock"], self, str_tag );
    self playsound( "wpn_imp_tesla" );

    if ( isdefined( self.animname ) && self.animname == "quad_zombie" )
        return;

    if ( is_true( self.head_gibbed ) )
        return;

    network_safe_play_fx_on_tag( "zapgun_death_fx", 2, level._effect["zapgun_shock_eyes"], self, "J_Eyeball_LE" );
}
