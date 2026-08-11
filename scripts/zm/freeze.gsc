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
    // 🛑 ZOMBIE_WEAPON_FREEZEGUN, not _UPGRADED. Found by diffing the three guns'
    // registrations while investigating the missing Wunderwaffe: thundergun.gsc:38
    // and teslagun.gsc:47 both pass their BASE key here, this one passed the
    // upgraded one. add_zombie_weapon()'s third argument is the base weapon's
    // display name, so the un-Packed Winter's Howl was announcing itself as
    // "Winter's Fury" in the box and on the HUD.
    add_zombie_weapon("freezegun_zm", "freezegun_upgraded_zm", &"ZOMBIE_WEAPON_FREEZEGUN", 10, "freeze", "", undefined );

    maps\mp\zombies\_zm_weap_freezegun::init();
}
