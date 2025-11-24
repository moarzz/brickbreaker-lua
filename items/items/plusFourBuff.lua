local PlusFourBuff = ItemBase.new();
PlusFourBuff.__index = PlusFourBuff;
PlusFourBuff.name = "Plus Four Buff";
PlusFourBuff.description = "";
PlusFourBuff.rarity = "uncommon";

function PlusFourBuff.new()
    local instance = setmetatable({}, PlusFourBuff):init();

    local itemStats = {
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Running Shoes +";
        "Two for One Meal Ticket +";
        "Extended Magazine +";
        "Fast Hands +";
        "Duct Tape +";
        "Fake Pregnancy Belly +";
    };

    local itemVersion = math.random(1, #itemStats);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -4 or (randStat == "damage" and 2 or 4);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusFourBuff;