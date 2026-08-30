// ============================================================================
//  bouncingbetty.gsc  -  THE MP BOUNCING BETTY, PORTED INTO ZOMBIES   (v2.9.9)
//
//  User directive 2026-08-30 (task 4): the multiplayer Bouncing Betty in the
//  mystery box, occupying the placed-equipment slot the way it does in MP.
//
//  📝 It lands in the PLACEABLE-MINE slot - the exact slot zombies' own
//  claymores use (actionslot 4, set_player_placeable_mine, planted with the
//  mine button). That IS the zombies equivalent of MP's lethal slot for a
//  planted mine: stock's weapon_give already swaps mines for each other, so
//  buying betties hands back your claymores and vice versa, exactly like MP's
//  one-lethal-at-a-time. Frag/semtex stay untouched - registering a PLANTED
//  mine as a THROWN lethal would put it through the cook-and-throw code path,
//  which is wrong in the hand and wrong in the def.
//
//  Every mechanism below is a measured clone, not a design:
//    - the plant/watch flow is stock's _zm_weap_claymore::claymore_watch/
//      claymore_setup (Tranzit dump), name-swapped;
//    - the proximity/detonation is claymore_detonation() with the cone test
//      REMOVED - MP's watcher sets ignoredirection=1 for the betty
//      (maps\mp\_bouncingbetty.gsc:42), it triggers all-round;
//    - the jump-and-explode is MP's own spawnminemover()/
//      bouncingbettyjumpandexplode()/mineexplode(), killcam plumbing dropped
//      (no killcam in zombies), numbers verbatim: jump 65 units over 0.65s,
//      rotatevelocity (0,750,32), damage 256/210/70;
//    - the green owner light is what MP's client half draws
//      (_bouncingbetty.csc:38, fx on tag_origin) - played server-side here,
//      the same way this mod plays every other broadcast fx.
//
//  🔊 SOUND, stated honestly: the explosion plays wpn_grenade_explode, which
//  is measured to be the SAME payload family fly_betty_explo points at
//  (its FileSource is raw\sound\wpn\grenade\explosion\explode\explode_00) and
//  it resolves on all 7 zombies bank sets. The deploy foley and the spring
//  "chunk" (betty_deploy / betty_trigger) live only inside mpl_common.all.sabl
//  and OpenAssetTools cannot unpack those two payloads ("Could not find data",
//  measured 2026-08-30), so fly_betty_plant_plr / fly_betty_jump are played
//  here but are silent until someone extracts the two payloads with the
//  GUI-only Sound Studio - at which point two CSV rows make them audible with
//  no code change. A silent plant is also exactly what stock's own zombies
//  claymore has (fly_claymore_plant_plr is a stock dangler, checkpoint 159 §6).
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

init()
{
    precacheitem( "bouncingbetty_zm" );
    precachemodel( "t6_wpn_bouncing_betty_world" );

    level._effect["betty_explosion"] = loadfx( "weapon/bouncing_betty/fx_betty_explosion" );
    level._effect["betty_launch"] = loadfx( "weapon/bouncing_betty/fx_betty_launch_dust" );
    level._effect["betty_light"] = loadfx( "weapon/bouncing_betty/fx_betty_light_green" );

    //  MP's own tuning block, maps\mp\_bouncingbetty.gsc:16-27, verbatim.
    level.zmqol_betty_radius = 192;
    level.zmqol_betty_mindist = 20;
    level.zmqol_betty_damage_radius = 256;
    level.zmqol_betty_damage_max = 210;
    level.zmqol_betty_damage_min = 70;
    level.zmqol_betty_jump_height = 65;
    level.zmqol_betty_jump_time = 0.65;
    level.zmqol_betty_rotate_velocity = ( 0, 750, 32 );
    level.zmqol_betty_activation_delay = 0.1;
    level.zmqol_betty_max_per_player = 12;

    //  Box registration - the same pair every ported gun uses. weapon_give's
    //  own is_placeable_mine branch then handles the slot swap with claymores.
    //  Stock's own mine registrar - this is what makes weapon_give's
    //  is_placeable_mine branch swap it with claymores, one mine type at a time.
    maps\mp\zombies\_zm_utility::register_placeable_mine_for_level( "bouncingbetty_zm" );

    include_weapon( "bouncingbetty_zm" );
    add_zombie_weapon( "bouncingbetty_zm", undefined, &"ZMWEAPON_BOUNCINGBETTY", 1000, "", "", undefined );

    level thread zmqol_betty_onplayerconnect();
}

zmqol_betty_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_betty_watch();
    }
}

//  claymore_watch(), name-swapped. grenade_fire is the engine's plant notify
//  for every weaponType "grenade" offhand, claymores included.
zmqol_betty_watch()
{
    self endon( "disconnect" );
    self notify( "zmqol_betty_watch" );
    self endon( "zmqol_betty_watch" );

    if ( !isdefined( self.zmqol_betties ) )
        self.zmqol_betties = [];

    for (;;)
    {
        self waittill( "grenade_fire", betty, weapname );

        if ( weapname != "bouncingbetty_zm" )
            continue;

        betty.owner = self;
        betty.team = self.team;

        if ( self.zmqol_betties.size >= level.zmqol_betty_max_per_player )
        {
            //  claymore_safe_to_plant()'s over-cap ending: it detonates.
            betty thread zmqol_betty_wait_and_detonate();
            continue;
        }

        self.zmqol_betties[self.zmqol_betties.size] = betty;
        betty thread zmqol_betty_proximity();
        betty thread zmqol_betty_light();
    }
}

zmqol_betty_wait_and_detonate()
{
    wait 0.1;
    self detonate( self.owner );
}

//  The owner light, MP's client draw done server-side: green fx on tag_origin
//  once the mine settles.
zmqol_betty_light()
{
    self endon( "death" );
    self waittill_not_moving();
    playfxontag( level._effect["betty_light"], self, "tag_origin" );
}

//  claymore_detonation() with the betty's ending. Differences, each measured:
//  no damageconetrace/cone test (MP betty ignoredirection=1), radius 192
//  (level.bettyradius), and instead of self detonate() the MP jump-and-explode
//  sequence runs on a stand-in model, because a planted grenade entity cannot
//  be moveto'd - which is exactly why MP spawns its minemover.
zmqol_betty_proximity()
{
    self endon( "death" );
    self waittill_not_moving();

    r = level.zmqol_betty_radius;
    damagearea = spawn( "trigger_radius", self.origin + ( 0, 0, 0 - r ), 4, r, r * 2 );
    damagearea setexcludeteamfortrigger( self.team );
    damagearea enablelinkto();
    damagearea linkto( self );
    self.zmqol_damagearea = damagearea;
    self thread zmqol_betty_cleanup_on_death( self.owner, damagearea );

    for (;;)
    {
        damagearea waittill( "trigger", ent );

        if ( isdefined( self.owner ) && ent == self.owner )
            continue;

        if ( isdefined( ent.pers ) && isdefined( ent.pers["team"] ) && ent.pers["team"] == self.team )
            continue;

        if ( !isdefined( ent.origin ) )
            continue;

        //  MP's detectionmindist: something standing ON the mine still sets
        //  it off; only sub-20-unit overlap right at the plant is ignored.
        if ( distance( ent.origin, self.origin ) < level.zmqol_betty_mindist )
            continue;

        break;
    }

    //  Armed. The alert alias is played for parity with the claymore's own
    //  code path; note it is a stock dangler in every zombies bank.
    self playsound( "wpn_claymore_alert" );
    wait( level.zmqol_betty_activation_delay );

    if ( !isdefined( self ) )
        return;

    //  --- MP's spawnminemover + bouncingbettyjumpandexplode, killcam dropped ---
    owner = self.owner;
    org = self.origin;
    angles = self.angles;
    minemover = spawn( "script_model", org );
    minemover.angles = angles;
    minemover setmodel( "t6_wpn_bouncing_betty_world" );

    if ( isdefined( damagearea ) )
        damagearea delete();

    if ( isdefined( owner ) && isdefined( owner.zmqol_betties ) )
        arrayremovevalue( owner.zmqol_betties, self );

    self delete();

    explodepos = org + ( 0, 0, level.zmqol_betty_jump_height );
    minemover moveto( explodepos, level.zmqol_betty_jump_time, level.zmqol_betty_jump_time, 0 );
    playfx( level._effect["betty_launch"], org );
    minemover rotatevelocity( level.zmqol_betty_rotate_velocity, level.zmqol_betty_jump_time, 0, level.zmqol_betty_jump_time );
    minemover playsound( "fly_betty_jump" );
    wait( level.zmqol_betty_jump_time );

    if ( !isdefined( minemover ) )
        return;

    //  --- MP's mineexplode ---
    minemover playsound( "wpn_grenade_explode" );
    wait 0.05;

    if ( !isdefined( minemover ) )
        return;

    minemover hide();
    playfx( level._effect["betty_explosion"], minemover.origin );

    if ( isdefined( owner ) )
        minemover radiusdamage( minemover.origin, level.zmqol_betty_damage_radius, level.zmqol_betty_damage_max, level.zmqol_betty_damage_min, owner, "MOD_EXPLOSIVE", "bouncingbetty_zm" );
    else
        minemover radiusdamage( minemover.origin, level.zmqol_betty_damage_radius, level.zmqol_betty_damage_max, level.zmqol_betty_damage_min, undefined, "MOD_EXPLOSIVE", "bouncingbetty_zm" );

    wait 0.2;

    if ( isdefined( minemover ) )
        minemover delete();
}

//  delete_claymores_on_death(), name-swapped: the trigger dies with the mine
//  and the owner's book-keeping stays truthful.
zmqol_betty_cleanup_on_death( player, area )
{
    self waittill( "death" );

    if ( isdefined( player ) && isdefined( player.zmqol_betties ) )
        arrayremovevalue( player.zmqol_betties, self );

    wait 0.05;

    if ( isdefined( area ) )
        area delete();
}
