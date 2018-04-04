#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "TeamTalk",
	author = "muso.sk",
	description = "Adds the possibility to teamtalk while alltalk is enabled",
	version = "0.1",
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static s_iButtons[MAXPLAYERS+1];
 
	// Player just started pushing +use
	if ((buttons & IN_USE) > 0 && (s_iButtons[client] & IN_USE) == 0)
	{
		if (IsPlayerAlive(client))
		{
			new iSpeakerTeam = GetClientTeam(client);

			for (new i=1; i<=MaxClients; i++)
			{
				// We can always hear ourself..
				if (i==client)
				{
					continue;
				}
 
				// Team mates should still hear us.
				if (!IsClientInGame(i) || GetClientTeam(i) == iSpeakerTeam) 
				{
					continue;
				}
 
				// This guy isn't in our team, so he shouldn't hear what i'm saying.
				SetListenOverride(i, client, Listen_No);
			}
		}
	}
	// Player just stopped pushing +use
	else if ((buttons & IN_USE) == 0 && (s_iButtons[client] & IN_USE) > 0)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			// We can always hear ourself..
			if (i == client)
				continue;
 
			// Nothing to reset, if not ingame.
			if (!IsClientInGame(i))
				continue;
 
			// Let the game decide again.
			SetListenOverride(i, client, Listen_Default);
		}
	}
	s_iButtons[client] = buttons;
	return Plugin_Continue;
}