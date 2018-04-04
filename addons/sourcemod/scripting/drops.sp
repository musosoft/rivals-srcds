#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <timers>
#include <morecolors>

#define ModelGift			"models/items/cs_gift.mdl"
#define SoundGiftDrop		"ambient/misc/metal8.wav"
#define SoundGiftPickup		"items/gift_pickup.wav"
#define SoundGiftBeacon		"ambient/tones/floor1.wav"
#define IntervalGiftBeacon  2.5

#define DropProbabilityMoney 	700
#define DropProbabilityHealth 	1100
// #define DropProbabilityBronze 	600

#define DropPositionOffset 30

new Handle:BeaconTimers[MAXPLAYERS+1];
new Handle:h_Trie;

enum GiftAttributes 
{
	iType,
	iRotator
};

public Plugin:myinfo =
{
	name = "Drops",
	author = "TotaLama, muso.sk",
	description = "Drop gift packs",
	version = "1.2-private",
	url = ""
};

public OnPluginStart()
{	
	LoadTranslations("drops.phrases");	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);	
	
	h_Trie = CreateTrie();
}

public OnMapStart()
{   
	InitPrecache();
	ClearTrie(h_Trie);
}

public InitPrecache() {
	PrecacheModel(ModelGift);		
	PrecacheSound(SoundGiftDrop);
	PrecacheSound(SoundGiftPickup);
	PrecacheSound(SoundGiftBeacon);	
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new iGiftType = -1;
	
	// Money
	if(GetRandomInt(0, DropProbabilityMoney)==0)
	{		
		iGiftType = 0;
	}		
	
	// Health
	if(GetRandomInt(0, DropProbabilityHealth)==0)
	{
		iGiftType = 1;
	}	
		
	// // Gold
	// if(GetRandomInt(0, DropProbabilityGold)==0)
	// {
	// 	iGiftType = 2;
	// }

	if(iGiftType >= 0) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));	
		DropGift(client, iGiftType);	
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	KillBeaconTimers();
}


public KillBeaconTimers()
{
   for (new i = 1; i <= MaxClients; i++)
   {				
		if(BeaconTimers[i] != INVALID_HANDLE)
		{
			KillTimer(BeaconTimers[i]);
			BeaconTimers[i] = INVALID_HANDLE;
		}
   }
}

public DropGift(client, iGiftType)
{
	new entity;
	
	if((entity = CreateEntityByName("prop_dynamic")) != -1)
	{
		new Float:origin[3];
		GetClientAbsOrigin(client, origin);		
		origin[2]-= DropPositionOffset;
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		
		decl String:targetname[100];
		targetname[0] = '\0';
		
		Format(targetname, sizeof(targetname), "gift_%i", entity);
		
		
		new iGiftRotator = CreateEntityByName("func_rotating");
		DispatchKeyValueVector(iGiftRotator, "origin", origin);
		DispatchKeyValue(iGiftRotator, "targetname", targetname);
		DispatchKeyValue(iGiftRotator, "maxspeed", "200");
		DispatchKeyValue(iGiftRotator, "friction", "0");
		DispatchKeyValue(iGiftRotator, "dmg", "0");
		DispatchKeyValue(iGiftRotator, "solid", "0");
		DispatchKeyValue(iGiftRotator, "spawnflags", "1024");
		DispatchSpawn(iGiftRotator);
		
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", iGiftRotator, iGiftRotator);
		AcceptEntityInput(iGiftRotator, "Start");
		
		SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", iGiftRotator);	
						
		DispatchKeyValue(entity, "model", ModelGift);	
		DispatchKeyValue(entity, "physicsmode", "3");
		DispatchKeyValue(entity, "massScale", "1.0");		
		DispatchKeyValue(entity, "targetname", targetname);
		DispatchSpawn(entity);
		
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);		
		
		SDKHook(entity, SDKHook_StartTouch, Event_StartTouch);
		
		new String:sEntity[12];
		sEntity[0] = '\0';		
		IntToString(entity, sEntity, sizeof(sEntity));				
		
		new SpawnedGiftAttributes[GiftAttributes];
		SpawnedGiftAttributes[iType] = iGiftType;
		SpawnedGiftAttributes[iRotator] = iGiftRotator;
				
		SetTrieArray(h_Trie, sEntity, SpawnedGiftAttributes[0], 2, true);				

		BeaconTimers[client] = CreateTimer(IntervalGiftBeacon, GiftBeacon, entity, TIMER_REPEAT);		
		EmitSoundToAll(SoundGiftDrop, SOUND_FROM_PLAYER);				
		
		switch(iGiftType)
		{
			// Money
			case 0:
			{								
				CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Drop MONEY");
			}
			
			// Health
			case 1:
			{				
				CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Drop HEALTH");
			}
			
			// // Gold
			// case 2:
			// {							
			// 	CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Drop GOLD");
			// }
		}
	}
}

public Event_StartTouch(touched, touching)
{
	decl String:model[128];
	model[0] = '\0';

	GetEntPropString(touched, Prop_Data, "m_ModelName", model, sizeof(model));		

	if(touching > 0 && touching <= MaxClients && IsPlayerAlive(touching) && !IsFakeClient(touching) && StrEqual(model, ModelGift))
	{
		if(IsValidEntity(touched))
		{										
			SDKUnhook(touched, SDKHook_StartTouch, Event_StartTouch);
			
			decl String:sEntity[12];
			sEntity[0] = '\0';	
			IntToString(touched, sEntity, sizeof(sEntity));
			
			AcceptEntityInput(touched, "Kill");			
			
			new GetGiftAttributes[GiftAttributes];						
			if(!GetTrieArray(h_Trie, sEntity, GetGiftAttributes[0], 2))
			{											
				return;
			}									
			
			AcceptEntityInput(GetGiftAttributes[iRotator], "Kill");			
			
			RemoveFromTrie(h_Trie, sEntity);
			
			decl String:sLogString[512];
			decl String:sNickname[256];												
			decl String:sSteamId[20];
			decl String:sTeamName[16];			

			//decl String:command[1024];
			
			GetClientName(touching, sNickname, sizeof(sNickname));
			GetTeamName(GetClientTeam(touching), sTeamName, sizeof(sTeamName));
			GetClientAuthId(touching, AuthId_Steam2, sSteamId, 20);
			
			switch(GetGiftAttributes[iType]){
				// Money
				case 0:
				{					
					GiveMoney(touching, 4000);					
					CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Pickup MONEY", sNickname);
					//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickedupmoneygift");															
					FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickedupmoneygift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
				}
				
				// Health
				case 1:
				{
					SetEntityHealth(touching, 100);					
					CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Pickup HEALTH", sNickname);
					//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickedupsilvergift");					
					FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickedupsilvergift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
				}
				
				// // Gold
				// case 2:
				// {
				// 	GiveMoney(touching, 16000);					
				// 	CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Pickup GOLD", sNickname);
				// 	//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickedupgoldgift");					
				// 	FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickedupgoldgift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
				// }
			}
			
			//LogMessage(command);
			//ServerCommand(command);
			LogToGame("%s", sLogString);
			EmitSoundToAll(SoundGiftPickup, SOUND_FROM_PLAYER);						
		}		
	}
}

public GiveMoney(client, iAmount){
	new iPlayersMoney = GetEntProp(client, Prop_Send, "m_iAccount");
	new iNewMoney = iAmount + iPlayersMoney;
	
	if(iNewMoney > 16000)
	{		
		SetEntProp(client, Prop_Send, "m_iAccount", 16000);
	}
	else 
	{
		SetEntProp(client, Prop_Send, "m_iAccount", iNewMoney);
	}
}

public Action:GiftBeacon(Handle:timer, any:entity)
{	
	decl String:sEntity[12];
	sEntity[0] = '\0';	
	IntToString(entity, sEntity, sizeof(sEntity));
	
	new GetGiftAttributes[GiftAttributes];						
	if(!GetTrieArray(h_Trie, sEntity, GetGiftAttributes[0], 2))
	{		
		return;
	}	
			
	EmitSoundToAll(SoundGiftBeacon, entity);
}