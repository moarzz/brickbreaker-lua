local PlusTwoBuff = ItemBase.new();
PlusTwoBuff.__index = PlusTwoBuff;
PlusTwoBuff.name = "Plus Two Buff";
PlusTwoBuff.description = "";
PlusTwoBuff.rarity = "common";

function PlusTwoBuff.new()
    local instance = setmetatable({}, PlusTwoBuff):init();

    local itemStats = {
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

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -2 or (randStat == "damage" and 1 or 2);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusTwoBuff;