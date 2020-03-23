/*
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
new szData[MAX_DMSG_LENGTH];

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
	new szMessage[MAX_MSG_LENGTH], szName[32];

	read_args(szMessage, charsmax(szMessage));
	get_user_name(id, szName, charsmax(szName));
	remove_quotes(szMessage);
	trim(szMessage);

	if (equal(szMessage, ""))
		return;

	format(szMessage, charsmax(szMessage), "(%s): %s", szName, szMessage);
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