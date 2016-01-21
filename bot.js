var Winston           = require('winston'); // For logging
var SteamUser         = require('steam-user'); // The heart of the bot.  We'll write the soul ourselves.
var TradeOfferManager = require('steam-tradeoffer-manager'); // Only required if you're using trade offers
var config            = require('./config.js');
var fs                = require('fs'); // For writing a dope-ass file for TradeOfferManager

// We have to use application IDs in our requests--this is just a helper
var appid = {
    TF2:   440,
    DOTA2: 570,
    CSGO:  730,
    Steam: 753
};
// We also have to know context IDs which are a bit tricker since they're undocumented.
// For Steam, ID 1 is gifts and 6 is trading cards/emoticons/backgrounds
// For all current Valve games the context ID is 2.
var contextid = {
    TF2:   2,
    DOTA2: 2,
    CSGO:  2,
    Steam: 6
}

// Setup logging to file and console
var logger = new (Winston.Logger)({
        transports: [
            new (Winston.transports.Console)({
                colorize: true,
                level: 'debug'
            }),
            new (Winston.transports.File)({
                level: 'info',
                timestamp: true,
                filename: 'cratedump.log',
                json: false
            })
        ]
});

// Initialize the Steam client and our trading library
var client = new SteamUser();
var offers = new TradeOfferManager({
    steam:        client,
    domain:       config.domain,
    language:     "en", // English item descriptions
    pollInterval: 10000, // (Poll every 10 seconds (10,000 ms)
    cancelTime:   300000 // Expire any outgoing trade offers that have been up for 5+ minutes (300,000 ms)
});
// Sign into Steam∏
client.logOn({
    accountName: config.username,
    password: config.password
});

client.on('loggedOn', function (details) {
    logger.info("Logged into Steam as " + client.steamID.getSteam3RenderedID());
    // If you wanted to go in-game after logging in (for crafting or whatever), you can do the following
    // client.gamesPlayed(appid.TF2);
});

client.on('error', function (e) {
    // Some error occurred during logon.  ENums found here:
    // https://github.com/SteamRE/SteamKit/blob/SteamKit_1.6.3/Resources/SteamLanguage/eresult.steamd
    logger.error(e);
    process.exit(1);
});

client.on('webSession', function (sessionID, cookies) {
    logger.debug("Got web session");
    // Set our status to "Online" (otherwise we always appear offline)
    client.friends.setPersonaState(SteamUser.Steam.EPersonaState.Online);
    offers.setCookies(cookies, function (err){
        if (err) {
            logger.error('Unable to set trade offer cookies: '+err);
            process.exit(1); // No point in staying up if we can't use trade offers
        }
        logger.debug("Trade offer cookies set.  Got API Key: "+offers.apiKey);
    });
});

// Emitted when Steam sends a notification of new items.
// Not important in our case, but kind of neat.
client.on('newItems', function (count) {
    logger.info(count + " new items in our inventory");
});

// Emitted on login and when email info changes
// Not important in our case, but kind of neat.
client.on('emailInfo', function (address, validated) {
    logger.info("Our email address is " + address + " and it's " + (validated ? "validated" : "not validated"));
});

// Emitted on login and when wallet balance changes
// Not important in our case, but kind of neat.
client.on('wallet', function (hasWallet, currency, balance) {
    if (hasWallet) {
        logger.info("We have "+ SteamUser.formatCurrency(balance, currency) +" Steam wallet credit remaining");
    } else {
        logger.info("We do not have a Steam wallet.");
    }
});
