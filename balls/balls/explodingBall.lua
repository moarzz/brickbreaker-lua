local ExplodingBall = BallBase.new();
ExplodingBall.__index = ExplodingBall;
ExplodingBall.name = "Exploding Ball";
ExplodingBall.type = "ball";
ExplodingBall.description = "A ball that explodes on impact, dealing damage to nearby bricks.";
ExplodingBall.rarity = "rare";
ExplodingBall.startingPrice = 50;
ExplodingBall.size = 1;
ExplodingBall.stats = {
    speed = 100;
    damage = 1;
    range = 3;
};

ExplodingBall.trail = Trail.new(10, 50);
ExplodingBall.speedMult = 1;
ExplodingBall.ballAmount = 1;

function ExplodingBall.new()
    local instance = setmetatable({}, ExplodingBall):init();

    return instance;
end

return ExplodingBall;