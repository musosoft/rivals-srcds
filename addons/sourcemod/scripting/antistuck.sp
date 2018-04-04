#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <clientprefs>

#define PLUGIN_VERSION "1.03-private"
#define PREFIX "{chartreuse}[{dodgerblue}AntiStuck{chartreuse}]{default}"

public Plugin:myinfo =
{
	name = "Anti Stuck",
	author = "muso.sk",
	description = "Allows players to push them away from stucked player",
	version = PLUGIN_VERSION,
	url = ""
};

new TimerActive;

#define COLLISION_GROUP_PUSHAWAY 17
#define COLLISION_GROUP_PLAYER 5

public OnPluginStart()
{
	RegConsoleCmd("sm_stuck", Command_Stuck);
	RegConsoleCmd("sm_unblock", Command_Stuck);
	RegConsoleCmd("sm_noblock", Command_Stuck);
	RegConsoleCmd("sm_unstuck", Command_Stuck);
}

public Action:Command_Stuck(client, args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && TimerActive == 0)
	{
		CPrintToChatAll("%s Unstucked players", PREFIX);	
		TimerActive = 1;
		CreateTimer(1.0, Timer_UnBlockPlayer, client);
		
		for (new i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
			}
		}
	}
	else if (TimerActive == 1)
	{
		CPrintToChat(client, "%s Command is already in use", PREFIX);
	}
	else
	{
		CPrintToChat(client, "%s You must be alive to use this command", PREFIX);
	}
	
	return Plugin_Handled;
}

public Action:Timer_UnBlockPlayer(Handle:timer, any:client)
{
	TimerActive = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		}
	}
	
	return Plugin_Continue;
}

public Action:TimerAnnounce(Handle:timer, any:client) 
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		CPrintToChat(client, "{chartreuse}[{dodgerblue}AntiStuck{chartreuse}]{default} \"Unbug\" command: !unblock");
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(client && !IsFakeClient(client))
	{
		CreateTimer(30.0, TimerAnnounce, client);
	}
}