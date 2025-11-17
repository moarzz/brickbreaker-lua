local PlusSixBuff = ItemBase.new();
PlusSixBuff.__index = PlusSixBuff;
PlusSixBuff.name = "Plus Six Buff";
PlusSixBuff.description = "";
PlusSixBuff.rarity = "rare";

function PlusSixBuff.new()
    local instance = setmetatable({}, PlusSixBuff):init();

    local itemStats = {
        "damage";
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Kitchen Knife ++";
        "Running Shoes ++";
        "Two for One Meal Ticket ++";
        "Extended Magazine ++";
        "Fast Hands ++";
        "Duct Tape ++";
        "Fake Pregnancy Belly ++";
        "Running Shoes ++";
        "Two for One Meal Ticket ++";
        "Extended Magazine ++";
        "Fast Hands ++";
        "Duct Tape ++";
        "Fake Pregnancy Belly ++";
    };

    local itemVersion = math.random(1, #itemStats);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -6 or (randStat == "damage" and 5 or 6);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusSixBuff;