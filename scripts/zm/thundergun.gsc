#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

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
    // which fails both tests below, so the default stays OFF.
    str_ww = getdvar( "zmqol_ww" );
    // v1.69.8: DEFAULT IS OFF. Unset gives "", which fails both tests, so a
    // normal launch loads the mod with no wonder weapon code running at all.
    // This is the first build where that is actually true - until v1.69.7 the
    // gate itself was being shadowed by Plutonium's loose scripts folder, so
    // every "guns off" test was really a guns-on test.
    if ( str_ww != "1" && str_ww != "2" )
        return;

    // Pulled from Buried/Origins alongside the freeze gun (custom wonder-weapon FX
    // not yet fully compiled into mod.ff). Gate matches thundergun.csc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    precachestring(&"ZOMBIE_WEAPON_THUNDERGUN"); // wallbuy hint

    precacheitem("thundergun_zm");
    precacheitem("thundergun_upgraded_zm");

    include_weapon("thundergun_zm");
    add_limited_weapon("thundergun_zm", 1); // 1 player can get it (for box)
    add_zombie_weapon("thundergun_zm", "thundergun_upgraded_zm", &"ZOMBIE_WEAPON_THUNDERGUN", 10, "thunder", "", undefined );

    maps\mp\zombies\_zm_weap_thundergun::init();
}
