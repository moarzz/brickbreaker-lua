local BallGun = BallBase.new();
BallGun.__index = BallGun;
BallGun.name = "Ball Gun";
BallGun.type = "gun";
BallGun.description = "A gun that shoots balls. \nDoesn't need to reload. \nSlow fire rate.";
BallGun.rarity = "uncommon";
BallGun.startingPrice = 50;
BallGun.size = 1;
BallGun.stats = {
    damage = 1;
    fireRate = 2;
    amount = 1;
    speed = 150;
};

BallGun.speedMult = 2;
BallGun.trail = Trail.new(10, 50);
BallGun.currentAmmo = 3 + ((Player.permanentUpgrades.ammo or 0)) * 3;
BallGun.bulletSpeed = 1250;
BallGun.ammoMult = 3;
BallGun.fireRateMult = 6;
BallGun.noAmount = true;
BallGun.radius = 10;

function BallGun.new()
    local instance = setmetatable({}, BallGun):init();

    return instance;
end

function BallGun:onBuy()
    -- shoot (?)
end

return BallGun;