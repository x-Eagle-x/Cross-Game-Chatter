#include <amxmodx>
#include <cromchat>

new g_szInputFileName[] = "discord_messages_i.txt";

new g_iInputTemp;
new g_iInputFileModTime;
new g_szInputFileLoc[64];
new g_szInputMessage[256];

new g_szOutputFileName[] = "discord_messages_o.txt";
new g_szOutputFileLoc[64];

public plugin_init()
{
	register_plugin("AmxXDMT", "1.0b", "thEsp");

	get_datadir(g_szInputFileLoc, charsmax(g_szInputFileLoc));
	format(g_szOutputFileLoc, charsmax(g_szOutputFileLoc), "%s\%s", g_szInputFileLoc, g_szOutputFileName); // Use this first
	format(g_szInputFileLoc, charsmax(g_szInputFileLoc), "%s\%s", g_szInputFileLoc, g_szInputFileName);

	register_clcmd("say", "cmdMessage");

	set_task(0.1, "tskReadLine", .flags = "b");
}

public tskReadLine()
{
	if(!file_exists(g_szInputFileLoc))
		return;

	g_iInputTemp = GetFileTime(g_szInputFileLoc, FileTime_LastChange);

	if (g_iInputFileModTime != g_iInputTemp)
	{
		read_file(g_szInputFileLoc, 0, g_szInputMessage, charsmax(g_szInputMessage));
		CC_SendMessage(0, g_szInputMessage);
		g_iInputFileModTime = g_iInputTemp
	}
}

public cmdMessage(id)
{
	new szMessage[128], szTime[16], szTeam[16];
	read_args(szMessage, charsmax(szMessage));
	
	remove_quotes(szMessage);/*
	AmxXDMT (Amx Mod X Discord Message Transmitter)

	More info at: https://forums.alliedmods.net/showthread.php?t=319940
	Source available at: https://github.com/4D1G06/AmxXDMT

	https://www.youtube.com/watch?v=7AqTB30d-Mc
*/

#include <amxmodx>
#include <cromchat>
#include <sockets>

#pragma semicolon 1

#define VERSION "1.0s" // Stable release
#define PORT 1337

#define MAX_MSG_LENGTH 64
#define MAX_DMSG_LENGTH 128

new g_iServer;
new szData[MAX_MSG_LENGTH];

public plugin_init()
{
	register_plugin("AmxXDMT", VERSION, "thEsp");

	if (Initialize())
		return set_fail_state("[Critical] AmxXDMT: Failed to initialze the (socket) server.");

	register_clcmd("say", "cmd_Chat");
//  register_clcmd("say_team", "cmd_Chat");

	return 0x0;
}

bool:Initialize()
{
	new Error;
	g_iServer = socket_open("127.0.0.1", PORT, _, Error);

	set_task(0.1, "tsk_Chat", .flags = "b");

	return bool:Error;
}

public cmd_Chat(id)
{
	new szMessage[MAX_MSG_LENGTH];

	read_args(szMessage, charsmax(szMessage));
	trim(szMessage);
	remove_quotes(szMessage);

	if (equal(szMessage, ""))
		return;

	format(szMessage, charsmax(szMessage), "(%n): %s", id, szMessage);
	socket_send(g_iServer, szMessage, charsmax(szMessage));
}

public tsk_Chat()
{
	if (socket_is_readable(g_iServer, 0))
	{
		socket_recv(g_iServer, szData, charsmax(szData));

		CC_SendMessage(0, szData);
	}
}

public plugin_end()
{
//	socket_close(g_iServer);

//  the server (nodejs) will throw an error if I close the socket here.
//  if someone is able to fix this problem, please pull a request (along with an issue) on github
}
	trim(szMessage);
	
	if(equal(szMessage, ""))
		return;
	
	get_time("%H:%M:%S", szTime, charsmax(szTime));
	get_user_team(id, szTeam, charsmax(szTeam));

	write_file(g_szOutputFileLoc, fmt("[%s] %s %n: %s", szTime, szTeam, id, szMessage), 0);
}

stock get_datadir(name[], len)
{
	return get_localinfo("amxx_datadir", name, len);
}
