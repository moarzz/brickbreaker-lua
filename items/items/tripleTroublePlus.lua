local TripleTroublePlus = ItemBase.new();
TripleTroublePlus.__index = TripleTroublePlus;
TripleTroublePlus.name = "Triple Trouble +";
TripleTroublePlus.description = "<font=default>Increase <colour=green>3<colour=white> random stats by <colour=blue>2";
TripleTroublePlus.rarity = "uncommon";
TripleTroublePlus.imageReference = "assets/sprites/UI/itemIcons/Triple-Trouble.png";

function TripleTroublePlus.new()
    local instance = setmetatable({}, TripleTroublePlus):init();

    local potentialStats = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -2 or 2;
    instance.stats[stat2] = stat2 == "cooldown" and -2 or 2;
    instance.stats[stat3] = stat3 == "cooldown" and -2 or 2;

    return instance;
end

return TripleTroublePlus;