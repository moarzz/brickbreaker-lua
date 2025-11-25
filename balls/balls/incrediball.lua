local Incrediball = BallBase.new();
Incrediball.__index = Incrediball;
Incrediball.name = "Incrediball";
Incrediball.type = "ball";
Incrediball.description = "Has the effects of every other ball (except phantom ball).";
Incrediball.rarity = "legendary";
Incrediball.startingPrice = 50;
Incrediball.size = 1;
Incrediball.stats = {
    speed = 50;
    damage = 1;
    range = 2;
};

Incrediball.trail = Trail.new(10, 50);
Incrediball.speedMult = 1.25;
Incrediball.ballAmount = 1;
Incrediball.currentAmmo = 1;
Incrediball.bulletSpeed = 1000;
Incrediball.attractionStrength = 600;

function Incrediball.new()
    local instance = setmetatable({}, Incrediball):init();

    return instance;
end

function Incrediball:onBounce()
    -- shoot
end

function Incrediball:canBuy()
    return hasItem("Superhero t-shirt");
end

return Incrediball;