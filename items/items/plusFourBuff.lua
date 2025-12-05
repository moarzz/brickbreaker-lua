local PlusFiveBuff = ItemBase.new();
PlusFiveBuff.__index = PlusFiveBuff;
PlusFiveBuff.name = "Plus Five Buff";
PlusFiveBuff.description = "";
PlusFiveBuff.rarity = "rare";

function PlusFiveBuff.new()
    local instance = setmetatable({}, PlusFiveBuff):init();

    local itemStats = {};
    local statUnlocked = {}

    local statNames = {
        "damage",
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
    instance.stats[randStat] = randStat == "cooldown" and -4 or (randStat == "damage" and 3 or 5);
    instance.imageReference = "assets/sprites/UI/ItemIcons/" .. randStat .. (randStat == "cooldown" and "-.png" or "+.png")
    instance.image = love.graphics.newImage(instance.imageReference);

    return instance;
end

return PlusFiveBuff;