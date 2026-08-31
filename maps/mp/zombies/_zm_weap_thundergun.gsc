#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;

init()
{
    if( !maps\mp\zombies\_zm_weapons::is_weapon_included( "thundergun_zm" ) )
    {
        return;
    }

    level._effect["thundergun_smoke_cloud"] = loadfx( "weapon/thunder_gun/fx_thundergun_smoke_cloud" );
    level._effect["thundergun_viewmodel_steam"] = loadfx("weapon/thunder_gun/fx_thundergun_steam_view");
    level._effect["thundergun_knockdown_ground"] = loadfx( "weapon/thunder_gun/fx_thundergun_knockback_ground" );
    level._effect["thundergun_viewmodel_power_cell1"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view1");
    level._effect["thundergun_viewmodel_power_cell2"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view2");
    level._effect["thundergun_viewmodel_power_cell3"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view3");
    level._effect["thundergun_viewmodel_steam_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_steam_view");
    level._effect["thundergun_viewmodel_power_cell1_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view1");
    level._effect["thundergun_viewmodel_power_cell2_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view2");
    level._effect["thundergun_viewmodel_power_cell3_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view3");

    set_zombie_var( "thundergun_cylinder_radius", 180);
    set_zombie_var( "thundergun_fling_range", 480);
    set_zombie_var( "thundergun_gib_range", 900);
    set_zombie_var( "thundergun_gib_damage", 75);
    set_zombie_var( "thundergun_knockdown_range", 1200);
    set_zombie_var( "thundergun_knockdown_damage", 15);

    level.thundergun_gib_refs = []; 
    level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "guts"; 
    level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "right_arm"; 
    level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "left_arm"; 

    level.basic_zombie_thundergun_knockdown = ::zombie_knockdown;
    OnPlayerConnect_Callback(::thundergun_on_player_connect);
}

thundergun_on_player_connect()
{
    self thread wait_for_thundergun_fired(); 
}

wait_for_thundergun_fired()
{
    self endon("disconnect");
    self waittill("spawned_player"); 

    while(true)
    {
        self waittill("weapon_fired");
        weapon = self getcurrentweapon();
        if(weapon != "thundergun_zm" && weapon != "thundergun_upgraded_zm") continue;

        self thread thundergun_fired();
        view_pos = self gettagorigin( "tag_flash" ) - self getplayerviewheight();
        view_angles = self gettagangles( "tag_flash" );
        playfx( level._effect["thundergun_smoke_cloud"], view_pos, anglestoforward( view_angles ), anglestoup( view_angles ) );
    }
}

thundergun_network_choke()
{
    level.thundergun_network_choke_count++;
    if(level.thundergun_network_choke_count % 10) return;

    wait_network_frame();
    wait_network_frame();
    wait_network_frame();
}

thundergun_fired()
{
    physicsexplosioncylinder(self.origin, 600, 240, 1);
    self thread thundergun_affect_ais();
}

thundergun_affect_ais()
{
    if(!isdefined( level.thundergun_knockdown_enemies ))
    {
        level.thundergun_knockdown_enemies = [];
        level.thundergun_knockdown_gib = [];
        level.thundergun_fling_enemies = [];
        level.thundergun_fling_vecs = [];
    }

    self thundergun_get_enemies_in_range();

    level.thundergun_network_choke_count = 0;
    for ( i = 0; i < level.thundergun_fling_enemies.size; i++ )
        level.thundergun_fling_enemies[i] thread thundergun_fling_zombie( self, level.thundergun_fling_vecs[i], i );

    for ( i = 0; i < level.thundergun_knockdown_enemies.size; i++ )
        level.thundergun_knockdown_enemies[i] thread thundergun_knockdown_zombie( self, level.thundergun_knockdown_gib[i] );

    level.thundergun_knockdown_enemies = [];
    level.thundergun_knockdown_gib = [];
    level.thundergun_fling_enemies = [];
    level.thundergun_fling_vecs = [];
}

thundergun_get_enemies_in_range()
{
    view_pos = self getweaponmuzzlepoint();
    zombies = get_array_of_closest( view_pos, srs_ww_target_array(), undefined, undefined, level.zombie_vars["thundergun_knockdown_range"] );

    if(!isdefined(zombies)) return;

    gib_range_squared = level.zombie_vars["thundergun_gib_range"] * level.zombie_vars["thundergun_gib_range"];
    fling_range_squared = level.zombie_vars["thundergun_fling_range"] * level.zombie_vars["thundergun_fling_range"];
    cylinder_radius_squared = level.zombie_vars["thundergun_cylinder_radius"] * level.zombie_vars["thundergun_cylinder_radius"];
    knockdown_range_squared = level.zombie_vars["thundergun_knockdown_range"] * level.zombie_vars["thundergun_knockdown_range"];

    forward_view_angles = self getweaponforwarddir();
    end_pos = view_pos + vectorscale( forward_view_angles, level.zombie_vars["thundergun_knockdown_range"] );

    foreach(zombie in zombies)
    {
        if(!isdefined(zombie) || !isalive(zombie)) continue;

        test_origin = zombie getcentroid();
        test_range_squared = distancesquared(view_pos, test_origin);

        if ( test_range_squared > knockdown_range_squared )
        {
            /#
            if(getdvarint("developer")) zombie thundergun_debug_print( "range", (1, 0, 0) );
            #/
            continue;
        }

        //  🛑 v2.9.16 - TRANZIT DENIZENS, user request 2026-08-31. A screecher
        //  latched to the shooter sits AT the muzzle: the dot test below sees a
        //  degenerate direction, and DamageConeTrace from inside the ent
        //  returns 0 - so the gates skipped it every time and the blast passed
        //  straight through the thing on your face. A screecher close to the
        //  shooter (or latched to them) is therefore accepted outright; a far
        //  one on the ground keeps the normal gates. Live screechers carry
        //  .isscreecher from their spawn init (_zm_ai_screecher.gsc:375) and
        //  .linked_ent while latched (:546-549).
        if ( isdefined( zombie.isscreecher ) && zombie.isscreecher && ( test_range_squared < 16384 || ( isdefined( zombie.linked_ent ) && zombie.linked_ent == self ) ) )
        {
            level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombie;
            level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = false;
            continue;
        }

        normal = vectornormalize( test_origin - view_pos );
        dot = vectordot( forward_view_angles, normal );

        if(dot < 0) continue;

        radial_origin = pointonsegmentnearesttopoint(view_pos, end_pos, test_origin);
        if(distancesquared( test_origin, radial_origin ) > cylinder_radius_squared)
        {
            /#
            if(getdvarint("developer")) zombie thundergun_debug_print( "cylinder", (1, 0, 0) );
            #/
            continue;
        }

        if (zombie damageconetrace(view_pos, self) == 0)
        {
            /#
            if(getdvarint("developer")) zombie thundergun_debug_print( "cone", (1, 0, 0) );
            #/
            continue;
        }
        
        if(test_range_squared < fling_range_squared)
        {
            level.thundergun_fling_enemies[level.thundergun_fling_enemies.size] = zombie;
            dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
            fling_vec = vectornormalize( test_origin - view_pos );

            if ( 5000 < test_range_squared )
                fling_vec = fling_vec + vectornormalize( test_origin - radial_origin );

            fling_vec = (fling_vec[0], fling_vec[1], abs( fling_vec[2] ));
            fling_vec = vectorscale( fling_vec, 100 + 100 * dist_mult );
            level.thundergun_fling_vecs[level.thundergun_fling_vecs.size] = fling_vec;

            zombie thread setup_thundergun_vox( self, true, false, false );
            continue;
        } else if(test_range_squared < gib_range_squared) {
            level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombie;
            level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = true;

            zombie thread setup_thundergun_vox( self, false, true, false );
            continue;
        }

        level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombie;
        level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = false;

        zombie thread setup_thundergun_vox( self, false, false, true );
    }
}


thundergun_debug_print(message, color)
{
    if(!isdefined(color)) color = (1, 1, 1);
    print3d(self.origin + (0, 0, 60), message, color, 1, 1, 40);
}

thundergun_fling_zombie( player, fling_vec, index )
{
    if( !IsDefined( self ) || !IsAlive( self ) )
    {
        // guy died on us
        return;
    }

    // 🛑 v1.94.1 - THE BOSS HOOK HAS TO BE ON THIS BRANCH TOO, AND v1.94.0 PUT IT
    // ONLY ON THE OTHER ONE. thundergun_get_enemies_in_range() sorts every target
    // into exactly one of two buckets by distance from the muzzle:
    //
    //      < thundergun_fling_range (480)  -> thundergun_fling_zombie   <- HERE
    //      480 .. thundergun_knockdown_range (1200) -> thundergun_knockdown_zombie
    //
    // v1.94.0 hooked the second one only. 480 units is point-blank-to-close, which
    // is the range anyone actually fights Brutus at, so in practice every shot the
    // user fired landed here and the helmet could never come off. That is exactly
    // what they reported: "the second shot just sends him flying again" - the
    // LaunchRagdoll below is the "flying", and it belongs to this branch alone.
    //
    // Same contract as the other three call sites: returns true when it has
    // handled the hit (helmet off on the first, lethal on the second), and the
    // gun's own damage is then skipped. See zmqol_brutus_ww_hit() in
    // scripts\zm\zm_prison\zm_prison.gsc.
    // 🛑 AND THE LAUNCH IS NOT OPTIONAL ON THE KILLING SHOT. User, same message:
    // "then kill him and send him flying with the second thundergun shot." So a
    // handled hit that turned out to be lethal still gets the ragdoll and the
    // fling vector - the identical three lines the normal path runs below. A
    // handled hit that only took the helmet off does NOT, which is the asked-for
    // two-stage behaviour. Reading self.health after DoDamage is the same test
    // the stock branch below already uses, so it is a supported pattern here.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        b_handled = self [[ level.zmqol_ww_boss_hit ]]( player );

        if ( b_handled )
        {
            if ( isdefined( self ) && isdefined( self.health ) && self.health <= 0 )
            {
                self StartRagdoll();
                self LaunchRagdoll( fling_vec );
                self.thundergun_death = true;
            }

            return;
        }
    }

    if ( IsDefined( self.thundergun_fling_func ) )
    {
        self [[ self.thundergun_fling_func ]]( player );
        return;
    }

    // Being consumed by a soul catcher: kill it, but do NOT ragdoll or launch it. The ragdoll
    // would tear it out of zm_portal_death mid-notetrack and strand is_eating at 1.
    if ( self srs_ww_feeding_the_wolves() )
    {
        self DoDamage( self.health + 666, player.origin, player );
        return;
    }

    self DoDamage( self.health + 666, player.origin, player );

    if ( self.health <= 0 )
    {
        player maps\mp\zombies\_zm_score::player_add_points( "thundergun_fling", -70 ); // 30 Points

        self StartRagdoll();
        self LaunchRagdoll( fling_vec );

        self.thundergun_death = true;
    }
}

// True only for the AI types whose animstatedef actually carries the wonder-weapon states.
// animstatedefs/zm_<map>_basic.asd defines zm_thundergun_fall_*/getup_* (27 states) against the
// standard zombie animname; brutus_zombie, leaper_zombie, screecher_zombie, mechz_zombie and
// ghost_zombie have none of them. Driving AnimCustom into a state an animname does not define is
// how you get a boss frozen mid-animation. On the four maps the guns are enabled for, the ones
// this actually catches are Brutus (MotD) and the Jumping Jacks / denizens (Die Rise, TranZit).
srs_ww_anims_supported()
{
    // 🛑 zm_qol: FORCED FALSE, and this is deliberate.
    //
    // The wonder-weapon reaction states - zm_thundergun_fall_*, getup_*, the
    // freeze poses - are defined only in the package's MODIFIED
    // animstatedefs/zm_*_basic.asd. This mod does not ship those: they are what
    // killed every map at load (v1.69.0-v1.69.5), proven by a boot with all
    // three guns gated OFF crashing at the identical point.
    //
    // With the stock animation tree in place those states do not exist, and
    // driving AnimCustom into a state an animname does not define is exactly
    // the "boss frozen mid-animation" failure the package README warns about -
    // here it would hit every ordinary zombie.
    //
    // Returning false takes the path the package ALREADY uses for every special
    // enemy: the gun plays its sound and applies FULL knockdown damage, the
    // zombie dies normally, and there is no fall, getup or gib animation. The
    // README's own words for that trade: "Degrading to normal death, full
    // damage beats gun does nothing."
    //
    // 📝 To restore the animations properly, the modified .asd/.atr have to come
    // back WITH the runtime scriptmodelsuseanimtree() contract this project
    // documents in zone_source/mod_locations.zone - not by re-declaring the
    // rawfiles on their own, which is what crashed.
    return false;
}

// MotD's Hell's Retriever soul catchers. A zombie killed inside a wolf volume gets
// self.deathfunction = zombie_soul_catcher_death, which sets is_eating = 1, plays zm_portal_death,
// waits ~3s + the consume anim, THEN increments souls_received, clears is_eating and deletes the
// body. Interrupt that zombie in between -- gib it, ragdoll it, delete it -- and is_eating is never
// cleared, so that dog head refuses every future zombie and the Hell's Retriever is unobtainable
// for the rest of the game.
//
// Treyarch exposed level.no_gib_in_wolf_area for exactly this, but the ONLY weapon that honours it
// is the Blundergat (_zm_weap_blundersplat.gsc:287) -- MotD's own special. These three guns are T5
// ports and have never heard of it. Same test, same answer: leave the body alone and let the soul
// catcher have it.
srs_ww_feeding_the_wolves()
{
    // Claimed by a soul catcher. This is the RELIABLE test once death has begun: Treyarch's
    // level.no_gib_in_wolf_area calls check_for_zombie_in_wolf_area, which only returns true while
    // the catcher is NOT yet eating -- and zombie_soul_catcher_death sets is_eating = 1 the moment
    // it starts. Any weapon acting after that point gets told "false" and destroys the body
    // mid-consume, stranding is_eating at 1 and killing that dog head for the rest of the game.
    // my_soul_catcher is set alongside the deathfunction and persists throughout, so it is the
    // check that actually holds. (2026-08-02: this is what was bricking Hell's Retriever.)
    if ( IsDefined( self.my_soul_catcher ) )
        return true;

    if ( !IsDefined( level.no_gib_in_wolf_area ) )
        return false;

    return self [[ level.no_gib_in_wolf_area ]]();
}

// Target list for all three wonder weapons. get_round_enemy_array() drops every AI with
// ignore_enemy_count set -- a flag that exists to keep bosses out of the ROUND COUNTER, not out of
// harm's way. Brutus sets it in brutus_spawn, so he was never in the target list of any of the
// three guns and could not be damaged by them at all. Take the full hostile species array instead;
// the callers already isalive-check every entry.
srs_ww_target_array()
{
    a = getaispeciesarray( level.zombie_team, "all" );

    if ( !IsDefined( a ) )
        return [];

    return a;
}

zombie_knockdown( player, gib )
{
    // 📝 v1.94.0 - THE BOSS HOOK WAS HERE AND IT WAS THE WRONG PLACE. It now
    // sits in thundergun_knockdown_zombie(), above the per-AI
    // self.thundergun_knockdown_func dispatch, because Brutus never reaches
    // this function at all. Read the comment there before moving it back.

    // Special AI still take the hit -- they just take it as plain damage, with no fall/getup and
    // no gib. Deliberately NOT a skip: the point is that every enemy type is damageable, only
    // that the ones without the animstates must not be driven through them.
    if ( !self srs_ww_anims_supported() )
    {
        self playsound( "fly_thundergun_forcehit" );
        self DoDamage( level.zombie_vars["thundergun_knockdown_damage"], player.origin, player );
        return;
    }

    // Same rule as the Blundergat: never gib a body a soul catcher is claiming.
    if ( gib && !self.gibbed && !self srs_ww_feeding_the_wolves() )
    {
        self.a.gib_ref = random( level.thundergun_gib_refs );
        self thread maps\mp\animscripts\zm_death::do_gib();
    }

    if(isDefined(level.override_thundergun_damage_func))
    {
        self[[level.override_thundergun_damage_func]](player,gib);
    }
    else
    {
        damage = level.zombie_vars["thundergun_knockdown_damage"];
        self playsound( "fly_thundergun_forcehit" );
        self.thundergun_handle_pain_notetracks = ::handle_thundergun_pain_notetracks;
        self DoDamage( damage, player.origin, player );
        self AnimCustom( ::playThundergunPainAnim );
    }
}

playThundergunPainAnim()
{
    self notify( "end_play_thundergun_pain_anim" );    
    self endon( "killanimscript" );
    self endon( "death" );
    self endon( "end_play_thundergun_pain_anim" );

    if( is_true( self.marked_for_death ) )
    {
        return;
    }

    if ( !is_true( self.completed_emerging_into_playable_area ) )
    {
        return;
    }

    if ( is_true( self.is_traversing ) )
    {
        return;
    }

    if ( is_true( self.barricade_enter ) )
    {
        return;
    }

    if ( is_true( self.is_inert ) )
    {
        return;
    }

    if ( self.damageYaw <= -135 || self.damageYaw >= 135 )
    {
        fallAnim = "zm_thundergun_fall_front";
        getupAnim = "zm_thundergun_getup_belly_early";
    }
    else if ( self.damageYaw > -135 && self.damageYaw < -45 )
    {
        fallAnim = "zm_thundergun_fall_left";
        getupAnim = "zm_thundergun_getup_belly_early";
    }
    else if ( self.damageYaw > 45 && self.damageYaw < 135 )
    {
        fallAnim = "zm_thundergun_fall_right";
        getupAnim = "zm_thundergun_getup_belly_early";
    }
    else
    {
        fallAnim = "zm_thundergun_fall_back";
        
        if( RandomInt(100) < 50 )
        {
            getupAnim = "zm_thundergun_getup_back_early";
        }
        else
        {
            getupAnim = "zm_thundergun_getup_back_late";
        }
    }

    self SetAnimStateFromASD( fallAnim );
    self maps\mp\animscripts\zm_shared::DoNoteTracks( "thundergun_fall_anim", self.thundergun_handle_pain_notetracks );

    if( !IsDefined( self ) || !IsAlive( self ) || !self.has_legs || (isDefined( self.marked_for_death ) && self.marked_for_death) )
    {
        // guy died on us , or can't get up
        return;
    }    
        
    self SetAnimStateFromASD( getupAnim );
    self maps\mp\animscripts\zm_shared::DoNoteTracks( "thundergun_getup_anim" );
}

thundergun_knockdown_zombie( player, gib )
{
    self endon( "death" );
    playsoundatposition ("vox_thundergun_forcehit", self.origin);
    playsoundatposition ("wpn_thundergun_proj_impact", self.origin);


    if( !IsDefined( self ) || !IsAlive( self ) )
    {
        // guy died on us
        return;
    }

    // ========================================================================
    // v1.94.0 - THE BOSS HOOK LIVES HERE, NOT IN zombie_knockdown().
    //
    // v1.93.0 put it in zombie_knockdown() and the user reported the result
    // exactly: "the thundergun 2 shots him but the first shot doesn't remove
    // his helmet, the second shot just sends him flying again."
    //
    // 🛑 zombie_knockdown() IS NOT ON BRUTUS'S PATH. This function does not
    // call it - it dispatches through the PER-AI pointer
    // self.thundergun_knockdown_func, which stock only assigns in
    // _zm_spawner.gsc:260 (basic zombies, as level.basic_zombie_thundergun_
    // knockdown) and _zm_ai_dogs.gsc:445 (dogs). _zm_ai_brutus.gsc never sets
    // it, so for Brutus the isdefined() below is false and the entire branch is
    // skipped - which is why the tesla and the freeze gun, whose hooks sit on
    // their own direct damage calls, worked on him and this one did not.
    //
    // Hooking above the dispatch catches him whichever way the pointer is set,
    // and leaves every ordinary zombie on the stock path untouched.
    // ========================================================================
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        b_handled = self [[ level.zmqol_ww_boss_hit ]]( player );

        if ( b_handled )
            return;
    }

    //  🛑 v2.9.16 - DENIZENS DIE TO THE BLAST. The dispatch below goes
    //  through self.thundergun_knockdown_func, which stock assigns ONLY for
    //  basic zombies (_zm_spawner.gsc:260) and dogs (_zm_ai_dogs.gsc:445) -
    //  a screecher has no pointer, so the isdefined() was false and the gun
    //  did NOTHING to it, exactly the Brutus failure the banner above
    //  documents, on a different AI. No knockdown animation exists for its
    //  rig (and this mod ships no reaction anims at all - see
    //  srs_ww_anims_supported), so it takes the kill directly; a denizen is a
    //  one-knife-hit creature, and its own screecher_death_func unlinks it
    //  from a latched player cleanly.
    if ( isdefined( self.isscreecher ) && self.isscreecher )
    {
        if ( isdefined( player ) && isalive( player ) )
            self dodamage( self.health + 666, self.origin, player, self, "none", "MOD_EXPLOSIVE", 0, "thundergun_zm" );
        else
            self dodamage( self.health + 666, self.origin );

        return;
    }

    if ( IsDefined( self.thundergun_knockdown_func ) )
    {
        self [[ self.thundergun_knockdown_func ]]( player, gib );
    }
}

handle_thundergun_pain_notetracks( note )
{
    if ( note == "zombie_knockdown_ground_impact" )
    {
        playfx( level._effect["thundergun_knockdown_ground"], self.origin, AnglesToForward( self.angles ), AnglesToUp( self.angles ) );
        self playsound( "fly_thundergun_forcehit" );
    }
}

is_thundergun_damage()
{
    return IsDefined( self.damageweapon ) && (self.damageweapon == "thundergun_zm" || self.damageweapon == "thundergun_upgraded_zm") && (self.damagemod != "MOD_GRENADE" && self.damagemod != "MOD_GRENADE_SPLASH");
}

enemy_killed_by_thundergun()
{
    return ( IsDefined( self.thundergun_death ) && self.thundergun_death == true ); 
}

thundergun_sound_thread()
{
    self endon( "disconnect" );
    self waittill( "spawned_player" ); 


    for( ;; )
    {
        result = self waittill_any_return( "grenade_fire", "death", "player_downed", "weapon_change", "grenade_pullback" );        

        if ( !IsDefined( result ) )
        {
            continue;
        }

        if( ( result == "weapon_change" || result == "grenade_fire" ) && self GetCurrentWeapon() == "thundergun_zm" )
        {
            self PlayLoopSound( "tesla_idle", 0.25 );

        }
        else
        {
            self notify ("weap_away");
            self StopLoopSound(0.25);


        }
    }
}

//SELF = Zombie Being Hit With Thundergun
setup_thundergun_vox( player, fling, gib, knockdown )
{
    if( !IsDefined( self ) || !IsAlive( self ) )
    {
        return;
    }
    
    if( !fling && ( gib || knockdown ) )
    {
        if( 25 > RandomIntRange( 1, 100 ) )
        {
            //IPrintLnBold( "HAHA, You Knocked Down Some Zombies!" );
        }
    }
         
    if( fling )
    {
        if( 30 > RandomIntRange( 1, 100 ) )
        {
            //IPrintLnBold( "WAY TO DISINTEGRATE THEM!!" );
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "kill", "thundergun" );
        }
    }
}