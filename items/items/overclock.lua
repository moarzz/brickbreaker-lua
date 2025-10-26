local Overclock = ItemBase.new();
Overclock.__index = Overclock;
Overclock.name = "Overclock";
Overclock.description = "When you buy this, all your weapons get a permanent upgrade to a random one of their stats";
Overclock.rarity = "uncommon";
Overclock.imageReference = "assets/sprites/UI/ItemIcons/Overclock.png";

Overclock.consumable = true; -- does smthn ig

function Overclock.new()
    local instance = setmetatable({}, Overclock):init();

    return instance;
end

function Overclock:purchase()
    FarmCoreUpgrade();
end

return Overclock;