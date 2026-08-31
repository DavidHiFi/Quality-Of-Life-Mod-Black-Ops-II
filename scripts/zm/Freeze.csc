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
    // getdvar, NOT getdvarintdefault: that one lives in mapsmp_utility, which
    // these scripts do not include, and using it here threw
    //     Unresolved external: "getdvarintdefault" with 2 parameters
    // getdvar is a true engine builtin and needs no include. Unset returns "",
    // which PASSES the gate below, so the default is ON.
    str_ww = getdvar( "zmqol_ww" );
    // DEFAULT IS ON: unset gives "", the first test fails, and the gate falls
    // through into the weapon code. Set zmqol_ww to any other value to turn the
    // guns off for a bisect ("1" = all guns on, this gun's own number = only it).
    // (An old v1.69.8 comment here claimed default-off - wrong: "" skips the
    // return. Until v1.69.7 the gate was also shadowed by Plutonium's loose
    // scripts folder, so every early "guns off" test was really guns-on.)
    if ( str_ww != "" && str_ww != "1" && str_ww != "4" )
        return;

    // MUST match the server gate in freeze.gsc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    include_weapon("freezegun_zm");
    clientscripts\mp\zombies\_zm_weap_freezegun::init();
}
