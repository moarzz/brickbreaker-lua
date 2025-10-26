local PlusThreeBuff = ItemBase.new();
PlusThreeBuff.__index = PlusThreeBuff;
PlusThreeBuff.name = "Plus Three Buff";
PlusThreeBuff.description = "";
PlusThreeBuff.rarity = "common";

function PlusThreeBuff.new()
    local instance = setmetatable({}, PlusThreeBuff):init();

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

    local itemVersion = math.random(1, 6);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -3 or 3;

    return instance;
end

return PlusThreeBuff;