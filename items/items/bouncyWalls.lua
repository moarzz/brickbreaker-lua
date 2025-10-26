local BouncyWalls = ItemBase.new();
BouncyWalls.__index = BouncyWalls;
BouncyWalls.name = "Bouncy Walls";
BouncyWalls.description = "Balls gain a temporary boost of speed after bouncing off walls";
BouncyWalls.rarity = "uncommon";
BouncyWalls.imageReference = "assets/sprites/UI/itemIcons/Bouncy-Walls.png";

BouncyWalls.unique = true; -- does smthn ig

function BouncyWalls.new()
    local instance = setmetatable({}, BouncyWalls):init();

    instance.stats.amount = 1;
    instance.stats.speed = 1;

    return instance;
end

return BouncyWalls;