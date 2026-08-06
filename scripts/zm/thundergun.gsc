#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

init()
{
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