#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    // ============================================================
    //  zm_qol BISECT GATE - zmqol_ww          (v1.69.3)
    //  0 = all three OFF (DEFAULT - the mod loads normally)
    //  1 = all three ON    2 = thundergun    3 = tesla    4 = freeze
    //  Three boots crashed at the SAME point with no script error, so
    //  the cause is now narrowed by elimination, not by more guessing.
    //  MUST stay identical to the twin file.
    // ============================================================
    n_ww = getdvarintdefault( "zmqol_ww", 0 );
    if ( n_ww != 1 && n_ww != 2 )
        return;

    // MUST match the server gate in thundergun.gsc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    include_weapon("thundergun_zm");
    clientscripts\mp\zombies\_zm_weap_thundergun::init();
}
