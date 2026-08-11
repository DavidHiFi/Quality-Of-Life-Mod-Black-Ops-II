#include clientscripts\mp\_utility;
#include clientscripts\mp\_fx;
#include clientscripts\mp\zombies\_zm_utility;

init()
{
    if ( GetDvar( "createfx" ) == "on" )
    {
        return;
    }

    if ( !clientscripts\mp\zombies\_zm_weapons::is_weapon_included( "freezegun_zm" ) )
    {
        return;
    }

    // MUST match the server-side gate in _zm_weap_freezegun.gsc: on zm_tomb/zm_buried the
    // actor clientfield set is at the engine's hard bit ceiling, so these two fields are
    // not registered there (client and server actor sets must stay identical, or clients
    // hit "Client Field Set actor is out of space" on connect).
    mapname = GetDvar( "mapname" );
    if ( mapname != "zm_tomb" && mapname != "zm_buried" )
    {
        RegisterClientField("actor", "freezegun_torso_damage_fx", 15000, 1, "int", ::freezegun_torso_damage_fx, true);
        RegisterClientField("actor", "freezegun_extremity_damage_fx", 15000, 1, "int", ::freezegun_extremity_damage_fx, true);
    }

    level._gib_overload_func = ::freezegun_gib_override;

    level._effect[ "freezegun_shatter" ]                = LoadFX( "weapon/freeze_gun/fx_freezegun_shatter" );
    level._effect[ "freezegun_crumple" ]                = LoadFX( "weapon/freeze_gun/fx_freezegun_crumple" );
    level._effect[ "freezegun_smoke_cloud" ]            = loadfx( "weapon/freeze_gun/fx_freezegun_smoke_cloud" );
    level._effect[ "freezegun_damage_torso" ]           = LoadFX( "maps/zombie/fx_zombie_freeze_torso" );
    level._effect[ "freezegun_damage_sm" ]              = LoadFX( "maps/zombie/fx_zombie_freeze_md" );
    level._effect[ "freezegun_upgraded" ]               = LoadFX( "weapon/freeze_gun/fx_exp_freezegun_impact" );

    level._effect[ "freezegun_shatter_gibtrail_fx" ]    = LoadFX( "weapon/freeze_gun/fx_trail_freezegun_blood_streak" );
    level._effect[ "freezegun_crumple_gibtrail_fx" ]    = LoadFX( "trail/fx_trail_blood_streak" );
    level._effect[ "freezegun_gib_fx" ]                 = LoadFX( "weapon/bullet/fx_flesh_gib_fatal_01" );

    level thread player_init();
}

player_init()
{
    waitforclient( 0 );

    players = GetLocalPlayers();

    for( i = 0; i < players.size; i++ )
    {
        player = players[i];
    }
}

freezegun_get_gibfx( shatter )
{
    return level._effect[ "freezegun_gib_fx" ];
}

freezegun_get_gibtrailfx( shatter )
{
    if ( shatter )
    {
        return level._effect[ "freezegun_shatter_gibtrail_fx" ];
    }
    else
    {
        return level._effect[ "freezegun_crumple_gibtrail_fx" ];
    }
}

freezegun_get_gibsound( shatter )
{
    if ( shatter )
    {
        return "zmb_death_gibs";
    }
    else
    {
        return "zmb_death_gibs";
    }
}

freezegun_get_gibforce( tag, force_from_torso, shatter )
{
    if ( shatter )
    {
        start_pos = self.origin;
        if ( force_from_torso )
        {
            start_pos = self gettagorigin( "J_SpineLower" );
        }

        forward = VectorNormalize( self gettagorigin( tag ) - start_pos );
        forward *= RandomFloatRange( 0.6, 1.0 );
        forward += (0, 0, RandomFloatRange( 0.4, 0.7 ));
        return forward;
    }
    else
    {
        return (0, 0, 0);
    }
}

freezegun_get_shatter_effect( upgraded )
{
    if ( upgraded )
    {
        return level._effect[ "freezegun_upgraded" ];
    }
    else
    {
        return level._effect[ "freezegun_shatter" ];
    }
}

freezegun_get_crumple_effect( upgraded )
{
    if ( upgraded )
    {
        return level._effect[ "freezegun_upgraded" ];
    }
    else
    {
        return level._effect[ "freezegun_crumple" ];
    }
}

freezegun_end_extremity_damage_fx( localclientnum, key )
{
    deletefx( localclientnum, self.freezegun_extremity_damage_fx_handles[localclientnum][key], false );
}

// 🛑 THE "IT STOPPED WORKING AFTER A WHILE" BUG. User, 2026-08-11: "it has none of
// it's visual frozen fx it seemed like it was working and then at some point it
// stopped working."
//
// This deleted the fx handles and left the ARRAY defined. Its partner
// freezegun_play_all_extremity_damage_fx() guards with
//     if ( IsDefined( self.freezegun_extremity_damage_fx_handles[localclientnum] ) )
//         return;
// so once an actor had been frozen once, that early-out was true forever and the
// actor could never show the fx again.
//
// 🌟 AND T6 RECYCLES ZOMBIE ENTITIES. A dead zombie's entity goes back into the pool
// and is reused for the next spawn, carrying this client-side field with it. So the
// effect is not per-zombie, it is per-ENTITY-SLOT: the fx work until every actor in
// the pool has been frozen once, then stop for the rest of the match. That is
// exactly the "worked, then stopped" the user described, and it is why it looked
// intermittent rather than broken.
//
// Clearing the slot is the whole fix - the guard then behaves as a
// "currently playing?" test, which is what it was always meant to be.
freezegun_end_all_extremity_damage_fx( localclientnum )
{
    if ( !IsDefined( self.freezegun_extremity_damage_fx_handles ) || !IsDefined( self.freezegun_extremity_damage_fx_handles[localclientnum] ) )
    {
        return;
    }

    keys = getArrayKeys( self.freezegun_extremity_damage_fx_handles[localclientnum] );

    for ( i = 0; i < keys.size; i++ )
    {
        freezegun_end_extremity_damage_fx( localclientnum, keys[i] );
    }

    self.freezegun_extremity_damage_fx_handles[localclientnum] = undefined;
}

freezegun_end_extremity_damage_fx_for_all_localclients( key )
{
    players = GetLocalPlayers();

    for( i = 0; i < players.size; i++ )
    {
        freezegun_end_extremity_damage_fx( i, key );
    }
}

freezegun_play_extremity_damage_fx( localclientnum, fx, key, tag )
{
    self.freezegun_extremity_damage_fx_handles[localclientnum][key] = PlayFxOnTag( localclientnum, fx, self, tag );
}

freezegun_play_all_extremity_damage_fx( localclientnum )
{
    if ( !IsDefined( self.freezegun_extremity_damage_fx_handles ) )
    {
        self.freezegun_extremity_damage_fx_handles = [];
    }

    if ( IsDefined( self.freezegun_extremity_damage_fx_handles[localclientnum] ) )
    {
        return;
    }

    self.freezegun_extremity_damage_fx_handles[localclientnum] = [];

    if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_ARM ) )
    {
        freezegun_play_extremity_damage_fx( localclientnum, level._effect[ "freezegun_damage_sm" ], "right_arm", "J_Elbow_RI" );
    }

    if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_ARM ) )
    {
        freezegun_play_extremity_damage_fx( localclientnum, level._effect[ "freezegun_damage_sm" ], "left_arm", "J_Elbow_LE" );
    }

    if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_LEG ) )
    {
        freezegun_play_extremity_damage_fx( localclientnum, level._effect[ "freezegun_damage_sm" ], "right_leg", "J_Knee_RI" );
    }

    if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_LEG ) )
    {
        freezegun_play_extremity_damage_fx( localclientnum, level._effect[ "freezegun_damage_sm" ], "left_leg", "J_Knee_LE" );
    }
}

freezegun_extremity_damage_fx(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasDemoJump)
{
    players = getlocalplayers();

    for ( i = 0; i < players.size; i++ )
    {
        if ( newVal )
        {
            self thread freezegun_play_all_extremity_damage_fx( i );
        }
        else
        {
            self thread freezegun_end_all_extremity_damage_fx( i );
        }
    }
}

// Same leak, same fix - freezegun_play_all_torso_damage_fx() guards on
// IsDefined( self.freezegun_damage_torso_fx[localclientnum] ), so leaving the slot
// defined permanently disabled the torso frost on that recycled entity.
freezegun_end_all_torso_damage_fx( localclientnum )
{
    if ( !IsDefined( self.freezegun_damage_torso_fx ) || !IsDefined( self.freezegun_damage_torso_fx[localclientnum] ) )
    {
        return;
    }

    deletefx( localclientnum, self.freezegun_damage_torso_fx[localclientnum], true );
    self.freezegun_damage_torso_fx[localclientnum] = undefined;
}

freezegun_play_all_torso_damage_fx( localclientnum )
{
    if ( !IsDefined( self.freezegun_damage_torso_fx ) )
    {
        self.freezegun_damage_torso_fx = [];
    }

    if ( IsDefined( self.freezegun_damage_torso_fx[localclientnum] ) )
    {
        return;
    }

    self.freezegun_damage_torso_fx[localclientnum] = PlayFxOnTag( localclientnum, level._effect[ "freezegun_damage_torso" ], self, "J_SpineLower" );
}

freezegun_torso_damage_fx(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasDemoJump)
{
    players = getlocalplayers();

    for ( i = 0; i < players.size; i++ )
    {
        if ( newVal )
        {
            self thread freezegun_play_all_torso_damage_fx( i );
        }
        else
        {
            self thread freezegun_end_all_torso_damage_fx( i );
        }
    }
}

freezegun_do_gib_fx( tag, shatter )
{
    players = getlocalplayers();

    for ( i = 0; i < players.size; i++ )
    {
        PlayFxOnTag( i, freezegun_get_gibtrailfx( shatter ), self, tag ); 
    }
    //PlaySound( 0, freezegun_get_gibsound( shatter ), self gettagorigin( tag ) );
}

freezegun_do_gib( model, tag, force_from_torso, shatter )
{
    //PrintLn( "*** Generating gib " + model + " from tag " + tag );

    if ( shatter && !force_from_torso )
    {
        tag_pos = self.origin;
        tag_angles = (0, 0, 1);
    }
    else
    {
        tag_pos = self gettagorigin( tag );
        tag_angles = self gettagangles( tag );
    }

    v_force = self freezegun_get_gibforce( tag, force_from_torso, shatter );
    n_fx = freezegun_get_gibtrailfx( shatter );
    players = getlocalplayers();

    for ( i = 0; i < players.size; i++ )
    {
        CreateDynEntAndLaunch( i, model, tag_pos, tag_angles, tag_pos, v_force, n_fx, 1 );
    }

    self freezegun_do_gib_fx( tag, shatter );
}

freezegun_gib_override( type, locations )
{
    if ( "freeze" != type && "up" != type )
    {
        if ( IsDefined( self.freezegun_damage_fx_handles ) )
        {
            for ( i = 0; i < locations.size; i++ )
            {
                switch( locations[i] )
                {
                    case 0: // level._ZOMBIE_GIB_PIECE_INDEX_ALL
                        players = getlocalplayers();
                        for ( i = 0; i < players.size; i++ )
                        {
                            self freezegun_end_all_extremity_damage_fx( i );
                        }
                        break;

                    case 1: // level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_ARM
                        freezegun_end_extremity_damage_fx_for_all_localclients( "right_arm" );
                        break;

                    case 2: // level._ZOMBIE_GIB_PIECE_INDEX_LEFT_ARM
                        freezegun_end_extremity_damage_fx_for_all_localclients( "left_arm" );
                        break;

                    case 3: // level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_LEG
                        freezegun_end_extremity_damage_fx_for_all_localclients( "right_leg" );
                        break;

                    case 4: // level._ZOMBIE_GIB_PIECE_INDEX_LEFT_LEG
                        freezegun_end_extremity_damage_fx_for_all_localclients( "left_leg" );
                        break;

                    // our guts torso is missing left arm, so we need to cancel fx on it for the guts case as well
                    case 6: // level._ZOMBIE_GIB_PIECE_INDEX_GUTS
                        freezegun_end_extremity_damage_fx_for_all_localclients( "left_arm" );
                        break;
                } 
            }
        }

        return false;
    }

    upgraded = false;

    for ( i = 0; i < locations.size; i++ )
    {
        switch( locations[i] )
        {
            case 7:
                upgraded = true;
                break;
        }
    }

    shatter = false;
    explosion_effect = freezegun_get_crumple_effect( upgraded );
    alias = "wpn_freezegun_collapse_zombie";

    if ( "up" == type )
    {
        shatter = true;
        explosion_effect = freezegun_get_shatter_effect( upgraded );
        alias = "wpn_freezegun_shatter_zombie";
    }

    // kill the eye glow and damage fx and play the right explosion effect for each player
    players = getlocalplayers();

    for ( i = 0; i < players.size; i++ )
    {
        self clientscripts\mp\zombies\_zm::deleteZombieEyes( i );
        self freezegun_end_all_extremity_damage_fx( i );
        self freezegun_end_all_torso_damage_fx( i );
        PlayFX( i, explosion_effect, self.origin );
        PlaySound( 0, alias, self.origin );
    }

    for ( i = 0; i < locations.size; i++ )
    {
        switch( locations[i] )
        {
            case 0: // level._ZOMBIE_GIB_PIECE_INDEX_ALL
                if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_ARM ) &&
                        IsDefined( self._gib_def.gibSpawn1 ) && IsDefined( self._gib_def.gibSpawnTag1 ) )
                {
                    self thread freezegun_do_gib( self._gib_def.gibSpawn1, self._gib_def.gibSpawnTag1, true, shatter );
                }
                if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_ARM ) &&
                        IsDefined( self._gib_def.gibSpawn2 ) && IsDefined( self._gib_def.gibSpawnTag2 ) )
                {
                    self thread freezegun_do_gib( self._gib_def.gibSpawn2, self._gib_def.gibSpawnTag2, true, shatter );
                }
                if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_LEG ) &&
                        IsDefined( self._gib_def.gibSpawn3 ) && IsDefined( self._gib_def.gibSpawnTag3 ) )
                {
                    self thread freezegun_do_gib( self._gib_def.gibSpawn3, self._gib_def.gibSpawnTag3, false, shatter );
                }
                if ( !self clientscripts\mp\zombies\_zm::has_gibbed_piece( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_LEG ) &&
                        IsDefined( self._gib_def.gibSpawn4 ) && IsDefined( self._gib_def.gibSpawnTag4 ) )
                {
                    self thread freezegun_do_gib( self._gib_def.gibSpawn4, self._gib_def.gibSpawnTag4, false, shatter );
                }

                self thread freezegun_do_gib_fx( "J_SpineLower", shatter ); //guts

                self clientscripts\mp\zombies\_zm::mark_piece_gibbed( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_ARM );
                self clientscripts\mp\zombies\_zm::mark_piece_gibbed( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_ARM );
                self clientscripts\mp\zombies\_zm::mark_piece_gibbed( level._ZOMBIE_GIB_PIECE_INDEX_RIGHT_LEG );
                self clientscripts\mp\zombies\_zm::mark_piece_gibbed( level._ZOMBIE_GIB_PIECE_INDEX_LEFT_LEG );
                self clientscripts\mp\zombies\_zm::mark_piece_gibbed( level._ZOMBIE_GIB_PIECE_INDEX_HEAD );
                break;
        } 
    }

    self.gibbed = true;
    return true;
}