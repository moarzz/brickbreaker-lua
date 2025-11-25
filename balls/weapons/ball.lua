local Ball = BallBase.new();
Ball.__index = Ball;
Ball.name = "Ball";
Ball.type = "ball";
Ball.description = "Basic ball. Very fast.";
Ball.rarity = "common";
Ball.startingPrice = 5;
Ball.size = 1;
Ball.stats = {
    speed = 200;
    damage = 1;
};

Ball.trail = Trail.new(10, 50);
Ball.speedMult = 2;
Ball.ballAmount = 1;

function Ball.new()
    local instance = setmetatable({}, Ball):init();

    instance.radius = Ball.size * 10;

    return instance;
end

function Ball:canBuy()
    return true;
end

return Ball;