#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include <sdkhooks>
#include <menus>

new Handle:g_hDatabaseConnection = INVALID_HANDLE;

new String:g_sDatabaseSettings[32] = "default";
new String:g_sWOTM[16] = "mp5navy"; // Zbraň měsíce (awp,galil,famas,ak47,glock,m4a1,usp,m3,deagle,p90,elite,aug,fiveseven,g3sg1,m249,mac10,mp5navy,p228,sg550,sg552,tmp,ump45,xm1014,scout,knife,flashbang,hegrenade,smokegrenade)

new bool:g_bIgnoreBots = true;
new bool:g_bIgnoreTeamkills = true;

new g_iTopPlayersLimit = 10;
new g_iPoints[MAXPLAYERS + 1];
new g_iLoaded[MAXPLAYERS + 1];


public Plugin:myinfo =
{
	name = "AGZ Weapon of The Month",
	author = "TotaLama",
	description = "Record player kills by weapon of the month",
	version = "2.0.2",
	url = "http://www.aggressivezone.com/"
};

public OnPluginStart()
{	
	LoadTranslations("agz-wotm.phrases");	
	HookEvent("player_death", Event_PlayerDeath);	
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{
	char text[192];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	if(strcmp(text,"!wotm") == 0) {		
		ShowTopPlayers(client);
	}

	return Plugin_Continue;
}

public ShowTopPlayers(client) {
	if (g_hDatabaseConnection == INVALID_HANDLE){
		LogError("[WOTM] Missing database connection!");
		return;
	}
	
	LoadClient(client);
	
	char query[1024];
	Format(query, sizeof(query), "SELECT `name`,`count` FROM `agz_wotm` WHERE `year` = YEAR(NOW()) AND `month` = MONTH(NOW()) AND `weapon` = '%s' ORDER BY `count` DESC LIMIT %d", g_sWOTM, g_iTopPlayersLimit);		
	SQL_TQuery(g_hDatabaseConnection, Callback_ShowTopPlayers, query, client);	
}

public Callback_ShowTopPlayers(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE){
		LogError("[WOTM] Query failed! %s", error);
		return;
	}	
	
	if(SQL_GetRowCount(hndl) < 1) return;
	
	new client = data;
	
	new Handle:menu = CreateMenu(Handler_TopPlayersMenu);
	SetMenuTitle(menu, "WoTM %t", "Top players", g_iTopPlayersLimit, g_iPoints[client]);
	SetMenuExitButton(menu, true);
	
	while (SQL_FetchRow(hndl)) {
		char sMenuLine[1024];
		char sName[512];
		char iPocet;
		
		SQL_FetchString(hndl, 0, sName, sizeof(sName));
		iPocet = SQL_FetchInt(hndl, 1);
		Format(sMenuLine, sizeof(sMenuLine), "%t", "Top players item", sName, iPocet);
		
		AddMenuItem(menu, "?", sMenuLine);
	} 
	
	DisplayMenu(menu, client, 20);
	CloseHandle(hndl);
}

public Handler_TopPlayersMenu(Handle:menu, MenuAction:action, param1, param2)
{	
	return;
}

public OnClientAuthorized(client, const String:auth[])
{
	g_iPoints[client] = 0;	
	g_iLoaded[client] = 0;
}

public LoadClient(client)
{
	if(IsFakeClient(client)) return;
	if(g_iLoaded[client] == 1) return;
	
	if (g_hDatabaseConnection == INVALID_HANDLE){
		LogError("[WOTM] Missing database connection!");
		return;
	}
	
	char sSteamID[20];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	char query[1024];
	Format(query, sizeof(query), "SELECT `count` FROM `agz_wotm` WHERE `steamid` = '%s' AND `year` = YEAR(NOW()) AND `month` = MONTH(NOW()) AND `weapon` = '%s'", sSteamID, g_sWOTM);		
	SQL_TQuery(g_hDatabaseConnection, Callback_LoadClient, query, client);	
				
}

public Callback_LoadClient(Handle:owner, Handle:hndl, const String:error[], any:data)
{	
	if (hndl == INVALID_HANDLE){
		LogError("[WOTM] Query failed! %s", error);
		return;
	}	
		
	if(!SQL_FetchRow(hndl)) return;		
	new client = data;	
	g_iPoints[client] = SQL_FetchInt(hndl, 0);
	g_iLoaded[client] = 1;
	
	CloseHandle(hndl);	
}

public OnMapStart()
{
	ConnectDB();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{			
	char sWeapon[16];    	  
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(attacker == 0 || IsFakeClient(attacker) || (g_bIgnoreBots && IsFakeClient(victim)))
	{
		return;
	}
	
	if(g_bIgnoreTeamkills && GetClientTeam(attacker) == GetClientTeam(victim))
	{
		return;
	}
	
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));					
	
	if( (strcmp(sWeapon, g_sWOTM) == 0) || (strcmp(sWeapon, "knife") == 0) )
	{
		GivePoint(attacker);
	}	
}

public ConnectDB()
{
	if (g_hDatabaseConnection != INVALID_HANDLE) {	  
		CloseHandle(g_hDatabaseConnection);		
	}
	
	SQL_TConnect(Callback_ConnectDB, g_sDatabaseSettings); 
}

public Callback_ConnectDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{	
	if (hndl == INVALID_HANDLE) {		
		LogError("[WOTM] Database connection failed: %s", error);
		return;
	}
	
	g_hDatabaseConnection = hndl;		  
	char query[1024];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `agz_wotm` (   `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,   `steamid` varchar(20) CHARACTER SET 'ascii' NOT NULL,   `name` varchar(513) NOT NULL,   `year` SMALLINT NOT NULL,   `month` TINYINT NOT NULL, `weapon` varchar(16) CHARACTER SET 'ascii' NOT NULL, `count` mediumint(8) unsigned NOT NULL,   PRIMARY KEY (`id`),   UNIQUE KEY `unique` (`steamid`,`year`,`month`,`weapon`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Weapon of the month'");
	SQL_TQuery(g_hDatabaseConnection, Callback_CreateDB, query);		
} 

public Callback_CreateDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE){
		LogError("[WOTM] Query failed! %s", error);		
		CloseHandle(owner);
		g_hDatabaseConnection = INVALID_HANDLE;
	}		
}

public GivePoint(client)
{	
	if (g_hDatabaseConnection == INVALID_HANDLE){
		LogError("[WOTM] Missing database connection!");
		return;
	}
	
	LoadClient(client);
	
	char sSteamID[20];
	char sName[256];	
	char sNameEscaped[2*sizeof(sName)+1];
	
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));	
	GetClientName(client, sName, sizeof(sName));	
	
	SQL_EscapeString(g_hDatabaseConnection, sName, sNameEscaped, sizeof(sNameEscaped));
	
	char query[1024];
	Format(query, sizeof(query), "INSERT INTO `agz_wotm` (`steamid`,`name`,`year`,`month`,`weapon`,`count`) VALUES('%s','%s',YEAR(NOW()), MONTH(NOW()),'%s', 1) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`),`count` = `count` + 1", sSteamID, sNameEscaped, g_sWOTM); 
	SQL_TQuery(g_hDatabaseConnection, Callback_GivePoint, query, client);			
}

public Callback_GivePoint(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE){
		LogError("[WOTM] Query failed! %s", error);					
		return;
	}				     
	
	g_iPoints[data]++;
	
	char sName[256];
	GetClientName(data, sName, sizeof(sName));
		
	CPrintToChatAll("{chartreuse}[{dodgerblue}WoTM{chartreuse}]{default} %t", "Player got point", sName, g_sWOTM, g_iPoints[data]);		   
	CloseHandle(hndl);
}

