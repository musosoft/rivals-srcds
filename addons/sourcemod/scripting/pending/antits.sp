#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

public Plugin:myinfo =
{
	name = "Anti TeamSpeak",
	description = "Fade to black after death",
	author = "muso.sk",
	version = "1.0",
	url = "http://rivals.cz"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnEventShutdown()
{
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		ScreenFade(client, 0, 0, 0, 255, 1, 8);
		CreateTimer(0.0, RemoveRadar, client);
		CPrintToChat(client, "{chartreuse}[{dodgerblue}AntiTeamspeak{chartreuse}]{green} You are suspected as unfair player. Fading screen to black...");
	}
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		CreateTimer(5.0, AddRadar, client, 0);
	}
}

public ScreenFade(client, red, green, blue, alpha, delay, type)
{
	new Handle:msg;
	new duration = delay * 1000;
	msg = StartMessageOne("Fade", client, 0);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public Action:RemoveRadar(Handle:timer, any:client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}

public Action:AddRadar(Handle:timer, any:client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.5);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}

