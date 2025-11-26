local ExplodingBall = WeaponBase.new();
ExplodingBall.__index = ExplodingBall;
ExplodingBall.name = "Exploding Ball";
ExplodingBall.type = "ball";
ExplodingBall.description = "A ball that explodes on impact, dealing damage to nearby bricks.";
ExplodingBall.rarity = "common";--"rare";
ExplodingBall.startingPrice = 50;
ExplodingBall.size = 1;
ExplodingBall.stats = {
    speed = 100;
    damage = 1;
    range = 3;
};

-- ExplodingBall.trail = Trail.new(10, 50);
ExplodingBall.speedMult = 1;
ExplodingBall.ballAmount = 1;

function ExplodingBall.new()
    local instance = setmetatable({}, ExplodingBall):init();

    instance.radius = ExplodingBall.size * 10;
    instance.ballAmount = instance.ballAmount;

    instance.activeBalls = {};
    instance.activeTrails = {};

    return instance;
end

function ExplodingBall:checkAddBalls()
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

function ExplodingBall:update(dt)
    self:checkAddBalls();

    for i, ball in ipairs(self.activeBalls) do
        ball:update(dt);
        self.activeTrails[i]:addPosition(ball.x, ball.y);
    end
end

function ExplodingBall:hitBrick(ball, brick)
    local scale = math.max(getStat(self.name, "range") * 0.3 + 0.5, 1)
    -- Limit Chain Lightning sprite animations to 25 at once
    createSpriteAnimation(ball.x, ball.y, scale/2, explosionVFX, 512, 512, 0.01, 5, false, 0.9, 0.9)

    --Explosion.spawn(ball.x, ball.y, scale)

    -- Play explosion sound
    playSoundEffect(explosionSFX, 0.5, 1, false, true);

    dealDamage(self, brick);

    local bricksTouchingCircle = getBricksInCircle(ball.x, ball.y, getStat(self.name, "range") * 15);
    for _, touchingBrick in ipairs(bricksTouchingCircle) do
        if touchingBrick and touchingBrick ~= brick then -- Ensure not nil and not the original brick
            if touchingBrick.health > 0 then
                dealDamage(self, touchingBrick); -- Deal damage to the touched bricks
            end
        end
    end

    -- Decrement the global Chain Lightning sprite count when the animation ends
    local anim = getAnimation and getAnimation(ball.x, ball.y, scale/3, explosionVFX); -- getAnimation must be implemented to retrieve the animation object
    if anim and anim.onComplete then
        local oldOnComplete = anim.onComplete;

        anim.onComplete = function(...)
            _G.chainLightningSpriteCount = math.max(0, (_G.chainLightningSpriteCount or 1) - 1);

            if oldOnComplete then
                oldOnComplete(...);
            end
        end
    end
end

function ExplodingBall:draw()
    love.graphics.setColor(1,0.2,0.2);

    for i, v in ipairs(self.activeBalls) do
        self.activeTrails[i]:draw();
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end
end

return ExplodingBall;