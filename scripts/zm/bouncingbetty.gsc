// ============================================================================
//  bouncingbetty.gsc  -  THE MP BOUNCING BETTY, PORTED INTO ZOMBIES   (v2.9.9)
//
//  User directive 2026-08-30 (task 4): the multiplayer Bouncing Betty in the
//  mystery box. Revised the same night: **a pure ADDITION - it replaces
//  nothing.** ("the bouncing betty needs to be an addition, not a
//  replacement... claymores need to be the same as usual.")
//
//  📝 HOW IT COEXISTS WITH EVERYTHING, each point measured:
//    - It is deliberately NOT registered with
//      register_placeable_mine_for_level: that registry is what makes
//      weapon_give's is_placeable_mine branch take your claymores away
//      (one-mine-at-a-time). Claymores keep their slot, their D-pad 4 bind
//      and their ammo, untouched.
//    - The give goes through stock's own per-weapon hook,
//      level.zombie_weapons_callbacks (_zm_weapons.gsc:2448) - the
//      data-driven form of the hardcoded claymore_zm case right above it -
//      so the generic give path never runs for this weapon at all.
//    - Betties bind to D-pad 2 (also key `2` on PC - read out of the user's own
//      bindings_zm.bdg: actionslot 1/2/3/4 = DPAD_UP/DOWN/LEFT/RIGHT = 8/2/5/X).
//      🛑 CORRECTED v2.9.11: slot 2 is NOT free on every map. Stock binds it on
//      Buried (_zm_weap_time_bomb.gsc:2043,2055 - the Time Bomb and its
//      detonator) and on Origins (zm_tomb_craftables.gsc:1075 - the Maxis
//      drone). See zmqol_betty_slot_free() for how that is handled without
//      breaking either of those stock items.
//    - 🛑 CORRECTED v2.9.11: the old claim that "the def is inventoryType item
//      so weapon_give's takeweapon can never fire for it" was BACKWARDS.
//      is_offhand_weapon() (_zm_utility.gsc:3523) reads nothing off the def -
//      it is five list lookups (lethal / tactical / placeable mine / melee /
//      equipment), and this weapon is deliberately in none of them, so it
//      returned FALSE and the at-limit `takeweapon( current_weapon )` at
//      _zm_weapons.gsc:2414 DID fire: boxing a Betty on two guns cost you a
//      gun. main() now replaces is_offhand_weapon so it answers truthfully for
//      this weapon, which is what the safety argument assumed all along.
//
//  🛑 v2.9.32 - WHY NO BETTY EVER DETONATED BEFORE THIS VERSION: the def
//  shipped `plantable 0` from day one, deviating from BOTH working precedents
//  on exactly that flag (MP's bouncingbetty_mp = 1, stock claymore_zm = 1;
//  field-diffed against the T6-Data-Archive dumps). Every watcher below waits
//  in waittill_not_moving(), which for a grenade ent is waittill("stationary")
//  - the settle notify of a PLANTED grenade. A non-plantable sticky projectile
//  sits visibly on the ground (engine stickiness, no script needed) while the
//  light, proximity and shot threads all hang on that wait forever - the
//  measured v2.9.31 symptom set exactly. The def now says plantable 1 =
//  byte-parity with the MP donor on every behavioral field. Suspected-not-
//  proven half, stated honestly: that "stationary" is withheld for stuck
//  non-plantable grenades cannot be confirmed offline - the probe printlns
//  below turn the next boot into the proof either way.
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

//  🛑 v2.9.11 - THE ONE HOOK THIS FEATURE NEEDS, and why it is safe.
//
//  is_offhand_weapon() is not a property of the weapon def - it is five list
//  lookups, and a weapon that is deliberately in none of those lists (which is
//  exactly what keeps claymores untouched) answers "no". weapon_give then
//  treats the Betty as a gun: it takes your held weapon at the 2-gun limit
//  (:2414), takes your fallback weapon (:2404), and switches you to it (:2470).
//  All three are wrong for a piece of equipment.
//
//  Every stock caller was read before replacing it - there are only eight:
//    _zm_weapons.gsc:2359 2404 2414 2470   the four above, all now correct
//    _zm_weapons.gsc:2531  ammo_give       Max Ammo skips it, as it does claymores
//    _zm_magicbox.gsc:238                  box prompt reads "swap for EQUIPMENT" ✅
//    _zm_laststand.gsc:244                 going down mid-plant matches the claymore
//    _zm_devgui.gsc:89                     dev only
//  Answering "yes" is the truthful answer at all eight.
//
//  📝 In main(), not init(), per CLAUDE.md section 4 failure mode 4.
main()
{
    replaceFunc( maps\mp\zombies\_zm_utility::is_offhand_weapon, ::zmqol_is_offhand_weapon );
}

zmqol_is_offhand_weapon( weaponname )
{
    if ( isdefined( weaponname ) && weaponname == "bouncingbetty_zm" )
        return 1;

    //  stock _zm_utility.gsc:3523, verbatim
    return is_lethal_grenade( weaponname ) || is_tactical_grenade( weaponname ) || is_placeable_mine( weaponname ) || is_melee_weapon( weaponname ) || is_equipment( weaponname );
}

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

    //  🛑 v2.9.10 - PURE ADDITION, NOTHING REPLACED. The give runs through
    //  stock's zombie_weapons_callbacks hook instead of the mine registry;
    //  see the banner for the whole safety argument.
    if ( !isdefined( level.zombie_weapons_callbacks ) )
        level.zombie_weapons_callbacks = [];

    level.zombie_weapons_callbacks["bouncingbetty_zm"] = ::zmqol_betty_setup;

    include_weapon( "bouncingbetty_zm" );
    add_zombie_weapon( "bouncingbetty_zm", undefined, &"ZMWEAPON_BOUNCINGBETTY", 1000, "", "", undefined );

    level thread zmqol_betty_onplayerconnect();
    level thread zmqol_claymore_shot_connect();
}

//  ============================================================================
//  v2.9.16 - CLAYMORES DETONATE WHEN SHOT OR CAUGHT IN A BLAST, user request
//  2026-08-31 ("Enable damage triggers for both Bouncing Betties and Claymores
//  so they detonate when shot by weapons or triggered by nearby explosions").
//
//  Nothing of stock's claymore is replaced. Every planted claymore already
//  fires the engine's "grenade_fire" notify on its planter, so this listens
//  from the outside, marks the planted ent damageable, and calls stock's own
//  detonate() when anything hurts it. The kill scaling needs no help here:
//  claymore_zm IS a registered placeable mine, so _zm_spawner's damage handler
//  gives every zombie it catches the round * randomintrange( 100, 200 ) bonus
//  on its own. And because a damageable ent receives radiusdamage, one
//  explosion chains into the next mine - betties included, both directions.
//  ============================================================================
zmqol_claymore_shot_connect()
{
    //  The host is already "connected" before a root script's init() runs (the
    //  lesson written over zmqol_betty_setup above), and unlike the Betty there
    //  is no per-give hook to catch them later - so sweep whoever is already
    //  in first. The notify/endon pair in the watch makes double-threading a
    //  no-op for anyone caught by both paths.
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
        a_players[i] thread zmqol_claymore_shot_watch();

    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_claymore_shot_watch();
    }
}

zmqol_claymore_shot_watch()
{
    self endon( "disconnect" );
    self notify( "zmqol_claymore_shot_watch" );
    self endon( "zmqol_claymore_shot_watch" );

    for (;;)
    {
        self waittill( "grenade_fire", clay, weapname );

        if ( weapname != "claymore_zm" )
            continue;

        clay thread zmqol_claymore_damage_think( self );
    }
}

zmqol_claymore_damage_think( player )
{
    self endon( "death" );
    self waittill_not_moving();

    if ( !isdefined( self ) )
        return;

    //  v2.9.32 - health first, per stock satchel_damage; see the betty watch.
    self.health = 100000;
    self setcandamage( 1 );
    self waittill( "damage", n_amount, e_attacker );

    if ( !isdefined( self ) )
        return;

    if ( isdefined( player ) )
        self detonate( player );
    else
        self detonate();
}

//  The give itself - claymore_setup minus the two lines that make claymores
//  exclusive (set_player_placeable_mine and actionslot 4). Runs as the
//  zombie_weapons_callbacks hook, threaded on the PLAYER by weapon_give, which
//  also plays the weapon vo and returns before the generic give.
zmqol_betty_setup()
{
    //  Stock's claymore_setup threads its own watcher on every give rather than
    //  relying on a connect loop, and for a good reason: the host is already
    //  "connected" before a root script's init() runs, so the loop below can
    //  miss them. The notify/endon pair at the top of the watch makes a second
    //  thread cancel the first, so this is idempotent.
    self thread zmqol_betty_watch();

    self giveweapon( "bouncingbetty_zm" );

    if ( self zmqol_betty_slot_free() )
        self setactionslot( 2, "weapon", "bouncingbetty_zm" );

    self setweaponammostock( "bouncingbetty_zm", 2 );
}

//  🛑 THE ACTION-SLOT MAP, measured from the stock dump, not assumed:
//     slot 1  equipment and craftables - turbine, gas mask, drone, headchopper
//     slot 2  Buried's Time Bomb + detonator (_zm_weap_time_bomb.gsc:2043,2055)
//             and Origins' Maxis drone (zm_tomb_craftables.gsc:1075).
//             FREE on TranZit, Die Rise, Nuketown and Mob of the Dead.
//     slot 3  "altMode" on every map (_zm.gsc:1320) + Origins' revive staff
//     slot 4  the claymore, on every map
//  There is no fifth slot, so on Buried and Origins the Betty and one stock
//  item genuinely want the same button. The Betty gives way: if the player
//  already holds that map's slot-2 item the bind is skipped and the Betty sits
//  in the inventory unbound, rather than silently disabling a stock feature.
//  The other order (Betty first, Time Bomb built later) resolves itself the
//  same way round - stock re-binds slot 2 and the Betty goes quiet.
zmqol_betty_slot_free()
{
    if ( level.script == "zm_buried" )
        return !self hasweapon( "time_bomb_zm" ) && !self hasweapon( "time_bomb_detonator_zm" );

    if ( level.script == "zm_tomb" )
        return !self hasweapon( "equip_dieseldrone_zm" );

    return 1;
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

        //  v2.9.16 - SHOOTABLE, user request 2026-08-31: "Enable damage
        //  triggers ... so they detonate when shot by weapons or triggered by
        //  nearby explosions." MP's own mines do exactly this (setcandamage +
        //  a damage watcher); radiusdamage from any other blast also lands on
        //  a damageable ent, so one mine going off sets off its neighbours.
        //  v2.9.32 - health first, stock's own satchel_damage order
        //  (_zm_weap_claymore.gsc:379-381): a damageable ent with default
        //  health can be KILLED by the shot instead of receiving "damage",
        //  and endon("death") then eats the watcher with no detonation.
        betty.health = 100000;
        betty setcandamage( 1 );
        betty thread zmqol_betty_shot_watch();

        //  v2.9.32 probe: user planted two betties (v2.9.31 boot) and neither
        //  proximity nor gunfire set them off. These lines make the next log
        //  say exactly which stage died. Remove once detonation is confirmed.
        println( "[zm_qol] betty: plant caught (grenade_fire), waiting to settle" );
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

    println( "[zm_qol] betty: settled, proximity trigger up at " + self.origin );

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

        //  🛑 v2.9.16 - FIRE AT CLAYMORE RANGE, NOT AT THE TRIGGER'S RIM.
        //  User: "Fix Bouncing Betty proximity triggers so zombies reliably
        //  detonate them when stepping over them." The old loop broke on the
        //  FIRST trigger notify, which for a walking zombie is the moment it
        //  crosses the 192-unit boundary - so the mine jumped while the zombie
        //  was still ~16 feet away and the blast caught nothing. A touching
        //  entity re-notifies every server frame, which is exactly how stock's
        //  own claymore_detonation() re-tests its cone - so waiting for a
        //  notify inside stock's claymore detonate radius (96,
        //  _zm_weap_claymore.gsc:150) fires the mine under the zombie's feet.
        //  The old MP detectionmindist skip is gone with it: for a PLANTER
        //  that rule stops instant self-triggering, but the owner is already
        //  skipped by identity above, and for a zombie standing directly on
        //  the mine it was a reason NOT to fire - backwards here.
        if ( distance( ent.origin, self.origin ) > 96 )
            continue;

        break;
    }

    println( "[zm_qol] betty: tripped, jumping" );

    //  Armed. The alert alias is played for parity with the claymore's own
    //  code path; note it is a stock dangler in every zombies bank.
    self playsound( "wpn_claymore_alert" );
    wait( level.zmqol_betty_activation_delay );

    if ( !isdefined( self ) )
        return;

    self zmqol_betty_pop( damagearea );
}

//  v2.9.16 - the jump-and-explode, split out of zmqol_betty_proximity() so the
//  shot-detonation watcher below can fire the same sequence. Body unchanged.
zmqol_betty_pop( damagearea )
{
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

    //  🛑 v2.9.16 - AND THE CLAYMORE'S OWN KILL RULE, because the MP numbers
    //  alone are why the mine "worked" and killed nothing. A zombie has
    //  round-scaled health; a claymore still one-shots deep into the rounds
    //  because _zm_spawner's damage handler gives any placeable-mine hit a
    //  bonus of level.round_number * randomintrange( 100, 200 )
    //  (_zm_spawner.gsc:1935-1942). The Betty is deliberately NOT registered
    //  as a placeable mine (that registry is what would make it evict
    //  claymores from the equipment slot), so its hits fell into the plain
    //  explosive branch - round * randomintrange( 0, 100 ), which can roll
    //  ZERO. So the mine's own damage rule is applied here explicitly, with
    //  stock's claymore numbers, to every live reachable zombie in the blast:
    a_zombies = getaispeciesarray( level.zombie_team, "all" );

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isdefined( a_zombies[i] ) || !isalive( a_zombies[i] ) )
            continue;

        if ( distance( a_zombies[i].origin, minemover.origin ) > level.zmqol_betty_damage_radius )
            continue;

        //  Scripted and boss zombies keep their protection - damaging one
        //  breaks the map script waiting on it (the zmqol_kill_horde lesson).
        if ( is_magic_bullet_shield_enabled( a_zombies[i] ) )
            continue;

        if ( isdefined( owner ) && isalive( owner ) )
            a_zombies[i] dodamage( level.round_number * randomintrange( 100, 200 ), a_zombies[i].origin, owner, a_zombies[i], "none", "MOD_EXPLOSIVE", 0, "bouncingbetty_zm" );
        else
            a_zombies[i] dodamage( level.round_number * randomintrange( 100, 200 ), a_zombies[i].origin, undefined, a_zombies[i], "none", "MOD_EXPLOSIVE", 0, "bouncingbetty_zm" );
    }

    wait 0.2;

    if ( isdefined( minemover ) )
        minemover delete();
}

//  v2.9.16 - detonate when shot, or when another blast reaches the mine. Any
//  damage notify fires the same jump-and-explode as a proximity trip; the
//  planter's book-keeping is cleaned by zmqol_betty_pop() exactly as before.
//  MP's own mines are damage-detonated the same way, so this matches the
//  weapon's home behaviour rather than inventing one.
zmqol_betty_shot_watch()
{
    self endon( "death" );
    self waittill_not_moving();
    self waittill( "damage", n_amount, e_attacker );

    if ( !isdefined( self ) )
        return;

    println( "[zm_qol] betty: damage-detonated (" + n_amount + ")" );
    self zmqol_betty_pop( self.zmqol_damagearea );
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
