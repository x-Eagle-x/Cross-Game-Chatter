const port = 1337;
const targetChannel = "---------------";

const auth = require("./auth.json");
const net = require("net");
const discord = require("discord.js")

const bot = new discord.Client({token: auth.token, autorun: true});
bot.login(auth.token);

var message;

function initializeServer()
{
	var server = net.createServer(function(socket) {

		socket.on("data", function(data) {
			message = data.toString("utf8");
			bot.channels.get(targetChannel).send(message);
		});

		bot.on("message", function sendMessage(msg) {
			if (!msg.author.bot)
				socket.write("(&x03" + msg.author.username + "&x01 - &x03#" + msg.channel.name + "&x01): &x04" + msg);
		});
	});

	server.listen(port, "127.0.0.1");
}

initializeServer();
