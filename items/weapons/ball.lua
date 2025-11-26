local Ball = WeaponBase.new();
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

-- Ball.trail = Trail.new(10, 50);
Ball.speedMult = 2;
Ball.ballAmount = 1;

function Ball.new()
    local instance = setmetatable({}, Ball):init();

    instance.radius = Ball.size * 10;
    instance.ballAmount = instance.ballAmount;

    instance.activeBalls = {};
    instance.activeTrails = {};

    return instance;
end

function Ball:checkAddBalls()
    while #self.activeBalls < self.ballAmount do
        local newBall = WeaponEntity.new(screenWidth / 2, math.max(screenHeight / 4, getHighestBrickY() + self.radius), self.radius);

        newBall:setSpeed(self.stats.speed);
        newBall:setDirection((math.random() - 0.5) * math.pi * 0.8 - math.pi / 2); -- random angle facing upwards and not too sideways
        newBall:setBrickCallback(
            function(...)
                self:hitBrick(...);
            end
        );

        table.insert(self.activeBalls, newBall);
        table.insert(self.activeTrails, Trail.new(10, 50));
    end
end

function Ball:update(dt)
    self:checkAddBalls();

    for i, ball in ipairs(self.activeBalls) do
        ball:update(dt);
        self.activeTrails[i]:addPosition(ball.x, ball.y);
    end
end

function Ball:hitBrick(ball, brick)
    dealDamage(self, brick);
end

function Ball:draw()
    love.graphics.setColor(1,1,1);

    for i, v in ipairs(self.activeBalls) do
        self.activeTrails[i]:draw();
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end
end

return Ball;