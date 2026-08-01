// ============================================================================
//  character\c_buried_player_reporter_dam   -   STOCK Treyarch script, shipped
//  by this mod to fill a gap in the GAME's own fastfile packaging.
//
//  🛑 Fixes: BURIED SURVIVAL (Maze / Borough) FAILS TO LOAD WITH
//     "Unresolved external: precache with 0 parameters in maps/mp/zm_buried.gsc"
//     "Unresolved external: main with 0 parameters in maps/mp/zm_buried.gsc"
//
//  --- WHY --------------------------------------------------------------------
//  Stock maps\mp\zm_buried.gsc has, at line 43:
//
//      #include character\c_buried_player_reporter_dam;
//
//  and this file is the only thing that provides main() and precache() to that
//  include - which is exactly the pair of 0-parameter symbols the error names,
//  reported against the file holding the reference (the same convention as the
//  "disconnect_door_zones ... in scripts/zm/replaced/zm_transit.gsc" error that
//  broke every TranZit location in v1.1.1).
//
//  Verified with the OAT Unlinker, not assumed:
//
//      zm_buried.ff             - no character scripts at all
//      zm_buried_patch.ff       - c_transit_player_oldman, _farmgirl, _engineer,
//                                 c_transit_player_reporter ... but NOT this one
//      so_zclassic_zm_buried.ff - HAS character/c_buried_player_reporter_dam.gsc
//      so_zencounter_zm_buried.ff - HAS it
//
//  A zstandard (survival) game on Buried loads only zm_buried_patch + zm_buried.
//  It loads neither so_zclassic nor so_zencounter, and - unlike TranZit, the one
//  map in the entire game that has one - there is no so_zsurvival_zm_buried.ff
//  for it to fall back on. So the include cannot resolve, zm_buried.gsc fails to
//  link, and the map dies before any script runs. That is why the MAZE marker
//  printlns added in v1.1.3 never appeared: the failure is at script LOAD, before
//  any main() is entered.
//
//  This is a stock Treyarch packaging gap, which is very likely part of why
//  Buried survival was never shipped. Supplying the script raw in mod.iwd makes
//  the include resolve in every gametype.
//
//  --- PROVENANCE -------------------------------------------------------------
//  Body is stock Treyarch, decompiled, from the starter kit's reference dump:
//  t6 modding starter kit\reference\gsc-dump\ZM\Maps\Buried\character\
//  c_buried_player_reporter_dam.gsc - verbatim, no changes. It is NOT imported
//  from another mod (AI_CONTEXT rule 7); it is the game's own script being
//  re-supplied where the game fails to ship it.
//
//  Harmless where the stock copy IS loaded (classic/grief): raw shadows the
//  fastfile copy and the contents are identical.
//
//  Note this character is not used by survival itself - survival assigns the
//  CIA/CDC team characters via maps\mp\zm_buried::give_team_characters - so in
//  practice these two functions only need to LINK, not run.
// ============================================================================

main()
{
    self setmodel( "c_zom_player_reporter_dam_fb" );
    self.voice = "american";
    self.skeleton = "base";
}

precache()
{
    precachemodel( "c_zom_player_reporter_dam_fb" );
}
