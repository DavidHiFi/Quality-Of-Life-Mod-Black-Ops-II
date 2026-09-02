// ============================================================================
//  zapgun.csc  -  client half of the Wave Gun / Zap Guns          (v2.10.14)
// ----------------------------------------------------------------------------
//  The whole job of this file is the client-side include_weapon: the mystery
//  box needs the weapon included on BOTH sides to draw the pickup model (the
//  rule written over the EMP registration in quality_of_life.gsc). Stock's own
//  clientscripts\mp\zombies\_zm_weapons.csc already lists microwavegundw_zm
//  among the dual-wield names it draws the second gun for.
//
//  Moon's client script (_zm_weap_microwavegun.csc, carved from the DLC5 zone
//  and decompiled 2026-09-03) registers two 1-bit "actor" clientfields for the
//  sizzle visuals. This mod's actor set is 31/32 (ERROR_CATALOGUE §2) and the
//  only branch those fields serve on stock maps is the instant pop, which
//  zapgun.gsc now broadcasts from the server - so there is no client fx module
//  here, and NO clientfield is registered. That keeps the symmetry rule trivially
//  true: nothing registered on either side.
//
//  🛑 BOTH GATES BELOW MUST STAY IDENTICAL TO zapgun.gsc's, and the include
//  list must mirror its two include_weapon calls exactly - a weapon included on
//  one side only is the InitGame -> ShutdownGame-at-0:00 failure with a clean
//  log (teslagun.csc's banner), and a client include of a weapon the server
//  never precached is an access violation (§37). getdvar, not
//  getdvarintdefault, for the reason recorded there: getdvarintdefault is not
//  reachable from these files and throws Unresolved external.
// ============================================================================
#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    include_weapon( "microwavegundw_zm" );
    include_weapon( "microwavegundw_upgraded_zm", 0 );
}
