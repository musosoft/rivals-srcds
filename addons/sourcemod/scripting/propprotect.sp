#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
	name        = "Prop Damage Protect",
	author      = "rodipm, muso.sk",
	description = "Protects you from taking prop damage!",
	version     = "1.0-private",
	url         = "https://forums.alliedmods.net/showthread.php?p=1532060"
};

public OnPluginStart()
{
	HookEvent("player_spawn", spawn);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));  
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:classname[256];
	decl String:classname1[256];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	GetEdictClassname(attacker, classname1, sizeof(classname1));
	
	if(attacker != 0)
	{
		if(StrEqual(classname, "func_physbox", false) || StrEqual(classname, "prop_physics", false) || StrEqual(classname1, "func_physbox", false) || StrEqual(classname1, "prop_physics", false))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
