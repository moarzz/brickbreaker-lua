local JackOfAllTrades = ItemBase.new();
JackOfAllTrades.__index = JackOfAllTrades;
JackOfAllTrades.name = "Jack Of All Trades";
JackOfAllTrades.description = "Increases all stats of your weapons by 2 and decreases cooldown by 2";
JackOfAllTrades.rarity = "rare";
JackOfAllTrades.imageReference = "assets/sprites/UI/ItemIcons/Jack-Of-All-Trades.png";

JackOfAllTrades.descriptionOverwrite = true; -- does smthn ig

function JackOfAllTrades.new()
    local instance = setmetatable({}, JackOfAllTrades):init();

    instance.stats.damage    = 2;
    instance.stats.speed    = 2;
    instance.stats.cooldown =-2;
    instance.stats.amount   = 2;
    instance.stats.range    = 2;
    instance.stats.fireRate = 2;
    instance.stats.ammo     = 2;

    return instance;
end

return JackOfAllTrades;