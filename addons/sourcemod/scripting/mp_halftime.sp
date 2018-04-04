#pragma semicolon 1

#define FADE_IN 0x0001

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <morecolors>

new Handle:mp_halftime		= INVALID_HANDLE;
new Handle:mp_maxrounds		= INVALID_HANDLE;
new Handle:mp_startmoney	= INVALID_HANDLE;

new bool:halftime;
new maxrounds;
new startmoney;

new bool:firsthalf = false;
new bool:swap = false;

new g_iAccount = -1;

public Plugin:myinfo = 
{
	name = "[CS:S] mp_halftime",
	author = "GabenNewell (Bad Kitty), muso.sk",
	description = "Determines whether the match switches sides in a halftime event.",
	version = "1.1.0-private",
	url = "https://forums.alliedmods.net/showthread.php?t=241716"
};

public OnPluginStart()
{
	mp_halftime		= CreateConVar("mp_halftime", "1", "Determines whether the match switches sides in a halftime event.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	mp_maxrounds	= FindConVar("mp_maxrounds");
	mp_startmoney	= FindConVar("mp_startmoney");

	
	HookConVarChange(mp_halftime,	ConVarChange);
	HookConVarChange(mp_maxrounds,	ConVarChange);
	HookConVarChange(mp_startmoney,	ConVarChange);
	
	halftime	= GetConVarBool(mp_halftime);
	maxrounds	= GetConVarInt(mp_maxrounds);
	startmoney	= GetConVarInt(mp_startmoney);
	
	g_iAccount	= FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	if (halftime)
	{
		HookEvent("round_start",	Event_RoundStart);
		HookEvent("round_end",		Event_RoundEnd);
		HookEvent("player_spawn",	Event_PlayerSpawn);
	}
}

public OnMapStart()
{
	PrecacheSound("common/warning.wav");
}

public ConVarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new nval = StringToInt(newValue);
	
	if (cvar == mp_halftime)
	{
		halftime = (nval == 1) ? true : false;
		
		if (halftime)
		{
			HookEvent("round_start",	Event_RoundStart);
			HookEvent("round_end",		Event_RoundEnd);
		}
		else
		{
			UnhookEvent("round_start",	Event_RoundStart);
			UnhookEvent("round_end",	Event_RoundEnd);
		}
	}
	else if (cvar == mp_maxrounds)
	{
		maxrounds = nval;
	}
	else if (cvar == mp_startmoney)
	{
		startmoney = nval;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((CS_GetTeamScore(2) + CS_GetTeamScore(3)) == 0)
	{
		firsthalf = true;
	}
	
	if (swap)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client) > 1)
			{
				for (new weapon, i = 0; i < 5; i++)
				{
					if (i != 2 && i != 4)
					{
						while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
						{
							RemovePlayerItem(client, weapon);
						}
					}
				}
				
				GivePlayerItem(client, (GetClientTeam(client) == 2) ? "weapon_glock" : "weapon_usp");
				
				SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
				SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
				SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
				SetEntData(client, g_iAccount, startmoney, 4, true);
			}
		}		
		swap = false;
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (firsthalf)
	{
		new timeleft;
		new timelimit;
		GetMapTimeLeft(timeleft);
		GetMapTimeLimit(timelimit);
		
		if ((maxrounds != 0 && (CS_GetTeamScore(2) + CS_GetTeamScore(3)) == (maxrounds / 2)) || (timelimit != 0 && timeleft <= (timelimit * 30)))
		{
			CreateTimer(6.2, SwapTeams);
		}
	}
}

public Action:SwapTeams(Handle:timer)
{
	CPrintToChatAll("{chartreuse}[{dodgerblue}HalfTime{chartreuse}]{default} Teams swapped!");
	new Handle:msg;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{				
			CS_SwitchTeam(client, (GetClientTeam(client) == 2) ? 3 : 2);

			if (GetClientTeam(client) == 2)
			{
				msg = StartMessageOne("Fade", client);
				BfWriteShort(msg, 500);
				BfWriteShort(msg, 0); //duration
				BfWriteShort(msg, FADE_IN); //type
				BfWriteByte(msg, 255); //red
				BfWriteByte(msg, 0); //green
				BfWriteByte(msg, 0); //blue
				BfWriteByte(msg, 255); //alpha
				EndMessage();

				EmitSoundToClient(client, "common/warning.wav");
				PrintCenterText(client, "[HalfTime] Teams switched! You are now T.");
			}
			else
			{
				msg = StartMessageOne("Fade", client);
				BfWriteShort(msg, 500);
				BfWriteShort(msg, 0); //duration
				BfWriteShort(msg, FADE_IN); //type
				BfWriteByte(msg, 0); //red
				BfWriteByte(msg, 0); //green
				BfWriteByte(msg, 255); //blue
				BfWriteByte(msg, 255); //alpha
				EndMessage();

				EmitSoundToClient(client, "common/warning.wav");
				PrintCenterText(client, "[HalfTime] Teams switched! You are now CT.");
			}
		}
	}
	
	new tmp = CS_GetTeamScore(2);
	CS_SetTeamScore(2, CS_GetTeamScore(3));
	CS_SetTeamScore(3, tmp);
	
	SetTeamScore(2, CS_GetTeamScore(2));
	SetTeamScore(3, CS_GetTeamScore(3));
	
	swap = true;
	firsthalf = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (maxrounds != 0 && (CS_GetTeamScore(2) + CS_GetTeamScore(3)) == (maxrounds / 2))
	{
		SetEntData(client, g_iAccount, startmoney, 4, true);
	}
}