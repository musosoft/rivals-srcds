#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <morecolors>

public Plugin:myinfo = 
{
	name	= "TK Punishment",
	author	= "wS / Schmidt, muso.sk",
	version	= "1.1-private",
	url		= "http://world-source.ru/"
};

new Handle:g_Menu;
new g_Id[MAXPLAYERS + 1];

public OnPluginStart()
{
	g_Menu = CreateMenu(g_Menu_CallBack);
	SetMenuTitle(g_Menu, "Vyber trest\n \n");
	SetMenuExitButton(g_Menu, false);
	AddMenuItem(g_Menu, "1", "Odpustit");
	AddMenuItem(g_Menu, "2", "Zabit");
	AddMenuItem(g_Menu, "3", "Vzit zbrane");
	AddMenuItem(g_Menu, "4", "Zapalit");
	AddMenuItem(g_Menu, "5", "Oslepit");
	AddMenuItem(g_Menu, "6", "Zmrazit");
	AddMenuItem(g_Menu, "7", "Vzit prachy");
	AddMenuItem(g_Menu, "8", "Uzemnit");
	AddMenuItem(g_Menu, "9", "Spomalit");

	HookEvent("player_death", player_death);
}

public OnClientPutInServer(client)
{
	g_Id[client] = 0;
}

public player_death(Handle:event, const String:name[], bool:silent)
{
	new attacker_userid = GetEventInt(event, "attacker");
	if (attacker_userid < 1)
		return;

	new attacker_client = GetClientOfUserId(attacker_userid);
	if (attacker_client < 1)
		return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (attacker_client != victim && !IsFakeClient(victim) && GetClientTeam(attacker_client) == GetClientTeam(victim))
	{
		g_Id[victim] = attacker_userid;
		DisplayMenu(g_Menu, victim, 0);
		CPrintToChat(victim, "{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N ta zabil..", attacker_client);
	}
}

public g_Menu_CallBack(Handle:menu, MenuAction:action, client, item)
{
	if (action != MenuAction_Select)
		return;

	new target = GetClientOfUserId(g_Id[client]);
	if (target < 1)
	{
		CPrintToChat(client, "{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} hrac nenajdeny");
		return;
	}

	if (item > 0 && !IsPlayerAlive(target))
	{
		CPrintToChat(client, "{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} pockaj kym sa %N nenarodi", target);
		DisplayMenu(g_Menu, client, 0);
		return;
	}

	decl String:text[3];
	if (!GetMenuItem(menu, item, text, 3))
		return;

	new x = StringToInt(text);
	if (x == 1)
	{
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N ma odpusteny TeamKill", target);
	}
	else if (x == 2)
	{
		ForcePlayerSuicide(target);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol zabity", target);
	}
	else if (x == 3)
	{
		decl ent;
		for (new slot = 0; slot < 4; slot++)
		{
			while ((ent = GetPlayerWeaponSlot(target, slot)) > 0) RemovePlayerItem(target, ent);
		}
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N prisiel o vsetky zbrane", target);
	}
	else if (x == 4)
	{
		IgniteEntity(target, 60.0);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol zapaleny", target);
	}
	else if (x == 5)
	{
		new Handle:h = StartMessageOne("Fade", target);
		if (h == INVALID_HANDLE)
		{
			PrintToChat(client, "Chyba zvol iny trest");
			DisplayMenu(g_Menu, client, 0);
			return;
		}
		BfWriteShort(h, 100000000);
		BfWriteShort(h, 0);
		BfWriteShort(h, 0x0008);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 255);
		EndMessage();
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol oslepeny", target);
	}
	else if (x == 6)
	{
		decl Float:wS_Pos[3];
		GetClientAbsOrigin(target, wS_Pos);
		wS_Pos[2] += 20.0;
		TeleportEntity(target, wS_Pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(target, MOVETYPE_NONE);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol zamrazeny", target);
	}
	else if (x == 7)
	{
		new cash = GetEntProp(target, Prop_Send, "m_iAccount") / 2;
		if (cash < 1)
		{
			PrintToChat(client, "Nema prachy, zvol iny trest.");
			DisplayMenu(g_Menu, client, 0);
			return;
		}
		SetEntProp(target, Prop_Send, "m_iAccount", cash);
		SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + cash);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} \"%N\" zobral $%d od \"%N\"", client, cash, target);
	}
	else if (x == 8)
	{
		if (!(GetEntityFlags(target) & FL_ONGROUND))
		{
			PrintToChat(client, "%N bol uzemneny", target);
			DisplayMenu(g_Menu, client, 0);
			return;
		}
		decl Float:wS_Pos[3];
		GetClientAbsOrigin(target, wS_Pos);
		wS_Pos[2] -= 25.0;
		TeleportEntity(target, wS_Pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(target, MOVETYPE_NONE);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol uzemneny", target);
	}
	else if (x == 9)
	{
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 0.1);
		CPrintToChatAll("{chartreuse}[{dodgerblue}TeamKill{chartreuse}]{default} %N bol spomaleny", target);
	}

	g_Id[client] = 0;
}