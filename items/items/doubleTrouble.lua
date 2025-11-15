local DoubleTrouble = ItemBase.new();
DoubleTrouble.__index = DoubleTrouble;
DoubleTrouble.name = "Double Trouble";
DoubleTrouble.description = "<font=default>Increase <colour=green>2<colour=white> random stats by <colour=blue>1";
DoubleTrouble.rarity = "common";
DoubleTrouble.imageReference = "assets/sprites/UI/ItemIcons/Triple-Trouble.png";

function DoubleTrouble.new()
    local instance = setmetatable({}, DoubleTrouble):init();

    local potentialStats = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    --local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -1 or 1;
    instance.stats[stat2] = stat2 == "cooldown" and -1 or 1;
    --instance.stats[stat3] = stat3 == "cooldown" and -1 or 1;

    return instance;
end

return DoubleTrouble;