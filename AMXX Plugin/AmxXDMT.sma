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
		g_iInputFileModTime = g_iInputTemp;
	}
}

public cmdMessage(id)
{
	new szMessage[128], szTime[16], szTeam[16];
	read_args(szMessage, charsmax(szMessage));
	get_time("%S:%M:%H", szTime, charsmax(szTime));
	get_user_team(id, szTeam, charsmax(szTeam));
	remove_quotes(szMessage);
	write_file(g_szOutputFileLoc, fmt("[%s] %s %n: %s", szTime, szTeam, id, szMessage), 0);
}

stock get_datadir(name[], len)
{
	return get_localinfo("amxx_datadir", name, len);
}
