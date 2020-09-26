const botconfig = require("./botconfig.json");
const discord = require("discord.js")
const bot = new discord.Client();
const fs = require("fs");
bot.commands = new discord.Collection();
bot.aliases = new discord.Collection();

fs.readdir("./commands/", (err, files) => {

    if (err) console.log(err)

    let jsfile = files.filter(f => f.split(".").pop() === "js")
    if (jsfile.length <= 0) {
        return console.log("[LOGS] Geen commando's nog gevonden!");
    }

    jsfile.forEach((f, i) => {
        let pull = require(`./commands/${f}`);
        console.log(`[LOGS] ${f} Wordt geladen...`);
        bot.commands.set(pull.config.name, pull);
        pull.config.aliases.forEach(alias => {
            bot.aliases.set(alias, pull.config.name)
        });
    })
});

bot.on('ready', () => {
    console.log(`[LOGS] ${bot.user.username} is geactiveerd`);
});


bot.on("message", async message => {
    if (message.author.bot) return;
    if (message.channel.type === "dm") return;

    var prefix = botconfig.prefix;
    var messageArray = message.content.split(" ");
    var cmd = messageArray[0];
    var args = messageArray.slice(1);
    var options = {}

    if (!message.content.startsWith(prefix)) return;
    let commandfile = bot.commands.get(cmd.slice(prefix.length)) || bot.commands.get(bot.aliases.get(cmd.slice(prefix.length)))
    if (commandfile) commandfile.run(bot, message, args, options)
});

bot.login(botconfig.token)
