/*
	AMXX CGC (Cross-Game Chatter)

	More info at: https://forums.alliedmods.net/showthread.php?t=319940
	Source available at: https://github.com/x-Eagle-x/Cross-Game-Chatter

	https://www.youtube.com/watch?v=7AqTB30d-Mc
*/

#include <amxmodx>
#include <sockets>
#include <cromchat>

#pragma semicolon 1

#define VERSION "1.6"
#define PORT 1337

#define TSK_CHAT_INDEX 3210
#define TSK_INFO_INDEX 3900

#define MAX_MSG_LENGTH 128
#define MAX_DMSG_LENGTH 128
#define MAX_MOTD_LENGTH 1536
#define MAX_DISCORD_MESSAGES 128 // <- Do whatever you want with this number.

new g_iServer, bool:g_bRunning;
new g_pMsgCvar, g_pMentionFixCvar, g_pMaxMentionWarnings, Array:g_aMessages;

new bool:g_bDark[33] = {true, ...}, g_WarningsIssued[33];

public plugin_init()
{
	register_plugin("Cross-Game Chatter", VERSION, "thEsp");

	if (!Initialize())
		return set_fail_state("[Critical] Cross-Game Chatter: Failed to initialze the (socket) server.");

	register_dictionary("crossgamechatter.ini");

	g_aMessages = ArrayCreate(MAX_DMSG_LENGTH, MAX_DISCORD_MESSAGES);
	g_pMsgCvar = register_cvar("amx_cgc_store_messages", "1");
	g_pMentionFixCvar = register_cvar("amx_cgc_mention_fix", "1");
	g_pMaxMentionWarnings = register_cvar("amx_cgc_mention_warns", "3");

	register_clcmd("say", "cmd_Chat");
	register_clcmd("say_team", "cmd_Chat");
	
	return (g_bRunning = true);
}

bool:Initialize()
{
	new Error; g_iServer = socket_open("127.0.0.1", PORT, _, Error);

	set_task(0.1, "tsk_Chat", TSK_CHAT_INDEX, .flags = "b");
	set_task(60.0, "tsk_Info", TSK_INFO_INDEX, .flags = "b");

	return !bool:Error;
}

bool:Running()
{
	return (socket_send(g_iServer, {0}, 1) != -1);
}

Close()
{		
	socket_close(g_iServer);
	set_fail_state("[Info] Cross-Game Chatter: Relay server has shut down.");
	remove_task(TSK_CHAT_INDEX);
	g_bRunning = false;
}

ShowDiscordChat(index)
{
	new szMessage[MAX_DMSG_LENGTH];
	static szMOTD[MAX_MOTD_LENGTH];
	szMOTD[0] = 0;

	if (g_bDark[index])
		add(szMOTD, charsmax(szMOTD), "<style type=^"text/css^">body { font-family: Verdana; background-color: rgb(44, 47, 51); color: white }</style>");
	else
		add(szMOTD, charsmax(szMOTD), "<style type=^"text/css^">body { font-family: Verdana; background-color: white; color: black }</style>");

	for (new iMsg = 0, iSize = ArraySize(g_aMessages); iMsg < iSize; iMsg++)
	{
		ArrayGetString(g_aMessages, iMsg, szMessage, charsmax(szMessage));

		add(szMOTD, charsmax(szMOTD), szMessage);
		add(szMOTD, charsmax(szMOTD), "<br/>");
	}

	show_motd(index, szMOTD, "Discord chat");
}

public cmd_Chat(id)
{
	new szMessage[MAX_MSG_LENGTH], szName[32];

	read_args(szMessage, charsmax(szMessage));
	get_user_name(id, szName, charsmax(szName));
	remove_quotes(szMessage);
	trim(szMessage);

	if (!szMessage[0])
		return PLUGIN_CONTINUE;

	if (equali(szMessage, "/discord"))
	{
		ShowDiscordChat(id);
		return PLUGIN_CONTINUE;
	}

	if (equali(szMessage, "/discordtheme"))
	{
		g_bDark[id] = !g_bDark[id];
		CC_SendMessage(id, "%L", LANG_PLAYER, g_bDark[id] ? "THEME_DARK" : "THEME_LIGHT");	
		return PLUGIN_CONTINUE;
	}

	if (get_pcvar_num(g_pMentionFixCvar) && containi(szMessage, "@everyone") != -1)
	{
		if (g_WarningsIssued[id] >= get_pcvar_num(g_pMaxMentionWarnings))
			KickPlayer(id);
		else
			CC_SendMessage(id, "%L", LANG_PLAYER, "MENTION_WARN", ++g_WarningsIssued[id]);
	
		return PLUGIN_HANDLED;
	}
	
	if (containi(szMessage, "discord.gg/") != -1)
		return PLUGIN_CONTINUE;
	
	format(szMessage, charsmax(szMessage), "(%s): %s", szName, szMessage);
	socket_send(g_iServer, szMessage, charsmax(szMessage));

	return PLUGIN_CONTINUE;
}

public tsk_Chat()
{
	if (!Running())
	{
		Close();
		return;
	}

	// Note: this is executed ONCE during compilation. A macro function isn't really needed.
	#if AMXX_VERSION_NUM < 190
	if (socket_change(g_iServer, 0))
	#else
	if (socket_is_readable(g_iServer, 0))
	#endif
	{
		static szData[MAX_DMSG_LENGTH];
		socket_recv(g_iServer, szData, charsmax(szData));	

		if (!szData[0] || szData[0] == '^n' && !szData[1])
			return;
			
		CC_SendMessage(0, szData);
		if (get_pcvar_num(g_pMsgCvar))
		{
			CC_RemoveColors(szData, charsmax(szData));
			if (ArraySize(g_aMessages) >= MAX_DISCORD_MESSAGES)
				ArrayClear(g_aMessages);

			ArrayPushString(g_aMessages, szData);
		}
	}
}

public tsk_Info()
{
	SendInfo();
}

SendInfo()
{
	static szMap[32], szMessage[64], szTemp[32], iPlayers, iMaxPlayers;

	get_mapname(szMap, charsmax(szMap));
	get_players(szTemp, iPlayers);
	iMaxPlayers = get_maxplayers();

	format(szMessage, charsmax(szMessage), "Map: %s [%i/%i]", szMap, iPlayers, iMaxPlayers);

	socket_send(g_iServer, szMessage, charsmax(szMessage));
}

KickPlayer(index)
{
	server_cmd("amx_kick #%i ^"%L^"", get_user_userid(index), LANG_PLAYER, "MENTION_PUNISH");
}

#if AMXX_VERSION_NUM < 190
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	g_WarningsIssued[id] = 0;
}

public plugin_end()
{
	ArrayDestroy(g_aMessages);
	if (!g_bRunning)
		socket_close(g_iServer);	
}
