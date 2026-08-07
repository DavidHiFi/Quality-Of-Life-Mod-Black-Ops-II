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
//  ?? WHY THIS IS NOT THE REAL ORIGINS MACHINE ANY MORE.
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
//  ? v1.23.0 - THE REAL MACHINE IS BACK, UNDER MOD-PRIVATE NAMES.
//  The route the revert commit named as "the only clean one" turned out to be
//  buildable after all. Nothing below is copied out of zm_tomb.ff at link time,
//  so mod.ff owns no Origins asset and there is nothing left to collide:
//
//      xmodel    qolwf_vending_diesel_magic          (was p6_zm_vending_diesel_magic)
//      material  mc/mtl_qolwf_tm_*, mc/mtl_qolwf_vending_diesel_magic*   (7)
//      image     qolwf_*                                                 (23)
//
//  How it is built - see zone_assets\ and the notes in mod_locations.zone:
//    - The Unlinker dumps the mesh as GLB (--model-format GLB). ?? It is GLB or
//      nothing: the Linker CANNOT compile .xmodel_bin or .XMODEL_EXPORT - even an
//      untouched dump of a stock model fails with "Failure while trying to load
//      model for lod 0". Tested all four formats; only GLB loads.
//    - Material names live as plain text in the GLB's JSON chunk, so they are
//      renamed in place. ?? The replacements are deliberately the SAME BYTE
//      LENGTH ("p6_zm_tm_"->"qolwf_tm_", "p6_zm_vending_"->"qolwf_vending_")
//      because a glTF chunk carries its length in a header - change the size and
//      the file is corrupt.
//    - Materials dump as JSON and are re-pointed at the renamed images.
//    - ?? The images are the part that cannot come from the game files. A .ff
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
//  Origins-owned too. quality_of_life.gsc already precaches the teddy for the
//  secret-song easter egg, so it is available on every map.
// ============================================================================
main()
{
    precachemodel( "zombie_teddybear" );

    //  v1.56.3 - the real departure bottle. Stock Origins precaches this at
    //  _zm_perk_random.gsc:188; it ships in mod.ff now (see the REAL WUNDERFIZZ
    //  block in zone_source\mod_locations.zone), so it is safe on every map.
    //  zombie_teddybear above stays precached - the secret-song easter egg uses
    //  it, and it is still the safety fallback in get_perk_weapon_model().
    precachemodel( "t6_wpn_zmb_perk_bottle_bear_world" );

    precachemodel( zmqol_wf_machine_model() );

    //  The bottles for perks THIS MOD adds to maps that never had them. A map
    //  precaches only its own perks' bottles, so without these the cycling
    //  bottle is a model the level never registered.
    //
    //  ?? Exactly these EIGHT and no more. They are the perk-bottle world models
    //  `Unlinker --list mod.ff` reports mod.ff itself carrying, so they resolve
    //  on every map because mod.ff loads on every map. Precaching a model the
    //  level does not have is fatal at load, so nothing goes in this list that
    //  has not been confirmed present in mod.ff.
    //
    //  v1.40.0: vulture JOINS the list. It used to be excluded alongside whoswho
    //  for exactly the right reason - it was Buried-only. It is not any more:
    //  mod_locations.zone now declares the whole Vulture Aid asset set, so
    //  mod.ff carries the bottle on every map. Re-confirmed with Unlinker --list
    //  rather than assumed from the fact that the zone line was added.
    //
    //  v1.52.0: whoswho JOINS the list, and for the same reason - the comment
    //  here used to say it "exists only in Die Rise / Mob of the Dead", which was
    //  half wrong even then (Unlinker --list over all six map fastfiles finds the
    //  bottle in zm_highrise.ff ONLY; Mob has the perk's HUD shader, not its
    //  bottle). mod_locations.zone now declares the four-asset Who's Who chain,
    //  so mod.ff carries this model on every map. Confirmed present by
    //  Unlinker --list mod.ff AFTER linking, not assumed from the zone line.
    precachemodel( "t6_wpn_zmb_perk_bottle_cherry_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_deadshot_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_doubletap_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_marathon_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_mule_kick_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_nuke_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_vulture_world" );
    precachemodel( "t6_wpn_zmb_perk_bottle_whoswho_world" );

    //  ?? THIS CALL IS NOT OPTIONAL. Declaring the .atr in the zone only makes
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
	//  (its support matrix lists fx as ?/?). The model, materials, images,
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
	//  ?? SCALE IS THE THING THAT BITES, NOT COLOUR. v1.26.x used
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
	//  ?? Match LOOPING vs ONE-SHOT to how each is played below, or you get the
	//  v1.21.0 bug back: a looping fx retriggered every second stacked into a
	//  blown-out white blob swallowing the top of the machine.
	//
	//  The location MARKER is deliberately gone. Stock's is a vertical lightning
	//  beam (fx_tomb_dieselmagic_identify); nothing we own resembles one, and
	//  firing a tesla shock at the machine's base every 3-4 seconds read as
	//  noise rather than a marker. Missing beats wrong.
	// ------------------------------------------------------------------------
	//  ?? ATTEMPT 3. The two before it are kept as the record, because an fx
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
	//  ?? v1.34.0 ? ATTEMPTS 1-3 ABOVE ALL FAILED FOR ONE REASON NOBODY CHECKED:
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
	//  ?? THE REUSABLE RULE: an fx is safe off its home map only if it is in that
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
	//  🌟 v1.56.3 - EVERY MAP NOW GETS ORIGINS' GENUINE EFFECTS.
	//
	//  This used to be `if ( level.script == "zm_tomb" )`, and that single line is
	//  why the machine looked right on Origins and wrong everywhere else. The
	//  fx_tomb_dieselmagic_* set was pulled from the zone at v1.22.0, so off
	//  Origins there was nothing to load and the else branch below substituted
	//  EMP bursts and power-up energy - the harsh white bolts the user reported.
	//
	//  The four effects are now declared in zone_source\mod_locations.zone and
	//  ship in mod.ff, so they resolve on all six maps. See the block there for
	//  the measurement that showed re-adding them is safe (shared assets are
	//  byte-identical across maps; only DIFFERING copies matter in a collision).
	//
	//  The else branch is deliberately KEPT rather than deleted. It is the
	//  fallback if these ever fail to resolve, and its comments are a worked
	//  record of four rounds of picking substitutes - worth keeping so nobody
	//  repeats that search. It simply should not be reachable now.
	if ( isdefined( level._effect ) )
	{
		level._effect[ "wunderfizz_loop" ]       = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_on" );
		level._effect[ "perk_machine_light" ]    = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_light" );
		level._effect[ "perk_machine_location" ] = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_identify" );
		level._effect[ "perk_machine_steam" ]    = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_steam" );
	}
	else
	{
		//  ?? v1.34.0's PICKS WERE PRESENT AND STILL INVISIBLE - a second, separate
		//  failure from v1.30's. Availability was fixed; VISIBILITY was not.
		//
		//  ?? v1.39.0 - THE "PROOF" THIS PARAGRAPH USED TO GIVE WAS NOT ONE, and it
		//  is left here as a worked example of the mistake. It argued that
		//  zmqol_wf_lightning() plays the location fx and then playsound
		//  ("zmb_hellhound_bolt") on the very next line, so the user hearing the
		//  zap - "the zapping sound effects seem to be normal but there's none of
		//  the electric fx to match" - proved playfx had executed. But
		//  zmb_hellhound_bolt does not exist in any bank a zombies map loads, so
		//  that line made no sound at all and whatever the user heard came from
		//  somewhere else entirely. An inference chained off an unverified asset
		//  is not evidence, however tight the reasoning looks.
		//
		//  The conclusion below happens to be right anyway - fx_elec_spark_emit and
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
		//  ?? READ THIS BEFORE PICKING A FIFTH SET.
		//
		//  There is NO lightning or electric-arc effect available off Origins.
		//  That is not an opinion about taste, it is the whole 226-effect list
		//  that exists on all six maps: the only electrical entries are
		//  fx_elec_sparking_oneshot, fx_elec_wire_spark_burst, fx_elec_spark_emit
		//  (all three are sparking-wire utilities - the user's "it looks like a
		//  power panel that's faulty", which is precisely what they depict) and
		//  fx_emp_explosion_equip. Origins' arcs are fx_tomb_dieselmagic_on, and
		//  shipping it is impossible: OAT can neither dump nor compile an
		//  FxEffectDef, so it cannot be renamed, and the only other route is
		//  --load zm_tomb.ff, which makes mod.ff own Origins' assets and makes
		//  Origins unbootable. Every off-Origins effect here is a stand-in and
		//  always will be.
		//
		//  So the choice is which compromise, and that is now the USER's to make
		//  in-game rather than mine to guess one release at a time:
		//      zmqol_wf_fx 0   EMP discharge   - the closest thing to a zap
		//      zmqol_wf_fx 1   power-up energy - v1.35.0, reads as magic not zap
		//      zmqol_wf_fx 2   sparking wires  - v1.34.0, the "faulty panel"
		//  ?? v1.38.0 - THE EMP BURST IS GONE. It is an explosion, so it threw a
		//  smoke plume: the user's "the visual effects are like too much right
		//  now... i see some cloud like effects". Retriggering it made a machine
		//  wrapped in smoke. Nothing about it was ever electrical-looking.
		//
		//  What replaced it was found by asking a better question. The earlier
		//  search intersected all six maps and concluded no arc effect existed.
		//  That was true of the intersection and WRONG as a conclusion, because
		//  the machine does not need one effect - it needs the best effect ON
		//  EACH MAP. Measured per map, against every zone each one loads:
		//
		//    zm_tomb     fx_tomb_dieselmagic_on            the genuine article
		//    zm_transit  fx_zombie_dog_lightning_spawn     REAL lightning bolts,
		//                  from so_zsurvival_zm_transit.ff - and it is already
		//                  paired with zmb_hellhound_bolt below, the same
		//                  hellhound-spawn strike, so picture and sound finally
		//                  come from the same event
		//    zm_prison   fx_zombie_tesla_shock             tesla arcs
		//    everywhere   weapon/raygun2/fx_zm_raygun2_bolt_emit
		//
		//  The Ray Gun Mark II bolt is the find: a compact BLUE ELECTRICAL bolt
		//  present on all six maps. Weapon-scale rather than explosion-scale, so
		//  it cannot produce the cloud, and it is the closest thing the game has
		//  to Origins' arcs outside Origins.
		n_set = getdvarintdefault( "zmqol_wf_fx", 0 );

		if( n_set == 2 )
		{
			level._effect[ "wunderfizz_loop" ]       = loadfx( "env/electrical/fx_elec_sparking_oneshot" );
			level._effect[ "perk_machine_light" ]    = loadfx( "maps/zombie/fx_zombie_packapunch" );
			level._effect[ "perk_machine_location" ] = loadfx( "system_elements/fx_elec_spark_emit" );
			level._effect[ "perk_machine_steam" ]    = loadfx( "env/electrical/fx_elec_wire_spark_burst" );
		}
		else if( n_set == 1 )
		{
			level._effect[ "wunderfizz_loop" ]       = loadfx( "misc/fx_zombie_powerup_wave" );
			level._effect[ "perk_machine_light" ]    = loadfx( "misc/fx_zombie_powerup_on" );
			level._effect[ "perk_machine_location" ] = loadfx( "weapon/emp/fx_emp_explosion_equip" );
			level._effect[ "perk_machine_steam" ]    = loadfx( "misc/fx_zombie_powerup_grab" );
		}
		else
		{
			//  🛑 v1.43.0 - THE _ug_ VARIANTS, BECAUSE THE STANDARD ONES ARE GREEN.
			//  User: "the effects are now green for some reason, they're meant to be
			//  the wunderfizz fx like the blue electrical fx".
			//
			//  The Ray Gun Mark II fires green. Its PACK-A-PUNCHED form fires blue,
			//  and that is what the parallel weapon/raygun2/fx_zm_raygun2_ug_* family
			//  exists for - the _ug_ set is not a different effect, it is the same
			//  effect recoloured for the upgraded weapon. Same for misc/fx_*_raygun_*
			//  vs misc/fx_*_raygun_ug_* (Ray Gun vs Porter's X2).
			//
			//  This is the ONLY blue electrical option there is. The true global set -
			//  the intersection of all six maps' .ff and _patch.ff, PLUS common_zm.ff
			//  which loads on every zombies map - is 224 effects, and its complete
			//  electrical inventory is:
			//
			//      env/electrical/fx_elec_sparking_oneshot    sparking wire, white
			//      env/electrical/fx_elec_wire_spark_burst    sparking wire, white
			//      system_elements/fx_elec_spark_emit         spark emitter, white
			//      weapon/raygun2/fx_zm_raygun2_bolt_emit     GREEN
			//      weapon/raygun2/fx_zm_raygun2_ug_bolt_emit  BLUE
			//      (+ the raygun2 impacts, same green/_ug_ blue split)
			//
			//  ⚠️ The colour is inferred from what the _ug_ family IS, not observed -
			//  OAT cannot open an FxEffectDef, so no effect in this file has ever been
			//  seen before shipping. zmqol_wf_fx_ug 0 puts the green set back without
			//  a rebuild if the inference is wrong.
			//
			//  📝 And note how the 224 was arrived at: common_zm.ff. An earlier pass
			//  intersected only the six map fastfiles, which is why misc/fx_zombie_powerup_*
			//  below looked absent from every map and was nearly "fixed" - power-up fx
			//  live in common_zm.ff, loaded everywhere. A map's .ff is not the whole
			//  of what a map loads.
			//  🛑 v1.50.0 - OFF THE RAYGUN FAMILY ENTIRELY. User: "the wunderfizz
			//  machine visual fx still aren't quite right they're green and purple
			//  and all that they should all be blue electrical zap effects like
			//  origins."
			//
			//  Both raygun variants were wrong and the _ug_ swap was a wasted
			//  round: the Ray Gun Mark II is green, its Pack-a-Punched form is
			//  PURPLE, and neither is blue. That was inferred from the naming
			//  rather than observed, and the note above it said so.
			//
			//  What was wrong before that is the actual mistake: the search was
			//  restricted to effects present on ALL SIX maps, and that intersection
			//  is 224 effects with no blue electrical entry in it. The machine does
			//  not need one effect - it needs the best effect ON EACH MAP, which is
			//  the same realisation the location marker reached back in v1.40.0 and
			//  then lost when the marker was unified. Measured per map:
			//
			//    zm_tomb                     fx_tomb_dieselmagic_*      the genuine
			//    transit/buried/prison/highrise
			//                                electrical/fx_elec_player_torso   arcs
			//                                electrical/fx_elec_player_md      zap
			//    zm_nuked                    electrical/fx_zm_elec_arc_vert
			//
			//  fx_elec_player_* is the TranZit electric trap's electrocution
			//  effect - blue arcs crawling over a body-sized volume, which is as
			//  close to Origins' dieselmagic arcs as anything outside Origins gets.
			//  Nuketown is the one map without it; fx_zm_elec_arc_vert is its own
			//  electrical arc and the only one it has.
			//
			//  ✅ ONE-SHOT, VERIFIED, NOT ASSUMED. _zm_traps.gsc:682-714 plays each
			//  of these with a single playfxontag per electrocution - no loop, no
			//  stopfx - so retriggering on a beat is the correct way to hold them
			//  on screen, and cannot produce the stacking blob that a looping
			//  effect would.
			str_arc = "electrical/fx_elec_player_torso";
			str_zap = "electrical/fx_elec_player_md";

			if( level.script == "zm_nuked" )
			{
				str_arc = "electrical/fx_zm_elec_arc_vert";
				str_zap = "electrical/fx_zm_elec_arc_vert";
			}

			//  zmqol_wf_fx_ug 1 goes back to the raygun set for A/B comparison.
			if( getdvarintdefault( "zmqol_wf_fx_ug", 0 ) )
			{
				str_arc = "weapon/raygun2/fx_zm_raygun2_ug_bolt_emit";
				str_zap = "weapon/raygun2/fx_zm_raygun2_ug_impact";
			}

			level._effect[ "wunderfizz_loop" ]    = loadfx( str_arc );
			level._effect[ "perk_machine_light" ] = loadfx( "misc/fx_zombie_powerup_on" );
			level._effect[ "perk_machine_steam" ] = loadfx( "misc/fx_zombie_powerup_grab" );

			//  🛑 v1.42.0 - THE PER-MAP "BEST" MARKERS ARE GONE, and picking them was
			//  a category error worth recording. v1.40.0 asked "what is the best
			//  electrical effect on each map" and answered with a hellhound spawn
			//  strike on TranZit and a tesla shock on Mob. Both are excellent
			//  lightning. Both are also authored to be seen from ANYWHERE ON THE
			//  MAP - that is a spawn cue's entire job - so firing one every 7-10
			//  seconds put a lightning bolt over the skyline of a map the player was
			//  nowhere near. The user: "i can see some of the effects sometimes when
			//  im on the other side of the map, like the bright blue flashing effect
			//  specifically".
			//
			//  "Best-looking up close" and "right size" are different questions and
			//  only the second one matters for something that fires unattended. The
			//  raygun impact is a point burst the size of a bullet hit, which is what
			//  a marker on a machine should be. It takes the blue electrical set
			//  above for the same reason everything else does - and being a
			//  body-scale electrocution rather than a spawn cue, it is still small
			//  enough not to be seen across the map, which was v1.42.0's fix.
			level._effect[ "perk_machine_location" ] = loadfx( str_zap );
		}

		level.zmqol_wf_fx_set = n_set;
	}

	//  The location fx fires at the orb's height off Origins (an EMP burst
	//  centred on the floor would be half-buried in it), but Origins' own
	//  identify beam is authored to rise FROM the base, so it keeps self.origin.
	//  Origins' identify beam is authored to rise FROM the ground, so it wants the
	//  true origin. The raygun impact used on every other map is a point burst and
	//  wants to be up at the orb. TranZit was in the first group only while it used
	//  the hellhound strike, which also rose from the ground; it takes the raygun
	//  impact now like everything else, so it belongs in the second.
	if( level.script == "zm_tomb" )
		level.zmqol_wf_marker_z = 0;
	else
		level.zmqol_wf_marker_z = 72;

	if(level.script == "zm_tomb")
    {
		//  ====================================================================
		//  v1.58.0 - THE MOD'S MACHINES NOW REPLACE ORIGINS' NATIVE SIX.
		//
		//  This branch used to be empty, on an earlier instruction to keep the
		//  vanilla machines. The user reversed that on 2026-08-07 after the
		//  vanilla ones misbehaved with the mod's perk list - duplicate bottles
		//  for perks already owned, and bottles landing off to the left:
		//  "get rid of the actual pre-existing wunderfizz machines from origins,
		//  and just put the custom ones that are already good and working."
		//
		//  🛑 THERE ARE SIX, NOT FOUR. An earlier comment in this file claimed
		//  four and it was wrong; the user corrected it and the map settles it.
		//  Counted from the real thing - Unlinker mapents dump of zm_tomb.ff:
		//  6 x classname script_model / targetname random_perk_machine, one per
		//  generator, model p6_zm_vending_diesel_magic. Two of them additionally
		//  carry script_noteworthy "start_machine", which is stock's random pick
		//  of a starting location.
		//
		//  🌟 POSITIONS ARE READ FROM THE MAP, NEVER TYPED. Whatever Treyarch
		//  placed is what the mod's machines inherit - origin AND angles - so
		//  they cannot drift from vanilla and there is no coordinate here to get
		//  wrong. It also means this is self-correcting if the count is ever
		//  different from six on a variant of the map.
		//
		//  The native entities are NOT deleted, only hidden - see
		//  scripts\zm\zm_tomb\zm_tomb.gsc::zmqol_hide_native_wunderfizz. They
		//  stay alive to receive .is_locked from Origins' own capture-zone code,
		//  which is how the generator gating survives this swap.
		//  ====================================================================
		a_native = getentarray( "random_perk_machine", "targetname" );

		for( i = 0; i < a_native.size; i++ )
		{
			if( !isdefined( a_native[i] ) )
				continue;

			zmqol_wf_add( a_native[i].origin, a_native[i].angles, zmqol_wf_machine_model() );
		}

		println( "[zm_qol] wunderfizz: origins - mirrored " + a_native.size + " native machine location(s)" );
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

    	//  TOWN - in the BAR, on the wall by the pool table.
    	//
    	//  ?? THIS IS A SEED PLUS AN AIM, NOT THE FINAL POSITION. Both numbers come
    	//  straight off a screenshot: the user stood at (2117,593,-55) with yaw 184
    	//  and put their crosshair on the wall they wanted. zmqol_wf_wall_snap()
    	//  traces that exact line at eye height, finds the wall, backs the machine
    	//  off it and turns it around to face the room. So the machine ends up
    	//  where the crosshair was pointing, measured on the real geometry.
    	//
    	//  Why traced rather than written down, again: the barber-shop attempt
    	//  before this one had no wall data in mapents either, and the attempt
    	//  before THAT (a hardcoded coordinate) put the machine in a sealed bunker
    	//  under the street. The engine knows where the walls are; ask it.
    	//
    	//  Previous positions, all superseded: (1823,114,88) was 30 units inside
    	//  Quick Revive in survival; the automatic relocation that fixed it landed
    	//  somewhere nobody asked for; the barber shop corner was right but not
    	//  where the machine was wanted.
    	zmqol_wf_add((2117,593,-55), (0,4,0), zmqol_wf_machine_model());
    	level.zmqol_wf_pending[ level.zmqol_wf_pending.size - 1 ].snap_yaw = 184;
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
//  ?? THE BUG: on Bus Depot and Farm survival the user found ONE machine, and it
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
//  ?? v1.19.1 TRIED THE ZONE MANAGER AND IT DOES NOT DISCRIMINATE. The theory was
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
//  ?? NEVER RETURNS NOTHING. If no machine clears the threshold - an arena whose
//  spawns are further out than expected - the single CLOSEST one is kept rather
//  than the whole list. One reachable machine that stays put is the requested
//  behaviour; falling back to all six would just reproduce the bug.
// ============================================================================
// ============================================================================
//  zmqol_wf_tomb_native_for  -  the hidden vanilla machine standing at this
//  spot, or undefined off Origins.
//
//  The mod's machines are placed AT the six native origins (see the zm_tomb
//  branch of setupWunderfizz), so "nearest native" is an exact pairing, not an
//  approximation - the distance is zero. Nearest-by-distance is used rather
//  than pairing by array index because zmqol_wf_place() may filter or reorder
//  the pending list, and an index pairing would then silently point a machine
//  at the wrong generator's lock.
//
//  Looked up ONCE per machine and cached by the caller; this walks six
//  entities and must not run in a polling loop.
// ============================================================================
zmqol_wf_tomb_native_for( v_origin )
{
	if( level.script != "zm_tomb" )
		return undefined;

	a_native = getentarray( "random_perk_machine", "targetname" );
	e_best   = undefined;
	n_best   = 0;

	for( i = 0; i < a_native.size; i++ )
	{
		if( !isdefined( a_native[i] ) )
			continue;

		n_dist = distancesquared( v_origin, a_native[i].origin );

		if( !isdefined( e_best ) || n_dist < n_best )
		{
			e_best = a_native[i];
			n_best = n_dist;
		}
	}

	return e_best;
}

// ============================================================================
//  zmqol_wf_tomb_locked  -  is this machine's generator still off?
//
//  Origins has no global "power_on" flag; power is per zone and per generator.
//  zm_tomb_capture_zones.gsc sets .is_locked on every random_perk_machine in a
//  zone - 0 when that generator is captured, 1 when it is lost - through
//  enable_random_perk_machines_in_zone() / disable_random_perk_machines_in_zone().
//
//  Reading it back means the gating IS stock's, not a reimplementation of it,
//  so it cannot drift from vanilla behaviour and it keeps working if a zone is
//  contested and lost again later.
//
//  Defaults to UNLOCKED when the flag is missing. .is_locked is undefined until
//  the capture-zone code first touches a machine, and defaulting to locked
//  would leave a machine permanently unusable if that never happened.
// ============================================================================
zmqol_wf_tomb_locked( e_native )
{
	if( !isdefined( e_native ) )
		return false;

	if( !isdefined( e_native.is_locked ) )
		return false;

	return ( e_native.is_locked == 1 );
}

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

	//  🛑 ORIGINS SKIPS EVERY POSITION ADJUSTER, ON PURPOSE.
	//
	//  On every other map these coordinates are the mod's own picks and need
	//  vetting - moved off perk machines, snapped to walls, pushed out of
	//  geometry. On Origins they are TREYARCH'S OWN machine positions, read
	//  straight out of the map by the zm_tomb branch above. They are correct by
	//  definition and must arrive unmodified, or the swap stops being seamless.
	//
	//  zmqol_wf_clear_of_perk_machines is the dangerous one: it DROPS entries,
	//  and it would be judging vanilla Wunderfizz spots against the mod's own
	//  clearance rule. Origins packs perks tightly - a single rejection there
	//  means a generator with no machine at all, which reads in game as "the
	//  replacement is broken". zmqol_wf_unclip would also nudge a machine that
	//  is already sitting exactly where it belongs.
	if( level.script != "zm_tomb" )
	{
		a_place = zmqol_wf_clear_of_perk_machines( a_place );

		for( i = 0; i < a_place.size; i++ )
		{
			if( isdefined( a_place[i].snap_yaw ) )
				a_place[i] = zmqol_wf_wall_snap( a_place[i] );
		}

		//  Every machine, on every other map, gets pushed out of whatever it is
		//  buried in.
		for( i = 0; i < a_place.size; i++ )
			a_place[i] = zmqol_wf_unclip( a_place[i] );
	}

	for( i = 0; i < a_place.size; i++ )
		wunderfizzSetup( a_place[i].origin, a_place[i].angles, a_place[i].model );

	level.zmqol_wf_pending = [];
	println( "[zm_qol] wunderfizz: placed " + a_place.size + " of " + n_candidates + " candidate location(s)" );
}

// ============================================================================
//  zmqol_wf_clear_of_perk_machines
//
//  ?? THE BUG: on TOWN survival the Wunderfizz spawned INSIDE the Quick Revive
//  machine. Not near it - the same spot, same facing.
//
//      this mod's town candidate   (1823, 114,   88)  yaw 90
//      stock Quick Revive struct   (1812, 142.5, 88)  yaw 90
//
//  30 units apart, identical Z, identical angle. The coordinate is not wrong; it
//  is STALE. That struct carries script_string "zgrief_perks_town
//  zstandard_perks_town" - survival and grief only. Classic TranZit puts Quick
//  Revive at the bus depot and leaves that corner of Town empty, which is where
//  the upstream mod's coordinate came from and why it looks fine in classic and
//  only collides in survival. Confirmed out of zm_transit's mapents, not guessed.
//
//  So the machine set is per gametype+location, and any hardcoded coordinate can
//  be legal in one mode and occupied in another. Rather than move one number and
//  wait to find the next one in game, this asks the map the same question stock
//  asks and relocates whatever actually clashes, on all six maps.
//
//  WHERE IT MOVES TO. Not an offset - a nudge risks a wall or a float, and there
//  is no way to check that offline. It moves to an UNUSED stock perk-machine
//  struct: a spot Treyarch authored for a vending machine, flat, wall-backed,
//  clear at the front, with its own correct angles - that this gametype+location
//  does not fill. Those are exactly the structs whose script_string does NOT
//  contain the current match string. Every fallback position is therefore a real
//  shipped machine placement, and no coordinate is invented here.
//
//  ?? v1.39.1 - "UNUSED" IS NOT ENOUGH. IT MUST BE AUTHORED FOR THIS LOCATION.
//  v1.39.0 accepted any unused struct within 2500 units of a gametype spawn, and
//  on Town it put the machine UNDER THE MAP - in the death barrier:
//
//      [zm_qol] wunderfizz: candidate 1 overlaps a perk machine - moved 752
//                           units to a free one
//
//  752 units lands on (2405.1, -155, -305.5): classic TranZit's Pack-a-Punch, in
//  the sealed bunker 393 units BELOW the Town street. It passed every test. It is
//  a genuine authored machine spot, it is not used by zstandard_perks_town, and
//  it is ~1078 units from a Town spawn - comfortably inside the threshold.
//
//  Because distance-to-spawn is a STRAIGHT LINE IN 3D and knows nothing about
//  floors. A sealed room directly underneath the arena is metres away by that
//  measure and unreachable in fact. Do not try to patch this with a Z tolerance:
//  the arenas are not flat, Die Rise is stacked vertically, and the number would
//  be a guess.
//
//  The structural fix is to stop asking "is it near?" and ask "was it authored
//  for THIS LOCATION?". A script_string token is <gametype>_perks_<location>, so
//  a token ending in "_perks_town" belongs to the Town arena whoever spawns it.
//  Treyarch placed it inside the same playable space; no distance heuristic is
//  needed and none is trusted. Town's alternates are now exactly the two
//  znml_perks_town spots by the bar - both beside the live Double Tap, both
//  demonstrably in the arena - and the classic-TranZit spots that caused this
//  (script_string "zclassic_perks_transit", location "transit") are excluded by
//  construction, along with every Farm, Diner and Cornfield spot.
//
//  The spawn-distance check is kept as a second gate, not the first one.
//
//  The match-string construction is stock's, copied from _zm_perks.gsc:2835-2847
//  (scr_zm_ui_gametype + "_perks_" + location, location falling back to
//  level.default_start_location) so it cannot disagree with the machines that
//  actually spawn.
//
//  ?? NEVER DROPS A MACHINE. If nothing free is far enough away, the original
//  position is kept - overlapping a perk machine still beats no Wunderfizz.
// ============================================================================
zmqol_wf_clear_of_perk_machines( a_place )
{
	n_clear = 72;   // stock's collision cylinder is 32 wide and its bump trigger 35

	a_structs = getstructarray( "zm_perk_machine", "targetname" );

	if( !isdefined( a_structs ) || a_structs.size < 1 )
		return a_place;

	str_loc = level.scr_zm_map_start_location;

	if( ( !isdefined( str_loc ) || str_loc == "default" || str_loc == "" ) && isdefined( level.default_start_location ) )
		str_loc = level.default_start_location;

	if( !isdefined( str_loc ) )
		return a_place;

	str_match  = level.scr_zm_ui_gametype + "_perks_" + str_loc;
	str_suffix = "_perks_" + str_loc;

	a_taken = [];   // machines this gametype+location really spawns
	a_free  = [];   // spots authored for THIS LOCATION that it leaves empty

	for( i = 0; i < a_structs.size; i++ )
	{
		if( !isdefined( a_structs[i].origin ) )
			continue;

		if( !isdefined( a_structs[i].script_string ) )
		{
			a_taken[ a_taken.size ] = a_structs[i];   // no script_string: stock spawns it everywhere
			continue;
		}

		b_used = 0;
		b_here = 0;

		a_tok = strtok( a_structs[i].script_string, " " );

		for( t = 0; t < a_tok.size; t++ )
		{
			if( a_tok[t] == str_match )
				b_used = 1;

			//  Same location, any gametype - "znml_perks_town" when we are
			//  zstandard_perks_town. See the ?? below for why this matters.
			if( a_tok[t].size > str_suffix.size )
			{
				if( getsubstr( a_tok[t], a_tok[t].size - str_suffix.size, a_tok[t].size ) == str_suffix )
					b_here = 1;
			}
		}

		if( b_used )
			a_taken[ a_taken.size ] = a_structs[i];
		else if( b_here )
			a_free[ a_free.size ] = a_structs[i];
	}

	for( i = 0; i < a_place.size; i++ )
	{
		if( zmqol_wf_dist_to_nearest_struct( a_place[i].origin, a_taken ) >= n_clear )
			continue;

		s_alt = zmqol_wf_nearest_free_spot( a_place[i].origin, a_free, a_taken, n_clear );

		if( !isdefined( s_alt ) )
		{
			println( "[zm_qol] wunderfizz: candidate " + ( i + 1 ) + " overlaps a perk machine and there is no free authored spot - keeping it" );
			continue;
		}

		println( "[zm_qol] wunderfizz: candidate " + ( i + 1 ) + " overlaps a perk machine - moved " + int( distance( a_place[i].origin, s_alt.origin ) ) + " units to a free one" );

		a_place[i].origin = s_alt.origin;

		if( isdefined( s_alt.angles ) )
			a_place[i].angles = s_alt.angles;
	}

	return a_place;
}

//  Nearest unused spot that is itself clear of every live machine. a_free is
//  already restricted to structs authored for THIS location, which is what keeps
//  the result in the arena; the spawn-distance test below is only a backstop for
//  a location whose structs sprawl further than expected.
zmqol_wf_nearest_free_spot( v_origin, a_free, a_taken, n_clear )
{
	s_best = undefined;
	n_best = 0;

	a_spawns = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

	for( i = 0; i < a_free.size; i++ )
	{
		if( zmqol_wf_dist_to_nearest_struct( a_free[i].origin, a_taken ) < n_clear )
			continue;

		if( isdefined( a_spawns ) && a_spawns.size > 0 )
		{
			if( zmqol_wf_dist_to_nearest( a_free[i].origin, a_spawns ) > 2500 )
				continue;
		}

		n_dist = distance( v_origin, a_free[i].origin );

		if( !isdefined( s_best ) || n_dist < n_best )
		{
			s_best = a_free[i];
			n_best = n_dist;
		}
	}

	return s_best;
}

// ============================================================================
//  zmqol_wf_wall_snap  -  put the machine where the crosshair was pointing
//
//  Takes a seed point and a yaw - literally a player's position and facing, off
//  a screenshot - traces that line at eye height, and returns the spot against
//  the wall it hits, floored, turned around to face back down the line.
//
//  WHY THIS SHAPE. Asking "which wall?" in words has failed three times running
//  on this one machine: a hardcoded coordinate landed inside Quick Revive, the
//  automatic relocation that fixed that landed in a sealed bunker UNDER the
//  street, and a traced room corner was right but not the corner wanted. A
//  screenshot with .where in it carries the answer exactly - where the user
//  stood and what they were looking at - and this turns those two numbers into
//  a position on the real geometry. No wall coordinate is ever written down.
//
//  ?? TRACED AT EYE HEIGHT, NOT KNEE HEIGHT. The bar has a counter along the
//  wall; a trace at floor+40 stops on the counter and the machine ends up
//  standing in the middle of the room instead of against the wall. +60 is
//  roughly where a standing player's view leaves from, which is what the
//  crosshair in the screenshot was.
//
//  ?? IT NEVER RETURNS SOMETHING WORSE THAN THE SEED. If the trace hits nothing
//  the seed is kept and the reason is logged. The seed is a spot a player was
//  demonstrably standing on, so the failure mode is "in the right room, wrong
//  spot" rather than "inside the world".
// ============================================================================
zmqol_wf_wall_snap( s_place )
{
	v_seed  = s_place.origin;
	n_yaw   = s_place.snap_yaw;

	//  38 -> 26 -> 30. v1.42.0 went to 26 on "push it towards the wall just a tiny
	//  bit more"; at 26 the user reports it "very slightly clipping into the wall".
	//  So the model's half-depth is somewhere just under 30, not the 16 the
	//  collision cylinder suggested - the cabinet is deeper than the cylinder it
	//  blocks with, which is why the cylinder was never the right thing to measure
	//  from. 30 is one step back out from the first value that visibly touched.
	//
	//  Still a dvar. Two builds have now been spent on a number that console can
	//  settle in seconds, and the answer is a matter of taste either way.
	n_clear = getdvarintdefault( "zmqol_wf_wall_gap", 30 );
	n_reach = 900;
	n_eye   = 60;

	v_dir = anglestoforward( ( 0, n_yaw, 0 ) );
	v_from = ( v_seed[0], v_seed[1], v_seed[2] + n_eye );
	v_to   = v_from + ( v_dir[0] * n_reach, v_dir[1] * n_reach, 0 );

	trace = bullettrace( v_from, v_to, 0, undefined );

	if( trace[ "fraction" ] >= 1 )
	{
		println( "[zm_qol] wunderfizz: wall snap found no wall along yaw " + n_yaw + " - keeping the seed" );
		return s_place;
	}

	v_hit = trace[ "position" ];

	//  🛑 THE FACING COMES OFF THE WALL, NOT OFF THE PLAYER. v1.41.1 used the seed
	//  yaw for both the trace AND the machine's angle, so the machine ended up
	//  rotated by however far the player's aim was off perpendicular - here the
	//  seed yaw is 184 against a wall that runs due north-south, and the user
	//  reported the machine "slightly tilted off axis". Four degrees, exactly the
	//  184-180 the seed carried.
	//
	//  bullettrace returns the surface normal of what it hit (stock uses
	//  trace["normal"] this way in dom.gsc:322 and _remotemortar.gsc:540), and
	//  that vector is perpendicular to the wall by construction. Flattened to the
	//  horizontal it is the exact direction the machine should face, no matter
	//  how sloppily the seed shot was aimed.
	v_out = undefined;

	if( isdefined( trace[ "normal" ] ) )
	{
		v_flat = ( trace[ "normal" ][0], trace[ "normal" ][1], 0 );

		//  A floor or ceiling hit has no horizontal normal to work with.
		if( length( v_flat ) > 0.1 )
			v_out = vectornormalize( v_flat );
	}

	//  No usable normal - fall back to v1.41.1's behaviour rather than to nothing.
	if( !isdefined( v_out ) )
		v_out = ( 0 - v_dir[0], 0 - v_dir[1], 0 );

	n_out = vectortoangles( v_out )[1];

	while( n_out < 0 )
		n_out += 360;
	while( n_out >= 360 )
		n_out -= 360;

	//  Then snap to the nearest axis if the wall is already within a few degrees
	//  of one. Brush walls are usually axis-aligned but a traced normal comes back
	//  off whatever surface the ray actually touched - a bevel, a trim piece, a
	//  decal brush - and a degree or two of that is still visible on a big flat
	//  cabinet. Only inside the tolerance, so a genuinely angled wall is left
	//  alone instead of being wrenched onto an axis it was never on.
	n_axis = int( ( n_out + 45 ) / 90 ) * 90;

	if( n_axis >= 360 )
		n_axis -= 360;

	n_off_axis = abs( n_out - n_axis );

	if( n_off_axis > 180 )
		n_off_axis = 360 - n_off_axis;

	if( n_off_axis <= getdvarintdefault( "zmqol_wf_axis_snap", 8 ) )
		n_out = n_axis;

	//  Back off PERPENDICULAR to the wall, not along the line we came in on. Off
	//  the perpendicular the machine sits at an angle to the surface it is meant
	//  to be flush with, which is the other half of what the user saw.
	v_out = anglestoforward( ( 0, n_out, 0 ) );

	v_at = ( v_hit[0] + ( v_out[0] * n_clear ), v_hit[1] + ( v_out[1] * n_clear ), v_seed[2] );

	s_place.origin = ( v_at[0], v_at[1], zmqol_wf_trace_floor( v_at ) );

	//  🛑 PLUS 90, BECAUSE THE MODEL'S FRONT IS NOT ITS +X. v1.41.0 set the yaw to
	//  exactly "away from the wall" and the machine stood side-on. The convention
	//  comes off an earlier screenshot: at the relocated (1967,-1297.8,-54.2) spot
	//  the struct angle was yaw 0 and the machine presented its FRONT to a player
	//  looking north, i.e. at yaw 0 the front faces -Y. So front direction =
	//  placement yaw - 90.
	//
	//  Left as a dvar because it is derived from one screenshot rather than from
	//  the model, and 0/90/180/270 in console beats another build to test the
	//  other three. It only affects this traced placement - the five hand-placed
	//  maps keep their own angles.
	s_place.angles = ( 0, n_out + getdvarintdefault( "zmqol_wf_yaw_off", 90 ), 0 );

	println( "[zm_qol] wunderfizz: wall snap (" + int( v_seed[0] ) + "," + int( v_seed[1] ) + "," + int( v_seed[2] ) + ") seed yaw " + n_yaw + " -> (" + int( s_place.origin[0] ) + "," + int( s_place.origin[1] ) + "," + int( s_place.origin[2] ) + ") wall normal yaw " + int( n_out ) + ", gap " + n_clear + ", wall was " + int( distance( v_from, v_hit ) ) + " away" );

	return s_place;
}

// ============================================================================
//  zmqol_wf_unclip  -  no machine ends up sunk into a wall, on any map
//
//  User: "on tranzit / bus depot the wunderfizz machine is slightly pushed in too
//  far into the wall here, just move it forwards a small amount... also the
//  wunderfizz in the tunnel in tranzit is slightly clipped into the wall so move
//  that one forwards as well, make sure none of the wunderfizz machines on any
//  maps that were added via my mod are not slightly clipped into the wall."
//
//  Fixing the two reported coordinates by hand would have left twenty-odd others
//  unchecked, on maps nobody has walked yet. So this measures instead: it traces
//  backwards out of every machine and pushes it forward by however much it is
//  short. A placement that already clears its wall is not touched at all.
//
//  🛑 THE 29 IS MEASURED, NOT CHOSEN. Dumped the mod's own machine model with
//      Unlinker --include-assets xmodel --model-format GLB
//  and read the POSITION accessor bounds out of the GLB's JSON chunk:
//
//      74 wide    55.8 deep    108 tall
//
//  and the depth runs -28.8 to +27.1 about the origin, so the back face sits
//  28.8 units behind it. 29 is that plus a unit of daylight.
//
//  📝 That number independently confirms zmqol_wf_wall_gap's 30, which was arrived
//  at by two rounds of trial and error against the user's eye. Worth noting for
//  next time: the answer was readable offline the whole way through.
//
//  Traced at +40 rather than at the origin because the origin sits on the floor,
//  where a trace catches the skirting, a kerb or the floor bevel instead of the
//  wall the cabinet's back actually meets.
// ============================================================================
zmqol_wf_unclip( s_place )
{
	n_need = getdvarintdefault( "zmqol_wf_wall_gap", 30 );

	//  front = placement yaw - 90 for this model (zmqol_wf_wall_snap explains the
	//  convention), so the back faces placement yaw + 90.
	v_back  = anglestoforward( ( 0, s_place.angles[1] + 90, 0 ) );
	v_front = ( 0 - v_back[0], 0 - v_back[1], 0 );

	v_from = s_place.origin + ( 0, 0, 40 );
	v_to   = v_from + ( v_back[0] * n_need, v_back[1] * n_need, 0 );

	trace = bullettrace( v_from, v_to, 0, undefined );

	if( trace[ "fraction" ] >= 1 )
		return s_place;

	n_have = n_need * trace[ "fraction" ];
	n_push = n_need - n_have;

	//  Sub-unit corrections are noise, not clipping.
	if( n_push < 1 )
		return s_place;

	s_place.origin = s_place.origin + ( v_front[0] * n_push, v_front[1] * n_push, 0 );

	println( "[zm_qol] wunderfizz: unclipped by " + int( n_push ) + " (wall was " + int( n_have ) + " behind, wanted " + n_need + ") -> (" + int( s_place.origin[0] ) + "," + int( s_place.origin[1] ) + "," + int( s_place.origin[2] ) + ")" );

	return s_place;
}

//  Straight down from well above the point, to well below it.
zmqol_wf_trace_floor( v_pos )
{
	trace = bullettrace( v_pos + ( 0, 0, 72 ), v_pos - ( 0, 0, 160 ), 0, undefined );

	if( trace[ "fraction" ] >= 1 )
		return v_pos[2];

	return trace[ "position" ][2];
}

zmqol_wf_dist_to_nearest_struct( v_origin, a_structs )
{
	if( !isdefined( a_structs ) || a_structs.size < 1 )
		return 999999;

	n_best = distance( v_origin, a_structs[0].origin );

	for( i = 1; i < a_structs.size; i++ )
	{
		n_dist = distance( v_origin, a_structs[i].origin );

		if( n_dist < n_best )
			n_best = n_dist;
	}

	return n_best;
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
	//  ?? WAS "t6_wpn_zmb_perk_bottle_vultureaid_world" - AN ASSET THAT DOES NOT
	//  EXIST. The real model is ..._vulture_world. Unlinker --list across every
	//  map zone plus mod.ff finds exactly two spellings, vulture and whoswho, and
	//  neither "vultureaid" nor "chugabud" appears anywhere in the game.
	if(perk == "specialty_nomotionsensor")
		return "t6_wpn_zmb_perk_bottle_vulture_world";
	if(perk == "specialty_fastreload")
		return "t6_wpn_zmb_perk_bottle_sleight_world";
	if(perk == "specialty_flakjacket")
		return "t6_wpn_zmb_perk_bottle_nuke_world";
	if(perk == "specialty_quickrevive")
		return "t6_wpn_zmb_perk_bottle_revive_world";
	if(perk == "specialty_scavenger")
		return "t6_wpn_zmb_perk_bottle_tombstone_world";
	//  ?? Same bug: the asset is ..._whoswho_world, not "..._chugabud_world".
	//  "chugabud" is the PERK's internal name and the VENDING model's name
	//  (p6_zm_vending_chugabud), but the bottle it dispenses is Who's Who.
	if(perk == "specialty_finalstand")
		return "t6_wpn_zmb_perk_bottle_whoswho_world";
	if(perk == "specialty_grenadepulldeath")
		return "t6_wpn_zmb_perk_bottle_cherry_world";
	if(perk == "specialty_additionalprimaryweapon")
		return "t6_wpn_zmb_perk_bottle_mule_kick_world";
	if(perk == "specialty_deadshot")
		return "t6_wpn_zmb_perk_bottle_deadshot_world";

	//  ?? THIS FALLBACK IS THE ACTUAL FIX FOR "the bottle is invisible".
	//  Falling off the end returned UNDEFINED, and self.bottle setModel(undefined)
	//  kills the thread that owns the machine - which is why it always struck on
	//  the last perk (the one perk left is by definition the odd one out) and why
	//  the machine stayed broken afterwards.
	//
	//  The teddy bear is the right stand-in: main() already precaches it, it is
	//  the model this machine legitimately shows on departure, and a mystery box
	//  bear reads as intentional rather than as a hole.
	return "zombie_teddybear";
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

	//  PROBE (passive, one line, first machine only). The user reports Who's Who
	//  "never offered by the Wunderfizz" on Origins, yet every offline check says
	//  it should be: zmqol_whoswho_enabled() excludes only Die Rise and Mob, the
	//  flag is set in perks() during main() which runs well before this, the boot
	//  log confirms stock's turn_chugabud_on ran, and getPerkName/getPerkModel/
	//  getPerkBottleModel all have specialty_finalstand entries.
	//
	//  So rather than guess a fifth time, print what this machine was ACTUALLY
	//  built with. The list is snapshotted HERE, once, and never rebuilt - so if
	//  specialty_finalstand is absent from this line it was absent at map init
	//  and no amount of spinning could ever produce it.
	if( !isdefined( level.zmqol_wf_logged_perks ) )
	{
		level.zmqol_wf_logged_perks = 1;
		str_list = "";

		for( i = 0; i < perks.size; i++ )
			str_list = str_list + perks[i] + " ";

		println( "[zm_qol] wunderfizz: perk list (" + perks.size + ") = " + str_list );
	}

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
	//  Origins' generator, cached once. Undefined on every other map, which is
	//  what makes every zm_tomb test below cost nothing elsewhere.
	e_native_gen = zmqol_wf_tomb_native_for( origin );

	// ========================================================================
	//  v1.58.1 - THE STATIC GLOW ANCHOR. This is stock's self.glow_location.
	//
	//  User, 2026-08-07: "the visual effects spin around and look all funky
	//  whenever i buy from the wunderfizz machine and spin it, the effects are
	//  supposed to be near identical to the original fx."
	//
	//  Correct, and the cause is exact. _zm_perk_random.csc attaches each
	//  effect to a SPECIFIC anchor, and only one of them is the ball:
	//
	//      perk_machine_light                 -> "j_ball"      (ball glow)
	//      perk_machine_light_red / _green    -> "tag_origin"  (machine)
	//      perk_machine_steam                 -> "tag_origin"  (machine)
	//      perk_machine_activation_electric_loop
	//                                         -> self.glow_location "tag_origin"
	//
	//  That last one - fx_tomb_dieselmagic_on, this file's "wunderfizz_loop" -
	//  was being played on "j_ball" here. j_ball SPINS during a purchase
	//  (%qolwf_diesel_ballspin_loop), so the whole electrical effect rotated
	//  with it. Stock hangs it on a separate, motionless script_model instead,
	//  which is why stock's never wheels around.
	//
	//  Built the same way stock builds it (_zm_perk_random.gsc::machines_setup):
	//  a script_model on "tag_origin", 65 units above the machine, sharing the
	//  machine's angles.
	// ========================================================================
	self.zmqol_wf_glow_loc = spawn( "script_model", origin + ( 0, 0, 65 ) );
	self.zmqol_wf_glow_loc setmodel( "tag_origin" );
	self.zmqol_wf_glow_loc.angles = angles;

	//  🛑 The ball must be PUT AWAY on every machine that is not the live one.
	//
	//  User: "some of the machines still have the ball at the top even though
	//  they're not the active machine, but others have the ball fly away like
	//  they're supposed to when they move."
	//
	//  Both halves of that are one bug. The ball only ever left because a
	//  DEPARTING machine plays "shut_down" on its way out - so a machine that
	//  has never once been active never played it and sat there holding a ball
	//  it should not have. Worse on Origins: a machine whose generator is still
	//  off blocks in the power gate below and never even reaches the dormant
	//  branch, which is why the unpowered generators kept theirs.
	//
	//  Setting the off pose HERE, before the power gate, covers all three cases
	//  - never-active, dormant, and generator-locked.
	//
	//  Deliberately the animation rather than stock's hidepart( "j_ball" ):
	//  hidepart needs a part on the model, and this is the mod's REBUILT model,
	//  where only the j_ball TAG is confirmed to exist (it is used by
	//  playfxontag/gettagorigin). The animtree is the mod's own and is known to
	//  drive this machine already.
	if( level.currentWunderfizzLocation != self.location )
		self zmqol_wf_anim( "shut_down" );

	if( level.script == "zm_tomb" )
	{
		//  🛑 ORIGINS DOES NOT HAVE "power_on". Power there is per generator,
		//  per zone, and it can be LOST again when a zone is contested - so this
		//  cannot be a one-shot flag_wait like the branch below. The live check
		//  is repeated in the buy loop as well; this one only holds the machine
		//  before it first goes live.
		trig SetHintString( "Activate the Generator First" );

		while( zmqol_wf_tomb_locked( e_native_gen ) )
			wait 0.5;

		trig SetHintString(" ");
	}
	else if(level.wunderfizzChecksPower && level.script != "zm_prison" && level.script != "zm_nuked")
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
			// ?? The bottle is force-hidden on arrival. The user hit "just before
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
				//  🛑 RE-CHECK THE GENERATOR EVERY PASS, do not trust the gate
				//  above. Origins zones can be lost after being captured, and a
				//  machine that went live once must lock again if its generator
				//  goes down. Skipping straight back to the top also means no
				//  `trig waittill("trigger")` is armed while locked, so there is
				//  no buy prompt and no way to purchase - "visible but locked",
				//  which is the behaviour the user picked and what stock does.
				if( zmqol_wf_tomb_locked( e_native_gen ) )
				{
					trig SetHintString( "Activate the Generator First" );
					wait 0.5;
					continue;
				}

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
							self.zmqol_wf_cycling = 1;
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
							self.zmqol_wf_cycling = 0;
							if((self.uses >= RandomIntRange(3,7)) && (level.wunderfizz_locations > 1))
							{
								//  v1.56.3 - the REAL bear bottle, not the teddy prop.
								//  Stock Origins does exactly this at
								//  _zm_perk_random.gsc:356. The model was pulled
								//  from the zone at v1.22.0 and "zombie_teddybear"
								//  (an actual teddy bear prop) stood in for it,
								//  which is what the user saw. It ships again now.
								self.bottle setModel( "t6_wpn_zmb_perk_bottle_bear_world" );
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
								//  🛑 THE BALL NEVER STOPPED SPINNING, AND ITS ABSENCE FROM
								//  THIS BRANCH IS WHY. User: "make the top ball on the
								//  wunderfizz only spin when you actually spin the machine
								//  like the real one... right now the ball is always spinning".
								//
								//  The animation is a state machine and this port only ever
								//  drove it one way. Arrival sets "start" then "idle", a
								//  purchase sets "in_use", departure sets "shut_down" - but
								//  the path back from "in_use" to "idle" was simply missing,
								//  so the FIRST purchase of the game left
								//  %qolwf_diesel_ballspin_loop running until the machine
								//  changed location. Stock has it at _zm_perk_random.gsc:391,
								//  in exactly this branch.
								//
								//  It goes here rather than above the departure check because
								//  a departing machine wants "shut_down", not "idle" - which
								//  is also why it cannot be hoisted next to the notify.
								//
								//  On timing: this lands on the frame done_cycling fired, which
								//  is when wunderfizzSounds() stops zmqol_wf_loop and plays
								//  zmqol_wf_stop, so the ball winds down WITH the sound.
								//  setanim's 0.2s blend out of the spin is the slowing down -
								//  it is a blend, not a cut. (Stock returns to idle later,
								//  after its grab window, because stock's stop sound is later
								//  too. Matching the sound matters more than matching the
								//  line number.)
								self zmqol_wf_anim( "idle" );

								perklist = array_randomize(perks);
								for(j=0;j<perklist.size;j++)
								{
									//  🛑 THIS CHECK WAS ASKING THE MACHINE, NOT THE PLAYER.
									//  It read `self has_perk_paused(...)`, and `self` here is the
									//  wunderfizzMachine script_model - the thread's owner - not the
									//  buyer. Stock's has_perk_paused() reads self.disabled_perks,
									//  which only ever exists on a PLAYER, so on an entity it
									//  returned false every single time and the paused-perk half of
									//  this guard has never once fired.
									//
									//  The cycling display twenty lines up (perkForRandom) has
									//  always had it right - `player has_perk_paused(...)` - so the
									//  two halves of the same machine disagreed about who to ask.
									//  That is the tell: same check, same file, two different
									//  subjects.
									if(!(player hasPerk(perklist[j]) || (player maps\mp\zombies\_zm_perks::has_perk_paused(perklist[j]))))
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

//  ?? LOOPING vs ONE-SHOT DECIDES WHETHER YOU PLAY ONCE OR RETRIGGER, AND
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
//  ============================================================================
//  zmqol_wf_fx_nearby  -  is anyone close enough for this effect to be FOR them?
//
//  Every effect on this machine repeats unattended - a marker every 7-10s, a
//  crackle while the orb cycles, a burst as it leaves - and playfx draws for
//  EVERY client, not just nearby ones. So a machine sitting alone in Town was
//  putting effects on the screen of a player at the bus depot.
//
//  Choosing smaller effects (above) fixes how big the thing looks. This fixes
//  whether it is drawn at all, which is the part that no choice of effect can
//  address: a small effect fired across the map is still a light on the horizon.
//
//  1500 units is about "the room and the street outside it" - Town's bar to the
//  far side of Town, not Town to the depot. Set zmqol_wf_fx_range 0 to turn the
//  gate off entirely and get every effect back everywhere.
//  ============================================================================
zmqol_wf_fx_nearby( n_extra )
{
	n_range = getdvarintdefault( "zmqol_wf_fx_range", 1500 );

	if( n_range <= 0 )
		return 1;

	if( isdefined( n_extra ) )
		n_range += n_extra;

	a_players = get_players();

	for( i = 0; i < a_players.size; i++ )
	{
		if( !isdefined( a_players[i] ) )
			continue;

		if( distance( a_players[i].origin, self.origin ) <= n_range )
			return 1;
	}

	return 0;
}

// ============================================================================
//  zmqol_wf_idle_arcs  -  the machine crackles while it just stands there
//
//  User: "the sound for when the machine is just idle is missing, by default on
//  origins the wunderfizz machine even when you don't spin it, it has a
//  sequential zapping electrical sort of sound effect that lines up with the
//  visual electrical effect".
//
//  🛑 WHY THERE WAS NOTHING TO PORT: ON ORIGINS THE SOUND IS INSIDE THE EFFECT.
//  zmb_rand_perk_sparks_top, _bolt, _strike and _hit are all in zmb_tomb.all and
//  NOT ONE of them is referenced by any script in the entire 2,093-file stock
//  dump - not the .gsc, not the .csc. A T6 FxEffectDef can carry sound elements,
//  and Origins' dieselmagic effects carry these. That is exactly why the user
//  hears it "line up with the visual effect": on Origins it is not lined up, it
//  IS the visual effect.
//
//  Which also means it could never have been found by reading scripts, and that
//  every "the machine makes no idle noise" pass that searched for a playsound was
//  looking in a place the answer could not be. The tell was in the bank: aliases
//  that exist, are obviously this machine's, and nothing calls.
//
//  We cannot ship an FxEffectDef, so the pairing is rebuilt by hand - one thread
//  firing the arc and its spark on the same line, which is as close to "inside
//  the effect" as script gets.
//
//  The beat is stock's own 0.1s retrigger for the arc (fx_activation_electric_loop,
//  _zm_perk_random.csc:165) slowed to a crackle off Origins for the same reason
//  the spin fx is - the raygun bolt is a discrete bright flash meant to be seen
//  once, not a faint arc meant to stack. The SOUND fires on its own slower,
//  randomised beat so it reads as sequential zapping rather than a machine-gun.
//
//  zmqol_wf_sparks is Origins' own three-variant spark (the engine picks one per
//  play, which is where the "sequential" character comes from) and carries
//  Treyarch's own falloff: full volume to 75 units, silent past 550. So it stays
//  local without any help from the fx gate.
// ============================================================================
zmqol_wf_idle_arcs()
{
	self endon( "zmqol_wf_ball_off" );
	level endon( "end_game" );

	if( !isdefined( level._effect[ "wunderfizz_loop" ] ) )
		return;

	for( ;; )
	{
		wait randomfloatrange( 1.1, 2.2 );

		//  The spin has its own, denser crackle - two threads drawing arcs on the
		//  same tag is the stacking failure this file has hit twice.
		if( isdefined( self.zmqol_wf_cycling ) && self.zmqol_wf_cycling )
			continue;

		if( !self zmqol_wf_fx_nearby() )
			continue;

		//  On the static anchor, never on j_ball - see the zmqol_wf_glow_loc
		//  block in wunderfizz(). j_ball spins and dragged this effect round
		//  with it.
		if( isdefined( self.zmqol_wf_glow_loc ) )
			playfxontag( level._effect[ "wunderfizz_loop" ], self.zmqol_wf_glow_loc, "tag_origin" );

		self playsound( "zmqol_wf_sparks" );
	}
}

zmqol_wf_ball_glow()
{
	level endon( "end_game" );

	self thread zmqol_wf_lightning();
	self thread zmqol_wf_idle_arcs();

	//  ?? v1.34.0: perk_machine_light is LOOPING on BOTH branches now
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
	//  v1.42.0 - the glow is the one effect the distance gate cannot simply skip,
	//  because it is a spawned ENTITY that stays lit rather than a call that fires
	//  and ends. So the gate spawns and deletes it instead, in a monitor thread;
	//  the delete path is the same one that has always run on "zmqol_wf_ball_off",
	//  just driven by proximity as well.
	self.zmqol_wf_glow = undefined;

	if( isdefined( level._effect[ "perk_machine_light" ] ) )
		self thread zmqol_wf_glow_monitor();

	self waittill( "zmqol_wf_ball_off" );

	if( isdefined( self.zmqol_wf_glow ) )
	{
		self.zmqol_wf_glow Delete();
		self.zmqol_wf_glow = undefined;
	}
}

zmqol_wf_glow_monitor()
{
	self endon( "zmqol_wf_ball_off" );
	level endon( "end_game" );

	for( ;; )
	{
		if( isdefined( self.zmqol_wf_glow ) )
		{
			//  400 units of hysteresis, so a player standing on the boundary gets a
			//  steady orb rather than one that blinks in and out once a second.
			if( !self zmqol_wf_fx_nearby( 400 ) )
			{
				self.zmqol_wf_glow Delete();
				self.zmqol_wf_glow = undefined;
			}
		}
		else if( self zmqol_wf_fx_nearby() )
		{
			v_ball = self gettagorigin( "j_ball" );

			if( !isdefined( v_ball ) )
				v_ball = self.origin + ( 0, 0, 60 );

			self.zmqol_wf_glow = SpawnFX( level._effect[ "perk_machine_light" ], v_ball, AnglesToForward( self.angles ), AnglesToUp( self.angles ) );
			TriggerFX( self.zmqol_wf_glow );
		}

		wait 1;
	}
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
//  ?? THE "lightning crack to match" IS GONE AS OF v1.39.0, and the paragraph
//  that justified it was wrong in a way worth recording. It read: zmb_hellhound_bolt
//  is the hellhound SPAWN LIGHTNING - evt\zombie_global\hellhounds\spawn\strikes_00
//  - so it is a real lightning strike, it lives in the global zombie bank rather
//  than Origins', and its DistMaxDry is 4000 so it carries. "Confirmed against
//  BO2-Reimagined's alias CSV rather than guessed."
//
//  Every specific in that is invented. The alias is in no bank the game ships -
//  not cmn_root, not zmb_common, not zmb_code_post_gfx, not any per-map bank.
//  And Reimagined's CSV is the alias table of ITS OWN bank, so it could never
//  have confirmed a stock alias; checkpoint 16 already flagged that exact
//  misreading after zmb_tombstone_looper, and it was made again anyway.
//
//  The lesson is the one-line check, not the individual alias:
//      Unlinker --include-assets soundbank -o <dir> <map>.ff
//  dumps a real bank's real alias table. Look the name up before shipping it.
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
	//  The beat has to match what the effect IS. Origins' arc is a short one-shot
	//  and stock retriggers it at 0.1s. An EMP explosion at 0.1s would be the
	//  v1.30.0 blinding blob, so set 0 gets a much slower one; the spark and wave
	//  sets sit in between.
	//  v1.39.0 - DIALLED BACK, on the user's note that the effects were "a bit
	//  exaggerated" and should match Origins, "where it's just a bit more subtle".
	//
	//  0.25 was chosen to make the raygun bolt read as a CONTINUOUS crackle, and
	//  it did - four bolts a second is a strobe around the orb, far louder to the
	//  eye than what Origins does. Origins' 0.1s beat is not a licence to go fast
	//  here: fx_tomb_dieselmagic_on is a faint short-lived arc authored to be
	//  stacked into a steady aura, while the raygun bolt is a discrete, bright,
	//  weapon-scale flash that is meant to be seen ONCE.
	//
	//  So off Origins it is now an occasional crackle rather than a constant one,
	//  and the interval is randomised - a fixed beat reads as a machine strobing,
	//  an irregular one reads as electricity. Origins keeps stock's own 0.1s
	//  because it keeps stock's own effect.
	n_beat = 0.1;

	for( ;; )
	{
		//  Anyone spinning the machine is standing at it, so this gate never costs
		//  the person using it anything - it only stops the crackle being drawn for
		//  a player on the far side of the map who is not part of the event.
		if( self zmqol_wf_fx_nearby() )
		{
			//  🛑 On the static anchor, NOT on j_ball. This is the one the user
			//  actually sees wheeling around, because it plays for the whole
			//  spin while %qolwf_diesel_ballspin_loop rotates the ball. Stock
			//  plays it on self.glow_location - a motionless script_model - and
			//  the comment below already said so while the code did otherwise.
			if( isdefined( self.zmqol_wf_glow_loc ) )
				playfxontag( level._effect[ "wunderfizz_loop" ], self.zmqol_wf_glow_loc, "tag_origin" );

			//  🛑 AND ON THE BOTTLE. User: "the blue electrical effects around the
			//  perk bottle while spinning seem to be absent."
			//
			//  Correct, and it was never played there. Origins runs TWO threads
			//  while the machine cycles - fx_activation_electric_loop and
			//  fx_bottle_cycling (_zm_perk_random.csc:165,178) - and BOTH play on
			//  self.glow_location, a script_model spawned at the machine's origin,
			//  not on the ball. This port had one thread, on j_ball, so all the
			//  electricity was up at the orb and the bottle cycling below it was
			//  bare.
			//
			//  self.bottle is the cycling bottle entity that perk_bottle_motion()
			//  floats out in front of the machine, so this puts the arcs exactly
			//  where the user is looking during a spin.
			if( isdefined( self.bottle ) )
				playfxontag( level._effect[ "wunderfizz_loop" ], self.bottle, "tag_origin" );
		}

		if( level.script != "zm_tomb" )
			n_beat = randomfloatrange( 0.7, 1.1 );

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
	//  v1.39.0 - the marker is SILENT on every map now, as it is on Origins.
	//
	//  Two reasons, and the second one only became checkable this release. The
	//  real machine's marker makes no noise, so a bang every 3-4 seconds was never
	//  matching it. And the sound it played, zmb_hellhound_bolt, DOES NOT EXIST -
	//  dumping every bank a zombies map loads and searching all of them finds it
	//  nowhere. So this line has been a no-op the whole time; deleting it changes
	//  nothing anyone has heard, and stops the file claiming a sound it never made.
	//
	//  v1.56.3 - ONE CADENCE, EVERY MAP. This used to wait 7-10s off Origins
	//  instead of stock's 3-4s, because off Origins the "identify" effect was a
	//  raygun impact standing in for the real beam and firing it every 3 seconds
	//  looked exaggerated. Every map now plays the genuine
	//  fx_tomb_dieselmagic_identify, so stock's cadence is correct everywhere and
	//  the stretched timing would just make the machine feel dead by comparison.
	for( ;; )
	{
		wait randomfloatrange( 3.0, 4.0 );

		if( self.location != level.currentWunderfizzLocation )
			continue;

		//  v1.42.0 - the gate. This is the effect that fires unattended forever, so
		//  it is the one that was reaching the other side of the map.
		if( !self zmqol_wf_fx_nearby() )
			continue;

		playfx( level._effect[ "perk_machine_location" ], self.origin + ( 0, 0, level.zmqol_wf_marker_z ) );

		//  ...and the bolt that goes with it. Same reasoning as the idle arcs: on
		//  Origins this sound is carried by fx_tomb_dieselmagic_identify itself, so
		//  the only way to reproduce the pairing is to fire both from one line.
		self playsound( "zmqol_wf_bolt" );
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

	//  v1.56.3 - STOCK'S CADENCE ON EVERY MAP: 0.1s for 5 seconds. This used to
	//  fork, because off Origins "perk_machine_steam" was an electrical burst
	//  standing in for the real steam and 50 bursts in 5 seconds is a strobe.
	//  Every map now loads the genuine fx_tomb_dieselmagic_steam, so the fork is
	//  gone and the departure puff is identical everywhere.
	n_end = GetTime() + 5000;

	while( GetTime() < n_end )
	{
		if( self zmqol_wf_fx_nearby() )
			playfxontag( level._effect[ "perk_machine_steam" ], self, "tag_origin" );

		wait 0.1;
	}
}

chooseLocation(currLoc)
{
	//  ?? With one location this used to spin forever - it draws until it gets a
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


//  🛑 THE RETRACT MUST NOT BE COMPUTED FROM THE LIVE ORIGIN.
//  Reported in game: "when it's finished spinning and the perk bottle it lands
//  on is finalised it pops out off to the left instead of retaining its normal
//  position centered", and again the moment the machine relocated.
//
//  The old code did:
//        self.bottle.origin -= v_float;                    // start behind home
//        self.bottle moveto( self.bottle.origin + v_float, putouttime, ... );
//        self waittill( "done_cycling" );
//        self.bottle moveto( self.bottle.origin - v_float, putbacktime, ... );
//
//  `.origin` on an entity that is MID-moveto is its position RIGHT NOW, not its
//  destination - and "done_cycling" is not tied to putouttime, so it routinely
//  fires while that 3-second glide is still running. The retract target was
//  therefore (wherever it got to) - v_float, which is short of the real home by
//  however much of the glide had not happened yet. The next spin then hard-set
//  the origin back to home, and that correction is the "jump" - it read as
//  sideways because v_float points along the machine's FRONT (yaw - 90, the same
//  offset the machine and the Pack-a-Punch both use), not along a screen axis.
//
//  Fixed by computing the home position ONCE and expressing both ends of the
//  motion relative to it, so the bottle cannot accumulate error no matter when
//  the spin ends.
perk_bottle_motion()
{
	putouttime = 3;
	putbacktime = 10;
	v_float = anglesToForward( self.angles - ( 0, 90, 0 ) ) * 10;

	//  Computed once. Every moveto below is relative to THIS, never to .origin.
	v_home = self.origin + ( 0, 0, 53 );

	self.bottle.origin = v_home - v_float;
	self.bottle.angles = self.angles;
	self.bottle moveto( v_home, putouttime, putouttime * 0.5 );
	self.bottle.angles += ( 0, 0, 10 );
	self.bottle rotateyaw( 720, putouttime, putouttime * 0.5 );

	self waittill( "done_cycling" );

	self.bottle.angles = self.angles;
	self.bottle moveto( v_home - v_float, putbacktime, putbacktime * 0.5 );
	self.bottle rotateyaw( 90, putbacktime, putbacktime * 0.5 );
}

// ============================================================================
//  wunderfizzSounds
//
//  ? v1.39.0 ? THE MACHINE HAS ITS REAL VOICE ON EVERY MAP. Six releases of
//  substitutes are deleted, and so is the claim they were unavoidable.
//
//  What was believed, and repeated in this header through v1.38.0: that
//  zmb_rand_perk_start / _loop / _stop live in Origins' zmb_tomb.all, that no
//  tool here can create a sound alias, and that a substitute was therefore the
//  best available. The first half is true. The conclusion was wrong.
//
//  ?? THE MISSED TOOL WAS THE ONE ALREADY IN THE BUILD. OpenAssetTools reads and
//  writes soundbanks:
//      Unlinker --include-assets soundbank --search-path <dir> <any .ff>
//        -> the bank's ENTIRE alias table as a 60-column CSV, and every payload
//           as .wav/.flac, for any fastfile in the game
//      Linker    with soundbank\<name>.aliases.csv + the audio under sound\
//        -> rebuilds that bank: the alias table into mod.ff AND the audio into
//           mod.all.sabl / .sabs
//  So the aliases below are not substitutes and not approximations. They are
//  Origins' own audio, lifted out of zmb_tomb.all, with Treyarch's own 60 field
//  values for volume, distance, bus, ducking and looping - only the Name column
//  differs. See build_ff.bat for the pipeline and .agents\ for the write-up.
//
//  ?? THEY ARE DELIBERATELY RENAMED zmqol_*, AND MUST STAY RENAMED. Defining
//  zmb_rand_perk_loop in mod.all would put a second definition of a live alias
//  in front of Origins, which already ships its own in zmb_tomb.all - the exact
//  duplicate-asset shape that made Origins unbootable in v1.19.0. A mod-private
//  name cannot collide on any map. Same discipline as the qolwf_* xmodel and
//  material rename in v1.23.0, and for the same reason.
//
//  One consequence worth keeping: there is no per-map branch any more. Origins
//  and the other five now play the identical audio through the identical path,
//  so anything heard on one is true of all six.
// ============================================================================
wunderfizzSounds()
{
	sound_ent = spawn( "script_origin", self.origin );

	sound_ent PlaySound( "zmqol_wf_start" );
	sound_ent PlayLoopSound( "zmqol_wf_loop", 0.5 );

	//  ?? Was `level waittill("wunderSpinStop")`. Two bugs in one line:
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
	sound_ent PlaySound( "zmqol_wf_stop" );

	//  ?? Deleting the emitter in the same frame as PlaySound cut the stop sound
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
