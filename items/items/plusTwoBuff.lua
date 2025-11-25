local PlusTwoBuff = ItemBase.new();
PlusTwoBuff.__index = PlusTwoBuff;
PlusTwoBuff.name = "Plus Two Buff";
PlusTwoBuff.description = "";
PlusTwoBuff.rarity = "common";

function PlusTwoBuff.new()
    local instance = setmetatable({}, PlusTwoBuff):init();

    local itemStats = {};
    local statUnlocked = {}
    for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
        for statName, _ in pairs(weapon.stats) do
            if not statUnlocked[statName] and statName ~= "damage" then
                table.insert(itemStats, statName);
                statUnlocked[statName] = true
            end
        end
        if weapon.type == "ball" then
            if not statUnlocked["amount"] then
                table.insert(itemStats, "amount");
                statUnlocked["amount"] = true
            end
        end
    end

    local statNames = {
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Running Shoes";
        "Two for One Meal Ticket";
        "Extended Magazine";
        "Fast Hands";
        "Duct Tape";
        "Fake Pregnancy Belly";
    };

    local itemVersion = math.random(1, #itemStats);

    local randStat = itemStats[itemVersion];

    local name = "no name found"
    for i, statName in ipairs(statNames) do
        if randStat == statName then
            name = itemNames[i]
        end
    end
    instance.name = name;
    instance.stats[randStat] = randStat == "cooldown" and -2 or (randStat == "damage" and 1 or 2);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusTwoBuff;