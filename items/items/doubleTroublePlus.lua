local DoubleTroublePlus = ItemBase.new();
DoubleTroublePlus.__index = DoubleTroublePlus;
DoubleTroublePlus.name = "Double Trouble +";
DoubleTroublePlus.description = "<font=default>Increase <colour=green>2<colour=white> random stats by <colour=blue>2";
DoubleTroublePlus.rarity = "uncommon";
DoubleTroublePlus.imageReference = "assets/sprites/UI/ItemIcons/Triple-Trouble.png";

function DoubleTroublePlus.new()
    local instance = setmetatable({}, DoubleTroublePlus):init();

    local itemStats = {};
    local statUnlocked = {}
    for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
        for statName, _ in pairs(weapon.stats) do
            if not statUnlocked[statName] and statName ~= "damage" then
                table.insert(itemStats, statName);
                table.insert(itemStats, statName);
                statUnlocked[statName] = true
            end
        end
        if weapon.type == "ball" then
            if not statUnlocked["amount"] then
                table.insert(itemStats, "amount");
                table.insert(itemStats, "amount");
                statUnlocked["amount"] = true
            end
        end
    end
    table.insert(itemStats, "damage");
    
    local stat1 = table.remove(itemStats, love.math.random(1, #itemStats));

    for i, statName in ipairs(itemStats) do
        if statName == stat1 then
            table.remove(itemStats, i)
        end
    end
    local stat2 = table.remove(itemStats, love.math.random(1, #itemStats));

    instance.stats[stat1] = stat1 == "cooldown" and -2 or 2;
    instance.stats[stat2] = stat2 == "cooldown" and -2 or 2;

    return instance;
end

return DoubleTroublePlus;