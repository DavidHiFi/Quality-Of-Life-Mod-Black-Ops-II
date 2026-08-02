#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

// ============================================================================
//  main
//
//  🛑 EXISTS ONLY TO PRECACHE. Plutonium runs main() before init() and inside the
//  precache window - confirmed in console_zm.log, which lists
//  "GSC Executed scripts/zm/<name>::main()" for every root script that has one,
//  ahead of every ::init().
//
//  The bug this fixes: the user reported that when the machine relocates it shows
//  "a standard perk bottle" instead of the teddy bear. The bear is NOT missing
//  from the fastfile - Unlinker --list mod.ff confirms xmodel
//  t6_wpn_zmb_perk_bottle_bear_world, its material and its image are all in there.
//  It was never precached, and a setmodel() to an unprecached model at RUNTIME
//  fails silently, leaving whatever model the entity already had - which is the
//  last perk bottle the cycle landed on. Exactly the reported symptom.
//
//  Why only this one model was affected:
//    - the perk bottles (t6_wpn_zmb_perk_bottle_*_world) ride in on their
//      zombie_perk_bottle_* WEAPON, which default_vending_precaching precacheitem's,
//      so they are registered as a side effect;
//    - the MACHINE gets away with it because wunderfizzSetup() setmodel's it during
//      init(), while the precache window is still open;
//    - the bear has no weapon and is only ever set mid-game, so it had nothing.
//  The machine is precached explicitly below anyway - it currently works by timing
//  luck, which is not a thing to leave load-bearing.
// ============================================================================
main()
{
    precachemodel( "t6_wpn_zmb_perk_bottle_bear_world" );
    precachemodel( "p6_zm_vending_diesel_magic" );
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
	// zm_qol: hoisted out of the zm_tomb branch. Upstream only loaded this on
	// Origins, because only Origins owns the effect - so on every other map
	// SpawnFX( level._effect["wunderfizz_loop"], ... ) in wunderfizz() ran on an
	// undefined effect and killed the thread silently. mod.ff now carries both
	// the effect and the machine model (copied out of zm_tomb.ff at link time,
	// see zone_source\mod_locations.zone), so it loads everywhere.
	level._effect[ "wunderfizz_loop" ] = loadfx( "maps/zombie_tomb/fx_tomb_dieselmagic_on" );

	if(level.script == "zm_tomb")
    {
		zmqol_wf_add((2468,4459,-316), (0,180,0), "p6_zm_vending_diesel_magic");
    }
    else if(level.script == "zm_nuked")
    {
    	zmqol_wf_add((-649,281,-56), (0,162,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-915,286,-56), (0,66,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((716,21,-57), (0,192,0), "p6_zm_vending_diesel_magic");
    }
    else if(level.script == "zm_prison")
    {
    	zmqol_wf_add((-377,-3903,-8448), (0,270, 0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((2046, 10332.9, 1336), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-1056,8673,1336), (0,90,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((2795,9270,1336), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-843,5585,-72), (0,13,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((2724,9563,1708), (0,90,0), "p6_zm_vending_diesel_magic");
    }
    else if(level.script == "zm_buried")
    {
    	zmqol_wf_add((146,138,10), (0,270,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-374,-1103,8), (0,270,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-58,-1512,168), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((1521,1366,-14), (0,342,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((4910,725,2), (0,0,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((6862,846,108), (0,49,0), "p6_zm_vending_diesel_magic");
    }
    else if(level.script == "zm_transit")
    {
    	zmqol_wf_add((11168,8120,-576), (0,0,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-7103,4952,-56), (0,0,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-11824,-1495,228), (0,90,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((-5043,-7772,-61), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((8371,-5408,264), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((1823,114,88), (0,90,0), "p6_zm_vending_diesel_magic");
    }
    else if(level.script == "zm_highrise")
    {
    	zmqol_wf_add((2608, 275, 1296), (0,60,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((1482, 1060, 3395), (0,180,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((2964, 2698, 2905), (349,0,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((1648, -635, 2880), (0,150,0), "p6_zm_vending_diesel_magic");
    	zmqol_wf_add((1809, 1459, 3040), (0,0,0), "p6_zm_vending_diesel_magic");
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
//  Rather than hardcode a coordinate per gametype+location, ask the game. The
//  zone manager already knows the answer: level.zones is populated ONLY by
//  _zm_zonemgr::zone_init(), which runs only for the zones this gametype and
//  location actually manages (_zm_zonemgr.gsc:166-174). So a point inside the
//  playable area resolves to a zone and a point outside it resolves to
//  undefined - no coordinate tables, and it covers Diner and the grief variants
//  for free.
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
//  🛑 FAILS OPEN. If the zone lookup comes back with nothing at all - zones not
//  built yet, or a machine sitting just outside every volume - the full list is
//  used, which is the old behaviour. A wrong hint string beats no Wunderfizz.
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
		a_zoned = zmqol_wf_filter_to_zones( a_place );

		if( a_zoned.size > 0 )
			a_place = a_zoned;
	}

	n_candidates = level.zmqol_wf_pending.size;

	for( i = 0; i < a_place.size; i++ )
		wunderfizzSetup( a_place[i].origin, a_place[i].angles, a_place[i].model );

	level.zmqol_wf_pending = [];
	println( "[zm_qol] wunderfizz: placed " + a_place.size + " of " + n_candidates + " candidate location(s)" );
}

zmqol_wf_filter_to_zones( a_place )
{
	a_keep = [];

	// The location scripts build their zones from _load::main(), which can land
	// after this thread starts. Ten seconds is far longer than it has ever taken
	// and the machines are only needed once the blackscreen lifts.
	n_wait = 0;
	while( ( !isdefined( level.zones ) || level.zones.size < 1 ) && n_wait < 200 )
	{
		wait 0.05;
		n_wait++;
	}

	if( !isdefined( level.zones ) || level.zones.size < 1 )
		return a_keep;

	for( i = 0; i < a_place.size; i++ )
	{
		// ignore_enabled_check = 1: zones start disabled and only open as doors
		// are bought, but a machine behind a closed door is still in the play
		// area and should be kept.
		if( isdefined( maps\mp\zombies\_zm_zonemgr::get_zone_from_position( a_place[i].origin, 1 ) ) )
			a_keep[ a_keep.size ] = a_place[i];
	}

	return a_keep;
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
			return "p6_zm_vending_diesel_magic";
		else
			return "p6_zm_vending_diesel_magic";
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
	self thread playLocFX();
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
			self ShowPart("j_ball");
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
							wunderfx = SpawnFX(level._effect["wunderfizz_loop"], self.origin,AnglesToForward(angles),AnglesToUp(angles));
							TriggerFX(wunderfx);
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
								TriggerFX(wunderfx);
								wait .2;
								rtime -= .2;
							}
							self notify( "done_cycling" );
							if((self.uses >= RandomIntRange(3,7)) && (level.wunderfizz_locations > 1))
							{
								self.bottle setModel("t6_wpn_zmb_perk_bottle_bear_world");
								level notify("wunderSpinStop");
								wunderfx Delete();
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
											TriggerFX(wunderfx);
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
								wunderfx Delete();
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
			self HidePart("j_ball");
			level waittill("wunderfizzMove");
		}
		wait .1;
	}
}

playLocFX()
{
	level waittill("connected", player);

	// zm_qol: lght_marker is loaded per-map (each map's own script does it), not
	// in Core, so it is not guaranteed to exist. SpawnFX on an undefined effect
	// throws and would kill this thread on its first iteration - silently, per
	// rule 14. The marker beam is cosmetic, so skip it rather than risk that.
	if(!isDefined(level._effect["lght_marker"]))
		return;

	for(;;)
	{
		fx = SpawnFX(level._effect["lght_marker"], self.origin);
		if(self.location == level.currentWunderfizzLocation)
		{
			TriggerFX(fx);
		}
		level waittill("wunderfizzMove");
		fx Delete();
	}
}

chooseLocation(currLoc)
{
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

wunderfizzSounds()
{
	sound_ent = spawn("script_origin", self.origin);
	sound_ent StopSounds();
	sound_ent PlaySound( "zmb_rand_perk_start");
	sound_ent PlayLoopSound("zmb_rand_perk_loop", 0.5);
	level waittill("wunderSpinStop");
	sound_ent StopLoopSound(1);
	sound_ent PlaySound("zmb_rand_perk_stop");
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