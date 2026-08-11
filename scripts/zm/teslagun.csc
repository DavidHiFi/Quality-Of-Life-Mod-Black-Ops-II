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
    if ( n_ww != 1 && n_ww != 3 )
        return;

	// MUST match the server gate in teslagun.gsc (tomb/prison were server-gated but
	// never client-gated — fixed for consistency).
	// MUST stay identical to the gate in teslagun.gsc -- see the reasoning there. zm_prison
	// removed 2026-08-02; Buried and Origins stay off permanently (bit/clientfield ceiling).
	if (getdvar("mapname") == "zm_tomb" || getdvar("mapname") == "zm_buried") return;
	include_weapon("tesla_gun_zm");
	
	clientscripts\mp\zombies\_zm_weap_tesla::init();
}
