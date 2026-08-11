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
    if ( str_ww == "0" )
        return;
    if ( str_ww != "" && str_ww != "1" && str_ww != "4" )
        return;

    // Pulled from Buried/Origins: the freeze-over FX assets are not yet compiled into
    // mod.ff (deferred FX pack), and firing the gun crashes clients. Gate matches freeze.csc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    precachestring(&"ZOMBIE_WEAPON_FREEZEGUN"); // wallbuy hint

    precacheitem("freezegun_zm");
    precacheitem("freezegun_upgraded_zm");

    include_weapon("freezegun_zm");
    add_limited_weapon("freezegun_zm", 1); // 1 player can get it (for box)
    add_zombie_weapon("freezegun_zm", "freezegun_upgraded_zm", &"ZOMBIE_WEAPON_FREEZEGUN_UPGRADED", 10, "freeze", "", undefined );

    maps\mp\zombies\_zm_weap_freezegun::init();
}
