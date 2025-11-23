local DoubleTrouble = ItemBase.new();
DoubleTrouble.__index = DoubleTrouble;
DoubleTrouble.name = "Double Trouble";
DoubleTrouble.description = "<font=default>Increase <colour=green>2<colour=white> random stats by <colour=blue>1";
DoubleTrouble.rarity = "common";
DoubleTrouble.imageReference = "assets/sprites/UI/ItemIcons/Triple-Trouble.png";

function DoubleTrouble.new()
    local instance = setmetatable({}, DoubleTrouble):init();

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

    -- local potentialStats = {"damage", "speed", "amount", "ammo", "fireRate", "cooldown", "range", "speed", "amount", "ammo", "fireRate", "cooldown", "range"};
    
    local stat1 = table.remove(itemStats, love.math.random(1, #itemStats));

    for i, statName in ipairs(itemStats) do
        if statName == stat1 then
            table.remove(itemStats, i)
        end
    end
    local stat2 = table.remove(itemStats, love.math.random(1, #itemStats));

    instance.stats[stat1] = stat1 == "cooldown" and -1 or 1;
    instance.stats[stat2] = stat2 == "cooldown" and -1 or 1;

    return instance;
end

return DoubleTrouble;