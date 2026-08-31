// ============================================================================
//  zapgun.csc  -  client half of the Zap Guns                    (v2.9.18)
// ----------------------------------------------------------------------------
//  The whole job of this file is the client-side include_weapon: the mystery
//  box needs the weapon included on BOTH sides to draw the pickup model
//  (the rule written over the EMP registration in quality_of_life.gsc).
//  There is no client fx/behaviour module - the zap kill is served entirely
//  from zapgun.gsc, and the fx it plays are broadcast server-side the way this
//  mod plays every other broadcast effect.
//
//  🛑 BOTH GATES BELOW MUST STAY IDENTICAL TO zapgun.gsc's - a weapon included
//  on one side only is the InitGame -> ShutdownGame-at-0:00 failure with a
//  clean log (teslagun.csc's banner). getdvar, not getdvarintdefault, for the
//  reason recorded there: getdvarintdefault is not reachable from these files
//  and throws Unresolved external.
// ============================================================================
#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    include_weapon( "zapgun_dw_zm" );
    include_weapon( "zapgun_le_zm", 0 );
    include_weapon( "zapgun_le_upgraded_zm", 0 );
}
