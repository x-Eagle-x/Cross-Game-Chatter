var auth = require("./auth.json");
const Discord = require("discord.js");
const FileStream = require("fs");
const Util = require("util");

const bot = new Discord.Client({token: auth.token, autorun: true});
bot.login(auth.token);

const targetChannel = "YOUR CHANNEL ID";
var lastMessage;

FileStream.watch("discord_messages_o.txt", function (event, filename) {
	if(filename && event == "change")
		FileStream.readFile("discord_messages_o.txt", "utf8", function (err, data) {
			if(err)
				throw err;
			
			if(lastMessage != data)
			{
				bot.channels.get(targetChannel).send(data);
				lastMessage = data;
			}
		});
});

bot.on("message", function sendMessages(msg) {
	if(msg.author.bot)
		return 0;
	
	FileStream.writeFile("discord_messages_i.txt", Util.format("[&x05%s&x01] &x04#%s&x01 &x05%s&x01: %s", new Date().toLocaleTimeString(), msg.channel.name, msg.author.username, msg), (err) => {
    if (err) throw err;});
})
