local PlusNineBuff = ItemBase.new();
PlusNineBuff.__index = PlusNineBuff;
PlusNineBuff.name = "Plus Nine Buff";
PlusNineBuff.description = "";
PlusNineBuff.rarity = "rare";

function PlusNineBuff.new()
    local instance = setmetatable({}, PlusNineBuff):init();

    local itemStats = {
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Running Shoes ++";
        "Two for One Meal Ticket ++";
        "Extended Magazine ++";
        "Fast Hands ++";
        "Duct Tape ++";
        "Fake Pregnancy Belly ++";
    };

    local itemVersion = math.random(1, 6);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -9 or (randStat == "damage" and 6 or 9);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. "+.png"
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusNineBuff;