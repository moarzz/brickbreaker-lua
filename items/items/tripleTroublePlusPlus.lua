local TripleTroublePlusPlus = ItemBase.new();
TripleTroublePlusPlus.__index = TripleTroublePlusPlus;
TripleTroublePlusPlus.name = "Triple Trouble ++";
TripleTroublePlusPlus.description = "<font=default>Increase <colour=green>3<colour=white> random stats by <colour=blue>3";
TripleTroublePlusPlus.rarity = "rare";
TripleTroublePlusPlus.imageReference = "assets/sprites/UI/itemIcons/Triple-Trouble.png";

function TripleTroublePlusPlus.new()
    local instance = setmetatable({}, TripleTroublePlusPlus):init();

    local potentialStats = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -3 or 3;
    instance.stats[stat2] = stat2 == "cooldown" and -3 or 3;
    instance.stats[stat3] = stat3 == "cooldown" and -3 or 3;

    return instance;
end

return TripleTroublePlusPlus;