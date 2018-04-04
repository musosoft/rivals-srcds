/*
 *		QuickDefuse - by pRED*
 *
 *		CT's get a menu to select a wire to cut when they defuse the bomb
 *			- Choose the right wire - Instant Defuse
 *			- Choose the wrong wire - Instant Explosion
 *
 *		T's also get the option to select the correct wire, otherwise it's random
 *
 *		Ignoring the menu's or selecting exit will let the game continue normally
 *
 */

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION			"0.5-private"

new wire
new ctcanqd
new Handle:cvar_tchoice
new String:wirecolours[5][20]
new String:messagestart[128]
new String:wiremorecolors[5][128]
 
public Plugin:myinfo = 
{
	name = "QuickDefuse",
	author = "pRED*, G-Phoenix, muso.sk",
	description = "Let's CT's choose a wire for quick defusion",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=59736"
};

public OnPluginStart()
{
	CreateConVar("sm_quickdefuse_version", PLUGIN_VERSION, "Quick Defuse Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	HookEvent("bomb_begindefuse", Event_Defuse, EventHookMode_Post)
	HookEvent("bomb_beginplant", Event_Plant, EventHookMode_Post)
	HookEvent("bomb_planted", Event_Planted, EventHookMode_PostNoCopy)
	HookEvent("bomb_abortdefuse", Event_Abort, EventHookMode_Post)
	HookEvent("bomb_abortplant", Event_Abort, EventHookMode_Post)
	
	cvar_tchoice = CreateConVar("qd_tchoice", "1", "Sets whether Terrorists can select a wire colour (QuickDefuse)")
	LoadTranslations("QuickDefuse.phrases")
}

public Event_Plant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	//translations
	
	new String:stringt[5][100]
	Format(stringt[0], sizeof(stringt[]), "%t", "Choose")
	Format(stringt[1], sizeof(stringt[]), "%t", "t2")
	Format(stringt[2], sizeof(stringt[]), "%t", "t3")
	Format(stringt[3], sizeof(stringt[]), "%t", "Exit")
	Format(wirecolours[0], sizeof(wirecolours[]), "%t", "Blue")
	Format(wirecolours[1], sizeof(wirecolours[]), "%t", "Yellow")
	Format(wirecolours[2], sizeof(wirecolours[]), "%t", "Red")
	Format(wirecolours[3], sizeof(wirecolours[]), "%t", "Green")
	Format(wirecolours[4], sizeof(wirecolours[]), "%t", "Black")
	
	wire = 0
	ctcanqd = 0
	//let the planter choose a wire
	
	if (GetConVarInt(cvar_tchoice))
	{	
		new Handle:panel = CreatePanel()
		SetPanelTitle(panel, stringt[0] )
		DrawPanelText(panel, " ")
		DrawPanelText(panel, stringt[1])
		DrawPanelText(panel, stringt[2])
		DrawPanelText(panel, " ")
		DrawPanelItem(panel, wirecolours[0])
		DrawPanelItem(panel, wirecolours[1])
		DrawPanelItem(panel, wirecolours[2])
		DrawPanelItem(panel, wirecolours[3])
		DrawPanelItem(panel, wirecolours[4])
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, stringt[3])
		SendPanelToClient(panel, client, PanelPlant, 5)
		CloseHandle(panel)
	}
}

public Event_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (wire == 0)
		wire = GetRandomInt(1,5)
	CreateTimer((GetConVarFloat(FindConVar("mp_c4timer")) - 10.0), CanQuickDefuse)
}

public Action:CanQuickDefuse(Handle:timer, any:data)
{
	ctcanqd = 1
	//CPrintToChatAll("{chartreuse}[{dodgerblue}QuickDefuse{chartreuse}]{default} Dratky povolene!")
}

public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	new bool:kit = GetEventBool(event, "haskit")
	
	//translations

	new String:stringct[12][100]
	Format(stringct[0], sizeof(stringct[]), "%t", "Choose")
	Format(stringct[1], sizeof(stringct[]), "%t", "ct2")
	Format(stringct[2], sizeof(stringct[]), "%t", "ct3")
	Format(stringct[3], sizeof(stringct[]), "%t", "ct4")
	Format(stringct[4], sizeof(stringct[]), "%t", "ct5")
	Format(stringct[5], sizeof(stringct[]), "%t", "ct6")
	Format(stringct[6], sizeof(stringct[]), "%t", "Blue")
	Format(stringct[7], sizeof(stringct[]), "%t", "Yellow")
	Format(stringct[8], sizeof(stringct[]), "%t", "Red")
	Format(stringct[9], sizeof(stringct[]), "%t", "Green")
	Format(stringct[10], sizeof(stringct[]), "%t", "Black")
	Format(stringct[11], sizeof(stringct[]), "%t", "Exit")
	
	//show a menu to the client offering a choice to pull/cut the wire
	if (ctcanqd == 1)	
	{
		new Handle:panel = CreatePanel()
		SetPanelTitle(panel, stringct[0])
		DrawPanelText(panel, stringct[1])
		DrawPanelText(panel, " ")
		DrawPanelText(panel, stringct[2])
		DrawPanelText(panel, stringct[3])
		
		if (!kit)
		{
			DrawPanelText(panel, stringct[4])
			DrawPanelText(panel, stringct[5])
		}

		DrawPanelText(panel, " ")
		DrawPanelItem(panel, stringct[6])
		DrawPanelItem(panel, stringct[7])
		DrawPanelItem(panel, stringct[8])
		DrawPanelItem(panel, stringct[9])
		DrawPanelItem(panel, stringct[10])
		DrawPanelText(panel, " ");
		DrawPanelItem(panel, stringct[11])
		
		if (kit)
			SendPanelToClient(panel, client, PanelDefuseKit, 5)
		else
			SendPanelToClient(panel, client, PanelNoKit, 5)
			
		CloseHandle(panel)
	}
	
}

public PanelPlant(Handle:menu, MenuAction:action, param1, param2)
{
	Format(messagestart, sizeof(messagestart), "%t", "Message Start")
	Format(wiremorecolors[0], sizeof(wiremorecolors[]), "%t", "Blue Color")
	Format(wiremorecolors[1], sizeof(wiremorecolors[]), "%t", "Yellow Color")
	Format(wiremorecolors[2], sizeof(wiremorecolors[]), "%t", "Red Color")
	Format(wiremorecolors[3], sizeof(wiremorecolors[]), "%t", "Green Color")
	Format(wiremorecolors[4], sizeof(wiremorecolors[]), "%t", "Black Color")
	
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		wire = param2
		CPrintToChat(param1, "%t", "Wire Choice", messagestart, wiremorecolors[param2-1])
	}
}

public PanelDefuseKit(Handle:menu, MenuAction:action, param1, param2)
{
	Format(messagestart, sizeof(messagestart), "%t", "Message Start")
	Format(wiremorecolors[0], sizeof(wiremorecolors[]), "%t", "Blue Color")
	Format(wiremorecolors[1], sizeof(wiremorecolors[]), "%t", "Yellow Color")
	Format(wiremorecolors[2], sizeof(wiremorecolors[]), "%t", "Red Color")
	Format(wiremorecolors[3], sizeof(wiremorecolors[]), "%t", "Green Color")
	Format(wiremorecolors[4], sizeof(wiremorecolors[]), "%t", "Black Color")
	
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent)
		{
			new String:name[32]
			GetClientName(param1, name, sizeof(name))
		
			if (param2 == wire)
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				CPrintToChatAllEx(param1, "%t", "Correct Cut", messagestart, name, wiremorecolors[param2-1])
			}
			else
			{	
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				CPrintToChatAllEx(param1, "%t", "Incorrect Cut", messagestart, name, wiremorecolors[param2-1], wiremorecolors[wire-1])
			}
		}
	}
}

public PanelNoKit(Handle:menu, MenuAction:action, param1, param2)
{
	Format(messagestart, sizeof(messagestart), "%t", "Message Start")
	Format(wiremorecolors[0], sizeof(wiremorecolors[]), "%t", "Blue Color")
	Format(wiremorecolors[1], sizeof(wiremorecolors[]), "%t", "Yellow Color")
	Format(wiremorecolors[2], sizeof(wiremorecolors[]), "%t", "Red Color")
	Format(wiremorecolors[3], sizeof(wiremorecolors[]), "%t", "Green Color")
	Format(wiremorecolors[4], sizeof(wiremorecolors[]), "%t", "Black Color")
	
	if (action == MenuAction_Select && param2 > 0 && param2 < 6) //User selected a valid wire colour
	{
		new bombent = FindEntityByClassname(-1,"planted_c4")
	
		if (bombent)
		{
			new String:name[32]
			GetClientName(param1, name, sizeof(name))
			
			if (param2 == wire && GetRandomInt(0,1))
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0)
				CPrintToChatAllEx(param1, "%t", "Correct Pull", messagestart, name, wiremorecolors[param2-1])
			}
			else
			{
				SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0)
				if (param2 != wire)
					CPrintToChatAllEx(param1, "%t", "Incorrect Pull", messagestart, name, wiremorecolors[param2-1], wiremorecolors[wire-1])
				else
					CPrintToChatAllEx(param1, "%t", "Correct Pull without Kit", messagestart, name, wiremorecolors[param2-1])
			}
		}
	}
}

public Event_Abort(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	CancelClientMenu(client)
}