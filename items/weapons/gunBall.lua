local GunBall = WeaponBase.new();
GunBall.__index = GunBall;
GunBall.name = "Gun Ball";
GunBall.type = "ball";
GunBall.description = "A ball that shoots bullets in a random direction like a gun on bounce.";
GunBall.rarity = "common";
GunBall.startingPrice = 50;
GunBall.size = 1;
GunBall.stats = {
    speed = 150;
    damage = 1;
};

GunBall.trail = Trail.new(10, 50);
GunBall.speedMult = 0.9;
GunBall.ballAmount = 1;
GunBall.currentAmmo = 1;
GunBall.bulletSpeed = 1000;

function GunBall.new()
    local instance = setmetatable({}, GunBall):init();

    instance.radius = GunBall.size * 10;
    instance.ballAmount = instance.ballAmount;

    instance.activeBalls = {};
    instance.activeTrails = {};

    instance.activeBullets = {};
    instance.bulletTrails = {};
    instance.deadBulletTrails = {};

    instance.brickCallback = function(...)
        instance:hitBrick(...);
    end
    instance.wallCallback = function(...)
        instance:hitWall(...);
    end
    instance.paddleCallback = function(...)
        instance:hitPaddle(...);
    end

    return instance;
end


function GunBall:checkAddBalls()
    while #self.activeBalls < self.ballAmount do
        local newBall = WeaponEntity.new(screenWidth / 2, math.max(screenHeight / 4, getHighestBrickY() + self.radius), self.radius);

        newBall:setSpeed(self.stats.speed);
        newBall:setDirection((math.random() - 0.5) * math.pi * 0.8 - math.pi / 2); -- random angle facing upwards and not too sideways
        newBall:setBrickCallback(self.brickCallback);
        newBall:setWallCallback(self.wallCallback);
        newBall:setPaddleCallback(self.paddleCallback);

        table.insert(self.activeBalls, newBall);
        table.insert(self.activeTrails, Trail.new(10, 50));
    end
end

function GunBall:update(dt)
    self:checkAddBalls();

    for i, ball in ipairs(self.activeBalls) do
        ball:update(dt);
        self.activeTrails[i]:addPosition(ball.x, ball.y);
    end

    for i = #self.deadBulletTrails, 1, -1 do
        if self.deadBulletTrails[i]:kickData() then
            table.remove(self.deadBulletTrails, i);
        end
    end

    for i = #self.activeBullets, 1, -1 do
        local bullet = self.activeBullets[i];

        bullet:update(dt);
        self.bulletTrails[i]:addPosition(bullet.x, bullet.y);

        if bullet:isDestroyed() then
            table.insert(self.deadBulletTrails, table.remove(self.bulletTrails, i));
            table.remove(self.activeBullets, i);
        end
    end
end

function GunBall:hitBrick(ball, brick)
    if ball.isBullet then
        dealDamage(ball, brick);
    else
        dealDamage(self, brick);
    end

    self:onBounce(ball);
end
function GunBall:hitWall(ball)
    self:onBounce(ball);
end
function GunBall:hitPaddle(ball)
    self:onBounce(ball);
end

function GunBall:draw()
    love.graphics.setColor(1,1,0); -- orange

    for i, v in ipairs(self.activeBalls) do
        self.activeTrails[i]:draw();
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end

    love.graphics.setColor(0.9, 1, 0.6); -- bronzeish?

    for _, v in ipairs(self.deadBulletTrails) do
        v:draw();
    end

    for i, v in ipairs(self.activeBullets) do
        self.bulletTrails[i]:draw();
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end
end

function GunBall:onBounce(ball)
    if ball.isBullet then
        ball:destroy();

        return;
    end

    -- Always calculate bulletDamage as a number, never a boolean
    local bulletDamage = getStat(self.name, "damage");

    if Player.currentCore == "Phantom Core" then
        bulletDamage = math.max(math.floor(bulletDamage / 2), 1);
    end

    local bulletSpeed = self.bulletSpeed or 1000;
    local angle = math.random() * math.pi * 2;

    playSoundEffect(gunShootSFX, 0.8, 0.8, false, true);

    local critChance = hasItem("Four Leafed Clover") and 0.5 or 0.25;

    local bullet = WeaponEntity.new(ball.x, ball.y, 5);
    bullet:setDirection(angle);
    bullet:setSpeed(bulletSpeed);
    bullet.isCrit = hasItem("Assassin's Dagger") and math.random() < critChance;
    bullet.isBullet = true;
    bullet.stats = {damage = bulletDamage * (bullet.isCrit and 2 or 1)};

    bullet:setBrickCallback(self.brickCallback);
    bullet:setWallCallback(self.wallCallback);
    bullet:setPaddleCallback(self.paddleCallback);
    -- bullet.isGold = math.random() < getGoldenBulletChance();

    table.insert(self.activeBullets, bullet);
    table.insert(self.bulletTrails, Trail.new(5, 30));

    if not hasItem("Sudden Mitosis") then
        return;
    end

    local splitChance = hasItem("Four Leafed Clover") and 0.2 or 0.1;
    if math.random() >= splitChance then
        return;
    end

    angle = math.random() * math.pi * 2;

    local bulletSplit = WeaponEntity.new(ball.x, ball.y, 5);
    bulletSplit:setDirection(angle);
    bulletSplit:setSpeed(bulletSpeed);
    bulletSplit.isCrit = hasItem("Assassin's Dagger") and math.random() < critChance;
    bulletSplit.isBullet = true;
    bulletSplit.stats = {damage = bulletDamage * (bulletSplit.isCrit and 2 or 1)};

    bulletSplit:setBrickCallback(self.brickCallback);
    bulletSplit:setWallCallback(self.wallCallback);
    bulletSplit:setPaddleCallback(self.paddleCallback);
    -- bulletSplit.isGold = math.random() < getGoldenBulletChance();

    table.insert(self.activeBullets, bulletSplit);
    table.insert(self.bulletTrails, Trail.new(5, 30));
end

return GunBall;