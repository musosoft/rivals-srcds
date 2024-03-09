#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <clientprefs>

#define PLUGIN_VERSION			 "2.00-dev"
#define PREFIX					 "{chartreuse}[{dodgerblue}AntiStuck{chartreuse}]{default}"
#define COMMANDS				 "sm_stuck", "sm_unblock", "sm_noblock", "sm_unstuck"
#define COLLISION_GROUP_PUSHAWAY 17
#define COLLISION_GROUP_PLAYER	 5
#define COOLDOWN_DURATION		 10.0

float lastUseTime[MAXPLAYERS + 1];
float lastKnownPosition[MAXPLAYERS + 1][3];
float lastCheckTime[MAXPLAYERS + 1];
bool  isUnstuckTimerActive[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Anti Stuck",
	author = "muso.sk",
	description = "Allows players to free themselves when stuck by pushing them away from their current position.",
	version = PLUGIN_VERSION,
	url = "https://github.com/musosoft/rivals-srcds/blob/master/addons/sourcemod/scripting/antistuck.sp"
};

public void OnPluginStart()
{
	char commands[][] = { COMMANDS };
	for (int i = 0; i < sizeof(commands); i++)
	{
		RegConsoleCmd(commands[i], Command_Stuck);
	}

	CreateTimer(5.0, CheckAllPlayersStuck, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Stuck(int client, int args)
{
	float currentTime = GetGameTime();

	if (currentTime - lastUseTime[client] < COOLDOWN_DURATION)
	{
		float remainingTime = COOLDOWN_DURATION - (currentTime - lastUseTime[client]);
		CPrintToChat(client, "%s Please wait %.1f more seconds to use this command again.", PREFIX, remainingTime);
		return Plugin_Handled;
	}

	lastUseTime[client] = currentTime;

	if (IsClientInGame(client) && IsPlayerAlive(client) && !isUnstuckTimerActive[client])
	{
		CPrintToChatAll("%s Attempting to unstuck player...", PREFIX);
		isUnstuckTimerActive[client] = true;
		CreateTimer(1.0, Timer_UnBlockPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		float maxDistance = 500.0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				float otherPos[3];
				GetClientAbsOrigin(i, otherPos);
				if (GetVectorDistance(clientPos, otherPos) <= maxDistance)
				{
					SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
				}
			}
		}
	}
	else if (isUnstuckTimerActive[client])
	{
		CPrintToChat(client, "%s Command is already in use.", PREFIX);
	}
	else
	{
		CPrintToChat(client, "%s You must be alive to use this command.", PREFIX);
	}

	return Plugin_Handled;
}

public Action Timer_UnBlockPlayer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientConnected(client)) return Plugin_Continue;

	isUnstuckTimerActive[client] = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		}
	}

	return Plugin_Continue;
}

public Action CheckAllPlayersStuck(Handle timer)
{
	float currentTime = GetTickedTime();
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client) || currentTime - lastCheckTime[client] < 5.0) continue;

		float currentPos[3];
		GetClientAbsOrigin(client, currentPos);

		if (GetVectorDistance(lastKnownPosition[client], currentPos) < 10.0)
		{
			TryUnstuckPlayer(client);
		}

		lastKnownPosition[client] = currentPos;
		lastCheckTime[client]	  = currentTime;
	}
	return Plugin_Continue;
}

void TryUnstuckPlayer(int client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
	CreateTimer(1.0, Timer_ResetCollisionGroup, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ResetCollisionGroup(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientConnected(client)) return Plugin_Continue;

	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	return Plugin_Continue;
}
