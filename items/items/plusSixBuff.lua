local PlusSixBuff = ItemBase.new();
PlusSixBuff.__index = PlusSixBuff;
PlusSixBuff.name = "Plus Six Buff";
PlusSixBuff.description = "";
PlusSixBuff.rarity = "uncommon";

function PlusSixBuff.new()
    local instance = setmetatable({}, PlusSixBuff):init();

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

    local itemVersion = math.random(1, 6);

    local randStat = itemStats[itemVersion];

    instance.name = itemNames[itemVersion];
    instance.stats[randStat] = randStat == "cooldown" and -6 or 6;

    return instance;
end

return PlusSixBuff;