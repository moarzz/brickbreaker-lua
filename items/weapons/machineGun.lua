local MachineGun = WeaponBase.new();
MachineGun.__index = MachineGun;
MachineGun.name = "Machine Gun";
MachineGun.type = "ball";
MachineGun.description = "Shoots bullets at a very high fire rate.";
MachineGun.rarity = "common";
MachineGun.startingPrice = 5;
MachineGun.size = 2;
MachineGun.stats = {
    damage = 1,
    cooldown = 8,
    ammo = 14,
    fireRate = 4,
};

MachineGun.bulletSpeed = 1000;
MachineGun.ammoMult = 7;
MachineGun.fireRateMult = 0.35;
MachineGun.noAmount = true;

function MachineGun.new()
    local instance = setmetatable({}, MachineGun):init();

    instance.isFiring = true; -- is the machine gun shooting?
    instance.bulletsLeft = instance.stats.ammo * instance.ammoMult;
    instance.shootingRemainder = 0;

    instance.cooldown = 0;

    instance.activeBullets = {};
    instance.bulletTrails = {};
    instance.deadBulletTrails = {};

    -- instance.currentAmmo = getStat("Machine Gun", "ammo");

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

function MachineGun:update(dt)
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

    if not self.isFiring then
        self.cooldown = self.cooldown - dt;

        if self.cooldown <= 0 then
            self.isFiring = true;
            self.bulletsLeft = self.stats.ammo * self.ammoMult;
            self.shootingRemainder = 0;
        end

        return;
    end

    self.shootingRemainder = self.shootingRemainder + self.stats.fireRate * self.fireRateMult * dt;

    while self.shootingRemainder > 0 do
        self.shootingRemainder = self.shootingRemainder - 1;
        self.bulletsLeft = self.bulletsLeft - 1;

        if self.bulletsLeft == 0 then
            self.shootingRemainder = 0;
            self.isFiring = false;
            self.cooldown = self.stats.cooldown;
        end

        local bulletDamage = getStat(self.name, "damage");

        if Player.currentCore == "Phantom Core" then
            bulletDamage = math.max(math.floor(bulletDamage / 2), 1);
        end

        local bulletSpeed = self.bulletSpeed or 1000;
        local angle = math.random() * math.pi / 2 - math.pi / 2;

        playSoundEffect(gunShootSFX, 0.8, 0.8, false, true);

        local critChance = hasItem("Four Leafed Clover") and 0.5 or 0.25;

        local bullet = WeaponEntity.new(paddle.x, paddle.y, 5);
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
    end
end

function MachineGun:hitBrick(ball, brick)
    if ball.isBullet then
        dealDamage(ball, brick);
    else
        dealDamage(self, brick);
    end

    self:onBounce(ball);
end
function MachineGun:hitWall(ball)
    self:onBounce(ball);
end
function MachineGun:hitPaddle(ball)
    self:onBounce(ball);
end

function MachineGun:onBounce(ball)
    if ball.isBullet then
        ball:destroy();

        return;
    end
end

function MachineGun:draw()
    love.graphics.setColor(0.9, 1, 0.6); -- bronzeish?

    for _, v in ipairs(self.deadBulletTrails) do
        v:draw();
    end

    for i, v in ipairs(self.activeBullets) do
        self.bulletTrails[i]:draw();
        love.graphics.circle("fill", v.x, v.y, v.radius);
    end
end

return MachineGun;