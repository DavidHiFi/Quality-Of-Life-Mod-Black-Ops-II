// ============================================================================
//  bouncingbetty.gsc  -  THE MP BOUNCING BETTY, PORTED INTO ZOMBIES   (v2.9.9)
//
//  User directive 2026-08-30 (task 4): the multiplayer Bouncing Betty in the
//  mystery box, as **a pure ADDITION - it replaces nothing.** ("the bouncing
//  betty needs to be an addition, not a replacement... claymores need to be the
//  same as usual.")
//
//  🛑 THAT DIRECTIVE WAS REVERSED BY THE USER ON 2026-09-04 (v2.11.20):
//  "make sure that you can't have both claymores and bouncing betties at the
//  same time, if you have claymores for example and then spin the mystery box
//  and land on bouncing betties, pick them up it replaces the claymores."
//  The Betty was registered with register_placeable_mine_for_level(), so
//  stock's own one-mine-at-a-time rule in weapon_give() did the swap in both
//  directions.
//
//  🛑 AND REVERSED BACK ON 2026-09-06 (v2.12.8) - THE ORIGINAL DIRECTIVE WINS.
//  The user read the README line describing the swap and rejected it in the
//  2026-08-30 words: "i do not want it to replace the claymore, i want it
//  purely as an addition in the mystery box." Asked which button the Betty
//  should then answer on, given the measurement below, they chose:
//  "Two seperate buttons, remove the betty from origins and buried."
//
//  🌟 WHY THAT IS THE WHOLE DESIGN, MEASURED 2026-09-06 - THE GAME HAS FOUR
//  ACTION SLOTS AND NO FIFTH. The user's own bindings_zm.bdg carries exactly
//  `+actionslot 1..4` (keys 8 / 2 / 5 / X; DPAD_UP/DOWN/LEFT/RIGHT). Every
//  setactionslot call in the whole stock ZM dump is 62 calls over those four:
//      slot 1  22 calls  equipment and craftables - turbine, gas mask,
//                        headchopper, and the generic buildable path
//                        (_zm_craftables.gsc:2195)
//      slot 2   4 calls  Buried's Time Bomb + detonator
//                        (_zm_weap_time_bomb.gsc:2043,2055) and Origins'
//                        Maxis drone (zm_tomb_craftables.gsc:1075,878)
//                        - AND NOTHING ELSE, ON ANY MAP
//      slot 3   6 calls  altMode on every map (_zm.gsc:1320) + Origins'
//                        revive staff
//      slot 4  29 calls  the claymore, on every map
//  So slot 2 is the only button the claymore can sit beside, and it is free on
//  TranZit, Nuketown, Die Rise and Mob of the Dead - but taken on Buried and
//  Origins the moment those two craftables are built, which would silently
//  unbind the Betty mid-game. Rather than ship that, the Betty is simply NOT
//  OFFERED on zm_buried and zm_tomb (the user's call, quoted above). 📝 The
//  slot-1 drone bind at zm_tomb_utility.gsc:196 is NOT a way out - it sits
//  inside a /# #/ dev block and never runs in retail, and stock's
//  craftablestub.use_actionslot hook is never set anywhere in the game.
//
//  The four points below are still the measured record of how the give path
//  behaves; the two the 09-04 reversal had overturned are live again and are
//  marked so.
//
//  📝 HOW IT COEXISTS WITH EVERYTHING, each point measured:
//    - 🌟 LIVE AGAIN v2.12.8. It is deliberately NOT registered with
//      register_placeable_mine_for_level: that registry is precisely what
//      makes weapon_give's is_placeable_mine branch take your claymores away,
//      and it cannot be had partway. The branch (_zm_weapons.gsc:2391) runs
//      BEFORE the zombie_weapons_callbacks hook this file gives through
//      (:2448), so no callback can undo the eviction after the fact - read in
//      the stock dump 2026-09-06 rather than assumed. Staying out of the
//      registry costs three stock mine rules, and each one is accounted for
//      here rather than quietly dropped:
//        1. a mine hit adds level.round_number * randomintrange( 100, 200 )
//           to the zombie (_zm_spawner.gsc:1934). REPLACED IN THIS FILE: the
//           hand-rolled loop at the end of zmqol_betty_jump_and_explode()
//           applies exactly that number to every live zombie in the blast.
//           It was written for this reason and is load-bearing again.
//        2. a mine cannot hurt a PLAYER at all - _zm.gsc:4152,
//           `if ( is_placeable_mine( sweapon ) ... ) return 0;`. REPLACED by
//           zmqol_betty_damage_install() below, which chains onto
//           level.overrideplayerdamage and returns 0 for this weapon. Without
//           it the blast would do up to 210 to the planter, which is the one
//           real regression this change could have shipped.
//        3. holding one in hand blocks a box or perk purchase the way a held
//           claymore does. NOT replaced - it is a minor stock courtesy, it is
//           how this weapon behaved for the whole v2.9.9-v2.11.19 run, and
//           faking it would mean owning another core check.
//    - The give goes through stock's own per-weapon hook,
//      level.zombie_weapons_callbacks (_zm_weapons.gsc:2448) - the
//      data-driven form of the hardcoded claymore_zm case right above it -
//      so the generic give path never runs for this weapon at all.
//    - 🌟 LIVE AGAIN v2.12.8. Betties bind D-pad DOWN / key `2` (actionslot 2),
//      the claymore keeps D-pad RIGHT / key `X` (actionslot 4), and you carry
//      both. The old hole this had - slot 2 not being free on Buried and
//      Origins, so the bind was skipped there and the Betty sat unbound in the
//      inventory - is closed by not offering the weapon on those two maps at
//      all, instead of by shipping a button that stops working when the player
//      builds the Time Bomb or the Maxis drone. See the slot census in the
//      banner for the measurement behind that.
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
//  🌟 v2.11.10 - THE BETTY DETONATES. The cause was in this file's own control
//  flow, and the two blocks below are now HISTORY, not current diagnosis.
//
//  The 2026-09-04 Origins log settles what every earlier version guessed at.
//  Both planted betties printed the complete chain - plant caught, settled,
//  proximity trigger up, tripped - so the plant, the settle, the arm and the
//  zombie trip have ALL been working. Only the detonation was missing, and it
//  was killed by `self endon( "death" )` in the calling thread the moment
//  zmqol_betty_pop() deleted the betty mid-sequence. Full derivation, with the
//  two stock proofs that deleting an entity fires "death", sits above
//  zmqol_betty_pop(). The fix is MP's own ordering: the jump and the explosion
//  now run threaded on the minemover, an entity nothing deletes.
//
//  🛑 SO THE v2.10.11 BLOCK BELOW IS SUPERSEDED. Its reading of the 2026-09-02
//  Borough log - "the plant is never caught at all" - was true of THAT log, but
//  the conclusion drawn from it (that the failure was upstream of every
//  watcher) did not survive the next boot: with the probes in, every watcher
//  fires. `plantable 0` is retained on its own merits - it is byte-parity with
//  the MP donor, which is independently correct - not because it fixed this.
//
//  🛑 v2.10.11 - v2.9.32's PREMISE WAS WRONG, AND IS REVERTED. The block below
//  changed the def to `plantable 1` on the stated grounds that MP's
//  bouncingbetty_mp is 1. It is NOT. Measured 2026-09-02 by dumping the real
//  asset out of retail common_mp.ff (Unlinker --include-assets weapon) and
//  diffing all 1,027 fields against this mod's def: the ONLY behavioural
//  differences were `plantable` (MP 0, this mod 1) and `startAmmo` (1 vs 2,
//  deliberate). So v2.9.32 moved the def AWAY from the one working betty in
//  the game rather than towards it.
//
//  The theory it was built on is disproved by the same donor: MP's own
//  spawnminemover() calls waittillnotmoving() on that plantable-0 grenade, and
//  maps\mp\_utility::waittillnotmoving is byte-for-byte the same logic as
//  zombies' waittill_not_moving ("stationary" for classname grenade). A
//  non-plantable sticky grenade therefore DOES emit "stationary" - retail MP
//  depends on it.
//
//  What the 2026-09-02 Borough log actually shows: the user gave themselves
//  Betties (.give betty, line 4892) and planted two, and NOT ONE of the four
//  probe lines below printed - not even "plant caught", which is the first
//  statement after the grenade_fire filter. So the failure is upstream of
//  every watcher: the plant is never caught at all, which is also why shooting
//  them did nothing (the shot watcher is threaded in that same loop). One
//  cause, both reported symptoms.
//
//  Fix: `plantable 0`, byte-parity with the MP donor on every behavioural
//  field, plus a probe that names every grenade_fire the engine reports, so if
//  it still fails the next log says whether the notify never fires or fires
//  under another name. 🛑 Still unverified in game.
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
//  🛑 SUPERSEDED 2026-09-02 - both payloads WERE extracted (reference\sound-tools//  extract_payload.py, hash of FileSource) into sound\mpletty\ and declared as
//  zmqol_betty_plant_plr / _npc / _jump. Re-verified 2026-09-04 against Origins'
//  runtime alias list: wpn_grenade_explode is resident (the explosion), and the
//  three zmqol_betty_* rows ship in mod.all with real MP payloads behind them
//  (betty_deploy for the plant, betty_trigger for the spring). Nothing in this
//  feature is silent any more - so if a betty pops without sound, that is a
//  fault to chase, not the documented state.
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
//  🛑 v2.12.8 - THIS HOOK IS LOAD-BEARING AGAIN, NOT A BELT-AND-BRACES SPARE.
//  While the Betty was a registered placeable mine (v2.11.20 - v2.12.7) stock's
//  own is_offhand_weapon() answered "yes" for it unaided, because
//  is_placeable_mine() is one of its five list lookups. The Betty has been
//  taken back out of that registry, so all five lookups miss it again and stock
//  would answer "no" - which is precisely the v2.9.11 bug above: boxing a Betty
//  while holding two guns would cost you a gun. Do not delete this.
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

// ============================================================================
//  zmqol_betty_damage_install  -  v2.12.8. YOUR OWN BETTY CANNOT HURT YOU.
//
//  🛑 THIS IS THE ONE REAL REGRESSION THE "ADDITION, NOT REPLACEMENT" CHANGE
//  WOULD OTHERWISE HAVE SHIPPED, and it is invisible until someone stands over
//  a mine. Stock's player damage path reaches _zm.gsc:4152, inside
//  player_damage_override():
//        if ( is_placeable_mine( sweapon ) || sweapon == "freezegun_zm" || ... )
//            return 0;
//  A registered mine - the claymore - therefore does nothing at all to a
//  player. The Betty was inheriting that for free while it sat in the registry.
//  Out of the registry it is a plain MOD_EXPLOSIVE, and the radiusdamage in
//  zmqol_betty_jump_and_explode() would put up to level.zmqol_betty_damage_max
//  (210) into the planter standing over it - more than a zombie swipe, and
//  enough to down them.
//
//  🌟 THE HOOK IS THE ONE STOCK ITSELF USES, AND STOCK IS ALREADY SITTING IN
//  IT. _zm.gsc:970 sets `level.overrideplayerdamage = ::player_damage_override`
//  and _zm.gsc:1054-1057 is what calls it:
//        if ( isdefined( self.overrideplayerdamage ) )
//            idamage = self [[ self.overrideplayerdamage ]]( ... );
//        else if ( isdefined( level.overrideplayerdamage ) )
//            idamage = self [[ level.overrideplayerdamage ]]( ... );
//  The RETURN VALUE becomes the damage, so returning 0 from here is the same
//  sentence stock writes about a claymore, written about this weapon.
//
//  🛑 CHAINED, NOT CLOBBERED - and for a sharper reason than the usual one.
//  What is already installed IS stock's player_damage_override, which carries
//  every other rule a player depends on (Juggernog, flak jacket, the last-stand
//  path), or the Cleansed gametype's own replacement of it. Overwriting it
//  outright would break player damage across the board. This captures whatever
//  is there and calls through FIRST, exactly as zmqol_three_hit_down_install()
//  does in quality_of_life.gsc. The two chain onto each other safely in either
//  order, because each keeps its predecessor under its own distinct name.
//
//  📝 Installed after initial_blackscreen_passed for the same reason that one
//  is: stock (_zm.gsc:970) and the gametype both write this during map load, so
//  installing any earlier captures a value that is then overwritten.
//
//  📝 Not installed on Buried or Origins - init() returns before this on those
//  two maps, and with no Betty in the game there is nothing to guard.
// ============================================================================
zmqol_betty_damage_install()
{
    flag_wait( "initial_blackscreen_passed" );

    //  Guarded so a second call can never chain this wrapper onto itself.
    if ( isdefined( level.zmqol_betty_prev_damage_set ) )
        return;

    level.zmqol_betty_prev_damage_set = 1;
    level.zmqol_betty_prev_damage = level.overrideplayerdamage;
    level.overrideplayerdamage = ::zmqol_betty_damage_wrapper;

    println( "[zm_qol] betty: player damage chain installed, prev=" + isdefined( level.zmqol_betty_prev_damage ) );
}

zmqol_betty_damage_wrapper( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
    if ( isdefined( level.zmqol_betty_prev_damage ) )
        idamage = self [[ level.zmqol_betty_prev_damage ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );

    //  Claymore parity, stock's own rule: a mine does nothing to a player.
    if ( isdefined( sweapon ) && sweapon == "bouncingbetty_zm" )
        return 0;

    return idamage;
}

init()
{
    //  🛑 THE CLAYMORE HALF OF THIS FILE IS NOT MAP-GATED. Shooting a planted
    //  claymore to set it off is its own user request (2026-08-31) and applies
    //  on every map, Buried and Origins included, so it is started before the
    //  Betty gate below and must stay there.
    level thread zmqol_claymore_shot_connect();

    //  🛑 v2.12.8 - NO BETTY ON BURIED OR ORIGINS, BY THE USER'S OWN CHOICE.
    //  The Betty needs actionslot 2 now that it no longer evicts the claymore
    //  from actionslot 4, and slot 2 is the only free button in the game - but
    //  stock claims it on exactly these two maps once the player builds
    //  Buried's Time Bomb (_zm_weap_time_bomb.gsc:2043,2055) or Origins' Maxis
    //  drone (zm_tomb_craftables.gsc:1075). That would leave a Betty already in
    //  the inventory with no button, mid-game, silently. Offered the choice,
    //  the user picked "remove the betty from origins and buried" over that.
    //
    //  Returning here keeps it out of the box, out of include_weapon(), and
    //  unprecached. 🌟 `.give betty` needs no separate gate and was checked
    //  rather than assumed: EVERY rule in quality_of_life.gsc's
    //  zmqol_give_resolve() resolves through level.zombie_weapons - rule 3 is
    //  `if ( key == str_arg && isdefined( level.zombie_weapons[ row.base ] ) )`
    //  and rules 4-5 walk the registry itself - so with add_zombie_weapon()
    //  never reached, the name simply does not resolve on these two maps.
    if ( level.script == "zm_buried" || level.script == "zm_tomb" )
        return;

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

    //  🛑 v2.12.8 - THE register_placeable_mine_for_level() CALL THAT USED TO
    //  SIT HERE IS GONE, and that single deletion is the whole "addition, not
    //  replacement" change. With the Betty out of the registry,
    //  weapon_give()'s is_placeable_mine branch (_zm_weapons.gsc:2391) never
    //  fires for it, so picking Betties out of the box no longer runs
    //      old_mine = self get_player_placeable_mine();
    //      if ( isdefined( old_mine ) ) { takeweapon; unacquire_weapon_toggle; }
    //  against your claymores - and the claymore's own gives leave the Betty
    //  alone for the same reason. See the banner for the three stock mine
    //  rules that leaving the registry costs and what covers each one.
    level thread zmqol_betty_damage_install();
    level thread zmqol_betty_onplayerconnect();
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

    //  v2.11.10 - stock satchel_damage's real order and its third field; see
    //  the correction in zmqol_betty_watch().
    self setcandamage( 1 );
    self.health = 100000;
    self.maxhealth = self.health;
    self waittill( "damage", n_amount, e_attacker );

    if ( !isdefined( self ) )
        return;

    if ( isdefined( player ) )
        self detonate( player );
    else
        self detonate();
}

//  The give itself - stock claymore_setup() with the one line that makes
//  claymores exclusive dropped (set_player_placeable_mine) and the action slot
//  moved off the claymore's 4 onto 2. Runs as the zombie_weapons_callbacks
//  hook, threaded on the PLAYER by weapon_give, which also plays the weapon vo
//  and returns before the generic give.
zmqol_betty_setup()
{
    //  Stock's claymore_setup threads its own watcher on every give rather than
    //  relying on a connect loop, and for a good reason: the host is already
    //  "connected" before a root script's init() runs, so the loop below can
    //  miss them. The notify/endon pair at the top of the watch makes a second
    //  thread cancel the first, so this is idempotent.
    self thread zmqol_betty_watch();
    self thread zmqol_betty_max_ammo_watch();

    self giveweapon( "bouncingbetty_zm" );

    //  🛑 v2.12.8 - NO set_player_placeable_mine() HERE, deliberately. That
    //  field holds ONE weapon per player and the claymore owns it. Writing the
    //  Betty into it is the eviction wearing a different hat: every stock
    //  check that reads it back would stop seeing a claymore - the
    //  between-round restore (_zm_weap_claymore.gsc:443, gated on
    //  `is_player_placeable_mine( "claymore_zm" )`) and the Tombstone,
    //  Chugabud and Afterlife restores (_zm_tombstone.gsc:267,
    //  _zm_chugabud.gsc:366, _zm_afterlife.gsc:1305). Leaving it alone is
    //  exactly what lets a player hold both and still get their claymores back
    //  after a down.
    //
    //  Slot 2 (D-pad DOWN / key `2`), not the claymore's slot 4 - the slot
    //  census in the banner is the measurement, and it is why this weapon is
    //  not offered on Buried or Origins.
    self setactionslot( 2, "weapon", "bouncingbetty_zm" );
    self setweaponammostock( "bouncingbetty_zm", 2 );
}

//  🛑 v2.12.8 - SLOT 2 AGAIN, AND THE HOLE IS CLOSED BY DROPPING TWO MAPS.
//  The Betty and the claymore are held at once once more, so the Betty needs a
//  button of its own, and the full stock census (banner) leaves exactly one:
//     slot 1  equipment and craftables - turbine, gas mask, drone, headchopper
//     slot 2  Buried's Time Bomb + detonator, Origins' Maxis drone  <- Betty
//     slot 3  "altMode" on every map (_zm.gsc:1320) + Origins' revive staff
//     slot 4  the claymore, on every map
//  v2.11.20 solved the Buried/Origins clash by taking slot 4 and evicting the
//  claymore; the user has now rejected the eviction, so the clash is solved the
//  other way instead - the Betty is not offered on those two maps at all
//  (init()). Nothing else in the entire stock ZM dump binds slot 2, so on the
//  four maps that do carry it the button cannot be taken away mid-game.

// ============================================================================
//  zmqol_betty_max_ammo_watch  -  v2.11.20. MAX AMMO REFILLS THE BETTIES.
//
//  User, 2026-09-04: "i just now got a max ammo and it didnt refill the ammo
//  for the betties, so make sure that the betties arent one time".
//
//  🌟 STOCK ITSELF REFILLS THIS CLASS OF WEAPON OFF THE NOTIFY, NOT OFF THE
//  POWERUP'S WEAPON LOOP. full_ammo_powerup() walks getweaponslist( 1 ) and
//  calls givemaxammo() on each entry (_zm_powerups.gsc:1585-1604; this mod's
//  own new_full_ammo_powerup() is that function plus the BO4 clip line).
//  Buried's Time Bomb - a Gear offhand with clipOnly 1, exactly the Betty's
//  shape - does not rely on that loop at all: time_bomb_inventory_slot_think()
//  sits on `self waittill( "zmb_max_ammo" )` and restores itself
//  (_zm_weap_time_bomb.gsc:673-690). That notify is sent to every living player
//  by the powerup BEFORE the loop runs, so this is the earlier and more
//  reliable half of the same event, and it catches any other max-ammo source
//  that sends it.
//
//  🛑 WHY THE LOOP MISSED THE BETTY IS NOT SETTLED OFFLINE, so the probe
//  below answers it on the next boot rather than the fix resting on a guess.
//  What IS measured: the def is clipOnly 1 / maxAmmo 2 / clipSize 2 - identical
//  to claymore_zm on all four - and the Betty is in neither exclusion list
//  (level.zombie_include_equipment, level.zombie_weapons_no_max_ammo). The one
//  field where the two defs differ is offhandSlot: every stock ZM and MP
//  grenade def carries a NUMBER there (claymore_zm 4, bouncingbetty_mp 3) and
//  this def carries the string "Equipment". Whether that keeps the weapon out
//  of getweaponslist( 1 ) is an engine question no dump answers, so the probe
//  prints whether the Betty was in that list at all.
//
//  The refill is three stock calls, cheapest-truest first, each one used by
//  stock on this same weapon class:
//    givemaxammo     _zm_weapons.gsc:2551, ammo_give's offhand branch - the
//                    claymore wallbuy's own re-buy path
//    givestartammo   _zm_weapons.gsc:2358, weapon_give's top-up for a weapon
//                    you already hold
//    setweaponammoclip( ..., 2 )
//                    _zm_weap_claymore.gsc:448, stock's own claymore restore -
//                    and the CLIP is what a claymore's count is read back from
//                    (_zm_weap_claymore.gsc:238), not the stock
//  All three are idempotent against a clipSize of 2, so running them together
//  cannot overfill; the probe line says which one did the work.
// ============================================================================
zmqol_betty_max_ammo_watch()
{
    self endon( "disconnect" );
    self notify( "zmqol_betty_max_ammo_watch" );
    self endon( "zmqol_betty_max_ammo_watch" );

    for (;;)
    {
        self waittill( "zmb_max_ammo" );

        if ( !self hasweapon( "bouncingbetty_zm" ) )
            continue;

        n_clip = self getweaponammoclip( "bouncingbetty_zm" );
        n_stock = self getweaponammostock( "bouncingbetty_zm" );
        b_listed = isinarray( self getweaponslist( 1 ), "bouncingbetty_zm" );

        self givemaxammo( "bouncingbetty_zm" );
        n_after_max = self getweaponammoclip( "bouncingbetty_zm" );

        self givestartammo( "bouncingbetty_zm" );
        n_after_start = self getweaponammoclip( "bouncingbetty_zm" );

        self setweaponammoclip( "bouncingbetty_zm", 2 );

        println( "[zm_qol] betty max ammo: clip " + n_clip + " stock " + n_stock + " listed=" + b_listed + " -> givemaxammo " + n_after_max + " -> givestartammo " + n_after_start + " -> setclip " + self getweaponammoclip( "bouncingbetty_zm" ) );
    }
}

zmqol_betty_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_betty_watch();
        player thread zmqol_betty_max_ammo_watch();
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

        //  v2.10.11 probe - names EVERY offhand the engine reports here, so a
        //  boot where no Betty is caught says whether the notify never fired
        //  at all or fired under a name this filter rejects. Remove once a
        //  detonation is confirmed in game.
        println( "[zm_qol] betty probe: grenade_fire weapname=" + weapname );

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
        //  🛑 v2.11.10 CORRECTION - the old comment here claimed "health first,
        //  stock's own satchel_damage order". Re-read this session, stock
        //  _zm_weap_claymore.gsc:379-381 is the OTHER order, and sets a third
        //  field this never did:
        //      self setcandamage( 1 );
        //      self.health = 100000;
        //      self.maxhealth = self.health;
        //  The REASON was right and still stands - a damageable ent left on
        //  default health is KILLED by the shot instead of receiving "damage",
        //  and endon("death") then eats the watcher with no detonation - but the
        //  order and the missing maxhealth were not stock. Matched exactly now.
        betty setcandamage( 1 );
        betty.health = 100000;
        betty.maxhealth = betty.health;
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
    //  v2.10.12 - the "wpn_claymore_alert" that used to play here does not
    //  exist in any zombies bank (measured against every map's runtime alias
    //  list), so it was silent; MP's real Betty has no separate alert either -
    //  its trigger sound is the jump sound, zmqol_betty_jump, played in _pop().
    wait( level.zmqol_betty_activation_delay );

    if ( !isdefined( self ) )
        return;

    self zmqol_betty_pop();
}

//  🛑 v2.11.10 - WHY NO BETTY EVER EXPLODED, AND THE FIX. MEASURED, NOT GUESSED.
//
//  The v2.10.11 probes did their job. The 2026-09-04 Origins log prints the
//  whole chain for both planted betties -
//      betty: plant caught (grenade_fire), waiting to settle
//      betty: settled, proximity trigger up at (825.724, 2359.54, -124.645)
//      betty: tripped, jumping
//  - so the plant, the settle, the arm and the zombie trip ALL work. The only
//  thing that never happened was the detonation, and the cause is this
//  function's own control flow, not the trigger, the radius or the def.
//
//  In T6, deleting an entity FIRES ITS "death" NOTIFY. Two independent stock
//  proofs, both read this session:
//    - _zm_weap_claymore::delete_claymores_on_death is `self waittill( "death" )`
//      and stock relies on it firing when the claymore is removed;
//    - zm_highrise_sq_slb::snipe_balls_watch_ball does `self delete(); wait 0.5;`
//      and KEEPS RUNNING - and it is guarded by `self endon( "delete" )`, a name
//      nothing ever fires. Treyarch picked a notify that cannot fire precisely
//      so the thread survives deleting its own self. A thread on a deleted
//      entity is therefore fine; a thread that registered endon("death") is NOT.
//
//  Both callers of this function - zmqol_betty_proximity() and
//  zmqol_betty_shot_watch() - open with `self endon( "death" )`, and this was a
//  plain call, not a thread, so it ran INSIDE them. The `self delete()` below
//  fired "death" on the betty and killed the whole call stack mid-detonation.
//  Everything past it - the jump wait, the explosion sound, hide(), the
//  explosion fx, radiusdamage and the entire zombie-damage loop - never ran.
//  What the player sees: the green light goes out, and nothing else happens.
//  Exactly the report.
//
//  MP never had this bug because it does not run the sequence on the betty.
//  maps\mp\_bouncingbetty::bouncingbettydetonate is, verbatim:
//      self.minemover setmodel( self.model );
//      self.minemover thread bouncingbettyjumpandexplode();   <- own thread,
//      self delete();                                            own entity
//  The jump and the explosion run on the MINEMOVER, which nothing deletes, so
//  the betty's death cannot reach them. That ordering is copied exactly below:
//  everything after the spawn moves into zmqol_betty_jump_and_explode(), which
//  is THREADED ON THE MINEMOVER before the betty is deleted.
//
//  This is also why shooting a betty did nothing even once the plant was being
//  caught: zmqol_betty_shot_watch() called straight into the same dead end.
//  One cause, both reported symptoms - again.
zmqol_betty_pop()
{
    //  --- MP's spawnminemover, killcam plumbing dropped (no killcam in zm) ---
    owner = self.owner;
    org = self.origin;
    angles = self.angles;
    minemover = spawn( "script_model", org );
    minemover.angles = angles;
    minemover setmodel( "t6_wpn_bouncing_betty_world" );
    minemover.owner = owner;

    //  The proximity trigger goes now so it cannot re-fire during the 0.65s
    //  jump. zmqol_betty_cleanup_on_death() is still the backstop if the shot
    //  watcher gets here before proximity ever built one.
    if ( isdefined( self.zmqol_damagearea ) )
        self.zmqol_damagearea delete();

    if ( isdefined( owner ) && isdefined( owner.zmqol_betties ) )
        arrayremovevalue( owner.zmqol_betties, self );

    //  🛑 ORDER IS LOAD-BEARING - MP's, for MP's reason. Start the sequence on
    //  the minemover FIRST; only then delete the betty. Reversing these two
    //  lines is the v2.9.16-v2.11.9 bug.
    minemover thread zmqol_betty_jump_and_explode();

    self delete();
}

//  MP's bouncingbettyjumpandexplode + mineexplode, run on the minemover exactly
//  as MP runs them. `self` here is the minemover, never the betty, so nothing in
//  this function can be cut short by the betty's death.
zmqol_betty_jump_and_explode()
{
    owner = self.owner;
    org = self.origin;
    minemover = self;

    explodepos = org + ( 0, 0, level.zmqol_betty_jump_height );
    minemover moveto( explodepos, level.zmqol_betty_jump_time, level.zmqol_betty_jump_time, 0 );
    playfx( level._effect["betty_launch"], org );
    minemover rotatevelocity( level.zmqol_betty_rotate_velocity, level.zmqol_betty_jump_time, 0, level.zmqol_betty_jump_time );
    minemover playsound( "zmqol_betty_jump" );
    wait( level.zmqol_betty_jump_time );

    if ( !isdefined( minemover ) )
        return;

    //  --- MP's mineexplode ---
    minemover playsound( "wpn_grenade_explode" );
    wait 0.05;

    if ( !isdefined( minemover ) )
        return;

    //  v2.11.10 probe - the chain already prints plant/settle/trip; this is the
    //  one stage that never ran. If the next Origins log shows this line, the
    //  detonation completed. Remove it and the three above once confirmed.
    println( "[zm_qol] betty: EXPLODED at " + minemover.origin );

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
    self zmqol_betty_pop();
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
