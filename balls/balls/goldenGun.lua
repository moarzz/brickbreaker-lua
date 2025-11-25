local GoldenGun = BallBase.new();
GoldenGun.__index = GoldenGun;
GoldenGun.name = "Golden Gun";
GoldenGun.type = "gun";
GoldenGun.description = "Fires golden bullets that pass through all bricks and always deal full damage.";
GoldenGun.rarity = "rare";
GoldenGun.startingPrice = 100;
GoldenGun.size = 1;
GoldenGun.stats = {
    damage = 2;
    cooldown = 8;
    ammo = 2;
    fireRate = 1;
};

GoldenGun.trail = Trail.new(10, 50);
GoldenGun.currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2;
GoldenGun.bulletSpeed = 1500;
GoldenGun.ammoMult = 2;
GoldenGun.fireRateMult = 1.25;
GoldenGun.noAmount = true;

function GoldenGun.new()
    local instance = setmetatable({}, GoldenGun):init();

    return instance;
end

function GoldenGun:canBuy()
    return Player.currentCore ~= "Phantom Core";
end

function GoldenGun:onBuy()
    -- shoot (?)
end

return GoldenGun;