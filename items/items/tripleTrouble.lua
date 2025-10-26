local TripleTrouble = ItemBase.new();
TripleTrouble.__index = TripleTrouble;
TripleTrouble.name = "Triple Trouble";
TripleTrouble.description = "<font=default>Increase <colour=green>3<colour=white> random stats by <colour=blue>1";
TripleTrouble.rarity = "common";
TripleTrouble.imageReference = "assets/sprites/UI/itemIcons/Triple-Trouble.png";

function TripleTrouble.new()
    local instance = setmetatable({}, TripleTrouble):init();

    local potentialStats = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -1 or 1;
    instance.stats[stat2] = stat2 == "cooldown" and -1 or 1;
    instance.stats[stat3] = stat3 == "cooldown" and -1 or 1;

    return instance;
end

return TripleTrouble;