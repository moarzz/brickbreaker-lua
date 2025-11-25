local Fireballs = BallBase.new();
Fireballs.__index = Fireballs;
Fireballs.name = "Fireballs";
Fireballs.type = "spell";
Fireballs.description = "shoot fireballs that explodes on impact, dealing area damage.";
Fireballs.rarity = "rare";
Fireballs.startingPrice = 100;
Fireballs.size = 1;
Fireballs.stats = {
    amount = 1;
    damage = 2;
    fireRate = 1;
    range = 2;
};

Fireballs.trail = Trail.new(10, 50);
Fireballs.noAmount = true;

function Fireballs.new()
    local instance = setmetatable({}, Fireballs):init();

    return instance;
end

function Fireballs:onBuy()
    -- cast (?)
end

return Fireballs;