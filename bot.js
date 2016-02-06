var Winston           = require('winston'); // For logging
var SteamUser         = require('steam-user'); // The heart of the bot.  We'll write the soul ourselves.
var TradeOfferManager = require('steam-tradeoffer-manager'); // Only required if you're using trade offers
var SteamTotp         = require('steam-totp');
var SteamCommunity    = require('steamcommunity');
var SocketIO          = require('socket.io');
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
};

var itemid = {
    StockKey:      1,
    GMKey:         2,
    GMCosmeticKey: 3,
    TBKey:         4,
    TBCosmeticKey: 5
};

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
                filename: 'logs/debug.log',
                json: false
            })
        ]
});

// Initialize the Steam client and our trading library
var client = new SteamUser();
var community = new SteamCommunity();
var manager = new TradeOfferManager({
    steam:        client,
    domain:       config.domain,
    language:     "en", // English item descriptions
    pollInterval: 10000, // (Poll every 10 seconds (10,000 ms)
    cancelTime:   300000 // Expire any outgoing trade offers that have been up for 5+ minutes (300,000 ms)
});

logger.info("Initialized!")

// Sign into Steam
client.logOn({
    accountName: config.username,
    password: config.password
});

client.on('loggedOn', function (details) {
    logger.info("Logged into Steam as " + client.steamID.getSteam3RenderedID() + ". Good morning, sunshine.");
    client.setPersona(SteamUser.Steam.EPersonaState.Busy);
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
    client.setPersona(SteamUser.Steam.EPersonaState.Online);
    manager.setCookies(cookies, function (err){
        if (err) {
            logger.error('Unable to set trade offer cookies: '+err);
            //process.exit(1); // No point in staying up if we can't use trade offers
        }
        logger.debug("Trade offer cookies set.  Got API Key: "+ manager.apiKey);
    });
});

client.on('tradeOffers', function(count){
  if(count < 5){logger.info("Found " + count + "new offers.")}
  if(count > 5){logger.warn("Found " + count + "new offers. Get on it!")}
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

client.on('accountLimitations', function (limited, communityBanned, locked, canInviteFriends) {
    if (limited) {
        // More info: https://support.steampowered.com/kb_article.php?ref=3330-IAGK-7663
        logger.warn("Our account is limited. We cannot send friend invites, use the market, open group chat, or access the web API.");
    }
    if (communityBanned){
        // More info: https://support.steampowered.com/kb_article.php?ref=4312-UOJL-0835
        // http://forums.steampowered.com/forums/showpost.php?p=17054612&postcount=3
        logger.warn("Our account is banned from Steam Community");
        // I don't know if this alone means you can't trade or not.
    }
    if (locked){
        // Either self-locked or locked by a Valve employee: http://forums.steampowered.com/forums/showpost.php?p=17054612&postcount=3
        logger.error("Our account is locked. We cannot trade/gift/purchase items, play on VAC servers, or access Steam Community.  Shutting down.");
        process.exit(1);
    }
    if (!canInviteFriends){
        // This could be important if you need to add users.  In our case, they add us or just use a direct tradeoffer link.
        logger.warn("Our account is unable to send friend requests.");
    }
    if (canInviteFriends && !locked && !communityBanned && !limited){
      logger.info("Our account is a-OK. No bans or limitations.")
    }
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

client.on('friendRelationship', function (sid, relationship) {
  if (relationship == SteamUser.Steam.EFriendRelationship.RequestRecipient) {
    logger.info('[' + sid +'] Accepted friend request.');
    client.addFriend(sid);
    client.chatMessage(sid, config.greetMsg);
  }
});
client.on('friendMessage', function (senderID, message) {
  var req;
  if (req = message.match(/^!trade (\d+) (\d+)/i)){
    var theirkey = req[1];
    var ourkey = req[2];
    client.chatMessage(senderID, "Sending an offer...")
    client.trade(senderID);
    logger.info('Sent ' + senderID + ' a trade offer.')
  } else{
    logger.info('Sent ' + senderID + ' the greeting message.');
    client.chatMessage(senderID, config.greetMsg);
  }
  //Possible anti-spam system, doesn't work
  //senderID.sentCount++;
  //if (senderID.sentCount < 3) {
    //logger.info('Sent ' + senderID + ' the greeting message.')
    //client.chatMessage(senderID, "Hey! I'm a key trading bot. I will convert your keys at the cost of one scrap.")
  //}
  //else if (senderID.sentCount > 3) {
    //client.chatMessage(senderID, "M'aiq is done talking.")
  //}
});
manager.on('newOffer', function(offer) {
  logger.info("New offer #" + offer.id + " from " + offer.partner.getSteam3RenderedID);
  offer.accept(function(err){
    if(err) {
      logger.error("Error with trade offer. Bad stuff has happened.");
    } else{
      logger.info("Offer accepted.")
    }
  })
});
