local DoubleTroublePlusPlus = ItemBase.new();
DoubleTroublePlusPlus.__index = DoubleTroublePlusPlus;
DoubleTroublePlusPlus.name = "Double Trouble ++";
DoubleTroublePlusPlus.description = "<font=default>Increase <colour=green>2<colour=white> random stats by <colour=blue>3";
DoubleTroublePlusPlus.rarity = "rare";
DoubleTroublePlusPlus.imageReference = "assets/sprites/UI/ItemIcons/Triple-Trouble.png";

function DoubleTroublePlusPlus.new()
    local instance = setmetatable({}, DoubleTroublePlusPlus):init();

    local potentialStats = {"damage", "speed", "amount", "fireRate", "cooldown", "range", "speed", "amount", "fireRate", "cooldown", "range"};
    local stat1 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    for i, statName in ipairs(potentialStats) do
        if statName == stat1 then
            table.remove(potentialStats, i)
        end
    end
    local stat2 = table.remove(potentialStats, love.math.random(1, #potentialStats));
    -- local stat3 = table.remove(potentialStats, love.math.random(1, #potentialStats));

    instance.stats[stat1] = stat1 == "cooldown" and -3 or 3;
    instance.stats[stat2] = stat2 == "cooldown" and -3 or 3;

    return instance;
end

return DoubleTroublePlusPlus;