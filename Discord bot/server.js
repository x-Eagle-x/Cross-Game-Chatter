/*
	Cross-Game Chatter v1.3
	By thEsp - https://github.com/4D1G06/Cross-Game-Chatter
*/

const port = 1337;
const targetChannel = "- ID GOES HERE-";

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
				bot.channels.get(targetChannel).send(message);			
			}
		});
		
		socket.on("close", function()
		{
			server.close()
		});
		
		bot.on("message", function sendMessage(msg)
		{
			if (!msg.author.bot)
				socket.write("(&x03" + msg.author.username + "&x01 - &x03#" + msg.channel.name + "&x01): &x04" + msg);
		});
	});

	server.listen(port, "127.0.0.1");
}

initializeServer();
