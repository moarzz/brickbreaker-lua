local DoubleTroublePlus = ItemBase.new();
DoubleTroublePlus.__index = DoubleTroublePlus;
DoubleTroublePlus.name = "Double Trouble +";
DoubleTroublePlus.description = "<font=default>Increase <colour=green>2<colour=white> random stats by <colour=blue>2";
DoubleTroublePlus.rarity = "uncommon";
DoubleTroublePlus.imageReference = "assets/sprites/UI/ItemIcons/Triple-Trouble.png";

function DoubleTroublePlus.new()
    local instance = setmetatable({}, DoubleTroublePlus):init();

    local potentialStats = {"damage", "speed", "amount", "fireRate", "cooldown", "range", "speed", "amount", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    for i, statName in ipairs(potentialStats) do
        if statName == stat1 then
            table.remove(potentialStats, i)
        end
    end
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    --local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -2 or 2;
    instance.stats[stat2] = stat2 == "cooldown" and -2 or 2;
    --instance.stats[stat3] = stat3 == "cooldown" and -2 or 2;

    return instance;
end

return DoubleTroublePlus;