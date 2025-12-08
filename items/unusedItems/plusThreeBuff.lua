local PlusThreeBuff = ItemBase.new();
PlusThreeBuff.__index = PlusThreeBuff;
PlusThreeBuff.name = "Plus Three Buff";
PlusThreeBuff.description = "";
PlusThreeBuff.rarity = "uncommon";

function PlusThreeBuff.new()
    local instance = setmetatable({}, PlusThreeBuff):init();

    local itemStats = {};
    local statUnlocked = {}

    local statNames = {
        "damage";
        "speed";
        "amount";
        "ammo";
        "fireRate";
        "cooldown";
        "range";
    };

    local itemNames = {
        "Kitchen Knife +";
        "Running Shoes +";
        "Two for One Meal Ticket +";
        "Extended Magazine +";
        "Fast Hands +";
        "Duct Tape +";
        "Fake Pregnancy Belly +";
    };

    local itemVersion = math.random(1, #statNames);

    local randStat = statNames[itemVersion];

    local name = "no name found"
    for i, statName in ipairs(statNames) do
        if randStat == statName then
            name = itemNames[i]
        end
    end
    instance.name = name;
    instance.stats[randStat] = randStat == "cooldown" and -3 or (randStat == "damage" and 2 or 3);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusThreeBuff;