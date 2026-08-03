#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

//  The mod's OWN copy of Origins' zm_perk_random tree, renamed so mod.ff owns no
//  Origins asset. Declared in zone_source\mod_locations.zone; the four anims it
//  lists are zone_assets\xanim\qolwf_diesel_*.
#using_animtree("qolwf_perk_random");


// ============================================================================
//  zmqol_wf_machine_model
//
//  🛑 WHY THIS IS NOT THE REAL ORIGINS MACHINE ANY MORE.
//
//  v1.19.0 - v1.21.3 used p6_zm_vending_diesel_magic, pulled out of zm_tomb.ff
//  at link time. That broke ORIGINS, and it took a screenshot plus an asset
//  audit to see it. The chain, straight out of the Linker log:
//
//      p6_zm_vending_diesel_magic
//        -> mc/mtl_p6_zm_tm_monolith_rock -> p6_zm_tm_monolith_rock_n,
//                                            zm_tm_rock_pattern_01_*,
//                                            p6_zm_tm_monolith_dark_*
//        -> mc/mtl_p6_zm_tm_crystal       -> mtl_p6_zm_tm_crystal_*
//        -> mc/mtl_..._ball / _logo       -> chemistry_glass_*
//
//  The Origins Wunderfizz is skinned with the same textures as Origins'
//  Pack-a-Punch MONOLITH. Shipping the model therefore made mod.ff take
//  OWNERSHIP of those textures, and mod.ff loads before zm_tomb.ff, so on
//  Origins the map's own copies were refused - the same "Attempting to override
//  asset ... from zone 'mod' with zone 'zm_tomb'" mechanism that made Origins
//  unbootable via the soundbank, except for images and materials it fails
//  quietly. Symptoms the user hit: a garbled HUD element and no generator
//  capture indicator, with
//      Could not load fx "maps/zombie_tomb/fx_tomb_pack_a_punch_light_beams"
//  in the log. Measured: 137 assets added beyond the donor, 108 of them also
//  owned by zm_tomb.ff.
//
//  It is not fixable by declaring them differently - mod.ff is one file loaded
//  on every map, so "own these everywhere except Origins" cannot be expressed.
//  A stock map rendering correctly beats a prettier machine on five others, so
//  every Origins-derived asset is gone: the machine model, the four
//  fx_tomb_dieselmagic_* effects, the zm_perk_random animtree and its four
//  xanims, and the teddy-bear bottle. With them go the ball spin, the location
//  beam and the electrical fx. The Wunderfizz still works exactly as before.
//
//  ✅ v1.23.0 - THE REAL MACHINE IS BACK, UNDER MOD-PRIVATE NAMES.
//  The route the revert commit named as "the only clean one" turned out to be
//  buildable after all. Nothing below is copied out of zm_tomb.ff at link time,
//  so mod.ff owns no Origins asset and there is nothing left to collide:
//
//      xmodel    qolwf_vending_diesel_magic          (was p6_zm_vending_diesel_magic)
//      material  mc/mtl_qolwf_tm_*, mc/mtl_qolwf_vending_diesel_magic*   (7)
//      image     qolwf_*                                                 (23)
//
//  How it is built - see zone_assets\ and the notes in mod_locations.zone:
//    - The Unlinker dumps the mesh as GLB (--model-format GLB). 🛑 It is GLB or
//      nothing: the Linker CANNOT compile .xmodel_bin or .XMODEL_EXPORT - even an
//      untouched dump of a stock model fails with "Failure while trying to load
//      model for lod 0". Tested all four formats; only GLB loads.
//    - Material names live as plain text in the GLB's JSON chunk, so they are
//      renamed in place. 🛑 The replacements are deliberately the SAME BYTE
//      LENGTH ("p6_zm_tm_"->"qolwf_tm_", "p6_zm_vending_"->"qolwf_vending_")
//      because a glTF chunk carries its length in a header - change the size and
//      the file is corrupt.
//    - Materials dump as JSON and are re-pointed at the renamed images.
//    - 🛑 The images are the part that cannot come from the game files. A .ff
//      holds image HEADERS only, so Unlinker reports "Could not find data for
//      image" for all 23 - the pixels live in the ipaks, which OAT cannot read.
//      They come instead from the texture dumps already in this workspace
//      ("BO2 Files Organized By Volkz", "All .DDS Files for Zombies"), converted
//      PNG -> DDS -> IWI with OAT's ImageConverter --t6 and capped at 512px
//      (no DXT compressor here, so they ship uncompressed; 512 keeps it ~15 MB).
//      Shipping our own pixels also removes the old worry that the DLC4 textures
//      might not be mounted off Origins - they no longer have to be.
//
//  Still gone, and NOT recoverable this way: the ball spin, the location beam
//  and the electrical fx. Those need fx and xanims, and OpenAssetTools can
//  neither dump nor compile an FxEffectDef - the only way to satisfy an fx is to
//  --load the fastfile that owns it, which is what causes the collision in the
//  first place. The machine is the real one; it just stands still.
// ============================================================================
zmqol_wf_machine_model()
{
    return "qolwf_vending_diesel_magic";
}

// ============================================================================
//  main - exists only to precache.
//
//  Plutonium runs main() before init() and inside the precache window, confirmed
//  in console_zm.log, which lists "GSC Executed scripts/zm/<name>::main()" for
//  every root script that has one, ahead of every ::init().
//
//  The relocate cue needs this: a setmodel() to an unprecached model at RUNTIME
//  fails silently and leaves the entity on whatever it already had, which is why
//  the machine used to show a leftover perk bottle instead of the bear. The perk
//  bottles get away without it because they ride in on their zombie_perk_bottle_*
//  WEAPON, which default_vending_precaching precacheitem's.
//
//  zombie_teddybear replaces t6_wpn_zmb_perk_bottle_bear_world - that model is
//  Origins-owned too. ridgelandproject.gsc already precaches the teddy for the
//  secret-song easter egg, so it is available on every map.
// ============================================================================
main()
{
    precachemodel( "zombie_teddybear" );
    precachemodel( zmqol_wf_machine_model() );

    //  🛑 THIS CALL IS NOT OPTIONAL. Declaring the .atr in the zone only makes
    //  the ASSET exist; without registering it here every map dies on load with
    //      COM_ERROR (1) Unrecognized animtree 'qolwf_perk_random'.
    //                    You may need to call ScriptModelsUseAnimTree()
    //  v1.21.0 shipped the ball spin with useanimtree() alone - on the reasoning
    //  that scriptmodelsuseanimtree() sets ONE global default tree and would
    //  break other maps' animated script models - and did not boot. That
    //  reasoning was wrong: it REGISTERS a tree for script-model use and is
    //  CUMULATIVE. Stock calls it several times per map with different trees
    //  (Origins alone from zm_tomb_capture_zones, zm_tomb_giant_robot,
    //  zm_tomb_quest_fire, zm_tomb_tank and _zm_perk_random). useanimtree() then
    //  selects which registered tree a given entity animates on - both are
    //  needed, in that order, exactly as stock does it
    //  (_zm_perk_random.gsc:174-177). The per-entity useanimtree() is in
    //  wunderfizzSetup().
    scriptmodelsuseanimtree( #animtree );
}

init()
{
    thread setupWunderfizz();
}

setupWunderfizz()
{
	level.wunderfizzChecksPower = getDvarIntDefault( "wunderfizzChecksPower", 1 );
	level.wunderfizzCost = getDvarIntDefault("wunderfizzCost", 1500);
	wunderfizzUseRandomStart = getDvarIntDefault("wunderfizzUseRandomStart", 0 );
	level.wunderfizz_locations = 0;
	level.zmqol_wf_pending = [];
	if(wunderfizzUseRandomStart)
		level.currentWunderfizzLocation = 0;
	else
		level.currentWunderfizzLocation = 1;
	// ------------------------------------------------------------------------
	//  THE EFFECTS - SUBSTITUTES, NOT ORIGINS' OWN. Read before "fixing" these.
	//
	//  Origins drives the Wunderfizz from six fx_tomb_dieselmagic_* effects. We
	//  cannot ship any of them, and this is a hard tooling limit, not an
	//  oversight: OpenAssetTools can neither DUMP nor COMPILE an FxEffectDef
	//  (its support matrix lists fx as ❌/❌). The model, materials, images,
	//  xanims and animtree all rebuild under mod-private names precisely because
	//  they round-trip through OAT - fx do not. The only way to satisfy an fx
	//  dependency is to --load the fastfile that OWNS it, which makes mod.ff own
	//  it too, which is exactly the collision that broke Origins in v1.19-v1.21.
	//  So: no renaming escape hatch exists for fx. Do not go looking for a .efx.
	//
	//  Instead these are effects mod.ff ALREADY owns - verified against
	//  "Unlinker --list mod.ff" - so they cost no new asset and cannot collide
	//  with anything that is not already colliding.
	//
	//  🛑 SCALE IS THE THING THAT BITES, NOT COLOUR. v1.26.x used
	//  fx_zombie_cola_arsenal_on for the orb light. It is a PERK-MACHINE-sized
	//  "powered on" glow - authored to envelop a whole vending cabinet - so
	//  attaching it to the ball tag produced the screenshot the user sent: a
	//  huge pink cloud swallowing the bottom half of the machine and spilling
	//  onto the ground. The effect was played correctly (once, not looped); it
	//  was simply the wrong SIZE. Anything named *_cola_*_on or *_lg is
	//  cabinet-scale - do not attach those to a tag.
	//
	//    fx_alcatraz_electric_cherry_sm   small electric accent. LOOPING, and
	//                                     small enough to sit on the ball.
	//    fx_zombie_tesla_shock_ground     a discrete burst, for the departure.
	//
	//  🛑 Match LOOPING vs ONE-SHOT to how each is played below, or you get the
	//  v1.21.0 bug back: a looping fx retriggered every second stacked into a
	//  blown-out white blob swallowing the top of the machine.
	//
	//  The location MARKER is deliberately gone. Stock's is a vertical lightning
	//  beam (fx_tomb_dieselmagic_identify); nothing we own resembles one, and
	//  firing a tesla shock at the machine's base every 3-4 seconds read as
	//  noise rather than a marker. Missing beats wrong.
	// ------------------------------------------------------------------------
	//  🛑 ATTEMPT 3. The two before it are kept as the record, because an fx
	//  cannot be previewed offline and these results are the only data there is:
	//
	//    v1.26.0  arsenal_on on j_ball, played once   -> huge pink cloud
	//    v1.28.0  electric_cherry_sm, played once     -> invisible, bare machine
	//    v1.30.0  electric_cherry_sm every 0.5s       -> blinding white-blue blob
	//
	//  v1.30.0 proves electric_cherry_sm is neither small nor short: at a 0.5s
	//  cadence its copies overlap into a blown-out ball. So this drops to the
	//  THINNEST effects mod.ff owns and stretches the cadence by ~6x, which are
	//  the only two levers available - an fx cannot be scaled from script.
	//
	//    _trail       a thin arc rather than a discharge ball
	//    _secondary   tesla's smaller follow-up bolt, not the main strike
	// ------------------------------------------------------------------------
	//  🛑 v1.34.0 — ATTEMPTS 1-3 ABOVE ALL FAILED FOR ONE REASON NOBODY CHECKED:
	//  THE EFFECTS ARE NOT IN THE MAP. Every fx this function used to load was
	//  absent from five of the six maps, so off Alcatraz `loadfx` had nothing to
	//  resolve and every playfxontag below was a no-op. That - not scale, not
	//  looping-vs-one-shot - is why the user saw "the electric fx when you spin
	//  also absent" on Farm.
	//
	//  Measured, not reasoned. `Unlinker --list <map>.ff` on all six maps plus
	//  the always-loaded common_zm.ff / code_post_gfx_zm.ff, intersected:
	//
	//      fx used before          in zm_transit.ff?
	//      electric_cherry_trail   NO      <- both the spin AND the ball glow
	//      electric_cherry_sm      NO
	//      tesla_shock_secondary   NO      <- the location marker
	//      tesla_shock_ground      NO      <- the departure puff
	//
	//  🛑 THE REUSABLE RULE: an fx is safe off its home map only if it is in that
	//  map's fastfile. A `loadfx` in a ZM/Core script is NOT sufficient evidence -
	//  _zm_perk_electric_cherry.gsc loads _sm/_lg/_player/_down on paper, yet
	//  zm_transit.ff contains none of them. This also explains the old table's
	//  contradiction: _sm gave a "blinding blob" and _trail drew nothing, from the
	//  same folder - _sm was present on whatever map that was tested on, _trail is
	//  in no zombie map at all. Check the fastfile, never the script.
	//
	//  Only 224 effects exist on all six maps. The electric ones are:
	//      env/electrical/fx_elec_sparking_oneshot     one-shot spark
	//      env/electrical/fx_elec_wire_spark_burst     one-shot burst
	//      system_elements/fx_elec_spark_emit          spark emitter
	//      maps/zombie/fx_zombie_packapunch            LOOPING energy swirl
	//
	//  On Origins the machine now uses its GENUINE effects - zm_tomb.ff owns all
	//  ten fx_tomb_dieselmagic_*, so there it is the real thing, not a stand-in.
	// ------------------------------------------------------------------------
	if( level.script == "zm_tomb" )
	{
		level._effect[ "wunderfizz_loop" ]       = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_on" );
		level._effect[ "perk_machine_light" ]    = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_light" );
		level._effect[ "perk_machine_location" ] = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_identify" );
		level._effect[ "perk_machine_steam" ]    = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_steam" );
	}
	else
	{
		//  🛑 v1.34.0's PICKS WERE PRESENT AND STILL INVISIBLE - a second, separate
		//  failure from v1.30's. Availability was fixed; VISIBILITY was not.
		//
		//  The proof they ran: zmqol_wf_lightning() plays the location fx and then
		//  playsound("zmb_hellhound_bolt") on the very next line. The user heard
		//  the zap - "the zapping sound effects seem to be normal but there's none
		//  of the electric fx to match" - so playfx executed with a valid index and
		//  simply drew nothing anyone could see. fx_elec_spark_emit and
		//  fx_elec_sparking_oneshot are utility effects for sparking wires and
		//  broken fuseboxes: a handful of pixel-sized sparks, authored to be
		//  noticed at arm's length against a dark wall, not across a barn.
		//
		//  So this drops the "electrical/" family entirely and takes the biggest,
		//  brightest energy effects that exist on all six maps. The power-up set is
		//  the right scale by construction - it is authored to make a floating orb
		//  read as magical from across the map, which is exactly this machine's
		//  job - and the EMP burst is the only large blue ELECTRIC discharge in the
		//  global set, so it carries the zap the user can already hear.
		level._effect[ "wunderfizz_loop" ]       = loadfx( "misc/fx_zombie_powerup_wave" );
		level._effect[ "perk_machine_light" ]    = loadfx( "misc/fx_zombie_powerup_on" );
		level._effect[ "perk_machine_location" ] = loadfx( "weapon/emp/fx_emp_explosion_equip" );
		level._effect[ "perk_machine_steam" ]    = loadfx( "misc/fx_zombie_powerup_grab" );
	}

	//  The location fx fires at the orb's height off Origins (an EMP burst
	//  centred on the floor would be half-buried in it), but Origins' own
	//  identify beam is authored to rise FROM the base, so it keeps self.origin.
	if( level.script == "zm_tomb" )
		level.zmqol_wf_marker_z = 0;
	else
		level.zmqol_wf_marker_z = 72;

	if(level.script == "zm_tomb")
    {
		zmqol_wf_add((2468,4459,-316), (0,180,0), zmqol_wf_machine_model());
    }
    else if(level.script == "zm_nuked")
    {
    	zmqol_wf_add((-649,281,-56), (0,162,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-915,286,-56), (0,66,0), zmqol_wf_machine_model());
    	zmqol_wf_add((716,21,-57), (0,192,0), zmqol_wf_machine_model());
    }
    else if(level.script == "zm_prison")
    {
    	zmqol_wf_add((-377,-3903,-8448), (0,270, 0), zmqol_wf_machine_model());
    	zmqol_wf_add((2046, 10332.9, 1336), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-1056,8673,1336), (0,90,0), zmqol_wf_machine_model());
    	zmqol_wf_add((2795,9270,1336), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-843,5585,-72), (0,13,0), zmqol_wf_machine_model());
    	zmqol_wf_add((2724,9563,1708), (0,90,0), zmqol_wf_machine_model());
    }
    else if(level.script == "zm_buried")
    {
    	zmqol_wf_add((146,138,10), (0,270,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-374,-1103,8), (0,270,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-58,-1512,168), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((1521,1366,-14), (0,342,0), zmqol_wf_machine_model());
    	zmqol_wf_add((4910,725,2), (0,0,0), zmqol_wf_machine_model());
    	zmqol_wf_add((6862,846,108), (0,49,0), zmqol_wf_machine_model());
    }
    else if(level.script == "zm_transit")
    {
    	zmqol_wf_add((11168,8120,-576), (0,0,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-7103,4952,-56), (0,0,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-11824,-1495,228), (0,90,0), zmqol_wf_machine_model());
    	zmqol_wf_add((-5043,-7772,-61), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((8371,-5408,264), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((1823,114,88), (0,90,0), zmqol_wf_machine_model());
    }
    else if(level.script == "zm_highrise")
    {
    	zmqol_wf_add((2608, 275, 1296), (0,60,0), zmqol_wf_machine_model());
    	zmqol_wf_add((1482, 1060, 3395), (0,180,0), zmqol_wf_machine_model());
    	zmqol_wf_add((2964, 2698, 2905), (349,0,0), zmqol_wf_machine_model());
    	zmqol_wf_add((1648, -635, 2880), (0,150,0), zmqol_wf_machine_model());
    	zmqol_wf_add((1809, 1459, 3040), (0,0,0), zmqol_wf_machine_model());
    }

	zmqol_wf_place();

	// Hoisted out of all six map branches, where it sat as an identical copy.
	// It has to run AFTER placement now, and it must not run at all when there is
	// only one location: chooseLocation() loops until it draws a number different
	// from the current one, so with wunderfizz_locations == 1 it spins forever.
	if( wunderfizzUseRandomStart && level.wunderfizz_locations > 1 )
	{
		level waittill("connected", player);
		wait 1;
		level.currentWunderfizzLocation = chooseLocation(level.currentWunderfizzLocation);
		level notify("wunderfizzMove");
	}
}

// ============================================================================
//  zmqol_wf_add / zmqol_wf_place / zmqol_wf_filter_to_zones
//
//  🛑 THE BUG: on Bus Depot and Farm survival the user found ONE machine, and it
//  said "Wunderfizz Orb is at Another Location" - permanently.
//
//  The location lists above are whole-map lists. TranZit's six are one per
//  region: bus depot, diner, power, town, farm, cornfield. Survival and grief
//  only ever open ONE of those regions, but all six machines were still spawned
//  and counted, so level.wunderfizz_locations was 6 while exactly one was
//  reachable. currentWunderfizzLocation then spent 5/6 of its life pointing at a
//  machine on the far side of a map the player cannot cross, and the one machine
//  in front of them reported itself as "the other location". Same on Mob of the
//  Dead, Buried and Die Rise, which have the same map-wide lists.
//
//  🛑 v1.19.1 TRIED THE ZONE MANAGER AND IT DOES NOT DISCRIMINATE. The theory was
//  that level.zones is populated only by _zm_zonemgr::zone_init() for the zones
//  this gametype+location manages, so an out-of-area point would resolve to
//  undefined. The diagnostic below disproved it on the first run:
//      [zm_qol] wunderfizz: placed 5 of 6 candidate location(s)
//  on Farm, where one is reachable. TranZit registers its zone volumes map-wide
//  regardless of location, so every machine except one sits inside some zone. Do
//  not re-try this approach.
//
//  What IS location-specific by construction is the player spawn set.
//  _zm_gametype::get_player_spawns_for_gametype() (:1443) matches
//  player_respawn_point structs whose script_string contains
//  "<ui_gametype>_<location>" - it cannot return a spawn belonging to another
//  survival location, which is exactly the property the zone lookup lacked. So
//  keep a machine only if it is near somewhere this gametype can actually spawn
//  a player. Still no hardcoded coordinates, and Diner and grief come free.
//
//  The 2500-unit threshold is picked off the geometry, not taste: TranZit's
//  regions are 10,000+ units apart (Farm's machine is ~10 units from a farm
//  spawn, the next nearest candidate ~13,500), while a machine sitting across a
//  survival arena is at most a couple of thousand from the nearest spawn. Any
//  number between about 3,000 and 5,000 would behave identically here.
//
//  Once the list is down to one, the rest falls out of the existing code with no
//  further change: wunderfizz() only offers to relocate when
//  level.wunderfizz_locations > 1, and location 1 == currentWunderfizzLocation,
//  so the single machine is live and stays put. That is exactly what the user
//  asked for.
//
//  Gated on !is_classic() per the standing rule that classic stays stock - on a
//  classic map every machine is reachable and the full list is correct.
//
//  🛑 NEVER RETURNS NOTHING. If no machine clears the threshold - an arena whose
//  spawns are further out than expected - the single CLOSEST one is kept rather
//  than the whole list. One reachable machine that stays put is the requested
//  behaviour; falling back to all six would just reproduce the bug.
// ============================================================================
zmqol_wf_add( origin, angles, model )
{
	s_place = spawnstruct();
	s_place.origin = origin;
	s_place.angles = angles;
	s_place.model = model;
	level.zmqol_wf_pending[ level.zmqol_wf_pending.size ] = s_place;
}

zmqol_wf_place()
{
	a_place = level.zmqol_wf_pending;

	if( !is_classic() )
	{
		a_near = zmqol_wf_filter_to_play_area( a_place );

		if( a_near.size > 0 )
			a_place = a_near;
	}

	n_candidates = level.zmqol_wf_pending.size;

	for( i = 0; i < a_place.size; i++ )
		wunderfizzSetup( a_place[i].origin, a_place[i].angles, a_place[i].model );

	level.zmqol_wf_pending = [];
	println( "[zm_qol] wunderfizz: placed " + a_place.size + " of " + n_candidates + " candidate location(s)" );
}

zmqol_wf_filter_to_play_area( a_place )
{
	a_keep = [];
	n_threshold = 2500;

	// The respawn structs are indexed by struct_class_init out of _load::main(),
	// which can land after this thread starts. Ten seconds is far longer than it
	// has ever taken, and the machines are only needed once the blackscreen lifts.
	a_spawns = [];
	n_wait = 0;
	while( n_wait < 200 )
	{
		a_spawns = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

		if( isdefined( a_spawns ) && a_spawns.size > 0 )
			break;

		wait 0.05;
		n_wait++;
	}

	if( !isdefined( a_spawns ) || a_spawns.size < 1 )
	{
		println( "[zm_qol] wunderfizz: no gametype spawns found - keeping the full list" );
		return a_keep;
	}

	n_best = -1;
	n_best_dist = 0;

	for( i = 0; i < a_place.size; i++ )
	{
		n_dist = zmqol_wf_dist_to_nearest( a_place[i].origin, a_spawns );

		println( "[zm_qol] wunderfizz: candidate " + ( i + 1 ) + " is " + int( n_dist ) + " from the nearest spawn" );

		if( n_best < 0 || n_dist < n_best_dist )
		{
			n_best = i;
			n_best_dist = n_dist;
		}

		if( n_dist <= n_threshold )
			a_keep[ a_keep.size ] = a_place[i];
	}

	// Nothing cleared the threshold - keep the closest rather than the whole map.
	if( a_keep.size < 1 && n_best >= 0 )
	{
		println( "[zm_qol] wunderfizz: nothing within " + n_threshold + " - keeping the closest at " + int( n_best_dist ) );
		a_keep[ a_keep.size ] = a_place[ n_best ];
	}

	return a_keep;
}

zmqol_wf_dist_to_nearest( v_origin, a_spawns )
{
	n_best = distance( v_origin, a_spawns[0].origin );

	for( i = 1; i < a_spawns.size; i++ )
	{
		n_dist = distance( v_origin, a_spawns[i].origin );

		if( n_dist < n_best )
			n_best = n_dist;
	}

	return n_best;
}

getPerks()
{
	perks = [];
	//Order is Rainbow
	if(isDefined(level.zombiemode_using_juggernaut_perk) && level.zombiemode_using_juggernaut_perk)
	{
		perks[perks.size] = "specialty_armorvest";
	}
	if(isDefined(level._custom_perks[ "specialty_nomotionsensor"] ))
	{
		perks[perks.size] = "specialty_nomotionsensor";
	}
	if ( isDefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
	{
		perks[perks.size] = "specialty_rof";
	}
	if ( isDefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
	{
		perks[perks.size] = "specialty_longersprint";
	}
	if ( isDefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
	{
		perks[perks.size] = "specialty_fastreload";
	}
	if(isDefined(level.zombiemode_using_additionalprimaryweapon_perk) && level.zombiemode_using_additionalprimaryweapon_perk)
	{
		perks[perks.size] = "specialty_additionalprimaryweapon";
	}
	if ( isDefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
	{
		perks[perks.size] = "specialty_quickrevive";
	}
	if ( isDefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
	{
		perks[perks.size] = "specialty_finalstand";
	}
	if ( isDefined( level._custom_perks[ "specialty_grenadepulldeath" ] ))
	{
		perks[perks.size] = "specialty_grenadepulldeath";
	}
	if ( isDefined( level._custom_perks[ "specialty_flakjacket" ]) && level.script != "zm_buried" )
	{
		perks[perks.size] = "specialty_flakjacket";
	}
	if ( isDefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
	{
		perks[perks.size] = "specialty_deadshot";
	}
	if ( isDefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
	{
		perks[perks.size] = "specialty_scavenger";
	}
	return perks;
}

getPerkName(perk)
{
	if(perk == "specialty_armorvest")
		return "Juggernog";
	if(perk == "specialty_rof")
		return "Double Tap";
	if(perk == "specialty_longersprint")
		return "Stamin-Up";
	if(perk == "specialty_fastreload")
		return "Speed Cola";
	if(perk == "specialty_additionalprimaryweapon")
		return "Mule Kick";
	if(perk == "specialty_quickrevive")
		return "Quick Revive";
	if(perk == "specialty_finalstand")
		return "Who's Who";
	if(perk == "specialty_grenadepulldeath")
		return "Electric Cherry";
	if(perk == "specialty_flakjacket")
		return "PHD Flopper";
	if(perk == "specialty_deadshot")
		return "Deadshot Daiquiri";
	if(perk == "specialty_scavenger")
		return "Tombstone";
	if(perk == "specialty_nomotionsensor")
		return "Vulture Aid";
}

getPerkModel(perk)
{
	if(perk == "specialty_armorvest")
	{
		if( level.script == "zm_prison" )
			return zmqol_wf_machine_model();
		else
			return zmqol_wf_machine_model();
	}
	if(perk == "specialty_nomotionsensor")
		return "p6_zm_vending_vultureaid";
	if(perk == "specialty_rof")
	{
		if(level.script == "zm_prison")
			return "p6_zm_al_vending_doubletap2_on";
		else
			return "zombie_vending_doubletap2";
	}
	if(perk == "specialty_longersprint")
		return "zombie_vending_marathon";
	if(perk == "specialty_fastreload")
	{
		if( level.script == "zm_prison" )
			return "p6_zm_al_vending_sleight_on";
		else
			return "zombie_vending_sleight";
	}
	if(perk == "specialty_quickrevive")
		return "zombie_vending_revive";
	if(perk == "specialty_scavenger")
		return "zombie_vending_tombstone";
	if(perk == "specialty_finalstand")
		return "p6_zm_vending_chugabud";
	if(perk == "specialty_grenadepulldeath")
		return "p6_zm_vending_electric_cherry_on";
	if(perk == "specialty_additionalprimaryweapon")
		return "zombie_vending_three_gun";
	if(perk == "specialty_deadshot")
	{
		if(level.script == "zm_prison")
			return "p6_zm_al_vending_ads_on";
		else
			return "zombie_vending_ads";
	}
}
getPerkBottleModel(perk)
{
	if(perk == "specialty_armorvest")
		return "t6_wpn_zmb_perk_bottle_jugg_world";
	if(perk == "specialty_rof")
		return "t6_wpn_zmb_perk_bottle_doubletap_world";
	if(perk == "specialty_longersprint")
		return "t6_wpn_zmb_perk_bottle_marathon_world";
	if(perk == "specialty_nomotionsensor")
		return "t6_wpn_zmb_perk_bottle_vultureaid_world";
	if(perk == "specialty_fastreload")
		return "t6_wpn_zmb_perk_bottle_sleight_world";
	if(perk == "specialty_flakjacket")
		return "t6_wpn_zmb_perk_bottle_nuke_world";
	if(perk == "specialty_quickrevive")
		return "t6_wpn_zmb_perk_bottle_revive_world";
	if(perk == "specialty_scavenger")
		return "t6_wpn_zmb_perk_bottle_tombstone_world";
	if(perk == "specialty_finalstand")
		return "t6_wpn_zmb_perk_bottle_chugabud_world";
	if(perk == "specialty_grenadepulldeath")
		return "t6_wpn_zmb_perk_bottle_cherry_world";
	if(perk == "specialty_additionalprimaryweapon")
		return "t6_wpn_zmb_perk_bottle_mule_kick_world";
	if(perk == "specialty_deadshot")
		return "t6_wpn_zmb_perk_bottle_deadshot_world";
}

wunderfizzSetup(origin, angles, model)
{
	level.wunderfizz_locations++;
	collision = spawn("script_model", origin);
    collision setModel("collision_geo_cylinder_32x128_standard");
    collision rotateTo(angles, .1);
	wunderfizzMachine = spawn("script_model", origin);
	wunderfizzMachine setModel(model);
	wunderfizzMachine rotateTo(angles, .1);
	// Selects which registered tree this entity animates on. main() must already
	// have run scriptmodelsuseanimtree() or this throws "Unrecognized animtree".
	wunderfizzMachine useanimtree( #animtree );
	wunderfizzBottle = spawn("script_model", origin);
	wunderfizzBottle setModel("tag_origin");
	wunderfizzBottle.angles = angles;
	wunderfizzBottle.origin += vectorScale( ( 0, 0, 1 ), 55 );
	wunderfizzMachine.bottle = wunderfizzBottle;
	wunderfizzMachine.location = level.wunderfizz_locations;
	wunderfizzMachine.uses = 0;
	perks = getPerks();
	cost = level.wunderfizzCost;
	trig = spawn("trigger_radius", origin, 1, 50, 50);
	trig SetCursorHint("HINT_NOICON");
	wunderfizzMachine thread wunderfizz(origin, angles, model, cost, perks, trig, wunderfizzBottle);
}

wunderfizz(origin, angles, model, cost, perks, trig, wunderfizzBottle )
{
	// playLocFX() used to sit here. It spawned level._effect["lght_marker"], a
	// per-map effect that mostly does not exist off the maps that load it, so it
	// was guarded into doing nothing at all - which is why there was no location
	// beam. Replaced by zmqol_wf_ball_glow(), started when this machine becomes
	// the active one, using Origins' real fx_tomb_dieselmagic_identify.
	if(level.wunderfizzChecksPower && level.script != "zm_prison" && level.script != "zm_nuked")
	{
		trig SetHintString("Power Must Be Activated First");
		flag_wait("power_on");
		trig SetHintString(" ");
	}
	else
	{
		trig SetHintString(" ");
	}
	for(;;)
	{
		if(level.currentWunderfizzLocation == self.location)
		{
			// Arrive: spin up, then settle into the powered idle, and light the
			// ball + the marker that says "the orb is HERE".
			//
			// 🛑 The bottle is force-hidden on arrival. The user hit "just before
			// I got all the perks the bottle in the machine itself disappeared,
			// so now there's no bottle there" - and the screenshot shows the
			// TEDDY BEAR left sitting in the case, not an empty one. That is the
			// departure model (set at the top of the departure branch below)
			// still in place, so the thread died somewhere between setting the
			// bear and clearing it 10 lines later. Rather than guess which of
			// those lines threw, make arrival authoritative: whatever the bottle
			// was left as, it is hidden again the moment a machine goes live, so
			// the state cannot outlive one cycle.
			if( isdefined( self.bottle ) )
				self.bottle setModel( "tag_origin" );

			self zmqol_wf_anim( "start" );
			wait 1;
			self zmqol_wf_anim( "idle" );
			self thread zmqol_wf_ball_glow();
			for(;;)
			{
				trig SetHintString("Hold ^3&&1^7 to buy Perk-a-Cola [Cost: " + cost + "]");
				trig waittill("trigger", player);
				if(player UseButtonPressed() && player.score >= cost && player.isDrinkingPerk == 0)
				{
					if(player.num_perks < level.perk_purchase_limit)
					{
						if(player.num_perks < perks.size)
						{
							self thread wunderfizzSounds();
							player playsound("zmb_cha_ching");
							self.uses++;
							player.score -= cost;
							trig setHintString(" ");
							rtime = 3;
							wunderfx = undefined;
								if( isdefined( level._effect[ "wunderfizz_loop" ] ) )
									wunderfx = SpawnFX(level._effect["wunderfizz_loop"], self.origin,AnglesToForward(angles),AnglesToUp(angles));
							if( isdefined( wunderfx ) ) TriggerFX(wunderfx);
							// Spin the ball while it picks a perk - stock's "in_use".
							self zmqol_wf_anim( "in_use" );
							// ...and crackle while it spins. The SpawnFX/TriggerFX
							// handle above is kept for compatibility but produced
							// nothing visible ("the perk bottle just visually cycles
							// without the electricity"), because SpawnFX holds a
							// persistent fx entity - which only shows for a LOOPING
							// effect, and every effect this mod can reach is
							// one-shot. Retriggering on the tag is what actually
							// draws. Ends itself on "done_cycling", notified below.
							self thread zmqol_wf_spin_fx();
							self thread perk_bottle_motion();
							wait .1;
							while(rtime>0)
							{
								for(;;)
								{
									perkForRandom = perks[randomInt(perks.size)];
									if(!(player hasPerk(perkForRandom) || (player maps\mp\zombies\_zm_perks::has_perk_paused(perkForRandom))))
									{
										// zm_qol: the upstream else-branch cycled the MACHINE through
										// each perk's vending model, because it had no Wunderfizz
										// machine to work with off Origins. We ship the real one now,
										// so every map gets the real presentation: the machine stays
										// put and the BOTTLE on top cycles.
										self.bottle setModel(getPerkBottleModel(perkForRandom));
										break;
									}
								}
								if( isdefined( wunderfx ) ) TriggerFX(wunderfx);
								wait .2;
								rtime -= .2;
							}
							self notify( "done_cycling" );
							if((self.uses >= RandomIntRange(3,7)) && (level.wunderfizz_locations > 1))
							{
								self.bottle setModel("zombie_teddybear");
								level notify("wunderSpinStop");
								if( isdefined( wunderfx ) ) wunderfx Delete();
								// Departing: kill the orb light, wind the ball down,
								// and puff on the way out - stock's shut_down plus
								// fx_departure_steam.
								self notify( "zmqol_wf_ball_off" );
								self zmqol_wf_anim( "shut_down" );
								self thread zmqol_wf_departure_steam();
								wait 7;
								self.bottle setModel("tag_origin");
								level.currentWunderfizzLocation = chooseLocation(level.currentWunderfizzLocation);
								level notify("wunderfizzMove");
								self setModel(model);
								self.uses = 0;
								break;
							}
							else{
								perklist = array_randomize(perks);
								for(j=0;j<perklist.size;j++)
								{
									if(!(player hasPerk(perklist[j]) || (self maps\mp\zombies\_zm_perks::has_perk_paused(perklist[j]))))
									{
										perkName = getPerkName(perklist[j]);

										// zm_qol: settle on the bottle, same as the cycling above.
										// The dropped else-branch also leaned on level._effect
										// "electriccherry" / "tombstone_light", which only exist on
										// the maps that ship those perks - another undefined-effect
										// thread killer off those maps.
										self.bottle setModel(getPerkBottleModel(perklist[j]));

										trig SetHintString("Hold ^3&&1^7 for " + perkName);
										time = 7;
										while(time > 0)
										{
											if(player UseButtonPressed() && distance(player.origin, trig.origin) < 65)
											{
												player thread givePerk(perklist[j]);
												break;
											}
											if( isdefined( wunderfx ) ) TriggerFX(wunderfx);
											wait .2;
											time -= .2;
										}
										self setModel(model);
										self.bottle setModel("tag_origin");
										trig SetHintString(" ");
										level notify("wunderSpinStop");
										// zm_qol: `fx Delete()` used to live here. `fx` was only ever
										// assigned inside the placeholder else-branch this commit
										// removed, so with that gone nothing assigns it and the
										// Plutonium compiler rejects the whole file:
										//     local variable 'fx' not found
										// The machine's loop effect is `wunderfx`, which is deleted
										// a few lines below - so there is nothing left to clean up.
										break;
									}
								}
								if( isdefined( wunderfx ) ) wunderfx Delete();
								wait 2;
								trig SetHintString("Hold ^3&&1^7 to buy Perk-a-Cola [Cost: " + cost + "]");
							}
						}
						else
						{
							trig SetHintString("You Have All " + perks.size + " Perks");
							wait 2;
							trig SetHintString("Hold ^3&&1^7 to buy Perk-a-Cola [Cost: " + cost + "]");
						}
					}
					else{
						trig SetHintString("You Can Only Hold " + level.perk_purchase_limit + " Perks");
						wait 2;
						trig SetHintString("Hold ^3&&1^7 to buy Perk-a-Cola [Cost: " + cost + "]");
					}
				}
				wait .1;
			}
		}
		else{
			trig SetHintString("Wunderfizz Orb is at Another Location");
			// Stop the glow and the beam - a dormant machine must not advertise
			// itself, or every location looks like the live one.
			level waittill("wunderfizzMove");
		}
		wait .1;
	}
}


// ============================================================================
//  BALL SPIN + EFFECTS
//
//  Stock splits these: the ANIMATION is server-side (setanim,
//  _zm_perk_random.gsc:609-634) and the FX are client-side, driven by five
//  clientfields that _zm_perk_random.csc listens on.
//
//  The animation half is a straight port, on the mod's own renamed animtree.
//  The fx half is deliberately NOT ported as clientfields: five more
//  registrations from a root script running on six maps is the most reliable
//  way to drop everyone with EXE_CLIENT_FIELD_MISMATCH, and this project has
//  already lost a release to exactly that. playfx / playfxontag work
//  server-side with no registration, so the effects are spawned from here
//  instead, at the same tags stock uses - just with the substitute effects set
//  up in setupWunderfizz(), since Origins' own cannot ship.
// ============================================================================

//  Stock's update_animation(), verbatim in behaviour (_zm_perk_random.gsc:609).
zmqol_wf_anim( str_state )
{
	if( str_state == "start" )
	{
		self clearanim( %root, 0.2 );
		self setanim( %qolwf_diesel_turn_on, 1, 0.2, 1 );
	}
	else if( str_state == "shut_down" )
	{
		self clearanim( %root, 0.2 );
		self setanim( %qolwf_diesel_turn_off, 1, 0.2, 1 );
	}
	else if( str_state == "in_use" )
	{
		self clearanim( %root, 0.2 );
		self setanim( %qolwf_diesel_ballspin_loop, 1, 0.2, 1 );
	}
	else
	{
		self clearanim( %root, 0.2 );
		self setanim( %qolwf_diesel_on_idle, 1, 0.2, 1 );
	}
}

//  🛑 LOOPING vs ONE-SHOT DECIDES WHETHER YOU PLAY ONCE OR RETRIGGER, AND
//  GETTING IT BACKWARDS HAS NOW FAILED IN BOTH DIRECTIONS. Both failures are
//  recorded because there is no way to inspect an fx offline - OpenAssetTools
//  cannot dump an FxEffectDef - so this table IS the documentation:
//
//    fx_zombie_cola_arsenal_on           LOOPING and cabinet-scale. v1.26.0
//        played it once on j_ball and it swallowed the machine in a pink cloud.
//    fx_alcatraz_electric_cherry_sm      ONE-SHOT. v1.28.0 "fixed" the above by
//        swapping to this and still playing it ONCE - so it flashed for an
//        instant and the machine was bare from then on, which is the state the
//        user screenshotted.
//
//  A one-shot must be RETRIGGERED to be continuously visible, and retriggering
//  is only safe BECAUSE it is one-shot - each copy expires on its own. Doing
//  this to a looping effect is what caused the v1.21.0 blob.
zmqol_wf_ball_glow()
{
	level endon( "end_game" );

	self thread zmqol_wf_lightning();

	//  🛑 v1.34.0: perk_machine_light is LOOPING on BOTH branches now
	//  (fx_tomb_dieselmagic_light on Origins, fx_zombie_packapunch elsewhere -
	//  stock plays each exactly once and leaves it running). So it is played
	//  ONCE here, never retriggered; retriggering a looping effect is the
	//  v1.21.0 blob, and the old 3-4s playfxontag loop above was doing exactly
	//  that - it only looked harmless because the effect did not exist.
	//
	//  It is SpawnFX rather than playfxontag because a looping effect has to be
	//  STOPPABLE, and server-side GSC has no stopfx - the entire stock ZM dump
	//  uses spawnfx/triggerfx and nothing else. Stock kills these from the
	//  CLIENT (_zm_perk_random.csc calls stopfx on its own handle), which is not
	//  reachable from here. SpawnFX yields an entity, and deleting the entity is
	//  the only server-side "off" switch there is. With playfxontag the orb
	//  would keep glowing on a machine the ball had already left.
	v_ball = self gettagorigin( "j_ball" );
	if( !isdefined( v_ball ) )
		v_ball = self.origin + ( 0, 0, 60 );

	e_glow = undefined;
	if( isdefined( level._effect[ "perk_machine_light" ] ) )
	{
		e_glow = SpawnFX( level._effect[ "perk_machine_light" ], v_ball, AnglesToForward( self.angles ), AnglesToUp( self.angles ) );
		TriggerFX( e_glow );
	}

	self waittill( "zmqol_wf_ball_off" );

	if( isdefined( e_glow ) )
		e_glow Delete();
}

//  "there's electrical effects all around it in origins and the lightning
//  coming down from above and also there's a electric zap sound effect" - the
//  user, comparing against real Origins.
//
//  Stock's beam is fx_tomb_dieselmagic_identify, which cannot ship (fx cannot
//  be renamed and owning Origins' copy breaks Origins). This fires a tesla
//  shock above the machine on the same 3-4s cadence stock uses for its
//  location indicator, with a lightning crack to match.
//
//  zmb_hellhound_bolt is the hellhound SPAWN LIGHTNING -
//  evt\zombie_global\hellhounds\spawn\strikes_00 - so it is a real lightning
//  strike, it lives in the global zombie bank rather than Origins', and its
//  DistMaxDry is 4000 so it carries. Confirmed against BO2-Reimagined's alias
//  CSV rather than guessed.
//  Electricity WHILE the machine cycles a perk. Denser than the idle crackle
//  because it is a 3-second burst rather than a permanent state, and it stops
//  the moment the roll ends.
zmqol_wf_spin_fx()
{
	self endon( "done_cycling" );
	self endon( "zmqol_wf_ball_off" );
	level endon( "end_game" );

	if( !isdefined( level._effect[ "wunderfizz_loop" ] ) )
		return;

	//  Cadence copied from stock rather than guessed: _zm_perk_random.csc's
	//  fx_activation_electric_loop() retriggers fx_tomb_dieselmagic_on every
	//  0.1s for as long as the bottle is cycling. Both effects this resolves to
	//  are one-shot, so retriggering is the correct - and only - way to keep
	//  them continuously visible.
	//
	//  Off Origins the effect is an expanding power-up wave rather than a tight
	//  electrical crackle, so it gets a slower beat - each wave needs room to
	//  travel before the next one starts, and at 0.1s they overlap into a solid
	//  ball, which is the v1.30.0 failure in a new costume.
	n_beat = 0.25;
	if( level.script == "zm_tomb" )
		n_beat = 0.1;

	for( ;; )
	{
		playfxontag( level._effect[ "wunderfizz_loop" ], self, "j_ball" );
		wait n_beat;
	}
}

zmqol_wf_lightning()
{
	self endon( "zmqol_wf_ball_off" );
	level endon( "end_game" );

	if( !isdefined( level._effect[ "perk_machine_location" ] ) )
		return;

	//  Stock's fx_location_indicator (_zm_perk_random.csc:205) fires at
	//  self.origin on a randomfloatrange( 3.0, 4.0 ) beat. Both are copied here
	//  rather than invented: the old 7-11s spacing was chosen when the effect was
	//  a tesla shock that read as noise, and the +90 lift was there to get that
	//  shock clear of the machine. Origins' real marker (dieselmagic_identify) is
	//  a beam authored to start at the machine's base, so it wants the true
	//  origin.
	for( ;; )
	{
		wait randomfloatrange( 3.0, 4.0 );

		if( self.location != level.currentWunderfizzLocation )
			continue;

		playfx( level._effect[ "perk_machine_location" ], self.origin + ( 0, 0, level.zmqol_wf_marker_z ) );

		//  No sound on Origins: the real machine's marker is silent, and the
		//  vortex loop is already carrying the audio.
		if( level.script != "zm_tomb" )
			self playsound( "zmb_hellhound_bolt" );
	}
}

//  Stock's fx_departure_steam (_zm_perk_random.csc:193) puffs for 5 seconds as
//  the orb leaves. Stock retriggers every 0.1s because its steam fx is a short
//  one-shot; ours is a discrete electrical burst, so it fires on a slower beat -
//  50 shocks in 5 seconds would be a strobe, not a departure.
zmqol_wf_departure_steam()
{
	level endon( "end_game" );

	if( !isdefined( level._effect[ "perk_machine_steam" ] ) )
		return;

	//  On Origins this is stock's own fx_tomb_dieselmagic_steam, so it gets
	//  stock's own cadence - 0.1s for 5 seconds. Off Origins it is an electrical
	//  burst instead of steam, and 50 of those in 5 seconds is a strobe, so that
	//  branch keeps the slower beat.
	if( level.script == "zm_tomb" )
	{
		n_end = GetTime() + 5000;
		while( GetTime() < n_end )
		{
			playfxontag( level._effect[ "perk_machine_steam" ], self, "tag_origin" );
			wait 0.1;
		}
		return;
	}

	n_ticks = 0;

	while( n_ticks < 7 )
	{
		playfxontag( level._effect[ "perk_machine_steam" ], self, "tag_origin" );
		wait 0.7;
		n_ticks++;
	}
}

chooseLocation(currLoc)
{
	//  🛑 With one location this used to spin forever - it draws until it gets a
	//  number different from the current one, and there is no such number. The
	//  caller guards on wunderfizz_locations > 1 today, so this is belt and
	//  braces, but a machine stuck in here never finishes departing and the orb
	//  never reappears anywhere, which is indistinguishable from the mod being
	//  broken. Cheap to make impossible.
	if( level.wunderfizz_locations < 2 )
		return currLoc;

	for(;;)
	{
		loc = RandomIntRange(1, level.wunderfizz_locations + 1);
		if(currLoc != loc)
		{
			return loc;
		}
		wait .1;
	}
}


perk_bottle_motion()
{
	putouttime = 3;
	putbacktime = 10;
	v_float = anglesToForward( self.angles - ( 0, 90, 0 ) ) * 10;
	self.bottle.origin = self.origin + ( 0, 0, 53 );
	self.bottle.angles = self.angles;
	self.bottle.origin -= v_float;
	self.bottle moveto( self.bottle.origin + v_float, putouttime, putouttime * 0.5 );
	self.bottle.angles += ( 0, 0, 10 );
	self.bottle rotateyaw( 720, putouttime, putouttime * 0.5 );
	self waittill( "done_cycling" );
	self.bottle.angles = self.angles;
	self.bottle moveto( self.bottle.origin - v_float, putbacktime, putbacktime * 0.5 );
	self.bottle rotateyaw( 90, putbacktime, putbacktime * 0.5 );
}

// ============================================================================
//  wunderfizzSounds
//
//  🛑 THE REAL ALIASES ONLY EXIST ON ORIGINS, AND THAT CANNOT BE FIXED FROM
//  SCRIPT OR FROM THE ZONE.
//
//  zmb_rand_perk_start / _loop / _stop live in zmb_tomb.all, which is Origins'
//  bank. console_zm.log lists every bank a map loads and that one is absent
//  everywhere else, so on five of six maps these calls resolved to nothing and
//  the machine was silent.
//
//  Routes that are closed, so nobody re-walks them:
//    - "soundbank,zmb_tomb.all" in the zone made Origins UNBOOTABLE in v1.19.0:
//        COM_ERROR Attempting to override asset 'zmb_tomb.all'
//                  from zone 'mod' with zone 'zm_tomb'
//      mod.ff loads first, the map's own copy is refused, and a duplicate
//      soundbank asset is fatal. There is no conditional form.
//    - No GSC builtin loads a soundbank at runtime (checked the whole dump).
//    - Building the aliases into the mod's own mod.all needs a tool that can
//      CREATE aliases. Black Ops II Sound Studio Extended cannot: it is a
//      payload REPLACER (its table is Name/Offset/Size/Format/Hash/Replaced
//      with a Replace Manager, and it shows a custom bank's entries as
//      "Sound #1.flac" because it cannot resolve their names). No alias
//      builder exists on this machine.
//
//  So: substitute aliases that ship in evt\zombie_global\pap\ - the
//  Pack-a-Punch machine set, present on all six maps because every map has a
//  PaP, and already proven here (the mod plays packa_ready and packa_upgrade
//  elsewhere without trouble). Same trade as the fx substitutes: a machine
//  that sounds like a machine beats a silent one.
//
//  Origins still gets its authentic audio, because there the real aliases
//  resolve. Do not "simplify" this by dropping the branch.
// ============================================================================
wunderfizzSounds()
{
	// ------------------------------------------------------------------------
	//  🛑 v1.34.0 — THE ORIGINS BRANCH HAD NEVER WORKED EITHER, AND NOT FOR THE
	//  REASON THIS HEADER CLAIMS. zmb_rand_perk_start / _loop / _stop are not
	//  stock alias names. They appear NOWHERE in the 2,093-file stock dump - they
	//  came in with the upstream wunderfizz mod and were taken on trust here.
	//  So the machine was silent on Origins too, not just off it.
	//
	//  The real machine's audio is CLIENT-side, in Origins'
	//  _zm_perk_random.csc, and it is two aliases:
	//      zmb_rand_perk_vortex_sparks   one-shot, on spin up AND spin down
	//      zmb_rand_perk_vortex          the loop, via soundloopemitter
	//  (_zm_perk_random.csc:119-131). Those are what Origins uses now.
	// ------------------------------------------------------------------------
	if ( level.script == "zm_tomb" || getdvarintdefault( "zmqol_wf_sound", 0 ) == 1 )
	{
		str_start = "zmb_rand_perk_vortex_sparks";
		str_loop  = "zmb_rand_perk_vortex";
		str_stop  = "zmb_rand_perk_vortex_sparks";
	}
	else
	{
		// 🛑 The loop is the one the user called "kinda off", and packa_ticktock
		// is why: it is the Pack-a-Punch CLOCK TICK (evt\zombie_global\pap\loop),
		// which reads as a countdown rather than a spinning orb.
		// zmb_tombstone_looper is the POWERUP swirl
		// (evt\zombie_global\powerup\loop\loop_00) - an energy loop, and still
		// zombie_global so it is on every map.
		//
		// 🛑 Do NOT reach for zmb_zombieblood_loop, which sounds like the right
		// idea: its source is zmb\level\zm_tomb\zombie_blood\loop, i.e. Origins'
		// bank, and it would be silent everywhere else - the exact bug this
		// whole branch exists to work around.
		//  🛑 v1.34.0 REVERTS v1.32.0's zmb_tombstone_looper. It was picked out of
		//  BO2-Reimagined's mod.all.aliases.csv on the assumption that the file was
		//  a dictionary of stock aliases. It is not - it is the alias table of
		//  Reimagined's OWN bank, so an entry there says nothing about what stock
		//  ships, and the user got silence. All three below are aliases this mod
		//  has actually been HEARD playing in game.
		//
		//  This cannot be settled offline: alias names are stored HASHED inside
		//  the .sabl banks (grepping cmn_root.all.sabl for a known-good alias
		//  finds nothing), and the fastfiles carry no `sound` asset type at all.
		//  There is no way to list a bank's aliases with the tooling here - only
		//  playing one and listening.
		//
		//  So `zmqol_wf_sound 1` in console switches these to Origins' real vortex
		//  pair, to find out in ONE session whether they live in a globally-loaded
		//  bank rather than in zmb_tomb.all. If they do, drop this branch.
		str_start = "zmb_perks_packa_upgrade";
		str_loop  = "zmb_perks_packa_ticktock";
		str_stop  = "zmb_perks_packa_ready";
	}

	sound_ent = spawn( "script_origin", self.origin );

	//  StopSounds() on a just-spawned entity was a no-op and is gone.
	sound_ent PlaySound( str_start );
	sound_ent PlayLoopSound( str_loop, 0.5 );

	//  🛑 Was `level waittill("wunderSpinStop")`. Two bugs in one line:
	//
	//  1. wunderSpinStop is only notified AFTER the 7-second "Hold F for X"
	//     offer window (or on departure), so the loop kept droning for up to ten
	//     seconds after the bottle had stopped moving. Stock ties the vortex
	//     exactly to the cycling - its clientfield goes 0 the moment the bottle
	//     settles - and done_cycling is this file's equivalent notify.
	//  2. It waited on LEVEL while the notify that matters is on the machine.
	//     With more than one machine that is cross-talk between locations.
	self waittill( "done_cycling" );

	sound_ent StopLoopSound( 1 );
	sound_ent PlaySound( str_stop );

	//  🛑 Deleting the emitter in the same frame as PlaySound cut the stop sound
	//  off before a single sample of it reached anyone - the old code did exactly
	//  that. Outlive the one-shot, then clean up.
	wait 2;
	sound_ent Delete();
}

givePerk(perk)
{
	if(!(self hasPerk(perk) || (self maps\mp\zombies\_zm_perks::has_perk_paused(perk))))
	{
		self.isDrinkingPerk = 1;
		gun = self maps\mp\zombies\_zm_perks::perk_give_bottle_begin(perk);
        evt = self waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete");
        if (evt == "weapon_change_complete")
        self thread maps\mp\zombies\_zm_perks::wait_give_perk(perk, 1);
       	self maps\mp\zombies\_zm_perks::perk_give_bottle_end(gun, perk);
       	self.isDrinkingPerk = 0;
    	if (self maps\mp\zombies\_zm_laststand::player_is_in_laststand() || isDefined(self.intermission) && self.intermission)
        	return;
    	self notify("burp");
	}
}