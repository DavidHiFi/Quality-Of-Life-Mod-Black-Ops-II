// zm_qol: imported from pluto-t6zm-bleedout-bar (Nathan3197 / Stick Gaming).
//
// Two changes from upstream:
//  1. Includes were written with FORWARD slashes, which is another compiler's
//     dialect - T6 needs backslashes and gsc-tool rejects the file otherwise.
//     Same fix as wunderfizz.gsc and the _zm_magicbox override.
//  2. `maps\_utility` is a SINGLEPLAYER path and does not exist in zombies.
//     Dropped; nothing in this file needs it.
#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\gametypes_zm\_hud_util;

// This Script is only use for Stick Gaming Zombies server for Pluto T6 Zombies only
// Some code in the script have been use or remix from other people round the internet
// This script is not ment to be shared outside Stick Gaming Devs unless given premissing from Nathan3197
//
// Any contributors will be credited down below
// Nathan3197
// 
//
// Credit of use of other people code found on the internet
// 
//
// Big thanks to the pluto team for all there hard efforts to allow us to play BO2 with mods and servers.




init()
{
	BleedoutTimer = getDvarIntDefault("Bleedout_timer", 45 );
	reviveTrigger = getDvarIntDefault("revive_trigger", 75);
	// How long untill the player bleed out
	level.cmPlayerLaststandBleedoutTime = getDvarIntDefault( "cmPlayerLaststandBleedoutTime", int(BleedoutTimer) );
	setdvar( "player_lastStandBleedoutTime", level.cmPlayerLaststandBleedoutTime );
	//revive trigger radius size
	level.cmPlayerReviveTriggerRadius = getDvarIntDefault( "cmPlayerReviveTriggerRadius", int(reviveTrigger) );
	setdvar( "revive_trigger_radius", level.cmPlayerReviveTriggerRadius );
	level thread onplayerconnect();
}

onplayerconnect()
{
	level endon ("end_game");
	for ( ;; )
	{
        level waittill( "connected", player );
		player thread Bleedout_bar_startup(); // thread the AFK_listener
		player thread Bleedout_bar_End_game_fix();
	}
}

Bleedout_bar_startup()
{
	self endon( "dissable_bleedout_End_game" ); 
	self endon( "disconnect" ); 
	self endon("end_game");
	flag_wait( "initial_blackscreen_passed" ); // yeah we don't want this to run while the match is setting up
	//self iprintln("Bleed out bar setup"); // debuging
	
	// zm_qol: upstream flashed "Bleedout Bar V2.0 Created by Nathan3197" on screen
	// at every spawn. Default flipped to OFF so it does not interrupt the start of
	// a game - the attribution lives in this file's header and in the commit
	// instead. Set the "credits" dvar to 1 to bring the on-screen line back.
	credits = getDvarIntDefault( "credits", 0 );

	if(int(credits) == 1)
	{
		self iprintln("Bleedout Bar V2.0 Created by ^2Nathan3197");
	}
	//watching if player goes down
	self thread Bleedout_bar_hud_toggle();


}

Bleedout_bar_hud_toggle()
{
	level endon( "end_game" );
	self endon( "end_game" ); 
	self endon( "disconnect" ); 
	//self iprintln("bleedout_toggle"); //debuging
	//bleeding out timer
	for(;;)
	{
		//when player goes down we continue
		self waittill("player_downed");
		self.bleeding_Out = true;
		//creating the hud
		self thread bleedout_bar();
		//we wait till any of these to turn of the hud
		self waittill_any("player_revived","bled_out", "death");
		self.bleeding_Out = false;
		wait 1;
	}
}
Bleedout_bar_End_game_fix()
{
	self endon( "disconnect" ); 
	level waittill("end_game");
	if(isdefined(self.ProcessBar2) && isdefined(self.Bleedout_text))
	{
	self.ProcessBar2 destroyElem();
	self.Bleedout_text destroy();
	}
	return;
}

bleedout_bar()
{
	self endon( "disconnect" ); 
	level endon("end_game");
	//self iprintln("bleedout bar new"); //debuging
	//we create a progress bar for the bleedout bar
	self.ProcessBar2 = createPrimaryProgressBar();
	self.ProcessBar2 setPoint("CENTER","CENTER",0,120);
	self.ProcessBar2.color = (0,0,0);
	self.ProcessBar2.bar.color = (1,0,0);
	self.ProcessBar2.alpha = 1;
	self.ProcessBar2.archived = 1;

	//we create a text displaying the bleedout timer
	self.Bleedout_text = newclienthudelem( self );
	self.Bleedout_text.x = 320;
	self.Bleedout_text.y = 345;
	self.Bleedout_text.alignx = "center";
	self.Bleedout_text.aligny = "middle";
	self.Bleedout_text.horzalign = "fullscreen";
	self.Bleedout_text.vertalign = "fullscreen";
    self.Bleedout_text.alpha = 1;
	self.Bleedout_text.archived = 1;
    self.Bleedout_text.fontscale = 1.2;
	self.Bleedout_text.hidewheninmenu = 1;
	self.Bleedout_text.label = &"Bleeding out in:^1 ";
	
	//while we are down we update the bar and text
	while(self.bleeding_Out == true)
	{
		self.ProcessBar2 updateBar(int(self.bleedout_time) / int(level.cmPlayerLaststandBleedoutTime));
		self.Bleedout_text setvalue(int(self.bleedout_time));
		wait 1;
		waittillframeend;
	}
	//we destroy the hud so we free up hud elemets for other scripts
	//self iprintln("hud destorty"); //debuging
	self.ProcessBar2 destroyElem();
	self.Bleedout_text destroy();
}