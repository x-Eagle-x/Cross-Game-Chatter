/*
	Cross-Game Chatter v1.6
	By thEsp - https://github.com/x-Eagle-x/Cross-Game-Chatter
*/

const port = 1337;
const targetChannels = ["add as many", "as you want"]; // (channel INDEX)
const inputChannels = ["ALL"]; // (channel INDEX) leave it so for all, put respectable indexes for specific channels

const auth = require("./auth.json");
const net = require("net");
const discord = require("discord.js")

require("events").EventEmitter.prototype._maxListeners = 0;

const bot = new discord.Client({token: auth.token, autorun: true});
bot.login(auth.token);

var message;

function initializeServer()
{
	var server = net.createServer(function(socket)
	{
		socket.on("data", function(data)
		{
			message = data.toString("utf8");

			if (message.startsWith("Map"))
			{
    				bot.user.setStatus("online");
    				bot.user.setPresence({
        				game: {
            					name: message,
            					type: "Playing",
            					afk: false,
            					url: "https://github.com/x-Eagle-x/Cross-Game-Chatter/"
        				}
				});
			}
			else
			{
				targetChannels.forEach(channel => bot.channels.get(channel).send(message));	
			}
		});
		
		socket.on("close", function()
		{
			server.close()
		});
		
		bot.on("message", function sendMessage(msg)
		{	
			if (msg.author.bot || (inputChannels[0] != "ALL" && !inputChannels.includes(msg.channel.id)))
				return;
			
			socket.write("(&x03" + msg.author.username + "&x01 - &x03#" + msg.channel.name + "&x01): &x04" + msg.content);
		});
	});

	server.listen(port, "127.0.0.1");
}

initializeServer();
