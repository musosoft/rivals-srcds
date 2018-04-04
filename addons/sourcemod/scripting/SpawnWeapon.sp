#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:szWeaponArray[2];

enum {
	TT = 0, 
	CT
}
public Plugin:myinfo = {
	name = "Spawn Weapon",
	author = "muso.sk",
	description = "muso.sk",
	version = PLUGIN_VERSION,
	url = "muso.sk"
}
public void OnPluginStart()
{
	CreateConVar("Spawn_Weapon", PLUGIN_VERSION, "Console Display Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("Spawn_Weapon_Override", Command_Override, ADMFLAG_CUSTOM2, "Command to set immunity to");
	HookEvent("player_spawn", Event_Spawn);
}
public OnMapStart()
{
	decl String:szMap[64], String:szFilePath[PLATFORM_MAX_PATH];
	
	GetCurrentMap(szMap, sizeof(szMap));
	if (strncmp(szMap, "de_", 3) || strncmp(szMap, "cs_", 3) || strncmp(szMap, "knas_", 5) == 0){
		BuildPath(Path_SM, szFilePath, PLATFORM_MAX_PATH, "spawn_weapon.ini");
	}
	else {
		BuildPath(Path_SM, szFilePath, PLATFORM_MAX_PATH, "spawn_weapon_others.ini");
	}
	
	CreateWeaponArray(szFilePath);	
}
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new usr = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (usr != 0 && IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		new szTeam = GetClientTeam(usr) == 3 ? CT : TT;
		StripUserWeapons(usr);
		GiveWeapons(usr, szTeam);
	}
	
	return bool:Plugin_Handled;
}
public CreateWeaponArray(const String:szFile[]) {
	decl String:szFileLine[512], Handle:iFile, iTeam;
	new String:szBuffer[2][32], String:szWeaponName[32];

	szWeaponArray[0] = CreateArray(32);
	szWeaponArray[1] = CreateArray(32);
	
	iFile = OpenFile(szFile, "r");
	if (iFile != INVALID_HANDLE) {
		
		while (!IsEndOfFile(iFile) && ReadFileLine(iFile, szFileLine, sizeof(szFileLine))) {
			
			TrimString(szFileLine);
			if (!(szFileLine[0] == ';') && szFileLine[0]){

				ExplodeString(szFileLine, " ", szBuffer, sizeof(szBuffer), sizeof(szBuffer[]));

				if (StrEqual(szBuffer[0], "CT", false))
					iTeam = CT;
				else if (StrEqual(szBuffer[0], "TT", false))
					iTeam = TT;

				FormatEx(szWeaponName, sizeof(szWeaponName), "weapon_%s", szBuffer[1]);			

				PushArrayString(szWeaponArray[iTeam], szWeaponName);
			}
			
		}
		CloseHandle(iFile);
		}else {
		LogMessage("*** Unable to open /* %s */ for reading.", szFile);
	}	
}
stock GiveWeapons( usr, szTeam )
{
	new String:iBuffer[32];
	if (IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		for(new i=0; i < GetArraySize(szWeaponArray[szTeam]); i++ )
		{
			GetArrayString(szWeaponArray[szTeam], i, iBuffer, sizeof(iBuffer));
			GivePlayerItem(usr, iBuffer); 
			if (CheckCommandAccess(usr, "Spawn_Weapon_Override", ADMFLAG_CUSTOM2))
			{
				GivePlayerItem(usr, "item_assaultsuit"); 
				GivePlayerItem(usr, "item_nvgs"); 
				GivePlayerItem(usr, "weapon_smokegrenade"); 
				GivePlayerItem(usr, "weapon_hegrenade"); 
				GivePlayerItem(usr, "weapon_flashbang"); 
				GivePlayerItem(usr, "weapon_flashbang"); 
				if(GetClientTeam(usr) == CS_TEAM_CT){
					GivePlayerItem(usr, "item_defuser"); 
				}
			}
		}
	}
}
stock StripUserWeapons(usr)
{
	if (IsClientInGame(usr) && IsPlayerAlive(usr))
	{
		FakeClientCommand(usr, "use weapon_knife");
		for (new i = 0; i < 4; i++)
		{
			if (i == 2) continue; // Keep knife.
			new entityIndex;
			while ((entityIndex = GetPlayerWeaponSlot(usr, i)) != -1)
			{
				RemovePlayerItem(usr, entityIndex);
				AcceptEntityInput(entityIndex, "Kill");
			}
		}
	}
}
public Action:Command_Override(client, args)
{
	return Plugin_Handled;
}