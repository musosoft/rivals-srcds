//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8"


new g_killCount[MAXPLAYERS+1];

new String:Game[64];

new Handle:bt_enable;
new Handle:bt_enableweapontracers;
new Handle:bt_enableweapontracersonlybt;
new Handle:bt_enableweapon_knife;
new Handle:bt_timescale;
new Handle:bt_bomb_timescale;
new Handle:bt_roundend_timescale;
new Handle:bt_trans;
new Handle:bt_fsound;
new Handle:bt_grenade;
new Handle:bt_c4;
new Handle:bt_kills;
new Handle:bt_kills_enabled;
new Handle:bt_roundend;
new Handle:bt_roundend_timer;
new Handle:bt_admin_slowdowntime;
new Handle:bt_roundend_slowdownlast;

new slowdown = 0;
new focussound = 2;
new transition = false;
new Float:timescale = 0.50;
new Float:bomb_timescale = 0.20;
new Float:roundend_timescale = 0.25;

new Handle:Cheats = INVALID_HANDLE;

static const String:Weapons[][]={"knife"};

new g_BeamSprite;

new Handle:g_CvarTeam2Red = INVALID_HANDLE;
new Handle:g_CvarTeam2Blue = INVALID_HANDLE;
new Handle:g_CvarTeam2Green = INVALID_HANDLE;
new Handle:g_CvarTeam3Red = INVALID_HANDLE;
new Handle:g_CvarTeam3Blue = INVALID_HANDLE;
new Handle:g_CvarTeam3Green = INVALID_HANDLE;
new Handle:g_CvarTrans = INVALID_HANDLE;
new Handle:g_CvarLife = INVALID_HANDLE;
new Handle:g_CvarWidth = INVALID_HANDLE;

public Plugin:myinfo = 

{
	name = "SM Bullet Time",
	author = "Andi67",
	description = "Creates a slow-motion effect on events in bullet time / matrix style",
	version = PLUGIN_VERSION,
	url = "http://www.andi67-blog.de.vu/"
};

public OnPluginStart() 
{
	CreateConVar("sm_bullettime_version", PLUGIN_VERSION, "SM Bullet Time Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	bt_enable = CreateConVar("bt_enable", "1", "Enables/Disables Bullet Time.", 0);
	bt_enableweapontracers = CreateConVar("bt_enableweapontracers", "0", "Enables/Disables Bullet Time Tracers.", 0);
	bt_enableweapontracersonlybt = CreateConVar("bt_enableweapontracersonlyBT", "1", "Enables/Disables Tracers only in BT.", 0);
	bt_grenade = CreateConVar("bt_grenade", "1", "Starts bullet time on kill with handgrenade.", 0);
	bt_c4 = CreateConVar("bt_c4", "1", "Enables BT on bomb explodes.", 0);	
	bt_kills_enabled = CreateConVar("bt_kills_enabled", "1", "Enables bt_kills for weapons.", 0);	
	bt_kills = CreateConVar("bt_kills", "4", "Kills for enabling BT on weapons exept Knife/Grenade.", 0);
	bt_roundend = CreateConVar("bt_roundend", "1", "Enables BT on RoundEnd.", 0);
	bt_admin_slowdowntime = CreateConVar("bt_admin_slowdowntime", "3.0", "Enables BT on Admincommand.", 0);
	bt_roundend_timer = CreateConVar("bt_roundend_timer", "1", "Enables timer for Roundend to stop BT.", 0);	
	bt_roundend_slowdownlast = CreateConVar("bt_roundend_slowdownlast", "1.0", "How long BT should last on Roundend.", 0);	

	bt_enableweapon_knife = CreateConVar("bt_enableweapon_knife", "1", "Enables BT on Knife.", 0);	
	
	bt_trans = CreateConVar("bt_transition", "1", "Transitions the timescales if on. If not, timescales are set directly.", 0);
	bt_timescale = CreateConVar("bt_timescale", "0.50", "Slowdown timescale.", 0);
	bt_bomb_timescale = CreateConVar("bt_bomb_timescale", "0.20", "Slowdown timescale for Bombexplode.", 0);	
	bt_roundend_timescale = CreateConVar("bt_roundend_timescale", "0.25", "Slowdown timescale for Roundend.", 0);		
	bt_fsound = CreateConVar("bt_fsound", "2", "Plays a sound for the focus of bullet time. If 2 it replaces the default sound rather than playing simultaneously.", 0);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);	
	HookEvent("round_start", EventRoundStart);	
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("bomb_exploded", Event_BombExplode);	
	HookEvent("bomb_defused", Event_BombDefused);	
	HookConVarChange(bt_trans, OnConVarChanged_Trans);
	timescale = GetConVarFloat(bt_timescale);
	bomb_timescale = GetConVarFloat(bt_bomb_timescale);	
	roundend_timescale = GetConVarFloat(bt_roundend_timescale);	
	transition = GetConVarBool(bt_trans);
	focussound = GetConVarBool(bt_fsound);
	Cheats = FindConVar("sv_cheats");
	
	RegAdminCmd("sm_bt" , Command_Bullettime , ADMFLAG_GENERIC , "Activates BT on Admincommand");
	
	g_CvarLife = CreateConVar("bt_laser_Life", "0.5", "Life of the Beam",0);
	g_CvarWidth = CreateConVar("bt_laser_Width", "2.0", "Width of the Beam",0);
	g_CvarTeam2Red = CreateConVar("bt_laser_team2_red", "25", "Amount OF Red In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam2Green = CreateConVar("bt_laser_team2_green", "25", "Amount Of Green In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam2Blue = CreateConVar("bt_laser_team2_blue", "200", "Amount OF Blue In The Beam of Team2", FCVAR_NOTIFY);
	g_CvarTeam3Red = CreateConVar("bt_laser_team3_red", "200", "Amount OF Red In The Beam of Team3", FCVAR_NOTIFY);
	g_CvarTeam3Green = CreateConVar("bt_laser_team3_green", "25", "Amount Of Green In The Beam of Team3", FCVAR_NOTIFY);
	g_CvarTeam3Blue = CreateConVar("bt_laser_team3_blue", "25", "Amount OF Blue In The Beam of Team3", FCVAR_NOTIFY);	
	g_CvarTrans = CreateConVar("bt_laser_alpha", "150", "Amount OF Transparency In Beam", FCVAR_NOTIFY);	
	
	AutoExecConfig(true,"sm_bullettime", "sm_bullettime");
	
	GetGameFolderName(Game, sizeof(Game));
}

public OnMapStart()
{
	if (StrEqual(Game, "cstrike"))	
	{	
		AddFileToDownloadsTable("materials/imgay/slowdown1.vmt");
		AddFileToDownloadsTable("materials/imgay/slowdown2.vmt");
		AddFileToDownloadsTable("materials/imgay/slowdown3.vmt");
		AddFileToDownloadsTable("materials/imgay/slowdown1.vtf");
		AddFileToDownloadsTable("materials/imgay/slowdown2.vtf");
		AddFileToDownloadsTable("materials/imgay/slowdown3.vtf");
	}
	
	g_BeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");	
	
	PrecacheSound("music/mb_bullettime/enter.mp3", true);
	PrecacheSound("music/mb_bullettime/exit.mp3", true);
	AddFileToDownloadsTable("sound/music/mb_bullettime/enter.mp3");
	AddFileToDownloadsTable("sound/music/mb_bullettime/exit.mp3");	
	
	CheatConVarSetup()
}

public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client))
		g_killCount[client] = 0;
}

public Action:Command_Bullettime(client, args)
{

	PrintToChatAll("[SM]  Admin %N has turned BULLETTIME on!!!.", client);
//	new activator = -1;	
	
	ActivateRoundEndSlowDown(client);		
	EmitSoundToClient(client ,"music/mb_bullettime/enter.mp3");		
	SetConVarInt(Cheats, 1, true, true);
	CreateTimer(GetConVarFloat(bt_admin_slowdowntime) , Bt_stop , client);

}

public Action:Bt_stop(Handle:timer, any:client)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		
		if (StrEqual(Game, "cstrike"))	
		{	
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				ClientCommand(i,"r_screenoverlay \"\"")
			}
		}
	}
}

ActivateSlow(activator) 
{
	if (slowdown > 0 || !GetConVarBool(bt_enable))
		return;
	slowdown = 55;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && !IsFakeClient(i)) 
		{
			if (StrEqual(Game, "cstrike"))	
			{			
				ClientCommand(i,"r_screenoverlay imgay/slowdown1");
			}
			if (i != activator) 
			{
				EmitSoundToClient(i, "music/mb_bullettime/enter.mp3");
			}
		}
	}
	timescale = GetConVarFloat(bt_timescale);
	ServerCommand("host_timescale %f", timescale);
}

ActivateBombSlowDown(activator) 
{
	if (slowdown > 0 || !GetConVarBool(bt_enable))
		return;
	slowdown = 55;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && !IsFakeClient(i)) 
		{
			if (StrEqual(Game, "cstrike"))	
			{		
				ClientCommand(i,"r_screenoverlay imgay/slowdown1");
			}
			if (i != activator) 
			{
				EmitSoundToClient(i, "music/mb_bullettime/enter.mp3");
			}
		}
	}
	bomb_timescale = GetConVarFloat(bt_bomb_timescale);
	ServerCommand("host_timescale %f", bomb_timescale);
}

public OnGameFrame() 
{
	if (transition && slowdown <= 10 && slowdown > 1)
	{
		timescale = GetConVarFloat(bt_timescale);
		new Float:difscale = 1.0 - timescale;
		new Float:tempscale = 1.0 - difscale * slowdown *0.1;
		ServerCommand("host_timescale %f", tempscale);
	}
	
	if (slowdown == 30)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				EmitSoundToClient(i, "music/mb_bullettime/exit.mp3");
			}
		}   
	}	

	if (slowdown == 5)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if(StrEqual(Game, "cstrike"))
				{
					ClientCommand(i,"r_screenoverlay imgay/slowdown2");
				}
			}
		}   
	}
    
	if (slowdown == 3)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				if(StrEqual(Game, "cstrike"))
				{				
					ClientCommand(i,"r_screenoverlay imgay/slowdown3");
				}
			}
		}   
	}
	if (slowdown == 1)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if(StrEqual(Game, "cstrike"))
				{				
					ClientCommand(i,"r_screenoverlay \"\"")
				}
			}
		}
	}
	if (slowdown > 1)
	{
		slowdown = slowdown - 1;
	}
}

public OnConVarChanged_Trans(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	transition = GetConVarBool(bt_trans);
}

public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		
		if(IsValidClient(i) && !IsFakeClient(i)) 
		{
			if(StrEqual(Game, "cstrike"))
			{				
				ClientCommand(i,"r_screenoverlay \"\"")
			}
		}		
	}
}

public Action:Event_BombExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	new activator = -1;	
	
	if(GetConVarInt(bt_c4) == 1)
	{
		ActivateBombSlowDown(activator);
		SetConVarInt(Cheats, 1, true, true);
	}
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new activator = -1;	
	
	if(GetConVarInt(bt_roundend) == 1)
	{
		ActivateRoundEndSlowDown(activator);
		SetConVarInt(Cheats, 1, true, true);		
	}
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(GetConVarInt(bt_roundend) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			slowdown = slowdown - 1;
			ServerCommand("host_timescale 1.0")
			SetConVarInt(Cheats, 0, true, true)

			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if(StrEqual(Game, "cstrike"))
				{				
					ClientCommand(i,"r_screenoverlay \"\"")
				}
			}
		}
	}
}

ActivateRoundEndSlowDown(activator) 
{	
	if (GetConVarBool(bt_enable))
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsValidClient(i) && !IsFakeClient(i)) 
			{
				if (StrEqual(Game, "cstrike"))	
				{		
					ClientCommand(i,"r_screenoverlay imgay/slowdown1");
				}
				if (i != activator) 
				{
					EmitSoundToAll("music/mb_bullettime/enter.mp3");
				}
			}		
		}
		
	}
	roundend_timescale = GetConVarFloat(bt_roundend_timescale);
	ServerCommand("host_timescale %f", roundend_timescale);
	
	if(GetConVarInt(bt_roundend_timer) == 1)
	{
		CreateTimer(GetConVarFloat(bt_roundend_slowdownlast) , RoundEndLast);
	}
}

public Action:RoundEndLast(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		slowdown = slowdown - 1;
		ServerCommand("host_timescale 1.0")
		SetConVarInt(Cheats, 0, true, true)
		
		if(IsValidClient(i) && !IsFakeClient(i)) 
		{
			if(StrEqual(Game, "cstrike"))
			{				
				ClientCommand(i,"r_screenoverlay \"\"")
			}
		}		
	}	
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(bt_enable))
		return;
	
	decl String:weapon[512];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:go = false;
	new activator = -1;
	
	g_killCount[attacker]++;	
	new curCount = g_killCount[attacker];
	
	if(GetConVarInt(bt_enableweapon_knife) == 1)
	{	
		for (new i = 0; i < sizeof(Weapons); i++) 
		{
			if (StrEqual(weapon,Weapons[i],false)) 
			{	
				go = true;
			}	
		
			focussound = GetConVarBool(bt_fsound);
			if (go == true && focussound >= 1) 
			{
				if(IsValidClient(attacker) && !IsFakeClient(attacker)) 
				{
					EmitSoundToClient(attacker, "music/mb_bullettime/enter.mp3");
					if (focussound >= 2) activator = attacker;
				}
				ActivateSlow(activator);
				SetConVarInt(Cheats, 1, true, true);
			}
		}
    }	
	
	if(GetConVarInt(bt_grenade) == 1)
	{
		if(StrEqual(weapon,"hegrenade",false))
		{
			go = true;
		}	
		
		focussound = GetConVarBool(bt_fsound);
		if (go == true && focussound >= 1) 
		{
			if(IsValidClient(attacker) && !IsFakeClient(attacker)) 
			{
				EmitSoundToClient(attacker, "music/mb_bullettime/enter.mp3");
				if (focussound >= 2) activator = attacker;
			}
			ActivateSlow(activator);
			SetConVarInt(Cheats, 1, true, true);
		}
    }
	if(GetConVarInt(bt_kills_enabled) ==1 && IsValidClient(attacker))
	{
		if(curCount == GetConVarInt(bt_kills))
		{
			EmitSoundToClient(attacker, "music/mb_bullettime/enter.mp3");	
			ActivateSlow(activator);
			SetConVarInt(Cheats, 1, true, true);
		}
	}	
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public CheatConVarSetup()
{
	new flags = GetConVarFlags(Cheats) 
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(Cheats, flags)
	if(GetConVarInt(Cheats) == 1)
	{
		SetConVarInt(Cheats, 0, true, true)
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetConVarInt(bt_enableweapontracers) == 1)
	{
		new client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));

		new Float:Life;
		Life = GetConVarFloat( g_CvarLife );
		new Float:Width;
		Width = GetConVarFloat( g_CvarWidth );
	
		decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client, vecAng);
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);

		new bool:go = true;		
		
		new String:sWeapon[32];
		GetClientWeapon(client,sWeapon, sizeof(sWeapon));
		
		if(StrEqual ("weapon_knife" , sWeapon) || StrEqual ("weapon_flashbang" , sWeapon) || StrEqual ("weapon_hegrenade" , sWeapon) || StrEqual ("weapon_molotov" , sWeapon) || StrEqual ("weapon_smokegrenade" , sWeapon) || StrEqual ("weapon_decoy" , sWeapon))
		{
			go = false;
		}
	
		if(go == true && TR_DidHit(trace))
		{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
					
			new color[4];
			if(GetClientTeam(client) == 2)
			{
				color[0] = GetConVarInt( g_CvarTeam2Red ); 
				color[1] = GetConVarInt( g_CvarTeam2Green );
				color[2] = GetConVarInt( g_CvarTeam2Blue );
			}
			else if(GetClientTeam(client) == 3)
			{
				color[0] = GetConVarInt( g_CvarTeam3Red ); 
				color[1] = GetConVarInt( g_CvarTeam3Green );
				color[2] = GetConVarInt( g_CvarTeam3Blue );
			}
			color[3] = GetConVarInt( g_CvarTrans );					
			
			CloseHandle(trace);
					

			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, Life, Width, Width, 1, 0.0, color, 0);
			TE_SendToAll();
		}
	}
	else if( GetConVarInt(bt_enableweapontracersonlybt) == 1 && GetConVarInt(bt_enableweapontracers) == 0 && GetConVarInt(Cheats) == 1)
	{
		new client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));

		new Float:Life;
		Life = GetConVarFloat( g_CvarLife );
		new Float:Width;
		Width = GetConVarFloat( g_CvarWidth );
	
		decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client, vecAng);
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);

		new bool:go = true;		
		
		new String:sWeapon[32];
		GetClientWeapon(client,sWeapon, sizeof(sWeapon));
		
		if(StrEqual ("weapon_knife" , sWeapon) || StrEqual ("weapon_flashbang" , sWeapon) || StrEqual ("weapon_hegrenade" , sWeapon) || StrEqual ("weapon_molotov" , sWeapon) || StrEqual ("weapon_smokegrenade" , sWeapon) || StrEqual ("weapon_decoy" , sWeapon))
		{
			go = false;
		}
	
		if(go == true && TR_DidHit(trace))
		{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
					
			new color[4];
			if(GetClientTeam(client) == 2)
			{
				color[0] = GetConVarInt( g_CvarTeam2Red ); 
				color[1] = GetConVarInt( g_CvarTeam2Green );
				color[2] = GetConVarInt( g_CvarTeam2Blue );
			}
			else if(GetClientTeam(client) == 3)
			{
				color[0] = GetConVarInt( g_CvarTeam3Red ); 
				color[1] = GetConVarInt( g_CvarTeam3Green );
				color[2] = GetConVarInt( g_CvarTeam3Blue );
			}
			color[3] = GetConVarInt( g_CvarTrans );					
			
			CloseHandle(trace);
					

			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, 0, 0, 0, Life, Width, Width, 1, 0.0, color, 0);
			TE_SendToAll();
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) 
{
	return entity>MaxClients;
}