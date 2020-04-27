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

#define VERSION "1.1"
#define PORT 1337

#define TSK_CHAT_INDEX 3210
#define MAX_MSG_LENGTH 128
#define MAX_DMSG_LENGTH 128

new g_iServer, bool:g_bRunning;

public plugin_init()
{
	register_plugin("CrossGameChat", VERSION, "thEsp");

	if (!Initialize())
		return set_fail_state("[Critical] Cross-Game Chatter: Failed to initialze the (socket) server.");

	register_clcmd("say", "cmd_Chat");
	register_clcmd("say_team", "cmd_Chat");
	
	g_bRunning = true;
	return 0x0;
}

bool:Initialize()
{
	new Error; g_iServer = socket_open("127.0.0.1", PORT, _, Error);
	set_task(0.1, "tsk_Chat", TSK_CHAT_INDEX, .flags = "b");
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
			goto check_if_running;
			
		CC_SendMessage(0, szData);

check_if_running:
		if (!Running())
			Close();
	}
}

public plugin_end()
{
	if (!g_bRunning)
		socket_close(g_iServer);

	/*
		If the relay (server) is closed, this socket will also be closed. 
		This way you don't have to start the nodejs script each time server restarts (or map changes). 
	*/	
}
