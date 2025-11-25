local GunBall = BallBase.new();
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

    return instance;
end

function GunBall:onBounce()
    -- shoot
end

return GunBall;