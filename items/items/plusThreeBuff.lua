local PlusThreeBuff = ItemBase.new();
PlusThreeBuff.__index = PlusThreeBuff;
PlusThreeBuff.name = "Plus Three Buff";
PlusThreeBuff.description = "";
PlusThreeBuff.rarity = "common";

function PlusThreeBuff.new()
    local instance = setmetatable({}, PlusThreeBuff):init();

    local itemStats = {
        "damage";
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

    local itemVersion = math.random(1, 6);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -3 or (randStat == "damage" and 2 or 3);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. "+.png"
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusThreeBuff;