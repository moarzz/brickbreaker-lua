local Shotgun = WeaponBase.new();
Shotgun.__index = Shotgun;
Shotgun.name = "Shotgun";
Shotgun.type = "gun";
Shotgun.description = "Fire bullets that die on impact in bursts.";
Shotgun.rarity = "common";
Shotgun.startingPrice = 25;
Shotgun.size = 1;
Shotgun.stats = {
    damage = 1;
    cooldown = 9;
    ammo = 2;
    fireRate = 1;
};

Shotgun.trail = Trail.new(10, 50);
Shotgun.bulletSpeed = 1500;
Shotgun.ammoMult = 2;
Shotgun.fireRateMult = 1.8;
Shotgun.noAmount = true;

function Shotgun.new()
    local instance = setmetatable({}, Shotgun):init();

    instance.currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2;

    return instance;
end

function Shotgun:onBuy()
    -- shoot (?)
end

return Shotgun;