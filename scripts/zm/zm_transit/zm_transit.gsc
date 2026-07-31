// zm_qol: a bogus "#include maps\mp_utility;" (missing the \ before _utility) used to sit
// here. It produced a harmless-looking "Could not load scriptparsetree maps/mp_utility.gsc"
// in the log. It is DELETED rather than corrected, because line 7 below already includes
// the real maps\mp\_utility - correcting it instead produced
// "[ERROR]:compiler: duplicated include file maps/mp/_utility", which is FATAL and took
// the whole map down. In T6 a duplicate #include is a compile error, not a warning.
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_weapon_locker;
#include maps\mp\zm_transit;
#include maps\mp\zm_transit_standard_station;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_race_utility;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zombies\_zm_perks;

main()
{
    replaceFunc( maps\mp\zm_transit_standard_station::main, ::main_o );
    replaceFunc( maps\mp\zm_transit_lava::zombie_exploding_death, ::zombie_exploding_death );

    // --- custom survival start locations: adds Diner, Power Station, Tunnel, Cornfield ---
    // Map-specific, so it lives here and not in ridgelandproject.gsc (AI_CONTEXT rule 2).
    replaceFunc( maps\mp\zm_transit_gamemodes::init, scripts\zm\replaced\zm_transit_gamemodes::init );

    electric_door_changes();

    if (is_not_busdepot())
	{
	   return;
	}
}

init()
{
    if( getDvar("ui_zm_mapstartlocation") == "town" )
    {
        level thread town_vault_breach_init();
    }

    added_weapons();
}

main_o()
{
    maps\mp\gametypes_zm\_zm_gametype::setup_standard_objects( "station" );
    maps\mp\zm_transit_standard_station::station_treasure_chest_init();
    level.enemy_location_override_func = maps\mp\zm_transit_standard_station::enemy_location_override;
    collision = spawn( "script_model", ( -6896, 4744, 0 ), 1 );
    collision setmodel( "zm_collision_transit_busdepot_survival" );
    collision disconnectpaths();
    flag_wait( "initial_blackscreen_passed" );
    flag_set( "power_on" );
    level setclientfield( "zombie_power_on", 1 );
    zombie_doors = getentarray( "zombie_door", "targetname" );

    foreach ( door in zombie_doors )
    {
        if ( isdefined( door.script_noteworthy ) && door.script_noteworthy == "local_electric_door" )
        {
            door trigger_off();
        }
    }
}

zombie_exploding_death( zombie_dmg, trap )
{
    self endon( "stop_flame_damage" );

    if ( isdefined( self.isdog ) && self.isdog && isdefined( self.a.nodeath ) )
    {
        return;
    }

    while ( isdefined( self ) && self.health >= zombie_dmg && ( isdefined( self.is_on_fire ) && self.is_on_fire ) )
    {
        wait 0.5;
    }

    if ( !isdefined( self ) || !( isdefined( self.is_on_fire ) && self.is_on_fire ) || isdefined( self.damageweapon ) && ( self.damageweapon == "tazer_knuckles_zm" || self.damageweapon == "jetgun_zm" ) || isdefined( self.knuckles_extinguish_flames ) && self.knuckles_extinguish_flames )
    {
        return;
    }

    tag = "J_SpineLower";

    if ( isdefined( self.animname ) && self.animname == "zombie_dog" )
    {
        tag = "tag_origin";
    }

    if ( is_mature() )
    {
        if ( isdefined( level._effect["zomb_gib"] ) )
        {
            playfx( level._effect["zomb_gib"], self gettagorigin( tag ) );
        }
    }
    else if ( isdefined( level._effect["spawn_cloud"] ) )
    {
        playfx( level._effect["spawn_cloud"], self gettagorigin( tag ) );
    }

    self radiusdamage( self.origin, 128, 30, 15, undefined, "MOD_GRENADE_SPLASH" );
    self ghost();

    if ( isdefined( self.isdog ) && self.isdog )
    {
        self hide();
    }
    else
    {
        self delay_thread( 1, ::self_delete );
    }
}

electric_door_changes() //BO2 Reimagined
{
	if (is_classic())
	{
		return;
	}

	zombie_doors = getentarray("zombie_door", "targetname");

	for (i = 0; i < zombie_doors.size; i++)
	{
        
		if (isDefined(zombie_doors[i].script_noteworthy) && (zombie_doors[i].script_noteworthy == "local_electric_door" || zombie_doors[i].script_noteworthy == "electric_door"))
		{
			if (zombie_doors[i].target == "lab_secret_hatch")
			{
				continue;
			}

			zombie_doors[i].script_noteworthy = "default";
			zombie_doors[i].zombie_cost = 750;

			// link Bus Depot and Farm electric doors together
			new_target = undefined;

			if (zombie_doors[i].target == "pf1766_auto2353")
			{
				new_target = "pf1766_auto2352";

			}
			else if (zombie_doors[i].target == "pf1766_auto2358")
			{
				new_target = "pf1766_auto2357";
			}

			if (isDefined(new_target))
			{
				targets = getentarray(zombie_doors[i].target, "targetname");
				zombie_doors[i].target = new_target;

				foreach (target in targets)
				{
					target.targetname = zombie_doors[i].target;
				}
			}
		}
	} 
}

town_vault_breach_init()
{
    vault_doors = getentarray( "town_bunker_door", "targetname" );
    array_thread( vault_doors, ::town_vault_breach );
}

town_vault_breach()
{
    if ( isdefined( self ) )
    {
        self.damage_state = 0;

        if ( isdefined( self.target ) )
        {
            clip = getent( self.target, "targetname" );
            clip linkto( self );
            self.clip = clip;
        }

        self thread vault_breach_think();
    }
    else
        return;
}

vault_breach_think()
{
    level endon( "intermission" );
    self.health = 99999;
    self setcandamage( 1 );
    self.damage_state = 0;
    self.clip.health = 99999;
    self.clip setcandamage( 1 );

    while ( true )
    {
        self thread track_clip_damage();
        self waittill( "damage", amount, attacker, direction, point, dmg_type, modelname, tagname, partname, weaponname );

        if ( isdefined( weaponname ) && ( weaponname == "emp_grenade_zm" || weaponname == "ray_gun_zm" || weaponname == "ray_gun_upgraded_zm" ) )
            continue;

        if ( isdefined( amount ) && amount <= 1 )
            continue;

        if ( isplayer( attacker ) && ( dmg_type == "MOD_PROJECTILE" || dmg_type == "MOD_PROJECTILE_SPLASH" || dmg_type == "MOD_EXPLOSIVE" || dmg_type == "MOD_EXPLOSIVE_SPLASH" || dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) )
        {
            if ( self.damage_state == 0 )
                self.damage_state = 1;

            playfxontag( level._effect["def_explosion"], self, "tag_origin" );
            self playsound( "exp_vault_explode" );
            self bunkerdoorrotate( 1 );

            if ( isdefined( self.script_flag ) )
                flag_set( self.script_flag );

            if ( isdefined( self.clip ) )
                self.clip connectpaths();

            wait 1;
            playsoundatposition( "zmb_cha_ching_loud", self.origin );
            return;
        }
    }
}

track_clip_damage()
{
    self endon( "damage" );
    self.clip waittill( "damage", amount, attacker, direction, point, dmg_type );
    self notify( "damage", amount, attacker, direction, point, dmg_type );
}

bunkerdoorrotate( open, time )
{
    if ( !isdefined( time ) )
        time = 0.2;

    rotate = self.script_float;

    if ( !open )
        rotate = rotate * -1;

    if ( isdefined( self.script_angles ) )
    {
        self notsolid();
        self rotateto( self.script_angles, time, 0, 0 );
        self thread maps\mp\zombies\_zm_blockers::door_solid_thread();
    }
}

is_not_busdepot()
{
	return !getdvar("g_gametype") == "zclassic" && getdvar("mapname") == "zm_transit" && getdvar("ui_zm_mapstartlocation") == "transit";
}

added_weapons()
{
    if (level.script == "zm_transit")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );
    
        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "pdw57_zm" );
        include_weapon( "pdw57_upgraded_zm", 0 );
        add_zombie_weapon( "pdw57_zm", "pdw57_upgraded_zm", &"ZOMBIE_WEAPON_PDW57", 1000, "smg", "", undefined );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        /* AK74u Extended Clip */
        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );

        /* B23R Extended Clip */
        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );
	}
}