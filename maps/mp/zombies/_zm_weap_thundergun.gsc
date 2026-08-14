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
    // v1.93.0 - BOSSES FIRST. level.zmqol_ww_boss_hit is installed only by the
    // map that owns the boss (scripts\zm\zm_prison\zm_prison.gsc for Brutus), so
    // this file - which loads on every map - never names a map-specific script.
    // It returns true when it has handled the hit: helmet off on the first shot,
    // lethal on the second. See the long comment on zmqol_brutus_ww_hit().
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        b_handled = self [[ level.zmqol_ww_boss_hit ]]( player );

        if ( b_handled )
            return;
    }

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