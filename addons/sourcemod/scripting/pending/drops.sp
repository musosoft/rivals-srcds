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
#define DropProbabilityDestruction 	600

#define DropPositionOffset 30

new Handle:BeaconTimers[MAXPLAYERS+1];
new Handle:h_Trie;
new g_ExplosionSprite = -1;

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
	version = "1.3-private",
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

	//--------------BirdFly------------------------//
	PrecacheModel("models/crow.mdl",true);
	PrecacheModel("models/pigeon.mdl",true);
	PrecacheModel("models/seagull.mdl",true);
	PrecacheSound("ambient/playonce/weather/thunder4",true);
	PrecacheSound("ambient/playonce/weather/thunder5",true);
	PrecacheSound("ambient/playonce/weather/thunder6",true);
	PrecacheSound("ambient/creatures/seagull_idle1",true);
	PrecacheSound("ambient/creatures/seagull_idle2",true);
	PrecacheSound("ambient/creatures/seagull_idle3",true);
	PrecacheSound("ambient/creatures/pigeon_idle1",true);
	PrecacheSound("ambient/creatures/pigeon_idle2",true);
	PrecacheSound("ambient/creatures/pigeon_idle3",true);
	PrecacheSound("ambient/creatures/pigeon_idle4",true);
	PrecacheSound("ambient/animal/crow",true);
	PrecacheSound("ambient/animal/crow_1",true);
	PrecacheSound("ambient/animal/crow_2",true);
	g_ExplosionSprite = PrecacheModel("materials/models/weapons/v_models/eq_molotov/v_eq_molotov_lighter_flame.vmt",true);
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
	
	if(GetRandomInt(0, DropProbabilityMoney)==0)
	{		
		iGiftType = 0;
	}		
	
	if(GetRandomInt(0, DropProbabilityHealth)==0)
	{
		iGiftType = 1;
	}	
		
	 if(GetRandomInt(0, DropProbabilityDestruction)==0)
	 {
	 	iGiftType = 2;
	 }

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
			
			// Destrcution
			case 2:
			{							
				CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Drop DESTRUCTION");
			}
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
					//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickeduphealthgift");					
					FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickeduphealthgift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
				}
				
				// Destrcution
				case 2:
				{
					BirdFly(touching);
					CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Pickup DESTRUCTION", sNickname);
					//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickedupmoneygift");					
					FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickedupdestructiongift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
				}
				
				// High
				// case 3:
				// {
				// 	GiveMoney(touching, 16000);					
				// 	CPrintToChatAll("{chartreuse}[{dodgerblue}Drops{chartreuse}]{default} %t", "Pickup HIGH", sNickname);
				// 	//Format(command, sizeof(command), "hlx_sm_player_action %d %s", touching, "pickedupmoneygift");					
				// 	FormatEx(sLogString, sizeof(sLogString), "\"%N<%d><%s><%s>\" triggered \"pickeduphighgift\"", touching, GetClientUserId(touching), sSteamId, sTeamName);
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

new Bird[65];
public BirdFly(client)
{
	if(!StatusCheck(client)) 
		return;
	ThirdPerson(client);
	SetEntityGravity(client, 0.3);
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	new BirdType = GetRandomInt(1,1);
	switch(BirdType)
	{
		case 1:SetEntityModel(client, "models/crow.mdl");
		case 2:SetEntityModel(client, "models/pigeon.mdl");
		case 3:SetEntityModel(client, "models/seagull.mdl");
	}
	
	Bird[client] = 6;
	PrintHintText(client,"%t %d","Missing Bird",Bird[client],"%t","Hint");
	
	CreateTimer(1.0, BirdBlyCounter	, client);
	CreateTimer(4.0, BirdThunder	, client);
	CreateTimer(5.0, BirdThunder	, client);
	CreateTimer(6.37,BirdStop		, client);
	CreateTimer(6.4, BirdThunder	, client);
	CreateTimer(6.5, ClientKillDelay, client);
	CreateTimer(6.5, BirdExplosion	, client);
	
	new String:BirdTypeSound[64],Float:pos[3];
	GetClientAbsOrigin(client, pos);
	if(BirdType == 1)
	{
		switch(GetRandomInt(1,3))
		{
			case 1:BirdTypeSound = "ambient/animal/crow.wav";
			case 2:BirdTypeSound = "ambient/animal/crow_1.wav";
			case 3:BirdTypeSound = "ambient/animal/crow_2.wav";
		}
	}
	if(BirdType == 2) 
		Format(BirdTypeSound,sizeof(BirdTypeSound),"ambient/creatures/pigeon_idle%d.wav",GetRandomInt(1,4));
	if(BirdType == 3) 
		Format(BirdTypeSound,sizeof(BirdTypeSound),"ambient/creatures/seagull_idle%d.wav",GetRandomInt(1,3));
	EmitAmbientSound2(BirdTypeSound, pos, client, SNDLEVEL_RAIDSIREN);
}

public Action:BirdStop(Handle: timer, any: client)
{ 
	SetEntityMoveType(client, MOVETYPE_NONE);
}

public Action:BirdThunder(Handle: timer, any: client)
{
	decl String:namebegin[64] = "LaserBeam0", String:nameend[64] = "LaserBeam_end0", String:number[32];
	IntToString(client, number, 32);
	ReplaceString(namebegin, 64, "0", number, false);
	ReplaceString(nameend, 64, "0", number, false);
	
	new Float:clientposOrgin[3],Float:clientposOrgin2[3];
	GetClientAbsOrigin(client, clientposOrgin);
	GetClientEyePosition(client, clientposOrgin2);
	clientposOrgin2[2] += 2000;
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client,"10");
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client,"10");
	
	new String:ThunderSound[64];
	Format(ThunderSound,sizeof(ThunderSound),"ambient/playonce/weather/thunder%d.wav",GetRandomInt(4,6));
	EmitAmbientSound2(ThunderSound, clientposOrgin, client, SNDLEVEL_RAIDSIREN);
}

public Action:BirdExplosion(Handle: timer, any: client)
{
	new Float:clientposOrgin[3];
	GetClientAbsOrigin(client, clientposOrgin);
	TE_SetupExplosion2(client,clientposOrgin, g_ExplosionSprite, 0.1, 1, 0, 600, 5000);
	
	new String:ThunderSound[64];
	switch(GetRandomInt(1,3)){
		case 1:ThunderSound = "ambient/playonce/weather/thunder_distant_01.wav";
		case 2:ThunderSound = "ambient/playonce/weather/thunder_distant_02.wav";
		case 3:ThunderSound = "ambient/playonce/weather/thunder_distant_06.wav";
	}
	EmitAmbientSound2(ThunderSound, clientposOrgin, client, SNDLEVEL_RAIDSIREN);
}

public Action:BirdBlyCounter(Handle: timer, any: client)
{
	Bird[client] -= 1;
	if(Bird[client] >= 0 && StatusCheck(client)){
		CreateTimer(1.0, BirdBlyCounter, client);
		if(Bird[client] >= 3)
			PrintHintText(client,"%t %d","Missing Bird",Bird[client],"%t","Hint");
		else
		 	PrintCenterText(client,"%t %d","Missing Bird",Bird[client],"%t","Hint");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(Bird[client] <= 0 || !StatusCheck(client)) 
		return;
	if(buttons & IN_JUMP && buttons & IN_FORWARD)
	{
		new Float:vec[3];
		GetAngleVectors(angles, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec , vec);
		
		if(buttons & IN_SPEED)
			ScaleVector(vec, 550.0);
		else 
			ScaleVector(vec, 300.0);
		vec[2] +=200;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	}
}

public Action:ClientKillDelay(Handle: timer, any: client){ ClientKill(client); }
stock ClientKill(client){
	ClientDefault(client);
	
	CreateParticlePub(client,"light_gaslamp_glow");
	
	//http://docs.sourcemod.net/api/index.php?fastload=show&id=1028&
	SDKHooks_TakeDamage(client, 0, 0 , 1410065408.0);
}

stock StatusCheck(const client = 0){
	if (!client)
		return true;
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client)) 
		return false;
	return true;
}

stock ThirdPerson(client){
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);
}

stock EmitAmbientSound2(const String:name[], const Float:pos[3], entity = SOUND_FROM_WORLD, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS,Float:vol = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, Float:delay = 0.0){
	PrecacheSound(name, true);
	EmitAmbientSound(name,pos,entity,level, flags,vol,pitch,delay);
}

stock CreateBeam(const String:startname[],const String:endname[], const Float:start[3], const Float:end[3], client,const String:NoiseAmplitude[] = "50"){
	// create laser beam
	new beam_ent = CreateEntityByName("env_beam");
	new startpoint_ent = CreateEntityByName("env_beam");
	new endpoint_ent = CreateEntityByName("env_beam");
	
	TeleportEntity(startpoint_ent, start, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(endpoint_ent, end, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(startpoint_ent, "targetname", startname);
	DispatchKeyValue(endpoint_ent, "targetname", endname);
	
	DispatchSpawn(startpoint_ent);
	DispatchSpawn(endpoint_ent);
	
	SetEntityModel(beam_ent, "materials/sprites/physbeam.vmt");
	
	decl String:Client[128];
	IntToString(client, Client, 128);
	
	SetRandomSeed(GetRandomInt( 1 , 999 ))
	
	new String:rendercolor[32];
	Format(rendercolor,sizeof(rendercolor),"%d %d %d",GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ));
	DispatchKeyValue(beam_ent, "rendercolor", rendercolor);
	
	SetRandomSeed(GetRandomInt( 1 , 999 ))
	new String:BoltWidth[32];
	FloatToString(GetRandomFloat(2.0, 5.0),BoltWidth, sizeof(BoltWidth));
	DispatchKeyValue(beam_ent, "BoltWidth", BoltWidth);
	
	DispatchKeyValue(beam_ent, "targetname", Client);
	DispatchKeyValue(beam_ent, "texture", "materials/sprites/physbeam.vmt");
	DispatchKeyValue(beam_ent, "TouchType", "4");
	DispatchKeyValue(beam_ent, "life", "2.5");
	DispatchKeyValue(beam_ent, "StrikeTime", "0.1");
	DispatchKeyValue(beam_ent, "renderamt", "255");
	DispatchKeyValue(beam_ent, "HDRColorScale", "10.0");
	DispatchKeyValue(beam_ent, "decalname", "redglowfade"); //"Bigshot" "redglowfade"
	DispatchKeyValue(beam_ent, "TextureScroll", "5");
	DispatchKeyValue(beam_ent, "LightningStart", startname);
	DispatchKeyValue(beam_ent, "LightningEnd", endname);
	
	DispatchKeyValue(beam_ent, "ClipStyle", "1");
	DispatchKeyValue(beam_ent, "NoiseAmplitude", NoiseAmplitude);
	//DispatchKeyValue(beam_ent, "damage", "500");
	//DispatchKeyValue(beam_ent, "Radius", "256");
	//DispatchKeyValue(beam_ent, "framerate", "50");
	//DispatchKeyValue(beam_ent, "framestart", "1");
	DispatchKeyValue(beam_ent, "spawnflags", "4");
	
	DispatchSpawn(beam_ent);
	ActivateEntity(beam_ent);
	AcceptEntityInput(beam_ent, "StrikeOnce");
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"Beam_%d",client);
	DispatchKeyValue(client, "targetname", targetname)
	SetVariantString(targetname);
	AcceptEntityInput(endpoint_ent, "SetParent");
	
	CreateTimer(0.5, KillEntity, beam_ent);
	CreateTimer(0.5, KillEntity, startpoint_ent);
	CreateTimer(0.5, KillEntity, endpoint_ent);
}

stock TE_SetupExplosion2(client,const Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, const Float:normal[3]={0.0, 0.0, 1.0}, MaterialType='C'){
	TE_SetupExplosion(pos, Model,Scale, Framerate, Flags, Radius, Magnitude,normal, MaterialType)
	TE_Send2(client)
}

stock ClientDefault(client){
	SlayLoserBird[client] = 0
	
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	DispatchKeyValue(client, "targetname", "")
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	
	SetEntityGravity(client,1.0)
	SetEntityRenderMode(client,RENDER_NORMAL)
	SetEntityRenderColor(client, 255, 255, 255, 255);
}