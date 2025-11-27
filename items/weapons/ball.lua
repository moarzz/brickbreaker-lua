local Ball = WeaponBase.new();
Ball.__index = Ball;
Ball.name = "Ball";
Ball.type = "ball";
Ball.description = "Basic ball. Very fast.";
Ball.rarity = "common";
Ball.startingPrice = 5;
Ball.size = 2;
Ball.stats = {
    speed = 400;
    damage = 1;
};

Ball.ballAmount = 1;

function Ball.new()
    local instance = setmetatable({}, Ball):init();

    instance.radius = Ball.size * 10;
    instance.ballAmount = instance.ballAmount;

    instance.activeBalls = {};
    instance.activeTrails = {};

    instance.brickCallback = function(...)
        instance:hitBrick(...);
    end

    return instance;
end

function Ball:checkAddBalls()
    while #self.activeBalls < self.ballAmount do
        local newBall = WeaponEntity.new(screenWidth / 2, math.max(screenHeight / 4, getHighestBrickY() + self.radius), self.radius);

        newBall.bonusSize = 0; -- animation

        newBall:setSpeed(self.stats.speed);
        newBall:setDirection((math.random() - 0.5) * math.pi * 0.8 - math.pi / 2); -- random angle facing upwards and not too sideways
        newBall:setBrickCallback(self.brickCallback);

        table.insert(self.activeBalls, newBall);
        table.insert(self.activeTrails, Trail.new(20, 100));
    end
end

function Ball:update(dt)
    self:checkAddBalls();

    for i, ball in ipairs(self.activeBalls) do
        ball:update(dt);
        self.activeTrails[i]:addPosition(ball.x, ball.y);

        if ball.bonusSize > 0 then
            ball.bonusSize = math.max(ball.bonusSize - dt * 8, 0);
        end
    end
end

function Ball:hitBrick(ball, brick)
    dealDamage(self, brick);
    ball.bonusSize = 10;
end

function Ball:draw()
    love.graphics.setColor(1,1,1);

    for i, v in ipairs(self.activeBalls) do
        self.activeTrails[i]:draw();
        love.graphics.setColor(1,1,1,0.9);
        love.graphics.circle("fill", v.x, v.y, v.radius + v.bonusSize);
        love.graphics.setColor(1,1,1);
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end
end

return Ball;